#!/usr/bin/env bash
set -euo pipefail

# Conda-first universal ML environment setup.
# Run this from inside your project directory.
# Creates a NAMED conda env (default: ml-<project-dir>) and installs PyTorch
# with hardware-aware defaults.

# ----------------------------------------------------------------------------
# Overridable version defaults (prefer latest, fleet-safe — verified 2026-07-14)
#
#   PYTHON_VERSION  default 3.13  (latest mature; cu130/rocm7.2/gfx1151-nightly
#                                  all ship cp313 wheels)
#   TORCH_VERSION   default 2.13.0 (latest stable on cu130 / rocm7.2)
#   CUDA_INDEX      default cu130  (CUDA 13.0 — the 3 fleet NVIDIA boxes are
#                                   driver 580.x = max CUDA 13.0. Use cu132 only
#                                   after upgrading drivers.)
#   ROCM_INDEX      default rocm7.2 (latest on pytorch.org)
#
# gfx1151 (Strix Halo) ignores TORCH_VERSION/CUDA_INDEX and uses its own
# verified tracks — see install_gfx1151() below.
# ----------------------------------------------------------------------------

PYTHON_VERSION_DEFAULT="3.13"
TORCH_VERSION_DEFAULT="2.13.0"
CUDA_INDEX_DEFAULT="cu130"
ROCM_INDEX_DEFAULT="rocm7.2"

PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

PYTHON_VERSION="${PYTHON_VERSION:-$PYTHON_VERSION_DEFAULT}"
TORCH_VERSION="${TORCH_VERSION:-$TORCH_VERSION_DEFAULT}"
CUDA_INDEX="${CUDA_INDEX:-$CUDA_INDEX_DEFAULT}"
ROCM_INDEX="${ROCM_INDEX:-$ROCM_INDEX_DEFAULT}"
ENV_NAME="${ENV_NAME:-ml-${PROJECT_NAME}}"

# Log into the PROJECT dir (not the skill dir) so users find it next to their code.
LOG_FILE="$PROJECT_DIR/setup-${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}=== ML Env Setup (conda-first) ===${NC}"
echo "Project:  $PROJECT_DIR"
echo "Env name: $ENV_NAME"
echo "Python:   $PYTHON_VERSION"
echo "PyTorch:  $TORCH_VERSION (gfx1151 uses its own tracks)"
echo "CUDA:     $CUDA_INDEX  |  ROCm: $ROCM_INDEX"
echo "Log:      $LOG_FILE"
echo

# ----------------------------------------------------------------------------
# conda discovery
# ----------------------------------------------------------------------------

ensure_conda() {
  if command -v conda >/dev/null 2>&1; then
    return 0
  fi

  # conda is a shell function; in non-interactive shells (e.g. Claude running
  # this script) it is often NOT on PATH. Source conda.sh from any common prefix.
  local cand
  for cand in \
      "$HOME/miniforge" \
      "$HOME/miniconda3" \
      "$HOME/anaconda3" \
      "$HOME/miniforge3"; do
    if [ -f "$cand/etc/profile.d/conda.sh" ]; then
      # shellcheck disable=SC1091
      . "$cand/etc/profile.d/conda.sh"
      command -v conda >/dev/null 2>&1 && return 0
    fi
  done

  return 1
}

if ! ensure_conda; then
  echo -e "${RED}Error: conda is not available in this shell.${NC}"
  echo "Install Miniforge/Miniconda and ensure conda.sh is sourced."
  echo "Tip: linux-dotfiles sets a portable ~/.condarc so envs go under ~/conda/envs."
  exit 1
fi

echo -e "${GREEN}✓ conda found: $(conda --version)${NC}"

if command -v uv >/dev/null 2>&1; then
  echo -e "${GREEN}✓ uv found: $(uv --version)${NC} (used as a faster pip front-end)"
else
  echo -e "${YELLOW}⚠️  uv not found (ok). Using pip directly.${NC}"
fi

# ----------------------------------------------------------------------------
# detection helpers
# ----------------------------------------------------------------------------

detect_platform() {
  if grep -qi microsoft /proc/version 2>/dev/null; then
    echo "wsl"
  else
    echo "linux"
  fi
}

detect_gpu() {
  if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    echo "nvidia"
    return
  fi

  if command -v rocminfo &>/dev/null && rocminfo &>/dev/null; then
    echo "amd"
    return
  fi

  if command -v rocm-smi &>/dev/null; then
    echo "amd"
    return
  fi

  if command -v lspci &>/dev/null && lspci | grep -iq "VGA.*AMD"; then
    echo "amd"
    return
  fi

  echo "cpu"
}

get_nvidia_compute_cap() {
  # Prints "major minor", e.g. "12 0" or "8 6".
  local cap
  cap=$(nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>/dev/null | head -n1 | xargs || true)
  if [ -z "$cap" ]; then
    echo "0 0"
    return
  fi
  echo "${cap%%.*} ${cap##*.}"
}

get_amd_gfx_arch() {
  if command -v rocminfo &>/dev/null; then
    rocminfo 2>/dev/null | grep -oE 'gfx[0-9]+' | head -n1 || true
  fi
}

# ----------------------------------------------------------------------------
# pip front-end (uv if present, else pip) — always targets the conda env's python
# ----------------------------------------------------------------------------

ENV_PYTHON=""

resolve_env_python() {
  ENV_PYTHON="$(conda run -n "$ENV_NAME" which python)"
}

run_pip() {
  # Args are the pip args AFTER the "install" verb, e.g. run_pip -U pip setuptools wheel
  if command -v uv >/dev/null 2>&1; then
    uv pip install --python "$ENV_PYTHON" "$@"
  else
    "$ENV_PYTHON" -m pip install "$@"
  fi
}

# ----------------------------------------------------------------------------
# project scaffolding
# ----------------------------------------------------------------------------

ensure_project_gitignore() {
  if [ -f "$PROJECT_DIR/.gitignore" ]; then
    return 0
  fi
  cat > "$PROJECT_DIR/.gitignore" <<'GITIGNORE'
# Python
__pycache__/
*.py[cod]
*.egg-info/
.ipynb_checkpoints/

# ML project artifacts
data/
models/
logs/
*.log
setup-*.log

# Editor / OS
.vscode/
.idea/
.DS_Store
GITIGNORE
  echo -e "${GREEN}✓ wrote .gitignore${NC}"
}

# ----------------------------------------------------------------------------
# env + package install
# ----------------------------------------------------------------------------

create_env() {
  if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo -e "${YELLOW}⚠️  Env already exists: $ENV_NAME (reusing)${NC}"
    return 0
  fi

  echo -e "${BLUE}Creating conda env: ${ENV_NAME} (python=${PYTHON_VERSION})${NC}"
  conda create -y -n "$ENV_NAME" "python=${PYTHON_VERSION}" pip
}

install_base_tools() {
  echo -e "${BLUE}Upgrading base python tooling...${NC}"
  run_pip -U pip setuptools wheel
}

install_gfx1151() {
  # Strix Halo (gfx1151): vanilla PyTorch wheels fail with
  # "HIP error: invalid device function". Use one of the verified tracks below.
  # The dedicated ~/Projects/amdtest (strix-halo-setup) skill owns the deep
  # details (GTT/amd-ttm, flash-SDPA build, kernel backport checks).
  cat <<'EOF'

Strix Halo (gfx1151) — special handling required.
Official PyTorch wheels do NOT work here. Two verified tracks:

  1) TheRock multi-arch nightly (DEFAULT) — latest PyTorch (~2.12), clean index,
     works with the default Python 3.13.
  2) AMD supported stable (ROCm 7.2.1) — AMD-validated, torch 2.9.1; cp312 only,
     needs PYTHON_VERSION=3.12.
  3) CPU-only fallback.

Do NOT set HSA_ENABLE_SDMA / PYTORCH_HIP_ALLOC_CONF globally (subtle bugs);
only per-process for a reproduced issue. See the strix-halo-setup skill.
EOF

  local choice="${GFX1151_TRACK:-}"
  if [ -z "$choice" ]; then
    if [ -t 0 ]; then
      read -r -p "Choice [1-3, default 1]: " choice || true
    fi
    choice="${choice:-1}"
  fi
  echo -e "${BLUE}gfx1151 track: ${choice}${NC}"

  case "$choice" in
    1)
      echo -e "${BLUE}Installing TheRock multi-arch nightly (torch[device-gfx1151])...${NC}"
      run_pip --index-url "https://rocm.nightlies.amd.com/whl-multi-arch/" \
        "torch[device-gfx1151]" "torchvision[device-gfx1151]" torchaudio
      ;;
    2)
      # AMD-validated ROCm 7.2.1 wheels (strix-halo v2.0.0 Track A).
      # Pinned URLs last validated 2026-07-14. Refresh source of truth:
      #   ~/Projects/amdtest  (strix-halo-setup skill, INSTALLATION.md)
      if [ "$PYTHON_VERSION" != "3.12" ]; then
        echo -e "${YELLOW}⚠️  AMD stable track ships cp312 wheels but this env is Python ${PYTHON_VERSION}.${NC}"
        echo "    Recreate with: PYTHON_VERSION=3.12 ENV_NAME=${ENV_NAME} bash setup-universal.sh"
        echo -e "${YELLOW}    Falling back to TheRock nightly (supports this Python).${NC}"
        run_pip --index-url "https://rocm.nightlies.amd.com/whl-multi-arch/" \
          "torch[device-gfx1151]" "torchvision[device-gfx1151]" torchaudio
        return
      fi
      echo -e "${BLUE}Installing AMD supported stable (ROCm 7.2.1, torch 2.9.1)...${NC}"
      run_pip \
        "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torch-2.9.1%2Brocm7.2.1.lw.gitff65f5bc-cp312-cp312-linux_x86_64.whl" \
        "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchvision-0.24.0%2Brocm7.2.1.gitb919bd0c-cp312-cp312-linux_x86_64.whl" \
        "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchaudio-2.9.0%2Brocm7.2.1.gite3c6ee2b-cp312-cp312-linux_x86_64.whl" \
        "https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/triton-3.5.1%2Brocm7.2.1.gita272dfa8-cp312-cp312-linux_x86_64.whl"
      ;;
    3)
      echo -e "${BLUE}Installing CPU-only PyTorch...${NC}"
      run_pip torch torchvision torchaudio \
        --index-url "https://download.pytorch.org/whl/cpu"
      ;;
    *)
      echo -e "${RED}Invalid choice '${choice}'. Aborting.${NC}"
      exit 1
      ;;
  esac
}

install_pytorch() {
  local gpu_type="$1"
  local platform="$2"

  if [ "$gpu_type" = "nvidia" ]; then
    read -r cc_major cc_minor < <(get_nvidia_compute_cap)
    echo -e "${YELLOW}NVIDIA GPU detected (compute capability: ${cc_major}.${cc_minor}, sm_${cc_major}${cc_minor})${NC}"

    if [ "${cc_major:-0}" -ge 12 ]; then
      # Blackwell (sm_120+) is natively supported by PyTorch >= 2.12 on cu130 —
      # no special "experimental" handling needed.
      echo -e "${YELLOW}Blackwell-class GPU — supported natively by PyTorch ${TORCH_VERSION} on ${CUDA_INDEX}.${NC}"
    fi

    if [ "$platform" = "wsl" ]; then
      echo -e "${BLUE}ℹ️  WSL2 detected: use the Windows NVIDIA driver (do NOT install a Linux driver in WSL).${NC}"
    fi

    local index_url="https://download.pytorch.org/whl/${CUDA_INDEX}"
    echo -e "${BLUE}Installing PyTorch ${TORCH_VERSION} from ${index_url}${NC}"
    run_pip "torch==${TORCH_VERSION}" torchvision torchaudio --index-url "$index_url"

  elif [ "$gpu_type" = "amd" ]; then
    local gfx
    gfx="$(get_amd_gfx_arch)"
    echo -e "${YELLOW}AMD GPU detected${NC}"
    [ -n "$gfx" ] && echo -e "${YELLOW}Detected arch: ${gfx}${NC}"

    if [ "$gfx" = "gfx1151" ]; then
      install_gfx1151
    else
      local index_url="https://download.pytorch.org/whl/${ROCM_INDEX}"
      echo -e "${BLUE}Installing PyTorch ${TORCH_VERSION} (ROCm) from ${index_url}${NC}"
      run_pip "torch==${TORCH_VERSION}" torchvision torchaudio --index-url "$index_url"
    fi

  elif [ "$gpu_type" = "cpu" ]; then
    echo -e "${BLUE}Installing CPU-only PyTorch ${TORCH_VERSION}${NC}"
    run_pip "torch==${TORCH_VERSION}" torchvision torchaudio \
      --index-url "https://download.pytorch.org/whl/cpu"
  fi
}

install_ml_packages() {
  echo -e "${BLUE}Installing common ML packages...${NC}"
  # IMPORTANT: use plain pip (not uv) and NO -U. uv's holistic --upgrade
  # re-resolution against PyPI will replace a hardware-specific torch (e.g. the
  # gfx1151 ROCm build) with a generic CUDA wheel, breaking the GPU. pip installs
  # incrementally and leaves an already-satisfied torch untouched.
  "$ENV_PYTHON" -m pip install \
    numpy pandas matplotlib scikit-learn jupyter tensorboard accelerate
}

# ----------------------------------------------------------------------------
# run
# ----------------------------------------------------------------------------

ensure_project_gitignore

platform=$(detect_platform)
gpu=$(detect_gpu)

echo -e "${BLUE}Detected platform: ${platform}${NC}"
echo -e "${BLUE}Detected gpu type: ${gpu}${NC}"
echo

create_env
resolve_env_python
install_base_tools
install_pytorch "$gpu" "$platform"
install_ml_packages

echo
echo -e "${GREEN}=== Done ===${NC}"
echo
cat <<EOF
Activate:

  conda activate ${ENV_NAME}

Verify:

  python -c "import torch; print('torch', torch.__version__); print('cuda:', torch.cuda.is_available()); print('hip:', getattr(torch.version,'hip',None))"

Notes:
  - Env/pkgs locations come from ~/.condarc (linux-dotfiles → ~/conda/envs).
  - For Strix Halo (gfx1151) deep setup (GTT memory, flash-SDPA, kernel checks),
    see the strix-halo-setup skill at ~/Projects/amdtest.
  - Setup log: ${LOG_FILE}
EOF

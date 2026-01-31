#!/usr/bin/env bash
set -euo pipefail

# Conda-first universal ML environment setup.
# Run this from inside your project directory.
# Creates a NAMED conda env (default: ml-<project-dir>) and installs PyTorch
# with hardware-aware defaults.

PYTHON_VERSION_DEFAULT="3.12"
PROJECT_DIR="$(pwd)"
PROJECT_NAME="$(basename "$PROJECT_DIR")"

PYTHON_VERSION="${PYTHON_VERSION:-$PYTHON_VERSION_DEFAULT}"
ENV_NAME="${ENV_NAME:-ml-${PROJECT_NAME}}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/setup-${PROJECT_NAME}-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${BLUE}=== ML Env Setup (conda-first) ===${NC}"
echo "Project: $PROJECT_DIR"
echo "Env name: $ENV_NAME"
echo "Python: $PYTHON_VERSION"
echo "Log: $LOG_FILE"
echo

ensure_conda() {
  if command -v conda >/dev/null 2>&1; then
    return 0
  fi

  if [ -f "$HOME/miniforge/etc/profile.d/conda.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/miniforge/etc/profile.d/conda.sh"
  elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/miniconda3/etc/profile.d/conda.sh"
  fi

  command -v conda >/dev/null 2>&1
}

if ! ensure_conda; then
  echo -e "${RED}Error: conda is not available in this shell.${NC}"
  echo "Install Miniforge/Miniconda and ensure conda.sh is sourced."
  echo "Tip: linux-dotfiles sets a portable ~/.condarc so envs go under ~/conda/envs." 
  exit 1
fi

echo -e "${GREEN}✓ conda found: $(conda --version)${NC}"

if command -v uv >/dev/null 2>&1; then
  echo -e "${GREEN}✓ uv found: $(uv --version)${NC}"
else
  echo -e "${YELLOW}⚠️  uv not found (ok). Using pip inside the conda env.${NC}"
fi

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

  if command -v rocminfo &>/dev/null; then
    echo "amd"
    return
  fi

  if command -v rocm-smi &>/dev/null; then
    echo "amd"
    return
  fi

  if command -v lspci &>/dev/null && lspci | grep -i "VGA.*AMD" &>/dev/null; then
    echo "amd"
    return
  fi

  echo "cpu"
}

get_nvidia_compute_cap() {
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

run_pip() {
  # Prefer uv pip if available for speed.
  if command -v uv >/dev/null 2>&1; then
    conda run -n "$ENV_NAME" uv pip "$@"
  else
    conda run -n "$ENV_NAME" python -m pip "$@"
  fi
}

create_env() {
  if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo -e "${YELLOW}⚠️  Env already exists: $ENV_NAME${NC}"
    return 0
  fi

  echo -e "${BLUE}Creating conda env: ${ENV_NAME}${NC}"
  conda create -y -n "$ENV_NAME" "python=${PYTHON_VERSION}" pip
}

install_base_tools() {
  echo -e "${BLUE}Installing base python tooling...${NC}"
  run_pip install -U pip setuptools wheel
}

install_pytorch() {
  local gpu_type="$1"
  local platform="$2"

  local index_url=""
  local pkgs=("torch==2.10.0" "torchvision==0.25.0" "torchaudio==2.10.0")

  if [ "$gpu_type" = "nvidia" ]; then
    read -r cc_major cc_minor < <(get_nvidia_compute_cap)
    echo -e "${YELLOW}NVIDIA GPU detected (compute capability: ${cc_major}.${cc_minor})${NC}"

    if [ "$cc_major" -ge 12 ]; then
      echo -e "${YELLOW}⚠️  Blackwell-ish GPU detected. Options:${NC}"
      echo "  1) CUDA 13.0 index (experimental)"
      echo "  2) nightly (cu128 nightly)"
      echo "  3) CUDA 12.8 index (default)"
      read -r -p "Choice [1-3]: " choice
      case "$choice" in
        1) index_url="https://download.pytorch.org/whl/cu130" ;;
        2) pkgs=("torch" "torchvision" "torchaudio" "--pre"); index_url="https://download.pytorch.org/whl/nightly/cu128" ;;
        *) index_url="https://download.pytorch.org/whl/cu128" ;;
      esac
    else
      index_url="https://download.pytorch.org/whl/cu128"
    fi

    if [ "$platform" = "wsl" ]; then
      echo -e "${BLUE}ℹ️  WSL2 detected: use Windows NVIDIA driver (do not install linux driver in WSL).${NC}"
    fi

    echo -e "${BLUE}Installing PyTorch (pip) from index: ${index_url}${NC}"
    run_pip install "${pkgs[@]}" --index-url "$index_url"

  elif [ "$gpu_type" = "amd" ]; then
    local gfx
    gfx=$(get_amd_gfx_arch)
    echo -e "${YELLOW}AMD GPU detected${NC}"
    [ -n "$gfx" ] && echo -e "${YELLOW}Detected arch: ${gfx}${NC}"

    if [ "$gfx" = "gfx1151" ]; then
      echo
      echo -e "${BLUE}Strix Halo (gfx1151) notes:${NC}"
      echo "- Vanilla PyTorch wheels often fail; gfx1151-specific wheels are required."
      echo "- For flash SDPA (AOTriton), see build kit:"
      echo "  https://github.com/ianbarber/strix-halo-flashattn-build"
      echo
      echo "Choose PyTorch wheel index for gfx1151:"
      echo "  1) ROCm 7 stable (recommended): https://repo.amd.com/rocm/whl/gfx1151/"
      echo "  2) ROCm nightlies (fallback):   https://rocm.nightlies.amd.com/v2/gfx1151/"
      echo "  3) CPU-only"
      read -r -p "Choice [1-3]: " choice
      case "$choice" in
        1) index_url="https://repo.amd.com/rocm/whl/gfx1151/" ;;
        2) index_url="https://rocm.nightlies.amd.com/v2/gfx1151/" ;;
        *) gpu_type="cpu" ;;
      esac

      if [ "$gpu_type" != "cpu" ]; then
        echo -e "${BLUE}Installing PyTorch (pip) from index: ${index_url}${NC}"
        run_pip install "${pkgs[@]}" --index-url "$index_url"
      fi
    else
      # generic AMD/ROCm path
      index_url="https://download.pytorch.org/whl/rocm6.2"
      echo -e "${BLUE}Installing PyTorch (ROCm) from index: ${index_url}${NC}"
      run_pip install "${pkgs[@]}" --index-url "$index_url"
    fi
  fi

  if [ "$gpu_type" = "cpu" ]; then
    echo -e "${BLUE}Installing CPU-only PyTorch (pip)${NC}"
    run_pip install "${pkgs[@]}" --index-url "https://download.pytorch.org/whl/cpu"
  fi
}

install_ml_packages() {
  echo -e "${BLUE}Installing common ML packages...${NC}"
  run_pip install -U numpy pandas matplotlib scikit-learn jupyter tensorboard accelerate
}

platform=$(detect_platform)
gpu=$(detect_gpu)

echo -e "${BLUE}Detected platform: ${platform}${NC}"
echo -e "${BLUE}Detected gpu type: ${gpu}${NC}"
echo

create_env
install_base_tools
install_pytorch "$gpu" "$platform"
install_ml_packages

echo
echo -e "${GREEN}Done.${NC}"
echo
cat <<EOF
Next:

  conda activate ${ENV_NAME}

Verify:

  python -c "import torch; print(torch.__version__); print('cuda:', torch.cuda.is_available()); print('hip:', getattr(torch.version,'hip',None))"

Note: envs/pkgs locations come from ~/.condarc (linux-dotfiles).
EOF

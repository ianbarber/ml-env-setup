---
name: ml-env
description: Set up ML environments with PyTorch and auto-detect hardware. Use this when creating new ML projects, setting up PyTorch, or troubleshooting GPU/environment issues. Guides you through creating isolated conda environments with hardware-specific PyTorch builds (NVIDIA/AMD/CPU).
allowed-tools: Read, Bash, WebFetch, WebSearch
activation-precedence: high
---

# ML Environment Setup & Troubleshooting

This skill creates **isolated conda environments** with PyTorch. It auto-detects
your hardware (NVIDIA GPU, AMD GPU, or CPU) and installs the right PyTorch build,
then validates it works. Designed for consistency across a small fleet of Linux
boxes (NVIDIA, AMD Strix Halo, CPU).

## Creating a New ML Project

When you ask me to set up a new ML project, I:

1. Create the project directory.
2. Run hardware detection.
3. Run `setup-universal.sh` from the project dir — it creates a **named conda
   env** (`ml-<project>` by default), installs PyTorch with the correct backend,
   and common ML libraries. It also drops a `.gitignore` if one is missing.
4. Run `validate.sh` to confirm the GPU/backend works.
5. Show you how to activate and use it.

```bash
# From the new project directory:
bash ~/.claude/skills/ml-env/scripts/setup-universal.sh
bash ~/.claude/skills/ml-env/scripts/validate.sh
```

The setup script (`~/.claude/skills/ml-env/scripts/setup-universal.sh`):
- Detects your GPU (NVIDIA via `nvidia-smi`, AMD via `rocminfo`, else CPU).
- Creates a conda env `ml-<basename-of-cwd>` (Python 3.13 by default).
- Installs **PyTorch 2.13.0** with the right backend (CUDA `cu130`, ROCm `7.2`,
  or CPU); gfx1151 uses its own verified tracks.
- Installs: numpy, pandas, matplotlib, scikit-learn, jupyter, tensorboard,
  accelerate.
- Writes a setup log into the project dir: `setup-<project>-<timestamp>.log`.

## Using Your Environment

```bash
conda activate ml-<project>
python -c "import torch; print(torch.__version__); print('cuda:', torch.cuda.is_available())"
```

Env names default to `ml-<project-dir>`. Override at setup time:

```bash
ENV_NAME=myexp PYTHON_VERSION=3.12 bash ~/.claude/skills/ml-env/scripts/setup-universal.sh
```

**Where envs live:** `~/.condarc` (linux-dotfiles) points new envs at
`~/conda/envs`. Existing envs under `~/miniforge/envs` are unaffected.

## Version Defaults (verified 2026-07-14; prefer latest)

Overridable via environment variables — see the header of `setup-universal.sh`.

| Component | Default | Notes |
|---|---|---|
| Python | **3.13** | latest mature; all backends ship cp313. Use 3.12 only if a package needs it. |
| PyTorch | **2.13.0** | latest stable on cu130 / rocm7.2 |
| CUDA (NVIDIA) | **cu130** | CUDA 13.0. cu132 (13.2) exists but needs newer drivers; the fleet boxes are driver 580.x = max CUDA 13.0. |
| ROCm (generic AMD) | **rocm7.2** | latest on pytorch.org |
| gfx1151 (Strix Halo) | **TheRock nightly** | see below — official wheels do not work |

## Hardware-Specific Guidance

### NVIDIA GPUs (Ampere / Ada / Blackwell)
- CUDA `cu130` wheels. Driver 580+ required (CUDA 13.0).
- **Blackwell (RTX 5090, GB10, sm_120+):** natively supported by PyTorch 2.13 on
  cu130 — no special handling. (If an older PyTorch is forced, fall back to
  nightly: `--pre --index-url …/whl/nightly/cu130`.)
- **WSL2:** use the Windows NVIDIA driver only — do **not** install a Linux
  driver inside WSL.

### AMD RDNA (RX 6000/7000) and other non-gfx1151
- ROCm `rocm7.2` wheels. User must be in `render` and `video` groups:
  `sudo usermod -aG render,video $USER && newgrp render`.

### AMD Strix Halo (gfx1151)
**⚠️ Official PyTorch wheels fail** with `HIP error: invalid device function`.
The setup script offers two verified tracks:

1. **TheRock multi-arch nightly (default)** — latest PyTorch (~2.12), clean index:
   `pip install --index-url https://rocm.nightlies.amd.com/whl-multi-arch/
   "torch[device-gfx1151]" "torchvision[device-gfx1151]" torchaudio`
2. **AMD supported stable (ROCm 7.2.1)** — AMD-validated, torch 2.9.1; **cp312
   only** (recreate the env with `PYTHON_VERSION=3.12`). Wheels from
   `repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/`.

**Environment variables:** do **not** set `HSA_ENABLE_SDMA`,
`PYTORCH_HIP_ALLOC_CONF`, etc. globally — they cause subtle bugs. Set them only
per-process for a reproduced issue. (Matches the strix-halo-setup skill v2.0.0.)

For GTT memory (`amd-ttm`), flash-SDPA source builds, and kernel-backport
checks, use the dedicated **strix-halo-setup** skill (`~/Projects/amdtest`).
ml-env intentionally does not duplicate that. See
[TROUBLESHOOTING.md](TROUBLESHOOTING.md#strix-halo-gfx1151) for the summary.

### CPU-only
Works everywhere. Good for development/testing before scaling to GPU.

## Validating an Existing Environment

```bash
cd ~/your-ml-project   # any dir; the env name defaults to ml-<this-dir>
ENV_NAME=ml-<project> bash ~/.claude/skills/ml-env/scripts/validate.sh
```

Checks Python, PyTorch, backend (CUDA/ROCm), device name + compute capability /
gfx arch, and runs a real matmul.

## Troubleshooting (quick)

**GPU not detected:**
```bash
nvidia-smi                     # NVIDIA driver present?
rocminfo | grep gfx            # AMD arch (expect gfx1151 on Strix Halo)
groups | grep -E "render|video"  # AMD requires these
```

**PyTorch installed but `cuda.is_available()` is False:**
- NVIDIA: driver too old for the CUDA wheel (cu130 needs driver 580+ / CUDA 13.0).
  Check `nvidia-smi`'s "CUDA Version" line, or drop to `cu128`.
- AMD: check groups and that you installed a gfx-appropriate build (not vanilla).

**CUDA out of memory / slow training:** these are general PyTorch questions — see
the PyTorch docs (mixed precision, gradient checkpointing, `torch.cuda.empty_cache`).
This skill focuses on environment setup, not training tuning.

For hardware-specific issues, WSL2, and full Strix Halo setup, see
[TROUBLESHOOTING.md](TROUBLESHOOTING.md). For updating packages, see
[UPDATE.md](UPDATE.md).

## Scripts in This Skill

Both live in `~/.claude/skills/ml-env/scripts/`:
- **setup-universal.sh** — detect hardware, create conda env, install PyTorch + libs.
- **validate.sh** — verify an existing env and exercise the GPU/CPU.

## When to Use This Skill

- Creating a new ML project / PyTorch environment.
- Setting up or repairing PyTorch with GPU support.
- Troubleshooting GPU/CUDA/ROCm detection.
- Updating or maintaining an ML environment.
- Hardware-specific questions (NVIDIA, AMD, Strix Halo).

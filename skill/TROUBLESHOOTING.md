# Troubleshooting Guide

Environment/GPU issues for ml-env conda environments. This focuses on **setup
and hardware** problems. For general PyTorch questions (OOM, mixed precision,
training loops) see the official PyTorch docs — this skill does not duplicate
that material.

## Setup / install issues

### `conda is not available in this shell`
The script sources `conda.sh` from `~/miniforge`, `~/miniconda3`, `~/anaconda3`,
or `~/miniforge3`. If conda lives elsewhere:
```bash
# Confirm conda's base, then ensure it's sourced in your shell profile:
conda info --base            # e.g. /home/you/miniforge
# Add to ~/.bashrc:  source <that>/etc/profile.d/conda.sh
```

### Package install fails / downloads stall
```bash
df -h                 # disk space?
ping pypi.org         # connectivity
"$ENV_PYTHON" -m pip cache purge   # clear pip cache
```
For AMD gfx1151, the wheel indexes are large (~2 GB) — be patient.

### Wrong Python version
The env is created with `PYTHON_VERSION` (default 3.13). To use another:
```bash
ENV_NAME=ml-foo PYTHON_VERSION=3.12 bash ~/.claude/skills/ml-env/scripts/setup-universal.sh
```
Note: the gfx1151 **AMD-stable** track ships cp312 wheels only (needs 3.12);
the TheRock-nightly default track works with 3.13.

## GPU not detected

```bash
nvidia-smi                      # NVIDIA driver present?
rocminfo | grep gfx             # AMD arch present?
groups | grep -E "render|video" # AMD needs these
source <conda-base>/etc/profile.d/conda.sh && conda activate ml-<project>
python -c "import torch; print(torch.cuda.is_available())"
```

### NVIDIA GPU present but `cuda.is_available()` is False
Most often a **driver/CUDA mismatch**:
```bash
nvidia-smi                       # check the "CUDA Version: X.Y" line = driver's max
python -c "import torch; print(torch.version.cuda)"   # what torch was built for
```
The default `cu130` wheels (CUDA 13.0) need driver 580+ (CUDA 13.0). If your
driver reports an older max, reinstall from an older index:
```bash
ENV_PYTHON="$(conda run -n ml-<project> which python)"
"$ENV_PYTHON" -m pip install --force-reinstall --no-deps \
  torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
```

### AMD GPU present but not detected
```bash
groups | grep -E "render|video"
sudo usermod -aG render,video $USER && newgrp render   # then re-login
ls -l /dev/dri/                  # render node should be accessible
rocminfo | grep gfx              # confirm arch
```

## CUDA / ROCm version mismatches

```bash
python -c "import torch; print('cuda', torch.version.cuda); print('hip', getattr(torch.version,'hip',None))"
```
Reinstall PyTorch from the right index (activate the env first):
```bash
# NVIDIA (cu130 default; cu128 fallback for older drivers)
python -m pip install --force-reinstall --no-deps torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cu130

# generic AMD (rocm7.2)
python -m pip install --force-reinstall --no-deps torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/rocm7.2

# CPU only
python -m pip install --force-reinstall --no-deps torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cpu
```

## Strix Halo (gfx1151) specific setup

**Official PyTorch wheels do not work** with gfx1151 — you get
`HIP error: invalid device function`. Two verified install tracks:

### Track 1 — TheRock multi-arch nightly (default, latest PyTorch)
```bash
python -m pip install --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ \
  "torch[device-gfx1151]" "torchvision[device-gfx1151]" torchaudio
```
Resolves to the newest PyTorch (~2.12) backed by ROCm dev packages; works with
Python 3.13. Do **not** add `--pre` (the index already serves ROCm dev builds).

### Track 2 — AMD supported stable (ROCm 7.2.1, AMD-validated, torch 2.9.1)
cp312 wheels — requires a Python 3.12 env. Direct URLs from AMD's manylinux index:
```bash
python -m pip install \
  https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torch-2.9.1%2Brocm7.2.1.lw.gitff65f5bc-cp312-cp312-linux_x86_64.whl \
  https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchvision-0.24.0%2Brocm7.2.1.gitb919bd0c-cp312-cp312-linux_x86_64.whl \
  https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/torchaudio-2.9.0%2Brocm7.2.1.gite3c6ee2b-cp312-cp312-linux_x86_64.whl \
  https://repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/triton-3.5.1%2Brocm7.2.1.gita272dfa8-cp312-cp312-linux_x86_64.whl
```

### Deprecated indexes (do not use)
- `repo.amd.com/rocm/whl/gfx1151/` — serves only torch 2.9.1, was mislabeled
  "stable". Use Track 1 or 2 instead.
- `rocm.nightlies.amd.com/v2/gfx1151/` — retired per-family index; historical
  repro only.

### Environment variables — do NOT set globally
`HSA_ENABLE_SDMA=0`, `PYTORCH_HIP_ALLOC_CONF`, `HSA_OVERRIDE_GFX_VERSION`, etc.
cause subtle bugs when set as baseline. Set them only **per-process** for a
reproduced issue. The one opt-in is `TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1`
(to test the flash-SDPA backend), set before importing torch.

### Memory, flash-SDPA, kernels — use the dedicated skill
Deep Strix Halo concerns are owned by the **strix-halo-setup** skill
(`~/Projects/amdtest`, https://github.com/ianbarber/strix-halo-skills), not
duplicated here:
- **GTT memory** — use `amd-debug-tools` (`pipx install amd-debug-tools`,
  `amd-ttm --set <GiB>`). VRAM and GTT are overlapping views of unified memory;
  never sum them.
- **Flash-SDPA** — stock wheels run SDPA in math mode; a source build is needed
  for flash attention. See https://github.com/ianbarber/strix-halo-flashattn-build.
- **Kernel** — Strix Halo KFD fixes are in Linux 6.18.4+ upstream, or AMD OEM
  kernels ≥ 6.14.0-1018-oem.

Quick checks:
```bash
rocminfo | grep gfx1151
groups | grep -E "render|video"
uname -r
```

## WSL2

WSL2 uses the **Windows** NVIDIA driver — do **not** install a Linux driver
inside WSL.
```bash
nvidia-smi          # from within WSL2 — should show the GPU
# If it fails: from Windows PowerShell,  wsl --shutdown ; wsl
```

## Performance / "is the GPU actually being used?"

```bash
# In one terminal while training:
nvidia-smi -l 1      # or: rocm-smi -d 1
```
```python
import torch
print(next(model.parameters()).device)   # should be cuda:0
print(data.device)
```
Slow training / OOM are general PyTorch topics — see the PyTorch performance
docs (mixed precision, `torch.compile`, gradient checkpointing, DataLoader
workers, `pin_memory`).

## Diagnostics bundle (before asking for help)

```bash
uname -a
nvidia-smi || (rocminfo | grep -iE "gfx|version" | head)
source <conda-base>/etc/profile.d/conda.sh && conda activate ml-<project>
python -c "import torch; print(torch.__version__, torch.version.cuda, getattr(torch.version,'hip',None))"
python -m pip freeze | grep -iE "torch|rocm"
bash ~/.claude/skills/ml-env/scripts/validate.sh
```
Share: hardware (GPU model), platform (Ubuntu/WSL2), driver version, and the
output of `validate.sh`. Issues: https://github.com/ianbarber/ml-env-setup/issues

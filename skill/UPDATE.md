# Updating and Version Management

How to inspect, update, and recreate ml-env conda environments.

## Check current versions

```bash
conda activate ml-<project>
python -c "import torch; print('torch', torch.__version__); print('cuda', torch.version.cuda); print('hip', getattr(torch.version,'hip',None))"
python -m pip list
python -m pip list --outdated
```

## Update PyTorch

Latest stable lives at https://pytorch.org/get-started/locally/ . ml-env defaults
(PyTorch 2.13.0, cu132 / rocm7.2) are overridable vars at the top of
`setup-universal.sh`.

```bash
conda activate ml-<project>

# NVIDIA (cu132 default)
python -m pip install --upgrade --index-url https://download.pytorch.org/whl/cu132 \
  torch torchvision torchaudio

# generic AMD (rocm7.2)
python -m pip install --upgrade --index-url https://download.pytorch.org/whl/rocm7.2 \
  torch torchvision torchaudio
```

### Strix Halo (gfx1151)
```bash
# Track 1 — TheRock nightly (default): latest torch
python -m pip install --upgrade --index-url https://rocm.nightlies.amd.com/whl-multi-arch/ \
  "torch[device-gfx1151]" "torchvision[device-gfx1151]" torchaudio

# Track 2 — AMD supported stable (ROCm 7.2.1, torch 2.9.1, needs Python 3.12):
#   reinstall the pinned wheels from repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/
#   (exact URLs in TROUBLESHOOTING.md → "Strix Halo")
```
Avoid the retired `…/v2/gfx1151/` and the `repo.amd.com` gfx1151 indexes.

> **Do not** run `pip install -U accelerate` (or `uv pip install -U <pkgs>`) after
> a gfx1151 install — uv's holistic upgrade can replace the ROCm torch with a CUDA
> wheel. Install other packages with plain `pip install` (no `-U`).

## Update other packages

```bash
conda activate ml-<project>
python -m pip install --upgrade <package-name>
```

## Driver / CUDA check (NVIDIA)

```bash
nvidia-smi                      # "CUDA Version: X.Y" = driver's max supported
python -c "import torch; print(torch.cuda.get_device_capability(0))"
```
The `cu132` wheels need driver 580+ (CUDA 13.2 runs on 580.x via minor-version
compat). If `nvidia-smi` reports an older max, use the `cu130` or `cu128` index.

## Recreate the environment from scratch

```bash
conda env remove -n ml-<project>
cd /path/to/project
bash ~/.claude/skills/ml-env/scripts/setup-universal.sh
```
Or override defaults: `ENV_NAME=... PYTHON_VERSION=3.12 TORCH_VERSION=2.13.0
CUDA_INDEX=cu130 bash setup-universal.sh`.

## Export / reproduce an environment

```bash
conda activate ml-<project>
python -m pip freeze > requirements-lock.txt
python -m torch.utils.collect_env > collect-env.txt     # full diagnostics

# Recreate elsewhere:
conda create -y -n ml-<project> python=3.13
conda activate ml-<project>
python -m pip install -r requirements-lock.txt
```

## Update uv (when present)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

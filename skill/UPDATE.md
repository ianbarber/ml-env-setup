# Updating and Version Management

## Checking Current Versions

### Check PyTorch and CUDA versions

Activate the environment and run:

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
python -c 'import torch; print(f"PyTorch: {torch.__version__}"); print(f"CUDA: {torch.version.cuda}")'
```

### Check all installed packages

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip list
```

### Check for outdated packages

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip list --outdated
```

## Updating PyTorch

### Check for newer PyTorch versions

Visit: https://pytorch.org/get-started/locally/

Or check available versions:

```bash
uv pip index versions torch --index-url https://download.pytorch.org/whl/cu130
```

### Update to a specific version

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip install torch==2.X.Y torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 --upgrade
```

### Update to the latest compatible version

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 --upgrade
```

## Updating Other Packages

### Update a specific package

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip install --upgrade package-name
```

### Update all packages (use with caution)

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip list --outdated | tail -n +3 | awk '{print $1}' | xargs -n1 uv pip install --upgrade
```

Note: This may break compatibility. Consider testing in a separate environment first.

## Updating the Setup Script

When you want to update the setup script for new projects:

1. Edit `/home/ianbarber/ml-env-setup/setup.sh`
2. Update version numbers in the script
3. Test the script in a temporary directory:

```bash
cd /tmp
mkdir test-ml-setup
cp /home/ianbarber/ml-env-setup/setup.sh test-ml-setup/
cd test-ml-setup
./setup.sh
```

4. If successful, your updated script is ready to copy to new projects

## Checking NVIDIA Driver and CUDA Toolkit

### Check NVIDIA driver version

```bash
nvidia-smi
```

### Check CUDA toolkit version

```bash
nvcc --version
```

### Verify GPU compute capability

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
python -c 'import torch; print(f"GPU Compute Capability: {torch.cuda.get_device_capability(0)}")'
```

Expected output for RTX 5090: `(12, 0)` indicating SM120

## Recreating the Environment from Scratch

If something goes wrong, you can recreate the environment:

```bash
cd /home/ianbarber/ml-env-setup
rm -rf ml-env
./setup.sh
```

## Exporting Environment Configuration

To create a reproducible environment specification:

```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
uv pip freeze > requirements.txt
```

To recreate from requirements:

```bash
uv venv new-ml-env --python 3.14
source new-ml-env/bin/activate
uv pip install -r requirements.txt
```

## Updating uv itself

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Or if installed via pip:

```bash
pip install --upgrade uv
```

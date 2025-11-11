# Universal ML Environment Setup

A portable setup script for creating a standardized ML environment with PyTorch 2.9.0. **Automatically detects your hardware** and installs the appropriate PyTorch build for:

- **NVIDIA GPUs**: RTX 3090, 4060, 5090, GB200, etc. (CUDA 12.8/13.0)
- **AMD GPUs**: RDNA, Strix Halo (ROCm 6.2/7.9)
- **CPU-only**: No GPU systems
- **WSL2**: Windows Subsystem for Linux support

## Quick Start

### First Time Setup (Recommended - Universal Script)

1. Install uv if you haven't already:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

2. Run the universal setup script (auto-detects your hardware):
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
```

3. Verify the installation:
```bash
./validate.sh
```

4. Activate the environment:
```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
```

### Using in New Projects

#### Option 1: Use Shared Environment (Recommended)

Use the ml-env-setup environment from all projects:

1. Generate a Claude Code skill for your project:
```bash
/home/ianbarber/ml-env-setup/generate-skill.sh /path/to/your/project
```

This creates `.claude/skills/ml-env/` in your project directory.

2. Activate the environment when working on your project:
```bash
source /home/ianbarber/ml-env-setup/ml-env/bin/activate
```

3. Claude Code will automatically use the skill when you ask about the environment, running code, or PyTorch.

**Benefits**: Shares one environment across all projects, saving disk space and installation time.

#### Option 2: Project-Specific Environment

Create an isolated environment for each project:

1. Copy the setup scripts to your project:
```bash
cp /home/ianbarber/ml-env-setup/setup-universal.sh /path/to/your/project/
cp /home/ianbarber/ml-env-setup/validate.sh /path/to/your/project/
cp /home/ianbarber/ml-env-setup/generate-skill.sh /path/to/your/project/
```

2. Run the setup in your project directory:
```bash
cd /path/to/your/project
./setup-universal.sh  # Creates ml-env/ and .claude/skills/ml-env/ in project
```

The script will automatically detect your hardware and install the appropriate PyTorch build, then create a Claude Code skill with the correct environment path.

## What Gets Installed

- **Python 3.14**
- **PyTorch 2.9.0** with appropriate backend:
  - NVIDIA (Ampere/Ada/Blackwell): CUDA 12.8 or 13.0
  - AMD (RDNA/Strix Halo): ROCm 6.2
  - CPU-only for systems without GPU
- **torchvision and torchaudio**
- **Essential ML libraries**: numpy, pandas, matplotlib, scikit-learn
- **Development tools**: jupyter, ipython, tqdm, tensorboard

## Directory Structure

```
ml-env-setup/
├── setup-universal.sh     # Universal setup script (auto-detects hardware)
├── validate.sh            # Environment validation script
├── generate-skill.sh      # Generates Claude Code skill for projects
├── README.md              # This file
├── UPDATE.md              # Version checking and update procedures
├── HARDWARE.md            # Machine-specific setup guides
└── STRIX_HALO.md          # Strix Halo (gfx1151) quick reference
```

## Documentation

- **setup-universal.sh**: Universal setup script that auto-detects your hardware (RECOMMENDED)
- **validate.sh**: Validates your installation and tests GPU/CPU computation
- **generate-skill.sh**: Generates Claude Code skill with environment information
- **README.md**: General setup guide (this file)
- **UPDATE.md**: Comprehensive guide for checking versions and updating packages
- **HARDWARE.md**: Detailed machine-specific guides for all your systems
- **STRIX_HALO.md**: Quick reference for Strix Halo (gfx1151) setup

## Supported Hardware

### NVIDIA GPUs
- **RTX 50 series** (5090, 5080, etc.) - Blackwell (sm_120)
  - PyTorch 2.9.0 with CUDA 13.0 (experimental) or nightly builds
- **RTX 40 series** (4090, 4080, 4060, etc.) - Ada Lovelace (sm_89)
  - PyTorch 2.9.0 with CUDA 12.8 (stable)
- **RTX 30 series** (3090, 3080, etc.) - Ampere (sm_86)
  - PyTorch 2.9.0 with CUDA 12.8 (stable)
- **GB200, B200** - Blackwell data center GPUs (sm_120)
  - PyTorch nightly builds recommended

### AMD GPUs
- **Strix Halo** (Ryzen AI Max, gfx1151)
  - ROCm 6.4.4+ nightlies (recommended) or ROCm 7.9 stable
  - ⚠️ Requires special gfx1151 builds - see [STRIX_HALO.md](STRIX_HALO.md)
- **RDNA 3** (RX 7000 series)
  - ROCm 6.2
- **RDNA 2** (RX 6000 series)
  - ROCm 6.2

### Platform Support
- **Native Linux**: Ubuntu 20.04+, other distributions
- **WSL2**: Windows 11 with WSL2 enabled (uses Windows NVIDIA drivers)

## Verifying Installation

Run the validation script to test your installation:

```bash
./validate.sh
```

This will:
- Check Python and PyTorch versions
- Detect CUDA/ROCm/CPU backend
- Display GPU information
- Run computation tests
- Show performance metrics

Example output for NVIDIA GPU:
```
=== ML Environment Validation ===
✓ Environment directory found
1. Python Version: Python 3.14.0
2. UV Version: uv 0.x.x
3. PyTorch Installation: PyTorch: 2.9.0
✓ PyTorch installed
✓ CUDA Backend Detected
5. CUDA Information
CUDA Version: 12.8
GPU Count: 1
6. GPU Details
GPU 0:
  Name: NVIDIA GeForce RTX 3090
  Compute Capability: (8, 6)
  SM Version: sm_86
  Memory: 24.00 GB
✓ GPU computation successful
```

## Updating

See [UPDATE.md](UPDATE.md) for detailed instructions on:
- Checking current versions
- Updating PyTorch and other packages
- Updating the setup script itself
- Troubleshooting

## Requirements

### Minimum Requirements
- Linux system (Ubuntu 20.04+) or WSL2 on Windows 11
- uv package manager
- Bash shell

### For NVIDIA GPU Support
- NVIDIA drivers (version 520+ for CUDA 12.x, 550+ for CUDA 13.0)
- CUDA toolkit (optional, PyTorch includes necessary CUDA libraries)
- **WSL2 users**: Windows NVIDIA driver only (do NOT install Linux driver)

### For AMD GPU Support
- ROCm drivers (6.2 or newer)
- ROCm-compatible AMD GPU

## Notes

- The environment uses **Python 3.14** (preview support in PyTorch 2.9.0)
- For production, consider Python 3.11 or 3.12 for more mature support
- The universal script automatically detects your hardware and chooses the best configuration
- Each project can have its own isolated environment
- The setup uses uv for faster package installation compared to pip

## Troubleshooting

### CUDA not available after installation (NVIDIA)

1. Check NVIDIA driver:
```bash
nvidia-smi
```

2. Verify PyTorch detects CUDA:
```bash
source ml-env/bin/activate
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
```

3. Check driver version (520+ for CUDA 12.x, 550+ for CUDA 13.0)

4. Recreate the environment:
```bash
rm -rf ml-env
./setup-universal.sh
```

### WSL2-Specific Issues

**Problem**: CUDA not available in WSL2

**Solution**:
1. Ensure Windows NVIDIA driver is up to date
2. **Do NOT install** Linux NVIDIA drivers inside WSL2
3. Check WSL2 can see GPU: `nvidia-smi` (should work from WSL2)
4. Reinstall PyTorch: `./setup-universal.sh`

### RTX 5090 / Blackwell GPU Issues

**Problem**: PyTorch not recognizing RTX 5090 or poor performance

**Solution**:
1. Try PyTorch nightly build (option 2 during setup)
2. Check for PTX JIT fallback warnings
3. Consider building PyTorch from source with sm_120 support
4. Monitor PyTorch GitHub for stable sm_120 support updates

### AMD GPU / Strix Halo Issues

**Problem**: ROCm not working or GPU not detected

**Solution**:
1. Verify ROCm installation: `rocm-smi` or `rocminfo`
2. Check AMD GPU compatibility with ROCm
3. **For Strix Halo (gfx1151)**: See [STRIX_HALO.md](STRIX_HALO.md) for detailed troubleshooting
   - Must use special gfx1151 builds (official PyTorch doesn't work!)
   - Requires `render` and `video` group membership
   - ROCm 6.4.4+ nightlies recommended
4. Install ROCm drivers if not already installed

### Package conflicts

If you encounter package conflicts:
1. Remove the environment: `rm -rf ml-env`
2. Clear uv cache: `uv cache clean`
3. Run setup again: `./setup-universal.sh`

### Python 3.14 not available

If uv cannot find Python 3.14:
1. Edit `setup-universal.sh` and change `PYTHON_VERSION="3.14"` to `"3.12"` or `"3.11"`
2. Run the setup again

## License

Free to use and modify for your ML projects.

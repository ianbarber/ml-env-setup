# Universal ML Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub](https://img.shields.io/github/stars/ianbarber/ml-env-setup?style=social)](https://github.com/ianbarber/ml-env-setup)

A portable setup script for creating a standardized ML environment with PyTorch 2.9.0. **Automatically detects your hardware** and installs the appropriate PyTorch build for:

- **NVIDIA GPUs**: RTX 3090, 4060, 5090, GB200, etc. (CUDA 12.8/13.0)
- **AMD GPUs**: RDNA, Strix Halo (ROCm 6.2/7.9)
- **CPU-only**: No GPU systems
- **WSL2**: Windows Subsystem for Linux support

## Features

- 🔍 **Auto-detection**: Identifies your hardware and installs the right PyTorch build
- 🚀 **Fast setup**: Uses `uv` for faster package installation
- 🎯 **Single command**: One script creates complete project with ML environment
- 🤖 **Claude Code integration**: Auto-generated skill for environment help
- 📝 **Comprehensive docs**: Hardware-specific guides for all supported GPUs
- ✅ **Validation**: Built-in testing to verify your installation
- 🔄 **WSL2 support**: Works seamlessly on Windows Subsystem for Linux
- 📦 **Project-ready**: Includes .gitignore, documentation, and validation tools

## Quick Start

### Prerequisites

Install uv if you haven't already:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### Clone This Repository

```bash
git clone https://github.com/ianbarber/ml-env-setup.git
cd ml-env-setup
```

### Create Your ML Project

**One simple command:**

```bash
# Create a new project in current directory
./setup.sh

# Or create a new project with a specific name
./setup.sh my-ml-project

# Or create at a specific path
./setup.sh /path/to/my-project
```

**That's it!** The script will:
- ✅ Create the project directory
- ✅ Detect your hardware (NVIDIA/AMD/CPU)
- ✅ Install PyTorch with the right backend
- ✅ Set up ML libraries (numpy, pandas, scikit-learn, etc.)
- ✅ Create a Claude Code skill for environment help
- ✅ Add a .gitignore
- ✅ Validate the installation

### Start Coding

```bash
cd my-ml-project
source ml-env/bin/activate
python your_script.py
```

### Example: Complete Workflow

```bash
# Clone the setup repo
git clone https://github.com/ianbarber/ml-env-setup.git

# Create your project
cd ml-env-setup
./setup.sh my-awesome-ai-project

# Start working
cd my-awesome-ai-project
source ml-env/bin/activate

# Verify everything works
./validate.sh

# Start coding!
python train_model.py
```

## How It Works

The `setup.sh` script:

1. **Creates Project Directory**: Makes the directory if it doesn't exist
2. **Copies Setup Scripts**: Includes setup-universal.sh, validate.sh, and generate-skill.sh
3. **Copies Documentation**: Adds README, HARDWARE guide, and Strix Halo docs
4. **Creates .gitignore**: Ignores common ML files (models, data, logs, etc.)
5. **Detects Hardware**: Runs setup-universal.sh which:
   - Checks for NVIDIA GPUs (via `nvidia-smi`)
   - Checks for AMD GPUs (via `rocminfo`)
   - Falls back to CPU if no GPU found
   - Detects WSL2 environment
6. **Installs PyTorch**: Chooses the right build:
   - NVIDIA: CUDA 12.8 or 13.0
   - AMD: ROCm 6.4.4+ or 7.9 (for Strix Halo: gfx1151 builds)
   - CPU: CPU-only build
7. **Installs ML Libraries**: numpy, pandas, scikit-learn, jupyter, etc.
8. **Creates Claude Skill**: Generates `.claude/skills/ml-env/` for environment help
9. **Validates Installation**: Runs tests to verify everything works
10. **Offers Git Init**: Optionally initializes git with good commit message

Each project gets its own isolated environment, so you can have different PyTorch versions or packages per project.

## What Gets Installed

- **Python 3.14**
- **PyTorch 2.9.0** with appropriate backend:
  - NVIDIA (Ampere/Ada/Blackwell): CUDA 12.8 or 13.0
  - AMD (RDNA/Strix Halo): ROCm 6.2
  - CPU-only for systems without GPU
- **torchvision and torchaudio**
- **Essential ML libraries**: numpy, pandas, matplotlib, scikit-learn
- **Development tools**: jupyter, ipython, tqdm, tensorboard

## What You Get

After running `./setup.sh`, your project will have:

```
your-project/
├── ml-env/                  # Python virtual environment with PyTorch
├── .claude/
│   └── skills/
│       └── ml-env/          # Claude Code skill (auto-activated)
├── setup-universal.sh       # The setup script (for reference)
├── validate.sh              # Test your installation
├── generate-skill.sh        # Skill generator (for reference)
├── .gitignore               # Ignores ml-env, logs, etc.
├── README.md                # Documentation
├── TROUBLESHOOTING.md       # Common issues and solutions
└── UPDATE.md                # Maintenance and updating guide
```

## Documentation in This Repo

- **setup.sh**: Main entry point - creates new ML projects
- **setup-universal.sh**: Core setup logic (auto-detects hardware)
- **validate.sh**: Validates installation and tests GPU/CPU
- **generate-skill.sh**: Creates Claude Code skill
- **README.md**: This guide
- **TROUBLESHOOTING.md**: Common issues, solutions, and hardware-specific notes
- **UPDATE.md**: Updating and maintenance guide
- **CLAUDE_WEBHOOK.md**: CI/CD setup guide

## Supported Hardware

### NVIDIA GPUs
- **RTX 50 series** (5090, 5080, etc.) - Blackwell consumer (sm_120+)
  - PyTorch 2.9.0 with CUDA 13.0 (experimental) or nightly builds
- **RTX 40 series** (4090, 4080, 4060, etc.) - Ada Lovelace (sm_89)
  - PyTorch 2.9.0 with CUDA 12.8 (stable)
- **RTX 30 series** (3090, 3080, etc.) - Ampere (sm_86)
  - PyTorch 2.9.0 with CUDA 12.8 (stable)
- **B100, GB200, B200** - Blackwell data center (sm_100)
  - Limited support, may need specific builds

### AMD GPUs
- **Strix Halo** (Ryzen AI Max, gfx1151)
  - ROCm 6.4.4+ nightlies (recommended) or ROCm 7.9 stable
  - ⚠️ Requires special gfx1151 builds - see [TROUBLESHOOTING.md](TROUBLESHOOTING.md#strix-halo-gfx1151-specific-setup)
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
3. **For Strix Halo (gfx1151)**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#strix-halo-gfx1151-specific-setup) for detailed instructions
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

## Contributing

Contributions are welcome! This project uses Claude Code for automated code reviews.

### How to Contribute

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/ml-env-setup.git`
3. Create a test project: `./setup.sh test-project`
4. Test your changes in the test project
5. Create a feature branch: `git checkout -b feature/amazing-feature`
6. Make your changes to the setup scripts
7. Test again: `./setup.sh test-project-2`
8. Commit your changes: `git commit -m "Add amazing feature"`
9. Push to your fork: `git push origin feature/amazing-feature`
10. Open a Pull Request

**Testing Checklist**:
- [ ] Runs on your hardware type (NVIDIA/AMD/CPU)
- [ ] Creates project directory correctly
- [ ] Installs PyTorch successfully
- [ ] Generates Claude skill
- [ ] Validation passes (`./validate.sh` in created project)
- [ ] Documentation is updated if needed

### Claude Code Reviews

This repository uses automated Claude Code reviews for PRs. The bot will:
- Review your code for security issues
- Check for bugs and code quality
- Suggest improvements

You can also mention `@claude` in PR comments for specific questions.

See [CLAUDE_WEBHOOK.md](CLAUDE_WEBHOOK.md) for setup details.

## Support

- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: See the guides in this repo:
  - [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and hardware-specific setup
  - [UPDATE.md](UPDATE.md) - Updating and maintenance
  - [CLAUDE_WEBHOOK.md](CLAUDE_WEBHOOK.md) - CI/CD setup

## Credits

Created with assistance from Claude Code.

Special thanks to:
- AMD ROCm team and community for Strix Halo support
- @scottt and @jammm for gfx1151 PyTorch builds
- uv team for fast Python package management

## License

MIT License - see [LICENSE](LICENSE) file for details.

Free to use and modify for your ML projects.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Universal ML Environment Setup - A portable Bash-based setup script that creates standardized PyTorch ML environments with automatic hardware detection. Supports NVIDIA GPUs (CUDA), AMD GPUs (ROCm), CPU-only systems, and WSL2.

The project creates **isolated project environments** outside the setup repository - it's not meant to be run inside this repo, but rather used to bootstrap new ML projects elsewhere.

## Architecture

### Three-Layer Design

1. **setup.sh** (Entry Point - ~242 lines)
   - Single command interface: `./setup.sh project-path`
   - Creates project directory structure
   - Copies setup scripts and documentation to target project
   - Creates .gitignore for ML projects
   - Delegates to setup-universal.sh for environment creation
   - Offers optional git initialization with good commit message

2. **setup-universal.sh** (Core Logic - ~428 lines)
   - Hardware detection: NVIDIA/AMD/CPU/WSL2 (setup-universal.sh:37-67)
   - GPU-specific installation logic:
     - NVIDIA: Detects compute capability (sm_86, sm_89, sm_120+) and chooses CUDA version (setup-universal.sh:69-84, 148-193)
     - AMD: Detects architecture (gfx1151 for Strix Halo) with special handling (setup-universal.sh:86-135, 195-280)
     - CPU: Fallback for systems without GPU (setup-universal.sh:282-286)
   - Creates Python 3.14 virtual environment using `uv`
   - Installs PyTorch with hardware-appropriate index URLs
   - Installs ML libraries: numpy, pandas, scikit-learn, jupyter, etc.
   - Generates Claude Code skill (setup-universal.sh:401-402)

3. **validate.sh** (Testing - ~188 lines)
   - Verifies environment installation
   - Tests GPU/CPU computation
   - Reports hardware details and performance metrics
   - Provides diagnostic information for troubleshooting

### Supporting Scripts

- **generate-skill.sh**: Creates `.claude/skills/ml-env/SKILL.md` in target projects
  - Auto-activated skill for environment questions
  - Contains activation commands, package info, troubleshooting
  - Embeds actual environment path from setup

## Common Development Tasks

### Testing the Setup Scripts

```bash
# Test in a temporary location (NEVER run setup inside this repo)
./setup.sh /tmp/test-ml-project
cd /tmp/test-ml-project
source ml-env/bin/activate
./validate.sh
```

### Testing Different Hardware Paths

The hardware detection logic has multiple branches:
- Mock `nvidia-smi` for NVIDIA testing
- Mock `rocminfo` for AMD testing
- Mock `/proc/version` for WSL2 testing
- See setup-universal.sh:37-67 for detection logic

### Modifying PyTorch Installation Logic

PyTorch installation URLs are in setup-universal.sh:138-290:
- NVIDIA: Lines 148-193 (compute capability detection, CUDA version selection)
- AMD Standard: Lines 264-279 (RDNA 2/3)
- AMD Strix Halo: Lines 209-263 (special gfx1151 handling with multiple build options)
- CPU: Lines 282-286

**Critical**: Strix Halo (gfx1151) requires non-standard PyTorch builds from AMD community repos. Official wheels don't work.

### Adding New Hardware Support

1. Add detection logic in `detect_gpu()` (setup-universal.sh:45-67)
2. Add info gathering in `get_nvidia_info()` or `get_amd_info()` (setup-universal.sh:69-108)
3. Add installation case in `determine_pytorch_install()` (setup-universal.sh:138-290)
4. Update README.md supported hardware section
5. Add troubleshooting section to TROUBLESHOOTING.md

### Modifying the Claude Skill

The skill template is in generate-skill.sh:24-210. Key sections:
- Environment activation commands (dynamically embedded path)
- Common ML tasks and code examples
- Troubleshooting patterns
- References to project documentation

## Key Design Patterns

### Hardware Detection Flow

```
detect_platform() → detect_gpu() → get_[nvidia|amd]_info() → determine_pytorch_install()
```

Each function returns parseable output that's consumed by the next layer.

### User Interaction Points

The scripts prompt users at key decision points:
- Python version availability (setup-universal.sh:347)
- PyTorch build selection for Blackwell GPUs (setup-universal.sh:160-171)
- ROCm build selection for Strix Halo (setup-universal.sh:218-258)
- Environment recreation if exists (setup.sh:100-106)
- Git initialization (setup.sh:218-238)

### Error Handling Strategy

- `set -e`: Fail fast on errors
- Logging: All output goes to timestamped log file (setup-universal.sh:21)
- Color-coded output: RED for errors, YELLOW for warnings, GREEN for success
- Permission checks for AMD GPUs before installation (setup-universal.sh:111-135)
- Validation script provides comprehensive diagnostics

## Special Cases to Remember

### Strix Halo (gfx1151) AMD GPUs

**Most complex hardware path** - requires special attention:
- Official PyTorch wheels don't work at all
- Must use AMD community nightlies or stable gfx1151 builds
- Three different repo options with trade-offs (setup-universal.sh:218-258)
- Requires user in `render` and `video` groups (checked at setup-universal.sh:111-135)
- GTT memory configuration for large models (documented but not automated)
- See TROUBLESHOOTING.md:262-380 for comprehensive guide

### WSL2

- Uses Windows GPU drivers, not Linux drivers (critical distinction)
- Detection via `/proc/version` grep for "microsoft" (setup-universal.sh:38-43)
- User instructions emphasize NOT installing Linux drivers
- Same PyTorch builds as Linux NVIDIA, but different troubleshooting

### Blackwell Architecture (RTX 5090, sm_120+)

- Experimental support in PyTorch 2.9.0
- Three installation options: CUDA 13.0 experimental, nightly builds, or CUDA 12.8 with PTX fallback
- May need future updates as PyTorch support matures

## Documentation Structure

- **README.md**: User-facing quick start and feature overview
- **TROUBLESHOOTING.md**: Comprehensive hardware-specific debugging guide (775 lines)
- **UPDATE.md**: Package maintenance and version updating
- **CLAUDE_WEBHOOK.md**: CI/CD setup for automated code reviews

## Testing Commands

```bash
# Run validation after setup
cd created-project/
source ml-env/bin/activate
./validate.sh

# Test GPU detection
python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"

# Test basic computation
python -c "import torch; x = torch.randn(100, 100, device='cuda' if torch.cuda.is_available() else 'cpu'); print(x.shape)"

# Check installed versions
uv pip list | grep torch
```

## When Making Changes

1. **Setup Scripts**: Test on at least one hardware type (or use temporary projects)
2. **Documentation**: Update both README.md and TROUBLESHOOTING.md
3. **Validation**: Ensure validate.sh covers new scenarios
4. **Skills**: Update generate-skill.sh if environment usage changes
5. **Git Messages**: Follow the style in recent commits (see git log)

## Dependencies

- **uv**: Modern Python package manager (required, checked at setup-universal.sh:28-32)
- **bash**: All scripts are Bash (not sh/dash compatible due to bash-isms)
- **nvidia-smi**: NVIDIA GPU detection and monitoring
- **rocminfo/rocm-smi**: AMD GPU detection and monitoring
- **lspci**: Fallback GPU detection
- **Python 3.14**: Default (configurable via PYTHON_VERSION variable)

## File Organization Philosophy

**This repo is a template/tool, not a project workspace**:
- Users clone this repo once
- They run `setup.sh` to create separate project directories elsewhere
- Each project gets its own isolated environment + copies of setup scripts
- This enables multiple projects with different PyTorch versions/configurations
- The ml-env-setup repo itself should remain clean (no ml-env/ directories here)

## Color Coding in Scripts

Scripts use ANSI colors consistently:
- `RED='\033[0;31m'`: Errors
- `GREEN='\033[0;32m'`: Success messages
- `YELLOW='\033[1;33m'`: Warnings
- `BLUE='\033[0;34m'`: Info/headers
- `CYAN='\033[0;36m'`: Banners
- `NC='\033[0m'`: Reset (no color)

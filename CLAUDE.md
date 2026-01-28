# ML Environment Skill - Repository Guidelines

This repository hosts a Claude Code skill for setting up isolated ML environments with PyTorch. It's designed to be distributed via symlink or copy to `~/.claude/skills/ml-env/`.

## Repository Purpose

**Primary Goal:** Provide an interactive Claude Code skill that guides users through creating PyTorch ML environments with automatic hardware detection (NVIDIA GPU, AMD GPU, or CPU).

**Key Philosophy:**
- Users install the skill, not the entire repo
- Claude interacts with users to set up projects (no setup.sh command needed)
- Each project gets only what it needs: `ml-env/` + `.gitignore`
- All guidance, troubleshooting, and scripts live in the skill

**Distribution:**
- GitHub repo as the canonical source
- Users symlink `skill/` to `~/.claude/skills/ml-env/` or copy it
- Users can update anytime with `git pull`

## Repository Structure

```
ml-env-setup/
├── README.md              # Installation and quick start (for GitHub)
├── CLAUDE.md              # This file - development guidelines
├── LICENSE                # MIT license
├── .github/               # GitHub workflows (CI/CD if added)
└── skill/                 # THE SKILL (what gets symlinked/copied)
    ├── SKILL.md           # Entry point - interactive setup guide
    ├── TROUBLESHOOTING.md # Hardware-specific setup details
    ├── UPDATE.md          # Package maintenance guide
    └── scripts/
        ├── setup-universal.sh  # Hardware detection + PyTorch install
        └── validate.sh         # Environment validation
```

**Key point:** Only the `skill/` directory is distributed to users. The README explains how to get it.

## Skill Design

### SKILL.md
- **Entry point** for Claude interaction
- ~400 lines maximum (keep focused)
- Guides users through project creation
- References detailed docs (TROUBLESHOOTING.md, UPDATE.md) for specific issues
- Includes common workflows and best practices
- Lists what scripts are available and where

### TROUBLESHOOTING.md
- Detailed hardware-specific guidance
- Special attention to Strix Halo (complex case)
- Linked from SKILL.md (not loaded until needed)
- Can be longer/comprehensive

### UPDATE.md
- How to update PyTorch versions
- Dependency pinning strategies
- Linked from SKILL.md

### Scripts (setup-universal.sh, validate.sh)
- Executable bash scripts in `skill/scripts/`
- Referenced from SKILL.md with full paths: `~/.claude/skills/ml-env/scripts/script.sh`
- Can be run by Claude or directly by users
- Main logic lives here; skill provides context/guidance

## Development Guidelines

### When Modifying Scripts

**Hardware Detection (setup-universal.sh lines 37-67):**
- Add detection logic for new GPU types
- Test with mock detection before release
- Document in TROUBLESHOOTING.md

**PyTorch Installation (setup-universal.sh lines 139-292):**
- Update index URLs when PyTorch/CUDA/ROCm versions change
- Strix Halo (gfx1151) requires special attention - see reference to strix-halo-skills repo
- Update CLAUDE.md version notes when changing major versions

**Validation (validate.sh):**
- Add tests for new hardware types
- Ensure comprehensive GPU memory/info reporting
- Test with different PyTorch versions

### When Updating Documentation

**SKILL.md:**
- Keep under 400 lines
- Focus on interactive guidance and common questions
- Reference TROUBLESHOOTING.md for detailed issues
- Update "Current Versions" section when packages update
- Add new workflows to "Common Workflows" section

**TROUBLESHOOTING.md:**
- Organized by hardware type
- Include step-by-step solutions
- Link to official docs where relevant
- Update with user-reported issues

**UPDATE.md:**
- Document version update procedures
- Include version compatibility matrix
- Update when new PyTorch/Python versions are supported

**README.md:**
- Explains installation (symlink vs copy)
- Quick start for new users
- Links to skill for detailed guidance

### Version Management

Keep CLAUDE.md, SKILL.md, and setup-universal.sh in sync:

```
# Current as of 2026-01-28
PyTorch: 2.10.0
Python: 3.13 (default), 3.12, 3.11 (avoid 3.14 - ML package compatibility issues)
CUDA: 12.8, 13.0
ROCm: 6.2 (RDNA), 7.x preferred for Strix Halo (6.4.4+ as fallback)
```

**Note**: The setup-universal.sh script defaults to Python 3.13. Users can change to 3.12 or 3.11 if needed, but Python 3.14 should be avoided due to ML package compatibility issues.

Update these files when new versions release:
1. setup-universal.sh - update download URLs and version strings
2. SKILL.md - update "Current Versions" section
3. CLAUDE.md - update version notes here
4. README.md - update supported versions

### Special Cases to Remember

**Strix Halo (gfx1151) AMD GPU:**
- Most complex hardware path
- Official PyTorch wheels completely incompatible
- **ROCm 7 stable (recommended)**: `https://repo.amd.com/rocm/whl/gfx1151/`
- **ROCm 6.4.4+ nightlies (fallback)**: `https://rocm.nightlies.amd.com/v2/gfx1151/`
- ROCm 7 provides ~2.5x performance improvement (~31 TFLOPS BF16 vs ~12 TFLOPS)
- User must be in render/video groups
- GTT memory configuration needed for 30B+ models
- Reference project: ~/Projects/amdtest
- See also: https://github.com/ianbarber/strix-halo-skills

**Blackwell GPU (RTX 5090):**
- sm_120+ is experimental in PyTorch 2.9.0
- Three options offered during setup:
  1. PyTorch 2.9.0 with CUDA 13.0 (experimental)
  2. PyTorch nightly (cutting edge)
  3. PyTorch 2.9.0 with CUDA 12.8 + PTX JIT fallback
- May need future updates as support matures

**WSL2:**
- Uses Windows NVIDIA drivers (NOT Linux drivers)
- Setup script detects via `/proc/version`
- Warn users NOT to install Linux NVIDIA driver
- Otherwise same as Linux setup

**Python 3.14 Compatibility:**
- Some ML packages have compatibility issues with 3.14
- Default to 3.13, fall back to 3.12 if needed
- Update once ecosystem catches up

## Common Development Tasks

### Testing Hardware Paths

```bash
# Test in a temporary location
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

# Manually run setup script
bash ~/.claude/skills/ml-env/scripts/setup-universal.sh

# Validate
bash ~/.claude/skills/ml-env/scripts/validate.sh

# Clean up
rm -rf "$TEST_DIR"
```

### Adding New Hardware Support

1. Update `setup-universal.sh:detect_gpu()` (lines 45-67)
2. Update `setup-universal.sh:get_[nvidia|amd]_info()` (lines 69-108)
3. Update `setup-universal.sh:determine_pytorch_install()` (lines 139-292)
4. Add troubleshooting section to TROUBLESHOOTING.md
5. Update SKILL.md "Hardware-Specific Guidance" section
6. Test in README.md "Contributing" checklist

### Modifying Claude Skill Behavior

Edit SKILL.md frontmatter:
```yaml
---
name: ml-env
description: Updated description here
allowed-tools: Read, Bash, WebFetch  # Tools Claude can use
activation-precedence: high  # Load skill in context early
---
```

## Contribution Checklist

When modifying this repo, ensure:

- [ ] **Hardware detection** works for your system
- [ ] **PyTorch installation** succeeds and GPU detected (if applicable)
- [ ] **validate.sh** passes without errors
- [ ] **SKILL.md** is updated if changing user-facing behavior
- [ ] **TROUBLESHOOTING.md** is updated if adding/fixing hardware issues
- [ ] **README.md** is accurate for new users
- [ ] **CLAUDE.md** (this file) is updated with new guidelines
- [ ] Skill stays focused (~400 lines max)
- [ ] All scripts are executable and tested
- [ ] Documentation uses current version numbers

## CI/CD and Automation

Currently: Manual. Future enhancements could include:
- GitHub Actions to test setup on matrix of hardware
- Automated skill validation
- PyPI version monitoring for updates
- ROCm/CUDA index URL monitoring

## File Organization Philosophy

**Single-purpose repo:** This repo is just a skill distribution source.
- Not a project workspace
- Not a general ML setup tool
- Specific to Claude Code skill distribution

**What lives here:**
- The complete skill directory that users install
- Installation/usage instructions (README.md)
- Development guidelines (CLAUDE.md)

**What doesn't live here:**
- Individual user projects (they use the skill to create their own)
- Copies of setup scripts (they're in skill/scripts/)

## Support and Communication

**For users:**
- GitHub issues for bug reports
- GitHub discussions for questions
- Direct Claude Code interaction once skill is installed

**For contributors:**
- Refer to CLAUDE.md (this file) for guidelines
- See README.md "Contributing" section
- Test thoroughly before submitting

## License

MIT License - Anyone can use, modify, and distribute this skill freely.

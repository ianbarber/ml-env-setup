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

**Hardware Detection (`detect_gpu()` / `get_nvidia_compute_cap()` / `get_amd_gfx_arch()` in setup-universal.sh):**
- Add detection logic for new GPU types
- Test with mock detection before release
- Document in TROUBLESHOOTING.md

**PyTorch Installation (`install_pytorch()` / `install_gfx1151()`):**
- Version defaults live in the `*_DEFAULT` vars at the top of the script.
- gfx1151 uses its own verified tracks (see Special Cases below); do NOT route it
  through the global `TORCH_VERSION`/`CUDA_INDEX` pins.
- `install_ml_packages()` MUST use plain `pip` (not `uv`) with no `-U` — uv's
  holistic upgrade re-resolves against PyPI and replaces a hardware-specific
  torch (e.g. gfx1151 ROCm) with a CUDA wheel. (Bug found + fixed 2026-07-14.)

**Validation (validate.sh):**
- The probe is written to a temp file and run via `conda run python <file>`.
  Do NOT use `conda run ... python - <<HEREDOC` — conda run does not reliably
  forward stdin, so the heredoc silently produces no output.

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
# Current as of 2026-07-14 (prefer latest, verified against live indexes + fleet)
PyTorch: 2.13.0           # NVIDIA/CPU/generic-AMD; gfx1151 nightly resolves ~2.12
Python: 3.13 (default; gfx1151 AMD-stable alt track needs 3.12)
CUDA:   cu130 (CUDA 13.0)  # cu132 exists but fleet NVIDIA boxes are driver 580.x = max CUDA 13.0
ROCm:   rocm7.2 (generic AMD); gfx1151 → TheRock whl-multi-arch nightly (default) or AMD stable 7.2.1
```

All of the above are overridable vars at the top of `setup-universal.sh`
(`PYTHON_VERSION`, `TORCH_VERSION`, `CUDA_INDEX`, `ROCM_INDEX`) — bumps are one
line. The gfx1151 path ignores those and uses its own verified tracks in
`install_gfx1151()`.

Update these files when new versions release:
1. setup-universal.sh - update the `*_DEFAULT` vars + gfx1151 pinned URLs
2. SKILL.md - update "Version Defaults" table
3. CLAUDE.md - update version notes here
4. README.md - update version table

### Special Cases to Remember

**Strix Halo (gfx1151) AMD GPU:**
- Most complex hardware path. Official PyTorch wheels are incompatible
  (`HIP error: invalid device function`).
- **Default track — TheRock multi-arch nightly**: `--index-url
  https://rocm.nightlies.amd.com/whl-multi-arch/ "torch[device-gfx1151]"`
  (latest ~2.12, clean PEP 503 index, no hardcoded-URL rot).
- **Alt track — AMD supported stable (ROCm 7.2.1, torch 2.9.1)**: pinned cp312
  wheels from `repo.radeon.com/rocm/manylinux/rocm-rel-7.2.1/`. **Needs Python 3.12.**
- **Deprecated** (do not use): `repo.amd.com/rocm/whl/gfx1151/` (serves only
  torch 2.9.1, was mislabeled stable) and `…/v2/gfx1151/` (retired).
- **Env vars**: do NOT set `HSA_ENABLE_SDMA`/`PYTORCH_HIP_ALLOC_CONF` globally
  (matches strix-halo-setup v2.0.0). Only opt-in: `TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1`.
- User must be in `render`/`video` groups; GTT/flash-SDPA/kernel work is owned by
  the **strix-halo-setup** skill (`~/Projects/amdtest`,
  https://github.com/ianbarber/strix-halo-skills); flash build kit:
  https://github.com/ianbarber/strix-halo-flashattn-build.

**Blackwell GPU (RTX 5090 / GB10, sm_120+):**
- Natively supported by PyTorch 2.13.0 on cu130 — no special menu or "experimental"
  handling. Just the standard NVIDIA/cu130 path.
- Fleet boxes (steed GB10, leejr RTX 5090) are driver 580.x (max CUDA 13.0), so
  cu130 is correct; cu132 would need newer drivers.

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

1. Update `setup-universal.sh:detect_gpu()`
2. Update `setup-universal.sh:get_nvidia_compute_cap()` / `get_amd_gfx_arch()`
3. Update `setup-universal.sh:install_pytorch()` (and `install_gfx1151()` if gfx-related)
4. Add troubleshooting section to TROUBLESHOOTING.md
5. Update SKILL.md "Hardware-Specific Guidance" section
6. Test against the README.md "Contributing" checklist

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

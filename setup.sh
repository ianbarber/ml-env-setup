#!/bin/bash
set -e

# Universal ML Environment Setup - Single Entry Point
# Creates a new ML project with PyTorch environment

VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Print banner
echo -e "${CYAN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║      Universal ML Environment Setup                      ║
║      PyTorch + CUDA/ROCm Auto-Detection                 ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"
echo "Version: $VERSION"
echo ""

# Show usage
show_usage() {
    cat << EOF
Usage: $0 [PROJECT_PATH]

Creates a new ML project with auto-configured PyTorch environment.

Arguments:
  PROJECT_PATH    Path to create project (default: current directory)
                  Can be relative or absolute path

Examples:
  $0                    # Setup in current directory
  $0 my-ml-project      # Create ./my-ml-project
  $0 /path/to/project   # Create at specific path

What this does:
  1. Creates project directory (if needed)
  2. Detects your hardware (NVIDIA/AMD/CPU)
  3. Installs PyTorch with appropriate backend
  4. Sets up ML libraries (numpy, pandas, etc.)
  5. Creates Claude Code skill for environment
  6. Validates installation

Supported Hardware:
  - NVIDIA: RTX 3090, 4060, 5090, GB200, etc.
  - AMD: Strix Halo (gfx1151), RDNA 2/3
  - CPU-only systems
  - WSL2 on Windows

For more info: https://github.com/ianbarber/ml-env-setup
EOF
}

# Check for help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Determine project path
if [ -z "$1" ]; then
    PROJECT_PATH="."
    PROJECT_NAME=$(basename "$(pwd)")
else
    PROJECT_PATH="$1"
    PROJECT_NAME=$(basename "$PROJECT_PATH")
fi

# Convert to absolute path
PROJECT_PATH=$(realpath -m "$PROJECT_PATH")

echo -e "${BLUE}Project: ${GREEN}$PROJECT_NAME${NC}"
echo -e "${BLUE}Location: ${GREEN}$PROJECT_PATH${NC}"
echo ""

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_PATH" ]; then
    echo -e "${YELLOW}Creating project directory...${NC}"
    mkdir -p "$PROJECT_PATH"
    echo -e "${GREEN}✓ Created $PROJECT_PATH${NC}"
else
    echo -e "${GREEN}✓ Project directory exists${NC}"
fi

# Check if already set up
if [ -f "$PROJECT_PATH/ml-env/bin/activate" ]; then
    echo -e "${YELLOW}⚠️  ML environment already exists in this project${NC}"
    read -p "Recreate environment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting..."
        exit 0
    fi
    rm -rf "$PROJECT_PATH/ml-env"
fi

# Copy setup scripts to project
echo ""
echo -e "${BLUE}Copying setup scripts...${NC}"
cp "$SCRIPT_DIR/setup-universal.sh" "$PROJECT_PATH/"
cp "$SCRIPT_DIR/validate.sh" "$PROJECT_PATH/"
cp "$SCRIPT_DIR/generate-skill.sh" "$PROJECT_PATH/"

# Copy documentation
echo -e "${BLUE}Copying documentation...${NC}"
cp "$SCRIPT_DIR/README.md" "$PROJECT_PATH/"
cp "$SCRIPT_DIR/TROUBLESHOOTING.md" "$PROJECT_PATH/"
cp "$SCRIPT_DIR/UPDATE.md" "$PROJECT_PATH/"

# Create .gitignore if it doesn't exist
if [ ! -f "$PROJECT_PATH/.gitignore" ]; then
    echo -e "${BLUE}Creating .gitignore...${NC}"
    cat > "$PROJECT_PATH/.gitignore" << 'GITIGNORE'
# ML Environment
ml-env/
.venv/
venv/

# Python
__pycache__/
*.py[cod]
*.pyc
.Python

# Jupyter
.ipynb_checkpoints/

# Data
data/
*.csv
*.h5
*.pkl

# Models
models/
checkpoints/
*.pth
*.pt
*.ckpt

# Logs
logs/
*.log
wandb/
tensorboard/

# IDE
.vscode/
.idea/
*.swp

# OS
.DS_Store

# Environment
.env
GITIGNORE
    echo -e "${GREEN}✓ Created .gitignore${NC}"
fi

echo -e "${GREEN}✓ Setup scripts copied${NC}"
echo ""

# Run the universal setup in the project directory
cd "$PROJECT_PATH"

echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Running hardware detection and PyTorch installation     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

./setup-universal.sh

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    Setup Complete!                       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}✅ Project created: ${BLUE}$PROJECT_PATH${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo "  1. Navigate to your project:"
echo -e "     ${BLUE}cd $PROJECT_PATH${NC}"
echo ""
echo "  2. Activate the environment:"
echo -e "     ${GREEN}Conda users:${NC}  ${BLUE}source ml-env/activate-safe.sh${NC}"
echo -e "     ${GREEN}Others:${NC}       ${BLUE}source ml-env/bin/activate${NC}"
echo ""
echo "  3. Verify installation:"
echo -e "     ${BLUE}./validate.sh${NC}"
echo ""
echo "  4. Start coding!"
echo -e "     ${BLUE}python your_script.py${NC}"
echo ""

# Show Claude skill info
if [ -d "$PROJECT_PATH/.claude/skills/ml-env" ]; then
    echo -e "${CYAN}🤖 Claude Code Integration${NC}"
    echo "   A skill has been created at .claude/skills/ml-env/"
    echo "   Claude will automatically help with environment questions"
    echo ""
fi

# Offer to initialize git
if [ ! -d "$PROJECT_PATH/.git" ] && command -v git &> /dev/null; then
    echo -e "${YELLOW}Initialize git repository? (y/n)${NC}"
    read -p "> " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$PROJECT_PATH"
        git init
        git add .
        git commit -m "Initial commit: ML environment setup

- PyTorch with auto-detected hardware support
- ML libraries: numpy, pandas, scikit-learn, etc.
- Claude Code skill for environment assistance
- Validation and documentation included

🤖 Created with ml-env-setup
https://github.com/ianbarber/ml-env-setup"
        echo -e "${GREEN}✓ Git repository initialized${NC}"
        echo ""
    fi
fi

echo -e "${GREEN}Happy coding! 🚀${NC}"
echo ""

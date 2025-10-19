#!/bin/bash
set -Eeuo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Repository information
REPO_OWNER="vgmello"
REPO_NAME="sdlc"
REPO_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}"
RAW_URL="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/main"

# Function to print section headers
print_section_header() {
    local title="$1"
    echo ""
    echo "================================================"
    echo "  $title"
    echo "================================================"
    echo ""
}

# Function to check if running on POSIX OS
check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}✓ POSIX OS detected${NC}"
        return 0
    else
        echo -e "${RED}✗ This installer currently supports POSIX systems only (Linux/macOS)${NC}"
        echo -e "${YELLOW}Your OS: $OSTYPE${NC}"
        exit 1
    fi
}

# Function to check if curl is installed
check_curl() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is not installed.${NC}"
        echo "Please install curl first:"
        echo "  - Ubuntu/Debian: sudo apt-get install curl"
        echo "  - CentOS/RHEL: sudo yum install curl"
        echo "  - macOS: brew install curl"
        exit 1
    fi
    echo -e "${GREEN}✓ curl found${NC}"
}

# Function to check if git is installed
check_git() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed.${NC}"
        echo "Please install git first:"
        echo "  - Ubuntu/Debian: sudo apt-get install git"
        echo "  - CentOS/RHEL: sudo yum install git"
        echo "  - macOS: brew install git"
        exit 1
    fi
    echo -e "${GREEN}✓ git found${NC}"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo -e "${RED}Error: Not in a git repository!${NC}"
        echo "Please run this installer from the root of your git repository."
        exit 1
    fi
    echo -e "${GREEN}✓ Git repository detected${NC}"
}

# Function to download a file
download_file() {
    local url="$1"
    local output="$2"

    echo -e "${BLUE}  Downloading: $(basename "$output")${NC}"

    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$output")"

    # Download the file
    if curl -fsSL "$url" -o "$output"; then
        echo -e "${GREEN}  ✓ Downloaded: $output${NC}"
        return 0
    else
        echo -e "${RED}  ✗ Failed to download: $url${NC}"
        return 1
    fi
}

# Function to make file executable
make_executable() {
    local file="$1"
    chmod +x "$file"
    echo -e "${GREEN}  ✓ Made executable: $file${NC}"
}

# Main installation function
install_sdlc() {
    print_section_header "SDLC Installation"

    # Check prerequisites
    echo -e "${BLUE}Checking prerequisites...${NC}"
    check_os
    check_curl
    check_git
    check_git_repo
    echo ""

    # Confirm installation
    echo -e "${YELLOW}This will install SDLC (Claude Code Infrastructure) in this repository.${NC}"
    echo -e "${YELLOW}The following will be downloaded:${NC}"
    echo "  - .github/workflows/claude.yml"
    echo "  - .github/workflows/cleanup-claude-state-workflow.yml"
    echo "  - .github/sdlc/claude-system-prompt.md"
    echo "  - .github/sdlc/README.md"
    echo "  - .github/sdlc/github-runner/Dockerfile"
    echo "  - .github/sdlc/github-runner/entrypoint.sh"
    echo "  - .github/sdlc/github-runner/docker-compose.yml"
    echo "  - .github/sdlc/github-runner/.gitignore"
    echo "  - .github/sdlc/claude-code-runner/Dockerfile"
    echo "  - .github/sdlc/claude-code-runner/entrypoint.sh"
    echo "  - sdlc.sh"
    echo ""

    read -p "Continue with installation? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 0
    fi

    print_section_header "Downloading Files"

    # Download all required files
    local files=(
        ".github/workflows/claude.yml"
        ".github/workflows/cleanup-claude-state-workflow.yml"
        ".github/sdlc/claude-system-prompt.md"
        ".github/sdlc/README.md"
        ".github/sdlc/github-runner/Dockerfile"
        ".github/sdlc/github-runner/entrypoint.sh"
        ".github/sdlc/github-runner/docker-compose.yml"
        ".github/sdlc/github-runner/.gitignore"
        ".github/sdlc/claude-code-runner/Dockerfile"
        ".github/sdlc/claude-code-runner/entrypoint.sh"
        "sdlc.sh"
    )

    local failed=0
    for file in "${files[@]}"; do
        if ! download_file "${RAW_URL}/${file}" "$file"; then
            failed=$((failed + 1))
        fi
    done

    if [ $failed -gt 0 ]; then
        echo ""
        echo -e "${RED}✗ Failed to download $failed file(s)${NC}"
        echo -e "${YELLOW}Some files may not have been installed correctly.${NC}"
        exit 1
    fi

    # Make sdlc.sh and entrypoint.sh files executable
    echo ""
    echo -e "${BLUE}Setting permissions...${NC}"
    make_executable "sdlc.sh"
    make_executable ".github/sdlc/github-runner/entrypoint.sh"
    make_executable ".github/sdlc/claude-code-runner/entrypoint.sh"

    print_section_header "Installation Complete!"

    echo -e "${GREEN}✓ SDLC has been successfully installed!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo ""
    echo "1. Run the setup script to configure your runners:"
    echo -e "   ${YELLOW}./sdlc.sh${NC}"
    echo ""
    echo "2. Configure GitHub Secrets (in repository settings):"
    echo "   Go to: Settings → Secrets and variables → Actions"
    echo "   - CLAUDE_CODE_OAUTH_TOKEN: Your Claude Code OAuth token"
    echo ""
    echo "3. Start using Claude by mentioning @claude in issues or pull requests!"
    echo ""
    echo "For more information, see:"
    echo "  - ${REPO_URL}"
    echo "  - .github/sdlc/README.md"
    echo ""
    echo "================================================"
}

# Run the installation
install_sdlc

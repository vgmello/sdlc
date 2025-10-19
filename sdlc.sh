#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_RUNNER_DIR="$SCRIPT_DIR/.github/sdlc/github-runner"
CLAUDE_CODE_RUNNER_DIR="$SCRIPT_DIR/.github/sdlc/claude-code-runner"

# Project name from git repository (folder name)
PROJECT_NAME="$(basename "$SCRIPT_DIR")"

# Default runner prefix from hostname
DEFAULT_RUNNER_PREFIX="$(hostname)"

# SDLC version and update info
SDLC_VERSION="1.0.0"
SDLC_REPO="vgmello/sdlc"
SDLC_UPDATE_CHECK_FILE="$SCRIPT_DIR/.sdlc_last_update_check"

# Function to display usage
show_usage() {
    echo "Usage: $0 [--stop|--update|--version]"
    echo ""
    echo "Options:"
    echo "  --stop       Stop the GitHub Actions runners"
    echo "  --update     Check for and install updates"
    echo "  --version    Display version information"
    echo "  (no flag)    Start the GitHub Actions runners (docker-compose up -d)"
    echo "               If .env file doesn't exist, setup will run automatically"
    echo ""
    echo "Examples:"
    echo "  $0            # Start runners (runs setup if needed)"
    echo "  $0 --stop     # Stop runners"
    echo "  $0 --update   # Check for updates"
    echo "  $0 --version  # Show version"
    exit 0
}

# Function to check for updates
check_for_updates() {
    # Only check if curl is available
    if ! command -v curl &> /dev/null; then
        return 0
    fi

    local now=$(date +%s)
    local last_check=0

    # Read last check time if file exists
    if [ -f "$SDLC_UPDATE_CHECK_FILE" ]; then
        last_check=$(cat "$SDLC_UPDATE_CHECK_FILE" 2>/dev/null || echo "0")
    fi

    # Check once per day (86400 seconds)
    local time_diff=$((now - last_check))
    if [ $time_diff -lt 86400 ]; then
        return 0
    fi

    # Fetch latest release tag from GitHub
    local latest_version=$(curl -s "https://api.github.com/repos/${SDLC_REPO}/releases/latest" | sed -nE 's/.*"tag_name": *"([^"]+)".*/\1/p' | head -n1 || echo "")

    # If we couldn't get the version, silently return
    if [ -z "$latest_version" ]; then
        return 0
    fi

    # Update last check timestamp only after successful fetch
    echo "$now" > "$SDLC_UPDATE_CHECK_FILE"

    # Remove 'v' prefix if present for comparison
    latest_version=${latest_version#v}

    # Compare versions (simple string comparison)
    if [ "$latest_version" != "$SDLC_VERSION" ] && [ ! -z "$latest_version" ]; then
        echo ""
        echo -e "${YELLOW}╔════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  Update Available!                             ║${NC}"
        echo -e "${YELLOW}╟────────────────────────────────────────────────╢${NC}"
        echo -e "${YELLOW}║  Current version: ${SDLC_VERSION}                           ║${NC}"
        echo -e "${YELLOW}║  Latest version:  ${latest_version}                           ║${NC}"
        echo -e "${YELLOW}╟────────────────────────────────────────────────╢${NC}"
        echo -e "${YELLOW}║  Run './sdlc.sh --update' to update            ║${NC}"
        echo -e "${YELLOW}╚════════════════════════════════════════════════╝${NC}"
        echo ""
    fi
}

# Function to perform update
perform_update() {
    print_section_header "SDLC Update"

    echo -e "${BLUE}Checking for updates...${NC}"

    if ! command -v curl &> /dev/null; then
        echo -e "${RED}Error: curl is required for updates${NC}"
        exit 1
    fi

    # Fetch latest release tag from GitHub
    local latest_version=$(curl -s "https://api.github.com/repos/${SDLC_REPO}/releases/latest" | sed -nE 's/.*"tag_name": *"([^"]+)".*/\1/p' | head -n1 || echo "")

    if [ -z "$latest_version" ]; then
        echo -e "${RED}Error: Could not fetch latest version${NC}"
        exit 1
    fi

    # Remove 'v' prefix if present
    latest_version=${latest_version#v}

    echo -e "${BLUE}Current version: ${SDLC_VERSION}${NC}"
    echo -e "${BLUE}Latest version:  ${latest_version}${NC}"
    echo ""

    if [ "$latest_version" == "$SDLC_VERSION" ]; then
        echo -e "${GREEN}✓ You are already on the latest version!${NC}"
        return 0
    fi

    echo -e "${YELLOW}A new version is available!${NC}"
    echo ""
    read -p "Update to version ${latest_version}? (y/n): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update cancelled.${NC}"
        return 0
    fi

    echo ""
    echo -e "${BLUE}Downloading and running installer...${NC}"
    echo ""

    # Download and run the install script
    if curl -fsSL "https://raw.githubusercontent.com/${SDLC_REPO}/main/install.sh" | bash; then
        echo ""
        echo -e "${GREEN}✓ Update completed successfully!${NC}"
        echo -e "${YELLOW}Note: If runners are currently running, restart them with:${NC}"
        echo -e "${YELLOW}  ./sdlc.sh --stop${NC}"
        echo -e "${YELLOW}  ./sdlc.sh${NC}"
    else
        echo ""
        echo -e "${RED}✗ Update failed${NC}"
        exit 1
    fi
}

# Function to show version
show_version() {
    echo "SDLC version ${SDLC_VERSION}"
    echo "Repository: https://github.com/${SDLC_REPO}"
}

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed.${NC}"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi
}

# Function to check if docker-compose is installed
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}Error: docker-compose is not installed.${NC}"
        echo "Install it from: https://docs.docker.com/compose/install/"
        exit 1
    fi
}

# Function to check if .env file exists
check_env_file() {
    if [ ! -f "$GITHUB_RUNNER_DIR/.env" ]; then
        return 1
    fi
    return 0
}

# Function to validate environment (checks .env file and docker-compose)
env_validation() {
    if ! check_env_file; then
        echo -e "${RED}Error: Configuration file not found!${NC}"
        echo ""
        exit 1
    fi
    check_docker_compose
}

# Function to build Claude Code container
print_section_header() {
    local title="$1"
    echo "================================================"
    echo "  $title"
    echo "================================================"
    echo ""
}

# Function to validate non-empty input
validate_non_empty() {
    local value="$1"
    local field_name="$2"
    
    if [ -z "$value" ]; then
        echo -e "${YELLOW}   Error: $field_name cannot be empty${NC}"
        return 1
    fi
    return 0
}

# Function to build Claude Code container
build_claude_container() {
    print_section_header "Building Claude Code Container"
    echo -e "${BLUE}Building sdlc-claude:latest...${NC}"
    docker build -t sdlc-claude:latest "$CLAUDE_CODE_RUNNER_DIR" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Claude Code container built successfully!${NC}"
    else
        echo -e "${RED}✗ Failed to build Claude Code container${NC}"
        exit 1
    fi
    echo ""
}

# Function to run setup
run_setup() {
    print_section_header "SDLC - Claude Code Infrastructure Setup"

    # Check if Docker is installed
    check_docker
    echo -e "${BLUE}✓ Docker found${NC}"

    # Check if docker-compose is installed
    check_docker_compose
    echo -e "${BLUE}✓ docker-compose found${NC}"

    echo ""

    # Build Claude Code container
    build_claude_container

    print_section_header "Creating Runner Configuration"

    # Create .env file in github-runner directory
    if [ ! -f "$GITHUB_RUNNER_DIR/.env" ]; then
        echo -e "${BLUE}Let's configure your GitHub Actions runners...${NC}"
        echo ""

        # Prompt for GitHub Token
        echo -e "${YELLOW}1. GitHub Personal Access Token${NC}"
        echo "   Create one at: https://github.com/settings/tokens"
        echo "   Required scopes:"
        echo "     - For repository runners: 'repo' (Full control of private repositories)"
        echo "     - For organization runners: 'admin:org' (Full control of orgs and teams)"
        echo ""

        while true; do
            read -s -p "   Enter your GitHub token (ghp_...): " GITHUB_TOKEN
            echo ""

            validate_non_empty "$GITHUB_TOKEN" "Token" || continue

            if [[ ! $GITHUB_TOKEN =~ ^(ghp_|github_pat_) ]]; then
                echo -e "${YELLOW}   Warning: Token should start with 'ghp_' or 'github_pat_'${NC}"
                read -p "   Continue anyway? (y/n): " CONTINUE
                if [[ $CONTINUE =~ ^[Yy]$ ]]; then
                    break
                fi
            else
                break
            fi
        done

        echo ""

        # Prompt for Repository or Organization
        echo -e "${YELLOW}2. GitHub Repository or Organization${NC}"
        echo "   Repository format: owner/repo-name (e.g., octocat/hello-world)"
        echo "   Organization format: org-name (e.g., my-organization)"
        echo ""

        while true; do
            read -p "   Enter your repository or organization: " GITHUB_REPOSITORY

            validate_non_empty "$GITHUB_REPOSITORY" "Repository/Organization" || continue

            # Check if it's an org (no slash) or repo (has slash)
            if [[ $GITHUB_REPOSITORY =~ ^[^/]+/[^/]+$ ]]; then
                # Repository format
                echo -e "${GREEN}   ✓ Detected repository-level runner configuration${NC}"
                RUNNER_SCOPE="repo"
                break
            elif [[ $GITHUB_REPOSITORY =~ ^[^/]+$ ]]; then
                # Organization format
                echo -e "${GREEN}   ✓ Detected organization-level runner configuration${NC}"
                echo -e "${BLUE}   Note: Using organization token - runners will be available to all repos in the org${NC}"
                RUNNER_SCOPE="org"
                break
            else
                echo -e "${YELLOW}   Error: Invalid format. Use 'owner/repo-name' for repository or 'org-name' for organization${NC}"
                continue
            fi
        done

        echo ""

        # Prompt for Runner Prefix (optional)
        echo -e "${YELLOW}3. Runner Name Prefix (optional)${NC}"
        echo "   Runners will be named: {prefix}-gh-runner-1, {prefix}-gh-runner-2, etc."
        echo "   Default prefix: $DEFAULT_RUNNER_PREFIX (hostname)"
        echo ""
        read -p "   Enter prefix (or press Enter for default '$DEFAULT_RUNNER_PREFIX'): " RUNNER_PREFIX

        # Use hostname as default if empty
        if [ -z "$RUNNER_PREFIX" ]; then
            RUNNER_PREFIX="$DEFAULT_RUNNER_PREFIX"
            echo -e "${GREEN}   ✓ Using default prefix: $RUNNER_PREFIX${NC}"
        fi

        echo ""

        # Prompt for Number of Runners (optional)
        echo -e "${YELLOW}4. Number of Runner Replications${NC}"
        echo "   How many parallel runners do you want to run?"
        echo "   Default: 5"
        echo ""
        
        while true; do
            read -p "   Enter number of runners (1-20, or press Enter for default '5'): " RUNNER_REPLICATIONS
            
            # Use default if empty
            if [ -z "$RUNNER_REPLICATIONS" ]; then
                RUNNER_REPLICATIONS=5
                echo -e "${GREEN}   ✓ Using default: $RUNNER_REPLICATIONS runners${NC}"
                break
            fi
            
            # Validate it's a number
            if ! [[ "$RUNNER_REPLICATIONS" =~ ^[0-9]+$ ]]; then
                echo -e "${YELLOW}   Error: Please enter a valid number${NC}"
                continue
            fi
            
            # Validate range
            if [ "$RUNNER_REPLICATIONS" -lt 1 ] || [ "$RUNNER_REPLICATIONS" -gt 20 ]; then
                echo -e "${YELLOW}   Error: Number must be between 1 and 20${NC}"
                continue
            fi
            
            echo -e "${GREEN}   ✓ Will create $RUNNER_REPLICATIONS runners${NC}"
            break
        done

        echo ""
        echo -e "${BLUE}Creating .env file...${NC}"

        # Create .env file with provided values
        cat > "$GITHUB_RUNNER_DIR/.env" << EOF
# GitHub Actions Runner Configuration
# Generated by sdlc.sh --setup

# Required: Your GitHub Personal Access Token with repo access (admin write on repo needed)
GITHUB_TOKEN=$GITHUB_TOKEN

# Required: Repository in format owner/repo-name OR Organization name
GITHUB_REPOSITORY=$GITHUB_REPOSITORY

# Runner scope: 'repo' for repository-level, 'org' for organization-level
RUNNER_SCOPE=$RUNNER_SCOPE

# Optional: Prefix for runner names (default: none)
# Runners will be named: {prefix}-gh-runner-1, {prefix}-gh-runner-2, etc.
RUNNER_PREFIX=$RUNNER_PREFIX

# Number of runner replications (default: 5)
RUNNER_REPLICATIONS=$RUNNER_REPLICATIONS
EOF

        echo -e "${GREEN}✓ Created .env file with your configuration${NC}"
    else
        echo -e "${YELLOW}.env file already exists - skipping creation${NC}"
        echo "If you want to reconfigure, delete $GITHUB_RUNNER_DIR/.env and run setup again"
    fi

    echo ""
    print_section_header "Setup Complete!"
    echo -e "${GREEN}✓ Docker image 'sdlc-claude:latest' is ready${NC}"
    echo -e "${GREEN}✓ Runner configuration file created${NC}"
    echo ""
    print_section_header "Next Steps"
    echo "1. Configure GitHub Secret (in repository settings):"
    echo "   Go to: Settings → Secrets and variables → Actions"
    echo "   - CLAUDE_CODE_OAUTH_TOKEN: Your Claude Code OAuth token"
    echo ""
    echo "2. Start the self-hosted GitHub Actions runners:"
    echo ""
    echo -e "   ${BLUE}./sdlc.sh${NC}"
    echo ""
    echo "3. Verify runners are registered:"
    echo "   Go to: Settings → Actions → Runners"
    echo "   You should see ${RUNNER_REPLICATIONS:-5} runners online"
    echo ""
    echo "4. Test the workflow:"
    echo "   - Create an issue in your repository"
    echo "   - Mention @claude in the issue description or comments"
    echo "   - Claude will respond and work on your request"
    echo ""
    echo "================================================"
    echo ""
}

# Function to start runners
start_runners() {
    # Check for updates (silent, once per day)
    check_for_updates

    # Check if .env file exists, run setup if not
    if ! check_env_file; then
        echo -e "${YELLOW}Configuration file not found. Running setup...${NC}"
        echo ""
        run_setup
        echo ""
    fi

    print_section_header "Starting GitHub Actions Runners"

    # Build Claude Code container first
    build_claude_container

    env_validation

    # Load environment variables to get RUNNER_REPLICATIONS
    source "$GITHUB_RUNNER_DIR/.env"
    RUNNER_COUNT=${RUNNER_REPLICATIONS:-5}

    echo -e "${BLUE}Starting runners with docker-compose...${NC}"
    echo -e "${BLUE}Project name: $PROJECT_NAME${NC}"
    echo -e "${BLUE}Number of runners: $RUNNER_COUNT${NC}"
    echo ""

    cd "$GITHUB_RUNNER_DIR"
    echo -e "${BLUE}Building and starting containers...${NC}"
    docker-compose -p "$PROJECT_NAME" up --build -d --scale github-runner=$RUNNER_COUNT > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Containers built and started successfully!${NC}"
        echo ""
        echo -e "${BLUE}Active runners:${NC}"
        docker-compose -p "$PROJECT_NAME" ps --filter "status=running" --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        echo -e "${GREEN}✓ Runners started successfully!${NC}"
        echo ""
        echo "To stop runners:"
        echo -e "  ${BLUE}./sdlc.sh --stop${NC}"
        echo ""
        echo "To check status:"
        echo -e "  ${BLUE}cd $GITHUB_RUNNER_DIR && docker-compose -p $PROJECT_NAME ps${NC}"
        echo ""
        echo "To view logs:"
        echo -e "  ${BLUE}cd $GITHUB_RUNNER_DIR && docker-compose -p $PROJECT_NAME logs -f${NC}"
        echo ""
    else
        echo -e "${RED}✗ Failed to start runners${NC}"
        exit 1
    fi
}

# Function to stop runners
stop_runners() {
    print_section_header "Stopping GitHub Actions Runners"

    env_validation

    echo -e "${BLUE}Stopping runners with docker-compose...${NC}"
    echo -e "${BLUE}Project name: $PROJECT_NAME${NC}"
    echo ""

    cd "$GITHUB_RUNNER_DIR"
    docker-compose -p "$PROJECT_NAME" down

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓ Runners stopped successfully!${NC}"
        echo ""
        echo "To start runners again:"
        echo -e "  ${BLUE}./sdlc.sh${NC}"
        echo ""
    else
        echo -e "${RED}✗ Failed to stop runners${NC}"
        exit 1
    fi
}

# Main script logic
case "${1:-}" in
    --stop)
        stop_runners
        ;;
    --update)
        perform_update
        ;;
    --version)
        show_version
        ;;
    --help|-h|help)
        show_usage
        ;;
    "")
        start_runners
        ;;
    *)
        echo -e "${RED}Error: Unknown option '$1'${NC}"
        echo ""
        show_usage
        ;;
esac

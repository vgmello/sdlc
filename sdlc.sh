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

# Function to display usage
show_usage() {
    echo "Usage: $0 [--setup|--stop|--fix-permissions]"
    echo ""
    echo "Options:"
    echo "  --setup             Run initial setup (build containers and configure runners)"
    echo "  --stop              Stop the GitHub Actions runners"
    echo "  --fix-permissions   Diagnose and fix Docker permission issues"
    echo "  (no flag)           Start the GitHub Actions runners (docker-compose up -d)"
    echo ""
    echo "Examples:"
    echo "  $0 --setup             # First-time setup"
    echo "  $0                     # Start runners"
    echo "  $0 --stop              # Stop runners"
    echo "  $0 --fix-permissions   # Fix Docker permissions"
    exit 0
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

# Function to check Docker permissions
check_docker_permissions() {
    echo -e "${BLUE}Checking Docker permissions...${NC}"
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        echo -e "${RED}✗ Cannot connect to Docker daemon${NC}"
        echo ""
        echo "Possible issues:"
        echo "  1. Docker is not running"
        echo "  2. Your user doesn't have permission to access Docker"
        echo ""
        
        # Detect OS and provide specific guidance
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "On macOS:"
            echo "  - Make sure Docker Desktop is running"
            echo "  - Check if Docker Desktop is properly installed"
            echo "  - Try restarting Docker Desktop"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "On Linux:"
            echo "  - Make sure Docker service is running: sudo systemctl start docker"
            echo "  - Add your user to docker group: sudo usermod -aG docker $USER"
            echo "  - Log out and back in for group changes to take effect"
            echo "  - Or run: newgrp docker"
        fi
        echo ""
        echo "Run '$0 --fix-permissions' for automated help"
        return 1
    fi
    
    # Check if user can run Docker without sudo
    if ! docker ps &> /dev/null; then
        echo -e "${RED}✗ Cannot run Docker commands${NC}"
        echo ""
        echo "Your Docker daemon is running, but you don't have permission to use it."
        echo "Run '$0 --fix-permissions' for help fixing this issue"
        return 1
    fi
    
    # Check Docker socket permissions
    if [ ! -S "/var/run/docker.sock" ]; then
        echo -e "${RED}✗ Docker socket not found at /var/run/docker.sock${NC}"
        echo ""
        echo "This might indicate a non-standard Docker installation."
        return 1
    fi
    
    echo -e "${GREEN}✓ Docker permissions OK${NC}"
    return 0
}

# Function to test Docker socket access from container
test_docker_in_container() {
    echo -e "${BLUE}Testing Docker access from container...${NC}"
    
    # Try to run a simple Docker command from within a container
    if docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        ubuntu:24.04 test -S /var/run/docker.sock 2>/dev/null; then
        echo -e "${GREEN}✓ Container can access Docker socket${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Container might have issues accessing Docker socket${NC}"
        return 1
    fi
}

# Function to diagnose and fix Docker permissions
fix_docker_permissions() {
    print_section_header "Docker Permissions Diagnostic & Fix"
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed${NC}"
        echo ""
        echo "Please install Docker first:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  Download Docker Desktop: https://docs.docker.com/desktop/install/mac-install/"
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            echo "  Follow instructions: https://docs.docker.com/engine/install/"
        fi
        return 1
    fi
    
    echo -e "${GREEN}✓ Docker is installed${NC}"
    echo ""
    
    # Check if Docker daemon is running
    echo -e "${BLUE}Checking Docker daemon...${NC}"
    if ! docker info &> /dev/null; then
        echo -e "${RED}✗ Docker daemon is not accessible${NC}"
        echo ""
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            echo -e "${YELLOW}macOS detected${NC}"
            echo ""
            echo "Steps to fix:"
            echo "  1. Open Docker Desktop application"
            echo "  2. Wait for Docker to start (whale icon in menu bar)"
            echo "  3. Verify it's running: docker info"
            echo ""
            echo "If Docker Desktop is installed but not running:"
            echo "  - Open it from Applications folder"
            echo "  - Or run: open -a Docker"
            echo ""
            
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            echo -e "${YELLOW}Linux detected${NC}"
            echo ""
            echo "Steps to fix:"
            echo "  1. Start Docker service:"
            echo "     sudo systemctl start docker"
            echo ""
            echo "  2. Enable Docker to start on boot:"
            echo "     sudo systemctl enable docker"
            echo ""
            echo "  3. Check Docker status:"
            echo "     sudo systemctl status docker"
            echo ""
        fi
        
        read -p "Press Enter after starting Docker to continue, or Ctrl+C to exit..."
        
        # Re-check
        if ! docker info &> /dev/null; then
            echo -e "${RED}✗ Docker is still not accessible${NC}"
            echo "Please ensure Docker is running and try again."
            return 1
        fi
    fi
    
    echo -e "${GREEN}✓ Docker daemon is running${NC}"
    echo ""
    
    # Check if user can run Docker without sudo
    echo -e "${BLUE}Checking Docker permissions for current user...${NC}"
    if ! docker ps &> /dev/null; then
        echo -e "${RED}✗ Current user cannot run Docker commands${NC}"
        echo ""
        
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux - need to add user to docker group
            echo -e "${YELLOW}Your user needs to be added to the 'docker' group${NC}"
            echo ""
            echo "To fix this, run the following commands:"
            echo ""
            echo -e "${BLUE}  sudo usermod -aG docker $USER${NC}"
            echo -e "${BLUE}  newgrp docker${NC}"
            echo ""
            echo "Or log out and log back in for the changes to take effect."
            echo ""
            
            read -p "Would you like me to add your user to the docker group now? (y/n): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                if sudo usermod -aG docker "$USER"; then
                    echo -e "${GREEN}✓ User added to docker group${NC}"
                    echo ""
                    echo "Please run one of the following:"
                    echo "  1. Log out and log back in"
                    echo "  2. Or run: newgrp docker"
                    echo ""
                    echo "Then run this script again to verify."
                    return 0
                else
                    echo -e "${RED}✗ Failed to add user to docker group${NC}"
                    return 1
                fi
            fi
            
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - should work with Docker Desktop
            echo -e "${YELLOW}On macOS with Docker Desktop, this usually works automatically${NC}"
            echo ""
            echo "Possible fixes:"
            echo "  1. Restart Docker Desktop"
            echo "  2. Reinstall Docker Desktop"
            echo "  3. Check Docker Desktop Settings → Advanced → Enable default Docker socket"
            echo ""
        fi
        
        return 1
    fi
    
    echo -e "${GREEN}✓ User can run Docker commands${NC}"
    echo ""
    
    # Test Docker socket from within a container
    echo -e "${BLUE}Testing Docker socket access from container...${NC}"
    TEST_OUTPUT=$(docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
        ubuntu:24.04 sh -c "ls -la /var/run/docker.sock 2>&1" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Container can access Docker socket${NC}"
        echo ""
        echo "Socket permissions:"
        echo "$TEST_OUTPUT"
        echo ""
        
        # Try to run docker command from container
        echo -e "${BLUE}Testing Docker command execution from container...${NC}"
        if docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
            docker:24-cli docker ps &> /dev/null; then
            echo -e "${GREEN}✓ Container can execute Docker commands${NC}"
            echo ""
            echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${GREEN}✓ All Docker permission checks passed!${NC}"
            echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo "Your Docker setup is properly configured for SDLC."
            echo "You can now run: $0 --setup"
            return 0
        else
            echo -e "${YELLOW}⚠ Container can see socket but cannot execute Docker commands${NC}"
            echo ""
            echo "This might be a Docker-in-Docker configuration issue."
            echo "The SDLC runners might still work, but there could be issues."
        fi
    else
        echo -e "${RED}✗ Container cannot access Docker socket${NC}"
        echo ""
        echo "Error output:"
        echo "$TEST_OUTPUT"
        echo ""
        echo "This is unusual and might indicate a complex Docker configuration issue."
    fi
    
    echo ""
    echo "Summary of findings and next steps above."
}

# Function to check if .env file exists
check_env_file() {
    if [ ! -f "$GITHUB_RUNNER_DIR/.env" ]; then
        echo -e "${RED}Error: Configuration file not found!${NC}"
        echo ""
        echo "Please run setup first:"
        echo -e "  ${BLUE}./sdlc.sh --setup${NC}"
        echo ""
        exit 1
    fi
}

# Function to validate environment (checks .env file and docker-compose)
env_validation() {
    check_env_file
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
    docker build -t sdlc-claude:latest "$CLAUDE_CODE_RUNNER_DIR"

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

    # Check Docker permissions
    if ! check_docker_permissions; then
        echo ""
        echo -e "${RED}✗ Docker permissions check failed${NC}"
        echo ""
        echo "Please fix Docker permissions before continuing."
        echo "Run: ${BLUE}$0 --fix-permissions${NC}"
        exit 1
    fi

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
    print_section_header "Starting GitHub Actions Runners"

    # Check Docker permissions before starting
    if ! check_docker_permissions; then
        echo ""
        echo -e "${RED}✗ Docker permissions check failed${NC}"
        echo ""
        echo "Please fix Docker permissions before starting runners."
        echo "Run: ${BLUE}$0 --fix-permissions${NC}"
        exit 1
    fi

    echo ""

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
    docker-compose -p "$PROJECT_NAME" up --build -d --scale github-runner=$RUNNER_COUNT

    if [ $? -eq 0 ]; then
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
    --setup)
        run_setup
        ;;
    --stop)
        stop_runners
        ;;
    --fix-permissions)
        fix_docker_permissions
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

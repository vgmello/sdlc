#!/bin/bash
set -e

# Source nvm to make node/npm available
export NVM_DIR=/usr/local/nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Claude Code Runner - InvestBot${NC}"
echo -e "${BLUE}================================================${NC}"

# Validate required environment variables
if [ -z "$GITHUB_REPOSITORY" ]; then
    echo -e "${RED}Error: GITHUB_REPOSITORY environment variable is required${NC}"
    exit 1
fi

if [ -z "$CLAUDE_BRANCH_NAME" ]; then
    echo -e "${RED}Error: CLAUDE_BRANCH_NAME environment variable is required${NC}"
    exit 1
fi

if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo -e "${RED}Error: CLAUDE_CODE_OAUTH_TOKEN secret is required${NC}"
    exit 1
fi

# Configure git
git config --global user.name "Claude Code"
git config --global user.email "claude-code@anthropic.com"
git config --global init.defaultBranch main

# Configure GitHub CLI with token
export GITHUB_TOKEN="${GH_TOKEN}"

# Configure git to use the token for authentication
if [ -n "$GH_TOKEN" ]; then
    git config --global url."https://oauth2:${GH_TOKEN}@github.com/".insteadOf "https://github.com/"
fi

# We should already be in the correct directory (set by docker run -w)
# Verify we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}Error: Not in a git repository. Current directory: $(pwd)${NC}"
    echo -e "${RED}Directory contents:${NC}"
    ls -la
    exit 1
fi

# Save the workspace directory for later use
WORKSPACE_DIR=$(pwd)

echo -e "${GREEN}✓ Repository: ${GITHUB_REPOSITORY}${NC}"
echo -e "${GREEN}✓ Branch: ${CLAUDE_BRANCH_NAME}${NC}"
echo -e "${GREEN}✓ Issue/PR #${ISSUE_NUMBER} (${ISSUE_TYPE})${NC}"
echo -e "${GREEN}✓ Working directory: $(pwd)${NC}"

# Fetch all branches
echo -e "${BLUE}Fetching latest changes...${NC}"
git fetch --all --prune

# Check if feature branch exists, create if needed
if git ls-remote --heads origin "$CLAUDE_BRANCH_NAME" | grep -q "$CLAUDE_BRANCH_NAME"; then
    echo -e "${GREEN}✓ Feature branch exists, checking out...${NC}"
    git checkout "$CLAUDE_BRANCH_NAME"
    git pull origin "$CLAUDE_BRANCH_NAME"
else
    echo -e "${YELLOW}⚠ Feature branch doesn't exist, creating from main...${NC}"
    git checkout -b "$CLAUDE_BRANCH_NAME" origin/main
    git push -u origin "$CLAUDE_BRANCH_NAME"
fi

# Set up Claude state directory (use /tmp since we're running as arbitrary UID)
CLAUDE_STATE_DIR="/tmp/.claude/projects/-workspace"
mkdir -p "$CLAUDE_STATE_DIR"

# Initialize state directory as git repo if needed
if [ ! -d "$CLAUDE_STATE_DIR/.git" ]; then
    echo -e "${BLUE}Initializing Claude state directory...${NC}"
    cd "$CLAUDE_STATE_DIR"
    git init
    git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
    # Return to workspace
    cd - > /dev/null
fi

# Check if state branch exists
STATE_BRANCH="${CLAUDE_BRANCH_NAME}"
cd "$CLAUDE_STATE_DIR"

if git ls-remote --heads origin "$STATE_BRANCH" | grep -q "$STATE_BRANCH"; then
    echo -e "${GREEN}✓ State branch exists, fetching...${NC}"
    git fetch origin "$STATE_BRANCH"
    git checkout -B "$STATE_BRANCH" "origin/$STATE_BRANCH" 2>/dev/null || git checkout -b "$STATE_BRANCH"
else
    echo -e "${YELLOW}⚠ State branch doesn't exist, creating...${NC}"
    git checkout -b "$STATE_BRANCH"
fi

cd "$WORKSPACE_DIR"

# Background loop to commit and push state changes every 30 seconds
(
    while true; do
        sleep 30
        cd "$CLAUDE_STATE_DIR"
        if [ -n "$(git status --porcelain)" ]; then
            echo -e "${BLUE}Saving Claude state...${NC}"
            git add -A
            git commit -m "Auto-save Claude state at $(date -u +"%Y-%m-%d %H:%M:%S UTC")" || true
            git push -f origin "$STATE_BRANCH" || true
        fi
        cd "$WORKSPACE_DIR"
    done
) &

# Store background process PID
STATE_COMMIT_PID=$!

# Cleanup function
cleanup() {
    echo -e "${BLUE}Performing final state save...${NC}"
    cd "$CLAUDE_STATE_DIR"
    if [ -n "$(git status --porcelain)" ]; then
        git add -A
        git commit -m "Final state save at $(date -u +"%Y-%m-%d %H:%M:%S UTC")" || true
        git push -f origin "$STATE_BRANCH" || true
    fi
    
    # Kill background commit process
    kill $STATE_COMMIT_PID 2>/dev/null || true
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

trap cleanup EXIT

# Build Claude prompt with system prompt and user request
SYSTEM_PROMPT_FILE="/workspace/.github/sdlc/claude-system-prompt.md"
if [ -f "$SYSTEM_PROMPT_FILE" ]; then
    SYSTEM_PROMPT=$(cat "$SYSTEM_PROMPT_FILE")
else
    echo -e "${YELLOW}⚠ System prompt file not found, using default${NC}"
    SYSTEM_PROMPT="You are an expert software engineer working on the InvestBot project via GitHub Actions."
fi

# Construct full prompt
FULL_PROMPT="${SYSTEM_PROMPT}

---

## User Request

${USER_PROMPT}

---

## Context

- **Repository**: ${GITHUB_REPOSITORY}
- **Branch**: ${CLAUDE_BRANCH_NAME}
- **Issue Type**: ${ISSUE_TYPE}
- **Issue/PR Number**: ${ISSUE_NUMBER}"

# Add PR review comment context if available
if [ -n "$FILE_PATH" ]; then
    FULL_PROMPT="${FULL_PROMPT}
- **File**: ${FILE_PATH}
- **Line**: ${LINE_NUMBER}
- **Comment ID**: ${COMMENT_ID}

### Diff Context
\`\`\`diff
${DIFF_HUNK}
\`\`\`"
fi

# Run Claude Code with the prompt
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Starting Claude Code Session${NC}"
echo -e "${BLUE}================================================${NC}"

# Run Claude Code with flags to continue conversation, print output, and skip permissions
echo "$FULL_PROMPT" | claude --continue --print --dangerously-skip-permissions

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}  Claude Code Session Complete${NC}"
echo -e "${GREEN}================================================${NC}"

#!/bin/bash
set -e

echo "=== AI Agent Runner Entrypoint ==="

# Required environment variables
: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN is required}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY is required}"
: "${AGENT_NAME:?Error: AGENT_NAME is required (e.g., 'claude', 'codex')}"

# Optional environment variables with defaults
GITHUB_REF="${GITHUB_REF:-}"  # If empty, will use default branch
AGENT_BRANCH_NAME="${AGENT_BRANCH_NAME:?Error: AGENT_BRANCH_NAME is required}"
USER_PROMPT="${USER_PROMPT:?Error: USER_PROMPT is required}"

# Validate AGENT_BRANCH_NAME format
if [[ "$AGENT_BRANCH_NAME" == "agent--" ]] || [[ "$AGENT_BRANCH_NAME" =~ ^agent--$ ]]; then
    echo ""
    echo "=========================================="
    echo "ERROR: Invalid AGENT_BRANCH_NAME"
    echo "=========================================="
    echo ""
    echo "AGENT_BRANCH_NAME is set to: '$AGENT_BRANCH_NAME'"
    echo ""
    echo "This indicates that the issue/PR number was not properly extracted."
    echo "The branch name should be in format: agent-{type}-{number}"
    echo "  Examples: agent-issue-123, agent-pr-456"
    echo ""
    echo "Possible causes:"
    echo "  1. Workflow context extraction failed"
    echo "  2. Issue/PR number is missing from the event"
    echo "  3. Environment variable not properly passed to Docker"
    echo ""
    echo "=========================================="
    echo ""
    exit 1
fi

# Workspace directories
WORKSPACE_DIR="/workspace"
AGENT_STATE_DIR="/home/agent/.${AGENT_NAME}/projects/-workspace"
AGENT_OUTPUT_FILE="/tmp/agent-output.txt"

# Export for agent scripts
export AGENT_OUTPUT_FILE
export SYSTEM_PROMPT

# Function to commit and push agent state changes
commit_agent_state() {
    if [ ! -d "$AGENT_STATE_DIR" ]; then
        return
    fi

    cd "$AGENT_STATE_DIR"

    if [[ -n $(git status -s) ]]; then
        echo "Changes detected in agent state"
        git add .
        git commit -m "AI Agent state update" 2>&1 | grep -v "x-access-token" || true
        git push -u origin "$AGENT_BRANCH_NAME" 2>&1 | grep -v "x-access-token" || true
        echo "Agent state committed and pushed to branch: $AGENT_BRANCH_NAME"
    fi
}

# Background function to periodically commit agent state
background_commit_loop() {
    while true; do
        sleep 30
        commit_agent_state
    done
}

echo "Configuration:"
echo "  Repository: $GITHUB_REPOSITORY"
echo "  GitHub Ref: ${GITHUB_REF:-<default branch>}"
echo "  Agent: $AGENT_NAME"
echo "  Agent State Branch: $AGENT_BRANCH_NAME"
echo ""

# Setup git credentials
echo "=== Setting up Git credentials ==="
git config --global credential.helper store
echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /home/agent/.git-credentials
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"
echo "Git credentials configured"
echo ""

# Setup agent state directory and clone/create branch (only for agents that need it)
if [ "$AGENT_NAME" == "claude" ]; then
    echo "=== Setting up agent state branch ==="
    mkdir -p "$(dirname "$AGENT_STATE_DIR")"

    if git ls-remote --heads "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$AGENT_BRANCH_NAME" 2>&1 | grep -v "x-access-token" | grep -q "$AGENT_BRANCH_NAME"; then
        echo "Agent state branch exists, cloning: $AGENT_BRANCH_NAME"
        git clone --depth 1 --branch "$AGENT_BRANCH_NAME" "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$AGENT_STATE_DIR" 2>&1 | grep -v "x-access-token" || true
    else
        echo "Agent state branch does not exist, creating: $AGENT_BRANCH_NAME"
        git clone --depth 1 "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$AGENT_STATE_DIR" 2>&1 | grep -v "x-access-token" || true
        cd "$AGENT_STATE_DIR"
        git checkout -b "$AGENT_BRANCH_NAME"
    fi

    echo "Agent state directory: $AGENT_STATE_DIR"
    echo ""
fi

# Navigate to workspace directories
cd "$WORKSPACE_DIR"

# Clone main repository
echo "=== Cloning main repository ==="
if [ -n "$GITHUB_REF" ]; then
    echo "Cloning with specific ref: $GITHUB_REF"
    git clone --depth 1 --branch "$GITHUB_REF" "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$WORKSPACE_DIR" 2>&1 | grep -v "x-access-token" || true
else
    echo "Cloning default branch"
    git clone --depth 1 "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$WORKSPACE_DIR" 2>&1 | grep -v "x-access-token" || true
fi

echo "Repository cloned to: $WORKSPACE_DIR"
echo ""

# Prepare prompts
echo "=== Preparing prompts ==="

# System prompt - read from repo
SYSTEM_PROMPT_FILE="$WORKSPACE_DIR/.github/sdlc/agent-system-prompt.md"

if [ -f "$SYSTEM_PROMPT_FILE" ]; then
    echo "System prompt found at: $SYSTEM_PROMPT_FILE"
    SYSTEM_PROMPT=$(cat "$SYSTEM_PROMPT_FILE")
else
    echo ""
    echo "=========================================="
    echo "WARNING: No system prompt file found!"
    echo "=========================================="
    echo ""
    echo "Expected location: $SYSTEM_PROMPT_FILE"
    echo ""
    echo "Using default system prompt instead."
    echo "For better results, create a system prompt file with:"
    echo "  - Project context and guidelines"
    echo "  - Coding standards and conventions"
    echo "  - Repository structure information"
    echo ""
    echo "=========================================="
    echo ""
    SYSTEM_PROMPT="You are an AI coding assistant helping with software development tasks."
fi

# User prompt - passed via environment variable
echo "User prompt provided via USER_PROMPT environment variable"
echo ""

# Start background commit loop (only for agents that need state tracking)
if [ "$AGENT_NAME" == "claude" ]; then
    echo "=== Starting background state commit loop ==="
    background_commit_loop &
    BACKGROUND_PID=$!
    echo "Background commit process started (PID: $BACKGROUND_PID)"

    # Trap to ensure background process is killed on exit
    trap "kill $BACKGROUND_PID 2>/dev/null || true" EXIT
    echo ""
fi

# Load and run the appropriate agent
AGENT_SCRIPT="/usr/local/bin/agents/${AGENT_NAME}.sh"

if [ ! -f "$AGENT_SCRIPT" ]; then
    echo ""
    echo "=========================================="
    echo "ERROR: Agent script not found!"
    echo "=========================================="
    echo ""
    echo "Agent: $AGENT_NAME"
    echo "Expected script: $AGENT_SCRIPT"
    echo ""
    echo "Available agents:"
    ls -1 /usr/local/bin/agents/ | sed 's/\.sh$//' | sed 's/^/  - /'
    echo ""
    echo "=========================================="
    echo ""
    exit 1
fi

echo "=== Running $AGENT_NAME agent ==="
echo "Working directory: $(pwd)"
echo ""

# Source and execute the agent script
set +e
source "$AGENT_SCRIPT"
AGENT_EXIT_CODE=$?
set -e

echo ""
echo "Agent exit code: $AGENT_EXIT_CODE"
echo ""

# Final commit and push agent state changes
if [ "$AGENT_NAME" == "claude" ]; then
    echo "=== Final commit of agent state changes ==="
    commit_agent_state
    echo ""
fi

echo "=== AI Agent Runner Complete ==="
exit $AGENT_EXIT_CODE

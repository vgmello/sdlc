#!/bin/bash
set -e

echo "=== Claude Code Runner Entrypoint ==="

# Required environment variables
: "${GITHUB_TOKEN:?Error: GITHUB_TOKEN is required}"
: "${GITHUB_REPOSITORY:?Error: GITHUB_REPOSITORY is required}"
: "${CLAUDE_CODE_OAUTH_TOKEN:?Error: CLAUDE_CODE_OAUTH_TOKEN is required}"
: "${GITHUB_ACTOR:?Error: GITHUB_ACTOR is required}"

# Optional environment variables with defaults
GITHUB_REF="${GITHUB_REF:-}"  # If empty, will use default branch
CLAUDE_BRANCH_NAME="${CLAUDE_BRANCH_NAME:?Error: CLAUDE_BRANCH_NAME is required}"
USER_PROMPT="${USER_PROMPT:?Error: USER_PROMPT is required}"
ISSUE_NUMBER="${ISSUE_NUMBER:-unknown}"
ISSUE_TYPE="${ISSUE_TYPE:-issue}"

# Workspace directories
WORKSPACE_DIR="/workspace"
CLAUDE_STATE_DIR="/home/claude/.claude/projects/-workspace"
CLAUDE_OUTPUT_FILE="$WORKSPACE_DIR/claude-output.txt"

echo "Configuration:"
echo "  Repository: $GITHUB_REPOSITORY"
echo "  GitHub Ref: ${GITHUB_REF:-<default branch>}"
echo "  Claude Branch: $CLAUDE_BRANCH_NAME"
echo "  Issue: $ISSUE_TYPE #$ISSUE_NUMBER"
echo ""

# Setup git credentials
echo "=== Setting up Git credentials ==="
git config --global credential.helper store
echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /home/claude/.git-credentials
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"
echo "Git credentials configured"
echo ""

# Create workspace directories
mkdir -p "$WORKSPACE_DIR"
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

# Setup Claude state directory and clone/create branch
echo "=== Setting up Claude state branch ==="
mkdir -p "$(dirname "$CLAUDE_STATE_DIR")"

if git ls-remote --heads "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$CLAUDE_BRANCH_NAME" 2>&1 | grep -v "x-access-token" | grep -q "$CLAUDE_BRANCH_NAME"; then
    echo "Claude branch exists, cloning: $CLAUDE_BRANCH_NAME"
    git clone --depth 1 --branch "$CLAUDE_BRANCH_NAME" "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$CLAUDE_STATE_DIR" 2>&1 | grep -v "x-access-token" || true
else
    echo "Claude branch does not exist, creating: $CLAUDE_BRANCH_NAME"
    git clone --depth 1 "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$CLAUDE_STATE_DIR" 2>&1 | grep -v "x-access-token" || true
    cd "$CLAUDE_STATE_DIR"
    git checkout -b "$CLAUDE_BRANCH_NAME"
    cd "$WORKSPACE_DIR"
fi

echo "Claude state directory: $CLAUDE_STATE_DIR"
echo ""

# Change to workspace directory for Claude to work in
cd "$WORKSPACE_DIR"

# Prepare prompts
echo "=== Preparing prompts ==="

# System prompt - read from repo
SYSTEM_PROMPT_FILE="$WORKSPACE_DIR/.github/sdlc/claude-system-prompt.md"

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
    SYSTEM_PROMPT="You are Claude Code, an AI assistant helping with software development tasks."
fi

# User prompt - passed via environment variable
echo "User prompt provided via USER_PROMPT environment variable"
echo ""

# Run Claude Code
echo "=== Running Claude Code ==="
echo "Working directory: $(pwd)"
echo ""

# Build claude command
CLAUDE_ARGS=(claude --continue --print --dangerously-skip-permissions)

# Add system prompt
if [ -n "$SYSTEM_PROMPT" ]; then
    CLAUDE_ARGS+=(--system-prompt "$SYSTEM_PROMPT")
fi

# Run Claude with user prompt via stdin, capture output
set +e
echo "$USER_PROMPT" | "${CLAUDE_ARGS[@]}" 2>&1 | tee "$CLAUDE_OUTPUT_FILE"
CLAUDE_EXIT_CODE=${PIPESTATUS[0]}
set -e

echo ""
echo "Claude Code exit code: $CLAUDE_EXIT_CODE"
echo ""

# Commit and push Claude state changes
echo "=== Committing Claude state changes ==="
cd "$CLAUDE_STATE_DIR"

if [[ -n $(git status -s) ]]; then
    echo "Changes detected in Claude state"
    git add .
    git commit -m "Claude Code state: $ISSUE_TYPE #$ISSUE_NUMBER" 2>&1 | grep -v "x-access-token" || true
    git push -u origin "$CLAUDE_BRANCH_NAME" 2>&1 | grep -v "x-access-token" || true
    echo "Claude state committed and pushed to branch: $CLAUDE_BRANCH_NAME"
else
    echo "No Claude state changes to commit"
fi
echo ""

# Post response as GitHub comment
echo "=== Posting response to GitHub ==="

if [ ! -s "$CLAUDE_OUTPUT_FILE" ]; then
    echo "Error: Claude Code did not produce output" > "$CLAUDE_OUTPUT_FILE"
fi

COMMENT_BODY=$(jq -n \
    --arg output "$(cat "$CLAUDE_OUTPUT_FILE")" \
    --arg actor "$GITHUB_ACTOR" \
    --arg type "$ISSUE_TYPE" \
    --arg number "$ISSUE_NUMBER" \
    '{
        body: ("## Claude Code Response\n\n```\n" + $output + "\n```\n\n---\n*Triggered by @" + $actor + " on " + $type + " #" + $number + "*")
    }')

curl -sS -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER/comments" \
    -d "$COMMENT_BODY"

echo "Comment posted successfully"
echo ""

echo "=== Claude Code Runner Complete ==="
exit $CLAUDE_EXIT_CODE

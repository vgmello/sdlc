#!/bin/bash
set -e

# Setup git credentials if GITHUB_TOKEN is provided
if [ -n "$GITHUB_TOKEN" ]; then
    echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > /home/claude/.git-credentials
    echo "Git credentials configured"
fi

# Default paths for prompts (can be overridden by environment variables)
SYSTEM_PROMPT_FILE="${SYSTEM_PROMPT_FILE:-/workspace/.claude-system-prompt.txt}"
USER_PROMPT_FILE="${USER_PROMPT_FILE:-/workspace/.claude-user-prompt.txt}"

# If arguments are provided, run them instead of the default claude command
if [ $# -gt 0 ]; then
    echo "Running custom command: $@"
    exec "$@"
else
    echo "Running Claude Code..."

    # Debug: check workspace contents
    echo "Workspace contents:"
    ls -la /workspace/ || echo "Failed to list /workspace"

    echo "Checking for prompt files:"
    echo "  System prompt file: $SYSTEM_PROMPT_FILE - exists: $([ -f "$SYSTEM_PROMPT_FILE" ] && echo 'yes' || echo 'no')"
    echo "  User prompt file: $USER_PROMPT_FILE - exists: $([ -f "$USER_PROMPT_FILE" ] && echo 'yes' || echo 'no')"

    # Build claude command array
    CLAUDE_ARGS=(claude --continue --print --dangerously-skip-permissions)

    # Add system prompt if file exists
    if [ -f "$SYSTEM_PROMPT_FILE" ]; then
        CLAUDE_ARGS+=(--system-prompt "$(cat "$SYSTEM_PROMPT_FILE")")
        echo "Using system prompt from: $SYSTEM_PROMPT_FILE"
    fi

    echo "Command: ${CLAUDE_ARGS[@]}"

    # Pass user prompt via stdin if file exists
    if [ -f "$USER_PROMPT_FILE" ]; then
        echo "Using user prompt from: $USER_PROMPT_FILE"
        "${CLAUDE_ARGS[@]}" < "$USER_PROMPT_FILE"
    else
        echo "WARNING: No user prompt file found, running without stdin"
        exec "${CLAUDE_ARGS[@]}"
    fi
fi

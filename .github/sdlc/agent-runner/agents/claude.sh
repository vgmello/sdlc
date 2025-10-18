#!/bin/bash
# Claude Code Agent Runner
set -e

echo "=== Claude Code Agent ==="

# Validate Claude-specific environment variables
# The workflow passes AGENT_OAUTH_TOKEN which contains the actual token
: "${AGENT_OAUTH_TOKEN:?Error: AGENT_OAUTH_TOKEN is required for Claude agent}"

# Set Claude-specific token from the generic AGENT_OAUTH_TOKEN
export CLAUDE_CODE_OAUTH_TOKEN="$AGENT_OAUTH_TOKEN"

# Claude Code installation check
if ! command -v claude &> /dev/null; then
    echo "Error: Claude Code CLI is not installed"
    exit 1
fi

echo "Claude Code CLI found: $(claude --version 2>&1 || echo 'version unknown')"

# Build Claude command
CLAUDE_ARGS=(claude --continue --print --dangerously-skip-permissions)

# Add system prompt if provided
if [ -n "$SYSTEM_PROMPT" ]; then
    CLAUDE_ARGS+=(--system-prompt "$SYSTEM_PROMPT")
fi

# Run Claude Code with user prompt via stdin, capture output
echo "Running Claude Code agent..."
echo ""

set +e
echo "$USER_PROMPT" | "${CLAUDE_ARGS[@]}" 2>&1 | tee "$AGENT_OUTPUT_FILE"
AGENT_EXIT_CODE=${PIPESTATUS[0]}
set -e

echo ""
echo "Claude Code exit code: $AGENT_EXIT_CODE"

exit $AGENT_EXIT_CODE

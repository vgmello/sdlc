#!/bin/bash
# OpenAI Codex Agent Runner
set -e

echo "=== OpenAI Codex Agent ==="

# Validate Codex-specific environment variables
: "${CODEX_OAUTH_TOKEN:?Error: CODEX_OAUTH_TOKEN is required for Codex agent}"

# OpenAI Codex installation check
if ! command -v aider &> /dev/null; then
    echo "Error: Aider (OpenAI Codex CLI) is not installed"
    exit 1
fi

echo "Aider CLI found: $(aider --version 2>&1 || echo 'version unknown')"

# Build Aider command with OpenAI configuration
AIDER_ARGS=(aider --yes --no-git)

# Set OpenAI API key from environment
export OPENAI_API_KEY="$CODEX_OAUTH_TOKEN"

# Add system message if provided
if [ -n "$SYSTEM_PROMPT" ]; then
    AIDER_ARGS+=(--message "$SYSTEM_PROMPT")
fi

# Run Aider with user prompt, capture output
echo "Running OpenAI Codex agent (via Aider)..."
echo ""

set +e
echo "$USER_PROMPT" | "${AIDER_ARGS[@]}" --message "$USER_PROMPT" 2>&1 | tee "$AGENT_OUTPUT_FILE"
AGENT_EXIT_CODE=${PIPESTATUS[0]}
set -e

echo ""
echo "Codex agent exit code: $AGENT_EXIT_CODE"

exit $AGENT_EXIT_CODE

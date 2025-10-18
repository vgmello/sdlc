#!/bin/bash
# OpenAI Codex Agent Runner
set -e

echo "=== OpenAI Codex Agent ==="

# Validate Codex-specific environment variables
# The workflow passes AGENT_OAUTH_TOKEN which contains the actual token
: "${AGENT_OAUTH_TOKEN:?Error: AGENT_OAUTH_TOKEN is required for Codex agent}"

# Set OpenAI API key from the generic AGENT_OAUTH_TOKEN
export OPENAI_API_KEY="$AGENT_OAUTH_TOKEN"

# OpenAI Codex installation check
if ! command -v codex &> /dev/null; then
    echo "Error: OpenAI Codex CLI is not installed"
    exit 1
fi

echo "OpenAI Codex CLI found: $(codex --version 2>&1 || echo 'version unknown')"

# Prepare the prompt
FULL_PROMPT="$USER_PROMPT"

# Add system prompt if provided
if [ -n "$SYSTEM_PROMPT" ]; then
    FULL_PROMPT="$SYSTEM_PROMPT

$USER_PROMPT"
fi

# Run OpenAI Codex with the prompt, capture output
echo "Running OpenAI Codex agent..."
echo ""

set +e
echo "$FULL_PROMPT" | codex 2>&1 | tee "$AGENT_OUTPUT_FILE"
AGENT_EXIT_CODE=${PIPESTATUS[0]}
set -e

echo ""
echo "Codex agent exit code: $AGENT_EXIT_CODE"

exit $AGENT_EXIT_CODE

#!/bin/bash
set -e

# Check required environment variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
    echo "Error: GITHUB_REPOSITORY environment variable is required"
    exit 1
fi

# Extract replica number from container name
CONTAINER_ID=$(hostname)
CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$CONTAINER_ID" 2>/dev/null | sed 's/^\///')

if [ -n "$CONTAINER_NAME" ]; then
    # Extract the number at the end of the container name (e.g., runner-github-runner-1 -> 1)
    REPLICA_NUM=$(echo "$CONTAINER_NAME" | grep -oP '\d+$' || echo "1")
else
    # Fallback: use last 2 digits of container ID
    REPLICA_NUM=$(echo "$CONTAINER_ID" | tail -c 3)
fi

# Build runner name: {prefix}-gh-runner-{replica} or gh-runner-{replica} if prefix is empty
if [ -z "$RUNNER_PREFIX" ]; then
    RUNNER_NAME="gh-runner-${REPLICA_NUM}"
else
    RUNNER_NAME="${RUNNER_PREFIX}-gh-runner-${REPLICA_NUM}"
fi

if [ -z "$RUNNER_WORKDIR" ]; then
    RUNNER_WORKDIR="_work"
fi

if [ -z "$RUNNER_LABELS" ]; then
    RUNNER_LABELS="self-hosted,linux,docker"
fi

echo "Configuring GitHub Actions Runner..."
echo "Repository: $GITHUB_REPOSITORY"
echo "Runner Name: $RUNNER_NAME"
echo "Runner Labels: $RUNNER_LABELS"

# Get registration token
REGISTRATION_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" | jq -r .token)

if [ -z "$REGISTRATION_TOKEN" ] || [ "$REGISTRATION_TOKEN" = "null" ]; then
    echo "Error: Failed to get registration token"
    exit 1
fi

# Configure the runner
./config.sh \
    --url "https://github.com/${GITHUB_REPOSITORY}" \
    --token "${REGISTRATION_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --unattended \
    --replace

# Cleanup function
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${REGISTRATION_TOKEN}"
}

trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

# Start the runner
echo "Starting GitHub Actions Runner..."
./run.sh & wait $!

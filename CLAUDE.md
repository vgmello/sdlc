# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the SDLC (Software Development Lifecycle) project - a self-hosted GitHub Actions infrastructure that integrates Claude Code AI directly into GitHub workflows. When users mention `@claude` in issues or PRs, the system triggers a GitHub Actions workflow that runs Claude Code in a Docker container to autonomously work on the requested tasks.

## Architecture

### Core Components

1. **GitHub Actions Workflow** (`.github/workflows/claude.yml`)
   - Triggers on: issue comments, PR comments, PR reviews, and new issues containing `@claude`
   - Validates user permissions (requires write access or higher)
   - Extracts context (issue/PR number, comment body, PR review comment details)
   - Runs Claude Code in a containerized environment
   - Posts Claude's responses as GitHub comments

2. **Self-Hosted Runners** (`.github/sdlc/github-runner/`)
   - Ubuntu 24.04-based Docker containers running GitHub Actions runners
   - Scalable: supports 1-20 parallel runners via `RUNNER_REPLICATIONS` env var
   - Supports both repository-level and organization-level runner scopes
   - Automatically registers/unregisters with GitHub

3. **Claude Code Runner** (`.github/sdlc/claude-code-runner/`)
   - .NET 9.0 SDK base with Node.js 22 (via nvm), Python 3, Git, and GitHub CLI
   - Runs as non-root `claude` user
   - Manages two git clones:
     - **Main workspace** (`/workspace`): The repository being worked on
     - **Claude state directory** (`/home/claude/.claude/projects/-workspace`): Persistent state stored in `claude-{type}-{number}` branches
   - Background loop commits Claude state changes every 30 seconds

### Branching Strategy

- **Feature branches**: `issue-{number}-{description}` (e.g., `issue-42-implement-user-auth`)
  - The issue number is REQUIRED in the branch name
  - Created by Claude when working on tasks
  - Always merged to `main` via PR

- **State branches**: `claude-issue-{number}` or `claude-pr-{number}`
  - Stores Claude's session state (conversation history, context)
  - Auto-created and managed by the runner entrypoint
  - Automatically cleaned up when feature branch is deleted (via `cleanup-claude-state-workflow.yml`)

### Key Workflows

1. **Main Claude Workflow** (`claude.yml`)
   - Concurrency control: one workflow per issue/PR (prevents parallel executions on same issue)
   - Permission check before execution
   - Passes context to Claude via environment variables: `GITHUB_REPOSITORY`, `CLAUDE_BRANCH_NAME`, `USER_PROMPT`, `ISSUE_TYPE`, `ISSUE_NUMBER`
   - For PR review comments: also passes file path, line number, comment ID, and diff hunk

2. **Cleanup Workflow** (`cleanup-claude-state-workflow.yml`)
   - Triggers on branch deletion or PR closure
   - Automatically removes corresponding `claude-{type}-{number}` state branches

### System Prompt

The Claude Code runner reads a system prompt from `.github/sdlc/claude-system-prompt.md` which defines:
- How to communicate via GitHub comments (output is auto-posted)
- Progress tracking using task breakdown comments
- Branch naming conventions
- PR creation workflow
- GitHub CLI command reference

## Development Commands

### Setup and Management

```bash
# Initial setup (builds containers, configures runners)
./sdlc.sh --setup

# Start runners (automatically runs setup if .env doesn't exist)
./sdlc.sh

# Stop runners
./sdlc.sh --stop

# Check runner status
cd .github/sdlc/github-runner && docker-compose -p sdlc ps

# View runner logs
cd .github/sdlc/github-runner && docker-compose -p sdlc logs -f
```

### Configuration

Configuration is stored in `.github/sdlc/github-runner/.env`:
- `GITHUB_TOKEN`: Personal access token (repo scope for repo runners, admin:org for org runners)
- `GITHUB_REPOSITORY`: Format `owner/repo` (repo scope) or `org-name` (org scope)
- `RUNNER_SCOPE`: `repo` or `org`
- `RUNNER_PREFIX`: Optional prefix for runner names
- `RUNNER_REPLICATIONS`: Number of parallel runners (1-20, default 5)

### Required GitHub Secrets

Set in repository Settings → Secrets and variables → Actions:
- `CLAUDE_CODE_OAUTH_TOKEN`: Claude Code OAuth token (generate via `claude setup-token`)
- `GH_PAT` (optional): GitHub PAT with repo + workflow scopes (falls back to `github.token` if not provided)

## Working in This Repository

### When Running as Claude Code in GitHub Actions

You are likely running inside the containerized environment. Key points:
- Your output is automatically posted as GitHub comments (just print your messages)
- Always work on feature branches: `issue-{number}-{description}` format is REQUIRED
- Create task breakdown comments for transparency using `gh issue comment` or `gh pr comment`
- Use GitHub CLI (`gh`) for all GitHub API interactions
- State is automatically persisted to `claude-{type}-{number}` branches
- Create PRs to `main` when work is complete

### Testing the System

1. Create an issue or PR in the repository
2. Mention `@claude` with a request
3. The workflow triggers and Claude responds via comments
4. Monitor workflow execution in Actions tab

### Docker Containers

**Claude Code Runner** (`sdlc-claude:latest`):
- Built from `.github/sdlc/claude-code-runner/Dockerfile`
- Entrypoint: `/usr/local/bin/entrypoint.sh`
- Runs with `--continue --print --dangerously-skip-permissions` flags
- Receives user prompt via stdin

**GitHub Actions Runner**:
- Built from `.github/sdlc/github-runner/Dockerfile`
- Entrypoint: `/home/runner/entrypoint.sh`
- Auto-registers with GitHub on startup, de-registers on shutdown
- Scales horizontally via docker-compose `--scale` parameter

## Important Notes

- The project name for docker-compose is derived from the repository directory name
- Runners are named: `{prefix}-gh-runner-{replica-number}` (or `gh-runner-{replica-number}` if no prefix)
- PR review comments include file path, line number, and diff hunk context
- The system supports both inline PR review comments and general issue/PR comments
- Branch name pattern detection: if a PR branch is named `issue-{number}`, Claude uses that issue number for state branch naming

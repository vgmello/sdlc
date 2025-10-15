# GitHub Claude Code Requirements

This document outlines all requirements for running Claude Code with GitHub Actions in this repository.

## System Requirements

### For Self-Hosted Runners (Current Setup)

This repository uses a self-hosted GitHub Actions runner approach with Docker containers.

#### Required Software

- **Docker**: Version 20.10+ (for containerization)
- **Docker Compose**: Version 2.0+ (for orchestrating multiple runners)
- **Git**: Version 2.23+ (for version control operations)

#### System Resources

- **RAM**: Minimum 4GB per runner (recommended 8GB for optimal performance)
- **CPU**: 2+ cores recommended
- **Storage**: Minimum 10GB free space for Docker images and workspace
- **Network**: Active internet connection for Claude API and GitHub API calls

### For Local Development (Optional)

If you want to use Claude Code CLI locally:

- **Node.js**: Version 18+ (required for npm installation)
- **Operating System**:
  - macOS 10.15+
  - Linux (Ubuntu 20.04+, Debian 10+, Alpine)
  - Windows 10+ (requires WSL2 - Windows Subsystem for Linux)

## Docker Image Requirements

The Claude Code runner Docker image (`sdlc-claude:latest`) includes:

### Base Image
- `mcr.microsoft.com/dotnet/sdk:9.0-noble` (Ubuntu Noble base)

### Installed Components

1. **GitHub CLI (`gh`)**: For interacting with GitHub API
2. **Python 3**: With pip and venv for Python scripts
3. **Node.js 22**: Installed via nvm for Claude Code CLI
4. **Claude Code CLI**: Latest version from https://claude.ai/install.sh
5. **Git**: Pre-configured for github-actions bot
6. **jq**: For JSON processing in scripts
7. **sudo**: For elevated permissions when needed

### Environment Configuration

Required environment variables for the Docker container:

```bash
DEBIAN_FRONTEND=noninteractive
PATH="/home/claude/.local/bin:$PATH"
NVM_DIR="/home/claude/.nvm"
```

## GitHub Secrets Required

The following secrets must be configured in your repository:

### 1. CLAUDE_CODE_OAUTH_TOKEN (Required)

**Purpose**: Authentication token for Claude Code API

**How to generate**:
```bash
# Install Claude Code CLI locally
npm install -g @anthropic-ai/claude-code

# Generate the OAuth token
claude setup-token
```

**Where to add**:
1. Go to your GitHub repository
2. Navigate to: Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `CLAUDE_CODE_OAUTH_TOKEN`
5. Value: Paste the token from `claude setup-token`

### 2. GH_PAT (Optional but Recommended)

**Purpose**: GitHub Personal Access Token with enhanced permissions

**Why needed**: The default `GITHUB_TOKEN` has limited permissions. A PAT allows:
- Workflow file modifications
- Creating branches and pull requests
- Enhanced API rate limits

**How to generate**:
1. Go to: https://github.com/settings/personal-access-tokens
2. Click "Generate new token" (Fine-grained token recommended)
3. Give it a descriptive name (e.g., "SDLC Claude Code")
4. Select Permissions:
   - **Repository permissions**:
     - Administration: Read and write
     - Contents: Read and write
     - Issues: Read and write
     - Pull requests: Read and write
     - Workflows: Read and write
5. Click "Generate token"
6. Copy the token immediately

**Where to add**:
1. Repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `GH_PAT`
4. Value: Paste the generated token

## GitHub Actions Workflow Requirements

### Permissions

The workflow file (`.github/workflows/claude.yml`) requires these permissions:

```yaml
permissions:
  contents: write       # Push commits and branches
  pull-requests: write  # Create and manage PRs
  issues: write         # Comment on issues
```

### Runner Configuration

- **Runs on**: `self-hosted` label
- **Concurrent executions**: Up to 5 runners (configurable via docker-compose)

### Trigger Events

The workflow is triggered on:
- `issue_comment`: When someone comments on an issue (checks for @claude mention)
- `pull_request_review_comment`: When someone comments on a PR (checks for @claude mention)
- `issues`: When an issue is opened/edited (checks for @claude mention)
- `pull_request_review`: When a PR review is submitted (checks for @claude mention)

## Claude Code CLI Requirements

### Installation (for local use)

```bash
# Via npm (recommended)
npm install -g @anthropic-ai/claude-code

# Verify installation
claude --version
```

### Configuration

The Claude Code CLI requires:

1. **OAuth Token**: Set via environment variable or login
   ```bash
   export CLAUDE_CODE_OAUTH_TOKEN="your-token-here"
   ```

2. **Project Directory**: Must be run in a git repository

3. **Permissions**: Uses `--dangerously-skip-permissions` flag in containerized environment

### Command Line Arguments

The entrypoint script uses these Claude Code arguments:

- `--continue`: Continue from previous conversation state
- `--print`: Print output to stdout
- `--dangerously-skip-permissions`: Skip permission checks (safe in container)
- `--system-prompt`: Custom system prompt from `.github/sdlc/claude-system-prompt.md`

## Network Requirements

### Outbound Connections Required

1. **Claude AI API**:
   - Domain: `*.anthropic.com`
   - Port: 443 (HTTPS)
   - Purpose: Claude Code API requests

2. **GitHub API**:
   - Domain: `api.github.com`
   - Port: 443 (HTTPS)
   - Purpose: Repository operations, comments, PRs

3. **GitHub Content**:
   - Domain: `github.com`
   - Port: 443 (HTTPS)
   - Purpose: Git clone/push operations

4. **GitHub CLI Packages**:
   - Domain: `cli.github.com`
   - Port: 443 (HTTPS)
   - Purpose: GitHub CLI installation

5. **NVM/Node.js**:
   - Domain: `raw.githubusercontent.com`
   - Port: 443 (HTTPS)
   - Purpose: Node.js installation

## File Structure Requirements

### Required Files

```
.github/
├── workflows/
│   └── claude.yml                          # Main workflow file
└── sdlc/
    ├── README.md                           # Setup documentation
    ├── claude-system-prompt.md             # Custom system prompt
    ├── claude-code-runner/
    │   ├── Dockerfile                      # Claude Code container
    │   └── entrypoint.sh                   # Container entrypoint
    └── github-runner/
        ├── Dockerfile                      # GitHub runner container
        └── docker-compose.yml              # Multi-runner orchestration
```

### Required Repository Structure

- Must be a valid Git repository
- Must have a default branch (main/master)
- Must have GitHub Actions enabled

## Anthropic Account Requirements

### Account Setup

1. **Create Account**: https://console.anthropic.com
2. **Billing**:
   - Free tier available (limited usage)
   - Paid plans recommended for production use (Pro/Max)
   - API credits required for Claude Code operations

### API Access

- API key/OAuth token must be active
- Sufficient API credits for operations
- Rate limits apply based on account tier

## Optional Enhancements

### Model Configuration

You can specify different Claude models via the `--model` flag:
- `claude-sonnet-4-5-20250929` (default)
- `claude-opus-4-5` (more capable, higher cost)
- `claude-haiku-4-5` (faster, lower cost)

### MCP Configuration

The Claude Code CLI supports Model Context Protocol (MCP) servers for extended functionality:
- Configure via `--mcp-config` argument
- Requires separate MCP server setup

### Custom Commands

Add custom slash commands in `.claude/commands/` directory for project-specific workflows.

## Verification Checklist

Use this checklist to verify all requirements are met:

- [ ] Docker and Docker Compose installed
- [ ] Claude Code OAuth token generated and added to GitHub secrets
- [ ] GitHub PAT (optional) generated and added to GitHub secrets
- [ ] Repository has GitHub Actions enabled
- [ ] Self-hosted runners configured and running
- [ ] `.github/workflows/claude.yml` file present
- [ ] `.github/sdlc/claude-system-prompt.md` file present
- [ ] Docker images built (`sdlc-claude:latest`)
- [ ] Network access to required domains
- [ ] Anthropic account with active API access
- [ ] Git configured on runners

## Troubleshooting

### Common Issues

1. **"CLAUDE_CODE_OAUTH_TOKEN is required" error**
   - Ensure the secret is added to GitHub repository secrets
   - Verify the secret name matches exactly

2. **"No runners available" error**
   - Check that self-hosted runners are online
   - Verify runners have the correct labels

3. **Claude Code installation fails**
   - Check internet connectivity
   - Verify Node.js version is 18+

4. **Git authentication fails**
   - Verify GITHUB_TOKEN or GH_PAT is valid
   - Check repository permissions

## Additional Resources

- [Claude Code Official Docs](https://docs.claude.com/en/docs/claude-code)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Claude Code GitHub Action](https://github.com/anthropics/claude-code-action)
- [Self-hosted Runners Guide](https://docs.github.com/en/actions/hosting-your-own-runners)

## Support

For issues specific to this setup, please create an issue in this repository with:
- Error messages and logs
- Steps to reproduce
- Environment details (Docker version, OS, etc.)

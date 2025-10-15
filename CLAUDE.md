# SDLC - Claude Code Infrastructure

## Project Overview

This project provides a self-hosted GitHub Actions infrastructure that integrates Claude Code to automatically handle GitHub issues. When someone mentions @claude in an issue or pull request, Claude will analyze the request, implement solutions, and create pull requests for review.

## Architecture

### Components

1. **GitHub Actions Runners** (`.github/sdlc/github-runner/`)
   - Self-hosted runners that execute workflows
   - Deployed using Docker containers
   - Scalable to multiple runner instances

2. **Claude Code Runner** (`.github/sdlc/claude-code-runner/`)
   - Custom Docker image with Claude Code installed
   - Handles AI-powered code generation and issue resolution
   - Integrates with GitHub API via OAuth token

3. **Main Setup Script** (`sdlc.sh`)
   - Orchestrates the entire setup process
   - Builds Docker images
   - Configures runner authentication
   - Manages runner lifecycle (start/stop)

## Key Files

- `sdlc.sh` - Main entry point for setup and runner management
- `.github/sdlc/github-runner/.env` - Runner configuration (created during setup)
- `.github/workflows/*.yml` - GitHub Actions workflows for Claude integration
- `.claude/commands/` - Custom slash commands for Claude Code
- `.claude/settings.json` - Project-specific Claude Code configuration

## Configuration Requirements

### GitHub Personal Access Token
- Required scope: `repo` (Full control of private repositories)
- Used for runner registration
- Created at: https://github.com/settings/tokens

### Claude Code OAuth Token
- Stored as GitHub Secret: `CLAUDE_CODE_OAUTH_TOKEN`
- Required for Claude API access
- Configured in: Settings → Secrets and variables → Actions

### Repository Format
- Format: `owner/repo-name`
- Example: `vgmello/sdlc`

## Workflow

1. **Setup Phase** (`./sdlc.sh --setup`)
   - Validates Docker installation
   - Builds Claude Code container
   - Collects configuration (GitHub token, repository)
   - Creates `.env` file with credentials

2. **Runtime Phase** (`./sdlc.sh`)
   - Starts 5 self-hosted GitHub Actions runners
   - Runners listen for workflow triggers
   - When @claude is mentioned in an issue:
     - Workflow is triggered
     - Claude Code analyzes the request
     - Implements solution on a feature branch
     - Creates a pull request for review

3. **Monitoring**
   - Check runner status: `docker-compose ps`
   - View logs: `docker-compose logs -f`
   - Verify in GitHub: Settings → Actions → Runners

## Custom Commands

- `/setup-sdlc` - Guide through initial infrastructure setup
- `/debug-runners` - Troubleshoot runner issues
- `/analyze-issue <number>` - Detailed issue breakdown and planning
- `/review-sdlc` - Audit infrastructure for improvements

## Security Considerations

- Tokens are stored in `.env` (gitignored)
- OAuth token stored as encrypted GitHub Secret
- Runners have repo-level access only
- Self-hosted runners run in isolated Docker containers

## Common Tasks

### First-Time Setup
```bash
./sdlc.sh --setup
```

### Start Runners
```bash
./sdlc.sh
```

### Stop Runners
```bash
cd .github/sdlc/github-runner && docker-compose down
```

### View Runner Logs
```bash
cd .github/sdlc/github-runner && docker-compose logs -f
```

### Rebuild Claude Code Container
```bash
docker build -t sdlc-claude:latest .github/sdlc/claude-code-runner/
```

## Troubleshooting

### Runners Not Appearing in GitHub
- Verify `.env` file has correct token and repository
- Check token permissions (need `repo` scope)
- Review runner logs for authentication errors

### Claude Not Responding to Issues
- Verify `CLAUDE_CODE_OAUTH_TOKEN` secret is set
- Check workflow file is properly configured
- Ensure @claude mention is in issue description or comment

### Docker Build Failures
- Update base images in Dockerfiles
- Check network connectivity
- Verify Docker daemon is running

## Development Notes

- Always work on feature branches
- Create PRs to `main` branch for review
- Use slash commands for common operations
- Keep CLAUDE.md updated with project changes
- Test changes locally before deploying to production runners

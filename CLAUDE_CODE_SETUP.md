# Claude Code Setup Guide

This document explains the Claude Code integration setup for the SDLC repository.

## Overview

This repository is now configured with Claude Code, providing:

1. **Custom Slash Commands** - Quick access to common SDLC operations
2. **Project Context** - Memory bank with project architecture and workflows
3. **Project Settings** - Optimized configuration for this codebase
4. **GitHub Actions Integration** - Automated issue handling via @claude mentions

## Directory Structure

```
.
├── .claude/
│   ├── commands/           # Custom slash commands
│   │   ├── setup-sdlc.md         # Guide for infrastructure setup
│   │   ├── debug-runners.md      # Troubleshoot runner issues
│   │   ├── analyze-issue.md      # Detailed issue analysis
│   │   └── review-sdlc.md        # Infrastructure audit
│   └── settings.json       # Project-specific configuration
├── CLAUDE.md               # Project memory bank (context for Claude)
└── CLAUDE_CODE_SETUP.md    # This file
```

## Custom Slash Commands

### `/setup-sdlc`
Guides you through setting up the SDLC infrastructure including:
- Docker/docker-compose installation verification
- Running `./sdlc.sh --setup`
- Configuring GitHub tokens and repository settings
- Setting up the CLAUDE_CODE_OAUTH_TOKEN secret

**Usage:**
```
/setup-sdlc
```

### `/debug-runners`
Troubleshoots GitHub Actions runner issues:
- Checks runner status with docker-compose
- Reviews logs for errors
- Verifies .env configuration
- Diagnoses authentication and connectivity problems
- Provides solutions for common issues

**Usage:**
```
/debug-runners
```

### `/analyze-issue <number>`
Analyzes a GitHub issue and creates an implementation plan:
- Fetches issue details from GitHub
- Identifies issue type (bug, feature, enhancement, etc.)
- Breaks down into actionable tasks
- Suggests solution approach
- Posts planning comment on the issue

**Usage:**
```
/analyze-issue 42
```

### `/review-sdlc`
Performs a comprehensive audit of the SDLC infrastructure:
- Reviews Docker configuration
- Checks GitHub Actions workflows
- Verifies security best practices
- Suggests improvements for performance, error handling, and documentation
- Provides detailed recommendations report

**Usage:**
```
/review-sdlc
```

## Project Settings (`.claude/settings.json`)

The settings file configures Claude Code behavior for this project:

- **Included Paths**: Focuses on key files (sdlc.sh, .github/sdlc/, workflows)
- **Excluded Paths**: Ignores sensitive files (.env), logs, and dependencies
- **Git Integration**: Enabled for seamless version control
- **Custom Commands**: Enabled and pointing to `.claude/commands/`

## CLAUDE.md Memory Bank

This file provides Claude with persistent context about:
- Project architecture and components
- Key files and their purposes
- Configuration requirements
- Common workflows and tasks
- Security considerations
- Troubleshooting guides

Claude automatically references this file when working on the project.

## GitHub Actions Integration

### Existing Workflows

#### 1. `claude.yml`
Triggers when @claude is mentioned in:
- Issue comments
- PR comments
- PR reviews
- New issues

**How it works:**
1. Extracts context (issue/PR number, type, message body)
2. Runs Claude Code in a Docker container with:
   - CLAUDE_CODE_OAUTH_TOKEN for API access
   - GitHub token for repo operations
   - Issue/PR context
3. Claude analyzes, implements, and creates PRs

#### 2. `cleanup-claude-state-workflow.yml`
Automatically cleans up Claude state branches when feature branches are deleted.

**Features:**
- Monitors branch deletions (issue-*, pr-*)
- Removes corresponding `claude-{type}-{number}` branches
- Posts cleanup notifications

## Requirements

### For Local Development

1. **Claude Code CLI** (optional for local use)
   ```bash
   npm install -g @anthropic-ai/claude-code
   ```

2. **Anthropic API Key**
   - Get from: https://console.anthropic.com/
   - Set as environment variable or in Claude Code config

### For GitHub Actions

1. **CLAUDE_CODE_OAUTH_TOKEN** (Required)
   - Store as repository secret
   - Path: Settings → Secrets and variables → Actions
   - Used by workflows to authenticate Claude API requests

2. **GH_PAT** (Optional)
   - Personal Access Token with `repo` + `workflow` scopes
   - Falls back to `GITHUB_TOKEN` if not provided
   - Needed for certain operations like triggering workflows

3. **Self-hosted Runners**
   - Set up using `./sdlc.sh --setup`
   - Requires Docker and docker-compose
   - Must have `sdlc-claude:latest` image built

## Getting Started

### Local Development with Claude Code

1. Install Claude Code CLI (if not already installed)
2. Clone the repository
3. Run Claude Code in the project directory
4. Use slash commands like `/setup-sdlc` or `/debug-runners`

### GitHub Actions Integration

1. Ensure self-hosted runners are set up and running
2. Configure CLAUDE_CODE_OAUTH_TOKEN secret
3. Mention @claude in any issue or PR
4. Claude will respond and handle the request automatically

## Usage Examples

### Example 1: Setting Up Infrastructure
```
Comment on issue: @claude /setup-sdlc
```
Claude guides you through the complete setup process.

### Example 2: Debugging Runner Issues
```
Comment on issue: @claude /debug-runners
```
Claude diagnoses and helps fix runner problems.

### Example 3: Analyzing a Bug Report
```
Comment on issue: @claude /analyze-issue 123
```
Claude analyzes issue #123 and provides a detailed implementation plan.

### Example 4: Infrastructure Review
```
Comment on issue: @claude /review-sdlc
```
Claude audits the entire SDLC setup and suggests improvements.

### Example 5: Custom Request
```
Comment on issue: @claude Add logging to the runner startup process
```
Claude implements the requested feature and creates a PR.

## Best Practices

### For Issues and PRs

1. **Be Specific**: Clearly describe what you need
2. **Provide Context**: Mention relevant files, errors, or goals
3. **Review PRs**: Always review Claude's work before merging
4. **Give Feedback**: Comment on PRs to help Claude learn preferences

### For Custom Commands

1. **Keep Commands Focused**: One clear purpose per command
2. **Use $ARGUMENTS**: Make commands flexible with parameters
3. **Document Usage**: Include usage examples in command files
4. **Test Locally**: Verify commands work before committing

### For Project Maintenance

1. **Update CLAUDE.md**: Keep project context current
2. **Evolve Commands**: Add new commands for repeated workflows
3. **Review Settings**: Adjust included/excluded paths as needed
4. **Monitor Workflows**: Check runner logs and GitHub Actions

## Troubleshooting

### Slash Commands Not Working

- Ensure you're in the project directory
- Verify `.claude/commands/` contains .md files
- Check file permissions

### Claude Not Responding to @mentions

- Verify CLAUDE_CODE_OAUTH_TOKEN is set
- Check runners are online (Settings → Actions → Runners)
- Review workflow logs for errors
- Ensure @claude is in the issue/comment body

### Runners Not Starting

- Run `/debug-runners` for diagnostics
- Check Docker daemon is running
- Verify `.env` file configuration
- Review runner logs: `docker-compose logs -f`

## Security Notes

- **Never commit tokens**: .env file is gitignored
- **Use secrets**: Store tokens in GitHub Secrets
- **Limit permissions**: Runners have repo-level access only
- **Review PRs**: Always review Claude's code before merging
- **Audit regularly**: Use `/review-sdlc` for security checks

## Additional Resources

- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)
- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Documentation](https://docs.docker.com/)

## Support

For questions or issues with this setup:
1. Use `/debug-runners` or `/review-sdlc` commands
2. Create an issue and mention @claude
3. Review CLAUDE.md for project context
4. Check workflow logs in GitHub Actions

---

**Last Updated**: October 2025
**Claude Code Version**: Latest
**Repository**: vgmello/sdlc

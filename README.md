# SDLC - Software Development Lifecycle with Claude Code

A self-hosted GitHub Actions infrastructure that integrates Claude Code AI assistant directly into your development workflow. Simply mention `@claude` in GitHub issues or pull requests, and Claude will autonomously work on your tasks.

## Features

- **AI-Powered Development**: Mention `@claude` in issues or PRs to get AI assistance
- **Self-Hosted Runners**: Run GitHub Actions runners on your own infrastructure
- **Docker-Based**: Containerized solution for easy deployment and scaling
- **Scalable**: Configure multiple parallel runners for concurrent tasks
- **Secure**: Uses GitHub Personal Access Tokens with proper scopes
- **Flexible**: Works with both repository-level and organization-level runners
- **GLM 4.6 Support (Experimental)**: Option to use Z.AI's GLM models as a drop-in replacement

## Prerequisites

- Docker (v20.10 or later)
- docker-compose (v1.29 or later)
- GitHub repository with admin access
- **Either:**
  - Claude Code OAuth token (for standard Anthropic Claude), OR
  - Z.AI API key (for experimental GLM 4.6 support)
- GitHub Personal Access Token with appropriate scopes:
  - For repository runners: `repo` (Full control of private repositories)
  - For organization runners: `admin:org` (Full control of orgs and teams)

## Quick Start

### 1. Initial Setup

Run the setup script to configure your environment:

```bash
./sdlc.sh --setup
```

This will:
- Build the Claude Code Docker container
- Prompt for your GitHub token
- Configure your repository or organization
- Set up runner preferences (prefix, number of runners)
- Create the necessary `.env` configuration file

### 2. Configure GitHub Secrets

In your GitHub repository settings:
1. Go to **Settings → Secrets and variables → Actions**
2. Add the following secret:
   - `CLAUDE_CODE_OAUTH_TOKEN`: Your Claude Code OAuth token

Optional:
   - `GH_PAT`: A GitHub Personal Access Token with `repo` and `workflow` scopes

### 3. Start the Runners

```bash
./sdlc.sh
```

This starts the self-hosted GitHub Actions runners using docker-compose.

### 4. Verify Runners

Check that your runners are online:
1. Go to **Settings → Actions → Runners** in your GitHub repository
2. You should see your configured number of runners (default: 5) online

### 5. Use Claude Code

Create an issue or comment on a PR and mention `@claude` with your request:

```
@claude add unit tests for the authentication module
```

Claude will:
- Create a feature branch following the pattern `issue-{number}-{description}`
- Work on your request autonomously
- Create a pull request with the changes
- Post updates and ask questions as needed

## Usage

### Start Runners

```bash
./sdlc.sh
```

### Stop Runners

```bash
./sdlc.sh --stop
```

### View Runner Status

```bash
cd .github/sdlc/github-runner
docker-compose -p sdlc ps
```

### View Logs

```bash
cd .github/sdlc/github-runner
docker-compose -p sdlc logs -f
```

### Reconfigure

To change your configuration:
1. Delete the existing configuration file:
   ```bash
   rm .github/sdlc/github-runner/.env
   ```
2. Run setup again:
   ```bash
   ./sdlc.sh --setup
   ```

## How It Works

1. **Trigger**: When you mention `@claude` in an issue or PR, the GitHub Actions workflow is triggered
2. **Permission Check**: The workflow verifies the user has write access or higher
3. **Context Extraction**: The workflow extracts the issue/PR context
4. **Claude Execution**: Claude Code runs in a Docker container with access to your repository
5. **Autonomous Work**: Claude analyzes, makes changes, runs tests, and creates pull requests

## Configuration

The `.env` file in `.github/sdlc/github-runner/` contains:

```env
# Your GitHub Personal Access Token
GITHUB_TOKEN=ghp_...

# Repository (owner/repo) or Organization name
GITHUB_REPOSITORY=owner/repo-name

# Runner scope: 'repo' or 'org'
RUNNER_SCOPE=repo

# Prefix for runner names
RUNNER_PREFIX=my-hostname

# Number of parallel runners
RUNNER_REPLICATIONS=5

# GLM 4.6 Support (Experimental)
USE_GLM=false
ZAI_API_KEY=
```

## GLM 4.6 Support (Experimental)

SDLC now supports using Z.AI's GLM 4.6 models as an experimental alternative to Anthropic's Claude models. This feature allows you to:

- Use GLM-4.6 for high-quality code generation (replaces both Sonnet and Opus; both are mapped to the same GLM-4.6 model variant)
- Use GLM-4.5-Air for faster responses (replaces Haiku)
- Connect to Z.AI's API endpoint as a drop-in replacement

### Setting Up GLM 4.6

1. **Get a Z.AI API Key**:
   - Visit [Z.AI Open Platform](https://z.ai/model-api)
   - Register or login to your account
   - Create an API key in the [API Keys management page](https://z.ai/manage-apikey/apikey-list)
   - Copy your API key for use in setup

2. **Configure During Setup**:
   When running `./sdlc.sh --setup`, answer "yes" when prompted about GLM 4.6 support and provide your Z.AI API key.

3. **Manual Configuration**:
   Alternatively, edit `.github/sdlc/github-runner/.env` and set:
   ```env
   USE_GLM=true
   ZAI_API_KEY=your_zai_api_key_here
   ```

4. **GitHub Secrets**:
   - When using GLM, you still need to set `CLAUDE_CODE_OAUTH_TOKEN` in GitHub Secrets
   - The system will use the Z.AI API key for model access instead

### Model Mapping

When GLM support is enabled, Claude Code's model selection maps to:

| Claude Code Model | GLM Model      | Use Case               |
|-------------------|----------------|------------------------|
| Opus              | GLM-4.6        | Complex tasks          |
| Sonnet            | GLM-4.6        | Balanced performance   |
| Haiku             | GLM-4.5-Air    | Fast responses         |

### Important Notes

- This is an **experimental feature** - behavior may differ from standard Claude
- API timeout is set to 3000 seconds (50 minutes) for long-running tasks
- The Z.AI endpoint (`https://api.z.ai/api/anthropic`) provides Anthropic-compatible API
- You can switch back to standard Claude by setting `USE_GLM=false` in the `.env` file

## Project Structure

```
.
├── sdlc.sh                          # Main setup and control script
├── .github/
│   ├── workflows/
│   │   └── claude.yml              # Claude Code workflow
│   └── sdlc/
│       ├── github-runner/          # GitHub Actions runner setup
│       └── claude-code-runner/     # Claude Code container setup
├── LICENSE                         # MIT License
├── README.md                       # This file
└── .gitignore                      # Git ignore patterns
```

## Branch Naming Convention

Claude automatically creates branches following this pattern:
```
issue-{issue-number}-{description}
```

Examples:
- `issue-42-implement-user-auth`
- `issue-123-fix-login-bug`

## Troubleshooting

### Runners not showing up in GitHub

1. Check runner logs:
   ```bash
   cd .github/sdlc/github-runner
   docker-compose -p sdlc logs github-runner
   ```
2. Verify your GitHub token has correct scopes
3. Ensure the repository/organization name is correct in `.env`

### Claude not responding

1. Verify `CLAUDE_CODE_OAUTH_TOKEN` is set in GitHub Secrets
2. Check the workflow run logs in **Actions** tab
3. Ensure you mentioned `@claude` in the issue/PR
4. Verify you have write access or higher to the repository

### Docker build failures

1. Ensure Docker is running:
   ```bash
   docker ps
   ```
2. Rebuild the Claude Code container:
   ```bash
   ./sdlc.sh --setup
   ```

## Security Considerations

- **Tokens**: Store GitHub tokens and Claude OAuth tokens securely in GitHub Secrets
- **Self-Hosted Runners**: Runners have access to your infrastructure; only use in trusted repositories
- **Permissions**: Claude requires write access to make code changes; review all PRs before merging
- **Environment Files**: Never commit `.env` files with sensitive tokens to version control

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- **Issues**: [GitHub Issues](https://github.com/vgmello/sdlc/issues)
- **Documentation**: This README and inline code comments

## Acknowledgments

- Built with [Claude Code](https://claude.ai/claude-code) by Anthropic
- Uses GitHub Actions self-hosted runners
- Containerized with Docker

---

**Made with ❤️ and AI assistance**

# SDLC - Self-Hosted Claude Code for GitHub Actions

Automate your development workflow with Claude Code AI running on self-hosted GitHub Actions runners. Simply mention `@claude` in any issue or pull request, and Claude will autonomously work on your request.

## 🌟 Features

- **AI-Powered Automation**: Leverage Claude AI for code generation, bug fixes, and development tasks
- **GitHub Integration**: Seamlessly integrates with GitHub Issues and Pull Requests
- **Self-Hosted**: Run on your own infrastructure with full control
- **Docker-Based**: Easy deployment with Docker containers
- **Stateful Conversations**: Maintains context across interactions
- **Automated PR Creation**: Claude creates pull requests when work is complete

## 📋 Requirements

For detailed requirements, see [REQUIREMENTS.md](./REQUIREMENTS.md).

### Quick Requirements Summary

- Docker and Docker Compose
- A GitHub repository
- Claude Code OAuth token (from Anthropic)
- Optional: GitHub Personal Access Token (recommended)

## 🚀 Quick Start

### Step 1: Generate Claude OAuth Token

Install Claude Code CLI locally and generate your authentication token:

```bash
# Install Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Generate OAuth token
claude setup-token
```

Copy the token value that is displayed.

### Step 2: Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to: **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secret:
   - Name: `CLAUDE_CODE_OAUTH_TOKEN`
   - Value: Paste the token from Step 1

### Step 3: (Optional) Generate GitHub Personal Access Token

For enhanced permissions (recommended):

1. Go to: https://github.com/settings/personal-access-tokens
2. Click **Generate new token** → Fine-grained token
3. Give it a descriptive name (e.g., "SDLC Self-hosted Runner")
4. Select Repository access: Your target repository
5. Select Permissions:
   - **Administration**: Read and write
   - **Contents**: Read and write
   - **Issues**: Read and write
   - **Pull requests**: Read and write
   - **Workflows**: Read and write
6. Click **Generate token** and copy it
7. Add to GitHub secrets as `GH_PAT`

### Step 4: Run Setup

Run the setup script and provide the required information:

```bash
./sdlc.sh --setup
```

The script will:
- Build the Claude Code Docker container
- Prompt you for:
  - **GitHub Token**: Your PAT from Step 3 (or use default workflow token)
  - **Repository**: Your repository in format `owner/repo-name`
  - **Runner Prefix**: (Optional) A prefix for your runner names
- Create the runner configuration automatically

### Step 5: Start the Runners

```bash
./sdlc.sh
```

This will start 5 self-hosted GitHub Actions runners by default.

### Step 6: Verify Setup

1. Go to your repository: **Settings** → **Actions** → **Runners**
2. You should see 5 runners online (e.g., `gh-runner-1`, `gh-runner-2`, etc.)

## 💬 Usage

Simply mention `@claude` in:

- Issue descriptions or comments
- Pull request descriptions or comments
- Pull request reviews

### Example: Request New Feature

```
@claude please add a user authentication module with login and signup functionality
```

### Example: Fix a Bug

```
@claude there's a memory leak in the data processing module, can you investigate and fix it?
```

### Example: Add Tests

```
@claude add comprehensive unit tests for the API endpoints in src/api/
```

### Example: Refactor Code

```
@claude refactor the database connection logic to use connection pooling
```

## 🔄 How It Works

1. **Trigger**: You mention `@claude` in an issue or PR
2. **Workflow Activation**: GitHub Actions workflow detects the mention
3. **Task Analysis**: Claude analyzes your request and creates a task breakdown
4. **Implementation**: Claude works autonomously on the task
5. **Progress Updates**: Claude posts comments with progress updates
6. **Pull Request**: When complete, Claude creates a PR with the changes
7. **Review**: You review and merge the PR

## 📁 Project Structure

```
.
├── README.md                           # This file
├── REQUIREMENTS.md                     # Detailed requirements documentation
├── package.json                        # Node.js dependencies
├── requirements.txt                    # Python dependencies (reference)
├── sdlc.sh                            # Main control script
└── .github/
    ├── workflows/
    │   ├── claude.yml                 # Claude Code workflow
    │   └── cleanup-claude-state-workflow.yml
    └── sdlc/
        ├── README.md                  # SDLC setup guide
        ├── claude-system-prompt.md    # System prompt for Claude
        ├── claude-code-runner/
        │   ├── Dockerfile             # Claude Code container
        │   └── entrypoint.sh          # Container entrypoint script
        └── github-runner/
            ├── Dockerfile             # GitHub Actions runner
            └── docker-compose.yml     # Multi-runner orchestration
```

## 🛠️ Management Commands

```bash
# Start runners
./sdlc.sh

# Setup or reconfigure
./sdlc.sh --setup

# Stop all runners
./sdlc.sh --stop

# View logs
./sdlc.sh --logs

# Build Docker image manually
npm run build

# Or with Docker directly
docker build -t sdlc-claude:latest .github/sdlc/claude-code-runner/
```

## 🔧 Configuration

### Workflow Configuration

Edit `.github/workflows/claude.yml` to customize:
- Trigger conditions
- Runner labels
- Permissions
- Environment variables

### System Prompt Customization

Edit `.github/sdlc/claude-system-prompt.md` to customize Claude's behavior:
- Project-specific guidelines
- Coding standards
- Documentation requirements
- Commit message formats

### Runner Scaling

Edit `.github/sdlc/github-runner/docker-compose.yml` to adjust the number of concurrent runners.

## 🔒 Security Considerations

- **Secrets Management**: Store sensitive tokens in GitHub Secrets only
- **Self-Hosted Runners**: Run in a secure, isolated environment
- **Code Review**: Always review Claude's PRs before merging
- **Branch Protection**: Enable branch protection rules on main/master
- **Token Permissions**: Use minimal required permissions for tokens

## 📊 Monitoring

### View Runner Status

```bash
# Check if runners are online
./sdlc.sh --logs

# View GitHub Actions runs
# Go to: Repository → Actions
```

### Check Docker Containers

```bash
# List running containers
docker ps | grep gh-runner

# View specific runner logs
docker logs gh-runner-1
```

## 🐛 Troubleshooting

### Runners Not Starting

1. Check Docker is running: `docker ps`
2. Verify GitHub token has correct permissions
3. Check logs: `./sdlc.sh --logs`

### Claude Not Responding

1. Verify `CLAUDE_CODE_OAUTH_TOKEN` secret is set
2. Check Anthropic account has API credits
3. Review workflow runs in GitHub Actions tab

### Authentication Errors

1. Regenerate GitHub PAT with correct permissions
2. Update `GH_PAT` secret in repository settings
3. Restart runners: `./sdlc.sh --stop && ./sdlc.sh`

### Docker Image Issues

```bash
# Rebuild the image
npm run build

# Or manually
docker build -t sdlc-claude:latest .github/sdlc/claude-code-runner/

# Verify image exists
docker images | grep sdlc-claude
```

## 📖 Additional Documentation

- [REQUIREMENTS.md](./REQUIREMENTS.md) - Complete requirements and dependencies
- [.github/sdlc/README.md](./.github/sdlc/README.md) - SDLC setup guide
- [Claude Code Documentation](https://docs.claude.com/en/docs/claude-code)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

You can even ask Claude to help with contributions:

```
@claude please review my changes and suggest improvements
```

## 📜 License

MIT License - see LICENSE file for details

## 🙏 Acknowledgments

- [Anthropic](https://anthropic.com) for Claude AI and Claude Code
- [GitHub](https://github.com) for Actions platform
- The open-source community

## 💡 Tips for Best Results

1. **Be Specific**: Provide clear, detailed requests to Claude
2. **Provide Context**: Reference specific files or functions when relevant
3. **Review Changes**: Always review PRs before merging
4. **Iterative Refinement**: Claude can iterate on its own work - just ask!
5. **Use Examples**: Show Claude examples of what you want

## 🔗 Links

- [Anthropic Console](https://console.anthropic.com) - Manage API keys
- [Claude Code CLI](https://github.com/anthropics/claude-code) - Official repository
- [GitHub Actions](https://github.com/features/actions) - Workflow automation

---

**Ready to get started?** Run `./sdlc.sh --setup` and mention `@claude` in your next issue!

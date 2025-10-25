# SDLC - Software Development Lifecycle with Claude Code

A self-hosted GitHub Actions infrastructure that integrates Claude Code AI assistant directly into your development workflow. Simply mention `@claude` in GitHub issues or pull requests, and Claude will autonomously work on your tasks.

## Features

- **AI-Powered Development**: Mention `@claude` in issues or PRs to get AI assistance
- **Self-Hosted Runners**: Run GitHub Actions runners on your own infrastructure
- **Docker-Based**: Containerized solution for easy deployment and scaling
- **Scalable**: Configure multiple parallel runners for concurrent tasks
- **Secure**: Uses GitHub Personal Access Tokens with proper scopes
- **Flexible**: Works with both repository-level and organization-level runners

## Prerequisites

- Docker (v20.10 or later)
- docker-compose (v1.29 or later)
- GitHub repository with admin access
- Claude Code OAuth token
- GitHub Personal Access Token with appropriate scopes:
  - For repository runners: `repo` (Full control of private repositories)
  - For organization runners: `admin:org` (Full control of orgs and teams)

**⚠️ Important Note on Docker Configuration:**

This setup requires **non-default Docker socket permissions** to enable GitHub Actions workflows to execute Docker commands. The runner containers automatically configure `chmod 666` on `/var/run/docker.sock` to allow workflow execution. This is a standard approach for containerized CI/CD environments but differs from default Docker security settings.

**Why This May Be Needed:**
- **Docker Desktop (macOS/Windows)**: Docker socket GID varies by installation and OS version
- **Linux Distributions**: Different distros assign different GIDs to the docker group (e.g., 999, 998, 127)
- **Docker Alternatives**: Colima, Rancher Desktop, Podman use different permission models
- **GitHub Actions Context**: Workflow steps execute in separate process contexts where group membership doesn't propagate

**Our Approach:**
Instead of requiring manual configuration for each environment, the runner automatically:
1. Detects the host's Docker socket GID
2. Creates matching group inside container
3. Sets socket to world-readable/writable (666) for workflow compatibility

See [DOCKER_PERMISSIONS_FIX.md](DOCKER_PERMISSIONS_FIX.md) for complete technical details.

## Quick Start

### 1. Verify Docker Setup (Recommended)

Before setting up, verify your Docker installation and permissions:

```bash
./sdlc.sh --fix-permissions
```

This diagnostic tool will:
- Check if Docker is installed and running
- Verify your user has permission to run Docker commands
- Test Docker socket access from containers
- Detect your Docker socket GID and configuration
- Provide platform-specific guidance if issues are found

**Note:** This is especially important if you're using:
- macOS with Docker Desktop (any version)
- Linux with non-standard Docker installation
- Docker alternatives (Colima, Rancher Desktop, Podman)
- Any system where you've encountered "permission denied" errors with Docker

### 2. Initial Setup

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
- **Verify Docker permissions before proceeding**

### 3. Configure GitHub Secrets

In your GitHub repository settings:
1. Go to **Settings → Secrets and variables → Actions**
2. Add the following secret:
   - `CLAUDE_CODE_OAUTH_TOKEN`: Your Claude Code OAuth token

Optional:
   - `GH_PAT`: A GitHub Personal Access Token with `repo` and `workflow` scopes

### 4. Start the Runners

```bash
./sdlc.sh
```

This starts the self-hosted GitHub Actions runners using docker-compose.

### 5. Verify Runners

Check that your runners are online:
1. Go to **Settings → Actions → Runners** in your GitHub repository
2. You should see your configured number of runners (default: 5) online

### 6. Use Claude Code

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
```

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

### Docker Permission Issues

**Understanding the Docker Socket Configuration:**

This SDLC setup uses a **non-default Docker socket permission configuration** to enable GitHub Actions workflow steps to execute Docker commands.

#### Why This Problem Occurs

Docker permission issues manifest differently across environments due to:

**1. Variable Docker Socket GIDs Across Systems:**
- **macOS (Docker Desktop)**: GID varies by Docker Desktop version and installation method
- **Linux**: Each distribution assigns different GIDs to the docker group
  - Ubuntu/Debian: Often GID 999
  - Fedora/RHEL: Often GID 998
  - Arch: Often GID 127
- **Docker Alternatives**: Colima, Rancher Desktop, Podman each have unique permission models

**2. Container UID/GID Mismatch:**
- Host's Docker socket has a specific GID (e.g., 999 on host)
- Container creates a `runner` user with a different UID/GID
- Simply mounting the socket doesn't grant access due to GID mismatch

**3. GitHub Actions Workflow Execution Model:**
- Runner process itself can be added to docker group (standard approach works here)
- Workflow steps run in **separate process contexts**
- Group membership from runner process **does not propagate** to workflow steps
- Result: `docker` commands in workflow steps fail with "permission denied"

#### Why Some Machines Work and Others Don't

✅ **Works by default if:**
- Docker socket happens to be world-readable on the host (rare)
- User is running workflows as root (not recommended)
- GID coincidentally matches between host and container

❌ **Fails on most systems:**
- Standard Docker installations with proper security (most common)
- When GIDs don't align between host and container
- When workflow steps need Docker access (the typical use case)

#### Our Three-Tier Solution

1. **Runner Process**: The runner user is added to a docker group with matching GID (standard approach)
2. **Group Creation**: Container dynamically creates/joins group with host's Docker socket GID
3. **Workflow Access**: Entrypoint sets `chmod 666` on socket to enable workflow step execution

**Why `chmod 666` is necessary:**
- Group membership works for the runner process
- Group membership does NOT work for workflow steps (different process context)
- Socket must be world-accessible within container for workflows to use Docker
- Socket is only exposed within container, not to host system

**Security Note:** The socket is only exposed within the container environment, not to the host system. This is acceptable and standard for self-hosted runners in controlled environments. The container itself provides isolation.

#### Diagnostic and Fix Tool

If you encounter Docker permission errors:

```bash
./sdlc.sh --fix-permissions
```

This diagnostic tool will:
- Check if Docker is installed and running
- Verify user permissions to run Docker commands
- Test Docker socket access from containers
- Provide platform-specific solutions

**Common issues:**

**On macOS:**
- Ensure Docker Desktop is running
- Check the whale icon in the menu bar
- Restart Docker Desktop if needed

**On Linux:**
- Add your user to the docker group: `sudo usermod -aG docker $USER`
- Log out and back in, or run: `newgrp docker`
- Ensure Docker service is running: `sudo systemctl start docker`

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

## Technical Details: Docker Socket Permissions

### The Complete Permission Solution

This implementation provides a comprehensive solution to Docker socket access that works across different environments:

#### Problem Statement

Standard approaches fail because:
1. **Group membership approach**: Works for runner process but NOT for GitHub Actions workflow steps
2. **Process isolation**: Workflow steps execute in separate contexts where group membership doesn't propagate
3. **GID variability**: Docker socket GIDs differ across systems (macOS: variable, Ubuntu: 999, Fedora: 998, etc.)

#### Implementation Details

**At Container Startup** (`entrypoint.sh`):

```bash
# 1. Detect Docker socket GID from host
DOCKER_SOCK_GID=$(stat -c '%g' /var/run/docker.sock)

# 2. Create or find group with matching GID
# Handles conflicts if "docker" name is already taken
getent group "$DOCKER_SOCK_GID" || groupadd -g "$DOCKER_SOCK_GID" docker

# 3. Add runner user to the group
usermod -aG docker runner

# 4. Set socket permissions for workflow access
chmod 666 /var/run/docker.sock
```

**Why Each Step is Necessary:**

| Step | Purpose | What It Solves |
|------|---------|----------------|
| GID Detection | Match host's docker socket GID | Works with any Docker installation |
| Group Creation | Establish proper group ownership | Runner process gets docker access |
| User Addition | Add runner to docker group | Standard permission model |
| chmod 666 | Enable workflow step access | **Critical for GitHub Actions workflows** |

#### Alternative Approaches Considered

❌ **Group membership only**: Fails for workflow steps (different process context)
❌ **DinD (Docker-in-Docker)**: Complex, security concerns, resource overhead
❌ **Hardcoded GIDs**: Breaks on different systems
✅ **Dynamic GID + chmod 666**: Works universally, acceptable security model for self-hosted

#### Security Model

**Container Isolation Provides Security:**
- Socket with 666 permissions is only accessible **within the container**
- Host system's socket remains protected by host permissions
- Container provides the security boundary
- Acceptable for self-hosted runners in controlled environments

**Not Recommended For:**
- Public, untrusted runner environments
- Multi-tenant systems with untrusted code

**Recommended For:**
- Self-hosted runners in controlled infrastructure
- Private repositories with trusted developers
- CI/CD pipelines in secured networks

For complete technical documentation, see [DOCKER_PERMISSIONS_FIX.md](DOCKER_PERMISSIONS_FIX.md).

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

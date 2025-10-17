FROM mcr.microsoft.com/dotnet/sdk:9.0-noble

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies as root
RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    git \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    sudo \
    wget && \
    #
    # Install GitHub CLI
    mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O /tmp/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    cat /tmp/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
    tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y gh && \
    #
    # Cleanup
    rm -rf /var/lib/apt/lists/* /tmp/githubcli-archive-keyring.gpg

# Create agent user with sudo access and workspace directory
RUN useradd -m -s /bin/bash agent && \
    mkdir -p /workspace && \
    chown -R agent:agent /workspace && \
    usermod -aG sudo agent && \
    echo "agent ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agent && \
    chmod 0440 /etc/sudoers.d/agent

# Switch to agent user (non-root installs)
USER agent

# Set up environment for agent user
ENV NVM_DIR="/home/agent/.nvm" \
    PATH="/home/agent/.nvm/versions/node/default/bin:/home/agent/.local/bin:$PATH"

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install 22 && \
    nvm alias default 22 && \
    nvm use default && \
    # Add node to PATH
    echo 'export NVM_DIR="$HOME/.nvm"' >> /home/agent/.bashrc && \
    echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> /home/agent/.bashrc && \
    echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> /home/agent/.bashrc

# Install Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash

# Install OpenAI Codex CLI
RUN . "$NVM_DIR/nvm.sh" && npm install -g @openai/codex@latest

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh
COPY --chmod=755 agents/ /usr/local/bin/agents/

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

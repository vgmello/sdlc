FROM mcr.microsoft.com/dotnet/sdk:9.0-noble

ENV DEBIAN_FRONTEND=noninteractive \
    PATH="/home/claude/.local/bin:$PATH" \
    NVM_DIR="/home/claude/.nvm"

RUN useradd -m -s /bin/bash claude && \
    mkdir -p /home/claude/.local/bin && \
    chown -R claude:claude /home/claude && \
    #
    # Install GitHub CLI, Python, Sudo, etc
    mkdir -p -m 755 /etc/apt/keyrings && \
    wget -nv -O /tmp/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg && \
    cat /tmp/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && \
    apt install -y gh sudo python3 python3-pip python3-venv && \
    rm -rf /var/lib/apt/lists/* /tmp/githubcli-archive-keyring.gpg && \
    #
    # Add claude user to sudo group with passwordless sudo
    usermod -aG sudo claude && \
    echo "claude ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/claude && \
    chmod 0440 /etc/sudoers.d/claude

# Copy entrypoint before switching to claude user
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER claude
WORKDIR /home/claude

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install 22 && \
    nvm alias default 22 && \
    nvm use default
ENV PATH="/home/claude/.nvm/versions/node/v22.20.0/bin:$PATH"

# Install Claude Code CLI
RUN curl -fsSL https://claude.ai/install.sh | bash

# Configure git for github-actions bot
RUN git config --global user.name 'github-actions[bot]' && \
    git config --global user.email 'github-actions[bot]@users.noreply.github.com' && \
    git config --global credential.helper store

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

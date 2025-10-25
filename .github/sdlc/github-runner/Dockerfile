FROM ubuntu:24.04

# Args 
ARG RUNNER_VERSION="2.329.0"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV RUNNER_ALLOW_RUNASROOT=0
ENV DOCKER_HOST=unix:///var/run/docker.sock
ENV RUNNER_WORKDIR=_work
ENV RUNNER_LABELS=self-hosted,linux,docker

RUN useradd -m -s /bin/bash runner && \
    mkdir -p /home/runner && \
    chown -R runner:runner /home/runner && \
    #
    # Install basic dependencies
    apt update && \
    apt install -y \
    ca-certificates \
    curl \
    git \
    jq \
    libicu-dev \
    sudo \
    && rm -rf /var/lib/apt/lists/* && \
    #
    # Allow runner to manage docker socket and workspace permissions (secure sudoers configuration)
    echo 'runner ALL=(ALL) NOPASSWD: /bin/chmod /var/run/docker.sock, /usr/bin/chmod /var/run/docker.sock' > /etc/sudoers.d/runner-docker && \
    echo 'runner ALL=(ALL) NOPASSWD: /bin/chown /var/run/docker.sock, /usr/bin/chown /var/run/docker.sock' >> /etc/sudoers.d/runner-docker && \
    echo 'runner ALL=(ALL) NOPASSWD: /usr/sbin/groupadd docker' >> /etc/sudoers.d/runner-docker && \
    echo 'runner ALL=(ALL) NOPASSWD: /usr/sbin/usermod -aG docker runner' >> /etc/sudoers.d/runner-docker && \
    echo 'runner ALL=(ALL) NOPASSWD: /bin/chown -R runner\:runner /home/runner/_work, /usr/bin/chown -R runner\:runner /home/runner/_work' >> /etc/sudoers.d/runner-docker && \
    echo 'runner ALL=(ALL) NOPASSWD: /bin/chmod -R 755 /home/runner/_work, /usr/bin/chmod -R 755 /home/runner/_work' >> /etc/sudoers.d/runner-docker && \
    echo 'runner ALL=(ALL) NOPASSWD: /bin/chmod 660 /var/run/docker.sock, /usr/bin/chmod 660 /var/run/docker.sock' >> /etc/sudoers.d/runner-docker && \
    chmod 0440 /etc/sudoers.d/runner-docker && \
    #
    # Add Docker's official GPG key
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    #
    # Add the Docker repository to Apt sources
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    #
    # Update package index with new repositories
    apt update && \
    #
    # Install extract packages
    apt install -y \
    #
    # Install Docker CE CLI
    docker-ce-cli && \
    rm -rf /var/lib/apt/lists/*

# Switch to runner user
USER runner    
WORKDIR /home/runner

# Download and install GitHub Actions Runner
RUN ARCH=$(dpkg --print-architecture) && \
    if [ "$ARCH" = "amd64" ]; then RUNNER_ARCH="x64"; \
    elif [ "$ARCH" = "arm64" ]; then RUNNER_ARCH="arm64"; \
    else echo "Unsupported architecture: $ARCH" && exit 1; fi && \
    # Install Runner
    curl -o actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz -L \
    https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    tar xzf ./actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    rm actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz && \
    # Install dependencies for the runner
    ./bin/installdependencies.sh || true

COPY --chown=runner:runner entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

ENTRYPOINT ["/home/runner/entrypoint.sh"]

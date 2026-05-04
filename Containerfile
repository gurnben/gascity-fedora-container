# =============================================================================
# Stage 1: Build gascity (gc) from source
# =============================================================================
FROM registry.fedoraproject.org/fedora-toolbox:latest AS builder

RUN dnf install -y \
        golang \
        git \
        make \
    && dnf clean all

WORKDIR /build
RUN git clone https://github.com/gastownhall/gascity.git .
RUN make build

# =============================================================================
# Stage 2: Final container image
# =============================================================================
FROM registry.fedoraproject.org/fedora-toolbox:latest

LABEL name="gastown-fedora-container" \
      summary="Fedora toolbox with gascity and agentic coding runtimes" \
      description="A Fedora-based development container with gascity orchestration SDK, \
        agentic coding runtimes (opencode, crush, claude-code, gemini-cli), and all \
        required dependencies pre-installed." \
      maintainer="gurnben" \
      url="https://github.com/gurnben/gastown-fedora-container"

# ---- System dependencies for gascity ----
RUN dnf install -y \
        tmux \
        git \
        jq \
        procps-ng \
        lsof \
        util-linux \
        make \
        golang \
    && dnf clean all

# ---- Install gascity (gc) from builder stage ----
COPY --from=builder /build/bin/gc /usr/local/bin/gc

# ---- Install dolt ----
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        DOLT_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        DOLT_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -fsSL "https://github.com/dolthub/dolt/releases/latest/download/install.sh" | bash

# ---- Install beads (bd) ----
RUN curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash

# ---- Add Charm RPM repository for crush ----
RUN printf '%s\n' \
        '[charm]' \
        'name=Charm' \
        'baseurl=https://repo.charm.sh/yum/' \
        'enabled=1' \
        'gpgcheck=1' \
        'gpgkey=https://repo.charm.sh/yum/gpg.key' \
    > /etc/yum.repos.d/charm.repo

# ---- Add Claude Code RPM repository ----
RUN printf '%s\n' \
        '[claude-code]' \
        'name=Claude Code' \
        'baseurl=https://downloads.claude.ai/claude-code/rpm/stable' \
        'enabled=1' \
        'gpgcheck=1' \
        'gpgkey=https://downloads.claude.ai/keys/claude-code.asc' \
    > /etc/yum.repos.d/claude-code.repo

# ---- Install crush and claude-code via native RPMs ----
RUN dnf install -y \
        crush \
        claude-code \
    && dnf clean all

# ---- Install opencode from GitHub release RPM ----
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        OC_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        OC_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    dnf install -y \
        "https://github.com/opencode-ai/opencode/releases/download/v0.0.55/opencode-linux-${OC_ARCH}.rpm" \
    && dnf clean all

# ---- Install Node.js for gemini-cli ----
RUN dnf install -y nodejs npm && dnf clean all

# ---- Install gemini-cli via npm ----
RUN npm install -g @google/gemini-cli

# ---- Configure gascity to use file-based beads by default ----
RUN mkdir -p /etc/skel/.config/gascity && \
    printf '%s\n' \
        '[beads]' \
        'provider = "bd"' \
    > /etc/skel/.config/gascity/city.toml

# ---- Verify installations ----
RUN gc version && \
    dolt version && \
    bd version && \
    crush --version && \
    claude --version && \
    opencode version && \
    gemini --version

CMD ["/bin/bash"]

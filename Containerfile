# =============================================================================
# Stage 1: Build gascity (gc) from source
# =============================================================================
# hadolint ignore=DL3007
FROM registry.fedoraproject.org/fedora-toolbox:latest AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3041
RUN dnf install -y \
        golang \
        git \
        make \
    && dnf clean all

WORKDIR /build
RUN git clone https://github.com/gastownhall/gascity.git . && \
    make build

# =============================================================================
# Stage 2: Final container image
# =============================================================================
# hadolint ignore=DL3007
FROM registry.fedoraproject.org/fedora-toolbox:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

LABEL name="gastown-fedora-container" \
      summary="Fedora toolbox with gascity and agentic coding runtimes" \
      description="A Fedora-based development container with gascity orchestration SDK, \
        agentic coding runtimes (opencode, crush, claude-code, gemini-cli), and all \
        required dependencies pre-installed." \
      maintainer="gurnben" \
      url="https://github.com/gurnben/gastown-fedora-container"

# ---- System dependencies for gascity ----
# hadolint ignore=DL3041
RUN dnf install -y \
        tmux \
        git \
        gh \
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
RUN curl -fsSL "https://github.com/dolthub/dolt/releases/latest/download/install.sh" | bash

# ---- Install beads (bd) ----
RUN curl -fsSL https://raw.githubusercontent.com/gastownhall/beads/main/scripts/install.sh | bash

# ---- Add RPM repositories and install crush, claude-code, opencode ----
RUN printf '%s\n' \
        '[charm]' \
        'name=Charm' \
        'baseurl=https://repo.charm.sh/yum/' \
        'enabled=1' \
        'gpgcheck=1' \
        'gpgkey=https://repo.charm.sh/yum/gpg.key' \
    > /etc/yum.repos.d/charm.repo && \
    printf '%s\n' \
        '[claude-code]' \
        'name=Claude Code' \
        'baseurl=https://downloads.claude.ai/claude-code/rpm/stable' \
        'enabled=1' \
        'gpgcheck=1' \
        'gpgkey=https://downloads.claude.ai/keys/claude-code.asc' \
    > /etc/yum.repos.d/claude-code.repo

# hadolint ignore=DL3041
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        OC_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        OC_ARCH="arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    dnf install -y \
        crush \
        claude-code \
        "https://github.com/opencode-ai/opencode/releases/download/v0.0.55/opencode-linux-${OC_ARCH}.rpm" \
    && dnf clean all

# ---- Install Node.js and gemini-cli ----
# hadolint ignore=DL3041,DL3016
RUN dnf install -y nodejs npm && dnf clean all && \
    npm install -g @google/gemini-cli

# ---- Configure gascity to use bd beads provider by default ----
RUN mkdir -p /etc/skel/.config/gascity && \
    printf '%s\n' \
        '[beads]' \
        'provider = "bd"' \
    > /etc/skel/.config/gascity/city.toml

# ---- Ship ADR pipeline pack ----
COPY pack/ /opt/adr-pipeline/

# ---- Verify installations ----
RUN gc version && \
    dolt version && \
    bd version && \
    crush --version && \
    claude --version && \
    opencode -v && \
    gemini --version && \
    gh --version

# ---- Create non-root user ----
RUN useradd -m -s /bin/bash -G wheel gascity && \
    echo "gascity ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/gascity

USER gascity
WORKDIR /home/gascity

# ---- Configure dolt and git identity defaults ----
RUN dolt config --global --add user.name "gascity" && \
    dolt config --global --add user.email "gascity@container.local" && \
    git config --global user.name "gascity" && \
    git config --global user.email "gascity@container.local"

CMD ["/bin/bash"]

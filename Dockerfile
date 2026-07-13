FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Accept Helix version as a build argument (resolved in CI with auth)
ARG HELIX_VERSION

# Install essential dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*

# Install Helix — the release tarball already contains pre-built grammars
# and query files under runtime/, so no grammar fetch/build step is needed
RUN curl -L -o helix.tar.xz \
      "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz" \
    && tar -C /opt -xJf helix.tar.xz \
    && mv "/opt/helix-${HELIX_VERSION}-x86_64-linux" /opt/helix \
    && ln -s /opt/helix/hx /usr/local/bin/hx \
    && rm helix.tar.xz

# Point Helix at its bundled runtime directory
ENV HELIX_RUNTIME=/opt/helix/runtime

# Create a non-root user
RUN useradd -m -s /bin/bash helixuser
USER helixuser
ENV HOME=/home/helixuser
WORKDIR /workspace

# Copy the Helix configuration files
RUN mkdir -p $HOME/.config/helix
COPY --chown=helixuser:helixuser . $HOME/.config/helix

ENTRYPOINT ["hx"]

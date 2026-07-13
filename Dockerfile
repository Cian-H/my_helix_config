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
    build-essential \
    unzip \
    ripgrep \
    fd-find \
    && rm -rf /var/lib/apt/lists/*

# Install Helix using the version resolved by the CI workflow
RUN curl -L -o helix.tar.xz "https://github.com/helix-editor/helix/releases/download/${HELIX_VERSION}/helix-${HELIX_VERSION}-x86_64-linux.tar.xz" \
    && mkdir -p /opt/helix \
    && tar -C /opt/helix --strip-components=1 -xJf helix.tar.xz \
    && rm helix.tar.xz \
    && ln -s /opt/helix/hx /usr/local/bin/hx

# Create a non-root user and setup home directory
RUN useradd -m -s /bin/bash helixuser
USER helixuser
ENV HOME=/home/helixuser
WORKDIR /workspace

# Copy the Helix configuration files to XDG config dir
RUN mkdir -p $HOME/.config/helix
COPY --chown=helixuser:helixuser . $HOME/.config/helix

# Fetch all language grammars and runtime files
RUN hx --grammar fetch && hx --grammar build

# Set up entrypoint
ENTRYPOINT ["hx"]

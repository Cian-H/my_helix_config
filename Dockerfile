# syntax=docker/dockerfile:1.4
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

# Fetch all language grammars and runtime files using BuildKit secret for GitHub auth
# Run as root to read the secret (secret files are owned by root), then run hx as helixuser
# Use retries for network/transient errors and continue (with warning) if fetch ultimately fails.
USER root
RUN --mount=type=secret,id=github_token,mode=0444 \
  set -euo pipefail; \
  if [ -s /run/secrets/github_token ]; then \
    GITHUB_TOKEN=$(cat /run/secrets/github_token); \
    git config --global url."https://x-access-token:${GITHUB_TOKEN}@github.com/".insteadOf "https://github.com/"; \
  fi; \
  echo "Secret metadata:"; ls -la /run/secrets || true; stat -c '%U:%G %a %n' /run/secrets/github_token 2>/dev/null || true; \
  # Retry hx --grammar fetch up to 3 times with exponential backoff
  n=0; until [ "$n" -ge 3 ]; do \
    echo "Attempt $((n+1)) to fetch grammars..."; \
    runuser -u helixuser -- /bin/bash -lc "hx --grammar fetch" && break; \
    n=$((n+1)); sleep $((n*5)); \
  done; \
  if [ "$n" -ge 3 ]; then \
    echo "Warning: hx --grammar fetch failed after 3 attempts; continuing build. Check logs for failing repositories."; \
  fi; \
  # Try to build grammars; if this fails, emit a warning but continue so the image can still be created.
  runuser -u helixuser -- /bin/bash -lc "hx --grammar build" || echo "Warning: hx --grammar build failed; image may be missing grammars.\n"

# Continue as non-root user
USER helixuser

# Set up entrypoint
ENTRYPOINT ["hx"]

# Dev container for dart_node monorepo
# Dart + Node.js — lean image, fast startup
#
# ┌─────────────────────────────────────────────────┐
# │  PINNED VERSIONS — update here, nowhere else    │
# │                                                 │
# │  Dart SDK:    3.10.7                            │
# │  Node.js:     20.20.0                           │
# │  npm:         11.8.0                            │
# │  cspell:      9.6.0                             │
# │  coverage:    1.15.0                            │
# │  gh CLI:      2.67.0  (in devcontainer.json)    │
# └─────────────────────────────────────────────────┘
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG DART_VERSION=3.10.7
ARG NODE_VERSION=20.20.0
ARG NPM_VERSION=11.8.0
ARG CSPELL_VERSION=9.6.0
ARG COVERAGE_VERSION=1.15.0

# System dependencies (minimal)
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        bc \
        build-essential \
        ca-certificates \
        curl \
        git \
        jq \
        lsof \
        python3 \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Dart SDK (exact version)
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) DART_ARCH="x64" ;; \
        arm64) DART_ARCH="arm64" ;; \
        *) echo "Unsupported arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-${DART_ARCH}-release.zip" -o /tmp/dart-sdk.zip \
    && unzip /tmp/dart-sdk.zip -d /usr/lib \
    && rm /tmp/dart-sdk.zip

ENV PATH="/usr/lib/dart-sdk/bin:${PATH}"
ENV PATH="/home/vscode/.pub-cache/bin:${PATH}"

# Node.js (exact version, direct binary)
RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
        amd64) NODE_ARCH="x64" ;; \
        arm64) NODE_ARCH="arm64" ;; \
        *) echo "Unsupported arch"; exit 1 ;; \
    esac; \
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
    && rm /tmp/node.tar.xz \
    && node --version && npm --version

# Upgrade npm itself (pinned), then global npm tools
RUN npm install -g "npm@${NPM_VERSION}" "cspell@${CSPELL_VERSION}"

# Global Dart tools (pinned, as vscode user so pub-cache lands correctly)
USER vscode
RUN dart pub global activate coverage "${COVERAGE_VERSION}"
USER root

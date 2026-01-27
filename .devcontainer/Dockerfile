# Dev container for dart_node monorepo
# Dart + Node.js + all build/test tooling
FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG DART_VERSION=3.10.0
ARG NODE_MAJOR=20

# System dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        bc \
        build-essential \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        lcov \
        lsof \
        python3 \
        unzip \
        wget \
        xvfb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Dart SDK
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

# Node.js via NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Chromium for browser tests
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y --no-install-recommends chromium-browser \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    || true

# Global npm tools
RUN npm install -g cspell

# Global Dart tools (as vscode user so pub-cache is in the right place)
USER vscode
RUN dart pub global activate coverage
USER root

# Playwright system deps (for website tests)
RUN npx playwright install-deps chromium 2>/dev/null || true

# Chrome/Chromium env
ENV CHROME_EXECUTABLE="/usr/bin/chromium-browser"
ENV PUPPETEER_EXECUTABLE_PATH="/usr/bin/chromium-browser"

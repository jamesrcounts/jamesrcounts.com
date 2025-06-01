FROM mcr.microsoft.com/vscode/devcontainers/ruby:3.2-bullseye

# Locale and timezone settings
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TZ=Etc/UTC

# Ruby gem settings
ENV GEM_HOME=/home/vscode/.gems \
    GEM_PATH=/home/vscode/.gems \
    PATH=/home/vscode/.gems/bin:$PATH

# Install Node.js
ARG NODE_VERSION="lts/*"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

# Install system dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        build-essential \
        curl \
        git \
        libffi-dev \
        libgdbm-dev \
        libmagickwand-dev \
        libncurses5-dev \
        libreadline-dev \
        libssl-dev \
        libxml2-dev \
        libxslt1-dev \
        libyaml-dev \
        zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Ensure GPG is available in /usr/local/bin for gem operations
RUN [ ! -e /usr/local/bin/gpg ] && ln -s /usr/bin/gpg /usr/local/bin/gpg || true

# Set up gem environment for vscode user
RUN mkdir -p /home/vscode/.gems \
    && chown -R vscode:vscode /home/vscode/.gems

# Switch to vscode user for all remaining operations
USER vscode

# Update RubyGems and install bundler
RUN gem update --system 3.6.9 \
    && gem install bundler

# Configure gem environment in bashrc
RUN echo 'export GEM_HOME="/home/vscode/.gems"' >> ~/.bashrc \
    && echo 'export GEM_PATH="/home/vscode/.gems"' >> ~/.bashrc \
    && echo 'export PATH="/home/vscode/.gems/bin:$PATH"' >> ~/.bashrc

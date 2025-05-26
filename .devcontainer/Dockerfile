FROM mcr.microsoft.com/vscode/devcontainers/ruby:0-2.7

# ENV Variables required by Jekyll
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    TZ=Etc/UTC \
    LC_ALL=en_US.UTF-8

# Install compatible Bundler for Ruby 2.7
RUN gem install bundler -v 2.4.22

# Install Node.js (needed by many Jekyll plugins/themes)
ARG NODE_VERSION="lts/*"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

# Install required native libraries and tools for building Ruby gems
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libreadline-dev \
        libyaml-dev \
        libxml2-dev \
        libxslt1-dev \
        libffi-dev \
        libgdbm-dev \
        libncurses5-dev \
        libmagickwand-dev \
        curl \
        git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optional: Handle GPG symlink issues
RUN ln -s /usr/bin/gpg /usr/local/bin/gpg

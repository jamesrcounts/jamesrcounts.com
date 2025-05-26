FROM mcr.microsoft.com/vscode/devcontainers/ruby:0-2.7

# ENV Variables required by Jekyll
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    TZ=Etc/UTC \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US

# Install bundler
RUN gem install bundler -v 2.4.22

# [Option] Install Node.js
ARG NODE_VERSION="lts/*"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        libmagickwand-dev \
        build-essential \
        libssl-dev \
        zlib1g-dev \
        libreadline-dev \
        libyaml-dev \         # ✅ YAML support
        libxml2-dev \
        libxslt1-dev \
        libffi-dev \
        libgdbm-dev \
        curl \
        git \
    && apt-get clean && rm -rf /var/lib/apt/lists/*


# [Optional] Uncomment this line to install additional gems.
# RUN gem install <your-gem-names-here>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# Some people have git config pointed at a different gpg location
RUN ln -s /usr/bin/gpg /usr/local/bin/gpg
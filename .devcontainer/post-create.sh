#!/bin/sh

# Install the version of Bundler listed in Gemfile.lock, if present
if [ -f Gemfile.lock ] && grep "BUNDLED WITH" Gemfile.lock > /dev/null; then
    BUNDLER_VERSION=$(tail -n 2 Gemfile.lock | tail -n 1)
    echo "Installing bundler version $BUNDLER_VERSION"
    gem install bundler -v "$BUNDLER_VERSION"
fi

# Run bundle install if Gemfile is present, otherwise install Jekyll
if [ -f Gemfile ]; then
    bundle config set path 'vendor/bundle'
    bundle config set force_ruby_platform true
    bundle install
else
    gem install jekyll
fi

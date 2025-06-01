source "https://rubygems.org"
ruby RUBY_VERSION

# Core Jekyll and theme
gem "jekyll", "~> 4.3"  # Latest stable version
gem "minima", "~> 2.5.2"  # Latest version with Sass fixes

# Jekyll Plugins
group :jekyll_plugins do
  # Core functionality plugins
  gem "jekyll-feed", "~> 0.17"
  gem "jekyll-seo-tag", "~> 2.8"
  gem "jekyll-sitemap", "~> 1.4"

  # Content and layout plugins
  gem "jekyll-gist", "~> 1.5"
  gem "jekyll-responsive-image", "~> 1.6"
  gem "jekyll-redirect-from", "~> 0.16"
end

# Development and testing
group :development, :test do
  gem "html-proofer", "~> 5.0"
  gem "webrick", "~> 1.8"  # Required for Ruby 3+
  gem "nokogiri", ">= 1.15"
end

# Markdown processing
gem "kramdown-parser-gfm", "~> 1.1"

# Platform-specific gems
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", "~> 2.0"
  gem "tzinfo-data"
end

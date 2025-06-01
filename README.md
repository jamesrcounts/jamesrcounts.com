# jamesrcounts.com

This repository contains the source code for my personal website and blog, built with Jekyll and hosted in an AWS storage bucket + CloudFront (for now). See my [getting started post](https://jamesrcounts.com/2017/03/16/getting-started-with-serverless.html) for a guide to how I got started, although I can't guarantee everything in there is up to date.

## Overview

This is a static website built using Jekyll, featuring blog posts, guides, and personal content. The site uses the Minima theme and includes responsive images and other optimizations for performance.

## Prerequisites

- Ruby (2.6.0 or higher recommended)
- Bundler
- Jekyll
- ImageMagick (for image processing)

## Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/jamesrcounts/jamesrcounts.com.git
   cd jamesrcounts.com
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

## Local Development

To run the site locally and preview your changes before publishing:

```bash
bundle exec jekyll serve --incremental --drafts
```

This command:
- Builds and serves the site locally at `http://localhost:4000`
- `--incremental` enables incremental builds for faster regeneration
- `--drafts` includes draft posts from the `_drafts` directory

## Directory Structure

- `_posts/` - Published blog posts
- `_drafts/` - Draft posts (not published)
- `_includes/` - Reusable components
- `_layouts/` - Page templates
- `assets/` - Static files (images, CSS, etc.)
- `guides/` - Technical guides and tutorials
- `media/` - Media files organized by year/month

## License

Content is copyrighted unless otherwise specified. Code samples are available under the MIT License.
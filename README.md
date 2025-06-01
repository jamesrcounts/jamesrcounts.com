# jamesrcounts.com

This repository contains the source code for my personal website and blog, built with Jekyll and hosted in an AWS storage bucket + CloudFront (for now). See my [getting started post](https://jamesrcounts.com/2017/03/16/getting-started-with-serverless.html) for a guide to how I got started, although I can't guarantee everything in there is up to date.

## Overview

This is a static website built using Jekyll, featuring:

- Blog posts about cloud engineering and DevOps
- Technical guides and tutorials
- Responsive images and performance optimizations
- AWS-based hosting with S3 and CloudFront
- Automated deployments via GitHub Actions

## Prerequisites

- Ruby 3.2.0 or higher
- Bundler 2.4.0 or higher
- ImageMagick (for responsive image processing)
- Node.js 20 or higher (for build tools)

## Local Development Setup

1. Clone the repository:

   ```shell
   git clone https://github.com/jamesrcounts/jamesrcounts.com.git
   cd jamesrcounts.com
   ```

2. Install dependencies:

   ```shell
   bundle install
   ```

3. Run development server:

   ```shell
   make serve
   ```

   Or manually:

   ```shell
   bundle exec jekyll serve --incremental --drafts
   ```

4. View the site at `http://localhost:4000`

## Development Workflow

- `make serve` - Run development server with drafts and incremental builds
- `make build` - Build the site locally
- `make test` - Build and run HTML validation
- `make quicktest` - Run HTML validation without cleaning
- `make clean` - Remove generated files

## Project Structure

```text
.
├── _drafts/       # Draft posts (not published)
├── _includes/     # Reusable components and layouts
├── _posts/        # Published blog posts
├── _sass/         # Sass stylesheets
├── assets/        # Static assets (images, etc.)
│   └── resized/   # Responsive image versions
├── guides/        # Technical guides and tutorials
├── media/         # Media files by year/month
└── _config.yml    # Site configuration
```

## Deployment

The site is automatically deployed to AWS when changes are pushed to the main branch:

1. GitHub Actions builds the site and runs validation
2. If successful, files are synced to S3
3. CloudFront distribution is updated
4. Site is available at https://jamesrcounts.com

## License

Content is copyrighted unless otherwise specified. Code samples are available under the MIT License.
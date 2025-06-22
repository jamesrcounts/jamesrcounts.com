.DEFAULT_GOAL := serve

# Install dependencies if they're missing
dependencies:
	@echo "Installing Jekyll dependencies..."
	bundle config set --local path 'vendor/bundle'
	bundle config set --local force_ruby_platform true
	bundle install

serve: dependencies
	bundle exec jekyll serve --incremental --drafts

build: dependencies
	bundle exec jekyll build --incremental --drafts

production-build: dependencies
	JEKYLL_ENV=production bundle exec jekyll build --incremental --drafts

clean:
	bundle exec jekyll clean

rebuild: clean build

debug: clean dependencies
	bundle exec jekyll build --trace

htmlproofer: dependencies
	bundle exec htmlproofer ./_site \
		--checks "Links,Images,Scripts" \
		--disable_external \
		--ignore_empty_alt \
		--ignore_missing_alt \
		--ignore_urls "/localhost:4000/,/http:\/\/localhost:4000/" \
		--log_level :info

test: clean production-build htmlproofer

quicktest: production-build htmlproofer
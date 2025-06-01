.DEFAULT_GOAL := serve

serve:
	bundle exec jekyll serve --incremental --drafts

build:
	bundle exec jekyll build --incremental --drafts

clean:
	bundle exec jekyll clean

rebuild: clean build

debug: clean
	bundle exec jekyll build --trace

htmlproofer:
	bundle exec htmlproofer ./_site \
		--checks "Links,Images,Scripts" \
		--disable_external \
		--ignore_empty_alt \
		--ignore_missing_alt \
		--ignore_urls "/localhost:4000/,/http:\/\/localhost:4000/" \
		--log_level :info

test: clean build htmlproofer

quicktest: build htmlproofer
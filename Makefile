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
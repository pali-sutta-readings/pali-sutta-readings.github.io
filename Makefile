all:
	@echo "Make what?"

build:
	poetry run mkdocs build -d ../pali-sutta-readings.github.io-main/

convert:
	cd scripts && ./org-to-md-convert-watcher.sh

preview:
	poetry run mkdocs serve

publish:
	./scripts/publish.sh

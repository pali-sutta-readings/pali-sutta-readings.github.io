all:
	@echo "Make what?"

convert:
	./scripts/org_to_md_convert_watcher.sh ./sessions ./docs/readings/sessions ./docs/readings-print

convert-once:
	./scripts/convert_once.sh ./sessions ./docs/readings/sessions ./docs/readings-print

build: convert-once
	poetry run mkdocs build -d ../pali-sutta-readings.github.io-main/

preview:
	poetry run mkdocs serve

publish: build
	./scripts/publish.sh

all:
	@echo "Make what?"

convert:
	./scripts/org_to_md_convert_watcher.sh ./sessions ./docs/readings/sessions ./docs/readings-print

convert-once:
	./scripts/convert_once.sh ./sessions ./docs/readings/sessions ./docs/readings-print

generate-html:
	poetry run mkdocs build -d ../pali-sutta-readings.github.io-main/

preview: convert-once
	poetry run mkdocs serve

publish: convert-once
	./scripts/publish.sh

pali-all: pali-lessons-pdf pali-cheatsheet-pdf pali-readings-pdf pali-readings-with-sentence-analysis-pdf pali-lessons-anki-deck pali-readings-anki-deck pali-readings-with-sentence-analysis-anki-deck

pali-vocabulary-words-pdf:
	cd pali-lessons/ && make pali-vocabulary-words

pali-vocabulary-sentences-pdf:
	cd pali-lessons/ && make pali-vocabulary-sentences

pali-lessons-pdf: pali-vocabulary-words-pdf pali-vocabulary-sentences-pdf
	cd pali-lessons && \
	make export-pali-lessons && \
	cd ../.. && \
	ANSWERKEY=FALSE ./scripts/compile_tex.sh ./pali-lessons/pali-lessons.tex && \
	ANSWERKEY=TRUE ./scripts/compile_tex.sh ./pali-lessons/pali-lessons-answerkey.tex

pali-cheatsheet-pdf:
	cd pali-lessons && \
	make export-pali-cheatsheet && \
	cd ../.. && \
	./scripts/compile_tex.sh ./pali-lessons/pali-cheatsheet.tex

pali-readings-pdf:
	cd 2023-readings && \
	make export-pali-readings && \
	cd ../.. && \
	ANSWERKEY=FALSE ./scripts/compile_tex.sh ./2023-readings/pali-readings.tex && \
	ANSWERKEY=TRUE ./scripts/compile_tex.sh ./2023-readings/pali-readings-answerkey.tex

pali-readings-with-sentence-analysis-pdf:
	cd 2023-readings && \
	make export-pali-readings-with-sentence-analysis && \
	cd ../.. && \
	ANSWERKEY=FALSE ./scripts/compile_tex.sh ./2023-readings/pali-readings-with-sentence-analysis.tex && \
	ANSWERKEY=TRUE ./scripts/compile_tex.sh ./2023-readings/pali-readings-with-sentence-analysis-answerkey.tex

pali-lessons-anki-deck:
	cp pali-lessons/exported/pali-lessons.apkg src/includes/docs/pali-lessons.apkg

pali-readings-anki-deck:
	cp 2023-readings/exported/pali-readings.apkg src/includes/docs/pali-readings.apkg

pali-readings-with-sentence-analysis-anki-deck:
	cp 2023-readings/exported/pali-readings-with-sentence-analysis.apkg src/includes/docs/pali-readings-with-sentence-analysis.apkg

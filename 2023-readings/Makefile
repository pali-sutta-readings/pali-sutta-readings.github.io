pali-readings: export-pali-readings pali-readings.pdf

pali-readings.apkg:
	../../scripts/export-reading-vocab-to-anki.py ./pali-readings.org

pali-readings-upload-pdf: pali-readings
	rclone copyto pali-readings.pdf "gambhiro.sumedharama:/Pāli Readings/pali-readings.pdf" --drive-shared-with-me

pali-readings-upload-all: pali-readings-upload-pdf pali-readings-anki.zip
	rclone copyto pali-readings-anki.zip "gambhiro.sumedharama:/Pāli Readings/pali-readings-anki.zip" --drive-shared-with-me

pali-readings-with-sentence-analysis: export-pali-readings-with-sentence-analysis pali-readings-with-sentence-analysis.pdf

pali-readings-answerkey: export-pali-readings
	ANSWERKEY=TRUE make pali-readings-answerkey.pdf

pali-readings-with-sentence-analysis-answerkey: export-pali-readings-with-sentence-analysis
	ANSWERKEY=TRUE make pali-readings-with-sentence-analysis-answerkey.pdf

export-pali-readings:
	emacs --batch -L -l 'pali-readings.org' -l 'export-init.el' --eval '(progn (org-latex-export-to-latex))'

export-pali-readings-with-sentence-analysis:
	emacs --batch -L -l 'pali-readings-with-sentence-analysis.org' -l 'export-init.el' --eval '(progn (org-latex-export-to-latex))'

export-pali-readings-vocab-to-anki:
	../../scripts/export-vocab-org-to-anki.py ./pali-readings-with-sentence-analysis.org ./exported/pali-readings-with-sentence-analysis.apkg "Pāli Readings::7. The Weaver's Daughter (Dhp 174 and Commentary Story)::1. Vocabulary"

%.pdf: %.tex
	$(LATEX) $(LATEX_OPTS) $<

preview $(FILE):
	latexmk -pdflua -pvc -e '$$latex=q/latex %O -interaction=nonstopmode -halt-on-error %S/' $(FILE)

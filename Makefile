ISPELLPAT = -ktexskip1 +cref,Cref,url
SPELLCHECK= chapters/*.tex


all: paper.pdf

graphics:
	${MAKE} -C figures/

paper.pdf: graphics *.bib *.tex chapters/*.tex
	latexmk -pdf paper.tex

spelling: ${SPELLCHECK}
	for file in ${SPELLCHECK}; do \
          ispell -t ${ISPELLPAT} -b -d american -p ./paper.dict $$file; \
        done

clean:
	latexmk -C -pdflatex='pdflatex -file-line-error' -pdf paper.tex
	rm -f paper.pdf
	rm -f *.tex.bak

distclean: clean
	${MAKE} -C figures/ clean
	rm -f paper.bbl


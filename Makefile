LATEXMK_ENGINE_FLAG ?= -pdf
LATEXMK_FLAGS = $(LATEXMK_ENGINE_FLAG) -use-make -bibtex-cond1 -silent

DIAGEN_FLAGS ?= -D_FONTNAME="PT Sans"
DIAGEN ?= ~/bin/diagen

PROJECTDIR := $(shell pwd)
PROJECT := $(shell basename "$(PROJECTDIR)")
TEXMAIN ?= $(PROJECT).tex

MACROGV := $(shell find diagrams -name '*.gv.m4')
PDF_FROM_MACROGV = $(MACROGV:.gv.m4=.pdf)

MARKDOWN := $(shell find sections -name '*.md')
TEX_FROM_MARKDOWN = $(MARKDOWN:.md=.tex)

SVG := $(shell find figures -name '*.svg')
PDF_FROM_SVG = $(SVG:.svg=.pdf)

.PHONY: pdf clean

pdf: $(PDF_FROM_MACROGV) $(TEX_FROM_MARKDOWN) $(PDF_FROM_SVG)
	latexmk $(LATEXMK_FLAGS) $(TEXMAIN)

clean:
	latexmk $(LATEXMK_FLAGS) -C
	rm -f $(PDF_FROM_MACROGV) $(TEX_FROM_MARKDOWN) $(PDF_FROM_SVG)

%.tex: %.md
	pandoc -f gfm -o $@ $<

%.pdf: %.svg
	inkscape -A "$(PROJECTDIR)/$@" --export-ignore-filters "$(PROJECTDIR)/$<"

%.eps: %.svg
	inkscape -E "$(PROJECTDIR)/$@" --export-ignore-filters "$(PROJECTDIR)/$<"

%.svg: %.gv.m4
	$(DIAGEN) $< $@ $(DIAGEN_FLAGS)

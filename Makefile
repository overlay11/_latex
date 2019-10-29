DOCUMENT_CLASS ?= extarticle
LATEXMK_ENGINE_FLAG ?= -pdf
PRETEX = \newcommand\Documentclass{$(DOCUMENT_CLASS)}
LATEXMK_FLAGS = $(LATEXMK_ENGINE_FLAG) -usepretex='$(PRETEX)' -use-make -bibtex-cond1 -silent

DIAGEN_FLAGS ?= -D_FONTNAME="PT Sans"
DIAGEN ?= ~/bin/diagen

PROJECTDIR := $(shell pwd)
PROJECT := $(shell basename "$(PROJECTDIR)")
TEXMAIN ?= $(PROJECT).tex

PANDOC_FLAGS ?= --top-level-division=section

MACROGV := $(shell find diagrams -name '*.gv.m4')
PDF_FROM_MACROGV = $(MACROGV:.gv.m4=.pdf)

MARKDOWN := $(shell find sections chapters -name '*.md')
TEX_FROM_MARKDOWN = $(MARKDOWN:.md=.tex)

RSTEXT := $(shell find sections chapters -name '*.rst')
TEX_FROM_RSTEXT = $(RSTEXT:.rst=.tex)

SVG := $(shell find figures -name '*.svg')
PDF_FROM_SVG = $(SVG:.svg=.pdf)

.PHONY: pdf tex clean

pdf: tex $(PDF_FROM_MACROGV) $(PDF_FROM_SVG)
	latexmk $(LATEXMK_FLAGS) $(TEXMAIN)

tex: $(TEX_FROM_MARKDOWN) $(TEX_FROM_RSTEXT)

clean:
	latexmk $(LATEXMK_FLAGS) -C
	rm -f $(PDF_FROM_MACROGV) $(TEX_FROM_MARKDOWN) $(TEX_FROM_RSTEXT) $(PDF_FROM_SVG)

%.tex: %.md
	pandoc $(PANDOC_FLAGS) -o $@ $<

%.tex: %.rst
	pandoc $(PANDOC_FLAGS) -o $@ $<

%.pdf: %.svg
	inkscape -A "$(PROJECTDIR)/$@" --export-ignore-filters "$(PROJECTDIR)/$<"

%.eps: %.svg
	inkscape -E "$(PROJECTDIR)/$@" --export-ignore-filters "$(PROJECTDIR)/$<"

%.svg: %.gv.m4
	$(DIAGEN) $< $@ $(DIAGEN_FLAGS)

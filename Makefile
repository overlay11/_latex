class ?= extarticle
mode ?= final
engineflag ?= -pdf
main ?= $(lastword $(subst /, ,$(abspath .)))
toplevel ?= section


.PHONY: pdf pdf-from-svg tex-from-md tex-from-rst pdf-from-macrogv \
png-from-scad tex-from-csv pdf-from-plt clean

.DEFAULT_GOAL := pdf

SHELL = /bin/sh

eq = $(and $(findstring $(1),$(2)),$(findstring $(2),$(1)))


PANDOC = pandoc
PANDOC_FLAGS = --top-level-division=$(toplevel)

TEXMAIN = $(main).tex
PREAMBLE := $(firstword $(shell find . -name 'preamble.tex'))

pandoc-standalone = echo '\input{$(PREAMBLE)}' > $@; \
echo '\\begin{document}' >> $@; \
$(PANDOC) $(PANDOC_FLAGS) -t latex $< >> $@; \
echo '\end{document}' >> $@

pandoc-fragment = $(PANDOC) $(PANDOC_FLAGS) -o $@ $<

%.tex: %.md
	$(if $(call eq,$@,$(TEXMAIN)),$(pandoc-standalone),$(pandoc-fragment))

%.tex: %.rst
	$(if $(call eq,$@,$(TEXMAIN)),$(pandoc-standalone),$(pandoc-fragment))

%.tex: %.csv
	$(pandoc-fragment)

%.tex: %.txt
	$(pandoc-fragment)

TEX_FROM_MD := $(patsubst %.md,%.tex,$(shell find . -name '*.md'))
TEX_FROM_RST := $(patsubst %.rst,%.tex,$(shell find . -name '*.rst'))
TEX_FROM_CSV := $(patsubst %.csv,%.tex,$(shell find . -name '*.csv'))

tex-from-md: $(TEX_FROM_MD)
tex-from-rst: $(TEX_FROM_RST)
tex-from-csv: $(TEX_FROM_CSV)


INKSCAPE = inkscape
INKSCAPE_FLAGS = --export-ignore-filters

%.pdf: %.svg
	$(INKSCAPE) $(INKSCAPE_FLAGS) $(INKSCAPE_PDF_FLAGS) -o $@ $<

%.eps: %.svg
	$(INKSCAPE) $(INKSCAPE_FLAGS) $(INKSCAPE_EPS_FLAGS) -o $@ $<

PDF_FROM_SVG := $(patsubst %.svg,%.pdf,$(shell find . -name '*.svg'))

pdf-from-svg: $(PDF_FROM_SVG)


POTRACE = potrace -s

%.svg: %.pbm
	$(POTRACE) $(POTRACE_FLAGS) -o $@ $<


# https://github.com/overlay11/diagen.sh
DIAGEN = ~/bin/diagen
DIAGEN_FLAGS = -D_FONTNAME='PT Sans'

%.svg: %.gv.m4
	$(DIAGEN) $< $@ $(DIAGEN_FLAGS)

PDF_FROM_MACROGV := $(patsubst %.gv.m4,%.pdf,$(shell find . -name '*.gv.m4'))

pdf-from-macrogv: $(PDF_FROM_MACROGV)


OPENSCAD = openscad
OPENSCAD_PNG_FLAGS = $(if $(call eq,$(mode),final),--render,--preview) \
--projection ortho --viewall --autocenter --colorscheme Tomorrow

%.svg: %.scad
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(OPENSCAD_SVG_FLAGS) -o $@ $<

%.png: %.scad
	$(OPENSCAD) $(OPENSCAD_FLAGS) $(OPENSCAD_PNG_FLAGS) -o $@ $<

PNG_FROM_SCAD := $(patsubst %.scad,%.png,$(shell find . -name '*.scad'))

png-from-scad: $(PNG_FROM_SCAD)


GNUPLOT = gnuplot

%.svg: %.plt
	$(GNUPLOT) $(GNUPLOT_FLAGS) -e "set terminal svg; set output '$@'" $<

PDF_FROM_PLT := $(patsubst %.plt,%.pdf,$(shell find . -name '*.plt'))

pdf-from-plt: $(PDF_FROM_PLT)


LATEXMK = latexmk
PRETEX = \newcommand\documentcls{$(class)} \
\newcommand\documentmode{$(mode)}
LATEXMK_FLAGS = $(engineflag) -usepretex='$(PRETEX)' -bibtex-cond1 -silent

tex: tex-from-md tex-from-rst tex-from-csv

pdf: tex pdf-from-macrogv pdf-from-svg png-from-scad pdf-from-plt
	$(LATEXMK) $(LATEXMK_FLAGS) $(TEXMAIN)

GENERATED_TEX = $(TEX_FROM_MD) $(TEX_FROM_RST) $(TEX_FROM_CSV)
INTERMEDIATE_PDF = $(PDF_FROM_MACROGV) $(PDF_FROM_SVG) $(PDF_FROM_PLT)

clean:
	$(LATEXMK) $(LATEXMK_FLAGS) -C
	rm -f $(PNG_FROM_SCAD) $(GENERATED_TEX) $(INTERMEDIATE_PDF)


# Make Targets:
#
# make CookbookPrint.pdf    - PDF Suitable for duplex printing, cutting, folding and stapling as a small book
# make Cookbook.pdf         - PDF Suitable for on-screen reading or standard printing (though pages are half-sheet in size)
# make cookbook             - Generate both Cookbook.pdf and CookbookPrint.pdf
# make recipes              - Insert new recipes and hints into Cookbook.tex just before \end{mainmatter} and \end{backmatter} respectively
# make tags                 - show list of currently used tags
# make sources              - show list of currently used sources
# make clean                - remove temporary build files
#
#
## ih_strip() { exiftool -all= --icc_profile:all "/cache/syncthing/Darr-Camera/Camera/$1" -o "$2-orig.jpg"; }
##
## ih_strip PXL_20250728_011423507.jpg pesto-pasta
##
## mv ~/run-tmp/tmp/* photos/; make

RECIPES=$(shell find recipes -type f -name "*.tex")
HINTS=$(shell find hints -type f -name "*.tex")
PHOTO_NAMES=$(shell perl -nE 'say $$1 if /^\s*\\photo\{([^\}]+)\}/' recipes/*.tex)
PHOTOS_LOW_RES=$(PHOTO_NAMES:%=photos/%-100.jpg)
PHOTOS_HIGH_RES=$(PHOTO_NAMES:%=photos/%-600.jpg)

COOKBOOK_DEPS = cookbook.sty References.bib ${RECIPES} ${HINTS} ${PHOTOS_LOW_RES} ${PHOTOS_HIGH_RES}


.PHONY: cookbook recipes clean tags sources

all: cookbook

cookbook:: Cookbook.pdf CookbookHiRes.pdf CookbookPrint.pdf

check:
	@./bin/lint-check

Cookbook.pdf: Cookbook.tex ${COOKBOOK_DEPS}
	xelatex -interaction nonstopmode Cookbook.tex
	bibtex Cookbook.aux
	xelatex -interaction nonstopmode Cookbook.tex
	makeindex Cookbook
	xelatex -interaction nonstopmode Cookbook.tex

CookbookHiRes.pdf: Cookbook.tex ${COOKBOOK_DEPS}
	perl -pE 's/^(.def.PhotoType)/% $$1/; s/^%+\s*(.def.PhotoType.\-600)/$$1/' $< >CookbookHiRes.tex
	xelatex -interaction nonstopmode CookbookHiRes.tex
	bibtex CookbookHiRes.aux
	xelatex -interaction nonstopmode CookbookHiRes.tex
	makeindex CookbookHiRes
	xelatex -interaction nonstopmode CookbookHiRes.tex
	rm -f CookbookHiRes.tex CookbookHiRes.aux CookbookHiRes.bbl CookbookHiRes.blg CookbookHiRes.idx CookbookHiRes.ilg CookbookHiRes.ind CookbookHiRes.log CookbookHiRes.out CookbookHiRes.toc

CookbookPrint.pdf: CookbookHiRes.pdf
	pdfbook2 --paper letter CookbookHiRes.pdf
	@mv -f CookbookHiRes-book.pdf CookbookPrint.pdf

recipes:
	@perl -pi -E'BEGIN{m#/(.*)\.tex$$# && $$x{$$1}++ for(@x=glob("recipes/*.tex"));} delete$$x{$$1}if/\\R(?:\[.*?\])?\{(.*?)\}/; if(/\\end\{mainmatter\}/){say"\\R{$$_}"for keys%x}' Cookbook.tex
	@perl -pi -E'BEGIN{m#/(.*)\.tex$$# && $$x{$$1}++ for(@x=glob("hints/*.tex"));} delete$$x{$$1}if/\\hint(?:\[.*?\])?\{(.*?)\}/; if(/\\end\{backmatter\}/){say"\\hint{$$_}"for keys%x}' Cookbook.tex

sources:
	@perl -nE'say $$1 while /\\source\{([^}]+)\}/gc' recipes/*.tex | sort | uniq -c | sort -n

tags:
	@perl -nE'say $$1 while /\\tag\{([^}]+)\}/gc'    recipes/*.tex | sort | uniq -c | sort -n

photos/%-100.jpg: photos/%-full.jpg
	convert $< -quality 75 -thumbnail 400x300 $@

photos/%-600.jpg: photos/%-full.jpg
	convert $< -quality 75 -thumbnail 2400x1800 $@


clean:
	rm -f *~ Cookbook.aux Cookbook.bbl Cookbook.blg Cookbook.dvi Cookbook.idx Cookbook.ilg Cookbook.ind Cookbook.log Cookbook.toc

distclean: clean
	rm -f Cookbook.pdf CookbookPrint.pdf CookbookHiRes.pdf


# Optionally include Makefile.local for per-developer make targets
-include Makefile.local
Makefile.local:
	@

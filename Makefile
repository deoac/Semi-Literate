SHELL := /bin/zsh
.PHONY: Makefile all  modules binaries executables markdowns docs clean test install

SOURCEDIR   := ./source
BINDIR	  := ./bin
DOCDIR  	:= ./docs
MODULESDIR  := ./lib/Semi
TESTSDIR	:= ./t
EXECUTABLES := ${BINDIR}
MODULE	  := ${MODULES}/Literate.rakumod

vpath %.sl ${SOURCEDIR}
vpath %.rakumod ${MODULESDIR}

all: 		 modules executables documents
modules: 	 Literate.rakumod module-install
binaries: 	 ${BINDIR}/sl-tangle ${BINDIR}/sl-weave
executables: binaries executable-install

Literate.rakumod: Literate.sl
	@chmod -R a+w lib/
	@echo "> Compiling the Semi::Literate module..."
	@sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod
	@chmod -R a-w lib/

module-install:
	@echo "> Installing the newly created module with zef..."
	@zef install --force-build --force-install --force-test . >/dev/null

${BINDIR}/sl-tangle: Literate.rakumod sl-tangle.sl
	@chmod -R a+w bin/
	@echo "> Creating the sl-tangle executable..."
	@sl-tangle source/sl-tangle.sl > bin/sl-tangle
	@chmod -R a-w,a+x bin/

${BINDIR}/sl-weave: Literate.rakumod sl-weave.sl
	@chmod -R a+w bin/
	@echo "> Creating the sl-weave executable..."
	@bin/sl-tangle source/sl-weave.sl  > bin/sl-weave
	@chmod -R a-w,a+x bin/

executable-install:
	@echo "> Installing the newly created executables with zef..."
	@zef install --force-build --force-install --force-test . >/dev/null

install:
	@echo "> Installing the module and the executables with zef..."
	@zef install --force-build --force-install --force-test . >/dev/null

test: pre ${LITERATE} executables post
	@echo "> Running the tests..."
	@prove6 -l -v

sanity-tests:
	@echo "> Tangling the module source code to a Raku file..."
	@raku lib/Semi/Literate.rakumod --testt > deleteme.raku
	@echo "> Weaving the module source code to a Pod6 file..."
	@raku lib/Semi/Literate.rakumod --testw > deleteme.p6
	@echo "> Verifying the raku file compiles..."
	@raku -c deleteme.raku
	@echo "> Verifying the Pod6 file compiles..."
	@raku -c deleteme.p6
	@echo "> Verifying that the Pod6 file can be made into a Markdown file..."
	@raku --doc=MarkDown2 deleteme.p6 >deleteme.md
	@echo "> Opening the .md file and verifying that it looks OK..."
	@open deleteme.md
	@sleep 5

clean:
	@echo "> Deleting the intermediate files..."
	@rm -rf deleteme.p6 deleteme.raku deleteme.md
	@echo "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/


#HTMLS := $(SOURCES:$(SOURCEDIR)/%.sl=$(DOCDIR)/html/%.html)
#MARKDOWNS := $(SOURCES:$(SOURCEDIR)/%.sl=$(DOCDIR)/markdown/%.md)
#PDFS := $(SOURCES:$(SOURCEDIR)/%.sl=$(DOCDIR)/pdf/%.pdf)
#
#.PHONY: docs
#docs: create_doc_dirs $(HTMLS) $(MARKDOWNS) $(PDFS)
#
#create_doc_dirs:
#	mkdir -p $(DOCDIR)/html
#	mkdir -p $(DOCDIR)/markdown
#	mkdir -p $(DOCDIR)/pdf
#
#$(DOCDIR)/html/%.html: $(SOURCEDIR)/%.sl
#	sl-weave --format=HTML --output-file=$@ $<
#
#$(DOCDIR)/markdown/%.md: $(SOURCEDIR)/%.sl
#	sl-weave --format=Markdown --output-file=$@ $<
#
#$(DOCDIR)/pdf/%.pdf: $(SOURCEDIR)/%.sl
#	sl-weave --format=PDF --output-file=$@ $<


SOURCES := $(wildcard ./source/*.sl)
HTML_TARGETS := $(patsubst ./source/%.sl, ./doc/html/%.html, $(SOURCES))
MARKDOWN_TARGETS := $(patsubst ./source/%.sl, ./doc/markdown/%.md, $(SOURCES))
PDF_TARGETS := $(patsubst ./source/%.sl, ./doc/pdf/%.pdf, $(SOURCES))

docs: html markdown pdf
html: $(HTML_TARGETS)
markdown: $(MARKDOWN_TARGETS)
pdf: $(PDF_TARGETS)

./doc/html/%.html: ./source/%.sl
	@mkdir -p $(@D)
	sl-weave --format=html --output-file=$@ $<

./doc/markdown/%.md: ./source/%.sl
	@mkdir -p $(@D)
	sl-weave --format=markdown --output-file=$@ $<

./doc/pdf/%.pdf: ./source/%.sl
	@mkdir -p $(@D)
	sl-weave --format=pdf --output-file=$@ $<


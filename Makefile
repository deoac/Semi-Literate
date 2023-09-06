SHELL := /bin/zsh
.PHONY: Makefile all modules binaries executables markdowns docs clean test install

SOURCEDIR   := ./source
BINDIR	  := ./bin
DOCDIR  	:= ./docs
MODULESDIR  := ./lib/Semi
TESTSDIR	:= ./t
EXECUTABLES := ${BINDIR}

vpath %.sl ${SOURCEDIR}
vpath %.rakumod ${MODULESDIR}
vpath %. ${BINDIR}

debug:       all view
all: 		 modules executables docs
temp: 		 temporary module-install all
modules: 	 Literate.rakumod module-install
binaries: 	 sl-tangle sl-weave
executables: binaries executable-install

SOURCES          := $(wildcard ./source/*.sl)
HTML_TARGETS     := $(patsubst ./source/%.sl, ./docs/html/%.html,   $(SOURCES))
MARKDOWN_TARGETS := $(patsubst ./source/%.sl, ./docs/markdown/%.md, $(SOURCES))
PDF_TARGETS      := $(patsubst ./source/%.sl, ./docs/pdf/%.pdf,     $(SOURCES))

docs: html markdown pdf
html: $(HTML_TARGETS)
markdown: $(MARKDOWN_TARGETS)
pdf: $(PDF_TARGETS)

view:
	@open README.md
	@open README.html

temporary:
	@chmod -R a+w lib/
	@echo -n "> Uninstalling Semi::Literate..."
	@zef uninstall Semi::Literate >/dev/null
	@echo "\e[32mOK\e[0m"
	@echo -n "> pod-tangling Literate.sl..."
	@pod-tangle source/Literate.sl > lib/Semi/Literate.rakumod
	@chmod -R a-w lib/
	@echo "\e[32mOK\e[0m"

Literate.rakumod: Literate.sl
	@chmod -R a+w lib/
	@echo -n "> Compiling the Semi::Literate module..."
	@sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod
	@chmod -R a-w lib/
	@echo "\e[32mOK\e[0m"

module-install:
	@echo -n "> Installing the newly created module with zef..."
	@zef install --force-build --force-install --force-test . >/dev/null
	@echo "\e[32mOK\e[0m"

sl-tangle: Literate.rakumod sl-tangle.sl
	@chmod -R a+w bin/
	@echo -n "> Creating the sl-tangle executable..."
	@pod-tangle source/sl-tangle.sl > bin/sl-tangle
	@chmod -R a-w,a+x bin/
	@echo "\e[32mOK\e[0m"

sl-weave: Literate.rakumod sl-weave.sl
	@chmod -R a+w bin/
	@echo -n "> Creating the sl-weave executable..."
	@bin/sl-tangle source/sl-weave.sl  > bin/sl-weave
	@chmod -R a-w,a+x bin/
	@echo "\e[32mOK\e[0m"

executable-install:
	@echo -n "> Installing the newly created executables with zef..."
	@zef install --force-build --force-install --force-test . >/dev/null
	@echo "\e[32mOK\e[0m"

install:
	@echo -n "> Installing the module and the executables with zef..."
	@zef install --force-build --force-install --force-test . >/dev/null
	@echo "\e[32mOK\e[0m"

test: ${LITERATE} executables
	@echo -n "> Running the tests..."
	@prove6 -l -v
	@echo "\e[32mOK\e[0m"

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
	@echo -n "> Opening the .md file and verifying that it looks OK..."
	@open deleteme.md
	@sleep 5
	@echo "\e[32mOK\e[0m"

clean:
	@echo "> Deleting the intermediate files..."
	@rm -rf deleteme.p6 deleteme.raku deleteme.md
	@echo -n "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/
	@echo "\e[32mOK\e[0m"


create_doc_dirs:
	@echo -n "> Creating the document directories..."
	mkdir -p $(DOCDIR)/html
	mkdir -p $(DOCDIR)/markdown
	mkdir -p $(DOCDIR)/pdf
	@echo "\e[32mOK\e[0m"

./docs/html/%.html: ./source/%.sl
	@mkdir -p $(@D)
	@echo -n "> Creating an HTML document for $<..."
	@sl-weave --format=html --/verbose --output-file=$@ $<
	@echo "\e[32mOK\e[0m"

./docs/markdown/%.md: ./source/%.sl
	@mkdir -p $(@D)
	@echo -n "> Creating a Markdown document for $<..."
	@sl-weave --format=markdown --/verbose --output-file=$@ $<
	@echo "\e[32mOK\e[0m"

./docs/pdf/%.pdf: ./source/%.sl
	@mkdir -p $(@D)
	@echo -n "> Creating a PDF document for $<..."
	@sl-weave --format=pdf --/verbose --output-file=$@ $<
	@echo "\e[32mOK\e[0m"


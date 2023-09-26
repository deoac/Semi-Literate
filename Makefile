SHELL := /bin/zsh
.PHONY: Makefile all-code all-docs all module binaries executables \
	    docs html markdown pdf text man pod latex \
		install-all \
		touch_sources clean test \
		write lock del_docs \
		temp temporary debug it


SOURCEDIR        := ./source
BINDIR           := ./bin
DOCDIR           := ./docs
MODULESDIR       := ./lib/Semi
TESTSDIR         := ./t
EXECUTABLES      := ${BINDIR}
RAKU_MODULE      := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/sources/A12861C6F020F7848C33E00652D93FCEB0ABE1C1
WEAVE_EXECUTABLE := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/resources/B341CB1403A58D057C239FBEBF2138FB5BAD8C15
TANGLE_BINARY    := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/bin/sl-tangle
WEAVE_BINARY     := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/bin/sl-weave

vpath %.sl      ${ SOURCEDIR}
vpath %.rakumod ${ MODULESDIR}
vpath %.        ${ BINDIR}

SOURCES              := $(wildcard ./source/*.sl)
HTML_TARGETS         := $(patsubst ./source/%.sl, ./docs/html/%.html,   $(SOURCES))
MAN_TARGETS          := $(patsubst ./source/%.sl, ./docs/man/%.1,       $(SOURCES))
MARKDOWN_TARGETS     := $(patsubst ./source/%.sl, ./docs/markdown/%.md, $(SOURCES))
PDF_TARGETS          := $(patsubst ./source/%.sl, ./docs/pdf/%.pdf,     $(SOURCES))
POD_TARGETS          := $(patsubst ./source/%.sl, ./docs/pod/%.rakudoc, $(SOURCES))
TEXT_TARGETS         := $(patsubst ./source/%.sl, ./docs/text/%.txt,    $(SOURCES))
TEX_TARGETS          := $(patsubst ./source/%.sl, ./docs/tex/%.tex,     $(SOURCES))
RAKU_MODULE_TARGET   := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/sources/A12861C6F020F7848C33E00652D93FCEB0ABE1C1
TANGLE_BINARY_TARGET := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/bin/sl-tangle
WEAVE_BINARY_TARGET  := /usr/local/Cellar/rakudo-star/2023.08/share/perl6/site/bin/sl-weave

it: 		 module html markdown view
docs:        html markdown text pod man
all:         all-code all-docs
all-code: 	 touch_sources module executables
all-docs: 	 markdown text html pdf tex pod man
module: 	 $(RAKU_MODULE_TARGET)
binaries: 	 bin/sl-tangle bin/sl-weave
executables: binaries install-all
html:  	     $(HTML_TARGETS)
man: 		 $(MAN_TARGETS)
markdown:    $(MARKDOWN_TARGETS)
pdf: 		 $(PDF_TARGETS)
pod: 		 $(POD_TARGETS)
tex: 		 $(TEX_TARGETS)
text: 		 $(TEXT_TARGETS)

temp: 		 write del_docs temporary
debug:       touch_sources all view

touch_sources:
	@touch source/*
	@-del docs &>/dev/null

view: $(RAKU_MODULE_TARGET) html markdown
	@open README.md
	@open README.html

temporary:
	@echo -n "> Uninstalling Semi::Literate..."; \
	-zef uninstall Semi::Literate &> /dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \
	echo -n "> pod-tangling Literate.sl..."; \
	pod-tangle source/Literate.sl > lib/Semi/Literate.rakumod; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \
	echo -n "> pod-tangling sl-tangle.sl..."; \
	pod-tangle source/sl-tangle.sl > bin/sl-tangle; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \
	echo -n "> pod-tangling sl-weave.sl..."; \
	pod-tangle source/sl-weave.sl > bin/sl-weave; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \

lib/Semi/Literate.rakumod: source/Literate.sl
	@chmod -R a+w lib/; \
	echo -n "> Compiling the Semi::Literate module..."; \
	sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


bin/sl-tangle: source/sl-tangle.sl $(RAKU_MODULE_TARGET)
	@chmod -R a+w bin/; \
	echo -n "> Creating the sl-tangle executable..."; \
	pod-tangle source/sl-tangle.sl > bin/sl-tangle; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \
	chmod -R a+x bin/

bin/sl-weave: source/sl-weave.sl  $(RAKU_MODULE_TARGET)
	@chmod -R a+w bin/; \
	echo -n "> Creating the sl-weave executable..."; \
	bin/sl-tangle source/sl-weave.sl  > bin/sl-weave; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \
	chmod -R a+x bin/


$(RAKU_MODULE_TARGET): lib/Semi/Literate.rakumod
	@echo -n "> Installing the newly created module with zef..."; \
	zef install --force-build --force-install --force-test . >/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"

$(TANGLE_BINARY_TARGET): bin/sl-tangle $(RAKU_MODULE_TARGET)
	@echo -n "> Installing the newly created tangle executable with zef..."; \
	zef install --force-build --force-install --force-test . >/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"

$(WEAVE_BINARY_TARGET): bin/sl-weave $(RAKU_MODULE_TARGET)
	@echo -n "> Installing the newly created weave executable with zef..."; \
	zef install --force-build --force-install --force-test . >/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"

install-all: $(RAKU_MODULE_TARGET) bin/sl-tangle bin/sl-weave
	@echo -n "> Installing the module and the executables with zef..."; \
	zef install --force-build --force-install --force-test . >/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"

test:
	@echo -n "> Running the tests..."
	@prove6 -l -v
	@echo "\e[32mOK\e[0m"

sanity_tests:
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
	@rm -rf deleteme.*
	@echo -n "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/
	@echo "\e[32mOK\e[0m"


create_doc_dirs:
	@echo -n "> Creating the document directories..."
	mkdir -p $(DOCDIR)/html
	mkdir -p $(DOCDIR)/markdown
	mkdir -p $(DOCDIR)/pdf
	mkdir -p $(DOCDIR)/text
	@echo "\e[32mOK\e[0m"

./docs/html/%.html: ./source/%.sl
	@mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating an HTML document for $<..."; \
	sl-weave --format=html --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


./docs/markdown/%.md: ./source/%.sl
	@mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating a Markdown document for $<..."; \
	sl-weave --format=markdown --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


./docs/pdf/%.pdf: ./source/%.sl
	@mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating a PDF document for $<..."; \
	sl-weave --format=pdf --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


./docs/text/%.txt: ./source/%.sl
	@mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating a text document for $<..."; \
	sl-weave --format=text --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


./docs/man/%.1: ./source/%.sl
	@-mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating a man page for $<..."; \
	sl-weave --format=Man --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


./docs/tex/%.tex: ./source/%.sl
	@mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating a TᴇX page for $<..."; \
	sl-weave --format=Latex --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


./docs/pod/%.rakudoc: ./source/%.sl
	@mkdir -p $(@D); \
	chmod -R a+w $(@D); \
	echo -n "> Creating a Pod6 page for $<..."; \
	sl-weave --format=Pod --/verbose --output-file=$@ $< 2>/dev/null; \
	if [ $$? -eq 0 ]; then echo -n "\e[32mOK"; else echo -n "\e[31mNot OK"; fi; echo "\e[0m"; \


write:
	@chmod a+w **/*

lock:
	@chmod a-w **/*

del_docs:
	@chmod a+w **/*
	@rm -rf docs

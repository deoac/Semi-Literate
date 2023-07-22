SHELL := /bin/zsh
.PHONY: Makefile all  modules binaries executables markdowns pre post clean test install

SOURCES  := ./source
BIN      := ./bin
DOCS     := ./docs
MARKDOWN := ${DOCS}/markdown
MODULES  := ./lib/Semi
TESTS    := ./t
EXECUTABLES := ./bin
LITERATE := ${MODULES}/Literate.rakumod

vpath %.sl ${SOURCES}
vpath %.rakumod ${MODULES}

Literate.rakumod: Literate.sl
	@echo "> Compiling the Semi::Literate module..."
	@sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod

${MARKDOWN}/%.md: modules executables
	@mkdir -p ${MARKDOWN}
	@echo "> Creating the .md file for the Semi::Literate module..."
	@bin/sl-weave  ${SOURCES}/Literate.sl  > ${MARKDOWN}/Literate.md
	@echo "> Creating the .md file for the sl-tangle executable..."
	@bin/sl-weave  ${SOURCES}/sl-tangle.sl > ${MARKDOWN}/sl-tangle.md
	@echo "> Creating the .md file for the sl-weave executable..."
	@bin/sl-weave  ${SOURCES}/sl-weave.sl  > ${MARKDOWN}/sl-weave.md


all: 		 all-pre modules executables markdowns all-post
modules: 	 mods-pre Literate.rakumod module-install mods-post
binaries: 	 ${BIN}/sl-tangle ${BIN}/sl-weave
executables: exec-pre modules binaries executable-install exec-post
markdowns:   md-pre ${MARKDOWN}/%.md md-post

${BIN}/sl-tangle: modules sl-tangle.sl
	@echo "> Unsetting permissions..."
	@chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/
	@echo "> Creating the sl-tangle executable..."
	@sl-tangle source/sl-tangle.sl > bin/sl-tangle

${BIN}/sl-weave: modules sl-weave.sl
	@echo "> Unsetting permissions..."
	@chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/
	@echo "> Creating the sl-weave executable..."
	@bin/sl-tangle source/sl-weave.sl  > bin/sl-weave

executable-install:
	@echo "> Installing the newly created executables..."
	@zef install --force-build --force-install --force-test . >/dev/null

module-install:
	@echo "> Installing the newly created module..."
	@zef install --force-build --force-install --force-test . >/dev/null

test: pre ${LITERATE} executables post
	@echo "> Running the tests..."
	@prove6 -l -v


${MODULES}/%.rakumod: ${SOURCES}/Literature.sl
	@sl-tangle source/Literate.sl > lib/Semi/Literate.rakumod

exec-pre:
#	@echo "> Unsetting permissions..."
	@chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/

mods-pre:
#	@echo "> Unsetting permissions..."
	@chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/

md-pre:
#	@echo "> Unsetting permissions..."
	@chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/

all-pre:
#	@echo "> Unsetting permissions..."
	@chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/

compile-module: source/Literate.sl
	@echo "> Compiling the Semi::Literate module..."
	@sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod

install-module: lib/Semi/Literate.rakumod
	@echo "> Installing the newly created module..."
	@zef install --verbose --force-build --force-install --force-test .

create-executables: source/sl-tangle.sl source/sl-weave.sl
	@echo "> Creating the sl-tangle executable..."
	@sl-tangle source/sl-tangle.sl > bin/sl-tangle
	@echo "> Creating the sl-weave executable..."
	@bin/sl-tangle source/sl-weave.sl  > bin/sl-weave

install-executables: bin/sl-weave bin/sl-tangle
	@echo "> Installing the newly created executables..."
	@zef install --verbose --force-build --force-install --force-test .

create-pdf: source/Literate.sl source/sl-tangle.sl source/sl-weave
	@echo "> Creating the .pdf file for the Semi::Literate module..."
	@bin/sl-weave --format=pdf --output-file=docs/Literate.pdf source/Literate.sl
	@echo "> Creating the .pdf file for the sl-tangle executable..."
	@bin/sl-weave --format=pdf --output-file=docs/sl-tangle.pdf source/sl-tangle.sl
	@echo "> Creating the .pdf file for the sl-weave executable..."
	@bin/sl-weave --format=pdf --output-file=docs/sl-weave.pdf source/sl-weave.sl

create-html:
	@echo "> Creating the .html file for the Semi::Literate module..."
	@bin/sl-weave --format=HTML source/Literate.sl  > docs/Literate.html
	@echo "> Creating the .html file for the sl-tangle executable..."
	@bin/sl-weave --format=HTML source/sl-tangle.sl > docs/sl-tangle.html
	@echo "> Creating the .html file for the sl-weave executable..."
	@bin/sl-weave --format=HTML source/sl-weave.sl  > docs/sl-weave.html

create-markdown:
	@echo "> Creating the .md file for the Semi::Literate module..."
	@bin/sl-weave  source/Literate.sl  > docs/Literate.md
	@echo "> Creating the .md file for the sl-tangle executable..."
	@bin/sl-weave  source/sl-tangle.sl > docs/sl-tangle.md
	@echo "> Creating the .md file for the sl-weave executable..."
	@bin/sl-weave  source/sl-weave.sl  > docs/sl-weave.md

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

mods-post:
#	@echo "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/

exec-post:
#	@echo "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/

all-post:
#	@echo "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/

md-post:
#	@echo "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/

clean:
	@echo "> Deleting the intermediate files..."
	@rm -rf deleteme.p6 deleteme.raku deleteme.md
	@echo "> Setting permissions..."
	@chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/



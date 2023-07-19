# Create the module and it's Markdown file
command='sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod '
echo $command; eval $command; echo ''

command='zef install --verbose --force-build --force-install --force-test . '
echo $command; eval $command; echo '';

command='sl-tangle source/sl-tangle.sl > bin/sl-tangle '
echo $command; eval $command;

command='bin/sl-tangle source/sl-weave.sl  > bin/sl-weave '
echo $command; eval $command; echo ''

command='zef install --verbose --force-build --force-install --force-test . '
echo $command; eval $command; echo '';

command='bin/sl-weave  source/Literate.sl  > docs/Literate.md '
echo $command; eval $command;
command='bin/sl-weave  source/sl-tangle.sl > docs/sl-tangle.md '
echo $command; eval $command;
command='bin/sl-weave  source/sl-weave.sl  > docs/sl-weave.md '
echo $command; eval $command; echo '';

## test the module
command='raku lib/Semi/Literate.rakumod --testw > deleteme.p6 '
echo $command; eval $command;
command='raku lib/Semi/Literate.rakumod --testt > deleteme.raku '
echo $command; eval $command; echo ''

## look at the created files
#mvim -p deleteme.p6 deleteme.raku 2> /dev/null > /dev/null

## test the raku file
command='raku -c deleteme.raku '
echo $command; eval $command; echo ''
sleep 2

## create a Markdown file and look at it.
command='raku --doc=MarkDown2 deleteme.p6 >deleteme.md '
echo $command; eval $command
command='open deleteme.md'
echo $command; eval $command; echo ''

sleep 5
command='rm -rf deleteme.p6 deleteme.raku deleteme.md'
echo $command; eval $command;

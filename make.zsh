function print_status_with_output() {
    if [ $? -eq 0 ]; then
        printf "\e[32msuccessfully\e[0m\n"  # Print 'successfully' in green
    else
        printf "\e[31mfailed\e[0m\n"  # Print 'failed' in red
        cat <<< "$output"
    fi
}

printf "> Unsetting permissions..."
command='chmod -R a+w bin/; chmod -R a+w docs/; chmod -R a+w lib/'
output=$(eval $command 2>&1); print_status_with_output;

# Creating the module with the grammar, tangle(), and weave()
printf "> Compiling the Semi::Literate module..."
command='sl-tangle source/Literate.sl  > lib/Semi/Literate.rakumod '
output=$(eval $command 2>&1); print_status_with_output;

# install the module so we can use the new .rakumod file
# for the remainder of the build
printf "> Installing the newly created module..."
command='zef install --verbose --force-build --force-install --force-test . '
output=$(eval $command 2>&1); print_status_with_output;

# Creating the sl-tangle executable (with the new .rakumod file)
# Note: this command requires the current sl-tangle to be working.
printf "> Creating the sl-tangle executable..."
command='sl-tangle source/sl-tangle.sl > bin/sl-tangle '
output=$(eval $command 2>&1); print_status_with_output;

# Creating the new sl-weave executable (with the new .rakumod file)
# Note: this command requires the new sl-tangle to be working.
printf "> Creating the sl-weave executable..."
command='bin/sl-tangle source/sl-weave.sl  > bin/sl-weave '
output=$(eval $command 2>&1); print_status_with_output;

# Install the module AGAIN, so we can use the new sl-weave
# for the remainder of the build
printf "> Installing the newly created executables..."
command='zef install --verbose --force-build --force-install --force-test . '
output=$(eval $command 2>&1); print_status_with_output;

# Creating Markdown documents for the module and the two executables.
printf "> Creating the .md file for the Semi::Literate module..."
command='bin/sl-weave  source/Literate.sl  > docs/Literate.md '
output=$(eval $command 2>&1); print_status_with_output;
printf "> Creating the .md file for the sl-tangle executable..."

command='bin/sl-weave  source/sl-tangle.sl > docs/sl-tangle.md '
output=$(eval $command 2>&1); print_status_with_output;

printf "> Creating the .md file for the sl-weave executable..."
command='bin/sl-weave  source/sl-weave.sl  > docs/sl-weave.md '
output=$(eval $command 2>&1); print_status_with_output;

## Test the module by tangling and weaving itself.
printf "> Tangling the module source code to a Raku file..."
command='raku lib/Semi/Literate.rakumod --testt > deleteme.raku '
output=$(eval $command 2>&1); print_status_with_output;

printf "> Weaving the module source code to a Pod6 file..."
command='raku lib/Semi/Literate.rakumod --testw > deleteme.p6 '
output=$(eval $command 2>&1); print_status_with_output;

printf "> Verifying the raku file compiles..."
command='raku -c deleteme.raku '
output=$(eval $command 2>&1); print_status_with_output;

printf "> Verifying the Pod6 file compiles..."
command='raku -c deleteme.p6 '
output=$(eval $command 2>&1); print_status_with_output;

printf "> Verifying that the Pod6 file can be made into a Markdown file..."
command='raku --doc=MarkDown2 deleteme.p6 >deleteme.md '
output=$(eval $command 2>&1); print_status_with_output;

printf "> Opening the .md file and verifying that it looks OK..."
command='open deleteme.md'
output=$(eval $command 2>&1); print_status_with_output;

printf "> Deleting the intermediate files..."
sleep 5 # Give the computer enough time to open the Markdown file before...
command='rm -rf deleteme.p6 deleteme.raku deleteme.md'
output=$(eval $command 2>&1); print_status_with_output;

printf "> Setting permissions..."
command='chmod -R a+x,a-w bin/; chmod -R a-w docs/; chmod -R a-w lib/'
output=$(eval $command 2>&1); print_status_with_output;


#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sat 16 Sep 2023 11:28:08 PM EDT
# Version 0.0.1

# begin-no-weave
# always use the latest version of Raku
use v6.*;
use Useful::Regexes;

use PrettyDump;
use Data::Dump::Tree;
#end-no-weave

=begin pod
=comment 1


=TITLE An implementation of Semi-Literate programming for Raku with Pod6

=head1 INTRODUCTION
=comment 2

I want to create a semi-literate Raku source file with the extension
C<.sl>. Then, I will I<weave> it to generate a readable file in formats like
Markdown, PDF, HTML, and more. Additionally, I will I<tangle> it to create source
code without any Pod6.

To do this, I need to divide the file into C<Pod> and C<Code> sections by parsing
it. For this purpose, I will create a dedicated Grammar.

(See L<Useful::Regexes|https://github.com/deoac/Useful-Regexes> for the
    definitions of the named regexes used here. (C<<hws>> == Horizontal WhiteSpace))

=head1 The Grammar
=comment 2
=end pod


#use Grammar::Tracer;
grammar Semi::Literate is export does Useful::Regexes {

=begin pod

Our file will exclusively consist of C<Pod> or C<Code> sections, and nothing
else. The C<Code> sections are of two types, a) code that is woven into the
documentation, and b) code that is not woven into the documentation.  The
C<TOP> token clearly indicates this.

=end pod

    token TOP {
        [
          || <pod>
          || <code>
        ]*
    } # end of token TOP

    token code  {
        [
          || <non-woven>+
          || <woven>+
        ]
    } # end of token code

=begin pod
=comment 1

=head2 The Pod6 delimiters

According to the L<documentation|https://docs.raku.org/language/pod>,

=begin defn

    Every Pod6 document has to begin with C<=begin pod> and end with C<=end> pod.

=end defn

So let's define those tokens.
=head3 The C<begin-pod> token

=end pod


    token begin-pod {
        <leading-ws>
        '=' begin <hws> pod
        <ws-till-EOL>
    } # end of token begin-pod

=begin pod
=comment 1

=head3 The C<end-pod> token

The C<end-pod> token is much simpler.

=end pod

    token end-pod  {
        <leading-ws>
        '=' end <hws> pod
        <ws-till-EOL>
    } # end of token end-pod

=begin pod
=comment 1

=head2 Replacing Pod6 sections with blank lines

When we I<tangle> the semi-literate code, all the Pod6 will be removed.  This
would leave a lot of blank lines in the Raku code.  So we'll clean it up.
We provide the option for users to specify the number of empty
lines that should replace a C<pod> block. To do this, simply add a Pod6 comment
immediately after the C<=begin  pod> statement.  The comment can say anything
you like, but must end with a digit specifying the number of blank lines with
which to replace the Pod6 section.

=begin code :lang<raku>

    =begin pod
    =comment I want this pod block replaced by only one line 1
    ...
    =end pod

=end code
Here's the relevant regex:
=end pod

    token blank-line-comment {
        <leading-ws>
        '=' comment
        \N*?
        $<num-blank-lines> = (\d+)?
        <ws-till-EOL>
    } # end of token blank-line-comment

=begin pod
=comment 1

=head2 The C<Pod> token

Within the delimiters, all lines are considered documentation. We will refer to
these lines as C<plain-lines>. Additionally, it is possible to have nested
C<Pod> sections. This allows for a hierarchical organization of
documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the
'zero-or-more' quantifier on the lines of documentation, allowing for the
possibility of having no lines in the block.

=end pod

    token pod {
        <.begin-pod>
        <blank-line-comment>?
            [<pod> | <.plain-line>]*
        <.end-pod>
    } # end of token pod

=begin pod
=comment 1

=head2 The C<Code> tokens

The C<Code> sections are similarly easily defined.  There are two types of
C<Code> sections, depending on whether they will appear in the woven code.

=head3 Woven sections

These sections are trivially defined.
They are just one or more C<plain-line>s.

=end pod


    token woven  {
        [
            || <.plain-line>
        ]+
    } # end of token woven

=begin pod
=comment 1

=head3 Non-woven sections

Sometimes there will be code you do not want woven into the documentation, such
as boilerplate code like C<use v6.d;>.  You have two options to mark such code.
By individual lines or by a delimited block of code.

=end pod

    token non-woven {
        [
          || <.one-line-no-weave>
          || <.delimited-no-weave>
        ]+
    } # end of token non-woven
=begin pod
=comment 1

=head4 One line of code

Simply append C<# no-weave-this-line> at the end of the line!

=end pod

    regex one-line-no-weave {
        $<the-code>=(<leading-ws> <optional-chars>)
        '#' <hws> 'no-weave-this-line'
        <ws-till-EOL>
    } # end of token one-line-no-weave

=begin pod
=comment 1



=head4 Delimited blocks of code

Simply add comments C<# begin-no-weave> and C<#end-no-weave> before and after
the code you want ignored in the formatted document.

=end pod

    token begin-no-weave {
        <leading-ws>
        '#' <hws> 'begin-no-weave'
        <ws-till-EOL>
    } # end of token <begin-no-weave>

    token end-no-weave {
        <leading-ws>
        '#' <hws> 'end-no-weave'
        <ws-till-EOL>
    } # end of token <end--no-weave>

    token delimited-no-weave {
        <.begin-no-weave>
            <.plain-line>*
        <.end-no-weave>
    } # end of token delimited-no-weave


=begin pod
=comment 1

=head3 The C<plain-line> token

The C<plain-line> token is, really, any line at all...
... except for one subtlety.  They it can't be one of the begin/end delimiters.
We can specify that with a L<Regex Boolean Condition
Check|https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check>.


=end pod

    token plain-line {
        :my $*EXCEPTION = False;
        [
          ||  <.begin-pod>         { $*EXCEPTION = True }
          ||  <.end-pod>           { $*EXCEPTION = True }
          ||  <.begin-no-weave>    { $*EXCEPTION = True }
          ||  <.end-no-weave>      { $*EXCEPTION = True }
          ||  <.one-line-no-weave> { $*EXCEPTION = True }
          || [^^ <rest-of-line>]
        ]
        <?{ !$*EXCEPTION }>
    } # end of token plain-line

=begin pod
=comment 1

And that concludes the grammar for separating C<Pod> from C<Code>!

=end pod

} # end of grammar Semi::Literate

=begin pod
=comment 2

=head1 The Tangle subroutine

This subroutine will remove all the Pod6 code from a semi-literate file
(C<.sl>) and keep only the Raku code.


=end pod

#begin-no-weave
#multi tangle ( Str $input-file!, Bool :v(:$verbose) ) {
#    tangle ($input-file.IO, :$verbose);
#} # end of multi tangle ( Str $input-file!, Bool :v(:$verbose) )
#end-no-weave

multi tangle (

=begin pod

The subroutine has a single parameter, which is the input filename. The
filename is required.  Typically, this parameter is obtained from the command
line or passed from the subroutine C<MAIN>.
=end pod
    Str $input-file!,
#    IO::Path $input-file!,

=begin pod
=comment 1
=head3 C<$verbose>
Use verbose only for debugging
=end pod
    Bool :v(:$verbose)      = False;
=begin pod

The subroutine will return a C<Str>, which will be a working Raku program.
=end pod
        --> Str ) is export {
=begin pod
=comment 1

First we will get the entire Semi-Literate C<.sl> file...
=end pod

    my Str $source = $input-file.IO.slurp;

=begin pod
=comment 1
=head2 Clean the source

=head3 Remove unnecessary blank lines

Very often the C<code> section of the Semi-Literate file will have blank lines
that you don't want to see in the tangled working code.
For example:

=begin code :lang<raku>

                                                # <== unwanted blank lines
                                                # <== unwanted blank lines
    sub foo () {
        { ... }
    } # end of sub foo ()
                                                # <== unwanted blank lines
                                                # <== unwanted blank lines

=end code
=end pod

=begin pod
=comment 1


So we'll remove the blank lines immediately outside the beginning and end of
the Pod6 sections.
=end pod

    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{    \=end (\N*) \n+}      =  "\=end$0\n";
    $cleaned-source ~~ s:g{\n+ \=begin (<hws> pod) } = "\n\=begin$0";

=begin pod
=comment 1
=head2 The interesting stuff

We parse it using the C<Semi::Literate> grammar
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

#    note "submatches.elems: {@submatches.elems}";
    my Str $raku-code = @submatches.map( {

=begin pod
=comment 1
=head3 Replace Pod6 sections with blank lines

=end pod


        when .key eq 'pod' {
            my $num-blank-lines =
                .value.hash<blank-line-comment><num-blank-lines>;
            "\n" x $num-blank-lines with $num-blank-lines;
        }

=begin pod
=comment 1

Add all the C<Code> sections.
=end pod

        when .key eq 'code' {
            .value;
        } # end of when .key eq 'code'

        # begin-no-weave
        default { die "Tangle: should never get here.
                    .key ==> {.key} .{.key}.keys => {.{.key}.keys}";
        } # end of default
        #end-no-weave
=begin pod
=comment 1

... and we will join all the code sections together...
=end pod

    } # end of my Str $raku-code = @submatches.map(
    ).join;

=begin pod
=comment 1
=head3 Remove the I<no-weave> delimiters

=end pod

    $raku-code ~~ s:g{
                        | <Semi::Literate::begin-no-weave>
                        | <Semi::Literate::end-no-weave>
                  } = '';

    $raku-code ~~ s:g{ <Semi::Literate::one-line-no-weave> }
                    = "$<Semi::Literate::one-line-no-weave><the-code>\n";

=begin pod
=comment 1
=head3 remove blank lines at the end

=end pod
    # remove blank lines at the end
    $raku-code ~~ s{\n  <blank-line>* $ } = '';

=begin pod
=comment 1

And that's the end of the C<tangle> subroutine!
=end pod
    return $raku-code;
} # end of sub tangle (

=begin pod
=comment 2

=head1 The Weave subroutine

The C<Weave> subroutine will I<weave> the C<.sl> file into a readable Markdown,
HTML, or other format.  It is a little more complicated than C<sub tangle>
because it has to include the C<code> sections.

=end pod

sub weave (

=begin pod
=comment 1
=head2 The parameters of Weave

C<sub weave> will have several parameters.
=head3 C<$input-file>

The input filename is required. Typically,
this parameter is obtained from the command line through a wrapper subroutine
C<MAIN>.

=end pod

    Str $input-file!;
=begin pod
=comment 1
=head3 C<$line-numbers>

It can be useful to print line numbers in the code listing.  It currently
defaults to True.
=end pod

    Bool :l(:$line-numbers) = True;
        #= Should line numbers be added to the embeded code?

=begin pod
=comment 1
=head3 C<$verbose>
Use verbose only for debugging
=end pod
    Bool :v(:$verbose)      = False;

=begin pod
C<sub weave> returns a Str.
=end pod

        --> Str ) is export {

    my UInt $line-number = 1;

=begin pod
First we will get the entire C<.sl> file...
=end pod

    my Str $source = $input-file.IO.slurp;

=begin pod
=comment 1
=head3 Remove blank lines at the begining and end of the code

B<EXPLAIN THIS!>

=end pod

#TODO create a subroutine since this is used in both tangle and weave
    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{    \=end (\N*) \n+}      =  "\=end$0\n";
    $cleaned-source ~~ s:g{\n+ \=begin (<hws> pod) } = "\n\=begin$0";

=begin pod
=comment 1
=head3 remove blank lines at the end of the code

=end pod
    # remove blank lines at the end
    $cleaned-source ~~ s{\n  <blank-line>* $ } = '';

=begin pod
=comment 1

=head2 Interesting stuff

...Next, we parse it using the C<Semi::Literate> grammar
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

=begin pod
=comment 1

...And now begins the interesting part.  We iterate through the submatches and
insert the C<code> sections into the Pod6...
=end pod


=begin pod
This function checks if the line of code is a full line comment. If so,
return False, so nothing will be printed for this line.

The function will return a C<Seq>uence of (possibly) modified lines.  It needs
to be a C<Seq> because the return value will then be fed to a feed operator
(C<==\>>)
=end pod

    sub remove-comments (Seq $lines --> List) {
        #TODO Add a parameter to sub weave()

        my token full-line-comment {
            $<the-code>=(<leading-ws>)
            '#'
            <rest-of-line>
        } # end of my token full-line-comment

        #TODO this regex is not robust.  It will tag lines with a # in a string,
        #unless the string delimiter is immediately before the #
        my regex partial-line-comment {
            $<the-code>=(<leading-ws> <optional-chars>)  # optional code
            <!after <opening-quote>>         #
            '#'                              # comment marker
            $<the-comment>=<-[#]>*           # the actual comment
            <ws-till-EOL>
        } # end of my regex comment

        my @retval = ();
        for $lines.List -> $line {
            given $line {
                # don't print full line comments
                when /<full-line-comment>/ {; #`[[do nothing]] }

                # remove comments that are at the end of a line.
                # The code will almost always end with a ';' or a '}'.
                when /<partial-line-comment>/ {
                    @retval.push: $<partial-line-comment><the-code>;
                }

                default
                    { @retval.push: $line; }
            } # end of given $line
        } # end of for $lines -> $line

        return @retval;
    } # end of sub remove-comments {Pair $p is rw}

    my Str $weave = @submatches.map( {
        when .key eq 'pod' {
            .value
        } # end of when .key eq 'pod'

        when .key eq 'code' {
            { qq:to/EOCB/ if .<code><woven>; }
            \=begin pod
            \=begin code :lang<raku>
             {
                $_<code><woven>
                ==> lines()
                ==> remove-comments()
                ==> map(
                        $line-numbers
                            ?? {"%4s| %s\n".sprintf($line-number++, $_) }
                            !! {     "%s\n".sprintf(                $_) }
                )
                ==> chomp() # get rid of the last \n
             }
            \=end code
            \=end pod
            EOCB
        } # end of when .key eq 'code'

        # begin-no-weave
        default { die "Weave: should never get here.
                    .key ==> {.key} .{.key}.keys => {.{.key}.keys}";
        } # end of default
        # end-no-weave
    } # end of my Str $weave = @submatches.map(
    ).join;

=begin pod
=comment 1
=head3 Remove unseemly blank lines
=end pod
    # The code below will occur wherever non-woven appeared.
    # We'll need to remove it from the woven Pod6.  Otherwise, it
    # creates an unseemly blank line.
    my Str $non-woven-blank-lines = qq:to/EOQ/;
        \=end code
        \=end pod
        \=begin pod
        \=begin code :lang<raku>
        EOQ

    my Regex $full-comment-blank-lines = rx[
        '=begin pod'              <ws-till-EOL>
        '=begin code :lang<raku>' <ws-till-EOL>
        [<leading-ws> \d+ | '|'?  <ws-till-EOL>]*
        '=end code'               <ws-till-EOL>
        '=end pod'                <ws-till-EOL>
    ];

    $weave ~~ s:g{ $non-woven-blank-lines | <$full-comment-blank-lines> } = '';

=begin pod
=comment 1

And that's the end of the C<weave> subroutine!
=end pod

    "deleteme.rakudoc".IO.spurt($weave) if $verbose; # no-weave-this-line
    return $weave
} # end of sub weave (

=begin pod
=comment 1
=head1 NAME

C<Semi::Literate> - A semi-literate way to weave and tangle Raku/Pod6 source code.
=head1 VERSION

This documentation refers to C<Semi-Literate> version 0.0.1

=head1 SYNOPSIS

=begin code :lang<raku>

use Semi::Literate;
# Brief but working code example(s) here showing the most common usage(s)

# This section will be as far as many users bother reading
# so make it as educational and exemplary as possible.

=end code
=head1 DESCRIPTION

=head2 Influences

C<Semi::Literate> is based on Daniel Sockwell's
L<Pod::Literate|https://www.codesections.com/blog/weaving-raku/>.

Also influenced by zyedidia's <Literate|https://zyedidia.github.io/literate/>
program. Especially the idea of not weaving some portions of the code.

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head2, etc.)

=head1 DEPENDENCIES

    Useful::Regexes

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Patches are welcome.

=head1 AUTHOR

Shimon Bollinger (deoac.bollinger@gmail.com)

=head1 LICENSE AND COPYRIGHT

© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Raku itself.
See L<The Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=end pod

# begin-no-weave
my %*SUB-MAIN-OPTS =
  :named-anywhere,             # allow named variables at any location
  :bundling,                   # allow bundling of named arguments
#  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  :allow-no,                   # allow --no-foo as alternative to --/foo
  :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
;

#| Run with option '--pod' to see all of the Pod6 objects
multi MAIN(Bool :$pod!) is hidden-from-USAGE {
    for $=pod -> $pod-item {
        for $pod-item.contents -> $pod-block {
            $pod-block.raku.say;
        }
    }
} # end of multi MAIN (:$pod)

#| Run with option '--doc' to generate a document from the Pod6
#| It will be rendered in Text format
#| unless specified with the --format option.  e.g.
#|       --doc --format=HTML
multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {
    run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
} # end of multi MAIN(Bool :$man!)

my $semi-literate-file = '/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl';
multi MAIN(Bool :$testt!) {
    say tangle($semi-literate-file);
} # end of multi MAIN(Bool :$test!)

multi MAIN(Bool :$testw!) {
    say weave($semi-literate-file);
} # end of multi MAIN(Bool :$test!)

#end-no-weave

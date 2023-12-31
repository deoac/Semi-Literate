#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Wed 27 Sep 2023 02:22:18 PM EDT
# Version 0.0.1

# begin-no-weave
# always use the latest version of Raku
use v6.*;
use Useful::Regexes;

use PrettyDump;
use Data::Dump::Tree;
#end-no-weave

=begin pod


=TITLE An implementation of Semi-Literate programming for Raku with Pod6

=head1 INTRODUCTION
=comment 2

=comment TODO Talk about the history of Literate Programming

I want to create a semi-literate Raku source file with the extension
C<.sl>. Then, you can I<weave> it to generate a readable file in formats like
Markdown, PDF, HTML, and more. Additionally, you can I<tangle> it to create
source code without any Pod6.

To do this, I need to parse the file into C<Pod> and C<Code> sections with
a dedicated grammar.  N<(See
L<Useful::Regexes|https://github.com/deoac/Useful-Regexes> for the definitions
of the named regexes used here. (e.g. C< <hws> > == Horizontal WhiteSpace))>

=head1 The Grammar
=comment 2
=end pod


#use Grammar::Tracer;
grammar Semi::Literate is export does Useful::Regexes {

=begin pod

Our Raku file will exclusively consist of C<Pod> or C<Code> sections, and nothing
else.

=end pod

    token TOP {
        [
          || <pod>
          || <code>
        ]*
    } # end of token TOP

=begin pod

=head2 The C<Pod> token

A Pod6 block is delimited by C<=begin pod> and C<=end pod>.  The body of the
Pod6 block can be empty, can be another Pod6 block, or can consist of
a series of C<plain-line>s.  We will use the 'zero-or-more' quantifier on the
body of the Pod6 block, allowing for the possibility of an empty block.

=end pod

    token pod {
        <begin-pod>
        <num-blank-line-comment>?
            [<pod> || <plain-line>]*
        <end-pod>
    } # end of token pod

=begin pod

=head3 The Pod6 delimiters

According to the L<documentation|https://docs.raku.org/language/pod>:

=comment The line "Every Pod6 document..." must not be reformated as
a paragraph.  If you do, only the first line will be the definition
term.

=begin defn
Every Pod6 document has to begin with '=begin pod' and end with '=end pod'.  Everything between these two delimiters will be processed and used to generate documentation.

=end defn

So let's define those tokens.
=head4 The C<begin-pod> token

=end pod


    token begin-pod {
        <leading-ws>
        '=' begin <hws> pod
        <ws-till-EOL>
    } # end of token begin-pod

=begin pod

=head4 The C<end-pod> token

The C<end-pod> token is similar.

=end pod

    token end-pod  {
        <leading-ws>
        '=' end <hws> pod
        <ws-till-EOL>
    } # end of token end-pod

=begin pod

=head3 The C<num-blank-line-comment> token

I<Replacing Pod6 sections with blank lines>

When we I<tangle> the semi-literate code, all the Pod6 will be removed.  This
would leave a lot of blank lines in the Raku code.  So we'll clean it
up. N<Unlike other Literate Programming systems, we want our tangled code to
be readable.>

By default, we'll replace each Pod6 block with a single blank line. However,
You can specify the number of blank lines that should replace a Pod6 block. To
do this, simply add a C<=comment> immediately after the C<=begin  pod>
statement.  The comment can say anything you like, but must end with a digit
specifying the number of blank lines with which to replace the Pod6
section. Zero is a valid number, for this purpose.

For example:

=begin code :lang<raku>

    =begin pod
    =comment I want this pod block replaced by two blank lines 2
    ...
    =end pod

=end code
Here's the relevant token, where we capture the number of blank lines in the
C<$<num-blank-line-comment><num-blank-lines>> variable.
=end pod

    token num-blank-line-comment {
        <leading-ws>
        '=' comment
        <optional-chars>
        $<num-blank-lines> = (\d+)?
        <ws-till-EOL>
    } # end of token num-blank-line-comment

=begin pod

=head2 The C<Code> tokens

The C<Code> sections are of two types, a) code that is woven into the
documentation, and b) code that is not woven into the documentation.  For
example, you may not want boilerplate code, such as C<use v6.d;>, to be woven
into the documentation.

Note the quantifier C<+> is used on each of the types of C<Code> sections,
rather than on the C<Code> token itself.  Otherwise C<woven> and C<non-woven>
code blocks would not be separated.

=end pod

    token code  {
        [
          || <non-woven>+
          || <woven>+
        ]
    } # end of token code


=begin pod

=head3 Woven sections

These sections are trivially defined.
They are just one or more C<plain-line>s.

=end pod


    token woven  {
        <plain-line>+
    } # end of token woven-code

=begin pod

=head3 Non-woven sections

You have two options to mark code as non-woven.
By individual lines or by a delimited block of code.

=end pod

    token non-woven {
        [
          || <delimited-no-weave>
          || <one-line-no-weave>
        ]+
    } # end of token non-woven
=begin pod

=head4 One line of unwoven code

Simply append C<# no-weave-this-line> at the end of the line!

Note we have to save the code in a variable C<$<the-code>>. As we'll see later,
we'll need to use it when we remove the C<no-weave-this-line> comment.

=end pod

    regex one-line-no-weave {
        $<the-code>=(<leading-ws> <optional-chars>)
        '#' <hws> 'no-weave-this-line'
        <ws-till-EOL>
    } # end of token one-line-no-weave

=begin pod



=head4 Delimited blocks of unwoven code

Simply add comments C<# begin-no-weave> and C<#end-no-weave> before and after
the code you want ignored in the formatted document.

=end pod

    token delimited-no-weave {
        <.begin-no-weave>
            <.plain-line>*
        <.end-no-weave>
    } # end of token delimited-no-weave
=begin pod

The delimiters are defined similarly to the Pod6 delimiters.

=end pod

    token begin-no-weave {
        <leading-ws>                # optional leading whitespace
        '#' <hws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
        <ws-till-EOL>               # optional trailing whitespace or comment
    } # end of token <begin-no-weave>

    token end-no-weave {
        <leading-ws>                # optional leading whitespace
        '#' <hws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
        <ws-till-EOL>               # optional trailing whitespace or comment
    } # end of token <end--no-weave>


=begin pod

=head3 The C<plain-line> token

The C<plain-line> token is, really, any line at all...

... except for one subtlety.  It can't be one of the Pod6 or no-weave
delimiters.  We can enforce that with a L<Regex Boolean Condition
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

And that concludes the grammar for separating C<Pod> from C<Code>!

=end pod

} # end of grammar Semi::Literate

=begin pod
=comment 2
=head1 The Tangle subroutine

This subroutine will remove all the Pod6 code from a semi-literate file
(C<.sl>) and keep only the Raku code.


=end pod

# begin-no-weave
multi tangle (Str $input-file!, Bool :$verbose = False) is export {
    # get the filehandle of the input file and call the other multi tangle()
    samewith $input-file.IO, :$verbose;
} # end of multi tangle () is export
# end-no-weave

multi tangle (

=begin pod

The subroutine has a single parameter, which is the input filename. The
filename is required.  Typically, this parameter is obtained from the command
line or passed from the subroutine C<MAIN>.
=end pod
    IO::Path $input-file!,
=begin pod
Setting C<$verbose> will show debug prints.
=end pod
    Bool :$verbose = False;

=begin pod
The subroutine will return a C<Str>, which will be a working Raku program.
=end pod
        --> Str ) is export {
=begin pod

First we will get the entire Semi-Literate C<.sl> file...
=end pod

    my Str $source = $input-file.slurp;

=begin pod
=head2 The interesting stuff

We parse it using the C<Semi::Literate> grammar
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse(clean $source).caps;

#    note "submatches.elems: {@submatches.elems}";
    my Str $raku-code = @submatches.map( {

=begin pod
=head3 Replace Pod6 sections with blank lines

=end pod


        when .key eq 'pod' {
            my $num-blank-lines =
                .value.hash<blank-line-comment><num-blank-lines>;
            "\n" x ($num-blank-lines // 1); #with $num-blank-lines;
        }

=begin pod

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

... and we will join all the code sections together...
=end pod

    } # end of my Str $raku-code = @submatches.map(
    ).join;

=begin pod
=head3 Remove the I<no-weave> delimiters

=end pod

    $raku-code ~~ s:g{
                        | <Semi::Literate::begin-no-weave>
                        | <Semi::Literate::end-no-weave>
                  } = '';

    $raku-code ~~ s:g{ <Semi::Literate::one-line-no-weave> }
                    = "$<Semi::Literate::one-line-no-weave><the-code>\n";

=begin pod
=head3 remove blank lines at the end

=end pod
    # remove blank lines at the end
    $raku-code ~~ s{\n  <blank-line>* $ } = '';

=begin pod

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
=head2 The parameters of Weave

C<sub weave> will have several parameters.
=head3 C<$input-file>

The input filename is required. Typically,
this parameter is obtained from the command line through a wrapper subroutine
C<MAIN>.

=end pod

    Str $input-file!;
=begin pod
=head3 C<$line-numbers>

It can be useful to print line numbers in the code listing.  It currently
defaults to True.
=end pod

    Bool :l(:$line-numbers) = True;
        #= Should line numbers be added to the embeded code?

=begin pod
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

=head2 Interesting stuff

...Next, we parse it using the C<Semi::Literate> grammar
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse(clean $source).caps;

=begin pod

...And now begins the interesting part.  We iterate through the submatches and
insert the C<code> sections into the Pod6...
=end pod


=begin pod
This function checks if the line of code is a full line comment. If so,
return False, so nothing will be printed for this line.

If it's a line of code with a comment at the end, remove the comment from the
line and return True

Otherwise return True
=end pod

    sub remove-comments (Seq $lines --> Seq) {
        #TODO Add a parameter to sub weave()
        #TODO Explain Seq

        my token full-line-comment {
            (<leading-ws>)
            '#'
            <rest-of-line>
        } # end of my token full-line-comment

        #TODO this regex is not robust.
        # If the '#' is in a quoted string, it will be removed.
        # Unless the string delimiter is immediately before the '#'
        my regex partial-line-comment {
            $<the-code>=(<leading-ws> <required-chars>)
            <!after <opening-quote>>
            '#'
            $<the-comment>=<-[#]>*
            <ws-till-EOL>
        } # end of my regex comment

        state Bool $at-start = True;
        my @retval = ();
        for $lines.List -> $line {
            given $line {
                when /<blank-line>/ {
                    @retval.push($line)
                    # If we're at the start of the file,
                    # don't push blank lines to the retval.
                        unless $at-start;
                }

                # don't print full line comments
                when /<full-line-comment>/ {#`[[do nothing]] }

                # remove comments that are at the end of a line.
                when /<partial-line-comment>/ {
                    @retval.push: $<partial-line-comment><the-code>;
                }

                default { @retval.push: $line; }
            } # end of given $line
        } # end of for $lines -> $line

        # After the first time through,
        # we're no longer at the start of the file.
        $at-start = False;
        return @retval.Seq;
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
             }
            \=end code
            \=end pod
            EOCB
        } # end of when .key eq 'code'

        # begin-no-weave
        default {
            die "Weave: should never get here. .key == {.key}" }
        # end-no-weave
    } # end of my Str $weave = @submatches.map(
    ).join;

=begin pod
=head3 Remove unseemly blank lines

#TODO Explain this regexes
=end pod

    # The code below will occur wherever non-woven appeared.
    # We need to remove it from the woven Pod6.  Otherwise, it
    # creates an unseemly blank line.
    my Str $non-woven-blank-lines = qq:to/EOQ/;
        \=end code
        \=end pod
        \=begin pod
        \=begin code :lang<raku>
        EOQ

    $weave ~~ s:g{ $non-woven-blank-lines } = '';

=begin pod

And that's the end of the C<weave> subroutine!
=end pod

    spurt "deleteme.rakudoc", $weave if $verbose; # no-weave-this-line
    return $weave
} # end of sub weave (

=begin pod
=comment 2
=head1 Clean the source code of unneccessary blank lines
=end pod

sub clean (Str $source is copy --> Str) {

=begin pod
=head2 Remove blank lines at the begining and end of the code

Very often the C<code> section of the Semi-Literate file will have blank lines
that you don't want to see in the tangled working code.
For example:

=begin code :lang<raku>

    ...
    \=end pod
                                                # <== unwanted blank line
                                                # <== unwanted blank line
    sub foo () {
        { ... }
    } # end of sub foo ()
                                                # <== unwanted blank line
                                                # <== unwanted blank line
                                                # <== unwanted blank line
    \=begin pod
    ...
=end code
=end pod

    $source ~~ s:g{    \=end (\N*) \n+}      =  "\=end$0\n";
    $source ~~ s:g{\n+ \=begin (<hws> pod) } = "\n\=begin$0";

=begin pod
=head2 Remove blank lines at the end of the code.

=end pod
    # remove blank lines at the end
    $source ~~ s{\n  <blank-line>* $ } = '';

    return $source;
} # end of sub clean-source (Str $source)

=begin pod
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

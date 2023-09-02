#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Fri 01 Sep 2023 09:59:29 PM EDT
# Version 0.0.1

# no-weave
# always use the latest version of Raku
use v6.*;
use PrettyDump;
use Data::Dump::Tree;
# end-no-weave

=begin pod


=TITLE A grammar to parse a file into C<Pod> and C<Code> sections.

=head1 INTRODUCTION

I want to create a semi-literate Raku source file with the extension
C<.sl>. Then, I will I<weave> it to generate a readable file in formats like
Markdown, PDF, HTML, and more. Additionally, I will I<tangle> it to create source
code without any Pod6.

To do this, I need to divide the file into C<Pod> and C<Code> sections by parsing
it. For this purpose, I will create a dedicated Grammar.


=head2 Convenient tokens

Let's create two tokens for convenience.

=end pod

#    We need to declare them with C<my> because we
#    need to use them in a subroutine later. #TODO explain why.

    my token rest-of-line {    \N* [\n | $] }
    my token blank-line   { ^^ \h* [\n | $] }

=begin pod
=head1 The Grammar

Our file will exclusively consist of C<Pod> or C<Code> sections, and nothing
else. The C<TOP> token clearly indicates this.

=end pod

#use Grammar::Tracer;
grammar Semi::Literate is export {
    token TOP {   [ <pod> | <code> ]* }


=begin pod

=head2 The Pod6 delimiters

According to the L<documentation|https://docs.raku.org/language/pod>,

=begin defn

    Every Pod6 document has to begin with =begin pod and end with =end pod.

=end defn

So let's define those tokens.
=head3 The C<begin> token

=end pod

    my token begin {
        ^^ \h* \= begin <.ws> pod

=begin pod

Most programming applications do not focus on the structure of the executable
file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty
lines that should replace a C<pod> block. To do this, simply add a number at
the end of the C<=begin> directive. For example, C<=begin  pod 2> .

=end pod

        [ \h* $<num-blank-lines>=(\d+) ]?  # an optional number to specify the
                                         # number of blank lines to replace the
                                         # C<Pod> blocks when tangling.
=begin pod
The remainder of the C<begin> directive can only be whitespace.
=end pod

        <rest-of-line>
    } # end of my token begin

=begin pod

=head3 The C<end> token

The C<end> token is much simpler.

=end pod

    my token end { ^^ \h* \= end <.ws> pod <rest-of-line> }

=begin pod 1

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
        <begin>
            [<pod> | <plain-line>]*
        <end>
    } # end of token pod

=begin pod 1

=head2 The C<Code> token

The C<Code> sections are trivially defined.  They are just one or more
C<plain-line>s.

=end pod

    token code { <plain-line>+ }

=begin pod 1

=head3 The C<plain-line> token

The C<plain-line> token is, really, any line at all...

=end pod

    token plain-line {
       $<plain-line> = [^^ <rest-of-line>]

=begin pod

=head3 Disallowing the delimiters in a C<plain-line>.

... except for one subtlety.  They it can't be one of the begin/end delimiters.
We can specify that with a L<Regex Boolean Condition
Check|https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check>.

=end pod

        <?{ &not-a-delimiter($<plain-line>.Str) }>
    } # end of token plain-line

=begin pod 1

This function simply checks whether the C<plain-line> match object matches
either the C<<begin>> or C<<end>> token.

Incidentally, this function is why we had to declare those tokens with the
C<my> keyword.  This function wouldn't work otherwise.

=end pod

    sub not-a-delimiter (Str $line --> Bool) {
        return not $line ~~ /<begin> | <end>/;
    } # end of sub not-a-delimiter (Match $line --> Bool)

=begin pod

And that concludes the grammar for separating C<Pod> from C<Code>!

=end pod

} # end of grammar Semi::Literate

=begin pod 2

=head1 The Tangle subroutine

This subroutine will remove all the Pod6 code from a semi-literate file
(C<.sl>) and keep only the Raku code.


=end pod

#TODO multi sub to accept Str & IO::PatGh
sub tangle (

=begin pod

The subroutine has a single parameter, which is the input filename. The
filename is required.  Typically, this parameter is obtained from the command
line or passed from the subroutine C<MAIN>.
=end pod
    Str $input-file!,
=begin pod

The subroutine will return a C<Str>, which will be a working Raku program.
=end pod
        --> Str ) is export {
=begin pod

First we will get the entire Semi-Literate C<.sl> file...
=end pod

    my Str $source = $input-file.IO.slurp;

=begin pod 1
Remove the I<no-weave> delimiters
=end pod

    $source ~~ s:g{ ^^ \h* '#' <.ws>     'no-weave' <rest-of-line> } = '';
    $source ~~ s:g{ ^^ \h* '#' <.ws> 'end-no-weave' <rest-of-line> } = '';

=begin pod 1

Very often the C<code> section of the Semi-Literate file will have blank lines
that you don't want to see in the tangled working code.
For example:

=end pod
                                                # <== unwanted blank lines
                                                # <== unwanted blank lines
    sub foo () {
        { ... }
    } # end of sub foo ()
                                                # <== unwanted blank lines
                                                # <== unwanted blank lines
=begin pod


So we'll remove the blank lines at the beginning and end of the code sections.
=end pod

    $source ~~ s:g/\=end (\N*)\n+/\=end$0\n/;
    $source ~~ s:g/\n+\=begin    /\n\=begin/;

=begin pod 1

...Next, we parse it using the C<Semi::Literate> grammar
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse($source).caps;

=begin pod 1

...And now begins the interesting part.  We iterate through the submatches and
keep only the C<code> sections...
=end pod

    my Str $raku-code = @submatches.map( {
        when .key eq 'code' {
            .value;
        }

=begin pod 1
        #TODO rewrite
Most programming applications do not focus on the structure of the
executable file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty
lines that should replace a C<pod> block. To do this, simply add a number
at the end of the C<=begin> directive. For example, C<=begin  pod 2> .
=end pod


        when .key eq 'pod' {
            my $num-blank-lines = .value.hash<begin><num-blank-lines>;
            with $num-blank-lines { "\n" x $num-blank-lines }
        }

=begin pod 1
#TODO
=end pod
        #no-weave
        default { die 'Should never get here' }
        #end-no-weave
=begin pod

... and we will join all the code sections together...
=end pod

    } # end of my Str $raku-code = @submatches.map(
    ).join;

=begin pod 1
=head3 remove blank lines at the end

=end pod

    $raku-code ~~ s{\n  <blank-line>* $ } = '';

=begin pod

And that's the end of the C<tangle> subroutine!
=end pod
    return $raku-code;
} # end of sub tangle (

=begin pod 2

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
=head3 C<$format>

The output of the weave can (currently) be Markdown, Text, or HTML.  It
defaults to Markdown. The variable is case-insensitive, so 'markdown' also
works.
=end pod

    Str :f(:$format) is copy = 'markdown';
        #= The output format for the woven file.

=begin pod
=head3 C<$line-numbers>

It can be useful to print line numbers in the code listing.  It currently
defaults to True.
=end pod

    Bool :l(:$line-numbers)  = True;
        #= Should line numbers be added to the embeded code?


=begin pod
C<sub weave> returns a Str.
=end pod

        --> Str ) is export {
=begin pod
#TODO
=end pod

    my UInt $line-number = 1;

=begin pod
First we will get the entire C<.sl> file...
=end pod

    my Str $source = $input-file.IO.slurp;

    my Str $cleaned-source;

=begin pod 1
=head2 Clean the source of items we don't want to see in the formatted document.

=head3 Remove code marked as 'no-weave'

Sometimes there will be code you do not want woven into the document, such
as boilerplate code like C<use v6.d;>.  You have two options to mark such
code.  By individual lines or by delimited blocks of code.

=head4 Delimited blocks of code

Simply add comments before and after the code you want ignored in the
formatted document.

=begin code :lang<raku>
#no-weave
    {...
    ...}
#end-no-weave

=end code

=end pod
#
#    $source ~~ s:g{^^ \h* '#'  <.ws> 'no-weave'     <rest-of-line>
#
#                    (^^ <rest-of-line> )*?  # all lines between the two weave delimiters
#
#                   ^^ \h* '#' <.ws> 'end-no-weave' <rest-of-line>
#                  } = '';
#
#
#=begin pod 1
#
#=head4 Individual lines of code
#
#    Add a comment at the end of the line of code.
#=begin code :lang<raku>
#use v6.d;  #no-weave
#=end code
#
#
#=end pod
#    $source ~~ s:g {
#        ^^ \h* .* '#' <.ws> 'no-weave' \h* $$
#    } = ''; # end of $source ~~ s:g {
#
=begin pod

=head3 Remove full comment lines followed by blank lines

=end pod

    # delete full comment lines
    $source ~~ s:g{ ^^ \h* '#' \N* \n+} = '';

    # remove Raku comments, unless the '#' is escaped with
    # a backslash or is in a quote. (It doesn't catch all quote
    # constructs...(that's a TODO))
    # And leave the newline.

=begin pod 1

=head3 Remove EOL comments

=end pod

    for $source.split("\n") -> $line {
        my $m = $line ~~ m{
                ^^
               $<stuff-before-the-comment> = ( \N*? )

                #TODO make this more robust - allow other delimiters, take into
                #account the Q language, heredocs, nested strings...
                <!after         # make sure the '#' isn't in a string
                    ( [
                        | \\
                        | \" <-[\"]>*
                        | \' <-[\']>*
                        | \｢ <-[\｣]>*
                    ] )
                >
                "#"


                # We need to keep these delimiters.
                # See the section above "Remove code marked as 'no-weave'".
                <!before
                      [
                        | 'no-weave'
                        | 'end-no-weave'
                      ]
                >
                \N*
                $$ };

        $cleaned-source ~= $m ?? $<stuff-before-the-comment> !! $line;
        $cleaned-source ~= "\n";
    } # end of for $source.split("\n") -> $line

=begin pod 1
=head3 Remove blank lines at the begining and end of the code

=end pod

    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
    $cleaned-source ~~ s:g{\n+\=begin (<.ws> pod) [<.ws> \d]?} = "\n\=begin$0";

=begin pod 1

...Next, we parse it using the C<Semi::Literate> grammar
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

#    print $cleaned-source;
#    exit;


    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

=begin pod 1

...And now begins the interesting part.  We iterate through the submatches and
insert the C<code> sections into the Pod6...
=end pod


    my Str $weave = @submatches.map( {
        when .key eq 'pod' {
            .value
        } # end of when .key
=begin pod 1
#TODO
=end pod

        when .key eq 'code' { qq:to/EOCB/; }
            \=begin  pod
            \=begin  code :lang<raku>
             { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
                .value
                .lines
                .map($line-numbers
                        ?? {"%4s| %s\n".sprintf($line-number++, $_) }
                        !! {     "%s\n".sprintf(                $_) }
                    )
                .chomp;
             }
            \=end  code
            \=end  pod
            EOCB

        # no-weave
        default { die 'Should never get here.' }
        # end-no-weave
    } # end of my $weave = Semi::Literate.parse($source).caps.map
    ).join;

=begin pod 1
remove useless Pod directives
=end pod

    $weave ~~ s:g{ \h* \=end   <.ws> pod  <rest-of-line>
                   \h* \=begin <.ws> pod <rest-of-line> } = '';

=begin pod 1
=head3 remove blank lines at the end

=end pod

    $weave ~~ s{\n  <blank-line>* $ } = '';

=begin pod 1

And that's the end of the C<tangle> subroutine!
=end pod

    return $weave
} # end of sub weave (

=begin pod 2

=head1 NAME

C<Semi::Literate> - Get the Pod vs Code structure from a Raku/Pod6 file.

=head1 VERSION

This documentation refers to C<Semi-Literate> version 0.0.1

=head1 SYNOPSIS

    use Semi::Literate;
    # Brief but working code example(s) here showing the most common usage(s)

    # This section will be as far as many users bother reading
    # so make it as educational and exemplary as possible.

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head2, etc.)

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Patches are welcome.

=head1 AUTHOR

Shimon Bollinger  (deoac.bollinger@gmail.com)

=head1 LICENSE AND COPYRIGHT

© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Raku itself.
See L<The Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=end pod

# no-weave
my %*SUB-MAIN-OPTS =
  :named-anywhere,             # allow named variables at any location
  :bundling,                   # allow bundling of named arguments
#  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  :allow-no,                   # allow --no-foo as alternative to --/foo
  :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
;

#| Run with option '--pod' to see all of the POD6 objects
multi MAIN(Bool :$pod!) is hidden-from-USAGE {
    for $=pod -> $pod-item {
        for $pod-item.contents -> $pod-block {
            $pod-block.raku.say;
        }
    }
} # end of multi MAIN (:$pod)

#| Run with option '--doc' to generate a document from the POD6
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

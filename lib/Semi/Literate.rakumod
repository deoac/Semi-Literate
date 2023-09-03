#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sat 02 Sep 2023 11:19:41 PM EDT
# Version 0.0.1

# no-weave
# always use the latest version of Raku
use v6.*;
use PrettyDump;
use Data::Dump::Tree;
# end-no-weave

#    We need to declare them with C<my> because we
#    need to use them in a subroutine later. #TODO explain why.

    my token rest-of-line {    \N* [\n | $]  }
    my token ws-till-EOL  {    \h* [\n | $]  }
    my token blank-line   { ^^ <ws-till-EOL> }

#use Grammar::Tracer;
grammar Semi::Literate is export {
    token TOP {   [ <pod> | <code> ]* }

    my token begin {
        ^^ \h* \= begin <.ws> pod

        [ \h* $<num-blank-lines>=(\d+) ]?  # an optional number to specify the
                                         # number of blank lines to replace the
                                         # C<Pod> blocks when tangling.

        <ws-till-EOL>
    } # end of my token begin

    my token end { ^^ \h* \= end <.ws> pod <ws-till-EOL> }

    token pod {
        <begin>
            [<pod> | <plain-line>]*
        <end>
    } # end of token pod

    token code {
        | <woven>
        | <non-woven>
    } # end of token code

    token woven { <plain-line>+ }

    token non-woven {
        | <one-line-no-weave>+
        | <delimited-no-weave>+
    } # end of token non-woven

    token one-line-no-weave {
        ^^ \N*
        '#' <.ws> 'no-weave'
        <.ws> <rest-of-line>
    } # end of token one-line-no-weave

    token delimited-no-weave {
        <begin-no-weave>
            <plain-line>*?
        <end-no-weave>
    } # end of token delimited-no-weave

    token begin-no-weave {
        ^^ \h*                      # optional leading whitespace
        '#' <.ws> 'no-weave'        # the delimiter itself (#no-weave)
        <.ws> <rest-of-line>        # optional trailing whitespace
    } # end of token <begin-no-weave>

    token end-no-weave {
        ^^ \h*                      # optional leading whitespace
        '#' <.ws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
        <.ws> <rest-of-line>        # optional trailing whitespace
    } # end of token <end--no-weave>

    token plain-line {
       $<plain-line> = [^^ <rest-of-line>]

        <?{ &not-a-delimiter($<plain-line>.Str) }>
    } # end of token plain-line

    sub not-a-delimiter (Str $line --> Bool) {
        return not $line ~~ /<begin> | <end>/;
    } # end of sub not-a-delimiter (Match $line --> Bool)

} # end of grammar Semi::Literate

#TODO multi sub to accept Str & IO::PatGh
sub tangle (

    Str $input-file!,

        --> Str ) is export {

    my Str $source = $input-file.IO.slurp;

    $source ~~ s:g{ ^^ \h* '#' <.ws>     'no-weave' <rest-of-line> } = '';
    $source ~~ s:g{ ^^ \h* '#' <.ws> 'end-no-weave' <rest-of-line> } = '';

    $source ~~ s:g/\=end (\N*)\n+/\=end$0\n/;
    $source ~~ s:g/\n+\=begin    /\n\=begin/;

    my Pair @submatches = Semi::Literate.parse($source).caps;

    my Str $raku-code = @submatches.map( {
        when .key eq 'code' {
            .value;
        }

        when .key eq 'pod' {
            my $num-blank-lines = .value.hash<begin><num-blank-lines>;
            "\n" x $num-blank-lines with $num-blank-lines;
        }

        #no-weave
        default { die 'Should never get here' }
        #end-no-weave

    } # end of my Str $raku-code = @submatches.map(
    ).join;

    $raku-code ~~ s{\n  <blank-line>* $ } = '';

    return $raku-code;
} # end of sub tangle (

sub weave (

    Str $input-file!;

    Str :f(:$format) is copy = 'markdown';
        #= The output format for the woven file.

    Bool :l(:$line-numbers)  = True;
        #= Should line numbers be added to the embeded code?

        --> Str ) is export {

    my UInt $line-number = 1;

    my Str $source = $input-file.IO.slurp;

    my Str $cleaned-source;

$cleaned-source = $source;
#=begin pod 1
#
#=head3 Remove full comment lines followed by blank lines
#
#=end pod
#
#    # delete full comment lines
#    $source ~~ s:g{ ^^ \h* '#' \N* \n+} = '';
#
#    # remove Raku comments, unless the '#' is escaped with
#    # a backslash or is in a quote. (It doesn't catch all quote
#    # constructs...(that's a TODO))
#    # And leave the newline.
#
#=begin pod 1
#
#=head3 Remove EOL comments
#
#=end pod
#
#    for $source.split("\n") -> $line {
#        my $m = $line ~~ m{
#                ^^
#               $<stuff-before-the-comment> = ( \N*? )
#
#                #TODO make this more robust - allow other delimiters, take into
#                #account the Q language, heredocs, nested strings...
#                <!after         # make sure the '#' isn't in a string
#                    ( [
#                        | \\
#                        | \" <-[\"]>*
#                        | \' <-[\']>*
#                        | \｢ <-[\｣]>*
#                    ] )
#                >
#                "#"
#
#
#                # We need to keep these delimiters.
#                # See the section above "Remove code marked as 'no-weave'".
#                <!before
#                      [
#                        | 'no-weave'
#                        | 'end-no-weave'
#                      ]
#                >
#                \N*
#                $$ };
#
#        $cleaned-source ~= $m ?? $<stuff-before-the-comment> !! $line;
#        $cleaned-source ~= "\n";
#    } # end of for $source.split("\n") -> $line
#
#=begin pod 1
#=head3 Remove blank lines at the begining and end of the code
#
#B<EXPLAIN THIS!>
#
#=end pod
#
#    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
#    $cleaned-source ~~ s:g{\n+\=begin (<.ws> pod) [<.ws> \d]?} = "\n\=begin$0";
#

    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

    my Str $weave = @submatches.map( {
        when .key eq 'pod' {
            .value
        } # end of when .key

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

        when .key eq 'non-woven' {
            ; # do nothing
        } # end of when .key eq 'non-woven'

        # no-weave
        default { die 'Should never get here.' }
        # end-no-weave
    } # end of my $weave = Semi::Literate.parse($source).caps.map
    ).join;

    $weave ~~ s:g{ \h* \=end   <.ws> pod  <rest-of-line>
                   \h* \=begin <.ws> pod <rest-of-line> } = '';

    $weave ~~ s{\n  <blank-line>* $ } = '';

    return $weave
} # end of sub weave (

# no-weave
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

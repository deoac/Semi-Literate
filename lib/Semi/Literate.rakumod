#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sun 10 Sep 2023 02:29:50 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;
use PrettyDump;
use Data::Dump::Tree;
#TODO Put these into a Role
    my token hws            {    <!ww>\h*       } # Horizontal White Space
    my token leading-ws     { ^^ <hws>          } # Whitespace at start of line
    my token optional-chars {    \N*?           }
    my token rest-of-line   {    \N*   [\n | $] } #no-weave-this-line
    my token ws-till-EOL    {    <hws> [\n | $] } #no-weave-this-line
    my token blank-line     { ^^ <ws-till-EOL>  } #no-weave-this-line
#use Grammar::Tracer;
grammar Semi::Literate is export {
    token TOP {
        [
          || <pod>
          || <woven-code>
          || <non-woven-code>
        ]*
    } # end of token TOP
    token begin-pod {
        <leading-ws>
        '=' begin <hws> pod
        <ws-till-EOL>
    } # end of token begin-pod
    token end-pod { <leading-ws> '=' end <hws> pod <ws-till-EOL> }
    token num-blank-line-comment {
        <leading-ws>
        '=' comment
        <optional-chars>
        $<num-blank-lines> = (\d+)?
        <ws-till-EOL>
    } # end of token num-blank-line-comment
    token pod {
        <begin-pod>
        <num-blank-line-comment>?
            [<pod> || <plain-line>]*
        <end-pod>
    } # end of token pod
    token woven-code  {
        [
#            || <comment> { note $/.Str }
            || <plain-line>
        ]+
    } # end of token woven-code
    token non-woven-code {
        [
          || <one-line-no-weave>
          || <delimited-no-weave>
        ]+
    } # end of token non-woven
    token one-line-no-weave {
        ^^ \N*?
        '#' <hws> 'no-weave-this-line'
        <ws-till-EOL>
    } # end of token one-line-no-weave
    token begin-no-weave {
        <leading-ws>                    # optional leading whitespace
        '#' <hws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
        <ws-till-EOL>               # optional trailing whitespace or comment
    } # end of token <begin-no-weave>

    token end-no-weave {
        <leading-ws>                    # optional leading whitespace
        '#' <hws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
        <ws-till-EOL>               # optional trailing whitespace or comment
    } # end of token <end--no-weave>

    token delimited-no-weave {
        <begin-no-weave>
            <plain-line>*
        <end-no-weave>
    } # end of token delimited-no-weave

    token code-comments {
            <leading-ws>
            '#' <rest-of-line>
        <!{ / <begin-no-weave> | <end-no-weave> / }>
    } # end of token code-comments
    token plain-line {
        :my $*EXCEPTION = False;
        [
          ||  <begin-pod>         { $*EXCEPTION = True }
          ||  <end-pod>           { $*EXCEPTION = True }
          ||  <begin-no-weave>    { $*EXCEPTION = True }
          ||  <end-no-weave>      { $*EXCEPTION = True }
          ||  <one-line-no-weave> { $*EXCEPTION = True }
          || $<plain-line> = [^^ <rest-of-line>]
        ]
        <?{ !$*EXCEPTION }>
    } # end of token plain-line
} # end of grammar Semi::Literate
#TODO multi sub to accept Str & IO::PatGh
sub tangle (
    Str $input-file!,
        --> Str ) is export {
    my Str $source = $input-file.IO.slurp;
    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
    $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";
    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;
#    note "submatches.elems: {@submatches.elems}";
    my Str $raku-code = @submatches.map( {
#        note .key;
        when .key eq 'woven-code'|'non-woven-code' {
            .value;
        }
        when .key eq 'pod' {
            my $num-blank-lines =
                .value.hash<num-blank-line-comment><num-blank-lines>;
            "\n" x $num-blank-lines with $num-blank-lines;
        }

        default { die "Tangle: should never get here. .key == {.key}" }
    } # end of my Str $raku-code = @submatches.map(
    ).join;
    $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'begin-no-weave'     <rest-of-line> }
        = '';
    $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'no-weave-this-line' <rest-of-line> }
        = "$0\n";
    $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'end-no-weave'       <rest-of-line> }
        = '';
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
    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
    $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";
    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;
#    note "weave submatches.elems: {@submatches.elems}";
#    note "submatches keys: {@submatches».keys}";
    my Str $weave = @submatches.map( {
        when .key eq 'pod' {
            .value
        } # end of when .key

        when .key eq 'woven-code' {qq:to/EOCB/; }
            \=begin pod
            \=begin code :lang<raku>
             { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
                .value
                .lines
                .map($line-numbers
                        ?? {"%4s| %s\n".sprintf($line-number++, $_) }
                        !! {     "%s\n".sprintf(                $_) }
                    )
                .chomp # get rid of the last \n
             }
            \=end code
            \=end pod
            EOCB

        when .key eq 'non-woven-code' {
          ''; # do nothing
          #TODO don't insert a newline here.
        } # end of when .key eq 'non-woven-code'

        default {
            die "Weave: should never get here. .key == {.key}" }
    } # end of my Str $weave = @submatches.map(
    ).join;
    $weave ~~ s{\n  <blank-line>* $ } = '';
    return $weave
} # end of sub weave (
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
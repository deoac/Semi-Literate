#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Tue 19 Sep 2023 11:11:14 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;
use Useful::Regexes;

use PrettyDump;
use Data::Dump::Tree;

#use Grammar::Tracer;
grammar Semi::Literate is export does Useful::Regexes {

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

    token begin-pod {
        <leading-ws>
        '=' begin <hws> pod
        <ws-till-EOL>
    } # end of token begin-pod

    token end-pod  {
        <leading-ws>
        '=' end <hws> pod
        <ws-till-EOL>
    } # end of token end-pod

    token blank-line-comment {
        <leading-ws>
        '=' comment
        \N*?
        $<num-blank-lines> = (\d+)?
        <ws-till-EOL>
    } # end of token blank-line-comment

    token pod {
        <.begin-pod>
        <blank-line-comment>?
            [<pod> | <.plain-line>]*
        <.end-pod>
    } # end of token pod

    token woven  {
        [
            || <.plain-line>
        ]+
    } # end of token woven

    token non-woven {
        [
          || <.one-line-no-weave>
          || <.delimited-no-weave>
        ]+
    } # end of token non-woven

    regex one-line-no-weave {
        $<the-code>=(<leading-ws> <optional-chars>)
        '#' <hws> 'no-weave-this-line'
        <ws-till-EOL>
    } # end of token one-line-no-weave

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

} # end of grammar Semi::Literate


multi tangle (Str $input-file!) is export {
    # get the filehandle of the input file and call the other multi tangle()
    samewith $input-file.IO;
} # end of multi tangle () is export

multi tangle (

    IO::Path $input-file!,

        --> Str ) is export {

    my Str $source = $input-file.slurp;

    my Pair @submatches = Semi::Literate.parse(clean $source).caps;

#    note "submatches.elems: {@submatches.elems}";
    my Str $raku-code = @submatches.map( {

        when .key eq 'pod' {
            my $num-blank-lines =
                .value.hash<blank-line-comment><num-blank-lines>;
            "\n" x ($num-blank-lines // 1); #with $num-blank-lines;
        }

        when .key eq 'code' {
            .value;
        } # end of when .key eq 'code'

        default { die "Tangle: should never get here.
                    .key ==> {.key} .{.key}.keys => {.{.key}.keys}";
        } # end of default

    } # end of my Str $raku-code = @submatches.map(
    ).join;

    $raku-code ~~ s:g{
                        | <Semi::Literate::begin-no-weave>
                        | <Semi::Literate::end-no-weave>
                  } = '';

    $raku-code ~~ s:g{ <Semi::Literate::one-line-no-weave> }
                    = "$<Semi::Literate::one-line-no-weave><the-code>\n";

    # remove blank lines at the end
    $raku-code ~~ s{\n  <blank-line>* $ } = '';

    return $raku-code;
} # end of sub tangle (


sub weave (

    Str $input-file!;

    Bool :l(:$line-numbers) = True;
        #= Should line numbers be added to the embeded code?

    Bool :v(:$verbose)      = False;

        --> Str ) is export {

    my UInt $line-number = 1;

    my Str $source = $input-file.IO.slurp;

    my Pair @submatches = Semi::Literate.parse(clean $source).caps;


    sub remove-comments (Seq $lines --> Seq) {
        #TODO Add a parameter to sub weave()
        #TODO Explain Seq

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
                ==> chomp() # get rid of the last \n
             }
            \=end code
            \=end pod
            EOCB
        } # end of when .key eq 'code'

        default { die "Weave: should never get here.
                    .key ==> {.key} .{.key}.keys => {.{.key}.keys}";
        } # end of default
    } # end of my Str $weave = @submatches.map(
    ).join;

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

    "deleteme.rakudoc".IO.spurt($weave) if $verbose; 
    return $weave
} # end of sub weave (


sub clean (Str $source is copy --> Str) {

    $source ~~ s:g{    \=end (\N*) \n+}      =  "\=end$0\n";
    $source ~~ s:g{\n+ \=begin (<hws> pod) } = "\n\=begin$0";

    # remove blank lines at the end
    $source ~~ s{\n  <blank-line>* $ } = '';

    return $source;
} # end of sub clean-source (Str $source)

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
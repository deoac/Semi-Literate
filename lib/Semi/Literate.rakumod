#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Tue 12 Sep 2023 01:38:58 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;
use PrettyDump;
use Data::Dump::Tree;

    #TODO put these in a Role
    my token hws            {    <!ww>\h*       } # Horizontal White Space
    my token leading-ws     { ^^ <hws>          } # Whitespace at start of line
    my regex optional-chars {    \N*?           }
    # deleteme
    my token rest-of-line   {    \N*   [\n | $] }
    my token ws-till-EOL    {    <hws> [\n | $] } #no-weave-this-line
    my token blank-line     { ^^ <ws-till-EOL>  }
    my token opening-quote  { <
                               :Ps +      # Unicode Open_Punctuation
                               :Pi +      # Unicode Initial_Punctuation
                               [\' \" \\]
                              >
                    # test comment
    } # end of my token opening-quote
#use Grammar::Tracer;
grammar Semi::Literate is export {
    token TOP {
        [
          || <pod>
          || <non-woven-code>
          || <woven-code>
        ]*
    } # end of token TOP

    token begin-pod {
        ^^ <hws> '=' begin <hws> pod <ws-till-EOL>
    } # end of token begin-pod

    token end-pod { ^^ <hws> '=' end <hws> pod <ws-till-EOL> }

    token blank-line-comment {
        ^^ <hws>
        '=' comment
        \N*?
        $<num-blank-lines> = (\d+)?
        <ws-till-EOL>
    } # end of token blank-line-comment

    token pod {
        <begin-pod>
        <blank-line-comment>?
            [<pod> | <plain-line>]*
        <end-pod>
    } # end of token pod

    token woven-code  {
        [
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
        ^^ <hws>                    # optional leading whitespace
        '#' <hws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
        <ws-till-EOL>               # optional trailing whitespace or comment
    } # end of token <begin-no-weave>

    token end-no-weave {
        ^^ <hws>                    # optional leading whitespace
        '#' <hws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
        <ws-till-EOL>               # optional trailing whitespace or comment
    } # end of token <end--no-weave>

    token delimited-no-weave {
        <begin-no-weave>
            <plain-line>*
        <end-no-weave>
    } # end of token delimited-no-weave

    my token full-line-comment {
        $<the-code>=(<leading-ws>)
        '#'
        <rest-of-line>
    } # end of my token full-line-comment

    #TODO this regex is not robust.  It will tag lines with a # in a string,
    #unless the string delimiter is immediately before the #
    my regex code-comment {
        $<the-code>=(<leading-ws> \N*?)  # optional code
        <!after <opening-quote>>         #
        '#'                              # comment marker
        $<the-comment>=<-[#]>*           # the actual comment
        <ws-till-EOL>
    } # end of my regex comment

    token plain-line {
        :my $*EXCEPTION = False;
        [
          ||  <begin-pod>         { $*EXCEPTION = True }
          ||  <end-pod>           { $*EXCEPTION = True }
          ||  <begin-no-weave>    { $*EXCEPTION = True }
          ||  <end-no-weave>      { $*EXCEPTION = True }
          ||  <one-line-no-weave> { $*EXCEPTION = True }
          || [^^ <rest-of-line>]
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
                .value.hash<blank-line-comment><num-blank-lines>;
            "\n" x $num-blank-lines with $num-blank-lines;
        }

        default { die "Tangle: should never get here. .key == {.key}" }

    } # end of my Str $raku-code = @submatches.map(
    ).join;

    $raku-code ~~ s:g{ ^^ <hws> '#' <hws> 'begin-no-weave'     <rest-of-line> }
        = '';
    $raku-code ~~ s:g{ ^^ <hws> '#' <hws> 'no-weave-this-line' <rest-of-line> }
        = "$0\n";
    $raku-code ~~ s:g{ ^^ <hws> '#' <hws> 'end-no-weave'       <rest-of-line> }
        = '';

    $raku-code ~~ s{\n  <blank-line>* $ } = '';

    return $raku-code;
} # end of sub tangle (


sub weave (

    Str $input-file!;

    Bool :l(:$line-numbers)  = True;
        #= Should line numbers be added to the embeded code?
        --> Str ) is export {

    my UInt $line-number = 1;
    my Str $source = $input-file.IO.slurp;

    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
    $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";

    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

    sub remove-comments (Seq $lines --> Seq) {
        #TODO Add a parameter to sub weave()
    #        return !{my $remove-comments = False};

#        note "Seq has {$lines.elems} lines";

        my @retval = ();
        for $lines.List -> $line {
            given $line {
#            note "» $line: {so $line ~~ /<leading-ws> '#'/}";
                # don't print full line comments
                when /<leading-ws> '#'/
                    {; #`[[do nothing]] }

                # remove comments that are at the end of a line.
                # The code will almost always end with a ';' or a '}'.
                when / (^^ <optional-chars> [\; | \}]) <hws> '#'/
                    {#`[[note ">> ending comment ($0)";]] @retval.push: $0}

                default
                    {#`[[note ">> normal line";]] @retval.push: $line}
            } # end of given $line
#            note "---> ", @retval.join("\n\t");
        } # end of for $lines -> $line


#        note "» Returning: ", @retval.join("\n\t"), "\n";
        return @retval.Seq;
    } # end of sub remove-comments {Pair $p is rw}

    # The code below will occur wherever non-woven-code appeared.
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

#    note "weave submatches.elems: {@submatches.elems}";
#    note "submatches keys: {@submatches».keys}";
    my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";

    my Str $weave = @submatches.map( {
        when .key eq 'pod' {
            .value
        } # end of when .key

        #TODO refactor that line out of this code
        when .key eq 'woven-code' { qq:to/EOCB/; }
            \=begin pod
            \=begin code :lang<raku>
             {
                .value
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

        when .key eq 'non-woven-code' {
            ''; # don't add any text to the Pod6
        } # end of when .key eq 'non-woven-code'

        default { die "Weave: should never get here. .key == {.key}" }
    } # end of my Str $weave = @submatches.map(
    ).join;

    $weave ~~ s:g{ $non-woven-blank-lines | <$full-comment-blank-lines> } = '';

    $weave ~~ s{\n  <blank-line>* $ } = '';

    "deleteme.rakudoc".IO.spurt: $weave;
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
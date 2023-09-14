# B---
# always use the latest version of Raku
use v6.*;
use Useful::Regexes;

use PrettyDump;
use Data::Dump::Tree;
# E---
# B---
#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Wed 13 Sep 2023 08:30:28 PM EDT
# Version 0.0.1

# E---

# B---
#use Grammar::Tracer;
grammar Semi::Literate is export does Useful::Regexes {
# E---
# B---
    token TOP {
        [
          || <pod>
          || <code>
        ]*
    } # end of token TOP

    token code  {
        [
          || <non-woven>
          || <woven>
        ]+
    } # end of token code
# E---

# B---
    token begin-pod {
        <leading-ws>
        '=' begin <hws> pod
        <ws-till-EOL>
    } # end of token begin-pod
# E---

# B---
    token end-pod  {
        <leading-ws>
        '=' end <hws> pod
        <ws-till-EOL>
    } # end of token end-pod
# E---

# B---
    token blank-line-comment {
        <leading-ws>
        '=' comment
        \N*?
        $<num-blank-lines> = (\d+)?
        <ws-till-EOL>
    } # end of token blank-line-comment
# E---

# B---
    token pod {
        <begin-pod>
        <blank-line-comment>?
            [<pod> | <plain-line>]*
        <end-pod>
    } # end of token pod
# E---

# B---
    token woven  {
        [
            || <plain-line>
        ]+
    } # end of token woven
# E---

# B---
    token non-woven {
        [
          || <one-line-no-weave>
          || <delimited-no-weave>
        ]+
    } # end of token non-woven
# E---

# B---
    token one-line-no-weave {
        <leading-ws> \N*?
        '#' <hws> 'no-weave-this-line'
        <ws-till-EOL>
    } # end of token one-line-no-weave
# E---

# B---
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
        <begin-no-weave>
            <plain-line>*
        <end-no-weave>
    } # end of token delimited-no-weave
# E---

# B---
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
# E---

# B---
} # end of grammar Semi::Literate
# E---


# B---
#TODO multi sub to accept Str & IO::PatGh
sub tangle (
# E---
# B---
    Str $input-file!,
# E---
# B---
        --> Str ) is export {
# E---

# B---
    my Str $source = $input-file.IO.slurp;
# E---


# B---
    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
    $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";
# E---

# B---
    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

#    note "submatches.elems: {@submatches.elems}";
    my Str $raku-code = @submatches.map( {
# E---

# B---
        when .key eq 'pod' {
            my $num-blank-lines =
                .value.hash<blank-line-comment><num-blank-lines>;
            "\n" x $num-blank-lines with $num-blank-lines;
        }
# E---

# B---
        default { die "Tangle: should never get here.
                    .key ==> {.key} .{.key}.keys => {.{.key}.keys}";
        } # end of default
# E---
# B---
        when .key eq 'code' {
#                note $_<code>.^name;
                note $_<code>.keys;
#                note $_<code><woven>.^name;
#                note $_<code><woven>.elems;
#                note $_<code><non-woven>.^name;
#                note $_<code><non-woven>.elems;
                my Str $code = '';
                my Str $keys = '';
                for $_<code>.keys.reverse -> $key {
                    $keys ~= "$key, " if $key;
                    $code ~= "# B---\n" ~ $_<code>{$key} ~ "# E---\n" if $_<code>{$key};
                } # end of for $_<code>.keys --> $key
#                $code ~=     $_<code><woven>.join if $_<code><woven>;
#                $code ~= $_<code><non-woven>.join if $_<code><non-woven>;
                note $keys;
                $code;
        } # end of when .key eq 'code'

# E---

# B---
    } # end of my Str $raku-code = @submatches.map(
    ).join;
# E---

# B---
    $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'begin-no-weave'     <rest-of-line> }
        = '';
    $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'no-weave-this-line' <rest-of-line> }
        = "$0\n";
    $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'end-no-weave'       <rest-of-line> }
        = '';
# E---

# B---
    # remove blank lines at the end
    $raku-code ~~ s{\n  <blank-line>* $ } = '';
# E---

# B---
    return $raku-code;
} # end of sub tangle (
# E---


# B---
sub weave (
# E---

# B---
    Str $input-file!;
# E---

# B---
    Bool :l(:$line-numbers)  = True;
        #= Should line numbers be added to the embeded code?
# E---
# B---
        --> Str ) is export {

    my UInt $line-number = 1;
# E---
# B---
    my Str $source = $input-file.IO.slurp;
# E---

# B---
    my Str $cleaned-source = $source;
    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
    $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";
# E---

# B---
    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;
# E---

# B---
        default { die "Weave: should never get here.";
#                    .key ==> {.key} .{.key}.keys => {.{.key}.keys}";
        } # end of default
# E---
# B---
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

    sub remove-comments (Seq $lines --> Seq) {
        #TODO Add a parameter to sub weave()

        my @retval = ();
        for $lines.List -> $line {
            given $line {
                # don't print full line comments
                when /<full-line-comment>/ {; #`[[do nothing]] }

                # remove comments that are at the end of a line.
                # The code will almost always end with a ';' or a '}'.
#                when / (^^ <optional-chars> [\; | \}]) <hws> '#'/
                when /<partial-line-comment>/ {
                    @retval.push: $<partial-line-comment><the-code>;
                }

                default
                    { @retval.push: $line; }
            } # end of given $line
#            note "---> ", @retval.join("\n\t");
        } # end of for $lines -> $line


#        note "» Returning: ", @retval.join("\n\t"), "\n";
        return @retval.Seq;
    } # end of sub remove-comments {Pair $p is rw}

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

#    note "weave submatches.elems: {@submatches.elems}";
#    note "submatches keys: {@submatches».keys}";
    my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";

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

     } # end of my Str $weave = @submatches.map(
    ).join;
# E---

# B---
    $weave ~~ s:g{ $non-woven-blank-lines | <$full-comment-blank-lines> } = '';
# E---

# B---
    $weave ~~ s{\n  <blank-line>* $ } = '';
# E---

# B---
    "deleteme.rakudoc".IO.spurt: $weave;
    return $weave
} # end of sub weave (
# E---

# B---
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

# E---
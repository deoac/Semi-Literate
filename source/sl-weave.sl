#!/usr/bin/env raku

# Weave a Semi-literate file into Text, Markdown, HTML, etc.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sat 16 Sep 2023 09:29:42 PM EDT
# Version 0.0.1

# begin-no-weave
# always use the latest version of Raku
use v6.*;
# end-no-weave

use File::Temp;
use Semi::Literate;

=begin pod
=TITLE Weave a semi-literate program into Text, Markdown, etc. format


=end pod

#| Weave Markdown documentation from Raku code
sub MAIN($input-file,
         Bool :l(:$line-numbers)  = True;
            #= Should line numbers be added to the embeded code?
         Str :f(:$format) is copy = 'markdown';
            #= The output format for the woven file.
         Str :o(:$output-file);
            #= The name of the output file.  Defaults to stdout.
         Bool :v(:$verbose) = True;
            #= verbose will print diagnostics and debug prints to $*ERR
    ) {
    my Str  @options;
    my Bool $no-output-file = False;

    note "Input Format =>  $format" if $verbose;
    $format .= trim;
    given $format {
        when  /:i ^ markdown | md $ / {
            $format    = 'MarkDown2';
        };
        when  /:i ^ [[plain][\-|_]?]? t[e]?xt $ / {
            $format    = 'Text';
        }
        when  /:i ^ [s]?htm[l]? $/ {
            $format    = 'HTML2';
        } # end of when  /:i html 2? $/
        when /:i ^ pdf $ / {
            $format         = 'PDF';
            @options        = "--save-as=$output-file" if $output-file;
            $no-output-file = True;
        }
        when /:i ^ pdf[\-|_]?lite  $ / {
            $format         = 'PDF::Lite';
            @options        = "--save-as=$output-file" if $output-file;
            $no-output-file = True;
        }
        when /:i ^ pod 6? $/ {
            $format    = 'Pod6';
        } # end of when /:i ^ pod 6? $/
        when /:i ^ [la]? tex $/ {
            $format    = 'Latex';
        } # end of when /:i ^ pod 6? $/
        when /:i man [page]? $/ {
            print "\n\e[33mPod::To::Man may not support pod comment blocks...\e[0m";
            $format    = 'Man';
        } # end of when /:i ^ pod 6? $/

        default {
            ; # some other format
        } # end of default

    } # end of given $output-format
    my Str $woven = weave($input-file, :$line-numbers);

    my $output-file-handle = $output-file              ??
                                open(:w, $output-file) !!
                                $*OUT
                            unless $no-output-file;

    if $format eq 'Pod6' {
        $output-file-handle.spurt: $woven;
        return;
    } # end of if $format = 'Pod6'

    # Format the Pod6 file appropriatly
    note "Weave Format =>  $format" if $verbose;
    my Str $f = "Pod::To::$format";
    try require ::($f);
    if ::($f) ~~ Failure {
        die "$format is not a supported output format"
    } # end of if ::("Pod::To::$_") ~~ Failure

    my ($pod-file, $fh) = tempfile(suffix =>  '.rakudoc', :!unlink);
    note "Temp file: $pod-file" if $verbose;

    $pod-file.IO.spurt: $woven;

    run $*EXECUTABLE,
        "--doc=$format",
        $pod-file,
        @options,
        :out($output-file-handle);

} # end of sub MAIN($input-file,


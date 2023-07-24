#!/usr/bin/env raku

# Weave a Semi-literate file into Text, Markdown, HTML, etc.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sun 23 Jul 2023 06:58:48 PM EDT
# Version 0.0.1

#no-weave
use v6.d;

use File::Temp;
use Semi::Literate;
#end-no-weave

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
    ) {
    my Str $extension;
    my Str @options;
    my Bool $no-output-file = False;

    $format .= trim;
    given $format {
        when  /:i markdown / {
            $format    = 'MarkDown2';
            $extension = 'md';
        };
        when  /:i [plain]? t[e]?xt / {
            $format    = 'Text';
            $extension = 'txt';
        }
        when  /:i html / {
            $format    = 'HTML2';
            $extension = 'html';
        } # end of when  /:i html 2? $/

        when /:i pdf / {
            $format = 'PDF';
            $extension = '.pdf';
            @options = "--save-as=$output-file" if $output-file;
            $no-output-file = True;
        }

        default {
            $extension = $format;
        } # end of default

    } # end of given $output-format

    my Str $f = "Pod::To::$format";
    try require ::($f);
    if ::($f) ~~ Failure {
        die "$format is not a supported output format"
    } # end of if ::("Pod::To::$_") ~~ Failure

    my Str $woven = weave($input-file, :$format, :$line-numbers);

    my ($pod-file, $fh) = tempfile(suffix =>  '.p6');

    $pod-file.IO.spurt: $woven;

    my $output-file-handle = $output-file              ??
                                open(:w, $output-file) !!
                                $*OUT
                            unless $no-output-file;

    run $*EXECUTABLE,
        "--doc=$format",
        $pod-file,
        @options,
        :out($output-file-handle);

} # end of sub MAIN($input-file,


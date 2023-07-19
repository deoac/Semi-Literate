#!/usr/bin/env raku

use v6.d;

use File::Temp;
use Semi::Literate;

#| Weave Markdown documentation from Raku code
sub MAIN($input-file,
         Bool :l(:$line-numbers) = True;
         Str :f(:$format) is copy ='markdown';
            #= The output format for the woven file
         Str :o(:$output-file) = '';
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

    my Str $woven = weave($input-file, $format);

    my ($pod-file, $fh) = tempfile(suffix =>  '.p6');

    $pod-file.IO.spurt: $woven;

    my $output-file-handle = $output-file              ??
                                open(:w, $output-file) !!
                                $*OUT;

    run $*EXECUTABLE,
        "--doc=$format",
        $pod-file,
        @options,
        (:out($output-file-handle) unless $no-output-file);

} # end of sub MAIN($input-file,


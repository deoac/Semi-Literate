<<<<<<< HEAD
#!/usr/bin/env raku

use v6.d;

use Semi::Literate;

#| Weave Markdown documentation from Raku code
sub MAIN($file,
         Bool :l(:$line-numbers) = True;
         Str :f(:$format)='markdown';
            #= The output format for the woven file
         Str :o(:$output-file);
    ) {
    my Str $extension;

    $format .= trim;
    given $format {
        when  /:i markdown 2? | md 2? / {
            $format    = 'MarkDown2';
            $extension = 'md';
        };
        when  /:i plain? te?xt / {
            $format    = 'Text';
            $extension = 'txt';
        }
        when  /:i html 2? / {
            $format    = 'HTML2';
            $extension = 'html';
        } # end of when  /:i html 2? $/

#        when  /:i pdf / {  }
#        when  /:i latex / {  }
#        when  /:i man / {  }
        default {
            $extension = $format;
        } # end of default

    } # end of given $output-format

    try require ::("Pod::To::$format");
    if ::("Pod::To::$_") ~~ Failure {
        die "$format is not a supported output format"
    } # end of if ::("Pod::To::$_") ~~ Failure

    $output-file //= $file.IO. extension: $extension;

    weave($file, )
} # end of sub MAIN($file,
||||||| e5a135e (Added META6 tests)
#!/usr/bin/env raku
use Pod::Weave::To::Markdown;
use Pod::Weave::To::MarkDown2;
use Pod::Weave::To::Text;
use Pod::Weave::To::HTML;
use Pod::Weave::To::HTML2;

#| Weave Markdown documentation from Raku code
sub MAIN($file,
         Str :f(:$output-format)='markdown', #= The output format for the woven file
    ) {
    given $output-format {
        when /:i^'markdown'$/ | /:i^'md'$/    { weave-markdown($file.IO).print };
        when /:i^'markdown2'$/ | /:i^'md2'$/  { weave-markdown2($file.IO).print };
        when /:i^'text'$/ | /:i^'plaintext'$/ { weave-text($file.IO).print }
        when /:i^'html'$/                     { weave-html($file.IO).print }
        when /:i^'html2'$/                    { weave-html2($file.IO).print }
        default { note "$output-format is not a supported output format"}
    }
}
=======
>>>>>>> parent of e5a135e (Added META6 tests)

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

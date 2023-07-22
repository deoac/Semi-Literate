# Weave a semi-literate program into Text, Markdown, etc. format
>
```
    1| sub MAIN($input-file,
    2|          Bool :l(:$line-numbers)  = True;
    3|          Str :f(:$format) is copy = 'markdown';
    4|          Str :o(:$output-file);
    5|     ) {
    6|     my Str $extension;
    7|     my Str @options;
    8|     my Bool $no-output-file = False;
    9| 
   10|     $format .= trim;
   11|     given $format {
   12|         when  /:i markdown / {
   13|             $format    = 'MarkDown2';
   14|             $extension = 'md';
   15|         };
   16|         when  /:i [plain]? t[e]?xt / {
   17|             $format    = 'Text';
   18|             $extension = 'txt';
   19|         }
   20|         when  /:i html / {
   21|             $format    = 'HTML2';
   22|             $extension = 'html';
   23|         } 
   24| 
   25|         when /:i pdf / {
   26|             $format = 'PDF';
   27|             $extension = '.pdf';
   28|             @options = "--save-as=$output-file" if $output-file;
   29|             $no-output-file = True;
   30|         }
   31| 
   32|         default {
   33|             $extension = $format;
   34|         } 
   35| 
   36|     } 
   37| 
   38|     my Str $f = "Pod::To::$format";
   39|     try require ::($f);
   40|     if ::($f) ~~ Failure {
   41|         die "$format is not a supported output format"
   42|     } 
   43| 
   44|     my Str $woven = weave($input-file, :$format, :$line-numbers);
   45| 
   46|     my ($pod-file, $fh) = tempfile(suffix =>  '.p6');
   47| 
   48|     $pod-file.IO.spurt: $woven;
   49| 
   50|     my $output-file-handle = $output-file              ??
   51|                                 open(:w, $output-file) !!
   52|                                 $*OUT;
   53| 
   54|     run $*EXECUTABLE,
   55|         "--doc=$format",
   56|         $pod-file,
   57|         @options,
   58|         (:out($output-file-handle) unless $no-output-file);
   59| 
   60| } 
   61| 
   62| 

```






----
Rendered from  at 2023-07-22T20:04:46Z

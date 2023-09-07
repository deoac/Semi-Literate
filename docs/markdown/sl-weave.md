# Weave a semi-literate program into Text, Markdown, etc. format
>
```
    1| #!/usr/bin/env raku
    2| 
    3| # Weave a Semi-literate file into Text, Markdown, HTML, etc.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Wed 06 Sep 2023 03:28:29 PM EDT
    6| # Version 0.0.1

```








```
    7| #| Weave Markdown documentation from Raku code
    8| sub MAIN($input-file,
    9|          Bool :l(:$line-numbers)  = True;
   10|             #= Should line numbers be added to the embeded code?
   11|          Str :f(:$format) is copy = 'markdown';
   12|             #= The output format for the woven file.
   13|          Str :o(:$output-file);
   14|             #= The name of the output file.  Defaults to stdout.
   15|          Bool :v(:$verbose) = True;
   16|             #= verbose will print diagnostics and debug prints to $*ERR
   17|     ) {
   18|     my Str $extension;
   19|     my Str @options;
   20|     my Bool $no-output-file = False;
   21| 
   22|     note "Input Format =>  $format" if $verbose;
   23|     $format .= trim;
   24|     given $format {
   25|         when  /:i ^ markdown | md $ / {
   26|             $format    = 'MarkDown2';
   27|             $extension = 'md';
   28|         };
   29|         when  /:i ^ [[plain][\-|_]?]? t[e]?xt $ / {
   30|             $format    = 'Text';
   31|             $extension = 'txt';
   32|         }
   33|         when  /:i ^ [s]?htm[l]? $/ {
   34|             $format    = 'HTML2';
   35|             $extension = 'html';
   36|         } # end of when  /:i html 2? $/
   37| 
   38|         when /:i ^ pdf $ / {
   39|             $format = 'PDF';
   40|             $extension = '.pdf';
   41|             @options = "--save-as=$output-file" if $output-file;
   42|             $no-output-file = True;
   43|         }
   44| 
   45|         when /:i ^ pdf[\-|_]?lite  $ / {
   46|             $format = 'PDF::Lite';
   47|             $extension = '.pdf';
   48|             @options = "--save-as=$output-file" if $output-file;
   49|             $no-output-file = True;
   50|         }
   51| 
   52|         default {
   53|             $extension = $format;
   54|         } # end of default
   55| 
   56| 
   57|     } # end of given $output-format
   58|     note "Weave Format =>  $format" if $verbose;
   59|     my Str $f = "Pod::To::$format";
   60|     try require ::($f);
   61|     if ::($f) ~~ Failure {
   62|         die "$format is not a supported output format"
   63|     } # end of if ::("Pod::To::$_") ~~ Failure
   64| 
   65|     my Str $woven = weave($input-file, :$format, :$line-numbers);
   66| 
   67|     my ($pod-file, $fh) = tempfile(suffix =>  '.p6');
   68| 
   69|     $pod-file.IO.spurt: $woven;
   70| 
   71|     my $output-file-handle = $output-file              ??
   72|                                 open(:w, $output-file) !!
   73|                                 $*OUT
   74|                             unless $no-output-file;
   75| 
   76|     run $*EXECUTABLE,
   77|         "--doc=$format",
   78|         $pod-file,
   79|         @options,
   80|         :out($output-file-handle);
   81| 
   82| } # end of sub MAIN($input-file,
   83| 

```






----
Rendered from  at 2023-09-06T20:29:08Z

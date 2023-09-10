# NO_TITLE
>
```
    1| #!/usr/bin/env raku
    2| 
    3| # Weave a Semi-literate file into Text, Markdown, HTML, etc.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Wed 06 Sep 2023 03:28:29 PM EDT
    6| # Version 0.0.1
    7| 
    8| # begin-no-weave
    9| use v6.d;
   10| 
   11| use File::Temp;
   12| use Semi::Literate;
   13| #end-no-weave
   14| =begin pod
   15| =TITLE Weave a semi-literate program into Text, Markdown, etc. format
   16| 
   17| 
   18| =end pod
   19| #| Weave Markdown documentation from Raku code
   20| sub MAIN($input-file,
   21|          Bool :l(:$line-numbers)  = True;
   22|             #= Should line numbers be added to the embeded code?
   23|          Str :f(:$format) is copy = 'markdown';
   24|             #= The output format for the woven file.
   25|          Str :o(:$output-file);
   26|             #= The name of the output file.  Defaults to stdout.
   27|          Bool :v(:$verbose) = True;
   28|             #= verbose will print diagnostics and debug prints to $*ERR
   29|     ) {
   30|     my Str $extension;
   31|     my Str @options;
   32|     my Bool $no-output-file = False;
   33| 
   34|     note "Input Format =>  $format" if $verbose;
   35|     $format .= trim;
   36|     given $format {
   37|         when  /:i ^ markdown | md $ / {
   38|             $format    = 'MarkDown2';
   39|             $extension = 'md';
   40|         };
   41|         when  /:i ^ [[plain][\-|_]?]? t[e]?xt $ / {
   42|             $format    = 'Text';
   43|             $extension = 'txt';
   44|         }
   45|         when  /:i ^ [s]?htm[l]? $/ {
   46|             $format    = 'HTML2';
   47|             $extension = 'html';
   48|         } # end of when  /:i html 2? $/
   49| 
   50|         when /:i ^ pdf $ / {
   51|             $format = 'PDF';
   52|             $extension = '.pdf';
   53|             @options = "--save-as=$output-file" if $output-file;
   54|             $no-output-file = True;
   55|         }
   56| 
   57|         when /:i ^ pdf[\-|_]?lite  $ / {
   58|             $format = 'PDF::Lite';
   59|             $extension = '.pdf';
   60|             @options = "--save-as=$output-file" if $output-file;
   61|             $no-output-file = True;
   62|         }
   63| 
   64|         default {
   65|             $extension = $format;
   66|         } # end of default
   67| 
   68| 
   69|     } # end of given $output-format
   70|     note "Weave Format =>  $format" if $verbose;
   71|     my Str $f = "Pod::To::$format";
   72|     try require ::($f);
   73|     if ::($f) ~~ Failure {
   74|         die "$format is not a supported output format"
   75|     } # end of if ::("Pod::To::$_") ~~ Failure
   76| 
   77|     my Str $woven = weave($input-file, :$format, :$line-numbers);
   78| 
   79|     my ($pod-file, $fh) = tempfile(suffix =>  '.p6');
   80| 
   81|     $pod-file.IO.spurt: $woven;
   82| 
   83|     my $output-file-handle = $output-file              ??
   84|                                 open(:w, $output-file) !!
   85|                                 $*OUT
   86|                             unless $no-output-file;
   87| 
   88|     run $*EXECUTABLE,
   89|         "--doc=$format",
   90|         $pod-file,
   91|         @options,
   92|         :out($output-file-handle);
   93| 
   94| } # end of sub MAIN($input-file,
   95| 

```






----
Rendered from  at 2023-09-10T18:13:13Z

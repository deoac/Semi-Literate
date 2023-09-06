# A grammar to parse a file into Pod and Code sections.
>
## Table of Contents
[INTRODUCTION](#introduction)  
[Convenient tokens](#convenient-tokens)  
[The Grammar](#the-grammar)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The begin-pod token](#the-begin-pod-token)  
[The end-pod token](#the-end-pod-token)  
[The Pod token](#the-pod-token)  
[The Code tokens](#the-code-tokens)  
[Woven sections](#woven-sections)  
[Non-woven sections](#non-woven-sections)  
[One line of code](#one-line-of-code)  
[Delimited blocks of code](#delimited-blocks-of-code)  
[The plain-line token](#the-plain-line-token)  
[The Tangle subroutine](#the-tangle-subroutine)  
[Clean the source](#clean-the-source)  
[Remove unnecessary blank lines](#remove-unnecessary-blank-lines)  
[The interesting stuff](#the-interesting-stuff)  
[Replace Pod6 sections with blank lines](#replace-pod6-sections-with-blank-lines)  
[Remove the no-weave delimiters](#remove-the-no-weave-delimiters)  
[remove blank lines at the end](#remove-blank-lines-at-the-end)  
[The Weave subroutine](#the-weave-subroutine)  
[The parameters of Weave](#the-parameters-of-weave)  
[$input-file](#input-file)  
[$format](#format)  
[$line-numbers](#line-numbers)  
[Remove blank lines at the begining and end of the code](#remove-blank-lines-at-the-begining-and-end-of-the-code)  
[Remove full comment lines followed by blank lines](#remove-full-comment-lines-followed-by-blank-lines)  
[Interesting stuff ...Next, we parse it using the Semi::Literate grammar and obtain a list of submatches (that's what the caps method does) ...](#interesting-stuff-next-we-parse-it-using-the-semiliterate-grammar-and-obtain-a-list-of-submatches-thats-what-the-caps-method-does-)  
[remove blank lines at the end](#remove-blank-lines-at-the-end-0)  
[NAME](#name)  
[VERSION](#version)  
[SYNOPSIS](#synopsis)  
[DESCRIPTION](#description)  
[BUGS AND LIMITATIONS](#bugs-and-limitations)  
[AUTHOR](#author)  
[LICENSE AND COPYRIGHT](#license-and-copyright)  

----
```
    1| use v6.*;
    2| use PrettyDump;
    3| use Data::Dump::Tree;

```




# INTRODUCTION
I want to create a semi-literate Raku source file with the extension `.sl`. Then, I will _weave_ it to generate a readable file in formats like Markdown, PDF, HTML, and more. Additionally, I will _tangle_ it to create source code without any Pod6.

To do this, I need to divide the file into `Pod` and `Code` sections by parsing it. For this purpose, I will create a dedicated Grammar.

## Convenient tokens
Let's create three tokens for convenience.





```
    4|     my token rest-of-line {    \N* [\n | $]  }
    5|     my token ws-till-EOL  {    \h* [\n | $]  }
    6|     my token blank-line   { ^^ <ws-till-EOL> }

```




# The Grammar
Our file will exclusively consist of `Pod` or `Code` sections, and nothing else. The `Code` sections are of two types, a) code that is woven into the documentation, and b) code that is not woven into the documentation. The `TOP` token clearly indicates this.





```
    7| grammar Semi::Literate is export {
    8|     token TOP {
    9|         [
   10|           | <non-woven-code>
   11|           | <pod>
   12|           | <woven-code>
   13|         ]*
   14|     } # end of token TOP

```




## The Pod6 delimiters
According to the [documentation](https://docs.raku.org/language/pod),

> **Every Pod6 document has to begin with =begin pod 1 and end with =end pod.**  


So let's define those tokens.

### The `begin-pod` token




```
   15|     token begin-pod {
   16|         ^^ <.ws> '=' begin <.ws> pod

```




Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans. Our tangle would replace all the Pod6 blocks with a single `\n`. That can clump code together that is easier read if there were one or more blank lines.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a number at the end of the `=begin` directive. For example, `=begin pod`. [ 1 ]





```
   17|         [ <.ws> $<num-blank-lines>=(\d+) ]?  # an optional number to specify the

```




The remainder of the `begin-pod` directive can only be whitespace.





```
   18|         <ws-till-EOL>
   19|     } # end of token begin

```




### The `end-pod` token
The `end-pod` token is much simpler.





```
   20|     token end-pod { ^^ <.ws> '=' end <.ws> pod <ws-till-EOL> }

```




## The `Pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `Pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.





```
   21|     token pod {
   22|         <begin-pod>
   23|             [<pod> | <plain-line>]*
   24|         <end-pod>
   25|     } # end of token pod

```




## The `Code` tokens
The `Code` sections are similarly easily defined. There are two types of `Code` sections, depending on whether they will appear in the woven code. See [below](below.md) for why some code would not be included in the woven code.

### Woven sections
These sections are trivially defined. They are just one or more `plain-line`s.





```
   26|     token woven-code { <plain-line>+ }

```




### Non-woven sections
Sometimes there will be code you do not want woven into the document, such as boilerplate code like `use v6.d;`. You have two options to mark such code. By individual lines or by delimited blocks of code.





```
   27|     token non-woven-code {
   28|         [
   29|           | <one-line-no-weave>
   30|           | <delimited-no-weave>
   31|         ]+
   32|     } # end of token non-woven

```




#### One line of code
Simply append `# begin-no-weave` at the end of the line!





```
   33|     token one-line-no-weave {
   34|         ^^ \N*?
   35|         '#' <.ws> 'no-weave-this-line'
   36|         <ws-till-EOL>
   37|     } # end of token one-line-no-weave

```




#### Delimited blocks of code
Simply add comments `# begin-no-weave` and `#end-no-weave` before and after the code you want ignored in the formatted document.





```
   38|     token begin-no-weave {
   39|         ^^ <.ws>                    # optional leading whitespace
   40|         '#' <.ws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
   41|         <ws-till-EOL>               # optional trailing whitespace or comment
   42|     } # end of token <begin-no-weave>
   43| 
   44|     token end-no-weave {
   45|         ^^ <.ws>                    # optional leading whitespace
   46|         '#' <.ws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
   47|         <ws-till-EOL>               # optional trailing whitespace or comment
   48|     } # end of token <end--no-weave>
   49| 
   50|     token delimited-no-weave {
   51|         <begin-no-weave>
   52|             <plain-line>*
   53|         <end-no-weave>
   54|     } # end of token delimited-no-weave

```




### The `plain-line` token
The `plain-line` token is, really, any line at all... ... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check).





```
   55|     token plain-line {
   56|         :my $*EXCEPTION = False;
   57|         [
   58|           ||  <begin-pod>         { $*EXCEPTION = True }
   59|           ||  <end-pod>           { $*EXCEPTION = True }
   60|           ||  <begin-no-weave>    { $*EXCEPTION = True }
   61|           ||  <end-no-weave>      { $*EXCEPTION = True }
   62|           ||  <one-line-no-weave> { $*EXCEPTION = True }
   63|           || $<plain-line> = [^^ <rest-of-line>]
   64|         ]
   65|         <?{ !$*EXCEPTION }>
   66|     } # end of token plain-line

```




And that concludes the grammar for separating `Pod` from `Code`!





```
   67| } # end of grammar Semi::Literate

```




# The Tangle subroutine
This subroutine will remove all the Pod6 code from a semi-literate file (`.sl`) and keep only the Raku code.





```
   68| sub tangle (

```




The subroutine has a single parameter, which is the input filename. The filename is required. Typically, this parameter is obtained from the command line or passed from the subroutine `MAIN`.





```
   69|     Str $input-file!,

```




The subroutine will return a `Str`, which will be a working Raku program.





```
   70|         --> Str ) is export {

```




First we will get the entire Semi-Literate `.sl` file...





```
   71|     my Str $source = $input-file.IO.slurp;

```




## Clean the source
### Remove unnecessary blank lines
Very often the `code` section of the Semi-Literate file will have blank lines that you don't want to see in the tangled working code. For example:

```
    sub foo () {
        { ... }
    } # end of sub foo ()

```




So we'll remove the blank lines immediately outside the beginning and end of the Pod6 sections.





```
   72|     $source ~~ s:g/\=end (\N*)\n+/\=end$0\n/;
   73|     $source ~~ s:g/\n+\=begin    /\n\=begin/;

```




## The interesting stuff
We parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
   74|     my Pair @submatches = Semi::Literate.parse($source).caps;

```




...and iterate through the submatches and keep only the `code` sections...





```
   75|     my Str $raku-code = @submatches.map( {
   76|         when .key eq 'woven-code'|'non-woven-code' {
   77|             .value;
   78|         }

```




### Replace Pod6 sections with blank lines




```
   79|         when .key eq 'pod' {
   80|             my $num-blank-lines = .value.hash<begin-pod><num-blank-lines>;
   81|             "\n" x $num-blank-lines with $num-blank-lines;
   82|         }
   83| 
   84|         default { die "Tangle: should never get here. .key == {.key}" }

```




... and we will join all the code sections together...





```
   85|     } # end of my Str $raku-code = @submatches.map(
   86|     ).join;

```




### Remove the _no-weave_ delimiters




```
   87|     $source ~~ s:g{ ^^ \h*   '#' <.ws>     'begin-no-weave' <rest-of-line> } = '';
   88|     $source ~~ s:g{ ^^ (.*?) '#' <.ws>     'begin-no-weave' <rest-of-line> } = "$0\n";
   89|     $source ~~ s:g{ ^^ \h*   '#' <.ws> 'end-no-weave' <rest-of-line> } = '';

```




### remove blank lines at the end




```
   90|     $raku-code ~~ s{\n  <blank-line>* $ } = '';

```




And that's the end of the `tangle` subroutine!





```
   91|     return $raku-code;
   92| } # end of sub tangle (

```




# The Weave subroutine
The `Weave` subroutine will _weave_ the `.sl` file into a readable Markdown, HTML, or other format. It is a little more complicated than `sub tangle` because it has to include the `code` sections.





```
   93| sub weave (

```




## The parameters of Weave
`sub weave` will have several parameters.

### `$input-file`
The input filename is required. Typically, this parameter is obtained from the command line through a wrapper subroutine `MAIN`.





```
   94|     Str $input-file!;

```




### `$format`
The output of the weave can (currently) be Markdown, Text, or HTML. It defaults to Markdown. The variable is case-insensitive, so 'markdown' also works.





```
   95|     Str :f(:$format) is copy = 'markdown';

```




### `$line-numbers`
It can be useful to print line numbers in the code listing. It currently defaults to True.





```
   96|     Bool :l(:$line-numbers)  = True;

```




`sub weave` returns a Str.





```
   97|         --> Str ) is export {

```








```
   98|     my UInt $line-number = 1;

```




First we will get the entire `.sl` file...





```
   99|     my Str $source = $input-file.IO.slurp;

```




### Remove blank lines at the begining and end of the code
**EXPLAIN THIS!**





```
  100|     my Str $cleaned-source = $source;
  101|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
  102|     $cleaned-source ~~ s:g{\n+\=begin (<.ws> pod) [<.ws> \d]?} = "\n\=begin$0";

```




### Remove full comment lines followed by blank lines




```
  103|     $cleaned-source ~~ s:g{ ^^ \h* '#' \N* \n+} = '';

```




## Interesting stuff ...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...




```
  104|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

```




...And now begins the interesting part. We iterate through the submatches and insert the `code` sections into the Pod6...





```
  105|     my Str $weave = @submatches.map( {
  106|         when .key eq 'pod' {
  107|             .value
  108|         } # end of when .key

```








```
  109|         when .key eq 'woven-code' { qq:to/EOCB/; }
  110|             \=begin pod
  111|             \=begin code :lang<raku>
  112|              { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
  113|                 .value
  114|                 .lines
  115|                 .map($line-numbers
  116|                         ?? {"%4s| %s\n".sprintf($line-number++, $_) }
  117|                         !! {     "%s\n".sprintf(                $_) }
  118|                     )
  119|                 .chomp;
  120|              }
  121|             \=end code
  122|             \=end pod
  123|             EOCB
  124| 
  125|         when .key eq 'non-woven-code' {
  126|           ''; # do nothing
  127|         } # end of when .key eq 'non-woven'
  128| 
  129|         default { die "Weave: should never get here. .key == {.key}" }
  130|     } # end of my $weave = Semi::Literate.parse($source).caps.map
  131|     ).join;

```




### remove blank lines at the end




```
  132|     $weave ~~ s{\n  <blank-line>* $ } = '';

```




And that's the end of the `tangle` subroutine!





```
  133|     return $weave
  134| } # end of sub weave (

```




# NAME
`Semi::Literate` - A semi-literate way to weave and tangle Raku/Pod6 source code.

# VERSION
This documentation refers to `Semi-Literate` version 0.0.1

# SYNOPSIS
```
use Semi::Literate;

```
# DESCRIPTION
`Semi::Literate` is based on Daniel Sockwell's Pod::Literate module

A full description of the module and its features. May include numerous subsections (i.e. =head2, =head2, etc.)

# BUGS AND LIMITATIONS
There are no known bugs in this module. Patches are welcome.

# AUTHOR
Shimon Bollinger (deoac.bollinger@gmail.com)

# LICENSE AND COPYRIGHT
© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Raku itself. See [The Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.





```
  135| my %*SUB-MAIN-OPTS =
  136|   :named-anywhere,             # allow named variables at any location
  137|   :bundling,                   # allow bundling of named arguments
  138|   :allow-no,                   # allow --no-foo as alternative to --/foo
  139|   :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
  140| ;
  141| 
  142| multi MAIN(Bool :$pod!) is hidden-from-USAGE {
  143|     for $=pod -> $pod-item {
  144|         for $pod-item.contents -> $pod-block {
  145|             $pod-block.raku.say;
  146|         }
  147|     }
  148| } # end of multi MAIN (:$pod)
  149| 
  150| multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {
  151|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
  152| } # end of multi MAIN(Bool :$man!)
  153| 
  154| my $semi-literate-file = '/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl';
  155| multi MAIN(Bool :$testt!) {
  156|     say tangle($semi-literate-file);
  157| } # end of multi MAIN(Bool :$test!)
  158| 
  159| multi MAIN(Bool :$testw!) {
  160|     say weave($semi-literate-file);
  161| } # end of multi MAIN(Bool :$test!)
  162| 

```





----
###### 1
This is non-standard Pod6 and will not compile until woven!

----
Rendered from  at 2023-09-06T20:46:16Z

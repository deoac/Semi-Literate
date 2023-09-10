# A grammar to parse a file into Pod and Code sections.
>
## Table of Contents
[INTRODUCTION](#introduction)  
[Convenient tokens](#convenient-tokens)  
[The Grammar](#the-grammar)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The begin-pod token](#the-begin-pod-token)  
[The end-pod token](#the-end-pod-token)  
[Replacing Pod6 sections with blank lines](#replacing-pod6-sections-with-blank-lines)  
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
[Interesting stuff](#interesting-stuff)  
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
    1| #! /usr/bin/env raku
    2| 
    3| # Get the Pod vs. Code structure of a Raku/Pod6 file.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Sun 10 Sep 2023 01:43:53 PM EDT
    6| # Version 0.0.1
    7| 

```




# INTRODUCTION
I want to create a semi-literate Raku source file with the extension `.sl`. Then, I will _weave_ it to generate a readable file in formats like Markdown, PDF, HTML, and more. Additionally, I will _tangle_ it to create source code without any Pod6.

## Convenient tokens
Let's create some tokens for convenience.





```
    8| #TODO Put these into a Role
    9|     my token hws            {    <!ww>\h*       } # Horizontal White Space
   10|     my token leading-ws     { ^^ <hws>          } # Whitespace at start of line
   11|     my token optional-chars {    \N*?           }

```




To do this, I need to divide the file into `Pod` and `Code` sections by parsing it. For this purpose, I will create a dedicated Grammar.

# The Grammar




```
   12| #use Grammar::Tracer;
   13| grammar Semi::Literate is export {

```




Our file will exclusively consist of `Pod` or `Code` sections, and nothing else. The `Code` sections are of two types, a) code that is woven into the documentation, and b) code that is not woven into the documentation. The `TOP` token clearly indicates this.





```
   14|     token TOP {
   15|         [
   16|           || <pod>
   17|           || <woven-code>
   18|           || <non-woven-code>
   19|         ]*
   20|     } # end of token TOP

```




## The Pod6 delimiters
According to the [documentation](https://docs.raku.org/language/pod),

> **Every Pod6 document has to begin with =begin pod and end with =end pod.**  


So let's define those tokens.

### The `begin-pod` token




```
   21|     token begin-pod {
   22|         <leading-ws>
   23|         '=' begin <hws> pod
   24|         <ws-till-EOL>
   25|     } # end of token begin-pod

```




### The `end-pod` token
The `end-pod` token is much simpler.





```
   26|     token end-pod { <leading-ws> '=' end <hws> pod <ws-till-EOL> }

```




### Replacing Pod6 sections with blank lines
Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans. Our tangle would replace all the Pod6 blocks with a single `\n`. That can clump code together that is easier read if there were one or more blank lines.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a Pod6 comment immediately after the `=begin pod` statement. The comment can say anything you like, but must end with a digit specifying the number of blank lines with which to replace the Pod6 section.





```
   27|     token num-blank-line-comment {
   28|         <leading-ws>
   29|         '=' comment
   30|         <optional-chars>
   31|         $<num-blank-lines> = (\d+)?
   32|         <ws-till-EOL>
   33|     } # end of token num-blank-line-comment

```




## The `Pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `Pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.





```
   34|     token pod {
   35|         <begin-pod>
   36|         <num-blank-line-comment>?
   37|             [<pod> || <plain-line>]*
   38|         <end-pod>
   39|     } # end of token pod

```




## The `Code` tokens
The `Code` sections are similarly easily defined. There are two types of `Code` sections, depending on whether they will appear in the woven code. See [below](below.md) for why some code would not be included in the woven code.

### Woven sections
These sections are trivially defined. They are just one or more `plain-line`s.





```
   40|     token woven-code  {
   41|         [
   42|             || <plain-line>
   43|         ]+
   44|     } # end of token woven-code

```




### Non-woven sections
Sometimes there will be code you do not want woven into the document, such as boilerplate code like `use v6.d;`. You have two options to mark such code. By individual lines or by delimited blocks of code.





```
   45|     token non-woven-code {
   46|         [
   47|           || <one-line-no-weave>
   48|           || <delimited-no-weave>
   49|         ]+
   50|     } # end of token non-woven

```




#### One line of code
Simply append `# begin-no-weave` at the end of the line!





```
   51|     token one-line-no-weave {
   52|         ^^ \N*?
   53|         '#' <hws> 'no-weave-this-line'
   54|         <ws-till-EOL>
   55|     } # end of token one-line-no-weave

```




#### Delimited blocks of code
Simply add comments `# begin-no-weave` and `#end-no-weave` before and after the code you want ignored in the formatted document.





```
   56|     token begin-no-weave {
   57|         <leading-ws>                    # optional leading whitespace
   58|         '#' <hws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
   59|         <ws-till-EOL>               # optional trailing whitespace or comment
   60|     } # end of token <begin-no-weave>
   61| 
   62|     token end-no-weave {
   63|         <leading-ws>                    # optional leading whitespace
   64|         '#' <hws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
   65|         <ws-till-EOL>               # optional trailing whitespace or comment
   66|     } # end of token <end--no-weave>
   67| 
   68|     token delimited-no-weave {
   69|         <begin-no-weave>
   70|             <plain-line>*
   71|         <end-no-weave>
   72|     } # end of token delimited-no-weave
   73| 
   74|     token code-comments {
   75|             <leading-ws>
   76|             '#' <rest-of-line>
   77|         <!{ / <begin-no-weave> | <end-no-weave> / }>
   78|     } # end of token code-comments

```




### The `plain-line` token
The `plain-line` token is, really, any line at all... ... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check).





```
   79|     token plain-line {
   80|         :my $*EXCEPTION = False;
   81|         [
   82|           ||  <begin-pod>         { $*EXCEPTION = True }
   83|           ||  <end-pod>           { $*EXCEPTION = True }
   84|           ||  <begin-no-weave>    { $*EXCEPTION = True }
   85|           ||  <end-no-weave>      { $*EXCEPTION = True }
   86|           ||  <one-line-no-weave> { $*EXCEPTION = True }
   87|           || $<plain-line> = [^^ <rest-of-line>]
   88|         ]
   89|         <?{ !$*EXCEPTION }>
   90|     } # end of token plain-line

```




And that concludes the grammar for separating `Pod` from `Code`!





```
   91| } # end of grammar Semi::Literate

```




# The Tangle subroutine
This subroutine will remove all the Pod6 code from a semi-literate file (`.sl`) and keep only the Raku code.





```
   92| #TODO multi sub to accept Str & IO::PatGh
   93| sub tangle (

```




The subroutine has a single parameter, which is the input filename. The filename is required. Typically, this parameter is obtained from the command line or passed from the subroutine `MAIN`.





```
   94|     Str $input-file!,

```




The subroutine will return a `Str`, which will be a working Raku program.





```
   95|         --> Str ) is export {

```




First we will get the entire Semi-Literate `.sl` file...





```
   96|     my Str $source = $input-file.IO.slurp;

```




## Clean the source
### Remove unnecessary blank lines
Very often the `code` section of the Semi-Literate file will have blank lines that you don't want to see in the tangled working code. For example:

```
                                                # <== unwanted blank lines
                                                # <== unwanted blank lines
    sub foo () {
        { ... }
    } # end of sub foo ()
                                                # <== unwanted blank lines
                                                # <== unwanted blank lines


```




So we'll remove the blank lines immediately outside the beginning and end of the Pod6 sections.





```
   97|     my Str $cleaned-source = $source;
   98|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
   99|     $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";

```




## The interesting stuff
We parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
  100|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

```




...and iterate through the submatches and keep only the `code` sections...





```
  101| #    note "submatches.elems: {@submatches.elems}";
  102|     my Str $raku-code = @submatches.map( {
  103| #        note .key;
  104|         when .key eq 'woven-code'|'non-woven-code' {
  105|             .value;
  106|         }

```




### Replace Pod6 sections with blank lines




```
  107|         when .key eq 'pod' {
  108|             my $num-blank-lines =
  109|                 .value.hash<num-blank-line-comment><num-blank-lines>;
  110|             "\n" x $num-blank-lines with $num-blank-lines;
  111|         }
  112| 

```




... and we will join all the code sections together...





```
  113|     } # end of my Str $raku-code = @submatches.map(
  114|     ).join;

```




### Remove the _no-weave_ delimiters




```
  115|     $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'begin-no-weave'     <rest-of-line> }
  116|         = '';
  117|     $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'no-weave-this-line' <rest-of-line> }
  118|         = "$0\n";
  119|     $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'end-no-weave'       <rest-of-line> }
  120|         = '';

```




### remove blank lines at the end




```
  121|     $raku-code ~~ s{\n  <blank-line>* $ } = '';

```




And that's the end of the `tangle` subroutine!





```
  122|     return $raku-code;
  123| } # end of sub tangle (

```




# The Weave subroutine
The `Weave` subroutine will _weave_ the `.sl` file into a readable Markdown, HTML, or other format. It is a little more complicated than `sub tangle` because it has to include the `code` sections.





```
  124| sub weave (

```




## The parameters of Weave
`sub weave` will have several parameters.

### `$input-file`
The input filename is required. Typically, this parameter is obtained from the command line through a wrapper subroutine `MAIN`.





```
  125|     Str $input-file!;

```




### `$format`
The output of the weave can (currently) be Markdown, Text, or HTML. It defaults to Markdown. The variable is case-insensitive, so 'markdown' also works.





```
  126|     Str :f(:$format) is copy = 'markdown';
  127|         #= The output format for the woven file.

```




### `$line-numbers`
It can be useful to print line numbers in the code listing. It currently defaults to True.





```
  128|     Bool :l(:$line-numbers)  = True;
  129|         #= Should line numbers be added to the embeded code?

```




`sub weave` returns a Str.





```
  130|         --> Str ) is export {
  131| 
  132|     my UInt $line-number = 1;

```




First we will get the entire `.sl` file...





```
  133|     my Str $source = $input-file.IO.slurp;

```




### Remove blank lines at the begining and end of the code
**EXPLAIN THIS!**





```
  134|     my Str $cleaned-source = $source;
  135|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
  136|     $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";

```




## Interesting stuff
...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
  137|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

```




...And now begins the interesting part. We iterate through the submatches and insert the `code` sections into the Pod6...





```
  138| #    note "weave submatches.elems: {@submatches.elems}";
  139| #    note "submatches keys: {@submatches».keys}";
  140|     my Str $weave = @submatches.map( {
  141|         when .key eq 'pod' {
  142|             .value
  143|         } # end of when .key
  144| 
  145|         when .key eq 'woven-code' {qq:to/EOCB/; }
  146|             \=begin pod
  147|             \=begin code :lang<raku>
  148|              { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
  149|                 .value
  150|                 .lines
  151|                 .map($line-numbers
  152|                         ?? {"%4s| %s\n".sprintf($line-number++, $_) }
  153|                         !! {     "%s\n".sprintf(                $_) }
  154|                     )
  155|                 .chomp # get rid of the last \n
  156|              }
  157|             \=end code
  158|             \=end pod
  159|             EOCB
  160| 
  161|         when .key eq 'non-woven-code' {
  162|           ''; # do nothing
  163|           #TODO don't insert a newline here.
  164|         } # end of when .key eq 'non-woven-code'
  165| 

```




```
  166|     } # end of my Str $weave = @submatches.map(
  167|     ).join;

```




### remove blank lines at the end




```
  168|     $weave ~~ s{\n  <blank-line>* $ } = '';

```




And that's the end of the `tangle` subroutine!





```
  169|     return $weave
  170| } # end of sub weave (

```




# NAME
`Semi::Literate` - A semi-literate way to weave and tangle Raku/Pod6 source code.

# VERSION
This documentation refers to `Semi-Literate` version 0.0.1

# SYNOPSIS
```
use Semi::Literate;
# Brief but working code example(s) here showing the most common usage(s)

# This section will be as far as many users bother reading
# so make it as educational and exemplary as possible.


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







----
Rendered from  at 2023-09-10T17:45:37Z

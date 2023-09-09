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
    1| 
    2| # Get the Pod vs. Code structure of a Raku/Pod6 file.
    3| # © 2023 Shimon Bollinger. All rights reserved.
    4| # Last modified: Sat 09 Sep 2023 07:48:51 PM EDT
    5| # Version 0.0.1
    6| 

```




# INTRODUCTION
I want to create a semi-literate Raku source file with the extension `.sl`. Then, I will _weave_ it to generate a readable file in formats like Markdown, PDF, HTML, and more. Additionally, I will _tangle_ it to create source code without any Pod6.

## Convenient tokens
Let's create four tokens for convenience.





```
    7|     my token hws          {    <!ww>\h*        } # Horizontal White Space
    8|     my token rest-of-line {    \N*   [\n | $]  }
    9|     my token ws-till-EOL  {    <hws> [\n | $]  }
   10|     my token blank-line   { ^^ <ws-till-EOL>   }

```




To do this, I need to divide the file into `Pod` and `Code` sections by parsing it. For this purpose, I will create a dedicated Grammar.

# The Grammar




```
   11| grammar Semi::Literate is export {

```




Our file will exclusively consist of `Pod` or `Code` sections, and nothing else. The `Code` sections are of two types, a) code that is woven into the documentation, and b) code that is not woven into the documentation. The `TOP` token clearly indicates this.





```
   12|     token TOP {
   13|         [
   14|           | <pod>
   15|           | <woven-code>
   16|           | <non-woven-code>
   17|         ]*
   18|     } # end of token TOP

```




## The Pod6 delimiters
According to the [documentation](https://docs.raku.org/language/pod),

> **Every Pod6 document has to begin with =begin pod and end with =end pod.**  


So let's define those tokens.

### The `begin-pod` token




```
   19|     token begin-pod {
   20|         ^^ <hws> '=' begin <hws> pod <ws-till-EOL>
   21|     } # end of token begin-pod

```




### The `end-pod` token
The `end-pod` token is much simpler.





```
   22|     token end-pod { ^^ <hws> '=' end <hws> pod <ws-till-EOL> }

```




### Replacing Pod6 sections with blank lines
Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans. Our tangle would replace all the Pod6 blocks with a single `\n`. That can clump code together that is easier read if there were one or more blank lines.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a Pod6 comment immediately after the `=begin pod` statement. The comment can say anything you like, but must end with a digit specifying the number of blank lines with which to replace the Pod6 section.





```
   23|     token blank-line-comment {
   24|         ^^ <hws>
   25|         '=' comment
   26|         \N*?
   27|         $<num-blank-lines> = (\d+)?
   28|         <ws-till-EOL>
   29|     } # end of token blank-line-comment

```




## The `Pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `Pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.





```
   30|     token pod {
   31|         <begin-pod>
   32|         <blank-line-comment>?
   33|             [<pod> | <plain-line>]*
   34|         <end-pod>
   35|     } # end of token pod

```




## The `Code` tokens
The `Code` sections are similarly easily defined. There are two types of `Code` sections, depending on whether they will appear in the woven code. See [below](below.md) for why some code would not be included in the woven code.

### Woven sections
These sections are trivially defined. They are just one or more `plain-line`s.





```
   36|     token woven-code  {
   37|         [
   38|             | <code-comments> { $*EXCEPTION = True }
   39|             | <plain-line>+
   40|         ]
   41|         <?{ !$*EXCEPTION }>
   42|     } # end of token woven-code

```




### Non-woven sections
Sometimes there will be code you do not want woven into the document, such as boilerplate code like `use v6.d;`. You have two options to mark such code. By individual lines or by delimited blocks of code.





```
   43|     token non-woven-code {
   44|         [
   45|           | <one-line-no-weave>
   46|           | <delimited-no-weave>
   47|           | <code-comments>
   48|         ]+
   49|     } # end of token non-woven

```




#### One line of code
Simply append `# begin-no-weave` at the end of the line!





```
   50|     token one-line-no-weave {
   51|         ^^ \N*?
   52|         '#' <hws> 'no-weave-this-line'
   53|         <ws-till-EOL>
   54|     } # end of token one-line-no-weave

```




#### Delimited blocks of code
Simply add comments `# begin-no-weave` and `#end-no-weave` before and after the code you want ignored in the formatted document.





```
   55|     token begin-no-weave {
   56|         ^^ <hws>                    # optional leading whitespace
   57|         '#' <hws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
   58|         <ws-till-EOL>               # optional trailing whitespace or comment
   59|     } # end of token <begin-no-weave>
   60| 
   61|     token end-no-weave {
   62|         ^^ <hws>                    # optional leading whitespace
   63|         '#' <hws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
   64|         <ws-till-EOL>               # optional trailing whitespace or comment
   65|     } # end of token <end--no-weave>
   66| 
   67|     token delimited-no-weave {
   68|         <begin-no-weave>
   69|             <plain-line>*
   70|         <end-no-weave>
   71|     } # end of token delimited-no-weave
   72| 
   73|     token code-comments {
   74|         ^^ <hws>
   75|         '#' <rest-of-line>
   76|     } # end of token code-comments

```




### The `plain-line` token
The `plain-line` token is, really, any line at all... ... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check).





```
   77|     token plain-line {
   78|         :my $*EXCEPTION = False;
   79|         [
   80|           ||  <begin-pod>         { $*EXCEPTION = True }
   81|           ||  <end-pod>           { $*EXCEPTION = True }
   82|           ||  <begin-no-weave>    { $*EXCEPTION = True }
   83|           ||  <end-no-weave>      { $*EXCEPTION = True }
   84|           ||  <one-line-no-weave> { $*EXCEPTION = True }
   85|           || $<plain-line> = [^^ <rest-of-line>]
   86|         ]
   87|         <?{ !$*EXCEPTION }>
   88|     } # end of token plain-line

```




And that concludes the grammar for separating `Pod` from `Code`!





```
   89| } # end of grammar Semi::Literate

```




# The Tangle subroutine
This subroutine will remove all the Pod6 code from a semi-literate file (`.sl`) and keep only the Raku code.





```
   90| sub tangle (

```




The subroutine has a single parameter, which is the input filename. The filename is required. Typically, this parameter is obtained from the command line or passed from the subroutine `MAIN`.





```
   91|     Str $input-file!,

```




The subroutine will return a `Str`, which will be a working Raku program.





```
   92|         --> Str ) is export {

```




First we will get the entire Semi-Literate `.sl` file...





```
   93|     my Str $source = $input-file.IO.slurp;

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
   94|     my Str $cleaned-source = $source;
   95|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
   96|     $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";

```




## The interesting stuff
We parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
   97|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

```




...and iterate through the submatches and keep only the `code` sections...





```
   98|     my Str $raku-code = @submatches.map( {
   99| #        note .key;
  100|         when .key eq 'woven-code'|'non-woven-code' {
  101|             .value;
  102|         }

```




### Replace Pod6 sections with blank lines




```
  103|         when .key eq 'pod' {
  104|             my $num-blank-lines =
  105|                 .value.hash<blank-line-comment><num-blank-lines>;
  106|             "\n" x $num-blank-lines with $num-blank-lines;
  107|         }
  108| 

```




... and we will join all the code sections together...





```
  109|     } # end of my Str $raku-code = @submatches.map(
  110|     ).join;

```




### Remove the _no-weave_ delimiters




```
  111|     $raku-code ~~ s:g{ ^^ <hws> '#' <hws> 'begin-no-weave'     <rest-of-line> }
  112|         = '';
  113|     $raku-code ~~ s:g{ ^^ <hws> '#' <hws> 'no-weave-this-line' <rest-of-line> }
  114|         = "$0\n";
  115|     $raku-code ~~ s:g{ ^^ <hws> '#' <hws> 'end-no-weave'       <rest-of-line> }
  116|         = '';

```




### remove blank lines at the end




```
  117|     $raku-code ~~ s{\n  <blank-line>* $ } = '';

```




And that's the end of the `tangle` subroutine!





```
  118|     return $raku-code;
  119| } # end of sub tangle (

```




# The Weave subroutine
The `Weave` subroutine will _weave_ the `.sl` file into a readable Markdown, HTML, or other format. It is a little more complicated than `sub tangle` because it has to include the `code` sections.





```
  120| sub weave (

```




## The parameters of Weave
`sub weave` will have several parameters.

### `$input-file`
The input filename is required. Typically, this parameter is obtained from the command line through a wrapper subroutine `MAIN`.





```
  121|     Str $input-file!;

```




### `$format`
The output of the weave can (currently) be Markdown, Text, or HTML. It defaults to Markdown. The variable is case-insensitive, so 'markdown' also works.





```
  122|     Str :f(:$format) is copy = 'markdown';
  123|         #= The output format for the woven file.

```




### `$line-numbers`
It can be useful to print line numbers in the code listing. It currently defaults to True.





```
  124|     Bool :l(:$line-numbers)  = True;
  125|         #= Should line numbers be added to the embeded code?

```




`sub weave` returns a Str.





```
  126|         --> Str ) is export {
  127| 
  128|     my UInt $line-number = 1;

```




First we will get the entire `.sl` file...





```
  129|     my Str $source = $input-file.IO.slurp;

```




### Remove blank lines at the begining and end of the code
**EXPLAIN THIS!**





```
  130|     my Str $cleaned-source = $source;
  131|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
  132|     $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";

```




## Interesting stuff
...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
  133|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

```




...And now begins the interesting part. We iterate through the submatches and insert the `code` sections into the Pod6...





```
  134|     my Str $weave = @submatches.map( {
  135|         when .key eq 'pod' {
  136|             .value
  137|         } # end of when .key
  138| 
  139|         when .key eq 'woven-code' {qq:to/EOCB/; }
  140|             \=begin pod
  141|             \=begin code :lang<raku>
  142|              { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
  143|                 .value
  144|                 .lines
  145|                 .map($line-numbers
  146|                         ?? {"%4s| %s\n".sprintf($line-number++, $_) }
  147|                         !! {     "%s\n".sprintf(                $_) }
  148|                     )
  149|                 .chomp # get rid of the last \n
  150|              }
  151|             \=end code
  152|             \=end pod
  153|             EOCB
  154| 
  155|         when .key eq 'non-woven-code' {
  156|           ''; # do nothing
  157|           #TODO don't insert a newline here.
  158|         } # end of when .key eq 'non-woven-code'
  159| 

```




```
  160|     } # end of my Str $weave = @submatches.map(
  161|     ).join;

```




### remove blank lines at the end




```
  162|     $weave ~~ s{\n  <blank-line>* $ } = '';

```




And that's the end of the `tangle` subroutine!





```
  163|     return $weave
  164| } # end of sub weave (

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
Rendered from  at 2023-09-09T23:51:19Z

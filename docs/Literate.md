# A grammar to parse a file into Pod and Code sections. 
>
## Table of Contents
[INTRODUCTION](#introduction)  
[The Grammar](#the-grammar)  
[Convenient tokens](#convenient-tokens)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The begin token](#the-begin-token)  
[The end token](#the-end-token)  
[The Pod token](#the-pod-token)  
[The Code token](#the-code-token)  
[The plain-line token](#the-plain-line-token)  
[Disallowing the delimiters in a plain-line.](#disallowing-the-delimiters-in-a-plain-line)  
[The Tangle subroutine](#the-tangle-subroutine)  
[Weave](#weave)  
[The parameters of Weave](#the-parameters-of-weave)  
[$input-file](#input-file)  
[$output-format](#output-format)  
[$line-numbers](#line-numbers)  
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

# The Grammar
Our file will exclusively consist of `Pod` or `Code` sections, and nothing else. The `TOP` token clearly indicates this.





```
  4| grammar Semi::Literate {
  5|     token TOP {   [ <pod> | <code> ]* }

```




## Convenient tokens
Let's introduce a "rest of the line" token for convenience.





```
  6|     my token rest-of-line { \h* \N* \n? } 

```




## The Pod6 delimiters
According to the [documentation](https://docs.raku.org/language/pod),

> **Every Pod6 document has to begin with =begin pod and end with =end pod.**  


So let's define those tokens. We need to declare them with `my` because we need to use them in a subroutine later. #TODO explain why.

### The `begin` token




```
  7|     my token begin {
  8|         ^^ <.ws> \= begin <.ws> pod

```




Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a number at the end of the `=begin` directive. For example, `=begin pod` .





```
  9|         [ <.ws> $<blank-lines>=(\d+) ]?

```




The remainder of the `begin` directive can only be whitespace.





```
 10|         <rest-of-line>
 11|     } 

```




### The `end` token
The `end` token is much simpler.





```
 12|     my token end { ^^ <.ws> \= end <.ws> pod <rest-of-line> }

```




## The `Pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `Pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.





```
 13|     token pod {
 14|         <begin> 
 15|             [<pod> | <plain-line>]*
 16|         <end>
 17|     } 

```




## The `Code` token
The `Code` sections are trivially defined. They are just one or more `plain-line`s.





```
 18|     token code { <plain-line>+ }

```




### The `plain-line` token
The `plain-line` token is, really, any line at all... 





```
 19|     token plain-line {
 20|        $<plain-line> = [^^ <rest-of-line>]

```




### Disallowing the delimiters in a `plain-line`.
... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes#Regex_Boolean_condition_check).





```
 21|         <?{ &not-a-delimiter($<plain-line>.Str) }> 
 22|     } 

```




This function simply checks whether the `plain-line` match object matches either the `begin` or `end` token. 

Incidentally, this function is why we had to declare those tokens with the `my` keyword. This function wouldn't work otherwise.





```
 23|     sub not-a-delimiter (Str $line --> Bool) {
 24|         return not $line ~~ /<begin> | <end>/;
 25|     } 

```




And that concludes the grammar for separating `Pod` from `Code`!





```
 26| } 

```




# The Tangle subroutine
This subroutine will remove all the Pod6 code from a semi-literate file (`.sl`) and keep only the Raku code.





```
 27| sub tangle ( 

```




The subroutine has a single parameter, which is the input filename. The filename is required. Typically, this parameter is obtained from the command line through the wrapper subroutine `MAIN`. 





```
 28|     IO::Path $input-file!,

```




The subroutine will return a `Str`, which should be a working Raku program.





```
 29|     --> Str ) {

```




First we will get the entire `.sl` file...





```
 30|     my Str $source = $input-file.slurp;

```




Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a number at the end of the `=begin` directive. For example, `=begin pod 2` .





```
 31|     $source ~~ s:g/\=end (\N*)\n+/=end$0\n/;
 32|     $source ~~ s:g/\n+\=begin    /\n=begin/;

```




...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
 33|     my Pair @submatches = Semi::Literate.parse($source).caps;

```




...And now begins the interesting part. We iterate through the submatches and keep only the `code` sections...





```
 34|     my Str $raku = @submatches.map( {
 35|         when .key eq 'code' {
 36|             .value;
 37|         }

```




#TODO 





```
 38|         when .key eq 'pod' { 
 39|             my $blank-lines = .value.hash<begin><blank-lines>;
 40|             with $blank-lines { "\n" x $blank-lines }
 41|         }

```




#TODO 





```
 42|         default { die 'Should never get here' }

```




... and we will join all the code sections together...





```
 43|     } 
 44|     ).join;

```




And that's the end of the `tangle` subroutine!





```
 45| } 

```




# Weave
The `Weave` subroutine will _weave_ the `.sl` file into a readable Markdown, HTML, or other format. It is a little more complicated than `sub tangle` because it has to include the `code` sections.





```
 46| sub weave ( 

```




## The parameters of Weave
`sub weave` will have several parameters. 

### `$input-file`
The input filename is required. Typically, this parameter is obtained from the command line through a wrapper subroutine `MAIN`.





```
 47|     IO::Path $input-file!;

```




### `$output-format`
The output of the weave can (currently) be Markdown, Text, or HTML. It defaults to Markdown. The variable is case-insensitive, so 'markdown' also works.





```
 48|     Str $output-format = 'Markdown'; # Can also be 'HTML' or 'Text'

```




### `$line-numbers`
It can be useful to print line numbers in the code listing. It currently defaults to True.





```
 49|     Bool $line-numbers = True;

```




`sub weave` returns a Str.





```
 50| --> Str ) {
 51| 
 52| } 

```




# NAME
`Semi::Literate` - Get the Pod vs Code structure from a Raku/Pod6 file.

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
 53| my %*SUB-MAIN-OPTS =                                                       
 54|   :named-anywhere,             
 55|   :bundling,                   
 56|   :allow-no,                   
 57|   :numeric-suffix-as-value,    
 58| ;                                                                          
 59| 
 60| multi MAIN(Bool :$pod!) is hidden-from-USAGE {                                                  
 61|     for $=pod -> $pod-item {                                               
 62|         for $pod-item.contents -> $pod-block {                             
 63|             $pod-block.raku.say;                                           
 64|         }                                                                  
 65|     }                                                                      
 66| } 
 67| 
 68| multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {                           
 69|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;                          
 70| } # end of multi MAIN(Bool :$man!)                                         
 71| 
 72| multi MAIN(Bool :$test!) {
 73|     say tangle('/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl'.IO);
 74| } # end of multi MAIN(Bool :$test!)

```






----
Rendered from  at 2023-07-15T23:48:43Z
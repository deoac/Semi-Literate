# A grammar to parse a file into Pod and Code sections. 
>
## Table of Contents
[INTRODUCTION](#introduction)  
[The Grammar](#the-grammar)  
[Convenient tokens](#convenient-tokens)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The Pod token](#the-pod-token)  
[The Code token](#the-code-token)  
[The plain-line token](#the-plain-line-token)  
[Disallowing the delimiters in a plain-line.](#disallowing-the-delimiters-in-a-plain-line)  
[The Tangle subroutine](#the-tangle-subroutine)  
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

```




# INTRODUCTION
I want to create a semi-literate Raku source file with the extension `.sl`. Then, I will _weave_ it to generate a readable file in formats like Markdown, PDF, HTML, and more. Additionally, I will _tangle_ it to create source code without any Pod6.

To do this, I need to divide the file into `Pod` and `Code` sections by parsing it. For this purpose, I will create a dedicated Grammar.

# The Grammar
Our file will exclusively consist of `Pod` or `Code` sections, and nothing else. The `TOP` token clearly indicates this.





```
  2| grammar Semi::Literate {
  3|     token TOP {   [ <pod> | <code> ]* }

```




## Convenient tokens
Let's introduce a "rest of the line" token for convenience.





```
  4|     my token rest-of-line { \h* \N* \n? } 

```




## The Pod6 delimiters
According to the [documentation](https://docs.raku.org/language/pod),

> **Every Pod6 document has to begin with =begin pod and end with =end pod.**  


So let's define those tokens. We need to declare them with `my` because we need to use them in a subroutine later. #TODO explain why.





```
  5|     my token begin {^^ <.ws> \= begin <.ws> pod <rest-of-line>}
  6|     my token end   {^^ <.ws> \= end   <.ws> pod <rest-of-line>}

```




## The `Pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `Pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.





```
  7|     token pod {
  8|         <begin> 
  9|             [<pod> | <plain-line>]*
 10|         <end>
 11|     } 

```




## The `Code` token
The `Code` sections are trivially defined. They are just one or more `plain-line`s.





```
 12|     token code { <plain-line>+ }

```




## The `plain-line` token
The `plain-line` token is, really, any line at all... 





```
 13|     token plain-line {
 14|        $<plain-line> = [^^ <rest-of-line>]

```




## Disallowing the delimiters in a `plain-line`.
... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes#Regex_Boolean_condition_check).





```
 15|         <?{ &not-a-delimiter($<plain-line>.Str) }> 
 16|     } 

```




This function simply checks whether the `plain-line` match object matches either `begin` or `end`. 

Incidentally, this function is why we had to declare those tokens with the `my` keyword. This function wouldn't work otherwise.





```
 17|     sub not-a-delimiter (Str $line --> Bool) {
 18|         return not $line ~~ /<begin> | <end>/;
 19|     } 

```




And that concludes the grammar for separating `Pod` from `Code`!





```
 20| } 

```




# The Tangle subroutine
This subroutine will remove all the Pod6 code from a semi-literate file (`.sl`) and keep only the Raku code.





```
 21| sub tangle (

```




The subroutine has only one parameter, the input filename





```
 22|     IO::Path $input-file!,

```




The subroutine will return a `Str`, which should be a working Raku program.





```
 23|     --> Str ) {

```




First we will get the entire `.sl` file...





```
 24|     my Str $source = $input-file.slurp;

```




...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...





```
 25|     my List @submatches = Semi::Literate.parse($source).caps;

```




...And now begins the interesting part. We iterate through the submatches and keep only the `code` sections, ignoring the `pod` sections...





```
 26|     my Str $raku = @submatches.map( {
 27|         when .key eq 'code' {
 28|             .value
 29|         }) # end of when .key eq 'code'

```




... and we will join all the code sections together...





```
 30|         .join("\n");
 31|     } # end of my Str $raku = @submatches.map(

```




And that's the end of the `tangle` subroutine!





```
 32| } 

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
 33| my %*SUB-MAIN-OPTS =                                                       
 34|   :named-anywhere,             
 35|   :bundling,                   
 36|   :allow-no,                   
 37|   :numeric-suffix-as-value,    
 38| ;                                                                          
 39| 
 40| multi MAIN(Bool :$pod!) is hidden-from-USAGE {                                                  
 41|     for $=pod -> $pod-item {                                               
 42|         for $pod-item.contents -> $pod-block {                             
 43|             $pod-block.raku.say;                                           
 44|         }                                                                  
 45|     }                                                                      
 46| } 
 47| 
 48| multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {                           
 49|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;                          
 50| } # end of multi MAIN(Bool :$man!)                                         

```






----
Rendered from  at 2023-07-15T00:19:20Zq
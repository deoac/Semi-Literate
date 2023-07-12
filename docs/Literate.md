# A grammar to parse a file into Pod and Code sections. 
>
## Table of Contents
[INTRODUCTION](#introduction)  
[The Grammar](#the-grammar)  
[Convenient tokens](#convenient-tokens)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The pod token](#the-pod-token)  
[NAME](#name)  
[VERSION](#version)  
[SYNOPSIS](#synopsis)  
[DESCRIPTION](#description)  
[BUGS AND LIMITATIONS](#bugs-and-limitations)  
[AUTHOR](#author)  
[LICENCE AND COPYRIGHT](#licence-and-copyright)  

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

*  ```
Every Pod6 document has to begin with C<=begin pod> and end with C<=end> pod. 
```
So let's define those tokens. We need to declare them with `my` because we need to use them in a subroutine later. #TODO explain why.





```
  5|     my token begin {^^ <.ws> \= begin <.ws> pod <rest-of-line>}
  6|     my token end   {^^ <.ws> \= end   <.ws> pod <rest-of-line>}

```




## The `pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.





```
  7|     token pod {
  8|         <begin> 
  9|             [<pod> | <plain-line>]*
 10|         <end>   
 11|     } 
 12| 
 13|     token code { <plain-line>+ }
 14| 
 15|     sub not-a-delimiter (Match $code --> Bool) {
 16|         return not $code ~~ / <begin> | <end> /;
 17|     } 
 18| 
 19|     token plain-line {
 20|         ^^ <rest-of-line>
 21|         <?{ &not-a-delimiter($/) }> 
 22|     } 
 23| 
 24| } 

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

# LICENCE AND COPYRIGHT
© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Raku itself. See [The Artistic License 2.0](https://opensource.org/licenses/Artistic-2.0).

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.





```
 25| my %*SUB-MAIN-OPTS =                                                       
 26|   :named-anywhere,             
 27|   :bundling,                   
 28|   :allow-no,                   
 29|   :numeric-suffix-as-value,    
 30| ;                                                                          
 31| 
 32| multi MAIN(Bool :$pod!) {                                                  
 33|     for $=pod -> $pod-item {                                               
 34|         for $pod-item.contents -> $pod-block {                             
 35|             $pod-block.raku.say;                                           
 36|         }                                                                  
 37|     }                                                                      
 38| } 
 39| 
 40| multi MAIN(Bool :$doc!, Str :$format = 'Text') {                           
 41|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;                          
 42| } # end of multi MAIN(Bool :$man!)                                         
 43| 
 44| multi MAIN (:$test!) {                                                     
 45|     use Test;                                                              
 46| 
 47|     my @tests = [                                                          
 48|     ];                                                                     
 49| 
 50|     for @tests {                                                           
 51|     } # end of for @tests                                                  
 52| 
 53|     my $test-pod = q:to/EOF/;
 54|     =begin pod
 55|     =TITLE Hello
 56| 
 57|     Paragraph Start
 58|     Line2
 59|     Line 3
 60| 
 61|     Line 4
 62| 
 63|     =end pod
 64| 
 65|     if True {
 66|         head1 'hello';
 67|     }
 68| 
 69|     my $a = 42;
 70| 
 71|     =begin pod
 72| 
 73|     =defn aoeu
 74| 
 75|     snthoeu
 76| 
 77|     =end pod
 78| 
 79|     EOF
 80| 
 81|     dd $test-pod;
 82| 
 83|     my $parse = Semi::Literate.parse($test-pod);
 84| 
 85|     say $parse.caps».keys;
 86|     say '------------';
 87| } # end of multi MAIN (:$test! )

```






----
Rendered from  at 2023-07-12T20:31:52Z
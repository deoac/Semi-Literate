# A grammar to parse a file into Pod and Code sections. 
>
## Table of Contents
[INTRODUCTION](#introduction)  
[The Grammar](#the-grammar)  
[Convenient tokens](#convenient-tokens)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The pod token](#the-pod-token)  
[The code token](#the-code-token)  
[The plain-line token](#the-plain-line-token)  
[Disallowing the delimiters in a plain-line.](#disallowing-the-delimiters-in-a-plain-line)  
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

> **Every Pod6 document has to begin with C&lt;=begin pod&gt; and end with C&lt;=end&gt; pod.**  


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

```




## The `code` token
The `code` sections are trivially defined. They are just one or more `plain-line`s!





```
 12|     token code { <plain-line>+ }

```




## The `plain-line` token
The `plain-line` token is, really, any line at all... 





```
 13|     token plain-line {
 14|         ^^ <rest-of-line>

```




## Disallowing the delimiters in a `plain-line`.
... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes#Regex_Boolean_condition_check).





```
 15|         <?{ &not-a-delimiter($/) }> 
 16|     } 

```




This function simply checks whether the `plain-line` match object matches either `begin` or `end`. Incidentally, this function is why we had to declare those tokens with the `my` keyword. This function wouldn't work otherwise.





```
 17|     sub not-a-delimiter (Match $code --> Bool) {
 18|         return not $code ~~ / <begin> | <end> /;
 19|     } 

```




And that concludes the grammar for separating `pod` from `code`!





```
 20| } 

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
 21| my %*SUB-MAIN-OPTS =                                                       
 22|   :named-anywhere,             
 23|   :bundling,                   
 24|   :allow-no,                   
 25|   :numeric-suffix-as-value,    
 26| ;                                                                          
 27| 
 28| multi MAIN(Bool :$pod!) {                                                  
 29|     for $=pod -> $pod-item {                                               
 30|         for $pod-item.contents -> $pod-block {                             
 31|             $pod-block.raku.say;                                           
 32|         }                                                                  
 33|     }                                                                      
 34| } 
 35| 
 36| multi MAIN(Bool :$doc!, Str :$format = 'Text') {                           
 37|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;                          
 38| } # end of multi MAIN(Bool :$man!)                                         
 39| 
 40| multi MAIN (:$test!) {                                                     
 41|     use Test;                                                              
 42| 
 43|     my @tests = [                                                          
 44|     ];                                                                     
 45| 
 46|     for @tests {                                                           
 47|     } # end of for @tests                                                  
 48| 
 49|     my $test-pod = q:to/EOF/;
 50|     =begin pod
 51|     =TITLE Hello
 52| 
 53|     Paragraph Start
 54|     Line2
 55|     Line 3
 56| 
 57|     Line 4
 58| 
 59|     =end pod
 60| 
 61|     if True {
 62|         head1 'hello';
 63|     }
 64| 
 65|     my $a = 42;
 66| 
 67|     =begin pod
 68| 
 69|     =defn aoeu
 70| 
 71|     snthoeu
 72| 
 73|     =end pod
 74| 
 75|     EOF
 76| 
 77|     dd $test-pod;
 78| 
 79|     my $parse = Semi::Literate.parse($test-pod);
 80| 
 81|     say $parse.caps».keys;
 82|     say '------------';
 83| } # end of multi MAIN (:$test! )

```






----
Rendered from  at 2023-07-12T20:49:15Z			
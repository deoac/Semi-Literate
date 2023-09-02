# A grammar to parse a file into Pod and Code sections.
>
## Table of Contents
[INTRODUCTION](#introduction)  
[Convenient tokens](#convenient-tokens)  
[The Grammar](#the-grammar)  
[The Pod6 delimiters](#the-pod6-delimiters)  
[The begin token](#the-begin-token)  
[The end token](#the-end-token)  
[The Pod token](#the-pod-token)  
[The Code token](#the-code-token)  
[Woven sections](#woven-sections)  
[Non-woven sections](#non-woven-sections)  
[One line of code](#one-line-of-code)  
[Delimited blocks of code](#delimited-blocks-of-code)  
[The plain-line token](#the-plain-line-token)  
[Disallowing the delimiters in a plain-line.](#disallowing-the-delimiters-in-a-plain-line)  
[The Tangle subroutine](#the-tangle-subroutine)  
[remove blank lines at the end](#remove-blank-lines-at-the-end)  
[The Weave subroutine](#the-weave-subroutine)  
[The parameters of Weave](#the-parameters-of-weave)  
[$input-file](#input-file)  
[$format](#format)  
[$line-numbers](#line-numbers)  
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
    1| #! /usr/bin/env raku
    2| 
    3| # Get the Pod vs. Code structure of a Raku/Pod6 file.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Sat 02 Sep 2023 04:29:38 PM EDT
    6| # Version 0.0.1
    7| 
    8| # no-weave
    9| # always use the latest version of Raku
   10| use v6.*;
   11| use PrettyDump;
   12| use Data::Dump::Tree;
   13| # end-no-weave
   14| 

```
# INTRODUCTION
I want to create a semi-literate Raku source file with the extension `.sl`. Then, I will _weave_ it to generate a readable file in formats like Markdown, PDF, HTML, and more. Additionally, I will _tangle_ it to create source code without any Pod6.

To do this, I need to divide the file into `Pod` and `Code` sections by parsing it. For this purpose, I will create a dedicated Grammar.

## Convenient tokens
Let's create two tokens for convenience.

```
   15| 
   16| #    We need to declare them with C<my> because we
   17| #    need to use them in a subroutine later. #TODO explain why.
   18| 
   19|     my token rest-of-line {    \N* [\n | $]  }
   20|     my token ws-till-EOL  {    \h* [\n | $]  }
   21|     my token blank-line   { ^^ <ws-till-EOL> }
   22| 

```
# The Grammar
Our file will exclusively consist of `Pod` or `Code` sections, and nothing else. The `TOP` token clearly indicates this.

```
   23| 
   24| #use Grammar::Tracer;
   25| grammar Semi::Literate is export {
   26|     token TOP {   [ <pod> | <code> ]* }
   27| 
   28| 

```
## The Pod6 delimiters
According to the [documentation](https://docs.raku.org/language/pod),

> **Every Pod6 document has to begin with =begin pod 1 and end with =end pod.**  


So let's define those tokens.

### The `begin` token
```
   29| 
   30|     my token begin {
   31|         ^^ \h* \= begin <.ws> pod
   32| 

```
Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a number at the end of the `=begin` directive. For example, `=begin pod 2`. [ 1 ]

```
   33| 
   34|         [ \h* $<num-blank-lines>=(\d+) ]?  # an optional number to specify the
   35|                                          # number of blank lines to replace the
   36|                                          # C<Pod> blocks when tangling.

```
The remainder of the `begin` directive can only be whitespace.

```
   37| 
   38|         <ws-till-EOL>
   39|     } # end of my token begin
   40| 

```
### The `end` token
The `end` token is much simpler.

```
   41| 
   42|     my token end { ^^ \h* \= end <.ws> pod <ws-till-EOL> }
   43| 

```
## The `Pod` token
Within the delimiters, all lines are considered documentation. We will refer to these lines as `plain-lines`. Additionally, it is possible to have nested `Pod` sections. This allows for a hierarchical organization of documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the 'zero-or-more' quantifier on the lines of documentation, allowing for the possibility of having no lines in the block.

```
   44| 
   45|     token pod {
   46|         <begin>
   47|             [<pod> | <plain-line>]*
   48|         <end>
   49|     } # end of token pod
   50| 

```
## The `Code` token
The `Code` sections are similarly easily defined. There are two types of `Code` sections, depending on whether they will appear in the woven code. See [no-weave](no-weave) for why some code would not be included in the woven code.

```
   51| 
   52|     token code {
   53|         | <woven>
   54|         | <non-woven>
   55|     } # end of token code

```
### Woven sections
These sections are trivially defined. They are just one or more `plain-line`s.

```
   56| 
   57|     token woven { <plain-line>+ }

```
### Non-woven sections
Sometimes there will be code you do not want woven into the document, such as boilerplate code like `use v6.d;`. You have two options to mark such code. By individual lines or by delimited blocks of code.

```
   58| 
   59|     token non-woven {
   60|         | <one-line-no-weave>+
   61|         | <delimited-no-weave>+
   62|     } # end of token non-woven

```
#### One line of code
Simply append `#no-weave` at the end of the line!

```
   63| 
   64|     token one-line-no-weave {
   65|         ^^ \N*
   66|         '#' <.ws> 'no-weave'
   67|         <.ws> <rest-of-line>
   68|     } # end of token one-line-no-weave
   69| 

```
#### Delimited blocks of code
Simply add comments `#no-weave` and `#end-no-weave` before and after the code you want ignored in the formatted document.

```
   70|     token delimited-no-weave {
   71|         <begin-no-weave>
   72|             <plain-line>*?
   73|         <end-no-weave>
   74|     } # end of token delimited-no-weave
   75| 
   76|     token begin-no-weave {
   77|         ^^ \h*                      # optional leading whitespace
   78|         '#' <.ws> 'no-weave'        # the delimiter itself (#no-weave)
   79|         <.ws> <rest-of-line>        # optional trailing whitespace
   80|     } # end of token <begin-no-weave>
   81| 
   82|     token end-no-weave {
   83|         ^^ \h*                      # optional leading whitespace
   84|         '#' <.ws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
   85|         <.ws> <rest-of-line>        # optional trailing whitespace
   86|     } # end of token <end--no-weave>
   87| 

```
### The `plain-line` token
The `plain-line` token is, really, any line at all...

```
   88| 
   89|     token plain-line {
   90|        $<plain-line> = [^^ <rest-of-line>]
   91| 

```
### Disallowing the delimiters in a `plain-line`.
... except for one subtlety. They it can't be one of the begin/end delimiters. We can specify that with a [Regex Boolean Condition Check](https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check).

```
   92| 
   93|         <?{ &not-a-delimiter($<plain-line>.Str) }>
   94|     } # end of token plain-line
   95| 

```
This function simply checks whether the `plain-line` match object matches either the `begin` or `end` token.

Incidentally, this function is why we had to declare those tokens with the `my` keyword. This function wouldn't work otherwise.

```
   96| 
   97|     sub not-a-delimiter (Str $line --> Bool) {
   98|         return not $line ~~ /<begin> | <end>/;
   99|     } # end of sub not-a-delimiter (Match $line --> Bool)
  100| 

```
And that concludes the grammar for separating `Pod` from `Code`!

```
  101| 
  102| } # end of grammar Semi::Literate
  103| 

```
# The Tangle subroutine
This subroutine will remove all the Pod6 code from a semi-literate file (`.sl`) and keep only the Raku code.

```
  104| 
  105| #TODO multi sub to accept Str & IO::PatGh
  106| sub tangle (
  107| 

```
The subroutine has a single parameter, which is the input filename. The filename is required. Typically, this parameter is obtained from the command line or passed from the subroutine `MAIN`.

```
  108|     Str $input-file!,

```
The subroutine will return a `Str`, which will be a working Raku program.

```
  109|         --> Str ) is export {

```
First we will get the entire Semi-Literate `.sl` file...

```
  110| 
  111|     my Str $source = $input-file.IO.slurp;
  112| 

```
Remove the _no-weave_ delimiters

```
  113| 
  114|     $source ~~ s:g{ ^^ \h* '#' <.ws>     'no-weave' <rest-of-line> } = '';
  115|     $source ~~ s:g{ ^^ \h* '#' <.ws> 'end-no-weave' <rest-of-line> } = '';
  116| 

```
Very often the `code` section of the Semi-Literate file will have blank lines that you don't want to see in the tangled working code. For example:

```
  117|                                                 # <== unwanted blank lines
  118|                                                 # <== unwanted blank lines
  119|     sub foo () {
  120|         { ... }
  121|     } # end of sub foo ()
  122|                                                 # <== unwanted blank lines
  123|                                                 # <== unwanted blank lines

```
So we'll remove the blank lines at the beginning and end of the code sections.

```
  124| 
  125|     $source ~~ s:g/\=end (\N*)\n+/\=end$0\n/;
  126|     $source ~~ s:g/\n+\=begin    /\n\=begin/;
  127| 

```
...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...

```
  128| 
  129|     my Pair @submatches = Semi::Literate.parse($source).caps;
  130| 

```
...And now begins the interesting part. We iterate through the submatches and keep only the `code` sections...

```
  131| 
  132|     my Str $raku-code = @submatches.map( {
  133|         when .key eq 'code' {
  134|             .value;
  135|         }
  136| 

```
```
#TODO rewrite
```
Most programming applications do not focus on the structure of the executable file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty lines that should replace a `pod` block. To do this, simply add a number at the end of the `=begin` directive. For example, `=begin pod 2` .

```
  137| 
  138| 
  139|         when .key eq 'pod' {
  140|             my $num-blank-lines = .value.hash<begin><num-blank-lines>;
  141|             with $num-blank-lines { "\n" x $num-blank-lines }
  142|         }
  143| 

```
#TODO

```
  144|         #no-weave
  145|         default { die 'Should never get here' }
  146|         #end-no-weave

```
... and we will join all the code sections together...

```
  147| 
  148|     } # end of my Str $raku-code = @submatches.map(
  149|     ).join;
  150| 

```
### remove blank lines at the end
```
  151| 
  152|     $raku-code ~~ s{\n  <blank-line>* $ } = '';
  153| 

```
And that's the end of the `tangle` subroutine!

```
  154|     return $raku-code;
  155| } # end of sub tangle (
  156| 

```
# The Weave subroutine
The `Weave` subroutine will _weave_ the `.sl` file into a readable Markdown, HTML, or other format. It is a little more complicated than `sub tangle` because it has to include the `code` sections.

```
  157| 
  158| sub weave (
  159| 

```
## The parameters of Weave
`sub weave` will have several parameters.

### `$input-file`
The input filename is required. Typically, this parameter is obtained from the command line through a wrapper subroutine `MAIN`.

```
  160| 
  161|     Str $input-file!;

```
### `$format`
The output of the weave can (currently) be Markdown, Text, or HTML. It defaults to Markdown. The variable is case-insensitive, so 'markdown' also works.

```
  162| 
  163|     Str :f(:$format) is copy = 'markdown';
  164|         #= The output format for the woven file.
  165| 

```
### `$line-numbers`
It can be useful to print line numbers in the code listing. It currently defaults to True.

```
  166| 
  167|     Bool :l(:$line-numbers)  = True;
  168|         #= Should line numbers be added to the embeded code?
  169| 
  170| 

```
`sub weave` returns a Str.

```
  171| 
  172|         --> Str ) is export {

```
#TODO

```
  173| 
  174|     my UInt $line-number = 1;
  175| 

```
First we will get the entire `.sl` file...

```
  176| 
  177|     my Str $source = $input-file.IO.slurp;
  178| 
  179|     my Str $cleaned-source;
  180| 
  181| $cleaned-source = $source;
  182| #=begin pod 1
  183| #
  184| #=head3 Remove full comment lines followed by blank lines
  185| #
  186| #=end pod
  187| #
  188| #    # delete full comment lines
  189| #    $source ~~ s:g{ ^^ \h* '#' \N* \n+} = '';
  190| #
  191| #    # remove Raku comments, unless the '#' is escaped with
  192| #    # a backslash or is in a quote. (It doesn't catch all quote
  193| #    # constructs...(that's a TODO))
  194| #    # And leave the newline.
  195| #
  196| #=begin pod 1
  197| #
  198| #=head3 Remove EOL comments
  199| #
  200| #=end pod
  201| #
  202| #    for $source.split("\n") -> $line {
  203| #        my $m = $line ~~ m{
  204| #                ^^
  205| #               $<stuff-before-the-comment> = ( \N*? )
  206| #
  207| #                #TODO make this more robust - allow other delimiters, take into
  208| #                #account the Q language, heredocs, nested strings...
  209| #                <!after         # make sure the '#' isn't in a string
  210| #                    ( [
  211| #                        | \\
  212| #                        | \" <-[\"]>*
  213| #                        | \' <-[\']>*
  214| #                        | \｢ <-[\｣]>*
  215| #                    ] )
  216| #                >
  217| #                "#"
  218| #
  219| #
  220| #                # We need to keep these delimiters.
  221| #                # See the section above "Remove code marked as 'no-weave'".
  222| #                <!before
  223| #                      [
  224| #                        | 'no-weave'
  225| #                        | 'end-no-weave'
  226| #                      ]
  227| #                >
  228| #                \N*
  229| #                $$ };
  230| #
  231| #        $cleaned-source ~= $m ?? $<stuff-before-the-comment> !! $line;
  232| #        $cleaned-source ~= "\n";
  233| #    } # end of for $source.split("\n") -> $line
  234| #
  235| #=begin pod 1
  236| #=head3 Remove blank lines at the begining and end of the code
  237| #
  238| #B<EXPLAIN THIS!>
  239| #
  240| #=end pod
  241| #
  242| #    $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
  243| #    $cleaned-source ~~ s:g{\n+\=begin (<.ws> pod) [<.ws> \d]?} = "\n\=begin$0";
  244| #

```
## Interesting stuff ...Next, we parse it using the `Semi::Literate` grammar and obtain a list of submatches (that's what the `caps` method does) ...
```
  245| 
  246|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;
  247| 

```
...And now begins the interesting part. We iterate through the submatches and insert the `code` sections into the Pod6...

```
  248| 
  249| 
  250|     my Str $weave = @submatches.map( {
  251|         when .key eq 'pod' {
  252|             .value
  253|         } # end of when .key

```
#TODO

```
  254| 
  255|         when .key eq 'code' { qq:to/EOCB/; }
  256|             \=begin  pod
  257|             \=begin  code :lang<raku>
  258|              { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
  259|                 .value
  260|                 .lines
  261|                 .map($line-numbers
  262|                         ?? {"%4s| %s\n".sprintf($line-number++, $_) }
  263|                         !! {     "%s\n".sprintf(                $_) }
  264|                     )
  265|                 .chomp;
  266|              }
  267|             \=end  code
  268|             \=end  pod
  269|             EOCB
  270| 
  271|         when .key eq 'non-woven' {
  272|             ; # do nothing
  273|         } # end of when .key eq 'non-woven'
  274| 
  275|         # no-weave
  276|         default { die 'Should never get here.' }
  277|         # end-no-weave
  278|     } # end of my $weave = Semi::Literate.parse($source).caps.map
  279|     ).join;
  280| 

```
remove useless Pod directives

```
  281| 
  282|     $weave ~~ s:g{ \h* \=end   <.ws> pod  <rest-of-line>
  283|                    \h* \=begin <.ws> pod <rest-of-line> } = '';
  284| 

```
### remove blank lines at the end
```
  285| 
  286|     $weave ~~ s{\n  <blank-line>* $ } = '';
  287| 

```
And that's the end of the `tangle` subroutine!

```
  288| 
  289|     return $weave
  290| } # end of sub weave (
  291| 

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
  292| 
  293| # no-weave
  294| my %*SUB-MAIN-OPTS =
  295|   :named-anywhere,             # allow named variables at any location
  296|   :bundling,                   # allow bundling of named arguments
  297| #  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  298|   :allow-no,                   # allow --no-foo as alternative to --/foo
  299|   :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
  300| ;
  301| 
  302| #| Run with option '--pod' to see all of the POD6 objects
  303| multi MAIN(Bool :$pod!) is hidden-from-USAGE {
  304|     for $=pod -> $pod-item {
  305|         for $pod-item.contents -> $pod-block {
  306|             $pod-block.raku.say;
  307|         }
  308|     }
  309| } # end of multi MAIN (:$pod)
  310| 
  311| #| Run with option '--doc' to generate a document from the POD6
  312| #| It will be rendered in Text format
  313| #| unless specified with the --format option.  e.g.
  314| #|       --doc --format=HTML
  315| multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {
  316|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
  317| } # end of multi MAIN(Bool :$man!)
  318| 
  319| my $semi-literate-file = '/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl';
  320| multi MAIN(Bool :$testt!) {
  321|     say tangle($semi-literate-file);
  322| } # end of multi MAIN(Bool :$test!)
  323| 
  324| multi MAIN(Bool :$testw!) {
  325|     say weave($semi-literate-file);
  326| } # end of multi MAIN(Bool :$test!)
  327| 
  328| #end-no-weave

```





----
###### 1
This is non-standard Pod6 and will not compile until woven!

----
Rendered from  at 2023-09-02T20:31:43Z

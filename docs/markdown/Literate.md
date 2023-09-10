# NO_TITLE
>
```
    1| #! /usr/bin/env raku
    2| 
    3| # Get the Pod vs. Code structure of a Raku/Pod6 file.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Sun 10 Sep 2023 02:21:43 PM EDT
    6| # Version 0.0.1
    7| 
    8| # begin-no-weave
    9| # always use the latest version of Raku
   10| use v6.*;
   11| use PrettyDump;
   12| use Data::Dump::Tree;
   13| #end-no-weave
   14| =begin pod
   15| =comment 1
   16| 
   17| 
   18| =TITLE A grammar to parse a file into C<Pod> and C<Code> sections.
   19| 
   20| =head1 INTRODUCTION
   21| 
   22| I want to create a semi-literate Raku source file with the extension
   23| C<.sl>. Then, I will I<weave> it to generate a readable file in formats like
   24| Markdown, PDF, HTML, and more. Additionally, I will I<tangle> it to create source
   25| code without any Pod6.
   26| 
   27| =head2 Convenient tokens
   28| 
   29| Let's create some tokens for convenience.
   30| 
   31| =end pod
   32| #TODO Put these into a Role
   33|     my token hws            {    <!ww>\h*       } # Horizontal White Space
   34|     my token leading-ws     { ^^ <hws>          } # Whitespace at start of line
   35|     my token optional-chars {    \N*?           }
   36|     my token rest-of-line   {    \N*   [\n | $] } #no-weave-this-line
   37|     my token ws-till-EOL    {    <hws> [\n | $] } #no-weave-this-line
   38|     my token blank-line     { ^^ <ws-till-EOL>  } #no-weave-this-line
   39| =begin pod
   40| =comment 2
   41| To do this, I need to divide the file into C<Pod> and C<Code> sections by parsing
   42| it. For this purpose, I will create a dedicated Grammar.
   43| 
   44| 
   45| =head1 The Grammar
   46| 
   47| =end pod
   48| #use Grammar::Tracer;
   49| grammar Semi::Literate is export {
   50| =begin pod
   51| 
   52| Our file will exclusively consist of C<Pod> or C<Code> sections, and nothing
   53| else. The C<Code> sections are of two types, a) code that is woven into the
   54| documentation, and b) code that is not woven into the documentation.  The
   55| C<TOP> token clearly indicates this.
   56| 
   57| =end pod
   58|     token TOP {
   59|         [
   60|           || <pod>
   61|           || <woven-code>
   62|           || <non-woven-code>
   63|         ]*
   64|     } # end of token TOP
   65| =begin pod
   66| =comment 1
   67| 
   68| =head2 The Pod6 delimiters
   69| 
   70| According to the L<documentation|https://docs.raku.org/language/pod>,
   71| 
   72| =begin defn
   73| 
   74|     Every Pod6 document has to begin with =begin pod and end with =end pod.
   75| =end defn
   76| So let's define those tokens.
   77| =head3 The C<begin-pod> token
   78| 
   79| =end pod
   80|     token begin-pod {
   81|         <leading-ws>
   82|         '=' begin <hws> pod
   83|         <ws-till-EOL>
   84|     } # end of token begin-pod
   85| =begin pod
   86| =comment 1
   87| 
   88| =head3 The C<end-pod> token
   89| 
   90| The C<end-pod> token is much simpler.
   91| 
   92| =end pod
   93|     token end-pod { <leading-ws> '=' end <hws> pod <ws-till-EOL> }
   94| =begin pod
   95| =comment 1
   96| 
   97| =head3 Replacing Pod6 sections with blank lines
   98| 
   99| Most programming applications do not focus on the structure of the executable
  100| file, which is not meant to be easily read by humans.  Our tangle would replace
  101| all the Pod6 blocks with a single C<\n>.  That can clump code together that is
  102| easier read if there were one or more blank lines.
  103| 
  104| However, we can provide the option for users to specify the number of empty
  105| lines that should replace a C<pod> block. To do this, simply add a Pod6 comment
  106| immediately after the C<=begin  pod> statement.  The comment can say anything
  107| you like, but must end with a digit specifying the number of blank lines with
  108| which to replace the Pod6 section.
  109| 
  110| =end pod
  111|     token num-blank-line-comment {
  112|         <leading-ws>
  113|         '=' comment
  114|         <optional-chars>
  115|         $<num-blank-lines> = (\d+)?
  116|         <ws-till-EOL>
  117|     } # end of token num-blank-line-comment
  118| =begin pod
  119| =comment 1
  120| 
  121| =head2 The C<Pod> token
  122| 
  123| Within the delimiters, all lines are considered documentation. We will refer to
  124| these lines as C<plain-lines>. Additionally, it is possible to have nested
  125| C<Pod> sections. This allows for a hierarchical organization of
  126| documentation, allowing for more structured and detailed explanations.
  127| 
  128| It is also permissible for the block to be empty. Therefore, we will use the
  129| 'zero-or-more' quantifier on the lines of documentation, allowing for the
  130| possibility of having no lines in the block.
  131| 
  132| =end pod
  133|     token pod {
  134|         <begin-pod>
  135|         <num-blank-line-comment>?
  136|             [<pod> || <plain-line>]*
  137|         <end-pod>
  138|     } # end of token pod
  139| =begin pod
  140| =comment 1
  141| 
  142| =head2 The C<Code> tokens
  143| 
  144| The C<Code> sections are similarly easily defined.  There are two types of
  145| C<Code> sections, depending on whether they will appear in the woven code. See
  146| L<below> for why some code would not be included in the woven
  147| code.
  148| 
  149| =head3 Woven sections
  150| 
  151| These sections are trivially defined.
  152| They are just one or more C<plain-line>s.
  153| 
  154| =end pod
  155|     token woven-code  {
  156|         [
  157|             || <comment> { note $/.Str }
  158|             || <plain-line>
  159|         ]+
  160|     } # end of token woven-code
  161| 
  162|     #TODO this regex is not robust.  It will tag lines with a # in a string.
  163|     regex comment {
  164|         $<x>=(<leading-ws> \N*?) # optional code
  165|         '#'                      # comment marker
  166|         <-[#]>*                  # the actual comment
  167|         <ws-till-EOL>
  168|     } # end of my regex comment
  169| =begin pod
  170| =comment 1
  171| 
  172| =head3 Non-woven sections
  173| 
  174| Sometimes there will be code you do not want woven into the document, such
  175| as boilerplate code like C<use v6.d;>.  You have two options to mark such
  176| code.  By individual lines or by delimited blocks of code.
  177| =end pod
  178|     token non-woven-code {
  179|         [
  180|           || <one-line-no-weave>
  181|           || <delimited-no-weave>
  182|         ]+
  183|     } # end of token non-woven
  184| =begin pod
  185| =comment 1
  186| 
  187| =head4 One line of code
  188| 
  189| Simply append C<# begin-no-weave> at the end of the line!
  190| 
  191| =end pod
  192|     token one-line-no-weave {
  193|         ^^ \N*?
  194|         '#' <hws> 'no-weave-this-line'
  195|         <ws-till-EOL>
  196|     } # end of token one-line-no-weave
  197| =begin pod
  198| =comment 1
  199| 
  200| 
  201| 
  202| =head4 Delimited blocks of code
  203| 
  204| Simply add comments C<# begin-no-weave> and C<#end-no-weave> before and after the
  205| code you want ignored in the formatted document.
  206| 
  207| =end pod
  208|     token begin-no-weave {
  209|         <leading-ws>                    # optional leading whitespace
  210|         '#' <hws> 'begin-no-weave'  # the delimiter itself (# begin-no-weave)
  211|         <ws-till-EOL>               # optional trailing whitespace or comment
  212|     } # end of token <begin-no-weave>
  213| 
  214|     token end-no-weave {
  215|         <leading-ws>                    # optional leading whitespace
  216|         '#' <hws> 'end-no-weave'    # the delimiter itself (#end-no-weave)
  217|         <ws-till-EOL>               # optional trailing whitespace or comment
  218|     } # end of token <end--no-weave>
  219| 
  220|     token delimited-no-weave {
  221|         <begin-no-weave>
  222|             <plain-line>*
  223|         <end-no-weave>
  224|     } # end of token delimited-no-weave
  225| 
  226|     token code-comments {
  227|             <leading-ws>
  228|             '#' <rest-of-line>
  229|         <!{ / <begin-no-weave> | <end-no-weave> / }>
  230|     } # end of token code-comments
  231| =begin pod
  232| =comment 1
  233| 
  234| =head3 The C<plain-line> token
  235| 
  236| The C<plain-line> token is, really, any line at all...
  237| ... except for one subtlety.  They it can't be one of the begin/end delimiters.
  238| We can specify that with a L<Regex Boolean Condition
  239| Check|https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check>.
  240| 
  241| 
  242| =end pod
  243|     token plain-line {
  244|         :my $*EXCEPTION = False;
  245|         [
  246|           ||  <begin-pod>         { $*EXCEPTION = True }
  247|           ||  <end-pod>           { $*EXCEPTION = True }
  248|           ||  <begin-no-weave>    { $*EXCEPTION = True }
  249|           ||  <end-no-weave>      { $*EXCEPTION = True }
  250|           ||  <one-line-no-weave> { $*EXCEPTION = True }
  251|           || $<plain-line> = [^^ <rest-of-line>]
  252|         ]
  253|         <?{ !$*EXCEPTION }>
  254|     } # end of token plain-line
  255| =begin pod
  256| =comment 1
  257| 
  258| And that concludes the grammar for separating C<Pod> from C<Code>!
  259| 
  260| =end pod
  261| } # end of grammar Semi::Literate
  262| =begin pod
  263| =comment 2
  264| 
  265| =head1 The Tangle subroutine
  266| 
  267| This subroutine will remove all the Pod6 code from a semi-literate file
  268| (C<.sl>) and keep only the Raku code.
  269| 
  270| 
  271| =end pod
  272| #TODO multi sub to accept Str & IO::PatGh
  273| sub tangle (
  274| =begin pod
  275| 
  276| The subroutine has a single parameter, which is the input filename. The
  277| filename is required.  Typically, this parameter is obtained from the command
  278| line or passed from the subroutine C<MAIN>.
  279| =end pod
  280|     Str $input-file!,
  281| =begin pod
  282| 
  283| The subroutine will return a C<Str>, which will be a working Raku program.
  284| =end pod
  285|         --> Str ) is export {
  286| =begin pod
  287| =comment 1
  288| 
  289| First we will get the entire Semi-Literate C<.sl> file...
  290| =end pod
  291|     my Str $source = $input-file.IO.slurp;
  292| =begin pod
  293| =comment 1
  294| =head2 Clean the source
  295| 
  296| =head3 Remove unnecessary blank lines
  297| 
  298| Very often the C<code> section of the Semi-Literate file will have blank lines
  299| that you don't want to see in the tangled working code.
  300| For example:
  301| 
  302| =begin code :lang<raku>
  303| 
  304|                                                 # <== unwanted blank lines
  305|                                                 # <== unwanted blank lines
  306|     sub foo () {
  307|         { ... }
  308|     } # end of sub foo ()
  309|                                                 # <== unwanted blank lines
  310|                                                 # <== unwanted blank lines
  311| 
  312| =end code
  313| =end pod
  314| =begin pod
  315| =comment 1
  316| 
  317| 
  318| So we'll remove the blank lines immediately outside the beginning and end of
  319| the Pod6 sections.
  320| =end pod
  321|     my Str $cleaned-source = $source;
  322|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
  323|     $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";
  324| =begin pod
  325| =comment 1
  326| =head2 The interesting stuff
  327| 
  328| We parse it using the C<Semi::Literate> grammar
  329| and obtain a list of submatches (that's what the C<caps> method does) ...
  330| =end pod
  331|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;
  332| =begin pod
  333| =comment 1
  334| 
  335| ...and iterate through the submatches and keep only the C<code> sections...
  336| =end pod
  337| #    note "submatches.elems: {@submatches.elems}";
  338|     my Str $raku-code = @submatches.map( {
  339| #        note .key;
  340|         when .key eq 'woven-code'|'non-woven-code' {
  341|             .value;
  342|         }
  343| =begin pod
  344| =comment 1
  345| =head3 Replace Pod6 sections with blank lines
  346| 
  347| =end pod
  348|         when .key eq 'pod' {
  349|             my $num-blank-lines =
  350|                 .value.hash<num-blank-line-comment><num-blank-lines>;
  351|             "\n" x $num-blank-lines with $num-blank-lines;
  352|         }
  353| 
  354|         # begin-no-weave
  355|         default { die "Tangle: should never get here. .key == {.key}" }
  356|         #end-no-weave
  357| =begin pod
  358| =comment 1
  359| 
  360| ... and we will join all the code sections together...
  361| =end pod
  362|     } # end of my Str $raku-code = @submatches.map(
  363|     ).join;
  364| =begin pod
  365| =comment 1
  366| =head3 Remove the I<no-weave> delimiters
  367| 
  368| =end pod
  369|     $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'begin-no-weave'     <rest-of-line> }
  370|         = '';
  371|     $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'no-weave-this-line' <rest-of-line> }
  372|         = "$0\n";
  373|     $raku-code ~~ s:g{ <leading-ws> '#' <hws> 'end-no-weave'       <rest-of-line> }
  374|         = '';
  375| =begin pod
  376| =comment 1
  377| =head3 remove blank lines at the end
  378| 
  379| =end pod
  380|     $raku-code ~~ s{\n  <blank-line>* $ } = '';
  381| =begin pod
  382| =comment 1
  383| 
  384| And that's the end of the C<tangle> subroutine!
  385| =end pod
  386|     return $raku-code;
  387| } # end of sub tangle (
  388| =begin pod
  389| =comment 2
  390| 
  391| =head1 The Weave subroutine
  392| 
  393| The C<Weave> subroutine will I<weave> the C<.sl> file into a readable Markdown,
  394| HTML, or other format.  It is a little more complicated than C<sub tangle>
  395| because it has to include the C<code> sections.
  396| 
  397| =end pod
  398| sub weave (
  399| =begin pod
  400| =comment 1
  401| =head2 The parameters of Weave
  402| 
  403| C<sub weave> will have several parameters.
  404| =head3 C<$input-file>
  405| 
  406| The input filename is required. Typically,
  407| this parameter is obtained from the command line through a wrapper subroutine
  408| C<MAIN>.
  409| 
  410| =end pod
  411|     Str $input-file!;
  412| =begin pod
  413| =comment 1
  414| =head3 C<$format>
  415| 
  416| The output of the weave can (currently) be Markdown, Text, or HTML.  It
  417| defaults to Markdown. The variable is case-insensitive, so 'markdown' also
  418| works.
  419| =end pod
  420|     Str :f(:$format) is copy = 'markdown';
  421|         #= The output format for the woven file.
  422| =begin pod
  423| =comment 1
  424| =head3 C<$line-numbers>
  425| 
  426| It can be useful to print line numbers in the code listing.  It currently
  427| defaults to True.
  428| =end pod
  429|     Bool :l(:$line-numbers)  = True;
  430|         #= Should line numbers be added to the embeded code?
  431| =begin pod
  432| C<sub weave> returns a Str.
  433| =end pod
  434|         --> Str ) is export {
  435| 
  436|     my UInt $line-number = 1;
  437| =begin pod
  438| First we will get the entire C<.sl> file...
  439| =end pod
  440|     my Str $source = $input-file.IO.slurp;
  441| =begin pod
  442| =comment 1
  443| =head3 Remove blank lines at the begining and end of the code
  444| 
  445| B<EXPLAIN THIS!>
  446| 
  447| =end pod
  448|     my Str $cleaned-source = $source;
  449|     $cleaned-source ~~ s:g{\=end (\N*)\n+} =   "\=end$0\n";
  450|     $cleaned-source ~~ s:g{\n+\=begin (<hws> pod) [<hws> \d]?} = "\n\=begin$0";
  451| =begin pod
  452| =comment 1
  453| 
  454| =head2 Interesting stuff
  455| 
  456| ...Next, we parse it using the C<Semi::Literate> grammar
  457| and obtain a list of submatches (that's what the C<caps> method does) ...
  458| =end pod
  459|     my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;
  460| =begin pod
  461| =comment 1
  462| 
  463| ...And now begins the interesting part.  We iterate through the submatches and
  464| insert the C<code> sections into the Pod6...
  465| =end pod
  466| #    note "weave submatches.elems: {@submatches.elems}";
  467| #    note "submatches keys: {@submatches».keys}";
  468|     my Str $weave = @submatches.map( {
  469|         when .key eq 'pod' {
  470|             .value
  471|         } # end of when .key
  472| 
  473|         when .key eq 'woven-code' { qq:to/EOCB/; }
  474|             \=begin pod
  475|             \=begin code :lang<raku>
  476|              { my $fmt = ($line-numbers ?? "%3s| " !! '') ~ "%s\n";
  477|                 .value
  478|                 .lines
  479|                 .map($line-numbers
  480|                         ?? {"%4s| %s\n".sprintf($line-number++, $_) }
  481|                         !! {     "%s\n".sprintf(                $_) }
  482|                     )
  483|                 .chomp # get rid of the last \n
  484|              }
  485|             \=end code
  486|             \=end pod
  487|             EOCB
  488| 
  489|         when .key eq 'non-woven-code' {
  490|           ''; # do nothing
  491|           #TODO don't insert a newline here.
  492|         } # end of when .key eq 'non-woven-code'
  493| 
  494|         # begin-no-weave
  495|         default {
  496|             die "Weave: should never get here. .key == {.key}" }
  497|         # end-no-weave
  498|     } # end of my Str $weave = @submatches.map(
  499|     ).join;
  500| =begin pod
  501| =comment 1
  502| =head3 remove blank lines at the end
  503| 
  504| =end pod
  505|     $weave ~~ s{\n  <blank-line>* $ } = '';
  506| =begin pod
  507| =comment 1
  508| 
  509| And that's the end of the C<tangle> subroutine!
  510| =end pod
  511|     return $weave
  512| } # end of sub weave (
  513| =begin pod
  514| =comment 1
  515| =head1 NAME
  516| 
  517| C<Semi::Literate> - A semi-literate way to weave and tangle Raku/Pod6 source code.
  518| =head1 VERSION
  519| 
  520| This documentation refers to C<Semi-Literate> version 0.0.1
  521| 
  522| =head1 SYNOPSIS
  523| 
  524| =begin code :lang<raku>
  525| 
  526| use Semi::Literate;
  527| # Brief but working code example(s) here showing the most common usage(s)
  528| 
  529| # This section will be as far as many users bother reading
  530| # so make it as educational and exemplary as possible.
  531| 
  532| =end code
  533| =head1 DESCRIPTION
  534| 
  535| C<Semi::Literate> is based on Daniel Sockwell's Pod::Literate module
  536| 
  537| A full description of the module and its features.
  538| May include numerous subsections (i.e. =head2, =head2, etc.)
  539| 
  540| =head1 BUGS AND LIMITATIONS
  541| 
  542| There are no known bugs in this module.
  543| Patches are welcome.
  544| 
  545| =head1 AUTHOR
  546| 
  547| Shimon Bollinger (deoac.bollinger@gmail.com)
  548| 
  549| =head1 LICENSE AND COPYRIGHT
  550| 
  551| © 2023 Shimon Bollinger. All rights reserved.
  552| 
  553| This module is free software; you can redistribute it and/or
  554| modify it under the same terms as Raku itself.
  555| See L<The Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.
  556| 
  557| This program is distributed in the hope that it will be useful,
  558| but WITHOUT ANY WARRANTY; without even the implied warranty of
  559| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  560| 
  561| =end pod
  562| # begin-no-weave
  563| my %*SUB-MAIN-OPTS =
  564|   :named-anywhere,             # allow named variables at any location
  565|   :bundling,                   # allow bundling of named arguments
  566| #  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  567|   :allow-no,                   # allow --no-foo as alternative to --/foo
  568|   :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
  569| ;
  570| 
  571| #| Run with option '--pod' to see all of the Pod6 objects
  572| multi MAIN(Bool :$pod!) is hidden-from-USAGE {
  573|     for $=pod -> $pod-item {
  574|         for $pod-item.contents -> $pod-block {
  575|             $pod-block.raku.say;
  576|         }
  577|     }
  578| } # end of multi MAIN (:$pod)
  579| 
  580| #| Run with option '--doc' to generate a document from the Pod6
  581| #| It will be rendered in Text format
  582| #| unless specified with the --format option.  e.g.
  583| #|       --doc --format=HTML
  584| multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {
  585|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
  586| } # end of multi MAIN(Bool :$man!)
  587| 
  588| my $semi-literate-file = '/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl';
  589| multi MAIN(Bool :$testt!) {
  590|     say tangle($semi-literate-file);
  591| } # end of multi MAIN(Bool :$test!)
  592| 
  593| multi MAIN(Bool :$testw!) {
  594|     say weave($semi-literate-file);
  595| } # end of multi MAIN(Bool :$test!)
  596| 
  597| #end-no-weave

```






----
Rendered from  at 2023-09-10T18:23:25Z

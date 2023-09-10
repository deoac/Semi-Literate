# NO_TITLE
>
```
    1| #! /usr/bin/env raku
    2| 
    3| # Tangle a Semi-literate file into a working Raku file.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Wed 06 Sep 2023 03:47:56 PM EDT
    6| # Version 0.0.1
    7| 
    8| # begin-no-weave
    9| # always use the latest version of Raku
   10| use v6.*;
   11| # end-no-weave
   12| 
   13| use Semi::Literate;
   14| 
   15| #| The actual program starts here.
   16| multi MAIN (
   17|     Str $input-file;
   18|     Str :o(:$output-file) = '';
   19| ) {
   20|     my Str $raku-source = tangle $input-file;
   21| 
   22|     my $output-file-handle = $output-file              ??
   23|                                 open(:w, $output-file) !!
   24|                                 $*OUT;
   25| 
   26|     $output-file-handle.spurt: $raku-source;
   27| } # end of multi MAIN ( )
   28| =begin pod
   29| 
   30| =head1 NAME
   31| 
   32| <application name> - <One line description of application's purpose>
   33| 
   34| =head1 VERSION
   35| 
   36| This documentation refers to <application name> version 0.0.1
   37| 
   38| =head1 SYNOPSIS
   39| 
   40|     # Brief working invocation example(s) here showing the most common usage(s)
   41| 
   42|     # This section will be as far as many users ever read
   43|     # so make it as educational and exemplary as possible.
   44| 
   45| =head1 REQUIRED ARGUMENTS
   46| 
   47| A complete list of every argument that must appear on the command line.
   48| when the application  is invoked, explaining what each of them does, any
   49| restrictions on where each one may appear (i.e. flags that must appear
   50| before or after filenames), and how the various arguments and options
   51| may interact (e.g. mutual exclusions, required combinations, etc.)
   52| 
   53| If all of the application's arguments are optional this section
   54| may be omitted entirely.
   55| 
   56| =head1 OPTIONS
   57| 
   58| A complete list of every available option with which the application
   59| can be invoked, explaining what each does, and listing any restrictions,
   60| or interactions.
   61| 
   62| If the application has no options this section may be omitted entirely.
   63| 
   64| =head1 DESCRIPTION
   65| 
   66| A full description of the application and its features.
   67| May include numerous subsections (i.e. =head2, =head3, etc.)
   68| 
   69| =head1 DIAGNOSTICS
   70| 
   71| A list of every error and warning message that the application can generate
   72| (even the ones that will "never happen"), with a full explanation of each
   73| problem, one or more likely causes, and any suggested remedies. If the
   74| application generates exit status codes (e.g. under Unix) then list the exit
   75| status associated with each error.
   76| 
   77| =head1 CONFIGURATION AND ENVIRONMENT
   78| 
   79| A full explanation of any configuration system(s) used by the application,
   80| including the names and locations of any configuration files, and the
   81| meaning of any environment variables or properties that can be set. These
   82| descriptions must also include details of any configuration language used
   83| 
   84| =head1 DEPENDENCIES
   85| 
   86| A list of all the other modules that this module relies upon, including any
   87| restrictions on versions, and an indication whether these required modules are
   88| part of the standard Perl distribution, part of the module's distribution,
   89| or must be installed separately.
   90| 
   91| =head1 INCOMPATIBILITIES
   92| 
   93| A list of any modules that this module cannot be used in conjunction with.
   94| This may be due to name conflicts in the interface, or competition for
   95| system or program resources, or due to internal limitations of Perl
   96| (for example, many modules that use source code filters are mutually
   97| incompatible).
   98| 
   99| =head1 BUGS AND LIMITATIONS
  100| 
  101| A list of known problems with the module, together with some indication
  102| whether they are likely to be fixed in an upcoming release.
  103| 
  104| Also a list of restrictions on the features the module does provide:
  105| data types that cannot be handled, performance issues and the circumstances
  106| in which they may arise, practical limitations on the size of data sets,
  107| special cases that are not (yet) handled, etc.
  108| 
  109| The initial template usually just has:
  110| 
  111| There are no known bugs in this module.
  112| Patches are welcome.
  113| 
  114| =head1 AUTHOR
  115| 
  116| Shimon Bollinger  (deoac.shimon@gmail.com)
  117| 
  118| =head1 LICENCE AND COPYRIGHT
  119| 
  120| © 2023 Shimon Bollinger. All rights reserved.
  121| 
  122| This module is free software; you can redistribute it and/or
  123| modify it under the same terms as Perl itself. See L<perlartistic|http://perldoc.perl.org/perlartistic.html>.
  124| 
  125| This program is distributed in the hope that it will be useful,
  126| but WITHOUT ANY WARRANTY; without even the implied warranty of
  127| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  128| 
  129| =end pod
  130| # begin-no-weave
  131| #| Run with the option '--test' to test the program
  132| multi MAIN (:$test!) {
  133|     use Test;
  134| 
  135|     my @tests = [
  136|         %{ got => '', op => 'eq', expected => '', desc => 'Example 1' },
  137|     ];
  138| 
  139|     for @tests {
  140| #        cmp-ok .<got>, .<op>, .<expected>, .<desc>;
  141|     } # end of for @tests
  142| } # end of multi MAIN (:$test!)
  143| 
  144| my %*SUB-MAIN-OPTS =
  145|   :named-anywhere,             # allow named variables at any location
  146|   :bundling,                   # allow bundling of named arguments
  147| #  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  148|   :allow-no,                   # allow --no-foo as alternative to --/foo
  149|   :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
  150| ;
  151| 
  152| #| Run with '--pod' to see all of the POD6 objects
  153| multi MAIN(Bool :$pod!) {
  154|     for $=pod -> $pod-item {
  155|         for $pod-item.contents -> $pod-block {
  156|             $pod-block.raku.say;
  157|         }
  158|     }
  159| } # end of multi MAIN (:$pod)
  160| 
  161| #| Run with '--doc' to generate a document from the POD6
  162| #| It will be rendered in Text format
  163| #| unless specified with the --format option.  e.g.
  164| #|       --format=HTML
  165| multi MAIN(Bool :$doc!, Str :$format = 'Text') {
  166|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
  167| } # end of multi MAIN(Bool :$man!)
  168| #end-no-weave
  169| 

```






----
Rendered from  at 2023-09-10T18:13:08Z

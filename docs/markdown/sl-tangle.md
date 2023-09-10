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

```




```
    8| 
    9| use Semi::Literate;
   10| 
   11| #| The actual program starts here.
   12| multi MAIN (
   13|     Str $input-file;
   14|     Str :o(:$output-file) = '';
   15| ) {
   16|     my Str $raku-source = tangle $input-file;
   17| 
   18|     my $output-file-handle = $output-file              ??
   19|                                 open(:w, $output-file) !!
   20|                                 $*OUT;
   21| 
   22|     $output-file-handle.spurt: $raku-source;
   23| } # end of multi MAIN ( )
   24| =begin pod
   25| 
   26| =head1 NAME
   27| 
   28| <application name> - <One line description of application's purpose>
   29| 
   30| =head1 VERSION
   31| 
   32| This documentation refers to <application name> version 0.0.1
   33| 
   34| =head1 SYNOPSIS
   35| 
   36|     # Brief working invocation example(s) here showing the most common usage(s)
   37| 
   38|     # This section will be as far as many users ever read
   39|     # so make it as educational and exemplary as possible.
   40| 
   41| =head1 REQUIRED ARGUMENTS
   42| 
   43| A complete list of every argument that must appear on the command line.
   44| when the application  is invoked, explaining what each of them does, any
   45| restrictions on where each one may appear (i.e. flags that must appear
   46| before or after filenames), and how the various arguments and options
   47| may interact (e.g. mutual exclusions, required combinations, etc.)
   48| 
   49| If all of the application's arguments are optional this section
   50| may be omitted entirely.
   51| 
   52| =head1 OPTIONS
   53| 
   54| A complete list of every available option with which the application
   55| can be invoked, explaining what each does, and listing any restrictions,
   56| or interactions.
   57| 
   58| If the application has no options this section may be omitted entirely.
   59| 
   60| =head1 DESCRIPTION
   61| 
   62| A full description of the application and its features.
   63| May include numerous subsections (i.e. =head2, =head3, etc.)
   64| 
   65| =head1 DIAGNOSTICS
   66| 
   67| A list of every error and warning message that the application can generate
   68| (even the ones that will "never happen"), with a full explanation of each
   69| problem, one or more likely causes, and any suggested remedies. If the
   70| application generates exit status codes (e.g. under Unix) then list the exit
   71| status associated with each error.
   72| 
   73| =head1 CONFIGURATION AND ENVIRONMENT
   74| 
   75| A full explanation of any configuration system(s) used by the application,
   76| including the names and locations of any configuration files, and the
   77| meaning of any environment variables or properties that can be set. These
   78| descriptions must also include details of any configuration language used
   79| 
   80| =head1 DEPENDENCIES
   81| 
   82| A list of all the other modules that this module relies upon, including any
   83| restrictions on versions, and an indication whether these required modules are
   84| part of the standard Perl distribution, part of the module's distribution,
   85| or must be installed separately.
   86| 
   87| =head1 INCOMPATIBILITIES
   88| 
   89| A list of any modules that this module cannot be used in conjunction with.
   90| This may be due to name conflicts in the interface, or competition for
   91| system or program resources, or due to internal limitations of Perl
   92| (for example, many modules that use source code filters are mutually
   93| incompatible).
   94| 
   95| =head1 BUGS AND LIMITATIONS
   96| 
   97| A list of known problems with the module, together with some indication
   98| whether they are likely to be fixed in an upcoming release.
   99| 
  100| Also a list of restrictions on the features the module does provide:
  101| data types that cannot be handled, performance issues and the circumstances
  102| in which they may arise, practical limitations on the size of data sets,
  103| special cases that are not (yet) handled, etc.
  104| 
  105| The initial template usually just has:
  106| 
  107| There are no known bugs in this module.
  108| Patches are welcome.
  109| 
  110| =head1 AUTHOR
  111| 
  112| Shimon Bollinger  (deoac.shimon@gmail.com)
  113| 
  114| =head1 LICENCE AND COPYRIGHT
  115| 
  116| © 2023 Shimon Bollinger. All rights reserved.
  117| 
  118| This module is free software; you can redistribute it and/or
  119| modify it under the same terms as Perl itself. See L<perlartistic|http://perldoc.perl.org/perlartistic.html>.
  120| 
  121| This program is distributed in the hope that it will be useful,
  122| but WITHOUT ANY WARRANTY; without even the implied warranty of
  123| MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  124| 
  125| =end pod

```




```
  126| 

```






----
Rendered from  at 2023-09-10T20:52:04Z

# NO_TITLE
>
## Table of Contents
[NAME](#name)  
[VERSION](#version)  
[SYNOPSIS](#synopsis)  
[REQUIRED ARGUMENTS](#required-arguments)  
[OPTIONS](#options)  
[DESCRIPTION](#description)  
[DIAGNOSTICS](#diagnostics)  
[CONFIGURATION AND ENVIRONMENT](#configuration-and-environment)  
[DEPENDENCIES](#dependencies)  
[INCOMPATIBILITIES](#incompatibilities)  
[BUGS AND LIMITATIONS](#bugs-and-limitations)  
[AUTHOR](#author)  
[LICENCE AND COPYRIGHT](#licence-and-copyright)  

----
```
    1| #! /usr/bin/env raku
    2| 
    3| # Tangle a Semi-literate file into a working Raku file.
    4| # © 2023 Shimon Bollinger. All rights reserved.
    5| # Last modified: Fri 01 Sep 2023 10:16:10 PM EDT
    6| # Version 0.0.1
    7| 
    8| # always use the latest version of Raku
    9| use v6.*;
   10| 
   11| use Semi::Literate;
   12| 
   13| #| The actual program starts here.
   14| multi MAIN (
   15|     Str $input-file;
   16|     Str :o(:$output-file) = '';
   17| ) {
   18|     my Str $raku-source = tangle $input-file;
   19| 
   20|     my $output-file-handle = $output-file              ??
   21|                                 open(:w, $output-file) !!
   22|                                 $*OUT;
   23| 
   24|     $output-file-handle.spurt: $raku-source;
   25| } # end of multi MAIN ( )
   26| 
   27| 

```
# NAME
<application name> - <One line description of application's purpose>

# VERSION
This documentation refers to <application name> version 0.0.1

# SYNOPSIS
```
# Brief working invocation example(s) here showing the most common usage(s)

# This section will be as far as many users ever read
# so make it as educational and exemplary as possible.
```
# REQUIRED ARGUMENTS
A complete list of every argument that must appear on the command line. when the application is invoked, explaining what each of them does, any restrictions on where each one may appear (i.e. flags that must appear before or after filenames), and how the various arguments and options may interact (e.g. mutual exclusions, required combinations, etc.)

If all of the application's arguments are optional this section may be omitted entirely.

# OPTIONS
A complete list of every available option with which the application can be invoked, explaining what each does, and listing any restrictions, or interactions.

If the application has no options this section may be omitted entirely.

# DESCRIPTION
A full description of the application and its features. May include numerous subsections (i.e. =head2, =head3, etc.)

# DIAGNOSTICS
A list of every error and warning message that the application can generate (even the ones that will "never happen"), with a full explanation of each problem, one or more likely causes, and any suggested remedies. If the application generates exit status codes (e.g. under Unix) then list the exit status associated with each error.

# CONFIGURATION AND ENVIRONMENT
A full explanation of any configuration system(s) used by the application, including the names and locations of any configuration files, and the meaning of any environment variables or properties that can be set. These descriptions must also include details of any configuration language used

# DEPENDENCIES
A list of all the other modules that this module relies upon, including any restrictions on versions, and an indication whether these required modules are part of the standard Perl distribution, part of the module's distribution, or must be installed separately.

# INCOMPATIBILITIES
A list of any modules that this module cannot be used in conjunction with. This may be due to name conflicts in the interface, or competition for system or program resources, or due to internal limitations of Perl (for example, many modules that use source code filters are mutually incompatible).

# BUGS AND LIMITATIONS
A list of known problems with the module, together with some indication whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide: data types that cannot be handled, performance issues and the circumstances in which they may arise, practical limitations on the size of data sets, special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module. Patches are welcome.

# AUTHOR
Shimon Bollinger (deoac.shimon@gmail.com)

# LICENCE AND COPYRIGHT
© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See [perlartistic](http://perldoc.perl.org/perlartistic.html).

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

```
   28| 
   29| #| Run with the option '--test' to test the program
   30| multi MAIN (:$test!) {
   31|     use Test;
   32| 
   33|     my @tests = [
   34|         %{ got => '', op => 'eq', expected => '', desc => 'Example 1' },
   35|     ];
   36| 
   37|     for @tests {
   38| #        cmp-ok .<got>, .<op>, .<expected>, .<desc>;
   39|     } # end of for @tests
   40| } # end of multi MAIN (:$test!)
   41| 
   42| my %*SUB-MAIN-OPTS =
   43|   :named-anywhere,             # allow named variables at any location
   44|   :bundling,                   # allow bundling of named arguments
   45| #  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
   46|   :allow-no,                   # allow --no-foo as alternative to --/foo
   47|   :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
   48| ;
   49| 
   50| #| Run with '--pod' to see all of the POD6 objects
   51| multi MAIN(Bool :$pod!) {
   52|     for $=pod -> $pod-item {
   53|         for $pod-item.contents -> $pod-block {
   54|             $pod-block.raku.say;
   55|         }
   56|     }
   57| } # end of multi MAIN (:$pod)
   58| 
   59| #| Run with '--doc' to generate a document from the POD6
   60| #| It will be rendered in Text format
   61| #| unless specified with the --format option.  e.g.
   62| #|       --format=HTML
   63| multi MAIN(Bool :$doc!, Str :$format = 'Text') {
   64|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
   65| } # end of multi MAIN(Bool :$man!)
   66| 
   67| 

```






----
Rendered from  at 2023-09-02T20:22:47Z

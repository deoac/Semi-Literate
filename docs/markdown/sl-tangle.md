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
    1| use v6.*;
    2| 
    3| use Semi::Literate;
    4| 
    5| multi MAIN (
    6|     Str $input-file;
    7|     Str :o(:$output-file) = '';
    8| ) {
    9|     my Str $raku-source = tangle $input-file;
   10| 
   11|     my $output-file-handle = $output-file              ??
   12|                                 open(:w, $output-file) !!
   13|                                 $*OUT;
   14| 
   15|     $output-file-handle.spurt: $raku-source;
   16| } 

```
# NAME
<application name> - <One line description of application's purpose>

# VERSION
This documentation refers to <application name> version 0.0.1

# SYNOPSIS
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
   17| multi MAIN (:$test!) {
   18|     use Test;
   19| 
   20|     my @tests = [
   21|         %{ got => '', op => 'eq', expected => '', desc => 'Example 1' },
   22|     ];
   23| 
   24|     for @tests {
   25|     } 
   26| } 
   27| 
   28| my %*SUB-MAIN-OPTS =
   29|   :named-anywhere,             
   30|   :bundling,                   
   31|   :allow-no,                   
   32|   :numeric-suffix-as-value,    
   33| ;
   34| 
   35| multi MAIN(Bool :$pod!) {
   36|     for $=pod -> $pod-item {
   37|         for $pod-item.contents -> $pod-block {
   38|             $pod-block.raku.say;
   39|         }
   40|     }
   41| } 
   42| 
   43| multi MAIN(Bool :$doc!, Str :$format = 'Text') {
   44|     run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
   45| } 
   46| 
   47| 
   48| 

```






----
Rendered from  at 2023-07-22T22:24:43Z

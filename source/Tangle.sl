#! /usr/bin/env raku
use v6.d;

#===============================================================================
#
#         FILE: <Tangle.sl>
#
#  DESCRIPTION: This is the semi-literate source of the Tangle module. The
#               purpose of this module is to process .sl files and generate a
#               .rakumod file that does not contain any Pod6 documentation.
#
#        NOTES:
#       AUTHOR: <Shimon Bollinger>  (<deoac.bollinger@gmail.com>)
#      VERSION: 0.0.1
#     REVISION: Last updated: Sun 22 Jan 2023 07:08:23 PM EST
#===============================================================================

use PrettyDump;
use Data::Dump::Tree;

##############################################################################
##    Example 7.1 (Recommended) from Chapter 7 of "Perl Best Practices"     ##
##     Copyright (c) O'Reilly & Associates, 2005. All Rights Reserved.      ##
##############################################################################

=begin pod

=head1 NAME

<Module::Name> - <One line description of module's purpose>


=head1 VERSION

This documentation refers to <Module::Name> version 0.0.1


=head1 SYNOPSIS

    use <Module::Name>;
    # Brief but working code example(s) here showing the most common usage(s)

    # This section will be as far as many users bother reading
    # so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.
These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module provides.
Name the section accordingly.

In an object-oriented module, this section should begin with a sentence of the
form "An object of this class represents...", to give the reader a high-level
context to help them understand the methods that are subsequently described.


=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies.
(See also  QUOTE \" " INCLUDETEXT "13_ErrorHandling" "XREF83683_Documenting_Errors_"\! Documenting Errors QUOTE \" " QUOTE " in Chapter "  in Chapter  INCLUDETEXT "13_ErrorHandling" "XREF40477__"\! 13.)


=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used.
(also see  QUOTE \" " INCLUDETEXT "19_Miscellanea" "XREF40334_Configuration_Files_"\! Configuration Files QUOTE \" " QUOTE " in Chapter "  in Chapter  INCLUDETEXT "19_Miscellanea" "XREF55683__"\! 19.)


=head1 DEPENDENCIES

A list of all the other modules that this module relies upon, including any
restrictions on versions, and an indication whether these required modules are
part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.


=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for
system or program resources, or due to internal limitations of Perl
(for example, many modules that use source code filters are mutually
incompatible).


=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication
whether they are likely to be fixed in an upcoming release.

Also a list of restrictions on the features the module does provide:
data types that cannot be handled, performance issues and the circumstances
in which they may arise, practical limitations on the size of data sets,
special cases that are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.
Please report problems to <Shimon Bollinger>  (<deoac.bollinger@gmail.com>)
Patches are welcome.

=head1 AUTHOR

<Shimon Bollinger>  (<deoac.bollinger@gmail.com>)


=head1 LICENCE AND COPYRIGHT

Copyright (c)2022 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Raku itself. See L<The Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=end pod



#! /usr/bin/env raku

# Tangle a Semi-literate file into a working Raku file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sat 16 Sep 2023 10:30:05 PM EDT
# Version 0.0.1

# begin-no-weave
# always use the latest version of Raku
use v6.*;
# end-no-weave

use Semi::Literate;

#| The actual program starts here.
multi MAIN (
    Str $input-file;
    Str :o(:$output-file) = '';
) {
    my Str $raku-source = tangle $input-file, :!verbose;

    my $output-file-handle = $output-file              ??
                                open(:w, $output-file) !!
                                $*OUT;

    $output-file-handle.spurt: $raku-source;
} # end of multi MAIN ( )


=begin pod

=head1 NAME

<application name> - <One line description of application's purpose>

=head1 VERSION

This documentation refers to <application name> version 0.0.1

=head1 SYNOPSIS

    # Brief working invocation example(s) here showing the most common usage(s)

    # This section will be as far as many users ever read
    # so make it as educational and exemplary as possible.

=head1 REQUIRED ARGUMENTS

A complete list of every argument that must appear on the command line.
when the application  is invoked, explaining what each of them does, any
restrictions on where each one may appear (i.e. flags that must appear
before or after filenames), and how the various arguments and options
may interact (e.g. mutual exclusions, required combinations, etc.)

If all of the application's arguments are optional this section
may be omitted entirely.

=head1 OPTIONS

A complete list of every available option with which the application
can be invoked, explaining what each does, and listing any restrictions,
or interactions.

If the application has no options this section may be omitted entirely.

=head1 DESCRIPTION

A full description of the application and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)

=head1 DIAGNOSTICS

A list of every error and warning message that the application can generate
(even the ones that will "never happen"), with a full explanation of each
problem, one or more likely causes, and any suggested remedies. If the
application generates exit status codes (e.g. under Unix) then list the exit
status associated with each error.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the application,
including the names and locations of any configuration files, and the
meaning of any environment variables or properties that can be set. These
descriptions must also include details of any configuration language used

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
Patches are welcome.

=head1 AUTHOR

Shimon Bollinger  (deoac.shimon@gmail.com)

=head1 LICENCE AND COPYRIGHT

© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic|http://perldoc.perl.org/perlartistic.html>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=end pod

# begin-no-weave
#| Run with the option '--test' to test the program
multi MAIN (:$test!) {
    use Test;

    my @tests = [
        %{ got => '', op => 'eq', expected => '', desc => 'Example 1' },
    ];

    for @tests {
#        cmp-ok .<got>, .<op>, .<expected>, .<desc>;
    } # end of for @tests
} # end of multi MAIN (:$test!)

my %*SUB-MAIN-OPTS =
  :named-anywhere,             # allow named variables at any location
  :bundling,                   # allow bundling of named arguments
#  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  :allow-no,                   # allow --no-foo as alternative to --/foo
  :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2
;

#| Run with '--pod' to see all of the POD6 objects
multi MAIN(Bool :$pod!) {
    for $=pod -> $pod-item {
        for $pod-item.contents -> $pod-block {
            $pod-block.raku.say;
        }
    }
} # end of multi MAIN (:$pod)

#| Run with '--doc' to generate a document from the POD6
#| It will be rendered in Text format
#| unless specified with the --format option.  e.g.
#|       --format=HTML
multi MAIN(Bool :$doc!, Str :$format = 'Text') {
    run $*EXECUTABLE, "--doc=$format", $*PROGRAM;
} # end of multi MAIN(Bool :$man!)
#end-no-weave


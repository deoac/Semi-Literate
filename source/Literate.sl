#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Tue 11 Jul 2023 11:40:45 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;


=begin pod


=TITLE A grammar to parse a file into C<Pod> and C<Code> sections. 

=INTRODUCTION

I want to create a semi-literate Raku source file with the extension
C<.sl>. Then, I will I<weave> it to generate a readable file in formats like
Markdown, PDF, HTML, and more. Additionally, I will I<tangle> it to create source
code without any Pod6.

To do this, I need to divide the file into C<Pod> and C<Code> sections by parsing
it. For this purpose, I will create a dedicated Grammar.

Our file will exclusively consist of C<Pod> or C<Code> sections, and nothing
else. The C<TOP> token clearly indicates this.

=head1 The Grammar

=end pod

use Grammar::Tracer;
grammar Semi::Literate {

    token TOP {   [ <pod> | <code> ]* }
=begin pod

Let's define a 'the rest of the line' token, for convenience.
=end pod

    token rest-of-line { <!before ^^> \N* \n? } # end of token rest-of-line

=begin pod

=head2 The Pod6 token

The C<pod> token is a bit more complex as it involves delimiters.

Pod6 lines are enclosed by C<=begin> and C<=end> markers, each followed by the same
identifier. Note that this token will also match blank lines I<between> the
delimiters.
=end pod

    token begin {^^ <.ws> \= begin <.ws> pod <.ws> <rest-of-line>}
    token end   {^^ <.ws> \= end   <.ws> pod <.ws> <rest-of-line>?}
#    token code { <after [^ | <end>]> <plain-line>+ <before [ <begin> | $ ]>}
#    token code { ^^ \N* \n?}
    token code { ^^ <.ws> <!before \=> \N* \n?}
    token plain-line { ^^ \N* \n}
    regex pod {
    <begin> 
        <plain-line>*
    <end>   
    } # end of token pod


} # end of grammar Semi::Literate



=begin pod

=head1 NAME

C<Semi::Literate> - Get the Pod vs Code structure from a Raku/Pod6 file.

=head1 VERSION

This documentation refers to C<Semi-Literate> version 0.0.1

=head1 SYNOPSIS

    use Semi::Literate;
    # Brief but working code example(s) here showing the most common usage(s) 

    # This section will be as far as many users bother reading
    # so make it as educational and exemplary as possible.

=head1 DESCRIPTION

A full description of the module and its features.
May include numerous subsections (i.e. =head2, =head3, etc.)

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.
Patches are welcome.

=head1 AUTHOR

Shimon Bollinger  (deoac.bollinger@gmail.com)

=head1 LICENCE AND COPYRIGHT

© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Raku itself. 
See L<The Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=end pod

# NO-WEAVE
my %*SUB-MAIN-OPTS =                                                       
  :named-anywhere,             # allow named variables at any location     
  :bundling,                   # allow bundling of named arguments         
#  :coerce-allomorphs-to(Str),  # coerce allomorphic arguments to given type
  :allow-no,                   # allow --no-foo as alternative to --/foo   
  :numeric-suffix-as-value,    # allow -j2 as alternative to --j=2         
;                                                                          

#| Run with option '--pod' to see all of the POD6 objects                  
multi MAIN(Bool :$pod!) {                                                  
    for $=pod -> $pod-item {                                               
        for $pod-item.contents -> $pod-block {                             
            $pod-block.raku.say;                                           
        }                                                                  
    }                                                                      
} # end of multi MAIN (:$pod)                                              

#| Run with option '--doc' to generate a document from the POD6            
#| It will be rendered in Text format                                      
#| unless specified with the --format option.  e.g.                        
#|       --doc --format=HTML                                               
multi MAIN(Bool :$doc!, Str :$format = 'Text') {                           
    run $*EXECUTABLE, "--doc=$format", $*PROGRAM;                          
} # end of multi MAIN(Bool :$man!)                                         

#| Run with the option '--test' to test the program                        
multi MAIN (:$test!) {                                                     
    use Test;                                                              
#    use Semi::Literate;

    my @tests = [                                                          
#        %{ input => ,          output => ,    text => 'Example 1' },      
    ];                                                                     

    for @tests {                                                           
#        is some-func(.<input>), .<output>, .<text>;                       
    } # end of for @tests                                                  

    my $test-pod = q:to/EOF/;
    =begin pod
    =TITLE Hello

    Paragraph Start
    Line2
    Line 3

    Line 4


    =end pod

    if True {
        # a comment
        head1 'hello';
    }

    # aoeuaoeu

    my $a = 42;

    =begin pod

    =defn aoeu

    snthoeu

    =end pod

    EOF


    dd $test-pod;
#    use Pod::Literate;
#    use Grammar::Tracer;
#    use Grammar::Debugger; 

    my $parse = Semi::Literate.parse($test-pod);
#    my $parse = Semi::Literate.parsefile('test.pod6'.IO);
#    my $parse2 = Pod::Literate.parsefile('test.pod6'.IO);

    say $parse.caps».keys;
#    $parse.caps.map( { 
#        when .key eq 'pod' { say 'Pod => ' ~ .value } 
#        when .key eq 'code' { say 'Code! => ' ~ .value } 
#        default { say 'Nuts!' ~ .key}
#    } );
    say '------------';
#    $parse2.caps.map( { 
#        when .key eq 'pod' { say 'Pod!' } 
#        when .key eq 'code' { say 'Code!' } 
#        default { say 'Nuts!' }
#    } );
#    say '------------';
} # end of multi MAIN (:$test! )

# END-NO-WEAVE

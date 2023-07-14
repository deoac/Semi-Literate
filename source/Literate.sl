#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Fri 14 Jul 2023 05:18:37 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;


=begin pod


=TITLE A grammar to parse a file into C<Pod> and C<Code> sections. 

=head1 INTRODUCTION

I want to create a semi-literate Raku source file with the extension
C<.sl>. Then, I will I<weave> it to generate a readable file in formats like
Markdown, PDF, HTML, and more. Additionally, I will I<tangle> it to create source
code without any Pod6.

To do this, I need to divide the file into C<Pod> and C<Code> sections by parsing
it. For this purpose, I will create a dedicated Grammar.

=head1 The Grammar

Our file will exclusively consist of C<Pod> or C<Code> sections, and nothing
else. The C<TOP> token clearly indicates this.

=end pod

#use Grammar::Tracer;
grammar Semi::Literate {
    token TOP {   [ <pod> | <code> ]* }

=begin pod
=head2 Convenient tokens

Let's introduce a "rest of the line" token for convenience.
=end pod

    my token rest-of-line { \h* \N* \n? } # end of token rest-of-line

=begin pod
=head2 The Pod6 delimiters

According to the L<documentation|https://docs.raku.org/language/pod>,
=begin defn
    Every Pod6 document has to begin with =begin pod and end with =end pod. 
=end defn

So let's define those tokens. We need to declare them with C<my> because we
need to use them in a subroutine later. #TODO explain why.
=end pod

    my token begin {^^ <.ws> \= begin <.ws> pod <rest-of-line>}
    my token end   {^^ <.ws> \= end   <.ws> pod <rest-of-line>}
=begin pod

=head2 The C<pod> token

Within the delimiters, all lines are considered documentation. We will refer to
these lines as C<plain-lines>. Additionally, it is possible to have nested
C<pod> sections. This allows for a hierarchical organization of
documentation, allowing for more structured and detailed explanations.

It is also permissible for the block to be empty. Therefore, we will use the
'zero-or-more' quantifier on the lines of documentation, allowing for the
possibility of having no lines in the block.
=end pod

    token pod {
        <begin>  
        [<pod> | <plain-line>]*
        <end>
    } # end of token pod

    method FAILGOAL($goal) { 
        my $cleaned = $goal.trim; 
        self.error("No closing $cleaned"); 
    } 

    method error($msg) { 
        my $parsed = self.target.substr(0, self.pos)\ .trim-trailing; 
        my $context = $parsed.substr($parsed.chars - 10 max 0) ~ '⏏' ~ self.target.substr($parsed.chars, 10);
        my $line-no = $parsed.lines.elems; 
        die "Cannot parse Pod6 block: $msg\n" ~ 
             "at line $line-no, around "                   ~ 
              $context.perl                                ~ 
             "\n(error location indicated by ⏏)\n"; 
    } 

=begin pod
=head2 The C<code> token

The C<code> sections are trivially defined.  They are just one or more
C<plain-line>s.
=end pod

    token code { <plain-line>+ }

=begin pod
=head2 The C<plain-line> token

The C<plain-line> token is, really, any line at all... 
=end pod

    token plain-line {
        $<plain-line> = [^^ <rest-of-line>]

=begin pod
=head2 Disallowing the delimiters in a C<plain-line>.

... except for one subtlety.  They it can't be one of the begin/end delimiters.
We can specify that with a L<Regex Boolean Condition
Check|https://docs.raku.org/language/regexes#Regex_Boolean_condition_check>.
=end pod

#        <!{ $<plain-line> ~~ / <begin> | <end> / }>
        <?{ &not-a-delimiter($/) }> 
    } # end of token plain-line

=begin pod
This function simply checks whether the C<plain-line> match object matches
either C<V< <begin> >> or C<V< <end> >>. Incidentally, this function is why we
had to declare those tokens with the C<my> keyword.  This function wouldn't
work otherwise.
=end pod

    sub not-a-delimiter (Match $line --> Bool) {
        return not $line.hash<plain-line> ~~ /<begin> | <end>/;
    } # end of sub not-a-delimiter (Match $line --> Bool)

=begin pod
And that concludes the grammar for separating C<pod> from C<code>!
=end pod
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
May include numerous subsections (i.e. =head2, =head2, etc.)

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
multi MAIN(Bool :$pod!) is hidden-from-USAGE {                                                  
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
multi MAIN(Bool :$doc!, Str :$format = 'Text') is hidden-from-USAGE {                           
    run $*EXECUTABLE, "--doc=$format", $*PROGRAM;                          
} # end of multi MAIN(Bool :$man!)                                         


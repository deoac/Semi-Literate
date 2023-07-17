#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Mon 17 Jul 2023 04:19:50 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;
use PrettyDump;
use Data::Dump::Tree;

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

    my token rest-of-line { \h* \N* \n? } 

=begin pod
    
=head2 The Pod6 delimiters

According to the L<documentation|https://docs.raku.org/language/pod>,

=begin defn

    Every Pod6 document has to begin with =begin pod and end with =end pod. 

=end defn

So let's define those tokens. We need to declare them with C<my> because we
need to use them in a subroutine later. #TODO explain why.

=head3 The C<begin> token

=end pod

    my token begin {
        ^^ <.ws> \= begin <.ws> pod 
=begin pod

Most programming applications do not focus on the structure of the executable
file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty
lines that should replace a C<pod> block. To do this, simply add a number at
the end of the C<=begin> directive. For example, C<=begin  pod 2> .

=end pod

        [ <.ws> $<blank-lines>=(\d+) ]?  # an optional number to specify the
                                         # number of blank lines to replace the
                                         # C<Pod> blocks when tangling.
=begin pod
The remainder of the C<begin> directive can only be whitespace.
=end pod

        <rest-of-line>
    } # end of my token begin

=begin pod

=head3 The C<end> token

The C<end> token is much simpler.

=end pod

    my token end { ^^ <.ws> \= end <.ws> pod <rest-of-line> }

=begin pod

=head2 The C<Pod> token

Within the delimiters, all lines are considered documentation. We will refer to
these lines as C<plain-lines>. Additionally, it is possible to have nested
C<Pod> sections. This allows for a hierarchical organization of
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

=begin pod

=head2 The C<Code> token

The C<Code> sections are trivially defined.  They are just one or more
C<plain-line>s.

=end pod

    token code { <plain-line>+ }

=begin pod

=head3 The C<plain-line> token

The C<plain-line> token is, really, any line at all... 

=end pod

    token plain-line {
       $<plain-line> = [^^ <rest-of-line>]

=begin pod

=head3 Disallowing the delimiters in a C<plain-line>.

... except for one subtlety.  They it can't be one of the begin/end delimiters.
We can specify that with a L<Regex Boolean Condition
Check|https://docs.raku.org/language/regexes\#Regex_Boolean_condition_check>.

=end pod

        <?{ &not-a-delimiter($<plain-line>.Str) }> 
    } # end of token plain-line

=begin pod

This function simply checks whether the C<plain-line> match object matches
either the C<<begin>> or C<<end>> token. 

Incidentally, this function is why we had to declare those tokens with the
C<my> keyword.  This function wouldn't work otherwise.

=end pod

    sub not-a-delimiter (Str $line --> Bool) {
        return not $line ~~ /<begin> | <end>/;
    } # end of sub not-a-delimiter (Match $line --> Bool)

=begin pod

And that concludes the grammar for separating C<Pod> from C<Code>!

=end pod

} # end of grammar Semi::Literate

=begin pod

=head1 The Tangle subroutine

This subroutine will remove all the Pod6 code from a semi-literate file
(C<.sl>) and keep only the Raku code.


=end pod

sub tangle ( 

=begin pod

The subroutine has a single parameter, which is the input filename. The
filename is required.  Typically, this parameter is obtained from the command
line through the wrapper subroutine C<MAIN>.    
=end pod
    IO::Path $input-file!,
=begin pod

The subroutine will return a C<Str>, which should be a working Raku program.
=end pod
    --> Str ) {
=begin pod

First we will get the entire C<.sl> file...
=end pod

    my Str $source = $input-file.slurp;

=begin pod
#TODO 
=end pod

    $source ~~ s:g/\=end (\N*)\n+/\=end$0\n/;
    $source ~~ s:g/\n+\=begin    /\n\=begin/;

=begin pod

...Next, we parse it using the C<Semi::Literate> grammar 
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse($source).caps;

=begin pod

...And now begins the interesting part.  We iterate through the submatches and
keep only the C<code> sections...
=end pod

    my Str $raku = @submatches.map( {
        when .key eq 'code' {
            .value;
        }

=begin pod
        #TODO rewrite
Most programming applications do not focus on the structure of the
executable file, which is not meant to be easily read by humans.

However, we can provide the option for users to specify the number of empty
lines that should replace a C<pod> block. To do this, simply add a number
at the end of the C<=begin> directive. For example, C<=begin  pod 2> .
=end pod


        when .key eq 'pod' { 
            my $blank-lines = .value.hash<begin><blank-lines>;
            with $blank-lines { "\n" x $blank-lines }
        }

=begin pod
#TODO 
=end pod

        default { die 'Should never get here' }
=begin pod

... and we will join all the code sections together...
=end pod

    } # end of my Str $raku = @submatches.map(
    ).join;
=begin pod

And that's the end of the C<tangle> subroutine!
=end pod

} # end of sub tangle (

=begin pod 

=head1 Weave

The C<Weave> subroutine will I<weave> the C<.sl> file into a readable Markdown,
HTML, or other format.  It is a little more complicated than C<sub tangle>
because it has to include the C<code> sections.

=head2 Necessary include files

=end pod
    #TODO 
=begin pod

=end pod

sub weave ( 

=begin pod
=head2 The parameters of Weave

C<sub weave> will have several parameters.  
=head3 C<$input-file>    

The input filename is required. Typically,
this parameter is obtained from the command line through a wrapper subroutine
C<MAIN>.
    
=end pod

    IO::Path $input-file!;
=begin pod
=head3 C<$output-format>

The output of the weave can (currently) be Markdown, Text, or HTML.  It
defaults to Markdown. The variable is case-insensitive, so 'markdown' also
works.
=end pod

    Str $output-format = 'Markdown'; # Can also be 'HTML' or 'Text'

=begin pod
=head3 C<$line-numbers>

It can be useful to print line numbers in the code listing.  It currently
defaults to True.
=end pod

    Bool $line-numbers = True;


=begin pod
C<sub weave> returns a Str.
=end pod

--> Str ) {
=begin pod
#TODO 
=end pod

    my UInt $line-number = 1;

=begin pod
First we will get the entire C<.sl> file...
=end pod

    my Str $source = $input-file.slurp;

=begin pod
#TODO 
=end pod

    $source ~~ s:g/\=end (\N*)\n+/\=end$0\n/;
    $source ~~ s:g/\n+\=begin    /\n\=begin/;
=begin pod
Remove all Raku comments
=end pod

    # delete full comment lines
    $source ~~ s:g{ ^^ \h* '#' \N* \n+} = ''; 

    # remove partial comments, unless the '#' is escaped with
    # a backslash or is in a quote. (It doesn't catch all quote
    # constructs...)
    # And leave the newline.          

    #TODO Fix this!!!
    # make a regex that matches a quoted string
    # or match # && not match in a quoted string



    my Str $cleaned-source;
    for $source.split("\n") -> $line {
        my $m = $line ~~ m{ 
                ^^ 
               $<stuff-before-the-comment> = ( \N*? )
                <!after 
                    ( [
                        | \\
                        | \" <-[\"]>* 
                        | \' <-[\']>* 
                        | \｢ <-[\｣]>*
                    ] )
                >
                "#" \N* 
                $$ };
        $cleaned-source ~= $m ?? $<stuff-before-the-comment> !! $line;    
        $cleaned-source ~= "\n";
    } # end of for $source.split("\n") -> $line
=begin pod

...Next, we parse it using the C<Semi::Literate> grammar 
and obtain a list of submatches (that's what the C<caps> method does) ...
=end pod

    my Pair @submatches = Semi::Literate.parse($cleaned-source).caps;

=begin pod

...And now begins the interesting part.  We iterate through the submatches and
insert the C<code> sections into the Pod6...
=end pod


    my $weave = @submatches.map( {
        when .key eq 'pod' {
            .value
        } # end of when .key

        when .key eq 'no-weave' {
            # don't add any thing to the weave.  
            # This is code irrelevant to the purpose of the woven document.
            ;
        }

=begin pod
#TODO 
=end pod

        when .key eq 'code' { qq:to/EOCB/; } 
            \=begin  pod          
            \=begin  code :lang<raku>

=begin pod
#TODO 
=end pod

             {.value.lines.map({ "%3s| %s\n".sprintf($line-number++, $_)}) }
            \=end  code
            \=end  pod
            EOCB

        default { die 'Should never get here.' }
    } # end of my $weave = Semi::Literate.parse($source).caps.map
    ).join;

=begin pod

#TODO Convert the POD to Markdown, etc.


=end pod


} # end of sub weave (

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

=head1 LICENSE AND COPYRIGHT

© 2023 Shimon Bollinger. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Raku itself. 
See L<The Artistic License 2.0|https://opensource.org/licenses/Artistic-2.0>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=end pod

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

my $semi-literate-file = '/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl';
multi MAIN(Bool :$testt!) {
    say tangle($semi-literate-file.IO);
} # end of multi MAIN(Bool :$test!)

multi MAIN(Bool :$testw!) {
    say weave($semi-literate-file.IO);
} # end of multi MAIN(Bool :$test!)


#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Sat 15 Jul 2023 08:53:38 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;
use PrettyDump;
use Data::Dump::Tree;




#use Grammar::Tracer;
grammar Semi::Literate {
    token TOP {   [ <pod> | <code> ]* }




    my token rest-of-line { \h* \N* \n? } 




    my token begin {
        ^^ <.ws> \= begin <.ws> pod 



        [ <.ws> $<blank-lines>=(\d+) ]?  # an optional number to specify the
                                         # number of blank lines to replace the
                                         # C<Pod> blocks when tangling.



        <rest-of-line>
    } # end of my token begin




    my token end { ^^ <.ws> \= end <.ws> pod <rest-of-line> }




    token pod {
        <begin> 
            [<pod> | <plain-line>]*
        <end>
    } # end of token pod




    token code { <plain-line>+ }




    token plain-line {
       $<plain-line> = [^^ <rest-of-line>]




        <?{ &not-a-delimiter($<plain-line>.Str) }> 
    } # end of token plain-line




    sub not-a-delimiter (Str $line --> Bool) {
        return not $line ~~ /<begin> | <end>/;
    } # end of sub not-a-delimiter (Match $line --> Bool)




} # end of grammar Semi::Literate




sub tangle ( 



    IO::Path $input-file!,


    --> Str ) {



    my Str $source = $input-file.slurp;




    $source ~~ s:g/\=end (\N*)\n+/=end$0\n/;
    $source ~~ s:g/\n+\=begin    /\n=begin/;




    my Pair @submatches = Semi::Literate.parse($source).caps;




    my Str $raku = @submatches.map( {
        when .key eq 'code' {
            .value;
        }





        when .key eq 'pod' { 
            my $blank-lines = .value.hash<begin><blank-lines>;
            with $blank-lines { "\n" x $blank-lines }
        }




        default { die 'Should never get here' }



    } # end of my Str $raku = @submatches.map(
    ).join;



} # end of sub tangle (



    #TODO 



sub weave ( 




    IO::Path $input-file!;



    Str $output-format = 'Markdown'; # Can also be 'HTML' or 'Text'




    Bool $line-numbers = True;





--> Str ) {



    my UInt $line-number = 0;




    my Str $source = $input-file.slurp;



    my Pair @submatches = Semi::Literate.parse($source).caps;





    my $weave = @submatches.map( {
        note .key;
        when .key eq 'pod' {
            .value
        } # end of when .key
        when .key eq 'code' { qq:to/EOCB/; } 
            \=begin pod          
            \=begin code :lang<raku>
                { .value }
            \=end code
            \=end pod
            EOCB

        default { die 'Should never get here.' }
    } # end of my $weave = Semi::Literate.parse($source).caps.map
    ).join;





} # end of sub weave (




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

multi MAIN(Bool :$testt!) {
    say tangle('/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl'.IO);
} # end of multi MAIN(Bool :$test!)

multi MAIN(Bool :$testw!) {
    say weave('/Users/jimbollinger/Documents/Development/raku/Projects/Semi-Literate/source/Literate.sl'.IO);
} # end of multi MAIN(Bool :$test!)


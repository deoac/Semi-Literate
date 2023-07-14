#! /usr/bin/env raku

# Get the Pod vs. Code structure of a Raku/Pod6 file.
# © 2023 Shimon Bollinger. All rights reserved.
# Last modified: Fri 14 Jul 2023 05:18:02 PM EDT
# Version 0.0.1

# always use the latest version of Raku
use v6.*;





#use Grammar::Tracer;
grammar Semi::Literate {
    token TOP {   [ <pod> | <code> ]* }




    my token rest-of-line { \h* \N* \n? } # end of token rest-of-line




    my token begin {^^ $<leading-ws>=<.ws> \= begin <.ws> pod <rest-of-line>}
    my token end   {^^ $<leading-ws> \= end   <.ws> pod <rest-of-line>}



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




    token code { <plain-line>+ }




    token plain-line {
        $<plain-line> = [^^ <rest-of-line>]




#        <!{ $<plain-line> ~~ / <begin> | <end> / }>
        <?{ &not-a-delimiter($/) }> 
    } # end of token plain-line




    sub not-a-delimiter (Match $line --> Bool) {
        return not $line.hash<plain-line> ~~ /<begin> | <end>/;
    } # end of sub not-a-delimiter (Match $line --> Bool)



} # end of grammar Semi::Literate






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


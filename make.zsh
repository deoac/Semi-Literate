pod-tangle source/Literate.sl > lib/Semi/Literate.rakumod
raku lib/Semi/Literate.rakumod --testw > deleteme.p6
raku lib/Semi/Literate.rakumod --testt > deleteme.raku
mvim -p deleteme.p6 deleteme.raku 2> /dev/null > /dev/null
raku --doc=HTML2 deleteme.p6 >deleteme.md
open deleteme.md


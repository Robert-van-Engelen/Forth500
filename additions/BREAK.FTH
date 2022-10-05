\ BREAK.FTH turn BREAK key on or off
\ ONLY WORKS WITH Forth500 v2, OTHER Forth500 VERSIONS MAY DAMAGE THE DICTIONARY!

DECIMAL

\ BREAK-ON restores instruction '0Bx064 test ($ff),8'
: BREAK-ON	( -- ) 8 [ ' (:) 11 + ] LITERAL C! ;

\ BREAK-OFF modify instruction '0Bx064 test ($ff),0' which is essentially a nop
: BREAK-OFF	( -- ) 0 [ ' (:) 11 + ] LITERAL C! ;

\ REDEFINE.FTH redefine a word with a new colon definition
\ Author: Robert van Engelen
\ Redefine a word's last colon definition with a new colon definition
\ Changes the last definition to a deferred word calling the new definition
\ Older definitions of the word before the last definition are not affected

\ Example:
\ : hello ." Hello" ;
\ : hi hello ."  world!" CR ;
\ hi
\ Hello World!
\ REDEFINE: hello ." Hi" ;
\ hi
\ Hi World!
\ REDEFINE: hello ." Hey" ;
\ hi
\ Hey World!
\ :NONAME ." Happy" ; IS hello
\ hi
\ Happy World!

\ Example (note that only a word's last definition is replaced):
\ : red ." RED" ;
\ : color red ;
\ : red ." REDDISH" ;
\ : color-ish red ;
\ REDEFINE: red ." blue" ;
\ color-ish
\ blue
\ color
\ RED
\ REDEFINE: red ." purple" ;
\ color-ish
\ purple
\ color
\ RED

: REDEFINE:     ( "name" -- )
  ' DUP COLON? OVER DEFER? OR INVERT ABORT" not redefinable" 
  $02 OVER C! 1+ ['] (DEF) OVER ! 2+ HERE SWAP !
  HERE TO LAST-XT (BODY) ;

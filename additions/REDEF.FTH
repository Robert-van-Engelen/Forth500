\ REDEF.FTH REDEF word - redefine word
\ Author: Robert van Engelen
\ Redefine the given word as a DEFER word pointing to the last dictionary entry
\ The word to redefine is case sensitive, using the wrong case will not redefine
\ A powerful and dangerous primitive: anything can be destructively redefined

\ WARNING: FORGET or MARKER should not be used to delete the new definition!!!
\          Doing so will crash Forth when the redefined word is executed!!!

\ You can replace any Forth word, with one minor exception: a CREATE word that
\ has no data.  Redefining that word will destroy the dictionary, because the
\ CREATE word is replaced with a DEFER that has its 2 byte data overwriting the
\ next entry in the dictionary.

\ REDEF is inspired by the Jupiter ACE REDEFINE primitive

\ Example:
\ : hello	." Hello" ;
\ : greeting	hello ."  world!" ;
\ : hi		." Hi" ;
\ REDEF hello		\ redefine the previous hello to execute hi
\ greeting		\ so that greeting executes hi
\ Hi world!
\ ' NOOP IS hello	\ reassign hello to execute NOOP (nothing)
\ greeting
\  world!
\ ' hello IS hello	\ never do this, this will hang hello (recover with RESET)

.( Loading REDEF...)

ANEW _REDEF_

: REDEF		( "name" -- )
  PARSE-NAME 2>R
  \ start of the dictionary search
  LAST
  BEGIN
    \ while the current dictionary link is nonzero
    ?DUP
  WHILE
    \ does the word match the specified name?
    DUP L>NAME NAME>STRING 2R@ S=
    IF
      \ point to the CFA field
      DUP L>NAME NAME>
      \ compile a 'jp' to the (DEF) address
      $02 OVER C! 1+ ['] (DEF) OVER ! 2+
      \ LAST-XT is the deferred word
      LAST-XT SWAP !
      CR ." REDEF " 2R@ TYPE
    THEN
    @
  REPEAT
  RDROP RDROP
;

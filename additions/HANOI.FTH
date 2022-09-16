\ Towers of Hanoi
\ Author: Robert van Engelen

\ Example to solve with 3 disks and waiting on key press:
\   3 TO disks
\   wait ON
\   Hanoi
\ To disable key press:
\   wait OFF
\   Hanoi

.( Loading HANOI...)

ANEW _HANOI_

8  CONSTANT max-disks
20 CONSTANT x-width
31 CONSTANT y-max

3 VALUE disks

VARIABLE wait
wait ON

: array:	( n -- )
  CREATE
    CELLS ALLOT
  DOES>		( index -- addr )
    SWAP CELLS +
;

3 array: top
3 max-disks * array: peg

: put-disk	( peg disk -- )
  OVER			\ peg disk peg
  DUP top @		\ peg disk peg top
  SWAP max-disks * +	\ peg disk index
  peg !			\ peg
  top 1 SWAP +!
;

: get-disk	( peg -- disk )
  -1 OVER top +!	\ peg
  DUP top @		\ peg top
  SWAP max-disks * +	\ index
  DUP peg @		\ peg disk
  SWAP peg OFF		\ disk
;

: move-disk     ( from to -- )
  \ get disk from the 'from' peg
  SWAP get-disk
  \ each disk makes a distinct sound
  100 MS DUP 10 * 100 + 100 BEEP
  \ place disk on the 'to' peg
  put-disk
;

: init		( -- )
  \ make sure there aren't too many disks
  disks max-disks UMIN TO disks
  \ clear tops
  0 top 3 CELLS ERASE
  \ clear pegs
  0 peg 3 max-disks * CELLS ERASE
  \ put disks on peg 0
  disks 0 DO
    0 disks I - put-disk
  LOOP
;

: x-pos		( peg -- x )
  1+ x-width *
;

: y-pos		( height -- y )
  1+ 3 * y-max SWAP -
;

: draw		( -- )
  PAGE
  \ draw a base
  0 x-pos max-disks - 0 y-pos 1+ 2 x-pos max-disks + OVER 1+ $aaaa GBOX
  \ loop over pegs
  3 0 DO
    \ draw peg I
    I x-pos 0 y-pos OVER disks y-pos 2- -1 GLINE
    \ loop over disks on peg I
    I top @ 0 ?DO
      \ disk at peg J height I
      J max-disks * I + peg @	\ disk
      \ draw a disk at peg J height I
      J x-pos OVER -		\ disk x1
      SWAP
      I y-pos			\ x1 disk y1
      SWAP
      J x-pos +			\ x1 y1 x2
      OVER 2-			\ x1 y1 x2 y2
      -1 GBOX
    LOOP
  LOOP
  wait @ IF
    27 3 AT-XY S"  press a key " PAUSE
  THEN
;

: solve		( from to temp n -- )
  1- DUP
  IF
    3 PICK ( from ) 2 PICK ( from temp ) 4 PICK ( from temp to ) 3 PICK ( from temp to n-1 ) RECURSE
    2OVER ( from to ) move-disk draw
    1 PICK ( temp ) 3 PICK ( temp to   ) 5 PICK ( temp to from ) 3 PICK ( temp to from n-1 ) RECURSE
    2DROP 2DROP
  ELSE
    2DROP ( from to ) move-disk draw
  THEN
;

: Hanoi
  init draw
  0 2 1 disks solve
;

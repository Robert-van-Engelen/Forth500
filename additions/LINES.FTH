\ LINES.FTH line drawing animation (screen saver)
\ Author: Robert van Engelen

.( Loading LINES...)

ANEW _LINES_

\ Generate random integer between 0 and 32767

2VARIABLE seed

: rand  ( -- +n ) seed 2@ 1103515245. D* 12345. D+ TUCK seed 2! 32767 AND ;

: srand ( x -- ) S>D seed 2! ;

\ Randomize by waiting for a key press

: randomize
  PAGE ." press key"
  0
  BEGIN INKEY 0= UNTIL
  BEGIN 1+ INKEY UNTIL
  srand
  PAGE
;

\ Generate random integer between 0 and n-1

: rnd           ( +n -- +n ) rand SWAP MOD ;

\ Erase (reset) and draw (set) solid graphics line

: rline         ( x1 y1 x2 y2 -- ) 1 GMODE! -1 GLINE ;

: sline         ( x1 y1 x2 y2 -- ) 0 GMODE! -1 GLINE ;

\ Convert to/from signed fixed point with 7 bit fraction part and 8 bit integer part

: >fix          ( n -- n ) 7 LSHIFT ;

: fix>          ( n -- n ) 128 / ;

\ Line object

BEGIN-STRUCTURE line
  FIELD: line.x1
  FIELD: line.y1
  FIELD: line.x2
  FIELD: line.y2
END-STRUCTURE

: line!         ( x1 y1 x2 y2 addr -- ) DUP>R line.y2 ! R@ line.x2 ! R@ line.y1 ! R> line.x1 ! ;

: line.init     ( addr -- ) >R 0 0 0 0 R> line! ;

: line.erase    ( addr -- ) DUP>R line.x1 @ R@ line.y1 @ R@ line.x2 @ R> line.y2 @ rline ;

: line.draw     ( addr -- ) DUP>R line.x1 @ R@ line.y1 @ R@ line.x2 @ R> line.y2 @ sline ;

\ Array constructor (number of elements and size of each element) see manual

: array:        ( +n +n "name" -- ; +n -- addr )
  CREATE DUP , * ALLOT
  DOES> SWAP OVER @ * + CELL+
;

\ Array of 32 lines

32 CONSTANT #LINES

#LINES line array: line-array

\ Animation velocity and position values

0 VALUE v1      0 VALUE u1
0 VALUE v2      0 VALUE u2
0 VALUE x1      0 VALUE y1
0 VALUE x2      0 VALUE y2

\ Init velocities, positions and lines

: init
  randomize
    2 >fix rnd 1 >fix + TO v1
    2 >fix rnd 1 >fix + TO u1
    2 >fix rnd 1 >fix + TO v2
    2 >fix rnd 1 >fix + TO u2
  240 >fix rnd          TO x1
   32 >fix rnd          TO y1
  240 >fix rnd          TO x2
   32 >fix rnd          TO y2
  #LINES 0 DO
    I line-array line.init
  LOOP
;

\ Animate lines

: animate
  BEGIN
    #LINES 0 DO
      v1 +TO x1
      x1 fix>   1 < IF v1 NEGATE TO v1 ELSE
      x1 fix> 238 > IF v1 NEGATE TO v1 THEN
      THEN
      u1 +TO y1
      y1 fix>   1 < IF u1 NEGATE TO u1 ELSE
      y1 fix>  30 > IF u1 NEGATE TO u1 THEN
      THEN
      v2 +TO x2
      x2 fix>   1 < IF v2 NEGATE TO v2 ELSE
      x2 fix> 238 > IF v2 NEGATE TO v2 THEN
      THEN
      u2 +TO y2
      y2 fix>   1 < IF u2 NEGATE TO u2 ELSE
      y2 fix>  30 > IF u2 NEGATE TO u2 THEN
      THEN
      I line-array line.erase
      x1 fix> y1 fix> x2 fix> y2 fix> I line-array line!
      I line-array line.draw
    LOOP
  AGAIN
;

\ Run

: lines init animate ;

lines

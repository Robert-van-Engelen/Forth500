\ GALTON.FTH Galton board simulation

.( Loading Galton...)

ANEW _GALTON_

\ Generate random integer values between 0 and 32767

2VARIABLE seed

: srand ( x -- ) S>D seed 2! ;

: rand  ( -- +n ) seed 2@ 1103515245. D* 12345. D+ TUCK seed 2! 32767 AND ;

\ Galton board

400 VALUE balls         \ number of balls to drop
100 VALUE levels        \ levels of pegs on the board
120 VALUE middle        \ starting point on the screen

: random-walk   ( xpos steps -- xpos ) 0 DO rand 1 AND 2* 1- + LOOP ;

: accumulate    ( xpos -- ) 0 BEGIN 2DUP GPOINT? 0= WHILE 1+ REPEAT 1- GPOINT ;

: drop-ball     middle levels random-walk accumulate 100 10 BEEP ;

: Galton        0 GMODE! PAGE balls 0 DO drop-ball LOOP S" done" PAUSE ;

Galton

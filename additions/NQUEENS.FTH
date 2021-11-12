\ NQUEENS.FTH n-queens calculator benchmark

ANEW _NQUEENS_

8 CONSTANT RR
0 VALUE SS
0 VALUE XX
0 VALUE YY
CREATE AA RR 1+ ALLOT

: RCLAA POSTPONE AA POSTPONE + POSTPONE C@ ; IMMEDIATE
: STOAA POSTPONE AA POSTPONE + POSTPONE C! ; IMMEDIATE

: NQCORE
  0 TO SS
  0 TO XX
  BEGIN
    1 +TO XX RR XX STOAA
    BEGIN
      1 +TO SS
      XX TO YY
      BEGIN YY 1 > WHILE
        -1 +TO YY
        XX RCLAA YY RCLAA - DUP
        0= SWAP ABS XX YY - = OR IF
          0 TO YY
          BEGIN XX RCLAA 1- DUP XX STOAA 0= WHILE
            -1 +TO XX
          REPEAT
        THEN
      REPEAT
    YY 1 = UNTIL
  RR XX = UNTIL
;

: NQUEENS
  NQCORE
  ." S=" SS .
;

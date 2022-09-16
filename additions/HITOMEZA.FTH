\ HITOMEZA.FTH
\ Author: Robert van Engelen
.( Hitomezashi patterns)
\ simple libc srand PRNG - see Forth500 manual
2VARIABLE seed
: rand seed 2@ 1103515245. D* 12345. D+ TUCK seed 2! 32767 AND ;
4     CONSTANT s
239   CONSTANT h
31    CONSTANT v
$f8f8 CONSTANT p
: hitomezashi
  PAGE
  v 1+ 0 DO
    rand 1 AND s * i h i p GLINE
  s +LOOP
  h 1+ 0 DO
    i rand 1 AND s * i v p GLINE
  s +LOOP
  0 4 AT-XY KEY DROP
;

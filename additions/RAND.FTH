\ RAND.FTH C rand() generates pseudo-random numbers between 0 and 32767
\ Author: Robert van Engelen

.( Loading RAND...)

ANEW _RAND_

2VARIABLE seed

: rand	( -- +n ) seed 2@ 1103515245. D* 12345. D+ TUCK seed 2! 32767 AND ;
: srand	( x -- ) S>D seed 2! ;

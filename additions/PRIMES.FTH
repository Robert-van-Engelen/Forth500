\ PRIMES.FTH generate prime numbers
\ Author: Dr. Robert van Engelen

ANEW _PRIMES_

.( Loading PRIMES...)

\ PRIMES GENERATOR 1
\ ------------------

\ address of temporary array

0 VALUE array

\ allocate and destroy temporary cell array to store primes found

: calloc    ( n -- ) HERE TO array 2* DUP ALLOT array SWAP ERASE ;
: destroy   ( -- ) array HERE - ALLOT ;

\ store/fetch a prime from the cell array

: prime!    ( p i -- ) 2* array + ! ;
: prime@    ( i -- p ) 2* array + @ ;

\ the primes filter

: filter    ( n -- )
  2 .
  3 DUP 0 prime!
  DUP .
  SWAP \ -- 3 n
  1 ?DO
    BEGIN
      2+ \ -- maybeprime
      I 0 ?DO
        I prime@   \ -- maybeprime prime
	2DUP DUP * \ -- maybeprime prime maybeprime prime*prime
	< IF
          DROP TRUE LEAVE \ -- maybeprime true
        ELSE
          OVER SWAP \ -- maybeprime maybeprime prime
	  MOD 0= IF
	    FALSE LEAVE \ -- maybeprime false
	  THEN
        THEN
      LOOP \ -- maybeprime isprime
    UNTIL
    DUP .
    DUP I prime!
  LOOP
  DROP ;

\ display the first n primes (n > 1)

: primes    ( n -- ) DUP calloc ['] filter CATCH destroy THROW ;

\ PRIMES GENERATOR 2
\ ------------------

\ Sieve of Eratosthenes - the real one, by marking off multiples of primes

: mark!     ( n -- ) DUP 4 RSHIFT 2* array + SWAP 15 AND 1 SWAP LSHIFT OVER @ OR SWAP ! ;

: marked    ( n -- ) DUP 4 RSHIFT 2* array + SWAP 15 AND 1 SWAP LSHIFT SWAP @ AND ;

: do-sieve  ( n -- )
  2 .
  DUP 3 ?DO
    I marked 0= IF
      I .
      DUP I DO
        I mark!
      J +LOOP
    THEN
  2 +LOOP
  DROP ;

\ display all primes up to n (n > 3)

: sieve     ( n -- ) DUP 15 + 16 / calloc ['] do-sieve CATCH destroy THROW ;

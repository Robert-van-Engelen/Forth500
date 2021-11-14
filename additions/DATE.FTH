\ DATE.FTH
\ convert day since 0-3-1 to ymd
\ public domain
\ forth-ev.de/wiki/examples:daymonthyear
\ adapted to Forth500 by Klaus Overhage

.( Loading DATE...)

ANEW _DATE_

: 0<=	0> INVERT ;
: 0>=	0< INVERT ;
: <=	> INVERT ;
: >=	< INVERT ;
: D<=	D> INVERT ;
: D>=	D< INVERT ;


: /mod3		( n1 n2 -- r q )
	DUP >R /MOD DUP 4 = IF DROP R@ + 3 THEN R>DROP ;

: D/mod3	( d1 d2 -- dr dq )
	2DUP 2>R D/MOD 2DUP 4. D= IF 2DROP 2R@ D+ 3. THEN R>DROP R>DROP ;

: day2dow	( day -- dow )  1. D+ 7. DMOD D>S ;

: weekday	( dow -- )
	CASE
		0 OF ." Sunday"    ENDOF
		1 OF ." Monday"    ENDOF
		2 OF ." Tuesday"   ENDOF
		3 OF ." Wednesday" ENDOF
		4 OF ." Thursday"  ENDOF
		5 OF ." Friday"    ENDOF
 		6 OF ." Saturday"  ENDOF
		." Unknown weekday"
	ENDCASE ;
 
\ Julian calendar
 
: j-day2ymd	( day -- y m d )
	1461 FM/MOD 4 * SWAP
	365 /mod3 rot + SWAP
	31 + 5 153 */MOD SWAP 5 / >R
	2 + DUP 12 > IF  12 - SWAP 1+ SWAP THEN
	R> 1+ ;

: (ymd2day)	( y m d -- day year/4 )
	1- -ROT
	2 - DUP 0<= IF 12 + SWAP 1- SWAP THEN
	153 5 */mod SWAP 0= >R
	31 - SWAP 4 /mod SWAP 365 * SWAP
	>R + + R> SWAP R> + 1+ SWAP ;

: j-ymd2day	( y m d -- day ) (ymd2day) 1461 M* ROT M+ ;

\ Gregorian calendar

1582 10 15 (ymd2day) 1 0 D+ 2CONSTANT gregorian.
1582 10 5 j-ymd2day 2CONSTANT gregorian

: day2ymd	( day -- y m d )
	2DUP gregorian D>= IF
		2. D- 146097. D/MOD 400. D* 2SWAP
		36524. D/mod3 100. D* 2ROT D+ D>S -ROT
		j-day2ymd 2>R + 2R>
	ELSE
		j-day2ymd
	THEN ;

: ymd2day	( y m d -- day )
	(ymd2day)		\ day year/4
	OVER 1+ OVER gregorian. D>= IF
	25 /MOD SWAP 	S>D	\ day year/100 remainder_double
	1461. D* ROT		\ day days_double1 year/100 
	4 /MOD SWAP S>D 	\ day days_double1 year/400 remainder_double
	36524. D* ROT S>D	\ day days_double1 days_double2 year/400_double
	146097. D* D+ D+ ROT M+ 2. D+
	ELSE
		1461 M* ROT M+
	THEN ;

2021 12 25 ymd2day 2DUP day2dow weekday CR
2021 11 13 ymd2day D- D.

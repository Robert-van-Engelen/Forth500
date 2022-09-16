( CALENDAR for the Jupiter Ace)
( Author: Ricardo F. Lopes - 2007)
( License: Public Domain)

( Usage: <year> <Month>   )
( Example: 2007 January   )

( Weekday calculation)
( [[month*26-54]/10 + day + [year-1900] + [year-1900]/4 - 34] MOD 7)
( SUN=0, MON=1,.. SAT=6 )  

ANEW _CALENDAR_ ( Forth500 addition )

: WEEKDAY ( year month day -- weekday )
 SWAP DUP 3 < ( Jan & Feb considered as..)
 IF           ( ..months 13 and 14 of last year)
  12 + ROT
  1- ROT ROT
 THEN             ( year day month )
 26 * 54 - 10 / + ( year days)
 SWAP 1900 -      ( days year)
 DUP 4 / + + 34 - ( days)
 7 MOD            ( weekday)
;

( Print calendar )
: CAL ( weekday days -- )
 CR ." SUN MON TUE WED THU FRI SAT" CR
 OVER 4 * SPACES   ( Position of the first day )
 1+ 1
 DO                ( Stack: weekday )
  I 9 > 2+ SPACES  ( Print tab ) ( Forth500 change because -1 is TRUE )
  I .              ( Print day )
  1+               ( Increment day )
  DUP 6 >          ( Last column? )
  IF
   XMAX@ 6 - DUP X! S" (more)" PAUSE Y@ 6 AT-CLR ( Forth500 addition )
   CR DROP 0       ( Next line )
  THEN 
 LOOP
 DROP
;

( Check if leap year )
: LEAPYEAR? ( year -- flag )
 DUP 100 MOD 0= 0=
 OVER 400 MOD 0= OR
 SWAP 4 MOD 0= AND
;

( Month definer) ( Forth500 change DEFINER MONTH -> MONTH CREATE )
: MONTH CREATE   ( month days -- )
 C, C,
DOES>  ( year -- )
 OVER LEAPYEAR?  ( Stack: year pfa leapyear? )
 OVER 1+ C@      ( Stack: year pfa leapyear? month )
 SWAP OVER       ( Stack: year pfa month leapyear? month )
 2 = AND         ( Stack: year pfa month +1? )
 ROT C@ +        ( Stack: year month days )
 ROT ROT 1       ( Stack: days year month 1 )
 WEEKDAY         ( Stack: days weekday )
 SWAP            ( Stack: weekday days )
 CAL
;

( Months)
1  31 MONTH JANUARY
2  28 MONTH FEBRUARY
3  31 MONTH MARCH
4  30 MONTH APRIL
5  31 MONTH MAY
6  30 MONTH JUNE
7  31 MONTH JULY
8  31 MONTH AUGUST
9  30 MONTH SEPTEMBER
10 31 MONTH OCTOBER
11 30 MONTH NOVEMBER
12 31 MONTH DECEMBER

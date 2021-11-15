\ FF.FTH display floating point values as proper fractions

.( Loading FF...)

ANEW _FF_

0e+0 FVALUE P
0e+0 FVALUE S
0e+0 FVALUE T
0e+0 FVALUE U
0e+0 FVALUE V
0e+0 FVALUE W
0e+0 FVALUE X
0e+0 FVALUE Y
0e+0 FVALUE Z

\ FF. displays floating point value as a fraction with the specified SET-PRECISION up to 1E-10
: FF.	( F: r -- )

  FDUP FDUP FLOOR F= IF F. EXIT THEN

       FDUP TO U TO X
  0e+0 FDUP TO V TO Y
  1e+0 FDUP TO W TO Z

  10E PRECISION 10 UMIN NEGATE S>F F** TO P

  BEGIN

    U FLOOR     TO T
    U T F-      TO U
    T Z F* V F+ TO S
    Z           TO V
    S           TO Z
    T Y F* W F+ TO S
    Y           TO W
    S           TO Y
    Z Y F/      TO T

  U F0<> WHILE
  T X F- FABS P F> WHILE

    1e+0 U F/   TO U

  REPEAT THEN

  Z F. ." / " Y F.
;

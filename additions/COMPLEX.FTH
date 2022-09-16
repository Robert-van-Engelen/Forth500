\ ANS Forth Complex Arithmetic Lexicon

\ Forth Scientific Library Algorithm #60

\ Minor modifications made to port to Forth500, Nov. 22, 2021
\ by Dr. Robert van Engelen (rve)
\ Polar coordinates are in degrees or radians depending on the current
\ angular mode

\ ------------------------------------------------------------ \
\ Original author:                                             \
\ Copyright (C) 1998 Julian V. Noble                           \
\                                                              \
\ Modifications not derived from the original:                 \
\ Copyright (C) 2002, 2003, 2005, 2008-2010 David N. Williams  \
\                                                              \
\ Version 1.0.3, revised May 6, 2011.                          \
\                                                              \
\ This library is free software; you can redistribute it       \
\ and/or modify it under the terms of the GNU Lesser General   \
\ Public License as published by the Free Software Foundation; \
\ either version 2.1 of the License, or at your option any     \
\ later version.                                               \
\                                                              \
\ This library is distributed in the hope that it will be      \
\ useful, but WITHOUT ANY WARRANTY; without even the implied   \
\ warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      \
\ PURPOSE.  See the GNU Lesser General Public License for more \
\ details.                                                     \
\                                                              \
\ You should have received a copy of the GNU Lesser General    \
\ Public License along with this library; if not, write to the \
\ Free Software Foundation, Inc., 59 Temple Place, Suite 330,  \
\ Boston, MA 02111-1307 USA.                                   \
\ ------------------------------------------------------------ \

\ Environmental dependences:
\ 1. requires FLOATING and FLOATING EXT wordsets
\ 2. assumes separate floating-point stack
\ 3. does not construct a separate complex number stack
\ 4. uses TOOLS EXT words:
\    [IF]  [THEN]  [ELSE]

\ Complex numbers x+iy are stored on the fp stack as ( f: -- x y),
\ also written as ( f: -- z ).

\ Angles are in radians.

\ Polar representation measures angles from the positive x-axis.

\ All Standard words are in uppercase, most non-Standard words
\ in lowercase.

\ Unattributed changes are by dnw.  The revision date above may
\ reflect cosmetic changes not logged here.

\ Version 1.0.3
\ 09Dec10 * Added: COMPLEX COMPLEXES COMPLEX+
\ 06May11 * Removed commented out version of ZSQRT.

\ Version 1.0.2
\ 07Nov10 * Renamed SIGNBIT as FSIGNBIT, to comply with Forth
\           IEEE-FP developments.
\ 17Nov10 * Made PRINCIPAL-ARG a value which controls the action
\           instead of the compilation of arg, log, and
\           nonintegral powers.
\         * Removed forced principal arg for FATAN2.
\         * Added NPARG, nonprincipal arg.
\ 25Nov10 * Removed .FSIGN and .FMINUS.  Added .F[BL|-] and
\           .F[+|-]I, and revised Z. and ZS. to use them.
\ 27Nov10 * Upper cased:  ZVARIABLE ZCONSTANT ZLITERAL

\ Version 1.0.1
\ 18Aug09 * Fixed FLOATING-EXT and FLOATING-STACK environmental
\           queries to guarantee an ABORT when the floating-
\           point stack is not separate.

\ Version 1.0 (Forth Scientific Library)
\ 17May09 * Added comment that IEEE special values are not
\	    explicitly mentioned.

\ Version 0.8.5
\ 20Sep08 * Renamed F-ROT as -FROT.
\         * Added ZROT, -ZROT, and ZLITERAL.
\ 21Sep08 * Eliminated redundant STATE in REAL, IMAG, and CONJG.
\         * Revised Z- to conserve signed zero.
\         * Added list of words, improved layout and comments,
\           added url's for references.
\ 22Sep08 * Removed EXIT from ZLITERAL throw phrase.
\ 11Jan09 * Replaced instance of "(f:" by "( f:" 
\ 12Mar09 * Renamed NONAME as FNONAME to avoid name clash with
\           gforth.
\         * Revised ZCONSTANT based on Anton Ertl's portable
\           definition of CONSTANT, which doesn't use DOES>.
\ 18Mar09 * Clarified comments about the ambiguity of ATAN2, and
\           replaced -1E 0E by -1E 1E to make the quadrant
\           transparent in the principal angle test.
\         * Added a disclaimer about the sign of NaN for IEEE
\           754/854 systems.

\ Version 0.8.4
\ 29Aug05 * Krishna Myneni noticed that Z and ZS. don't print
\           the sign of minus zero.  Fixed by introducing
\           SIGNBIT, which aims to emulate the IEEE 754
\           function.

\ Version 0.8.3
\  3Mar05 * Revised ZCOSH for fairly good accuracy with
\           conservation of signed zero on the real axis.
\  4Mar05 * Rewrote ZACOS to use minimal computation.
\ 24Apr05 * Renamed (-I)* as -I*.  Removed simple floating point
\           and complex constants, leaving them to the user.
\         * Added Y+ and Y-, syntactic sugar for F+ and F-.

\ Version 0.8.2
\  5Mar03 * Release with changes under 0.8.1  Passes all our
\           tests, except for a few "exotic" signed zero
\           properties.

\ Version 0.8.1
\ 21Feb03 * Rewrote PSQRT for stability on the branch cut.
\         * Added X+ and X-.  Used to make ZASINH, ZACOSH,
\           ZATANH, and ZACOTH valid on their cuts, labeled by
\           signed zero.
\         * Passed complex-test.fs on MacOS X, including signed
\           zero and branch cut tests.
\ 22Feb03 * Replaced Z. and ZS. with jvn's code for Krishna
\           Myneni's suggestion to factor out the sign of the
\           imaginary part.

\ Version 0.8.0
\ 15Dec02 * Started revision of jvn's complex.f.
\ 20Feb03 * Release.                

\ The basic modifications have been a few changes in
\ floating-point alignment and the completion of the definitions
\ of the inverse functions.

\ The definitions here coincide with Abramowitz and Stegun [1],
\ Kahan [2], and the OpenMath standard [3], which produce
\ principal branches given principal branches for square roots
\ and natural logs.  The formulas, or "principal expressions",
\ are selected from [3], with choices among equivalent, formally
\ correct possibilities based mainly on computational
\ conciseness, with a nod to numerical stability where the
\ authors mention it.  Those authors do not claim to analyze
\ numerical stability, but Kahan does, and we implement his
\ algorithms in Forth in a separate library.

\ The original Noble code uses the convention common among
\ physicists for branch cuts, with arguments between zero and
\ 2pi, especially for logs and noninteger powers.  The numerical
\ analysis community is pretty unanimous about using principal
\ branches instead.

\ Everybody seems to agree on the nontriviality of the branch
\ cuts for the inverse functions and to follow Abramowitz and
\ Stegun, who define them in terms of principal branches. 
\ In this code we include a PRINCIPAL-ARG switch to select
\ between the two common conventions for arg, log, and
\ nonintegral powers, but we use only principal arguments for
\ the inverse functions.

\ Kahan pays attention to signed zero, where available in IEEE
\ 754/854 implementations.  We address that a couple of ways in
\ this library.  One is to provide optional versions of ZSINH
\ and ZTANH which respect the sign of zero, and of ZCOSH which
\ respects it on the real axis.  The other is to write the
\ functions having branch cuts so that signed zero in the
\ appropriate x or y input produces correct values on the cuts.

\ The sign of any resultant NaN when IEEE 754/854 is present is
\ not at all controlled in this library.  It is simply whatever
\ the host system produces from the propagation of NaN's in the
\ code steps.  And different systems are allowed to produce
\ different results, because the IEEE 754/854 standard imposes
\ no interpretation of the sign of NaN.

\ The test file for this code is complex-test.fs.  Although the
\ code here does not explicitly mention any of the IEEE 754
\ floating-point values for signed zero, NaN, or infinity, with
\ the optional versions mentioned above, the words pass all
\ tests in complex-ieee-test.fs, except for signed zero in the
\ imaginary part at points of real analyticity in ZASIN and
\ ZASINH.  The more aggressive Kahan algorithms in
\ complex-kahan.fs and pfe pass those as well.

\ The word COMPLEX may be used with Forth Scientific Library
\ arrays, after loading the system-dependent fsl-util file. 
\ Here is an example of an array sufficient for 20 complex
\ numbers:

\   20 COMPLEX ARRAY a{
\   1E 0E a{ 0 } z!
\   0E 1E a{ 1 } z!

\ Modified by rve to remove unnecessary and obsolescent queries

\ s" FLOATING-EXT" environment? dup [IF] ( flag) and [THEN]
\ 0= [IF] cr .( ***Floating-point extensions not available.) cr
\ ABORT [THEN]

\ s" FLOATING-STACK" environment? dup [IF] ( maxdepth) and [THEN]
\ 0= [IF] cr .( ***Floating-point stack not separate.) cr
\ ABORT [THEN]


\ ------------------------------------------------------ WORDS

\ VALUES AND FCONSTANTS
\   PRINCIPAL-ARG
\   pi/2  2pi

\ NONSTANDARD FLOATING POINT
\   -frot  fnip  ftuck  s>f  1/f  f^2  f2*  f2/
\   fsignbit

\ LOAD AND STORE
\   COMPLEX  COMPLEXES  COMPLEX+
\   z@  z!  ZVARIABLE  ZCONSTANT  ZLITERAL

\ OUTPUT
\   .f[bl|-]  .f[+|-]i  z.  zs.

\ FLOATING POINT STACK
\   z=  zdrop  zdup  zswap  zover  znip  ztuck  zrot  -zrot 

\ ARITHMETIC
\   conjg  real  imag  cmplx
\   i*  -i*  znegate
\   z*  z*f  z/  z/f  z+  z-  x+  x-  y+  y-
\   |z|  1/z  z2*  z2/  z^2  z^3  z^4  z^n  |z|^2

\ FUNCTIONS
\   parg  nparg  pln  psqrt
\   arg  >polar  polar>
\   zsqrt  zexp  zln  z^
\   zsinh  zcosh  ztanh  zcoth
\   zsin  zcos  ztan  zcot

\ INVERSE FUNCTIONS
\   zasinh  zacosh  zatanh  zacoth
\   zasin  zacos  zatan  zacot

\ Added by rve to complete Forth500 FLOATING-EXT

ANEW _COMPLEX_

\ -------------------------------------- VALUES AND FCONSTANTS

\ The PRINCIPAL-ARG flag controls calculation with/without the
\ principal argument for ARG, >POLAR, ZSQRT, ZLN, and Z^.  The
\ inverse functions are always defined with principal arguments,
\ in accord with Abramowitz and Stegun [1], Kahan [2], and
\ OpenMath [3].

\ This value may be changed after this file is loaded.
  false VALUE PRINCIPAL-ARG     \ output  0 <= arg <  2pi
\ true  VALUE PRINCIPAL-ARG     \ output -pi < arg <= pi

DECIMAL  \ important for fp input

\ Modified by rve to remove pi/2 and 2pi and replace pi/2 with 0e+0 FACOS in
\ zacos and replace 2pi with 0e+0 FACOS FDUP F+ FDUP F+ this is required to
\ perform operations independent of the current DEG and RAD angular modes

\ 1.570796326794896619231E FCONSTANT pi/2
\ 6.283185307179586476925E FCONSTANT 2pi

\ Added by rve to complete Forth500 FLOATING-EXT
[UNDEFINED] FSINCOS [IF]
    : FSINCOS   FDUP FSIN FSWAP FCOS ;
    : FALOG     10e FSWAP F** ;
    : FCOSH     FEXP FDUP 1e FSWAP F/ F+ 2e F/ ;
    : FSINH     FEXP FDUP 1e FSWAP F/ F- 2e F/ ;
    : FTANH     FDUP F+ FEXP FDUP 1e F- FSWAP 1e F+ F/ ;
    : FACOSH    FDUP FDUP F* 1e F- FSQRT F+ FLN ;
    : FASINH    FDUP FDUP F* 1e F+ FSQRT F+ FLN ;
    : FATANH    FDUP 1e F+ FSWAP 1e FSWAP F- F/ FLN 2e F/ ;
    : FATAN2    ( F: r1 r2 -- r3 )
      FDUP F0> IF
        F/ FATAN
      ELSE FSWAP FDUP F0<> IF
        FDUP FSIGN FASIN FROT FROT F/ FATAN F-
      ELSE
        FDROP F0< S>F FACOS THEN THEN ;
    : F~        ( F: r1 r2 r3 -- ; -- flag )
      FDUP F0= IF FDROP F= EXIT THEN
      FDUP F0< IF FROT FROT FOVER FOVER F- FROT FABS FROT FABS F+ FROT FABS F* F< EXIT THEN
      FROT FROT F- FABS F< ;
    : FE.       ( F: r -- )
      HERE PRECISION 3 MAX REPRESENT DROP IF '- EMIT THEN
      1- 3 /MOD SWAP DUP 0< IF 3 + SWAP 1- SWAP THEN 1+ HERE OVER TYPE '. EMIT
      HERE OVER + SWAP PRECISION SWAP - 0 MAX TYPE 3 * 'E DBL + EMIT . ;
[THEN]

\ --------------------------------- NONSTANDARD FLOATING POINT

\ In ANS Forth 94 FATAN2 is ambiguous.  The definitions of PARG
\ and NPARG below assume it to follow one of only two known
\ conventions, -pi < arg < pi (or maybe <=), or 0 <= arg < 2pi. 
\ The two words are helpers for managing the PRINCIPAL-ARG
\ option.

-1E 1E ( f: y x) FATAN2 F0<
( arg<0)
[IF]    \ FATAN2 principal
    : parg  ( f: x y -- princ.arg )  FSWAP FATAN2 ;
    : nparg ( f: x y -- npinc.arg )
        FDUP F0< FSWAP FATAN2
        ( y<0) IF 0e+0 FACOS FDUP F+ FDUP F+ F+ THEN ;
[ELSE]  \ FATAN2 not principal arg
    : parg  ( f: x y -- princ.arg )
        FDUP F0< FSWAP FATAN2
        ( y<0) IF 2pi F- THEN ;
    : nparg ( f: x y -- nprincp.arg )  FSWAP FATAN2 ;
[THEN]

\ Modified by rve to rename [UN] to [UNDEFINED] and replace f1.0 by 1E in 1/f

\ s" [UN]" PAD C! PAD CHAR+ PAD C@ MOVE 
\ PAD FIND NIP 0= [IF]
\     \ Leave true if name is in the search order, else leave false.
\     : [UN]  ( "name" -- flag )  BL WORD FIND NIP 0= ; IMMEDIATE
\ [THEN]

\ non-Standard fp words jvn has found useful
[UNDEFINED] s>f     [IF]  : s>f    S>D  D>F  ;       [THEN]
[UNDEFINED] -frot   [IF]  : -frot  FROT  FROT  ;     [THEN]
[UNDEFINED] fnip    [IF]  : fnip   FSWAP  FDROP  ;   [THEN]
[UNDEFINED] ftuck   [IF]  : ftuck  FSWAP  FOVER  ;   [THEN]
[UNDEFINED] 1/f     [IF]  : 1/f    1E FSWAP  F/ ;    [THEN]
[UNDEFINED] f^2     [IF]  : f^2    FDUP  F*  ;       [THEN]

\ added by dnw
[UNDEFINED] f2*     [IF]  : f2*    FDUP F+  ;        [THEN]
[UNDEFINED] f2/     [IF]  : f2/    0.5E F*  ;        [THEN]

\ Modified by rve to simplify fsignbit (PC-E500 is not IEEE-754)

[UNDEFINED] fsignbit [IF]
: fsignbit  ( f: r -- s: minus? )
(
Emulate the IEEE 754 signbit function, including signed zero
when the system supports IEEE 754.  The results for +Inf, -Inf,
and NaN are undefined in this implementation when IEEE 754 is
absent, and wrong for NaN when IEEE 754 is present and the sign
bit is unity.
)
    F0< ;
\    ( f: r) FDUP 0E FDUP F~
\    ( 0E?)  IF FDROP FALSE EXIT THEN
\    ( f: r) FDUP -0E 0E F~
\    ( -0E?) IF FDROP TRUE EXIT THEN
\    ( f: r) 0E F< ;
[THEN]


\ --------------------------------------------- LOAD AND STORE

: COMPLEXES ( n -- n*/complex )           2* FLOATS ;
: COMPLEX+  ( f-addr -- f-addr+/complex ) [ 1 COMPLEXES ] LITERAL + ;
[UNDEFINED] COMPLEX [IF] 1 COMPLEXES CONSTANT COMPLEX [THEN]

\ hidden, *nonnestable* scratch storage for stuff from fp stack
  FALIGN HERE 3 COMPLEXES ALLOT VALUE fnoname

: z@  ( addr --  f: -- z)  DUP F@ FLOAT+ F@ ;
: z!  ( addr --  f: z --)  DUP FLOAT+ F! F! ;

: ZVARIABLE  ( "name" -- )  \ compile
             ( -- addr )    \ run
    FALIGN HERE [ 1 COMPLEXES ] LITERAL ALLOT CONSTANT ;

: ZLITERAL   ( f: z -- )  \ compile
             ( f: -- z )  \ run
    STATE @ 0= IF -14 THROW THEN
    FSWAP POSTPONE FLITERAL POSTPONE FLITERAL ; IMMEDIATE

: ZCONSTANT  ( "name" f: z -- )  \ compile
             ( f: -- z )         \ run
(
Based on Anton Ertl's portable definition of CONSTANT,
comp.lang.forth, "Re: Alternative DEFER strategies?", 16 Dec
2008, but avoiding the return stack.
)
  [ fnoname ] LITERAL z!
  : [ fnoname ] LITERAL z@ POSTPONE zliteral POSTPONE ; ;


\ ----------------------------------------------------- OUTPUT

: .f[bl|-]  ( f: r -- |r| )
  FDUP fsignbit FABS
  DUP INVERT BL AND   SWAP [CHAR] - AND + EMIT ;

: .f[+|-]i  ( f: r -- |r| )
  FDUP fsignbit FABS
  DUP INVERT [CHAR] + AND   SWAP [CHAR] - AND + EMIT ."  i" ;

: z.   ( f: z -- )    \ emit complex #
  FSWAP .f[bl|-] F.   .f[+|-]i F. ;

: zs.  ( f: z -- )    \ emit complex #, scientific notation
  FSWAP .f[bl|-] FS.   .f[+|-]i FS. ;


\ --------------------------------------- FLOATING POINT STACK

: zdrop  ( f: z --)       FDROP FDROP ;
: zdup   ( f: z -- z z )  FOVER FOVER ;

: zswap  ( f: z1 z2 -- z2 z1 )
    [ fnoname ] LITERAL  F!  -frot
    [ fnoname ] LITERAL  F@  -frot
;

: zover  ( f: z1 z2 -- z1 z2 z1 )
    FROT    [ fnoname FLOAT+ ]  LITERAL  F!  ( f: -- x1 x2 y2)
    FROT FDUP   [ fnoname    ]  LITERAL  F!  ( f: -- x2 y2 x1)
    -frot   [ fnoname FLOAT+ ]  LITERAL  F@  ( f: -- x1 x2 y2 y1)
    -frot   [ fnoname        ]  LITERAL  z@  ( f: -- x1 y1 x2 y2 x1 y1)
;

: znip   ( f: z1 z2 -- z2 )        zswap  zdrop ;
: ztuck  ( f: z1 z2 -- z2 z1 z2 )  zswap  zover ;

: zrot   ( f: z1 z2 z3 -- z2 z3 z1 )
    [ fnoname ]            LITERAL z!
    [ fnoname COMPLEX+ ] LITERAL z!
    [ fnoname 2 COMPLEXES + ] LITERAL z!
    [ fnoname COMPLEX+ ] LITERAL z@
    [ fnoname ]            LITERAL z@
    [ fnoname 2 COMPLEXES + ] LITERAL z@
;

: -zrot  ( f: z1 z2 z3 -- z3 z1 z2 )
    [ fnoname ]            LITERAL z!
    [ fnoname COMPLEX+ ] LITERAL z!
    [ fnoname 2 COMPLEXES + ] LITERAL z!
    [ fnoname ]            LITERAL z@
    [ fnoname 2 COMPLEXES + ] LITERAL z@
    [ fnoname COMPLEX+ ] LITERAL z@
;


\ ------------------------------------------------- ARITHMETIC

: real   ( f: x y -- x )       FDROP ;
: imag   ( f: x y -- y )       fnip  ;
: conjg  ( f: x y -- x -y )    FNEGATE ;
: cmplx  ( f: x 0 y 0 -- x y)  FDROP fnip ;  \ for use with ftran2xx.f

: znegate  ( f: x y -- -x -y )  FSWAP FNEGATE FSWAP FNEGATE ;

: z=   ( f: z1 z2 -- s: flag )  FROT F= F= AND ;
: z*f  ( f: x y a -- x*a y*a )  FROT FOVER F* -frot F*  ;
: z/f  ( f: x y a -- x/a y/a )  1/f   z*f  ;
: z+   ( f: z1 z2 -- z1+z2 )    FROT F+ -frot F+ FSWAP ;

: z-   ( f: a b x y -- a-x b-y )
(
Kahan says, to conserve signed zero, write -y+b for b-y instead
of -[y-b].
)
    FNEGATE FROT F+ -FROT F- FSWAP
;

: z*   ( f: x y u v -- x*u-y*v  x*v+y*u)
(
Uses the algorithm
    [x+iy]*[u+iv] = {[x+y]*u - y*[u+v]} + i{[x+y]*u + x*[v-u]}
requiring 3 multiplications and 5 additions.
)  
    zdup F+                         ( f: x y u v u+v)
    [ fnoname ] LITERAL  F!         ( f: x y u v)
    FOVER F-                        ( f: x y u v-u)
    [ fnoname FLOAT+ ] LITERAL F!   ( f: x y u)
    FROT FDUP                       ( f: y u x x)
    [ fnoname FLOAT+ ] LITERAL F@   ( f: y u x x v-u)
    F*
    [ fnoname FLOAT+ ] LITERAL F!   ( f: y u x)
    FROT FDUP                       ( f: u x y y)
    [ fnoname ] LITERAL F@          ( f: u x y y u+v)
    F*
    [ fnoname ] LITERAL F!          ( f: u x y)
    F+  F* FDUP                     ( f: u*[x+y] u*[x+y])
    [ fnoname ] LITERAL F@ F-       ( f: u*[x+y] x*u-y*v)
    FSWAP
    [ fnoname FLOAT+ ] LITERAL F@   ( f: x*u-y*v u*[x+y] x*[v-u])
    F+ ;                            ( f: x*u-y*v x*v+y*u)

\ to avoid unneeded calculations on the other part that could
\ raise gratuitous overflow or underflow signals and changes in
\ the sign of zero (Kahan)
: x+  ( f: x y a -- x+a y )  FROT F+ FSWAP ;
: x-  ( f: x y a -- x-a y )  FNEGATE FROT F+ FSWAP ;
: y+  ( f: x y a -- x y+a )  F+ ;
: y-  ( f: x y a -- x y-a )  F- ;

: |z|^2  ( f: z -- |z|^2 )  f^2  FSWAP  f^2  F+  ;

\ writing |z| and 1/z as shown reduces overflow probability

: |z|  ( f: x y -- |z|)
    FABS FSWAP FABS
    zdup FMAX
    FDUP F0= IF
        FDROP zdrop 0E
    ELSE
        -frot FMIN     ( f: max min)
        FOVER F/ f^2 1E F+ FSQRT F*
    THEN
;

: 1/z  ( f: z -- 1/z )
    FNEGATE zdup |z| 1/f FDUP [ fnoname ] LITERAL F!
    z*f [ fnoname ] LITERAL F@  z*f
;

: z/   ( f: z1 z2 -- z1/z2 )  1/z z* ;
: z2/  ( f: z -- z/2 )        f2/ FSWAP f2/ FSWAP ;
: z2*  ( f: z -- z*2 )        f2* FSWAP f2* FSWAP ;

: arg     ( f: x y -- arg[x+iy] )
    PRINCIPAL-ARG IF parg ELSE nparg THEN ;

: >polar  ( f: x+iy -- r theta )   zdup |z| -frot arg  ;
: polar>  ( f: r theta -- x+iy )   FSINCOS FROT z*f FSWAP  ;

:  i*  ( f: x+iy -- -y+ix)  FNEGATE FSWAP ;
: -i*  ( f: x+iy -- y-ix)   FSWAP FNEGATE ;

\ Raise z to an integer power.
: z^2  ( f: z -- z^2 )  zdup z*  ;
: z^3  ( f: z -- z^3 )  zdup z^2 z* ;
: z^4  ( f: z -- z^4 )  z^2  z^2  ;

\ Use Z^ instead for n > 50 or so.
: z^n  ( n --  f: z -- z^n )
    1E 0E zswap
    BEGIN DUP 0> WHILE
        DUP 1 AND IF ztuck z* zswap THEN z^2 2/
    REPEAT zdrop DROP
;


\ -------------------------------------------------- FUNCTIONS

: pln  ( f: z -- ln[z].prin )   zdup parg -frot |z| FLN FSWAP ;

: zln  ( f: z -- ln[|z|]+iarg[z] )
    >polar FSWAP FLN FSWAP
;

: zexp ( f: z -- exp[z] )          FSINCOS FSWAP FROT FEXP z*f ;
: z^   ( f: z1 z2 --  [z1]^[z2] )  zswap zln z* zexp ;

: psqrt  ( f: z -- sqrt[z].prin )
(
Kahan's algorithm without overflow/underflow avoidance and
without treating infinity.  But it should handle signed zero
properly.
)
    zdup [ fnoname FLOAT+ ] LITERAL ( f: y) F!
         [ fnoname ] LITERAL ( f: x) F!
    |z| [ fnoname ] LITERAL F@
        fabs f+ f2/ fsqrt               ( f: rho=sqrt[[|z|+|x|]/2])
    fdup f0=
        [ fnoname FLOAT+ ] LITERAL F@   ( f: rho y)
    0= IF ( rho<>0)
        fover f/ f2/                    ( f: rho eta=[y/rho]/2)
        [ fnoname ] LITERAL F@
        f0< IF ( x<0)
            fabs fswap                  ( f: |eta| rho)
            [ fnoname FLOAT+ ] LITERAL F@
            FDUP F0<   -0e 0e F~ OR
            IF ( y<0) FNEGATE THEN      ( f: |eta| |rho|*sgn[y])
        THEN
    THEN ;

: zsqrt  ( f: z -- sqrt[z] | a b )
  PRINCIPAL-ARG
  IF     ( f: z -- sqrt[z] )  psqrt     \ imag cut
  ELSE   ( f: x y -- a b )              \ (a+ib)^2 = x+iy, real cut
    zdup                                ( f: -- z z)
    |z|^2                               ( f: -- z |z|^2)
    FDUP  F0=   IF   FDROP EXIT  THEN   ( f: -- z=0)
    FSQRT FROT  FROT  F0<               ( f: -- |z| x)  ( -- sgn[y])
    ftuck                               ( f: -- x |z| x)
    F-  f2/                             ( f: -- x [|z|-x]/2)
    ftuck  F+                           ( f: -- [|z|-x]/2 [|z|+x]/2)
    FSQRT  IF  FNEGATE  THEN            ( f: -- [|z|-x]/2  a)
    FSWAP  FSQRT                        ( f: -- a b)
  THEN
;

\ Trigonometric and hyperbolic functions

\ All stack patterns are ( f: z -- func[z] ).

0 [IF]
: zsinh    zexp zdup 1/z z-z2/ ;
[ELSE]
\ This version is reasonably accurate and preserves
\ signed zero.
: zsinh
    FSINCOS [ fnoname ] LITERAL ( f: cos[y]) F!
        [ fnoname FLOAT+ ] LITERAL ( f: sin[y]) F!
    FDUP FSINH [ fnoname ] LITERAL F@ F*  ( f: x sh[x]cos[y])
    FSWAP FCOSH
        [ fnoname FLOAT+ ] LITERAL F@ F*  ( f: sh[x]cos[y] ch[x]sin[y])
;
[THEN]

0 [IF]
: zcosh    zexp zdup 1/z z+ z2/ ;
[ELSE]
\ This version is reasonably accurate and preserves 
\ signed zero on the real axis.
: zcosh
    FSINCOS [ fnoname ]    LITERAL ( f: cos[y]) F!
        [ fnoname FLOAT+ ] LITERAL ( f: sin[y]) F!
    FDUP FCOSH [ fnoname ] LITERAL F@ F*  ( f: x ch[x]cos[y])
    FSWAP FSINH
        [ fnoname FLOAT+ ] LITERAL F@ F*  ( f: ch[x]cos[y] sh[x]sin[y])
;
[THEN]

0 [IF]
: ztanh    zexp z^2 i* zdup 1E F- zswap 1E F+ z/ ;
[ELSE]  \ This version, based on Kahan, preserves signed zero.
: ztanh
(
            [1 + tan^2[y]] cosh[x] sinh[x] + i tan[y]
  tanh[z] = -----------------------------------------
                 1 + [1 + tan^2[y]] sinh^2[x]
)
    FTAN FDUP f^2 1E F+                 ( f: x t=tan[y] b=1+t^2)
        [ fnoname ] LITERAL F!
    FSWAP FDUP FSINH                    ( f: t x sh[x])
        [ fnoname FLOAT+ ] LITERAL F!
    FCOSH
        [ fnoname FLOAT+ ] LITERAL F@   ( f: t ch[x] sh[x])
    F* [ fnoname ] LITERAL F@ F* FSWAP  ( f: c=ch[x]sh[x]b t)
    [ fnoname ] LITERAL F@
        [ fnoname FLOAT+ ] LITERAL F@
        f^2 F* 1E F+                    ( f: c t 1+b*sh^2[x])
    z/f ;
[THEN]

: zcoth    ztanh 1/z ;

: zsin     i* zsinh -i* ;
: zcos     i* zcosh ;
: ztan     i* ztanh -i* ;
: zcot     i* zcoth  i* ;


\ ------------------------------------------ INVERSE FUNCTIONS

\ In the following, we use phrases like "1E x+" instead of
\ "1E 0E z+", for stability on branch cuts involving signed
\ zero.  This follows a suggestion by Kahan [2], and it actually
\ makes a difference in every one of the functions.

: zasinh   ( f: z -- ln[z+sqrt[[z+i][z-i]] )
(
This is more stable for signed zero than the version with z^2+1.
)
    zdup 1E F+   zover 1E F-   z* psqrt z+ pln
;

: zacosh   ( f: z -- 2ln[sqrt[[z+1]/2]+sqrt[[z-1]/2] )
    zdup  1E x- z2/ psqrt
    zswap 1E x+ z2/ psqrt
    z+ pln z2*
;

: zatanh   ( f: z -- [ln[1+z]-ln[1-z]]/2 )
    zdup  1E x+ pln
    zswap 1E x- znegate pln
    z- z2/
;

: zacoth  ( f: z -- [ln[-1-z]-ln[1-z]]/2 )
    znegate zdup 1E x- pln
    zswap 1E x+ pln
    z- z2/
;

: zasin  ( f: z -- -iln[iz+sqrt[1-z^2]] )    i* zasinh -i* ;
: zacos  ( f: z -- pi/2-asin[z] )            zasin znegate 0e+0 FACOS x+ ;
: zatan  ( f: z -- [ln[1+iz]-ln[1-iz]]/2i )  i* zatanh -i* ;
: zacot  ( f: z -- [ln[[z+i]/[z-i]]/2i )    -i* zacoth -i* ;


\ ------------------------------------------------- REFERENCES
(
1. M. Abramowitz and I. Stegun, Handbook of Mathematical
   Functions with Formulas, Graphs, and Mathematical Tables, US
   Government Printing Office, 10th Printing December 1972,
   Secs. 4.4, 4.6.

   http://www.convertit.com/Go/ConvertIt/Reference/AMS55.ASP

2. William Kahan, "Branch cuts for complex elementary
   functions", The State of the Art in Numerical Analysis, A.
   Iserles and M.J.D. Powell, eds., Clarendon Press, Oxford,
   1987, pp. 165-211.

   http://www.cims.nyu.edu/~dbindel/class/cs279/slits02.pdf
   http://www.cims.nyu.edu/~dbindel/class/cs279/slits34.pdf
   http://www.cims.nyu.edu/~dbindel/class/cs279/slits56.pdf

3. Robert M. Corless, James H. Davenport, David J. Jeffrey,
   Stephen M. Watt, "'According to Abramowitz and Stegun' or
   arcoth needn't be uncouth", ACM SIGSAM Bulletin, June, 2000,
   pp. 58-65.

   http://portal.acm.org/citation.cfm?doid=362001.362023
   http://www.apmaths.uwo.ca/~djeffrey/Offprints/couth.pdf
)

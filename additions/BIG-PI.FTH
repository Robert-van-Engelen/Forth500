\ BIG-PI.FTH output first n digits of pi, for up to 9864 digits
\ Original K&R C version by Dik T. Winter, CWI Amsterdam
\   uint64_t a=10000,b,c,d,e,*f,g; // 64 bit for up to 54935 digits of pi
\   main(){printf("digits?");scanf("%llu",&c);c*=3.5;c-=c%14;f=malloc(sizeof(*f)*(c+1));
\   for(;b-c;)f[b++]=a/5;for(;d=0,g=c*2;c-=14,printf("%.4llu",e+d/a),e=d%a)
\   for(b=c;d+=f[b]*a,f[b]=d%--g,d/=g--,--b;d*=b);}
\ Translated to FORTH by Robert van Engelen

\ Example (takes one minute to compute)
\ 152 big-pi
\ 3141592653589793238462643383279502884197
\ 1693993751058209749445923078164062862089
\ 9862803482534211706798214808651328230664
\ 70938446095505822317253594081284 OK[0]

.( Loading BIG-PI...)

ANEW _BIG_PI_

DECIMAL

0 VALUE b       0 VALUE c
0 VALUE e       0 VALUE g
0. 2VALUE d     

\ array f located at HERE + 40 bytes (hold area)
: f!    CELLS HERE + 40 + ! ;
: f@    CELLS HERE + 40 + @ ;

: big-pi    ( +n -- )
  DUP 4 < ABORT" too small"
  \ c=7*n/2; c-=c%14
  7 UM* D2/ D>S DUP 14 MOD - TO c
  \ check for sufficient space to store array f
  c UNUSED 40 - 1 RSHIFT U> ABORT" out of memory"
  \ f[0...c-1]=2000
  c 0 DO 2000 I f! LOOP
  \ e=0
  0 TO e
  CR
  BEGIN
    \ d=0; g=2*c-1; b=c
    0. TO d
    c 2* 1- TO g
    c TO b
    BEGIN
      \ d+=f[b]*10000; f[b]=d%g; d/=g; g-=2; b--
      b f@ 10000 UM* +TO d
      d g 0 D/MOD
      TO d
      D>S b f!
      -2 +TO g
      -1 +TO b
    b WHILE
      \ d*=b
      d b UMD* TO d
    REPEAT
    \ printf("%.4u",e+d/10000); e=d%10000
    d 10000 SM/REM
    e + 0 <# # # # # #> TYPE
    TO e
    \ c-=14
    -14 +TO c
  c 0= UNTIL
;

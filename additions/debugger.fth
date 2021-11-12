\ Debugger for the E500-Forth environment.
\ Author: Sebastien Furic
\ 14th september 2002
\ Updated to Forth500 by Robert van Engelen
\ NOT THOROUGHLY TESTED, MAY HAVE ISSUES

.( Loading debugger... )

ANEW _DEBUGGER_

VARIABLE STOP                   \ Step-by-step/continuous debugging
STOP ON
VARIABLE NEST                   \ Nest/unnest calls
NEST OFF
VARIABLE SHOW-R                 \ Display return stack on/off
SHOW-R OFF
3 VALUE DPTH                    \ Stack printing depth
5 VALUE R-DPTH                  \ Return stack printing depth

500 VALUE MS-DELAY              \ In case of continuous debugging

\ Values and constants

2 CELLS CONSTANT CELL-SIZE      \ The size of a return stack cell
1 CHARS CELL+ CONSTANT CFA-SIZE \ The size of basic cfa

0 VALUE RSH                     \ Return stack limit
0 VALUE RSP                     \ Return stack pointer
CREATE RSL                      \ Return stack
  32 CELL-SIZE * ALLOT
  HERE TO RSH

0 VALUE IP                      \ Interpretation pointer register
0 VALUE W                       \ Working register
0 VALUE NESTING                 \ # of nested calls
FALSE VALUE CONTINUE            \ Exit debugger

0 CONSTANT #TERMINATED          \ Token indicating 'root' return stack address
1 CONSTANT #VALUE               \ Token indicating value pushed using >R
2 CONSTANT #ADDRESS             \ Token indicating a return address
3 CONSTANT #LOOP                \ Token indicating a loop parameter

\ Functions

: EMPTY-R ( -- )
  RSL TO RSP
;

: PUSH-R ( x #id -- )
  RSH RSP - CELL-SIZE < IF -5 THROW THEN \ Return stack overflow
  RSP 2!
  CELL-SIZE +TO RSP
;

: POP-R ( -- x #id )
  RSP RSL - CELL-SIZE < IF -6 THROW THEN \ Return stack underflow
  CELL-SIZE NEGATE +TO RSP
  RSP 2@
;

CREATE FORTH-BUFF 255 CHARS ALLOT

: FORTH> ( i*x -- j*x )
  BEGIN
    CR ." F>"
    FORTH-BUFF 255 ACCEPT ?DUP
  WHILE
    FORTH-BUFF SWAP
    ['] EVALUATE CATCH ?DUP IF NIP NIP (ERROR) THEN
  REPEAT
;

: .SR ( -- )
      ." R:( "
  RSP
  RSP R-DPTH 2* CELLS - RSL UMAX
  BEGIN
    2DUP U>
  WHILE
    DUP @ CASE
      #TERMINATED OF ." addr "   ENDOF
      #VALUE      OF DUP CELL+ ? ENDOF
      #ADDRESS    OF ." addr "   ENDOF
      #LOOP       OF ." loop "   ENDOF
    ENDCASE
    CELL+ CELL+
  REPEAT
  2DROP
  [CHAR] ) EMIT
;

: >UPPERCASE
  DUP [CHAR] a [CHAR] { WITHIN IF $20 - THEN
;

DEFER STEP-KEY ( i*x -- j*x )

:NONAME ( i*x -- j*x )
  KEY >UPPERCASE
  CASE
    $0d      OF NEST ON   ENDOF
    $20      OF NEST OFF  ENDOF
    [CHAR] F OF FORTH> CR ENDOF
    [CHAR] R OF SHOW-R ON ENDOF
    [CHAR] S OF STOP OFF  ENDOF
  ENDCASE
; IS STEP-KEY

: WAIT/GO ( i*x -- j*x )
  STOP @ IF STEP-KEY EXIT THEN
  MS-DELAY MS
  KEY? IF STOP ON STEP-KEY THEN
;

: (.NAME) ( addr -- )
  >NAME NAME>STRING TYPE
;

: .NAME ( addr -- )
  ['] (.NAME) CATCH IF DROP ." [NONAME]" THEN
  SPACE
;

: .NEST ( -- )
  [CHAR] [ EMIT NESTING S>D (D.) TYPE [CHAR] ] EMIT
;

: .TOKEN ( -- )
  W .NAME
  W CASE
    ['] (LIT)  OF IP ?                   ENDOF
    ['] (2LIT) OF IP 2@ D. [CHAR] . EMIT ENDOF
    ['] (FLIT) OF IP F@ FS.              ENDOF
    ['] (SLIT) OF
      IP CELL+ IP @ [CHAR] " EMIT TYPE [CHAR] " EMIT SPACE ENDOF
    ['] (TO)   OF IP @ CFA-SIZE - .NAME  ENDOF
    ['] (2TO)  OF IP @ CFA-SIZE - .NAME  ENDOF
    ['] (FTO)  OF IP @ CFA-SIZE - .NAME  ENDOF
    ['] (+TO)  OF IP @ CFA-SIZE - .NAME  ENDOF
    ['] (D+TO) OF IP @ CFA-SIZE - .NAME  ENDOF
  \ ['] (IS)   OF IP @ CFA-SIZE - .NAME  ENDOF
  ENDCASE
;

: .STACK ( -- )
  ." ( " DPTH N.S [CHAR] ) EMIT
;

: .NAME<-STACK ( -- )
  ?STACK IP .NAME ." <- " .STACK WAIT/GO
  SHOW-R @ IF SPACE .SR THEN CR
;

: .->STACK ( -- )
  ?STACK ." -> " .STACK
  SHOW-R @ IF SPACE .SR THEN
;

: W<-IP@++
  IP @ TO W
  CELL +TO IP
;

: DO-LIT ( -- x )
  W<-IP@++ W
;

: DO-2LIT ( -- x1 x2 )
  W<-IP@++ W W<-IP@++ W
;

: DO-FLIT ( -- r )
  IP F@
  1 FLOATS +TO IP
;

: DO-SLIT ( -- c-addr u )
  W<-IP@++
  IP W
  W +TO IP
;

: (>VALUE) ( -- a-addr xt )
  W<-IP@++
  W CFA-SIZE - ( cfa of the value )
  VALUE? IF W EXIT THEN
  -32 THROW \ Invalid name argument
;

: (>2VALUE) ( -- a-addr xt )
  W<-IP@++
  W CFA-SIZE - ( cfa of the value )
  2VALUE? IF W EXIT THEN
  -32 THROW \ Invalid name argument
;

: (>FVALUE) ( -- a-addr xt )
  W<-IP@++
  W CFA-SIZE - ( cfa of the value )
  FVALUE? IF W EXIT THEN
  -32 THROW \ Invalid name argument
;

: DO-TO ( x -- )
  (>VALUE)
  !
;

: DO-2TO ( x -- )
  (>2VALUE)
  2!
;

: DO-FTO ( x -- )
  (>FVALUE)
  F!
;

: DO-+TO ( n -- )
  (>VALUE)
  +!
;

: DO-D+TO ( x -- )
  (>2VALUE)
  D+!
;

\ : DO-IS ( xt -- )
\  W<-IP@++
\  W CFA-SIZE - ( cfa of the defered word )
\  DUP IF W ! EXIT THEN
\  -32 THROW \ Invalid name argument
\ ;

: DO-AHEAD ( -- )
  W<-IP@++
  W +TO IP
;

: DO-AGAIN ( -- )
  W<-IP@++
  W NEGATE +TO IP
;

: DO-IF ( bool -- )
  W<-IP@++
  IF EXIT THEN
  W +TO IP
;

: DO-OF ( x x -- |x )
  W<-IP@++
  OVER = IF DROP EXIT THEN
  W +TO IP
;

: DO-UNTIL ( bool -- )
  W<-IP@++
  IF EXIT THEN
  W NEGATE +TO IP
;

: PUSH-LOOP ( n -- )
  #LOOP PUSH-R
;

: POP-LOOP ( -- n )
  POP-R
  #LOOP <> IF -26 THROW THEN \ Loop parameters unavailable
;

: DO-DO ( n1 n2 -- ) ( R: i*x -- j*x )
  W<-IP@++
  W PUSH-LOOP
  SWAP $8000 + DUP PUSH-LOOP
  - PUSH-LOOP
;

: DO-?DO ( n1 n2 -- ) ( R: i*x -- j*x )
  2DUP = IF
    2DROP IP @ TO IP EXIT
  THEN
  DO-DO
;

: DO-LOOP ( -- ) ( R: i*x -- j*x )
  POP-LOOP \ Modified loop counter
  1+
  DUP $8000 = IF
    POP-LOOP POP-LOOP 2DROP DROP W<-IP@++ EXIT
  THEN
  PUSH-LOOP
  DO-AGAIN
;

: DO-+LOOP ( n -- ) ( R: i*x -- j*x )
  POP-LOOP \ Modified loop counter
  DUP>R
  OVER 0> IF
    + DUP 0> R> 0< OR IF
      PUSH-LOOP DO-AGAIN EXIT
    THEN
  ELSE
    + DUP 0< R> 0> OR IF
      PUSH-LOOP DO-AGAIN EXIT
    THEN
  THEN
  POP-LOOP POP-LOOP 2DROP DROP W<-IP@++
;

: DO-UNLOOP ( -- ) ( R: i*x -- j*x )
  POP-LOOP DROP \ Modified loop counter
  POP-LOOP DROP \ Modified loop limit
  POP-LOOP DROP \ LEAVE adress
;

: DO-LEAVE ( -- ) ( R: i*x -- j*x )
  POP-LOOP DROP  \ Modified loop counter
  POP-LOOP DROP  \ Modified loop limit
  POP-LOOP TO IP \ LEAVE adress
;

: DO-I ( -- n )
  POP-LOOP \ Modified loop counter
  POP-LOOP \ Modified loop limit
  2DUP + >R
  PUSH-LOOP
  PUSH-LOOP
  R>
;

: DO-J ( -- n )
  POP-LOOP \ Modified loop counter 1
  POP-LOOP \ Modified loop limit 1
  POP-LOOP \ LEAVE adress 1
  POP-LOOP \ Modified loop counter 2
  POP-LOOP \ Modified loop limit 2
  2DUP + >R
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  R>
;

: DO-K ( -- n )
  POP-LOOP \ Modified loop counter 1
  POP-LOOP \ Modified loop limit 1
  POP-LOOP \ LEAVE adress 1
  POP-LOOP \ Modified loop counter 2
  POP-LOOP \ Modified loop limit 2
  POP-LOOP \ LEAVE adress 1
  POP-LOOP \ Modified loop counter 2
  POP-LOOP \ Modified loop limit 2
  2DUP + >R
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  PUSH-LOOP
  R>
;

: PUSH-VALUE ( x -- )
  #VALUE PUSH-R
;

: POP-VALUE ( -- x )
  POP-R
  #VALUE <> IF -25 THROW THEN \ Return stack imbalance
;

: DO-TO-R ( x -- ) ( R: -- x )
  PUSH-VALUE
;

: DO-R> ( -- x ) ( R: x -- )
  POP-VALUE
;

: DO-2>R ( x1 x2 -- ) ( R: -- x1 x2 )
  SWAP
  PUSH-VALUE
  PUSH-VALUE
;

: DO-2R> ( -- x1 x2 ) ( R: x1 x2 -- )
  POP-VALUE
  POP-VALUE
  SWAP
;

: DO-DUP>R ( x -- x ) ( R: -- x )
  DUP PUSH-VALUE
;

: DO-R>DROP ( -- ) ( R: x -- )
  POP-VALUE DROP
;

: DO-R@ ( -- x ) ( R: x -- x )
  POP-VALUE
  DUP PUSH-VALUE
;

: DO-R'@ ( -- x1 ) ( R: x1 x2 -- x1 x2 )
  POP-VALUE
  POP-VALUE
  DUP>R
  PUSH-VALUE
  PUSH-VALUE
  R>
;

: DO-R"@ ( -- x1 ) ( R: x1 x2 x3 -- x1 x2 x3 )
  POP-VALUE
  POP-VALUE
  POP-VALUE
  DUP>R
  PUSH-VALUE
  PUSH-VALUE
  PUSH-VALUE
  R>
;

: DO-EXIT ( -- )
  POP-R
  DUP #TERMINATED <> TO CONTINUE
  CONTINUE IF
    #ADDRESS <> IF -25 THROW THEN \ Return stack imbalance
    TO IP
    -1 +TO NESTING
    EXIT
  THEN 2DROP
;

: DO-;CODE ( -- )
  IP LAST-XT @ 1+ ! \ Modify last xt's behavior
  DO-EXIT
;

: TRACE-COLON ( -- )
  ." : " .NAME<-STACK
  CFA-SIZE +TO IP
;

: TRACE-VAR ( -- a-addr )
  ." CREATE " .NAME<-STACK
  IP CFA-SIZE + \ Push the address of the CREATEd word on the stack
;

: TRACE-VAL ( -- x )
  ." VALUE " .NAME<-STACK
  IP CFA-SIZE + @ \ Push the value of the VALUE on the stack
;

: TRACE-2VAL ( -- x1 x2 )
  ." 2VALUE " .NAME<-STACK
  IP CFA-SIZE + 2@ \ Push the value of the 2VALUE on the stack
;

: TRACE-FVAL ( -- x1 x2 )
  ." FVALUE " .NAME<-STACK
  IP CFA-SIZE + F@ \ Push the value of the FVALUE on the stack
;

: TRACE-DOES ( -- a-addr )
  TRACE-VAR
  .NEST ." DOES> " .NAME<-STACK
  IP CHAR+ @ CFA-SIZE + TO IP \ The DOES> indirection
;

: TRACE-DEF ( -- )
  ." DEFER " IP .NAME
  BEGIN
    IP CFA-SIZE + @ TO IP
    ." IS " IP .NAME
    IP DEFER? 0=
  UNTIL
  CR
;

: TRACE-CON ( -- x )
  ." CONSTANT " .NAME<-STACK
  IP CFA-SIZE + @ \ Push the value of the CONSTANT on the stack
;

: TRACE-2CON ( -- x1 x2 )
  ." 2CONSTANT " .NAME<-STACK
  IP CFA-SIZE + 2@ \ Push the value of the 2CONSTANT on the stack
;

: TRACE-FCON ( -- r )
  ." FCONSTANT " .NAME<-STACK
  IP CFA-SIZE + F@ \ Push the value of the FCONSTANT on the stack
;

: CALL-PRIMITIVE ( i*x -- j*x )
  ." CODE " .NAME<-STACK
  IP EXECUTE
;

: JUMP-CFA ( i*x -- j*x )
  .NEST
  IP ['] RP! = ABORT" Can't trace RP!."
  IP DOES>? IF TRACE-DOES EXIT THEN \ No immediate DO-EXIT
  IP C@ $2 = IF  \ Check whether cfa begins with 'jp' or not
    IP 1+ @ CASE \ Get the address of the jump instruction
      ['] (:)    OF TRACE-COLON EXIT       ENDOF \ No immediate DO-EXIT
      ['] (VAR)  OF TRACE-VAR              ENDOF
      ['] (VAL)  OF TRACE-VAL              ENDOF
      ['] (2VAL) OF TRACE-2VAL             ENDOF
      ['] (FVAL) OF TRACE-FVAL             ENDOF
      ['] (DEF)  OF TRACE-DEF RECURSE EXIT ENDOF \ Reenter JUMP-CFA
      ['] (CON)  OF TRACE-CON              ENDOF
      ['] (2CON) OF TRACE-2CON             ENDOF
      ['] (FCON) OF TRACE-FCON             ENDOF
      ( DEFAULT )   >R CALL-PRIMITIVE R>
    ENDCASE
  ELSE
    CALL-PRIMITIVE
  THEN
  .NEST ." (EXIT) "
  DO-EXIT
  .->STACK WAIT/GO CR
;

: DO-OTHER ( i*x -- j*x )
  NEST @ IF
    IP #ADDRESS PUSH-R
    W TO IP
    1 +TO NESTING
    CR
    JUMP-CFA EXIT
  THEN
  W EXECUTE
  .->STACK CR
;

: DO-TOKEN ( i*x -- j*x )
  W CASE
    ['] (LIT)    OF DO-LIT    ENDOF
    ['] (2LIT)   OF DO-2LIT   ENDOF
    ['] (FLIT)   OF DO-FLIT   ENDOF
    ['] (SLIT)   OF DO-SLIT   ENDOF
    ['] (TO)     OF DO-TO     ENDOF
    ['] (2TO)    OF DO-2TO    ENDOF
    ['] (FTO)    OF DO-FTO    ENDOF
    ['] (+TO)    OF DO-+TO    ENDOF
    ['] (D+TO)   OF DO-D+TO   ENDOF
  \ ['] (IS)     OF DO-IS     ENDOF
    ['] (;CODE)  OF DO-;CODE  ENDOF
    ['] (AHEAD)  OF DO-AHEAD  ENDOF
    ['] (AGAIN)  OF DO-AGAIN  ENDOF
    ['] (IF)     OF DO-IF     ENDOF
    ['] (OF)     OF DO-OF     ENDOF
    ['] (UNTIL)  OF DO-UNTIL  ENDOF
    ['] (DO)     OF DO-DO     ENDOF
    ['] (?DO)    OF DO-?DO    ENDOF
    ['] (LOOP)   OF DO-LOOP   ENDOF
    ['] (+LOOP)  OF DO-+LOOP  ENDOF
    ['] (UNLOOP) OF DO-UNLOOP ENDOF
    ['] (LEAVE)  OF DO-LEAVE  ENDOF
    ['] I        OF DO-I      ENDOF
    ['] J        OF DO-J      ENDOF
    ['] K        OF DO-K      ENDOF
    ['] >R       OF DO-TO-R   ENDOF
    ['] R>       OF DO-R>     ENDOF
    ['] 2>R      OF DO-2>R    ENDOF
    ['] 2R>      OF DO-2R>    ENDOF
    ['] DUP>R    OF DO-DUP>R  ENDOF
    ['] R>DROP   OF DO-R>DROP ENDOF
    ['] R@       OF DO-R@     ENDOF
    ['] R'@      OF DO-R'@    ENDOF
    ['] R"@      OF DO-R"@    ENDOF
    ( DEFAULT )
      DUP ['] RP! = ABORT" Can't trace RP!."
      DO-OTHER  EXIT \ Immediate EXIT
  ENDCASE
  .->STACK CR
;

: TRACE-TOKENS ( i*x -- j*x )
  BEGIN
    CONTINUE
  WHILE
    W<-IP@++
    .NEST .TOKEN
    W ['] (EXIT) = IF
      DO-EXIT .->STACK WAIT/GO CR
    ELSE
      WAIT/GO DO-TOKEN
    THEN
  REPEAT
  ." Terminated."
;

: (DEBUG) ( i*x addr <name> -- j*x )
  ' TO IP
  TRUE TO CONTINUE
  EMPTY-R
  ( addr ) #TERMINATED PUSH-R
  CR
  JUMP-CFA TRACE-TOKENS
;

: DEBUG ( i*x <name> -- j*x )
  RP@ \ Return stack pointer in case of restart
  ['] (DEBUG) CATCH DUP IF
    STOP ON
  THEN NEST OFF SHOW-R OFF THROW
;

.( Done. )

\ SEE.FTH SEE word - decompiles a word

.( Loading SEE...)

\ ANEW _SEE_

\ a value flag to indicate immediate words
0 VALUE IMM

\ display the name of an xt
: NAME. ( xt -- )
  ['] >NAME CATCH IF S" ???" ELSE NAME>STRING THEN TYPE ;

\ display the name of an xt formatted as a colon definition
: COLON. ( xt -- )
  ['] >NAME CATCH IF S" :NONAME" ELSE ." : " NAME>STRING THEN TYPE ;

\ display TO name
: TO. ( ip -- ip )
  CELL+ DUP @ 3 - SPACE NAME. ;

\ display the jump distance of a jump word from the current ip and increment ip by 2
: JUMP. ( ip -- ip )
  CELL+ DUP @ OVER + CELL+ ."  ->" HEX. ;

\ display a cell in decimal, hex and as a word if the value matches an execution token
: CELL. ( x -- )
  DUP . DUP '$ EMIT HEX. ['] >NAME CATCH IF DROP ELSE NAME>STRING TYPE THEN ;

\ display the words of a colon definition starting at address ip
: SEE-DEF ( ip -- )
  BEGIN
    CR DUP HEX. SPACE
    DUP @ CASE
      ['] (;)      OF DROP '; EMIT IMM IF ."  IMMEDIATE" THEN EXIT ENDOF
      ['] (;CODE)  OF ." DOES>" >BODY ENDOF
      ['] (LIT)    OF CELL+ DUP @ CELL.                    ENDOF
      ['] (2LIT)   OF CELL+ DUP 2@ (D.) TYPE '. EMIT CELL+ ENDOF
      ['] (FLIT)   OF CELL+ DUP F@ FS. FLOAT+ 2-           ENDOF
      ['] (SLIT)   OF S\" S\" " TYPE CELL+ DUP CELL+ OVER @ DUP>R TYPE '" EMIT R> + ENDOF
      ['] (TO)     OF ." TO"    TO.   ENDOF
      ['] (2TO)    OF ." TO"    TO.   ENDOF
      ['] (FTO)    OF ." TO"    TO.   ENDOF
      ['] (+TO)    OF ." +TO"   TO.   ENDOF
      ['] (D+TO)   OF ." +TO"   TO.   ENDOF
      ['] (IF)     OF ." IF"    JUMP. ENDOF
      ['] (OF)     OF ." OF"    JUMP. ENDOF
      ['] (AHEAD)  OF ." AHEAD" JUMP. ENDOF
      ['] (AGAIN)  OF ." AGAIN" JUMP. ENDOF
      ['] (UNTIL)  OF ." UNTIL" JUMP. ENDOF
      ['] (DO)     OF ." DO"    JUMP. ENDOF
      ['] (?DO)    OF ." ?DO"   JUMP. ENDOF
      ['] (LOOP)   OF ." LOOP"  JUMP. ENDOF
      ['] (+LOOP)  OF ." +LOOP" JUMP. ENDOF
      DUP NAME.
    ENDCASE
    XMAX@ 7 - DUP X! S" (more)" PAUSE Y@ 6 AT-CLR
    CELL+
  AGAIN
;

\ display the meaning of a word defined in the dictionary
: SEE-WORD ( xt -- )
  DUP C@ 2 = IF
    DUP 1+ @ CASE
      ['] (:)    OF DUP COLON.     >BODY SEE-DEF ENDOF
      ['] (VAR)  OF ." VARIABLE $" >BODY HEX.    ENDOF
      ['] (VAL)  OF ." VALUE "     >BODY ?       ENDOF
      ['] (2VAL) OF ." 2VALUE "    >BODY 2@ D.   ENDOF
      ['] (FVAL) OF ." FVALUE "    >BODY F@ F.   ENDOF
      ['] (CON)  OF ." CONSTANT "  >BODY ?       ENDOF
      ['] (2CON) OF ." 2CONSTANT " >BODY 2@ D.   ENDOF
      ['] (FCON) OF ." FCONSTANT " >BODY F@ F.   ENDOF
      ['] (DEF)  OF ." DEFER "     DEFER@ NAME.  ENDOF
      OVER DOES>? IF
        ." DOES> ->" DUP >BODY DUP HEX. SEE-DEF
      ELSE OVER MARKER? IF
        ." MARKER"
      THEN THEN
      NIP
    ENDCASE
    EXIT
  THEN
  DROP ." CODE"
;

: SEE ( "name" -- )
  (')         \ 0 0 | xt 1 | xt -1
  ?DUP IF
    0> TO IMM
    SEE-WORD
  ELSE
    -13 THROW
  THEN
;

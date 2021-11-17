\ TRY.FTH exception handling like gforth
\ TRY <code> IFERROR <handle-code> THEN <restore-code> ENDTRY
\ TRY <code> RESTORE <restore-code> ENDTRY
\ where <handle-code> and <restore-code> may inspect the TOS error code (not drop it)

.( Loading TRY...)

ANEW _TRY_

: CALL		( ip -- ) >R ;

: CATCH-CALL	( ip -- ) ['] CALL CATCH ;

: TRY		( -- addr ; -- )
		POSTPONE AHEAD
		HERE ; IMMEDIATE

: IFERROR	( addr --  ; -- x)
		POSTPONE EXIT
		>R POSTPONE THEN
		R> POSTPONE LITERAL POSTPONE CATCH-CALL
		POSTPONE DUP POSTPONE IF
		POSTPONE DROP POSTPONE 0 ; IMMEDIATE

: RESTORE	( addr -- ; -- x )
		POSTPONE EXIT
		>R POSTPONE THEN
		R> POSTPONE LITERAL POSTPONE CATCH-CALL ; IMMEDIATE
  
: ENDTRY        ( -- ; x -- )
		POSTPONE THROW ; IMMEDIATE

\ tests

1 [IF]
: test1	( n -- )
  TRY
    1 SWAP / 2 + .
  IFERROR
    ." ERROR"
  THEN
    ." CLEANUP"
  ENDTRY ;
: test2	( n -- )
  TRY
    1 SWAP / 2 + .
  RESTORE
    ." RESTORE"
  ENDTRY ;
[THEN]

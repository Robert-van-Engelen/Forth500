\ TRY.FTH exception handling like gforth
\ TRY <code> IFERROR <handle-code> THEN <restore-code> ENDTRY
\ TRY <code> RESTORE <restore-code> ENDTRY
\ where <handle-code> and <restore-code> may inspect the TOS error code (not drop it)

.( Loading TRY...)

ANEW _TRY_

: TRY		( -- addr ; -- )
		POSTPONE AHEAD
		HERE
		['] (:) CFA, ; IMMEDIATE

: IFERROR	( addr --  ; -- x)
		POSTPONE (;)
		>R POSTPONE THEN
		R> POSTPONE LITERAL POSTPONE CATCH
		POSTPONE DUP POSTPONE IF
		POSTPONE DROP POSTPONE 0 ; IMMEDIATE

: RESTORE	( addr -- ; -- x )
		POSTPONE (;)
		>R POSTPONE THEN
		R> POSTPONE LITERAL POSTPONE CATCH ; IMMEDIATE
  
: ENDTRY        ( -- ; x -- )
		POSTPONE THROW ; IMMEDIATE

\ tests

0 [IF]
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

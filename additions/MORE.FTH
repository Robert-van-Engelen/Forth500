\ MORE.FTH MORE FILE - list file contents, like the Unix more utility
\ Author: Robert van Engelen

\ SPACE to page through a file
\ ENTER to display the next line
\ C-CE or BREAK to quit

.( Loading MORE...)

ANEW _MORE_

VOCABULARY VOC-MORE
VOC-MORE DEFINITIONS

0 VALUE fh \ file handle
0 VALUE nl? \ new line flag

: more-file	( -- )
  0 TO nl?
  \ turn cursor off and clear display
  0 SET-CURSOR PAGE
  BEGIN
  fh READ-CHAR DUP 257 <> WHILE \ char ior
    THROW \ char
    DUP $0a <> nl? AND IF CR THEN
    DUP $0d = TO nl? 
    DUP $20 $ff WITHIN IF
      EMIT
    ELSE
      $0a = IF CR THEN
    THEN
    \ if cursor moved past the display
    Y@ YMAX@ < INVERT IF
      \ wait for key
      EKEY
      \ space = new page, CCE = break, other = one more line
      CASE 
        $20 OF PAGE ENDOF
	$0c OF -28 THROW ENDOF
      ENDCASE
    THEN
  REPEAT
  2DROP
  Y@ YMAX@ < INVERT IF EKEY DROP THEN
;

FORTH DEFINITIONS

: more		( "filename" -- )
  \ MORE vocabulary context
  [ VOC-MORE ]
  \ parse file name, open file, save fileid
  PARSE-NAME R/O OPEN-FILE THROW TO fh
  \ show file content, catch io errors
  ['] more-file CATCH
  \ close file no matter what
  fh CLOSE-FILE DROP
  \ rethrow error when nonzero and not BREAK
  DUP -28 <> IF THROW ELSE DROP THEN
  \ back to FORTH
  [ FORTH ]
;

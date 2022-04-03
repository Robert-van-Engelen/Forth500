\ TLOAD.FTH load TEXT file with line numbers as Forth source
\ Author: Robert van Engelen
\ TLOAD filename.BAS
\ where filename.BAS is a Forth source file with line numbers edited and saved in TEXT mode

.( Loading TLOAD...)

ANEW _TLOAD_

DECIMAL

: TLOADED       ( c-addr u -- )
  \ open file and save fileid to the return stack
  R/O OPEN-FILE THROW >R
  \ read header 16 bytes + 0 0 CR bytes
  FIB 19 R@ READ-FILE 0= SWAP 19 = AND
  \ and check if it is a TEXT file header
  FIB 5 S\" \xff\x00\x08\x00\x34" S= AND IF
    BEGIN
      \ while not EOF and line number high byte is not $FF
      R@ READ-CHAR 0= SWAP $FF <> AND WHILE
      \ read and nip line number low byte
      R@ READ-CHAR NIP 0= WHILE
      \ get line len byte
      R@ READ-CHAR 0= WHILE ( -- len1 )
      \ read the len number of bytes into the FIB
      FIB OVER R@ READ-FILE 0= WHILE ( -- len1 len2 )
      \ all bytes read?
      OVER = WHILE ( -- len1 )
      \ evaluate the line read
      FIB SWAP ['] EVALUATE CATCH ?DUP IF
        \ drop string that failed to evaluate, close file and rethrow
        2DROP R> CLOSE-FILE DROP THROW
      THEN
    AGAIN
    ELSE DROP THEN
    ELSE 2DROP THEN
    ELSE DROP THEN
    THEN
    THEN
  ELSE
    ." not TEXT"
  THEN
  \ pop fileid from the return stack and close file
  R> CLOSE-FILE DROP
;

: TLOAD         ( "name" -- ) PARSE-NAME TLOADED ;

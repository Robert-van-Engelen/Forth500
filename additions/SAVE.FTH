\ SAVE.FTH save entire Forth500 image to a file, reload with LOADM from BASIC
\ Author: Robert van Engelen

\ In Forth500 execute:
\ SAVE F:MYFORTH.BIN
\ In BASIC execute (assuming memory for Forth500 is still allocated):
\ LOADM "F:MYFORTH.BIN"
\ CALL &B0000 (or CALL &B9000 on an unexpanded machine)

.( Loading SAVE...)

ANEW _SAVE_

DECIMAL

: SAVE          ( "name" -- )
  PARSE-NAME W/O CREATE-FILE THROW >R
  \ determine Forth500 start address and length up to HERE
  ['] (:) $ff00 AND HERE OVER -
  \ create file header using HERE as a temporary buffer
  HERE 16 ERASE
  \ 255 0 6 1 16 SizeLow SizeHigh 0 StartLow StartHigh Segment 255 255 255 0 15
  -1   HERE      C!
  262  HERE  2+  !
  16   HERE  4 + C!
  DUP  HERE  5 + !
  OVER HERE  8 + !
  $b   HERE 10 + C!
  -1   HERE 11 + !
  -1   HERE 13 + C!
  15   HERE 15 + C!
  \ write 16 byte header
  HERE 16 R@ WRITE-FILE THROW
  \ write Forth500 image from base address up to HERE
  R@ WRITE-FILE THROW
  \ close the file
  R> CLOSE-FILE THROW
;

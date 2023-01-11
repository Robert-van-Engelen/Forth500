\ TED.FTH TED - Text EDitor
\ Author: Robert van Engelen

.( Loading TED...)

ANEW _TED_

DECIMAL

VOCABULARY TEDDY
TEDDY DEFINITIONS

0 VALUE file.id
0 VALUE file.len
14 BUFFER: file.name

0 VALUE text.size
0 VALUE text.pos
0 VALUE text.row
0 VALUE text.col

\ -----------
\ LOAD & SAVE
\ -----------

: text		HERE 40 + ;

: file		file.name file.len ;

: >file		( c-addr u -- )
  -TRAILING
  \ get the drive character, if any, assign it, remove it
  DUP 2 U> IF
    OVER 1+ C@ ': = IF
      NEXT-CHAR DRIVE C!
      1 /STRING
    THEN
  THEN
  \ save the file name length
  12 UMIN DUP TO file.len
  \ save the file name string
  file.name SWAP CMOVE
  \ add .FTH extension if no extension present
  file 8 MIN S" ." SEARCH NIP NIP 0= IF
    file.len 8 UMIN TO file.len
    S" .FTH" file + SWAP CMOVE 4 +TO file.len
  THEN
;

S" WORKFILE.FTH" >file

: parse-file	BL PARSE-WORD ?DUP IF >file ELSE DROP THEN ;

: ?fits		( size -- ) DUP UNUSED 42 - U> ABORT" file too large" ;

: ?size		file.id FILE-SIZE THROW D>S ?fits DUP TO text.size ;

: gulp		text ?size file.id READ-FILE THROW TO text.size ;

: spit		text text.size file.id WRITE-FILE THROW ;

: close		file.id ?DUP IF CLOSE-FILE DROP 0 TO file.id THEN ;

: lf+!		( pos -- ) text + $0a SWAP C! 1 +TO text.size ;

: load-file
  close
  file R/O OPEN-FILE IF
    DROP
    0 TO text.size
  ELSE
    TO file.id
    CR ." Loading " file TYPE
    ['] gulp CATCH
    close
    THROW
  THEN
  \ trim trailing control characters, if any
  text.size
  BEGIN
  DUP WHILE
  DUP text + 1- C@ BL U< WHILE
    1-
  REPEAT THEN
  DUP TO text.size
  lf+!
;

: save-file
  BEGIN
    PAGE ." Saving " file TYPE
  file W/O CREATE-FILE ?DUP WHILE
    CR ." Error " .  ." try a different file"
    file 14 SWAP 0 0 EDIT >file
  REPEAT
  TO file.id
  ['] spit CATCH
  close
  THROW
;

: norm-file
  text text.size
  BEGIN
  ?DUP WHILE
    NEXT-CHAR DUP BL U< IF
      CASE
	$0a OF ENDOF
	$0d OF
	  OVER C@ $0a <> OVER 0= OR IF
	    OVER $0a SWAP 1- C!
	  THEN
	ENDOF
	BL 3 PICK 1- C!
      ENDCASE
    ELSE
      DROP
    THEN
  REPEAT
  DROP
;

\ ------
\ CURSOR
\ ------

: home		0 TO text.pos 0 TO text.row ;

: len		( -- u )
  text.pos
  BEGIN
  DUP text + C@ DUP $0a <> SWAP $0d <> AND WHILE
    1+
  REPEAT
  text.pos -
;

: crlf+		( pos -- pos )
  DUP text + C@ CASE
    $0a OF 1+ ENDOF
    $0d OF 2+ ENDOF
  ENDCASE
;

: up?		( -- flag )
  FALSE
  text.pos IF
    text.pos 1-
    BEGIN
    DUP WHILE
      DUP text + 1- C@ $0a <> WHILE
      1-
    REPEAT THEN
    TO text.pos
    -1 +TO text.row
    INVERT
  THEN
;

: down?		( -- flag )
  text.pos len + crlf+ DUP text.size U< IF
    TO text.pos
    1 +TO text.row
    TRUE
  ELSE
    DROP
    FALSE
  THEN
;

\ ---------
\ EDIT LINE
\ ---------

0 VALUE temp.len
PAD CONSTANT temp.buf
255 CONSTANT temp.max

: alert		100 MS 195 500 BEEP ;

: line		( -- c-addr u ) text text.pos + len ;

: temp		( -- buf len ) temp.buf temp.len ;

: line>temp	line temp.max UMIN DUP TO temp.len temp.buf SWAP CMOVE ;

: temp>line
  temp.len len -	\ delta
  DUP			\ delta delta 
  text.size		\ delta delta oldsize
  +			\ delta newsize
  DUP UNUSED 42 - U> IF
    \ out of memory, cannot update line
    2DROP
    alert
  ELSE
    \ update text.size and move the rest of text afer the line
    DUP TO text.size		\ delta newsize
    text.pos temp.len + - 	\ delta newsize-(pos+len)=restsize
    SWAP			\ restsize delta
    text text.pos +		\ restsize delta text+pos
    temp.len +			\ restsize delta text+to
    TUCK SWAP -			\ restsize text+to text+from
    SWAP ROT			\ text+from text+to restsize
    \ move text+from to text+to, if text+from<>text+to
    MOVE
    \ insert updated line
    temp text text.pos + SWAP CMOVE
  THEN
;

: edit-line
  0 0 AT-XY
  line>temp
  temp		\ buf len
  temp.max	\ buf len max
  SWAP		\ buf max len
  text.col	\ buf max len text.col
  OVER UMIN 0 EDIT TO temp.len DROP
  temp>line
;

\ -------
\ DISPLAY
\ -------

: disp
  PAGE
  text.pos		\ save old pos
  text.row		\ save old row
  160			\ oldpos oldrow num
  BEGIN
    text text.pos + len		\ num text+pos len
    2 PICK UMIN			\ num text+pos min(num,len)
    ROT OVER DUP 0<> + 40 / 1+ 40 * -	\ text+pos min(num,len) num-40*floor(min-1/40+1)
    -ROT			\ num-40*floor(min-/40+1) text+pos min
    TYPE CR			\ num-40*floor(min-/40+1)
  DUP 0> WHILE
  down? WHILE
  REPEAT THEN
  0 ?DO '~ EMIT CR 40 +LOOP
  TO text.row		\ restore row
  TO text.pos		\ restore pos
  0 4 AT-XY
;

\ ---------
\ EDIT FILE
\ ---------

: new
  text.size UNUSED 42 - U> IF
    alert
  ELSE
    text text.pos +		\ text+pos
    DUP 1+			\ text+pos text+pos+1
    text.size text.pos -	\ text+pos text+pos+1 restsize
    CMOVE>
    text.pos lf+!
  THEN
;

: cut
  line>temp
  text.pos			\ oldpos
  DUP len + crlf+		\ oldpos downpos
  text.size OVER -		\ oldpos downpos movesize
  -ROT				\ movesize oldpos downpos
  2DUP - +TO text.size
  text + SWAP text + ROT	\ text+downpos text+oldpos movesize
  CMOVE
  text.pos text.size U< INVERT IF
    text.size lf+!
  THEN
;

: copy 		line>temp ;

: paste		new temp>line ;
 
: insert	new disp 0 TO text.col edit-line ;

: enter
  down? INVERT IF
    text.size UNUSED 42 - U> INVERT IF
      text.size lf+!
    THEN
    down? DROP
  THEN
  insert
;

: menu-file	6 0 AT-XY file 14 SWAP DUP 0 EDIT >file ;

: menu
  PAGE
  ." File: " file REVERSE-TYPE text.size
  19 0 AT-XY DEC. 25 0 AT-XY ." [CCE] exit/save" CR
  ." [SPC] insert before [ENTER] insert after" CR
  ." [DEL] cut  [STO] copy  [ANS]/[RCL] paste" CR
  ." [UP]/[DN] scroll   [LFT]/[RGT] edit line" CR
  EKEY CASE
     $0c ( CCE   ) OF RDROP EXIT ENDOF
     $1c ( RIGHT ) OF menu-file ENDOF
     $1d ( LEFT  ) OF menu-file ENDOF
    $-04 ( OFF   ) OF POWER-OFF ENDOF
  ENDCASE
;

: edit-file
  home
  BEGIN
    disp
    EKEY CASE
       $0c ( CCE   ) OF EXIT ENDOF
       $0d ( ENTER ) OF enter ENDOF
       $1c ( RIGHT ) OF 0 TO text.col edit-line ENDOF
       $1d ( LEFT  ) OF -1 TO text.col edit-line ENDOF
       $1e ( UP    ) OF up? DROP ENDOF
       $1f ( DOWN  ) OF down? DROP ENDOF
       $20 ( SPACE ) OF insert ENDOF
       $7f ( DEL   ) OF cut ENDOF
      $-04 ( OFF   ) OF POWER-OFF ENDOF
      $-06 ( MENU  ) OF menu ENDOF
      $-90 ( RCL   ) OF paste ENDOF
      $-91 ( STO   ) OF copy ENDOF
      alert
    ENDCASE
  AGAIN
;

: start		( "name" -- ) 40 XMAX! 4 YMAX! parse-file load-file norm-file ;

: resume	edit-file save-file ;

\ -----
\ FORTH
\ -----

FORTH DEFINITIONS
: TED [ TEDDY ] start resume [ FORTH ] ;
: TEDI TED [ TEDDY ] file [ FORTH ] INCLUDED ;
: TED-RESUME [ TEDDY ] resume [ FORTH ] ;
: TEDI-RESUME TED-RESUME [ TEDDY ] file [ FORTH ] INCLUDED ;

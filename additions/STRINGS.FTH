\ STRINGS.FTH defines string buffers of variable lengths
\ See the manual example "Strings" instructions

.( Loading STRINGS...)

ANEW _STRINGS_

: strmax	( string -- max ) 2- C@ ;
: strlen	( string -- len ) 1- C@ ;
: strunused	( string -- unused ) DUP strmax SWAP strlen - ;
: strupdate	( string len -- ) OVER strmax UMIN SWAP 1- C! ;

: string:	( max "name" -- ; string len )
  CREATE DUP C, 0 C, ALLOT
  DOES> 2+ DUP strlen ;

: strcpy	( c-addr u string len -- )
  DROP DUP ROT strupdate	\ set the new length
  DUP strlen CMOVE ;

: strcat	( c-addr u string len -- )
  >R				\ save the old length
  SWAP OVER strunused UMIN	\ limit the added length
  2DUP R@ + strupdate		\ set the new length = old length + added
  SWAP R> + SWAP CMOVE ;

: straccept	( string len -- )
  DROP DUP DUP strmax ACCEPT strupdate ;

: stredit	( string len -- )
  >R DUP strmax R>	\ -- string max len
  DUP			\ place cursor at the end (=len)
  0			\ allow edits to the begin at position 0 (no prompt)
  EDIT strupdate ;

: slice		( c-addr1 u1 pos len -- c-addr2 u2 )
  >R			\ save len
  OVER UMIN		\ -- c-addr u1 pos where pos is limited to u1
  TUCK			\ -- c-addr pos u1 pos
  - R> UMIN		\ -- c-addr pos len where pos+len is limited to u1
  >R + R> ;

: sfield:	( u max "name" -- u ; addr -- string len )
  CREATE
    OVER ,		\ store current struct size u
    DUP ,		\ store max
    + 2+		\ update struct size += max+2
  DOES>		( struct-addr addr -- member-addr )
    SWAP OVER @ +	\ compute member address
    DUP ROT		\ -- member-addr member-addr addr
    CELL+ @ C!		\ make sure string max is set
    2+ DUP strlen ;

: sarray:	( size max "name" -- ; index -- string len )
  CREATE
    DUP , 2+ * ALLOT	\ save max and allocate space
  DOES>		( array-addr index -- string len )
    SWAP OVER @		\ -- addr index max
    DUP>R		\ save max
    2+ * + CELL+	\ address in the array = (max+2)*index+addr+2
    R> OVER C!		\ make sure the string max is set
    2+			\ skip max and len to get to string
    DUP strlen ;

: toupper	( char -- char ) DUP [CHAR] a [CHAR] { WITHIN IF $20 - THEN ;
: tolower	( char -- char ) DUP [CHAR] A [CHAR] [ WITHIN IF $20 + THEN ;
: strupper	( string len -- ) 0 ?DO DUP I + DUP C@ toupper SWAP C! LOOP DROP ;
: strlower	( string len -- ) 0 ?DO DUP I + DUP C@ tolower SWAP C! LOOP DROP ;

: strtmp	254 PAD C! PAD 2+ PAD 1+ C@ ;

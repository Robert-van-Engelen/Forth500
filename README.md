# A Forth Compiler for the SHARP PC-E500(S)

A Forth compiler based on the excellent ANS Forth compiler for the PC-E500(S) by Sébastien Furic.

This Forth500 compiler implementation is [standard-Forth](https://forth-standard.org) compliant and satisifies:
- CORE
- CORE-EXT
- (BLOCK is incomplete and removed to save space for now)
- DOUBLE
- DOUBLE-EXT
- EXCEPTION
- EXCEPTION-EXT
- FACILITY
- FACILITY-EXT: `EKEY`, `EKEY>CHAR`, `EKEY?`, `MS`, `BEGIN-STRUCTURE`, `END-STRUCTURE`, `+FIELD`, `CFIELD:`, `FIELD:`, `2FIELD:`
- FILE (note: `RESIZE-FILE` cannot truncate files, but returns 0 no error anyway)
- FILE-EXT: `FILE-STATUS`, `INCLUDE`, `REFILL`, `RENAME-FILE`, `S\"`
- FLOATING (no: TBD)
- FLOATING-EXT (no: TBD)
- STRING
- TOOLS: `.S`, `?`, `DUMP`, `WORDS`
- TOOLS-EXT: `AHEAD`, `BYE`, `CS-PICK`, `CS-ROLL`, `FORGET`, `STATE`, `N>R`, `NR>`, `[DEFINED]`, `[ELSE]`, `[IF]`, `[THEN]`, `[UNDEFINED]`

Additional words:
- introspection: `COLON?`, `DOES>?`, `MARKER?`, `VARIABLE?`, `2VARIABLE?`, `VALUE?`, `2VALUE?`
- values: `+TO`
- variables: `ON`, `OFF`
- arithmetic: `UMAX`, `UMIN`, `2+`, `2-`, `M-`, `D/MOD`, `DMOD`, `UMD*`
- stack: `-ROT`, `2NIP`, `2TUCK`, `DUP>R`, `R>DROP`
- loops: `K`, `?LEAVE`
- strings: `S=`, `EDIT`
- display: `REVERSE-TYPE`, `BASE.`, `BIN.`, `DEC.`, `HEX.`, `N.S`
- LCD: `SET-SYMBOLS`, `BUSY-ON`, `BUSY-OFF`, `CURSOR`, `SET-CURSOR`, `X@`, `X!`, `Y@`, `Y!`, `XMAX@`, `XMAX!`, `YMAX@`, `YMAX!`
- graphics: `GMODE`, `GPOINT`, `GPOINT?`, `GLINE`, `GBOX`, `GDOTS`, `GDOTS?`, `GDRAW`, `GBLIT!`, `GBLIT@`
- sound: `BEEP`
- dictionary: `LAST`, `LAST-XT`, `HIDE`, `REVEAL`, `L>NAME`, `>NAME, NAME>, FIND-WORD
- files: `STRING>FILE`, `FILE>STRING`, `FIND-FILE`, `FILE-INFO`, `FILE-END?`, `WRITE-CHAR`, `READ-CHAR`, `PEEK-CHAR`, `CHAR-READY?`, `SEEK-FILE` (with `SEEK-SET`, `SEEK-CUR`, `SEEK-END`), `FREE-CAPACITY`, `>FILE`, `FILES`, `DRIVE`, `STDI`, `STDO`, `STDL`
- keyboard: `>KEY-BUFFER`, `KEY-CLEAR`, `INKEY`
- parsing: `\"-PARSE`
- editing: `EDIT`
- marking: `ANEW`
- power: `POWER-OFF`

The code is optimized and more compact. The `docol` fetch-execute cycle is 40% more efficient.

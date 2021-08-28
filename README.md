# A Complete Forth System for the SHARP PC-E500(S)

A Forth 2012 system based on the excellent ANS Forth compiler for the PC-E500(S) by Sébastien Furic.

![PC-E500S](PC-E500S.jpeg)

The PC-E500 is a powerful pocket computer introduced in 1989 that saw a [PC-E500S](https://en.wikipedia.org/wiki/Sharp_PC-E500S) successor in 1995.

Parts of the Forth machine code are rewritten and optimized for speed and code size. The `docol` fetch-execute cycle is 40% more efficient.  Words are case-insensitive and can be typed in upper/lower/mixed case.  Included are the binaries for unexpanded 32KB machines and expanded >96KB machines.  Also included is the XASM assembler written by N. Kon for the SC62015 CPU with the documentation translated to English.  XASM is required to rebuild the Forth500 system from assembly.

To use Forth500, first load the binary, then `CALL &B0000` (see [expanded E500](E500-expanded)) or `CALL &B9000` (see [unexpanded E500](E500-unexpanded)).  Forth500 starts immediately and can be exited with `BYE`.  Call again to continue using Forth500 where you left off.  Forth500 resides in protected memory and does not interfere with BASIC.

The [Forth500.s](Forth500.s) source code is extensively documented and PC-E500 technical [resources](resources) are included.

The [Forth500 User Guide](#manual.md) introduces standard Forth and the Forth500 system.

This updated Forth compiler is [standard Forth](https://forth-standard.org) 2012 compliant and satisifies:
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
- variables: `D+!`, `ON`, `OFF`
- arithmetic: `UMAX`, `UMIN`, `2+`, `2-`, `M-`, `D/MOD`, `DMOD`, `UMD*`
- stack: `-ROT`, `2NIP`, `2TUCK`, `DUP>R`, `R>DROP`, `CLEAR`
- loops: `K`, `?LEAVE`
- strings: `S=`, `EDIT`
- display: `REVERSE-TYPE`, `BASE.`, `BIN.`, `DEC.`, `HEX.`, `N.S`
- LCD: `SET-SYMBOLS`, `BUSY-ON`, `BUSY-OFF`, `CURSOR`, `SET-CURSOR`, `X@`, `X!`, `Y@`, `Y!`, `XMAX@`, `XMAX!`, `YMAX@`, `YMAX!`
- graphics: `GMODE`, `GPOINT`, `GPOINT?`, `GLINE`, `GBOX`, `GDOTS`, `GDOTS?`, `GDRAW`, `GBLIT!`, `GBLIT@`
- sound: `BEEP`
- dictionary: `LAST`, `LAST-XT`, `HIDE`, `REVEAL`, `L>NAME`, `>NAME`, `NAME>`, `FIND-WORD`
- files: `FILES`, `DRIVE`, `STDI`, `STDO`, `STDL`, `FREE-CAPACITY`, `STRING>FILE`, `FILE>STRING`, `FIND-FILE`, `FILE-INFO`, `FILE-END?`, `WRITE-CHAR`, `READ-CHAR`, `PEEK-CHAR`, `CHAR-READY?`, `SEEK-FILE` (with `SEEK-SET`, `SEEK-CUR`, `SEEK-END`), `>FILE`
- keyboard: `>KEY-BUFFER`, `KEY-CLEAR`, `INKEY`
- parsing: `\"-PARSE`
- marking: `ANEW`
- power: `POWER-OFF`
- misc: `CELL`, `NOOP`

Work in progress:

- Floating point words and stack
- A file editor (a command line editor is included)

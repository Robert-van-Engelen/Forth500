# A Complete Forth System for the SHARP PC-E500(S)

![PC-E500S](PC-E500S.jpeg)

The PC-E500 is a powerful pocket computer introduced in 1989 that saw a [PC-E500S](https://en.wikipedia.org/wiki/Sharp_PC-E500S) successor in 1995.

Sébastien Furic's original (incomplete) ANS Forth compiler is available from the great retro web site [Aldweb](https://www.aldweb.com/articles.php?lng=en&pg=9362).

I've rewritten large parts of the code to optimize for speed, code size and compliance with the Forth Standard, see the [changelog](changelog.md). The `docol` fetch-execute cycle is 40% more efficient.  Words are now case-insensitive and can be typed in upper/lower/mixed case.  All standard floating point words are now also included.  Included in this repo are the binaries for unexpanded 32KB machines and expanded >96KB machines.  Also included is the XASM assembler written by N. Kon for the SC62015 CPU.  I translated the XASM documentation to English and I made a minor change to the XASM source code to be able to compile XASM with FreePascal (see XASM/PASCAL.txt).  XASM is required to rebuild the Forth500 system from assembly.  The [Forth500.s](Forth500.s) source code is heavily documented and PC-E500 technical [resources](resources) are included.

## Instruction manual

See the [Forth500 User Guide](manual.md) with an introduction to Forth and a full description of the Forth500 system.

## How fast is it?

The [n-queens benchmark](https://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/articles.cgi?read=700) is solved in 3.47 seconds, the fastest Forth system in this benchmark and faster than the compiled n-queens C program on a Sharp PC-G850VS that runs at 8.0MHz compared to the 2.3MHz PC-E500(S).

## Load Forth500 via serial or cassette interface

To use Forth500, first load the binary, then `CALL &B0000` (see [expanded E500](E500-expanded)) or `CALL &B9000` (see [unexpanded E500](E500-unexpanded)).  Forth500 starts immediately and can be exited with `BYE`.  Call again to continue using Forth500 where you left off.  Forth500 resides in protected memory and does not interfere with BASIC.

Forth programs can be loaded into Forth500 via the serial interface or cassette interface with [PocketTools](https://www.peil-partner.de/ifhe.de/sharp/).

## Editing Forth source files

[TED](additions/TED.FTH) is a small text editor for Forth500:

    TED             edit the last file edited
    TED FILE.FTH    edit FILE.FTH
    TEDI            edit the last file edited, then read it into Forth500
    TEDI FILE.FTH   edit FILE.FTH, then read it into Forth500

The `TEDI` command uses `INCLUDE` (or `INCLUDED`) to read the saved file.

See also [TED.TXT](additions/TED.TXT).

## Saving a Forth500 image to a file

[SAVE](additions/SAVE.FTH) saves the entire Forth500 image, including all user-defined definitions, to a binary file from Forth500:

    SAVE F:MYFORTH.BIN

In BASIC execute (assuming memory for Forth500 is still allocated):

    LOADM "F:MYFORTH.BIN"
    CALL &B0000 (or CALL &B9000 on an unexpanded machine)

## Batteries included...

Forth500 is [Forth Standard](https://forth-standard.org) compliant and implements:
- [CORE and CORE-EXT](https://forth-standard.org/standard/core) complete: `ABORT`, `ABORT"`, `ABS`, `ACCEPT`, `ACTION-OF`, `AGAIN`, `ALIGN`, `ALIGNED`, `ALLOT`, `AND`, `BASE`, `BEGIN`, `BL`, `BUFFER:`, `[`, `[CHAR]`, `[COMPILE]`, `[']`, `CASE`, `C,`, `CELL+`, `CELLS`, `C@`, `CHAR`, `CHAR+`, `CHARS`, `COMPILE,`, `CONSTANT`, `COUNT`, `CR`, `CREATE`, `C!`, `:`, `:NONAME`, `,`, `C"`, `DECIMAL`, `DEFER`, `DEFER@`, `DEFER!`, `DEPTH`, `DO`, `DOES>`, `DROP`, `DUP`, `/`, `/MOD`, `.R`, `.(`, `."`, `ELSE`, `EMIT`, `ENDCASE`, `ENDOF`, `ENVIRONMENT?`, `ERASE`, `EVALUATE`, `EXECUTE`, `EXIT`, `=`, `FALSE`, `FILL`, `FIND`, `FM/MOD`, `@`, `HERE`, `HEX`, `HOLD`, `HOLDS`, `I`, `IF`, `IMMEDIATE`, `INVERT`, `IS`, `J`, `KEY`, `LEAVE`, `LITERAL`, `LOOP`, `LSHIFT`, `MARKER`, `MAX`, `MIN`, `MOD`, `MOVE`, `M*`, `-`, `NEGATE`, `NIP`, `OF`, `OR`, `OVER`, `1-`, `1+`, `PAD`, `PARSE-NAME`, `PARSE`, `PICK`, `POSTPONE`, `+`, `+LOOP`, `+!`, `QUIT`, `RECURSE`, `REFILL`, `REPEAT`, `RESTORE-INPUT`, `R@`, `ROLL`, `ROT`, `RSHIFT`, `R>`, `SAVE-INPUT`, `SIGN`, `SM/REM`, `SOURCE-ID`, `SOURCE`, `SPACE`, `SPACES`, `STATE`, `SWAP`, `;`, `S\"`, `S"`, `S>D`, `!`, `THEN`, `TO`, `TRUE`, `TUCK`, `TYPE`, `'`, `*`, `*/`, `*/MOD`, `2DROP`, `2DUP`, `2/`, `2@`, `2OVER`, `2R@`, `2R>`, `2SWAP`, `2!`, `2*`, `2>R`, `U.R`, `UM/MOD`, `UM*`, `UNLOOP`, `UNTIL`, `UNUSED`, `U.`, `U<`, `U>`, `VALUE`, `VARIABLE`, `WHILE`, `WITHIN`, `WORD`, `XOR`, `0=`, `0<`, `0>`, `0<>`, `\`, `.`, `<`, `>`, `<>`, `#>`, `<#`, `#`, `#S`, `(`, `?DO`, `?DUP`, `>BODY`, `>IN`, `>NUMBER`, `>R`
- [BLOCK](https://forth-standard.org/standard/block) removed to save space, not practical on the PC-E500
- [DOUBLE and DOUBLE-EXT](https://forth-standard.org/standard/double) complete: `DABS`, `D.R`, `D=`, `DMAX`, `DMIN`, `D-`, `DNEGATE`, `D+`, `D2/`, `D2*`, `DU<`, `D0=`, `D0<`, `D.`, `D<`, `D>S`, `M+`, `M*/`, `2CONSTANT`, `2LITERAL`, `2ROT`, `2VALUE`, `2VARIABLE`
- [EXCEPTION and EXCEPTION-EXT](https://forth-standard.org/standard/exception) complete: `ABORT`, `ABORT"`, `CATCH`, `THROW`
- [FACILITY](https://forth-standard.org/standard/facility) complete: `AT-XY`, `KEY?`, `PAGE`
- [FACILITY-EXT](https://forth-standard.org/standard/facility) partly: `BEGIN-STRUCTURE`, `CFIELD:`, `EKEY`, `EKEY?`, `EKEY>CHAR`, `END-STRUCTURE`, `FIELD:`, `2FIELD:`, `+FIELD`, `MS`
- [FILE and FILE-EXT](https://forth-standard.org/standard/file) complete: `BIN`, `CLOSE-FILE`, `CREATE-FILE`, `DELETE-FILE`, `FILE-POSITION`, `FILE-SIZE`, `FILE-STATUS`, `FLUSH-FILE`, `INCLUDE-FILE`, `INCLUDE`, `INCLUDED`, `OPEN-FILE`, `R/O`, `R/W`, `READ-FILE`, `READ-LINE`, `REFILL`, `RENAME-FILE`, `REPOSITION-FILE`, `REQUIRE`, `REQUIRED`, `RESIZE-FILE`, `SOURCE-ID`, `S\"`, `S"`, `W/O`, `WRITE-FILE`, `WRITE-LINE`, `(`
- [FLOATING and FLOATING-EXT](https://forth-standard.org/standard/float) complete: `DFALIGN`, `DFALIGNED`, `DFFIELD:`, `DF@`, `DFLOAT+`, `DFLOATS`, `DF!`, `D>F`, `FABS`, `FACOS`, `FACOSH`, `FALIGN`, `FALIGNED`, `FALOG`, `FASIN`, `FASINH`, `FATAN`, `FATANH`, `FATAN2`, `FCONSTANT`, `FCOS`, `FCOSH`, `FDEPTH`, `FDROP`, `FDUP`, `F/`, `FEXP`, `FEXPM1`, `FE.`, `FFIELD:`, `F@`, `FLITERAL`, `FLN`, `FLNP1`, `FLOAT+`, `FLOATS`, `FLOG`, `FLOOR`, `FMAX`, `FMIN`, `F-`, `FNEGATE`, `FOVER`, `F+`, `FROT`, `FROUND`, `FSIN`, `FSINCOS`, `FSINH`, `FSQRT`, `FSWAP`, `FS.`, `F!`, `FTAN`, `FTANH`, `FTRUNC`, `F*`, `F**`, `FVALUE`, `FVARIABLE`, `F0=`, `F0<`, `F.`, `F<`, `F~`, `F>D`, `F>S`, `PRECISION`, `REPRESENT`, `SET-PRECISION`, `SFALIGN`, `SFALIGNED`, `SFFIELD:`, `SF@`, `SFLOAT+`, `SFLOATS`, `SF!`, `S>F`, `>FLOAT`, where the hyperbolics and `FE.` and `F~` are defined in [FLOATEXT.FTH](https://github.com/Robert-van-Engelen/Forth500/blob/main/additions/FLOATEXT.FTH) to load separately to save memory
- [STRING](https://forth-standard.org/standard/string) complete: `BLANK`, `CMOVE`, `CMOVE>`, `COMPARE`, `/STRING`, `-TRAILING`, `SEARCH`, `SLITERAL`
- [TOOLS and TOOLS-EXT](https://forth-standard.org/standard/tools) partly: `.S`, `?`, `AHEAD`, `BYE`, `CS-ROLL`, `DUMP`, `FORGET`, `STATE`, `N>R`, `NR>`, `WORDS`, `[DEFINED]`, `[ELSE]`, `[IF]`, `[THEN]`, `[UNDEFINED]`
- [SEARCH and SEARCH EXT](https://forth-standard.org/standard/search) partly: `DEFINITIONS`, `FIND`, `FORTH`

Additional built-in words:
- introspection: `COLON?`, `DOES>?`, `MARKER?`, `DEFER?`, `VALUE?`, `2VALUE?`, `FVALUE?`
- values: `2TO`, `+TO`, `D+TO`
- variables: `D+!`, `ON`, `OFF`
- arithmetic: `UMAX`, `UMIN`, `2+`, `2-`, `M-`, `D/MOD`, `DMOD`, `UMD*`, `FDEG`, `FDMS`, `FRAND`, `FSIGN`
- logic: `D<>`, `D>`, `D0<>`, `D0>`, `F<>`, `F>`, `F0<>`, `F0>`
- stack: `-ROT`, `2NIP`, `2TUCK`, `DUP>R`, `R>DROP`, `CLEAR`
- loops: `K`, `?LEAVE`
- strings: `NEXT-CHAR`, `S=`, `-CHARS`, `EDIT`, `>DOUBLE`
- display: `REVERSE-TYPE`, `PAUSE`, `BASE.`, `BIN.`, `DEC.`, `HEX.`, `N.S`, `TTY`
- printing: `STDL`, `PRINTER`
- tape: `TAPE`, `CLOAD`
- LCD: `SET-SYMBOLS`, `BUSY-ON`, `BUSY-OFF`, `CURSOR`, `SET-CURSOR`, `X@`, `X!`, `Y@`, `Y!`, `XMAX@`, `XMAX!`, `YMAX@`, `YMAX!`
- graphics: `GMODE!`, `GPOINT`, `GPOINT?`, `GLINE`, `GBOX`, `GDOTS`, `GDOTS?`, `GDRAW`, `GBLIT!`, `GBLIT@`
- sound: `BEEP`
- vocabulary: `VOCABULARY`, `CURRENT`, `CONTEXT`
- dictionary: `LAST-XT`, `HIDE`, `REVEAL`, `L>NAME`, `>NAME`, `NAME>`, `FIND-WORD`, `CREATE-NONAME`
- files: `FILES`, `DSKF`, `DRIVE`, `STDO`, `STDI`, `STDL`, `STRING>FILE`, `FILE>STRING`, `FIND-FILE`, `FILE-INFO`, `FILE-END?`, `WRITE-CHAR`, `READ-CHAR`, `PEEK-CHAR`, `CHAR-READY?`, `SEEK-FILE` (with `SEEK-SET`, `SEEK-CUR`, `SEEK-END`), `>FILE`
- keyboard: `>KEY-BUFFER`, `KEY-CLEAR`, `INKEY`
- parsing: `\"-PARSE`
- marking: `ANEW`
- power: `POWER-OFF`
- misc: `CELL`, `NOOP`

# Forth500 User Guide

Author: Dr. Robert A. van Engelen, 2021

## Table of contents

- [Forth500](#forth500)
- [Quick Forth tutorial](#quick-forth-tutorial)
- [Stack effects](#stack-effects)
- [Stack manipulation](#stack-manipulation)
  - [Floating point stack manipulation](#floating-point-stack-manipulation)
- [Integer constants](#integer-constants)
  - [Floating point constants](#floating-point-constants)
- [Arithmetic](#arithmetic)
  - [Single arithmetic](#single-arithmetic)
  - [Double arithmetic](#double-arithmetic)
  - [Mixed arithmetic](#mixed-arithmetic)
  - [Fixed point arithmetic](#fixed-point-arithmetic)
  - [Floating point arithmetic](#floating-point-arithmetic)
  - [Numeric comparisons](#numeric-comparisons)
- [Numeric output](#numeric-output)
  - [Pictured numeric output](#pictured-numeric-output)
- [String constants](#string-constants)
- [String operations](#string-operations)
- [Keyboard input](#keyboard-input)
- [Screen and cursor operations](#screen-and-cursor-operations)
- [Graphics](#graphics)
- [Sound](#sound)
- [The return stack](#the-return-stack)
- [Defining new words](#defining-new-words)
  - [Constants, variables and values](#constants-variables-and-values)
  - [Deferred words](#deferred-words)
  - [Noname definitions](#noname-definitions)
  - [Recursion](#recursion)
  - [Immediate words](#immedate-words)
  - [CREATE and DOES>](#create-and-does)
  - [Structures](#structures)
  - [Arrays](#arrays)
  - [Markers](#markers)
  - [Deleting words](#removing-words)
  - [Introspection](#introspection)
- [Control flow](#control-flow)
  - [Conditionals](#conditionals)
  - [Loops](#loops)
- [Compile-time immedate words](#compile-time-immediate-words)
  - [The \[ and \] brackets](#the--and--brackets)
  - [Immediate execution](#immediate-execution)
  - [Literals](#literals)
  - [Postponing execution](#postponing-execution)
  - [Compile-time conditionals](#compile-time-conditionals)
- [Source input and parsing](#source-input-and-parsing)
- [Files](#files)
  - [Loading from files](#loading-from-files)
  - [File and stream operations](#file-and-stream-operations)
  - [Filename globbing](#filename-globbing)
  - [Loading from tape](#loading-from-tape)
  - [File errors](#file-errors)
- [Exceptions](#exceptions)
- [Environmental queries](#environmental-queries)
- [Dictionary structure](#dictionary-structure)
- [Examples](#examples)
  - [CHDIR](#chdir)
  - [GCD](#gcd)
  - [RAND](#rand)
  - [SQRT](#sqrt)
  - [Strings](#strings)
  - [Enums](#enums)
  - [Slurp](#slurp)
- [Further reading](#further-reading)

## Forth500

Forth500 is a [Forth Standard](https://forth-standard.org/standard/intro)
system for the SHARP PC-E500(S) pocket computer.  This pocket computer sports a
2.304MHz 8-bit CPU with a 20-bit address space of up to 1MB.  This pocket
computer includes 256KB system ROM and 32KB to 256KB RAM.  The RAM card slot
offers additional storage up to 256KB RAM.  Forth500 is small enough to fit in
an unexpanded 32KB machine.

Forth is unlike any other mainstream programming language.  It has an
unconventional syntax and unique program execution characteristics.  Because of
this, programs run very efficiently and do not require much memory to run.
On the other hand, this makes learning Forth a bit more challenging for
beginners and experienced programmers alike.

It is perhaps best to think of Forth as a language positioned between assembly
coding and C in terms of power and complexity.  Like assembly and C, you have a
lot of freedom and power at your fingertips.  But this comes with a healthy
dose of responsibility to do things right:  errors can lead to system crashes.
Fortunately, the PC-E500(S) easily recovers from a system crash with a reset.

## Quick Forth tutorial

This section is intentionally kept simple by avoiding technical jargon and
unnecessary excess.  Familiarity with the concepts of stacks and dictionaries
is assumed.  Experience with C makes it easier to follow the use of addresses
(pointers) to integer values, strings and other data in Forth.

A Forth system is a dictionary of words.  A word can be any sequence of
characters but excludes space, tab, newline, and other control characters.
Words can be entered simply by typing them in as long as they are separated by
spacing.  Words are defined for subroutines, for named constants and for global
variables and data.  Some words may execute at compile time to compile the body
of subroutine definitions and to implement control flow such as conditional
branches and loops.  As such, the syntax blends compile-time and runtime
behaviors that are distinguishable by naming and naming conventions of words.

You can enter Forth words at the Forth500 interactive prompt.  The following
special keys can be used to enter a line of Forth code of up to 255 characters
long:

| key         | comment
| ----------- | ----------------------------------------------------------------
| INS         | switch to insertion mode or back to replace mode
| DEL         | delete the character under the cursor
| BS          | backspace
| ENTER       | execute the line of input
| LEFT/RIGHT  | before typing input "replays" the last line of input to edit
| CURSOR KEYS | move cursor up/down/left/right on the line
| C/CE        | clears the line

To exit Forth500 and return to BASIC, enter `bye`.  This saves the Forth500
state in memory.  To reenter Forth500 from BASIC, `CALL &Bxx00` again where
`xx` is the high-order address of Forth500.

Forth500 is case insensitive.  Words may be typed in upper or lower case or in
mixed case.  In this manual all built-in words are shown in UPPER CASE.
User-defined words in the examples are shown in lower case.

To list the words stored in the Forth dictionary, type (↲ is ENTER):

    WORDS ↲

Hit any key to continue or BREAK to stop.  BREAK generally terminates the
execution of a Forth500 subroutine associated with a word.

To list words that fully and partially match a given name, type:

    WORDS NAME ↲

For example, `WORDS DUP` lists all words with names that contain the part `DUP`
(the `WORDS` search is case sensitive).  Press BREAK or C/CE to stop listing
more words.

Words like `DUP` operate on the stack.  `DUP` duplicates the top value,
generally called TOS "Top Of Stack".  All computations in Forth occur on the
stack.  Words may take values from the stack, by popping them, and push return
values on the stack.  Besides words, you can also enter literal integer values
to push them onto the stack:

    TRUE 123 DUP .S ↲
    -1 123 123 OK[3]

where `TRUE` pushes -1, `123` pushes 123, `DUP` duplicates the TOS and `.S`
shows the stack values.  It helps to use `.S` to see what's currently on the
stack when debugging.  `OK[3]` indicates that currently there are three values
on the stack.  This may show as `OK[3 1]` when there is one floating point
value on the floating point stack indicated by the second number.

You can spread the code over multiple lines.  It does not matter if you hit
ENTER at the end or if you hit ENTER to input more than one line.

When an error occurred, an error message will be shown and a blinking cursor
will appear:

    1 0 / 2 + . ↲
    1 0 / <error -10

Press the left or right cursor key to edit the last line.  For a description
of the standard Forth error codes, see [exceptions](#exceptions).

To clear the stacks, type `CLEAR`:

    CLEAR ↲
    OK[0]

Like traditional Forth systems, Forth500 integers are 16-bit signed or
unsigned.  Decimal, hexadecimal and binary number systems are supported:

| input   | TOS | comment
| ------- | --- | --------------------------------------------------------------
| `TRUE`  |  -1 | Boolean true is -1
| `FALSE` |   0 | Boolean false is 0
| `123`   | 123 | decimal number (if the current base is `DECIMAL`)
| `-1`    |  -1 |
| `0`     |   0 |
| `$FF`   | 255 | hexadecimal number
| `#-12`  | -12 | decimal number (regardless of the current base)
| `%1000` |   8 | binary number
| `'A`    |  65 | ASCII code of letter A

Words for arithmetic like `+` pop the TOS and 2OS "Second on Stack" to return
the sum.  The `.` ("dot") word can then be used to print the TOS:

    1 2 + . ↲
    3 OK[0]

Two single stack integers can be combined to form a 32-bit signed or unsigned
integer.  A double integer number is pushed (as two single integers) when the
number is written with a `.` anywhere among the digits, but we prefer the `.`
at the end:

    123. 456. D+ D. ↲
    579 OK[0] 

The `D+` word adds two double integers and the `D.` word prints a signed double
integer and pops it from the stack.  Words that operate on two integers or
doubles are typically identified by `Dxxx` and `2xxx`.  See also [double
arithmetic](#double-arithmetic) and [numeric output](#numeric-output).

The use of `.` to mark double integers is unfortunate, because the number is
not a floating point number!  The `.` is traditional in Forth and still part of
the Forth standard.

Floating point numbers require an exponent `E` or `D` for double precision,
even when the exponent is zero, as for example in `1.23e+0` (the `E` and `D`
are case insensitive).  Floating point values are stored on a separate floating
point stack and have their own words for floating point arithmetic:

    12.3e0 45.6e0 F+ FDUP F. FS. ↲
    57.9 5.7900000000000000000E1 OK[0]

where `F.` displays the value in fixed-point notation without exponent and
`FS.` displays the value in scientific notation with 20 digits precision.  See
also [floating point stack manipulation](#floating-point-stack-manipulation),
[floating point arithmetic](#floating-point-arithmetic) and [numeric
output](#numeric-output).

Words that execute subroutines are defined with a `:` ("colon") and end with
a `;` ("semicolon"):

    : hello     ." Hello, World!" CR ; ↲

This defines the word `hello` that displays the obligatory "Hello, World!"
message.  Separating the word with its definition using tab spacing visually
assists to identify word definitions more easily.

The `."` word parses a sequence of character until `"`.  These characters are
displayed on screen.  Note that `."` is a normal word and must therefore be
followed by a space.  The `CR` word starts a new line by printing a carriage
return and newline.

Let's try it out:

    hello ↲
    Hello, World! OK[0]

Some words like `."` and `;` are compile-time only, which means that they can
only be used in colon definitions.  Two other compile-time words are `DO` and
`LOOP` for loops:

    : greetings     10 0 DO hello LOOP ; ↲
    greetings ↲

This displays 10 lines with "Hello, World!"  Let's add a word that takes a
number as an argument, then displays that many `hello` lines:

    : hellos    0 DO hello LOOP ; ↲
    2 hellos ↲
    Hello, World!
    Hello, World! OK[0]

Something interesting has happened here, that is typical Forth: `hellos` is the
same as `greetings` but without the `10` loop limit.  We just specify the loop
limit on the stack as an argument to `hellos`.  Therefore, we can refactor
`greetings` to use `hellos` by simply replacing `0 DO hello LOOP` by `hellos`:

    : greetings     10 hellos ; ↲

It is good practice to define words with short definitions.  It makes programs
much easier to understand, maintain and reuse.  Because words operate on the
stack, pretty much any sequence of words can be moved from a definition into a
new word to replace the sequence with a single word.  This keeps definitions
short and understandable.

But what if we want to change the message of `hellos`?  Forth allows you to
redefine words at any time, but this does not change the behavior of any
previously defined words that are used by other previously defined words:

    : hello     ." Hola, Mundo!" CR ; ↲
    2 hellos ↲
    Hello, World!
    Hello, World! OK[0]

Only new words that we add after this will use our new `hello` definition.
Basically, the Forth dictionary is searched from the most recently defined
word to the oldest defined word.  A definition of a word is no longer
searchable when a word with the same name is defined.

Definitions can be deleted with everything defined after it by forgetting:

    FORGET hello ↲

Because we defined two `hello` words, we should forget `hello` twice to delete
the new and the old `hello`.  Forgetting means that everything after the
specified word is deleted from the dictionary, including our `greetings` and
`hellos` definitions.  Another way to delete definitions is to define a
`MARKER` with `ANEW` for a section of code, see [markers](#markers).  Executing
a marker deletes it and everything after it.

To create a configurable `hello` word that displays alternative messages, we
can use branching based on the value of a variable:

    VARIABLE spanish ↲

`VARIABLE` parses the next word in the input and adds the word to the
dictionary as a variable, in this case `spanish`.

We rewrite our `hello` as follows:

    : hello ↲
      spanish @ IF ↲
        ." Hola, Mundo!" ↲
      ELSE ↲
        ." Hello, World!" ↲
      THEN CR ; ↲

If you are new to Forth this may look strange with the `IF` and `THEN` out of
place.  A `THEN` closes the `IF` (some Forth's allow both `ENDIF` and `THEN`).
By comparison to C, `spanish @ IF x ELSE y` is similar to `*spanish ? x : y`.
The variable `spanish` places the address of its value on the stack.  The value
is fetched (dereferenced) with the word `@` ("fetch").  If the value is nonzero
(true), then the statements after `IF` are executed.  Otherwise, the statements
after `ELSE` are executed.

To set the `spanish` variable to true:

    TRUE spanish ! ↲

where the word `!` ("store") stores the 2OS value to the memory cell addressed
by the TOS, which is the variable `spanish` in this example.

Observe this stack order carefully!  Otherwise you will end up writing data to
arbitrary memory locations.  The `!` reminds you of this potential danger.

For convenience, the words `ON` and `OFF` can be used:

    spanish OFF ↲
    spanish ? ↲
    0 OK[0]
    spanish ON ↲
    spanish ? ↲
    -1 OK[0]

The `?` word used in the example above is a shorthand for `@ .` to display the
value of a variable:

    : ? @ . ;

Like the built-in `?` word, a large portion of the Forth system is defined in
Forth itself.  Also `ON` and `OFF` are defined in Forth:

    : ON    TRUE SWAP ! ;
    : OFF   FALSE SWAP ! ;

where `SWAP` swaps the TOS and 2OS.

Instead of nesting multiple `IF`-`ELSE`-`THEN` branches to cover additional
languages, we should use `CASE`-`OF`-`ENDOF`-`ENDCASE` and enumerate the
languages as follows:

    0 CONSTANT #english ↲
    1 CONSTANT #spanish ↲
    2 CONSTANT #french ↲
    VARIABLE language #english language ! ↲
    : hello ↲
      language @ CASE ↲
        #english OF ." Hello, World!"  ENDOF ↲
        #spanish OF ." Hola, Mundo!"   ENDOF ↲
        #french  OF ." Salut Mondial!" ENDOF ↲
        ." Unknown language" ↲
      ENDCASE ↲
      CR ; ↲
    hello ↲
    Hello, World!

Note that the default case is not really necessary, but can be inserted between
the last `ENDOF` and `ENDCASE`.  In the default arm of a `CASE`, the `CASE`
value is the TOS, which can be inspected, but should not be dropped before
`ENDCASE`.

Unlike a `VARIABLE`, a `CONSTANT` word is initialized with the specified value
on the stack.  When the word is executed it pushes its value on the stack.  By
contrast, a word defined as a variable pushes the address of its value on the
stack, after which the value can be fetched with `@`.  A new value can be
stored with `!`.

So-called Forth value words offer the advantage of implicit fetches like
constants.  To illustrate value words, let's replace the `VARIABLE language`
with `VALUE language` initialized to `#english`:

    #english VALUE language ↲

To change the value we use the `TO` word followed by the name of the value:

    #spanish TO language ↲

Now with `language` as a `VALUE`, `hello` should be changed by removing the
`@` after `language`:

    : hello ↲
      language CASE ↲
      ...

Forth constants, variables and values contain data.  Data words are added
to the dictionary with `CREATE` followed by words to allocate space for the
data.  The word created returns the address pointing to its data:

    CREATE data ↲
    data . ↲
    <address> OK[0]

In this example `data` has no data allocated or stored, it just returns the
address of the location where the data would reside.  Because addresses of
words in the dictionary are unique, we can use this mechanism to create
"symbolic" enumerations to replace constants (and save some space):

    CREATE english ↲
    CREATE spanish ↲
    CREATE french ↲
    english TO language ↲

Working with `CREATE` and `DOES>` to create data types and data structures is a
more advanced topic.  See [CREATE and DOES>](#create-and-does) for details.
See also example [enums](#enums) for a more elaborate example.

Earlier we saw the `DO`-`LOOP`.  The loop iterates until its internal loop
counter when incremented *equals* the final value.  For example, this loop
executes `hello` 10 times:

    : greetings     10 0 DO hello LOOP ; ↲

Actually, `DO` cannot be recommended because the loop body is always executed
*at least once*.  When the initial value is the same as the final value we end
up executing the loop 65536 times! (Because integers wrap around.) We use `?DO`
instead of `DO` to avoid this problem:

    : hellos    0 ?DO hello LOOP ; ↲
    0 hellos ↲
    OK[0]

This example has zero loop iterations and never executes the loop body `hello`.

When we add more languages to `hello`, the `hello` definition code grows
substantially by the addition of lots of `OF`-`ENDOF` arms.  We should keep
Forth definitions short and concise.  To so so, we may want to reconsider
`hello` and change it to a "deferred word".  A deferred word can be assigned
another word, in this case to display a message in the selected language:

    DEFER hello ↲
    : hellos    0 ?DO hello LOOP ; ↲

The deferred `hello` word is assigned `hello-es` with `IS`:

    : hello-en  ." Hello, World!" CR ; ↲
    : hello-es  ." Hola, Mundo!" CR ; ↲
    : hello-fr  ." Salut Mondial!" CR ; ↲
    ' hello-es IS hello ↲
    2 hellos ↲
    Hola, Mundo!
    Hola, Mundo! OK[0]

The `'` "tick" parses the next word and returns its "execution token" on the
stack, which is assigned by `IS` to `hello`.  An execution token is the address
of the start of the code associated with a word.  Basically, a deferred word is
a variable that holds the execution token of another word.  When the deferred
`hello` executes, it takes this execution token and executes it with `EXECUTE`.

Think of execution tokens as function pointers in C and as call addresses in
assembly.  You can pass them around and store them in variables and tables to
be invoked later with `EXECUTE`.

We saw the use of a `?DO`-`LOOP` earlier.  To change the step size or direction
of the loop, we use `+LOOP`.  The word `I` returns the loop counter value:

    : evens     10 0 ?DO I . 2 +LOOP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

The `+LOOP` terminates if the updated counter equals or crosses the limit.  The
increment may be negative to count down.

A `BEGIN`-`WHILE`-`REPEAT` is a logically-controlled loop with which we can do
the same as follows by pushing a `0` to use as a counter on top of the stack:

    : evens ↲
      0 ↲
      BEGIN DUP 10 < WHILE ↲
        DUP . ↲
        2+ ↲
      REPEAT ↲
      DROP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

`DUP 10 <` is used for the `WHILE` test to check the TOS counter value is less
than 10.  After the loop terminates, `DROP` removes the TOS counter.

A `BEGIN`-`UNTIL` loop is similar, but executes the loop body at least once:

    : evens ↲
      0 ↲
      BEGIN ↲
        DUP . ↲
        2+ ↲
      DUP 10 < INVERT UNTIL ↲
      DROP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

Forth has no built-in `>=`, so we use `< INVERT`.  If you really want `>=`,
then define:

    : >=    < INVERT ; ↲

Until now we haven't commented our code.  Forth offers two words to comment
code, `( a comment goes here )` and `\ a comment until the end of the line`:

    : evens ( -- ) ↲
      0                     \ push counter 0 ↲
      BEGIN ↲
        DUP .               \ display counter value ↲
        2+                  \ increment counter ↲
      DUP 10 < INVERT UNTIL \ until counter >= 10 ↲
      DROP ;                \ drop counter ↲

Word definitions are typically annotated with their stack effect, in this case
there is no effect `( -- )`, see the next section on how this notation is used
in practice.

Forth source code is loaded from a file with `INCLUDE` or with `INCLUDED`:

    INCLUDE FLOATEXT.FTH ↲
    S" FLOATEXT.FTH" INCLUDED ↲

where `S" FLOATEXT.FTH"` specifies a string constant with the file name.  A
drive letter such as F: can be specified to load from a specific drive, which
becomes the current drive (the default drive is E:).

To compile a Forth source code file transmitted to the PC-E500 via the serial
interface:

    INCLUDE COM: ↲

To make sure that a file is included at most once, use `REQUIRE` or `REQUIRED`
instead of `INCLUDE` and `INCLUDED`, respectively:

    REQUIRE FLOATEXT.FTH ↲
    S" FLOATEXT.FTH" REQUIRED ↲

The name of the file will show up in the dictionary to record its presence, but
with a space appended to the name to distinguish it from executable words.

To compile a Forth source code file transmitted by a CE-126P or CE-124 cassette
interface to the PC-E500:

    CLOAD ↲

The wav file transmitted from the host computer, such as a PC, should be
created with [PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) from the
source code file (e.g. `FLOATEXT.FTH`) as follows:

    $ bin2wav --pc=E500 --type=bin -dINV FLOATEXT.FTH
    $ afplay FLOATEXT.wav

The `afplay` plays the wav file.  Use maximum volume or close to maximum to
avoid distortion.  If `-dINV` does not transfer the file, then try `-dMAX`.

To list files on the current drive:

    FILES ↲

You can also specify a drive with a glob pattern to list matching `FILES`:

    FILES F:*.FTH ↲

This lists all Forth .FTH source code files on the F: drive and makes the F:
drive the current drive.  Forth source files commonly use extension FTH or FS.
File names and extensions are case sensitive on the PC-E500(S), but drive names
are not.

This ends our introduction of the basics of Forth.

## Stack effects

To make it easier to document words that manipulate the stack, we use the
following Forth naming conventions to identify the types of values on the
stack:

| value    | represents
| -------- | -------------------------------------------------------------------
| _flag_   | the Boolean value true (nonzero, typically -1) or false (zero)
| _true_   | true flag (-1)
| _false_  | false flag (0)
| _n_      | a signed single integer -32768 to 32767
| _+n_     | a non-negative single integer 0 to 32767
| _u_      | an unsigned single integer 0 to 65535
| _x_      | an unspecified single integer
| _d_      | a signed double integer -2147483648 to 2147483647
| _+d_     | a non-negative double integer 0 to 2147483647
| _ud_     | an unsigned double integer 0 to 4294967295
| _xd_     | an unspecified double integer (two unspecified single integers)
| _r_      | a single or double precision floating point value on the floating point stack
| _addr_   | a 16-bit address
| _c-addr_ | a 16-bit address pointing to 8-bit character(s), usually a constant string
| _f-addr_ | a 16-bit address pointing to a floating point value
| _s-addr_ | a 16-bit address pointing to a file status structure (Forth500)
| _fileid_ | a nonzero single integer file identifier
| _ior_    | a single integer nonzero system-specific error code
| _fam_    | a file access mode
| _nt_     | a name token, address of the name of a word in the dictionary
| _xt_     | an execution token, address of code of a word in the dictionary

A single integer or address unit is also called a "cell" with a size of two
bytes in Forth500.

With these naming conventions for stack values, words are described by their
stack effect.  Values on the left of the -- are on the stack _before_ the word
is executed and the values on the right of the -- are on the stack _after_ the
word is executed:

`OVER` ( _x1_ _x2_ -- _x1_ _x2_ _x1_ )

Words that create other words on the dictionary parse the name of a new word.
For example, `CREATE` parses a word at "compile time".  This word leaves the
address of its body (a data field) on the stack at "run time".  This is denoted
by two effects separated by a semi-colon `;`, the first effect occurs at
compile time and the second effect occurs at run time:

`CREATE` ( "name" -- ; -- _addr_ )

A quoted part such as "name" are parsed from the input and not taken from the
stack.

Return stack effects are prefixed with `R:`.  For example:

`>R` ( _x_ -- ; R: -- _x_ )
`R>` ( R: _x_ -- ; -- _x_ )

The word `>R` ("to r") moves _x_ from the stack to the so-called "return
stack".  The word `R>` ("r from") moves _x_ from the return stack to the stack.

The return stack is used to keep return addresses of words executed and to
store temporary values.  When using the return stack to store values
temporarily in your code, it is very important to keep the return stack
balanced.  This prevents words from returning to an incorrect return address
and crashing the system.

## Stack manipulation

The following words manipulate values on the stack:

| word   | stack effect ( _before_ -- _after_ ) | comment
| ------ | ------------------------------------ | ------------------------------
| `DUP`  | ( _x_ -- _x_ _x_ )                   | duplicate TOS
| `?DUP` | ( _x_ -- _x_ _x_ ) or ( 0 -- 0 )     | duplicate TOS if nonzero
| `DROP` | ( _x_ -- )                           | drop the TOS
| `SWAP` | ( _x1_ _x2_ -- _x2_ _x1_ )           | swap TOS with 2OS
| `OVER` | ( _x1_ _x2_ -- _x1_ _x2_ _x1_ )      | duplicate 2OS to the top
| `NIP`  | ( _x1_ _x2_ -- _x2_ )                | delete 2OS
| `TUCK` | ( _x1_ _x2_ -- _x2_ _x1_ _x2_ )      | tuck a copy of TOS under 2OS
| `ROT`  | ( _x1_ _x2_ _x3_ -- _x2_ _x3_ _x1_ ) | rotate stack, 3OS goes to TOS
| `-ROT` | ( _x1_ _x2_ _x3_ -- _x3_ _x1_ _x2_ ) | rotate stack, TOS goes to 3OS

Note that `NIP` is the same as `SWAP DROP`, `TUCK` is the same as `DUP -ROT`,
and `-ROT` ("not rot") is the same as `ROT ROT`.

There are also two words to reach deeper into the stack:

| word   | stack effect ( _before_ -- _after_ )         | comment
| ------ | -------------------------------------------- | ----------------------
| `PICK` | ( _xk_ ... _x0_ _k_ -- _xk_ ... _x0_ _xk_ )  | duplicate k'th value down to the top
| `ROLL` | ( _xk_ ... _x0_ _k_ -- _xk-1_ ... _x0_ _xk_) | rotate the k'th value down to the top

Note that `0 PICK` is the same as `DUP`, `1 PICK` is the same as `OVER`, `1
ROLL` is the same as `SWAP`, `2 ROLL` is the same as `ROT` and `0 ROLL` does
nothing.

Note: `PICK` and `ROLL` take _k_ _mod_ 128 cells max as a precaution.

The following words operate on two cells on the stack at once (a pair of single
integers or one double integer):

| word    | stack effect ( _before_ -- _after_ )
| ------- | -------------------------------------------------------------------
| `2DUP`  | ( _x1_ _x2_ -- _x1_ _x2_ _x1_ _x2_ )
| `2DROP` | ( _x1_ _x2_ -- )
| `2SWAP` | ( _x1_ _x2_ _x3_ _x4_ -- _x3_ _x4_ _x1_ _x2_ )
| `2OVER` | ( _x1_ _x2_ _x3_ _x4_ -- _x1_ _x2_ _x3_ _x4_ _x1_ _x2_ )
| `2NIP`  | ( _x1_ _x2_ _x3_ _x4_ -- _x3_ _x4_ )
| `2TUCK` | ( _x1_ _x2_ _x3_ _x4_ -- _x3_ _x4_ _x1_ _x2_ _x3_ _x4_ )
| `2ROT ` | ( _x1_ _x2_ _x3_ _x4_ _x5_ _x6_ -- _x3_ _x4_ _x5_ _x6_ _x1_ _x2_ )

Other words related to the stack:

| word    | stack effect           | comment
| ------- | ---------------------- | -------------------------------------------
| `CLEAR` | ( ... -- ; F: ,,, -- ) | clears the stack and the floating point stack
| `DEPTH` | ( -- _n_ )             | returns the current depth of the stack
| `.S`    | ( -- )                 | displays the stack contents
| `N.S`   | ( _n_ -- )             | displays the top _n_ values on the stack
| `SP@`   | ( -- _addr_ )          | returns the stack pointer, points to the TOS
| `SP!`   | ( _addr_ -- )          | assigns the stack pointer (danger!)

`DEPTH` returns the current depth of the stack, which is the number of cells on
the stack not counting the depth value returned on the stack.  The maximum
stack depth in Forth500 is 128 cells or 64 double cells.

### Floating point stack manipulation

The following words manipulate values on the floating point stack:

| word     | stack effect ( _before_ -- _after_ )    | comment
| -------- | --------------------------------------- | -------------------------
| `FDUP`   | ( F: _r_ -- _r_ _r_ )                   | duplicate FP TOS
| `FDROP`  | ( F: _r_ -- )                           | drop the FP TOS
| `FSWAP`  | ( F: _r1_ _r2_ -- _r2_ _r1_ )           | swap FP TOS with FP 2OS
| `FOVER`  | ( F: _r1_ _r2_ -- _r1_ _r2_ _r1_ )      | duplicate FP 2OS to the top
| `FROT`   | ( F: _r1_ _r2_ _r3_ -- _r2_ _r3_ _r1_ ) | rotate stack, FP 3OS goes to FP TOS
| `CLEAR`  | ( ... -- ; F: ,,, -- )                  | clears the stack and the floating point stack
| `FDEPTH` | ( -- _n_ )                              | returns the current depth of the floating point stack
| `FP@`    | ( -- _addr_ )                           | returns the floating point stack pointer, points to the FP TOS
| `FP!`    | ( _addr_ -- )                           | assigns the floating point stack pointer (danger!)

`FDEPTH` returns the current depth of the floating point stack, which is the
number of floats on the stack.  The maximum floating point stack depth in
Forth500 is 120 bytes or 10 floating point values.

## Integer constants

Integer values when parsed from the input are directly pushed on the stack.
The current `BASE` is used for conversion:

| word        | comment
| ----------- | ----------------------------------------------------------------
| `BASE`      | a `VARIABLE` holding the current base, valid values range from 2 to 36
| `DECIMAL`   | set `BASE` to 10
| `HEX`       | set `BASE` to 16
| `#d`...`d`  | a decimal single integer, ignores current `BASE`
| `#-d`...`d` | a negative decimal single integer, ignores current `BASE`
| `$h`...`h`  | a hex single integer, ignores current `BASE`
| `$-h`...`h` | a negative hex single integer, ignores current `BASE`
| `%b`...`b`  | a binary single integer, ignores current `BASE`
| `%-b`...`b` | a negative binary single integer, ignores current `BASE`

Valid single integer constant values range from -32768 to 65535.  The unsigned
integer range 32768 to 65535 is the same signed integer range -1 to -32768.

The signedness of an integer only applies to the way the integer value is used
by a word.  For example, `-1 U.` displays 65535, because `U.` takes an unsigned
integer to display and -1 is the same as 65535 (two's complement).

Double integer values have a `.` (dot) anywhere placed among the digits.  For
example, `-1.` is double integer pushed on the stack, occupying the top pair of
consecutive cells on the stack, i.e. the TOS and 2OS with TOS holding the
16 high-order bits and 2OS holding the 16 low-order bits.  The `.` (dot) is
typically placed at the end of the digits.

A word defined in the dictionary with a name that matches a number will be
evaluated instead of the number.  Therefore, it makes sense to avoid defining
words with numeric names.

When the current `BASE` is not decimal, such as `HEX`, words in the dictionary
may match instead of the integer constant specified.  For example, `F.` is a
valid double integer value in `HEX` but the `F.` word will output a float
instead.

The ASCII value of a single character is pushed on the stack with `'char'`.
The quoted form `'char` can be used interactively and to compile a literal:

| word       | comment
| ---------- | -----------------------------------------------------------------
| `'A'`      | ASCII code 65 of letter A
| `'B`       | ASCII code 66 of letter B, the closing quote may be omitted
| `CHAR C`   | ASCII code 67 of letter C, use this word interactively
| `[CHAR] D` | ASCII code 68 of letter D, use this word to compile a literal

The quoted form is essentially the same as `CHAR` or `[CHAR]` depending on the
current `STATE`.

The following words define common constants regardless of the current `BASE`:

| word    | comment
| ------- | --------------------------------------------------------------------
| `BL`    | the space character, ASCII 32
| `FALSE` | Boolean false, same as 0
| `TRUE`  | Boolean true, same as -1

### Floating point constants

Floating point values are parsed in base 10.  Floating point values are not
parsed if the `BASE` is anything other than `DECIMAL`.  Exception -13 will be
thrown instead, when the unrecognized word is not found in the dictionary.

Floating point values when parsed from the input are directly pushed on the
floating point stack.  Floating point values must include a `E` or `D`
exponent.  An `E` exponent marks a single precision floating point value (see
note below).  A `D` exponent marks a double precision floating point value with
up to 20 significant digits.  The `E` and `D` exponent ranges from -99 to +99.

| word                       | comment
| -------------------------- | ------------------------------------------------
| `3.141592654e+0`           | single precision pi
| `3.1415926535897932385d+0` | double precision pi
| `3.1415926535897932385e+0` | double precision pi (exceeds 10 digits)
| `9.9999999999999999999d99` | maximum double precision value
| `-1.234e-10`               | single precision -0.0000000001234
| `1e0`                      | single precision 1
| `0e`                       | single precision 0
| `0d`                       | double precision 0

Note that exponent `e+0` may be abbreviated to `e0` or just `e`.  A floating
point value may not start with a decimal point `.`.  The formal syntax is:

    <float>             := <significand> [ <exponent> ]
    <significand>       := [ <sign> ] <digit>+ [ . <digit>* ]
    <exponent>          := {E|e|D|d} [ <sign> ] [ <digit> ] [ <digit> ]
    <sign>              := {+|-}
    <digit>             := {0|1|2|3|4|5|6|7|8|9}

If the number of significant digits exceeds 10, then the floating point value
is stored in double precision format even when marked with an `e`.  Digits are
considered significant after removing all leading zeros, including zeros to the
right of the decimal point.  For example, `0.001234567890e` is a single
precision value because it has 10 significant digits (this differs with the
PC-E500(S) BASIC where zero digits after the decimal point are considered
significant) and `0.0012345678900e` is a double precision value because it has
11 significant digits.

Forth500 floating point operations are performed on both single and double
precision floating point values.  A double precision value is returned if one
of the operands is a double precision value.

The `0e+0` word is predefined.  This word takes only 2 bytes of code space
instead of the 14 bytes to store floating point literals in code (2 bytes code
plus 12 bytes for the float).  To save memory, you can also use `S>F` and `D>F`
to push small whole numbers on the floating point stack, which require only 6
bytes and 8 bytes of code space, respectively.

A floating point value requires 12 bytes of storage for the sign, exponent and
the binary-coded decimal mantissa with 10 or 20 digits:

(sign)(exp)(BCD0)(BCD1)(BCD2)(BCD3)(BCD4)(BCD5)(BCD6)(BCD7)(BCD8)(BCD9) 

- the (sign) byte bit 0 is set to mark double precision values
- the (sign) byte bit 3 is set to mark negative values
- the (exp) byte is a 2s-complement integer in the range [-99,99]
- a single precision floating point value uses (BCD0) to (BCD4) and may use
  (BCD5) and (BCD6) to store so-called guard digits that are not displayed.  A
  double precision floating point value uses (BCD0) to (BCD9)

To view the internal format of a floating point value on the stack:

    FP@ 12 DUMP ↲

All digits are stored, including the 2 or 3 guard digits of a single precision
value.  Up to 10 significant digits of a single precision values are displayed.
This means that comparisons for equality may fail even though the numbers
displayed look equal.

The maximum depth of the floating point stack in Forth500 is 120 bytes to hold
up to 10 floating point values.

## Arithmetic

### Single arithmetic

The following words perform single integer (one cell) arithmetic operations.
Words involving division and modulo may throw exception -10 "Division by zero":

| word     | stack effect ( _before_ -- _after_ )
| -------- | -------------------------------------------------------------------
| `+`      | ( _x1_ _x2_ -- (_x1_+_x2_) )
| `-`      | ( _x1_ _x2_ -- (_x1_-_x2_) )
| `*`      | ( _n1_ _n2_ -- (_n1_\*_n2_) )
| `/`      | ( _n1_ _n2_ -- (_n1_/_n2_) )
| `MOD`    | ( _n1_ _n2_ -- (_n1_%_n2_) )
| `/MOD`   | ( _n1_ _n2_ -- (_n1_%_n2_) (_n1_/_n2_) )
| `*/`     | ( _n1_ _n2_ _n3_ -- (_n1_\*_n2_/_n3_) )
| `*/MOD`  | ( _n1_ _n2_ _n3_ -- (_n1_\*_n2_%_n3_) (_n1_\*_n2_/_n3_) )
| `MAX`    | ( _n1_ _n2_ -- _n1_ ) if _n1_>_n2_ otherwise ( _n1_ _n2_ -- _n2_ )
| `UMAX`   | ( _u1_ _u2_ -- _u1_ ) if _u1_>_u2_ unsigned otherwise ( _u1_ _u2_ -- _u2_ )
| `MIN`    | ( _n1_ _n2_ -- _n1_ ) if _n1_<_n2_ otherwise ( _n1_ _n2_ -- _n2_ )
| `UMIN`   | ( _u1_ _u2_ -- _u1_ ) if _u1_<_u2_ unsigned otherwise ( _u1_ _u2_ -- _u2_ )
| `AND`    | ( _x1_ _x2_ -- (_x1_&_x2_) )
| `OR`     | ( _x1_ _x2_ -- (_x1_\|_x2_) )
| `XOR`    | ( _x1_ _x2_ -- (_x1_^_x2_) )
| `ABS`    | ( _n_ -- _+n_ )
| `NEGATE` | ( _n_ -- (-_n_) )
| `INVERT` | ( _x_ -- (~_x_) )
| `1+`     | ( _x_ -- (_x_+1) )
| `2+`     | ( _x_ -- (_x_+2) )
| `1-`     | ( _x_ -- (_x_-1) )
| `2-`     | ( _x_ -- (_x_-2) )
| `2*`     | ( _n_ -- (_n_\*2) )
| `2/`     | ( _n_ -- (_n_/2) )
| `LSHIFT` | ( _u_ _+n_ -- (_u_<<_+n_) )
| `RSHIFT` | ( _u_ _+n_ -- (_u_>>_+n_) )

The _after_ stack effects in the table indicate the result computed with
operations % (mod), & (bitwise and), | (bitwise or), ^ (bitwise xor), ~
(bitwise not/invert), << (bitshift left) and >> (bitshift right).

Integer overflow and underflow does not throw exceptions.  In case of integer
addition and subtraction, values wrap around.  For all other integer
operations, overflow and underflow produce undefined values.

The `MOD`, `/MOD`, and `*/MOD` words return a remainder on the stack.  The
quotient _q_ and remainder _r_ satisfy _q_ = _floor_(_a_ / _b_) such that
_a_ = _b_ \* _q_ + _r_ , where _floor_ rounds towards zero.  The `MOD` is
symmetric, i.e. `10 7 MOD` and `-10 7 MOD` return 3 and -3, respectively.  See
also `FM/MOD` and `SM/MOD` [mixed arithmetic](#mixed-arithmetic).

The `*/` and `*/MOD` words produce an intermediate double integer product to
avoid intermediate overflow.  Therefore, `*/` is not a shorthand for the two
words `* /`, which would truncate an overflowing product to a single integer.
For example, `radius 355 * 113 /` with 355/133 to approximate pi overflows
when `radius` exceeds 92, but `radius 355 113 */` gives the correct result.

A logical `NOT` word not available.  Either `INVERT` should be used to invert
bits or `0=` should be used, which returns `TRUE` for `0` and `FALSE`.

### Double arithmetic

The following words perform double integer arithmetic operations.  Words
involving division and modulo may throw exception -10 "Division by zero":

| word      | stack effect ( _before_ -- _after_ )
| --------- | ------------------------------------------------------------------
| `D+`      | ( _d1_ _d2_ -- (_d1_+_d2_) )
| `D-`      | ( _d1_ _d2_ -- (_d1_-_d2_) )
| `D*`      | ( _d1_ _d2_ -- (_d1_\*_d2_) )
| `D/`      | ( _d1_ _d2_ -- (_d1_/_d2_) )
| `DMOD`    | ( _d1_ _d2_ -- (_d1_%_d2_) )
| `D/MOD`   | ( _d1_ _d2_ -- (_d1_%_d2_) (_d1_/_d2_) )
| `DMAX`    | ( _d1_ _d2_ -- _d1_ ) if _d1_>_d2_ otherwise ( _d1_ _d2_ -- _d2_ )
| `DMIN`    | ( _d1_ _d2_ -- _d1_ ) if _d1_<_d2_ otherwise ( _d1_ _d2_ -- _d2_ )
| `DABS`    | ( _d_ -- _+d_ )
| `DNEGATE` | ( _d_ -- (-_d_) )
| `D2*`     | ( _d_ -- (_d_\*2) )
| `D2/`     | ( _d_ -- (_d_/2) )
| `S>D`     | ( _n_ -- _d_ )
| `D>S`     | ( _d_ -- _n_ )

The `D>S` word converts a signed double to a signed single integer, throwing
exception -11 "Result out of range" if the double value cannot be converted.

To convert an unsigned single integer to an unsigned double integer, just push
a `0` on the stack.

Integer overflow and underflow does not throw exceptions.  In case of integer
addition and subtraction, values simply wrap around.  For all other integer
operations, overflow and underflow produce undefined values.

### Mixed arithmetic

The following words cover mixed single and double integer arithmetic
operations.  Words involving division may throw exception -10 "Division by
zero".

| word     | stack effect ( _before_ -- _after_ )     | comment
| -------- | ---------------------------------------- | ------------------------
| `M+`     | ( _d_ _n_ -- (_d_+_n_) )                 | add signed single to signed double
| `M-`     | ( _d_ _n_ -- (_d_-_n_) )                 | subtract signed single from signed double
| `M*`     | ( _n1_ _n2_ -- (_n1_\*_n2_) )            | multiply signed singles to return signed double
| `UM*`    | ( _u1_ _u2_ -- (_u1_\*_u2_) )            | multiply unsigned singles to return unsigned double
| `UMD*`   | ( _ud_ _u_ -- (_ud_\*_u_) )              | multiply unsigned double and single to return unsigned double
| `M*/`    | ( _d_ _n_ _+n_ -- (_d_\*_n_/_+n_) )      | multiply signed double with signed single then divide by positive single to return signed double
| `UM/MOD` | ( _u1_ _u2_ -- (_u1_%_u2_) (_u1_/_u2_) ) | unsigned single remainder and quotient of unsigned single division
| `FM/MOD` | ( _d_ _n_ -- (_d_%_n_) (_d_/_n_) )       | floored single remainder and single quotient of signed double and single division
| `SM/REM` | ( _d_ _n_ -- (_d_%_n_) (_d_/_n_) )       | symmetric single remainder and single quotient of signed double and single division

The `UM/MOD`, `FM/MOD`, and `SM/REM` words return a remainder on the stack.  In
all cases, the quotient _q_ and remainder _r_ satisfy _a_ = _b_ \* _q_ + _r_,

In case of `FM/MOD`, the quotient is a single signed integer rounded towards
negative _q_ = _floor_(_a_ / _b_).  For example, `-10. 7 FM/MOD` returns
remainder 4 and quotient -2.

In case of `SM/REM`, the quotient is a single signed integer rounded towards
zero (hence symmetric) _q_ = _trunc_(_a_ / _b_). For example, `-10. 7 SM/REM`
returns remainder -3 and quotient -1.  This behavior is identical to `/MOD`,
but `/MOD` behavior may differ on other Forth systems.

### Fixed point arithmetic

Fixed point offers an alternative to floating point if the range of values
manipulated can be fixed to a few digits after the decimal point.  Scaling of
values must be applied when appropriate.

A classic example is pi to compute the circumference of a circle using a
rational approximation of pi and a fixed point radius with a 2 digit fraction.

    : pi*   355 113 M*/ ; ↲
    12.00 2VALUE radius ↲
    radius 2. D* pi* D. ↲
    7539 OK[0]

This computes 12*2*pi=75.39.  Note that the placement of `.` in `12.00` has no
meaning at all, it is just suggestive of a decimal value with a 2 digit
fraction.

Multiplying the fixed point value `radius` by the double integer `2.` does not
require scaling of the result.  Addition and subtraction with `D+` and `D-`
do not require scaling either.  However, multiplying and dividing two fixed
point numbers requires scaling the result, for example with a new word:

    : *.00  D* 100. D/ ; ↲
    radius radius *.00 pi* D. ↲
    45238 OK[0]

There is a risk of overflowing the intermediate product when the multiplicants
are large.  If this is a potential hazard then note that this can be avoided by
scaling the multiplicants instead of the result with a small loss in precision
of the result:

    : 10./  10. D/ ; ↲
    : *.00  10./ 2SWAP 10./ D* ; ↲

Likewise, fixed point division requires scaling.  One way to do this is
by scaling the divisor down by 10 and the dividend up by 10 before dividing:

    : /.00  10./ 2SWAP 10. D* 2SWAP D/ ;

### Floating point arithmetic

The following words cover floating point arithmetic operations.  The words
accept single and double precision floating point numbers on the floating point
stack (the F: stack effects):

| word      | stack effect ( _before_ -- _after_ )
| --------- | ------------------------------------------------------------------
| `F+`      | ( F: _r1_ _r2_ -- _r1_+_r2_ )
| `F-`      | ( F: _r1_ _r2_ -- _r1_-_r2_ )
| `F*`      | ( F: _r1_ _r2_ -- _r1_\*_r2_ )
| `F/`      | ( F: _r1_ _r2_ -- _r1_/_r2_ )
| `F**`     | ( F: _r1_ _r2_ -- _r1_\*\*_r2_ )
| `FMAX`    | ( F: _r1_ _r2_ -- _r1_ ) if _r1_>_r2_ otherwise ( F: _r1_ _r2_ -- _r2_ )
| `FMIN`    | ( F: _r1_ _r2_ -- _r1_ ) if _r1_<_r2_ otherwise ( F: _r1_ _r2_ -- _r2_ )
| `FABS`    | ( F: _r_ -- +_r_ )
| `FSIGN`   | ( F: _r_ -- 0e+0 ) if _r_=0 or ( F: _r_ -- 1e+0 ) if _r_>0 otherwise ( F: _r_ -- -1e+0 )
| `FNEGATE` | ( F: _r_ -- -_r_ )
| `FLOOR`   | ( F: _r_ -- ⌊_r_⌋ ) round towards negative infinity
| `FROUND`  | ( F: _r_ -- [_r_+5e-1⌋ )
| `FTRUNC`  | ( F: _r_ -- [_r_] ) round towards zero
| `FSIN`    | ( F: _r_ -- sin(_r_) )
| `FCOS`    | ( F: _r_ -- cos(_r_) )
| `FTAN`    | ( F: _r_ -- tan(_r_) )
| `FASIN`   | ( F: _r_ -- arcsin(_r_) )
| `FACOS`   | ( F: _r_ -- arccos(_r_) )
| `FATAN`   | ( F: _r_ -- arctan(_r_) )
| `FLOG`    | ( F: _r_ -- log10(_r_) )
| `FLN`     | ( F: _r_ -- log(_r_) )
| `FEXP`    | ( F: _r_ -- e\*\*_r_ )
| `FSQRT`   | ( F: _r_ -- √ _r_ )
| `FDEG`    | ( F: _r1_ -- _r2_ ) where _r1_ is in dd.mmss format and _r2_ is degrees
| `FDMS`    | ( F: _r1_ -- _r2_ ) where _r1_ is degrees and _r2_ is in dd.mmss format
| `FRAND`   | ( F: _r1_ -- _r2_ ) where _r2_ is a pseudo-random number, see below
| `F>D`     | ( F: _r_ -- ; -- _d_ ) or ( F: _r_ -- ; -- _ud_ ) with _r_ converted to _d_ or _ud_
| `D>F`     | ( _d_ -- ; F: -- _r_ ) with _d_ converted to _r_
| `F>S`     | ( F: _r_ -- ; -- _n_ ) or ( F: _r_ -- ; -- u ) with _r_ converted to _n_ or _u_
| `S>F`     | ( _n_ -- ; F: -- _r_ ) with _n_ converted to _r_

If any of the operands of an arithmetic operation are double precision, then
the result of the operation is a double precision floating point value.  For
example, `0d F+` promotes a single precision value to a double precision
value by adding a double precision zero.

Floating point operations in single precision are performed with 12 or 13
digits (10 + 2 or 3 guard digits).  All digits are stored and passed on to
subsequent floating point operations.  However, only up to 10 significant
digits of a single precision floating point value are displayed.

`F**` returns _r1_ to the power _r2_.

`FLOOR` returns _r_ truncated towards negative values, for example `-1.5e
FLOOR` returns -2e+0.  `FTRUNC` returns _r_ truncated towrds zero, for example
`-1.5e+0 FTRUNC` returns -1e+0.

`FDMS` returns the degrees (or hours) dd with the minutes mm and seconds ss as
a fraction.  `FDEG` performs the opposite.  For example, `36.09055e0 FDMS`
returns 36.052598 or 36° 5' 25.98".  The `FDEG` and `FDMS` words are also
useful for time conversions.

`FRAND` returns a pseudo-random number in the open range _r2_ ∈ (0,1) if
_r1_<1e and in the closed range _r2_ ∈ [1,_r1_] otherwise.  A double precision
pseudo-random number is returned when _r1_ is a double precision floating point
value.

`F>D` throws an exception when the floating point value _r_ is too large for an
unsigned 32 bit integer, i.e. when |_r_|>4294967295.  Likewise, `F>S` throws an
exception when _r_ is too large for an unsigned 16 bit integer, i.e. when
|_r_|>65535.

Trigonometric functions are performed in the current angular unit (DEG, RAD or
GRAD).  You can use the BASIC interpreter to set the desired angular unit or
define a word to scale degrees and radians to the current unit before applying
a trigonometric function:

    3.141592654e FCONSTANT PI
    : ?>dbl     FP@ FLOAT+ C@ 1 AND FP@ C@ OR FP@ C! ;
    : deg>      90e F/ 0e+0 ?>dbl FACOS F* ;
    : rad>      FDUP F+ PI F/ 0e+0 ?>dbl FACOS F* ;
    : >deg      0e+0 ?>dbl FACOS F/ 90e F* ;
    : >rad      0e+0 ?>dbl FACOS FDUP F+ F/ PI F* ;

For example, `30e deg> FSIN` ("30 degree from sine") and `PI 6e F/ rad> FSIN`
both return 0.5e+0 on the floating point stack regardless of the current
angular unit.  Likewise `0.5E FASIN >deg` ("half arcsine to degree") returns
30.0e+0 on the floating point stack regardless of the current angular unit.
The `?>dbl` word promotes the FP TOS to a double if the FP 2OS is a double.
This word allows angular unit conversion words to support both single and
double precision floating point values.  See [floating point
constants](#floating-point-constants) for the internal floating point format.

The following additional floating point extended word set definitions are not
built in Forth500 and defined in `FLOATEXT.FTH`.  These words apply to both
single and double floating point values.  For these definitions we do not need
`?>DBL`:

    : FSINCOS   FDUP FSIN FSWAP FCOS ;
    : FALOG     10e FSWAP F** ;
    : FCOSH     FEXP FDUP 1e FSWAP F/ F+ 2e F/ ;
    : FSINH     FEXP FDUP 1e FSWAP F/ F- 2e F/ ;
    : FTANH     FDUP F+ FEXP FDUP 1e F- FSWAP 1e F+ F/ ;
    : FACOSH    FDUP FDUP F* 1e F- FSQRT F+ FLN ;
    : FASINH    FDUP FDUP F* 1e F+ FSQRT F+ FLN ;
    : FATANH    FDUP 1e F+ FSWAP 1e FSWAP F- F/ FLN 2e F/ ;
    : FATAN2    ( F: r1 r2 -- r3 )
      FDUP F0> IF
        F/ FATAN
      ELSE FSWAP FDUP F0<> IF
        FDUP FSIGN FASIN FROT FROT F/ FATAN F-
      ELSE
        FDROP F0< S>F FACOS THEN THEN ;
    : F~        ( F: r1 r2 r3 -- ; -- flag )
      FDUP F0= IF FDROP F= EXIT THEN
      FDUP F0< IF FROT FROT FOVER FOVER F- FROT FABS FROT FABS F+ FROT FABS F* F< EXIT THEN
      FROT FROT F- FABS F< ;

The `F~` word compares two floating point values with the specified precision.
If _r3_ is zero, then _flag_ is _true_ if _r1_ and _r2_ are equal.  If _r3_ is
negative, then _flag_ is _true_ if the absolute value of (_r1_ minus _r2_) is
less than the absolute value of _r3_ times the sum of the absolute values of
_r1_ and _r2_.  If _r3_ is positive, then _flag_ is _true_ if the absolute
value of (_r1_ minus _r2_) is less than _r3_.

To check if a floating point value is a double precision value, define:

    : DBL?      FP@ C@ 1 AND NEGATE ;

`DBL?` returns true if the value is double precision.

To promote a single to a double on the floating point stack, just add `0d` or
define:

    : E>D       FP@ C@ 1 OR FP@ C! ;

To demote a double to a single on the floating point stack by truncation:

    : D>E       FP@ C@ $fe AND FP@ C! FP@ 7 + 5 ERASE ;

### Numeric comparisons

The following words return true (-1) or false (0) on the stack by comparing
integer values:

| word     | stack effect ( _before_ -- _after_ )
| -------- | -------------------------------------------------------------------
| `<`      | ( _n1_ _n2_ -- true ) if _n1_<_n2_ otherwise ( _n1_ _n2_ -- false )
| `>`      | ( _n1_ _n2_ -- true ) if _n1_>_n2_ otherwise ( _n1_ _n2_ -- false )
| `=`      | ( _x1_ _x2_ -- true ) if _x1_=_x2_ otherwise ( _x1_ _x2_ -- false )
| `<>`     | ( _x1_ _x2_ -- true ) if _x1_<>_x2_ otherwise ( _x1_ _x2_ -- false )
| `U<`     | ( _u1_ _u2_ -- true ) if _u1_<_u2_ otherwise ( _u1_ _u2_ -- false )
| `U>`     | ( _u1_ _u2_ -- true ) if _u1_>_u2_ otherwise ( _u1_ _u2_ -- false )
| `D<`     | ( _d1_ _d2_ -- true ) if _d1_<_d2_ otherwise ( _d1_ _d2_ -- false )
| `D>`     | ( _d1_ _d2_ -- true ) if _d1_>_d2_ otherwise ( _d1_ _d2_ -- false )
| `D=`     | ( _xd1_ _xd2_ -- true ) if _xd1_=_xd2_ otherwise ( _xd1_ _xd2_ -- false )
| `D<>`    | ( _xd1_ _xd2_ -- true ) if _xd1_<>_xd2_ otherwise ( _xd1_ _xd2_ -- false )
| `DU<`    | ( _ud1_ _ud2_ -- true ) if _ud1_<_ud2_ otherwise ( _ud1_ _ud2_ -- false )
| `DU>`    | ( _ud1_ _ud2_ -- true ) if _ud1_>_ud2_ otherwise ( _ud1_ _ud2_ -- false )
| `0<`     | ( _n_ -- true ) if _n_<0 otherwise ( _n_ -- false )
| `0>`     | ( _n_ -- true ) if _n_>0 otherwise ( _n_ -- false )
| `0=`     | ( _x_ -- true ) if _x_=0 otherwise ( _x_ -- false )
| `0<>`    | ( _x_ -- true ) if _x_<>0 otherwise ( _x_ -- false )
| `D0<`    | ( _d_ -- true ) if _d_<0 otherwise ( _d_ -- false )
| `D0>`    | ( _d_ -- true ) if _d_>0 otherwise ( _d_ -- false )
| `D0=`    | ( _xd_ -- true ) if _xd_=0 otherwise ( _xd_ -- false )
| `D0<>`   | ( _xd_ -- true ) if _xd_<>0 otherwise ( _xd_ -- false )
| `WITHIN` | ( _n1_\|_u1_ _n2_\|_u2_ _n3_\|_u3_ -- flag )

The `WITHIN` word applies to signed and unsigned single integers on the stack,
represented by _n_|_u_.  True is returned if the value _n1_|_u1_ is in the range
_n2_|_u2_ inclusive to _n3_|_u3_ exclusive.  For exanple:

    5 -1 10 WITHIN . ↲
    -1 OK[0]
    5 6 10 WITHIN . ↲
    0 OK[0]
    5 -1 5 WITHIN . ↲
    0 OK[0]

More specifically, `WITHIN` performs a comparison of a test value _n1_|_u1_
with an inclusive lower limit _n2_|_u2_ and an exclusive upper limit _n3_|_u3_,
returning true if either (_n2_|_u2_ < _n3_|_u3_ and (_n2_|_u2_ <= _n1_|_u1_ and
_n1_|_u1_ < _n3_|_u3_)) or (_n2_|_u2_ > _n3_|_u3_ and (_n2_|_u2_ <= _n1_|_u1_
or _n1_|_u1_ < _n3_|_u3_)) is true, returning false otherwise.

The following words return true (-1) or false (0) on the stack by comparing
floating point values on the floating point stack:

| word   | stack effect ( _before_ -- _after_ )
| ------ | ---------------------------------------------------------------------
| `F<`   | ( F: _r1_ _r2_ -- ; -- _true_ ) if _r1_<_r2_ otherwise ( F: _r1_ _r2_ -- ; -- _false_ )
| `F>`   | ( F: _r1_ _r2_ -- ; -- _true_ ) if _r1_>_r2_ otherwise ( F: _r1_ _r2_ -- ; -- _false_ )
| `F=`   | ( F: _r1_ _r2_ -- ; -- _true_ ) if _r1_=_r2_ otherwise ( F: _r1_ _r2_ -- ; -- _false_ )
| `F<>`  | ( F: _r1_ _r2_ -- ; -- _true_ ) if _r1_<>_r2_ otherwise ( F: _r1_ _r2_ -- ; -- _false_ )
| `F0<`  | ( F: _r_ -- ; -- _true_ ) if _r_<0e otherwise ( F: _r_ -- ; -- _false_ )
| `F0>`  | ( F: _r_ -- ; -- _true_ ) if _r_>0e otherwise ( F: _r_ -- ; -- _false_ )
| `F0=`  | ( F: _r_ -- ; -- _true_ ) if _r_=0e otherwise ( F: _r_ -- ; -- _false_ )
| `F0<>` | ( F: _r_ -- ; -- _true_ ) if _r_<>0e otherwise ( F: _r_ -- ; -- _false_ )

Floating point operations in single precision are performed with 12 or 13
digits (10 + 2 or 3 guard digits).  All digits are stored, but only up to 10
significant digits are displayed.  This means that comparisons for equality may
fail even though the numbers displayed look equal.

## Numeric output

The following words display integer values:

| word    | stack effect     | comment
| ------- | ---------------- | -------------------------------------------------
| `.`     | ( _n_ -- )       | display signed _n_ in current `BASE` followed by a space
| `.R`    | ( _n1_ _n2_ -- ) | display signed _n1_ in current `BASE`, right-justified to fit _n2_ characters
| `U.`    | ( _u_ -- )       | display unsigned _u_ in current `BASE` followed by a space
| `U.R`   | ( _u_ _n_ -- )   | display unisnged _u_ in current `BASE`, right-justified to fit _n_ characters
| `D.`    | ( _d_ -- )       | display signed double _d_ in current `BASE` followed by a space
| `D.R`   | ( _d_ _u_ -- )   | display signed double _d_ in current `BASE`, right-justified to fit _n_ characters
| `BASE.` | ( _u1_ _u2_ -- ) | display unsigned _u1_ in base _u2_ followed by a space
| `BIN.`  | ( _u_ -- )       | display unsigned _u_ in binary followed by a space
| `DEC.`  | ( _u_ -- )       | display unsigned _u_ in decimal followed by a space
| `HEX.`  | ( _u_ -- )       | display unsigned _u_ in hexadecimal followed by a space

Note that `0 .R` may be used to display an integer without a trailing space.

Values are displayed with `EMIT` and `TYPE`, which may be redirected to a
printer or to a file.  See [character output](#character-output).

See also [pictured numeric output](#pictured-numeric-output).

The following words display floating point values:

| word            | stack effect     | comment
| --------------- | ---------------- | -----------------------------------------
| `F.`            | ( F: _r_ -- )    | display _r_ in fixed-point notation followed by a space
| `FS.`           | ( F: _r_ -- )    | display _r_ in scientific notation followed by a space
| `SET-PRECISION` | ( _n_ -- )       | set the `VARIABLE` `PRECISION` to _n_ significant digits to display with `F.` and `FS.`

Note that `SET-PRECISION` does not affect the precision of floating point
operations.

The standard `FE.` word is defined in `FLOATEXT.FTH` and displays a floating
point value in engineering format:

    : FE.       ( F: r -- )
      HERE PRECISION 3 MAX REPRESENT DROP IF '- EMIT THEN
      1- 3 /MOD SWAP DUP 0< IF 3 + SWAP 1- SWAP THEN 1+ HERE OVER TYPE '. EMIT
      HERE OVER + SWAP PRECISION SWAP - 0 MAX TYPE 3 * 'E DBL + EMIT . ;

### Pictured numeric output

Formatted numeric output is produced with a sequence of "pictured numeric
output" words.  An internal "hold area" (a buffer of 40 bytes) is filled with
digits and other characters in backward order (least significant digit goes in
first):

| word    | stack effect             | comment
| ------- | ------------------------ | -----------------------------------------
| `<#`    | ( -- )                   | initiates the hold area for conversion
| `#`     | ( _ud1_ -- _ud2_ )       | adds one digit to the hold area in the current `BASE`, updates _ud1_ to _ud2_
| `#S`    | ( _ud_ --  0 0 )         | adds all remaining digits to the hold area in the current `BASE`
| `HOLD`  | ( _char_ -- )            | places `char` in the hold area
| `HOLDS` | ( _c-addr_ _u_ -- )      | places the string `c-addr u` in the hold area
| `SIGN`  | ( _n_ -- )               | places a minus in the hold area if `_n_` is negative
| `#>`    | ( _xd_ -- _c-addr_ _u_ ) | returns the hold area as a string

For example:

    : dollars   <# # # '. HOLD #S '$ HOLD #> TYPE SPACE ; ↲
    1.23 dollars ↲
    $1.23  OK[0]

Note the reverse order in which the numeric output is composed.  Also note that
`HOLD` is used to add one character to the hold area.  To hold a string we
should use `S" string" HOLDS`.

In this example the value `1.23` appears to have a fraction, but the placement
of the `.` in a double integer has no significance, i.e. it is merely
"syntactic sugar".

To display signed double integers, it is necessary to tuck the high order cell
with the sign under the double number, then make the number positive and
convert using `SIGN` at the end to place the sign at the front of the number:

    : dollars   TUCK DABS <# # # '. HOLD #S '$ HOLD DROP OVER SIGN #> TYPE SPACE ; ↲
    -1.23 dollars ↲
    -$1.23  OK[0]

Pictured numeric words should not be used directly from the Forth prompt,
because the hold area may be overwritten by other numeric outputs and by new
words added to the dictionary.

## String constants

The following words store or display string constants:

| word       | stack effect        | comment
| ---------- | ------------------- | -------------------------------------------
| `S" ..."`  | ( -- _c-addr_ _u_ ) | returns the string _c-addr_ _u_ on the stack
| `S\" ..."` | ( -- _c-addr_ _u_ ) | same as `S"` with special character escapes (see below)
| `C" ..."`  | ( -- _c-addr_ )     | return a counted string on the stack, can only be used in colon definitions
| `." ..."`  | ( -- )              | displays the string, can only be used in colon definitions
| `.( ...)`  | ( -- )              | displays the string immediately, even when compiling, followed by a `CR`, 

Strings contain 8-bit characters, including special characters.

The string constants created with `S"` and `S\"` are compiled to code when used
in colon definitions.  Otherwise, the string is stored in a temporary internal
256-byte string buffer returned by `WHICH-POCKET`.  Two buffers are recycled.

Note that most words require strings with a _c-addr_ _u_ pair of cells on the
stack, such as `TYPE` to display a string.

A so-called "counted string" is compiled with `C"` to code in colon
definitions.  A counted string constant is a _c-addr_ pointing to the length of
the string followed by the string characters.  The `COUNT` word takes a counted
string _c-addr_ from the stack to return a string address _c-addr_ and length
_u_ on the stack.  The maximum length of a counted string is 255 characters.

The `S\"` word accepts the following special characters in the string when
escaped with `\`:

| escape | ASCII    | character
| ------ | -------- | ----------------------------------------------------------
| `\\`   | 92       | `\`
| `\"`   | 34       | `"`
| `\a`   | 7        | BEL; alert
| `\b`   | 8        | BS; backspace
| `\e`   | 27       | ESC; escape
| `\f`   | 12       | FF; form feed
| `\l`   | 10       | LF; line feed
| `\m`   | 13 10    | CR and LF; carriage return and line feed
| `\n`   | 13 10    | CR and LF; carriage return and line feed
| `\q`   | 34       | `"`
| `\r`   | 13       | CR; carriage return
| `\t`   | 9        | HT; horizontal tab
| `\v`   | 11       | VT; vertical tab
| `\xhh` | hh (hex) |
| `\z`   | 0        | NUL

The escape letters are case sensitive.

## String operations

The following words allocate and accept user input into a string buffer:

| word      | stack effect ( _before_ -- _after_ )                | comment
| --------- | --------------------------------------------------- | ------------
| `PAD`     | ( -- _c-addr_ )                                     | returns the fixed address of a 256 byte temporary buffer that is not used by any built-in Forth words
| `BUFFER:` | ( _u_ "name" -- ; _c-addr_ )                        | creates an uninitialized string buffer of size _u_
| `ACCEPT`  | ( _c-addr_ _+n1_ -- _+n2_ )                         | accepts user input into the buffer _c-addr_ of max size _+n1_ and returns string size _+n2_
| `EDIT`    | ( _c-addr_ _+n1_ _n2_ _n3_ _n4_ -- _c-addr_ _+n5_ ) | edit string buffer _c-addr_ of max size _+n1_ containing a string of length _n2_, placing the cursor at _n3_ and limiting cursor movement to _n4_ and after, returns string _c-addr_ with updated size _+n5_

Note that `BUFFER:` only reserves space for the string, or any type of data
that you want to store, but does not store the max size and the length of the
actual string contained.  To do so, we can use a `CONSTANT` and a `VARIABLE`:

    40 CONSTANT name-max ↲
    name-max BUFFER: name ↲
    VARIABLE name-len ↲
    name name-max ACCEPT name-len ! ↲

For example, to let the user edit the name:

    name name-max name-len @ DUP 0 EDIT name-len ! DROP ↲

See also the [strings](#strings) example for an improved implementation of
string buffers that hold both the maximum and actual string lengths.

The following words move and copy characters in and between string buffers:

| word     | stack effect                   | comment
| -------- | ------------------------------ | ----------------------------------
| `CMOVE`  | ( _c-addr1_ _c-addr2_ _u_ -- ) | copy _u_ characters from _c-addr1_ to _c-addr2_, from lower addresses to higher addresses
| `CMOVE>` | ( _c-addr1_ _c-addr2_ _u_ -- ) | copy _u_ characters from _c-addr1_ to _c-addr2_, from higher addresses to lower addresses
| `MOVE`   | ( _c-addr1_ _c-addr2_ _u_ -- ) | copy _u_ characters from _c-addr1_ to _c-addr2_
| `C!`     | ( _char_ _c-addr_ -- )         | store _char_ in _c-addr_
| `C@`     | ( _c-addr_ -- _char_ )         | fetch _char_ from _c-addr_

A problem may arise when the source and target address ranges overlap, for
example when moving string contents in place.  In this case, `CMOVE` ("c move")
correctly copies characters when _c-addr1_>_c-addr2_ and `CMOVE>` ("c move up")
correctly copies characters when _c-addr1_<_c-addr2_.  The `MOVE` word always
correctly copies characters.

For example, to insert `name=` before the string in the `name` buffer by
shifting the string to make room and copying the prefix into the buffer:

     name DUP 5 + name-len max-name 5 - MIN CMOVE> ↲
     S" name=" name SWAP CMOVE ↲

The following words fill a string buffer with characters:

| word    | stack effect               | comment
| ------- | -------------------------- | ---------------------------------------
| `BLANK` | ( _c-addr_ _u_ -- )        | fills _u_ bytes at address _c-addr_ with `BL` (space, ASCII 32)
| `ERASE` | ( _c-addr_ _u_ -- )        | fills _u_ bytes at address _c-addr_ with zeros
| `FILL`  | ( _c-addr_ _u_ _char_ -- ) | fills _u_ bytes at address _c-addr_ with _char_

The following words update the string address _c-addr_ and size _u_ on the
stack:

| word        | stack effect ( _before_ -- _after_ )        | comment
| ----------- | ------------------------------------------- | -----------------
| `NEXT-CHAR` | ( _c-addr1_ _u1_ -- _c-addr2_ _u2_ _char_ ) | if _u1_>0 returns _c-addr2_=_c-addr1_+1, _u2_=_u1_-1 and _char_ is the char at _c-addr2_, otherwise throw -24
| `/STRING`   | ( _c-addr1_ _u1_ _n_ -- _c-addr2_ _u2_ )    | skip _n_ characters _c-addr2_=_c-addr1_+_n_, _u2_=_u1_-_n_, _n_ may be negative to revert
| `-TRAILING` | ( _c-addr_ _u1_ -- _c-addr_ _u2_ )          | returns string _c-addr_ with adjusted size _u2_<=_u1_ to ignore trailing spaces
| `-CHARS`    | ( _c-addr_ _u1_ _char_ -- _c-addr_ _u2_ )   | returns string _c-addr_ with adjusted size _u2_<=_u1_ to ignore trailing _char_

Note that `-TRAILING` ("not trailing") is the same as `BL -CHARS`.  For
example, to remove trailing spaces from `name` to update `name-len`, then
display the name without the `name=` prefix:

    name name-len @ -TRAILING name-len ! ↲
    name name-len @ 5 /STRING TYPE ↲

Beware that `/STRING` ("slash string") does not perform any checking on the
length of the string and the size of the adjustment _n_ that may be negative,
e.g. to add slashed characters back.

The following words compare and search two strings:

| word      | stack effect ( _before_ -- _after_ )                       | comment
| --------- | ---------------------------------------------------------- | -----
| `S=`      | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- flag )                  | returns `TRUE` if the two strings are equal
| `COMPARE` | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- -1\|0\|1 )              | returns -1\|0\|1 (less, equal, greater) comparison of the two strings
| `SEARCH`  | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- _c-addr3_ _u3_ _flag_ ) | returns `TRUE` if the second string was found in the first string at _c-addr3_ with _u3_=_u2_, otherwise `FALSE` and _c-addr3_=_c-addr1_, _u3_=_u1_

To convert a string to a number:

| word      | stack effect ( _before_ -- _after_ )                                  | comment
| --------- | --------------------------------------------------------------------- | -------
| `>NUMBER` | ( _ud1_ _c-addr1_ _u1_ -- _ud2_ _c-addr2_ _u2_ )                      | convert the integer in string _c-addr1_ _u1_ to _ud2_ using the current `BASE` and _ud1_ as seed, returns the remaining non-convertable string _c-addr2_ _u2_
| `>DOUBLE` | ( _c-addr_ _u_ -- _d_ _true_ ) or ( _c-addr_ _u_ -- _false_ )         | convert the integer in string _c-addr_ _u_ to _d_ using the current `BASE`, returns _true_ if successful, otherwise returns _false_ without _d_
| `>FLOAT`  | ( _c-addr_ _u_ -- _true_ ; F: -- _r_ ) or ( _c-addr_ _u_ -- _false_ ) | convert the floating point value in string _c-addr_ _u_ to _r_, returns _true_ if successful, otherwise returns _false_ without _r_

For `>NUMBER`, the initial _ud1_ value is the "seed" that is normally zero.
This value can also be a previously converted high-order part of the number.

`>DOUBLE` returns a double integer when successful.  It also sets the `VALUE`
flag `DBL` to true if the integer is a double with a dot (`.`) in the numeric
string.  To convert a string to a single signed integer, use `D>S` afterwards
to convert.

`>FLOAT` returns a single or double float on the floating point stack when
successful.  It also sets the `VALUE` flag `DBL` to true if the float is a
double.  `>FLOAT` requires `BASE` to be `DECIMAL`.

The `REPRESENT` word can be used to convert a floating point value to a string
saved to a string buffer

| word        | stack effect ( _before_ -- _after_ )              | comment
| ----------- | ------------------------------------------------- | ----------
| `REPRESENT` | ( _c-addr_ _u_ -- _n_ _flag_ _true_ ; F: _r_ -- ) | save the string representation of the significant of _r_ to _c-addr_ of size _u_, returns exponent _n_ and sign _flag_

`REPRESENT` is used by the `F.`, `FE.` and `FS.` words, which save the string
to the hold area at `HERE` to display.  The character string contains the _u_
most significant digits of the significand of _r_ represented as a decimal
fraction with the implied decimal point to the left of the first digit, and the
first digit zero only if all digits are zero.  The significand is rounded to
_u_ digits following the "round to nearest" rule; _n_ is adjusted, if
necessary, to correspond to the rounded magnitude of the significand.  If
_flag_ is _true_ then _r_ is negative.  The `VALUE` flag `DBL` is true if the
float is a double.

The `F.`, `FE.` and `FS.` words are defined as follows:

    : F.        ( F: r -- )
      HERE PRECISION REPRESENT DROP IF '- EMIT THEN
      HERE PRECISION '0 -CHARS 1 UMAX NIP
      OVER 0> INVERT IF
        ." 0." SWAP NEGATE ZEROS HERE SWAP TYPE
      ELSE 2DUP < INVERT IF
        HERE OVER TYPE - ZEROS '. EMIT
      ELSE
        SWAP HERE OVER TYPE '. EMIT HERE OVER + -ROT - TYPE
      THEN THEN SPACE ;

    : FE.       ( F: r -- )
      HERE PRECISION 3 MAX REPRESENT DROP IF '- EMIT THEN
      1- 3 /MOD SWAP DUP 0< IF 3 + SWAP 1- SWAP THEN 1+ HERE OVER TYPE '. EMIT
      HERE OVER + SWAP PRECISION SWAP - 0 MAX TYPE 3 * 'E DBL + EMIT . ;

    : FS.       ( F: r -- )
      HERE PRECISION REPRESENT DROP IF '- EMIT THEN
      HERE C@ EMIT '. HERE C! HERE PRECISION TYPE 'E DBL + EMIT 1- . ;

    : ZEROS     ( n -- ) 0 ?DO '0 EMIT LOOP ;

See also [numeric output](#numeric-output).

## Keyboard input

The following words return key presses and control the key buffer:

| word          | stack effect             | comment
| ------------- | ------------------------ | -----------------------------------
| `EKEY?`       | ( -- _flag_ )            | if a keyboard event is available, return `TRUE`, otherwise return `FALSE`
| `EKEY`        | ( -- _x_ )               | display the cursor, wait for a keyboard event, return the event _x_
| `EKEY>CHAR`   | ( _x_ -- _char_ _flag_ ) | convert keyboard event _x_ to a valid character and return `TRUE`, otherwise return `FALSE`
| `KEY?`        | ( -- _flag_ )            | if a character is available, return `TRUE`, otherwise return `FALSE`
| `KEY`         | ( -- _char_ )            | display the cursor, wait for a character and return it
| `INKEY`       | ( -- _char_ )            | check for a key press returning the key as _char_ or 0 otherwise, clears the key buffer
| `KEY-CLEAR`   | ( -- )                   | empty the key buffer
| `>KEY-BUFFER` | ( _c-addr_ _u_ -- )      | fill the key buffer with the string of characters at address _c-addr_ size _u_
| `MS`          | ( _u_ -- )               | stops execution for _u_ milliseconds

The `KEY` word returns a nonzero 7-bit ASCII code and ignores any special keys.

The `EKEY` word returns a PC-E500(S) key event code as two bytes b1 and b2
stored in a single 16 bit cell b1+256\*b2.  A 7-bit nonzero ASCII code is
returned as b1 when b2 is zero.  If b1 is zero then b2 contains the PC-E500(S)
second byte code assigned to special keys.  See BASIC `INPUT$` in the PC-E500
manual page 268 for the corresponding key code table for byte 2.

The `INKEY` word returns a value between 0 and 255.  See BASIC `INKEY$` in the
PC-E500 manual page 265 for the corresponding key code table.

## Character output

The following words display characters and text:

| word           | stack effect        | comment
| -------------- | ------------------- | ---------------------------------------
| `EMIT`         | ( _char_ -- )       | display character _char_
| `TYPE`         | ( _c-addr_ _u_ -- ) | display string _c-addr_ of size _u_
| `REVERSE-TYPE` | ( _c-addr_ _u_ -- ) | same as `TYPE` with reversed video
| `PAUSE`        | ( _c-addr_ _u_ -- ) | display string _c-addr_ of size _u_ in reverse video and wait for a key press
| `DUMP`         | ( _addr_ _u_ -- )   | dump _u_ bytes at address _addr_ in hexadecimal
| `CR`           | ( -- )              | moves the cursor to a new line with CR-LF
| `SPACE`        | ( -- )              | displays a single space
| `SPACES`       | ( _n_ -- )          | displays _n_ spaces

The `PAUSE` word checks if the current `TTY` output is to `STDO`, then displays
the string in reverse video and waits for a key press.  If the BREAK key or the
C/CE key is pressed, then `PAUSE` executes `ABORT`.  If the output is not to
`STDO`, then `PAUSE` drops _c-addr_ and _u_.

The following words can be used to control character output:

| word      | stack effect    | comment
| --------- | --------------- | -------------------------------------------------
| `STDO`    | ( -- 1 )        | returns _fileid_=1 for standard output to the screen
| `STDL`    | ( -- 3 )        | returns _fileid_=3 for standard output to the line printer
| `TTY`     | ( -- _fileid_ ) | a `VALUE` containing the _fileid_ of a device or file to send character data to
| `PRINTER` | ( -- _n_ )      | connects printer, returns the number of characters per line or zero if printer is off

Normally `TTY` is `STDO` for screen output.  The output can be redirected by
setting the `TTY` value to a _fileid_ of an open file with `fileid TO TTY`.
When an exception occurs, including `ABORT`, `TTY` is set back to `STDO`.

For example, to print "This is printed":

    PRINTER . ↲
    24 OK[0]
    STDL TO TTY .( This is printed) STDO TO TTY ↲
    OK[0]
    Printer: This is printed           

Note that a final `CR` may be needed to print the last line on the printer.
The `.(` output includes a final `CR`.

To make this easier, you can define two words to redirect all character output
to a printer:

    : print-on  PRINTER IF STDL TO TTY THEN ;
    : print-off STDO TO TTY ;

For example:

    print-on FILES F:*.* print-off ↲

## Screen and cursor operations

The following words control the screen and cursor position:

| word         | stack effect                  | comment
| ------------ | ----------------------------- | -------------------------------
| `AT-XY`      | ( _n1_ _n2_ -- )              | set cursor at column _n1_ and row _n2_ position
| `AT-TYPE`    | ( _n1_ _n2_ _c-addr_ _u_ -- ) | display the string _c-addr_ _u_at column _n1_ and row _n2_
| `AT-CLR`     | ( _n1_ _n2_ _n3_ -- )         | clear _n3_ characters at column _n1_ and row _n2_
| `PAGE`       | ( -- )                        | clear the screen
| `SCROLL`     | ( _n_ -- )                    | scroll the screen _n_ lines up when _n_>0 or down when _n_<0
| `X@`         | ( -- _n_ )                    | returns current cursor column position
| `X!`         | ( _n_ -- )                    | set cursor column position
| `Y@`         | ( -- _n_ )                    | returns current cursor row position
| `Y!`         | ( _n_ -- )                    | set cursor row position
| `XMAX@`      | ( -- _n_ )                    | returns cursor max column position
| `XMAX!`      | ( _n_ -- )                    | set cursor max column position, restricts viewing window
| `YMAX@`      | ( -- _n_ )                    | returns cursor max row position
| `YMAX!`      | ( _n_ -- )                    | set cursor max column position, restricts viewing window
| `BUSY-ON`    | ( -- )                        | turn on the busy annunciator
| `BUSY-OFF`   | ( -- )                        | turn off the busy annunciator
| `SET-CURSOR` | ( _u_ -- )                    | set cursor shape bit 5=on, bit 3=blink, bis 0 to 2=underline, 

The `SET-CURSOR` argument is an 8-bit pattern formed by `OR`-ing `$20` to turn
the cursor on, `OR`-ing with `$8` to blink the cursor, and `OR`-ing with one of
the following five possible cursor shapes:

| value | cursor shape
| ----- | ------------
| `$00` | underline
| `$01` | double underline
| `$02` | solid box
| `$03` | space (to display a cursor "box" on reverse video text)
| `$04` | triangle

## Graphics

The graphics mode is set with `GMODE!`.  All graphics drawing commands use this
mode to set, reset or reverse pixels:

| word      | stack effect                   | comment
| --------- | ------------------------------ | ---------------------------------
| `GMODE!`  | ( 0\|1\|2 -- )                 | pixels are set (0), reset (1) or reversed (2), stores in `VARIABLE` `GMODE`
| `GPOINT`  | ( _n1_ _n2_ -- )               | draw a pixel at x=_n1_ and y=_n2_
| `GPOINT?` | ( _n1_ _n2_ -- 0\|1\|-1 )      | returns 1 if a pixel is set at x=_n1_ and y=_n2_ or 0 if unset or -1 when outside of the screen
| `GLINE`   | ( _n1_ _n2_ _n3_ _n4_ _u_ -- ) | draw a line from x=_n1_ and y=_n2_ to x=_n3_ and y=_n4_ with pattern _u_
| `GBOX`    | ( _n1_ _n2_ _n3_ _n4_ _u_ -- ) | draw a filled box from x=_n1_ and y=_n2_ to x=_n3_ and y=_n4_ with pattern _u_
| `GDOTS`   | ( _n1_ _n2_ _u_ -- )           | draw a row of 8 pixels _u_ at x=_n1_ and y=_n2_
| `GDOTS?`  | ( _n1_ _n2_ -- _u_ )           | returns the row of 8 pixels _u_ at x=_n1_ and y=_n2_
| `GDRAW`   | ( _n1_ _n2_ _c-addr_ _u_ -- )  | draw rows of 8 pixels stored in string _c-addr_ _u_ at x=_n1_ and y=_n2_
| `GBLIT!`  | ( _u_ _addr_ -- )              | copy 240 bytes of screen data from row _u_ (0 to 3) to address _addr_
| `GBLIT@`  | ( _u_ _addr_ -- )              | copy 240 bytes of screen data at address _addr_ to row _u_ (0 to 3)

A pattern _u_ is a 16-bit pixel pattern to draw dashed lines and boxes.  The
pattern should be $ffff (-1 or `TRUE`) for solid lines and boxes.  For example,
to reverse the current screen:

    2 GMODE! ↲
    0 0 239 31 TRUE GBOX ↲

The `GDOTS` word takes an 8-bit pattern to draw a row of 8 pixels.  The `GDRAW`
word draws a sequence of 8-bit patterns.  For example, to display a smiley at
the upper left corner of the screen:

    : smiley    ( x y -- ) S\" \x3c\x42\x91\xa5\xa1\xa1\xa5\x91\x42\x3c" GDRAW ; ↲
    0 GMODE! PAGE CR 0 0 smiley ↲

      XXXXXX
     X      X
    X  X  X  X
    X        X
    X X    X X
    X  XXXX  X
     X      X
      XXXXXX

In addition to `S\"` escaped strings with hexadecimal codes, the 10 bytes can
also be specified in binary with the sprite rotated sideways so that the top of
the sprite is on the right:

    : sprite    CREATE C, DOES> ( x y addr -- ) COUNT GDRAW ; ↲
    10 sprite smiley ↲
      %00111100 C, ↲
      %01000010 C, ↲
      %10010001 C, ↲
      %10100101 C, ↲
      %10100001 C, ↲
      %10100001 C, ↲
      %10100101 C, ↲
      %10010001 C, ↲
      %01000010 C, ↲
      %00111100 C, ↲
    0 GMODE! PAGE CR 0 0 smiley ↲

Blitting moves screen data between buffers to update or restore the screen
content.  The `GBLIT!` word stores a row of screen data in a buffer and
`GPLIT@` fetches a row of screen data to restore the screen.  Each operation
moves 240 bytes of screen data for one of the four rows of 40 characters.  For
example, to save and restore the top row in the 256 byte `PAD`:

    : save-top-row      ( -- ) 0 PAD GBLIT! ;
    : restore-top-row   ( -- ) 0 PAD GBLIT@ ;

To blit the whole screen, a buffer of 4 times 240 bytes is required:

    240 4 * BUFFER: blit
    : save-screen       ( -- ) 4 0 DO I DUP 240 * blit + GBLIT! LOOP ;
    : restore-screen    ( -- ) 4 0 DO I DUP 240 * blit + GBLIT@ LOOP ;

## Sound

The `BEEP` word emits sound with the specified duration and tone:

| word   | stack effect     | comment
| ------ | ---------------- | --------------------------------------------------
| `BEEP` | ( _u1_ _u2_ -- ) | beeps with tone _u1_ for _u2_ milliseconds
| `MS`   | ( _u_ -- )       | stops execution for _u_ milliseconds

## The return stack

The return stack is used to call colon definitions by saving the return address
on the return stack.  The return stack is also used by do-loops to store the
loop control values, see also [loops](#loops).

The following words move cells between both stacks:

| word     | stack effect ( _before_ -- _after_ )              | comment
| -------- | ------------------------------------------------- | ---------------
| `>R`     | ( _x_ -- ; R: -- _x_ )                            | move the TOS to the return stack
| `DUP>R`  | ( _x_ -- _x_ ; R: -- _x_ )                        | copy the TOS to the return stack
| `2>R`    | ( _xd_ -- ; R: -- _xd_ )                          | move the double TOS to the return stack
| `R@`     | ( R: _x_ -- _x_ ; -- _x_ )                        | copy the return stack TOS to the stack
| `2R@`    | ( R: _xd_ -- _xd_ ; -- _xd_ )                     | copy the return stack double cell (TOS and 2OS) to the stack
| `R'@`    | ( R: _x1_ _x2_ -- _x1_ _x2_ ; -- _x1_ )           | copy the return stack 2OS to the stack
| `R"@`    | ( R: _x1_ _x2_ _x3_ -- _x1_ _x2_ _x3_ ; -- _x1_ ) | copy the return stack 3OS to the stack
| `R>`     | ( R: _x_ -- ; -- _x_ )                            | move the TOS from the return stack to the stack
| `R>DROP` | ( R: _x_ -- ; -- )                                | drop the return stack TOS
| `2R>`    | ( R: _xd_ -- ; -- _xd_ )                          | move the double TOS from the return stack to the stack
| `N>R`    | ( _n_\*_x_ _+n_ -- ; R: -- _n_\*_x_ _+n_ )        | move _n_ cells to the return stack
| `NR>`    | ( -- _n_\*_x_ _+n_ ; R: _n_\*_x_ _+n_ -- )        | move _n_ cells from the return stack

The `N>R` and `NR>` words move _+n_+1 cells, including the cell _+n_.  For
example `2 N>R ... NR> DROP` moves 2+1 cells to the return stack and back,
then dropping the restored 2.  Effectively the same as executing `2>R ... 2R>`.

Note: `N>R` and `NR>` move _+n_ _mod_ 128 cells max as a precaution.

Other words related to the return stack:

| word    | stack effect  | comment
| ------- | ------------- | ----------------------------------------------------
| `RP@`   | ( -- _addr_ ) | returns the return stack pointer, points the to return TOS
| `RP!`   | ( _addr_ -- ) | assigns the return stack pointer (danger!)

Care must be taken to prevent return stack imbalences when a colon definition
exits.  The return stack pointer must be restored to the original state when
the colon definition started before the colon definition exits.

"Caller cancelling" is possible with `R>DROP` ("r from drop" or just "r drop")
to remove a return address before exiting:

    : bar  ." bar " R>DROP ;
    : foo  ." foo " bar ." rest of foo" ;

where `R>DROP` removes the return address to `foo`.  Therefore:

    foo ↲
    foo bar OK[0]

The maximum depth of the return stack in Forth500 is 256 bytes to hold up to
128 cells or 128 calls to secondaries (colon definitions of words constructed
from existing Forth words).

## Defining new words

### Constants, variables and values

The following words define constants, variables and values:

| word        | stack effect                       | comment
| ----------- | ---------------------------------- | ---------------------------
| `CONSTANT`  | ( _x_ "name" -- ; -- _x_ )         | define "name" to return _x_ on the stack
| `2CONSTANT` | ( _dx_ "name" -- ; -- _dx_ )       | define "name" to return _dx_ on the stack
| `FCONSTANT` | ( F: _r_ -- ; "name" -- ; -- _r_ ) | define "name" to return _r_ on the floating point stack
| `VARIABLE`  | ( "name" -- ; -- _addr_ )          | define "name" to return _addr_ of the variable's cell on the stack
| `!`         | ( _x_ _addr_ -- )                  | store _x_ at _addr_ of a `VARIABLE`
| `+!`        | ( _n_ _addr_ -- )                  | add _n_ to the value at _addr_ of a `VARIABLE`
| `@`         | ( _addr_ -- _x_ )                  | fetch the value _x_ from _addr_ of a `VARIABLE`
| `?`         | ( _addr_ -- )                      | fetch the value _x_ from _addr_ of a `VARIABLE` and display it with `.`
| `ON`        | ( _addr_ -- )                      | store `TRUE` (-1) at _addr_ of a `VARIABLE`
| `OFF`       | ( _addr_ -- )                      | store `FALSE` (0) at _addr_ of a `VARIABLE`
| `2VARIABLE` | ( "name" -- ; -- _addr_ )          | define "name" to return _addr_ of the variable's double cell on the stack
| `2!`        | ( _dx_ _addr_ -- )                 | store _dx_ at _addr_ of a `2VARIABLE`
| `D+!`       | ( _d_ _addr_ -- )                  | add _d_ to the value at _addr_ of a `2VARIABLE`
| `2@`        | ( _addr_ -- _dx_ )                 | fetch the value _dx_ from  _addr_ of a `2VARIABLE`
| `FVARIABLE` | ( "name" -- ; -- _addr_ )          | define "name" to return _addr_ of the variable's floating point value on the stack
| `F!`        | ( F: _r_ -- ; _addr_ -- )          | store floating point value _r_ at _addr_ of a `VARIABLE`
| `F@`        | ( _addr_ -- ; F: _r_ )             | fetch the floating point value _r_ from  _addr_ of a `2VARIABLE`
| `VALUE`     | ( _x1_ "name" -- ; -- _x2_ )       | define "name" with initial value _x1_ to return its current value _x2_ on the stack
| `TO`        | ( _x_ "name" -- )                  | assign "name" the value _x_, if "name" is a `VALUE`
| `+TO`       | ( _n_ "name" -- )                  | add _n_ to the value of "name", if "name" is a `VALUE`
| `2VALUE`    | ( _dx1_ "name" -- ; -- _dx2_ )     | define "name" with initial value _dx1_ to return its current value _dx2_ on the stack
| `TO`        | ( _dx_ "name" -- )                 | assign "name" the value _dx_, if "name" is a `2VALUE`
| `+TO`       | ( _d_ "name" -- )                  | add _d_ to the value of "name", if "name" is a `2VALUE`
| `FVALUE`    | ( F: _r1_ "name" -- ; -- F: _r2_ ) | define "name" with initial value _r1_ to return its current value _r2_ on the floating point stack
| `TO`        | ( F: _r_ "name" -- )               | assign "name" the value _r_, if "name" is an `FVALUE`

Values are initialized with the specified initial values and do not require
fetch operations, exactly like constants.  By contrast to constants, values can
be updated with `TO` and `+TO`.  Note that the `TO` and `+TO` words are used
to assign and update `VALUE` and `2VALUE` words.

### Deferred words

A deferred word executes another word assigned to it, essentially a variable
that contains the execution token of another word to execute indirectly:

| word        | stack effect            | comment
| ----------- | ----------------------- | --------------------------------------
| `DEFER`     | ( "name" -- )           | defines a deferred word that is initially uninitialized
| `'`         | ( "name" -- _xt_ )      | tick returns the execution token of "name" on the stack
| `[']`       | ( "name" -- ; -- _xt_ ) | compiles "name" as an execution token literal _xt_
| `IS`        | ( _xt_ "name" -- )      | assign "name" the execution token _xt_ of another word
| `ACTION-OF` | ( "name" -- _xt_ )      | fetch the execution token _xt_ assigned to "name"
| `DEFER!`    | ( _xt1_ _xt2_ -- )      | assign _xt1_ to deferred word execution token _xt2_
| `DEFER@`    | ( _xt1_ -- _xt2_ )      | fetch _xt2_ from deferred word execution token _xt1_
| `NOOP`      | ( -- )                  | does nothing
| `EXECUTE`   | ( ... _xt_ -- ... )     | executes execution token _xt_

A deferred word is defined with `DEFER` and assigned with `IS`:

    DEFER greeting ↲
    : hi ." hi" ; ↲
    ' hi IS greeting ↲
    greeting ↲
    hi OK[0]
    ' NOOP IS greeting ↲
    greeting ↲
    OK[0]
    :NOMAME ." hello" ; IS greeting ↲
    greeting ↲
    hello OK[0]

The tick `'` word parses the name of a word in the dictionary and returns its
execution token on the stack.  An execution token points to executable code in
the dictionary located directly after the name of a word.  The `EXECUTE` word
executes code pointed to by an execution token.  Therefore, `' my-word EXECUTE`
is the same as executing `my-word`.

Executing an uninitialized deferred word throws exception -256 "execution of an
uninitialized deferred word".  To make a deferred word do nothing, assign
`NOOP` "no-operation" to the deferred word.

To assign one deferred word to another we use `ACTION-OF`, for example:

    DEFER foo ↲
    ' TRUE IS foo ↲
    DEFER bar ↲
    ACTION-OF foo IS bar ↲

The result is that `bar` is assigned `TRUE` to execute.  By contrast, `' foo IS
bar` assigns `foo` to `bar` so that `bar` executes `foo` and `foo` executes
`TRUE`.  This means that changing `foo` would also change `bar`.

The current action of a deferred word can be compiled into a definition to
produce a static binding:

    : bar ... [ ACTION-OF foo COMPILE, ] ... ;

where `COMPILE,` compiles the execution token on the stack into the current
definition.  See also [the \[ and \] brackets](#the--and--brackets).  To
streamline this method, define the immediate word `[ACTION-OF]`:

    : [ACTION-OF] ACTION-OF COMPILE, ; IMMEDIATE

which is used as follows:

    : bar ... [ACTION-OF] foo ...

Some Forth implementations use `DEFERS` to do the same.

### Noname definitions

A nameless colon definition just stores code and cannot be referenced by name.
The `:NONAME` word compiles a definition and returns its execution token on the
stack:

    :NONAME ." this definition has no name" ; ↲
    EXECUTE ↲
    this definition has no name OK[0]

`EXECUTE` runs to code, but there is no longer any way to reuse the code or
delete it from the dictionary.  `:NONAME` is typically used with [deferred
words](#deferred-words) to store and execute the unnamed code:

    DEFER lambda ↲
    :NONAME ." this definition has no name" ; IS lambda ↲
    lambda ↲
    this definition has no name OK[0]
    FORGET lambda ↲
    OK[0]

The no-name equivalent of `CREATE` is `CREATE-NONAME`, see [CREATE and
DOES>](#create-and-does).

### Recursion

A recursive colon definition cannot refer to its own name, which is hidden
until the final `;` is parsed.  There are two reasons for this: to avoid the
possible use of an incomplete colon definition that can crash the system when
executed and to allow redefining a word to call the old definition while
executing additional code in the redefinition.

A recursive colon definition should use `RECURSE` to call itself, for example:

    : factorial ( u -- ud ) \ u<=12
      ?DUP IF DUP 1- RECURSE ROT UMD* ELSE 1. THEN ;

Mutual recursion can be accomplished with [deferred words](#deferred-words):

    DEFER foo ↲
    : bar ... foo ... ; ↲
    :NONAME ... bar ... ; IS foo ↲

`:NONAME` returns the execution token of an unnamed colon definition,
see also [noname definitions](#noname-definitions).

Do not recurse too deep.  The return stack supports up to 128 calls to
secondaries, not counting other data stored on the return stack.

### Immediate words

An immediate word is always interpreted and executed, even within colon
definitions.  A colon definition word can be declared `IMMEDIATE` after
the terminating `;`.  For example, the following colon definition of `RECURSE`
compiles the execution token of the most recent colon definition (i.e.  the
word we are defining) into the compiled code:

    : RECURSE
      ?COMP     \ error -14 if we are not compiling
      LAST-XT   \ the execution token of the word being defined
      COMPILE,  \ compile it into code
    ; IMMEDIATE

See also [compile-time immedate words](#compile-time-immediate-words).

### CREATE and DOES>

Data can be stored in the dictionary as words created with `CREATE`.  Like a
colon definition, the name of a word is parsed and added to the dictionary.
This word does nothing else but just return the address of the body of data
stored in the dictionary.  To allocate and populate the data the following
words can be used:

| word     | stack effect              | comment
| -------- | ------------------------- | ---------------------------------------
| `CREATE` | ( "name" -- ; -- _addr_ ) | adds a new word entry for "name" to the dictionary, this word returns _addr_
| `HERE`   | ( -- _addr_ )             | the next free address in the dictionary
| `CELL`   | ( -- 2 )                  | the size of a cell (single integer) in bytes
| `CELLS`  | ( _u_ -- 2\*_u_ )         | convert _u_ from cells to bytes
| `CELL+`  | ( _addr_ -- _addr_+2 )    | increments _addr_ by a cell width (2 bytes)
| `CHARS`  | ( _u_ -- _u_ )            | convert _u_ from characters to bytes (does nothing)
| `CHAR+`  | ( _addr_ -- _addr_+1 )    | increments _addr_ by a character width (1 byte)
| `FLOATS` | ( _u_ -- 12\*_u_ )        | convert _u_ from floats to bytes
| `FLOAT+` | ( _addr_ -- _addr_+12 )   | increments _addr_ by a floating point value width (12 bytes)
| `ALLOT`  | ( _n_ -- )                | reserves _n_ bytes in the dictionary starting `HERE`, adds _n_ to `HERE`
| `UNUSED` | ( -- _u_ )                | returns the number of unused bytes remaining in the dictionary
| `,`      | ( _x_ -- )                | stores _x_ at `HERE` then increments `HERE` by `CELL` (by 2 bytes)
| `2,`     | ( _dx_ -- )               | stores _dx_ at `HERE` then increments `HERE` by `2 CELLS` (by 4 bytes)
| `C,`     | ( _char_ -- )             | stores _char_ at `HERE` then increments `HERE` by `1 CHARS` (by 1 byte)
| `F,`     | ( F: _r_ -- )             | stores floating point value _r_ at `HERE` then increments `HERE` by `1 FLOATS` (by 12 bytes)
| `DOES>`  | ( -- ; -- _addr_ )        | the following code will be compiled and executed by the word we `CREATE`
| `@`      | ( _addr_ -- _x_)          | fetches _x_ stored at _addr_
| `2@`     | ( _addr_ -- _dx_ )        | fetches _dx_ stored at _addr_
| `C@`     | ( _addr_ -- _char_ )      | fetches _char_ stored at _addr_
| `F@`     | ( _addr_ -- ; F: _r_ )    | fetches _r_ stored at _addr_

Allocation is limited by the remaining free space in the dictionary returned by
the `UNUSED` word.  Note that the `ALLOT` value may be negative to release
space.  Make sure to release space only with `ALLOT` after allocating space
with `ALLOT` and when no new words were defined and added to the dictionary.

The `CREATE` word adds an entry to the dictionary, typically followed by words
to allocate and store data assocated with the new word.  For example, we can
create a word `foo` with a cell to hold a value that is initially zero:

    CREATE foo 0 , ↲
    3 foo ! ↲
    foo ? ↲
    3 OK[0]

In fact, this is exactly how the `VARIABLE` word is defined in Forth:

    : VARIABLE CREATE 0 , ; ↲

We can use `CREATE` with "comma" words such as `,` to store values.  For
example, a table of 10 primes:

    CREATE primes 2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 31 , ↲

The entire `primes` table is displayed using address arithmetic as follows:

    : primes?   ( -- ) 10 0 DO primes I CELLS + ? LOOP ; ↲

where `primes` returns the starting address of the table and `primes I CELLS +`
computes the address of the cell that holds the `I`'th prime value.  The
`CELLS` word multiplies the TOS by two, since Forth500 cells are 2 bytes.

Uninitialized space is allocated with `ALLOT`.  For example, a buffer:

    CREATE buf 256 ALLOT ↲

This creates a buffer `buf` of 256 bytes.  The `buf` word returns the starting
address of this buffer.  In fact, the built-in `BUFFER:` word is defined as:

    : BUFFER:   CREATE ALLOT ; ↲

so that `buf` can also be created with:

    256 BUFFER: buf ↲

The `DOES>` word compiles code until a terminating `;`.  This code is executed
by the word we `CREATE`.  For example, `CONSTANT` is defined in Forth as
follows:

    : CONSTANT  CREATE , DOES> @ ; ↲

A constant just fetches its data from the definition's body.

Note that `>BODY` (see [introspection](#introspection)) of an execution token
returns the same address as `CREATE` returns and that `DOES>` pushes on the
stack.  For example, `' buf >BODY` and `buf` return the same address.

`DOES>` is valid only in a colon definition, because the `DOES>` code is part
of the creating definition, not with the word we `CREATE`.  The word we
`CREATE` executes the `DOES>` code.

For example, address arithmetic can be added with `DOES>` to automatically
fetch a prime number from the `primes` table of constants:

    : table:    ( "name" -- ; index -- n ) CREATE DOES> SWAP CELLS + @ ;
    table: primes 2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 31 , ↲
    3 primes . ↲
    7 OK[0]

The `SWAP CELLS + @` doubles the index with `CELLS` then adds the address of
the `primes` table to get to the address to fetch the value.

`CREATE-NONAME` is similar to `CREATE`, but does not add a new word to the
dictionary, returning the execution token of the code instead.  The execution
toke, can be assigned to a `DEFER` word for example, see also [noname
definitions](#noname-definitions).

#### Structures

The following words define a structure and its fields:

| word              | stack effect ( _before_ -- _after_ )         | comment
| ----------------- | -------------------------------------------- | -----------
| `BEGIN-STRUCTURE` | ( "name" -- _addr_ 0 ; -- _u_ )              | define a structure type
| `+FIELD`          | ( _u_ _n_ "name" -- _u_ ; _addr_ -- _addr_ ) | define a field name with the specified size
| `FIELD:`          | ( _u_ "name" -- n ; addr -- addr )           | define a single cell field
| `CFIELD:`         | ( _u_ "name" -- n ; addr -- addr )           | define a character field
| `2FIELD:`         | ( _u_ "name" -- n ; addr -- addr )           | define a double cell field
| `FFIELD:`         | ( _u_ "name" -- n ; addr -- addr )           | define a floating point field
| `END-STRUCTURE`   | ( _addr_ _u_ -- )                            | end of structure type

The `FIELD:` word is the same as `CELL +FIELD`, `CFIELD:` is the same as `1
CHARS +FIELD` and `2FIELD` is the same as `2 CELLS +FIELD`.

Fields behave like variables and can be assigned with `!`, `ON` and `OFF` and
fetched with `@`.  For example:

    BEGIN-STRUCTURE pair ↲
      FIELD: pair.first ↲
      FIELD: pair.second ↲
    END-STRUCTURE ↲
    : pair.init DUP pair.first OFF pair.second OFF ; ↲
    pair BUFFER: xy ↲
    xy pair.init ↲
    xy pair.first @ xy pair.second @ AT-XY ↲

Structures can be nested. For example:

    BEGIN-STRUCTURE pixel ↲
      pair +FIELD pixel.xy ↲
      FIELD: pixel.on ↲
    END-STRUCTURE ↲

#### Arrays

Space for arrays can be allocated with `BUFFER:`, for example to store 10 prime
numbers:

    10 CELLS BUFFER: primes ↲

This allocates space for 10 primes, but does nothing more.  Adding a provision
to automatically index an array is done by creating a `BUFFER:` with `DOES>`
code to return the address of a cell given the array and array index on the
stack:

    : cell-array:   CELLS BUFFER: DOES> SWAP CELLS + ; ↲

where `CELLS BUFFER:` creates a new word and allocates the specified number of
cells for the named array, where `BUFFER:` just calls `CREATE ALLOT` to define
the name with the reserved space.

We can use `cell-array` to create an array of 10 uninitialized cells, then set
the first entry to `123` for example:

    10 cell-array: values ↲
    123 0 values ! ↲

A generic `array` word takes the number of elements and size of an element,
where the element size is stored as a cell using `,` followed by `* ALLOT` to
reserve space for the array data:

    : array:    CREATE DUP , * ALLOT DOES> SWAP OVER @ * + CELL+ ; ↲
    10 2 CELLS array: factorials ↲
    1.      0 factorials 2! 1.    1 factorials 2! 2.     2 factorials 2! ↲
    6.      3 factorials 2! 24.   4 factorials 2! 120.   5 factorials 2! ↲
    720.    6 factorials 2! 5040. 7 factorials 2! 40320. 8 factorials 2! ↲
    362880. 9 factorials 2! ↲

We can add "syntactic sugar" to enhance the readability of the code, for
example using `{` and `}` to demarcate the array index expression as follows:

    : { ; IMMEDIATE  \ Does nothing ↲
    10 2 CELLS array: }factorials ↲
    1. { 0 }factorials 2! 1. { 1 }factorials 2! 2. { 2 }factorials 2! ↲

By making `{` immediate, it won't compile to a useless call to the `{` excution
token.  This array implementation has no array index bound checking.

### Markers

A so-called "marker word" is created with `MARKER`.  When the word is executed,
it deletes itself and all definitions after it.  For example:

    MARKER _program_ ↲
    ...
    _program_ ↲

This marks `_program_` as the start of our code indicated by the `...`.  This
code is deleted by executing `_program_`.

A source code file might start with the following code to delete its
definitions when the file is parsed again to be replace the old definitions
with updated definitions:

    [DEFINED] _program_ [IF] _program_ [THEN] ↲
    MARKER _program_ ↲

`ANEW` is shorter and does the same thing:

    ANEW _program_ ↲

### Deleting words

Besides [markers](#markers), `FORGET name` can be used to remove `name` and all
words defined thereafter.  To protect the dictionary, forgetting is not
permitted past the address returned by `FENCE`.  `FENCE` is a variable that can
be assigned a new boundary in the dictionary to protect from `FORGET`.  For
example, `HERE FENCE !` protects all previously defined words.

### Introspection

The following words can be used to inspect words and dictionary contents:

| word          | stack effect             | comment
| ------------- | ------------------------ | -----------------------------------
| `'`           | ( "name" -- _xt_ )       | tick returns the execution token of "name" on the stack
| `[']`         | ( "name" -- ; -- _xt_ )  | compiles "name" as an execution token literal _xt_
| `COLON?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `:` definition
| `DEFER?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `DEFER`
| `VALUE?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `VALUE`
| `2VALUE?`     | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `2VALUE`
| `FVALUE?`     | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is an `FVALUE`
| `DOES>?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is created by a word that uses `CREATE` with `DOES>`
| `MARKER?`     | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `MARKER`
| `>BODY`       | ( _xt_ -- _addr_ )       | return the _addr_ of the body of execution token _xt_, usually data
| `>NAME`       | ( _xt_ -- _nt_ )         | return the name token _nt_ of the name of execution token _xt_
| `NAME>STRING` | ( _nt_ -- _c-addr_ _u_ ) | return the string _c-addr_ of size _u_ of the name token _nt_
| `NAME>`       | ( _nt_ -- _xt_ )         | return the execution token of the name token _nt_
| `LAST`        | ( -- _addr_ )            | return the dictionary entry of the last defined word (the entry is a link to the previous entry)
| `L>NAME`      | ( _addr_ -- _nt_ )       | return the name token of the dictionary entry at _addr_ 
| `LAST-XT`     | ( -- _xt_ )              | return the execution token of the last defined word
| `WORDS`       | ( [ "name" ] -- )        | displays all words in the dictionary matching (part of) the optional "name" 

Words named `xxx>yyy` are pronounced "xxx to yyy", words named `>xxx` are
pronounced "to xxx" and words named `xxx>` are pronounced "xxx from".
See the [Forth word list](https://forth-standard.org/standard/alpha) with
pronounciations of all standard words.

See also the [dictionary structure](#dictionary-structure).

## Control flow

A colon definition can be exited with `EXIT` to return to the caller.  To
recursively call the current word, use `RECURSE` see [recursion](#recursion).
See also [exceptions](#exceptions) to `THROW` and `CATCH` exceptions and to use
`ABORT` or `ABORT"` to abort and return control to the keyboard.

The next two sections introduce conditional branches and loops.

### Conditionals

The immediate words `IF`, `ELSE` and `THEN` execute a branch based on a single
condition:

    test IF
      executed if test is nonzero
    THEN

    test IF
      executed if test is nonzero
    ELSE
      executed if test is zero
    THEN

These words can only be used in colon definitions.

The immediate words `CASE`, `OF`, `ENDOF`, `ENDCASE` select a branch to
execute by comparing the TOS to the `OF` values:

    value CASE
      case1 OF
        executed if value=case1
      ENDOF
      case2 OF
        executed if value=case2
      ENDOF
      ...
      caseN OF
        executed if value=caseN
      ENDOF
        executed if no case matched (default branch)
    ENDCASE

These words can only be used in colon definitions.  The default branch has
`value` as TOS, which may be inspected in the default branch, but should not be
dropped.  It is common to use the `>R` and `R>` words to temporarily save the
TOS in the default branch:

      ENDOF
        >R ... R>
    ENDCASE

The stack effects of `...` are transparent to the code that follows `ENDCASE`.

### Loops

Enumeration-controlled do-loops start with the word `DO` or `?DO` and end with
the word `LOOP` or `+LOOP`:

    limit start DO
      loop body
    LOOP

    limit start ?DO
      loop body
    LOOP

    limit start DO
      loop body
    step +LOOP

    limit start ?DO
      loop body
    step +LOOP

These words can only be used in colon definitions.  Do-loops run from the `start`
to the `limit` values, excluding the last iteration for `limit`.  The `DO` loop
iterates at least once, even when `start` equals `limit`.  The `?DO` loop does
not iterate when `start` equals `limit`.  The `+LOOP` word increments the
internal loop counter by `step`.  The `step` size may be negative.  The `+LOOP`
terminates if the updated counter equals or crosses the limit.

The internal loop counter value can be used in the loop as `I`.  Likewise, the
second outer loop counter of a loop nest is `J` and the third outer loop
counter is `K`.  These return undefined values when not used within do-loops.

A do-loop body is exited prematurely with `LEAVE` and `?LEAVE`.  The `?LEAVE`
word pops the TOS and when nonzero leaves the do-loop, which is a shorthand for
`IF LEAVE THEN`.

When exiting from the current colon definition with `EXIT` inside a do-loop,
first the `UNLOOP` word must be used to remove the loop control values from the
return stack: `UNLOOP EXIT`.

Return stack operations `>R`, `R@` and `R>` cannot be used to pass values on
the returns stack from outside a do-loop to the inside, because the do-loop
stores the loop counter and limit value on the return stack.  For example, `>R
DO ... R@ ... LOOP R>` produces undefined values.

The words `BEGIN` and `AGAIN` form a loop that never ends:

    BEGIN
      loop body
    AGAIN

There is no word like `LEAVE` to exit a `BEGIN` loop.  Instead, `UNTIL` or
`WHILE` with `REPEAT` should be used.  An `EXIT` in a loop will terminate the
loop and return control from the current colon definition,

The words `BEGIN` and `UNTIL` form a conditional loop which iterates at least
once until the condition `test` is nonzero (is true):

    BEGIN
      loop body
    test UNTIL

The words `BEGIN`, `WHILE` and `REPEAT` form a conditional loop that iterates
while the condition `test` is true (nonzero):

    BEGIN
    test WHILE
      loop body
    REPEAT

The `BEGIN`, `WHILE`, `REPEAT`, `UNTIL` and `AGAIN` words can only be used in
colon definitions.

A `WHILE` loop can be enhanced with additional `WHILE` tests to create a
multi-test conditional loop with optional `ELSE`:

    BEGIN
    test1 WHILE
      loop body1
      test2 WHILE
        loop body2
    REPEAT
    ELSE
      executed if test2 is true (nonzero)
    THEN

The loop `body1` and `body2` are executed as long as `test1` and `test2` are
true (nonzere).  If `test1` is false (zero), then the loop exits.  If `test2`
is false (zero), then the loop terminates in the `ELSE` branch.  Multiple
`WHILE` and optional `ELSE` branches may be added.  Each additional `WHILE`
requires a `THEN` after `REPEAT`.

To understand how and why this works, note that a `WHILE` and `REPEAT`
combination is equal to `BEGIN` with an `IF` to conditionally execute `AGAIN`:

    BEGIN       \  BEGIN
      test IF   \    test WHILE
    AGAIN THEN  \  REPEAT

## Compile-time immediate words

The interpretation versus compilation state variable is `STATE`.  When true
(nonzero), a colon definition is being compiled.  When false (zero), the
system is interpreting.  The `[` and `]` may be used in colon definitions to
temporarily switch to interpret mode.

Some words are always interpreted and not compiled.  These words are marked
`IMMEDIATE`.  The compiler executes `IMMEDIATE` word immediately.  In fact,
Forth control flow is implemented with immediate words that compile conditional
branches and loops.

### The [ and ] brackets

The immediate `[` word switches `STATE` to `FALSE` and `]` switches `STATE` to
`TRUE`.  This means that `[` and `]` can be used within a colon definition to
temporarily switch to interpret mode and execute words, rather than compiling
them.  For example:

    : my-word       [ .( here=) HERE . ] ." executing my-word" CR ;

This example displays `here=<CR><address>` when `my-word` is compiled and displays
`executing my-word` when `my-word` is executed.

Note that the immediate `.(` word is used to display messages at compile time
or at run time, so we can also write this as follows:

    : my-word       .( here=) [ HERE . ] ." executing my-word" CR ;

It is a good habit to define words to break up longer definitions, so we can
refactor this by introducing a new word `"here"`:

    : "here"    ." here=" CR HERE . ;
    : my-word   [ "here" ] ." executing my-word" CR ;

### Immediate execution

Consider:

    : "here"    ." here=" CR HERE . ;
    : my-word   [ "here" ] ." executing my-word" CR ;

The `[` and `]` are not necessary if we make `"here"` `IMMEDIATE` to execute
immediately:

    : [here]    ." here=" CR HERE . ; IMMEDIATE
    : my-word   [here] ." executing my-word" CR ;

Using brackets with `[here]` is another good habit as a reminder that we
execute an immediate word when it affects compilation.

This example illustrates how `IMMEDIATE` is used.  Because displaying
information while compiling is generally considered useful, the `.(` word is
marked immediate to display text followed by a `CR` during compilation:

    : my-word   .( compiling my-word) ." executing my-word" CR ;

All [control flow](#control-flow) words execute immediately to compile
conditionals and loops.

### Literals

To compile values on the stack into literal constants in the compiled code, we
use the `LITERAL`, `2LITERAL` and `SLITERAL` immediate words.  For example,
we can create a variable and use its current value to create a literal
constant:

    VARIABLE foo 123 foo ! ↲
    : now-foo   [ foo @ ] LITERAL ; ↲
    456 foo ! ↲
    now-foo . ↲
    123 OK[0]

The example demonstrates how the current value of a variable is compiled into a
literal in `now-foo`.

The `2LITERAL` word compiles double integers (two cells).  The `SLITERAL` word
compiles strings:

| word       | stack effect ( _before_ -- _after_ ) | comment
| ---------- | ------------------------------------ | --------------------------
| `LITERAL`  | ( _x_ -- ; -- _x_ )                  | compiles _x_ as a literal
| `2LITERAL` | ( _dx_ -- ; -- _dx_ )                | compiles _dx_ as a double literal
| `FLITERAL` | ( F: _r_ -- ; F: -- _r_ )            | compiles _r_ as a floating point literal
| `SLITERAL` | ( _c-addr1_ _u_ ; -- _c-addr2_ _u_ ) | compiles string _c-addr_ of size _u_ as a string literal
| `[CHAR]`   | ( "name" -- ; -- _char_ )            | compiles the first character of "name" as a literal
| `[']`      | ( "name" -- ; -- _xt_ )              | compiles "name" as an execution token literal _xt_

The `SLITERAL` word compiles the string address _c-addr1_ and size _u_ by
copying the string to code.  The copied string is returned at runtime as
_c-addr2_ _u_.

The `[CHAR]` word parses a name and compiles the first character as a literal.
This is the compile-time equivalent of `CHAR`.  For example, `[CHAR] $` is the
same as `[ CHAR $ ] LITERAL`.  Instead of `[CHAR] $`, the short form `'$` may
be used.

The `[']` word parses the name of a word and compiles the word's execution
token as a literal.  This is the compile-time equivalent of `'` ("tick").  For
example, `['] NOOP` is the same as `[ ' NOOP ] LITERAL`.

### Postponing execution

Immediate words cannot be compiled, unless we postpone their execution with
`POSTPONE`.  The `POSTPONE` word parses a name marked `IMMEDIATE` and compiles
it to execute when the colon definition executes.  If the name is not
immediate, then `POSTPONE` compiles the word's execution token as a literal
followed by `COMPILE,`, which means that this use of `POSTPONE` in a colon
definition compiles code.  Basically, `POSTPONE` may be used to define words
that compile the postponed words into a definition, acting like macros.

An example of `POSTPONE` to compile the immedate word `THEN` to execute when
`ENDIF` executes, making `ENDIF` synonymous to `THEN`:

    : ENDIF     POSTPONE THEN ; IMMEDIATE ↲

An example of `POSTPONE` to compile a non-immedate word:

    : [MAX]     POSTPONE MAX ; IMMEDIATE ↲
    : foo       [MAX] ; ↲

the result of which is:

    : foo       MAX ;

Note that `[MAX]` is `IMMEDIATE` to compile `MAX` in the definition of `foo`.
Basically, `[MAX]` acts like a macro that expands into `MAX`.  Macros are
useful as immediate words to performs specific operations to compile one or
more words into a definition.

### Compile-time conditionals

Forth source input is conditionally interpreted and compiled with `[IF]`,
`[ELSE]` and `[THEN]` words.  The `[IF]` word jumps to a matching `[ELSE]`
or `[THEN]` if the TOS is zero (i.e. false).  When used in colon definitions,
the TOS value should be produced immediately with `[` and `]`:

    [ test ] [IF]
      this source input is compiled if test is nonzero
    [THEN]

    [ test ] [IF]
      this source input is compiled if test is nonzero
    [ELSE]
      this source input is compiled if test is zero
    [THEN]

The `[DEFINED]` and `[UNDEFINED]` immediate words parse a name and return
`TRUE` if the name is defined as a word or not, otherwise return `FALSE`.  For
example, to check if `2NIP` is defined before using it within a colon
definition:

    : foo
      ...
      [DEFINED] 2NIP [IF] 2NIP [ELSE] ROT DROP ROT DROP [THEN] ↲
      ... ;

Likewise, we can define `2NIP` if undefined:

    [UNDEFINED] 2NIP [IF] ↲
    : 2NIP      ROT DROP ROT DROP ; ↲
    [THEN] ↲

## Source input and parsing

The interpreter and compiler parse input from two buffers, the `TIB` (terminal
input buffer) and `FIB` (file input buffer).  Input from these two sources is
controlled by the following words:

| word        | stack effect          | comment
| ----------- | --------------------- | ----------------------------------------
| `TIB`       | ( -- _c-addr_ )       | a 256 character terminal input buffer
| `FIB`       | ( -- _c-addr_ )       | a 256 character file input buffer
| `SOURCE-ID` | ( -- 0\|-1|_fileid_ ) | identifies the source input from a string (-1) with `EVALUATE` or the terminal (0) or from _fileid_
| `SOURCE`    | ( -- _c-addr_ _u_ )   | returns the current buffer (`TIB` or `FIB`) and the number of characters stored in it
| `>IN`       | ( -- _addr_ )         | a `VARIABLE` holding the current input position in the `SOURCE` buffer to parse from
| `REFILL`    | ( -- _flag_ )         | refills the current input buffer from `SOURCE-ID`, returns true if successful

The following words parse the current source of input:

| word       | stack effect ( _before_ -- _after_ ) | comment
| ---------- | ------------------------------------ | --------------------------
| `PARSE`    | ( _char_ "chars" -- _c-addr_ _u_ )   | parses "chars" up to a matching _char_, returns the parsed characters as string _c-addr_ _u_
| `\"-PARSE` | ( _char_ "chars" -- _c-addr_ _u_ )   | same as `PARSE` but also converts escapes to raw characters in _c-addr_ _u_, see `S\"` in [string constants](#string-constants)
| `PARSE-WORD` | ( _char_ "chars" -- _c-addr_ _u_ ) | same as `PARSE` but skips all leading matching _char_ first
| `PARSE-NAME` | ( "name" -- _c-addr_ _u_ )         | parses a name delimited by blank space, returns the name as a string _c-addr_ _u_
| `WORD`       | ( _char_ "chars" -- _c-addr_ )     | an obsolete word to parse a word

`PARSE-NAME` is the same as `BL PARSE-WORD`, where `BL` is the space character.
The names of words in the dictionary are parsed with `PARSE-NAME`.  When `BL`
is used as delimiter, also the control characters, such as CR and LF, are
considered delimiters.

The `EVALUATE` word combines parsing and execution with a string as the source
input:

| word       | stack effect                | comment
| ---------- | --------------------------- | -----------------------------------
| `EVALUATE` | ( ... _c-addr_ _u_ -- ... ) | redirects input to the string _c-addr_ _u_ to parse and execute

## Files

### Loading from files

The following words are available to load Forth source code from files on the
E: and F: drives and from the serial COM: port:

| word              | stack effect ( _before_ -- _after_ )            | comment
| ----------------- | ----------------------------------------------- | --------
| `INCLUDE`         | ( "name" -- )                                   | load Forth source code file "name"
| `INCLUDED`        | ( _c-addr_ _u_ -- )                             | load Forth source code file named by the string _c-addr_ _u_
| `INCLUDE-FILE`    | ( _fileid_ -- )                                 | load Forth source code from _fileid_
| `REQUIRE`         | ( "name" -- )                                   | load Forth source code file "name" if not already loaded
| `REQUIRED`        | ( _c-addr_ _u_ -- )                             | load Forth source code file named by the string _c-addr_ _u_ if not already loaded

### File and stream operations

The following file-related words are available:

| word              | stack effect ( _before_ -- _after_ )            | comment
| ----------------- | ----------------------------------------------- | --------
| `FILES`           | ( [ "glob" ] -- )                               | lists files matching optional "glob" with wildcards `*` and `?`
| `DELETE-FILE`     | ( _c-addr_ _u_ -- _ior_ )                       | delete file with name _c-addr1_ _u1_
| `RENAME-FILE`     | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- _ior_ )      | rename file with name _c-addr1_ _u1_ to _c-addr2_ _u2_
| `FILE-STATUS`     | ( _c-addr_ _u_ -- _s-addr_ _ior_ )              | if file with name _c-addr_ _u_ exists, return _ior_=0
| `R/O`             | ( -- _fam_ )                                    | open file for read only
| `W/O`             | ( -- _fam_ )                                    | open file for write only
| `R/W`             | ( -- _fam_ )                                    | open file for reading and writing
| `BIN`             | ( _fam_ -- _fam_ )                              | update _fam_ for "binary file" mode access (does nothing)
| `CREATE-FILE`     | ( _c-addr_ _u_ _fam_ -- _fileid_ _ior_ )        | create new file named _c-addr_ _u_ with mode _fam_, returns _fileid_ or truncate existing file to zero length
| `OPEN-FILE`       | ( _c-addr_ _u_ _fam_ -- _fileid_ _ior_ )        | open existing file named _c-addr_ _u_ with mode _fam_, returns _fileid_ and _ior_
| `CLOSE-FILE`      | ( _fileid_ -- _ior_ )                           | close file _fileid_
| `READ-FILE`       | ( _c-addr_ _u1_ _fileid_ -- _u2_ _ior_ )        | read buffer _c-addr_ of size _u1_ from _fileid_, returning number of bytes _u2_ read and _ior_
| `READ-LINE`       | ( _c-addr_ _u1_ _fileid_ -- _u2_ _flag_ _ior_ ) | read a line into buffer _c-addr_ of size _u1_ from _fileid_, returning number of bytes _u2_ read and a _flag_ indicating when EOF is reached
| `READ-CHAR`       | ( _fileid_ -- _char_ _ior_ )                    | returns _char_ read from _fileid_
| `PEEK-CHAR`       | ( _fileid_ -- _char_ _ior_ )                    | returns the next _char_ from _fileid_ without reading it
| `WRITE-FILE`      | ( _c-addr_ _u_ _fileid_ -- _ior_ )              | write buffer _c-addr_ of size _u_ to _fileid_
| `WRITE-LINE`      | ( _c-addr_ _u_ _fileid_ -- _ior_ )              | write string _c-addr_ of size _u_ and CR LF to _fileid_
| `WRITE-CHAR`      | ( _char_ _fileid_ -- _ior_ )                    | write _char_ to _fileid_
| `FILE-INFO`       | ( _fileid_ -- _ud1_ _ud2_ _u1_ _u2_ _ior_ )     | returns file _fileid_ current position _ud1_ file size _ud_ file attribute _u1_ and device attribue _u2_
| `FILE-SIZE`       | ( _fileid_ -- _ud_ _ior_ )                      | returns file _fileid_ size _ud_
| `FILE-POSITION`   | ( _fileid_ -- _ud_ _ior_ )                      | returns file _fileid_ current position _ud_
| `FILE-END?`       | ( _fileid_ -- _flag_ _ior_ )                    | returns `TRUE` if current position in _fileid_ is a the end
| `SEEK-SET`        | ( -- 0 )                                        | to seek from the start of the file
| `SEEK-CUR`        | ( -- 1 )                                        | to seek from the current position in the file
| `SEEK-END`        | ( -- 2 )                                        | to seek from the ens of the file
| `SEEK-FILE`       | ( _d_ _fileid_ 0\|1\|2 -- _ior_ )               | seek file offset _d_ from the start, relative to the current position or from the end
| `REPOSITION-FILE` | ( _ud_ _fileid_ -- _ior_ )                      | seek file offset _ud_ from the start
| `RESIZE-FILE`     | ( _ud_ _fileid_ -- _ior_ )                      | resize _fileid_ to _ud_ bytes (cannot truncate files, only enlarge)
| `DRIVE`           | ( -- _addr_ )                                   | returns address _addr_ of the current drive letter
| `DSKF`            | ( _c-addr_ _u_ -- _du_ _ior_ )                  | returns the free capacity of the drive in string _c-addr_ _u_
| `STDO`            | ( -- 1 )                                        | returns _fileid_=1 for standard output to the screen
| `STDI`            | ( -- 2 )                                        | returns _fileid_=2 for standard input from the keyboard
| `STDL`            | ( -- 3 )                                        | returns _fileid_=3 for standard output to the line printer
| `>FILE`           | ( _fileid_ -- _s-addr_ _ior_ )                  | returns file _s-addr_ data for _fileid_
| `FILE>STRING`     | ( _s-addr_ -- _c-addr_ _u_ )                    | returns string _c-addr_ _u_ file name converted from file _s-addr_ data

Low-level file I/O words return _ior_ to indicate success (zero) or failure
with nonzero [file error](#file-errors) code.

`FILE-INFO` returns current position _ud1_ file size _ud_ file attribute _u1_
and device attribue _u2_.  See the PC-E500 technical manual for details on
the attribute values.

If an exception occurs before a file is closed, then the file cannot be opened
again.  Doing so returns error _ior_=264.  The _fileid_ of open files start
with 4, which means that the first file opened but not closed can be manually
closed with `4 CLOSE-FILE .` displaying zero when successful.

### Filename globbing

Globs with wildcard `*` and `?` can be used to list files on the E: or F:
drive with `FILES`, for example:

    FILES E:*.*       \ list all E: files and change the current drive to E:
    FILES             \ list all files on the current drive
    FILES *.FTH       \ list all FTH files on the current drive
    FILES PROGRAM.*   \ list all PROGRAM files with any extension on the current drive
    FILES PROGRAM.??? \ same as above

Up to one `*` for the file name may be used and up to one `*` for the file
extension may be used.  Press BREAK or C/CE to stop the `FILES` listing.

The `FILES` word repeatedly calls `FIND-FILE` that uses glob patterns to
provide information about files:

| word        | stack effect ( _before_ -- _after_ )                             | comment
| ----------- | ---------------------------------------------------------------- | -------
| `FIND-FILE` | ( _c-addr_ _u1_ _u2_ -- _c-addr_ _u1_ _u2_ _s-addr_ _u3_ _ior_ ) | returns the _s-addr_ of a file with directory index _u3_>=_u2_ that matches the string pattern _c-addr_ _u1_

### Device drive names

When a drive letter is used with a filename or glob pattern, the specified
drive becomes the current drive.  To change the current drive letter:

    'F DRIVE C!

The PC-E500 drive names associated with devices are:

| drive name    | _fam_ | comment
| ------------- | ----- | -------------------------------------------------------
| STDO: / SCRN: | `W/O` | LCD display
| STDI: / KYBD: | `R/O` | keyboard
| STDL: / PRN:  | `W/O` | printer
| COM:          | `R/W` | SIO
| CAS:          | `R/W` | tape
| E:            | `R/W` | internal RAM disk
| F:            | `R/W` | external RAM disk
| G:            | `R/O` | ROM disk
| X:            | `R/W` | FDD

The first three devices are always accessible with the `STDO`, `STDI` and
`STDL` words that return the corresponding _fileid_.  `STDL` is usable after
connecting and checking the status of the printer with `PRINTER`, see also
[character output](#character-output).

### Loading from tape

The following words load raw binary data or text and Forth source code from
"tape" (any audio device) via a SHARP CE-126P printer and cassette interface or
a CE-124 cassette interface:

| word    | stack effect            | comment
| ------- | ----------------------- | ------------------------------------------
| `TAPE`  | ( -- _addr_ _u_ _ior_ ) | load data (binary or text) from tape into free dictionary space, returning data _addr_ of size _u_
| `CLOAD` | ( -- )                  | load and compile Forth source code from tape

`TAPE` stores the raw tape data in free space located directly below the
floating point stack.  When data was successfully loaded, zero is returned with
the address and size of the data.  Otherwise a nonzero _ior_ [file
error](#file-errors) code is returned with incomplete data.  The data stored in
free space is not persistent and may be overwritten when the dictionary grows.

`CLOAD` calls `TAPE` `THROW` and `EVALUATE`.  Because `TAPE` saves the tape
data to the free space in the dictionary, the Forth source code should not
initially allocate large chunks of the dictionary with `ALLOT`.  Doing so may
overwrite the Forth source code stored in the remaining free space and may
cause strange compilation errors.

To transfer data and Forth source code from a host PC to the PC-E500(S), a wav
file of the data or Forth source code should be created with the popular
[PocketTools](https://www.peil-partner.de/ifhe.de/sharp/) and then "played" on
the audio output to transmit the file to the PC-E500(S) via a cassette
interface:

    $ bin2wav --pc=E500 --type=bin -dINV sourcefile
    $ afplay sourcefile.wav

Use maximum volume to play the file or close to maximum to avoid distortion.
If `-dINV` does not transfer the file, then try `-dMAX`.  The `bin2wav` tool
reports the "start address" and "end address", which are not relevant and can
be ignored.

The following `tcopy` definition copies tape data to a new file on the E: or F:
drive:

    : ?ior      ( fileid ior -- fileid ) ?DUP IF SWAP CLOSE-FILE DROP THROW THEN ;
    : tcopy     ( "filename" -- )
      PARSE-NAME W/O CREATE-FILE THROW
      DUP TAPE ?ior
      ROT WRITE-FILE ?ior
      CLOSE-FILE DROP ;

Executing `tcopy FLOATEXT.FTH` copies the Forth source code transmitted from
tape to the new file `FLOATEXT.FTH` on the current drive.

### File errors

File I/O _ior_ error codes returned by file operations, _ior_=0 means no error:

| code | error
| ---- | -----------------------------------------------------------------------
| 256  | an error occurred in the device and aborted ($00)
| 257  | the parameter is beyond the range ($01)
| 258  | the specified file does not exist ($02)
| 259  | the specified pass code does not exist ($03)
| 260  | the number of files to be opened exceeds the limit ($04)
| 261  | the file whose processing is not permitted ($05)
| 262  | ineffective file handle was attempted (invalid _fileid_ argument) ($06)
| 263  | processing is not specified by open statement ($07)
| 264  | the file is already open ($08)
| 265  | the file name is duplicated ($09)
| 266  | the specified drive does not exist ($0a)
| 267  | error in data verification ($0b)
| 268  | processing of byte number has not been completed ($0c)
| 510  | fatal low battery ($fe)
| 511  | break key was pressed ($ff)

The _ior_ code is the PC-E500(S) technical manual page 5 FCS error code + 256.

## Exceptions

| word     | stack effect ( _before_ -- _after_ ) | comment
| -------- | ------------------------------------ | ----------------------------
| `ABORT`  | ( ... -- ... )                       | unconditionally abort execution and throw -1
| `ABORT"` | ( "string" -- ; ... _x_ -- ... )     | if _x_ is nonzero, display "string" message and throw -2
| `QUIT`   | ( ... -- ... )                       | throw -56
| `THROW`  | ( ... _x_ -- ... ) or ( 0 -- )       | if _x_ is nonzero, throw _x_ else drop the 0
| `CATCH`  | ( _xt_ -- ... 0 ) or ( _xt_ -- _x_ ) | execute _xt_, if an exception _x_ occurs then restore the stack and return _x_, otherwise return 0
| `'`      | ( "name" -- _xt_ )                   | tick returns the execution token of "name" on the stack
| `[']`    | ( "name" -- ; -- _xt_ )              | compiles "name" as an execution token literal _xt_

`ABORT`, `ABORT"` and `QUIT` return control to the keyboard to enter commands.

Note that `test ABORT" test failed"` throws -2 if `test` leaves a nonzero on
the stack.  This construct can be used to check return values and perform
assertions on values in the code.

The `CATCH` word executes the execution token _xt_ on the stack like `EXECUTE`,
but catches exceptions thrown.  If an exception _x_ is thrown, then the stack
has the state before `CATCH` with _xt_ removed and the nonzero exception code
_x_ as the new TOS.  Otherwise,  a zero is left on the stack.  For example:

    : try-divide    ( dividend divisor -- )
      ['] / CATCH IF ↲
        ." cannot divide by zero" 2DROP \ remove dividend and divisor ↲
      ELSE ↲
        ." result=" . ↲
      THEN ; ↲
    9 3 try-divide ↲
    result=3 OK[0]
    9 0 try-divide ↲
    cannot divide by zero OK[0]

`CATCH` restores the stack pointers when an exception is thrown, but the stack
values may be changed by the word executed and thus may or may not hold the
original values before `CATCH`.

To throw and catch any errors when opening a file read-only, read it in blocks
of 256 bytes into the `PAD` to display on screen, and close at the end of the
file.  We also want to catch a `read` exception to properly `close` the file
then re-throw the exception:

    : VARIABLE fh \ file handle, nonzero when file is open
    : open      ( c-addr u -- ) R/O OPEN-FILE THROW fh ! ;
    : read      ( -- len ) PAD 256 fh @ READ-FILE THROW ;
    : close     ( -- ) fh @ CLOSE-FILE fh OFF THROW ;
    : more      ( c-addr u -- )
      open
      BEGIN
        ['] read CATCH ?DUP IF
          close
          THROW \ rethrow exception thrown by read
        THEN
      ?DUP WHILE
        PAD SWAP TYPE
      REPEAT
      close CR ;
    : test-more ( -- ) S" somefile.txt" ['] more CATCH ABORT" an error occurred" ;

The following [standard Forth exception
codes](https://forth-standard.org/standard/exception) may be thrown by built-in
Forth500 words:

| code | exception
| ---- | -----------------------------------------------------------------------
| -1   | `ABORT`
| -2   | `ABORT"`
| -3   | stack overflow
| -4   | stack underflow
| -5   | return stack overflow
| -6   | return stack underflow
| -7   | do-loops nested too deeply during execution
| -8   | dictionary overflow
| -9   | invalid memory address
| -10  | division by zero
| -11  | result out of range
| -12  | argument type mismatch
| -13  | undefined word
| -14  | interpreting a compile-only word
| -15  | invalid `FORGET`
| -16  | attempt to use zero-length string as a name
| -17  | pictured numeric output string overflow
| -18  | parsed string overflow
| -19  | definition name too long
| -20  | write to a read-only location
| -21  | unsupported operation
| -22  | control structure mismatch
| -23  | address alignment exception
| -24  | invalid numeric argument
| -25  | return stack imbalance
| -26  | loop parameters unavailable
| -27  | invalid recursion
| -28  | user interrupt
| -29  | compiler nesting
| -30  | obsolescent feature
| -31  | `>BODY` used on non-CREATEd definition
| -32  | invalid name argument (invalid `TO` name)
| -33  | block read exception
| -34  | block write exception
| -35  | invalid block number
| -36  | invalid file position
| -37  | file I/O exception
| -38  | non-existent file
| -39  | unexpected end of file
| -40  | invalid BASE for floating point conversion
| -41  | loss of precision
| -42  | floating-point divide by zero
| -43  | floating-point result out of range
| -44  | floating-point stack overflow
| -45  | floating-point stack underflow
| -46  | floating-point invalid argument
| -47  | compilation word list deleted
| -48  | invalid `POSTPONE`
| -49  | search-order overflow
| -50  | search-order underflow
| -51  | compilation word list changed
| -52  | control-flow stack overflow
| -53  | exception stack overflow
| -54  | floating-point underflow
| -55  | floating-point unidentified fault
| -56  | `QUIT`
| -57  | exception in sending or receiving a character
| -58  | `[IF]`, `[ELSE]`, or `[THEN]` exception
| -256 | execution of an uninitialized deferred word (Forth500)

## Environment queries

The `ENVIRONMENT?` word takes a string to return system-specific information
about the Forth500 implementation as required by [standard
Forth](https://forth-standard.org/standard/usage#usage:env) `ENVIRONMENT?`.
These queries return `TRUE` with a value of the indicated type:

| query string         | type   | meaning
| -------------------- | ------ | ----------------------------------------------
| `/COUNTED-STRING`    | _n_    | maximum size of a counted string, in characters
| `/HOLD`              | _n_    | size of the pictured numeric output string buffer, in characters
| `/PAD`               | _n_    | size of the scratch area pointed to by PAD, in characters
| `ADDRESS-UNIT-BITS`  | _n_    | size of one address unit, in bits
| `FLOORED`            | _flag_ | true if floored division is the default
| `MAX-CHAR`           | _u_    | maximum value of any character in the implementation-defined character set
| `MAX-D`              | _d_    | largest usable signed double number
| `MAX-N`              | _n_    | largest usable signed integer
| `MAX-U`              | _u_    | largest usable unsigned integer
| `MAX-UD`             | _ud_   | largest usable unsigned double number
| `RETURN-STACK-CELLS` | _n_    | maximum size of the return stack, in cells
| `STACK-CELLS`        | _n_    | maximum size of the data stack, in cells
| `FLOATING-STACK`     | _n_    | maximum size of the floating point stack, in floats
| `MAX-FLOAT`          | _r_    | largest usable floating point number

For example, `S" MAX-N" ENVIRONMENT? . .` displays `-1` (true) and `32767`.

Non-implemented and obsolescent queries (according to the Forth Standard)
return `FALSE`.  Obsolescent queries that return `FALSE` but are in fact
available in Forth500:

| query string    | type   | comment
| --------------- | ------ | ---------------------------------------------------
| `CORE`          | _flag_ | available
| `CORE-EXT`      | _flag_ | available
| `DOUBLE`        | _flag_ | available
| `DOUBLE-EXT`    | _flag_ | available
| `EXCEPTION`     | _flag_ | available
| `EXCEPTION-EXT` | _flag_ | available
| `FACILITY`      | _flag_ | available
| `FACILITY-EXT`  | _flag_ | partly available
| `FILE`          | _flag_ | available
| `FILE-EXT`      | _flag_ | available
| `FLOATING`      | _flag_ | available
| `FLOATING-EXT`  | _flag_ | `INCLUDE FLOATEXT.FTH` to complete
| `STRING`        | _flag_ | available
| `TOOLS`         | _flag_ | partly available
| `TOOLS-EXT`     | _flag_ | partly available

Some public Forth libraries still test these queries.  To use these libraries
with Forth500, change the library Forth source code to successfully pass
obsolescent queries.

## Dictionary structure

The Forth500 dictionary is organized as follows:

         low address in the 11th segment $Bxxxx
          _________
    +--->| $0000   |     last entry link is zero (2 bytes)
    ^    |---------|
    |    | 7       |     length of "(DOCOL)" (1 byte)
    |    |---------|
    |    | (DOCOL) |     "(DOCOL)" word characters (7 bytes)
    |    |---------|
    |    | code    |     machine code
    |    |=========|
    +<==>+ link    |     link to previous entry (2 bytes)
    ^    |---------|
    :    :         :
    :    :         :
    :    :         :
    |    |=========|
    +<==>| link    |     link to previous entry (2 bytes)
    ^    |---------|
    |    | $80+5   |     length of "aword" (1 byte) with IMMEDIATE bit set
    |    |---------|
    |    | aword   |     "aword" word characters (5 bytes)
    |    |---------|
    |    | code    |     Forth code and/or data
    |    |=========|
    +<---| link    |<--- LAST link to previous entry (2 bytes)
         |---------|
         | 7       |     length of "my-word" (1 byte)
         |---------|
         | my-word |     "my-word" word characters (7 bytes)
         |---------|
         | code    |<--- LAST-XT Forth code and/or data
         |=========|<--- HERE pointer to free space
         |         |     (and the 40 byte hold area for numerical output)
         | free    |
         | space   |
         |         |
         |=========|<--- dictionary limit
         |         |
         | float   |     stack of 120 bytes (10 floats)
         | stack   |     grows toward lower addresses
         |         |<--- FP stack pointer
         |=========|
         |         |
         | data    |     stack of 256 bytes (128 cells)
         | stack   |     grows toward lower addresses
         |         |<--- SP stack pointer
         |=========|
         |         |
         | return  |     return stack of 256 bytes
         | stack   |     grows toward lower addresses
         |         |<--- RP return stack pointer
         |---------|<--- $BFC00

         high address

A link field points to the previous link field.  The last link field at the
lowest address of the dictionary is zero.

`LAST` returns the address of the last entry in the dictionary.  This is where
the search for dictionary words starts.

`LAST-XT` returns the execution token of the last definition, which is the
location where the machine code of the last word starts.

Code is either machine code or starts with a jump or call machine code
instruction of 3 bytes, followed by Forth code (a sequence of execution tokens
in a colon definition) or data (constants, variables, values and other words
created with `CREATE`).

Immediate words are marked with the length byte high bit 7 set ($80).  Hidden
words have the "smudge" bit 6 ($40) set.  A word is hidden until successfully
compiled.  `HIDE` hides the last defined word by setting the smudge bit.
`REVEAL` reveals it.  Incomplete colon definitions with compilation errors
should never be revealed.

There are two words to search the dictionary:

| word        | stack effect ( _before_ -- _after_ )
| ----------- | ----------------------------------------------------------------
| `FIND`      | ( _c-addr_ -- _xt_ 1 ) if found and word is immediate, ( _c-addr_ -- _xt_ -1 ) if found and not immediate, otherwise ( _c-addr_ -- _c-addr_ 0 ) 
| `FIND-WORD` | ( _c-addr_ _u_ -- _xt_ 1 ) if found and word is immediate, ( _c-addr_ _u_ -- _xt_ -1 ) if found and not immediate, otherwise ( _c-addr_ _u_ -- 0 0 ) 

`FIND` takes a counted string _c-addr_ whereas `FIND-WORD` takes a string
_c-addr_ of size _u_ to search.  The search is case insensitive.  Hidden words
are not searchable but are displayed by `WORDS`.

`:NONAME` and `CREATE-NONAME` code has no dictionary entry.  The code is just
part of the dictionary space as a block of code without link and name header.
Both words return the execution token of the code.

## Examples

### CHDIR

File operations like `FILES F:*.*` change the current drive letter to the
specified drive letter.  This changes the `DRIVE` variable.

We can also change the `DRIVE` letter by defining a new word that sets
`DRIVE C!` by the drive letter parsed from the input with `PARSE-NAME`
(we can `DROP` the length which is always positive non-zero):

    : CHDIR     ( "letter" -- ) PARSE-NAME DROP C@ DRIVE C! ;

For example:

    CHDIR F
    FILES

### GCD

The greatest common divisor of two integers is computed with Euclid's algorithm
in Forth as follows:

    : gcd   ( n1 n2 -- gcd ) BEGIN ?DUP WHILE TUCK MOD REPEAT ;

The double integer version:

    : dgcd  ( d1 d2 -- dgcd ) BEGIN 2DUP D0<> WHILE 2TUCK DMOD REPEAT 2DROP ;

### RAND

A Forth500 version of the C rand() function to generate pseudo-random numbers
between 0 and 32767:

    2VARIABLE seed
    : rand  ( -- +n ) seed 2@ 1103515245. D* 12345. D+ TUCK seed 2! 32767 AND ;
    : srand ( x -- ) S>D seed 2! ;
    1 srand

Note: do not use `rand` for serious applications.

To draw a randomized "starry night" on the 240x32 pixel screen:

    : starry-night PAGE 1000 0 DO rand 240 MOD rand 32 MOD GPOINT LOOP ;

Note that Forth500 includes an `FRAND` floating point random number generator,
see [floating point arithmetic](#floating-point-arithmetic).

As an example application of `rand`, let's simulate a Galton board with 400
balls and as many as 100 levels (!) of pegs:

    400 VALUE balls     \ number of balls to drop
    100 VALUE levels    \ levels of pegs on the board
    120 VALUE middle    \ starting point on the screen

Dropping a ball in the board means going left or right at each peg on the
board, performing a random walk on the x-axis as it falls down:

    : random-walk   ( xpos steps -- xpos ) 0 DO rand 1 AND 2* 1- + LOOP ;

Balls accumulate at the bottom on top of eachother:
    
    : accumulate    ( xpos -- ) 0 BEGIN 2DUP GPOINT? 0= WHILE 1+ REPEAT 1- GPOINT ;

Each ball drops from the middle, makes a random walk, and accumulates making a
click sound:
    
    : drop-ball     middle levels random-walk accumulate 100 10 BEEP ;

The program repeats for all balls:
    
    : Galton        0 GMODE! PAGE balls 0 DO drop-ball LOOP S" done" PAUSE ;

### SQRT

The square root of a number is approximated with Newton's method.  Forth500
includes a floating point `FSQRT` word.  This example shows how the method can
be used to efficiently compute the square root of an integer without `FSQRT`,

Given an initial guess _x_ for _f_(_x_) = 0, an improved guess is _x_' = _x_ -
_f_(_x_)/_f_'(_x_).  This is iterated with _x_=_x'_ until convergence.

To compute _sqrt_(_a_), let _f_(_x_) = _x_^2 - _a_ to find the answer _x_ with
Newton's method such that _f_(_x_) = 0.  Therefore, _x'_ = _x_ -
(_x_^2-_a_)/(2 _x_) = (_x_ + _a_/_x_)/2.

Because we operate with integers, the convergence check should consider the
previous two estimates of _x_ to avoid oscillation.  The outline of the
algorithm is:

    y = 1                   \ estimate before the previous estimate
    x = 1                   \ previous estimate
    begin
      x' = (x+a/x)/2        \ improved estimate
      while x'<>x and x'<>y \ convergence?
        y = x               \ update estimates
        x = x'
    again

This algorithm assumes that _a_ is positive.  Negative _a_ are invalid and may
raise a division by zero exception.  If _a_ is zero then we also raise an
exception, which we want to avoid by returning zero if _a_ is zero.

To implement the algorithm in Forth, we place _a_ on the return stack, because
we only need _a_ to compute _x'_.  We place _y_ and _x_ on the stack and
compute the new estimate _x'_ as the TOS above them:

    : sqrt      ( n -- sqrt )
      DUP IF            \ if a<>0
        >R              \ move a to the return stack
        1 1             \ -- y x where y=1 and x=1 initially
        BEGIN
          R@            \ -- y x a
          OVER /        \ -- y x (a/x)
          OVER + 2/     \ -- y x x' where x'=(a/x+x)/2
          ROT           \ -- x x' y
          OVER <> WHILE \ while x'<>y
          2DUP <> WHILE \ and also while x'<>x
        REPEAT THEN
        DROP            \ -- x
        R>DROP          \ drop a from the return stack
      THEN ;

Note that the second `WHILE` requires a `THEN` after `REPEAT`.  For an
explanation of this multi-`WHILE` structure, see [loops](#loops).

A minor issue is the potential integer overflow to a negative value in
(_a_/_x_+_x_) before dividing by 2.  This can lead to all sorts of problems,
such as non-termination of the loop.  This problem can be remedied by an
unsigned division by 2 with `1 RSHIFT` to replace `2/`.

The double integer square root implementation:

    : dsqrt     ( d -- dsqrt )
      2DUP D0<> IF
        2>R
        1. 1.
        BEGIN
          2R@
          2OVER D/
          2OVER D+ 2. D/
          2ROT
          2OVER D<> WHILE
          2OVER 2OVER D<> WHILE
        REPEAT THEN
        2DROP
        R>DROP R>DROP
      THEN ;

### Numerical integration

In this example we use Simpson's rule for numerical integration.  Simpson's
rule approximates the definite integral of a function _f_ over a range [a,b]
with 2n summation steps:

_I_ = _h_/3 × [ _f_(_a_) + ∑ᵢ₌₁ ⁿ ( 4 _f_(_a_ + _h_ × (2 i - 1)) + 2 _f_(_a_ + 2 _h_ i) ) - _f_(_a_ + 2 _h_ _n_) ]

where _h_ = (_b_-_a_)/(2 _n_)

First we define the function to integrate as a deferred word in Forth, which
means we can assign it later any given function _y_=_f_(_x_) defined in Forth
to integrate:

    DEFER integrand     ( F: x -- y )

Next, we define three variables to hold _x_ = _a_+_h_ × (2 i - 1),
_h_=(_b_-_a_)/(2 _n_) and the partial _sum_:

    FVARIABLE x
    FVARIABLE h
    FVARIABLE sum

Note that Forth doesn't care if you redefine `x` later, because `x` and the
other variables remain visible to `integrate` as a form of static scoping.
Thus, `x`, `h` and `sum` are essentially local variables of `integrate`.

Variables `x` and `h` are initialized with _a_ and (_b_-_a_)/(2 _n_),
respectively, where _a_ and _b_ are on the floating point stack and _n_ is on
the regular stack:

    : init      ( F: a b -- ; n -- ) FOVER F- 2* S>F F/ h F! x F! 0e sum F! ;

In the following definition we aim to update the next value of `x` and return
its updated value on the floating point stack to use right away:

    : nextx     ( F: -- x ) x F@ h F@ F+ FDUP x F! ;

To accummulate the sum, we multiply _y_=_f_(_x_) by the FP TOS (4e or 2e) and
add it to `sum`:

    : *sum+!    ( F: y r -- ) F* sum F@ F+ sum F! ;

The integration proceeds by first dividing the number of steps by 2 to get _n_,
then set `x` to _a_ and `h` to (_b_-_a_)/(2 _n_) with `init` and the `sum` to
_f_(_a_) before the summation loop:

    : integrate         ( F: a b -- I ; 2n -- )
      2/ DUP init
      x F@ integrand 1e *sum+!
      0 ?DO
        nextx integrand 4e *sum+!
        nextx integrand 2e *sum+!
      LOOP
      x F@ integrand -1e *sum+!
      sum F@ h F@ F* 3e F/ ;

Recall that all floating point values must be typed with an exponent `e` for
single precision or `d` for double precision.

Because Forth500 internally switches to double precision if any of the operands
of an arithmetic operation are double precision, the function to integrate or
the integration bounds may use double precision to produce a double precision
result.  The double precision integration result is not affected by the use of
the single precision weight values, such as `1e`, `2e`, `3e` and `4e`, in the
`integrate` definition.

Let's integrate _f_(_x_)=1/(_x_ ² + 1) over [0,1] with 2 _n_ = 10 steps:

    6 SET-PRECISION ↲
    :NONAME FDUP F* 1e F+ 1e FSWAP F/ ; IS integrand ↲
    0e 1e 10 integrate F. ↲
    0.785398 OK[0]

We set the precision to 6 digits to display the result with `F.`.  We defined
an anonymous function with `:NONAME` as the `integrand` to integrate.

With double precision floating point and 100 steps:

    20 SET-PRECISION ↲
    0d 1d 100 integrate F. ↲
    0.7853981633974 OK[0]

This example demonstrates how easy it is to switch to double precision.  But
this is not very useful with Simpson's rule of integration.  The precision of
the result is determined by Simpson's approximation and the number of steps
performed, rather than by the use of higher precision floating point values.

Because Forth500 internally operates with BCD (Binary-Coded Decimal) floating
point values, the numerical result of this example differs slightly from
implementations that internally use IEEE 754 floating point values.

### Strings

This example is an implementation with string buffers residing in the
dictionary, which is pretty standard practice in Forth.  Each buffer includes
the maximum length of the string as the first byte followed by the actual
length of the string in the second byte.  The string contents follow these two
bytes.  This implementation is safer than simpler implementations that do not
store the maximum string buffer size and thus have no protections against
buffer overflows.

In this example we keep our definitions short and concise by reusing words as
much as possible to avoid unnecessary complexity.

We first define four auxilliary words to obtain the max length, the current
length, the unused space and to set a new length limited by the max length:

    : strmax    ( string -- max ) 2- C@ ;
    : strlen    ( string -- len ) 1- C@ ;
    : strunused ( string -- unused ) DUP strmax SWAP strlen - ;
    : strupdate ( string len -- ) OVER strmax UMIN SWAP 1- C! ;

Note that we used `UMIN` to prevent negative string lengths (`MIN` is signed).

A `string` value on the stack is an address that points right after the max and
length bytes to the string contents stored in a string buffer.

The following `string:` word creates a string buffer given a maximum length:

    : string:   ( max "name" -- ; string len )
      CREATE DUP C, 0 C, ALLOT
      DOES> 2+ DUP strlen ;

Let's define a `name` to store up to 30 characters:

    30 string: name ↲

The string `name` returns the string address of its first character and the
length of the string.  This makes it simpler to use our strings as the usual
constant string arguments passed to standard Forth words, such as `TYPE`:

    name TYPE ↲
    OK[0]

This displays nothing because the string is initially empty.

To safely copy a (constant) string to a string buffer by limiting the number of
characters copied to guard against overflowing the buffer:

    : strcpy    ( c-addr u string len -- )
      DROP DUP ROT strupdate \ set the new length
      DUP strlen CMOVE ;

For example:

    S" John" name strcpy ↲
    name TYPE ↲
    John OK[0]

To safely concatenate a string to another by limiting the number of characters
appended to guard against overflowing the buffer:

    : strcat    ( c-addr u string len -- )
      >R                       \ save the old length
      SWAP OVER strunused UMIN \ limit the added length
      2DUP R@ + strupdate      \ set the new length = old length + added
      SWAP R> + SWAP CMOVE ;

For example:

    S"  Doe" name strcat ↲
    name TYPE ↲
    John Doe OK[0]

Forth words that work with constant strings, such as `TYPE`, `SEARCH` and `S=`,
also work with our string buffers:

    name S" Do" SEARCH . TYPE ↲
    -1 Doe OK[0]
    S" John" name 4 MIN S= . ↲
    -1 OK[0]

We can also accept user input into a string:

    : straccept ( string len -- ) DROP DUP DUP strmax ACCEPT strupdate ;
    : stredit   ( string len -- )
      >R DUP strmax R> \ -- string max len
      DUP              \ place cursor at the end (=len)
      0                \ allow edits to the begin at position 0 (no prompt)
      EDIT strupdate ;

For example:

    name straccept ↲
    John ↲
    name stredit ↲
     Doe ↲
    name TYPE ↲
    John Doe OK[0]

The `NEXT-CHAR` word slices off the first character of a string by incrementing
the address and decrementing the length by one:

    name NEXT-CHAR EMIT CR TYPE ↲
    J
    ohn Doe OK[0]

The `/STRING` ("slash string") word advances the string address and reduces the
string length by the given amount and :

    name 5 /STRING TYPE ↲
    Doe OK[0]

We can define a word to slice strings.  Slicing a substring from a (constant)
string returns the (constant) substring address and substring length:

    : slice     ( c-addr1 u1 pos len -- c-addr2 u2 )
      >R        \ save len
      OVER UMIN \ -- c-addr u1 pos where pos is limited to u1
      TUCK      \ -- c-addr pos u1 pos
      - R> UMIN \ -- c-addr pos len where pos+len is limited to u1
      >R + R> ;

where _pos_ and _len_ take a slice from string _c-addr1_ _u1_ to return the
substring _c-addr2_ _u2_ located in _c-addr1_ at position _pos_ with length
_len_.  If _pos_ exceeds the string length _u1_ then _u2_=0. If _pos_+_len_
exceeds the string length _u1_ then _u2_<_len_.

For example:

    name 5 3 slice TYPE ↲
    Doe OK[0]

Note that we can take slices of slices:

    name 4 4 slice 1 2 slice TYPE ↲
    Do OK[0]

Slicing can be used to modify a string by copying or concatenating a slice of
the string to itself:

    name 5 3 slice name strcat ↲
    name TYPE ↲
    John DoeDoe OK[0]
    name 0 8 slice name strcpy ↲
    name TYPE ↲
    John Doe OK[0]

Inserting and deleting characters can be done with slicing and a temporary
buffer, such as the `PAD` of 256 bytes that can hold a string with up to 254
characters:

    : strtmp    254 PAD C! PAD 2+ PAD 1+ C@ ;

For example, to copy "John" from `name`, insert " J." and append " Doe" from
`name` into the string temporary:

    name 0 4 slice strtmp strcpy ↲
    S"  J." strtmp strcat ↲
    name 5 3 slice strtmp strcat ↲
    strtmp TYPE ↲
    John J. Doe OK[0]

Additional words to convert characters and string buffers to upper and lower
case:

    : toupper   ( char -- char ) DUP [CHAR] a [CHAR] { WITHIN IF $20 - THEN ;
    : tolower   ( char -- char ) DUP [CHAR] A [CHAR] [ WITHIN IF $20 + THEN ;
    : strupper  ( string len -- ) 0 ?DO DUP I + DUP C@ toupper SWAP C! LOOP DROP ;
    : strlower  ( string len -- ) 0 ?DO DUP I + DUP C@ tolower SWAP C! LOOP DROP ;

For example:

    name strupper name TYPE ↲
    JOHN DOE OK[0]

The following `sfield:` word adds a string member to a structure:

    : sfield:   ( u max "name" -- u ; addr -- string len )
      CREATE
        OVER ,  \ store current struct size u
        DUP ,   \ store max
        + 2+    \ update struct size += max+2
      DOES>     ( struct-addr addr -- member-addr )
        SWAP OVER @ + \ compute member address
        DUP ROT       \ -- member-addr member-addr addr
        CELL+ @ C!    \ make sure string max is set
        2+ DUP strlen ;

For example an address with a 30 max character street name:

    BEGIN-STRUCTURE address ↲
      30 sfield: address.street ↲
      FIELD:     address.number ↲
    END-STRUCTURE ↲
    : address: address BUFFER: ; ↲
    address: home ↲
    S" Pleasantville" home address.street strcpy ↲
    555 home address.number ! ↲
    home address.street TYPE SPACE home address.number ? ↲
    Pleasantville 555

To create arrays of (uninitialized) strings:

    : sarray:   ( size max "name" -- ; index -- string len )
      CREATE
        DUP , 2+ * ALLOT \ save max and allocate space
      DOES>     ( array-addr index -- string len )
        SWAP OVER @  \ -- addr index max
        DUP>R        \ save max
        2+ * + CELL+ \ address in the array = (max+2)*index+addr+2
        R> OVER C!   \ make sure the string max is set
        2+           \ skip max and len to get to string
        DUP strlen ;

To initialize an array element, just `strcpy` a value to it.  For example, to
create an array of 10 strings of 16 characters max, then copy "John" into array
item 5 (counting from 0):

    10 16 sarray: names ↲
    S" John" 5 names strcpy ↲

Large arrays of strings aren't very resource efficient, because each string
element in the array reserves space.  Best is to implement a heap to store
strings and use compaction to keep the heap space efficiently used.

### Enums

Enumerated values can be created with multiple `CONSTANT`, each for a new
enumeration value.  We can automate the constant value assignments as follows:

    : begin-enum        ( -- n ) 0 ;
    : enum              ( n "name" -- n ) DUP CONSTANT 1+ ;
    : end-enum          ( -- n ) DROP ;

Such that:

    begin-enum
      enum red
      enum white
      enum blue
    end-enum

will create the constants `red`, `white` and `blue` with values 0, 1 and 2,
respectively.  In a similar way we can define a `bitmask` word using `1 OVER
LSHIFT` to set the constants to 1, 2, 4, 8 and so on to perform bit operations
with `AND`, `OR`, `XOR` and `INVERT`.

If we don't care about the constants as long as they are unique, then another
approach is to use the unique address of a word as the enumeration value,
assuming the actual value does not matter as long as it is unique.  Consider
for example an enumeration of colors:

    CREATE red
    CREATE white
    CREATE blue

Each color word returns its address of the definitions body, which contains no
data.  Because in Forth500 the body if a word is 3 bytes below the execution
token, we can implement a word `enum.` to display the color name:

    : body>     ( addr -- xt ) 3 - ;
    : enum.     ( addr -- ) body> >NAME NAME>STRING TYPE ;

The `body>` "body from" word converts the address of the body of a word to its
execution token, `>NAME` converts the execution token to a name token and
`NAME>STRING` returns the string of a name token on the stack.  For example:

    red enum. ↲
    red OK[0]

Another way to implement enumerations is to use the address of a "counted
string" as a unique enumeration value:

    : red       C" the color red" ;
    : white     C" the color white" ;
    : blue      C" the color blue" ;

The string of a color word is displayed with `COUNT TYPE`.

This example shows how Forth encourages a bit of creativity to come up with an
approach that is best suited for an application.

### Slurp

"Slurping" a file into memory to process it is typically performed by storing
the file's contents in the free dictionary space.  The free dictionary space
serves as our working area.  We could pre-allocate memory with the file size,
but in this example we assume that the file size is unknown (e.g. when reading
standard input with piped input, keyboard input, etc.)  Therefore, slurping a
file is done incrementally by reading a chunk at a time.

First we need some variables:

    VARIABLE fh \ file handle, nonzero if file is open
    VARIABLE fp \ file content pointer, points to start of the slurped file
    VARIABLE fz \ file content length

Next, we define `slurp`:

    : slurp     ( c-addr u -- c-addr u ) open read close ;

The `slurp` word takes the file name as a string and returns the file contents
as a string.  The file `open` and `close` words use `OPEN-FILE` and
`CLOSE-FILE`, respectively, which return a I/O error code _ior_.  We want to
throw this error:

    : open      ( c-addr u -- ) R/O OPEN-FILE THROW fh ! ;
    : close     fh @ ?DUP IF CLOSE-FILE fh OFF THROW THEN ;

Note that `close` has a guard to close only open files (omitting the guard
`?DUP IF ... THEN` is fine too, it just throws an exception, because _fileid_=0
is invalid and cannot be closed).

Now we can `read` a file incrementally, "sipping" one block at a time until he
last sip is empty:

    : read      start BEGIN sip 0= UNTIL done ;

To `start`, we just initialize `fp` to `HERE` to point to the free space:

    : start     HERE fp ! ;

A "sip" allocates and reads up to 100 bytes at a time from the file:

    : sip       ( -- n ) HERE 100 DUP ALLOT fh @ READ-FILE THROW DUP 100 - ALLOT ;

Note that the second `ALLOT` with a negative size (= number of bytes read -
100) releases unused space back to the dictionary, then returns the number of
bytes read.

After repeately "sipping", we can compute and return the length by subtracting
`HERE` (the final address) from `fp @` (the starting address) and return `fp`
and `fz`:

    : done      ( -- c-addr u ) HERE fp @ - fz ! fp @ fz @ ;

For good measure, when we are all good and done with the file in memory, we
should release memory back to the dictionary:

    : release   fp @ HERE - ALLOT ;

If we decide not to `release`, then the file remains in memory for later use.
Before slurping another file, make sure to save `fp` and `fz` to retain access
to the file's content stored in memory.

Let's recap and put things in order:
   
    VARIABLE fh \ file handle, nonzero if file is open
    VARIABLE fp \ file content pointer, points to start of the slurped file
    VARIABLE fz \ file content length
    : sip       ( -- n ) HERE 100 DUP ALLOT fh @ READ-FILE THROW DUP 100 - ALLOT ;
    : start     HERE fp ! ;
    : done      ( -- c-addr u ) here fp @ - fz ! fp @ fz @ ;
    : read      start BEGIN sip 0= UNTIL done ;
    : open      ( c-addr u -- ) R/O OPEN-FILE THROW fh ! ;
    : close     fh @ ?DUP IF CLOSE-FILE fh OFF THROW THEN ;
    : slurp     ( c-addr u -- c-addr u ) open read close ;
    : release   fp @ HERE - ALLOT ;

Note that definitions without a `(` stack effect `)` have no stack effect.

For example, we can search a text file for string matches, say "TODO":

    ." some.txt" slurp ." TODO" SEARCH release . ↲
    0 OK[2]

This will display -1 (true) when found and leaves the address of the match with
remaining length of the file on the stack, or 0 (false) when not found.

If the free space in the dictionary is insufficient, then exception -8 will be
thrown.  If that happens, call `close` and `release` to close the file and
release memory.

Slurping a file from the E: or F: drive is much simpler.  Since the file size is
known, we can pre-allocate memory space and gulp the whole file at once into
this space.  We can make the following changes accordingly:

    : data      ( -- c-addr u ) fp @ fz @ ;
    : gulp      fz @ ALLOT data fh @ READ-FILE THROW ;
    : size      fh @ FILE-SIZE THROW fz ! ;
    : read      start gulp data ;
    : slurp     ( c-addr u -- c-addr u ) open size read close ;

where `size` assigns variable `fz` the file size, `gulp` reads the whole file
at once and `data` returns the address and size of the file data (i.e. as
_c-addr_ _u_) for convenience.

## Further reading

[And so Forth...](https://thebeez.home.xs4all.nl/ForthPrimer/Forth_primer.html)
by Hans Bezemer.

[A Beginner's Guide to Forth](http://galileo.phys.virginia.edu/classes/551.jvn.fall01/primer.htm)
by J.V. Noble.

[Thinking Forth](http://thinking-forth.sourceforge.net)
by Leo Brodie.

[Forth Standard alphabetic list of words](https://forth-standard.org/standard/alpha)

_This document is Copyright Robert A. van Engelen (c) 2021_

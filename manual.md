# Forth500 User Guide

Author: Dr. Robert A. van Engelen, 2021

## Table of contents

- [Forth](#forth)
- [Quick tutorial](#quick-tutorial)
- [Stack effects](#stack-effects)
- [Stack manipulation](#stack-manipulation)
- [Integer constants](#integer-constants)
- [Arithmetic](#arithmetic)
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
  - [Introspection](#introspection)
- [Control flow](#control-flow)
  - [Conditionals](#conditionals)
  - [Loops](#loops)
- [Compile-time immedate words](#compile-time-immediate-words)
  - [The \[ and \] brackets](#the--and--brackets)
  - [Immediate execution](#immediate-execution)
  - [Literals](#literals)
  - [Postponing](#postponing)
  - [Compile-time conditionals](#compile-time-conditionals)
- [Source input and parsing](#source-input-and-parsing)
- [Files](#files)
- [File errors](#file-errors)
- [Exceptions](#exceptions)
- [Environmental queries](#environmental-queries)
- [Dictionary structure](#dictionary-structure)
- [Alphabetic list of words](#alphabetic-list-of-words)

## Forth

Forth500 is a [standard Forth 2012](https://forth-standard.org/standard/intro)
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

## Quick tutorial

This section is intentionally kept simple by avoiding technical jargon and
unnecessary excess.  Familiarity with the concepts of stacks and dictionaries
is assumed.  Experience with C makes it easier to follow the use of addresses
(pointers) to integer values, strings and other data in Forth.

A Forth system is a dictionary of words.  A word is often a name but can be any
sequence of characters excluding space, tab, newline, and other control
characters.  Words are defined for subroutines, for named constants and for
global variables and data.  Some words may execute at compile time to compile
the body of subroutine definitions and to implement control flow such as
branched and loops.  As such, the syntax blends compile-time and runtime
behaviors that are only distinguishable by naming and naming conventions.

You can enter Forth code at the Forth500 interactive prompt.  The following
special keys can be used:

| key         | comment
| ----------- | ----------------------------------------------------------------
| INS         | switch to insertion mode or back to replace mode
| DEL         | delete the character under the cursor
| BS          | backspace
| ENTER       | execute the line of input
| LEFT/RIGHT  | before typing input "replays" the last line of input
| CURSOR KEYS | move cursor up/down/left/right on the line
| C/CE        | clears the line

To exit Forth500 and return to BASIC, enter `bye`.  To reenter Forth500 from
BASIC, `CALL &Bxx00` again where `xx` is the high-order address of Forth500.

Forth500 is case insensitive.  Words may be typed in either case or use mixed
case.  In the following, built-in words are shown in UPPER CASE.  User-defined
words are shown in lower case.

To list the words stored in the Forth dictionary, type (↲ is ENTER):

    WORDS ↲

Hit any key to continue or ON/BRK to stop.  ON/BRK generally terminates the
execution of a Forth500 program or subroutine associated with a word.  To list
words that fully and partially match a given name, type:

    WORDS NAME ↲

For example, `WORDS DUP` lists all words with names that contain the part `DUP`
(the search is case sensitive).

Words like `DUP` operate on the stack.  `DUP` duplicates the top value,
generally called TOS: "Top Of Stack".  All computations in Forth occur on the
stack.  Words may take values from the stack, by popping them, and push return
values on the stack.  Besides words, type literal integer values to push them
onto the stack:

    TRUE 123 DUP .S ↲
    -1 123 123 OK[3]

where `TRUE` pushes -1, `123` pushes 123, `DUP` duplicates the TOS and `.S`
shows the stack values.  `OK[3]` indicates that currently there are three
values on the stack.

You can spread the code over multiple lines.  It does not matter if you hit
ENTER at the end or if you hit ENTER to input more than one line.

To clear the stack, type `CLEAR`:

    CLEAR ↲
    OK[0]

Like traditional Forth systems, Forth500 integers are 16-bit signed or
unsigned.  Decimal, hexadecimal and binary number systems are supported:

| input   | TOS | comment
| ------- | --- | --------------------------------------------------------------
| `TRUE`  |  -1 | Boolean true is -1
| `FALSE` |   0 | Boolean false is 0
| `123`   | 123 | decimal number (if the current base is `decimal`)
| `-1`    |  -1 |
| `0`     |   0 |
| `$FF`   | 255 | hexadecimal number
| `#-12`  | -12 | decimal number (regardless of the current base)
| `%1000` |   8 | binary number

The `.` word prints the TOS and pops it off the stack:

    1 2 + . ↲
    3 OK[0]

Two single stack integers can be combined to form a 32-bit signed or unsigned
integer.  A double integer number is pushed (as two single integers) when the
number is written with a `.` anywhere, but we prefer the `.` at the end:

    123. D. ↲
    123 OK[0] 

The use of `.` for double integers is unfortunate, because the number is not a
floating point number.  The `.` is traditional in Forth and still part of the
Forth standard.

The `D.` word prints a signed double integer and pops it from the stack.  Words
that operate on two integers as doubles are typically identified by `Dxxx` and
`2xxx`.

Words that execute subroutines are defined with a `:` (colon):

    : hello ." Hello, World!" CR ; ↲

This defines the word `hello` that displays the obligatory "Hello, World!"
message.  The definition ends with a `;` (semicolon).  The `."` word parses a
sequence of character until `"`.  These characters are display on screen.  Note
that `."` is a normal word and must therefore be followed by a space.  The `CR`
word starts a new line by printing a carriage return and newline.

Let's try it out:

    hello ↲
    Hello, World!

Some words like `."` and `;` are compile-time only, which means that they can
only be used in colon definitions.  Two other compile-time words are `DO` and
`LOOP` for loops:

    : greetings 10 0 DO hello LOOP ; ↲
    greetings ↲

This displays 10 lines with Hello, World!  Let's add a word that takes a
number as an argument, then displays that many `hello` lines:

    : hellos 0 DO hello LOOP ; ↲
    2 hellos ↲
    Hello, World!
    Hello, World!

It is good practice to define words with short subroutines.  It makes programs
much easier to understand and maintain.  Because words operate on the stack,
pretty much any sequence of words can be moved into a new defined word and
reused in other colon definitions.  This keeps definitions short and
understandable.  For example, we can redefine `greetings` to use `hellos`:

    : greetings 10 hellos ; ↲

But what if we want to change the message?  Forth allows you to redefine words
at any time, but this does not change the behavior of any previously defined
words that may be used by other previously defined words:

    : hello ." Hola, Mundo!" CR ; ↲
    2 hellos ↲
    Hello, World!
    Hello, World!

Only new words that we add after this will use our new `hello` definition.
Basically, the Forth dictionary is searched from the most recently defined
word to the oldest defined word.

We can delete old definitions by forgetting them:

    forget hello

Because we defined two `hello` words, we should forget `hello` twice to delete
the new and the old `hello`.  Forgetting means that everything after the
specified word is deleted from the dictionary, including our `greetings` and
`hellos` definitions.

To create a configurable `hello` word that displays alternative messages, we
can use branching based on the value of a variable:

    VARIABLE spanish ↲
    : hello ↲
      spanish @ IF ↲
        ." Hola, Mundo!" ↲
      ELSE ↲
        ." Hello, World!" ↲
      THEN CR ; ↲

For newcomers to Forth this may look strange with the `IF` and `THEN` out of
place.  A `THEN` closes the `IF` (some Forth's allow both `ENDIF` and `THEN`).
By comparison to C, `spanish @ IF x ELSE y` is similar to `*spanish ? x : y`.
The variable `spanish` places the address of its value on the stack.  The value
is fetched (dereferenced) with the word `@`.  If the value is nonzero (true),
then the statements after `IF` are executed.  Otherwise, the statements after
`ELSE` are executed.

To set the `spanish` variable to true:

    TRUE spanish ! ↲

where the store word `!` saves the 2OS value to the memory cell indicated by
the TOS address.  Observe this stack order carefully!  Otherwise you will end
up writing data to arbitrary memory locations.  The `!` reminds you of this
potential danger.

For convenience, the words `ON` and `OFF` can be used:

    spanish OFF ↲
    spanish ? ↲
    0 OK[0]
    spanish ON ↲
    spanish ? ↲
    -1 OK[0]

The `?` word is a shorthand for `@ .` to display the value of a variable:

    : ? @ . ;

Like the built-in `?` word, a large portion of the Forth system is defined in
Forth itself.

Instead of nesting multiple `IF-ELSE-THEN` branches to cover additional
languages, we should use `CASE-OF-ENDOF-ENDCASE` and enumerate the languages
as follows:

    0 CONSTANT #english ↲
    1 CONSTANT #spanish ↲
    2 CONSTANT #french ↲
    VARIABLE language #english language ! ↲
    : hello ↲
      language @ CASE ↲
        #english OF ." Hello, World!" ENDOF ↲
        #spanish OF ." Hola, Mundo!" ENDOF ↲
        #french OF ." Salut Mondial!" ENDOF ↲
        ." Unknown language" ↲
      ENDCASE ↲
      CR ; ↲
    hello ↲
    Hello, World!

Note that a default case is not really necessary, but can be inserted between
the last `ENDOF` and `ENDCASE`.  In the default branch the `CASE` value is the
TOS, which can be inspected, but should not be dropped before `ENDCASE`.

Constant words push their value on the stack, wheras variable words push the
address of their value on the stack to be fetched with `@` and new values are
stored with `!`.

So-called Forth values offer the advantage of implicit fetch like constants.
Let's replace the `VARIABLE language` with a `VALUE` initialized to `#english`:

    #english VALUE language ↲

To change the value we use the `TO` word followed by the name of the value:

    #spanish TO language ↲

Now with `language` as a `VALUE`, `hello` should be changed by removing the
`@` after `language`:

    : hello ↲
      language CASE ↲
      ...

Earlier we saw the `DO-LOOP`.  The loop iterates until its internal loop
counter when incremented *equals* the final value.  For example, this loop
executes `hello` 10 times:

    : greetings 10 0 DO hello LOOP ; ↲

Actually, `DO` cannot be recommended because the loop body is always executed
at least once, for example when the initial value is the same as the final
value we end up executing the loop 65536 times! (Because integers wrap around.)
We use `?DO` instead of `DO` to avoid this problem:

    : hellos 0 ?DO hello LOOP ; ↲
    0 hellos ↲
    OK[0]

This example has zero loop iterations and never executes the loop body `hello`.
To change the step size or direction of the loop, use `+LOOP`.  The word `I`
returns the counter value:

    : evens 10 0 ?DO I . 2 +LOOP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

Again, be warned that the loop terminates when the counter *equals* the final
value, not exceeds it.  Therefore, using the wrong loop `9 0 ?DO I . 2 +LOOP`
would never terminate.

A `BEGIN-WHILE-REPEAT` is a logically-controlled loop with which we can do the
same as follows by pushing a `0` to use as a counter on top of the stack:

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

A `BEGIN-UNTIL` loop is similar, but executes the loop body at least once:

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

    : >= < INVERT ; ↲

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

This ends our tutorial introduction to the essential basics of Forth.

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
| _addr_   | a 16-bit address
| _c-addr_ | a 16-bit address pointing to 8-bit character(s)
| _f-addr_ | a 16-bit address pointing to a file status structure (Forth500)
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

This word moves _x_ from the stack to the so-called "return stack".  The return
stack is used to keep return addresses of words executed and to store temporary
values.  It is important to keep the return stack balanced.  This prevents
words from returning to an incorrect return address and crashing the system.

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

Note that `NIP` is the same as `SWAP DROP` and `TUCK` is the same as `DUP -ROT`.

There are also two words to reach deeper into the stack:

| word   | stack effect ( _before_ -- _after_ )       | comment
| ------ | ------------------------------------------ | ------------------------
| `PICK` | ( _xk_ ... _x0_ k -- _xk_ ... _x0_ _xk_ )  | duplicate k'th value down to the top
| `ROLL` | ( _xk_ ... _x0_ k -- _xk-1_ ... _x0_ _xk_) | rotate the k'th value down to the top

Note that `0 PICK` is the same as `DUP`, `1 PICK` is the same as `OVER`, `1
ROLL` is the same as `SWAP`, `2 ROLL` is the same as `ROT` and `0 ROLL` does
nothing.

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

Other stack-related words:

| word    | stack effect | comment
| ------- | ------------ | -----------------------------------------------------
| `CLEAR` | ( ... -- )   | clears the stack
| `DEPTH` | ( -- _n_ )   | returns the current depth of the stack
| `.S`    | ( -- )       | displays the stack contents
| `N.S`   | ( _n_ -- )   | displays the top _n_ values on the stack

`DEPTH` returns the depth of the stack before pushing the depth value.  The
maximum stack depth in Forth500 is 200 cells or 100 double cells.

## Integer constants

Integer values when parsed from the input are directly pushed on the stack.
The current `BASE` is used for conversion:

| word        | comment
| ----------- | ----------------------------------------------------------------
| `BASE`      | a `VARIABLE` holding the current base
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

Note that the signedness of an integer only applies to the way the integer
value is used by a word.  For example, `-1 U.` displays 65535, because `U.`
takes an unsigned integer to display and -1 is the same as 65535 (two's
complement).

Double integer values have a `.` (dot) anywhere placed among the digits.  For
example, `-1.` is double integer pushed on the stack, occupying the top pair of
consecutive cells on the stack, i.e. the TOS and 2OS with TOS holding the
high-order bits.  The `.` (dot) is typically placed at the end of the digits.

The following words define common constants regardless of the current `BASE`:

| word    | comment
| ------- | --------------------------------------------------------------------
| `BL`    | the space character, ASCII 32
| `FALSE` | Boolean false, same as 0
| `TRUE`  | Boolean true, same as -1

## Arithmetic

The following words cover integer arithmetic operations.  Words involving
division and modulo may throw exception -10 "Division by zero":

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
| `UMAX`   | ( _u1_ _u2_ -- _u1_ ) if _u1_U>_u2_ otherwise ( _u1_ _u2_ -- _u2_ )
| `MIN`    | ( _n1_ _n2_ -- _n1_ ) if _n1_<_n2_ otherwise ( _n1_ _n2_ -- _n2_ )
| `UMIN`   | ( _u1_ _u2_ -- _u1_ ) if _u1_U<_u2_ otherwise ( _u1_ _u2_ -- _u2_ )
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

Integer overflow and underflow throws no exceptions.  In case of integer
addition and subtraction, values wrap around.  For all other integer
operations, overflow and underflow produce unreliable values.

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

The _after_ stack effects include the operations % (mod), & (bitwise and), |
(bitwise or), ^ (bitwise xor), ~ (bitwise not/invert), << (bitshift left)
and >> (bitshift right).  The `U<` and `U>` comparisons are unsigned, see
[numeric comparisons](#numeric-comparisons).

## Double arithmetic

The following words cover double integer arithmetic operations.  Words
involving division and modulo may throw exception -10 "Division by zero":

| word      | stack effect ( _before_ -- _after_ )
| --------- | ------------------------------------------------------------------
| `D+`      | ( _d1_ _d2_ -- (_d1_+_d2_) )
| `D-`      | ( _d1_ _d2_ -- (_d1_-_d2_) )
| `D*`      | ( _d1_ _d2_ -- (_d1_\*_d2_) )
| `D/`      | ( _d1_ _d2_ -- (_d1_/_d2_) )
| `DMOD`    | ( _d1_ _d2_ -- (_d1_%_d2_) )
| `D/MOD`   | ( _d1_ _d2_ -- (_d1_%_d2_) (_d1_/_d2_) )
| `DMAX`    | ( _d1_ _d2_ -- _d1_ ) if _d1_D>_d2_ otherwise ( _d1_ _d2_ -- _d2_ )
| `DMIN`    | ( _d1_ _d2_ -- _d1_ ) if _d1_D<_d2_ otherwise ( _d1_ _d2_ -- _d2_ )
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

## Mixed arithmetic

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
| `FM/MOD` | ( _d_ _n_ -- (_d_%_n_) (_d_/_n_) )       | floored single remainder and quotient of signed double and single division
| `SM/REM` | ( _d_ _n_ -- (_d_%_n_) (_d_/_n_) )       | symmetric single remainder and quotient of signed double and single division

The `UM/MOD`, `FM/MOD`, and `SM/REM` words return a remainder on the stack.  In
all cases, the quotient _q_ and remainder _r_ satisfy _a_ = _b_ \* _q_ + _r_,

In case of `FM/MOD`, the quotient is a single signed integer truncated
towards negative _q_ = _trunc_(_a_ / _b_).  For example, `-10. 7 FM/MOD`
returns remainder 4 and quotient -2.

In case of `SM/REM`, the quotient is a single signed integer floored
towards zero (hence symmetric) _q_ = _floor_(_a_ / _b_). For example,
`-10. 7 SM/REM` returns remainder -3 and quotient -1.

## Fixed point arithmetic

Fixed point offers an alternative to floating point if the exponential range of
values manipulated can be fixed to a few digits after the decimal point.

A classic example is pi to compute the circumference of a circle using a
rational approximation of pi and a fixed point radius with a 2 digit fraction:

    : pi* 355 113 M*/ ; ↲
    12.00 2VALUE radius ↲
    radius 2. D* pi* D. ↲

Note that the placement of `.` in `12.00` has no meaning at all, it is just
suggestive of a decimal value with a 2 digit fraction.

Multiplying the fixed point value `radius` by the double integer `2.` does not
require scaling of the result.  Addition and subtraction with `D+` and `D-`
does not require scaling either.  However, multiplying and dividing two fixed
point numbers requires scaling the result, for example with a new word:

    : *.00 D* 100 SM/REM 2NIP ; ↲
    radius radius *.00 pi* D. ↲

There is a slight risk of overflowing the intermediate product when the
multiplicants are large.  If this is a potential hazard then note that this can
be avoided by scaling the multiplicants instead of the result:

    : 10/ 10 SM/REM 2NIP ; ↲
    : *.00 10/ 2SWAP 10/ D* ; ↲

Likewise, fixed point division requires scaling.  One way to do this is
by scaling the divisor down by 10 and the dividend up by 10 before dividing:

    : /.00 10/ 2SWAP 10. D* 2SWAP D/ ;

## Floating point arithmetic

Not implemented yet.  I am looking for information on the location of the
floating point routines in PC-E500(S), which was once available online and
documented, but I cannot find it.

## Numeric comparisons

The following words return true (-1) or false (0) on the stack by comparing
integer values.

| word     | stack effect ( _before_ -- _after_ )
| -------- | -------------------------------------------------------------------
| `<`      | ( _n1_ _n2_ -- true ) if _n1_<_n2_ otherwise ( _n1_ _n2_ -- false )
| `=`      | ( _x1_ _x2_ -- true ) if _x1_=_x2_ otherwise ( _x1_ _x2_ -- false )
| `>`      | ( _n1_ _n2_ -- true ) if _n1_>_n2_ otherwise ( _n1_ _n2_ -- false )
| `<>`     | ( _x1_ _x2_ -- true ) if _x1_≠_x2_ otherwise ( _n1_ _n2_ -- false )
| `U<`     | ( _u1_ _u2_ -- true ) if _u1_<_u2_ otherwise ( _u1_ _u2_ -- false )
| `U>`     | ( _u1_ _u2_ -- true ) if _u1_>_u2_ otherwise ( _u1_ _u2_ -- false )
| `D<`     | ( _d1_ _d2_ -- true ) if _d1_<_d2_ otherwise ( _n1_ _n2_ -- false )
| `D=`     | ( _d1_ _d2_ -- true ) if _d1_=_d2_ otherwise ( _n1_ _n2_ -- false )
| `D>`     | ( _d1_ _d2_ -- true ) if _d1_>_d2_ otherwise ( _n1_ _n2_ -- false )
| `D<>`    | ( _d1_ _d2_ -- true ) if _d1_≠_d2_ otherwise ( _n1_ _n2_ -- false )
| `DU<`    | ( _ud1_ _ud2_ -- true ) if _ud1_<_ud2_ otherwise ( _ud1_ _ud2_ -- false )
| `DU>`    | ( _ud1_ _ud2_ -- true ) if _ud1_>_ud2_ otherwise ( _ud1_ _ud2_ -- false )
| `0<`     | ( _n_ -- true ) if _n_<0 otherwise ( _n_ -- false )
| `0=`     | ( _n_ -- true ) if _n_=0 otherwise ( _n_ -- false )
| `0>`     | ( _n_ -- true ) if _n_>0 otherwise ( _n_ -- false )
| `0<>`    | ( _n_ -- true ) if _n_≠0 otherwise ( _n_ -- false )
| `D0<`    | ( _d_ -- true ) if _d_<0 otherwise ( _d_ -- false )
| `D0=`    | ( _d_ -- true ) if _d_=0 otherwise ( _d_ -- false )
| `D0>`    | ( _d_ -- true ) if _d_>0 otherwise ( _d_ -- false )
| `D0<>`   | ( _d_ -- true ) if _d_≠0 otherwise ( _d_ -- false )
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

More precisely, `WITHIN` performs a comparison of a test value _n1_|_u1_ with an
inclusive lower limit _n2_|_u2_ and an exclusive upper limit _n3_|_u3_,
returning true if either (_n2_|_u2_ < _n3_|_u3_ and (_n2_|_u2_ <= _n1_|_u1_ and
_n1_|_u1_ < _n3_|_u3_)) or (_n2_|_u2_ > _n3_|_u3_ and (_n2_|_u2_ <= _n1_|_u1_
or _n1_|_u1_ < _n3_|_u3_)) is true, returning false otherwise.

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

See also [pictured numeric output](#pictured-numeric-output).

## Pictured numeric output

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

    : dollars <# # # S" ." HOLDS #S S" $" HOLDS #> TYPE SPACE ; ↲
    1.23 dollars ↲
    $1.23  OK[0]

Note the reverse order in which the numeric output is composed.  In the example
the value `1.23` appears to have a fraction as syntactic sugar, but the
placement of the `.` in a double integer has no significance.

To display signed double integers, it is necessary to tuck the high order cell
with the sign under the double number, then make the number positive and
convert using `SIGN` at the end to get the sign a front:

    : dollars TUCK DABS <# # # [CHAR] . HOLD #S [CHAR] $ HOLD DROP OVER SIGN #> TYPE SPACE ; ↲
    -1.23 dollars ↲
    -$1.23  OK[0]

Note that `HOLD` is used to add one character to the hold area.

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
| `.( ...)`  | ( -- )              | displays the string immediately, even when compiling

All strings contain 8-bit characters, including special characters.

The string constants created with `S"` and `S\"` are compiled to code when used
in colon definitions.  Otherwise, the string is stored in a temporary internal
256-byte string buffer returned by `WHICH-POCKET` (two buffers are recycled).

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
| `\t`   | 9        | HT; horizintal tab
| `\v`   | 11       | VT; vertical tab
| `\xhh` | hh (hex) |
| `\z`   | 0        | NUL

## String operations

The following words allocate and accept user input into a string buffer:

| word      | stack effect ( _before_ -- _after_ )                | comment
| --------- | --------------------------------------------------- | ------------
| `PAD`     | ( -- _c-addr_ )                                     | returns the fixed address of a 256 byte temporary buffer that is not used by any built-in Forth words
| `BUFFER:` | ( _u_ "name" -- ; _c-addr_ )                        | creates an uninitialized string buffer of size _u_
| `ACCEPT`  | ( _c-addr_ _+n1_ -- _+n2_ )                         | accepts user input into the buffer _c-addr_ of max size _+n1_ and returns string size _+n2_
| `EDIT`    | ( _c-addr_ _+n1_ _n2_ _n3_ _n4_ -- _c-addr_ _+n5_ ) | edit string buffer _c-addr_ of max size _+n1_ containing a string of length _n2_, placing the cursor at _n3_ and limiting cursor movement to _n4_ and after, returns string _c-addr_ with updated size _+n5_

Note that `BUFFER:` only reserves space for the string but does not store the
max size and the length of the actual string contained.  To do so, use a
`CONSTANT` and a `VARIABLE`:

    40 CONSTANT max-name ↲
    max-name BUFFER: name ↲
    VARIABLE name-len ↲
    name max-name ACCEPT name-len ! ↲

To let the user edit the name:

    name max-name name-len @ DUP 0 EDIT DROP name-len ! ↲

The following words move and copy characters in and between string buffers:

| word     | stack effect                   | comment
| -------- | ------------------------------ | ----------------------------------
| `CMOVE`  | ( _c-addr1_ _c-addr2_ _u_ -- ) | copy _u_ characters from _c-addr1_ to _c-addr2_, from lower addresses to higher addresses
| `CMOVE>` | ( _c-addr1_ _c-addr2_ _u_ -- ) | copy _u_ characters from _c-addr1_ to _c-addr2_, from higher addresses to lower addresses
| `MOVE`   | ( _c-addr1_ _c-addr2_ _u_ -- ) | copy _u_ characters from _c-addr1_ to _c-addr2_
| `C!`     | ( _char_ _c-addr_ -- )         | store _char_ in _c-addr_
| `C@`     | ( _c-addr_ -- _char_ )         | fetch _char_ from _c-addr_

A problem may arise when the source and target address ranges overlap, for
example when moving string contents in place.  In this case, `CMOVE` correctly
copies characters when _c-addr1_>_c-addr2_ and `CMOVE>` correctly copies
characters when _c-addr1_<_c-addr2_.  The `MOVE` word always correctly copies
characters.

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

For example, to remove trailing spaces from `name` to update `name-len`, then
display the name without the `name=` prefix:

    name name-len @ -TRAILING name-len ! ↲
    name name-len @ 5 /STRING TYPE ↲

Note that `/STRING` does not perform any checking on the length of the string
and the size of the adjustment _n_.

The following words compare and search two strings:

| word      | stack effect ( _before_ -- _after_ )                       | comment
| --------- | ---------------------------------------------------------- | -----
| `S=`      | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- flag )                  | returns `TRUE` if the two strings are equal
| `COMPARE` | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- -1\|0\|1 )              | returns -1\|0\|1 (less, equal, greater) comparison of the two strings
| `SEARCH`  | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- _c-addr3_ _u3_ _flag_ ) | returns `TRUE` if the second string was found in the first string at _c-addr3_ with _u3_=_u2_, otherwise `FALSE` and _c-addr3_=_c-addr1_, _u3_=_u1_

To convert a string to a number:

| word      | stack effect ( _before_ -- _after_ )             | comment
| --------- | ------------------------------------------------ | ---------------
| `>NUMBER` | ( _ud1_ _c-addr1_ _u1_ -- _ud2_ _c-addr2_ _u2_ ) | convert the number in string _c-addr1_ _u1_ to _ud2_ using the current `BASE`, returns the remaining non-convertable string _c-addr2_ _u2_

The initial _ud1_ value is the "seed" that is normally zero.  This value can
also be a previously converted high-order component of the number.

## Keyboard input

The following words return key presses and control the key buffer:

| word          | stack effect             | comment
| ------------- | ------------------------ | -----------------------------------
| `EKEY?`       | ( -- _flag_ )            | if a keyboard event is available, return `TRUE`, otherwise return `FALSE`
| `EKEY`        | ( -- _x_ )               | display the cursor, wait for a keyboard event, return the event _x_
| `EKEY>CHAR`   | ( _x_ -- _char_ _flag_ ) | convert keyboard event _x_ to a valid character and return `TRUE`, otherwise return `FALSE`
| `KEY?`        | ( -- _flag_ )            | if a character is available, return `TRUE`, otherwise return `FALSE`
| `KEY`         | ( -- _char_ )            | display the cursor, wait for a character and return it
| `INKEY`       | ( -- _char_ )            | check for a key press returning the key as _char_, clears the key buffer
| `KEY-CLEAR`   | ( -- )                   | empty the key buffer
| `>KEY-BUFFER` | ( _c-addr_ _u_ -- )      | fill the key buffer with the string of characters at address _c-addr_ size _u_

## Character output

The following words display characters and text on the screen:

| word           | stack effect        | comment
| -------------- | ------------------- | ---------------------------------------
| `EMIT`         | ( _char_ -- )       | display character _char_
| `TYPE`         | ( _c-addr_ _u_ -- ) | display string _c-addr_ of size _u_
| `REVERSE-TYPE` | ( _c-addr_ _u_ -- ) | same as `TYPE` with reversed video
| `DUMP`         | ( _addr_ _u_ -- )   | dump _u_ bytes at address _addr_ in hexadecimal
| `CR`           | ( -- )              | moves the cursor to a new line
| `SPACE`        | ( -- )              | displays a single space
| `SPACES`       | ( _n_ -- )          | displays _n_ spaces

## Screen and cursor operations

The following words control the screen and cursor position:

| word         | stack effect                  | comment
| ------------ | ----------------------------- | -------------------------------
| `AT-XY`      | ( _n1_ _n2_ -- )              | set cursor at column _n1_ and row _n2_ position
| `AT-TYPE`    | ( _n1_ _n2_ _c-addr_ _u_ -- ) | display the string _c-addr_ _u_at column _n1_ and row _n2_
| `AT-CLR`     | ( _n1_ _n2_ _n3_ -- )         | clear _n3_ characters at column _n1_ and row _n2_
| `CR`         | ( -- )                        | move cursor to a new line
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
the cursor on with `$8` to blink the cursor and one of the following five
possible cursor shapes:

| value | cursor shape
| ----- | ------------
| `$00` | underline
| `$01` | double underline
| `$02` | solid box
| `$03` | space (to display a cursor "box" on reverse video text)
| `$04` | triangle

## Graphics

The graphics mode is set with `GMODE`.  All graphics drawing commands use this
mode to set, reset or reverse pixels:

| word      | stack effect                   | comment
| --------- | ------------------------------ | ---------------------------------
| `GMODE`   | ( 0\|1\|2 -- )                 | pixels are set (0), reset (1) or reversed (2)
| `GPOINT`  | ( _n1_ _n2_ -- )               | draw a pixel at x=_n1_ and y=_n2_
| `GPOINT?` | ( _n1_ _n2_ -- _flag_ )        | returns `TRUE` if a pixel is set at x=_n1_ and y=_n2_
| `GLINE`   | ( _n1_ _n2_ _n3_ _n4_ _u_ -- ) | draw a line from x=_n1_ and y=_n2_ to x=_n3_ and y=_n4_ with pattern _u_
| `GBOX`    | ( _n1_ _n2_ _n3_ _n4_ _u_ -- ) | draw a filled box from x=_n1_ and y=_n2_ to x=_n3_ and y=_n4_ with pattern _u_
| `GDOTS`   | ( _n1_ _n2_ _u_ -- )           | draw a row of 8 pixels _u_ at x=_n1_ and y=_n2_
| `GDOTS?`  | ( _n1_ _n2_ -- _u_ )           | returns the row of 8 pixels _u_ at x=_n1_ and y=_n2_
| `GDRAW`   | ( _n1_ _n2_ _c-addr_ _u_ -- )  | draw rows of 8 pixels stored in string _c-addr_ _u_ at x=_n1_ and y=_n2_
| `GBLIT!`  | ( _u_ _addr_ -- )              | copy 240 bytes of screen data from row _u_ (0 to 3) to address _addr_
| `GBLIT@`  | ( _u_ _addr_ -- )              | copy 240 bytes of screen data at address _addr_ to row _u_ (0 to 3)

A pattern _u_ is a 16-bit pixel pattern to draw dashes lines and boxes.  The
pattern should be $ffff (-1 or `TRUE`) for solid lines and boxes.  For example,
to reverse the current screen:

    2 GMODE ↲
    0 0 239 31 TRUE GBOX ↲

The `GDOTS` word takes an 8-bit pattern to draw a row of 8 pixels.  The `GDRAW`
word draws a sequence of 8-bit patterns.  For example, to display a smiley at
the upper left corner of the screen:

    : smiley S\" \xc3\x24\x19\x5a\x1a\x1a\x5a\x19\x24\xc3" GDRAW ; ↲
    0 GMODE ↲
    0 0 smiley ↲

      XXXXXX
     X      X
    X  X  X  X
    X        X
    X X    X X
    X  XXXX  X
     X      X
      XXXXXX

Blitting moves screen data between buffers to update or restore the screen
content.  The `GBLIT!` word stores a row of screen data in a buffer and
`GPLIT@` fetches a row of screen data to restore the screen.  Each operation
moves 240 bytes of screen data for one of the four rows of 40 characters.  For
example, to save and restore the top row in the 256 byte `PAD`:

    : save-top-row 0 PAD GBLIT! ; ↲
    : restore-top-row 0 PAD GBLIT@ ; ↲

To blit the whole screen, a buffer of 4 times 240 bytes is required:

    4 240 * BUFFER: blit ↲
    : save-screen 4 0 DO I DUP 240 * blit + GBLIT! LOOP ; ↲
    : restore-screen 4 0 DO I DUP 240 * blit + GBLIT@ LOOP ; ↲

## Sound

The `BEEP` word emits sound with the specified duration and tone:

| word   | stack effect     | comment
| ------ | ---------------- | --------------------------------------------------
| `BEEP` | ( _u1_ _u2_ -- ) | beeps with tone _u1_ for _u2_ milliseconds

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
| `R@`     | ( -- _x_ ; R: _x_ -- _x_ )                        | copy the return stack TOS to the stack
| `2R@`    | ( -- _xd_ ; R: _xd_ -- _xd_ )                     | copy the return stack double TOS to the stack
| `R'@`    | ( -- _x2_ ; R: _x1_ _x2_ -- _x1_ _x2_ )           | copy the return stack 2OS to the stack
| `R"@`    | ( -- _x3_ ; R: _x1_ _x2_ _x3_ -- _x1_ _x2_ _x3_ ) | copy the return stack 3OS to the stack
| `R>`     | ( R: _x_ -- ; -- _x_ )                            | move the TOS from the return stack to the stack
| `R>DROP` | ( R: _x_ -- ; -- )                                | drop the return stack TOS
| `2R>`    | ( R: _xd_ -- ; -- _xd_ )                          | move the double TOS from the return stack to the stack
| `N>R`    | ( _n_\*_x_ _+n_ -- ; R: -- _n_\*_x_ _+n_ )        | move _n_ cells to the return stack
| `NR>`    | ( -- _n_\*_x_ _+n_ ; R: _n_\*_x_ _+n_ -- )        | move _n_ cells from the return stack

The `N>R` and `NR>` words move _+n_+1 cells, including the cell _+n_.  For
example `2 N>R ... NR> DROP` moves 2+1 cells to the return stack and back,
then dropping the restored 2.  Effectively the same as executing `2>R ... 2R>`.

Care must be taken to prevent return stack imbalences when a colon definition
exits.  The return stack must be restored to the previous state when the colon
definition started before the colon definition exits.

The maximum depth of the return stack in Forth500 is 200 cells or 100 double
cells.

## Defining new words

### Constants, variables and values

The following words define constants, variables and values:

| word        | stack effect                   | comment
| ----------- | ------------------------------ | -------------------------------
| `CONSTANT`  | ( _x_ "name" -- ; -- _x_ )     | define "name" to return _x_ on the stack
| `2CONSTANT` | ( _dx_ "name" -- ; -- _dx_ )   | define "name" to return _dx_ on the stack
| `VARIABLE`  | ( "name" -- ; -- _addr_ )      | define "name" to return _addr_ of the variable's cell on the stack
| `!`         | ( _x_ _addr_ -- )              | store _x_ at _addr_ of a `VARIABLE`
| `+!`        | ( _n_ _addr_ -- )              | add _n_ to the value at _addr_ of a `VARIABLE`
| `@`         | ( _addr_ -- _x_ )              | fetch the value _x_ from _addr_ of a `VARIABLE`
| `?`         | ( _addr_ -- )                  | fetch the value _x_ from _addr_ of a `VARIABLE` and display it with `.`
| `ON`        | ( _addr_ -- )                  | store `TRUE` (-1) at _addr_ of a `VARIABLE`
| `OFF`       | ( _addr_ -- )                  | store `FALSE` (0) at _addr_ of a `VARIABLE`
| `2VARIABLE` | ( "name" -- ; -- _addr_ )      | define "name" to return _addr_ of the variable's double cell on the stack
| `2!`        | ( _dx_ _addr_ -- )             | store _dx_ at _addr_ of a `2VARIABLE`
| `D+!`       | ( _d_ _addr_ -- )              | add _d_ to the value at _addr_ of a `2VARIABLE`
| `2@`        | ( _addr_ -- _dx_ )             | fetch the value _dx_ from  _addr_ of a `2VARIABLE`
| `VALUE`     | ( _x1_ "name" -- ; -- _x2_ )   | define "name" with initial value _x1_ to return its current value _x2_ on the stack
| `TO`        | ( _x_ "name" -- )              | assign "name" the value _x_, if "name" is a `VALUE`
| `+TO`       | ( _n_ "name" -- )              | add _n_ to the value of "name", if "name" is a `VALUE`
| `2VALUE`    | ( _dx1_ "name" -- ; -- _dx2_ ) | define "name" with initial value _dx1_ to return its current value _dx2_ on the stack
| `TO`        | ( _dx_ "name" -- )             | assign "name" the value _x_, if "name" is a `2VALUE`
| `+TO`       | ( _d_ "name" -- )              | add _d_ to the value of "name", if "name" is a `2VALUE`

Values are initialized with the specified initial values and do not require
fetch operations, exactly like constants.  By contrast to constants, values can
be updated with `TO` and `+TO`.  Note that the `TO` and `+TO` words are used
to assign and update `VALUE` and `2VALUE` words.

### Deferred words

A deferred word executes another word assigned to it, essentially a variable
that contains the execution token of another word to execute indirectly:

| word        | stack effect        | comment
| ----------- | ------------------- | ------------------------------------------
| `DEFER`     | ( "name" -- )       | defines a deferred word that is initially uninitialized
| `'`         | ( "name" -- _xt_ )  | (tick) return the execution token of a name
| `IS`        | ( _xt_ "name" -- )  | assign "name" the execution token _xt_ of another word
| `ACTION-OF` | ( "name" -- _xt_ )  | fetch the execution token _xt_ assigned to "name"
| `DEFER!`    | ( _xt1_ _xt2_ -- )  | assign _xt1_ to deferred word execution token _xt2_
| `DEFER@`    | ( _xt1_ -- _xt2_ )  | fetch _xt2_ from deferred word execution token _xt1_
| `NOOP`      | ( -- )              | does nothing
| `EXECUTE`   | ( ... _xt_ -- ... ) | executes execution token _xt_

A deferred word is defined with `DEFER` and assigned with `IS`:

    DEFER greeting ↲
    : hi ." hi" ; ↲
    ' hi IS greeting ↲
    greeting ↲
    hi OK[0]
    ' NOOP IS greeting ↲
    greeting ↲
    OK [0]
    :NOMAME ." hello" ; IS greeting ↲
    greeting ↲
    hello OK [0]

The tick `'` word parses the name of a word in the dictionary and returns its
execution token on the stack.  An execution token points to executable code in
the dictionary located directly after the name of a word.  The `EXECUTE` word
executes code pointed to by an execution token.  Therefore, `' some-word
EXECUTE` is the same as executing `some-word`.

To assign one deferred word to another we use `ACTION-OF`, for example:

    DEFER foo ↲
    ' TRUE IS foo ↲
    DEFER bar ↲
    ACTION-OF foo IS bar ↲

The result is that `bar` is assigned `TRUE` to execute.  By contrast, `' foo IS
bar` assigns `foo` to `bar` so that `bar` executes `foo` and `foo` executes
`TRUE`.  Changing `foo` would also change `bar`.

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
    OK [0]

### Recursion

A recursive colon definition cannot use its name, which is hidden until the
final `;` is parsed.  This is done to avoid the possible use of incomplete
colon definitions that can crash the system when executed.  A recursive colon
definition should use `RECURSE` to call itself:

    : factorial ( _u_ -- _ud_ )
      ?DUP IF DUP 1- RECURSE ROT UMD* ELSE 1. THEN ;

Mutual recursion can be accomplished with [deferred words](#deferred-words):

    DEFER foo ↲
    : bar ... foo ... ; ↲
    :NONAME ... bar ... ; IS foo ↲

`:NONAME` returns the execution token of an unnamed colon definition,
see also [noname definitions](#noname-definitions).

### Immediate words

An immediate word is always interpreted and executed, even within colon
definitions.  A colon definition word can be declared `IMMEDIATE` after
ther terminating `;`.  For example, this is the colon definition of `RECURSE`
to compile the execution token of the most recent colon definition (i.e.
the word we are defining) into the compiled code:

    : RECURSE
      ?COMP     \ error if we are not compiling
      LAST-XT @ \ the execution token of the word being defined
      COMPILE,  \ compile it into code
    ; IMMEDIATE

### CREATE and DOES>

Data can be stored in the dictionary as words with `CREATE`.  Like a colon
definition, the name of a word is parsed and added to the dictionary.  This
word does nothing else but just return the address of the body of data stored
in the dictionary.  To allocate and populate the data the following words can
be used:

| word     | stack effect              | comment
| -------- | ------------------------- | ---------------------------------------
| `CREATE` | ( "name" -- ; -- _addr_ ) | adds a new word entry for "name" to the dictionary, this word returns _addr_
| `HERE`   | ( -- _addr_ )             | the next free address in the dictionary
| `CELL`   | ( -- 2 )                  | the size of a cell (single integer)
| `CELLS`  | ( _u_ -- 2\*_u_ )         | convert _u_ from cells to bytes
| `CELL+`  | ( _addr_ -- _addr_+2 )    | increments _addr_ by a cell width (by two)
| `CHARS`  | ( _u_ -- _u_ )            | convert _u_ from characters to bytes (does nothing)
| `CHAR+`  | ( _addr_ -- _addr_+1 )    | increments _addr_ by a character width (by one)
| `ALLOT`  | ( _u_ -- )                | reserves _u_ bytes in the dictionary starting `HERE`, just adds _u_ to `HERE`
| `UNUSED` | ( -- _u_ )                | returns the number of unused bytes remaining in the dictionary
| `,`      | ( _x_ -- )                | stores _x_ at `HERE` then increments `HERE` by `CELL` (by two)
| `2,`     | ( _dx_ -- )               | stores _dx_ at `HERE` then increments `HERE` by `2 CELLS` (by four)
| `C,`     | ( _char_ -- )             | stores _char_ at `HERE` then increments `HERE` by `1 CHARS` (by one)
| `DOES>`  | ( -- ; -- _addr_ )        | the following code will be compiled and executed by the word we `CREATE`
| `@`      | ( _addr_ -- _x_)          | fetches _x_ stored at _addr_
| `2@`     | ( _addr_ -- _dx_ )        | fetches _dx_ stored at _addr_
| `C@`     | ( _addr_ -- _char_ )      | fetches _char_ stored at _addr_

Allocation is limited by the remaining free space in the dictionary returned by
the `UNUSED` word.

The `CREATE` word adds an entry to the dictionary, typically followed by words
to allocate and store data assocated with the new word.  For example, we can
create a word `foo` with a cell to hold a value that is initially zero:

    CREATE foo 0 , ↲
    3 foo ! ↲
    foo ? ↲
    3 OK[0]

In fact, this is exactly how a `VARIABLE` is defined in Forth:

    : VARIABLE CREATE 0 , ; ↲

We can use `CREATE` with "comma" words such as `,` to store values.  For
example, a table of 10 primes:

    CREATE primes 2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 31 , ↲

The `primes` table values are accessed with address arithmetic as follows:

    : show-primes 10 0 DO primes I CELLS + ? LOOP ; ↲

where `primes` returns the starting address of the table and `primes I CELLS +`
computes the address of the cell that holds the `I`'th prime value.

Uninitialized space is allocated with `ALLOT`.  For example, a buffer:

    CREATE buf 256 ALLOT ↲

This creates a buffer `buf` of 256 bytes.  The `buf` word returns the starting
address of this buffer.  In fact, the built-in `BUFFER:` word is defined as:

    : BUFFER: CREATE ALLOT ; ↲

so that `buf` can also be created with:

    256 BUFFER: buf ↲

The `DOES>` word compiles code until a terminating `;`.  This code is executed
by the word we `CREATE`.  For example, we can create a `bar` word that stores a
value and fetch it automatically whenever `bar` is executed:

    CREATE bar 7 , DOES> @ ; ↲
    bar . ↲
    7 OK[0]

Executing `bar` first returns the address of its body then executes `@` to
fetch the value before returning.

In fact, this is exactly how a `CONSTANT` is defined in Forth:

    : CONSTANT CREATE , DOES> @ ; ↲

so that `bar` can also be created with:

    7 CONSTANT bar ↲

Address arithmetic can be added with `DOES>` to automatically fetch a prime
number from the `primes` table:

    CREATE primes 2 , 3 , 5 , 7 , 11 , 13 , 17 , 19 , 23 , 31 , ↲
    DOES> SWAP CELLS + @ ; ↲
    3 primes . ↲
    7 OK[0]

The `SWAP CELLS + @` doubles 3 to 6 then adds the address of the `primes` table
to get to the address to fetch the value.

Note that `>BODY` (see [introspection](#introspection)) of an execution token
returns the same address as `CREATE` returns and that `DOES>` pushes on the
stack.  For example, `' buf >BODY` and `buf` return the same address.

#### Structures

The following words define a structure and its fields:

| word              | stack effect ( _before_ -- _after_ )         | comment
| ----------------- | -------------------------------------------- | -----------
| `BEGIN-STRUCTURE` | ( "name" -- _addr_ 0 ; -- _u_ )              | define a structure type
| `+FIELD:`         | ( _u_ _n_ "name" -- _u_ ; _addr_ -- _addr_ ) | define a field name with the specified size
| `FIELD:`          | ( _u_ "name" -- n ; addr -- addr )           | define a single cell field
| `CFIELD:`         | ( _u_ "name" -- n ; addr -- addr )           | define a character field
| `2FIELD:`         | ( _u_ "name" -- n ; addr -- addr )           | define a double cell field
| `END-STRUCTURE`   | ( _addr_ _u_ -- )                            | end of structure type

The `FIELD:` word is the same as `CELL +FIELD`, `CFIELD:` is the same as `1
CHARS +FIELD` and `2FIELD` is the same as `2 CELLS +FIELD`.

For example:

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
to automatically index an array is done by creating a `BUFFER:` with a `DOES>`
operation to return the address of a cell given the array and array index on
the stack:

    : cell-array: CELLS BUFFER: DOES> SWAP CELLS + ; ↲

where `CELLS BUFFER:` allocates the specified number of cells for the named
array, where `BUFFER:` just calls `CREATE ALLOT` to define the name with the
reserved space.

We can use `cell-array` to create an array of 10 prime numbers, each is a
single integer:

    10 cell-array: primes ↲
     2 0 primes !  3 1 primes !  5 2 primes !  7 3 primes ! 11 4 primes ! ↲
    13 5 primes ! 17 6 primes ! 23 7 primes ! 29 8 primes ! 31 9 primes ! ↲

A generic `array` word takes the number of elements and size of an element,
where the element size is stored as a cell using `,` followed by `* ALLOT` to
reserve space for the array data:

    : array: CREATE DUP , * ALLOT DOES> SWAP OVER @ * + CELL+ ; ↲
    10 2 CELLS array: factorials ↲
    1.      0 factorials 2! 1.    1 factorials 2! 2.     2 factorials 2! ↲
    6.      3 factorials 2! 24.   4 factorials 2! 120.   5 factorials 2! ↲
    720.    6 factorials 2! 5040. 7 factorials 2! 40320. 8 factorials 2! ↲
    362880. 9 factorials 2! ↲

We can add "syntactic sugar" to enhance the readability of the code, using `{`
and `}` to demarcate the array index expression as follows:

    : { ;  \ Does nothing ↲
    10 2 CELLS array: }factorials ↲
    1. { 0 }factorials 2! 1. { 1 }factorials 2! 2. { 2 }factorials 2! ↲

### Markers

A so-called "marker word" is created with `MARKER`.  When the word is executed,
it deletes itself and all definitions after it.  For example:

    MARKER my-program ↲
    ...
    my-program ↲

This marks `my-program` as the start of our code in `...`.  The code is deleted
by `my-program`.

A source code file might start with the following to delete its definitions
when the file is parsed again:

    [DEFINED] my-program [IF] my-program [THEN] ↲
    MARKER my-program ↲

`ANEW` is shorter and does the same thing:

    ANEW my-program ↲

### Introspection

The following words can be used to inspect words and dictionary contents:

| word          | stack effect             | comment
| ------------- | ------------------------ | -----------------------------------
| `COLON?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `:` definition
| `DEFER?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `DEFER`
| `CONSTANT?`   | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `CONSTANT`
| `2CONSTANT?`  | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `2CONSTANT`
| `VARIABLE?`   | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `VARIABLE` or is created by a word that uses `CREATE` without `DOES>`
| `2VARIABLE?`  | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `2VARIABLE`
| `VALUE?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `VALUE`
| `2VALUE?`     | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `2VALUE`
| `DOES>?`      | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is created by a word that uses `CREATE` with `DOES>`
| `MARKER?`     | ( _xt_ -- _flag_ )       | return `TRUE` if _xt_ is a `MARKER`
| `>BODY`       | ( _xt_ -- _addr_ )       | return the _addr_ of the body of execution token _xt_, usually data
| `>NAME`       | ( _xt_ -- _nt_ )         | return the name token _nt_ of the name of execution token _xt_
| `NAME>STRING` | ( _nt_ -- _c-addr_ _u_ ) | return the string _c-addr_ of size _u_ of the name token _nt_
| `NAME>`       | ( _nt_ -- _xt_ )         | return the execution token of the name token _nt_
| `LAST`        | ( -- _addr_ )            | return the dictionary entry of the last defined word (the entry is a link to the previous entry)
| `L>NAME`      | ( _addr_ -- _nt_ )       | return the name token of the dictionary entry at _addr_ 
| `LAST-XT`     | ( -- _xt_ )              | return the execution token of the last defined word
| `WORDS`       | ( [ "name" ] -- )        | displays all words in the dictionary matching the optional "name" 

## Control flow

### Conditionals

The immediate words `IF`, `ELSE` and `THEN` executes a branch based on a single
condition:

    test IF
      executed if test is nonzero
    THEN

    condition IF
      executed if test is nonzero
    ELSE
      executed if test is zero
    THEN

These words can only be used in colon definitions.

The immediate words `CASE`, `OF`, `ENDOF`, `ENDCASE` select a branch to
execute by comparing the TOS to the `OF` value:

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
`value` as TOS, which may be inspected but should not be dropped.

### Loops

Enumeration-controlled do-loops use the words `DO` or `?DO` and `LOOP` or
`+LOOP`:

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

These words can only be used in colon definitions.  Do-loops run from `start`
to `limit`, but exclude the last iteration for `limit`.  The `DO` loop iterates
at least once, even when `start` equals `limit`.  The `?DO` loop does not
iterate when `start` equals `limit`.  The `+LOOP` word increments the internal
loop counter by `step`, which may be negative.

Do-loops iterate forever when the internal counter never equals `limit`, even
when the counter exceeds `limit`.

The internal loop counter can be used in the loop as `I`.  Likewise, the second
outer loop counter is `J` and the third outer loop counter is `K`.  These
return undefined values when not used within do-loops.

A do-loop body is exited with `LEAVE`.  The `?LEAVE` word pops the TOS and when
nonzero leaves the do-loop, which is a shorthand for `IF LEAVE THEN`.

When exiting from the current colon definition with `EXIT` from within a
do-loop, first the `UNLOOP` word must be used to remove the loop control values
from the return stack before `EXIT`:

Return stack operations `>R`, `R@` and `R>` cannot be used from outside a
do-loop to the inside loop body, because the do-loop stores the loop counter
and limit value on the return stack.  For example, `>R DO ... R@ ... LOOP R>`
produces undefined values.

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
while the condition `test` is nonzero (is true):

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
      executed if test2 is nonzero (is true)
    THEN

The loop `body1` and `body2` are executed as long as `test1` and `test2` are
nonzere (are true).  If `test1` is zero (is false), then the loop exits.  If
`test2` is zero (is false), then the loop terminates in the `ELSE` branch.
Multiple `WHILE` and optional `ELSE` branches may be added.  Each additional
`WHILE` requires a `THEN` after `REPEAT`.

To understand how and why this works, note that a `WHILE` and `REPEAT`
combination is equal to:

    BEGIN       \  BEGIN
      test IF   \    test WHILE
    AGAIN THEN  \  REPEAT

## Compile-time immediate words

The interpretation versus compilation state variable is `STATE`.  When nonzero
(or `TRUE`), a colon definition is being compiled.  When zero (or `FALSE`), the
system is interpreting.  The `[` and `]` may be used in colon definitions to
temporarily switch to interpret mode.  Some words are always interpreted and
not compiled.  These words are marked `IMMEDIATE`.  The compiler executes
`IMMEDIATE` word immediately.  In fact, Forth control flow is implemented with
immediate words that compile conditional branches and loops.

### The [ and ] brackets

The `[` word switches `STATE` to `FALSE` and `]` switches `STATE` to `TRUE`.
This means that `[` and `]` can be used within a colon definition to temporarily
switch to interpret mode and execute words, rather than compiling them.  For
example:

    : my-word ↲
      [ ." compiling my-word" CR ] ↲
      ." executing my-word" CR ; ↲
    my-word ↲

This example displays `compiling my-word...` when `my-word` is compiled and
displays `executing my-word` when `my-word` is executed.

It is a good habit to define words to break up long definitions:

    : compiling-my-word ." compiling my-word" CR ; ↲
    : my-word ↲
      [ compiling-my-word ] ↲
      ." executing my-word" CR ; ↲
    my-word ↲

### Immediate execution

The `[` and `]` are no longer necessary if we make `compiling-my-word`
`IMMEDIATE` to execute immediately:

    : [compiling-my-word] ." compiling my-word" CR ; IMMEDIATE ↲
    : my-word ↲
      [compiling-my-word] ↲
      ." executing my-word" CR ; ↲

Using brackets with `[compiling-my-word]` is another good habit as a reminder
that we execute `[ compiling-my-word ]`.

This example illustrates how `IMMEDIATE` can be used.  Because displaying
information while compiling is generally considered useful, the `.(` word is
marked immediate to display text followed by a `CR` during compilation:

    : my-word ↲
      .( compiling my-word) ↲
      ." executing my-word" CR ; ↲

All [control flow](#control-flow) words execute immediately to compile
conditionals and loops.

### Literals

To compile values on the stack into literal constants in the compiled code, we
use the `LITERAL`, `2LITERAL` and `SLITERAL` immediate words.  For example,
we can create a variable and use its current value to create a literal
constant:

    VARIABLE foo 123 foo ! ↲
    : now-foo [ foo ] LITERAL ; ↲
    456 foo ! ↲
    now-foo . ↲
    123 OK[0]

This example demonstrates that the constant `123` is compiled into a literal in
`now-foo`.

The `2LITERAL` word compiles double integers (two cells).  The `SLITERAL` word
compiles strings:

| word       | stack effect                         | comment
| ---------- | ------------------------------------ | --------------------------
| `LITERAL`  | ( _x_ -- ; -- _x_ )                  | compiles the _x_ as a literal
| `2LITERAL` | ( _dx_ -- ; -- _dx_ )                | compiles the _dx_ as a double literal
| `SLITERAL` | ( _c-addr1_ _u_ ; -- _c-addr2_ _u_ ) | compiles the string _c-addr_ of size _u_ as a string literal
| `[CHAR]`   | ( "name" -- ; -- _char_ )            | returns the first character of "name" on the stack
| `[']`      | ( "name" -- ; -- _xt_ )              | returns the execution token of "name" on the stack

The `[CHAR]` word parses a name and returns the first character on the stack.
This is the compile-time equivalent of `CHAR`.  For example, `[CHAR] $` is the
same as `[ CHAR $ ] LITERAL`.

The `[']` word parses a name and returns the execution token on the stack.
This is the compile-time equivalent of `'` (tick).  For example, `['] NOOP` is
the same as `[ ' NOOP ] LITERAL`.

### Postponing

Immediate words cannot be compiled unless we postpone its execution with
`POSTPONE`.  The `POSTPONE` word parses a name marked `IMMEDIATE` and compiles
it to execute when the colon definition executes.  If the name is not
immediate, then `POSTPONE` compiles the word's execution token as a literal
followed by `COMPILE,`, which means that this use of `POSTPONE` in a colon
definition compiles code.

An example of `POSTPONE` to compile the immedate word `THEN` to execute when
`ENDIF` executes, making `ENDIF` synonymous to `THEN`:

    : ENDIF POSTPONE THEN ; IMMEDIATE ↲

An example of `POSTPONE` to compile a non-immedate word:

    : compile-MAX POSTPONE MAX ; IMMEDIATE ↲
    : foo compile-MAX ; ↲

the result of which is:

    : foo MAX ;

Note that `compile-MAX` is `IMMEDIATE` to compile `MAX` in the definition of
`foo`.  In this way, `compile-MAX` serves as a macro that expands into `MAX`.

### Compile-time conditionals

Forth source input is conditionally interpeted and compiled with `[IF]`,
`[ELSE]` and `[THEN]` words.  The `[IF]` word jumps to a matching `[ELSE]`
or `[THEN]` if the TOS is zero (`FALSE`).  When used in colon definitions, the
TOS value should be produced immediately with `[` and `]`:

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
    : 2NIP ROT DROP ROT DROP ; ↲
    [THEN] ↲

## Source input and parsing

The interpreter and compiler parse input from two buffers, the `TIB` (terminal
input buffer) and `FIB` (file input buffer).  Input from these two sources is
controlled by the following words:

| word        | stack effect        | comment
| ----------- | ------------------- | ------------------------------------------
| `TIB`       | ( -- _c-addr_ )     | a 256 character terminal input buffer
| `FIB`       | ( -- _c-addr_ )     | a 256 character file input buffer
| `SOURCE-ID` | ( -- _addr_ )       | a variable holding the _fileid_ of the input source (e.g. `STDI` for keyboard)
| `SOURCE`    | ( -- _c-addr_ _u_ ) | the current buffer (`TIB` or `FIB`) and number of characters stored in it
| `>IN`       | ( -- _addr_ )       | a variable holding the current input position in the `SOURCE` buffer to parse from
| `REFILL`    | ( -- _flag_ )       | refills the current input buffer, returns true if successful

The following words parse the current source of input:

| word       | stack effect                         | comment
| ---------- | ------------------------------------ | --------------------------
| `PARSE`    | ( _char_ "chars" -- _c-addr_ _u_ )   | parses "chars" up to a matching _char_, returns the parsed characters as string _c-addr_ _u_
| `\"-PARSE` | ( _char_ "chars" -- _c-addr_ _u_ )   | same as `PARSE` but also converts escapes to raw characters in _c-addr_ _u_, see `S\"` in [string constants](#string-constants)
| `PARSE-WORD` | ( _char_ "chars" -- _c-addr_ _u_ ) | same as `PARSE` but skips all leading matching _char_ first
| `PARSE-NAME` | ( "name" -- _c-addr_ _u_ )         | parses a name delimited by blank space, returns the name as a string _c-addr_ _u_
| `WORD`       | ( _char_ "chars" -- _c-addr_ )     | an obsolete word to parse a word

Basically, `PARSE-NAME` is the same as `BL PARSE-WORD`, where `BL` is the space
character.  The names of words in the dictionary are parsed with `PARSE-NAME`.
When `BL` is used as delimiter, also the control characters, such as CR and LF,
are considered delimiters.

## Files

The following words return _ior_ to indicate success (zero) or failure (nonzero
[file error](#file-errors) code)

| word              | stack effect                                    | comment
| ----------------- | ----------------------------------------------- | --------
| `FILES`           | ( [ "glob" ] -- )                               | lists files matching optional "glob" with wildcards `*` and `?`
| `FILE-STATUS`     | ( _c-addr_ _u_ -- _f-addr_ _ior_ )              | if file with name _c-addr_ _u_ exists, return _ior_=0
| `DELETE-FILE`     | ( _c-addr_ _u_ -- _ior_ )                       | delete file with name _c-addr1_ _u1_
| `RENAME-FILE`     | ( _c-addr1_ _u1_ _c-addr2_ _u2_ -- _ior_ )      | rename file with name _c-addr1_ _u1_ to _c-addr2_ _u2_
| `R/O`             | ( -- _fam_ )                                    | open file for read only
| `W/O`             | ( -- _fam_ )                                    | open file for write only
| `R/W`             | ( -- _fam_ )                                    | open file for reading and writing
| `BIN`             | ( _fam_ -- _fam_ )                              | update _fam_ for "binary file" mode access (does nothing)
| `CREATE-FILE`     | ( _c-addr_ _u_ _fam_ -- _fileid_ _ior_ )        | create new file named _c-addr_ _u_ with mode _fam_, returns _fileid_
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
| `RESIZE-FILE`     | ( _ud_ _fileid_ -- _ior_ )                      | resize _fileid_ to _ud_ bytes (does not truncate files, only enlarge)
| `DRIVE`           | ( -- _addr_ )                                   | returns address _addr_ of the current drive letter
| `FREE-CAPACITY`   | ( _c-addr_ _u_ -- _du_ _ior_ )                  | returns the free capacity of the drive in string _c-addr_ _u_
| `STDO`            | ( -- 1 )                                        | returns _fileid_ 1 for standard input from the keyboard
| `STDI`            | ( -- 2 )                                        | returns _fileid_ 2 for standard output to the screen
| `STDL`            | ( -- 3 )                                        | returns _fileid_ 3 for standard output to the line printer
| `>FILE`           | ( _fileid_ -- _f-addr_ )                        | returns file _f-addr_ data for _fileid_
| `FILE>STRING`     | ( _f-addr_ -- _c-addr_ _u_ )                    | returns string _c-addr_ _u_ file name converted from file _f-addr_ data

Globs with wildcard `*` and `?` can be used to list files on the E: or F:
drive, for example:

    FILES E:*.*        \ list all E: files and the current drive to E:
    FILES              \ list all files on the current drive
    FILES *.FS         \ list all FS files on the current drive
    FILES PROGRAM.*    \ list all PROGRAM files with any extension on the current drive
    FILES PROGRAM.???  \ same as above

Only one `*` for the file name can be used and only one `*` for the file
extension can be used.

## File errors

File I/O _ior_ error codes returned by file operations, _ior_=0 means no error:

| code | error
| ---- | -----------------------------------------------------------------------
| 256  | an error occurred in the device and aborted
| 257  | the parameter is beyond the range
| 258  | the specified file does not exist
| 259  | the specified pass code does not exist
| 260  | the number of files to be opened exceeds the limit
| 261  | the file whose processing is not permitted
| 262  | ineffective file handle was attempted
| 263  | processing is not specified by open statement
| 264  | the file is already open
| 265  | the file name is duplicated
| 266  | the specified drive does not exist
| 267  | error in data verification
| 268  | processing of byte number has not been completed
| 510  | fatal low battery

## Exceptions

| word     | stack effect                         | comment
| -------- | ------------------------------------ | ----------------------------
| `ABORT`  | ( ... -- ... )                       | abort execution and throw -1
| `ABORT"` | ( "string" -- ; ... _x_ -- ... )     | if _x_ is nonzero, display "string" message and throw -2
| `QUIT`   | ( ... -- ... )                       | throw -56
| `THROW`  | ( ... _x_ -- ... ) or ( 0 -- )       | if _x_ is nonzero, throw _x_ else drop the 0
| `CATCH`  | ( _xt_ -- ... 0 ) or ( _xt_ -- _x_ ) | execute _xt_, if an exception _x_ occurs then restore the stack and return _x_, otherwise return 0

Note that `test ABORT" test failed"` throws -2 if `test` leaves a nonzero on
the stack.  This construct can be used to check return values and perform
assertions on values in the code.

The `CATCH` word executes the execution token _xt_ like `EXECUTE`, but catches
exceptions thrown.  If an exception _x_ occurs, then the stack is restored to
the state before `CATCH` (without _xt_) and the nonzero exception code _x_ is
pushed on the stack.  Otherwise a zero is left on the stack.

For example, to throw and catch any errors when opening a file read-only, read
it in blocks of 256 bytes into the `PAD` to display on screen, and close it:

    : fopen ( c-addr u -- fileid )
      R/O OPEN-FILE THROW ;
    : fread ( fileid -- fileid c-addr length )
      DUP PAD 256 ROT \ fileid c-addr 256 fileid
      READ-FILE THROW \ fileid length
      PAD SWAP ;      \ fileid c-addr length
    : fclose ( fileid -- )
      CLOSE-FILE THROW ;
    : more ( -- )
      fopen \ fileid
      BEGIN
        ' fread CATCH IF
          fclose ABORT
        THEN \ fileid c-addr length
      DUP WHILE
        TYPE
      REPEAT
      2DROP
      fclose CR ;
    : some ( -- )
      S" somefile.txt" ' more CATCH ABORT" an error occurred" ;

The following standard Forth exception codes may be thrown by built-in Forth500
words:

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
| -256 | execution of an uninitialized deferred word

## Environment queries

The `ENVIRONMENT?` word takes a string to return system-specific information
about this Forth implementation as required by [standard
Forth](https://forth-standard.org/standard/usage#usage:env) `ENVIRONMENT?`.

## Dictionary structure

The Forth500 dictionary is organized as follows:

         low address in the 11th segment $Bxx00
          _________
    +--->| $0000   |     last entry link is zero (2 bytes)
    |    |---------|
    |    | 7       |     length of "(DOCOL)" (1 byte)
    |    |---------|
    |    | (DOCOL) |     "(DOCOL)" characters (7 bytes)
    |    |---------|
    |    | code    |     machine code
    |    |---------|
    +<==>+ link    |     link to previous entry (2 bytes)
    |    |---------|
    :    :         :
    :    :         :
    :    :         :
    |    |---------|
    +<==>| link    |     link to previous entry (2 bytes)
    |    |---------|
    |    | $80+5   |     length of "aword" (1 byte) with IMMEDIATE bit set
    |    |---------|
    |    | aword   |     "my-word" characters (7 bytes)
    |    |---------|
    |    | code    |     Forth code and/or data
    |    |---------|
    +<---| link    |<--- LAST link to previous entry (2 bytes)
         |---------|
         | 7       |     length of "my-word" (1 byte)
         |---------|
         | my-word |     "my-word" characters (7 bytes)
         |---------|
         | code    |<--- LAST-XT Forth code and/or data
         |---------|<--- HERE pointer
         |         |
         | free    |
         | space   |
         |         |
         |---------|<--- dictionary limit
         |         |
         | data    |     stack of 200 cells (400 bytes)
         | stack   |     grows toward lower addresses
         |         |<--- SP stack pointer
         |---------|
         |         |
         | return  |     return stack of 200 cells (400 bytes)
         | stack   |     grows toward lower addresses
         |         |<--- RP return stack pointer
         |---------|<--- $BFC00

         high address

A link field points to the previous link field.  The last link field is zero.

The `LAST` variable holds the address of the last entry in the dictionary.
This is where the search for dictionary words starts.

The `LAST-XT` variable holds the address of the last compiled execution token,
which is the location where the machine code starts.

Code is either machine code or starts with a jump or call instruction of 3
bytes, followed by Forth code (a sequence of execution tokens) or data.

Immediate words are marked with the high bit 7 set ($80).  Hidden words have
the "smudge" bit 6 ($40) set.  A word is hidden until successfully compiled.

## Alphabetic list of words

TODO

_Copyright Robert A. van Engelen (c) 2021_

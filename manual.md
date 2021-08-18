!!WORK IN PROGRESS!!

# Forth500 User Guide

Author: Robert A. van Engelen, 2021

Forth500 is a standard Forth 2012 system for the SHARP PC-E500(S) pocket
computer.  This pocket computer sports a 2.304MHz 8-bit CPU with a 20-bit
address space of 1MB.  This pocket computer includes 256KB system ROM and 32KB
to 256KB RAM.  The RAM card slot offers additional storage up to 256KB RAM.
Forth500 is small enough to fit in an unexpanded 32KB machine.

## Forth

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

### Introduction

A Forth system is a dictionary of words.  A word is often a name but can be any
sequence of characters excluding space, tab, newline, and other control
characters.  Words are defined for subroutines, for named constants and for
global variables and data.  Some words may execute at compile time to compile
the body of subroutine definitions and to implement control flow such as
branched and loops.  As such, the syntax blends compile-time and runtime
behaviors that are only distinguishable by naming and naming conventions.

Forth500 is case insensitive.  Words may be typed in either case or use mixed
case.  In the following, built-in words are shown in UPPER CASE.  User-defined
words are shown in lower case.

To list the words stored in the Forth dictionary, type (↲ is ENTER):

    WORDS ↲

Hit any key to continue or BREAK to stop.  BREAK generally terminates the
execution of a Forth500 program or subroutine associated with a word.  To list
words that fully and partially match a given name, type:

    WORDS NAME ↲

For example, `WORDS DUP` lists all words with names that contain the part `DUP`
(the search is case sensitive).

Words like `DUP` operate on the stack.  `DUP` duplicates the top value,
generally called TOS: top of stack.  All computations in Forth occur on the
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

To clear the stack, type:

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
that `."` is a normal word and must be followed by a blank.  The `CR` word
prints a carriage return and newline.

Let's try it out:

    hello ↲
    Hello, World!

Some words like `."` and `;` are compile-time only, which means that they can
only be used in definitions.  Two other compile-time words are `DO` and `LOOP`
for loops:

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
reused in other definitions.  This keeps definitions short and understandable.
For example, we can redefine `greetings` to use `hellos`:

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

To set the variable to a value:

    FALSE spanish ! ↲

or

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

A large portion of the Forth system is defined in Forth itself, like the `?`
word.

In place of `IF-ELSE-THEN` which we can nest, we can also use
`CASE-OF-ENDOF-ENDCASE` to add more languages:

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
counter when incremented equals the final value.  For example, this loop
executes `hello` 10 times:

    : greetings 10 0 DO hello LOOP ; ↲

Actually, `DO` cannot be recommended because the loop body is always executed
at least once, for example when the initial value is the same as the final
value.  Using `?DO` instead of `DO` avoids this:

    : hellos 0 ?DO hello LOOP ; ↲
    0 hellos ↲
    OK[0]

This never executes the loop body `hello` as intended.  To change the step size
or direction of the loop, use `+LOOP`.  The word `I` returns the counter value:

    : evens 10 0 ?DO I . 2 +LOOP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

Again, be warned that the loop terminates when the counter equals the final
value, not exceeds it.  Therefore, using the wrong loop `9 0 ?DO I . 2 +LOOP`
would never terminate.

A `BEGIN-WHILE-REPEAT` is a logically-controlled loop with which we can do the
same as follows by pushing a `0` to use as a counter on top of the stack:

    : evens ↲
      0 ↲
      BEGIN DUP 10 < WHILE ↲
        DUP . ↲
        2+ ↲
      REPEAT DROP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

A `BEGIN-UNTIL` loop:

    : evens ↲
      0 ↲
      BEGIN ↲
        DUP . ↲
        2+ ↲
      DUP 10 < INVERT UNTIL DROP ; ↲
    evens ↲
    0 2 4 6 8 OK[0]

Forth has no built-in `>=`, so we use `< INVERT`.  To define `>=` is easy:

    : >= < INVERT ; ↲

This ends our quick tutorial introduction to the essential basics of Forth.

## Stack manipulation

To make it easier to document words that manipulate the stack, we need to first
distinguish what type of values are manipulted on the stack.  To do so, we use
the following common conventions:

| value    | represents
| -------- | -------------------------------------------------------------------
| _flag_   | the Boolean value true (nonzero, typically -1) or false (zero)
| _true_   | true flag (nonzero, typically -1)
| _false_  | false flag (zero)
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
| _f-addr_ | a 16-bit address pointing to a file status structure
| _fileid_ | a nonzero single integer file identifier
| _ior_    | a single integer error code
| _nt_     | a name token, address of the name of a word in the dictionary
| _xt_     | an execution token, address of code (of a word in the dictionary)

A single integer or address is also called a "cell" with a size of two bytes.

With these naming conventions for stack values, we can now describe words by
their stack effect.  Values on the left of the -- are on the stack before the
word is executed and the values on the right of the -- are on the stack after
the word is executed.  The stack grows to the right with the TOS on top:

| word   | stack effect ( _before_ -- _after_ ) | comment
| ------ | ------------------------------------ | ------------------------------
| `DUP`  | ( _x_ -- _x_ _x_ )                   | duplicate TOS
| `DROP` | ( _x_ -- )                           | drop the TOS
| `SWAP` | ( _x1_ _x2_ -- _x2_ _x1_ )           | swap TOS with 2OS
| `OVER` | ( _x1_ _x2_ -- _x1_ _x2_ _x1_ )      | duplicate 2OS to the top
| `NIP`  | ( _x1_ _x2_ -- _x2_ )                | delete 2OS
| `TUCK` | ( _x1_ _x2_ -- _x2_ _x1_ _x2_ )      | tuck a copy of TOS under 2OS
| `ROT`  | ( _x1_ _x2_ _x3_ -- _x2_ _x3_ _x1_ ) | rotate stack, 3OS goes to TOS
| `-ROT` | ( _x1_ _x2_ _x3_ -- _x3_ _x1_ _x2_ ) | rotate stack, TOS goes to 3OS
| `?DUP` | ( _x_ -- _x_ _x_ ) or ( 0 -- 0 )     | duplicate TOS if nonzero

Note that `NIP` is the same as `SWAP DROP` and `TUCK` is the same as `DUP -ROT`.

To reach deeper into the stack:

| word   | stack effect ( _before_ -- _after_ )       | comment
| ------ | ------------------------------------------ | ------------------------
| `PICK` | ( _xk_ ... _x0_ k -- _xk_ ... _x0_ _xk_ )  | duplicate k'th value to the top
| `ROLL` | ( _xk_ ... _x0_ k -- _xk-1_ ... _x0_ _xk_) | rotate the k'th value to the top

Note that `0 PICK` is the same as `DUP`, `1 PICK` is the same as `OVER`, `1
ROLL` is the same as `SWAP`, `2 ROLL` is the same as `ROT` and `0 ROLL` does
nothing.

The following words operate on two cells on the stack (a pair of single
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

The _after_ stack effects include the operations % (mod), & (bitwise and), |
(bitwise or), ^ (bitwise xor), ~ (bitwise not/invert), << (bitshift left)
and >> (bitshift right).  The U< and U> comparisons are unsigned, see
[Comparisons](#comparisons).

The `*/` and `*/MOD` words produce an intermediate double product to avoid
intermediate overflow.

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

Note: to convert an unsigned single integer to a double, just push a `0`.

## Mixed arithmetic

The following words cover mixed single and double integer arithmetic
operations.  Words involving division and modulo may throw exception -10
"Division by zero".

| word     | stack effect ( _before_ -- _after_ )     | comment
| -------- | ---------------------------------------- | ------------------------
| `M+`     | ( _d_ _n_ -- (_d_+_n_) )                 | add signed single to signed double
| `M-`     | ( _d_ _n_ -- (_d_-_n_) )                 | subtract signed single from signed double
| `M*`     | ( _n1_ _n2_ -- (_n1_\*_n2_) )            | multiply signed singles to return signed double
| `UM*`    | ( _u1_ _u2_ -- (_u1_\*_u2_) )            | multiply unsigned singles to return unsigned double
| `UMD*`   | ( _ud_ _u_ -- (_ud_\*_u_) )              | multiply unsigned double and single to return unsigned double
| `M*/`    | ( _d_ _n_ _+n_ -- (_d_\*_n_/_+n_) )      | multiply signed double with signed single then divide by positive single to return signed double
| `UM/MOD` | ( _u1_ _u2_ -- (_u1_%_u2_) (_u1_/_u2_) ) | remainder and quotient of unsigned singles
| `FM/MOD` | ( _d_ _n_ -- (_d_%_n_) (_d_/_n_) )       | floored remainder and quotient of signed double and single
| `SM/REM` | ( _d_ _n_ -- (_d_%_n_) (_d_/_n_) )       | symmetric remainder and quotient of signed double and single

## Comparisons

The following words return true or false on the stack by comparing integer
values.

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

More precisely, the word performs a comparison of a test value _n1_|_u1_ with an
inclusive lower limit _n2_|_u2_ and an exclusive upper limit _n3_|_u3_,
returning true if either (_n2_|_u2_ < _n3_|_u3_ and (_n2_|_u2_ <= _n1_|_u1_ and
_n1_|_u1_ < _n3_|_u3_)) or (_n2_|_u2_ > _n3_|_u3_ and (_n2_|_u2_ <= _n1_|_u1_
or _n1_|_u1_ < _n3_|_u3_)) is true, returning false otherwise.

## Strings

## Return stack

## Variables, values and constants

## Defining new words

### Deferred words

### Recursion

### Immediate words

### Noname words

### Words to create data

## Control flow

### Conditionals

### Loops

## Exceptions

## Numeric output

We saw that `.` displays the TOS.  Other words to display stack values:

| word    |
| ------- |
| `.`     |
| `U.`    |
| `D.`    |
| `BASE.` |
| `BIN.`  |
| `DEC.`  |
| `HEX.`  |

## Character output

## Input

## Files

## Screen

## Graphics

## Sound

_Copyright Robert A. van Engelen 2021_

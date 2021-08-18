!!WORK IN PROGRESS!!

# Forth500 User Guide

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

## A quick tutorial

This section is intentionally kept simple by avoiding technical jargon and
unnecessary excess.  Familiarity with the concepts of stacks and dictionaries
is assumed.

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

To list the words stored in the Forth dictionary, type (↲ is enter):

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
values on the stack.  Integer values are simply pushed onto the stack:

    TRUE 123 DUP .S ↲
    -1 123 123 OK[3]

where `TRUE` pushes -1, `123` pushes 123, `DUP` duplicates the TOS and `.S`
shows the stack values.  `OK[3]` indicates that there currently are three
values on the stack.

You can spread the code over multiple lines.  It does not matter if you hit
ENTER at the end or if you hit ENTER to input more than one line.

To clear the stack, type:

    CLEAR ↲

Like traditional Forth systems, Forth500 integers are 16-bit signed or
unsigned.  Decimal, hexadecimal and binary number systems are supported:

| input   | TOS |
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

This defines the word `hello` with the obligatory "Hello, World!" message.  The
definition ends with a `;` (semicolon).  The `."` word parses a sequence of
character until `"`.  These characters are display on screen.  Note that `."`
is a normal word and must be followed by a blank.  The `CR` word prints a
carriage return and newline.

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
words used by other previously defined words:

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
specified word is deleted from the dictionary, including `greetings` and
`hellos`.

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
place.  A `THEN` closes the `IF` (some Forth's allow `ENDIF` or `THEN`).  By
comparison to C, `spanish @ IF x ELSE y` is similar to `*spanish ? x : y`.  The
variable `spanish` places its address on the stack.  The value is fetched with
`@`.  If the value is nonzero (true), then the statements after `IF` are
executed.  Otherwise, the statements after `ELSE` are executed.

### Stack manipulation

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
their stack effect.  Values on the left of the `--` are on the stack before
the word is executed and the values on the right of the `--` are on the stack
after the word is executed.  The stack grows to the right with the TOS on top:

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

### Arithmetic

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
(bitwise or), ^ (bitwise xor), ~ (bitwise not/invert), << (bitshift left) and
>> (bitshift right).  The U< and U> comparisons are unsigned,
see Conditionals.

The `*/` and `*/MOD` operations produce an intermediate double product to avoid
intermediate overflow.

### Double arithmetic

### Mixed arithmetic

### Conditionals

### Numeric output

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

### Character output

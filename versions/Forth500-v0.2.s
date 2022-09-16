; Forth500
;
; Authors:
;   Sébastien Furic (original incomplete pce500forth-v1)
;   Dr. Robert van Engelen (Forth500)
;
; Change org in Forth500.s according to the available RAM memory:
; 
; 1. for machines with extra 64KB RAM card or larger and MEM$="B":
;         org	$b0000
; 
; 2. for machines with extra 32KB RAM card and MEM$="B" and no E: drive:
;         org	$b1000
; 
; 3. for unexpanded 32KB machines or MEM$="S1" and no E: drive:
;         org	$b9000
; 
; Assemble to produce binary file Forth500.OBJ:
;   $ XASM Forth500.s -O -L -S -TB
; 
; Then remove the leading 6 header bytes from the Forth500.OBJ file:
;   $ tail -c +7 Forth500.OBJ > Forth500.bin
; 
; With a cassette interface such as CE-126p use PocketTools to load (use
; Forth500 org address &Bxx00 for option --addr):
;   $ bin2wav --pc=E500 --type=bin --addr=0xBxx00 --sync=3 Forth500.bin
; 
; On the PC-E500 execute (the specified Forth500 org address is &Bxx00):
;   > POKE &BFE03,&1A,&FD,&0B,0,&FC-&xx,0: CALL &FFFD8
; This reserves &Bxx00-&BFC00 and resets the machine.
;
; Warning: memory cannot be allocated when in use by programs.  To check if
; memory was allocated:
; 
;     > HEX PEEK &BFD1B
;     xx
; 
; The value xx shows that memory was allocated from &Bxx00 on (&BFD1C contains
; the low-order address byte, which is zero).
; 
; Play the wav file, load and run Forth (the specified org address is &xx00):
;   > CLOADM
;   > CALL &Bxx00
;
; To remove Forth from memory and release its allocated RAM space:
;   > POKE &BFE03,&1A,&FD,&0B,0,0,0: CALL &FFFD8

;-------------------------------------------------------------------------------
;
;		Forth500 CPU registers and internal RAM usage
;
;-------------------------------------------------------------------------------
;
;	BA	TOS
;	U	stack pointer (SP) points to 2OS, grows to lower addresses
;	S	return stack pointer (RP), grows to lower addresses
;	I	execution token in the fetch-execute cycle and free to use
;	X	instruction pointer (IP)
;	Y	unassigned, free to use
;	(wi)	HERE pointer (3 bytes)
;	(xi)	floating point stack pointer (FP) (3 bytes)
;	(ll)	floating point stack depth (8 bit)
;	(fp)	floating point working area (36 bytes)
;
;-------------------------------------------------------------------------------
;
;		BP register offset for BP-relative addresses
;
;-------------------------------------------------------------------------------
bp0:		equ	$70
;-------------------------------------------------------------------------------
;
;		Implementation logic registers (BP-relative addresses)
;
;-------------------------------------------------------------------------------
; floating point arguments for fop__
fp:		equ	$00			; 32 bytes floating point working area
; 16 bit (8+8) registers
el:		equ	$20			; el / floating point extra area (36 bytes total)
eh:		equ	$21			; eh / floating point extra area (36 bytes total)
ex:		equ	$20
fl:		equ	$22			; fl / floating point extra area (36 bytes total)
fh:		equ	$23			; fh / floating point extra area (36 bytes total)
fx:		equ	$22
gl:		equ	$24
gh:		equ	$25
gx:		equ	$24
hl:		equ	$26
hh:		equ	$27
hx:		equ	$26
il:		equ	$28
ih:		equ	$29
ix:		equ	$28
jl:		equ	$2a
jh:		equ	$2b
jx:		equ	$2a
kl:		equ	$2c
kh:		equ	$2d
kx:		equ	$2c
ll:		equ	$2e			; Floating point stack's depth
lh:		equ	$2f
lx:		equ	$2e
; 20 bit registers
wi:		equ	$30			; HERE pointer
xi:		equ	$33			; FP (Floating point stack pointer)
yi:		equ	$36
zi:		equ	$39
;-------------------------------------------------------------------------------
;
;		 Standard logic registers
;
;-------------------------------------------------------------------------------
bl:		equ	$d4
bh:		equ	$d5
bx:		equ	$d4
cl:		equ	$d6
ch:		equ	$d7
cx:		equ	$d6
dl:		equ	$d8
dh:		equ	$d9
dx:		equ	$d8
si:		equ	$da
di:		equ	$dd
;-------------------------------------------------------------------------------
;
;		System file and IO control vectors
;
;-------------------------------------------------------------------------------
fcs:		equ	$fffe4
iocs:		equ	$fffe8
;-------------------------------------------------------------------------------
;
;		Forth system parameters
;
;-------------------------------------------------------------------------------
base_address:	equ	$b0000			; 11th segment (do not change)
ib_size:	equ	256			; TIB and FIB size
hold_size:	equ	40			; ENVIRONMENT? /HOLD size in bytes
;blk_buff_size:	equ	1024
r_size:		equ	256			; The return stack size in bytes (must be 256, see ?STACK)
s_size:		equ	256			; The stack size in bytes (must be 256, see ?STACK)
f_size:		equ	8			; The FP stack size in number of entries (8*12=96 bytes)
r_beginning:	equ	$bfc00			; The return stack's beginning
r_limit:	equ	r_beginning-r_size	; The return stack's low limit ($bfb00 see ?STACK)
s_beginning:	equ	r_limit			; The stack's beginning
s_limit:	equ	s_beginning-s_size	; The stack's low limit ($bfa00 see ?STACK)
f_beginning:	equ	s_limit			; The floating-point stack's beginning
f_limit:	equ	f_beginning-12*f_size	; The floating-point stack's low limit
dict_limit:	equ	f_limit			; The upper limit of the dictionary space
;-------------------------------------------------------------------------------
;
;		Forth location and boot address
;
;-------------------------------------------------------------------------------
		org	$b9000			; $b0000 or $b1000 or $b9000 ...
;-------------------------------------------------------------------------------
;
;		Forth booting
;
;-------------------------------------------------------------------------------
boot:		local
		pre_on
		and	($fb),$7f		; Disable interruptions
		mv	x,!bp_value		; System and Forth parameters
		mv	[x++],($ec)		; Save BP's current value
		mv	[x++],u			; Save U's current value
		mv	y,s
		mv	[x++],y			; Save S's current value
		mv	($ec),!bp0		; Set BP to its new value
		mv	u,!s_beginning		; Set U to its new value
		mv	s,!r_beginning		; Set S to its new value
		or	($fb),$80		; Enable interruptions
		pre_off
		mvp	(!xi),!f_beginning	; Set FP to its new value
		mv	(!ll),0			; Set floating point stack's depth
		mv	ba,[$bfc97]		; symbols
		mv	[x++],ba		; to restore them
		mv	ba,[$bfc99]		; when returning to
		mv	[x++],ba		; BASIC
		mvp	(!wi),[x++]		; Set HERE value
		mv	ba,[x++]
		mv	[!last_xt+3],ba		; Set LAST value
		mv	ba,[x++]
		mv	[!lastxt_xt+3],ba	; Set LAST-XT value
		;sub	ba,ba
		;mv	[!handler_xt+3],ba	; No error handler
		mv	i,!startup_xt
		jp	!startup_xt
		endl
;-------------------------------------------------------------------------------
;
;		Saved E500 system and Forth parameters
;
;-------------------------------------------------------------------------------
bp_value:	ds	1			; To restore BP
u_value:	ds	3			; To restore U
s_value:	ds	3			; To restore S
symbols:	ds	4			; To restore display's symbols when returning to BASIC
here_value:	dp	_end_			; 20 bit HERE pointer
last_value:	dw	startup			; 16 bit LAST address
lastxt_value:	dw	startup_xt		; 16 bit LAST-XT address
;-------------------------------------------------------------------------------
;
;		Forth internals
;
;-------------------------------------------------------------------------------
docol_:		dw	$0000			; To mark the start of the dictionary
		db	$07
		db	'(DOCOL)'	; cycles = 23 + 7 + 15 = 45
docol__xt:	ex	i,x		; 4	; Save execution token I in X, set I to the short IP
		pushs	i		; 6	; Save IP as return address
		mv	i,x		; 2	; I is the current execution token
		mv	x,!base_address+3 ; 4	; Set new IP (I contains
		add	x,i		; 7	; the current execution token, skip 3 bytes jp docol__xt)
;---------------
interp__:	pre_on			; cycles = 7 + 15 = 22
		test	($ff),$08	; 5	; Is break pushed?
		pre_off
		jrnz	break__		; 2/3	; Break was pushed
;---------------			; cycles = 15
cont__:		mv	i,[x++]		; 5	; Set I to new execution token
		pushs	i		; 6	; Execute
		ret			; 4	; new token
;-------------------------------------------------------------------------------
break__:	local
		pre_on
lbl1:		mv	i,1181			; Set I to count 20ms debounce time
lbl2:		test	($ff),$08	; 5	; Test if the break key
		jrnz	lbl1		; 2/3	; was intentionally released
		dec	i		; 3	; (break action is triggered
		jrnz	lbl2		; 2/3	; when the break key is released)
		pre_off
		endl
		mv	il,-28			; User interrupt
;---------------
throw__:	pushu	ba			; Save TOS
		mv	ba,$ff00		; Set high-order bits, standard error codes are always negative
		add	ba,il			; Set TOS to error code
		mv	i,!throw_xt		; Execution token of THROW, (DOCOL) needs this
		jp	!throw_xt
;-------------------------------------------------------------------------------
doret_:		dw	docol_
		db	$07
		db	'(DORET)'
doret__xt:	local			; cycles = 30
		mv	i,[s]		; 5	; I is the short return address
		mv	x,!base_address ; 4	;
		add	x,i		; 7	; X is the return address IP
		mv	i,[x++]		; 5	; Set I to new execution token
		mv	[s],i		; 5	; Execute
		ret			; 4	; new token
		endl
;-------------------------------------------------------------------------------
doexit_:	dw	doret_
		db	$06
		db	'(EXIT)'
doexit__xt:	local
		jr	!doret__xt		; Same as (DORET)
		endl
;-------------------------------------------------------------------------------
dolit0:		dw	doexit_
		db	$01
		db	'0'
dolit0_xt:	local
		pushu	ba			; Save old TOS
		sub	ba,ba			; Set new TOS to 0 (FALSE)
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
dolit1:		dw	dolit0
		db	$01
		db	'1'
dolit1_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,1			; Set new TOS to 1
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
dolit2:		dw	dolit1
		db	$01
		db	'2'
dolit2_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,2			; Set new TOS to 2
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
dolit3:		dw	dolit2
		db	$01
		db	'3'
dolit3_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,3			; Set new TOS to 2
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
dolitm1:	dw	dolit3
		db	$02
		db	'-1'
dolitm1_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,-1			; Set new TOS -1 (TRUE or $ffff)
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
true:		dw	dolitm1
		db	$04
		db	'TRUE'
true_xt:	local
		jr	!dolitm1_xt		; TRUE is -1
		endl
;-------------------------------------------------------------------------------
false:		dw	true
		db	$05
		db	'FALSE'
false_xt:	local
		jr	!dolit0_xt		; FALSE is 0
		endl
;-------------------------------------------------------------------------------
dolit_:		dw	false
		db	$07
		db	'(DOLIT)'
dolit__xt:	local
		pushu	ba			; Save old TOS
		mv	ba,[x++]		; Set new TOS (next token)
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
do2lit_:	dw	dolit_
		db	$08
		db	'(DO2LIT)'
do2lit__xt:	local
		pushu	ba			; Save old TOS
		mv	ba,[x++]		; Fetch the high-order 16 bits (next token) and set new TOS
		mv	i,[x++]			; Fetch the low-order 16 bits (next token)
		pushu	i			; Push the low-order 16 bits one the stack as 2OS
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
;doflit_:	dw	do2lit_
;		db	$08
;		db	'(DOFLIT)'
;doflit__xt:	local
;		pushu	ba			; Save TOS
;		mv	y,(!xi)			; Y holds FP's value
;		mv	a,[x]			; Test the length of the floating point
;		test	a,$01			; number (single or double precision)
;		jrz	lbl1			; zero=single precision
;		mv	i,12			; The length of a double precision floating-point number
;		jr	lbl2
;lbl1:		mv	i,5			; Align FP
;		sub	y,i			; on a double precision address
;		mv	i,7			; The length of a single precision floating-point number
;lbl2:		mv	a,[x++]			; Copy the floating-point number
;		mv	[--y],a			; on the floating-point stack
;		dec	i
;		jrnz	lbl2
;		mv	il,0			; Store computation
;		mv	[--y],i			; correction
;		mv	(!xi),y			; Update FP's value
;		popu	ba			; Restore TOS
;		jr	!cont__
;		endl
;-------------------------------------------------------------------------------
doslit_:	dw	do2lit_
		db	$08
		db	'(DOSLIT)'
doslit__xt:	local
		pushu	ba			; Save old TOS
		mv	ba,[x++]		; Read the length of the string
		mv	i,x			; I holds the short address of the string
		pushu	i			; Save it on the stack
		add	x,ba			; Update IP to skip up to the end of the string
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
dovar_:		dw	doslit_
		db	$07
		db	'(DOVAR)'
dovar__xt:	local
		pushu	ba		; 4	; Save old TOS
		mv	ba,3		; 3	; Set
		add	ba,i		; 5	; new TOS
		jr	!cont__		; 3
		endl
;-------------------------------------------------------------------------------
docon_:		dw	dovar_
		db	$07
		db	'(DOCON)'
docon__xt:	local
		pushu	ba		; 4	; Save old TOS
		mv	y,!base_address+3 ; 4
		add	y,i		; 7
		mv	ba,[y]		; 5	; Set new TOS
		jr	!cont__		; 3
		endl
;-------------------------------------------------------------------------------
do2con_:	dw	docon_
		db	$08
		db	'(DO2CON)'
do2con__xt:	local
		pushu	ba			; Save old TOS
		mv	y,!base_address+3
		add	y,i
		mv	ba,[y++]		; Fetch the 16 high-order bits (and set new TOS)
		mv	i,[y]			; Fetch the 16 low-order bits
		pushu	i			; Push the 16 low-order bits
		jr	!cont__
		endl
;-------------------------------------------------------------------------------
doval_:		dw	do2con_
		db	$07
		db	'(DOVAL)'
doval__xt:	local
		jr	!docon__xt		; Same code as DOCON
		endl
;-------------------------------------------------------------------------------
do2val_:	dw	doval_
		db	$07
		db	'(DO2VAL)'
do2val__xt:	local
		jr	!do2con__xt		; Same code as DO2CON
		endl
;-------------------------------------------------------------------------------
doto_:		dw	do2val_
		db	$04
		db	'(TO)'
doto__xt:	local
		mv	i,[x++]			; Read the short address of the value
		mv	y,!base_address		; Y holds the
		add	y,i			; address of the value
		mv	[y],ba			; Set new value
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
do2to_:		dw	doto_
		db	$05
		db	'(2TO)'
do2to__xt:	local
		mv	i,[x++]			; Read the short address of the value
		mv	y,!base_address		; Y holds the
		add	y,i			; address of the value
		mv	[y++],ba		; Set new high-order bits
		popu	ba
		mv	[y],ba			; Set new low-order bits
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
dodefer_:	dw	do2to_
		db	$09
		db	'(DODEFER)'
dodefer__xt:	local
		;pre_on				; Optional: check break just in case a deferred word has an infinite cycle
		;test	($ff),$08		; Is break pushed?
		;pre_off
		;jpnz	!break__		; Break was pushed
		mv	y,!base_address+3
		add	y,i		
		mv	i,[y]		 	; Set current xt
		pushs	i
		ret				; Jump to defered word
		endl
;-------------------------------------------------------------------------------
does_:		dw	dodefer_
		db	$07
		db	'(DOES>)'		; ( -- addr ; R: xt -- ret )
does__xt:	local
		pushu	ba			; Save TOS
		mv	ba,3			; Compute the
		add	ba,i			; address of the data on TOS
		mv	i,[s]			; The CALL does__xt return short address is the execution token
		ex	i,x			; I is the short old IP
		mv	[s],i			; Save old IP
		mv	i,x			; I is the current execution token
		mv	x,!base_address		; X holds
		add	x,i			; the address of the parameter field
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
sc_code_:	dw	does_
		db	$07
		db	'(;CODE)'		; ( -- )
sc_code__xt:	local
		mv	i,[!lastxt_xt+3]	; I holds the LAST-XT value
		mv	y,!base_address+1	; Y holds the address of the 'jp' operands
		add	y,i			; of the LAST-XT (IP is lost)
		mv	i,x			; I holds the address of the token after (;CODE)
		mv	[y],i			; Compile a 'jp' to the token after (;CODE)
		jp	!doret__xt		; Perform a (DORET)
		endl
;-------------------------------------------------------------------------------
ahead_:		dw	sc_code_
		db	$07
		db	'(AHEAD)'		; ( -- )
ahead__xt:	local
		mv	i,[x++]			; Read the number of bytes to jump
		add	x,i			; Skip forward the specified number of bytes
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
again_:		dw	ahead_
		db	$07
		db	'(AGAIN)'		; ( -- )
again__xt:	local
		mv	i,[x++]			; Read the number of bytes to jump
		sub	x,i			; Skip backward the specified number of bytes
		;jp	!interp__		; Removed to add stack check
		jp	!quest_stack_xt		; Check stack overflow/underflow
		endl
;-------------------------------------------------------------------------------
if_:		dw	again_
		db	$04
		db	'(IF)'			; ( flag -- )
if__xt:		local
		mv	i,[x++]			; Read the number of bytes to jump
		inc	ba			; Test the TOS
		dec	ba			;
		popu	ba			; Set new TOS
		jrnz	lbl1
		add	x,i			; Skip forward the specified number of bytes
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
of_:		dw	if_
		db	$04
		db	'(OF)'			; ( x x -- |x )
of__xt:		local
		popu	i			; I holds the 2OS
		sub	ba,i			; Test if the TOS equals 2OS
		mv	ba,[x++]		; Read the number of bytes to jump
		jrz	lbl2
		add	x,ba			; Skip forward the specified number of bytes
		mv	ba,i			; Set new TOS to old 2OS
lbl1:		jp	!cont__
lbl2:		popu	ba			; Set new TOS
		jr	lbl1
		endl
;-------------------------------------------------------------------------------
until_:		dw	of_
		db	$07
		db	'(UNTIL)'		; ( flag -- )
until__xt:	local
		mv	i,[x++]			; Read the number of bytes to jump
		inc	ba			; Test the TOS
		dec	ba			;
		popu	ba			; Set new TOS
		jpnz	!cont__
		sub	x,i			; Skip backward the specified number of bytes
		;jp	!interp__		; Removed to add stack check
		jp	!quest_stack_xt		; Check stack overflow/underflow
		endl
;-------------------------------------------------------------------------------
do_:		dw	until_
		db	$04
		db	'(DO)'			; ( n|u n|u -- ; R: loop-sys )
do__xt:		popu	i			; I holds the loop limit and BA the initial value
		pushu	ba			; Save the initial value on the parameter stack
		mv	ba,[x++]		; BA holds the LEAVE address (to exit DO statement)
;---------------
do__:		local
		add	ba,x			; The effective LEAVE address is a jump forward
		pushs	ba			; Save the LEAVE address
		mv	ba,$8000		; Perform a 'slice'
		add	i,ba			; of the loop limit
		pushs	i			; Save the 'sliced' loop limit
		popu	ba			; Restore the initial value
		sub	ba,i			; Perform the 'slice' operation on the initial value
		pushs	ba			; Save the initial value
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
quest_do_:	dw	do_
		db	$05
		db	'(?DO)'			; ( n|u n|u -- ; R: loop-sys )
quest_do__xt:	local
		popu	i			; I holds the loop limit and BA the initial value
		pushu	ba			; Save the initial value
		sub	ba,i			; Test if these two values are equal
		mv	ba,[x++]		; BA holds the short LEAVE address (to exit ?DO statement)
		jrnz	!do__			; Execute (DO) if the initial value is not the final value
		;jrz	lbl2
		;add	ba,x			; The effective LEAVE address is a jump forward
		;pushs	ba			; Save the short LEAVE address
		;mv	ba,$8000		; Perform a 'slice'
		;add	i,ba			; on the loop limit
		;pushs	i			; Save the 'sliced' loop limit
		;popu	ba			; Restore the initial value
		;sub	ba,i			; Perform the 'slice' operation on the initial value
		;pushs	ba			; Save the initial value
		;popu	ba			; Set new TOS
		;jr	lbl3
lbl2:		add	x,ba			; Jump forward to the end of the DO statement
		popu	i			; Discard the initial value
		popu	ba			; Set new TOS
lbl3:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
loop_:		dw	quest_do_
		db	$06
		db	'(LOOP)'
loop__xt:	local
		pushu	ba			; Save TOS
		pops	i			; Restore the loop counter's current value
		inc	i			; Increment the loop counter
		mv	ba,$8000		; Test if
		sub	ba,i			; overflow occurred
		mv	ba,[x++]		; Read the number of bytes to jump
		jrz	lbl1
		sub	x,ba			; Jump backward to the beginning of the DO statement
		pushs	i			; Save the new loop counter's value
		popu	ba			; Restore the TOS
		;jp	!interp__		; Removed to add stack check
		jp	!quest_stack_xt		; Check stack overflow/underflow
lbl1:		pops	i			; Discard the loop parameters
		pops	i			; (only the loop limit and LEAVE address are on the stack)
		popu	ba			; Restore the TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
plus_loop_:	dw	loop_
		db	$07
		db	'(+LOOP)'
plus_loop__xt:	local
		mv	i,ba			; Test the
		add	i,i			; sign of the increment
		pops	i			; Restore the loop counter's current value
		jrc	lbl2
		add	ba,i			; Increment the loop counter
		pushs	ba			; Save its value on the stack
		add	ba,ba			; Test the sign of the result
		jrnc	lbl1
		add	i,i			; Test the sign of the previous value
		jrnc	lbl3
lbl1:		mv	ba,[x++]		; Read the number of bytes to jump
		sub	x,ba			; Jump backward to the beginning of the DO statement
		popu	ba			; Set new TOS
		;jp	!interp__		; Removed to add stack check
		jp	!quest_stack_xt		; Check stack overflow/underflow
lbl2:		add	ba,i			; Increment the loop counter with negative BA
		pushs	ba			; Save its value on the stack
		add	ba,ba			; Test the sign of the result
		jrc	lbl1
		add	i,i			; Test the sign of the previous value
		jrnc	lbl1
lbl3:		mv	ba,[x++]		; Discard the number of bytes to jump
		;pops	i			; Discard the loop parameters
		;pops	i			;
		;pops	i			;
		popu	ba			; Set new TOS
		jr	!unloop__xt		; Discard the loop parameters
		;jp	!cont__
		endl
;-------------------------------------------------------------------------------
unloop_:	dw	plus_loop_
		db	$08
		db	'(UNLOOP)'
unloop__xt:	local
		mv	il,6			; Discard
		add	s,il			; the loop parameters
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
leave_:		dw	unloop_
		db	$07
		db	'(LEAVE)'
leave__xt:	local
		pops	i			; Discard the loop parameters
		pops	i			;
		pops	i			; I holds the LEAVE address
		mv	x,!base_address		; Skip up to
		add	x,i			; the end of the DO statement
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
qst_leave_:	dw	leave_
		db	$08
		db	'(?LEAVE)'
qst_leave__xt:	local
		inc	ba			; Test the
		dec	ba			; TOS
		popu	ba			; Set new TOS
		jrnz	!leave__xt		; If TOS is nonzero, leave the loop
		jp	!cont__			; Else continue
		endl
;-------------------------------------------------------------------------------
noop:		dw	qst_leave_
		db	$04
		db	'NOOP'
noop_xt:	local
		jp	!cont__			; Does nothing
		endl
;-------------------------------------------------------------------------------
blnk:		dw	noop
		db	$02
		db	'BL'
blnk_xt:	local
		pushu	ba			; Save the TOS
		mv	ba,32			; Set new TOS to space (ASCII 32)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
align:		dw	blnk
		db	$05
		db	'ALIGN'
align_xt:	local
		jp	!cont__			; Does nothing
		endl
;-------------------------------------------------------------------------------
aligned:	dw	align
		db	$07
		db	'ALIGNED'
aligned_xt:	local
		jp	!cont__			; Does nothing
		endl
;-------------------------------------------------------------------------------
cell_plus:	dw	aligned
		db	$05
		db	'CELL+'
cell_plus_xt:	local
		jp	!two_plus_xt		; Same as 2+
		endl
;-------------------------------------------------------------------------------
cells:		dw	cell_plus
		db	$05
		db	'CELLS'
cells_xt:	local
		jp	!two_star_xt		; Same as 2*
		endl
;-------------------------------------------------------------------------------
cell:		dw	cells
		db	$04
		db	'CELL'
cell_xt:	local
		jp	!dolit2_xt		; Same as 2
		endl
;-------------------------------------------------------------------------------
char_plus:	dw	cell
		db	$05
		db	'CHAR+'
char_plus_xt:	local
		jp	!one_plus_xt		; Same as 1+
		endl
;-------------------------------------------------------------------------------
chars:		dw	char_plus
		db	$05
		db	'CHARS'
chars_xt:	local
		jp	!cont__			; Does nothing
		endl
;-------------------------------------------------------------------------------
store:		dw	chars
		db	$01
		db	'!'
store_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		popu	ba			; BA holds the value to store
		mv	[y],ba			; Store the value in memory
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
fetch:		dw	store
		db	$01
		db	'@'
fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to fetch the value
		mv	ba,[y]			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_store:	dw	fetch
		db	$02
		db	'2!'
two_store_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		popu	ba			; BA holds the 16 high-order bits to store
		mv	[y++],ba		; Store the 16 high-order bits in memory
		popu	ba			; BA holds the 16 low-order bits to store
		mv	[y],ba			; Store the 16 low-order bits in memory
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_fetch:	dw	two_store
		db	$02
		db	'2@'
two_fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to fetch the 16 low-order bits
		mv	ba,[y++]		; Fetch the 16 high-order bits (and set new TOS)
		mv	i,[y]			; Fetch the 16 low-order bits
		pushu	i			; Push the 16 low-order bits
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
c_store:	dw	two_fetch
		db	$02
		db	'C!'
c_store_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		popu	ba			; A holds the character value
		mv	[y],a			; Store the 8 low-order bits in memory
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
c_fetch:	dw	c_store
		db	$02
		db	'C@'
c_fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to fetch the value
		sub	ba,ba			; To clear B register
		mv	a,[y]			; Set new TOS (only the 8 low-order bits are significative)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
comma:		dw	c_fetch
		db	$01
		db	','
comma_xt:	local
		mv	[(!wi)],ba		; Copy TOS to [HERE]
		popu	ba			; Set new TOS
		mv	il,2			; Increment HERE by 2
		jr	!allot__
		endl
;-------------------------------------------------------------------------------
compile_com:	dw	comma
		db	$08
		db	'COMPILE,'
compile_com_xt:	local
		jr	!comma_xt		; Same code as comma in this implementation
		endl
;-------------------------------------------------------------------------------
cfa_comma:	dw	compile_com
		db	$04
		db	'CFA,'
cfa_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	il,$02
		mv	[y++],il		; Compile 'jp' instruction
		mv	[y],ba			; Compile the address of the interpretation routine
		popu	ba			; Set new TOS
		mv	il,3			; Increment HERE by 3
		jr	!allot__
		endl
;-------------------------------------------------------------------------------
does_comma:	dw	cfa_comma
		db	$05
		db	'DOES,'
does_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	il,$04
		mv	[y++],il		; Compile 'call' instruction
		mv	i,!does__xt
		mv	[y],i			; Compile the address of the (DOES>) routine
		mv	il,3			; Increment HERE by 3
		jr	!allot__
		endl
;-------------------------------------------------------------------------------
allot:		dw	does_comma
		db	$05
		db	'ALLOT'			; ( n -- )
allot_xt:	local
		mv	i,ba			; I holds the size to allocate
		popu	ba			; Set new TOS
		endl
;---------------
allot__:	local
		pushu	ba			; Save TOS
		mv	ba,(!wi)		; BA holds HERE short address
		add	ba,i			; New HERE value short address
		jrc	lbl2			; Negative increment or overflow?
		add	i,i			; Check if positive increment
		jrc	lbl3			; Overflow if increment is negative
		mv	i,!dict_limit-!hold_size
		sub	ba,i			; Check overflow
		jrnc	lbl3			; for positive increment
lbl1:		add	ba,i			; Restore new HERE short address
		mv	(!wi),ba		; Save new HERE value
		popu	ba			; Restore TOS
		jp	!cont__			;
lbl2:		add	i,i			; Check if negative increment
		jrnc	lbl3			; Overflow if increment is positive
		mv	i,!_end_		; Check
		sub	ba,i			; if
		jrnc	lbl1			; underflow
lbl3:		mv	il,-8			; Dictionary overflow
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
c_comma:	dw	allot
		db	$02
		db	'C,'
c_comma_xt:	local
		mv	[(!wi)],a		; Store lower-order TOS at HERE
		popu	ba			; Set new TOS
		mv	il,1			; Increment HERE by 1
		jr	!allot__
		endl
;-------------------------------------------------------------------------------
two_comma:	dw	c_comma
		db	$02
		db	'2,'
two_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	[y++],ba		; Store the 16 high-order bits in memory and post-increment Y
		popu	ba
		mv	[y],ba			; Store the 16 low-order bits in memory
		popu	ba			; Set new TOS
		mv	il,4			; Increment HERE by 4
		jr	!allot__
		endl
;-------------------------------------------------------------------------------
fill:		dw	two_comma
		db	$04
		db	'FILL'			; ( c-addr u char -- )
fill_xt:	local
		mv	(!el),a			; Save the 8 low-order bits of the TOS
		popu	i			; I holds the number of bytes to fill
		popu	ba			; BA holds the short address where to fill the bytes
		mv	y,!base_address		; Y holds the address
		add	y,ba			; where to fill the bytes
		mv	a,(!el)			; Restore the char used to fill the bytes
		inc	i
		jr	lbl2
lbl1:		mv	[y++],a			; Fill the bytes
lbl2:		dec	i			; Count the number of bytes to fill
		jrnz	lbl1
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
erase:		dw	fill
		db	$05
		db	'ERASE'			; ( c-addr u -- )
erase_xt:	local
		pushu	ba			; Save TOS
		mv	a,0			; Set TOS char part to zero
		jr	!fill_xt		; FILL
		endl
;-------------------------------------------------------------------------------
blank:		dw	erase
		db	$05
		db	'BLANK'
blank_xt:	local
		pushu	ba			; Save TOS
		mv	a,32			; Set TOS char part to space (ASCII 32)
		jr	!fill_xt		; FILL
		endl
;-------------------------------------------------------------------------------
drop:		dw	blank
		db	$04
		db	'DROP'
drop_xt:	local
		popu	ba			; Discard old TOS an set new one
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_drop:	dw	drop
		db	$05
		db	'2DROP'
two_drop_xt:	local
		popu	ba			; Discard old TOS
		popu	ba			; Discard next value and set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
;fdrop:		dw	two_drop
;		db	$05
;		db	'FDROP'
;fdrop_xt:	local
;		cmp	(!ll),0			; Is the floating point stack empty?
;		jrz	lbl1
;		mv	y,(!xi)			; Y holds FP's value
;		inc	y
;		inc	y
;		inc	y
;		mv	(!xi),y			; Update FP
;		dec	(!ll)			; Update the depth of the stack
;		jp	!cont__
;lbl1:		;pushu	ba			; Save TOS
;		mv	il,-45
;		jp	!throw__
;		;mv	ba,-45			; Floating-point stack underflow
;		;mv	i,!throw_xt
;		;jp	!throw_xt
;		endl
;-------------------------------------------------------------------------------
dup:		dw	two_drop
		db	$03
		db	'DUP'
dup_xt:		local
		pushu	ba			; Save TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_dup:	dw	dup
		db	$04
		db	'2DUP'
two_dup_xt:	local
		mv	i,[u]			; I holds the next value
		pushu	ba			; Push TOS
		pushu	i			; Push next value (BA already contains the TOS)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
quest_dup:	dw	two_dup
		db	$04
		db	'?DUP'
quest_dup_xt:	local
		dec	ba			; Test if
		inc	ba			; TOS is zero
		jrz	lbl1
		pushu	ba			; Duplicate if non-zero
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
;fdup:		dw	quest_dup
;		db	$04
;		db	'FDUP'
;fdup_xt:	local
;		pushs	x			; Save IP
;		cmp	(!ll),0			; Is the floating point stack empty?
;		jrz	lbl3
;		cmp	(!ll),!heap_size	; Is the floating point stack full?
;		jrz	lbl1
;		mv	y,(!xi)			; Y holds FP's value
;		mv	x,[y]			; X holds the top of the floating-point stack
;		mv	[--y],x			; Duplicate it
;		mv	(!xi),y			; Update FP
;		inc	(!ll)			; Update the depth of the stack
;		pops	x			; Restore IP
;		jp	!cont__
;lbl1:		;pushu	ba			; Save TOS
;		mv	il,-44			; Floating-point stack overflow
;		jp	!throw__
;		;mv	ba,-44			; Floating-point stack overflow
;lbl2:		;mv	i,!throw_xt
;		;jp	!throw_xt
;lbl3:		;pushu	ba			; Save TOS
;		mv	il,-45			; Floating-point stack underflow
;		jp	!throw__
;		;mv	ba,-45			; Floating-point stack underflow
;		;jr	lbl2
;		endl
;-------------------------------------------------------------------------------
nip:		dw	quest_dup
		db	$03
		db	'NIP'
nip_xt:		local
		popu	i			; Discard 2OS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_nip:	dw	nip
		db	$04
		db	'2NIP'
two_nip_xt:	local
		popu	i
		popu	y			; Discard second and 3OS (4 bytes)
		popu	f
		pushu	i
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
;fnip:		dw	two_nip
;		db	$04
;		db	'FNIP'
;fnip_xt:	local
;		pushs	x			; Save IP
;		cmp	(!ll),2			; Is there enough elements on the floating point stack?
;		jrc	lbl1
;		mv	y,(!xi)			; Y holds FP's value
;		mv	x,[y++]			; X holds the top of the floating-point stack
;		mv	[y],x			; Discard the next element
;		mv	(!xi),y			; Update FP
;		dec	(!ll)			; Update the depth of the stack
;		pops	x			; Restore IP
;		jp	!cont__
;lbl1:		;pushu	ba			; Save TOS
;		mv	il,-45			; Floating-point stack underflow
;		jp	!throw__
;		;mv	ba,-45			; Floating-point stack underflow
;		;mv	i,!throw_xt
;		;rc
;		;jp	!throw_xt
;		endl
;-------------------------------------------------------------------------------
over:		dw	two_nip
		db	$04
		db	'OVER'
over_xt:	local
		pushu	ba			; Save TOS
		mv	ba,[u+2]		; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_over:	dw	over
		db	$05
		db	'2OVER'
two_over_xt:	local
		pushu	ba			; Save TOS
		mv	ba,[u+6]		; Store the 4OS
		pushu	ba			; Save the 4OS
		mv	ba,[u+6]		; Set new TOS to the old 3OS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
;fover:		dw	two_over
;		db	$05
;		db	'FOVER'
;fover_xt:	local
;		pushs	x			; Save IP
;		cmp	(!ll),2			; Is there enough elements on the floating point stack?
;		jrc	lbl3
;		cmp	(!ll),!heap_size	; Is the floating point stack full?
;		jrz	lbl1
;		mv	y,(!xi)			; Y holds FP's value
;		mv	x,[y+3]			; X holds the 2OS of the floating-point stack
;		mv	[--y],x			; Duplicate it on the top
;		mv	(!xi),y			; Update FP
;		inc	(!ll)			; Update the depth of the stack
;		pops	x			; Restore IP
;		jp	!cont__
;lbl1:		;pushu	ba			; Save TOS
;		mv	il,-44			; Floating-point stack overflow
;		jp	!throw__
;		;mv	ba,-44			; Floating-point stack overflow
;lbl2:		;mv	i,!throw_xt
;		;rc
;		;jp	!throw_xt
;lbl3:		;pushu	ba			; Save TOS
;		mv	il,-45			; Floating-point stack underflow
;		jp	!throw__
;		;mv	ba,-45			; Floating-point stack underflow
;		;jr	lbl2
;		endl
;-------------------------------------------------------------------------------
pick:		dw	two_over
		db	$04
		db	'PICK'
pick_xt:	local
		mv	y,u			; Store SP value
		add	a,a			; Compute the offset (mod 128 to limit 127 cell rolls max)
		add	y,a			; Y holds the address of the value to fetch
		mv	ba,[y]			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
roll:		dw	pick
		db	$04
		db	'ROLL'
roll_xt:	local
		and	a,$7f			; Take TOS (mod 128 to limit 127 cell rolls max), test if zero
		jrnz	lbl1
		popu	ba			; Set new TOS
		jp	!cont__
lbl1:		mv	y,u			; Store SP value
		mv	il,a			; Store the TOS into I
		add	a,a			; Compute the offset
		add	y,a			; Y holds the address of the value to fetch
		mv	ba,[y]			; BA holds the new TOS
		pushu	ba			; Save new TOS into the stack
lbl2:		mv	ba,[--y]		; BA holds the next stack's element
		mv	[y+2],ba		; Replace previous element by BA contents
		dec	il			; Count the number of elements to roll
		jrnz	lbl2
		popu	ba			; Restore new TOS
		popu	i			; Discard the stack's old first element
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
rot:		dw	roll
		db	$03
		db	'ROT'
rot_xt:		local
		popu	i			; Store old 2OS
		pushu	ba			; Set new 2OS to old TOS
		mv	ba,[u+2]		; Set new TOS (old 3OS)
		mv	[u+2],i			; Set new 3OS to old second one
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_rot:	dw	rot
		db	$04
		db	'2ROT'
two_rot_xt:	local
		mv	i,[u+2]			; Store old 3OS
		mv	[u+2],ba		; Replace it with old TOS
		mv	ba,[u+6]		; Store old 5OS
		mv	[u+6],i			; Replace it with old third one
		mv	i,[u]			; Store old 2OS
		pushu	ba			; Save new TOS
		mv	ba,[u+6]		; Store old 4OS
		mv	[u+6],i			; Replace it with old 2OS
		mv	i,[u+10]		; Store old 6OS
		mv	[u+10],ba		; Replace it with old fourth one
		mv	[u+2],i			; Replace old 2OS by old 6OS
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
not_rot:	dw	two_rot
		db	$04
		db	'-ROT'
not_rot_xt:	local
		mv	i,[u+2]			; Store old 3OS
		mv	[u+2],ba		; Set new 3OS to old TOS
		popu	ba			; Set new TOS to old 2OS
		pushu	i			; Set new 2OS to old third one
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
swap:		dw	not_rot
		db	$04
		db	'SWAP'
swap_xt:	local
		popu	i			; Pop next element
		pushu	ba			; Save TOS
		mv	ba,i			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_swap:	dw	swap
		db	$05
		db	'2SWAP'
two_swap_xt:	local
		mv	i,[u+2]			; Store the 3OS
		mv	[u+2],ba		; Exchange TOS and
		pushu	i			; the 3OS and save new TOS
		mv	i,[u+6]			; Store the 4OS
		mv	ba,[u+2]		; Store the 2OS
		mv	[u+6],ba		; Exchange the fourth and
		mv	[u+2],i			; the 2OS
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
tuck:		dw	two_swap
		db	$04
		db	'TUCK'
tuck_xt:	local
		popu	i			; Store the 2OS
		pushu	ba			; Set new 3OS to TOS
		pushu	i			; Set new 2OS to old one
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_tuck:	dw	tuck
		db	$05
		db	'2TUCK'
two_tuck_xt:	local
		popu	i			; Store the 2OS
		popu	y			; Store the third and 4OS
		popu	f
		pushu	i			; Set new 6OS
		pushu	ba			; Set new 5OS to TOS
		pushu	f			; Set new 4OS and 3OS to old ones
		pushu	y
		pushu	i			; Set new 2OS to old one
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
n_to_r:		dw	two_tuck
		db	$03
		db	'N>R'			; ( n*x +n -- ; R: -- n*x +n )
n_to_r_xt:	local
		mv	(!fx),ba		; Save TOS
		and	a,$7f			; A holds TOS (mod 128 to limit to 128 cell moves max)
		jrz	lbl2
lbl1:		popu	i			; Pop value from the stack
		pushs	i			; and push on the return stack
		dec	a			; Decrement A and repeat until zero
		jrnz	lbl1
lbl2:		mv	ba,(!fx)		; Push old TOS on
		pushs	ba			; the return stack
		popu	ba			; Set new TOS
		;jp	!cont__
		jp	!quest_stack_xt		; Check stack overflow/underflow
		endl
;-------------------------------------------------------------------------------
n_r_from:	dw	n_to_r
		db	$03
		db	'NR>'			; ( R: n*x +n -- ;-- n*x +n )
n_r_from_xt:	local
		pushu	ba			; Save the TOS
		pops	ba			; BA holds n
		mv	(!fx),ba		; Save new TOS
		and	a,$7f			; A holds TOS (mod 128 to limit to 128 cell moves max)
		jrz	lbl2
lbl1:		pops	i			; Pop value from the return stack
		pushu	i			; and push on the stack
		dec	a			; Decrement BA and repeat until zero
		jrnz	lbl1
lbl2:		mv	ba,(!fx)		; Set new TOS
		;jp	!cont__
		jp	!quest_stack_xt		; Check stack overflow/underflow
		endl
;-------------------------------------------------------------------------------
to_r:		dw	n_r_from
		db	$02
		db	'>R'
to_r_xt:	local
		pushs	ba			; Save TOS in the return stack
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_to_r:	dw	to_r
		db	$03
		db	'2>R'
two_to_r_xt:	local
		popu	i			; Store 2OS
		pushs	i			; Save it in the return stack
		pushs	ba			; Save old TOS in the return stack
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
r_from:		dw	two_to_r
		db	$02
		db	'R>'
r_from_xt:	local
		pushu	ba
		pops	ba			; Set new TOS to return stack top
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_r_from:	dw	r_from
		db	$03
		db	'2R>'
two_r_from_xt:	local
		pushu	ba
		pops	ba			; Set new TOS to return stack top
		pops	i			; Pop second return stack element
		pushu	i			; Push it into the data stack
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
r_fetch:	dw	two_r_from
		db	$02
		db	'R@'
r_fetch_xt:	local
		pushu	ba
		mv	ba,[s]			; Set new TOS to return stack top
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_r_fetch:	dw	r_fetch
		db	$03
		db	'2R@'
two_r_fetch_xt:	local
		pushu	ba
		mv	ba,[s]			; Set new TOS to return stack top
		mv	i,[s+2]			; Fetch return stack's 2OS
		pushu	i			; Set new 2OS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
r_tick_ftch:	dw	two_r_fetch
		db	$03
		db	'R''@'
r_tick_ftch_xt:	local
		pushu	ba
		mv	ba,[s+2]		; Set new TOS to return stack's 2OS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
r_quot_ftch:	dw	r_tick_ftch
		db	$03
		db	'R"@'
r_quot_ftch_xt:	local
		pushu	ba
		mv	ba,[s+4]		; Set new TOS to return stack's 3OS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
dup_to_r:	dw	r_quot_ftch
		db	$05
		db	'DUP>R'			; ( x -- x ; R: -- x )
dup_to_r_xt:	local
		pushs	ba			; Copy TOS to the return stack
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
r_from_drop:	dw	dup_to_r
		db	$06
		db	'R>DROP'		; ( R: x -- )
r_from_drop_xt:	local
		pops	i			; Remove return stack's first element
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
i:		dw	r_from_drop
		db	$01
		db	'I'			; ( -- n )
i_xt:		local
		pushu	ba			; Save the TOS
		mv	ba,[s]			; Reverse the
		mv	i,[s+2]			; 'slice'
		add	ba,i			; operation (see DO)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
j:		dw	i
		db	$01
		db	'J'			; ( -- n )
j_xt:		local
		pushu	ba			; Save the TOS
		mv	ba,[s+6]		; Reverse the
		mv	i,[s+8]			; 'slice'
		add	ba,i			; operation (see DO)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
k:		dw	j
		db	$01
		db	'K'			; ( -- n )
k_xt:		local
		pushu	ba			; Save the TOS
		mv	ba,[s+12]		; Reverse the
		mv	i,[s+14]		; 'slice'
		add	ba,i			; operation (see DO)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
execute:	dw	k
		db	$07
		db	'EXECUTE'		; ( ... xt -- ... )
execute_xt:	local
		pushs	ba			; Push the current xt into the return stack
		mv	i,ba			; Set current xt
		popu	ba			; Set new TOS
		ret				; Execute the xt
		endl
;-------------------------------------------------------------------------------
and:		dw	execute
		db	$03
		db	'AND'			; ( u u -- u )
and_xt:		local
		mv	(!fx),ba		; Save TOS
		popu	ba			; Pop 2OS
		and	a,(!fl)
		ex	a,b
		and	a,(!fh)
		ex	a,b			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
or:		dw	and
		db	$02
		db	'OR'			; ( u u -- u )
or_xt:		local
		mv	(!fx),ba		; Save TOS
		popu	ba			; Pop 2OS
		or	a,(!fl)
		ex	a,b
		or	a,(!fh)
		ex	a,b			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
xor:		dw	or
		db	$03
		db	'XOR'			; ( u u -- u )
xor_xt:		local
		mv	(!fx),ba		; Save TOS
		popu	ba			; Pop 2OS
		xor	a,(!fl)
		ex	a,b
		xor	a,(!fh)
		ex	a,b			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
invert:		dw	xor
		db	$06
		db	'INVERT'		; ( u -- u )
invert_xt:	local
		mv	i,$ffff
		sub	i,ba
		mv	ba,i
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
equals:		dw	invert
		db	$01
		db	'='			; ( x x -- flag )
equals_xt:	local
		popu	i			; Pop 2OS
		sub	ba,i			; Compare it with TOS
		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
zero_equals:	dw	equals
		db	$02
		db	'0='
zero_equals_xt:	local
		inc	ba
		dec	ba
		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_equals:	dw	zero_equals
		db	$02
		db	'D='
d_equals_xt:	local
		mv	i,[u+2]			; I holds first operand's 16 high-order bits
		sub	i,ba			; Compare high-order bits
		popu	ba			; BA holds second operand's 16 low-order bits
		popu	i			; Discard first operand's 16 high-order bits
		popu	i			; I holds first operand's 16 low-order bits
		jrnz	lbl1			; Jump if high-order bits differ
		sub	i,ba			; Compare low-order bits
lbl1:		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl2			; Jump if low-order bits differ
		dec	ba			; Set new TOS to TRUE
lbl2:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_zero_equ:	dw	d_equals
		db	$03
		db	'D0='
d_zero_equ_xt:	local
		popu	i			; I holds operand's 16 low-order bits
		inc	ba
		dec	ba
		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1			; Jump if high-order bits are not zero
		sub	i,ba			; Compare I to zero
		jrnz	lbl1			; Jump if low-order bits are not zero
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
not_equals:	dw	d_zero_equ
		db	$02
		db	'<>'
not_equals_xt:	local
		popu	i			; Pop 2OS
		sub	ba,i			; Compare it with TOS
		mv	ba,-1			; Set new TOS to TRUE
		jrnz	lbl1
		inc	ba			; Set new TOS to FALSE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
zer_not_equ:	dw	not_equals
		db	$03
		db	'0<>'
zer_not_equ_xt:	local
		inc	ba
		dec	ba
		mv	ba,-1			; Set new TOS to TRUE
		jrnz	lbl1
		inc	ba			; Set new TOS to FALSE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_not_equ:	dw	zer_not_equ
		db	$03
		db	'D<>'
d_not_equ_xt:	local
		mv	i,[u+2]			; I holds first operand's 16 high-order bits
		sub	i,ba			; Compare high-order bits
		popu	ba			; BA holds second operand's 16 low-order bits
		popu	i			; Discard first operand's 16 high-order bits
		popu	i			; I holds first operand's 16 low-order bits
		jrnz	lbl1			; Jump if high-order bits differ
		sub	i,ba			; Compare low-order bits
lbl1:		mv	ba,-1			; Set new TOS to TRUE
		jrnz	lbl2			; Jump if low-order bits differ
		inc	ba			; Set new TOS to FALSE
lbl2:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_z_not_eq:	dw	d_not_equ
		db	$04
		db	'D0<>'
d_z_not_eq_xt:	local
		popu	i			; I holds operand's 16 low-order bits
		inc	ba
		dec	ba
		mv	ba,-1			; Set new TOS to TRUE
		jrnz	lbl1			; Jump if high-order bits are not zero
		inc	i
		dec	i
		jrnz	lbl1			; Jump if low-order bits are not zero
		inc	ba			; Set new TOS to FALSE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
less_than:	dw	d_z_not_eq
		db	$01
		db	'<'
less_than_xt:	local
		popu	i
		add	i,i			; Is 2OS negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	i,ba			; Compare two positive left-shifted numbers
		jrc	lbl5
lbl2:		sub	ba,ba
		jr	lbl6
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
lbl5:		mv	ba,-1			; Set new TOS to TRUE
lbl6:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
zer_lss_thn:	dw	less_than
		db	$02
		db	'0<'
zer_lss_thn_xt:	local
		add	ba,ba			; Is TOS negative?
		mv	ba,0			; Set new TOS to FALSE
		jrnc	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
u_less_than:	dw	zer_lss_thn
		db	$02
		db	'U<'
u_less_than_xt:	local
		popu	i			; Pop 2OS
		sub	i,ba			; Compare it with TOS
		mv	ba,0			; Set new TOS to FALSE
		jrnc	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_less_than:	dw	u_less_than
		db	$02
		db	'D<'
d_less_than_xt:	local
		mvw	(!fx),[u++]
		popu	i
		mvw	(!gx),[u++]
		add	i,i			; Is 2OS negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	i,ba			; Compare two positive left-shifted numbers
		jrc	lbl5
		jrnz	lbl2
		mv	i,(!gx)
		mv	ba,(!fx)
		sub	i,ba			; Compare the 16 low-order bits
		jrc	lbl5
lbl2:		sub	ba,ba			; Set new TOS to FALSE
		jr	lbl6
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
lbl5:		mv	ba,-1			; Set new TOS to TRUE
lbl6:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_zer_l_thn:	dw	d_less_than
		db	$03
		db	'D0<'
d_zer_l_thn_xt:	local
		popu	i			; Discard the 16 low-order bits
		add	ba,ba			; Is TOS negative?
		mv	ba,0			; Set new TOS to FALSE
		jrnc	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_u_l_than:	dw	d_zer_l_thn
		db	$03
		db	'DU<'
d_u_l_than_xt:	local
		mvw	(!fx),[u++]
		popu	i
		mvw	(!gx),[u++]
		sub	i,ba			; Compare the 16 high-order bits
		jrc	lbl2
		jrnz	lbl1
		mv	ba,(!fx)
		mv	i,(!gx)
		sub	i,ba			; Compare the 16 low-order bits
		jrc	lbl2
lbl1:		sub	ba,ba			; Set new TOS to FALSE
		jr	lbl3
lbl2:		mv	ba,-1			; Set new TOS to TRUE
lbl3:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
greatr_than:	dw	d_u_l_than
		db	$01
		db	'>'
greatr_than_xt:	local
		popu	i
		add	i,i			; Is 2OS negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	ba,i			; Compare two positive left-shifted numbers
		jrnc	lbl5
lbl2:		mv	ba,-1			; Set new TOS to TRUE
		jr	lbl6
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
lbl5:		sub	ba,ba			; Set new TOS to FALSE
lbl6:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
zer_grt_thn:	dw	greatr_than
		db	$02
		db	'0>'
zer_grt_thn_xt:	local
		add	ba,ba			; Is TOS negative?
		mv	ba,0			; Set new TOS to FALSE
		jrc	lbl1
		jrz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
u_grtr_than:	dw	zer_grt_thn
		db	$02
		db	'U>'
u_grtr_than_xt:	local
		popu	i			; Pop 2OS
		sub	ba,i			; Compare it with TOS
		mv	ba,0			; Set new TOS to FALSE
		jrnc	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_grtr_than:	dw	u_grtr_than
		db	$02
		db	'D>'
d_grtr_than_xt:	local
		mvw	(!fx),[u++]
		popu	i
		mvw	(!gx),[u++]
		add	i,i			; Is 2OS negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	i,ba			; Compare two positive left-shifted numbers
		jrc	lbl5
		jrnz	lbl2
		mv	i,(!gx)
		mv	ba,(!fx)
		sub	i,ba			; Compare the 16 low-order bits
		jrc	lbl5
		jrz	lbl5
lbl2:		mv	ba,-1			; Set new TOS to TRUE
		jr	lbl6
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
lbl5:		sub	ba,ba			; Set new TOS to FALSE
lbl6:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_zer_g_thn:	dw	d_grtr_than
		db	$03
		db	'D0>'
d_zer_g_thn_xt:	local
		popu	i			; I holds the 16 low-order bits
		add	ba,ba			; Is TOS negative?
		mv	ba,0			; Set new TOS to FALSE
		jrc	lbl2
		jrnz	lbl1
		inc	i			; Test whether the
		dec	i			; low-order bits are zero or not
		jrz	lbl2
lbl1:		dec	ba			; Set new TOS to TRUE
lbl2:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_u_g_than:	dw	d_zer_g_thn
		db	$03
		db	'DU>'
d_u_g_than_xt:	local
		mvw	(!fx),[u++]
		popu	i
		mvw	(!gx),[u++]
		sub	ba,i			; Compare the 16 high-order bits
		jrc	lbl2
		jrnz	lbl1
		mv	ba,(!fx)
		mv	i,(!gx)
		sub	ba,i			; Compare the 16 low-order bits
		jrc	lbl2
lbl1:		sub	ba,ba			; Set new TOS to FALSE
		jr	lbl3
lbl2:		mv	ba,-1			; Set new TOS to TRUE
lbl3:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
within:		dw	d_u_g_than
		db	$06
		db	'WITHIN'		; ( test low high -- flag )
within_xt:	local
		popu	i			; I holds low
		sub	ba,i			; BA holds high-low
		mv	(!fl),ba		; Save BA high-low
		popu	ba			; BA holds test
		sub	ba,i			; BA holds test-low
		mv	i,(!fl)			; I holds high-low
		sub	ba,i			; Check test-low U< high-low
		mv	ba,-1			; Set TOS to TRUE
		jrc	lbl1			; Is test-low U< high-low?
		inc	ba			; Set TOS to FALSE
lbl1:		jp	!cont__
;		jp	!docol__xt		; : WITHIN ( test low high -- flag )
;		dw	!over_xt		;   OVER
;		dw	!minus_xt		;   -
;		dw	!to_r_xt		;   >R
;		dw	!minus_xt		;   -
;		dw	!r_from_xt		;   R>
;		dw	!u_less_than_xt		;   U<
;		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
s_to_d:		dw	within
		db	$03
		db	'S>D'
s_to_d_xt:	local
		pushu	ba			; Save TOS
		add	ba,ba			; Check if TOS is negative
		mv	ba,0			; TOS is positive
		jrnc	lbl1
		dec	ba			; TOS is negative
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_to_s:		dw	s_to_d
		db	$03
		db	'D>S'
d_to_s_xt:	local
		inc	ba
		jrz	lbl1			; Check if TOS is $ffff
		dec	ba			; Check if TOS is $0000
		jrnz	lbl2			; The double precision number is too large
lbl1:		popu	ba
		jp	!cont__
lbl2:		mv	il,-11			; Result out of range
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
negate:		dw	d_to_s
		db	$06
		db	'NEGATE'
negate_xt:	local
		mv	il,0
		sub	i,ba
		mv	ba,i
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_negate:	dw	negate
		db	$07
		db	'DNEGATE'
d_negate_xt:	local
		mv	(!fx),ba		; Save the TOS with 16 high-order bits
		popu	ba			; BA holds the 16 low-order bits
		mv	il,0			; Set new 2OS
		sub	i,ba			; to the negative
		pushu	i			; of old 2OS
		mv	ba,0			;
		adc	(!fl),a			; Set new TOS
		adc	(!fh),a			; to the negative
		mv	i,(!fx)			; of old TOS
		sub	ba,i			; minus carry
		jp	!cont__

;		mv	il,0			; Negate the 16 high-order bits before
;		sub	i,ba			;
;		mv	(!fx),i			; Save the result
;		popu	ba			; Negate the 16
;		mv	il,0			; lower-bits
;		sub	i,ba			;
;		pushu	i			; Save them on the stack
;		mv	ba,(!fx)		; Restore the 16 high-order bits
;		jrnc	lbl1			; Test if they must be adjusted
;		dec	ba
;lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
abs:		dw	d_negate
		db	$03
		db	'ABS'
abs_xt:		local
		mv	i,ba
		add	i,i			; Check if TOS is negative
		jrc	!negate_xt		; Negate if TOS is negative
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_abs:		dw	abs
		db	$04
		db	'DABS'
d_abs_xt:	local
		mv	i,ba
		add	i,i			; Test the sign
		jrc	!d_negate_xt
;		jrnc	lbl1
;		mv	il,$00			; Negate the 16 high-order bits before
;		sub	i,ba			;
;		mv	(!fx),i			; Save the result
;		popu	ba			; Negate the 16
;		mv	il,$00			; lower-bits
;		sub	i,ba			;
;		pushu	i			; Save them on the stack
;		mv	ba,(!fx)		; Restore the 16 high-order bits
;		jrnc	lbl1			; Test if they must be adjusted
;		dec	ba
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
max:		dw	d_abs
		db	$03
		db	'MAX'
max_xt:		local
		jp	!docol__xt		; : MAX ( n1 n2 -- n3 )
		dw	!two_dup_xt		;   2DUP
		dw	!less_than_xt		;   <
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt	;     SWAP THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
u_max:		dw	max
		db	$04
		db	'UMAX'
u_max_xt:	local
		jp	!docol__xt		; : UMAX ( u1 u2 -- u3 )
		dw	!two_dup_xt		;   2DUP
		dw	!u_less_than_xt		;   U<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt	;     SWAP THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!doret__xt		;
		endl
;-------------------------------------------------------------------------------
d_max:		dw	u_max
		db	$04
		db	'DMAX'
d_max_xt:	local
		jp	!docol__xt		; : DMAX ( d1 d2 -- d3 )
		dw	!two_over_xt		;   2OVER
		dw	!two_over_xt		;   2OVER
		dw	!d_less_than_xt		;   D<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!two_swap_xt	;     2SWAP THEN
lbl2:		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
min:		dw	d_max
		db	$03
		db	'MIN'
min_xt:		local
		jp	!docol__xt		; : MIN ( n1 n2 -- n3 )
		dw	!two_dup_xt		;   2DUP
		dw	!greatr_than_xt		;   >
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt	;     SWAP THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
u_min:		dw	min
		db	$04
		db	'UMIN'
u_min_xt:	local
		jp	!docol__xt		; : UMIN ( u1 u2 -- u3 )
		dw	!two_dup_xt		;   2DUP
		dw	!u_grtr_than_xt		;   U>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt	;     SWAP THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
d_min:		dw	u_min
		db	$04
		db	'DMIN'
d_min_xt:	local
		jp	!docol__xt		; : DMIN ( d1 d2 -- d3 )
		dw	!two_over_xt		;   2OVER
		dw	!two_over_xt		;   2OVER
		dw	!d_grtr_than_xt		;   D>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!two_swap_xt	;     2SWAP THEN
lbl2:		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
two_star:	dw	d_min
		db	$02
		db	'2*'
two_star_xt:	local
		add	ba,ba			; Double (left bit-shift) TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_two_star:	dw	two_star
		db	$03
		db	'D2*'
d_two_star_xt:	local
		add	ba,ba			; Double (left bit-shift) the 16 high-order bits
		popu	i			; I holds the 16 low-order bits
		add	i,i			; Double the 16 low-order bits
		pushu	i
		adc	a,0			; Update the least significant bit of the 16 high-order bits in case of carry
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
lshift:		dw	d_two_star
		db	$06
		db	'LSHIFT'
lshift_xt:	local
		mv	il,a			; Bit count, ignore the bigh-order 8 bits
		popu	ba
		inc	il
		jr	lbl2
lbl1:		add	ba,ba			; Left shift the bits
lbl2:		dec	il
		jrnz	lbl1
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_slash:	dw	lshift
		db	$02
		db	'2/'
two_slash_xt:	local
		ex	a,b
		mv	il,a			; Copy sign bit
		add	il,il			; to the carry flag
		shr	a			; Right bit-shift 8 high-order bits
		ex	a,b
		shr	a			; Right bit-shift 8 low-order bits
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_two_slash:	dw	two_slash
		db	$03
		db	'D2/'
d_two_slash_xt:	local
		ex	a,b
		mv	il,a			; Copy sign bit
		add	il,il			; to the carry flag
		shr	a			; Right bit-shift 8 high-order bits
		ex	a,b
		shr	a			; Right bit-shift 8 low-order bits
		mv	i,ba
		popu	ba
		ex	a,b
		shr	a			; Right bit-shift 8 high-order bits
		ex	a,b
		shr	a			; Right bit-shift 8 low-order bits
		pushu	ba
		mv	ba,i
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
rshift:		dw	d_two_slash
		db	$06
		db	'RSHIFT'
rshift_xt:	local
		popu	i
		mv	(!fx),i
		inc	a			; Ignore the 8 high-order bits
		jr	lbl2
lbl1:		rc
		shr	(!fh)			; Right shift
		shr	(!fl)			; the bits
lbl2:		dec	a
		jrnz	lbl1
		mv	ba,(!fx)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
plus:		dw	rshift
		db	$01
		db	'+'
plus_xt:	local
		popu	i
		add	ba,i
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
one_plus:	dw	plus
		db	$02
		db	'1+'
one_plus_xt:	local
		inc	ba
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_plus:	dw	one_plus
		db	$02
		db	'2+'
two_plus_xt:	local
		inc	ba
		inc	ba
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
plus_store:	dw	two_plus
		db	$02
		db	'+!'
plus_store_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		popu	ba			; BA holds the value to add
		endl
;---------------
plus_store__:	local
		mv	i,[y]			; I holds the old value
		add	ba,i			; BA holds the new value
		mv	[y],ba			; Store the new value
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_plus_stor:	dw	plus_store
		db	$03
		db	'D+!'			; ( d addr -- )
d_plus_stor_xt:	local
		mv	y,!base_address+2
		add	y,ba			; Y holds the address + 2 (low order) where to store the value
		popu	ba			; BA holds the high-order bits to add
		endl
;---------------
d_plus_store__:	local
		mv	(!fx),ba		; Save high-order bits to add
		popu	i			; I holds the low-order bits to add
		mv	ba,[y]			; BA holds the old low-order bits
		add	ba,i			; BA holds the new low-order bits
		mv	[y],ba
		mv	ba,[--y]		; BA holds the old high-order bits
		adc	a,(!fl)			; Add old high-order bits
		ex	a,b			; with carry
		adc	a,(!fh)			; to new
		ex	a,b			; high-order bits
		mv	[y],ba
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
doplusto_:	dw	d_plus_stor
		db	$05
		db	'(+TO)'
doplusto__xt:	local
		mv	i,[x++]			; Read the short address of the value
		mv	y,!base_address		; Y holds the
		add	y,i			; address of the value
		jr	!plus_store__
		endl
;-------------------------------------------------------------------------------
dodplus2to_:	dw	doplusto_
		db	$07
		db	'(D+2TO)'
dodplus2to__xt:	local
		mv	i,[x++]			; Read the short address of the value
		mv	y,!base_address+2	; Y holds the
		add	y,i			; address of the low-order bits
		jr	!d_plus_store__
		endl
;-------------------------------------------------------------------------------
d_plus:		dw	dodplus2to_
		db	$02
		db	'D+'
d_plus_xt:	local
		mv	(!fx),ba		; Save the TOS
		popu	i
		popu	ba
		mv	(!gx),ba		; Save the 3OS
		popu	ba
		add	ba,i			; Add 2OS to 4OS
		pushu	ba			; Save the new 2OS 16 low-order bits
		mv	ba,(!gx)		; Restore TOS
		adc	a,(!fl)			; Add TOS
		ex	a,b			; to the 3OS
		adc	a,(!fh)			; with carry
		ex	a,b			; as new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
m_plus:		dw	d_plus
		db	$02
		db	'M+'
m_plus_xt:	local
		jp	!docol__xt		; : M+ ( d n -- d )
		dw	!s_to_d_xt		;   S>D
		dw	!d_plus_xt		;   D+
		dw	!doret__xt		; ;
;		popu	i
;		mv	(!fx),i
;		mv	i,ba
;		add	i,i
;		jrc	lbl3
;		popu	i
;		add	i,ba
;		pushu	i
;		mv	ba,(!fx)
;		jrnc	lbl2
;		inc	ba
;lbl2:		jr	lbl4
;lbl3:		popu	i
;		add	i,ba
;		pushu	i
;		mv	ba,(!fx)
;		jrc	lbl2
;		dec	ba
;lbl4:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
minus:		dw	m_plus
		db	$01
		db	'-'
minus_xt:	local
		popu	i
		sub	i,ba
		mv	ba,i
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
one_minus:	dw	minus
		db	$02
		db	'1-'
one_minus_xt:	local
		dec	ba
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_minus:	dw	one_minus
		db	$02
		db	'2-'
two_minus_xt:	local
		dec	ba
		dec	ba
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_minus:	dw	two_minus
		db	$02
		db	'D-'
d_minus_xt:	local
		mv	(!fx),ba		; Save the TOS
		popu	i
		popu	ba
		mv	(!gx),ba		; Save the 3OS
		popu	ba
		sub	ba,i			; Subtract 2OS from 4OS
		pushu	ba			; Set new 2OS
		mv	ba,(!gx)		; Restore 3OS
		sbc	a,(!fl)			; Substract
		ex	a,b			; the TOS
		sbc	a,(!fh)			; from 3OS with carry
		ex	a,b			; as new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
m_minus:	dw	d_minus
		db	$02
		db	'M-'
m_minus_xt:	local
		jp	!docol__xt		; : M- ( d n -- d )
		dw	!s_to_d_xt		;   S>D
		dw	!d_minus_xt		;   D-
		dw	!doret__xt		; ;
;		popu	i
;		mv	(!fx),i
;		mv	i,ba
;		add	i,i
;		jrc	lbl3
;		popu	i
;		sub	i,ba
;		pushu	i
;		mv	ba,(!fx)
;		jrnc	lbl2
;		dec	ba
;;lbl1:		rc
;lbl2:		jr	lbl4
;lbl3:		popu	i
;		sub	i,ba
;		pushu	i
;		mv	ba,(!fx)
;		jrc	lbl2
;		inc	ba
;lbl4:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
star:		dw	m_minus
		db	$01
		db	'*'
star_xt:	local
		popu	i
		mv	(!el),$80		; Initialize counter
		mv	(!fx),ba		; Save old TOS
		sub	ba,ba			; Initialize result
lbl1:		shr	(!fl)			; Is right-most bit 1 or 0?
		jrnc	lbl2
		add	ba,i			; Add first operand to partial result
lbl2:		add	i,i			; Left shift first operand 
		ror	(!el)			; Better than dec (no initialization required to reuse)
		jrnc	lbl1
lbl3:		shr	(!fh)			; The same with 8 high-order bits
		jrnc	lbl4
		add	ba,i
lbl4:		add	i,i
		ror	(!el)
		jrnc	lbl3
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
d_star:		dw	star
		db	$02
		db	'D*'
d_star_xt:	local
		mv	(!el),$80		; Initialize counter
		mv	(!gx),ba		; Save old TOS
		mvw	(!fx),[u++]
		mvw	(!ix),[u++]
		mvw	(!hx),[u++]
		mvw	(!jx),$0000		; Initialize
		mvw	(!kx),$0000		; result
lbl1:		shr	(!fl)			; Is right-most bit 1 or 0?
		jrnc	lbl2
		mv	il,4
		adcl	(!jx),(!hx)		; Add first operand to partial result
lbl2:		mv	il,4
		adcl	(!hx),(!hx)		; Left shift first operand 
		ror	(!el)			; Better than dec (no initialization required to reuse)
		jrnc	lbl1
lbl3:		shr	(!fh)			; The same with 8 high-order bits
		jrnc	lbl4
		mv	il,4
		adcl	(!jx),(!hx)
lbl4:		mv	il,4
		adcl	(!hx),(!hx)
		ror	(!el)
		jrnc	lbl3
lbl5:		shr	(!gl)
		jrnc	lbl6
		mv	il,4
		adcl	(!jx),(!hx)
lbl6:		mv	il,4
		adcl	(!hx),(!hx)
		ror	(!el)
		jrnc	lbl5
lbl7:		shr	(!gh)
		jrnc	lbl8
		mv	il,4
		adcl	(!jx),(!hx)
lbl8:		mv	il,4
		adcl	(!hx),(!hx)
		ror	(!el)
		jrnc	lbl7
		mvw	[--u],(!jx)
		mv	ba,(!kx)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
slash_mod:	dw	d_star
		db	$04
		db	'/MOD'
slash_mod_xt:	local
		mv	(!eh),$00		; The sign of the modulo (bit 0) and the sign of the quotient (bit 1)
		mv	i,ba			; Copy old TOS (the second argument)
		inc	ba			; Test if
		dec	ba			; the divisor
		jrz	lbl7			; is zero
		add	ba,ba			; Test the sign of the divisor
		jrnc	lbl1
		mv	(!eh),$02		; The quotient may be negative
		sub	ba,ba			; Negate
		sub	ba,i			; the divisor
		mv	i,ba
lbl1:		mv	(!gx),i			; Save the divisor
		popu	i			; Restore the dividend
		mv	ba,i			; Make a copy of it
		add	i,i			; Test the sign of the dividend
		jrnc	lbl2
		xor	(!eh),$03		; The modulo has the same sign as the dividend
		mv	il,0			; Negate
		sub	i,ba			; the dividend
		mv	ba,i
lbl2:		mv	(!fx),ba		; Save the dividend
		mv	(!el),0
		mv	ba,(!gx)		; Restore the divisor
lbl3:		mv	(!gx),ba		; Left-shift
		add	ba,ba			; the divisor
		inc	(!el)			; until it becomes
		cmpw	(!fx),ba		; greater than the dividend (and save previous result)
		jrnc	lbl3
		sub	ba,ba			; BA holds the absolute value of the result of the division
lbl4:		add	ba,ba			; Left-shift the intermediate result
		cmpw	(!fx),(!gx)		; Test if the next bit of the result is 0 or 1
		jrc	lbl5
		inc	ba			; Set next bit of the result to 1
		mv	il,2			; Subtract
		sbcl	(!fx),(!gx)		; an entire part of the divisor from the dividend
lbl5:		rc
		shr	(!gh)			; Right-shift the
		shr	(!gl)			; divisor
		dec	(!el)			; Test if all the bits have been computed
		jrnz	lbl4
		mv	i,(!fx)			; Store the modulo
		test	(!eh),$01		; Test the sign of the modulo
		jrz	lbl6
		pushu	ba			; Save BA register (the quotient of the division)
		sub	ba,ba			; Negate
		sub	ba,i			; the modulo
		mv	i,ba
		popu	ba			; Restore the quotient of the division
lbl6:		pushu	i			; Save the modulo
		test	(!eh),$02		; Test the sign of the quotient
		jpnz	!negate_xt		; Negate the TOS
		jp	!cont__
lbl7:		mv	il,-10			; Division by zero
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
slash:		dw	slash_mod
		db	$01
		db	'/'
slash_xt:	local
		jp	!docol__xt		; : / ( n1 n2 -- n3 )
		dw	!slash_mod_xt		;   /MOD
		dw	!nip_xt			;   NIP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
mod:		dw	slash
		db	$03
		db	'MOD'
mod_xt:		local
		jp	!docol__xt		; : MOD ( n1 n2 -- n3 )
		dw	!slash_mod_xt		;   /MOD
		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
d_slash_mod:	dw	mod
		db	$05
		db	'D/MOD'
d_slash_mod_xt:	local
		mv	(!eh),$00		; The sign of the modulo (bit 0) and the sign of the quotient (bit 1)
		mv	(!ix),ba		; Save
		popu	i			; the
		mv	(!hx),i			; divisor
		mvw	(!gx),[u++]		; Save the
		mvw	(!fx),[u++]		; dividend
		inc	ba			; Test
		dec	ba			; if
		jrnz	lbl1			; the
		inc	i			; divisor
		dec	i			; is
		jrz	lbl12			; zero
lbl1:		test	(!ih),$80		; Test the sign of the divisor
		jrz	lbl2
		mv	(!eh),$02		; The quotient may be negative
		mvw	(!jx),$0000		; Negate
		mvw	(!kx),$0000		; the
		mv	il,4			; divisor
		sbcl	(!jx),(!hx)		;
		mv	il,4			;
		mvl	(!hx),(!jx)		;
lbl2:		test	(!gh),$80		; Test the sign of the dividend
		jrz	lbl3
		xor	(!eh),$03		; The modulo has the same sign as the dividend
		mvw	(!jx),$0000		; Negate
		mvw	(!kx),$0000		; the
		mv	il,4			; dividend
		sbcl	(!jx),(!fx)		;
		mv	il,4			;
		mvl	(!fx),(!jx)		;
lbl3:		mv	(!el),0
		mv	il,4			; Restore
		mvl	(!jx),(!hx)		; the divisor
lbl4:		mv	il,4			; Left-shift
		mvl	(!hx),(!jx)		; the
		rc				; divisor
		shl	(!jl)			; until
		shl	(!jh)			; it becomes
		shl	(!kl)			; greater
		shl	(!kh)			; than
		inc	(!el)			; the
		cmpw	(!gx),(!kx)		; dividend
		jrc	lbl5			; (and
		jrnz	lbl4			; save
		cmpw	(!fx),(!jx)		; previous
		jrnc	lbl4			; result)
lbl5:		mvw	(!jx),$0000		; (jx) holds the 16 low-order bits of the absolute value of the
		mvw	(!kx),$0000		; result of the division while (kx) holds the 16 high-order ones
lbl6:		rc				; Left-shift
		shl	(!jl)			; the
		shl	(!jh)			; intermediate
		shl	(!kl)			; result
		shl	(!kh)			;
		cmpw	(!gx),(!ix)		; Test if
		jrc	lbl8			; the next bit
		jrnz	lbl7			; of the result
		cmpw	(!fx),(!hx)		; is 0 or 1
		jrc	lbl8
lbl7:		inc	(!jl)			; Set next bit of the result to 1
		mv	il,4			; Subtract an entire part
		sbcl	(!fx),(!hx)		; of the divisor from the dividend
lbl8:		rc				; Right-shift
		shr	(!ih)			; the
		shr	(!il)			; divisor
		shr	(!hh)			;
		shr	(!hl)			;
		dec	(!el)			; Test if all the bits have been computed
		jrnz	lbl6
		test	(!eh),$01		; Test the sign of the modulo
		jrz	lbl9
		mvw	(!hx),$0000		; Negate
		mvw	(!ix),$0000		; the
		mv	il,4			; modulo
		sbcl	(!hx),(!fx)		;
		mvw	[--u],(!hx)		; Save the negated
		mvw	[--u],(!ix)		; modulo on the stack
		jr	lbl10
lbl9:		mvw	[--u],(!fx)		; Save the modulo
		mvw	[--u],(!gx)		; on the stack
lbl10:		test	(!eh),$02		; Test the sign of the quotient
		jrz	lbl11
		mvw	(!hx),$0000		; Negate
		mvw	(!ix),$0000		; the
		mv	il,4			; quotient
		sbcl	(!hx),(!jx)		;
		mvw	[--u],(!hx)		; Save the negated
		mv	ba,(!ix)		; quotient
		jp	!cont__
lbl11:		mvw	[--u],(!jx)		; Save the quotient
		mv	ba,(!kx)
		jp	!cont__
lbl12:		mv	il,-10			; Division by zero
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
d_slash:	dw	d_slash_mod
		db	$02
		db	'D/'
d_slash_xt:	local
		jp	!docol__xt		; : D/ ( d1 d2 -- d3 )
		dw	!d_slash_mod_xt		;   D/MOD
		dw	!two_nip_xt		;   2NIP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
d_mod:		dw	d_slash
		db	$04
		db	'DMOD'
d_mod_xt:	local
		jp	!docol__xt		; : DMOD ( d1 d2 -- d3 )
		dw	!d_slash_mod_xt		;   D/MOD
		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
u_m_d_star:	dw	d_mod
		db	$04
		db	'UMD*'			; ( ud u -- ud )
u_m_d_star_xt:	local
		mv	(!el),$80		; Initialize counter
		mvw	(!gx),[u++]		; Save first argument
		mvw	(!fx),[u++]		; as an unsigned double
		mvw	(!jx),$0000		; Initialize
		mvw	(!kx),$0000		; result
lbl1:		shr	a			; Is right-most bit 1 or 0?
		jrnc	lbl2
		mv	il,4
		adcl	(!jx),(!fx)		; Add first operand to partial result
lbl2:		mv	il,4
		adcl	(!fx),(!fx)		; Left shift first operand 
		ror	(!el)			; Better than dec (no initialization required to reuse)
		jrnc	lbl1
		ex	a,b
lbl3:		shr	a			; The same with 8 high-order bits
		jrnc	lbl4
		mv	il,4
		adcl	(!jx),(!fx)
lbl4:		mv	il,4
		adcl	(!fx),(!fx)
		ror	(!el)
		jrnc	lbl3
		mvw	[--u],(!jx)
		mv	ba,(!kx)
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
u_m_star:	dw	u_m_d_star
		db	$03
		db	'UM*'
u_m_star_xt:	local
		jp	!docol__xt		; : UM* ( u u -- ud )
		dw	!dolit0_xt		;   0
		dw	!rot_xt			;   ROT
		dw	!u_m_d_star_xt		;   UMD*
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
m_star:		dw	u_m_star
		db	$02
		db	'M*'
m_star_xt:	local
		jp	!docol__xt		; : M* ( n1 n2 -- ud )
		dw	!s_to_d_xt		;   S>D
		dw	!rot_xt			;   ROT
		dw	!dup_to_r_xt		;   DUP>R
		dw	!abs_xt			;   ABS
		dw	!u_m_d_star_xt		;   UMD*
		dw	!r_from_xt		;   R>
		dw	!zer_lss_thn_xt		;   0<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!d_negate_xt	;     NEGATE THEN
lbl2:		dw	!doret__xt		;   ;
		endl
;-------------------------------------------------------------------------------
u_m_sl_mod:	dw	m_star
		db	$06
		db	'UM/MOD'
u_m_sl_mod_xt:	local
		mv	(!hx),ba		; Save the TOS as the divisor
		mvw	(!gx),[u++]		; Save dividend's 16 high-order bits
		mvw	(!fx),[u++]		; Save dividend's 16 low-order bits
		inc	ba			; Test if the TOS (the divisor)
		dec	ba			; is zero
		jrz	lbl6
		mvw	(!ix),$0000		; Store the divisor's 16 high-order bits
		mv	(!el),0			; The number of bits to compute
lbl1:		mv	ba,(!hx)		; Left-shift
		mv	i,(!ix)			; the second
		rc				; argument
		shl	(!hl)			; until
		shl	(!hh)			; it becomes
		shl	(!il)			; greater
		shl	(!ih)			; than the
		inc	(!el)			; first one
		cmpw	(!gx),(!ix)		; (and save previous result)
		jrc	lbl2
		jrnz	lbl1
		cmpw	(!fx),(!hx)
		jrnc	lbl1
lbl2:		mv	(!hx),ba		; Store the previous value
		mv	(!ix),i			; (which is lower than the first argument)
		sub	ba,ba			; BA holds the absolute value of the result of the division
lbl3:		add	ba,ba			; Left-shift the intermediate result
		cmpw	(!gx),(!ix)		; Test if
		jrc	lbl5			; the next bit
		jrnz	lbl4			; of the result
		cmpw	(!fx),(!hx)		; is 0 or 1
		jrc	lbl5
lbl4:		inc	ba			; Set next bit of the result to 1
		mv	il,4			; Subtract
		sbcl	(!fx),(!hx)		; an entire part of the second argument to the first
lbl5:		rc
		shr	(!ih)			; Right-shift
		shr	(!il)			; the
		shr	(!hh)			; second
		shr	(!hl)			; argument
		dec	(!el)			; Test if all the bits have been computed
		jrnz	lbl3
		mv	i,(!fx)			; I holds the modulo
		pushu	i			; Save it on the stack (the TOS contains the quotient)
		jp	!cont__
lbl6:		mv	il,-10			; Division by zero
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
s_m_sl_rem:	dw	u_m_sl_mod
		db	$06
		db	'SM/REM'
s_m_sl_rem_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!to_r_xt
		dw	!abs_xt
		dw	!not_rot_xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!to_r_xt
		dw	!d_abs_xt
		dw	!rot_xt
		dw	!u_m_sl_mod_xt
		dw	!swap_xt
		dw	!r_fetch_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!negate_xt
lbl2:		dw	!swap_xt
		dw	!two_r_from_xt
		dw	!xor_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!negate_xt
lbl4:		dw	!doret__xt
		endl
;-------------------------------------------------------------------------------
f_m_sl_mod:	dw	s_m_sl_rem
		db	$06
		db	'FM/MOD'
f_m_sl_mod_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!to_r_xt
		dw	!abs_xt
		dw	!not_rot_xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!to_r_xt
		dw	!d_abs_xt
		dw	!rot_xt
		dw	!u_m_sl_mod_xt
		dw	!two_r_fetch_xt
		dw	!xor_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!one_plus_xt
			dw	!negate_xt
			dw	!swap_xt
			dw	!one_plus_xt
			dw	!swap_xt
lbl2:		dw	!swap_xt
		dw	!two_r_from_xt
		dw	!drop_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!negate_xt
lbl4:		dw	!swap_xt
		dw	!doret__xt
		endl
;-------------------------------------------------------------------------------
star_sl_mod:	dw	f_m_sl_mod
		db	$05
		db	'*/MOD'
star_sl_mod_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!m_star_xt
		dw	!r_from_xt
		dw	!s_m_sl_rem_xt
		dw	!doret__xt
		endl
;-------------------------------------------------------------------------------
star_slash:	dw	star_sl_mod
		db	$02
		db	'*/'
star_slash_xt:	local
		jp	!docol__xt
		dw	!star_sl_mod_xt
		dw	!nip_xt
		dw	!doret__xt
		endl
;-------------------------------------------------------------------------------
m_star_sl:	dw	star_slash
		db	$03
		db	'M*/'			; ( d n +n -- d )
m_star_sl_xt:	local
		mv	i,ba			; Test if the third
		add	i,i			; argument is negative or zero
		jpc	lbl18
		jpz	lbl19
		mv	(!eh),$00		; To keep track of the sign of the result
		mvw	(!ix),[u++]		; Save the second argument into internal memory
		mvw	(!hx),$0000		; Store the
		mvw	(!gx),[u++]		; first argument
		mvw	(!fx),[u++]		; using 3 cells
		test	(!gh),$80		; Test the sign of the first argument
		jrz	lbl1
		mv	(!eh),$01		; The first argument is negative
		mvw	(!jx),$0000		; Negate
		mvw	(!kx),$0000		; the
		mv	il,4			; first
		sbcl	(!jx),(!fx)		; argument
		mv	il,4			;
		mvl	(!fx),(!jx)		;
lbl1:		test	(!ih),$80		; Test the sign of the second argument
		jrz	lbl2
		xor	(!eh),$01		; The second argument is negative
		mvw	(!jx),$0000		; Negate
		mv	il,2			; the
		sbcl	(!jx),(!ix)		; second
		mvw	(!ix),(!jx)		; argument
lbl2:		pushu	ba			; Save the third argument on the stack
		mv	ba,(!ix)		; BA holds the absolute value of the second argument
		mvw	(!ix),$0000		; Initialize
		mvw	(!jx),$0000		; the intermediate
		mvw	(!kx),$0000		; result
		mv	(!el),$80		; Initialize counter
lbl3:		shr	a
		jrnc	lbl4
		mv	il,6
		adcl	(!ix),(!fx)
lbl4:		mv	il,6
		adcl	(!fx),(!fx)
		ror	(!el)
		jrnc	lbl3
		mv	a,b			; The same with the 8 high-order bits
lbl5:		shr	a
		jrnc	lbl6
		mv	il,6
		adcl	(!ix),(!fx)
lbl6:		mv	il,6
		adcl	(!fx),(!fx)
		ror	(!el)
		jrnc	lbl5
		mvw	(!fx),[u]		; Restore the third argument
		mvw	[--u],(!ix)		; Save the 16 low-order bits of the dividend
		cmpw	(!kx),(!fx)		; Test if the result overflows
		jpnc	lbl20
		mvw	(!gx),$0000		; Perform a division of the 32 high-order bits by the divisor first
		mv	(!el),0
		mv	il,4			; Restore
		mvl	(!hx),(!fx)		; the divisor
lbl7:		mv	il,4			; Left-shift
		mvl	(!fx),(!hx)		; the
		rc				; divisor
		shl	(!hl)			; until
		shl	(!hh)			; it becomes
		shl	(!il)			; greater
		shl	(!ih)			; than
		inc	(!el)			; the
		cmpw	(!kx),(!ix)		; dividend
		jrc	lbl8			; (and
		jrnz	lbl7			; save
		cmpw	(!jx),(!hx)		; previous
		jrnc	lbl7			; result)
lbl8:		sub	ba,ba			; BA holds the 16 high-order bits of the absolute value of the result
lbl9:		add	ba,ba			; Left-shift the 16 high-order bits of the intermediate result
		cmpw	(!kx),(!gx)		; Test if
		jrc	lbl11			; the next bit
		jrnz	lbl10			; of the result
		cmpw	(!jx),(!fx)		; is 0 or 1
		jrc	lbl11
lbl10:		inc	ba			; Set next bit of the result to 1
		mv	il,4			; Subtract an entire part
		sbcl	(!jx),(!fx)		; of the divisor from the dividend
lbl11:		rc				; Right-shift
		shr	(!gh)			; the
		shr	(!gl)			; divisor
		shr	(!fh)			;
		shr	(!fl)			;
		dec	(!el)			; Test if all the bits have been computed
		jrnz	lbl9
		mvw	(!kx),(!jx)		; Shift the modulo to compute the 16 low-order bits of the result
		mvw	(!jx),[u++]		; Restore the 16 low-order bits of the dividend
		mvw	(!fx),[u++]		; Restore the divisor
		mvw	(!gx),$0000		; as a 32 bit value
		mv	(!el),0
		mv	il,4			; Restore
		mvl	(!hx),(!fx)		; the divisor
lbl12:		mv	il,4			; Left-shift
		mvl	(!fx),(!hx)		; the
		rc				; divisor
		shl	(!hl)			; until
		shl	(!hh)			; it becomes
		shl	(!il)			; greater
		shl	(!ih)			; than
		inc	(!el)			; the
		cmpw	(!kx),(!ix)		; dividend
		jrc	lbl13			; (and
		jrnz	lbl12			; save
		cmpw	(!jx),(!hx)		; previous
		jrnc	lbl12			; result)
lbl13:		mv	(!ix),ba		; Save the 16 high-order bits of the absolute value of the result
		sub	ba,ba			; BA holds the 16 low-order bits of the absolute value of the result
lbl14:		add	ba,ba			; Left-shift the 16 low-order bits of the intermediate result
		cmpw	(!kx),(!gx)		; Test if
		jrc	lbl16			; the next bit
		jrnz	lbl15			; of the result
		cmpw	(!jx),(!fx)		; is 0 or 1
		jrc	lbl16
lbl15:		inc	ba			; Set next bit of the result to 1
		mv	il,4			; Subtract an entire part
		sbcl	(!jx),(!fx)		; of the divisor from the dividend
lbl16:		rc				; Right-shift
		shr	(!gh)			; the
		shr	(!gl)			; divisor
		shr	(!fh)			;
		shr	(!fl)			;
		dec	(!el)			; Test if all the bits have been computed
		jrnz	lbl14
		mv	(!hx),ba		; Save the 16 low-order bits of the absolute value of the result
		test	(!eh),$01		; Test he sign of the result
		jrz	lbl17
		mv	(!fx),ba		; Negate
		mvw	(!gx),(!ix)		; the
		mvw	(!hx),$0000		; result
		mvw	(!ix),$0000		;
		mv	il,4			;
		sbcl	(!hx),(!fx)		;
lbl17:		mvw	[--u],(!hx)		; Save the 16 low-order bits of the result on the stack
		mv	ba,(!ix)		; Set new TOS
		jp	!cont__
lbl18:		mv	il,-24			; Invalid numeric argument
		jp	!throw__
lbl19:		mv	il,-10			; Division by zero
		jp	!throw__
lbl20:		mv	il,-11			; Result out of range
lbl21:		jp	!throw__
		jp	!throw_xt
		endl
;-------------------------------------------------------------------------------
;
;		FLOAT
;
;-------------------------------------------------------------------------------
;fop_:		dw	m_star_sl
;		db	$05
;		db	'(FOP)'			; ( addr fop -- flag )
;fop__xt:	local
;		pre_on
;		pushs	x			; Save IP
;		popu	i			; FP data short address
;		mv	y,!base_address
;		add	y,i			; Y holds the FP data address
;		pushs	y			; Save Y
;		mv	il,30
;		mvl	(bp+!fp),[y++]		; Copy 30 bytes FP data to internal RAM
;		mvw	(!cx),$0009		; Function driver
;		mv	il,a			; Function $41 to $7f
;		callf	!iocs			;
;		pops	y			; Restore Y
;		mv	ba,-1			; Set new TOS to TRUE
;		jrc	lbl1			; Error
;		mv	il,30
;		mvl	[y++],(bp+!fp)		; Copy 30 bytes internal RAM to FP data
;lbl1:		inc	ba			; Set new TOS to FALSE
;		pops	x			; Restore IP
;		jp	!cont__
;		pre_off
;		endl
;-------------------------------------------------------------------------------
;
;		STRING
;
;-------------------------------------------------------------------------------
s_equals:	dw	m_star_sl
		db	$02
		db	'S='
s_equals_xt:	local
		jp	!docol__xt		; : S= ( c-addr u c-addr u -- flag )
		dw	!compare_xt		;   COMPARE
		dw	!zero_equals_xt		;   0=
		dw	!doret__xt		; ;
;		mv	i,[u+2]			; I holds the length of the first string
;		sub	ba,i			; Test the length of the strings
;		jrnz	lbl5
;		pushs	x			; Save IP
;		mv	x,!base_address
;		mv	y,x
;		popu	ba
;		add	y,ba			; Y holds the address of the second string
;		popu	ba			; Discard the length of the first string (already known)
;		popu	ba
;		add	x,ba			; X holds the address of the first string
;		inc	i
;		dec	i
;		jrz	lbl2
;lbl1:		mv	a,[x++]
;		mv	(!el),[y++]
;		cmp	(!el),a			; Compare characters
;		jrnz	lbl4
;		dec	i
;		jrnz	lbl1
;lbl2:		mv	ba,-1			; Set new TOS to TRUE
;lbl3:		pops	x			; Restore IP
;		jr	lbl6
;lbl4:		sub	ba,ba			; Set new TOS to FALSE
;		jr	lbl3
;lbl5:		popu	y			; Clean-up the stack
;		popu	y			;
;		sub	ba,ba			; Set new TOS to FALSE
;lbl6:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
dash_chars:	dw	s_equals
		db	$06
		db	'-CHARS'		; ( c-addr u char -- c-addr u )
dash_chars_xt:	local
		mv	(!el),a			; Save TOS low-order byte
		popu	i			; I holds the length of the string to adjust
		mv	y,!base_address
		add	y,i
		mv	ba,[u]			; BA holds the short address of the string
		add	y,ba			; Y holds the address of the last character of the string + 1
		inc	i
		jr	lbl2
lbl1:		mv	a,[--y]			; Read characters from the end
		cmp	(!el),a			; Compare current character
		jrnz	lbl3
lbl2:		dec	i			; Is the begining of the string reached?
		jrnz	lbl1
lbl3:		mv	ba,i			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
dash_trail:	dw	dash_chars
		db	$09
		db	'-TRAILING'		; ( c-addr u -- c-addr u )
dash_trail_xt:	local
		pushu	ba			; Save TOS
		mv	a,32			; Sete new TOS 8 low-order bits to BL
		jp	!dash_chars_xt		; Execute -CHARS
;		mv	i,ba			; I holds the length of the string
;		mv	y,!base_address
;		add	y,ba
;		mv	ba,[u]			; BA holds the short address of the string
;		add	y,ba			; Y holds the address of the last character of the string + 1
;		inc	i
;		jr	lbl2
;lbl1:		mv	a,[--y]			; Read characters from the end
;		cmp	a,$20			; Compare current character to character space
;		jrnz	lbl3
;lbl2:		dec	i			; Is the begining of the string reached?
;		jrnz	lbl1
;lbl3:		mv	ba,i			; Set new TOS
;		jp	!cont__
		endl
;-------------------------------------------------------------------------------
slash_str:	dw	dash_trail
		db	$07
		db	'/STRING'		; ( c-addr u n -- c-addr u )
slash_str_xt:	local
		mv	i,[u+2]			; I holds the short address of the string
		add	i,ba			; Add TOS to this address
		mv	[u+2],i			; Save the new address on the stack
		popu	i			; I holds the length of the string
		sub	i,ba			; Adjust the length of the string
		mv	ba,i			; Set new TOS to this length
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
next_char:	dw	slash_str
		db	$09
		db	'NEXT-CHAR'		; ( c-addr u -- c-addr u char )
next_char_xt:	local
		inc	ba			; Test whether the
		dec	ba			; string is empty or not
		jrz	lbl1
		mv	y,!base_address
		popu	i			; I holds the short address of the string
		add	y,i			; Y holds the address of the string
		inc	i			; Consume one character
		dec	ba			; of the string
		pushu	i			; Save the new address on the stack
		pushu	ba			; Save the new length on the stack
		sub	ba,ba			; Set
		mv	a,[y]			; new TOS
		jp	!cont__
lbl1:		mv	il,-24			; Invalid numeric argument
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
move:		dw	next_char
		db	$04
		db	'MOVE'			; ( addr addr u -- )
move_xt:	local
		mv	i,[u]			; I holds the destination address
		mvw	(!ex),[u+2]		; (ex) holds the source address
		cmpw	(!ex),i			; Test if source address is lower than destination
		jrc	!c_move_up_xt		; Source address is lower than destination
		jrnz	!c_move_xt		; Source address is higher than destination
		jp	!cont__

;		mv	(!ex),ba		; Save the number of bytes to move
;		popu	ba			; BA holds the short destination address
;		popu	i			; I holds the short source address
;		pushu	x			; Save IP
;		mv	y,!base_address
;		mv	x,y
;		add	y,ba			; Y holds the destination address
;		add	x,i			; X holds the source address
;		sub	ba,i			; Test if source address is lower or greater than destination one
;		mv	i,(!ex)			; Restore the the number of bytes to move
;		inc	i			; Test if the number of
;		dec	i			; bytes to move is zero
;		jrz	lbl3
;		jrc	lbl2
;		add	x,i			; X holds the address of the last byte to move + 1
;		add	y,i			; X holds the destination address of the last byte to move + 1
;lbl1:		mv	a,[--x]			; Move the bytes
;		mv	[--y],a			; by traversing towards lower addresses
;		dec	i			; Count the number of bytes to move
;		jrnz	lbl1
;		jr	lbl3
;lbl2:		mv	a,[x++]			; Move the bytes
;		mv	[y++],a			; by traversing towards higher addresses
;		dec	i			; Count the number of bytes to move
;		jrnz	lbl2
;lbl3:		popu	x			; Restore IP
;		popu	ba			; Set new TOS
;		jp	!cont__
		endl
;-------------------------------------------------------------------------------
c_move:		dw	move
		db	$05
		db	'CMOVE'			; ( c-addr c-addr u -- )
c_move_xt:	local
		pushs	x			; Save IP
		mv	y,!base_address
		mv	x,y
		mv	i,ba			; I holds the number of characters to move
		popu	ba
		add	y,ba			; Y holds the destination address
		popu	ba
		add	x,ba			; X holds the source address
		inc	i
		jr	lbl2
lbl1:		mv	a,[x++]			; Move characters from
		mv	[y++],a			; lower to upper addresses
lbl2:		dec	i			; Count the number of characters to move
		jrnz	lbl1
		popu	ba			; Set new TOS
		pops	x			; Restore IP
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
c_move_up:	dw	c_move
		db	$06
		db	'CMOVE>'		; ( c-addr c-addr u -- )
c_move_up_xt:	local
		pushs	x			; Save IP
		mv	y,!base_address
		add	y,ba
		mv	x,y
		mv	i,ba			; I holds the number of characters to move
		popu	ba
		add	y,ba			; Y holds the last destination address + 1
		popu	ba
		add	x,ba			; X holds the last source address + 1
		inc	i
		jr	lbl2
lbl1:		mv	a,[--x]			; Move characters from
		mv	[--y],a			; upper to lower addresses
lbl2:		dec	i			; Count the number of characters to move
		jrnz	lbl1
		popu	ba			; Set new TOS
		pops	x			; Restore IP
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
compare:	dw	c_move_up
		db	$07
		db	'COMPARE'		; ( c-addr u c-addr u -- n )
compare_xt:	local
		pushs	x			; Save IP
		mv	y,!base_address
		mv	x,y
		mv	(!gx),ba		; Save the length of the second string
		popu	i
		add	y,i			; Y holds the address of the second string
		mvw	(!fx),[u++]		; Save the length of the first string
		popu	i
		add	x,i			; X holds the address of the first string
		cmpw	(!fx),ba		; Compare the length of the strings
		jrnc	lbl1
		mv	ba,(!fx)		; BA holds the smallest length
lbl1:		mv	i,ba			; Set I to the smallest length
		inc	i			; Does this value
		jr	lbl2a			; equals zero?
lbl2:		mv	(!el),[x++]		; Compare
		mv	a,[y++]			; characters
		cmp	(!el),a			;
		jrc	lbl5
		jrnz	lbl6
lbl2a:		dec	i			; Count the number of remaining characters
		jrnz	lbl2
lbl3:		cmpw	(!fx),(!gx)		; Strings are equal with respect to their first characters
		jrc	lbl5			; Compare the length to discriminate
		jrnz	lbl6			; over them
		sub	ba,ba			; Set new TOS (strings are equal)
lbl4:		pops	x			; Restore IP
		jp	!cont__
lbl5:		mv	ba,-1			; Set new TOS (string1 is lower than string2)
		jr	lbl4
lbl6:		mv	ba,1			; Set new TOS (string1 is greater than string2)
		jr	lbl4
		endl
;-------------------------------------------------------------------------------
search:		dw	compare
		db	$06
		db	'SEARCH'		; ( c-addr u c-addr u -- c-addr u flag )
search_xt:	local
		pushs	x			; Save IP
		mv	y,!base_address
		mv	x,y
		popu	i
		add	y,i			; Y holds the address of the second string
		mv	i,[u+2]
		add	x,i			; X holds the address of the first string
		inc	ba			; Does the length of
		dec	ba			; the second string equals zero?
		jrz	lbl3
		mv	i,[u]			; I holds the length of the first string
		sub	i,ba			; Verify that the second string is not too long
		jrc	lbl6
		inc	i			; I holds the number of possible matching substrings in the first string
		mv	(!fx),ba		; Save the length of the second string
lbl1:		pushu	x			; Save the current address from where to start searching
		pushu	y			; Save the address of the second string
lbl2:		mv	(!el),[x++]		; Compare
		mv	(!eh),[y++]		; characters
		cmp	(!el),(!eh)		;
		jrnz	lbl5
		dec	ba			; Count the number of remaining characters
		jrnz	lbl2
		popu	y			; Discard the address of the second string
		popu	x			; Pop X (that holds the address of the matching area)
		mv	ba,x			; Truncate it to 16 bits
		mv	i,[u+2]			; I holds the address of the first string
		mv	[u+2],ba		; Update the address of the matching substring
		sub	ba,i			; Compute the
		mv	i,[u]			; length of the
		sub	i,ba			; remaining string
		mv	[u],i			; Save it on the stack
lbl3:		mv	ba,-1			; Set new TOS to TRUE (a match is found)
lbl4:		pops	x			; Restore IP
		jp	!cont__
lbl5:		popu	y			; Positon Y at the beginning of the second string
		popu	x			; X holds the previous address from where to start searching
		inc	x			; Increment it
		mv	ba,(!fx)		; Restore BA's value to the length of the second string
		dec	i			; Count the number of possible matches
		jrnz	lbl1
lbl6:		sub	ba,ba			; Set new TOS to FALSE (no match found)
		jr	lbl4
		endl
;-------------------------------------------------------------------------------
;
;		MISC
;
;-------------------------------------------------------------------------------
on:		dw	search
		db	$02
		db	'ON'
on_xt:		local
		jp	!docol__xt		; : ON
		dw	!dolitm1_xt		;   TRUE
		dw	!swap_xt		;   SWAP
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
off:		dw	on
		db	$03
		db	'OFF'
off_xt:		local
		jp	!docol__xt		; : OFF
		dw	!dolit0_xt		;   FALSE
		dw	!swap_xt		;   SWAP
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
ms:		dw	off
		db	$02
		db	'MS'			; ( u -- )
ms_xt:		local				; 124x6+5+11=760 cycles per ms matching 768KHz clock, interrupt adds some overhead
lbl1:		inc	ba			; 3 cycles
		dec	ba			; 3 cycles
		jrz	lbl3			; 2 cycles (3 when jumping)
		mv	il,$7c			; 3 cycles
lbl2:		dec	i			; 3*$7c cycles
		jrnz	lbl2			; 3*$7b+2 cycles
		dec	ba			; 3 cycles
		jr	lbl1			; 3 cycles
lbl3:		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
beg_struct:	dw	ms
		db	$0f
		db	'BEGIN-STRUCTURE'
beg_struct_xt:	local
		jp	!docol__xt		; : BEGIN-STRUCTURE ( "<spaces>name" -- addr 0 ; -- u )
		dw	!create_xt		;   CREATE
		dw	!here_xt		;     HERE
		dw	!dolit0_xt		;     0
		dw	!dolit0_xt		;     0
		dw	!comma_xt		;     ,   \ mark stack, lay dummy 0
		dw	!sc_code__xt		;   DOES> \ (;CODE) compiled by DOES>
		call	!does__xt		;         \ Compiled by DOES>
		dw	!fetch_xt		;     @   \ -- size
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
end_struct:	dw	beg_struct
		db	$0d
		db	'END-STRUCTURE'
end_struct_xt:	local
		jp	!docol__xt		; : END-STRUCTURE ( addr u -- )
		dw	!swap_xt		;   SWAP
		dw	!store_xt		;   ! \ set size
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
plus_field:	dw	end_struct
		db	$06
		db	'+FIELD'
plus_field_xt:	local
		jp	!docol__xt		; : +FIELD ( u n "<spaces>name" -- u ; addr -- addr )
		dw	!create_xt		;   CREATE
		dw	!over_xt		;     OVER
		dw	!comma_xt		;     ,
		dw	!plus_xt		;     +
		dw	!sc_code__xt		;   DOES> \ (;CODE) compiled by DOES>
		call	!does__xt		;         \ Compiled by DOES>
		dw	!fetch_xt		;     @
		dw	!plus_xt		;     +
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
c_field:	dw	plus_field
		db	$07
		db	'CFIELD:'
c_field_xt:	local
		jp	!docol__xt		; : CFIELD: ( u "<spaces>name" -- u ; addr -- addr )
		dw	!dolit1_xt		;   1
		dw	!plus_field_xt		;   +FIELD
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
field:		dw	c_field
		db	$06
		db	'FIELD:'
field_xt:	local
		jp	!docol__xt		; : FIELD: ( u "<spaces>name" -- u ; addr -- addr )
		dw	!dolit2_xt		;   2
		dw	!plus_field_xt		;   +FIELD
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
two_field:	dw	field
		db	$07
		db	'2FIELD:'
two_field_xt:	local
		jp	!docol__xt		; : 2FIELD: ( u "<spaces>name" -- u ; addr -- addr )
		dw	!field_xt		;   FIELD:
		dw	!field_xt		;   FIELD:
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		BLOCK (INCOMPLETE AND DISABLED)
;
;-------------------------------------------------------------------------------
;buffer0:	dw	two_field
;		db	$07
;		db	'BUFFER0'
;buffer0_xt:	local
;		jp	!dovar__xt		; 2VARIABLE 1024 ALLOT
;		dw	$0000			; Link to the next buffer (zero if last one)
;		dw	$0000			; UPDATE field
;		ds	!blk_buff_size		; Block or file buffer  ************* CREATE-BUFFER *************
;		endl
;-------------------------------------------------------------------------------
;last_buffer:	dw	buffer0
;		db	$0b
;		db	'LAST-BUFFER'
;last_buffer_xt:	local
;		jp	!dovar__xt
;		dw	!buffer0_xt
;		endl
;-------------------------------------------------------------------------------
;blk:		dw	last_buffer
;		db	$03
;		db	'BLK'
;blk_xt:		local
;		jp	!dovar__xt
;		dw	0
;		endl
;-------------------------------------------------------------------------------
;block:		dw	blk
;		db	$05
;		db	'BLOCK'
;block_xt:	local
;		jp	!cont__xt		; Does nothing, not implemented (yet)
;		endl
;-------------------------------------------------------------------------------
;buffer:		dw	block
;		db	$06
;		db	'BUFFER'
;buffer_xt:	local
;		jp	!docol__xt
;		dw	!block_xt
;		dw	!doret__xt
;		endl
;-------------------------------------------------------------------------------
;save_buffs:	dw	buffer
;		db	$0c
;		db	'SAVE-BUFFERS'
;save_buffs_xt:	local
;		jp	!cont__xt		; Does nothing, not implemented (yet)
;		endl
;-------------------------------------------------------------------------------
;empty_buffs:	dw	save_buffs
;		db	$0d
;		db	'EMPTY-BUFFERS'
;empty_buffs_xt:	local
;		jp	!cont__xt		; Does nothing, not implemented (yet)
;		endl
;-------------------------------------------------------------------------------
;flush:		dw	empty_buffs
;		db	$05
;		db	'FLUSH'
;flush_xt:	local
;		jp	!docol__xt
;		dw	!save_buffs_xt
;		dw	!empty_buffs_xt
;		dw	!doret__xt
;		endl
;-------------------------------------------------------------------------------
;load:		dw	flush
;		db	$04
;		db	'LOAD'
;load_xt:	local
;		jp	!cont__xt		; Does nothing, not implemented (yet)
;		endl
;-------------------------------------------------------------------------------
;thru:		dw	load
;		db	$04
;		db	'THRU'
;thru_xt:	local
;		jp	!docol__xt
;		dw	!one_plus_xt
;		dw	!swap_xt
;		dw	!quest_do__xt
;		dw	lbl2-lbl1
;lbl1:		dw	!i_xt
;		dw	!load_xt
;		dw	!loop__xt
;		dw	lbl2-lbl1
;lbl2:		dw	!doret__xt
;		endl
;-------------------------------------------------------------------------------
;update:		dw	thru
;		db	$06
;		db	'UPDATE'
;update_xt:	local
;		jp	!cont__xt		; Does nothing, not implemented (yet)
;		endl
;-------------------------------------------------------------------------------
;scr:		dw	update
;		db	$03
;		db	'SCR'
;scr_xt:		local
;		jp	!dovar__xt
;		dw	0
;		endl
;-------------------------------------------------------------------------------
;list:		dw	scr
;		db	$04
;		db	'LIST'
;list_xt:	local
;		jp	!cont__xt		; Does nothing, not implemented (yet)
;		endl
;-------------------------------------------------------------------------------
;
;		PAD AND STRING BUFFERS
;
;-------------------------------------------------------------------------------
pad:		dw	two_field
		db	$03
		db	'PAD'
pad_xt:		local
		jp	!docon__xt
		dw	$ff00			; The PAD is located at $bff00
		endl
;-------------------------------------------------------------------------------
which_pockt:	dw	pad
		db	$0c
		db	'WHICH-POCKET'		; ( -- c-addr )
which_pockt_xt:	local
		pushu	ba			; Save the TOS
		call	!which_pocket__		; New TOS is the address of a free pocket
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
which_pocket__:	local
		mv	a,[nbr]
		xor	a,1
		mv	[nbr],a
		mv	ba,buf0
		jrz	lbl1
		mv	ba,buf1
lbl1:		ret
nbr:		db	0			; Round-robin #0 or #1
buf0:		ds	!ib_size		; Buffer #0
buf1:		ds	!ib_size		; Buffer #1
		endl
;-------------------------------------------------------------------------------
;
;		FILE I/O
;
;-------------------------------------------------------------------------------
bin:		dw	which_pockt
		db	$03
		db	'BIN'
bin_xt:		local
		jp	!cont__			; Does nothing (since files are UNIX-coded)
		endl
;-------------------------------------------------------------------------------
r_o:		dw	bin
		db	$03
		db	'R/O'
r_o_xt:		local
		jp	!dolit1_xt		; 1 CONSTANT R/O / immutable
		endl
;-------------------------------------------------------------------------------
w_o:		dw	r_o
		db	$03
		db	'W/O'
w_o_xt:		local
		jp	!dolit2_xt		; 2 CONSTANT W/O / immutable
		endl
;-------------------------------------------------------------------------------
r_w:		dw	w_o
		db	$03
		db	'R/W'
r_w_xt:		local
		jp	!dolit3_xt		; 3 CONSTANT R/W / immutable
		endl
;-------------------------------------------------------------------------------
stdo:		dw	r_w
		db	$04
		db	'STDO'
stdo_xt:	local
		jp	!dolit1_xt		; 1 CONSTANT STDO / immutable standard out
		endl
;-------------------------------------------------------------------------------
stdi:		dw	stdo
		db	$04
		db	'STDI'
stdi_xt:	local
		jp	!dolit2_xt		; 2 CONSTANT STDI / immutable standard in
		endl
;-------------------------------------------------------------------------------
stdl:		dw	stdi
		db	$04
		db	'STDL'
stdl_xt:	local
		jp	!dolit3_xt		; 3 CONSTANT STDL / immutable standard listing (prn)
		endl
;-------------------------------------------------------------------------------
which_file:	dw	stdl
		db	$0a
		db	'WHICH-FILE'		; ( -- s-addr )
which_file_xt:	local
		pushu	ba			; Save the TOS
		call	!which_file__		; New TOS is the address of a free file data block
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
which_file__:	local
		mv	a,[nbr]
		xor	a,1
		mv	[nbr],a
		mv	ba,buf0
		jrz	lbl1
		mv	ba,buf1
lbl1:		ret
nbr:		db	0			; Round-robin #0 or #1
buf0:		ds	5+1+8+1+3		; Drive name + ':' + file name + '.' + extension
		ds	1+2+2+3			; Attribute + time + date + size
buf1:		ds	5+1+8+1+3		; Drive name + ':' + file name + '.' + extension
		ds	1+2+2+3			; Attribute + time + date + size
		endl
;-------------------------------------------------------------------------------
drive:		dw	which_file
		db	$05
		db	'DRIVE'
drive_xt:	local
		jp	!dovar__xt		; CREATE DRIVE 2 CHARS ALLOT
		db	'E:'			; Current drive letter E, F or G can change with 'F DRIVE C!
		endl
;-------------------------------------------------------------------------------
;chdir:		dw	drive
;		db	$05
;		db	'CHDIR'
;chdir_xt:	local
;		jp	!docol__xt			; : CHDIR ( "name" -- )
;		dw	!parse_name_xt			;   PARSE-NAME
;		dw	!drop_xt			;   DROP
;		dw	!c_fetch_xt			;   C@
;		dw	!drive_xt			;   DRIVE
;		dw	!c_store_xt			;   C!
;		dw	!doret__xt			; ;
;		endl
;-------------------------------------------------------------------------------
drivename:	dw	drive
		db	$09
		db	'DRIVENAME'
drivename_xt:	local
		jp	!docol__xt			; : DRIVENAME ( c-addr u -- c-addr u )
		dw	!two_dup_xt			;   2DUP
		dw	!doslit__xt			;   S" :"
		dw	1				;
		db	':'				;
		dw	!search_xt			;   SEARCH \ c-addr u c-addr u flag
		dw	!if__xt				;   IF
		dw	lbl4-lbl1			;
lbl1:			dw	!drop_xt		;     DROP
			dw	!nip_xt			;     NIP
			dw	!over_xt		;     OVER
			dw	!minus_xt		;     -     \ c-addr u
			dw	!dup_xt			;     DUP
			dw	!dolit1_xt		;     1
			dw	!equals_xt		;     =
			dw	!if__xt			;     IF    \ if drive is one char, set DRIVE to this char
			dw	lbl3-lbl2		;
lbl2:				dw	!over_xt	;       OVER
				dw	!c_fetch_xt	;       C@
				dw	!drive_xt	;       DRIVE
				dw	!c_store_xt	;       C! THEN
lbl3:			dw	!doexit__xt		;     EXIT THEN
lbl4:		dw	!two_drop_xt			;   2DROP
		dw	!two_drop_xt			;   2DROP
		dw	!drive_xt			;   DRIVE
		dw	!dolit1_xt			;   1
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
filename:	dw	drivename
		db	$08
		db	'FILENAME'
filename_xt:	local
		jp	!docol__xt		; : FILENAME ( c-addr u -- c-addr u )
		dw	!doslit__xt		;   S" :"
		dw	1			;
		db	':'			;
		dw	!search_xt		;   SEARCH \ c-addr u flag
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit1_xt	;     1
			dw	!slash_str_xt	;     /STRING THEN
lbl2:		dw	!two_dup_xt		;   2DUP
		dw	!doslit__xt		;   S" ."
		dw	1			;
		db	'.'			;
		dw	!search_xt		;   SEARCH \ c-addr u c-addr u flag
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!drop_xt	;     DROP
			dw	!nip_xt		;     NIP
			dw	!over_xt	;     OVER
			dw	!minus_xt	;     -
			dw	!doexit__xt	;     EXIT THEN
lbl4:		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
extension:	dw	filename
		db	$09
		db	'EXTENSION'
extension_xt:	local
		jp	!docol__xt		; : EXTENSION ( c-addr u -- c-addr u )
		dw	!doslit__xt		;   S" ."
		dw	1			;
		db	'.'			;
		dw	!search_xt		;   SEARCH
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit1_xt	;     1
			dw	!slash_str_xt	;     /STRING
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!dolit0_xt		;   0
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
fnp:		dw	extension
		db	$03
		db	'FNP'
fnp_xt:		local
		jp	!doval__xt		; 0 VALUE FNP \ pointer to (FILE) buf0 or buf1
		dw	0
		endl
;-------------------------------------------------------------------------------
drive_file_:	dw	fnp
		db	$0c
		db	'(DRIVE>FILE)'
drive_file__xt:	local
		jp	!docol__xt		; : (DRIVE>FILE) ( c-addr u -- )
		dw	!dolit__xt		;   5
		dw	5			;
		dw	!min_xt			;   MIN
		dw	!fnp_xt			;   FNP
		dw	!swap_xt		;   SWAP
		dw	!dup_xt			;   DUP
		dw	!doplusto__xt		;   +TO FNP
		dw	!fnp_xt+3		;
		dw	!c_move_xt		;   CMOVE
		dw	!dolit__xt		;   ':
		dw	$3a			;   \ The value of the ':' character
		dw	!fnp_xt			;   FNP
		dw	!c_store_xt		;   C!
		dw	!dolit1_xt		;   1
		dw	!doplusto__xt		;   +TO FNP
		dw	!fnp_xt+3		;
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
glob_file_:	dw	drive_file_
		db	$0b
		db	'(GLOB>FILE)'
glob_file__xt:	local
		jp	!docol__xt			; : (GLOB>FILE) ( c-addr u u -- )
		dw	!dup_to_r_xt			;   DUP>R        \ Max length
		dw	!min_xt				;   MIN
		dw	!dolit0_xt			;   0            \ c-addr u 0
		dw	!quest_do__xt			;   ?DO
		dw	lbl4-lbl1			;
lbl1:			dw	!dup_xt			;     DUP        \ c-addr c-addr
			dw	!c_fetch_xt		;     C@
			dw	!dup_xt			;     DUP
			dw	!dolit__xt		;     '*
			dw	$2a			;
			dw	!equals_xt		;     =          \ c-addr char flag
			dw	!if__xt			;     IF
			dw	lbl3-lbl2		;
lbl2:				dw	!two_drop_xt	;       2DROP
				dw	!fnp_xt		;       FNP
				dw	!i_xt		;       I
				dw	!plus_xt	;       +        \ s-addr
				dw	!i_xt		;       I        \ s-addr u
				dw	!unloop__xt	;       UNLOOP
				dw	!r_from_xt	;       R>       \ Compute...
				dw	!dup_xt		;       DUP
				dw	!doplusto__xt	;       +TO FNP
				dw	!fnp_xt+3	;
				dw	!swap_xt	;       SWAP     \ ...number of...
				dw	!minus_xt	;       -        \ ...remaining chars in s-addr to...
				dw	!dolit__xt	;       '?       \ s-addr u char
				dw	$3f		;       
				dw	!fill_xt	;       FILL     \ ...fill with ?
				dw	!doexit__xt	;       EXIT THEN
lbl3:			dw	!fnp_xt			;     FNP
			dw	!i_xt			;     I
			dw	!plus_xt		;     +
			dw	!c_store_xt		;     C!
			dw	!one_plus_xt		;     1+
		dw	!loop__xt			;   LOOP
		dw	lbl4-lbl1
lbl4:		dw	!drop_xt			;   DROP
		dw	!r_from_xt			;   R>
		dw	!doplusto__xt			;   +TO FNP
		dw	!fnp_xt+3			;
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
attr_file_:	dw	glob_file_
		db	$0b
		db	'(ATTR>FILE)'
attr_file__xt:	local
		jp	!docol__xt		; : (ATTR>FILE) ( c-addr u -- )
		dw	!dolit__xt		;   $20
		dw	$20			;   \ Default attribute
		dw	!fnp_xt			;   FNP
		dw	!c_store_xt		;   C!
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
str_to_file:	dw	attr_file_
		db	$0b
		db	'STRING>FILE'
str_to_file_xt:	local
		jp	!docol__xt		; : STRING>FILE ( c-addr u -- s-addr )
		dw	!which_file_xt		;   WHICH-FILE
		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   18
		dw	18			;
		dw	!blank_xt		;   BLANK
		dw	!dup_to_r_xt		;   DUP>R
		dw	!doto__xt		;   TO FNP
		dw	!fnp_xt+3		;
		dw	!two_dup_xt		;   2DUP
		dw	!drivename_xt		;   DRIVENAME
		dw	!drive_file__xt		;   (DRIVE>FILE)
		dw	!two_dup_xt		;   2DUP
		dw	!filename_xt		;   FILENAME
		dw	!dolit__xt		;   8
		dw	8			;
		dw	!glob_file__xt		;   (GLOB>FILE)
		dw	!dolit__xt		;   '.
		dw	$2e			;   \ The value of the '.' character
		dw	!fnp_xt			;   FNP
		dw	!c_store_xt		;   C!
		dw	!dolit1_xt		;   1
		dw	!doplusto__xt		;   +TO FNP
		dw	!fnp_xt+3		;
		dw	!extension_xt		;   EXTENSION
		dw	!dolit3_xt		;   3
		dw	!glob_file__xt		;   (GLOB>FILE)
		dw	!attr_file__xt		;   (ATTR>FILE)
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
file_to_str:	dw	str_to_file
		db	$0b
		db	'FILE>STRING'
file_to_str_xt:	local
		jp	!docol__xt		; : FILE>STRING ( s-addr -- s-addr u )
		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   15
		dw	15			;
		dw	!doslit__xt		;   S" ."
		dw	1			;
		db	'.'			;
		dw	!search_xt		;   SEARCH \ s-addr c-addr u flag
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!nip_xt		;     NIP  \ s-addr u
			dw	!dolit__xt	;     19
			dw	19		;
			dw	!swap_xt	;     SWAP
			dw	!minus_xt	;     -
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!two_drop_xt		;   2DROP
		dw	!dolit0_xt		;   0
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
to_file:	dw	file_to_str
		db	$05
		db	'>FILE'			; ( fileid -- s-addr ior )
to_file_xt:	local
		pre_on
		pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl3
		call	!which_file__
		mv	x,!base_address
		add	x,ba			; X holds current filename area address
		pushs	x			; Save current filename area address
		mv	il,$0a			; 'Reading various information of a file'
		mv	a,$01			; 'Reading of file name, extension and attribute'
		callf	!fcs
		pops	x			; Restore current filename area address
		jrnc	lbl5
lbl3:		mv	il,$00			; Address where to find
		pushu	i			; information is zero in case of an error
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl4:		pops	x			; Restore IP
		jp	!interp__
lbl5:		mv	i,x			; Save current filename
		pushu	i			; area address on the stack
		sub	ba,ba			; Set new TOS (no error)
		jr	lbl4
		pre_off
		endl
;-------------------------------------------------------------------------------
creat_file_:	dw	to_file
		db	$0d
		db	'(CREATE-FILE)'		; ( s-addr fam -- fileid ior )
creat_file__xt:	local
		pre_on
		pushs	x			; Save IP
		popu	i			; Read the short address of the file name
		mv	x,!base_address
		add	x,i			; X holds the address of the file name
		mv	il,$00			; 'Creating a file'
		mv	a,$00			; Discard the access mode (which will be as free as possible) and
		callf	!fcs			; set file attribute to 'visible and writable'
		mv	il,(!cl)		; Read the file handle
		inc	i			; Increment it (because fileIDs must start at index 1)
		pushu	i			; Save the file handle on the stack
		jrnc	lbl2
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		pops	x			; Restore IP
		jp	!interp__
lbl2:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
;-------------------------------------------------------------------------------
create_file:	dw	creat_file_
		db	$0b
		db	'CREATE-FILE'
create_file_xt:	local
		jp	!docol__xt		; : CREATE-FILE ( c-addr u fam -- fileid ior )
		dw	!to_r_xt		;   >R
		dw	!str_to_file_xt		;   STRING>FILE
		dw	!r_from_xt		;   R>
		dw	!creat_file__xt		;   (CREATE-FILE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
del_file_:	dw	create_file
		db	$0d
		db	'(DELETE-FILE)'		; ( s-addr -- ior )
del_file__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		add	x,ba			; X holds the address of the file name
		mv	il,$0e			; 'Deleting a file'
		callf	!fcs
		jrnc	lbl2
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		pops	x			; Restore IP
		jp	!interp__
lbl2:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
;-------------------------------------------------------------------------------
delete_file:	dw	del_file_
		db	$0b
		db	'DELETE-FILE'
delete_file_xt:	local
		jp	!docol__xt		; : DELETE-FILE ( c-addr u -- ior )
		dw	!str_to_file_xt		;   STRING>FILE
		dw	!del_file__xt		;   (DELETE-FILE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
file_stat_:	dw	delete_file
		db	$0d
		db	'(FILE-STATUS)'		; ( s-addr -- s-addr ior )
file_stat__xt:	local
		pre_on
		pushs	x			; Save IP
		pushu	ba			; Save TOS
		mv	x,!base_address
		add	x,ba			; X holds the address of the file name
		mv	y,18
		add	y,x			; Y holds the current file attribute area
		mv	il,$0b			; 'Changing directory information of drive'
		mv	a,$00			; 'Reading of the directory information of drive'
		callf	!fcs
		;mv	il,[y++]		; Read the file attribute
		;pushu	i			; Save it on the stack
		;mv	i,[y++]			; Read the time information
		;pushu	i			; Save it on the stack
		;mv	i,[y++]			; Read the date information
		;pushu	i			; Save it on the stack
		;mv	i,[y++]			; Read the 16 low-order bits of the size information
		;pushu	i			; Save them on the stack
		;mv	il,[y]			; Read the 8 high-order bits of the size information
		;pushu	i			; Save it on the stack
		jrnc	lbl2
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		pops	x			; Restore IP
		jp	!interp__
lbl2:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
;-------------------------------------------------------------------------------
file_status:	dw	file_stat_
		db	$0b
		db	'FILE-STATUS'
file_status_xt:	local
		jp	!docol__xt		; : FILE-STATUS ( c-addr u -- s-addr ior )
		dw	!str_to_file_xt		;   STRING>FILE
		dw	!file_stat__xt		;   (FILE-STATUS)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
ren_file_:	dw	file_status
		db	$0d
		db	'(RENAME-FILE)'		; ( s-addr s-addr -- ior )
ren_file__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	y,x
		add	y,ba			; Y holds the address of the new file name
		popu	i
		add	x,i			; X holds the address of the initial file name
		mv	il,$0d			; 'Renaming a file'
		callf	!fcs
		jrnc	lbl2
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		pops	x			; Restore IP
		jp	!interp__
lbl2:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
;-------------------------------------------------------------------------------
rename_file:	dw	ren_file_
		db	$0b
		db	'RENAME-FILE'
rename_file_xt:	local
		jp	!docol__xt		; : RENAME-FILE ( c-addr u c-addr u -- ior )
		dw	!two_swap_xt		;   2SWAP
		dw	!str_to_file_xt		;   STRING>FILE
		dw	!not_rot_xt		;   -ROT
		dw	!which_file_xt		;   WHICH-FILE \ s-addr c-addr u s-addr
		dw	!dup_to_r_xt		;   DUP>R
		dw	!dolit__xt		;   18
		dw	18			;
		dw	!blank_xt		;   BLANK
		dw	!two_dup_xt		;   2DUP       \ s-addr c-addr u c-addr u
		dw	!doslit__xt		;   S" ."
		dw	1			;
		db	'.'			;
		dw	!search_xt		;   SEARCH
		dw	!if__xt			;   IF         \ s-addr c-addr u c-addr u
		dw	lbl2-lbl1		;
lbl1:			dw	!tuck_xt	;     TUCK     \ s-addr c-addr u u c-addr u
			dw	!dolit__xt	;     4
			dw	4		;
			dw	!min_xt		;     MIN
			dw	!r_fetch_xt	;     R@       \ s-addr c-addr u u c-addr u s-addr
			dw	!dolit__xt	;     8
			dw	8		;
			dw	!plus_xt	;     +
			dw	!swap_xt	;     SWAP     \ s-addr c-addr u u c-addr s-addr u
			dw	!c_move_xt	;     CMOVE    \ s-addr c-addr u u
		dw	!ahead__xt		;   ELSE
		dw	lbl3-lbl2		;
lbl2:			dw	!two_drop_xt	;     2DROP
			dw	!dolit0_xt	;     0 THEN   \ s-addr c-addr u 0
lbl3:		dw	!minus_xt		;   -
		dw	!dolit__xt		;   8
		dw	8			;
		dw	!min_xt			;   MIN
		dw	!r_fetch_xt		;
		dw	!swap_xt		;   SWAP       \ s-addr c-addr u
		dw	!c_move_xt		;   CMOVE
		dw	!r_from_xt		;   R@         \ s-addr s-addr
		dw	!ren_file__xt		;   (RENAME-FILE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
open_file_:	dw	rename_file
		db	$0b
		db	'(OPEN-FILE)'		; ( s-addr fam -- fileid ior )
open_file__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		popu	i
		add	x,i			; X holds the address of the filename (e.g. in FILENAME0 or FILENAME1)
		ex	a,b
		cmp	a,$00
		mv	a,$01			; 'The parameter is beyond the range'
		jrnz	lbl1
		ex	a,b			; A holds the open mode: bit0 = read, bit1 = write
		mv	il,$01			; 'Opening a file'
		callf	!fcs
		jrnc	lbl3
lbl1:		mv	il,$00			; File handle is zero when
		pushu	i			; an eror occurred
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		mv	il,(!cl)		; Read file handle
		inc	i			; Increment it (because fileIDs must start at index 1)
		pushu	i			; Save it on the stack
		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
open_file:	dw	open_file_
		db	$09
		db	'OPEN-FILE'
open_file_xt:	local
		jp	!docol__xt		; : OPEN-FILE ( c-addr u fam -- fileid ior )
		dw	!to_r_xt		;   >R
		dw	!str_to_file_xt		;   STRING>FILE
		dw	!r_from_xt		;   R>
		dw	!open_file__xt		;   (OPEN-FILE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
close_file:	dw	open_file
		db	$0a
		db	'CLOSE-FILE'		; ( fileid -- ior )
close_file_xt:	local
		pre_on
		pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	il,$02			; 'Closing a file'
		callf	!fcs
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
file_info:	dw	close_file
		db	$09
		db	'FILE-INFO'		; ( fileid -- ud ud u u ior )
file_info_xt:	local
		pre_on
		pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	il,$0a			; 'Reading various information of a file'
		mv	a,$00			; 'Reading of file size, pointer value'
		callf	!fcs
		mvw	[--u],(!si)		; Read file
		mv	il,(!si+2)		; position
		pushu	i			; and save it on the stack
		mvw	[--u],(!di)		; Read file
		mv	il,(!di+2)		; size
		pushu	i			; and save it on the stack
		mv	i,a			; I holds the open attribute
		pushu	i			; Save it on the stack
		mv	a,$00
		ex	a,b			; A holds the device attribute
		pushu	ba			; Save it on the stack
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
file_pos:	dw	file_info
		db	$0d
		db	'FILE-POSITION'
file_pos_xt:	local
		jp	!docol__xt		; : FILE-POSITION ( fileid -- ud ior )
		dw	!file_info_xt		;   FILE-INFO
		dw	!to_r_xt		;   >R
		dw	!two_drop_xt		;   2DROP
		dw	!two_drop_xt		;   2DROP
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
file_size:	dw	file_pos
		db	$09
		db	'FILE-SIZE'
file_size_xt:	local
		jp	!docol__xt		; : FILE-POSITION ( fileid -- ud ior )
		dw	!file_info_xt		;   FILE-INFO
		dw	!to_r_xt		;   >R
		dw	!two_drop_xt		;   2DROP
		dw	!two_nip_xt		;   2NIP
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
fil_end_qst:	dw	file_size
		db	$09
		db	'FILE-END?'
fil_end_qst_xt:	local
		jp	!docol__xt		; : FILE-END? ( fileid -- flag ior )
		dw	!file_info_xt		;   FILE-INFO
		dw	!to_r_xt		;   >R
		dw	!two_drop_xt		;   2DROP
		dw	!d_equals_xt		;   D=
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
read_file:	dw	fil_end_qst
		db	$09
		db	'READ-FILE'		; ( c-addr u fileid -- u ior )
read_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		popu	i			; I holds the number of bytes to read
		mv	y,i			; Save them into Y
		popu	i			; I holds the short address where to store the data
		add	x,i			; X holds the address where to store the data
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	il,$03			; 'Reading a block of the file'
		mv	a,$01			; 'File end is physical end of file'
		callf	!fcs
		mv	i,y			; I holds the number of bytes that was read correctly
		pushu	i			; Save it on the stack
		jrnc	lbl3
		cmp	a,$0c			; Test whether the specified number of bytes wasn't read
		jrz	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
read_char:	dw	read_file
		db	$09
		db	'READ-CHAR'		; ( fileid -- char ior )
read_char_xt:	local
		pre_on
		pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		mv	(bp+!el),a		; Make a copy of the file handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl2
		mv	il,$0a			; 'Reading various information of a file'
		mv	a,$00			; 'Reading of file size, pointer value'
		callf	!fcs
		jrc	lbl2
		cmpp	(!si),(!di)		; Compare file position
		;cmpw	(!si),(!di)		; Compare file position
		;jrnz	lbl1			; with
		;cmp	(!si+2),(!di+2)		; file size
		jrz	lbl2
lbl1:		mv	il,$05			; 'Reading a byte of the file'
		mv	(!cl),(bp+!el)		; Restore the file handle
		mv	a,$01			; 'File end is physical end of file'
		callf	!fcs
		jrnc	lbl4
lbl2:		mv	il,$00			; Set the value of the character to zero
		pushu	i			; (an error occurred)
		ex	a,b			; Set new TOS to $01xx where xx=$01,$06,$07,$0c,$ff
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl3:		pops	x			; Restore IP
		jp	!interp__
lbl4:		ex	a,b			; Test
		cmp	a,$00			; whether
		mv	a,$0c			; no character
		jrz	lbl2			; was read (THERE IS A BUG IN THIS PRIMITIVE
		mv	a,$00			; SO THAT THAT NEVER HAPPENS, HENCE THE ABOVE CODE
		ex	a,b			; TO TEST THE FILE POSITION)
		pushu	ba			; Save the character on the stack
		sub	ba,ba			; Set new TOS (no error)
		jr	lbl3
		pre_off
		endl
;-------------------------------------------------------------------------------
peek_char:	dw	read_char
		db	$09
		db	'PEEK-CHAR'		; ( fileid -- char ior )
peek_char_xt:	local
		pre_on
		pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	il,$08			; 'Non destructive reading a file'
		mv	a,$81			; 'File end is physical end of file, with data'
		callf	!fcs
		jrnc	lbl3
lbl1:		mv	il,$00			; Set the value of the character to zero
		pushu	i			; (an error occurred)
		ex	a,b			; Set new TOS to $01xx where xx=$01,$06,$07,$0c,$ff
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		ex	a,b			; Test
		cmp	a,$00			; whether no character was read
		mv	a,$0c			; 'Processing of byte number has not been completed.'
		jrz	lbl1
		mv	a,$00			
		ex	a,b
		pushu	ba			; Save the character on the stack
		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
chr_rdy_qst:	dw	peek_char
		db	$0b
		db	'CHAR-READY?'		; ( fileid -- flag ior )
chr_rdy_qst_xt:	local
		pre_on
		pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	il,$08			; 'Non destructive reading a file'
		mv	a,$01			; 'File end is physical end of file, without data'
		callf	!fcs
		jrnc	lbl3
		ex	a,b			; Set new TOS to $01xx where xx=$01,$06,$07,$ff
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		mv	il,$00			; Set I to FALSE
lbl2:		pushu	i			; Save I contents
		pops	x			; Restore IP
		jp	!interp__
lbl3:		ex	a,b			; Test whether
		cmp	a,0			; no character was read
		mv	ba,0			; Set new TOS (no error)
		jrz	lbl1			; 
		mv	i,-1			; Set I to TRUE
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
read_line:	dw	chr_rdy_qst
		db	$09
		db	'READ-LINE'
read_line_xt:	local
		jp	!docol__xt				; : READ-LINE ( c-addr u fileid -- u flag ior )
		dw	!dup_xt					;   DUP
		dw	!fil_end_qst_xt				;   FILE-END? \ c-addr u fileid flag ior
		dw	!quest_dup_xt				;   ?DUP
		dw	!if__xt					;   IF
		dw	lbl2-lbl1				;
lbl1:			dw	!nip_xt				;     NIP
			dw	!nip_xt				;     NIP
			dw	!doexit__xt			;     EXIT THEN
lbl2:		dw	!if__xt					;   IF
		dw	lbl4-lbl3				;
lbl3:			dw	!two_drop_xt			;     2DROP
			dw	!drop_xt			;     DROP
			dw	!dolit0_xt			;     0
			dw	!false_xt			;     FALSE
			dw	!dolit0_xt			;     0
			dw	!doexit__xt			;     EXIT THEN
lbl4:		dw	!to_r_xt				;   >R
		dw	!swap_xt				;   SWAP
		dw	!to_r_xt				;   >R       \ u ; R: fileid c-addr
		dw	!dolitm1_xt				;   -1
lbl5:			dw	!one_plus_xt			;   BEGIN 1+ \ u u
			dw	!two_dup_xt			;     2DUP
			dw	!not_equals_xt			;     <>
		dw	!if__xt					;     IF
		dw	lbl9-lbl6				;
lbl6:			dw	!r_tick_ftch_xt			;       R'@       \ u fileid
			dw	!read_char_xt			;       READ-CHAR \ u char ior
			dw	!quest_dup_xt			;       ?DUP
			dw	!if__xt				;       IF
			dw	lbl8-lbl7			;
lbl7:				dw	!nip_xt			;         NIP
				dw	!r_from_drop_xt		;         R>DROP
				dw	!r_from_drop_xt		;         R>DROP
				dw	!doexit__xt		;         EXIT THEN
lbl8:			dw	!dup_xt				;       DUP
			dw	!r_from_xt			;       R>
			dw	!tuck_xt			;       TUCK
			dw	!c_store_xt			;       C!
			dw	!one_plus_xt			;       1+
			dw	!to_r_xt			;       >R
			dw	!dolit__xt			;       10
			dw	$000a				;       \ The value of the LF character
			dw	!equals_xt			;       =
			dw	!until__xt			;       UNTIL THEN
			dw	lbl9-lbl5			;
lbl9:		dw	!nip_xt					;   NIP
		dw	!true_xt				;   TRUE
		dw	!dolit0_xt				;   0
		dw	!r_from_drop_xt				;   R>DROP
		dw	!r_from_drop_xt				;   R>DROP
		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
write_file:	dw	read_line
		db	$0a
		db	'WRITE-FILE'		; ( c-addr u fileid -- ior )
write_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		popu	i			; I holds the number of bytes to write
		mv	y,i			; Save them into Y
		popu	i			; I holds the short address where to fetch the data
		add	x,i			; X holds the address where to fetch the data
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	il,$04			; 'Writing a block of the file'
		callf	!fcs
		jrnc	lbl3
		;cmp	a,$0c			; FIXME this looks wrong; Test whether the specified number of bytes wasn't written
		;jrz	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		mv	ba,0			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
write_char:	dw	write_file
		db	$0a
		db	'WRITE-CHAR'		; ( char fileid -- ior )
write_char_xt:	local
		pre_on
		;pushs	x			; Save IP
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		popu	i			; I holds the value of the character to write
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl1
		mv	a,il			; A holds the 8 low-order bits of the character value
		mv	il,$06			; 'Writing a byte of the file'
		callf	!fcs
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		;pops	x			; Restore IP
		jp	!interp__
lbl3:		ex	a,b			; Test
		cmp	a,$00			; whether
		mv	a,$0c			; no character
		jrz	lbl1			; was written
		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
write_line:	dw	write_char
		db	$0a
		db	'WRITE-LINE'
write_line_xt:	local
		jp	!docol__xt		; : WRITE-LINE ( c-addr u fileid -- ior )
		dw	!dup_to_r_xt		;   DUP>R
		dw	!write_file_xt		;   WRITE-FILE
		dw	!quest_dup_xt		;   ?DUP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!r_from_drop_xt	;     R>DROP
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!doslit__xt		;   S\" \n"
		dw	2			;
		db	13,10			;   \ The values of the CR LF characters
		dw	!r_from_xt		;   R>
		dw	!write_file_xt		;   WRITE-FILE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
seek_set:	dw	write_line
		db	$08
		db	'SEEK-SET'
seek_set_xt:	local
		jp	!dolit0_xt		; 0 CONSTANT SEEK-SET
		endl
;-------------------------------------------------------------------------------
seek_cur:	dw	seek_set
		db	$08
		db	'SEEK-CUR'
seek_cur_xt:	local
		jp	!dolit1_xt		; 1 CONSTANT SEEK-CUR
		endl
;-------------------------------------------------------------------------------
seek_end:	dw	seek_cur
		db	$08
		db	'SEEK-END'
seek_end_xt:	local
		jp	!dolit2_xt		; 2 CONSTANT SEEK-END
		endl
;-------------------------------------------------------------------------------
seek_file:	dw	seek_end
		db	$09
		db	'SEEK-FILE'		; ( d fileid u -- ior )
seek_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	(bp+!el),a		; Save position attribute (relative from top, etc.)
		popu	ba
		dec	ba			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),a			; File handle
		;ex	a,b
		;cmp	a,$00
		;mv	a,$06			; 'Ineffective file handle was attempted'
		;jrnz	lbl3
		popu	ba			; Read the 16 high-order bits
		mv	i,ba			; I holds the 16 high-order bits
		shl	a			; Test the high-order bits for signed overflow
		ex	a,b
		adc	a,0			; $ff+cf = 0 and $00 = 0 means no signed overflow
		mv	a,$01
		jrnz	lbl4
		popu	ba
		mv	(!si+2),il		; Store the 8 last low-order ones (ignore others)
		mv	(!si),ba		; Store the 16 low-order bits
		mv	il,$09			; 'Moving a file pointer'
		mv	a,(bp+!el)		; Restore position attribute
		callf	!fcs
		jrc	lbl5
		sub	ba,ba			; No error
		jr	lbl6
lbl3:		popu	i			; Discard the 16 high-order bits
lbl4:		popu	i			; Discard the 16 low-order bits
lbl5:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl6:		pops	x			; Restore IP
		jp	!interp__
		pre_off
		endl
;-------------------------------------------------------------------------------
repos_file:	dw	seek_file
		db	$0f
		db	'REPOSITION-FILE'
repos_file_xt:	local
		jp	!docol__xt		; : REPOSITION-FILE ( ud fileid -- ior )
		dw	!seek_set_xt		;   SEEK-SET \ 'Relative value from the file top'
		dw	!seek_file_xt		;   SEEK-FILE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;verify_file:	dw	repos_file
;		db	$0b
;		db	'VERIFY-FILE'
;verify_file_xt:	local
;		pre_on
;		pushs	x			; Save IP
;		mv	x,!base_address
;		dec	ba			; Decrement it (because fileIDs start at index 1)
;		mv	(!cl),a			; File handle
;		popu	y			; Y holds the number of bytes to verify (20 bits)
;		popu	il			; Discard the 8 high-order bits of the double
;		popu	i			; I holds the short address where to find the data to be verified
;		add	x,i			; X holds the address where to find the data to be verified
;		ex	a,b
;		cmp	a,$00
;		mv	a,$06			; 'Ineffective file handle was attempted'
;		jrnz	lbl1
;		mv	il,$04			; 'Verifying a file'
;		mv	a,$01			; 'File end is physical end of file'
;		callf	!fcs
;		mv	il,$00			; Save on the stack as a double the
;		pushu	il			; number of bytes that
;		pushu	y			; was successfully verified
;		jrnc	lbl3
;lbl1:		ex	a,b			; Set new TOS
;		mv	a,$01			; (an error
;		ex	a,b			; occurred)
;lbl2:		pops	x			; Restore IP
;		jp	!interp__
;lbl3:		sub	ba,ba			; Set new TOS (no error)
;		jr	lbl2
;		pre_off
;		endl
;-------------------------------------------------------------------------------
resize_file:	dw	repos_file
		db	$0b
		db	'RESIZE-FILE'
resize_file_xt:	local
		jp	!docol__xt			; : RESIZE-FILE ( ud fileid -- ior )
		dw	!dup_xt				;   DUP
		dw	!file_size_xt			;   FILE-SIZE    \ ud fileid ud ior
		dw	!quest_dup_xt			;   ?DUP
		dw	!if__xt				;   IF
		dw	lbl2-lbl1			;
lbl1:			dw	!to_r_xt		;     >R
			dw	!two_drop_xt		;     2DROP
			dw	!drop_xt		;     DROP
			dw	!two_drop_xt		;     2DROP
			dw	!r_from_xt		;     R>
			dw	!doexit__xt		;     EXIT THEN
lbl2:		dw	!rot_xt				;   ROT          \ ud ud fileid
		dw	!to_r_xt			;   >R
		dw	!d_minus_xt			;   D-           \ Requested size minus actual size
		dw	!two_dup_xt			;   2DUP
		dw	!d_zer_g_thn_xt			;   D0>          \ Requested size is greater than actual size
		dw	!if__xt				;   IF
		dw	lbl6-lbl3			;
lbl3:			dw	!dolit0_xt		;     0
			dw	!dolit0_xt		;     0
			dw	!r_fetch_xt		;     R@
			dw	!seek_end_xt		;     SEEK-END   \ ud 0. fileid 2
			dw	!seek_file_xt		;     SEEK-FILE  \ ud ior
			dw	!quest_dup_xt		;     ?DUP
			dw	!if__xt			;     IF
			dw	lbl5-lbl4		;
lbl4:				dw	!not_rot_xt	;       -ROT
				dw	!two_drop_xt	;       2DROP
				dw	!r_from_xt	;       R>DROP
				dw	!doexit__xt	;       EXIT THEN
lbl5:			dw	!d_to_s_xt		;     D>S        \ Enlarge by up to 64K or throw -11
			dw	!dolit0_xt		;     0          \ use bytes from address 0 to fill the file
			dw	!swap_xt		;     SWAP
			dw	!r_from_xt		;     R>         \ 0 u fileid
			dw	!write_file_xt		;     WRITE-FILE \ ior
			dw	!doexit__xt		;     EXIT THEN
lbl6:		dw	!r_from_drop_xt			;   R>DROP
		dw	!dolit0_xt			;   0
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
find_file_:	dw	resize_file
		db	$0b
		db	'(FIND-FILE)'		; ( s-addr u -- s-addr u s-addr ior )
find_file__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	(!bx),ba		; Position to start searching
		call	!which_file__
		mv	y,!base_address
		add	y,ba			; Y holds current filename area address
lbl2:		mv	x,!base_address	
		popu	i
		add	x,i			; X holds the file name pattern ('?' are wildcard characters, '*' cannot be used)
		pushs	y			; Save the current filename area address
		mv	il,$0c			; 'Searching for corresponding file name'
		mv	a,$00			; 'Searching for the back of the specified directory number'
		callf	!fcs
		pops	y			; Restore the current filename area address
		mv	i,x
		pushu	i			; Save the file name pattern on the stack
		mvw	[--u],(!bx)		; Save the actual file directory position on the stack
		mv	i,y
		pushu	i			; Save the detected file name address on the stack
		jrnc	lbl5
lbl3:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl4:		pops	x			; Restore IP
		jp	!interp__
lbl5:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl4
		pre_off
		endl
;-------------------------------------------------------------------------------
find_file:	dw	find_file_
		db	$09
		db	'FIND-FILE'
find_file_xt:	local
		jp	!docol__xt		; : FIND-FILE ( c-addr u u -- c-addr u u s-addr u ior )
		dw	!to_r_xt		;   >R
		dw	!two_dup_xt		;   2DUP
		dw	!str_to_file_xt		;   STRING>FILE
		dw	!r_from_xt		;   R>          \ c-addr u s-addr u
		dw	!find_file__xt		;   (FIND-FILE) \ c-addr u s-addr u s-addr ior
		dw	!to_r_xt		;   >R          \ c-addr u s-addr u s-addr
		dw	!rot_xt			;   ROT         \ c-addr u u s-addr s-addr
		dw	!drop_xt		;   DROP        \ c-addr u u s-addr
		dw	!file_to_str_xt		;   FILE>STRING \ c-addr u u s-addr u
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
files:		dw	find_file
		db	$05
		db	'FILES'
files_xt:	local
		jp	!docol__xt			; : FILES ( optional: "glob.glob" -- )
		dw	!cr_xt				;   CR
		dw	!blnk_xt			;   BL
		dw	!parse_word_xt			;   PARSE-WORD
		dw	!dup_xt				;   DUP
		dw	!zero_equals_xt			;   0=
		dw	!if__xt				;   IF
		dw	lbl2-lbl1			;
lbl1:			dw	!two_drop_xt		;     2DROP
			dw	!doslit__xt		;     S" *.*"   \ Show all files
			dw	3			; 
			db	'*.*'			;   THEN
lbl2:		dw	!dolit0_xt			;   0           \ Directory index for first iocs call
		dw	!dolit0_xt			;   0           \ Loop (infinite)
		dw	!dolit1_xt			;   1           \ c-addr u 0 0 1
		dw	!do__xt				;   DO          \ c-addr u u
		dw	lbl9-lbl3			;
lbl3:			dw	!find_file_xt		;     FIND-FILE \ c-addr u u s-addr u ior
			dw	!if__xt			;     IF
			dw	lbl5-lbl4		;
lbl4:				dw	!two_drop_xt	;       2DROP
				dw	!leave__xt	;       LEAVE THEN
lbl5:			dw	!over_xt		;     OVER
			dw	!to_r_xt		;     >R
			dw	!type_xt		;     TYPE
			dw	!r_from_xt		;     R>            \ c-addr u u s-addr
			dw	!file_stat__xt		;     (FILE-STATUS) \ c-addr u u s-addr ior
			dw	!drop_xt		;     DROP
			dw	!dolit__xt		;     23
			dw	23			;
			dw	!plus_xt		;     +             \ File size address is s-addr+18+1+2+2
			dw	!dup_xt			;     DUP
			dw	!fetch_xt		;     @
			dw	!swap_xt		;     SWAP
			dw	!two_plus_xt		;     2+
			dw	!c_fetch_xt		;     C@
			dw	!dolit__xt		;     6
			dw	6			;
			dw	!d_dot_r_xt		;     D.R
			dw	!one_plus_xt		;     1+            \ Search next file in the directory
			dw	!i_xt			;     I
			dw	!dolit3_xt		;     3
			dw	!and_xt			;     AND
			dw	!zero_equals_xt		;     0=
			dw	!tty_xt			;     TTY           \ output to screen?
			dw	!stdo_xt		;     STDO
			dw	!equals_xt		;     =
			dw	!and_xt			;     AND
			dw	!if__xt			;     IF
			dw	lbl7-lbl6		;
lbl6:				dw	!dolit__xt	;       9
				dw	9
				dw	!spaces_xt	;       SPACES
				dw	!doslit__xt	;       S" (more)"
				dw	6		;
				db	'(more)'	;
				dw	!pause_xt	;       PAUSE
				dw	!page_xt	;       PAGE
			dw	!ahead__xt		;     ELSE
			dw	lbl8-lbl7		;
lbl7:				dw	!cr_xt		;       CR THEN
lbl8:		dw	!loop__xt			;   LOOP
		dw	lbl9-lbl3			;
lbl9:		dw	!drop_xt			;   DROP
		dw	!two_drop_xt			;   2DROP
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
free_capty:	dw	files
		db	$0d
		db	'FREE-CAPACITY'		; ( c-addr u -- du ior )
free_capty_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		popu	ba			; Discard the length of the string (':' is the terminator)
		add	x,ba			; X holds the address of the string
		mv	il,$0f			; 'Reading a free capacity of drive'
		mv	a,$00			; Required
		callf	!fcs
		mvw	[--u],(!si)		; Push on the stack the free
		mv	il,(!si+2)		; capacity
		pushu	i			; as a double
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		jp	!interp__
lbl3:		sub	ba,ba			; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
;-------------------------------------------------------------------------------
;
;		KEYBOARD INPUT
;
;-------------------------------------------------------------------------------
to_key_buff:	dw	free_capty
		db	$0b
		db	'>KEY-BUFFER'		; ( c-addr u -- )
to_key_buff_xt:	local
		pre_on
		mv	i,[($e6)+$14]		; I holds the size of the input buffer
		sub	i,ba			; Test if the number of bytes to send does not exceed
		jrnc	lbl1			; the size of the buffer
		mv	ba,[($e6)+$14]		; (else set BA to this size)
lbl1:		popu	i			; I holds the short address of the data to send
		pushu	x			; Save IP
		mv	x,!base_address
		add	x,i
		mvw	(!cx),$0001		; Keyboard device driver
		mv	il,$44			; 'Data set to keyboard buffer'
		callf	!iocs
		pre_off
		popu	x			; Restore IP
		popu	ba			; Set new TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
key_clear:	dw	to_key_buff
		db	$09
		db	'KEY-CLEAR'		; ( -- )
key_clear_xt:	local
		pushu	ba			; Save TOS
		pushu	x			; Save IP
		pre_on
		mvw	(!cx),$0001		; Keyboard device driver
		mv	il,$45			; 'Key clear'
		callf	!iocs
		pre_off
		popu	x			; Restore IP
		popu	ba			; Restore TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
inkey:		dw	key_clear
		db	$05
		db	'INKEY'			; ( -- char )
inkey_xt:	local
		pushu	ba			; Save TOS
		pushu	x			; Save IP
		pre_on
		mvw	(!cx),$0001		; Keyboard device driver
		mv	il,$45			; 'Key clear'
		callf	!iocs
		pre_off
		mv	ba,[$bfcb5]		; Read key buffer
		cmp	a,$00
		ex	a,b
		jrz	lbl2
		cmp	a,$00
		jrz	lbl1
		mv	a,$00
		jr	lbl2
lbl1:		ex	a,b
lbl2:		mv	y,_table		; Perform
		add	y,a			; conversion of
		mv	a,[y]			; the code
		popu	x			; Restore IP
		jp	!interp__		; BA holds a one-byte code corresponding to key pressed
_table:		db	$00,$10,$16,$1b,$0a,$08,$09,$14,$17,$15,$01,$0c,$02,$0d,$1e,$00	; The
		db	$00,$00,$0b,$f1,$f2,$f3,$f4,$f5,$00,$00,$00,$00,$0e,$0f,$04,$05	; conversion
		db	$30,$31,$32,$33,$34,$35,$36,$37,$38,$39,$2a,$2b,$2c,$2d,$2e,$2f	; table
		db	$20,$41,$42,$43,$44,$45,$46,$47,$48,$49,$4a,$4b,$4c,$4d,$4e,$4f	; (from matrix
		db	$50,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5a,$3d,$3b,$28,$29,$00	; code to
		db	$11,$95,$96,$97,$13,$85,$9b,$91,$92,$87,$03,$1f,$5e,$fc,$88,$1a	; BASIC
		db	$06,$07								; code)
		endl
;-------------------------------------------------------------------------------
e_key_quest:	dw	inkey
		db	$05
		db	'EKEY?'
e_key_quest_xt:	local
		jp	!docol__xt		; : EKEY? ( -- flag )
		dw	!stdi_xt		;   STDI
		dw	!chr_rdy_qst_xt		;   CHAR-READY?
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -57
			dw	-57		;     \ Exception in sending or receiving a character
			dw	!throw_xt	;     THROW
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
e_key:		dw	e_key_quest
		db	$04
		db	'EKEY'
e_key_xt:	local
		jp	!docol__xt		; : EKEY ( -- x )
		dw	!cursor_xt		;   CURSOR
		dw	!fetch_xt		;   @
		dw	!set_cursor_xt		;   SET-CURSOR \ enable cursor
		dw	!stdi_xt		;   STDI
		dw	!read_char_xt		;   READ-CHAR
		dw	!dolit0_xt		;   0
		dw	!set_cursor_xt		;   SET-CURSOR \ disable cursor
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -57
			dw	-57		;     \ Exception in sending or receiving a character
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!quest_dup_xt		;   ?DUP
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!doexit__xt	;     EXIT THEN
lbl4:		dw	!stdi_xt		;   STDI
		dw	!read_char_xt		;   READ-CHAR
		dw	!drop_xt		;   DROP
		dw	!negate_xt		;   NEGATE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
e_key_to_ch:	dw	e_key
		db	$09
		db	'EKEY>CHAR'
e_key_to_ch_xt:	local
		jp	!docol__xt		; : EKEY-CHAR ( x -- char flag )
		dw	!dup_xt			;   DUP
		dw	!zer_grt_thn_xt		;   0>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
key_quest:	dw	e_key_to_ch
		db	$04
		db	'KEY?'
key_quest_xt:	local
		jp	!docol__xt			; : KEY? ( -- flag )
lbl1:		dw	!e_key_quest_xt			;   BEGIN EKEY?
		dw	!if__xt				;   WHILE
		dw	lbl5-lbl2			;
lbl2:			dw	!stdi_xt		;     STDI
			dw	!peek_char_xt		;     PEEK-CHAR
			dw	!drop_xt		;     DROP
			dw	!if__xt			;     IF
			dw	lbl4-lbl3		;
lbl3:				dw	!true_xt	;       TRUE
				dw	!doexit__xt	;       EXIT THEN
lbl4:			dw	!stdi_xt		;     STDI
			dw	!read_char_xt		;     READ-CHAR
			dw	!two_drop_xt		;     2DROP
			dw	!again__xt		;   REPEAT
			dw	lbl5-lbl1		;
lbl5:		dw	!false_xt			;   FALSE
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
key:		dw	key_quest
		db	$03
		db	'KEY'
key_xt:		local
		jp	!docol__xt		; : KEY ( -- char )
lbl1:		dw	!e_key_xt		;   BEGIN EKEY
			dw	!dup_xt		;     DUP
			dw	!zer_lss_thn_xt	;     0<
		dw	!if__xt			;   WHILE	\ Ignore special keys
		dw	lbl3-lbl2		;
lbl2:			dw	!drop_xt	;     DROP
			dw	!again__xt	;   REPEAT
			dw	lbl3-lbl1	;
lbl3:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		LCD SCREEN SYMBOLS/ANNUNCIATORS
;
;-------------------------------------------------------------------------------
set_symbols:	dw	key
		db	$0b
		db	'SET-SYMBOLS'		; ( u u -- )
set_symbols_xt:	local
		pushs	x			; Save IP
		pre_on
		mv	(!bl),a			; Store the symbol number
		popu	ba			; BA (A, in fact) holds the pattern to display
		mvw	(!cx),$0000		; LCD driver
		mv	il,$46			; 'Symbol display'
		callf	!iocs
		pre_off
		pops	x			; Restore IP
		popu	ba			; Set new TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
busy_on:	dw	set_symbols
		db	$07
		db	'BUSY-ON'
busy_on_xt:	local
		jp	!docol__xt		; : BUSY-ON ( -- )
		dw	!dolit1_xt		;   1 \ turn on
		dw	!dolit1_xt		;   1 \ busy
		dw	!set_symbols_xt		;   SET-SYMBOLS
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
busy_off:	dw	busy_on
		db	$08
		db	'BUSY-OFF'
busy_off_xt:	local
		jp	!docol__xt		; : BUSY-OFF ( -- )
		dw	!dolit0_xt		;   0 \ turn off
		dw	!dolit1_xt		;   1 \ busy
		dw	!set_symbols_xt		;   SET-SYMBOLS
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		CURSOR SHAPE
;
;-------------------------------------------------------------------------------
cursor:		dw	busy_off
		db	$06
		db	'CURSOR'
cursor_xt:	local
		jp	!dovar__xt		; VARIABLE CURSOR $28 CURSOR !
		dw	$20+$08+$00		; Cursor enabled, blink, underline
		endl
;-------------------------------------------------------------------------------
set_cursor:	dw	cursor
		db	$0a
		db	'SET-CURSOR'		; ( u -- )
set_cursor_xt:	local
		pushu	x
		pre_on
		mvw	(!cx),$0000		; LCD driver
		mv	il,$45			; 'Setting the type of cursor display'
		callf	!iocs
		pre_off
		popu	x
		popu	ba			; Set new TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
;
;		PRINTER
;
;-------------------------------------------------------------------------------
printer:	dw	set_cursor
		db	$07
		db	'PRINTER'		; ( -- n )
printer_xt:	local
		pushu	ba			; Save TOS
		pre_on
		mvw	(!cx),$0003		; Printer
		mv	il,$40			; 'Initialization of each parameter'
		mv	a,$03			; On
		callf	!iocs
		mvw	(!cx),$0003		; Printer
		mv	il,$43			; 'Printer check'
		callf	!iocs
		mv	ba,i
		jrnc	lbl1
		sub	ba,ba			; Set TOS to zero (printer not connected)
lbl1:		jp	!interp__
		pre_off
		endl
;-------------------------------------------------------------------------------
;
;		OUTPUT
;
;-------------------------------------------------------------------------------
tty:		dw	printer
		db	$03
		db	'TTY'
tty_xt:		local
		jp	!doval__xt		; 1 VALUE TTY
		dw	$0001			; The fileid of the output device
		endl
;-------------------------------------------------------------------------------
emit:		dw	tty
		db	$04
		db	'EMIT'			; : EMIT ( char -- )
emit_xt:	local
		pre_on
		mv	i,[!tty_xt+3]		; The current output device file handle
		dec	i			; Decrement it (because fileIDs start at index 1)
		mv	(!cl),il
		mv	il,$06			; 'Writing a byte of the file'
		callf	!fcs
		jrc	lbl1
		popu	ba			; Set new TOS
		jp	!interp__
lbl1:		cmp	a,$ff			; Test if break key has been pushed
		;mv	i,[!handler_xt+3]	; Test whether there is
		;inc	i			; a handler for this exception or not
		;dec	i			;
		jpz	!break__
		mv	il,-57			; Exception in sending or receiving a character
		jp	!throw__
		pre_off
		endl
;-------------------------------------------------------------------------------
cr:		dw	emit
		db	$02
		db	'CR'
cr_xt:		local
		jp	!docol__xt		; : CR ( -- )
		dw	!dolit__xt		;   $0d
		dw	$000d			;   \ The value of the carriage return character
		dw	!emit_xt		;   EMIT
		dw	!dolit__xt		;   $0a
		dw	$000a			;   \ The value of the line feed character
		dw	!emit_xt		;   EMIT
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
space:		dw	cr
		db	$05
		db	'SPACE'
space_xt:	local
		jp	!docol__xt		; : SPACE ( -- )
		dw	!blnk_xt		;   BL
		dw	!emit_xt		;   EMIT
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
spaces:		dw	space
		db	$06
		db	'SPACES'
spaces_xt:	local
		jp	!docol__xt		; : SPACES ( n -- )
		dw	!dup_xt			;   DUP
		dw	!zer_lss_thn_xt		;   0<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!drop_xt	;     DROP
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!dolit0_xt		;   0
		dw	!quest_do__xt		;   ?DO
		dw	lbl4-lbl3		;
lbl3:			dw	!space_xt	;     SPACE
		dw	!loop__xt		;   LOOP
		dw	lbl4-lbl3		;
lbl4:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
page:		dw	spaces
		db	$04
		db	'PAGE'			; ( -- )
page_xt:	local
		pushu	ba			; Save TOS
		mv	il,0			; Set x and y coordinates
		mv	[$bfc27],i		; of both next position to print
		mv	[$bfc9b],i		; and cursor to zero
		pre_on
		mv	(!cx),i			; LCD driver
		mv	il,$51			; 'Clearing of display 1'
		callf	!iocs
		pre_off
		popu	ba			; Restore TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
x_fetch:	dw	page
		db	$02
		db	'X@'			; ( -- u )
x_fetch_xt:	local
		pushu	ba			; Save old TOS
		sub	ba,ba			; Clear B
		mv	a,[$bfc9b]		; BA holds x location
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
x_store:	dw	x_fetch
		db	$02
		db	'X!'			; ( u -- )
x_store_xt:	local
		mv	il,[$bfc9d]		; The maximum length of a line
		dec	i
		sub	i,ba			; Test if the value is not out of range
		jrnc	lbl1
		add	ba,i			; Set the value to its upper bound
lbl1:		mv	[$bfc27],a
		mv	[$bfc9b],a
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
y_fetch:	dw	x_store
		db	$02
		db	'Y@'			; ( -- u )
y_fetch_xt:	local
		pushu	ba			; Save old TOS
		sub	ba,ba			; Clear B
		mv	a,[$bfc9c]		; BA holds y location
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
y_store:	dw	y_fetch
		db	$02
		db	'Y!'			; ( u -- )
y_store_xt:	local
		mv	il,[$bfc9e]		; The maximum number of lines
		dec	i
		sub	i,ba			; Test if the value is not out of range
		jrnc	lbl1
		add	ba,i			; Set the value to its upper bound
lbl1:		mv	[$bfc28],a
		mv	[$bfc9c],a
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
x_max_fetch:	dw	y_store
		db	$05
		db	'XMAX@'			; ( -- u )
x_max_fetch_xt:	local
		pushu	ba			; Save old TOS
		sub	ba,ba			; Clear B
		mv	a,[$bfc9d]		; BA holds max x
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
x_max_store:	dw	x_max_fetch
		db	$05
		db	'XMAX!'			; ( u -- )
x_max_store_xt:	local
		mv	[$bfc9d],a
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
y_max_fetch:	dw	x_max_store
		db	$05
		db	'YMAX@'			; ( -- u )
y_max_fetch_xt:	local
		pushu	ba			; Save old TOS
		sub	ba,ba			; Clear B
		mv	a,[$bfc9e]		; BA holds max y
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
y_max_store:	dw	y_max_fetch
		db	$05
		db	'YMAX!'			; ( u -- )
y_max_store_xt:	local
		mv	[$bfc9e],a
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
at_x_y:		dw	y_max_store
		db	$05
		db	'AT-XY'
at_x_y_xt:	local
		jp	!docol__xt		; : AT-XY ( u u -- )
		dw	!y_store_xt		;   Y!
		dw	!x_store_xt		;   X!
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
type_:		dw	at_x_y
		db	$06
		db	'(TYPE)'		; ( c-addr u u -- )
type__xt:	local
		mv	(!el),[$bfca1]		; Save display mode
		or	a,(!el)			; Set display
		mv	[$bfca1],a		; mode (normal/reverse...)
		mv	i,[!tty_xt+3]		; The current output device file handle
		dec	i			; Decrement it (because fileIDs start at index 1)
		pre_on
		mv	(!cl),il
		popu	ba			; BA holds the length of the string to display
		popu	i			; I holds the short address of the string to display
		pushs	x			; Save IP
		mv	x,!base_address		; X contains the address
		add	x,i			; of the character string
		mv	y,ba			; Y holds the number of characters into the string
		mv	il,$04			; 'Writing a block of the file'
		callf	!fcs
		pre_off
		mv	[$bfca1],(!el)		; Restore display mode
		pops	x			; Restore IP
		jrc	lbl1
		popu	ba			; Set new TOS
		jp	!interp__
lbl1:		cmp	a,$ff			; Test if break key has been pushed
		;mv	i,[!handler_xt+3]	; Test whether there is
		;inc	i			; a handler for this exception or not
		;dec	i			;
		jpz	!break__
		mv	il,-57			; Exception in sending or receiving a character
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
type:		dw	type_
		db	$04
		db	'TYPE'
type_xt:	local
		jp	!docol__xt		; : TYPE ( c-addr u -- )
		dw	!dolit0_xt		;   0 \ Normal display mode 0
		dw	!type__xt		;   (TYPE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
rev_type:	dw	type
		db	$0c
		db	'REVERSE-TYPE'
rev_type_xt:	local
		jp	!docol__xt		; : REVERSE-TYPE ( c-addr u -- )
		dw	!dolit__xt		;   $40
		dw	$0040			;   \ Bit 6 is 1: display in reverse mode
		dw	!type__xt		;   (TYPE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
pause:		dw	rev_type
		db	$05
		db	'PAUSE'
pause_xt:	local
		jp	!docol__xt		; : PAUSE ( c-addr u -- )
		dw	!tty_xt			;   TTY    	\ Output to screen?
		dw	!stdo_xt		;   STDO
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF		\ No, drop args and return
		dw	lbl2-lbl1		;
lbl1:			dw	!two_drop_xt	;     2DROP
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!rev_type_xt		;   REVERSE-TYPE
		dw	!dolit__xt		;   ['] EKEY
		dw	!e_key_xt		;
		dw	!catch_xt		;   CATCH
		dw	!if__xt			;   IF		\ BREAK pressed?
		dw	lbl4-lbl3		;
lbl3:			dw	!abort_xt	;     ABORT THEN
lbl4:		dw	!dolit__xt		;   $0c
		dw	$0c			;   \ C/CE key code
		dw	!equals_xt		;   =		\ C/CE pressed?
		dw	!if__xt			;   IF
		dw	lbl6-lbl5		;
lbl5:			dw	!abort_xt	;     ABORT THEN
lbl6:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		LCD SCREEN OUTPUT
;
;-------------------------------------------------------------------------------
at_type:	dw	pause
		db	$07
		db	'AT-TYPE'		; ( n n c-addr u -- )
at_type_xt:	local
		pre_on
		mv	y,ba			; Y holds the length of the character string
		pushs	x			; Save IP
		mv	x,!base_address
		popu	ba			; BA holds the short address of the character string
		add	x,ba			; X holds the address of the character string
		popu	i			; I holds the y coordinate at output position
		mv	(!bh),il		; Save its 8 low-order bits
		popu	i			; I holds the x coordinate at output position
		mv	(!bl),il		; Save its 8 low-order bits
lbl3:		mvw	(!cx),$0000		; LCD driver
		mv	il,$42			; 'Character output to arbitrary position'		
		callf	!iocs
		jrnc	lbl4
		mv	(!bl),$00		; Update the x coordinate at output position
		inc	(!bh)			; Update the y coordinate at output position
		mv	a,[$bfc9e]		; Test if the end of the
		cmp	(!bh),a			; display has been reached
		jrc	lbl3
lbl4:		pops	x			; Restore IP
		popu	ba			; Set new TOS
		jp	!interp__
		pre_off
		endl
;-------------------------------------------------------------------------------
scroll:		dw	at_type
		db	$06
		db	'SCROLL'		; ( n -- )
scroll_xt:	local
		pre_on
		pushu	x			; Save IP
		mv	i,ba			; I holds the number of lines to be scrolled
		add	i,i			; Test its sign
		jrc	lbl2
lbl1:		mv	il,$47			; 'n line scroll-up'
		jr	lbl3		
lbl2:		mv	il,$00
		sub	i,ba
		mv	ba,i
		mv	il,$48			; 'n line scroll-down'
lbl3:		mvw	(!cx),$0000
		mvw	(!bx),$0000
		callf	!iocs
		popu	x			; Restore IP
		popu	ba			; Set new TOS
		jp	!interp__
		pre_off
		endl
;-------------------------------------------------------------------------------
at_clr:		dw	scroll
		db	$06
		db	'AT-CLR'		; ( n n n -- )
at_clr_xt:	local
		pre_on
		popu	i			; y-coordinate to start to clear
		mv	(!bh),il
		popu	i			; x-coordinate to start to clear
		mv	(!bl),il
		pushu	x			; Save IP
		mvw	(!cx),$0000		; LCD driver
		mv	il,$52			; 'Clearing of display 2'
		callf	!iocs
		popu	x			; Restore IP
		popu	ba			; Restore TOS
		jp	!interp__
		pre_off
		endl
;-------------------------------------------------------------------------------
;
;		GRAPHICS
;
;-------------------------------------------------------------------------------
gmode:		dw	at_clr
		db	$05
		db	'GMODE'
gmode_xt:	local
		jp	!dovar__xt		; VARIABLE GMODE
		dw	$0000			; 0=set, 1=reset, 2=reverse
		endl
;-------------------------------------------------------------------------------
gmode_stor:	dw	gmode
		db	$06
		db	'GMODE!'
gmode__stor_xt:	local
		jp	!docol__xt		; : GMODE! ( 0|1|2 -- )
		dw	!gmode_xt		;   GMODE
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
gpoint:		dw	gmode_stor
		db	$06
		db	'GPOINT'		; ( n n -- )
gpoint_xt:	local
		pushs	x
		pre_on
		mv	y,ba
		popu	i
		mv	x,i
		mv	ba,[!gmode_xt+3]
		mvw	(!cx),$0000
		mv	il,$4c
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gpoint_qust:	dw	gpoint
		db	$07
		db	'GPOINT?'		; ( n n -- u )
gpoint_qust_xt:	local
		pushs	x
		pre_on
		mv	y,ba
		popu	i
		mv	x,i
		mvw	(!cx),$0000
		mv	il,$4d
		callf	!iocs
		pre_off
		ex	a,b
		mv	a,$00
		ex	a,b
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gline:		dw	gpoint_qust
		db	$05
		db	'GLINE'			; ( n n n n u -- )
gline_xt:	local
		pushs	x
		pre_on
		mv	[$bfc2a],ba
		mv	i,[!gmode_xt+3]
		mv	[$bfc96],i
		popu	i
		mv	(!dx),i
		popu	i
		mv	(!bx),i
		popu	i
		mv	y,i
		popu	i
		mv	x,i
		mvw	(!cx),$0000
		mv	il,$4e
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gbox:		dw	gline
		db	$04
		db	'GBOX'			; ( n n n n u -- )
gbox_xt:	local
		pushs	x
		pre_on
		mv	[$bfc2a],ba
		mv	i,[!gmode_xt+3]
		mv	[$bfc96],i
		popu	i
		mv	(!dx),i
		popu	i
		mv	(!bx),i
		popu	i
		mv	y,i
		popu	i
		mv	x,i
		mvw	(!cx),$0000
		mv	il,$4f
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gdots:		dw	gbox
		db	$05
		db	'GDOTS'			; ( n n u -- )
gdots_xt:	local
		pushs	x
		pre_on
		mv	i,[!gmode_xt+3]
		mv	[$bfc96],i
		popu	i
		mv	y,i
		popu	i
		mv	x,i
		mvw	(!cx),$0000
		mv	il,$4a
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gdots_quest:	dw	gdots
		db	$06
		db	'GDOTS?'		; ( n n -- u )
gdots_quest_xt:	local
		pushs	x
		pre_on
		mv	y,ba
		popu	i
		mv	x,i
		mvw	(!cx),$0000
		mv	il,$4b
		callf	!iocs
		pre_off
		ex	a,b
		mv	a,$00
		ex	a,b
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gdraw:		dw	gdots_quest
		db	$05
		db	'GDRAW'
gdraw_xt:	local
		jp	!docol__xt		; : GDRAW ( n n c-addr u -- )
		dw	!two_swap_xt		;   2SWAP
		dw	!two_to_r_xt		;   2>R
lbl1:			dw	!dup_xt		;   BEGIN DUP
		dw	!if__xt			;   WHILE
		dw	lbl3-lbl2		;
lbl2:			dw	!next_char_xt	;     NEXT-CHAR \ c-addr u char
			dw	!two_r_fetch_xt	;     2R@
			dw	!rot_xt		;     ROT       \ c-addr u n n char
			dw	!gdots_xt	;     GDOTS
			dw	!two_r_from_xt	;     2R>
			dw	!swap_xt	;     SWAP
			dw	!one_plus_xt	;     1+
			dw	!swap_xt	;     SWAP
			dw	!two_to_r_xt	;     2>R
			dw	!again__xt	;   REPEAT
			dw	lbl3-lbl1	;
lbl3:		dw	!r_from_drop_xt		;   R>DROP
		dw	!r_from_drop_xt		;   R>DROP
		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
gblit_store:	dw	gdraw
		db	$06
		db	'GBLIT!'		; ( u addr -- )
gblit_store_xt:	local
		pushs	x
		pre_on
		mv	x,!base_address
		add	x,ba			; Address of 240 bytes 8-dot data to copy from the screen
		popu	i
		mv	(!bh),il		; y coordinate (line 0 to 3) on screen
		mvw	(!cx),$0000
		mv	il,$55
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
gblit_fetch:	dw	gblit_store
		db	$06
		db	'GBLIT@'		; ( u addr -- )
gblit_fetch_xt:	local
		pushs	x
		pre_on
		mv	x,!base_address
		add	x,ba			; Address of 240 bytes 8-dot data to copy to the screen
		popu	i
		mv	(!bh),il		; y coordinate (line 0 to 3) on screen to write the data to
		mvw	(!cx),$0000
		mv	il,$56
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
;
;		SOUND
;
;-------------------------------------------------------------------------------
beep_:		dw	gblit_fetch
		db	$06
		db	'(BEEP)'		; ( u u -- )
beep__xt:	local
		mv	y,ba			; Y holds the duration of the beep
		popu	ba			; BA holds the frequency of the beep
		inc	y			; Test whether duration
		dec	y			; is zero or not
		jrz	lbl2
		pushu	imr			; Disable interruptions
		pre_on
lbl1:		mv	i,ba
		or	($fd),$10		; Set bit 4 of $fd to 1 (emit sound)
		wait
		mv	i,ba
		and	($fd),$ef		; Set bit 4 of $fd to 0 (no sound)
		wait
		dec	y
		jrnz	lbl1
		pre_off
		popu	imr			; Enable interruptions
lbl2:		popu	ba			; Set new TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
beep:		dw	beep_
		db	$04
		db	'BEEP'
beep_xt:	local
		jp	!docol__xt		; : BEEP ( u u -- )
		dw	!over_xt		;   OVER
		dw	!dolit__xt		;   11
		dw	11			;
		dw	!plus_xt		;   +
		dw	!dolit__xt		;   100
		dw	100			;
		dw	!swap_xt		;   SWAP
		dw	!star_slash_xt		;   */
		dw	!beep__xt		;   (BEEP)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		NUMBER BASE
;
;-------------------------------------------------------------------------------
base:		dw	beep
		db	$04
		db	'BASE'
base_xt:	local
		jp	!dovar__xt		; BASE is 10 by default 
		dw	10
		endl
;-------------------------------------------------------------------------------
decimal:	dw	base
		db	$07
		db	'DECIMAL'
decimal_xt:	local
		jp	!docol__xt		; : DECIMAL ( -- )
		dw	!dolit__xt		;   10
		dw	10			;
		dw	!base_xt		;   BASE
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
hex:		dw	decimal
		db	$03
		db	'HEX'
hex_xt:		local
		jp	!docol__xt		; : HEX ( -- )
		dw	!dolit__xt		;   16
		dw	16			;
		dw	!base_xt		;   BASE
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		FORTH POINTERS
;
;-------------------------------------------------------------------------------
here:		dw	hex
		db	$04
		db	'HERE'			; ( -- addr )
here_xt:	local
		pushu	ba
		mv	ba,(!wi)		; BA holds the data space pointer
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
sp_store:	dw	here
		db	$03
		db	'SP!'			; ( addr -- )
sp_store_xt:	local
		pushs	imr
		mv	u,!base_address
		add	u,ba
		pops	imr
		popu	ba			; Set new TOS and increment SP by two
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
sp_fetch:	dw	sp_store
		db	$03
		db	'SP@'			; ( -- addr )
sp_fetch_xt:	local
		pushu	ba			; Save TOS
		mv	ba,u			; U holds the parameter stack pointer
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
rp_store:	dw	sp_fetch
		db	$03
		db	'RP!'			; ( addr -- )
rp_store_xt:	local
		pushu	imr
		mv	s,!base_address
		add	s,ba
		popu	imr
		popu	ba
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
rp_fetch:	dw	rp_store
		db	$03
		db	'RP@'			; ( -- addr )
rp_fetch_xt:	local
		pushu	ba
		mv	ba,s			; S holds the return stack pointer
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
depth:		dw	rp_fetch
		db	$05
		db	'DEPTH'
depth_xt:	local
		jp	!docol__xt		; : DEPTH ( -- u )
		dw	!dolit__xt		;   #s_beginning - 4
		dw	!s_beginning-4		;
		dw	!sp_fetch_xt		;   SP@
		dw	!minus_xt		;   -
		dw	!two_slash_xt		;   2/
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
clear:		dw	depth
		db	$05
		db	'CLEAR'
clear_xt:	local
		jp	!docol__xt		; : CLEAR ( ... -- )
		dw	!dolit__xt		;   #s_beginning - 2 (-2 accounts for new TOS)
		dw	!s_beginning-2		;
		dw	!sp_store_xt		;   SP! \ Set SP to s_beginning (SP! pops TOS)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		EXCEPTIONS
;
;-------------------------------------------------------------------------------
handler:	dw	clear
		db	$07
		db	'HANDLER'
handler_xt:	local
		jp	!dovar__xt		; VARIABLE HANDLER
		dw	0			; Holds saved RP
		endl
;-------------------------------------------------------------------------------
catch:		dw	handler
		db	$05
		db	'CATCH'
catch_xt:	local
		jp	!docol__xt		; : CATCH ( i*x xt -- j*x 0 | i*x n )
		dw	!sp_fetch_xt		;   SP@
		dw	!to_r_xt		;   >R
;		dw	!fp_fetch_xt		;   FP@
;		dw	!to_r_xt		;   >R
		dw	!handler_xt		;   HANDLER
		dw	!fetch_xt		;   @
		dw	!to_r_xt		;   >R
		dw	!rp_fetch_xt		;   RP@
		dw	!handler_xt		;   HANDLER
		dw	!store_xt		;   !
		dw	!execute_xt		;   EXECUTE
		dw	!r_from_xt		;   R>
		dw	!handler_xt		;   HANDLER
		dw	!store_xt		;   !
		dw	!r_from_drop_xt		;   R>DROP
		dw	!dolit0_xt		;   0
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
throw:		dw	catch
		db	$05
		db	'THROW'
throw_xt:	local
		jp	!docol__xt		; : THROW ( k*x n -- k*x | i*x n )
		dw	!quest_dup_xt		;   ?DUP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!handler_xt	;     HANDLER
			dw	!fetch_xt	;     @
			dw	!rp_store_xt	;     RP!
			dw	!r_from_xt	;     R>
			dw	!handler_xt	;     HANDLER
			dw	!store_xt	;     !
;			dw	!r_from_xt	;     R>
;			dw	!fp_store_xt	;     FP!
			dw	!r_from_xt	;     R>
			dw	!swap_xt	;     SWAP
			dw	!to_r_xt	;     >R
			dw	!sp_store_xt	;     SP!
			dw	!drop_xt	;     DROP
			dw	!r_from_xt	;     R> THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
abort:		dw	throw
		db	$05
		db	'ABORT'
abort_xt:	local
		jp	!docol__xt		; : ABORT ( -- )
		dw	!dolitm1_xt		;   -1 \ ABORT
		dw	!throw_xt		;   THROW
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
abort_qte_:	dw	abort
		db	$08
		db	'(ABORT")'
abort_qte__xt:	local
		jp	!docol__xt			; : (ABORT") ( x c-addr u -- )
		dw	!rot_xt				;   ROT
		dw	!if__xt				;   IF
		dw	lbl5-lbl1			;
lbl1:			dw	!handler_xt		;     HANDLER
			dw	!fetch_xt		;     @
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl3-lbl2		;
lbl2:				dw	!two_drop_xt	;       2DROP
			dw	!ahead__xt		;     ELSE
			dw	lbl4-lbl3		;
lbl3:				dw	!type_xt	;       TYPE THEN
lbl4:			dw	!dolit__xt		;     -2
			dw	-2			;     \ ABORT"
			dw	!throw_xt		;     THROW THEN
lbl5:		dw	!two_drop_xt			;   2DROP
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
abort_quote:	dw	abort_qte_
		db	$86
		db	'ABORT"'
abort_quote_xt:	local
		jp	!docol__xt		; : ABORT" ( "ccc<quote>" -- ; x -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!s_quote_xt		;   POSTPONE S"
		dw	!dolit__xt		;   ['] (ABORT") \ POSTPONE (ABORT")
		dw	!abort_qte__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
;
;		COMPILATION
;
;-------------------------------------------------------------------------------
state:		dw	abort_quote
		db	$05
		db	'STATE'
state_xt:	local
		jp	!dovar__xt		; VARIABLE STATE
		dw	0
		endl
;-------------------------------------------------------------------------------
last:		dw	state
		db	$04
		db	'LAST'
last_xt:	local
		jp	!doval__xt		; startup VALUE LAST
		dw	!startup		; The value of the last compiled definition
		endl
;-------------------------------------------------------------------------------
lastxt:		dw	last
		db	$07
		db	'LAST-XT'
lastxt_xt:	local
		jp	!doval__xt		; startup_xt VALUE LAST-XT
		dw	!startup_xt		; The value of the last compiled XT
		endl
;-------------------------------------------------------------------------------
quest_comp:	dw	lastxt
		db	$05
		db	'?COMP'
quest_comp_xt:	local
		jp	!docol__xt		; : ?COMP ( -- )
		dw	!state_xt		;   STATE
		dw	!fetch_xt		;   @
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!dolit__xt		;   -14
		dw	-14			;   \ Interpreting a compile-only word
		dw	!throw_xt		;   THROW
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
colon_sys_:	dw	quest_comp
		db	$0b
		db	'(COLON-SYS)'
colon_sys__xt:	local
		jp	!dovar__xt		; 'colon-sys' magic number (address)
		;dw	8334			; 'colon-sys' magic number
		endl
;-------------------------------------------------------------------------------
orig_:		dw	colon_sys_
		db	$06
		db	'(ORIG)'
orig__xt:	local
		jp	!dovar__xt		; 'orig' magic number (address)
		;dw	7328			; 'orig' magic number
		endl
;-------------------------------------------------------------------------------
dest_:		dw	orig_
		db	$06
		db	'(DEST)'
dest__xt:	local
		jp	!dovar__xt		; 'dest' magic number (address)
		;dw	2194			; 'dest' magic number
		endl
;-------------------------------------------------------------------------------
do_sys_:	dw	dest_
		db	$08
		db	'(DO-SYS)'
do_sys__xt:	local
		jp	!dovar__xt		; 'do-sys' magic number (address)
		;dw	6973			; 'do-sys' magic number
		endl
;-------------------------------------------------------------------------------
cs_push:	dw	do_sys_
		db	$07
		db	'CS-PUSH'
cs_push_xt:	local
		jp	!cont__			; Does nothing, since the C stack is the data stack in this implementation
		endl
;-------------------------------------------------------------------------------
cs_pop:		dw	cs_push
		db	$06
		db	'CS-POP'
cs_pop_xt:	local
		jp	!cont__			; Does nothing, since the C stack is the data stack in this implementation
		endl
;-------------------------------------------------------------------------------
cs_drop:	dw	cs_pop
		db	$07
		db	'CS-DROP'
cs_drop_xt:	local
		jp	!two_drop_xt		; Same as 2DROP, since the C stack is the data stack in this implementation
		endl
;-------------------------------------------------------------------------------
cs_pick:	dw	cs_drop
		db	$07
		db	'CS-PICK'
cs_pick_xt:	local
		jp	!docol__xt		; : CS-PICK
		dw	!two_star_xt		;   2*
		dw	!one_plus_xt		;   1+
		dw	!dup_to_r_xt		;   DUP>R
		dw	!pick_xt		;   PICK
		dw	!r_from_xt		;   R>
		dw	!pick_xt		;   PICK
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
cs_roll:	dw	cs_pick
		db	$07
		db	'CS-ROLL'
cs_roll_xt:	local
		jp	!docol__xt		; : CS-ROLL
		dw	!two_star_xt		;   2*
		dw	!one_plus_xt		;   1+
		dw	!dup_to_r_xt		;   DUP>R
		dw	!roll_xt		;   ROLL
		dw	!r_from_xt		;   R>
		dw	!roll_xt		;   ROLL
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
left_brkt:	dw	cs_roll
		db	$81
		db	'['
left_brkt_xt:	local
		jp	!docol__xt		; : [ ( -- )
		dw	!state_xt		;   STATE
		dw	!off_xt			;   OFF
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
right_brkt:	dw	left_brkt
		db	$01
		db	']'
right_brkt_xt:	local
		jp	!docol__xt		; : ] ( -- )
		dw	!state_xt		;   STATE
		dw	!on_xt			;   ON
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
hide:		dw	right_brkt
		db	$04
		db	'HIDE'
hide_xt:	local
		jp	!docol__xt		; : HIDE ( -- )
		dw	!last_xt		;   LAST
		dw	!two_plus_xt		;   2+   / same as L>NAME
		dw	!dup_xt			;   DUP
		dw	!c_fetch_xt		;   C@
		dw	!dolit__xt		;   $40
		dw	$40			;   / smudge bit
		dw	!or_xt			;   OR
		dw	!swap_xt		;   SWAP
		dw	!c_store_xt		;   C!
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
reveal:		dw	hide
		db	$06
		db	'REVEAL'
reveal_xt:	local
		jp	!docol__xt		; : REVEAL ( -- )
		dw	!last_xt		;   LAST
		dw	!two_plus_xt		;   2+   / same as L>NAME
		dw	!dup_xt			;   DUP
		dw	!c_fetch_xt		;   C@
		dw	!dolit__xt		;   $bf
		dw	$00bf			;   / inverted smudge bit
		dw	!and_xt			;   AND
		dw	!swap_xt		;   SWAP
		dw	!c_store_xt		;   C!
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
immediate:	dw	reveal
		db	$09
		db	'IMMEDIATE'
immediate_xt:	local
		jp	!docol__xt		; : IMMEDIATE ( -- )
		dw	!last_xt		;   LAST
		dw	!two_plus_xt		;   2+   / same as L>NAME
		dw	!dup_xt			;   DUP
		dw	!c_fetch_xt		;   C@
		dw	!dolit__xt		;   128
		dw	$0080			;   / immediate bit
		dw	!or_xt			;   OR
		dw	!swap_xt		;   SWAP
		dw	!c_store_xt		;   C!
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;recursive:	dw	immediate
;		db	$89
;		db	'RECURSIVE'
;recursive_xt:	local
;		jp	!docol__xt		; : RECURSIVE ( -- ; -- )
;		dw	!quest_comp_xt		;   ?COMP
;		dw	!reveal_xt		;   REVEAL
;		dw	!doret__xt		; ; IMMEDIATE
;		endl
;-------------------------------------------------------------------------------
;
;		PARSING
;
;-------------------------------------------------------------------------------
fib:		dw	immediate
		db	$03
		db	'FIB'
fib_xt:		local
		jp	!dovar__xt		; CREATE FIB #ib_size ALLOT
		ds	!ib_size
		endl
;-------------------------------------------------------------------------------
tib:		dw	fib
		db	$03
		db	'TIB'
tib_xt:		local
		jp	!dovar__xt		; CREATE TIB #ib_size ALLOT
		ds	!ib_size
		endl
;-------------------------------------------------------------------------------
to_in:		dw	tib
		db	$03
		db	'>IN'
to_in_xt:	local
		jp	!dovar__xt		; VARIABLE >IN
		dw	0			; The offset in characters from the beginning of the
		endl				; input buffer to the current position
;-------------------------------------------------------------------------------
source_id:	dw	to_in
		db	$09
		db	'SOURCE-ID'
source_id_xt:	local
		jp	!doval__xt		; 0 VALUE SOURCE-ID
		dw	0
		endl
;-------------------------------------------------------------------------------
source:		dw	source_id
		db	$06
		db	'SOURCE'
source_xt:	local
		jp	!do2val__xt		; TIB 0 2VALUE SOURCE
		dw	0			; The number of characters in the input buffer
		dw	!tib_xt+3		; The address of the input buffer (e.g. FIB or TIB)
		endl
;-------------------------------------------------------------------------------
;source_:	dw	source_id
;		db	$08
;		db	'(SOURCE)'
;source__xt:	local
;		jp	!dovar__xt		; CREATE (SOURCE) 0 , TIB ,
;		dw	0			; The number of characters in the input buffer, like #TIB or #FIB
;		dw	!tib_xt+3		; The address of the input buffer (e.g. FIB or TIB)
;		endl
;-------------------------------------------------------------------------------
;source:		dw	source_
;		db	$06
;		db	'SOURCE'
;source_xt:	local
;		jp	!docol__xt		; : SOURCE ( -- c-addr u )
;		dw	!source__xt		;   (SOURCE)
;		dw	!two_fetch_xt		;   2@
;		dw	!doret__xt		; ;
;		endl
;-------------------------------------------------------------------------------
restr_input:	dw	source
		db	$0d
		db	'RESTORE-INPUT'
restr_input_xt:	local
		jp	!docol__xt		; : RESTORE-INPUT ( x x x x 4 -- flag )
		dw	!drop_xt		;   DROP
		dw	!to_in_xt		;   >IN
		dw	!store_xt		;   !
		dw	!do2to__xt		;   TO SOURCE
		dw	!source_xt+3
		dw	!doto__xt		;   TO SOURCE-ID
		dw	!source_id_xt+3		;
		dw	!false_xt		;   FALSE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
save_input:	dw	restr_input
		db	$0a
		db	'SAVE-INPUT'
save_input_xt:	local
		jp	!docol__xt		; : SAVE-INPUT ( -- x x x x 4 )
		dw	!source_id_xt		;   SOURCE-ID
		dw	!source_xt		;   SOURCE
		dw	!to_in_xt		;   >IN
		dw	!fetch_xt		;   @
		dw	!dolit__xt		;   4
		dw	4			;
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
bs_qt_parse:	dw	save_input
		db	$08
		db	'\"-PARSE'		; ( "ccc<quote>" -- c-addr u )
bs_qt_parse_xt:	local
		pushs	x			; Save IP
		pushu	ba			; Save TOS
		mv	x,!base_address
		mv	y,x
		call	!which_pocket__		; The address of a free pocket
		pushu	ba			; Push address of the temp buffer
		add	x,ba			; X holds the address of the temp buffer
		mv	ba,[!source_xt+5]	; Y holds the address of the
		add	y,ba			; input buffer
		mv	ba,[!to_in_xt+3]	; Number of previously parsed characters
		add	y,ba			; Address of the first character to parse
		mv	i,[!source_xt+3]	; Size of the input buffer
		sub	i,ba			; Compute the number of characters that remains within the buffer
		jrz	lbl3
lbl1:		mv	a,[y++]			; Parse next character
		cmp	a,$22			; Character is a quote?
		jrz	lbl4			; 
		cmp	a,$5c			; Character is a backslash?
		jrz	lbl5			; 
lbl1a:		mv	[x++],a			; Append the character to the temp buffer
		dec	i			; Count the number of remaining characters
		jrnz	lbl1
lbl2:		mv	ba,[!source_xt+3]	; Compute the new
		sub	ba,i			; >IN value
		mv	[!to_in_xt+3],ba	; Update >IN
lbl3:		mv	ba,[u]			; Address of the temp buffer is below the TOS
		sub	x,ba			; Compute the number of parsed valid characters in low-order 16 bits of X
		mv	ba,x			; Set new TOS (the number of parsed valid characters in the temp buffer)
		pops	x			; Restore IP
		jp	!interp__
lbl4:		dec	i			; Discard the separator
		jr	lbl2
lbl5:		dec	i			; Count the number of remaining characters
		jrz	lbl2
		mv	a,[y++]			; Parse next character
		cmp	a,'a'			; \a
		jrnz	lbl6
		mv	a,7
		;jr	lbl1a
lbl6:		cmp	a,'b'			; \b
		jrnz	lbl7
		mv	a,8
		;jr	lbl1a
lbl7:		cmp	a,'e'			; \e
		jrnz	lbl8
		mv	a,27
		;jr	lbl1a
lbl8:		cmp	a,'f'			; \f
		jrnz	lbl9
		mv	a,12
		;jr	lbl1a
lbl9:		cmp	a,'l'			; \l
		jrnz	lbl10
		mv	a,10
		;jr	lbl1a
lbl10:		cmp	a,'m'			; \m
		jrz	lbl11
		cmp	a,'n'			; \n
		jrnz	lbl12
lbl11:		mv	a,13
		mv	[x++],a
		mv	a,10
		;jr	lbl1a
lbl12:		cmp	a,'q'			; \q
		jrnz	lbl13
		mv	a,34
		;jr	lbl1a
lbl13:		cmp	a,'r'			; \r
		jrnz	lbl14
		mv	a,13
		;jr	lbl1a
lbl14:		cmp	a,'t'			; \t
		jrnz	lbl15
		mv	a,9
		;jr	lbl1a
lbl15:		cmp	a,'v'			; \v
		jrnz	lbl16
		mv	a,11
		;jr	lbl1a
lbl16:		cmp	a,'z'			; \z
		jrnz	lbl17
		mv	a,0
lbl17:		cmp	a,'x'			; \x
		jrnz	lbl1a
		dec	i
		jrz	lbl2
		dec	i
		jrz	lbl2
		mv	a,[y++]			; \xH
		sub	a,'0'
		cmp	a,10
		jrc	lbl18
		sub	a,7
		and	a,$0f
lbl18:		swap	a
		mv	(!el),a
		mv	a,[y++]			; \xHL
		sub	a,'0'
		cmp	a,10
		jrc	lbl19
		sub	a,7
		and	a,$0f
lbl19:		or	a,(!el)
		jr	lbl1a
		endl
;-------------------------------------------------------------------------------
parse:		dw	bs_qt_parse
		db	$05
		db	'PARSE'			; ( char "ccc<char>" -- c-addr u )
parse_xt:	local
		mv	(!el),a			; Store separator
		mv	y,!base_address		; Y holds the
		mv	ba,[!source_xt+5]	; address of the
		add	y,ba			; input buffer
		mv	ba,[!to_in_xt+3]	; Number of previously parsed characters
		add	y,ba			; Address of the first character to parse
		mv	i,y			; Truncate it to 16 bits
		pushu	i			; Save it to the stack
		mv	i,[!source_xt+3]	; Size of the input buffer
		sub	i,ba			; Compute the number of characters that remains within the buffer
		jrz	lbl3
		cmp	(!el),$20		; Is the submited separator a blank?
		jrz	lbl2
lbl1:		mv	a,[y++]			; Parse next character
		cmp	(!el),a			; Is it the end of a word? (only character whose
		jrz	lbl3			; value is equal to the submitted character is a valid separator)
		dec	i			; Count the number of remaining characters
		jrnz	lbl1
		jr	lbl3
lbl2:		mv	a,[y++]			; Parse next character
		cmp	a,$21			; Is it the end of a word? (every character whose
		jrc	lbl3			; value is lower than $20 is a valid separator)
		dec	i			; Count the number of remaining characters
		jrnz	lbl2
lbl3:		mv	ba,[!source_xt+3]	; Size of the input buffer
		sub	ba,i			; The new >IN value without the separator
		inc	i			; Are there any
		dec	i			; remaining characters?
		mv	i,[!to_in_xt+3]		; The old >IN value
		jrz	lbl4			; No remaining characters means no separator
		inc	ba			; The new >IN value with the separator
		inc	i			; Discard separator from the result
lbl4:		mv	[!to_in_xt+3],ba	; Update >IN
		sub	ba,i			; Set new TOS (the number of parsed valid characters)
		jp	!interp__
		endl
;parse_xt:       local
;                mv      (!el),a                 ; Store separator
;                pushs   x                       ; Save IP
;                mv      y,!base_address         ; Y holds the
;                mv      ba,[!source_xt+5]       ; address of the
;                add     y,ba                    ; input buffer
;                mv      ba,[!to_in_xt+3]        ; Number of previously parsed characters
;                add     y,ba                    ; Address of the first character to parse
;                mv      i,y                     ; Truncate it to 16 bits
;                pushu   i                       ; Save it to the stack
;                mv      x,0                     ; The number of parsed valid charaters
;                mv      i,[!source_xt+3]        ; Size of the input buffer
;                sub     i,ba                    ; Compute the number of characters that remains within the buffer
;                jrz     lbl4
;                cmp     (!el),$20               ; Is the submited separator a blank?
;                jrz     lbl2
;lbl1:           mv      a,[y++]                 ; Parse next character
;                cmp     (!el),a                 ; Is it the end of a word? (only character whose
;                jrz     lbl5                    ; value is equal to the submitted character is a valid separator)
;                inc     x                       ; Increment the number of parsed valid charaters
;                dec     i                       ; Count the number of remaining characters
;                jrnz    lbl1
;                jr      lbl3
;lbl2:           mv      a,[y++]                 ; Parse next character
;                cmp     a,$21                   ; Is it the end of a word? (every character whose
;                jrc     lbl5                    ; value is lower than $20 is a valid separator)
;                inc     x                       ; Increment the number of parsed valid charaters
;                dec     i                       ; Count the number of remaining characters
;                jrnz    lbl2
;lbl3:           mv      ba,[!source_xt+3]       ; Compute the new
;                sub     ba,i                    ; >IN value
;                mv      [!to_in_xt+3],ba        ; Update >IN
;lbl4:           mv      ba,x                    ; Set new TOS (the number of parsed valid characters)
;                pops    x                       ; Restore IP
;                jp      !interp__
;lbl5:           dec     i                       ; Discard the separator
;                jr      lbl3
;                endl
;-------------------------------------------------------------------------------
skip_seps:	dw	parse
		db	$0f
		db	'SKIP-SEPARATORS'
skip_seps_xt:	local
		mv	(!el),a			; Save TOS char
		mv	y,!base_address		; Y holds the
		mv	ba,[!source_xt+5]	; address of the
		add	y,ba			; input buffer
		mv	ba,[!to_in_xt+3]	; Number of previously parsed characters
		add	y,ba			; Address of the first character to parse
		mv	i,[!source_xt+3]	; Size of the input buffer
		sub	i,ba			; Compute the number of characters that remains into the buffer
		jrz	lbl4
		cmp	(!el),$20		; Is the submited separator a blank?
		jrz	lbl2
lbl1:		mv	a,[y++]			; Parse next character
		cmp	(!el),a			; Is it the beginning of a word? (only character whose
		jrnz	lbl3			; value is equal to the submitted character is a valid separator)
		dec	i			; Count the number of remaining characters
		jrnz	lbl1
		jr	lbl3
lbl2:		mv	a,[y++]			; Parse next character
		cmp	a,$21			; Is it the beginning of a word? (every character whose
		jrnc	lbl3			; value is lower than $20 is a valid separator)
		dec	i			; Count the number of remaining characters
		jrnz	lbl2
lbl3:		mv	ba,[!source_xt+3]	; Compute the new
		sub	ba,i			; >IN value
		mv	[!to_in_xt+3],ba	; Update >IN
lbl4:		popu	ba			; Set new TOS
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
parse_word:	dw	skip_seps
		db	$0a
		db	'PARSE-WORD'
parse_word_xt:	local
		jp	!docol__xt		; : PARSE-WORD ( char "<chars>ccc<char>" -- c-addr u )
		dw	!dup_xt			;   DUP
		dw	!skip_seps_xt		;   SKIP-SEPARATORS
		dw	!parse_xt		;   PARSE
		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   255
		dw	$00ff			;
		dw	!u_grtr_than_xt		;   U>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt	;     -18
			dw	-18		;     \ Parsed string overflow
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
word:		dw	parse_word
		db	$04
		db	'WORD'
word_xt:	local
		jp	!docol__xt		; : WORD ( char "<chars>ccc<char>" -- c-addr )
		dw	!parse_word_xt		;   PARSE-WORD
		dw	!here_xt		;   HERE
		dw	!two_dup_xt		;   2DUP
		dw	!c_store_xt		;   C!
		dw	!char_plus_xt		;   CHAR+
		dw	!swap_xt		;   SWAP
		dw	!c_move_xt		;   CMOVE
		dw	!here_xt		;   HERE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
check_name:	dw	word
		db	$0a
		db	'CHECK-NAME'
check_name_xt:	local
		jp	!docol__xt		; : CHECK-NAME ( c-addr u -- c-addr u )
		dw	!dup_xt			;   DUP
		dw	!zero_equals_xt		;   0=
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -16
			dw	-16		;     \ Attempt to use a zero-length string as a name
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   63
		dw	63			;
		dw	!u_grtr_than_xt		;   U>
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!dolit__xt	;     -19
			dw	-19		;     \ Definition name too long
			dw	!throw_xt	;     THROW THEN
lbl4:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
parse_name:	dw	check_name
		db	$0a
		db	'PARSE-NAME'
parse_name_xt:	local
		jp	!docol__xt		; : PARSE-NAME ( "<spaces>name" -- c-addr u )
		dw	!blnk_xt		;   BL
		dw	!parse_word_xt		;   PARSE-WORD
		dw	!check_name_xt		;   CHECK-NAME
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		DICTIONARY
;
;-------------------------------------------------------------------------------
count:		dw	parse_name
		db	$05
		db	'COUNT'
count_xt:	local
		mv	y,!base_address
		add	y,ba
		mv	il,[y++]
		mv	ba,y
		pushu	ba
		mv	ba,i
		jp	!cont__

;		jp	!docol__xt		; : COUNT ( c-addr -- c-addr u )
;		dw	!dup_xt			;   DUP
;		dw	!char_plus_xt		;   CHAR+
;		dw	!swap_xt		;   SWAP
;		dw	!c_fetch_xt		;   C@
;		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
l_to_name:	dw	count
		db	$06
		db	'L>NAME'		; ( addr -- nt )
l_to_name_xt:	local
		jp	!two_plus_xt		; Same as 2+
		endl
;-------------------------------------------------------------------------------
name_to_str:	dw	l_to_name
		db	$0b
		db	'NAME>STRING'		; ( nt -- c-addr u )
name_to_str_xt:	local
		jp	!docol__xt		; : NAME>STRING ( nt -- c-addr u )
		dw	!count_xt		;   COUNT
		dw	!dolit__xt		;   $3F
		dw	$3f			;
		dw	!and_xt			;   AND
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
name_from:	dw	name_to_str
		db	$05
		db	'NAME>'			; ( nt -- xt )
name_from_xt:	local
		jp	!docol__xt		; : NAME> ( nt -- c-addr )
		dw	!name_to_str_xt		;   NAME>STRING
		dw	!plus_xt		;   +
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
to_name:	dw	name_from
		db	$05
		db	'>NAME'			; ( xt -- nt )
to_name_xt:	local
		pushu	x			; Save IP
		mv	y,!base_address
		add	y,ba			; Y holds the searched xt
		mv	(!zi),y			; Set 3rd byte of (zi) to base address segment $b
		mvw	(!zi),[!last_xt+3] 	; (zi) holds the full LAST address
;		LOOP OVER DICTIONARY
lbl1:		mv	x,(!zi)		; 5	; X holds the dictionary entry address
		or	(!zi),(!zi+1)	; 6	; Check if the dictionary entry address is zero
		jrz	lbl2		; 2/3	; Dictionary entry address is zero?
		mvw	(!zi),[x++]	; 7	; (zi) holds the previous dictionary link address
		mv	i,x		; 2	; I holds the nt to return
		mv	a,[x++]		; 4	; A holds the word length and control bits
		test	a,$40		; 4	; Test if smudge bit is on
		jrnz	lbl1		; 2/3
		and	a,$3f		; 4	; Discard control bits to add length to X
		add	x,a		; 7	; X holds the current xt
		sub	x,y		; 7
		jrnz	lbl1		; 2/3	; Loop until matching xt
					; =53 cycles
;		FOUND THE MATCHING WORD IN THE DICTIONARY
		mv	ba,i			; Set new TOS to nt
		popu	x			; Restore IP
		jp	!cont__
lbl2:		mv	il,-24			; Invalid numeric argument
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
to_body:	dw	to_name
		db	$05
		db	'>BODY'			; ( xt -- addr )
to_body_xt:	local
		mv	il,3
		add	ba,il			; Skip 'jp' instruction to reach the body
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
find_word:	dw	to_body
		db	$09
		db	'FIND-WORD'		; ( c-addr u -- 0 0 | xt 1 | xt -1 )
find_word_xt:	local
		mv	(!gl),a			; (gl) holds the string length (length < 64 checked next)
		mv	il,64			; Compare the string length
		sub	ba,i			; to the max of 63 characters
		popu	ba			; BA holds the string address
		pushu	x			; Save IP
		jrnc	lbl6			; String too long?
		mv	y,!base_address
		add	y,ba			; Y holds the string address
		mv	(!fl),[y++]		; (fl) holds the first character of the string to search
		mv	(!yi),y			; (yi) holds the string address + 1
		mv	(!zi),y			; Set 3rd byte of (zi) to base address segment $b
		mvw	(!zi),[!last_xt+3] 	; (zi) holds the full LAST address
;		LOOP OVER DICTIONARY
lbl1:		mv	y,(!yi)		; 5	; Y holds the string address + 1
		mv	il,(!gl)	; 4	; IL holds the string length
					; =9 cycles
;		NEXT WORD IN THE DICTIONARY
lbl2:		mv	x,(!zi)		; 5	; X holds the address of the dictionary entry
		or	(!zi),(!zi+1)	; 6	; Check if the address of the dictionary entry is zero by ORing the low and high bytes
		jrz	lbl6		; 2/3	; Dictionary entry address is zero?
		mvw	(!zi),[x++]	; 7	; (zi) holds the previous dictionary link address
		mv	ba,[x++]	; 5	; A holds the word length and B holds the first character
;		COMPARE STRING LENGTHS
		sub	a,il		; 3	; Compare string lengths
		test	a,$7f		; 3	; Check string lengths, ignore immediate bit, keep smudge bit to force mismatch
		jrnz	lbl2		; 2/3	; String lengths are not the same?
					; =33 cycles +1 for jump if the length does not match
;		COMPARE FIRST CHARACTERS
		ex	a,b		; 3	; B holds immediate bit to save for later, A holds first character
		xor	a,(!fl)		; 4	; Compare first characters
		jrz	lbl4		; 2/3	; First characters match?
		test	a,$df		; 3	; Check if case insensitive bits match
		jrnz	lbl2		; 2/3	; Case insensitive characters differ?
					; =33+14=47 cycles +1 for jump if the length does not match and the first character did not match
		mv	a,(!fl)		; 3	; A holds the first character of the string to search
		or	a,$20		; 3	; Make it lower case (if A is a letter, checked next)
		cmp	a,'a'		; 3
		jrc	lbl2		; 2/3	; A is not a letter?
		cmp	a,'{'		; 3
		jrnc	lbl2		; 2/3	; A is not a letter?
		dec	il		; 3	; Decrement string length
		jrz	lbl5		; 2/3	; String length is zero?
					; =47+22=69 cycles if the length matched and the first character matched
;		LOOP OVER STRINGS TO COMPARE
lbl3:		mv	a,[x++]		; 4	; A holds the next charater of the word
		mv	(!el),[y++]	; 6	; (el) holds the next character of the string to match
		xor	a,(!el)		; 4	; Compare characters
		jrz	lbl4		; 2/3	; Characters match?
		test	a,$df		; 3	; Check if case insensitive bits match
		jrnz	lbl1		; 2/3	; Case insensitive characters differ?
		mv	a,(!el)		; 3	; A holds the next character of the string to match
		or	a,$20		; 3	; Make it lower case (if A is a letter, checked next)
		cmp	a,'a'		; 3	; A is not a letter?
		jrc	lbl1		; 2/3
		cmp	a,'{'		; 3	; A is not a letter?
		jrnc	lbl1		; 2/3
lbl4:		dec	il		; 3	; Decrement string length
		jrnz	lbl3		; 2/3	; String length is not zero?
					; =43 cycles for each subsequent character matched
;		FOUND A MATCHING WORD IN THE DICTIONARY
lbl5:		add	ba,ba			; Check immediate bit stored in B
		mv	ba,x			; BA holds the execution token
		popu	x			; Restore IP
		pushu	ba			; Save new 2OS execution token
		mv	ba,-1			; Set new TOS to -1, word is not immediate
		jrnc	lbl7			; Immediate bit is unset?
		mv	ba,1			; Set new TOS to 1, word is immediate
		jr	lbl7
;		NOT FOUND
lbl6:		popu	x			; Restore IP
		sub	ba,ba			; Set TOS to zero
		pushu	ba			; Set 2OS to zero
lbl7:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
find:		dw	find_word
		db	$04
		db	'FIND'
find_xt:	local
		jp	!docol__xt		; : FIND ( c-addr -- c-addr 0 | xt 1 | xt -1 )
		dw	!dup_to_r_xt		;   DUP>R
		dw	!count_xt		;   COUNT
		dw	!find_word_xt		;   FIND-WORD
		dw	!dup_xt			;   DUP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!r_from_drop_xt	;     R>DROP
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!nip_xt			;   NIP
		dw	!r_from_xt		;   R>
		dw	!swap_xt		;   SWAP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		DEFINITIONS
;
;-------------------------------------------------------------------------------
created_:	dw	find
		db	$09
		db	'(CREATED)'
created__xt:	local
		jp	!docol__xt		; : (CREATED) ( c-addr u -- )
		dw	!here_xt		;   HERE
		dw	!last_xt		;   LAST        \ Pointer to last definition
		dw	!comma_xt		;   ,
		dw	!doto__xt		;   TO LAST     \ Update last definition pointer
		dw	!last_xt+3		;
		dw	!dup_xt			;   DUP
		dw	!c_comma_xt		;   C,          \ Length and control bits
		dw	!here_xt		;   HERE
		dw	!swap_xt		;   SWAP
		dw	!dup_xt			;   DUP         \ c-addr HERE u u
		;dw     !chars_xt               ;   CHARS       \ Does nothing (char is one byte)
		dw	!allot_xt		;   ALLOT       \ c-addr HERE u
		dw	!c_move_xt		;   CMOVE
		dw	!here_xt		;   HERE
		dw	!doto__xt		;   TO LAST-XT  \ Update pointer to last xt
		dw	!lastxt_xt+3		;
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
create_:	dw	created_
		db	$08
		db	'(CREATE)'
create__xt:	local
		jp	!docol__xt		; : (CREATE) ( "<spaces>name" -- )
		dw	!parse_name_xt		;   PARSE-NAME
		dw	!created__xt		;   (CREATED)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
body_:		dw	create_
		db	$07
		db	'(:BODY)'
body__xt:	local
		jp	!docol__xt		; : (:BODY)
		dw	!right_brkt_xt		;   ]
		dw	!here_xt		;   HERE
		dw	!colon_sys__xt		;   (COLON-SYS)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!dolit__xt		;   ['] (DOCOL)
		dw	!docol__xt		;
		dw	!cfa_comma_xt		;   CFA,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
noname:		dw	body_
		db	$07
		db	':NONAME'
noname_xt:	local
		jp	!docol__xt		; : :NONAME
		dw	!here_xt		;   HERE	\ Execution token
		dw	!dup_xt			;   DUP
		dw	!doto__xt		;   TO LAST-XT
		dw	!lastxt_xt+3		;
		dw	!body__xt		;   (:BODY)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
colon:		dw	noname
		db	$01
		db	':'
colon_xt:	local
		jp	!docol__xt		; : :
		dw	!create__xt		;   (CREATE)
		dw	!hide_xt		;   HIDE
		dw	!body__xt		;   (:BODY)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
semi_colon:	dw	colon
		db	$81
		db	';'
semi_colon_xt:	local
		jp	!docol__xt		; : ;
		dw	!quest_comp_xt		;   ?COMP
		;dw	!cs_pop_xt		;   CS-POP	\ Does nothing
		dw	!colon_sys__xt		;   (COLON-SYS)
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -22
			dw	-22		;     \ Control structure mismatch
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!dolit__xt		;   ['] (DORET) \ POSTPONE (DORET)
		dw	!doret__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!reveal_xt		;   REVEAL
		dw	!left_brkt_xt		;   [
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
create:		dw	semi_colon
		db	$06
		db	'CREATE'
create_xt:	local
		jp	!docol__xt		; : CREATE ( "<spaces>name" -- ; -- addr )
		dw	!create__xt		;   (CREATE)
		dw	!dolit__xt		;   ['] (DOVAR)
		dw	!dovar__xt		;
		dw	!cfa_comma_xt		;   CFA,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
creat_nonam:	dw	create
		db	$0d
		db	'CREATE-NONAME'
creat_nonam_xt:	local
		jp	!docol__xt		; : CREATE-NONAME ( -- xt ; -- addr )
		dw	!here_xt		;   HERE
		dw	!dup_xt			;   DUP
		dw	!doto__xt		;   TO LAST-XT
		dw	!lastxt_xt+3		;
		dw	!dolit__xt		;   ['] (DOVAR)
		dw	!dovar__xt		;
		dw	!cfa_comma_xt		;   CFA,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
does:		dw	creat_nonam
		db	$85
		db	'DOES>'
does_xt:	local
		jp	!docol__xt		; : DOES> ( -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (;CODE) \ POSTPONE (;CODE)
		dw	!sc_code__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!does_comma_xt		;   DOES,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
constant:	dw	does
		db	$08
		db	'CONSTANT'
constant_xt:	local
		jp	!docol__xt		; : CONSTANT ( x "<spaces>name" -- ; -- x)
		dw	!create__xt		;   (CREATE)
		dw	!dolit__xt		;   ['] (DOCON)
		dw	!docon__xt
		dw	!cfa_comma_xt		;   CFA,
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
two_const:	dw	constant
		db	$09
		db	'2CONSTANT'
two_const_xt:	local
		jp	!docol__xt		; : 2CONSTANT ( x1 x2 "<spaces>name" -- ; -- x1 x2 )
		dw	!create__xt		;   (CREATE)
		dw	!dolit__xt		;   ['] (DO2CON)
		dw	!do2con__xt
		dw	!cfa_comma_xt		;   CFA,
		dw	!two_comma_xt		;   2,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
variable:	dw	two_const
		db	$08
		db	'VARIABLE'
variable_xt:	local
		jp	!docol__xt		; : VARIABLE ( "<spaces>name" -- ; -- addr )
		dw	!create_xt		;   CREATE
		dw	!dolit0_xt		;   0
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
two_variabl:	dw	variable
		db	$09
		db	'2VARIABLE'
two_variabl_xt:	local
		jp	!docol__xt		; : 2VARIABLE ( "<spaces>name" -- ; -- addr )
		dw	!create_xt		;   CREATE
		dw	!dolit0_xt		;   0
		dw	!dolit0_xt		;   0
		dw	!two_comma_xt		;   2,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
value:		dw	two_variabl
		db	$05
		db	'VALUE'
value_xt:	local
		jp	!docol__xt		; : VALUE ( x "<spaces>name" -- ; -- x )
		dw	!create__xt		;   (CREATE)
		dw	!dolit__xt		;   ['] (DOVAL)
		dw	!doval__xt		;
		dw	!cfa_comma_xt		;   CFA,
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
two_value:	dw	value
		db	$06
		db	'2VALUE'
two_value_xt:	local
		jp	!docol__xt		; : 2VALUE ( x1 x2 "<spaces>name" -- ; -- x1 x2 )
		dw	!create__xt		;   (CREATE)
		dw	!dolit__xt		;   ['] (DO2VAL)
		dw	!do2val__xt		;
		dw	!cfa_comma_xt		;   CFA,
		dw	!two_comma_xt		;   2,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
value_quest:	dw	two_value
		db	$06
		db	'VALUE?'		; ( xt -- flag )
value_quest_xt:	local
		mv	y,!base_address		; Compute the address
		add	y,ba			; code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a doval ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	i,!doval__xt		; Compare it with
		sub	ba,i			; the doval execution token
lbl2:		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
two_val_qst:	dw	value_quest
		db	$07
		db	'2VALUE?'		; ( xt -- flag )
two_val_qst_xt:	local
		mv	y,!base_address		; Compute the address
		add	y,ba			; code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a do2val ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	i,!do2val__xt		; Compare it with
		sub	ba,i			; the do2val execution token
lbl2:		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
to:		dw	two_val_qst
		db	$82
		db	'TO'
to_xt:		local
		jp	!docol__xt			; : TO ( |x "<spaces>name" -- ; x -- )
		dw	!tick_xt			;   '
		dw	!dup_xt				;   DUP
		dw	!value_quest_xt			;   VALUE?
		dw	!if__xt				;   IF
		dw	lbl4-lbl1			;
lbl1:			dw	!to_body_xt		;     >BODY
			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl3-lbl2		;
lbl2:				dw	!dolit__xt	;       ['] (TO) \ POSTPONE (TO)
				dw	!doto__xt	;
				dw	!compile_com_xt	;       COMPILE,
				dw	!comma_xt	;       ,
				dw	!doexit__xt	;       EXIT THEN
lbl3:			dw	!store_xt		;     !
			dw	!doexit__xt		;     EXIT THEN
lbl4:		dw	!dup_xt				;   DUP
		dw	!two_val_qst_xt			;   2VALUE?
		dw	!if__xt				;   IF
		dw	lbl8-lbl5			;
lbl5:			dw	!to_body_xt		;     >BODY
			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl7-lbl6		;
lbl6:				dw	!dolit__xt	;       ['] (2TO) \ POSTPOONE (2TO)
				dw	!do2to__xt	;
				dw	!compile_com_xt	;       COMPILE,
				dw	!comma_xt	;       ,
				dw	!doexit__xt	;       EXIT THEN
lbl7:			dw	!two_store_xt		;     2!
			dw	!doexit__xt		;     EXIT THEN
lbl8:		dw	!dolit__xt			;   -32
		dw	-32				;   \ Invalid name argument
		dw	!throw_xt			;   THROW
		dw	!doret__xt			; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
plus_to:	dw	to
		db	$83
		db	'+TO'
plus_to_xt:	local
		jp	!docol__xt			; : +TO ( |x "<spaces>name" -- ; x -- )
		dw	!tick_xt			;   '
		dw	!dup_xt				;   DUP
		dw	!value_quest_xt			;   VALUE?
		dw	!if__xt				;   IF
		dw	lbl4-lbl1			;                                      
lbl1:			dw	!to_body_xt		;     >BODY
			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl3-lbl2		;                                      
lbl2:				dw	!dolit__xt	;       ['] (+TO) \ POSTPONE (+TO)
				dw	!doplusto__xt	;                                      
				dw	!compile_com_xt	;       COMPILE,
				dw	!comma_xt	;       ,
				dw	!doexit__xt	;       EXIT THEN
lbl3:			dw	!plus_store_xt		;     +!
			dw	!doexit__xt		;     EXIT THEN
lbl4:		dw	!dup_xt				;   DUP
		dw	!two_val_qst_xt			;   2VALUE?
		dw	!if__xt				;   IF
		dw	lbl8-lbl5			;                                      
lbl5:			dw	!to_body_xt		;     >BODY
			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl7-lbl6		;                                      
lbl6:				dw	!dolit__xt	;       ['] (D+2TO) \ POSTPONE (D+2TO)
				dw	!dodplus2to__xt	;                                      
				dw	!compile_com_xt	;       COMPILE,
				dw	!comma_xt	;       ,
				dw	!doexit__xt	;       EXIT THEN
lbl7:			dw	!d_plus_stor_xt		;     D+!
			dw	!doexit__xt		;     EXIT THEN
lbl8:		dw	!dolit__xt			;   -32
		dw	-32				;   \ Invalid name argument
		dw	!throw_xt			;   THROW
		dw	!doret__xt			; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
uninit_:	dw	plus_to
		db	$08
		db	'(UNINIT)'
uninit__xt:	local
		jp	!docol__xt		; : (UNINIT) ( -- )
		dw	!dolit__xt		;   -256
		dw	-256			;   \ Execution of an uninitialized deferred word
		dw	!throw_xt		;   THROW
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
defer:		dw	uninit_
		db	$05
		db	'DEFER'
defer_xt:	local
		jp	!docol__xt		; : DEFER ( "<spaces>name" -- )
		dw	!create__xt		;   (CREATE)
		dw	!dolit__xt		;   ['] (DODEFER)
		dw	!dodefer__xt		;
		dw	!cfa_comma_xt		;   CFA,
		dw	!dolit__xt		;   ['] (UNINIT)
		dw	!uninit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
defer_fetch:	dw	defer
		db	$06
		db	'DEFER@'
defer_fetch_xt:	local
		jp	!docol__xt		; : DEFER@ ( xt -- xt )
		dw	!to_body_xt		;   >BODY
		dw	!fetch_xt		;   @
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
defer_store:	dw	defer_fetch
		db	$06
		db	'DEFER!'
defer_store_xt:	local
		jp	!docol__xt		; : DEFER! ( xt xt -- )
		dw	!to_body_xt		;   >BODY
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
defer_quest:	dw	defer_store
		db	$06
		db	'DEFER?'
defer_quest_xt:	local
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a dodefer ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	i,!dodefer__xt		; Compare it with
		sub	ba,i			; the DODEFER execution token
lbl2:		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
is:		dw	defer_quest
		db	$82
		db	'IS'
is_xt:		local
		jp	!docol__xt			; : IS ( xt "<spaces>name" -- )
		dw	!tick_xt			;   '
		dw	!dup_xt				;   DUP
		dw	!defer_quest_xt			;   DEFER?
		dw	!if__xt				;   IF
		dw	lbl4-lbl1			;
lbl1:			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl3-lbl2		;
lbl2:				dw	!literal_xt	;       LITERAL
				dw	!dolit__xt	;       ['] DEFER! \ POSTPONE DEFER!
				dw	!defer_store_xt	;
				dw	!compile_com_xt	;       COMPILE,
				dw	!doexit__xt	;       EXIT THEN
lbl3:			dw	!defer_store_xt		;     DEFER!
			dw	!doexit__xt		;     EXIT THEN
lbl4:		dw	!dolit__xt			;   -32
		dw	-32				;   \ Invalid name argument
		dw	!throw_xt			;   THROW
		dw	!doret__xt			; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
action_of:	dw	is
		db	$89
		db	'ACTION-OF'
action_of_xt:	local
		jp	!docol__xt			; : ACTION-OF ( "<spaces>name" -- xt )
		dw	!tick_xt			;   '
		dw	!dup_xt				;   DUP
		dw	!defer_quest_xt			;   DEFER?
		dw	!if__xt				;   IF
		dw	lbl4-lbl1			;
lbl1:			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!if__xt			;     IF
			dw	lbl3-lbl2		;
lbl2:				dw	!literal_xt	;       LITERAL
				dw	!dolit__xt	;       ['] DEFER@ \ POSTPONE DEFER@
				dw	!defer_fetch_xt	;
				dw	!compile_com_xt	;       COMPILE,
				dw	!doexit__xt	;       EXIT THEN
lbl3:			dw	!defer_fetch_xt		;     DEFER@
			dw	!doexit__xt		;     EXIT THEN
lbl4:		dw	!dolit__xt			;   -32
		dw	-32				;   \ Invalid name argument
		dw	!throw_xt			;   THROW
		dw	!doret__xt			; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
colon_quest:	dw	action_of
		db	$06
		db	'COLON?'		; ( xt -- flag )
colon_quest_xt:	local
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a docol ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	i,!docol__xt		; Compare it with
		sub	ba,i			; the DOCOL execution token
lbl2:		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
does_quest:	dw	colon_quest
		db	$06
		db	'DOES>?'		; ( xt -- flag )
does_quest_xt:	local
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a jump to a call to does__xt?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the does routine
		mv	a,[y++]			; Test if it
		cmp	a,$04			; is a
		jrnz	lbl2			; call
		mv	ba,[y]			; to the
		mv	i,!does__xt		; (DOES>)
		sub	ba,i			; execution token
lbl2:		mv	ba,0			; Set new TOS to FALSE
		jrnz	lbl1
		dec	ba			; Set new TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
marker:		dw	does_quest
		db	$06
		db	'MARKER'
marker_xt:	local
		jp	!docol__xt		; : MARKER ( "<spaces>name" -- ; -- )
		dw	!here_xt		;   HERE
		dw	!lastxt_xt		;   LAST-XT
		dw	!last_xt		;   LAST
		dw	!create_xt		;   CREATE
		dw	!comma_xt		;     ,
		dw	!comma_xt		;     ,
		dw	!comma_xt		;     ,
		dw	!sc_code__xt		;   DOES> \ (;CODE) compiled by DOES>
marker_bhvr_xt:	call	!does__xt		;         \ Compiled by DOES>
		dw	!dup_xt			;     DUP
		dw	!fetch_xt		;     @
		dw	!doto__xt		;     TO LAST
		dw	!last_xt+3		;
		dw	!cell_plus_xt		;     CELL+
		dw	!dup_xt			;     DUP
		dw	!fetch_xt		;     @
		dw	!doto__xt		;     TO LAST-XT
		dw	!lastxt_xt+3		;
		dw	!cell_plus_xt		;     CELL+
		dw	!fetch_xt		;     @
		dw	!here_xt		;     HERE
		dw	!minus_xt		;     -
		dw	!allot_xt		;     ALLOT
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
marker_qust:	dw	marker
		db	$07
		db	'MARKER?'
marker_qust_xt:	local
		mv	y,!base_address
		add	y,ba
		mv	a,[y++]				; Is it a call to a jump?
		cmp	a,$02				;
		jrnz	lbl2
		mv	ba,[y]				; Compare the jump
		mv	i,!marker_xt!marker_bhvr_xt	; address to the address
		sub	i,ba				; of the behavior of a marker
lbl2:		mv	ba,0				; Set TOS to FALSE
		jrnz	lbl1
		dec	ba				; Set TOS to TRUE
lbl1:		jp	!cont__
		endl
;-------------------------------------------------------------------------------
anew:		dw	marker_qust
		db	$04
		db	'ANEW'
anew_xt:	local
		jp	!docol__xt		; : ANEW ( "<spaces>name" -- )
		dw	!to_in_xt		;   >IN
		dw	!fetch_xt		;   @
		dw	!to_r_xt		;   >R
		dw	!tick__xt		;   (')
		dw	!over_xt		;   OVER
		dw	!marker_qust_xt		;   MARKER?
		dw	!and_xt			;   AND
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!execute_xt	;     EXECUTE
		dw	!ahead__xt		;   ELSE
		dw	lbl3-lbl2		;
lbl2:			dw	!drop_xt	;     DROP THEN
lbl3:		dw	!r_from_xt		;   R>
		dw	!to_in_xt		;   >IN
		dw	!store_xt		;   !
		dw	!marker_xt		;   MARKER
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
buffer_col:	dw	anew
		db	$07
		db	'BUFFER:'
buffer_col_xt:	local
		jp	!docol__xt		; : BUFFER: ( u "<spaces>name" -- ; -- addr )
		dw	!create_xt		;   CREATE
		dw	!allot_xt		;   ALLOT
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		CONTROL FLOW
;
;-------------------------------------------------------------------------------
recurse:	dw	buffer_col
		db	$87
		db	'RECURSE'
recurse_xt:	local
		jp	!docol__xt		; : RECURSE ( -- ; ... -- ... )
		dw	!quest_comp_xt		;   ?COMP
		dw	!lastxt_xt		;   LAST-XT
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
ahead:		dw	recurse
		db	$85
		db	'AHEAD'
ahead_xt:	local
		jp	!docol__xt		; : AHEAD
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (AHEAD) \ POSTPONE (AHEAD)
		dw	!ahead__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!here_xt		;   HERE
		dw	!orig__xt		;   (ORIG)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!dolit0_xt		;   0
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
begin:		dw	ahead
		db	$85
		db	'BEGIN'
begin_xt:	local
		jp	!docol__xt		; : BEGIN
		dw	!quest_comp_xt		;   ?COMP
		dw	!here_xt		;   HERE
		dw	!dest__xt		;   (DEST)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
again:		dw	begin
		db	$85
		db	'AGAIN'
again_xt:	local
		jp	!docol__xt		; : AGAIN
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (AGAIN) \ POSTPOONE (AGAIN)
		dw	!again__xt		;
		dw	!compile_com_xt		;   COMPILE,
		;dw	!cs_pop_xt		;   CS-POP	\ Does nothing
		dw	!dest__xt		;   (DEST)
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -22
			dw	-22		;     \ Control structure mismatch
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!swap_xt		;   SWAP \ Avoid errors if C stack and data stack are the same
		dw	!minus_xt		;   -
		dw	!two_plus_xt		;   2+
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
until:		dw	again
		db	$85
		db	'UNTIL'
until_xt:	local
		jp	!docol__xt		; : UNTIL
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (UNTIL) \ POSTPONE (UNTIL)
		dw	!until__xt		;
		dw	!compile_com_xt		;   COMPILE,
		;dw	!cs_pop_xt		;   CS-POP	\ Does nothing
		dw	!dest__xt		;   (DEST)
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -22
			dw	-22		;     \ Control structure mismatch
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!swap_xt		;   SWAP \ Avoid errors if C stack and data stack are the same
		dw	!minus_xt		;   -
		dw	!two_plus_xt		;   2+
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
if:		dw	until
		db	$82
		db	'IF'
if_xt:		local
		jp	!docol__xt		; : IF
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (IF)
		dw	!if__xt			;
		dw	!compile_com_xt		;   COMPILE,
		dw	!here_xt		;   HERE
		dw	!orig__xt		;   (ORIG)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!dolit0_xt		;   0
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
then:		dw	if
		db	$84
		db	'THEN'
then_xt:	local
		jp	!docol__xt		; : THEN
		dw	!quest_comp_xt		;   ?COMP
		;dw	!cs_pop_xt		;   CS-POP	\ Does nothing
		dw	!orig__xt		;   (ORIG)
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -22
			dw	-22		;     \ Control structure mismatch
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!over_xt		;   OVER \ Avoid errors if C stack and data stack are the same
		dw	!minus_xt		;   -
		dw	!two_minus_xt		;   2-
		dw	!swap_xt		;   SWAP
		dw	!store_xt		;   !
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
while:		dw	then
		db	$85
		db	'WHILE'
while_xt:	local
		jp	!docol__xt		; : WHILE
		dw	!quest_comp_xt		;   ?COMP
		dw	!if_xt			;   POSTPONE IF
		dw	!dolit1_xt		;   1
		dw	!cs_roll_xt		;   CS-ROLL
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
repeat:		dw	while
		db	$86
		db	'REPEAT'
repeat_xt:	local
		jp	!docol__xt		; : REPEAT
		dw	!quest_comp_xt		;   ?COMP
		dw	!again_xt		;   POSTPONE AGAIN
		dw	!then_xt		;   POSTPONE THEN
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
else:		dw	repeat
		db	$84
		db	'ELSE'
else_xt:	local
		jp	!docol__xt		; : ELSE
		dw	!quest_comp_xt		;   ?COMP
		dw	!ahead_xt		;   POSTPONE AHEAD
		dw	!dolit1_xt		;   1
		dw	!cs_roll_xt		;   CS-ROLL
		dw	!then_xt		;   POSTPONE THEN
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
do:		dw	else
		db	$82
		db	'DO'
do_xt:		local
		jp	!docol__xt		; : DO
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (DO) \ POSTPONE (DO)
		dw	!do__xt			;
		dw	!compile_com_xt		;   COMPILE,
		dw	!here_xt		;   HERE
		dw	!do_sys__xt		;   (DO-SYS)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!dolit0_xt		;   0
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
quest_do:	dw	do
		db	$83
		db	'?DO'
quest_do_xt:	local
		jp	!docol__xt		; : ?DO
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (?DO) \ POSTPONE (?DO)
		dw	!quest_do__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!here_xt		;   HERE
		dw	!do_sys__xt		;   (DO-SYS)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!dolit0_xt		;   0
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
loop:		dw	quest_do
		db	$84
		db	'LOOP'
loop_xt:	local
		jp	!docol__xt		; : LOOP
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (LOOP) \ POSTPONE (LOOP)
		dw	!loop__xt		;
		dw	!compile_com_xt		;   COMPILE,
		;dw	!cs_pop_xt		;   CS-POP	\ Does nothing
		dw	!do_sys__xt		;   (DO-SYS)
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -22
			dw	-22		;     \ Control structure mismatch
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!over_xt		;   OVER \ Avoid errors if C stack and data stack are the same
		dw	!minus_xt		;   -
		dw	!dup_xt			;   DUP \ Added for DO/?DO relative jumps
		dw	!comma_xt		;   ,
		;dw	!here_xt		;   \ Removed for DO/?DO relative jumps
		dw	!swap_xt		;   SWAP
		dw	!store_xt		;   !
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
plus_loop:	dw	loop
		db	$85
		db	'+LOOP'
plus_loop_xt:	local
		jp	!docol__xt		; : +LOOP
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (+LOOP)
		dw	!plus_loop__xt		;
		dw	!compile_com_xt		;   COMPILE,
		;dw	!cs_pop_xt		;   CS-POP	\ Does nothing
		dw	!do_sys__xt		;   (DO-SYS)
		dw	!not_equals_xt		;   <>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -22
			dw	-22		;     \ Control structure mismatch
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!over_xt		;   OVER \ Avoid errors if C stack and data stack are the same
		dw	!minus_xt		;   -
		dw	!dup_xt			;   DUP \ Added for DO/?DO relative jumps
		dw	!comma_xt		;   ,
		;dw	!here_xt		;   \ Removed for DO/?DO relative jumps
		dw	!swap_xt		;   SWAP
		dw	!store_xt		;   !
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
unloop:		dw	plus_loop
		db	$86
		db	'UNLOOP'
unloop_xt:	local
		jp	!docol__xt		; : UNLOOP
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (UNLOOP) \ POSTPONE (UNLOOP)
		dw	!unloop__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
leave:		dw	unloop
		db	$85
		db	'LEAVE'
leave_xt:	local
		jp	!docol__xt		; : LEAVE
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (LEAVE) \ POSTPONE (LEAVE)
		dw	!leave__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
qst_leave:	dw	leave
		db	$86
		db	'?LEAVE'
qst_leave_xt:	local
		jp	!docol__xt		; : ?LEAVE
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (?LEAVE) \ POSTPONE (?LEAVE)
		dw	!qst_leave__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
case:		dw	qst_leave
		db	$84
		db	'CASE'
case_xt:	local
		jp	!docol__xt		; : CASE ( -- 0 )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit0_xt		;   0
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
of:		dw	case
		db	$82
		db	'OF'
of_xt:		local
		jp	!docol__xt		; : OF ( n -- n ; x x -- |x )
		dw	!quest_comp_xt		;   ?COMP
		dw	!one_plus_xt		;   1+
		dw	!to_r_xt		;   >R
		dw	!dolit__xt		;   ['] (OF) \ New (OF) replaces OVER = (IF) DROP
		dw	!of__xt			;
		dw	!compile_com_xt		;   COMPILE,
		dw	!here_xt		;   HERE
		dw	!orig__xt		;   (ORIG)
		;dw	!cs_push_xt		;   CS-PUSH	\ Does nothing
		dw	!dolit0_xt		;   0
		dw	!comma_xt		;   ,
		;dw	!dolit__xt		;   ['] OVER
		;dw	!over_xt		;
		;dw	!compile_com_xt		;   COMPILE,
		;dw	!dolit__xt		;   ['] =
		;dw	!equals_xt		;
		;dw	!compile_com_xt		;   COMPILE,
		;dw	!if_xt			;   IF
		;dw	!dolit__xt		;   ['] DROP
		;dw	!drop_xt		;
		;dw	!compile_com_xt		;   COMPILE,
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
endof:		dw	of
		db	$85
		db	'ENDOF'
endof_xt:	local
		jp	!docol__xt		; : ENDOF
		dw	!quest_comp_xt		;   ?COMP
		dw	!to_r_xt		;   >R
		dw	!else_xt		;   POSTPONE ELSE
		dw	!r_from_xt		;   R>
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
endcase:	dw	endof
		db	$87
		db	'ENDCASE'
endcase_xt:	local
		jp	!docol__xt		; : ENDCASE ( n -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] DROP \ POSTPONE DROP
		dw	!drop_xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!dolit0_xt		;   0
		dw	!quest_do__xt		;   ?DO
		dw	lbl2-lbl1		;
lbl1:			dw	!then_xt	;     POSTPONE THEN
		dw	!loop__xt		;   LOOP
		dw	lbl2-lbl1		;
lbl2:		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
exit:		dw	endcase
		db	$84
		db	'EXIT'
exit_xt:	local
		jp	!docol__xt		; : EXIT ( -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (EXIT) \ POSTPONE (EXIT)
		dw	!doexit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
literal:	dw	exit
		db	$87
		db	'LITERAL'
literal_xt:	local
		jp	!docol__xt		; : LITERAL ( x -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (DOLIT)
		dw	!dolit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
two_literal:	dw	literal
		db	$88
		db	'2LITERAL'
two_literal_xt:	local
		jp	!docol__xt		; : 2LITERAL ( x1 x2 -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (DO2LIT)
		dw	!do2lit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!two_comma_xt		;   ,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
sliteral:	dw	two_literal
		db	$88
		db	'SLITERAL'
sliteral_xt:	local
		jp	!docol__xt		; : SLITERAL ( c-addr u -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (DOSLIT)
		dw	!doslit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!dup_xt			;   DUP
		dw	!comma_xt		;   ,
		dw	!here_xt		;   HERE
		dw	!over_xt		;   OVER
		;dw	!chars_xt		;   CHARS  \ Does nothing
		dw	!allot_xt		;   ALLOT
		dw	!swap_xt		;   SWAP
		dw	!c_move_xt		;   CMOVE
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
dot_quote:	dw	sliteral
		db	$82
		db	'."'
dot_quote_xt:	local
		jp	!docol__xt		; : ." ( "ccc<quote>" -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   '"
		dw	$22			;   \ The value of the quote character
		dw	!parse_xt		;   PARSE
		dw	!sliteral_xt		;   SLITERAL
		dw	!dolit__xt		;   ['] TYPE \ POSTPONE TYPE
		dw	!type_xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
s_bs_quote:	dw	dot_quote
		db	$83
		db	'S\"'
s_bs_quote_xt:	local
		jp	!docol__xt		; : S\" ( "ccc<quote>" -- ; -- c-addr u )
		dw	!bs_qt_parse_xt		;   \"-PARSE
		dw	!state_xt		;   STATE
		dw	!fetch_xt		;   @
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!sliteral_xt	;     SLITERAL
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
s_quote:	dw	s_bs_quote
		db	$82
		db	'S"'
s_quote_xt:	local
		jp	!docol__xt		; : S" ( "ccc<quote>" -- ; -- c-addr u )
		dw	!dolit__xt		;   '"
		dw	$22			;   \ The value of the quote character
		dw	!parse_xt		;   PARSE
		dw	!state_xt		;   STATE
		dw	!fetch_xt		;   @
		dw	!if__xt			;   IF
		dw	lbl2-lbl1
lbl1:			dw	!sliteral_xt	;     SLITERAL
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!which_pockt_xt		;   WHICH-POCKET
		dw	!swap_xt		;   SWAP
		dw	!two_dup_xt		;   2DUP
		dw	!two_to_r_xt		;   2>R
		dw	!c_move_xt		;   CMOVE
		dw	!two_r_from_xt		;   2R>
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
c_quote:	dw	s_quote
		db	$82
		db	'C"'
c_quote_xt:	local
		jp	!docol__xt		; : C" ( "ccc<quote>" -- ; -- c-addr )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   '"
		dw	$22			;   \ The value of the quote character
		dw	!parse_xt		;   PARSE
		dw	!dolit__xt		;   ['] (DOSLIT)  \ POSTPONE (DOSLIT)
		dw	!doslit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   255
		dw	$00ff			;
		dw	!u_grtr_than_xt		;   U>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -18
			dw	-18		;     \ Parsed string overflow
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!dup_xt			;   DUP
		dw	!dup_xt			;   DUP
		dw	!one_plus_xt		;   1+
		dw	!comma_xt		;   ,
		dw	!c_comma_xt		;   C,
		dw	!here_xt		;   HERE
		dw	!over_xt		;   OVER
		;dw	!chars_xt		;   CHARS  \ does nothing
		dw	!allot_xt		;   ALLOT
		dw	!swap_xt		;   SWAP
		dw	!c_move_xt		;   CMOVE
		dw	!dolit__xt		;   ['] DROP  \ POSTPONE DROP
		dw	!drop_xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
;
;		BRACKET
;
;-------------------------------------------------------------------------------
tick_:		dw	c_quote
		db	$03
		db	'('')'
tick__xt:	local
		jp	!docol__xt		; : (') ( "<spaces>name" -- 0 0 | xt 1 | xt -1 )
		dw	!blnk_xt		;   BL
		dw	!parse_word_xt		;   PARSE-WORD
		dw	!find_word_xt		;   FIND-WORD
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
tick:		dw	tick_
		db	$01
		db	''''
tick_xt:	local
		jp	!docol__xt		; : ' ( "<spaces>name" -- xt )
		dw	!tick__xt		;   (')
		dw	!zero_equals_xt		;   0=
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -13
			dw	-13		;     \ Undefined word
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
brkt_tick:	dw	tick
		db	$83
		db	'['']'
brkt_tick_xt:	local
		jp	!docol__xt		; : ['] ( "<spaces>name" -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!tick_xt		;   '
		dw	!literal_xt		;   LITERAL
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
postpone:	dw	brkt_tick
		db	$88
		db	'POSTPONE'
postpone_xt:	local
		jp	!docol__xt		; : POSTPONE ( "<spaces>name" -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!tick__xt		;   (')
		dw	!quest_dup_xt		;   ?DUP
		dw	!zero_equals_xt		;   0=
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -13
			dw	-13		;     \ Undefined word
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!zer_grt_thn_xt		;   0>
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!compile_com_xt	;     COMPILE,
			dw	!doexit__xt	;     EXIT THEN
lbl4:		dw	!dolit__xt		;   ['] (DOLIT)		/ POSTPONE LITERAL
		dw	!dolit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!comma_xt		;   ,
		dw	!dolit__xt		;   [COMPILE] COMPILE,	/ POSTPONE COMPILE,
		dw	!compile_com_xt		;
		dw	!compile_com_xt		;
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
brkt_compil:	dw	postpone
		db	$89
		db	'[COMPILE]'
brkt_compil_xt:	local
		jp	!docol__xt		; : [COMPILE]
		dw	!quest_comp_xt		;   ?COMP
		dw	!tick_xt		;   '
		dw	!compile_com_xt		;   COMPILE,
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
fence:		dw	brkt_compil
		db	$05
		db	'FENCE'
fence_xt:	local
		jp	!dovar__xt		; VARIABLE FENCE
		dw	!_end_			; Cannot forget before _end_
		endl
;-------------------------------------------------------------------------------
forget:		dw	fence
		db	$06
		db	'FORGET'
forget_xt:	local
		jp	!docol__xt		; : FORGET ( "<spaces>name" -- )
		dw	!tick_xt		;   '
		dw	!dup_xt			;   DUP   \ xt xt
		dw	!fence_xt		;   FENCE
		dw	!fetch_xt		;   @
		dw	!u_less_than_xt		;   U<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -15
			dw	-15		;     \ Invalid FORGET
			dw	!throw_xt	;     THROW THEN
lbl2:		dw	!to_name_xt		;   >NAME   \ nt
		dw	!two_minus_xt		;   2-      \ l
		dw	!dup_xt			;   DUP     \ l l
		dw	!fetch_xt		;   @       \ l l1
		dw	!dup_xt			;   DUP     \ l l1 l1
		dw	!doto__xt		;   TO LAST
		dw	!last_xt+3		;
		dw	!l_to_name_xt		;   L>NAME  \ l nt
		dw	!name_from_xt		;   NAME>   \ l xt
		dw	!doto__xt		;   TO LAST-XT
		dw	!lastxt_xt+3		;
		dw	!here_xt		;   HERE    \ l here
		dw	!minus_xt		;   -
		dw	!allot_xt		;   ALLOT   \ Deallocate l-here bytes
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
char:		dw	forget
		db	$04
		db	'CHAR'
char_xt:	local
		jp	!docol__xt		; : CHAR ( "<spaces>name" -- char )
		dw	!blnk_xt		;   BL
		dw	!parse_word_xt		;   PARSE-WORD
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!c_fetch_xt	;     C@
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!dolit__xt		;   -16
		dw	-16			;   \ Attempt to use zero-length string as a name
		dw	!throw_xt		;   THROW
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
brkt_char:	dw	char
		db	$86
		db	'[CHAR]'
brkt_char_xt:	local
		jp	!docol__xt		; : [CHAR] ( "<spaces>name" -- ; -- char )
		dw	!quest_comp_xt		;   ?COMP
		dw	!char_xt		;   CHAR
		dw	!literal_xt		;   LITERAL
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
;
;		PICTURED NUMERIC OUTPUT
;
;-------------------------------------------------------------------------------
hp:		dw	brkt_char
		db	$02
		db	'HP'
hp_xt:		local
		jp	!dovar__xt		; VARIABLE HP
		dw	0
		endl
;-------------------------------------------------------------------------------
less_nb_sgn:	dw	hp
		db	$02
		db	'<#'
less_nb_sgn_xt:	local
		jp	!docol__xt		; : <# ( -- )
		dw	!here_xt		;   HERE
		dw	!dolit__xt		;   #hold_size
		dw	!hold_size		;   \ ENVIRONMENT? /HOLD size
		dw	!plus_xt		;   +
		dw	!hp_xt			;   HP
		dw	!store_xt		;   !
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
hold:		dw	less_nb_sgn
		db	$04
		db	'HOLD'
hold_xt:	local
		jp	!docol__xt		; : HOLD ( char -- )
		dw	!hp_xt			;   HP
		dw	!fetch_xt		;   @
		dw	!dup_xt			;   DUP
		dw	!here_xt		;   HERE
		dw	!u_less_than_xt		;   U<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     -17
			dw	-17		;     \ Pictured numeric output string overflow
			dw	!throw_xt	;     THROW
lbl2:		dw	!one_minus_xt		;   1-
		dw	!dup_xt			;   DUP
		dw	!hp_xt			;   HP
		dw	!store_xt		;   !
		dw	!c_store_xt		;   C!
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
holds:		dw	hold
		db	$05
		db	'HOLDS'
holds_xt:	local
		jp	!docol__xt		; : HOLDS ( c-addr u -- )
lbl1:		dw	!dup_xt			;   BEGIN DUP
		dw	!if__xt			;   WHILE
		dw	lbl3-lbl2		;
lbl2:			dw	!one_minus_xt	;     1-
			dw	!two_dup_xt	;     2DUP
			dw	!plus_xt	;     +
			dw	!c_fetch_xt	;     C@
			dw	!hold_xt	;     HOLD
			dw	!again__xt	;   REPEAT
			dw	lbl3-lbl1	;
lbl3:		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
sign:		dw	holds
		db	$04
		db	'SIGN'
sign_xt:	local
		jp	!docol__xt		; : SIGN ( n -- )
		dw	!zer_lss_thn_xt		;   0<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     '-
			dw	$2d		;     \ The value of '-'
			dw	!hold_xt	;     HOLD THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
nb_sgn_b:	dw	sign
		db	$02
		db	'#B'
nb_sgn_b_xt:	local
		jp	!docol__xt		; : #B ( ud +n -- ud )
		dw	!to_r_xt		;   >R
		dw	!dolit0_xt		;   0
		dw	!r_fetch_xt		;   R@
		dw	!u_m_sl_mod_xt		;   UM/MOD
		dw	!to_r_xt		;   >R
		dw	!r_tick_ftch_xt		;   R'@
		dw	!u_m_sl_mod_xt		;   UM/MOD
		dw	!swap_xt		;   SWAP
		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   9
		dw	9			;
		dw	!greatr_than_xt		;   >
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     7
			dw	7		;
			dw	!plus_xt	;     + THEN
lbl2:		dw	!dolit__xt		;   '0
		dw	$0030			;   \ The value of '0'
		dw	!plus_xt		;   +
		dw	!hold_xt		;   HOLD
		dw	!r_from_xt		;   R>
		dw	!r_from_drop_xt		;   R>DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
nb_sg_b_s:	dw	nb_sgn_b
		db	$03
		db	'#BS'
nb_sg_b_s_xt:	local
		jp	!docol__xt		; : #BS ( ud n+ -- ud )
		dw	!to_r_xt		;   >R
lbl1:			dw	!r_fetch_xt	;   BEGIN R@
			dw	!nb_sgn_b_xt	;     #B
			dw	!two_dup_xt	;     2DUP
			;dw	!or_xt
			;dw	!zero_equals_xt
			dw	!d_zero_equ_xt	;     D0=
		dw	!until__xt		;   UNTIL
		dw	lbl2-lbl1		;
lbl2:		dw	!r_from_drop_xt		;   R>DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
nmbr_sign:	dw	nb_sg_b_s
		db	$01
		db	'#'
nmbr_sign_xt:	local
		jp	!docol__xt		; : # ( ud -- ud )
		dw	!base_xt		;   BASE
		dw	!fetch_xt		;   @
		dw	!nb_sgn_b_xt		;   #B
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
nmbr_sign_s:	dw	nmbr_sign
		db	$02
		db	'#S'
nmbr_sign_s_xt:	local
		jp	!docol__xt		; : #S ( ud -- ud )
		dw	!base_xt		;   BASE
		dw	!fetch_xt		;   @
		dw	!nb_sg_b_s_xt		;   #BS
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
nb_sgn_grtr:	dw	nmbr_sign_s
		db	$02
		db	'#>'
nb_sgn_grtr_xt:	local
		jp	!docol__xt		; : #> ( xd -- c-addr u )
		dw	!two_drop_xt		;   2DROP
		dw	!here_xt		;   HERE
		dw	!dolit__xt		;   #hold_size
		dw	!hold_size		;   \ ENVIRONMENT? /HOLD size
		dw	!plus_xt		;   +
		dw	!hp_xt			;   HP
		dw	!fetch_xt		;   @
		dw	!dup_xt			;   DUP
		dw	!not_rot_xt		;   -ROT
		dw	!minus_xt		;   -
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		NUMERIC OUTPUT
;
;-------------------------------------------------------------------------------
base_dot:	dw	nb_sgn_grtr
		db	$05
		db	'BASE.'
base_dot_xt:	local
		jp	!docol__xt		; : BASE. ( u -- )
		dw	!dolit0_xt		;   0
		dw	!less_nb_sgn_xt		;   <#
		dw	!swap_xt		;   SWAP
		dw	!nb_sg_b_s_xt		;   #BS
		dw	!nb_sgn_grtr_xt		;   #>
		dw	!type_xt		;   TYPE
		dw	!space_xt		;   SPACE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
bin_dot:	dw	base_dot
		db	$04
		db	'BIN.'
bin_dot_xt:	local
		jp	!docol__xt		; : BIN. ( u -- )
		dw	!dolit2_xt		;
		dw	!base_dot_xt		;
		dw	!doret__xt		;
		endl
;-------------------------------------------------------------------------------
dec_dot:	dw	bin_dot
		db	$04
		db	'DEC.'
dec_dot_xt:	local
		jp	!docol__xt		; : DEC. ( u -- )
		dw	!dolit__xt		;   10
		dw	10			;
		dw	!base_dot_xt		;   BASE.
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
hex_dot:	dw	dec_dot
		db	$04
		db	'HEX.'
hex_dot_xt:	local
		jp	!docol__xt		; : HEX. ( u -- )
		dw	!dolit__xt		;   16
		dw	16			;
		dw	!base_dot_xt		;   BASE.
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
d_dot_:		dw	hex_dot
		db	$04
		db	'(D.)'
d_dot__xt:	local
		jp	!docol__xt		; : (D.) ( d -- )
		dw	!tuck_xt		;   TUCK
		dw	!d_abs_xt		;   DABS
		dw	!less_nb_sgn_xt		;   <#
		dw	!nmbr_sign_s_xt		;   #S
		dw	!rot_xt			;   ROT
		dw	!sign_xt		;   SIGN
		dw	!nb_sgn_grtr_xt		;   #>
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
d_dot:		dw	d_dot_
		db	$02
		db	'D.'
d_dot_xt:	local
		jp	!docol__xt		; : D. ( d -- )
		dw	!d_dot__xt		;   (D.)
		dw	!type_xt		;   TYPE
		dw	!space_xt		;   SPACE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
d_dot_r:	dw	d_dot
		db	$03
		db	'D.R'
d_dot_r_xt:	local
		jp	!docol__xt		; : D.R ( d +n -- )
		dw	!to_r_xt		;   >R
		dw	!d_dot__xt		;   (D.)
		dw	!r_from_xt		;   R>
		dw	!over_xt		;   OVER
		dw	!minus_xt		;   -
		dw	!spaces_xt		;   SPACES
		dw	!type_xt		;   TYPE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
dot:		dw	d_dot_r
		db	$01
		db	'.'
dot_xt:		local
		jp	!docol__xt		; : . ( n -- )
		dw	!s_to_d_xt		;   S>D
		dw	!d_dot_xt		;   D.
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
dot_r:		dw	dot
		db	$02
		db	'.R'
dot_r_xt:	local
		jp	!docol__xt		; : .R ( n +n -- )
		dw	!to_r_xt		;   >R
		dw	!s_to_d_xt		;   S>D
		dw	!r_from_xt		;   R>
		dw	!d_dot_r_xt		;   D.R
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
u_dot:		dw	dot_r
		db	$02
		db	'U.'
u_dot_xt:	local
		jp	!docol__xt		; : U. ( u -- )
		dw	!dolit0_xt		;   0
		dw	!d_dot_xt		;   D.
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
u_dot_r:	dw	u_dot
		db	$03
		db	'U.R'
u_dot_r_xt:	local
		jp	!docol__xt		; : U.R ( u +n -- )
		dw	!dolit0_xt		;   0
		dw	!swap_xt		;   SWAP
		dw	!d_dot_r_xt		;   D.R
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
n_dot_s:	dw	u_dot_r
		db	$03
		db	'N.S'
n_dot_s_xt:	local
		jp	!docol__xt			; : N.S ( -- )
		dw	!depth_xt			;   DEPTH
		dw	!one_minus_xt			;   1-
		dw	!min_xt				;   MIN
		dw	!dup_xt				;   DUP
		dw	!zer_grt_thn_xt			;   0>
		dw	!if__xt				;   IF
		dw	lbl4-lbl1			;
lbl1:			dw	!one_minus_xt		;     1-
			dw	!dolit0_xt		;     0
			dw	!swap_xt		;     SWAP
			dw	!do__xt			;     DO
			dw	lbl3-lbl2		;
lbl2:				dw	!i_xt		;       I
				dw	!pick_xt	;       PICK
				dw	!dot_xt		;       .
			dw	!dolitm1_xt		;       -1
			dw	!plus_loop__xt		;     +LOOP
			dw	lbl3-lbl2		;
lbl3:			dw	!doexit__xt		;     EXIT THEN
lbl4:		dw	!drop_xt			;   DROP
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
dot_s:		dw	n_dot_s
		db	$02
		db	'.S'
dot_s_xt:	local
		jp	!docol__xt		; : .S ( -- )
		dw	!depth_xt		;   DEPTH
		dw	!n_dot_s_xt		;   N.S
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
question:	dw	dot_s
		db	$01
		db	'?'
question_xt:	local
		jp	!docol__xt		; : ? ( addr -- )
		dw	!fetch_xt		;   @
		dw	!dot_xt			;   .
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		DUMP
;
;-------------------------------------------------------------------------------
dump:		dw	question
		db	$04
		db	'DUMP'
dump_xt:	local
		jp	!docol__xt		; : DUMP ( addr u -- )
		dw	!dolit0_xt		;   0
		dw	!quest_do__xt		;   ?DO
		dw	lbl2-lbl1		;
lbl1:			dw	!dup_xt		;     DUP
			dw	!c_fetch_xt	;     C@
			dw	!hex_dot_xt	;     HEX.
			dw	!char_plus_xt	;     C+
		dw	!loop__xt		;   LOOP
		dw	lbl2-lbl1		;
lbl2:		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		WORDS
;
;-------------------------------------------------------------------------------
words:		dw	dump
		db	$05
		db	'WORDS'
words_xt:	local
		jp	!docol__xt				; : WORDS ( optional: "substring" -- )
		dw	!cr_xt					;   CR
		dw	!blnk_xt				;   BL
		dw	!parse_word_xt				;   PARSE-WORD
		dw	!two_to_r_xt				;   2>R
		dw	!dolit0_xt				;   0
		dw	!last_xt				;   LAST
lbl1:		dw	!quest_dup_xt				;   BEGIN ?DUP
		dw	!if__xt					;     IF
		dw	lbl5-lbl2				;
lbl2:			dw	!dup_xt				;       DUP
			dw	!l_to_name_xt			;       L>NAME
			dw	!name_to_str_xt			;       NAME>STRING
			dw	!two_r_fetch_xt			;       2R@
			dw	!search_xt			;       SEARCH
			dw	!nip_xt				;       NIP
			dw	!nip_xt				;       NIP
			dw	!if__xt				;       IF
			dw	lbl4-lbl3			;
lbl3:				dw	!dup_xt			;         DUP
				dw	!rot_xt			;         ROT
				dw	!swap_xt		;         SWAP
				dw	!l_to_name_xt		;         L>NAME
				dw	!name_to_str_xt		;         NAME>STRING
				dw	!rot_xt			;         ROT
				dw	!over_xt		;         OVER
				dw	!plus_xt		;         +
				dw	!one_plus_xt		;         1+ \ The size of a space after each word
				dw	!dup_xt			;         DUP
				dw	!dolit__xt		;         152
				dw	152			;         \ 160 characters - the size of '(more) ' - 1
				dw	!greatr_than_xt		;         >
				dw	!if__xt			;         IF
				dw	lbl2a-lbl1a		;
lbl1a:					dw	!drop_xt	;           DROP
					dw	!dup_xt		;           DUP
					dw	!doslit__xt	;           S" (more)"
					dw	6		;
					db	'(more)'	;
					dw	!pause_xt	;           PAUSE
					dw	!page_xt	;           PAGE THEN
lbl2a:				dw	!not_rot_xt		;         -ROT
				dw	!type_xt		;         TYPE
				dw	!space_xt		;         SPACE
				dw	!swap_xt		;         SWAP THEN
lbl4:			dw	!fetch_xt			;       @
			dw	!again__xt			;       AGAIN THEN
			dw	lbl5-lbl1			;
lbl5:		dw	!doslit__xt				;   S" (end)"
		dw	5					;
		db	'(end)'					;
		dw	!pause_xt				;   PAUSE
		dw	!r_from_drop_xt				;   R>DROP
		dw	!r_from_drop_xt				;   R>DROP
		dw	!drop_xt				;   DROP
		dw	!cr_xt					;   CR
		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
;
;
;
;-------------------------------------------------------------------------------
unused:		dw	words
		db	$06
		db	'UNUSED'
unused_xt:	local
		jp	!docol__xt		; : UNUSED ( -- u )
		dw	!dolit__xt		;   dict_limit
		dw	!dict_limit		;
		dw	!here_xt		;   HERE
		dw	!minus_xt		;   -
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		EDITING
;
;-------------------------------------------------------------------------------
origx_:		dw	unused
		db	$07
		db	'(ORIGX)'
origx__xt:	local
		jp	!doval__xt		; 0 VALUE (ORIGX)
		dw	0
		endl
;-------------------------------------------------------------------------------
origy_:		dw	origx_
		db	$07
		db	'(ORIGY)'
origy__xt:	local
		jp	!doval__xt		; 0 VALUE (ORIGY)
		dw	0
		endl
;-------------------------------------------------------------------------------
beginning_:	dw	origy_
		db	$0b
		db	'(BEGINNING)'
beginning__xt:	local
		jp	!doval__xt		; 0 VALUE (BEGINNING)
		dw	0
		endl
;-------------------------------------------------------------------------------
current_:	dw	beginning_
		db	$09
		db	'(CURRENT)'
current__xt:	local
		jp	!doval__xt		; 0 VALUE (CURRENT)
		dw	0
		endl
;-------------------------------------------------------------------------------
end_:		dw	current_
		db	$05
		db	'(END)'
end__xt:	local
		jp	!doval__xt		; 0 VALUE (END)
		dw	0
		endl
;-------------------------------------------------------------------------------
lbound_:	dw	end_
		db	$08
		db	'(LBOUND)'
lbound__xt:	local
		jp	!doval__xt		; 0 VALUE (LBOUND)
		dw	0
		endl
;-------------------------------------------------------------------------------
ubound_:	dw	lbound_
		db	$08
		db	'(UBOUND)'
ubound__xt:	local
		jp	!doval__xt		; 0 VALUE (UBOUND)
		dw	0
		endl
;-------------------------------------------------------------------------------
ins_:		dw	ubound_
		db	$05
		db	'(INS)'
ins__xt:	local
		jp	!doval__xt		; 0 VALUE (INS)
		dw	0
		endl
;-------------------------------------------------------------------------------
position_:	dw	ins_
		db	$0a
		db	'(POSITION)'
position__xt:	local
		jp	!docol__xt		; : POSITION ( -- n n )
		dw	!origx__xt		;   (ORIGX)
		dw	!current__xt		;   (CURRENT)
		dw	!plus_xt		;   +
		dw	!x_max_fetch_xt		;   XMAX@
		dw	!slash_mod_xt		;   /MOD
		dw	!origy__xt		;   (ORIGY)
		dw	!plus_xt		;   +
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
scroll_up_:	dw	position_
		db	$0b
		db	'(SCROLL-UP)'
scroll_up__xt:	local
		jp	!docol__xt		; : (SCROLL-UP)
		dw	!y_max_fetch_xt		;   YMAX@
		dw	!one_minus_xt		;   1-
		dw	!y_store_xt		;   Y!
		dw	!dolitm1_xt		;   -1
		dw	!doplusto__xt		;   +TO (ORIGY)
		dw	!origy__xt+3		;
		dw	!dolit0_xt		;   0
		dw	!y_fetch_xt		;   Y@
		dw	!end__xt		;   (END)
		dw	!current__xt		;   (CURRENT)
		dw	!x_fetch_xt		;   X@
		dw	!minus_xt		;   -
		dw	!dup_xt			;   DUP
		dw	!beginning__xt		;   (BEGINNING)
		dw	!plus_xt		;   +
		dw	!not_rot_xt		;   -ROT
		dw	!minus_xt		;   -
		dw	!dolit1_xt		;   1
		dw	!scroll_xt		;   SCROLL
		dw	!at_type_xt		;   AT-TYPE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
scroll_dwn_:	dw	scroll_up_
		db	$0d
		db	'(SCROLL-DOWN)'
scroll_dwn__xt:	local
		jp	!docol__xt		; : (SCROLL-DOWN)
		dw	!dolit0_xt		;   0
		dw	!y_store_xt		;   Y!
		dw	!dolit1_xt		;   1
		dw	!doplusto__xt		;   +TO (ORIGY)
		dw	!origy__xt+3		;
		dw	!origy__xt		;   (ORIGY)
		dw	!zer_lss_thn_xt		;   0<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit0_xt	;     0
			dw	!y_fetch_xt	;     Y@
			dw	!beginning__xt	;     (BEGINNING)
			dw	!current__xt	;     (CURRENT)
			dw	!plus_xt	;     +
			dw	!x_fetch_xt	;     X@
			dw	!minus_xt	;     -
		dw	!ahead__xt		;   ELSE
		dw	lbl3-lbl2		;
lbl2:			dw	!origx__xt	;     (ORIGX)
			dw	!y_fetch_xt	;     Y@
			dw	!beginning__xt	;     (BEGINNING) THEN
lbl3:		dw	!x_max_fetch_xt		;   XMAX@
		dw	!end__xt		;   (END)
		dw	!min_xt			;   MIN
		dw	!dolitm1_xt		;   -1
		dw	!scroll_xt		;   SCROLL
		dw	!at_type_xt		;   AT-TYPE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
refresh_:	dw	scroll_dwn_
		db	$09
		db	'(REFRESH)'
refresh__xt:	local
		jp	!docol__xt		; : (REFRESH) ( -- )
		dw	!position__xt		;   (POSITION)
		dw	!swap_xt		;   SWAP
		dw	!x_store_xt		;   X!
		dw	!dup_xt			;   DUP
		dw	!dolit0_xt		;   0
		dw	!y_max_fetch_xt		;   YMAX@
		dw	!within_xt		;   WITHIN
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!y_store_xt	;     Y!
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!zer_lss_thn_xt		;   0<
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!scroll_dwn__xt	;     (SCROLL-DOWN)
			dw	!doexit__xt	;     EXIT THEN
lbl4:		dw	!scroll_up__xt		;   (SCROLL-UP)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
power_off:	dw	refresh_
		db	$09
		db	'POWER-OFF'		; ( -- )
power_off_xt:	local
		pre_on
		mvw	(!cx),$0008		; System control driver
		mv	il,$41			; 'Power off'
		callf	!iocs
		pre_off
		jp	!interp__
		endl
;-------------------------------------------------------------------------------
clear_:		dw	power_off
		db	$07
		db	'(CLEAR)'
clear__xt:	local
		jp	!docol__xt		; : (CLEAR)
		dw	!dolit0_xt		;   0
		dw	!doto__xt		;   TO (CURRENT)
		dw	!current__xt+3		;
		dw	!position__xt		;   (POSITION)
		dw	!nip_xt			;   NIP
		dw	!zer_lss_thn_xt		;   0<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit0_xt	;     0
			dw	!dolit0_xt	;     0
			dw	!doto__xt	;     TO (ORIGY)
			dw	!origy__xt+3	;
			dw	!dup_xt		;     DUP
			dw	!beginning__xt	;     (BEGINNING)
			dw	!end__xt	;     (END)
			dw	!at_type_xt	;     AT-TYPE THEN
lbl2:		dw	!lbound__xt		;   (LBOUND)
		dw	!doto__xt		;   TO (CURRENT)
		dw	!current__xt+3		;
		dw	!position__xt		;   (POSITION)
		dw	!two_dup_xt		;   2DUP
		dw	!at_x_y_xt		;   AT_XY
		dw	!end__xt		;   (END)
		dw	!lbound__xt		;   (LBOUND)
		dw	!minus_xt		;   -
		dw	!at_clr_xt		;   AT-CLR
		dw	!current__xt		;   (CURRENT)
		dw	!doto__xt		;   TO (END)
		dw	!end__xt+3		;
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;all_clear_:	dw	clear_
;		db	$0b
;		db	'(ALL-CLEAR)'
;all_clear__xt:	local
;		jp	!docol__xt
;		dw	!page_xt
;		dw	!dolit0_xt
;		dw	!dup_xt
;		dw	!dup_xt
;		dw	!doto__xt
;		dw	!origx__xt+3
;		dw	!doto__xt
;		dw	!origy__xt+3
;		dw	!doto__xt
;		dw	!current__xt+3
;		dw	!lbound__xt
;		dw	!dup_xt
;		dw	!doto__xt
;		dw	!current__xt+3
;		dw	!doto__xt
;		dw	!end__xt+3
;		dw	!doret__xt
;		endl
;-------------------------------------------------------------------------------
up_:		dw	clear_
		db	$04
		db	'(UP)'
up__xt:		local
		jp	!docol__xt		; : (UP) ( -- )
		dw	!current__xt		;   (CURRENT)
		dw	!x_max_fetch_xt		;   XMAX@
		dw	!minus_xt		;   -
		dw	!lbound__xt		;   (LBOUND)
		dw	!max_xt			;   MAX
		dw	!doto__xt		;   TO (CURRENT)
		dw	!current__xt+3		;
		dw	!refresh__xt		;   (REFRESH)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
down_:		dw	up_
		db	$06
		db	'(DOWN)'
down__xt:	local
		jp	!docol__xt		; : (DOWN) ( -- )
		dw	!current__xt		;   (CURRENT)
		dw	!x_max_fetch_xt		;   XMAX@
		dw	!plus_xt		;   +
		dw	!end__xt		;   (END)
		dw	!min_xt			;   MIN
		dw	!doto__xt		;   TO (CURRENT)
		dw	!current__xt+3		;
		dw	!refresh__xt		;   (REFRESH)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
left_:		dw	down_
		db	$06
		db	'(LEFT)'
left__xt:	local
		jp	!docol__xt		; : (LEFT) ( -- )
		dw	!current__xt		;   (CURRENT)
		dw	!lbound__xt		;   (LBOUND)
		dw	!greatr_than_xt		;   >
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolitm1_xt	;     -1
			dw	!doplusto__xt	;     +TO (CURRENT)
			dw	!current__xt+3	;
			dw	!refresh__xt	;     (REFRESH) THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
right_:		dw	left_
		db	$07
		db	'(RIGHT)'
right__xt:	local
		jp	!docol__xt		; : (RIGHT) ( -- )
		dw	!ubound__xt		;   (UBOUND)
		dw	!one_minus_xt		;   1-
		dw	!end__xt		;   (END)
		dw	!min_xt			;   MIN
		dw	!current__xt		;   (CURRENT)
		dw	!greatr_than_xt		;   >
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit1_xt	;     1
			dw	!doplusto__xt	;     +TO (CURRENT)
			dw	!current__xt+3	;
			dw	!refresh__xt	;     (REFRESH) THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
return_:	dw	right_
		db	$08
		db	'(RETURN)'
return__xt:	local
		jp	!docol__xt		; : (RETURN) ( -- )
		dw	!beginning__xt		;   (BEGINNING)
		dw	!lbound__xt		;   (LBOUND)
		dw	!plus_xt		;   +
		dw	!end__xt		;   (END)
		dw	!dup_xt			;   DUP
		dw	!doto__xt		;   TO (CURRENT)
		dw	!current__xt+3		;
		dw	!refresh__xt		;   (REFRESH)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
del_:		dw	return_
		db	$05
		db	'(DEL)'
del__xt:	local
		jp	!docol__xt		; : (DEL) ( -- )
		dw	!end__xt		;   (END)
		dw	!current__xt		;   (CURRENT)
		dw	!minus_xt		;   -
		dw	!quest_dup_xt		;   ?DUP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!beginning__xt	;     (BEGINNING)
			dw	!current__xt	;     (CURRENT)
			dw	!plus_xt	;     +
			dw	!dup_xt		;     DUP
			dw	!one_plus_xt	;     1+
			dw	!swap_xt	;     SWAP
			dw	!rot_xt		;     ROT
			dw	!c_move_xt	;     CMOVE
			dw	!dolitm1_xt	;     -1
			dw	!doplusto__xt	;
			dw	!end__xt+3	;     (END)
			dw	!position__xt	;     (POSITION)
			dw	!beginning__xt	;     (BEGINNING)
			dw	!current__xt	;     (CURRENT)
			dw	!plus_xt	;     +
			dw	!end__xt	;     (END)
			dw	!current__xt	;     (CURRENT)
			dw	!minus_xt	;     -
			dw	!at_type_xt	;     AT-TYPE
			dw	!origx__xt	;     (ORIGX)
			dw	!end__xt	;     (END)
			dw	!plus_xt	;     +
			dw	!x_max_fetch_xt	;     XMAX@
			dw	!slash_mod_xt	;     /MOD
			dw	!origy__xt	;     (ORIGY)
			dw	!plus_xt	;     +
			dw	!dolit1_xt	;     1
			dw	!at_clr_xt	;     AT-CLR THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
bs_:		dw	del_
		db	$04
		db	'(BS)'
bs__xt:		local
		jp	!docol__xt		; : (BS) ( -- )
		dw	!current__xt		;   (CURRENT)
		dw	!lbound__xt		;   (LBOUND)
		dw	!greatr_than_xt		;   >
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolitm1_xt	;     -1
			dw	!doplusto__xt	;     +TO (CURRENT)
			dw	!current__xt+3	;
			dw	!refresh__xt	;     (REFRESH)
			dw	!del__xt	;     (DEL) THEN
lbl2:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
replace_:	dw	bs_
		db	$09
		db	'(REPLACE)'
replace__xt:	local
		jp	!docol__xt		; ; (REPLACE) ( char -- )
		dw	!beginning__xt		;   (BEGINNING)
		dw	!current__xt		;   (CURRENT)
		dw	!plus_xt		;   +
		dw	!c_store_xt		;   C!
		dw	!position__xt		;   (POSITION)
		dw	!beginning__xt		;   (BEGINNING)
		dw	!current__xt		;   (CURRENT)
		dw	!plus_xt		;   +
		dw	!dolit1_xt		;   1
		dw	!at_type_xt		;   AT-TYPE
		dw	!current__xt		;   (CURRENT)
		dw	!end__xt		;   (END)
		dw	!equals_xt		;   =
		dw	!end__xt		;   (END)
		dw	!ubound__xt		;   (UBOUND)
		dw	!less_than_xt		;   <
		dw	!and_xt			;   AND
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit1_xt	;     1
			dw	!doplusto__xt	;     +TO (END)
			dw	!end__xt+3	;   THEN
lbl2:		dw	!right__xt		;   (RIGHT)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
insert_:	dw	replace_
		db	$08
		db	'(INSERT)'
insert__xt:	local
		jp	!docol__xt		; ; (INSERT) ( char -- )
		dw	!end__xt		;   (END)
		dw	!ubound__xt		;   (UBOUND)
		dw	!less_than_xt		;   <
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!beginning__xt	;     (BEGINNING)
			dw	!current__xt	;     (CURRENT)
			dw	!plus_xt	;     +
			dw	!dup_xt		;     DUP
			dw	!dup_xt		;     DUP
			dw	!one_plus_xt	;     1+
			dw	!end__xt	;     (END)
			dw	!current__xt	;     (CURRENT)
			dw	!minus_xt	;     -
			dw	!c_move_up_xt	;     CMOVE>
			dw	!c_store_xt	;     C!
			dw	!dolit1_xt	;     1
			dw	!doplusto__xt	;     +TO (END)
			dw	!end__xt+3	;
			dw	!position__xt	;     (POSITION)
			dw	!beginning__xt	;     (BEGINNING)
			dw	!current__xt	;     (CURRENT)
			dw	!plus_xt	;     +
			dw	!end__xt	;     (END)
			dw	!current__xt	;     (CURRENT)
			dw	!minus_xt	;     -
			dw	!at_type_xt	;     AT-TYPE
			dw	!right__xt	;     (RIGHT)
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
edit:		dw	insert_
		db	$04
		db	'EDIT'
edit_xt:	local
		jp	!docol__xt				; : EDIT ( c-addr +n n n n -- c-addr +n )
		dw	!doto__xt				;   TO (LBOUND)    \ n left margin (not editable)
		dw	!lbound__xt+3				;
		dw	!doto__xt				;   TO (CURRENT)   \ n starting position in the string to edit
		dw	!current__xt+3				;
		dw	!doto__xt				;   TO (END)       \ n length of the string to edit
		dw	!end__xt+3				;
		dw	!doto__xt				;   TO (UBOUND)    \ +n buffer size
		dw	!ubound__xt+3				;
		dw	!doto__xt				;   TO (BEGINNING) \ c-addr buffer address
		dw	!beginning__xt+3			;
		dw	!x_fetch_xt				;   X@
		dw	!doto__xt				;   TO (ORIGX)
		dw	!origx__xt+3				;
		dw	!y_fetch_xt				;   Y@
		dw	!doto__xt				;   TO (ORIGY)
		dw	!origy__xt+3				;
		dw	!false_xt				;   FALSE
		dw	!doto__xt				;   TO (INS)
		dw	!ins__xt+3				;
		dw	!position__xt				;   (POSITION)
		dw	!nip_xt					;   NIP
		dw	!y_max_fetch_xt				;   YMAX@
		dw	!one_minus_xt				;   1-
		dw	!greatr_than_xt				;   >
		dw	!if__xt					;   IF
		dw	lbl2a-lbl1a				;
lbl1a:			dw	!y_max_fetch_xt			;     YMAX@
			dw	!one_minus_xt			;     1-
			dw	!y_store_xt			;     Y!
			dw	!position__xt			;     (POSITION)
			dw	!nip_xt				;     NIP
			dw	!y_max_fetch_xt			;     YMAX@
			dw	!minus_xt			;     -
			dw	!one_plus_xt			;     1+
			dw	!dup_xt				;     DUP
			dw	!scroll_xt			;     SCROLL
			dw	!y_max_fetch_xt			;     YMAX@
			dw	!swap_xt			;     SWAP
			dw	!minus_xt			;     -
			dw	!doto__xt			;     TO (ORIGY)
			dw	!origy__xt+3			;   THEN
lbl2a:		dw	!dolit0_xt				;   0
		dw	!set_cursor_xt				;   SET-CURSOR
		dw	!origx__xt				;   (ORIGX)
		dw	!origy__xt				;   (ORIGY)
		dw	!beginning__xt				;   (BEGINNING)
		dw	!end__xt				;   (END)       \ n n c-addr u
		dw	!at_type_xt				;   AT-TYPE
		dw	!position__xt				;   (POSITION)  \ n n
		dw	!at_x_y_xt				;   AT_XY
lbl1:			dw	!e_key_xt			;   BEGIN EKEY CASE
			dw	!dolit__xt			;     $0d
			dw	$000d				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl3-lbl2			;
lbl2:				;dw	!drop_xt		;
				dw	!return__xt		;       (RETURN)
				dw	!doexit__xt		;       EXIT
			;dw	!ahead__xt			;     ENDOF \ ENDOF code after EXIT can be removed
			;dw	lbl28-lbl3			;
lbl3:			dw	!dolit__xt			;       $08
			dw	$0008				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl5-lbl4			;
lbl4:				;dw	!drop_xt		;
				dw	!bs__xt			;       (BS)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl5			;
lbl5:			dw	!dolit__xt			;       $7f
			dw	$007f				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl7-lbl6			;
lbl6:				;dw	!drop_xt		;
				dw	!del__xt		;       (DEL)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl7			;
lbl7:			dw	!dolit__xt			;       $1c
			dw	$001c				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl9-lbl8			;
lbl8:				;dw	!drop_xt		;
				dw	!right__xt		;       (RIGHT)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl9			;
lbl9:			dw	!dolit__xt			;       $1d
			dw	$001d				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl11-lbl10			;
lbl10:				;dw	!drop_xt		;
				dw	!left__xt		;       (LEFT)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl11			;
lbl11:			dw	!dolit__xt			;       $1e
			dw	$001e				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl13-lbl12			;
lbl12:				;dw	!drop_xt		;
				dw	!up__xt			;       (UP)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl13			;
lbl13:			dw	!dolit__xt			;       $1f
			dw	$001f				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl15-lbl14			;
lbl14:				;dw	!drop_xt		;
				dw	!down__xt		;       (DOWN)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl15			;
lbl15:			dw	!dolit__xt			;       $0c
			dw	$000c				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl17-lbl16			;
lbl16:				;dw	!drop_xt		;
				dw	!clear__xt		;       (CLEAR)
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl17			;
;lbl15_:			dw	!dolit__xt		;
;			dw	-$2c				;
;			;dw	!over_xt			;
;			;dw	!equals_xt			;
;			;dw	!if__xt				;
;			dw	!of__xt				;
;			dw	lbl17-lbl16_			;
;lbl16_:				;dw	!drop_xt	;
;				dw	!all_clear__xt		;
;			dw	!ahead__xt			;
;			dw	lbl28-lbl17			;
lbl17:			dw	!dolit__xt			;
			dw	$0012				;       $12
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl19-lbl18			;
lbl18:				;dw	!drop_xt		;
				dw	!ins__xt		;       (INS)
				dw	!invert_xt		;       INVERT
				dw	!doto__xt		;       TO (INS)
				dw	!ins__xt+3		;
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl19			;
lbl19:			dw	!dolit__xt			;       $fffc
			dw	$fffc				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl21-lbl20			;
lbl20:				;dw	!drop_xt		;
				dw	!power_off_xt		;       POWER-OFF
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl21			;
lbl21:			dw	!dolit__xt			;       $fff1
			dw	$fff1				;
			;dw	!over_xt			;
			;dw	!equals_xt			;
			;dw	!if__xt				;
			dw	!of__xt				;     OF
			dw	lbl23-lbl22			;
lbl22:				;dw	!drop_xt		;
				dw	!power_off_xt		;       POWER-OFF
			dw	!ahead__xt			;     ENDOF
			dw	lbl28-lbl23			;
lbl23:			dw	!dup_xt				;       DUP
			dw	!blnk_xt			;       BL
			dw	!dolit__xt			;       $7f
			dw	$007f				;
			dw	!within_xt			;       WITHIN
			dw	!if__xt				;       IF
			dw	lbl27-lbl24			;
lbl24:				dw	!dup_xt			;         DUP
				dw	!ins__xt		;         (INS)
				dw	!if__xt			;         IF
				dw	lbl26-lbl25		;
lbl25:					dw	!insert__xt	;           (INSERT)
				dw	!ahead__xt		;         ELSE
				dw	lbl27-lbl26		;
lbl26:					dw	!replace__xt	;           (REPLACE) THEN
lbl27:		dw	!drop_xt				;     ENDCASE \ also DROP of the default case
lbl28:		dw	!again__xt				;   AGAIN
		dw	lbl29-lbl1				;
lbl29:		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
;
;		NUMBER PARSING AND CONVERSION
;
;-------------------------------------------------------------------------------
to_binary:	dw	edit
		db	$07
		db	'>BINARY'		; ( char -- n )
to_binary_xt:	local
		ex	a,b			; Check if TOS
		cmp	a,0			; high-order 8 bits
		jrnz	lbl1			; are zero
		ex	a,b			;
		cmp	a,'0'			; Check '0'
		jrc	lbl1			;
		cmp	a,':'			; Check '9'+1
		jrc	lbl2			;
		and	a,$df			; Make upper case
		cmp	a,'A'			; Check 'A'
		jrc	lbl1			;
		sub	a,7			; Close the gap
		cmp	a,'T'			; Check 'Z'+1-7
		jrc	lbl2			;
lbl1:		mv	ba,$ff2f		; Set new TOS to -1, a bad character has been encountered
lbl2:		sub	a,$30			; Set new TOS
		jp	!cont__
;		jp	!docol__xt		; : >BINARY ( char -- u )
;		dw	!dup_xt			;   DUP
;		dw	!dolit__xt		;   '0
;		dw	$30			;   \ The value of '0'
;		dw	!dolit__xt		;   ':
;		dw	$3a			;   \ The value of '9' + 1
;		dw	!within_xt		;   WITHIN
;		dw	!if__xt			;   IF
;		dw	lbl2-lbl1		;
;lbl1:			dw	!dolit__xt	;     $30
;			dw	$30		;     \ The value of '0'
;			dw	!minus_xt	;     -
;			dw	!doexit__xt	;     EXIT THEN
;lbl2:		dw	!dolit__xt		;   $20
;		dw	$20			;   \ Make char lower case
;		dw	!or_xt			;   OR
;lbl4:		dw	!dup_xt			;   DUP
;		dw	!dolit__xt		;   'a
;		dw	$61			;   \ The value of 'a'
;		dw	!dolit__xt		;   '{
;		dw	$7b			;   \ The value of 'z' + 1
;		dw	!within_xt		;   WITHIN
;		dw	!if__xt			;   IF
;		dw	lbl6-lbl5		;
;lbl5:			dw	!dolit__xt	;     $57
;			dw	$0057		;
;			dw	!minus_xt	;     -
;			dw	!doexit__xt	;     EXIT THEN
;lbl6:		dw	!drop_xt		;   DROP
;		dw	!dolitm1_xt 		;   -1 \ A negative value means that a bad character has been encountered
;		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
to_number:	dw	to_binary
		db	$07
		db	'>NUMBER'
to_number_xt:	local
		jp	!docol__xt			; : >NUMBER ( ud c-addr u -- ud c-addr u )
		dw	!two_swap_xt			;   2SWAP
		dw	!two_to_r_xt			;   2>R
lbl1:		dw	!dup_xt				;   BEGIN DUP
		dw	!if__xt				;   WHILE
		dw	lbl5-lbl2			;
lbl2:			dw	!next_char_xt		;     NEXT-CHAR
			dw	!to_binary_xt		;     >BINARY
			dw	!dup_xt			;     DUP
			dw	!dolit0_xt		;     0
			dw	!base_xt		;     BASE
			dw	!fetch_xt		;     @
			dw	!within_xt		;     WITHIN
			dw	!invert_xt		;     INVERT
			dw	!if__xt			;     IF
			dw	lbl4-lbl3		;
lbl3:				dw	!drop_xt	;       DROP
				dw	!dolitm1_xt	;       -1
				dw	!slash_str_xt	;       /STRING
				dw	!two_r_from_xt	;       2R>
				dw	!two_swap_xt	;       2SWAP
				dw	!doexit__xt	;       EXIT THEN
lbl4:			dw	!s_to_d_xt		;     S>D
			dw	!two_r_from_xt		;     2R>
			dw	!base_xt		;     BASE
			dw	!fetch_xt		;     @
			dw	!u_m_d_star_xt		;     UMD*
			dw	!d_plus_xt		;     D+
			dw	!two_to_r_xt		;     2>R
			dw	!again__xt		;   REPEAT
			dw	lbl5-lbl1		;
lbl5:		dw	!two_r_from_xt			;   2R>
		dw	!two_swap_xt			;   2SWAP
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
single:		dw	to_number
		db	$06
		db	'SINGLE'
single_xt:	local
		jp	!dovar__xt		; VARIABLE SINGLE
		dw	0			; A flag to indicate single cell, set by >DOUBLE
		endl
;-------------------------------------------------------------------------------
to_double:	dw	single
		db	$07
		db	'>DOUBLE'
to_double_xt:	local
		jp	!docol__xt				; : >DOUBLE ( c-addr u -- d true ) or ( c-addr u -- false )
		dw	!single_xt				;   SINGLE
		dw	!on_xt					;   ON         \ Assume single cell, unless a . is used
		dw	!next_char_xt				;   NEXT-CHAR
			dw	!dolit__xt			;   CASE
			dw	$24				;     '$ \ The value of the '$' character
			dw	!of__xt				;   OF
			dw	lbl2-lbl1			;
lbl1:				dw	!dolit__xt		;     16
				dw	16			;
			dw	!ahead__xt			;   ENDOF
			dw	lbl11-lbl2			;
lbl2:			dw	!dolit__xt			;     '#
			dw	$23				;     \ The value of the '#' character
			dw	!of__xt				;   OF
			dw	lbl4-lbl3			;
lbl3:				dw	!dolit__xt		;     10
				dw	10			;
			dw	!ahead__xt			;   ENDOF
			dw	lbl11-lbl4			;
lbl4:			dw	!dolit__xt			;     '%
			dw	$25				;     \ The value of the '%' character
			dw	!of__xt				;   OF
			dw	lbl6-lbl5			;
lbl5:				dw	!dolit2_xt		;     2
			dw	!ahead__xt			;   ENDOF
			dw	lbl11-lbl6			;
lbl6:			dw	!dolit__xt			;     ''
			dw	$27				;     \ The value of the '''' character
			dw	!of__xt				;   OF
			dw	lbl10-lbl7			;
lbl7:				dw	!dolit3_xt		;     3
				dw	!less_than_xt		;     <
				dw	!if__xt			;     IF
				dw	lbl9-lbl8		;
lbl8:					dw	!c_fetch_xt	;       C@
					dw	!s_to_d_xt	;       S>D
					dw	!true_xt	;       TRUE
					dw	!doexit__xt	;       EXIT THEN
lbl9:				dw	!drop_xt		;     DROP
				dw	!false_xt		;     FALSE
				dw	!doexit__xt		;     EXIT
			dw	!ahead__xt			;   ENDOF
			dw	lbl11-lbl10			;
lbl10:				dw	!to_r_xt		;     >R
				dw	!dolitm1_xt		;     -1
				dw	!slash_str_xt		;     /STRING  \ Backup one char
				dw	!base_xt		;     BASE
				dw	!fetch_xt		;     @        \ Current BASE
				dw	!r_from_xt		;     R>
		dw	!drop_xt				;   ENDCASE    \ DROP of the default case
lbl11:		dw	!base_xt				;   BASE
		dw	!fetch_xt				;   @
		dw	!to_r_xt				;   >R         \ Save current BASE
		dw	!base_xt				;   BASE
		dw	!store_xt				;   !          \ Set new BASE
		dw	!next_char_xt				;   NEXT-CHAR
		dw	!dolit__xt				;   '-
		dw	$2d					;   \ The value of '-'
		dw	!equals_xt				;   =
		dw	!dup_to_r_xt				;   DUP>R      \ Negative sign flag
		dw	!invert_xt				;   INVERT     \ Gives 0 (got a '-') or -1 (not a '-')
		dw	!slash_str_xt				;   /STRING    \ Backup or not
		dw	!dolit0_xt				;   0.
		dw	!dolit0_xt				;
		dw	!two_swap_xt				;   2SWAP
		dw	!to_number_xt				;   >NUMBER
		dw	!dup_xt					;   DUP
		dw	!if__xt					;   IF
		dw	lbl13-lbl12				;
lbl12:			dw	!single_xt			;     SINGLE
			dw	!off_xt				;     OFF     \ Double cell
			dw	!next_char_xt			;     NEXT-CHAR
			dw	!dolit__xt			;     '.
			dw	$2e				;
			dw	!not_equals_xt			;     <>
			dw	!slash_str_xt			;     /STRING \ Backup or not
			dw	!to_number_xt			;     >NUMBER THEN \ Parse number after . or retry if not .
lbl13:		dw	!nip_xt					;   NIP       \ Remove c-addr
		dw	!if__xt					;   IF
		dw	lbl15-lbl14				;
lbl14:			dw	!r_from_drop_xt			;     R>DROP  \ Drop sign flag
			dw	!r_from_xt			;     R>
			dw	!base_xt			;     BASE
			dw	!store_xt			;     !       \ Restore BASE
			dw	!two_drop_xt			;     2DROP   \ Drop ud
			dw	!false_xt			;     FALSE
			dw	!doexit__xt			;     EXIT THEN
lbl15:		dw	!r_from_xt				;   R>        \ Negative sign flag
		dw	!if__xt					;   IF
		dw	lbl17-lbl16				;
lbl16:			dw	!d_negate_xt			;     DNEGATE THEN
lbl17:		dw	!r_from_xt				;   R>
		dw	!base_xt				;   BASE
		dw	!store_xt				;   !         \ Restore BASE
		dw	!true_xt				;   TRUE
		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
;
;		INPUT
;
;-------------------------------------------------------------------------------
accept:		dw	to_double
		db	$06
		db	'ACCEPT'
accept_xt:	local
		jp	!docol__xt		; : ACCEPT ( c-addr +n -- +n )
		dw	!dolit0_xt		;   0    \ END length of the string to edit in the buffer
		dw	!dolit0_xt		;   0    \ CURRENT position of the cursor in the buffer
		dw	!dolit0_xt		;   0    \ LBOUND leftmost position of the cursor permitted
		dw	!edit_xt		;   EDIT
		dw	!nip_xt			;   NIP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
file_refill:	dw	accept
		db	$0b
		db	'FILE-REFILL'
file_refill_xt:	local
		jp	!docol__xt		; : FILE-REFILL ( -- flag )
		dw	!fib_xt			;   FIB
		dw	!dolit__xt		;   #ib_size
		dw	!ib_size		;
		dw	!source_id_xt		;   SOURCE-ID
		dw	!read_line_xt		;   READ-LINE
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!two_drop_xt	;     2DROP
			dw	!false_xt	;     FALSE
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!fib_xt			;   FIB
		dw	!rot_xt			;   ROT
		;dw	!source__xt		;   (SOURCE)
		;dw	!two_store_xt		;   2!
		dw	!do2to__xt		;   TO SOURCE
		dw	!source_xt+3		;
		dw	!to_in_xt		;   >IN
		dw	!off_xt			;   OFF
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
user_refill:	dw	file_refill
		db	$0b
		db	'USER-REFILL'
user_refill_xt:	local
		jp	!docol__xt		; : USER-REFILL ( -- flag )
		dw	!busy_off_xt		;   BUSY-OFF
		dw	!tib_xt			;   TIB
		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   #ib_size
		dw	!ib_size		;
		dw	!stdi_xt		;   STDI
		dw	!peek_char_xt		;   PEEK-CHAR
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!two_drop_xt	;     2DROP
			dw	!busy_on_xt	;     BUSY-ON
			dw	!false_xt	;     FALSE
			dw	!to_in_xt	;     >IN
			dw	!off_xt		;     OFF
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!dolit__xt		;   CASE
		dw	$001c			;     $1c \ Right arrow
		;dw	!over_xt		;
		;dw	!equals_xt		;
		;dw	!if__xt			;
		dw	!of__xt			;   OF
		dw	lbl4-lbl3		;
lbl3:			;dw	!drop_xt	;
			dw	!stdi_xt	;     STDI
			dw	!read_char_xt	;     READ-CHAR
			dw	!two_drop_xt	;     2DROP
			;dw	!source__xt	;     (SOURCE)
			;dw	!two_fetch_xt	;     2@
			dw	!source_xt	;     SOURCE
			dw	!nip_xt		;     NIP
			dw	!dolit0_xt	;     0
			dw	!ahead__xt	;   ENDOF
			dw	lbl7-lbl4	;
lbl4:		dw	!dolit__xt		;     $1d
		dw	$001d			;     \ Left arrow
		;dw	!over_xt		;
		;dw	!equals_xt		;
		;dw	!if__xt			;
		dw	!of__xt			;   OF
		dw	lbl6-lbl5		;
lbl5:			;dw	!drop_xt	;
			dw	!stdi_xt	;     STDI
			dw	!read_char_xt	;     READ-CHAR
			dw	!two_drop_xt	;     2DROP
			;dw	!source__xt	;     (SOURCE)
			;dw	!two_fetch_xt	;     2@
			dw	!source_xt	;     SOURCE
			dw	!nip_xt		;     NIP
			dw	!dup_xt		;     DUP
			dw	!ahead__xt	;   ENDOF
			dw	lbl7-lbl6	;
lbl6:		dw	!drop_xt		;     DROP
		dw	!dolit0_xt		;     0
		dw	!dolit0_xt		;     0 ENDCASE
;lbl6:		dw	!dolit0_xt
;		dw	!dup_xt
;		dw	!rot_xt
;		dw	!drop_xt
lbl7:		dw	!dolit0_xt		;   0    \ LBOUND
		dw	!edit_xt		;   EDIT
		dw	!nip_xt			;   NIP
		;dw	!source__xt		;   (SOURCE)
		;dw	!two_store_xt		;   2!
		dw	!do2to__xt		;   TO SOURCE
		dw	!source_xt+3		;
		dw	!busy_on_xt		;   BUSY-ON
		dw	!to_in_xt		;   >IN
		dw	!off_xt			;   OFF
		dw	!true_xt		;   TRUE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
refill:		dw	user_refill
		db	$06
		db	'REFILL'
refill_xt:	local
		jp	!docol__xt		; : REFILL ( -- flag )
		dw	!source_id_xt		;   SOURCE-ID
		dw	!dolitm1_xt		;   -1
		dw	!equals_xt		;   =
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!false_xt	;     FALSE
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!source_id_xt		;   SOURCE-ID
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!file_refill_xt	;     FILE-REFILL
			dw	!doexit__xt	;     EXIT THEN
lbl4:		dw	!user_refill_xt		;   USER-REFILL
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
;		COMMENTS AND CONDITIONAL COMPILATION
;
;-------------------------------------------------------------------------------
paren:		dw	refill
		db	$81
		db	'('
paren_xt:	local
		jp	!docol__xt				; : ( ( "ccc<paren>" -- )
lbl1:			dw	!dolit__xt			;   BEGIN
			dw	$29				;     ') \ The value of the ')' character
			dw	!parse_xt			;     PARSE
			dw	!plus_xt			;     +
			dw	!dup_xt				;     DUP
			dw	!source_xt			;     SOURCE
			dw	!plus_xt			;     +
			dw	!equals_xt			;     =
			dw	!if__xt				;     IF
			dw	lbl3-lbl2			;
lbl2:				dw	!drop_xt		;       DROP
				dw	!refill_xt		;       REFILL
			dw	!ahead__xt			;     ELSE
			dw	lbl6-lbl3			;
lbl3:				dw	!c_fetch_xt		;       C@
				dw	!dolit__xt		;       ')
				dw	$29			;       \ The value of the ')' character
				dw	!not_equals_xt		;       <>
				dw	!if__xt			;       IF
				dw	lbl5-lbl4		;
lbl4:					dw	!refill_xt	;         REFILL
				dw	!ahead__xt		;       ELSE
				dw	lbl6-lbl5		;
lbl5:					dw	!false_xt	;         FALSE THEN THEN
lbl6:			dw	!zero_equals_xt			;     0=
			dw	!until__xt			;   UNTIL
			dw	lbl7-lbl1			;
lbl7:		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
back_slash:	dw	paren
		db	$81
		db	'\'
back_slash_xt:	local
		jp	!docol__xt		; : \ ( "ccc<eol>" -- )
		dw	!dolit__xt		;   10
		dw	$000a			;   \ The value of the LF character
		dw	!parse_xt		;   PARSE
		dw	!two_drop_xt		;   2DROP
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
dot_paren:	dw	back_slash
		db	$82
		db	'.('
dot_paren_xt:	local
		jp	!docol__xt		; : .( "ccc<paren>" -- )
		dw	!dolit__xt		;   ')
		dw	$29			;   \ The value of the ')' character
		dw	!parse_xt		;   PARSE
		dw	!cr_xt			;   CR
		dw	!type_xt		;   TYPE
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
brkt_def:	dw	dot_paren
		db	$89
		db	'[DEFINED]'
brkt_def_xt:	local
		jp	!docol__xt		; : [DEFINED] ( "<spaces>name ..." -- flag )
		dw	!blnk_xt		;   BL
		dw	!parse_word_xt		;   PARSE-WORD
		dw	!find_word_xt		;   FIND-WORD
		dw	!nip_xt			;   NIP
		dw	!zer_not_equ_xt		;   0<>
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
brkt_undef:	dw	brkt_def
		db	$8b
		db	'[UNDEFINED]'
brkt_undef_xt:	local
		jp	!docol__xt		; : [UNDEFINED] ( "<spaces>name ..." -- flag )
		dw	!brkt_def_xt		;   [DEFINED]
		dw	!invert_xt		;   INVERT
		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
brkt_else:	dw	brkt_undef
		db	$86
		db	'[ELSE]'
brkt_else_xt:	local
		jp	!docol__xt
		dw	!dolit1_xt
lbl1:				dw	!blnk_xt
				dw	!parse_word_xt
				dw	!dup_xt
			dw	!if__xt
			dw	lbl13-lbl2
lbl2:				dw	!two_dup_xt
				dw	!doslit__xt
				dw	4
				db	'[IF]'
				dw	!compare_xt
				dw	!zero_equals_xt
				dw	!if__xt
				dw	lbl4-lbl3
lbl3:					dw	!two_drop_xt
					dw	!one_plus_xt
				dw	!ahead__xt
				dw	lbl10-lbl4
lbl4:					dw	!two_dup_xt
					dw	!doslit__xt
					dw	6
					db	'[ELSE]'
					dw	!compare_xt
					dw	!zero_equals_xt
					dw	!if__xt
					dw	lbl8-lbl5
lbl5:						dw	!two_drop_xt
						dw	!one_minus_xt
						dw	!dup_xt
						dw	!if__xt
						dw	lbl7-lbl6
lbl6:							dw	!one_plus_xt
lbl7:					dw	!ahead__xt
					dw	lbl10-lbl8
lbl8:						dw	!doslit__xt
						dw	6
						db	'[THEN]'
						dw	!compare_xt
						dw	!zero_equals_xt
						dw	!if__xt
						dw	lbl10-lbl9
lbl9:							dw	!one_minus_xt
lbl10:				dw	!quest_dup_xt
				dw	!zero_equals_xt
				dw	!if__xt
				dw	lbl12-lbl11
lbl11:					dw	!doexit__xt
lbl12:			dw	!again__xt
			dw	lbl13-lbl1
lbl13:			dw	!two_drop_xt
			dw	!refill_xt
			dw	!zero_equals_xt
		dw	!until__xt
		dw	lbl14-lbl1
lbl14:		dw	!drop_xt
		dw	!doret__xt
		endl
;-------------------------------------------------------------------------------
brkt_if:	dw	brkt_else
		db	$84
		db	'[IF]'
brkt_if_xt:	local
		jp	!docol__xt		; : [IF] ( flag -- )
		dw	!zero_equals_xt		;   0=
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!brkt_else_xt	;     POSTPONE [ELSE] THEN
lbl2:		dw	!doret__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
brkt_then:	dw	brkt_if
		db	$86
		db	'[THEN]'
brkt_then_xt:	local
		jp	!cont__			; Does nothing, IMMEDIATE
		endl
;-------------------------------------------------------------------------------
;
;		EVALUATION
;
;-------------------------------------------------------------------------------
quest_stack:	dw	brkt_then
		db	$06
		db	'?STACK'		; ( -- )
quest_stack_xt:	local			; cycles = 19 (+ 22 interp__ = 41)
		mv	i,ba		; 2	; Save the TOS to I
		mv	ba,u		; 2	; BA is the low order 16 bit SP
		dec	ba		; 3	; Adjust down to allow empty stack check to pass
		ex	a,b		; 3	; A is the middle byte of SP
		cmp	a,!s_limit/256	; 3	; Compare SP middle byte to s_limit middle byte ($fa)
		mv	ba,i		; 2	; Restore the TOS from I
		jpz	!interp__	; 3/4	; No stack overflow or underflow
		mv	il,-3			; Stack overflow
		jrc	lbl1
		mv	il,-4			; Stack underflow
lbl1:		jp	!throw__
;		jp	!docol__xt		; : ?STACK ( -- )
;		dw	!depth_xt		;   DEPTH
;		dw	!dup_xt			;   DUP
;		dw	!zer_lss_thn_xt		;   0<
;		dw	!if__xt			;   IF
;		dw	lbl2-lbl1		;
;lbl1:			dw	!dolit__xt	;     -4
;			dw	-4		;     \ Stack underflow
;			dw	!throw_xt	;     THROW THEN
;lbl2:		dw	!dolit__xt		;   #s_size/2
;		dw	!s_size/2		;   \ One cell = 16 bits
;		dw	!greatr_than_xt		;   > \ Signed integer comparison
;		dw	!if__xt			;   IF
;		dw	lbl4-lbl3		;
;lbl3:			dw	!dolit__xt	;     -3
;			dw	-3		;     \ Stack overflow
;			dw	!throw_xt	;     THROW
;lbl4:		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
number:		dw	quest_stack
		db	$06
		db	'NUMBER'
number_xt:	local
		jp	!docol__xt				; : NUMBER ( c-addr u -- n|u|d|ud | F: -- r )
		;dw	!two_dup_xt				;   2DUP \ FIXME
		dw	!to_double_xt				;   >DOUBLE
		dw	!if__xt					;   IF
		dw	lbl8-lbl1				;
lbl1:			;dw	!two_nip_xt			;     2NIP \ FIXME
			dw	!single_xt			;     SINGLE
			dw	!fetch_xt			;     @
			dw	!if__xt				;     IF
			dw	lbl3-lbl2			;
lbl2:				dw	!d_to_s_xt		;       D>S THEN
lbl3:			dw	!state_xt			;     STATE
			dw	!fetch_xt			;     @
			dw	!if__xt				;     IF
			dw	lbl7-lbl4			;
lbl4:				dw	!single_xt		;       SINGLE
				dw	!fetch_xt		;       @
				dw	!if__xt			;       IF
				dw	lbl6-lbl5		;
lbl5:					dw	!dolit__xt	;         LITERAL
					dw	!dolit__xt	;
					dw	!compile_com_xt	;
					dw	!comma_xt	;
					dw	!doexit__xt	;         EXIT THEN
lbl6:				dw	!dolit__xt		;       2LITERAL
				dw	!do2lit__xt		;
				dw	!compile_com_xt		;
				dw	!two_comma_xt		;       THEN
lbl7:			dw	!doexit__xt			;     EXIT THEN
lbl8:		;dw	!to_float_xt				;   >FLOAT \ FIXME
		;dw	!if__xt					;   IF
		;dw	lbl10-lbl9				;
lbl9:		;	dw	!doexit__xt			;     EXIT THEN
lbl10:		dw	!dolit__xt				;   -13
		dw	-13					;
		dw	!throw_xt				;   THROW THEN
		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
interpret:	dw	number
		db	$09
		db	'INTERPRET'
interpret_xt:	local
		jp	!docol__xt				; : INTERPRET ( -- )
lbl1:			dw	!blnk_xt			;   BEGIN BL
			dw	!parse_word_xt			;     PARSE-WORD
			dw	!quest_dup_xt			;     ?DUP
		dw	!if__xt					;   WHILE
		dw	lbl9-lbl2				;
lbl2:			dw	!two_dup_xt			;     2DUP
			dw	!find_word_xt			;     FIND-WORD
			dw	!quest_dup_xt			;     ?DUP
			dw	!if__xt				;     IF
			dw	lbl7-lbl3			;
lbl3:				dw	!two_nip_xt		;       2NIP
				dw	!state_xt		;       STATE
				dw	!fetch_xt		;       @
				dw	!equals_xt		;       =
				dw	!if__xt			;       IF
				dw	lbl5-lbl4		;
lbl4:					dw	!compile_com_xt	;         COMPILE,
				dw	!ahead__xt		;       ELSE
				dw	lbl6-lbl5		;
lbl5:					dw	!execute_xt	;         EXECUTE THEN
lbl6:			dw	!ahead__xt			;     ELSE
			dw	lbl8-lbl7			;
lbl7:				dw	!drop_xt		;       DROP
				dw	!number_xt		;       NUMBER THEN
lbl8:			dw	!quest_stack_xt			;     ?STACK
		dw	!again__xt				;   REPEAT
		dw	lbl9-lbl1				;
lbl9:		dw	!drop_xt				;   DROP
		dw	!doret__xt				; ;
		endl
;-------------------------------------------------------------------------------
evaluate:	dw	interpret
		db	$08
		db	'EVALUATE'
evaluate_xt:	local
		jp	!docol__xt		; : EVALUATE ( ... c-addr u -- ... )
		dw	!save_input_xt		;   SAVE-INPUT
		dw	!n_to_r_xt		;   N>R
		dw	!do2to__xt		;   TO SOURCE
		dw	!source_xt+3		;
		dw	!to_in_xt		;   >IN
		dw	!off_xt			;   OFF
		dw	!dolitm1_xt		;   -1
		dw	!doto__xt		;   TO SOURCE-ID
		dw	!source_id_xt+3		;
		dw	!interpret_xt		;   INTERPET
		dw	!n_r_from_xt		;   NR>
		dw	!restr_input_xt		;   RESTORE-INPUT
		dw	!drop_xt		;   DROP
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
include_fil:	dw	evaluate
		db	$0c
		db	'INCLUDE-FILE'
include_fil_xt:	local
		jp	!docol__xt			; : INCLUDE-FILE ( i*x fileid -- j*x )
		dw	!save_input_xt			;   SAVE-INPUT
		dw	!n_to_r_xt			;   N>R
		dw	!doto__xt			;   TO SOURCE-ID \ Set SOURCE-ID to fileid
		dw	!source_id_xt+3			;
lbl1:			dw	!refill_xt		;   BEGIN REFILL
			dw	!if__xt			;   WHILE
			dw	lbl3-lbl2		;
lbl2:				dw	!interpret_xt	;     INTERPRET
				dw	!again__xt	;   REPEAT
				dw	lbl3-lbl1	;
lbl3:		dw	!source_id_xt			;   SOURCE-ID
		dw	!close_file_xt			;   CLOSE-FILE
		dw	!n_r_from_xt			;   NR>
		dw	!restr_input_xt			;   RESTORE-INPUT
		dw	!two_drop_xt			;   2DROP
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
included:	dw	include_fil
		db	$08
		db	'INCLUDED'
included_xt:	local
		jp	!docol__xt		; : INCLUDED ( i*x c-addr u -- j*x )
		dw	!r_o_xt			;   R/O
		dw	!open_file_xt		;   OPEN-FILE
		dw	!throw_xt		;   THROW
		dw	!include_fil_xt		;   INCLUDE-FILE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
include:	dw	included
		db	$07
		db	'INCLUDE'
include_xt:	local
		jp	!docol__xt		; : INCLUDE ( i*x "name" -- j*x )
		dw	!parse_name_xt		;   PARSE-NAME
		dw	!included_xt		;   INCLUDED
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
required:	dw	include
		db	$08
		db	'REQUIRED'
required_xt:	local
		jp	!docol__xt		; : REQUIRED ( i*x c-addr u -- j*x )
		dw	!which_pockt_xt		;   WHICH-POCKET
		dw	!dup_to_r_xt		;   DUP>R
		dw	!swap_xt		;   SWAP
		dw	!dup_to_r_xt		;   DUP>R
		dw	!c_move_xt		;   CMOVE
		dw	!blnk_xt		;   BL
		dw	!two_r_fetch_xt		;   2R@
		dw	!plus_xt		;   +
		dw	!c_store_xt		;   C!
		dw	!two_r_fetch_xt		;   2R@
		dw	!one_plus_xt		;   1+
		dw	!find_word_xt		;   FIND-WORD
		dw	!nip_xt			;   NIP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!r_from_drop_xt	;     R>DROP
			dw	!r_from_drop_xt	;     R>DROP
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!two_r_fetch_xt		;   2R@
		dw	!included_xt		;   INCLUDED
		dw	!two_r_from_xt		;   2R>
		dw	!one_plus_xt		;   1+
		dw	!created__xt		;   (CREATED)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
require:	dw	required
		db	$07
		db	'REQUIRE'
require_xt:	local
		jp	!docol__xt		; : REQUIRE ( i*x "name" -- j*x )
		dw	!parse_name_xt		;   PARSE-NAME
		dw	!required_xt		;   REQUIRED
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
envnmt_qry:	dw	require
		db	$0c
		db	'ENVIRONMENT?'
envnmt_qry_xt:	local
		jp	!docol__xt
		dw	!two_dup_xt
		dw	!doslit__xt
		dw	15
		db	'/COUNTED-STRING'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	255
			dw	!true_xt
			dw	!doexit__xt
lbl2:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	5
		db	'/HOLD'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	!hold_size
			dw	!true_xt
			dw	!doexit__xt
lbl4:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	4
		db	'/PAD'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl6-lbl5
lbl5:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	!ib_size
			dw	!true_xt
			dw	!doexit__xt
lbl6:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	17
		db	'ADDRESS-UNIT-BITS'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl12-lbl7
lbl7:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	16
			dw	!true_xt
			dw	!doexit__xt
;lbl8:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	4
;		db	'CORE'			; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl10-lbl9
;lbl9:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;lbl10:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	8
;		db	'CORE-EXT'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl12-lbl11
;lbl11:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
lbl12:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	7
		db	'FLOORED'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl14-lbl13
lbl13:			dw	!two_drop_xt
			dw	!false_xt
			dw	!true_xt
			dw	!doexit__xt
lbl14:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	8
		db	'MAX-CHAR'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl16-lbl15
lbl15:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	255
			dw	!true_xt
			dw	!doexit__xt
lbl16:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	5
		db	'MAX-D'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl18-lbl17
lbl17:			dw	!two_drop_xt
			dw	!do2lit__xt
			dw	$ffff
			dw	$7fff
			dw	!true_xt
			dw	!doexit__xt
lbl18:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	5
		db	'MAX-N'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl20-lbl19
lbl19:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	$7fff
			dw	!true_xt
			dw	!doexit__xt
lbl20:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	5
		db	'MAX-U'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl22-lbl21
lbl21:			dw	!two_drop_xt
			dw	!dolitm1_xt
			dw	!true_xt
			dw	!doexit__xt
lbl22:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	6
		db	'MAX-UD'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl24-lbl23
lbl23:			dw	!two_drop_xt
			dw	!do2lit__xt
			dw	$ffff
			dw	$ffff
			dw	!true_xt
			dw	!doexit__xt
lbl24:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	18
		db	'RETURN-STACK-CELLS'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl26-lbl25
lbl25:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	!r_size/2
			dw	!true_xt
			dw	!doexit__xt
lbl26:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	11
		db	'STACK-CELLS'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl40-lbl27
lbl27:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	!s_size/2
			dw	!true_xt
			dw	!doexit__xt
;lbl28:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	14
;		db	'FLOATING-STACK'
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl30-lbl29
;lbl29:			dw	!two_drop_xt
;			dw	!dolit__xt
;			dw	!f_size
;			dw	!true_xt
;			dw	!doexit__xt
;lbl30:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	9
;		db	'MAX-FLOAT'
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl40-lbl31
;lbl31:			dw	!two_drop_xt
;			dw	!doflit__xt
;			db	0, 99, $99, $99, $99, $99, $99, $99, $99, $99, $99, $99
;			dw	!true_xt
;			dw	!doexit__xt
;--------------------------------------------------------------------------------
;lbl28:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	6
;		db	'DOUBLE'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl30-lbl29
;lbl29:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;lbl30:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	10
;		db	'DOUBLE-EXT'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl32-lbl31
;lbl31:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;lbl32:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	9
;		db	'EXCEPTION'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl34-lbl33
;lbl33:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;lbl34:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	13
;		db	'EXCEPTION-EXT'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl36-lbl35
;lbl35:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;lbl36:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	8
;		db	'FACILITY'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl38-lbl37
;lbl37:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;lbl38:		dw	!two_dup_xt
;		dw	!doslit__xt
;		dw	6
;		db	'STRING'		; Obsolescent environmental query
;		dw	!s_equals_xt
;		dw	!if__xt
;		dw	lbl40-lbl39
;lbl39:			dw	!two_drop_xt
;			dw	!true_xt
;			dw	!true_xt
;			dw	!doexit__xt
;--------------------------------------------------------------------------------
lbl40:		dw	!two_drop_xt
		dw	!false_xt
		dw	!doret__xt
		endl
;-------------------------------------------------------------------------------
bye_:		dw	envnmt_qry
		db	$05
		db	'(BYE)'
bye__xt:	local
		pre_on
		mv	x,!symbols		; X holds the address where the pattern is stored
		mv	(!bl),0
lbl1:		mvw	(!cx),$0000		; LCD driver
		mv	il,$46			; 'Symbol display'
		mv	a,[x++]			; Read symbol pattern
		callf	!iocs
		inc	(!bl)
		cmp	(!bl),4			; Test whether all the symbols have been displayed or not
		jrc	lbl1
		pre_off
		mv	x,!here_value
		mvp	[x++],(!wi)		; Save HERE value
		mv	ba,[!last_xt+3]
		mv	[x++],ba		; Save LAST value
		mv	ba,[!lastxt_xt+3]
		mv	[x++],ba		; Save LAST-XT value
		pre_on
		and	($fb),$7f		; Disable interruptions
		mv	x,!bp_value
		mv	($ec),[x++]		; Restore BP's value
		mv	u,[x++]			; Restore U's value
		mv	y,[x++]			; Restore S's value
		mv	s,y
		or	($fb),$80		; Enable interruptions
		pre_off
		rc				; Return
		retf				; to BASIC
		endl
;-------------------------------------------------------------------------------
bye:		dw	bye_
		db	$03
		db	'BYE'
bye_xt:		local
		jp	!docol__xt		; : BYE ( -- )
		dw	!key_clear_xt		;   KEY-CLEAR
		dw	!page_xt		;   PAGE
		dw	!bye__xt		;   (BYE)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
error_:		dw	bye
		db	$07
		db	'(ERROR)'
error__xt:	local
		jp	!docol__xt		; : (ERROR) ( ior -- )
		dw	!dup_xt			;   DUP
		dw	!dolitm1_xt 		;   -1 \ ABORT case
		dw	!equals_xt		;   =
		dw	!over_xt		;   OVER
		dw	!dolit__xt		;   -2
		dw	-2			;   \ ABORT" case
		dw	!equals_xt		;   =
		dw	!or_xt			;   OR
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!clear_xt	;     CLEAR
			dw	!doexit__xt	;     EXIT THEN
lbl2:		dw	!dup_xt			;   DUP
		dw	!dolit__xt		;   -56
		dw	-56			;   \ QUIT case
		dw	!equals_xt		;   =
		dw	!if__xt			;   IF
		dw	lbl4-lbl3		;
lbl3:			dw	!drop_xt	;     DROP
			dw	!doexit__xt	;     EXIT THEN
lbl4:		dw	!cr_xt			;   CR
		dw	!source_xt		;   SOURCE
		dw	!to_in_xt		;   >IN
		dw	!fetch_xt		;   @
		dw	!u_min_xt		;   UMIN
		dw	!type_xt		;   TYPE
		dw	!doslit__xt		;   S" <=ERR#"
		dw	6			;
		db	'<=ERR#'		;
		dw	!type_xt		;   TYPE
		dw	!s_to_d_xt		;   S>D
		dw	!d_dot__xt		;   (D.)
		dw	!type_xt		;   TYPE
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
;refill_:	dw	error_
;		db	$08
;		db	'(REFILL)'
;refill__xt:	local
;		jp	!docol__xt		; : (REFILL) ( -- flag )
;lbl1:			dw	!dolit__xt	;   BEGIN ['] REFILL
;			dw	!refill_xt	;
;			dw	!catch_xt	;     CATCH
;		dw	!if__xt			;   WHILE
;		dw	lbl3-lbl2		;
;lbl2:			dw	!page_xt	;     PAGE
;			dw	!dolit0_xt	;     0
;			dw	!source__xt	;     (SOURCE)
;			dw	!store_xt	;     !
;		dw	!again__xt		;   REPEAT
;		dw	lbl3-lbl1		;
;lbl3:		dw	!doret__xt		; ;
;		endl
;-------------------------------------------------------------------------------
quit_:		dw	error_
		db	$06
		db	'(QUIT)'
quit__xt:	local
		jp	!docol__xt			; : (QUIT) ( -- )
		dw	!handler_xt			;   HANDLER
		dw	!off_xt				;   OFF \ No error handler
		dw	!dolit__xt			;   #r_beginning
		dw	!r_beginning			;
		dw	!rp_store_xt			;   RP!
		dw	!source_id_xt			;   SOURCE-ID
		dw	!zer_grt_thn_xt			;   0>
		dw	!if__xt				;   IF
		dw	lbl2-lbl1			;
lbl1:			dw	!source_id_xt		;     SOURCE-ID
			dw	!close_file_xt		;     CLOSE-FILE
			dw	!drop_xt		;     DROP THEN
lbl2:		dw	!dolit0_xt			;   0
		dw	!doto__xt			;   TO SOURCE-ID
		dw	!source_id_xt+3			;
		dw	!stdo_xt			;   STDO
		dw	!doto__xt			;   TO TTY
		dw	!tty_xt+3			;
		dw	!key_clear_xt			;   KEY-CLEAR
		;dw	!dolit__xt			;   $28
		;dw	$28				;
		;dw	!cursor_xt			;   CURSOR
		;dw	!store_xt			;   !
		dw	!dolit__xt			;   $2a \ blinking block cursor
		dw	$2a				;
		dw	!set_cursor_xt			;   SET-CURSOR \ enable cursor
		dw	!cr_xt				;   CR
		dw	!dolit__xt			;   13
		dw	13				;
		dw	!emit_xt			;   EMIT \ scroll if needed to show new line
		dw	!left_brkt_xt			;   POSTPONE [
lbl3:				dw	!dolit__xt	;   BEGIN BEGIN
				dw	!refill_xt	;        ['] REFILL
				dw	!catch_xt	;        CATCH
			dw	!if__xt			;      WHILE
			dw	lbl5-lbl4		;
lbl4:				dw	!page_xt	;        PAGE
				dw	!source_xt	;        SOURCE
				dw	!drop_xt	;        DROP
				dw	!dolit0_xt	;        0
				dw	!do2to__xt	;        TO SOURCE
				dw	!source_xt+3	;
			dw	!again__xt		;      REPEAT
			dw	lbl5-lbl3		;
lbl5:		dw	!if__xt				;   WHILE
		dw	lbl11-lbl6			;
lbl6:			dw	!space_xt		;     SPACE
			dw	!dolit__xt		;     ['] INTERPRET
			dw	!interpret_xt		;
			dw	!catch_xt		;     CATCH
			dw	!quest_dup_xt		;     ?DUP
			dw	!if__xt			;     IF
			dw	lbl8-lbl7		;
lbl7:				dw	!error__xt	;       (ERROR)
				dw	!quit__xt	;       (QUIT)
lbl8:			dw	!state_xt		;     STATE
			dw	!fetch_xt		;     @
			dw	!invert_xt		;     INVERT
			dw	!if__xt			;     IF
			dw	lbl10-lbl9		;
lbl9:				dw	!doslit__xt	;       S" OK["
				dw	4		;
				db	' OK['		;
				dw	!type_xt	;       TYPE
				dw	!depth_xt	;       DEPTH
				dw	!s_to_d_xt	;       S>D
				dw	!d_dot__xt	;       (D.)
				dw	!type_xt	;       TYPE
				dw	!dolit__xt	;       ']
				dw	$5d		;       \ The ']' character
				dw	!emit_xt	;       EMIT THEN
lbl10:			dw	!cr_xt			;     CR
		dw	!again__xt			;   REPEAT
		dw	lbl11-lbl3			;
lbl11:		dw	!bye_xt				;   BYE
		dw	!doret__xt			; ;
		endl
;-------------------------------------------------------------------------------
quit:		dw	quit_
		db	$04
		db	'QUIT'
quit_xt:	local
		jp	!docol__xt		; : QUIT ( -- ; R: i*x -- )
		dw	!dolit__xt		;   -56
		dw	-56			;   \ QUIT
		dw	!throw_xt		;   THROW
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
startup:	dw	quit
		db	$07
		db	'STARTUP'
startup_xt:	local
		jp	!docol__xt		; : STARTUP
		dw	!dolit0_xt		;   0
		dw	!dolit3_xt		;   3
		dw	!set_symbols_xt		;   SET-SYMBOLS
		dw	!page_xt		;   PAGE
		dw	!doslit__xt		;   S" ** Welcome to Forth! "
		dw	21			;
		db	'** Welcome to Forth! '	;
		dw	!type_xt		;   TYPE
		dw	!unused_xt		;   UNUSED
		dw	!u_dot_xt		;   U.
		dw	!doslit__xt		;   S" bytes free **"
		dw	13			;
		db	'bytes free **'		;
		dw	!type_xt		;   TYPE
		dw	!cr_xt			;   CR
		dw	!doslit__xt		;   S" Type `BYE' to exit"
		dw	18			;
		db	'Type `BYE'' to exit'	;
		dw	!type_xt		;   TYPE
		dw	!clear_xt		;   CLEAR
		dw	!quit__xt		;   (QUIT)
		dw	!doret__xt		; ;
		endl
;-------------------------------------------------------------------------------
_end_:		end

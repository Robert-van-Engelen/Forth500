;
;
;


; Implementation logic registers (BP-relative addresses)
; 16 bit (8+8) registers
el:		equ	$00
eh:		equ	$01
ex:		equ	$00
fl:		equ	$02
fh:		equ	$03
fx:		equ	$02
gl:		equ	$04
gh:		equ	$05
gx:		equ	$04
hl:		equ	$06
hh:		equ	$07
hx:		equ	$06
il:		equ	$08
ih:		equ	$09
ix:		equ	$08
jl:		equ	$0a
jh:		equ	$0b
jx:		equ	$0a
kl:		equ	$0c
kh:		equ	$0d
kx:		equ	$0c
ll:		equ	$0e			; Floating point stack's depth
lh:		equ	$0f			; Free heap pointers stack's remaining places
lx:		equ	$0e
; 20 bit registers
wi:		equ	$10			; Here pointer
xi:		equ	$13			; FP (Floating point stack pointer)
yi:		equ	$16			; Free heap pointers stack pointer value
zi:		equ	$19			; Heap address


; Standard logic registers
;
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
;
fcs:		equ	$fffe4
iocs:		equ	$fffe8
;
ib_size:	equ	256
blk_buff_size:	equ	1024
heap_size:	equ	32
r_size:		equ	400
s_size:		equ	400
r_beginning:	equ	$bfc00			; The return stack's beginning
r_limit:	equ	r_beginning-r_size	; The return stack's low limit
s_beginning:	equ	r_limit			; The stack's beginning
s_limit:	equ	s_beginning-s_size	; The stack's low limit
f_beginning:	equ	s_limit			; The floating-point stack's beginning
f_limit:	equ	f_beginning-3*heap_size	; The floating-point stack's low limit (100 pointers)
a_beginning:	equ	f_limit			; The free heap pointers stack's beginning
a_limit:	equ	a_beginning-3*heap_size	; The free heap pointers stack's low limit
heap_addr:	equ	a_limit-16*heap_size	; The address of the floating-point heap
dict_limit:	equ	heap_addr		; The upper limit of the dictionary space
;
;Other constants
bp0:		equ	$70
base_address:	equ	$b0000			; 11th segment
;
		org	base_address		; $b0000 is the best choice, but some machines does not have enough memory
boot:		local				; ($b9000 is the value to choose when running on a 32 kB machine).
		pre_on
		and	($fb),$7f		; Disable interruptions
		mv	[!bp_value],($ec)	; Save BP's current value
		mv	[!u_value],u		; Save U's current value
		mv	[!s_value],s		; Save S's current value
		mv	($ec),!bp0		; Set BP to its new value
		mv	u,!s_beginning		; Set U to its new value
		mv	s,!r_beginning		; Set S to its new value
		or	($fb),$80		; Enable interruptions
		pre_off
		mv	x,!symbols		; Save
		mv	y,$bfc97		; display's
		mv	ba,[y++]		; symbols
		mv	[x++],ba		; to restore them
		mv	ba,[y++]		; when returning to
		mv	[x++],ba		; BASIC
		mvp	(!wi),[x++]		; Set HERE value
;		mvp	(!xi),[x++]		; Set FP value
;		mvp	(!yi),[x++]		; Set free heap pointers stack pointer value
;		mvp	(!zi),!heap_addr	; Set heap address (constant)
;		mv	(!ll),[x++]		; Set floating point stack's depth
;		mv	(!lh),[x++]		; Set free heap pointers stack's remaining places
		mv	ba,[x++]
		mv	[!last_xt+3],ba		; Set LAST value
		mv	ba,[x++]
		mv	[!lastxt_xt+3],ba	; Set LAST-XT value
		mv	ba,$0000
		mv	[!handler_xt+3],ba	; No error handler (stopping Forth machine becomes impossible)
		mv	i,!startup_xt
		jp	!startup_xt
		endl
bp_value:	ds	1
u_value:	ds	3
s_value:	ds	3
symbols:	ds	4			; To restore display's symbols when returning to BASIC
here_value:	dp	_end_
;fp_value:	dp	f_beginning		; Floating-point stack pointer
;ap_value:	dp	a_beginning		; Free heap pointers stack pointer
;f_depth:	db	32			; The number of remaining places on the floating-point stack
;a_depth:	db	0			; The number of remaining free heap pointers (0 to force garbage collection)
last_value:	dw	startup
lastxt_value:	dw	startup_xt
;
docol_:		dw	$0000			; To mark the last definition
		db	$07
		db	'(DOCOL)'
docol__xt:	pushs	x			; Save old IP
		mv	x,!base_address+3	; Set new IP (I contains
		add	x,i			; the current execution token)
interp__:	pre_on
		test	($ff),$08		; Is break pushed?
		pre_off
		jrnz	_user_break
_continue:	mv	i,[x++]			; Set I to new execution token
		pushs	i			; Execute
		ret				; new token
_user_break:	pushu	i
		mv	i,[handler_xt+3]	; Y (unused register) holds the value of HANDLER
		inc	i			; Test whether there is
		dec	i			; a handler for this exception or not
		popu	i
		jrz	_continue		; No handler: ignore break and continue execution
break__:	local
		pre_on
lbl1:		mv	i,$100			; Test if the break
lbl2:		test	($ff),$08		; key was intentionally
		jrnz	lbl1			; released
		dec	i			; (break action is triggered
		jrnz	lbl2			; when the break key is released)
		pre_off
		endl
		rc
		mv	ba,-28			; User interrupt
		mv	i,!throw_xt		; Execution token of the next word to execute
		rc
		jp	!throw_xt
doexit_:	dw	docol_
		db	$06
		db	'(EXIT)'
doexit__xt:	local
		pops	x			; restore old IP
		jp	!interp__
		endl
does_:		dw	doexit_
		db	$07
		db	'(DOES>)'
does__xt:	local
		pushu	ba			; Save TOS
		mv	a,3			; Compute the
		add	i,a			; address of the data
		mv	ba,i			; Set new TOS
		pops	i			; Compute the address of the execution token
		pushs	x			; Save the return address
		mv	x,!base_address		; X holds
		add	x,i			; the address of the parameter field
		jp	!interp__
		endl
dolit_:		dw	does_
		db	$07
		db	'(DOLIT)'
dolit__xt:	local
		pushu	ba			; Save old TOS
		mv	ba,[x++]		; Set new TOS (next token)
		jp	!interp__
		endl
do2lit_:	dw	dolit_
		db	$08
		db	'(DO2LIT)'
do2lit__xt:	local
		pushu	ba			; Save old TOS
		mv	ba,[x++]		; Fetch the first 16 bits (next token)
		pushu	ba			; Push the first 16 bits one the stack
		mv	ba,[x++]		; Set new TOS (next token)
		jp	!interp__
		endl
doflit_:	dw	do2lit_
		db	$08
		db	'(DOFLIT)'
doflit__xt:	local
		pushu	ba			; Save TOS
		mv	y,(!xi)			; Y holds FP's value
		mv	a,[x]			; Test the length of the floating point
		test	a,$01			; number (single or double precision)
		jrz	lbl1			; zero=single precision
		mv	i,12			; The length of a double precision floating-point number
		jr	lbl2
lbl1:		mv	i,5			; Align FP
		sub	y,i			; on a double precision address
		mv	i,7			; The length of a single precision floating-point number
lbl2:		mv	a,[x++]			; Copy the floating-point number
		mv	[--y],a			; on the floting-point stack
		dec	i
		jrnz	lbl2
		mv	ba,$0000		; Store computation
		mv	[--y],ba		; correction
		mv	(!xi),y			; Update FP's value
		popu	ba			; Restore TOS
		jp	!interp__
		endl
doslit_:	dw	doflit_
		db	$08
		db	'(DOSLIT)'
doslit__xt:	local
		pushu	ba			; Save old TOS
		mv	ba,[x++]		; Read the length of the string
		mv	i,x			; Truncate the beginning address of the string
		pushu	i			; Save it on the stack
		add	x,ba			; Update IP (skip up to the end of the string)
		jp	!interp__
		endl
dovar_:		dw	doslit_
		db	$07
		db	'(DOVAR)'
dovar__xt:	local
		pushu	ba			; Save old TOS
		mv	a,3			; Set
		add	i,a			; new
		mv	ba,i			; TOS
		jp	!interp__
		endl
doto_:		dw	dovar_
		db	$04
		db	'(TO)'
doto__xt:	local
		mv	i,[x++]			; Read the short address of the value
		mv	y,!base_address		; Y holds the
		add	y,i			; address of the value
		mv	[y],ba			; Set new value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
doplusto_:	dw	doto_
		db	$05
		db	'(+TO)'
doplusto__xt:	local
		mv	i,[x++]			; Read the short address of the value
		mv	y,!base_address		; Y holds the
		add	y,i			; address of the value
		mv	i,[y]			; Read the old value
		add	ba,i			; Add it to the new one
		mv	[y],ba			; Set new value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
doval_:		dw	doplusto_
		db	$07
		db	'(DOVAL)'
doval__xt:	local
		pushu	ba			; Save old TOS
		mv	y,!base_address+3
		add	y,i
		mv	ba,[y]			; Set new TOS
		jp	!interp__
		endl
dodefer_:	dw	doval_
		db	$09
		db	'(DODEFER)'
dodefer__xt:	local
		mv	y,!base_address+3
		add	y,i
		mv	i,[y]			; Set current xt
		pushs	i
		ret				; Call defered word
		endl
dois_:		dw	dodefer_
		db	$04
		db	'(IS)'
dois__xt:	local
		mv	i,[x++]			; Read the short address of the defering word
		mv	y,!base_address		; Y holds the
		add	y,i			; address of the defering word
		mv	[y],ba			; Set new defered word
		popu	ba			; Set new TOS
		jp	!interp__
		endl
docon_:		dw	dois_
		db	$07
		db	'(DOCON)'
docon__xt:	local
		pushu	ba			; Save old TOS
		mv	y,!base_address+3
		add	y,i
		mv	ba,[y]			; Set new TOS
		jp	!interp__
		endl
do2con_:	dw	docon_
		db	$08
		db	'(DO2CON)'
do2con__xt:	local
		pushu	ba			; Save old TOS
		mv	y,!base_address+3
		add	y,i
		mv	ba,[y++]		; Read the first 16 bits
		pushu	ba			; Push the first 16 bits on the stack
		mv	ba,[y]			; Set new TOS
		jp	!interp__
		endl
sc_code_:	dw	do2con_
		db	$07
		db	'(;CODE)'
sc_code__xt:	local
		pushu	ba			; Save TOS
		mv	i,x			; I holds the address of the token after (;CODE)
		mv	ba,[!lastxt_xt+3]	; Store last xt pointer
		mv	x,!base_address		; X holds the address
		add	x,ba			; of the last xt (IP is lost)
		mv	[x+1],i			; Compile a 'jp' to the token after (;CODE)
		popu	ba			; Restore TOS
		pops	x			; restore old IP (perform a doexit_)
		jp	!interp__
		endl
ahead_:		dw	sc_code_
		db	$07
		db	'(AHEAD)'
ahead__xt:	local
		mv	i,[x++]			; Read the number of bytes to jump
		add	x,i			; Skip forward the specified number of bytes
		jp	!interp__
		endl
again_:		dw	ahead_
		db	$07
		db	'(AGAIN)'
again__xt:	local
		mv	i,[x++]			; Read the number of bytes to jump
		sub	x,i			; Skip backward the specified number of bytes
		jp	!interp__
		endl
if_:		dw	again_
		db	$04
		db	'(IF)'
if__xt:		local
		mv	i,[x++]			; Read the number of bytes to jump
		inc	ba			; Test the TOS
		dec	ba			;
		popu	ba			; Set new TOS
		jpnz	!interp__
		add	x,i			; Skip forward the specified number of bytes
		jp	!interp__
		endl
until_:		dw	if_
		db	$07
		db	'(UNTIL)'
until__xt:	local
		mv	i,[x++]			; Read the number of bytes to jump
		inc	ba			; Test the TOS
		dec	ba			;
		popu	ba			; Set new TOS
		jpnz	!interp__
		sub	x,i			; Skip backward the specified number of bytes
		jp	!interp__
		endl
do_:		dw	until_
		db	$04
		db	'(DO)'
do__xt:		local
		popu	i			; I holds the loop limit and BA the initial value
		pushu	ba			; Save the initial value on the parameter stack
		mv	ba,[x++]		; I holds the LEAVE address (to exit DO statement)
		pushs	ba			; Save the LEAVE address
		mv	ba,$8000		; Perform a 'slice'
		add	i,ba			; of the loop limit
		pushs	i			; Save the 'sliced' loop limit
		popu	ba			; Restore the initial value
		sub	ba,i			; Perform the 'slice' operation on the initial value
		pushs	ba			; Save the initial value
		popu	ba			; Set new TOS
		rc
		jp	!interp__
		endl
quest_do_:	dw	do_
		db	$05
		db	'(?DO)'
quest_do__xt:	local
		popu	i			; I holds the loop limit and BA the initial value
		pushu	ba			; Save the initial value
		sub	ba,i			; Test if these two values are equal
		mv	ba,[x++]		; I holds the short LEAVE address (to exit ?DO statement)
		jrz	lbl2
		pushs	ba			; Save the short LEAVE address
		mv	ba,$8000		; Perform a 'slice'
		add	i,ba			; on the loop limit
		pushs	i			; Save the 'sliced' loop limit
		popu	ba			; Restore the initial value
		sub	ba,i			; Perform the 'slice' operation on the initial value
		pushs	ba			; Save the initial value
		popu	ba			; Set new TOS
		jp	!interp__
lbl2:		mv	x,!base_address		; X holds the
		add	x,ba			; address of the end of the ?DO statement
		popu	i			; Discard the initial value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
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
		jp	!interp__
lbl1:		pops	i			; Discard the loop parameters
		pops	i			; (only the loop limit and LEAVE address are on the stack)
		popu	ba			; Restore the TOS
		rc
		jp	!interp__
		endl
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
		jrc	lbl1
		jr	lbl3
lbl1:		mv	ba,[x++]		; Read the number of bytes to jump
		sub	x,ba			; Jump backward to the beginning of the DO statement
		popu	ba			; Set new TOS
		jp	!interp__
lbl2:		add	ba,i			; Increment the loop counter
		pushs	ba			; Save its value on the stack
		add	ba,ba			; Test the sign of the result
		jrc	lbl1
		add	i,i			; Test the sign of the previous value
		jrnc	lbl1
lbl3:		mv	ba,[x++]		; Discard the number of bytes to jump
		pops	i			; Discard the loop parameters
		pops	i			;
		pops	i			;
		popu	ba			; Set new TOS
		rc
		jp	!interp__
		endl
unloop_:	dw	plus_loop_
		db	$08
		db	'(UNLOOP)'
unloop__xt:	local
		mv	il,6			; Discard
		add	s,il			; the loop parameters
		jp	!interp__
		endl
leave_:		dw	unloop_
		db	$07
		db	'(LEAVE)'
leave__xt:	local
		pops	i			; Discard
		pops	i			; the loop
		pops	i			; parameters (I holds the jump address now)
		mv	x,!base_address		; Skip up to
		add	x,i			; the end of the DO statement
		jp	!interp__
		endl
qst_leave_:	dw	leave_
		db	$08
		db	'(?LEAVE)'
qst_leave__xt:	local
		inc	ba			; Test the
		dec	ba			; TOS
		jrz	lbl1
		pops	i			; Discard
		pops	i			; the loop
		pops	i			; parameters (I holds the jump address now)
		mv	x,!base_address		; Skip up to
		add	x,i			; the end of the DO statement
lbl1:		popu	ba			; Set new TOS
		jp	!interp__
		endl
noop:		dw	qst_leave_
		db	$04
		db	'NOOP'
noop_xt:	local
		jp	!interp__		; Does nothing
		endl
true:		dw	noop
		db	$04
		db	'TRUE'
true_xt:	local
		jp	!docon__xt
		dw	$ffff
		endl
false:		dw	true
		db	$05
		db	'FALSE'
false_xt:	local
		jp	!docon__xt
		dw	$0000
		endl
blnk:		dw	false
		db	$02
		db	'BL'
blnk_xt:	local
		jp	!docon__xt
		dw	$0020
		endl
align:		dw	blnk
		db	$05
		db	'ALIGN'
align_xt:	local
		jp	!interp__		; Does nothing
		endl
aligned:	dw	align
		db	$07
		db	'ALIGNED'
aligned_xt:	local
		jp	!interp__		; Does nothing
		endl
cell_plus:	dw	aligned
		db	$05
		db	'CELL+'
cell_plus_xt:	local
		inc	ba			; Add two
		inc	ba			; to TOS
		jp	!interp__
		endl
cells:		dw	cell_plus
		db	$05
		db	'CELLS'
cells_xt:	local
		add	ba,ba			; Double TOS
		jp	!interp__
		endl
char_plus:	dw	cells
		db	$05
		db	'CHAR+'
char_plus_xt:	local
		inc	ba			; Add one to TOS
		jp	!interp__
		endl
chars:		dw	char_plus
		db	$05
		db	'CHARS'
chars_xt:	local
		jp	!interp__		; Does nothing
		endl
store:		dw	chars
		db	$01
		db	'!'
store_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		popu	ba			; BA holds the value to store
		mv	[y],ba			; Store the value in memory
		popu	ba			; Set new TOS
		jp	!interp__
		endl
fetch:		dw	store
		db	$01
		db	'@'
fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to fetch the value
		mv	ba,[y]			; Set new TOS
		jp	!interp__
		endl
comma:		dw	fetch
		db	$01
		db	','
comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	[y++],ba		; Store TOS HERE and post-increment Y
		mv	(!wi),y			; Save new HERE value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
compile_com:	dw	comma
		db	$08
		db	'COMPILE,'
compile_com_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	[y++],ba		; Store TOS (that holds the current token) HERE and post-increment Y
		mv	(!wi),y			; Save new HERE value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
allot:		dw	compile_com
		db	$05
		db	'ALLOT'
allot_xt:	local
		mv	i,(!wi)			; Y holds HERE value
		add	i,ba			; Update HERE value
		mv	(!wi),i			; Save new HERE value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
c_store:	dw	allot
		db	$02
		db	'C!'
c_store_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		popu	ba			; A holds the character value
		mv	[y],a			; Store the 8 low-order bits in memory
		popu	ba			; Set new TOS
		jp	!interp__
		endl
c_fetch:	dw	c_store
		db	$02
		db	'C@'
c_fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to fetch the value
		mv	ba,$0000		; To clear B register
		mv	a,[y]			; Set new TOS (only the 8 low-order bits are significative)
		jp	!interp__
		endl
c_comma:	dw	c_fetch
		db	$02
		db	'C,'
c_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	[y++],a			; Store TOS as character HERE and post-increment Y
		mv	(!wi),y			; Save new HERE value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
two_store:	dw	c_comma
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
		jp	!interp__
		endl
two_fetch:	dw	two_store
		db	$02
		db	'2@'
two_fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address where to fetch the 16 low-order bits
		mv	ba,[y++]		; Fetch the 16 high-order bits (and set new TOS)
		mv	i,[y]			; Fetch the 16 low-order bits
		pushu	i			; Push the 16 low-order bits
		jp	!interp__
		endl
two_comma:	dw	two_fetch
		db	$02
		db	'2,'
two_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	[y++],ba		; Store the 16 high-order bits in memory and post-increment Y
		popu	ba			; BA holds the low-order bits
		mv	[y++],ba		; Store the 16 low-order bits in memory
		mv	(!wi),y			; Save new HERE value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
fill:		dw	two_comma
		db	$04
		db	'FILL'
fill_xt:	local
		mv	(!el),a			; Save the 8 high-order bits of the TOS
		popu	i			; I holds the number of bytes to fill
		popu	ba			; BA holds the short address where to fill the bytes
		inc	i			; Test if the number of bytes to fill is not
		dec	i			; zero
		jrz	lbl2
		mv	y,!base_address		; Y holds the address
		add	y,ba			; where to fill the bytes
		mv	a,(!el)			; Restore the char used to fill the bytes
lbl1:		mv	[y++],a			; Fill the bytes
		dec	i			; Count the number of bytes to fill
		jrnz	lbl1
lbl2:		popu	ba			; Set new TOS
		rc
		jp	!interp__
		endl
erase:		dw	fill
		db	$05
		db	'ERASE'
erase_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!fill_xt
		dw	!doexit__xt
		endl
move:		dw	erase
		db	$04
		db	'MOVE'
move_xt:	local
		mv	(!ex),ba		; Save the number of bytes to move
		popu	ba			; BA holds the short destination address
		popu	i			; I holds the short source address
		pushu	x			; Save IP
		mv	y,!base_address
		mv	x,y
		add	y,ba			; Y holds the destination address
		add	x,i			; X holds the source address
		sub	ba,i			; Test if source address is lower or greater than destination one
		mv	i,(!ex)			; Restore the the number of bytes to move
		inc	i			; Test if the number of
		dec	i			; bytes to move is zero
		jrz	lbl3
		jrc	lbl2
		add	x,i			; X holds the address of the last byte to move + 1
		add	y,i			; X holds the destination address of the last byte to move + 1
lbl1:		mv	a,[--x]			; Move the bytes
		mv	[--y],a			; by traversing towards lower addresses
		dec	i			; Count the number of bytes to move
		jrnz	lbl1
		jr	lbl3
lbl2:		mv	a,[x++]			; Move the bytes
		mv	[y++],a			; by traversing towards higher addresses
		dec	i			; Count the number of bytes to move
		jrnz	lbl2
lbl3:		popu	x			; Restore IP
		popu	ba			; Set new TOS
		rc
		jp	!interp__
		endl
drop:		dw	move
		db	$04
		db	'DROP'
drop_xt:	local
		popu	ba			; Discard old TOS an set new one
		jp	!interp__
		endl
two_drop:	dw	drop
		db	$05
		db	'2DROP'
two_drop_xt:	local
		popu	ba			; Discard old TOS
		popu	ba			; Discard next value and set new TOS
		jp	!interp__
		endl
fdrop:		dw	two_drop
		db	$05
		db	'FDROP'
fdrop_xt:	local
		cmp	(!ll),0			; Is the floating point stack empty?
		jrz	lbl1
		mv	y,(!xi)			; Y holds FP's value
		inc	y
		inc	y
		inc	y
		mv	(!xi),y			; Update FP
		dec	(!ll)			; Update the depth of the stack
		jp	!interp__
lbl1:		pushu	ba			; Save TOS
		mv	ba,-45			; Floating-point stack underflow
		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
dup:		dw	fdrop
		db	$03
		db	'DUP'
dup_xt:		local
		pushu	ba			; Save TOS
		jp	!interp__
		endl
two_dup:	dw	dup
		db	$04
		db	'2DUP'
two_dup_xt:	local
		mv	i,[u]			; I holds the next value
		pushu	ba			; Push TOS
		pushu	i			; Push next value (BA already contains the TOS)
		jp	!interp__
		endl
quest_dup:	dw	two_dup
		db	$04
		db	'?DUP'
quest_dup_xt:	local
		dec	ba			; Test if
		inc	ba			; TOS is zero
		jpz	!interp__
		pushu	ba			; Duplicate if non-zero
		jp	!interp__
		endl
fdup:		dw	quest_dup
		db	$04
		db	'FDUP'
fdup_xt:	local
		pushs	x			; Save IP
		cmp	(!ll),0			; Is the floating point stack empty?
		jrz	lbl3
		cmp	(!ll),!heap_size	; Is the floating point stack full?
		jrz	lbl1
		mv	y,(!xi)			; Y holds FP's value
		mv	x,[y]			; X holds the top of the floating-point stack
		mv	[--y],x			; Duplicate it
		mv	(!xi),y			; Update FP
		inc	(!ll)			; Update the depth of the stack
		pops	x			; Restore IP
		jp	!interp__
lbl1:		pushu	ba			; Save TOS
		mv	ba,-44			; Floating-point stack overflow
lbl2:		mv	i,!throw_xt
		rc
		jp	!throw_xt
lbl3:		pushu	ba			; Save TOS
		mv	ba,-45			; Floating-point stack underflow
		jr	lbl2
		endl
nip:		dw	fdup
		db	$03
		db	'NIP'
nip_xt:		local
		popu	i			; Discard second stack element
		jp	!interp__
		endl
two_nip:	dw	nip
		db	$04
		db	'2NIP'
two_nip_xt:	local
		mvw	(!fx),[u++]
		popu	i			; Discard third stack element
		popu	i			; Discard fourth stack element
		mvw	[--u],(!fx)
		jp	!interp__
		endl
fnip:		dw	two_nip
		db	$04
		db	'FNIP'
fnip_xt:	local
		pushs	x			; Save IP
		cmp	(!ll),2			; Is there enough elements on the floating point stack?
		jrc	lbl1
		mv	y,(!xi)			; Y holds FP's value
		mv	x,[y++]			; X holds the top of the floating-point stack
		mv	[y],x			; Discard the next element
		mv	(!xi),y			; Update FP
		dec	(!ll)			; Update the depth of the stack
		pops	x			; Restore IP
		jp	!interp__
lbl1:		pushu	ba			; Save TOS
		mv	ba,-45			; Floating-point stack underflow
		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
over:		dw	fnip
		db	$04
		db	'OVER'
over_xt:	local
		pushu	ba			; Save TOS
		mv	ba,[u+2]		; Set new TOS
		jp	!interp__
		endl
two_over:	dw	over
		db	$05
		db	'2OVER'
two_over_xt:	local
		pushu	ba			; Save TOS
		mv	ba,[u+6]		; Store the fourth stack element
		pushu	ba			; Save the fourth stack element
		mv	ba,[u+6]		; Set new TOS to the old third element
		jp	!interp__
		endl
fover:		dw	two_over
		db	$05
		db	'FOVER'
fover_xt:	local
		pushs	x			; Save IP
		cmp	(!ll),2			; Is there enough elements on the floating point stack?
		jrc	lbl3
		cmp	(!ll),!heap_size	; Is the floating point stack full?
		jrz	lbl1
		mv	y,(!xi)			; Y holds FP's value
		mv	x,[y+3]			; X holds the second element of the floating-point stack
		mv	[--y],x			; Duplicate it on the top
		mv	(!xi),y			; Update FP
		inc	(!ll)			; Update the depth of the stack
		pops	x			; Restore IP
		jp	!interp__
lbl1:		pushu	ba			; Save TOS
		mv	ba,-44			; Floating-point stack overflow
lbl2:		mv	i,!throw_xt
		rc
		jp	!throw_xt
lbl3:		pushu	ba			; Save TOS
		mv	ba,-45			; Floating-point stack underflow
		jr	lbl2
		endl
pick:		dw	fover
		db	$04
		db	'PICK'
pick_xt:	local
		mv	y,u			; Store SP value
		add	ba,ba			; Compute the offset
		add	y,ba			; Y holds the address of the value to fetch
		mv	ba,[y]			; Set new TOS
		jp	!interp__
		endl
roll:		dw	pick
		db	$04
		db	'ROLL'
roll_xt:	local
		inc	ba			; Test if TOS
		dec	ba			; is zero
		jrnz	lbl1
		popu	ba			; Set new TOS
		jp	!interp__
lbl1:		mv	y,u			; Store SP value
		mv	i,ba			; Store the TOS into I
		add	ba,ba			; Compute the offset
		add	y,ba			; Y holds the address of the value to fetch
		mv	ba,[y]			; BA holds the new TOS
		pushu	ba			; Save new TOS into the stack
lbl2:		mv	ba,[--y]		; BA holds the next stack's element
		mv	[y+2],ba		; Replace previous element by BA contents
		dec	i			; Count the number of elements to roll
		jrnz	lbl2
		popu	ba			; Restore new TOS
		popu	i			; Discard the stack's old first element
		jp	!interp__
		endl
rot:		dw	roll
		db	$03
		db	'ROT'
rot_xt:		local
		popu	i			; Store old second stack element
		pushu	ba			; Set new second stack element to old TOS
		mv	ba,[u+2]		; Set new TOS (old third element)
		mv	[u+2],i			; Set new third stack element to old second one
		jp	!interp__
		endl
two_rot:	dw	rot
		db	$04
		db	'2ROT'
two_rot_xt:	local
		mv	i,[u+2]			; Store old third element
		mv	[u+2],ba		; Replace it with old TOS
		mv	ba,[u+6]		; Store old fifth element
		mv	[u+6],i			; Replace it with old third one
		mv	i,[u]			; Store old second element
		pushu	ba			; Save new TOS
		mv	ba,[u+6]		; Store old fourth element
		mv	[u+6],i			; Replace it with old second element
		mv	i,[u+10]		; Store old sisth element
		mv	[u+10],ba		; Replace it with old fourth one
		mv	[u+2],i			; Replace old second element by old sixth one
		popu	ba			; Set new TOS
		jp	!interp__
		endl
minus_rot:	dw	two_rot
		db	$04
		db	'-ROT'
minus_rot_xt:	local
		mv	i,[u+2]			; Store old third element
		mv	[u+2],ba		; Set new third element to old TOS
		popu	ba			; Set new TOS to old second element
		pushu	i			; Set new second element to old third one
		jp	!interp__
		endl
swap:		dw	minus_rot
		db	$04
		db	'SWAP'
swap_xt:	local
		popu	i			; Pop next element
		pushu	ba			; Save TOS
		mv	ba,i			; Set new TOS
		jp	!interp__
		endl
two_swap:	dw	swap
		db	$05
		db	'2SWAP'
two_swap_xt:	local
		mv	i,[u+2]			; Store the third stack element
		mv	[u+2],ba		; Exchange TOS and
		pushu	i			; the third element and save new TOS
		mv	i,[u+6]			; Store the fourth stack element
		mv	ba,[u+2]		; Store the second stack element
		mv	[u+6],ba		; Exchange the fourth and
		mv	[u+2],i			; the second element
		popu	ba			; Set new TOS
		jp	!interp__
		endl
tuck:		dw	two_swap
		db	$04
		db	'TUCK'
tuck_xt:	local
		popu	i			; Store the second stack element
		pushu	ba			; Set new third element to TOS
		pushu	i			; Set new second element to old one
		jp	!interp__
		endl
to_r:		dw	tuck
		db	$02
		db	'>R'
to_r_xt:	local
		pushs	ba			; Save TOS in the return stack
		popu	ba			; Set new TOS
		jp	!interp__
		endl
two_to_r:	dw	to_r
		db	$03
		db	'2>R'
two_to_r_xt:	local
		popu	i			; Store second stack element
		pushs	i			; Save it in the return stack
		pushs	ba			; Save old TOS in the return stack
		popu	ba			; Set new TOS
		jp	!interp__
		endl
r_from:		dw	two_to_r
		db	$02
		db	'R>'
r_from_xt:	local
		pushu	ba
		pops	ba			; Set new TOS to return stack top
		jp	!interp__
		endl
two_r_from:	dw	r_from
		db	$03
		db	'2R>'
two_r_from_xt:	local
		pushu	ba
		pops	ba			; Set new TOS to return stack top
		pops	i			; Pop second return stack element
		pushu	i			; Push it into the data stack
		jp	!interp__
		endl
r_fetch:	dw	two_r_from
		db	$02
		db	'R@'
r_fetch_xt:	local
		pushu	ba
		mv	ba,[s]			; Set new TOS to return stack top
		jp	!interp__
		endl
two_r_fetch:	dw	r_fetch
		db	$03
		db	'2R@'
two_r_fetch_xt:	local
		pushu	ba
		mv	ba,[s]			; Set new TOS to return stack top
		mv	i,[s+2]			; Fetch return stack's second element
		pushu	i			; Set new second element
		jp	!interp__
		endl
r_tick_ftch:	dw	two_r_fetch
		db	$03
		db	'R''@'
r_tick_ftch_xt:	local
		pushu	ba
		mv	ba,[s+2]		; Set new TOS to return stack's second element
		jp	!interp__
		endl
r_quot_ftch:	dw	r_tick_ftch
		db	$03
		db	'R"@'
r_quot_ftch_xt:	local
		pushu	ba
		mv	ba,[s+4]		; Set new TOS to return stack's third element
		jp	!interp__
		endl
dup_to_r:	dw	r_quot_ftch
		db	$05
		db	'DUP>R'
dup_to_r_xt:	local
		pushs	ba			; Copy TOS to the return stack
		jp	!interp__
		endl
r_from_drop:	dw	dup_to_r
		db	$06
		db	'R>DROP'
r_from_drop_xt:	local
		pops	i			; Remove return stack's first element
		jp	!interp__
		endl
i:		dw	r_from_drop
		db	$01
		db	'I'
i_xt:		local
		pushu	ba			; Save the TOS
		mv	ba,[s]			; Reverse the
		mv	i,[s+2]			; 'slice'
		add	ba,i			; operation (see DO)
		rc
		jp	!interp__
		endl
j:		dw	i
		db	$01
		db	'J'
j_xt:		local
		pushu	ba			; Save the TOS
		mv	ba,[s+6]		; Reverse the
		mv	i,[s+8]			; 'slice'
		add	ba,i			; operation (see DO)
		rc
		jp	!interp__
		endl
execute:	dw	j
		db	$07
		db	'EXECUTE'
execute_xt:	local
		pushs	ba			; Push the current xt into the return stack
		mv	i,ba			; Set current xt
		popu	ba			; Set new TOS
		ret				; Execute the xt
		endl
and:		dw	execute
		db	$03
		db	'AND'
and_xt:		local
		mv	(!fx),ba		; Save TOS
		popu	ba			; Pop second element
		and	a,(!fl)
		ex	a,b
		and	a,(!fh)
		ex	a,b			; Set new TOS
		jp	!interp__
		endl
or:		dw	and
		db	$02
		db	'OR'
or_xt:		local
		mv	(!fx),ba		; Save TOS
		popu	ba			; Pop second element
		or	a,(!fl)
		ex	a,b
		or	a,(!fh)
		ex	a,b			; Set new TOS
		jp	!interp__
		endl
xor:		dw	or
		db	$03
		db	'XOR'
xor_xt:		local
		mv	(!fx),ba		; Save TOS
		popu	ba			; Pop second element
		xor	a,(!fl)
		ex	a,b
		xor	a,(!fh)
		ex	a,b			; Set new TOS
		jp	!interp__
		endl
invert:		dw	xor
		db	$06
		db	'INVERT'
invert_xt:	local
		mv	i,$ffff
		sub	i,ba
		mv	ba,i
		jp	!interp__
		endl
equals:		dw	invert
		db	$01
		db	'='
equals_xt:	local
		popu	i			; Pop second stack element
		sub	i,ba			; Compare it with TOS
		rc
		jrz	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
		endl
zero_equals:	dw	equals
		db	$02
		db	'0='
zero_equals_xt:	local
		inc	ba
		dec	ba
		jrz	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
		endl
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
		jrnz	lbl1			; Jump if low-order bits differ
		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
		endl
d_zer_equ:	dw	d_equals
		db	$03
		db	'D0='
d_zer_equ_xt:	local
		popu	i			; I holds operand's 16 low-order bits
		inc	ba
		dec	ba
		jrnz	lbl1			; Jump if high-order bits are not zero
		inc	i
		dec	i
		jrnz	lbl1			; Jump if low-order bits are not zero
		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
		endl
not_equals:	dw	d_zer_equ
		db	$02
		db	'<>'
not_equals_xt:	local
		popu	i			; Pop second stack element
		sub	i,ba			; Compare it with TOS
		rc
		jrz	lbl1
		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
		endl
zer_not_equ:	dw	not_equals
		db	$03
		db	'0<>'
zer_not_equ_xt:	local
		inc	ba
		dec	ba
		jrz	lbl1
		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
		endl
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
		jrnz	lbl1			; Jump if low-order bits differ
		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
d_z_not_eq:	dw	d_not_equ
		db	$04
		db	'D0<>'
d_z_not_eq_xt:	local
		popu	i			; I holds operand's 16 low-order bits
		inc	ba
		dec	ba
		jrnz	lbl1			; Jump if high-order bits are not zero
		inc	i
		dec	i
		jrnz	lbl1			; Jump if low-order bits are not zero
		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
less_than:	dw	d_z_not_eq
		db	$01
		db	'<'
less_than_xt:	local
		popu	i
		add	i,i			; Is second element negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	i,ba			; Compare two positive left-shifted numbers
		jrc	lbl3
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
lbl3:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
		endl
zer_lss_thn:	dw	less_than
		db	$02
		db	'0<'
zer_lss_thn_xt:	local
		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
u_less_than:	dw	zer_lss_thn
		db	$02
		db	'U<'
u_less_than_xt:	local
		popu	i			; Pop second stack element
		sub	i,ba			; Compare it with TOS
		jrc	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
d_less_than:	dw	u_less_than
		db	$02
		db	'D<'
d_less_than_xt:	local
		mvw	(!fx),[u++]
		popu	i
		mvw	(!gx),[u++]
		add	i,i			; Is second element negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	i,ba			; Compare two positive left-shifted numbers
		jrc	lbl3
		jrnz	lbl2
		mv	i,(!gx)
		mv	ba,(!fx)
		sub	i,ba			; Compare the 16 low-order bits
		jrc	lbl3
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
lbl3:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
		endl
d_zer_l_thn:	dw	d_less_than
		db	$03
		db	'D0<'
d_zer_l_thn_xt:	local
		popu	i			; Discard the 16 low-order bits
		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
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
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl2:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
greatr_than:	dw	d_u_l_than
		db	$01
		db	'>'
greatr_than_xt:	local
		popu	i
		add	i,i			; Is second element negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	ba,i			; Compare two positive left-shifted numbers
		jrnc	lbl3
lbl2:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
		endl
zer_grt_thn:	dw	greatr_than
		db	$02
		db	'0>'
zer_grt_thn_xt:	local
		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		jrz	lbl1
		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
		endl
u_grtr_than:	dw	zer_grt_thn
		db	$02
		db	'U>'
u_grtr_than_xt:	local
		popu	i			; Pop second stack element
		sub	ba,i			; Compare it with TOS
		jrnc	lbl1
		rc
		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
		endl
d_grtr_than:	dw	u_grtr_than
		db	$02
		db	'D>'
d_grtr_than_xt:	local
		mvw	(!fx),[u++]
		popu	i
		mvw	(!gx),[u++]
		add	i,i			; Is second element negative?
		jrc	lbl4
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
lbl1:		sub	i,ba			; Compare two positive left-shifted numbers
		jrc	lbl3
		jrnz	lbl2
		mv	i,(!gx)
		mv	ba,(!fx)
		sub	i,ba			; Compare the 16 low-order bits
		jrc	lbl3
		jrz	lbl3
lbl2:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
lbl4:		add	ba,ba			; Is TOS negative?
		jrc	lbl1
		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
		endl
d_zer_g_thn:	dw	d_grtr_than
		db	$03
		db	'D0>'
d_zer_g_thn_xt:	local
		popu	i			; I holds the 16 low-order bits
		add	ba,ba			; Is TOS negative?
		jrc	lbl2
		jrnz	lbl1
		inc	i			; Test whether the
		dec	i			; double is zero or not
		jrz	lbl2
lbl1:		mv	ba,$ffff		; Set new TOS to TRUE
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
		endl
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
lbl1:		mv	ba,$0000		; Set new TOS to FALSE
		jp	!interp__
lbl2:		mv	ba,$ffff		; Set new TOS to TRUE
		rc
		jp	!interp__
		endl
within:		dw	d_u_g_than
		db	$06
		db	'WITHIN'
within_xt:	local
		jp	!docol__xt
		dw	!over_xt
		dw	!minus_xt
		dw	!to_r_xt
		dw	!minus_xt
		dw	!r_from_xt
		dw	!u_less_than_xt
		dw	!doexit__xt
		endl
s_to_d:		dw	within
		db	$03
		db	'S>D'
s_to_d_xt:	local
		pushu	ba
		mv	i,ba
		add	i,i
		jrnc	lbl1
		rc
		mv	ba,$ffff		; TOS is negative
		jp	!interp__
lbl1:		mv	ba,$0000		; TOS is positive
		jp	!interp__
		endl
d_to_s:		dw	s_to_d
		db	$03
		db	'D>S'
d_to_s_xt:	local
		inc	ba
		jrz	lbl1
		dec	ba
		jrnz	lbl2			; The double precision number is too large
lbl1:		popu	ba
		jp	!interp__
lbl2:		mv	ba,-11			; Result out of range
		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
abs:		dw	d_to_s
		db	$03
		db	'ABS'
abs_xt:		local
		mv	i,ba
		add	i,i
		jpnc	!interp__
		mv	il,$00
		sub	i,ba
		mv	ba,i
		rc
		jp	!interp__
		endl
d_abs:		dw	abs
		db	$04
		db	'DABS'
d_abs_xt:	local
		pushu	ba			; Save the TOS
		add	ba,ba			; Test the sign
		popu	ba			; Restore TOS
		jrnc	lbl1
		mv	il,$00			; Negate the 16 high-order bits before
		sub	i,ba			;
		mv	(!fx),i			; Save the result
		popu	ba			; Negate the 16
		mv	il,$00			; lower-bits
		sub	i,ba			;
		pushu	i			; Save them on the stack
		mv	ba,(!fx)		; Restore the 16 high-order bits
		jrnc	lbl1			; Test if they must be adjusted
		dec	ba
		rc
lbl1:		jp	!interp__
		endl
max:		dw	d_abs
		db	$03
		db	'MAX'
max_xt:		local
		jp	!docol__xt
		dw	!two_dup_xt
		dw	!less_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt
lbl2:		dw	!drop_xt
		dw	!doexit__xt
		endl
u_max:		dw	max
		db	$04
		db	'UMAX'
u_max_xt:		local
		jp	!docol__xt
		dw	!two_dup_xt
		dw	!u_less_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt
lbl2:		dw	!drop_xt
		dw	!doexit__xt
		endl
d_max:		dw	u_max
		db	$04
		db	'DMAX'
d_max_xt:	local
		jp	!docol__xt
		dw	!two_over_xt
		dw	!two_over_xt
		dw	!d_less_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!two_swap_xt
lbl2:		dw	!two_drop_xt
		dw	!doexit__xt
		endl
min:		dw	d_max
		db	$03
		db	'MIN'
min_xt:		local
		jp	!docol__xt
		dw	!two_dup_xt
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt
lbl2:		dw	!drop_xt
		dw	!doexit__xt
		endl
u_min:		dw	min
		db	$04
		db	'UMIN'
u_min_xt:		local
		jp	!docol__xt
		dw	!two_dup_xt
		dw	!u_grtr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!swap_xt
lbl2:		dw	!drop_xt
		dw	!doexit__xt
		endl
d_min:		dw	u_min
		db	$04
		db	'DMIN'
d_min_xt:	local
		jp	!docol__xt
		dw	!two_over_xt
		dw	!two_over_xt
		dw	!d_grtr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!two_swap_xt
lbl2:		dw	!two_drop_xt
		dw	!doexit__xt
		endl
two_star:	dw	d_min
		db	$02
		db	'2*'
two_star_xt:	local
		add	ba,ba			; Double (left bit-shift) TOS
		rc
		jp	!interp__
		endl
d_two_star:	dw	two_star
		db	$03
		db	'D2*'
d_two_star_xt:	local
		add	ba,ba			; Double (left bit-shift) the 16 high-order bits
		popu	i			; I holds the 16 low-order bits
		add	i,i			; Double the 16 low-order bits
		pushu	i
		jrnc	lbl1
		rc
		inc	ba			; Update the 16 high-order bits in case of carry
lbl1:		jp	!interp__
		endl
lshift:		dw	d_two_star
		db	$06
		db	'LSHIFT'
lshift_xt:	local
		popu	i
		cmp	a,0			; Ignore the 8 high-order bits
		jrz	lbl2
lbl1:		add	i,i			; Left shift the bits
		dec	a
		jrnz	lbl1
lbl2:		mv	ba,i
		rc
		jp	!interp__
		endl
two_slash:	dw	lshift
		db	$02
		db	'2/'
two_slash_xt:	local
		rc
		ex	a,b
		shr	a			; Right bit-shift 8 high-order bits
		ex	a,b
		shr	a			; Right bit-shift 8 low-order bits
		rc
		jp	!interp__
		endl
d_two_slash:	dw	two_slash
		db	$03
		db	'D2/'
d_two_slash_xt:	local
		rc
		ex	a,b
		shr	a			; Right bit-shift 8 high-order bits
		ex	a,b
		shr	a			; Right bit-shift 8 low-order bits
		mv	i,ba
		popu	ba
		ex	a,b
		shr	a			; Right bit-shift 8 high-order bits
		ex	a,b
		shr	a			; Right bit-shift 8 low-order bits
		rc
		pushu	ba
		mv	ba,i
		jp	!interp__
		endl
rshift:		dw	d_two_slash
		db	$06
		db	'RSHIFT'
rshift_xt:	local
		popu	i
		mv	(!fx),i
		cmp	a,0			; Ignore the 8 high-order bits
		jrz	lbl2
lbl1:		rc
		shr	(!fh)			; Left shift
		shr	(!fl)			; the bits
		dec	a
		jrnz	lbl1
lbl2:		mv	ba,(!fx)
		jp	!interp__
		endl
plus:		dw	rshift
		db	$01
		db	'+'
plus_xt:	local
		popu	i
		add	ba,i
		rc
		jp	!interp__
		endl
one_plus:	dw	plus
		db	$02
		db	'1+'
one_plus_xt:	local
		inc	ba
		jp	!interp__
		endl
two_plus:	dw	one_plus
		db	$02
		db	'2+'
two_plus_xt:	local
		inc	ba
		inc	ba
		jp	!interp__
		endl
plus_store:	dw	two_plus
		db	$02
		db	'+!'
plus_store_xt:	local
		popu	i			; I holds the value to add
		mv	y,!base_address
		add	y,ba			; Y holds the address where to store the value
		mv	ba,[y]			; BA holds the old value
		add	ba,i			; BA holds the new value
		rc
		mv	[y],ba			; Store the new value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
d_plus:		dw	plus_store
		db	$02
		db	'D+'
d_plus_xt:	local
		mv	(!fx),ba
		popu	ba
		mvw	(!gx),[u++]
		popu	i
		add	ba,i
		pushu	ba
		mv	ba,(!fx)
		mv	i,(!gx)
		jrnc	lbl1
		inc	ba
lbl1:		add	ba,i
		rc
		jp	!interp__
		endl
m_plus:		dw	d_plus
		db	$02
		db	'M+'
m_plus_xt:	local
		mvw	(!fx),[u++]
		mv	i,ba
		add	i,i
		jrc	lbl3
		popu	i
		add	i,ba
		pushu	i
		mv	ba,(!fx)
		jrnc	lbl2
		inc	ba
lbl1:		rc
lbl2:		jp	!interp__
lbl3:		popu	i
		add	i,ba
		pushu	i
		mv	ba,(!fx)
		jrc	lbl1
		dec	ba
		jp	!interp__
		endl
minus:		dw	m_plus
		db	$01
		db	'-'
minus_xt:	local
		popu	i
		sub	i,ba
		rc
		mv	ba,i
		jp	!interp__
		endl
one_minus:	dw	minus
		db	$02
		db	'1-'
one_minus_xt:	local
		dec	ba
		jp	!interp__
		endl
two_minus:	dw	one_minus
		db	$02
		db	'2-'
two_minus_xt:	local
		dec	ba
		dec	ba
		jp	!interp__
		endl
d_minus:	dw	two_minus
		db	$02
		db	'D-'
d_minus_xt:	local
		mv	(!fx),ba
		popu	i
		mvw	(!gx),[u++]
		popu	ba
		sub	ba,i
		pushu	ba
		mv	i,(!fx)
		mv	ba,(!gx)
		jrnc	lbl1
		dec	ba
lbl1:		sub	ba,i
		rc
		jp	!interp__
		endl
m_minus:	dw	d_minus
		db	$02
		db	'M-'
m_minus_xt:	local
		mvw	(!fx),[u++]
		mv	i,ba
		add	i,i
		jrc	lbl3
		popu	i
		sub	i,ba
		pushu	i
		mv	ba,(!fx)
		jrnc	lbl2
		dec	ba
lbl1:		rc
lbl2:		jp	!interp__
lbl3:		popu	i
		sub	i,ba
		pushu	i
		mv	ba,(!fx)
		jrc	lbl1
		inc	ba
		jp	!interp__
		endl
negate:		dw	m_minus
		db	$06
		db	'NEGATE'
negate_xt:	local
		mv	il,$00
		sub	i,ba
		mv	ba,i
		rc
		jp	!interp__
		endl
d_negate:	dw	negate
		db	$07
		db	'DNEGATE'
d_negate_xt:	local
		mv	il,$00			; Negate the 16 high-order bits before
		sub	i,ba			;
		mv	(!fx),i			; Save the result
		popu	ba			; Negate the 16
		mv	il,$00			; lower-bits
		sub	i,ba			;
		pushu	i			; Save them on the stack
		mv	ba,(!fx)		; Restore the 16 high-order bits
		jrnc	lbl1			; Test if they must be adjusted
		dec	ba
		rc
lbl1:		jp	!interp__
		endl
star:		dw	d_negate
		db	$01
		db	'*'
star_xt:	local
		popu	i
		mv	(!el),$80		; Initialize counter
		mv	(!fx),ba		; Save old TOS
		mv	ba,0			; Initialize result
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
		rc
		jp	!interp__
		endl
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
		rc
		jp	!interp__
		endl
slash_mod:	dw	d_star
		db	$04
		db	'/MOD'
slash_mod_xt:	local
		mv	(!eh),$00		; The sign of the modulo (bit 0) and the sign of the quotient (bit 1)
		mv	i,ba			; Copy old TOS (the second argument)
		inc	ba			; Test if the divisor
		dec	ba			; is zero
		jrz	lbl7
		add	ba,ba			; Test the sign of the divisor
		jrnc	lbl1
		mv	(!eh),$02		; The quotient may be negative
		mv	ba,$0000		; Negate
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
		mv	ba,$0000		; BA holds the absolute value of the result of the division
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
		mv	ba,$0000		; Negate
		sub	ba,i			; the modulo
		mv	i,ba
		popu	ba			; Restore the quotient of the division
lbl6:		pushu	i			; Save the modulo
		test	(!eh),$02		; Test the sign of the quotient
		jpnz	!negate_xt		; Negate the TOS
		rc
		jp	!interp__
lbl7:		mv	ba,-10			; Division by zero
		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
slash:		dw	slash_mod
		db	$01
		db	'/'
slash_xt:	local
		jp	!docol__xt
		dw	!slash_mod_xt
		dw	!nip_xt
		dw	!doexit__xt
		endl
mod:		dw	slash
		db	$03
		db	'MOD'
mod_xt:		local
		jp	!docol__xt
		dw	!slash_mod_xt
		dw	!drop_xt
		dw	!doexit__xt
		endl
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
		rc
		jp	!interp__
lbl11:		mvw	[--u],(!jx)		; Save the quotient
		mv	ba,(!kx)
		rc
		jp	!interp__
lbl12:		mv	ba,-10			; Division by zero
		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
d_slash:	dw	d_slash_mod
		db	$02
		db	'D/'
d_slash_xt:	local
		jp	!docol__xt
		dw	!d_slash_mod_xt
		dw	!two_nip_xt
		dw	!doexit__xt
		endl
d_mod:		dw	d_slash
		db	$04
		db	'DMOD'
d_mod_xt:	local
		jp	!docol__xt
		dw	!d_slash_mod_xt
		dw	!two_drop_xt
		dw	!doexit__xt
		endl
u_m_d_star:	dw	d_mod
		db	$04
		db	'UMD*'
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
		rc
		jp	!interp__
		endl
u_m_star:	dw	u_m_d_star
		db	$03
		db	'UM*'
u_m_star_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!rot_xt
		dw	!u_m_d_star_xt
		dw	!doexit__xt
		endl
m_star:		dw	u_m_star
		db	$02
		db	'M*'
m_star_xt:	local
		jp	!docol__xt
		dw	!s_to_d_xt
		dw	!rot_xt
		dw	!dup_to_r_xt
		dw	!abs_xt
		dw	!u_m_d_star_xt
		dw	!r_from_xt
		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!d_negate_xt
lbl2:		dw	!doexit__xt
		endl
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
		mv	ba,$0000		; BA holds the absolute value of the result of the division
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
		rc
		jp	!interp__
lbl6:		mv	ba,-10			; Division by zero
		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
s_m_sl_rem:	dw	u_m_sl_mod
		db	$06
		db	'SM/REM'
s_m_sl_rem_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!to_r_xt
		dw	!abs_xt
		dw	!minus_rot_xt
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
lbl4:		dw	!doexit__xt
		endl
f_m_sl_mod:	dw	s_m_sl_rem
		db	$06
		db	'FM/MOD'
f_m_sl_mod_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!to_r_xt
		dw	!abs_xt
		dw	!minus_rot_xt
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
		dw	!doexit__xt
		endl
star_sl_mod:	dw	f_m_sl_mod
		db	$05
		db	'*/MOD'
star_sl_mod_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!m_star_xt
		dw	!r_from_xt
		dw	!s_m_sl_rem_xt
		dw	!doexit__xt
		endl
star_slash:	dw	star_sl_mod
		db	$02
		db	'*/'
star_slash_xt:	local
		jp	!docol__xt
		dw	!star_sl_mod_xt
		dw	!nip_xt
		dw	!doexit__xt
		endl
m_star_sl:	dw	star_slash
		db	$03
		db	'M*/'
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
lbl8:		mv	ba,$0000		; BA holds the 16 high-order bits of the absolute value of the result
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
		mv	ba,$0000		; BA holds the 16 low-order bits of the absolute value of the result
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
		rc
		jp	!interp__
lbl18:		mv	ba,-24			; Invalid numeric argument
		jr	lbl21
lbl19:		mv	ba,-10			; Division by zero
		jr	lbl21
lbl20:		mv	ba,-11			; Result out of range
lbl21:		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
;call_op_:	dw	m_star_sl
;		db	$09
;		db	'(CALL-OP)'
;call_op_xt:	local
;		pushs	x			; Save IP
;		mv	y,_table		; Y holds the address of the jump table
;		shl	a			; Compute
;		shl	a			; the address of
;		add	y,a			; the entry in the table
;		mv	x,[y++]			; X holds the adress of the floating-point routine
;		mv	a,[y]			; 4 low-order bits: # of inputs; 4 high-order bits: # of outputs
;		mv	(!el),a			; Make a copy of the 8 low-order bits (0-3: # of inputs, 4-7: # of outputs)
;		and	(!el),$f0		; Compute the # of outputs
;		and	a,$0f			; Compute the # of inputs
;		cmp	(!ll),a
;		jrnc	lbl1
;		mv	ba,-45			; Floating-point stack underflow
;		jr
;lbl1:		sub	(!ll),a			; Update the depth of the floating-point stack
;		cmp	a,2
;		jrnc	
;		cmp	(!ll),a 		; Is there enough place on the floating-point stack?
;		jrnc	lbl1
;		rc
;		mv	ba,-44			; Floating-point stack overflow
;		mv	i,!throw_xt
;		jp	!throw_xt
;lbl1:		pushs	x			; Save IP
;		cmp	(!lh),a			; Is there enough free places on the heap?
;		jrnc	lbl7
;		pushu	a			; Save TOS's 8 low-order bits
;		mv	a,$00			; Set A to $00 to erase the heap's marks
;		mv	il,16			; I holds the length of a heap allocation unit
;		mv	(!el),!heap_size	; Copy the size of the heap
;		mv	x,!heap_addr		; X holds the address of the heap
;lbl2:		mv	[x],a			; Erase the pointed mark
;		add	x,il			; Move to the next mark
;		dec	(!el)			; Count the number of remaining marks
;		jrnz	lbl2
;		popu	a			; Restore TOS's 8 low-order bits
;		pushu	a			; Save TOS's 8 low-order bits
;		mv	(!el),(!ll)		; The number of floating-point items on the stack
;		mv	a,$ff			; Set A to $ff to mark the current floatig-point number as used
;		mv	x,(!xi)			; X holds the floating-point stack pointer
;lbl3:		mv	y,[x++]			; Y holds the address of the current floating-point number
;		cmpp	(!zi),y			; Is the current floating-point number stored on the heap?
;		jrnc	lbl4
;		mv	[y-1],a			; Mark the current floatig-point place
;lbl4:		dec	(!el)			; Count the number of remainig items
;		jrnz	lbl3
;		mv	(!lh),0			; Reset the free heap pointers stack's remaining places
;		mv	(!el),!heap_size	; Copy the size of the heap
;		mv	x,!heap_addr+1		; X holds the address of the first heap-allocated floating-point number
;		mv	y,!a_beginning		; Y holds the address of the free heap pointers stack's beginning
;lbl5:		mv	a,[x-1]			; Get the current mark
;		cmp	a,$00			; Is the current heap allocation unit available?
;		jrnz	lbl6
;		mv	[--y],x			; Add the address to the free heap pointers stack
;		inc	(!lh)			; Update the depth of the free heap pointers stack
;lbl6:		add	x,il			; Move to the next mark
;		dec	(!el)			; Count the number of remaining marks
;		jrnz	lbl5
;		mv	(!yi),y			; Update free heap pointers stack pointer
;		popu	a			; Restore TOS's 8 low-order bits
;lbl7:		add	(!ll),a			; Update the floating-point stack's depth
;		sub	(!lh),a			; Update the heap's remaining places
;lbl8:		mv	y,(!yi)			; Y holds the free heap pointers stack pointer
;		mv	x,[y++]			; X holds the top free heap pointer
;		mv	(!yi),y			; Update the free heap pointers stack pointer
;		mv	y,(!xi)			; Y holds the floating-point stack pointer
;		mv	[--y],x			; Push the free heap pointer on the floating-point stack
;		mv	(!xi),y			; Update the floating-point stack pointer
;		dec	a			; Count the number of stack items to push
;		jrnz	lbl8
;		pops	x			; Restore IP
;		jp	!interp__
;_table:	dp	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
		db	$00000
		db	$11
;		endl		
s_equals:	dw	m_star_sl
		db	$02
		db	'S='
s_equals_xt:	local
		mv	i,[u+2]			; I holds the length of the first string
		sub	ba,i			; Test the length of the strings
		jrnz	lbl5
		pushs	x			; Save IP
		mv	x,!base_address
		mv	y,x
		popu	ba
		add	y,ba			; Y holds the address of the second string
		popu	ba			; Discard the length of the first string (already known)
		popu	ba
		add	x,ba			; X holds the address of the first string
		inc	i
		dec	i
		jrz	lbl2
lbl1:		mv	a,[x++]
		mv	(!el),[y++]
		cmp	(!el),a			; Compare characters
		jrnz	lbl4
		dec	i
		jrnz	lbl1
lbl2:		mv	ba,$ffff		; Set new TOS to TRUE
lbl3:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl4:		mv	ba,$0000		; Set new TOS to TRUE
		jr	lbl3
lbl5:		popu	y			; Clean-up the stack
		popu	y			;
		mv	ba,$0000		; Set new TOS to FALSE
		rc
		jp	!interp__
		endl
dash_trail:	dw	s_equals
		db	$09
		db	'-TRAILING'
dash_trail_xt:	local
		inc	ba			; Does the length of
		dec	ba			; the string equals zero?
		jpz	!interp__
		mv	i,ba			; I holds the length of the string
		mv	y,!base_address
		add	y,i
		mv	ba,[u]			; BA holds the short address of the string
		add	y,ba			; Y holds the address of the last character of the string + 1
lbl1:		mv	a,[--y]			; Read characters from the end
		cmp	a,$20			; Compare current character to character space
		jrnz	lbl2
		dec	i			; Is the begining of the string reached?
		jrnz	lbl1
lbl2:		mv	ba,i			; Set new TOS
		rc
		jp	!interp__
		endl
slash_str:	dw	dash_trail
		db	$07
		db	'/STRING'
slash_str_xt:	local
		mv	i,[u+2]			; I holds the short address of the string
		add	i,ba			; Add TOS to this address
		mv	[u+2],i			; Save the new address on the stack
		popu	i			; I holds the length of the string
		sub	i,ba			; Adjust the length of the string
		mv	ba,i			; Set new TOS to this length
		rc
		jp	!interp__
		endl
next_char:	dw	slash_str
		db	$09
		db	'NEXT-CHAR'
next_char_xt:	local
		inc	ba			; Test whether the
		dec	ba			; string is empty or not
		jrnz	lbl1
		mv	ba,-24			; Invalid numeric argument
		mv	i,!throw_xt
		jp	!throw_xt
lbl1:		mv	y,!base_address
		popu	i			; I holds the short address of the string
		add	y,i			; Y holds the address of the string
		inc	i			; Consume one character
		dec	ba			; of the string
		pushu	i			; Save the new address on the stack
		pushu	ba			; Save the new length on the stack
		mv	a,0			; Set
		ex	a,b			; new
		mv	a,[y]			; TOS
		rc
		jp	!interp__
		endl
blank:		dw	next_char
		db	$05
		db	'BLANK'
blank_xt:	local
		jp	!docol__xt
		dw	!blnk_xt
		dw	!fill_xt
		dw	!doexit__xt
		endl
c_move:		dw	blank
		db	$05
		db	'CMOVE'
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
		dec	i
		jrz	lbl2
lbl1:		mv	a,[x++]			; Move characters from
		mv	[y++],a			; lower to upper addresses
		dec	i			; Count the number of characters to move
		jrnz	lbl1
lbl2:		pops	x			; Restore IP
		popu	ba			; Set new TOS
		rc
		jp	!interp__
		endl
c_move_up:	dw	c_move
		db	$06
		db	'CMOVE>'
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
		dec	i
		jrz	lbl2
lbl1:		mv	a,[--x]			; Move characters from
		mv	[--y],a			; upper to lower addresses
		dec	i			; Count the number of characters to move
		jrnz	lbl1
lbl2:		pops	x			; Restore IP
		popu	ba			; Set new TOS
		rc
		jp	!interp__
		endl
compare:	dw	c_move_up
		db	$07
		db	'COMPARE'
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
		dec	i			; equals zero?
		jrz	lbl3
lbl2:		mv	(!el),[x++]		; Compare
		mv	a,[y++]			; characters
		cmp	(!el),a			;
		jrc	lbl5
		jrnz	lbl6
		dec	i			; Count the number of remaining characters
		jrnz	lbl2
lbl3:		cmpw	(!fx),(!gx)		; Strings are equal with respect to their first characters
		jrc	lbl5			; Compare the length to discriminate
		jrnz	lbl6			; over them
		mv	ba,0			; Set new TOS (strings are equal)
lbl4:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl5:		mv	ba,-1			; Set new TOS (string1 is lower than string2)
		jr	lbl4
lbl6:		mv	ba,1			; Set new TOS (string1 is greater than string2)
		jr	lbl4
		endl
search:		dw	compare
		db	$06
		db	'SEARCH'
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
lbl3:		mv	ba,$ffff		; Set new TOS (a match is found)
lbl4:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl5:		popu	y			; Positon Y at the beginning of the second string
		popu	x			; X holds the previous address from where to start searching
		inc	x			; Increment it
		mv	ba,(!fx)		; Restore BA's value to the length of the second string
		dec	i			; Count the number of possible matches
		jrnz	lbl1
lbl6:		mv	ba,$0000		; Set new TOS (no match found)
		jr	lbl4
		endl
match_quest:	dw	search
		db	$06
		db	'MATCH?'
match_quest_xt:	local
		jp	!docol__xt
		dw	!search_xt
		dw	!nip_xt
		dw	!nip_xt
		dw	!zer_not_equ_xt
		dw	!doexit__xt
		endl
on:		dw	match_quest
		db	$02
		db	'ON'
on_xt:		local
		jp	!docol__xt
		dw	!true_xt
		dw	!swap_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
off:		dw	on
		db	$03
		db	'OFF'
off_xt:		local
		jp	!docol__xt
		dw	!false_xt
		dw	!swap_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
ms:		dw	off
		db	$02
		db	'MS'
ms_xt:		local
lbl1:		inc	ba			; 3 cycles
		dec	ba			; 3 cycles
		jrz	lbl3			; 2 cycles (3 when jumping)
		mv	i,$72			; 3 cycles
lbl2:		dec	i			; 3*72 cycles
		jrnz	lbl2			; 3*71+2 cycles
		dec	ba			; 3 cycles
		jr	lbl1			; 3 cycles
lbl3:		popu	ba			; Set new TOS
		jp	!interp__
		endl
buffer0:	dw	ms
		db	$07
		db	'BUFFER0'
buffer0_xt:	local
		jp	!dovar__xt
		dw	$0000			; Link to the next buffer (zero if last one)
		dw	$0000			; UPDATE field
		ds	!blk_buff_size		; Block or file buffer  ************* CREATE-BUFFER *************
		endl
last_buffer:	dw	buffer0
		db	$0b
		db	'LAST-BUFFER'
last_buffer_xt:	local
		jp	!dovar__xt
		dw	!buffer0_xt
		endl
blk:		dw	last_buffer
		db	$03
		db	'BLK'
blk_xt:		local
		jp	!dovar__xt
		dw	0
		endl
block:		dw	blk
		db	$05
		db	'BLOCK'
block_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
buffer:		dw	block
		db	$06
		db	'BUFFER'
buffer_xt:	local
		jp	!docol__xt
		dw	!block_xt
		dw	!doexit__xt
		endl
save_buffs:	dw	buffer
		db	$0c
		db	'SAVE-BUFFERS'
save_buffs_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
empty_buffs:	dw	save_buffs
		db	$0d
		db	'EMPTY-BUFFERS'
empty_buffs_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
flush:		dw	empty_buffs
		db	$05
		db	'FLUSH'
flush_xt:	local
		jp	!docol__xt
		dw	!save_buffs_xt
		dw	!empty_buffs_xt
		dw	!doexit__xt
		endl
load:		dw	flush
		db	$04
		db	'LOAD'
load_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
thru:		dw	load
		db	$04
		db	'THRU'
thru_xt:	local
		jp	!docol__xt
		dw	!one_plus_xt
		dw	!swap_xt
		dw	!quest_do__xt
		dw	lbl2
lbl1:		dw	!i_xt
		dw	!load_xt
		dw	!loop__xt
		dw	lbl2-lbl1
lbl2:		dw	!doexit__xt
		endl
update:		dw	thru
		db	$06
		db	'UPDATE'
update_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
scr:		dw	update
		db	$03
		db	'SCR'
scr_xt:		local
		jp	!dovar__xt
		dw	0
		endl
list:		dw	scr
		db	$04
		db	'LIST'
list_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
pad:		dw	list
		db	$03
		db	'PAD'
pad_xt:		local
		jp	!docon__xt
		dw	$ff00
		endl
pocket_nbr:	dw	pad
		db	$07
		db	'POCKET#'
pocket_nbr_xt:	local
		jp	!doval__xt
		dw	$0000
		endl
pocket0:	dw	pocket_nbr
		db	$07
		db	'POCKET0'
pocket0_xt:	local
		jp	!dovar__xt
		ds	!ib_size
		endl
pocket1:	dw	pocket0
		db	$07
		db	'POCKET1'
pocket1_xt:	local
		jp	!dovar__xt
		ds	!ib_size
		endl
which_pockt:	dw	pocket1
		db	$0c
		db	'WHICH-POCKET'
which_pockt_xt:	local
		jp	!docol__xt
		dw	!pocket_nbr_xt
		dw	!zero_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!pocket0_xt
		dw	!ahead__xt
		dw	lbl3-lbl2
lbl2:			dw	!pocket1_xt
lbl3:		dw	!dolit__xt
		dw	$0001
		dw	!pocket_nbr_xt
		dw	!xor_xt
		dw	!doto__xt
		dw	!pocket_nbr_xt+3
		dw	!doexit__xt
		endl
no_io_error:	dw	which_pockt
		db	$0a
		db	'NO-IOERROR'
no_io_error_xt:	local
		jp	!docon__xt
		dw	$0000
		endl
bin:		dw	no_io_error
		db	$03
		db	'BIN'
bin_xt:		local
		jp	!interp__		; Does nothing (since files are UNIX-coded)
		endl
r_o:		dw	bin
		db	$03
		db	'R/O'
r_o_xt:		local
		jp	!docon__xt
		dw	$0001
		endl
r_w:		dw	r_o
		db	$03
		db	'R/W'
r_w_xt:		local
		jp	!docon__xt
		dw	$0003
		endl
w_o:		dw	r_w
		db	$03
		db	'W/O'
w_o_xt:		local
		jp	!docon__xt
		dw	$0002
		endl
stdo:		dw	w_o
		db	$04
		db	'STDO'
stdo_xt:	local
		jp	!docon__xt
		dw	$0001
		endl
stdi:		dw	stdo
		db	$04
		db	'STDI'
stdi_xt:	local
		jp	!docon__xt
		dw	$0002
		endl
stdl:		dw	stdi
		db	$04
		db	'STDL'
stdl_xt:	local
		jp	!docon__xt
		dw	$0003
		endl
filenam_nbr:	dw	stdl
		db	$09
		db	'FILENAME#'
filenam_nbr_xt:	local
		jp	!doval__xt
		dw	$0000
		endl
filename0:	dw	filenam_nbr
		db	$09
		db	'FILENAME0'
filename0_xt:	local
		jp	!dovar__xt
		ds	5+1+8+1+3		; Drive name + ':' + file name + '.' + extension
		ds	1+2+2+3			; Attribute + time + date + size
		endl
filename1:	dw	filename0
		db	$09
		db	'FILENAME1'
filename1_xt:	local
		jp	!dovar__xt
		ds	5+1+8+1+3		; Drive name + ':' + file name + '.' + extension
		ds	1+2+2+3			; Attribute + time + date + size
		endl
which_filen:	dw	filename1
		db	$0e
		db	'WHICH-FILENAME'
which_filen_xt:	local
		jp	!docol__xt
		dw	!filenam_nbr_xt
		dw	!zero_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!filename0_xt
		dw	!ahead__xt
		dw	lbl3-lbl2
lbl2:			dw	!filename1_xt
lbl3:		dw	!dolit__xt
		dw	$0001
		dw	!filenam_nbr_xt
		dw	!xor_xt
		dw	!doto__xt
		dw	!filenam_nbr_xt+3
		dw	!doexit__xt
		endl
drive_name:	dw	which_filen
		db	$0a
		db	'DRIVE-NAME'
drive_name_xt:	local
		jp	!docol__xt
		dw	!two_dup_xt
		dw	!doslit__xt
		dw	1
		db	':'
		dw	!search_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!drop_xt
			dw	!nip_xt
			dw	!over_xt
			dw	!minus_xt
			dw	!doexit__xt
lbl2:		dw	!two_drop_xt
		dw	!dup_xt
		dw	!minus_xt
		dw	!doexit__xt
		endl
file_name:	dw	drive_name
		db	$09
		db	'FILE-NAME'
file_name_xt:	local
		jp	!docol__xt
		dw	!doslit__xt
		dw	1
		db	':'
		dw	!search_xt
		dw	!if__xt
		dw	lbl4-lbl1
lbl1:			dw	!dolit__xt
			dw	1
			dw	!slash_str_xt
			dw	!two_dup_xt
			dw	!doslit__xt
			dw	1
			db	'.'
			dw	!search_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!drop_xt
				dw	!nip_xt
				dw	!over_xt
				dw	!minus_xt
				dw	!doexit__xt
lbl3:			dw	!two_drop_xt
			dw	!doexit__xt
lbl4:		dw	!dup_xt
		dw	!minus_xt
		dw	!doexit__xt
		endl
extension:	dw	file_name
		db	$09
		db	'EXTENSION'
extension_xt:	local
		jp	!docol__xt
		dw	!doslit__xt
		dw	1
		db	'.'
		dw	!search_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	1
			dw	!slash_str_xt
			dw	!doexit__xt
lbl2:		dw	!dup_xt
		dw	!minus_xt
		dw	!doexit__xt
		endl
fnp:		dw	extension
		db	$03
		db	'FNP'
fnp_xt:		local
		jp	!dovar__xt
		dw	$0000
		endl
store_drve_:	dw	fnp
		db	$0d
		db	'(STORE-DRIVE)'
store_drve__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	5
		dw	!min_xt
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!swap_xt
		dw	!dup_xt
		dw	!fnp_xt
		dw	!plus_store_xt
		dw	!c_move_xt
		dw	!dolit__xt
		dw	$003a			; The value of the ':' character
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!c_store_xt
		dw	!dolit__xt
		dw	1
		dw	!fnp_xt
		dw	!plus_store_xt
		dw	!doexit__xt
		endl
store_name_:	dw	store_drve_
		db	$0c
		db	'(STORE-NAME)'
store_name__xt:	local
		jp	!docol__xt
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!dolit__xt
		dw	8
		dw	!blank_xt
		dw	!dolit__xt
		dw	8
		dw	!min_xt
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!swap_xt
		dw	!c_move_xt
		dw	!dolit__xt
		dw	8
		dw	!fnp_xt
		dw	!plus_store_xt
		dw	!doexit__xt
		endl
store_ext_:	dw	store_name_
		db	$0b
		db	'(STORE-EXT)'
store_ext__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$002e			; The value of the '.' character
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!c_store_xt
		dw	!dolit__xt
		dw	1
		dw	!fnp_xt
		dw	!plus_store_xt
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!dolit__xt
		dw	3
		dw	!blank_xt
		dw	!dolit__xt
		dw	3
		dw	!min_xt
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!swap_xt
		dw	!c_move_xt
		dw	!dolit__xt
		dw	3
		dw	!fnp_xt
		dw	!plus_store_xt
		dw	!doexit__xt
		endl
store_attr_:	dw	store_ext_
		db	$0c
		db	'(STORE-ATTR)'
store_attr__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0020			; Default attribute
		dw	!fnp_xt
		dw	!fetch_xt
		dw	!c_store_xt
		dw	!doexit__xt
		endl
str_to_filn:	dw	store_attr_
		db	$0f
		db	'STRING>FILENAME'
str_to_filn_xt:	local
		jp	!docol__xt
		dw	!which_filen_xt
		dw	!dup_to_r_xt
		dw	!fnp_xt
		dw	!store_xt
		dw	!two_dup_xt
		dw	!drive_name_xt
		dw	!store_drve__xt
		dw	!two_dup_xt
		dw	!file_name_xt
		dw	!store_name__xt
		dw	!extension_xt
		dw	!store_ext__xt
		dw	!store_attr__xt
		dw	!r_from_xt
		dw	!doexit__xt
		endl
filn_to_str:	dw	str_to_filn
		db	$0f
		db	'FILENAME>STRING'
filn_to_str_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	6
		dw	!doslit__xt
		dw	1
		db	':'
		dw	!search_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!drop_xt
			dw	!over_xt
			dw	!minus_xt
			dw	!dolit__xt
			dw	13
			dw	!plus_xt
			dw	!doexit__xt
lbl2:		dw	!two_drop_xt
		dw	!dolit__xt
		dw	0
		dw	!doexit__xt
		endl
to_filename:	dw	filn_to_str
		db	$09
		db	'>FILENAME'
to_filename_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	y,!filenam_nbr_xt+3	; Filename areas are
		mv	i,[y]			; attributed
		inc	i			; following
		dec	i			; round-robin rule
		jrnz	lbl1
		mv	i,$0001			; Set next filename area number
		mv	x,!filename0_xt+3	; X holds current filename area address
		jr	lbl2
lbl1:		mv	il,$00			; Set next filename area number
		mv	x,!filename1_xt+3	; X holds current filename area address
lbl2:		mv	[y],i			; Save next filename area number
		pushs	x			; Save current filename area address
		mv	(!cl),a			; File handle
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl3
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
		rc
		jp	!interp__
lbl5:		mv	i,x			; Save current filename
		pushu	i			; area address on the stack
		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl4
		pre_off
		endl
creat_file_:	dw	to_filename
		db	$0d
		db	'(CREATE-FILE)'
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
		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
create_file:	dw	creat_file_
		db	$0b
		db	'CREATE-FILE'
create_file_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!str_to_filn_xt
		dw	!r_from_xt
		dw	!creat_file__xt
		dw	!doexit__xt
		endl
del_file_:	dw	create_file
		db	$0d
		db	'(DELETE-FILE)'
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
		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
delete_file:	dw	del_file_
		db	$0b
		db	'DELETE-FILE'
delete_file_xt:	local
		jp	!docol__xt
		dw	!str_to_filn_xt
		dw	!del_file__xt
		dw	!doexit__xt
		endl
file_set:	dw	delete_file
		db	$08
		db	'FILE-SET'
file_set_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		popu	i
		add	x,i			; X holds the address of the file name
		mv	y,18
		add	y,x			; Y holds the current file attribute area
		mv	[y++],a			; Set attribute (ignore 8 high-order bits)
		mv	ba,$0000		; Set time
		mv	[y++],ba		; and date
		mv	[y++],ba		; ('not specified')
		mv	il,$0b			; 'Changing directory information of drive'
		mv	a,$01			; 'Writing of the directory information of drive'
		callf	!fcs
		jrnc	lbl2
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
protected:	dw	file_set
		db	$09
		db	'PROTECTED'
protected_xt:	local
		jp	!docon__xt
		dw	$0001
		endl
invisible:	dw	protected
		db	$09
		db	'INVISIBLE'
invisible_xt:	local
		jp	!docon__xt
		dw	$0002
		endl
file_statu_:	dw	invisible
		db	$0d
		db	'(FILE-STATUS)'
file_statu__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		add	x,ba			; X holds the address of the file name
		mv	y,18
		add	y,x			; Y holds the current file attribute area
		mv	il,$0b			; 'Changing directory information of drive'
		mv	a,$00			; 'Reading of the directory information of drive'
		callf	!fcs
		mv	il,[y++]		; Read the file attribute
		pushu	i			; Save it on the stack
		mv	i,[y++]			; Read the time information
		pushu	i			; Save it on the stack
		mv	i,[y++]			; Read the date information
		pushu	i			; Save it on the stack
		mv	i,[y++]			; Read the 16 low-order bits of the size information
		pushu	i			; Save them on the stack
		mv	il,[y]			; Read the 8 high-order bits of the size information
		pushu	i			; Save it on the stack
		jrnc	lbl2
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
file_status:	dw	file_statu_
		db	$0b
		db	'FILE-STATUS'
file_status_xt:	local
		jp	!docol__xt
		dw	!str_to_filn_xt
		dw	!file_statu__xt
		dw	!doexit__xt
		endl
ren_file_:	dw	file_status
		db	$0d
		db	'(RENAME-FILE)'
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
		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl1
		pre_off
		endl
rename_file:	dw	ren_file_
		db	$0b
		db	'RENAME-FILE'
rename_file_xt:	local
		jp	!docol__xt
		dw	!two_swap_xt
		dw	!str_to_filn_xt
		dw	!minus_rot_xt
		dw	!which_filen_xt
		dw	!dup_to_r_xt
		dw	!dolit__xt
		dw	18
		dw	!blank_xt
		dw	!two_dup_xt
		dw	!doslit__xt
		dw	1
		db	'.'
		dw	!search_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!tuck_xt
			dw	!dolit__xt
			dw	4
			dw	!min_xt
			dw	!r_fetch_xt
			dw	!dolit__xt
			dw	8
			dw	!plus_xt
			dw	!swap_xt
			dw	!c_move_xt
		dw	!ahead__xt
		dw	lbl3-lbl2
lbl2:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	0
lbl3:		dw	!minus_xt
		dw	!dolit__xt
		dw	8
		dw	!min_xt
		dw	!r_fetch_xt
		dw	!swap_xt
		dw	!c_move_xt
		dw	!r_from_xt
		dw	!ren_file__xt
		dw	!doexit__xt
		endl
open_file_:	dw	rename_file
		db	$0b
		db	'(OPEN-FILE)'
open_file__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		popu	i
		add	x,i			; X holds the address of the filename
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
		rc
		jp	!interp__
lbl3:		mv	il,(!cl)		; Read file handle
		inc	i			; Increment it (because fileIDs must start at index 1)
		pushu	i			; Save it on the stack
		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
open_file:	dw	open_file_
		db	$09
		db	'OPEN-FILE'
open_file_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!str_to_filn_xt
		dw	!r_from_xt
		dw	!open_file__xt
		dw	!doexit__xt
		endl
close_file:	dw	open_file
		db	$0a
		db	'CLOSE-FILE'
close_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	il,$02			; 'Closing a file'
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
		callf	!fcs
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
file_info:	dw	close_file
		db	$09
		db	'FILE-INFO'
file_info_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
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
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
file_pos:	dw	file_info
		db	$0d
		db	'FILE-POSITION'
file_pos_xt:	local
		jp	!docol__xt
		dw	!file_info_xt
		dw	!to_r_xt
		dw	!two_drop_xt
		dw	!two_drop_xt
		dw	!r_from_xt
		dw	!doexit__xt
		endl
file_size:	dw	file_pos
		db	$09
		db	'FILE-SIZE'
file_size_xt:	local
		jp	!docol__xt
		dw	!file_info_xt
		dw	!to_r_xt
		dw	!two_drop_xt
		dw	!two_nip_xt
		dw	!r_from_xt
		dw	!doexit__xt
		endl
fil_end_qst:	dw	file_size
		db	$09
		db	'FILE-END?'
fil_end_qst_xt:	local
		jp	!docol__xt
		dw	!file_info_xt
		dw	!to_r_xt
		dw	!two_drop_xt
		dw	!d_equals_xt
		dw	!r_from_xt
		dw	!doexit__xt
		endl
read_file:	dw	fil_end_qst
		db	$09
		db	'READ-FILE'
read_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		popu	i			; I holds the number of bytes to read
		mv	y,i			; Save them into Y
		popu	i			; I holds the short address where to store the data
		add	x,i			; X holds the address where to store the data
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
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
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
read_char:	dw	read_file
		db	$09
		db	'READ-CHAR'
read_char_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		mv	(bp+!el),(!cl)		; Make a copy of the file handle
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl2
		mv	il,$0a			; 'Reading various information of a file'
		mv	a,$00			; 'Reading of file size, pointer value'
		callf	!fcs
		jrc	lbl2
		cmpw	(!si),(!di)		; Compare file position
		jrnz	lbl1			; with
		cmp	(!si+2),(!di+2)		; file size
		jrz	lbl2
lbl1:		mv	il,$05			; 'Reading a byte of the file'
		mv	(!cl),(bp+!el)		; Restore the file handle
		mv	a,$01			; 'File end is physical end of file'
		callf	!fcs
		jrnc	lbl4
lbl2:		mv	il,$00			; Set the value of the character to zero
		pushu	i			; (an error occurred)
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl3:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl4:		ex	a,b			; Test
		cmp	a,$00			; whether
		mv	a,$0c			; no character
		jrz	lbl2			; was read (THERE IS A BUG IN THIS PRIMITIVE
		mv	a,$00			; SO THAT THAT NEVER HAPPENS, HENCE THE ABOVE CODE
		ex	a,b			; TO TEST THE FILE POSITION)
		pushu	ba			; Save the character on the stack
		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl3
		pre_off
		endl
peek_char:	dw	read_char
		db	$09
		db	'PEEK-CHAR'
peek_char_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
		mv	il,$08			; 'Non destructive reading a file'
		mv	a,$81			; 'File end is physical end of file, with data'
		callf	!fcs
		jrnc	lbl3
lbl1:		mv	il,$00			; Set the value of the character to zero
		pushu	i			; (an error occurred)
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl3:		ex	a,b			; Test
		cmp	a,$00			; whether
		mv	a,$0c			; no character
		jrz	lbl1			; was read
		mv	a,$00			
		ex	a,b
		pushu	ba			; Save the character on the stack
		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
chr_rdy_qst:	dw	peek_char
		db	$0b
		db	'CHAR-READY?'
chr_rdy_qst_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
		mv	il,$08			; 'Non destructive reading a file'
		mv	a,$01			; 'File end is physical end of file, without data'
		callf	!fcs
		jrnc	lbl3
		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl1:		mv	il,$00			; Set I to FALSE
lbl2:		pushu	i			; Save I contents
		pops	x			; Restore IP
		rc
		jp	!interp__
lbl3:		ex	a,b			; Test whether
		cmp	a,$00			; no character was read
		mv	ba,$0000		; Set new TOS (no error)
		jrz	lbl1			; 
		mv	i,$ffff			; Set I to TRUE
		jr	lbl2
		pre_off
		endl
read_line:	dw	chr_rdy_qst
		db	$09
		db	'READ-LINE'
read_line_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!fil_end_qst_xt
		dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!nip_xt
			dw	!nip_xt
			dw	!doexit__xt
lbl2:		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!two_drop_xt
			dw	!drop_xt
			dw	!dolit__xt
			dw	0
			dw	!false_xt
			dw	!no_io_error_xt
			dw	!doexit__xt
lbl4:		dw	!to_r_xt
		dw	!swap_xt
		dw	!to_r_xt
		dw	!dolit__xt
		dw	-1
lbl5:			dw	!one_plus_xt
			dw	!two_dup_xt
			dw	!not_equals_xt
		dw	!if__xt
		dw	lbl9-lbl6
lbl6:			dw	!r_tick_ftch_xt
			dw	!read_char_xt
			dw	!quest_dup_xt
			dw	!if__xt
			dw	lbl8-lbl7
lbl7:				dw	!nip_xt
				dw	!r_from_drop_xt
				dw	!r_from_drop_xt
				dw	!doexit__xt
lbl8:			dw	!dup_xt
			dw	!r_from_xt
			dw	!tuck_xt
			dw	!c_store_xt
			dw	!one_plus_xt
			dw	!to_r_xt
			dw	!dolit__xt
			dw	$000a			; The value of the LF character
			dw	!equals_xt
		dw	!until__xt
		dw	lbl9-lbl5
lbl9:		dw	!nip_xt
		dw	!true_xt
		dw	!no_io_error_xt
		dw	!r_from_drop_xt
		dw	!r_from_drop_xt
		dw	!doexit__xt
		endl
write_file:	dw	read_line
		db	$0a
		db	'WRITE-FILE'
write_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		popu	i			; I holds the number of bytes to write
		mv	y,i			; Save them into Y
		popu	i			; I holds the short address where to fetch the data
		add	x,i			; X holds the address where to fetch the data
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
		mv	il,$04			; 'Writing a block of the file'
		callf	!fcs
		jrnc	lbl3
		cmp	a,$0c			; Test whether the specified number of bytes wasn't written
		jrz	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
write_char:	dw	write_file
		db	$0a
		db	'WRITE-CHAR'
write_char_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		popu	i			; I holds the value of the character to write
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
		mv	a,il			; A holds the 8 low-order bits of the character value
		mv	il,$06			; 'Writing a byte of the file'
		callf	!fcs
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl3:		ex	a,b			; Test
		cmp	a,$00			; whether
		mv	a,$0c			; no character
		jrz	lbl1			; was written
		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
write_line:	dw	write_char
		db	$0a
		db	'WRITE-LINE'
write_line_xt:	local
		jp	!docol__xt
		dw	!dup_to_r_xt
		dw	!write_file_xt
		dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!r_from_drop_xt
			dw	!doexit__xt
lbl2:		dw	!dolit__xt
		dw	$000a			; The value of the LF character
		dw	!r_from_xt
		dw	!write_char_xt
		dw	!doexit__xt
		endl
file_seek_:	dw	write_line
		db	$0b
		db	'(FILE-SEEK)'
file_seek__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	(bp+!el),a		; Save position attribute (relative from top, etc.)
		popu	ba
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl3
		popu	ba			; Read the 16 high-order bits
		mv	i,ba			; I holds the 16 high-order bits
		ex	a,b			; Test
		test	a,$80			; for an
		jrnz	lbl1			; eventual
		cmp	a,$00			; overflow
		mv	a,$01			; 'The parameter is beyond the range'
		jrnz	lbl4			;
		popu	ba			; Test
		inc	ba			; the low-order
		dec	ba			; bits
		jrz	lbl6
		jr	lbl2			;
lbl1:		cmp	a,$ff			;
		mv	a,$01			; 'The parameter is beyond the range'
		jrnz	lbl4
		popu	ba
lbl2:		mv	(!si+2),il		; Store the 8 last low-order ones (ignore others)
		mv	(!si),ba		; Store the 16 low-order bits
		mv	il,$09			; 'Moving a file pointer'
		mv	a,(bp+!el)		; Restore position attribute
		callf	!fcs
		jrnc	lbl7
		jr	lbl5
lbl3:		popu	i			; Discard the 16 high-order bits
lbl4:		popu	i			; Discard the 16 low-order bits
lbl5:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl6:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl7:		mv	ba,$0000
		jr	lbl6
		pre_off
		endl
repos_file:	dw	write_line
		db	$0f
		db	'REPOSITION-FILE'
repos_file_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000			; 'Relative value from the file top'
		dw	!file_seek__xt
		dw	!doexit__xt
		endl
skip_chars:	dw	repos_file
		db	$0a
		db	'SKIP-CHARS'
skip_chars_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0001			; 'Relative value from the present position'
		dw	!file_seek__xt
		dw	!doexit__xt
		endl
verify_file:	dw	skip_chars
		db	$0b
		db	'VERIFY-FILE'
verify_file_xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!base_address
		mv	(!cl),a			; File handle
		dec	(!cl)			; Decrement it (because fileIDs start at index 1)
		popu	y			; Y holds the number of bytes to verify (20 bits)
		popu	il			; Discard the 8 high-order bits of the double
		popu	i			; I holds the short address where to find the data to be verified
		add	x,i			; X holds the address where to find the data to be verified
		ex	a,b
		cmp	a,$00
		mv	a,$06			; 'Ineffective file handle was attempted'
		jrnz	lbl1
		mv	il,$04			; 'Verifying a file'
		mv	a,$01			; 'File end is physical end of file'
		callf	!fcs
		mv	il,$00			; Save on the stack as a double the
		pushu	il			; number of bytes that
		pushu	y			; was successfully verified
		jrnc	lbl3
lbl1:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl2:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
resize_file:	dw	verify_file
		db	$0b
		db	'RESIZE-FILE'
resize_file_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	0
		dw	!skip_chars_xt
		dw	!doexit__xt
		endl
find_file_:	dw	resize_file
		db	$0b
		db	'(FIND-FILE)'
find_file__xt:	local
		pre_on
		pushs	x			; Save IP
		mv	x,!filenam_nbr_xt+3	; Filename areas are
		mv	i,[x]			; attributed
		inc	i			; following
		dec	i			; round-robin rule
		jrnz	lbl1
		mv	y,!filename0_xt+3	; Y holds current filename area address
		jr	lbl2
lbl1:		mv	y,!filename1_xt+3	; Y holds current filename area address
lbl2:		mv	x,!base_address	
		popu	i
		add	x,i			; X holds the file name pattern
		pushu	y			; Save the current filename area address
		mv	(!bx),ba		; Position to start searching
		mv	il,$0c			; 'Searching for corresponding file name'
		mv	a,$00			; 'Searching for the back of the specified directory number'
		callf	!fcs
		popu	y			; Restore the current filename area address
		mv	i,x
		pushu	i			; Save the file name pattern on the stack
		mvw	[--u],(!bx)		; Save next position to start searching on the stack
		mv	i,y
		pushu	i			; Save the detected file name address on the stack
		jrnc	lbl5
lbl3:		ex	a,b			; Set new TOS
		mv	a,$01			; (an error
		ex	a,b			; occurred)
lbl4:		pops	x			; Restore IP
		rc
		jp	!interp__
lbl5:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl4
		pre_off
		endl
free_capty:	dw	find_file_
		db	$0d
		db	'FREE-CAPACITY'
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
		rc
		jp	!interp__
lbl3:		mv	ba,$0000		; Set new TOS (no error)
		jr	lbl2
		pre_off
		endl
to_key_buff:	dw	free_capty
		db	$0b
		db	'>KEY-BUFFER'
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
key_clear:	dw	to_key_buff
		db	$09
		db	'KEY-CLEAR'
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
inkey:		dw	key_clear
		db	$05
		db	'INKEY'
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
e_key_quest:	dw	inkey
		db	$05
		db	'EKEY?'
e_key_quest_xt:	local
		jp	!docol__xt
		dw	!stdi_xt
		dw	!chr_rdy_qst_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-57		; Exception in sending or receiving a character
			dw	!throw_xt
lbl2:		dw	!doexit__xt
		endl
e_key:		dw	e_key_quest
		db	$04
		db	'EKEY'
e_key_xt:	local
		jp	!docol__xt
		dw	!cursor_xt
		dw	!fetch_xt
		dw	!set_cursor_xt
		dw	!stdi_xt
		dw	!read_char_xt
		dw	!dolit__xt
		dw	$0000
		dw	!set_cursor_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-57		; Exception in sending or receiving a character
			dw	!throw_xt
lbl2:		dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!doexit__xt
lbl4:		dw	!stdi_xt
		dw	!read_char_xt
		dw	!drop_xt
		dw	!negate_xt
		dw	!doexit__xt
		endl
e_key_to_ch:	dw	e_key
		db	$09
		db	'EKEY>CHAR'
e_key_to_ch_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zer_grt_thn_xt
		dw	!doexit__xt
		endl
key_quest:	dw	e_key_to_ch
		db	$04
		db	'KEY?'
key_quest_xt:	local
		jp	!docol__xt
lbl1:			dw	!e_key_quest_xt
		dw	!if__xt
		dw	lbl5-lbl2
lbl2:			dw	!stdi_xt
			dw	!peek_char_xt
			dw	!drop_xt
			dw	!zer_not_equ_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!true_xt
				dw	!doexit__xt
lbl4:			dw	!stdi_xt
			dw	!read_char_xt
			dw	!two_drop_xt
		dw	!again__xt
		dw	lbl5-lbl1
lbl5:		dw	!false_xt
		dw	!doexit__xt
		endl
key:		dw	key_quest
		db	$03
		db	'KEY'
key_xt:		local
		jp	!docol__xt
lbl1:			dw	!e_key_xt
			dw	!dup_xt
			dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl3-lbl2
lbl2:			dw	!drop_xt
		dw	!again__xt
		dw	lbl3-lbl1
lbl3:		dw	!doexit__xt
		endl
set_symbols:	dw	key
		db	$0b
		db	'SET-SYMBOLS'
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
busy_on:	dw	set_symbols
		db	$07
		db	'BUSY-ON'
busy_on_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0001
		dw	!dolit__xt
		dw	1
		dw	!set_symbols_xt
		dw	!doexit__xt
		endl
busy_off:	dw	busy_on
		db	$08
		db	'BUSY-OFF'
busy_off_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!dolit__xt
		dw	1
		dw	!set_symbols_xt
		dw	!doexit__xt
		endl
cursor:		dw	busy_off
		db	$06
		db	'CURSOR'
cursor_xt:	local
		jp	!dovar__xt
		dw	$0028
		endl
set_cursor:	dw	cursor
		db	$0a
		db	'SET-CURSOR'
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
emit:		dw	set_cursor
		db	$04
		db	'EMIT'
emit_xt:	local
		pre_on
		mv	il,$06			; 'Writing a byte of the file'
		mv	(!cl),$00		; LCD display's file handle
		callf	!fcs
		jrnc	lbl2
		cmp	a,$ff			; Test if break key has been pushed
		mv	i,[!handler_xt+3]	; Test whether there is
		inc	i			; a handler for this exception or not
		dec	i			;
		jpz	!break__
		mv	ba,-57			; Exception in sending or receiving a character
lbl1:		mv	i,!throw_xt
		rc
		jp	!throw_xt
lbl2:		popu	ba			; Set new TOS
		jp	!interp__
		pre_off
		endl
cr:		dw	emit
		db	$02
		db	'CR'
cr_xt:		local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$000d			; The value of the carriage return character
		dw	!emit_xt
		dw	!dolit__xt
		dw	$000a			; The value of the line feed character
		dw	!emit_xt
		dw	!doexit__xt
		endl
space:		dw	cr
		db	$05
		db	'SPACE'
space_xt:	local
		jp	!docol__xt
		dw	!blnk_xt
		dw	!emit_xt
		dw	!doexit__xt
		endl
spaces:		dw	space
		db	$06
		db	'SPACES'
spaces_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!drop_xt
			dw	!doexit__xt
lbl2:		dw	!dolit__xt
		dw	0
		dw	!quest_do__xt
		dw	lbl4
lbl3:			dw	!space_xt
		dw	!loop__xt
		dw	lbl4-lbl3
lbl4:		dw	!doexit__xt
		endl
page:		dw	spaces
		db	$04
		db	'PAGE'
page_xt:	local
		pushu	ba			; Save TOS
		mv	ba,$0000		; Set x and y coordinates
		mv	[$bfc27],ba		; of both next position to print
		mv	[$bfc9b],ba		; and cursor to zero
		pre_on
lbl1:		mvw	(!cx),$0000		; LCD driver
		mv	il,$51			; 'Clearing of display 1'
		callf	!iocs
		pre_off
		popu	ba			; Restore TOS
		jp	!interp__
		endl
x_fetch:	dw	page
		db	$02
		db	'X@'
x_fetch_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,$0000
		mv	a,[$bfc9b]
		jp	!interp__
		endl
x_store:	dw	x_fetch
		db	$02
		db	'X!'
x_store_xt:	local
		mv	il,[$bfc9d]		; The maximum length of a line
		dec	i
		sub	i,ba			; Test if the value is not out of range
		jrnc	lbl1
		add	ba,i			; Set the value to its upper bound
		rc
lbl1:		mv	[$bfc27],a
		mv	[$bfc9b],a
		popu	ba			; Set new TOS
		jp	!interp__
		endl
y_fetch:	dw	x_store
		db	$02
		db	'Y@'
y_fetch_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,$0000
		mv	a,[$bfc9c]
		jp	!interp__
		endl
y_store:	dw	y_fetch
		db	$02
		db	'Y!'
y_store_xt:	local
		mv	il,[$bfc9e]		; The maximum number of lines
		dec	i
		sub	i,ba			; Test if the value is not out of range
		jrnc	lbl1
		add	ba,i			; Set the value to its upper bound
		rc
lbl1:		mv	[$bfc28],a
		mv	[$bfc9c],a
		popu	ba			; Set new TOS
		jp	!interp__
		endl
x_max_fetch:	dw	y_store
		db	$05
		db	'XMAX@'
x_max_fetch_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,$0000
		mv	a,[$bfc9d]
		jp	!interp__
		endl
x_max_store:	dw	x_max_fetch
		db	$05
		db	'XMAX!'
x_max_store_xt:	local
		mv	[$bfc9d],a
		popu	ba			; Set new TOS
		jp	!interp__
		endl
y_max_fetch:	dw	x_max_store
		db	$05
		db	'YMAX@'
y_max_fetch_xt:	local
		pushu	ba			; Save old TOS
		mv	ba,$0000
		mv	a,[$bfc9e]
		jp	!interp__
		endl
y_max_store:	dw	y_max_fetch
		db	$05
		db	'YMAX!'
y_max_store_xt:	local
		mv	[$bfc9e],a
		popu	ba			; Set new TOS
		jp	!interp__
		endl
at_x_y:		dw	y_max_store
		db	$05
		db	'AT-XY'
at_x_y_xt:	local
		jp	!docol__xt
		dw	!y_store_xt
		dw	!x_store_xt
		dw	!doexit__xt
		endl
type_:		dw	at_x_y
		db	$06
		db	'(TYPE)'
type__xt:	local
		mv	(!el),[$bfca1]		; Save display mode
		or	a,(!el)			; Set display
		mv	[$bfca1],a		; mode (normal/reverse...)
		popu	ba			; BA holds the length of the string to display
		popu	i			; I holds the short address of the string to display
		pushu	x			; Save IP
		pre_on
		mv	x,!base_address		; X contains the address
		add	x,i			; of the character string
		mv	y,ba			; Y holds the number of characters into the string
		mv	il,$04			; 'Writing a block of the file'
		mv	(!cl),$00		; LCD display's file handle
		callf	!fcs
		pre_off
		mv	[$bfca1],(!el)		; Restore display mode
		popu	x			; Restore IP
		jrc	lbl1
		popu	ba			; Set new TOS
		jp	!interp__
lbl1:		cmp	a,$ff			; Test if break key has been pushed
		mv	i,[!handler_xt+3]	; Test whether there is
		inc	i			; a handler for this exception or not
		dec	i			;
		jpz	!break__
		mv	ba,-57			; Exception in sending or receiving a character
lbl2:		mv	i,!throw_xt
		rc
		jp	!throw_xt
		endl
type:		dw	type_
		db	$04
		db	'TYPE'
type_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!type__xt
		dw	!doexit__xt
		endl
rev_type:	dw	type
		db	$0c
		db	'REVERSE-TYPE'
rev_type_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0040			; Bit 6 is 1: display in reverse mode
		dw	!type__xt
		dw	!doexit__xt
		endl
disp_:		dw	rev_type
		db	$06
		db	'(DISP)'
disp__xt:	local
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
lbl4:		rc
		pops	x			; Restore IP
		popu	ba			; Set new TOS
		jp	!interp__
		pre_off
		endl
scroll_:	dw	disp_
		db	$08
		db	'(SCROLL)'
scroll__xt:	local
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
		rc
		popu	x			; Restore IP
		popu	ba			; Set new TOS
		jp	!interp__
		pre_off
		endl
clean_up_:	dw	scroll_
		db	$0a
		db	'(CLEAN-UP)'
clean_up__xt:	local
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
point_:		dw	clean_up_
		db	$07
		db	'(POINT)'
point__xt:	local
		pushs	x
		pre_on
		popu	i
		mv	y,i
		popu	i
		mv	x,i
		mvw	(!cx),$0000
		mv	il,$4c
		callf	!iocs
		pre_off
		popu	ba
		pops	x
		jp	!interp__
		endl
line_:		dw	point_
		db	$06
		db	'(LINE)'
line__xt:	local
		pushs	x
		pre_on
		mv	[$bfc96],ba
		popu	i
		mv	[$bfc2a],i
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
box_:		dw	line_
		db	$05
		db	'(BOX)'
box__xt:	local
		pushs	x
		pre_on
		mv	[$bfc96],ba
		popu	i
		mv	[$bfc2a],i
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
pset:		dw	box_
		db	$04
		db	'PSET'
pset_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!point__xt
		dw	!doexit__xt
		endl
preset:		dw	pset
		db	$06
		db	'PRESET'
preset_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0001
		dw	!point__xt
		dw	!doexit__xt
		endl
xpset:		dw	preset
		db	$05
		db	'XPSET'
xpset_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0002
		dw	!point__xt
		dw	!doexit__xt
		endl
point:		dw	xpset
		db	$05
		db	'POINT'
point_xt:	local
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
mline:		dw	point
		db	$05
		db	'MLINE'
mline_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!line__xt
		dw	!doexit__xt
		endl
line:		dw	mline
		db	$04
		db	'LINE'
line_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$ffff
		dw	!mline_xt
		dw	!doexit__xt
		endl
mxline:		dw	line
		db	$06
		db	'MXLINE'
mxline_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0002
		dw	!line__xt
		dw	!doexit__xt
		endl
xline:		dw	mxline
		db	$05
		db	'XLINE'
xline_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$ffff
		dw	!mxline_xt
		dw	!doexit__xt
		endl
mrline:		dw	xline
		db	$06
		db	'MRLINE'
mrline_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0001
		dw	!line__xt
		dw	!doexit__xt
		endl
rline:		dw	mxline
		db	$05
		db	'RLINE'
rline_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$ffff
		dw	!mrline_xt
		dw	!doexit__xt
		endl
box:		dw	xline
		db	$03
		db	'BOX'
box_xt:		local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$ffff
		dw	!dolit__xt
		dw	$0000
		dw	!box__xt
		dw	!doexit__xt
		endl
beep_:		dw	box
		db	$06
		db	'(BEEP)'
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
beep:		dw	beep_
		db	$04
		db	'BEEP'
beep_xt:	local
		jp	!docol__xt
		dw	!over_xt
		dw	!dolit__xt
		dw	11
		dw	!plus_xt
		dw	!dolit__xt
		dw	100
		dw	!swap_xt
		dw	!star_slash_xt
		dw	!beep__xt
		dw	!doexit__xt
		endl
base:		dw	beep
		db	$04
		db	'BASE'
base_xt:	local
		jp	!dovar__xt		; BASE is 10 by default 
		dw	10
		endl
decimal:	dw	base
		db	$07
		db	'DECIMAL'
decimal_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	10
		dw	!base_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
hex:		dw	decimal
		db	$03
		db	'HEX'
hex_xt:		local
		jp	!docol__xt
		dw	!dolit__xt
		dw	16
		dw	!base_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
here:		dw	hex
		db	$04
		db	'HERE'
here_xt:	local
		pushu	ba
		mv	ba,(!wi)		; BA holds the data space pointer
		jp	!interp__
		endl
allocp:		dw	here
		db	$06
		db	'ALLOCP'
allocp_xt:	local
		jp	!dovar__xt
		dw	!s_limit
		endl
sp_store:	dw	allocp
		db	$03
		db	'SP!'
sp_store_xt:	local
		pushs	imr
		mv	u,!base_address
		add	u,ba
		pops	imr
		popu	ba
		jp	!interp__
		endl
sp_fetch:	dw	sp_store
		db	$03
		db	'SP@'
sp_fetch_xt:	local
		pushu	ba
		mv	ba,u			; U holds the parameter stack pointer
		jp	!interp__
		endl
rp_store:	dw	sp_fetch
		db	$03
		db	'RP!'
rp_store_xt:	local
		pushu	imr
		mv	s,!base_address
		add	s,ba
		popu	imr
		popu	ba
		jp	!interp__
		endl
rp_fetch:	dw	rp_store
		db	$03
		db	'RP@'
rp_fetch_xt:	local
		pushu	ba
		mv	ba,s			; S holds the return stack pointer
		jp	!interp__
		endl
fdpth_store:	dw	rp_fetch
		db	$03
		db	'FP!'
fdpth_store_xt:	local
		mv	(!ll),a			; Update the floating-point stack's depth
		mv	il,a			; Compute the value
		add	i,i			; of FP
		add	i,a			; given the
		mv	y,!f_limit		; depth of the
		sub	y,i			; floating-point stack
		mv	(!xi),y			; Update FP
		popu	ba			; Set new TOS
		jp	!interp__
		endl
fdpth_fetch:	dw	fdpth_store
		db	$07
		db	'FDEPTH@'
fdpth_fetch_xt:	local
		pushu	ba
		mv	ba,0
		mv	a,(!ll)			; Read the depth of the floating-point stack
		jp	!interp__
		endl
depth:		dw	fdpth_fetch
		db	$05
		db	'DEPTH'
depth_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	!s_beginning
		dw	!sp_fetch_xt
		dw	!two_plus_xt
		dw	!minus_xt
		dw	!dolit__xt
		dw	2
		dw	!slash_xt
		dw	!doexit__xt
		endl
clear:		dw	depth
		db	$05
		db	'CLEAR'
clear_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	!s_beginning
		dw	!sp_store_xt
		dw	!doexit__xt
		endl
handler:	dw	clear
		db	$07
		db	'HANDLER'
handler_xt:	local
		jp	!dovar__xt
		dw	$0000
		endl
catch:		dw	handler
		db	$05
		db	'CATCH'
catch_xt:	local
		jp	!docol__xt
		dw	!sp_fetch_xt
		dw	!to_r_xt
;		dw	!fp_fetch_xt
;		dw	!to_r_xt
		dw	!handler_xt
		dw	!fetch_xt
		dw	!to_r_xt
		dw	!rp_fetch_xt
		dw	!handler_xt
		dw	!store_xt
		dw	!execute_xt
		dw	!r_from_xt
		dw	!handler_xt
		dw	!store_xt
		dw	!r_from_drop_xt
		dw	!dolit__xt
		dw	$0000
		dw	!doexit__xt
		endl
throw:		dw	catch
		db	$05
		db	'THROW'
throw_xt:	local
		jp	!docol__xt
		dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!handler_xt
			dw	!fetch_xt
			dw	!rp_store_xt
			dw	!r_from_xt
			dw	!handler_xt
			dw	!store_xt
;			dw	!r_from_xt
;			dw	!fp_store_xt
			dw	!r_from_xt
			dw	!swap_xt
			dw	!to_r_xt
			dw	!sp_store_xt
			dw	!drop_xt
			dw	!r_from_xt
lbl2:		dw	!doexit__xt
		endl
state:		dw	throw
		db	$05
		db	'STATE'
state_xt:	local
		jp	!dovar__xt
		dw	$0000
		endl
quest_comp:	dw	state
		db	$05
		db	'?COMP'
quest_comp_xt:	local
		jp	!docol__xt
		dw	!state_xt
		dw	!fetch_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!doexit__xt
lbl2:		dw	!dolit__xt
		dw	-14			; Interpreting a compile-only word
		dw	!throw_xt
		dw	!doexit__xt
		endl
quit:		dw	quest_comp
		db	$04
		db	'QUIT'
quit_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	-56
		dw	!throw_xt
		dw	!doexit__xt
		endl
abort:		dw	quit
		db	$05
		db	'ABORT'
abort_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	-1
		dw	!throw_xt
		dw	!doexit__xt
		endl
abort_qte_:	dw	abort
		db	$88
		db	'(ABORT")'
abort_qte__xt:	local
		jp	!docol__xt
		dw	!rot_xt
		dw	!if__xt
		dw	lbl5-lbl1
lbl1:			dw	!handler_xt
			dw	!fetch_xt
			dw	!fetch_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!two_drop_xt
			dw	!ahead__xt
			dw	lbl4-lbl3
lbl3:				dw	!type_xt
lbl4:			dw	!dolit__xt
			dw	-2
			dw	!throw_xt
lbl5:		dw	!two_drop_xt
		dw	!doexit__xt
		endl
abort_quote:	dw	abort_qte_
		db	$86
		db	'ABORT"'
abort_quote_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!s_quote_xt
		dw	!dolit__xt
		dw	!abort_qte__xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
colon_sys_:	dw	abort_quote
		db	$0b
		db	'(COLON-SYS)'
colon_sys__xt:	local
		jp	!docon__xt
		dw	8334			; 'colon-sys' magic number
		endl
orig_:		dw	colon_sys_
		db	$06
		db	'(ORIG)'
orig__xt:	local
		jp	!docon__xt
		dw	7328			; 'orig' magic number
		endl
dest_:		dw	orig_
		db	$06
		db	'(DEST)'
dest__xt:	local
		jp	!docon__xt
		dw	2194			; 'dest' magic number
		endl
do_sys_:	dw	dest_
		db	$08
		db	'(DO-SYS)'
do_sys__xt:	local
		jp	!docon__xt
		dw	6973			; 'do-sys' magic number
		endl
cs_push:	dw	do_sys_
		db	$07
		db	'CS-PUSH'
cs_push_xt:	local
		jp	!docol__xt		; Does nothing
		dw	!doexit__xt		; (since the C stack is the data stack in this implementation)
		endl
cs_pop:		dw	cs_push
		db	$06
		db	'CS-POP'
cs_pop_xt:	local
		jp	!docol__xt		; Does nothing
		dw	!doexit__xt		; (since the C stack is the data stack in this implementation)
		endl
cs_drop:	dw	cs_pop
		db	$07
		db	'CS-DROP'
cs_drop_xt:	local
		jp	!docol__xt
		dw	!two_drop_xt
		dw	!doexit__xt
		endl
cs_pick:	dw	cs_drop
		db	$07
		db	'CS-PICK'
cs_pick_xt:	local
		jp	!docol__xt
		dw	!two_star_xt
		dw	!one_plus_xt
		dw	!dup_to_r_xt
		dw	!pick_xt
		dw	!r_from_xt
		dw	!pick_xt
		dw	!doexit__xt
		endl
cs_roll:	dw	cs_pick
		db	$07
		db	'CS-ROLL'
cs_roll_xt:	local
		jp	!docol__xt
		dw	!two_star_xt
		dw	!one_plus_xt
		dw	!dup_to_r_xt
		dw	!roll_xt
		dw	!r_from_xt
		dw	!roll_xt
		dw	!doexit__xt
		endl
last:		dw	cs_roll
		db	$04
		db	'LAST'
last_xt:	local
		jp	!dovar__xt
		dw	!startup		; The value of the last compiled definition
		endl
lastxt:		dw	last
		db	$07
		db	'LAST-XT'
lastxt_xt:	local
		jp	!dovar__xt
		dw	!startup_xt		; The value of the last compiled XT
		endl
left_brkt:	dw	lastxt
		db	$81
		db	'['
left_brkt_xt:	local
		jp	!docol__xt
		dw	!state_xt
		dw	!off_xt
		dw	!doexit__xt
		endl
right_brkt:	dw	left_brkt
		db	$01
		db	']'
right_brkt_xt:	local
		jp	!docol__xt
		dw	!state_xt
		dw	!on_xt
		dw	!doexit__xt
		endl
cfa_comma:	dw	right_brkt
		db	$04
		db	'CFA,'
cfa_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	(!el),$02
		mv	[y++],(!el)		; Compile 'jp'
		mv	[y++],ba		; Compile the address of the interpretation routine
		mv	(!wi),y			; Save new HERE value
		popu	ba			; Set new TOS
		jp	!interp__
		endl
does_comma:	dw	cfa_comma
		db	$05
		db	'DOES,'
does_comma_xt:	local
		mv	y,(!wi)			; Y holds HERE value
		mv	(!el),$04
		mv	[y++],(!el)		; Compile 'call'
		mvw	(!ex),!does__xt
		mvw	[y++],(!ex)		; Compile the address of the dodoes routine
		mv	(!wi),y			; Save new HERE value
		jp	!interp__
		endl
hide:		dw	does_comma
		db	$04
		db	'HIDE'
hide_xt:	local
		jp	!docol__xt
		dw	!last_xt
		dw	!fetch_xt
		dw	!two_plus_xt
		dw	!dup_xt
		dw	!c_fetch_xt
		dw	!dolit__xt
		dw	$0040
		dw	!or_xt
		dw	!swap_xt
		dw	!c_store_xt
		dw	!doexit__xt
		endl
reveal:		dw	hide
		db	$06
		db	'REVEAL'
reveal_xt:	local
		jp	!docol__xt
		dw	!last_xt
		dw	!fetch_xt
		dw	!two_plus_xt
		dw	!dup_xt
		dw	!c_fetch_xt
		dw	!dolit__xt
		dw	$00bf
		dw	!and_xt
		dw	!swap_xt
		dw	!c_store_xt
		dw	!doexit__xt
		endl
immediate:	dw	reveal
		db	$09
		db	'IMMEDIATE'
immediate_xt:	local
		jp	!docol__xt
		dw	!last_xt
		dw	!fetch_xt
		dw	!two_plus_xt
		dw	!dup_xt
		dw	!c_fetch_xt
		dw	!dolit__xt
		dw	$0080
		dw	!or_xt
		dw	!swap_xt
		dw	!c_store_xt
		dw	!doexit__xt
		endl
fib:		dw	immediate
		db	$03
		db	'FIB'
fib_xt:		local
		jp	!dovar__xt
		ds	!ib_size
		endl
tib:		dw	fib
		db	$03
		db	'TIB'
tib_xt:		local
		jp	!dovar__xt
		ds	!ib_size
		endl
to_in:		dw	tib
		db	$03
		db	'>IN'
to_in_xt:	local
		jp	!dovar__xt
		dw	$0000			; The offset in characters from the beginning of the
		endl				; input buffer to the current position
source_id:	dw	to_in
		db	$09
		db	'SOURCE-ID'
source_id_xt:	local
		jp	!doval__xt
		dw	$0000
		endl
source_:	dw	source_id
		db	$08
		db	'(SOURCE)'
source__xt:	local
		jp	!dovar__xt
		dw	0			; The number of characters in the input buffer
		dw	!tib_xt+3		; The address of the input buffer
		endl
source:		dw	source_
		db	$06
		db	'SOURCE'
source_xt:	local
		jp	!docol__xt
		dw	!source__xt
		dw	!two_fetch_xt
		dw	!doexit__xt
		endl
parse:		dw	source
		db	$05
		db	'PARSE'
parse_xt:	local
		mv	(!el),a			; Store separator
		pushs	x			; Save IP
		mv	y,!base_address		; Y holds the
		mv	ba,[!source__xt+5]	; address of the
		add	y,ba			; input buffer
		mv	ba,[!to_in_xt+3]	; Number of previously parsed characters
		add	y,ba			; Address of the first character to parse
		mv	i,y			; Truncate it to 16 bits
		pushu	i			; Save it to the stack
		mv	x,0			; The number of parsed valid charaters
		mv	i,[!source__xt+3]	; Size of the input buffer
		sub	i,ba			; Compute the number of characters that remains within the buffer
		jrz	lbl4
		cmp	(!el),$20		; Is the submited separator a blank?
		jrz	lbl2
lbl1:		mv	a,[y++]			; Parse next character
		cmp	(!el),a			; Is it the end of a word? (only character whose
		jrz	lbl5			; value is equal to the submitted character is a valid separator)
		inc	x			; Increment the number of parsed valid charaters
		dec	i			; Count the number of remaining characters
		jrnz	lbl1
		jr	lbl3
lbl2:		mv	a,[y++]			; Parse next character
		cmp	a,$21			; Is it the end of a word? (every character whose
		jrc	lbl5			; value is lower than $20 is a valid separator)
		inc	x			; Increment the number of parsed valid charaters
		dec	i			; Count the number of remaining characters
		jrnz	lbl2
lbl3:		mv	ba,[!source__xt+3]	; Compute the new
		sub	ba,i			; >IN value
		mv	[!to_in_xt+3],ba	; Update >IN
lbl4:		mv	ba,x			; Set new TOS (the number of parsed valid characters)
		pops	x			; Restore IP
		rc
		jp	!interp__
lbl5:		dec	i			; Discard the separator
		jr	lbl3
		endl
skip_seps:	dw	parse
		db	$0f
		db	'SKIP-SEPARATORS'
skip_seps_xt:	local
		mv	(!el),a			; Save TOS
		mv	y,!base_address		; Y holds the
		mv	ba,[!source__xt+5]	; address of the
		add	y,ba			; input buffer
		mv	ba,[!to_in_xt+3]	; Number of previously parsed characters
		add	y,ba			; Address of the first character to parse
		mv	i,[!source__xt+3]	; Size of the input buffer
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
lbl3:		mv	ba,[!source__xt+3]	; Compute the new
		sub	ba,i			; >IN value
		mv	[!to_in_xt+3],ba	; Update >IN
lbl4:		popu	ba			; Set new TOS
		jp	!interp__
		endl
parse_word:	dw	skip_seps
		db	$0a
		db	'PARSE-WORD'
parse_word_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!skip_seps_xt
		dw	!parse_xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	$00ff
		dw	!u_grtr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-18		; Parsed string overflow
			dw	!throw_xt
lbl2:		dw	!doexit__xt
		endl
word:		dw	parse_word
		db	$04
		db	'WORD'
word_xt:	local
		jp	!docol__xt
		dw	!parse_word_xt
		dw	!here_xt
		dw	!two_dup_xt
		dw	!c_store_xt
		dw	!char_plus_xt
		dw	!swap_xt
		dw	!c_move_xt
		dw	!here_xt
		dw	!doexit__xt
		endl
count:		dw	word
		db	$05
		db	'COUNT'
count_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!char_plus_xt
		dw	!swap_xt
		dw	!c_fetch_xt
		dw	!doexit__xt
		endl
link_:		dw	count
		db	$06
		db	'(LINK)'
link__xt:	local
		jp	!docol__xt
		dw	!here_xt
		dw	!last_xt		; Pointer to last definition
		dw	!fetch_xt
		dw	!comma_xt
		dw	!last_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
check_name:	dw	link_
		db	$0a
		db	'CHECK-NAME'
check_name_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!zero_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-16		; Attempt to use a zero-length string as a name
			dw	!throw_xt
lbl2:		dw	!dup_xt
		dw	!dolit__xt
		dw	31
		dw	!u_grtr_than_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!dolit__xt
			dw	-19		; Definition name too long
			dw	!throw_xt
lbl4:		dw	!doexit__xt
		endl
name_:		dw	check_name
		db	$06
		db	'(NAME)'
name__xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!c_comma_xt		; Length and control bits
		dw	!here_xt
		dw	!swap_xt
		dw	!dup_xt
		dw	!chars_xt
		dw	!allot_xt
		dw	!c_move_xt
		dw	!doexit__xt
		endl
create_hdr:	dw	name_
		db	$0d
		db	'CREATE-HEADER'
create_hdr_xt:	local
		jp	!docol__xt
		dw	!blnk_xt
		dw	!parse_word_xt
		dw	!check_name_xt
		dw	!link__xt
		dw	!name__xt
		dw	!here_xt
		dw	!lastxt_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
noname_:	dw	create_hdr
		db	$09
		db	'(:NONAME)'
noname__xt:	local
		jp	!docol__xt
		dw	!right_brkt_xt
		dw	!here_xt
		dw	!colon_sys__xt
		dw	!cs_push_xt
		dw	!dolit__xt
		dw	!docol__xt
		dw	!cfa_comma_xt
		dw	!doexit__xt
		endl
noname:		dw	noname_
		db	$07
		db	':NONAME'
noname_xt:	local
		jp	!docol__xt
		dw	!here_xt
		dw	!dup_xt
		dw	!lastxt_xt
		dw	!store_xt
		dw	!noname__xt
		dw	!doexit__xt
		endl
colon:		dw	noname
		db	$01
		db	':'
colon_xt:	local
		jp	!docol__xt
		dw	!create_hdr_xt
		dw	!hide_xt
		dw	!noname__xt
		dw	!doexit__xt
		endl
semi_colon:	dw	colon
		db	$81
		db	';'
semi_colon_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!cs_pop_xt
		dw	!colon_sys__xt
		dw	!not_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-22		; Control structure mismatch
			dw	!throw_xt		
lbl2:		dw	!drop_xt
		dw	!dolit__xt
		dw	!doexit__xt
		dw	!compile_com_xt
		dw	!reveal_xt
		dw	!left_brkt_xt
		dw	!doexit__xt
		endl
create:		dw	semi_colon
		db	$06
		db	'CREATE'
create_xt:	local
		jp	!docol__xt
		dw	!create_hdr_xt
		dw	!dolit__xt
		dw	!dovar__xt
		dw	!cfa_comma_xt
		dw	!doexit__xt
		endl
creat_nonam:	dw	create
		db	$0d
		db	'CREATE-NONAME'
creat_nonam_xt:	local
		jp	!docol__xt
		dw	!here_xt
		dw	!dup_xt
		dw	!lastxt_xt
		dw	!store_xt
		dw	!dolit__xt
		dw	!dovar__xt
		dw	!cfa_comma_xt
		dw	!doexit__xt
		endl
does:		dw	creat_nonam
		db	$85
		db	'DOES>'
does_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!sc_code__xt
		dw	!compile_com_xt
		dw	!does_comma_xt
		dw	!doexit__xt
		endl
constant:	dw	does
		db	$08
		db	'CONSTANT'
constant_xt:	local
		jp	!docol__xt
		dw	!create_hdr_xt
		dw	!dolit__xt
		dw	!docon__xt
		dw	!cfa_comma_xt
		dw	!comma_xt
		dw	!doexit__xt
		endl
two_const:	dw	constant
		db	$09
		db	'2CONSTANT'
two_const_xt:	local
		jp	!docol__xt
		dw	!create_hdr_xt
		dw	!dolit__xt
		dw	!do2con__xt
		dw	!cfa_comma_xt
		dw	!two_comma_xt
		dw	!doexit__xt
		endl
variable:	dw	two_const
		db	$08
		db	'VARIABLE'
variable_xt:	local
		jp	!docol__xt
		dw	!create_xt
		dw	!dolit__xt
		dw	$0000
		dw	!comma_xt
		dw	!doexit__xt
		endl
two_variabl:	dw	variable
		db	$09
		db	'2VARIABLE'
two_variabl_xt:	local
		jp	!docol__xt
		dw	!create_xt
		dw	!do2lit__xt
		dw	$0000
		dw	$0000
		dw	!two_comma_xt
		dw	!doexit__xt
		endl
value:		dw	two_variabl
		db	$05
		db	'VALUE'
value_xt:	local
		jp	!docol__xt
		dw	!create_hdr_xt
		dw	!dolit__xt
		dw	!doval__xt
		dw	!cfa_comma_xt
		dw	!comma_xt
		dw	!doexit__xt
		endl
value_quest:	dw	value
		db	$06
		db	'VALUE?'
value_quest_xt:	local
		mv	y,!base_address		; Compute the address
		add	y,ba			; code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a doval ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	i,!doval__xt		; Compare it with
		sub	ba,i			; the doval execution token
		jrnz	lbl2
		mv	ba,$ffff		; Set new TOS to TRUE
lbl1:		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		jr	lbl1
		endl
to:		dw	value_quest
		db	$82
		db	'TO'
to_xt:		local
		jp	!docol__xt
		dw	!tick_xt
		dw	!dup_xt
		dw	!value_quest_xt
		dw	!if__xt
		dw	lbl4-lbl1
lbl1:			dw	!to_body_xt
			dw	!state_xt
			dw	!fetch_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!dolit__xt
				dw	!doto__xt
				dw	!compile_com_xt
				dw	!comma_xt
				dw	!doexit__xt

lbl3:			dw	!store_xt
			dw	!doexit__xt
lbl4:		dw	!dolit__xt
		dw	-32			; Invalid name argument
		dw	!throw_xt
		dw	!doexit__xt
		endl
plus_to:	dw	to
		db	$83
		db	'+TO'
plus_to_xt:	local
		jp	!docol__xt
		dw	!tick_xt
		dw	!dup_xt
		dw	!value_quest_xt
		dw	!if__xt
		dw	lbl4-lbl1
lbl1:			dw	!to_body_xt
			dw	!state_xt
			dw	!fetch_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!dolit__xt
				dw	!doplusto__xt
				dw	!compile_com_xt
				dw	!comma_xt
				dw	!doexit__xt

lbl3:			dw	!plus_store_xt
			dw	!doexit__xt
lbl4:		dw	!dolit__xt
		dw	-32			; Invalid name argument
		dw	!throw_xt
		dw	!doexit__xt
		endl
uninit_:	dw	plus_to
		db	$08
		db	'(UNINIT)'
uninit__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	-59			; Execution of an uninitialized deferred word
		dw	!throw_xt
		dw	!doexit__xt
		endl
defer:		dw	uninit_
		db	$05
		db	'DEFER'
defer_xt:	local
		jp	!docol__xt
		dw	!create_hdr_xt
		dw	!dolit__xt
		dw	!dodefer__xt
		dw	!cfa_comma_xt
		dw	!dolit__xt
		dw	!uninit__xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
defer_quest:	dw	defer
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
		sub	ba,i			; the dodefer execution token
		jrnz	lbl2
		mv	ba,$ffff		; Set new TOS to TRUE
lbl1:		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		jr	lbl1
		endl
is:		dw	defer_quest
		db	$82
		db	'IS'
is_xt:		local
		jp	!docol__xt
		dw	!tick_xt
		dw	!dup_xt
		dw	!defer_quest_xt
		dw	!if__xt
		dw	lbl4-lbl1
lbl1:			dw	!to_body_xt
			dw	!state_xt
			dw	!fetch_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!dolit__xt
				dw	!dois__xt
				dw	!compile_com_xt
				dw	!comma_xt
				dw	!doexit__xt

lbl3:			dw	!store_xt
			dw	!doexit__xt
lbl4:		dw	!dolit__xt
		dw	-32			; Invalid name argument
		dw	!throw_xt
		dw	!doexit__xt
		endl
behavior_:	dw	is
		db	$0a
		db	'(BEHAVIOR)'
behavior__xt:	local
		mv	y,!base_address+3
		add	y,ba
		mv	ba,[y]
		jp	!interp__
		endl
behavior:	dw	behavior_
		db	$08
		db	'BEHAVIOR'
behavior_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!defer_quest_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!behavior__xt
			dw	!doexit__xt
lbl2:		dw	!dolit__xt
		dw	-24			; Invalid numeric argument
		dw	!throw_xt
		dw	!doexit__xt
		endl
colon_quest:	dw	behavior
		db	$06
		db	'COLON?'
colon_quest_xt:	local
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a docol ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	i,!docol__xt		; Compare it with
		sub	ba,i			; the dodefer execution token
		jrnz	lbl2
		mv	ba,$ffff		; Set new TOS to TRUE
lbl1:		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		jr	lbl1
		endl
does_quest:	dw	colon_quest
		db	$06
		db	'DOES>?'
does_quest_xt:	local
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the code field routine
		mv	a,[y++]			; Test the nature of the word
		cmp	a,$02			; (is it a call to a does ?)
		jrnz	lbl2
		mv	ba,[y]			; Read the address of the code field routine
		mv	y,!base_address		; Compute the address of the
		add	y,ba			; address of the does routine
		mv	a,[y++]			; Test if it
		cmp	a,$04			; is a
		jrnz	lbl2			; call
		mv	ba,[y]			; to the
		mv	i,!does__xt		; (does)
		sub	ba,i			; execution token
		jrnz	lbl2
		mv	ba,$ffff		; Set new TOS to TRUE
lbl1:		rc
		jp	!interp__
lbl2:		mv	ba,$0000		; Set new TOS to FALSE
		jr	lbl1
		endl
marker:		dw	does_quest
		db	$06
		db	'MARKER'
marker_xt:	local
		jp	!docol__xt
		dw	!here_xt
		dw	!lastxt_xt
		dw	!fetch_xt
		dw	!last_xt
		dw	!fetch_xt
		dw	!create_xt
		dw	!comma_xt
		dw	!comma_xt
		dw	!comma_xt
		dw	!sc_code__xt		; Compiled by DOES>
marker_bhvr_xt:	call	!does__xt
		dw	!dup_xt
		dw	!fetch_xt
		dw	!last_xt
		dw	!store_xt
		dw	!cell_plus_xt
		dw	!dup_xt
		dw	!fetch_xt
		dw	!lastxt_xt
		dw	!store_xt
		dw	!cell_plus_xt
		dw	!fetch_xt
		dw	!here_xt
		dw	!minus_xt
		dw	!allot_xt
		dw	!doexit__xt
		endl
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
		jrnz	lbl2
		mv	ba,$ffff
lbl1:		rc
		jp	!interp__
lbl2:		mv	ba,$0000
		jr	lbl1
		endl
recurse:	dw	marker_qust
		db	$87
		db	'RECURSE'
recurse_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!lastxt_xt
		dw	!fetch_xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
recursive:	dw	recurse
		db	$89
		db	'RECURSIVE'
recursive_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!reveal_xt
		dw	!doexit__xt
		endl
ahead:		dw	recursive
		db	$85
		db	'AHEAD'
ahead_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!ahead__xt
		dw	!compile_com_xt
		dw	!here_xt
		dw	!orig__xt
		dw	!cs_push_xt
		dw	!dolit__xt
		dw	$0000
		dw	!comma_xt
		dw	!doexit__xt
		endl
begin:		dw	ahead
		db	$85
		db	'BEGIN'
begin_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!here_xt
		dw	!dest__xt
		dw	!cs_push_xt
		dw	!doexit__xt
		endl
again:		dw	begin
		db	$85
		db	'AGAIN'
again_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!again__xt
		dw	!compile_com_xt
		dw	!cs_pop_xt
		dw	!dest__xt
		dw	!not_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-22		; Control structure mismatch
			dw	!throw_xt
lbl2:		dw	!here_xt
		dw	!swap_xt		; Avoid errors if C stack and data stack are the same
		dw	!minus_xt
		dw	!two_plus_xt
		dw	!comma_xt
		dw	!doexit__xt
		endl
until:		dw	again
		db	$85
		db	'UNTIL'
until_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!until__xt
		dw	!compile_com_xt
		dw	!cs_pop_xt
		dw	!dest__xt
		dw	!not_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-22		; Control structure mismatch
			dw	!throw_xt
lbl2:		dw	!here_xt
		dw	!swap_xt		; Avoid errors if C stack and data stack are the same
		dw	!minus_xt
		dw	!two_plus_xt
		dw	!comma_xt
		dw	!doexit__xt
		endl
if:		dw	until
		db	$82
		db	'IF'
if_xt:		local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!if__xt
		dw	!compile_com_xt
		dw	!here_xt
		dw	!orig__xt
		dw	!cs_push_xt
		dw	!dolit__xt
		dw	$0000
		dw	!comma_xt
		dw	!doexit__xt
		endl
then:		dw	if
		db	$84
		db	'THEN'
then_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!cs_pop_xt
		dw	!orig__xt
		dw	!not_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-22		; Control structure mismatch
			dw	!throw_xt		
lbl2:		dw	!here_xt
		dw	!over_xt		; Avoid errors if C stack and data stack are the same
		dw	!minus_xt
		dw	!two_minus_xt
		dw	!swap_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
while:		dw	then
		db	$85
		db	'WHILE'
while_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!if_xt
		dw	!dolit__xt
		dw	$0001
		dw	!cs_roll_xt
		dw	!doexit__xt
		endl
repeat:		dw	while
		db	$86
		db	'REPEAT'
repeat_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!again_xt
		dw	!then_xt
		dw	!doexit__xt
		endl
else:		dw	repeat
		db	$84
		db	'ELSE'
else_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!ahead_xt
		dw	!dolit__xt
		dw	$0001
		dw	!cs_roll_xt
		dw	!then_xt
		dw	!doexit__xt
		endl
do:		dw	else
		db	$82
		db	'DO'
do_xt:		local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!do__xt
		dw	!compile_com_xt
		dw	!here_xt
		dw	!do_sys__xt
		dw	!cs_push_xt
		dw	!dolit__xt
		dw	$0000
		dw	!comma_xt
		dw	!doexit__xt
		endl
quest_do:	dw	do
		db	$83
		db	'?DO'
quest_do_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!quest_do__xt
		dw	!compile_com_xt
		dw	!here_xt
		dw	!do_sys__xt
		dw	!cs_push_xt
		dw	!dolit__xt
		dw	$0000
		dw	!comma_xt
		dw	!doexit__xt
		endl
loop:		dw	quest_do
		db	$84
		db	'LOOP'
loop_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!loop__xt
		dw	!compile_com_xt
		dw	!cs_pop_xt
		dw	!do_sys__xt
		dw	!not_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-22		; Control structure mismatch
			dw	!throw_xt
lbl2:		dw	!here_xt
		dw	!over_xt		; Avoid errors if C stack and data stack are the same
		dw	!minus_xt
		dw	!comma_xt
		dw	!here_xt
		dw	!swap_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
plus_loop:	dw	loop
		db	$85
		db	'+LOOP'
plus_loop_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!plus_loop__xt
		dw	!compile_com_xt
		dw	!cs_pop_xt
		dw	!do_sys__xt
		dw	!not_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-22		; Control structure mismatch
			dw	!throw_xt
lbl2:		dw	!here_xt
		dw	!over_xt		; Avoid errors if C stack and data stack are the same
		dw	!minus_xt
		dw	!comma_xt
		dw	!here_xt
		dw	!swap_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
unloop:		dw	plus_loop
		db	$86
		db	'UNLOOP'
unloop_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!unloop__xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
leave:		dw	unloop
		db	$85
		db	'LEAVE'
leave_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!leave__xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
qst_leave:	dw	leave
		db	$86
		db	'?LEAVE'
qst_leave_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!qst_leave__xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
case:		dw	qst_leave
		db	$84
		db	'CASE'
case_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	$0000
		dw	!doexit__xt
		endl
of:		dw	case
		db	$82
		db	'OF'
of_xt:		local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!one_plus_xt
		dw	!to_r_xt
		dw	!dolit__xt
		dw	!over_xt
		dw	!compile_com_xt
		dw	!dolit__xt
		dw	!equals_xt
		dw	!compile_com_xt
		dw	!if_xt
		dw	!dolit__xt
		dw	!drop_xt
		dw	!compile_com_xt
		dw	!r_from_xt
		dw	!doexit__xt
		endl
endof:		dw	of
		db	$85
		db	'ENDOF'
endof_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!to_r_xt
		dw	!else_xt
		dw	!r_from_xt
		dw	!doexit__xt
		endl
endcase:	dw	endof
		db	$87
		db	'ENDCASE'
endcase_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!drop_xt
		dw	!compile_com_xt
		dw	!dolit__xt
		dw	$0000
		dw	!quest_do__xt
		dw	lbl2
lbl1:			dw	!then_xt
		dw	!loop__xt
		dw	lbl2-lbl1
lbl2:		dw	!doexit__xt
		endl
;succeed:	dw	endcase
;		db	$87
;		db	'SUCCEED'
;succeed_xt:	local
;		jp	!docol__xt
;		dw	!quest_comp_xt
;		dw	!dolit__xt
;		dw	!succeed__xt
;		dw	!compile_com_xt
;		dw	!doexit__xt
;		endl
;fail:		dw	succeed
;		db	$84
;		db	'FAIL'
;fail_xt:	local
;		jp	!docol__xt
;		dw	!quest_comp_xt
;		dw	!dolit__xt
;		dw	!fail__xt
;		dw	!compile_com_xt
;		dw	!doexit__xt
;		endl
exit:		dw	endcase
		db	$84
		db	'EXIT'
exit_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!doexit__xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
literal:	dw	exit
		db	$87
		db	'LITERAL'
literal_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!dolit__xt
		dw	!compile_com_xt
		dw	!comma_xt
		dw	!doexit__xt
		endl
two_literal:	dw	literal
		db	$88
		db	'2LITERAL'
two_literal_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!do2lit__xt
		dw	!compile_com_xt
		dw	!two_comma_xt
		dw	!doexit__xt
		endl
sliteral:	dw	two_literal
		db	$88
		db	'SLITERAL'
sliteral_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	!doslit__xt
		dw	!compile_com_xt
		dw	!dup_xt
		dw	!comma_xt
		dw	!here_xt
		dw	!over_xt
		dw	!chars_xt
		dw	!allot_xt
		dw	!swap_xt
		dw	!c_move_xt
		dw	!doexit__xt
		endl
dot_quote:	dw	sliteral
		db	$82
		db	'."'
dot_quote_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	$0022			; The value of the quote character
		dw	!parse_xt
		dw	!sliteral_xt
		dw	!dolit__xt
		dw	!type_xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
s_quote:	dw	dot_quote
		db	$82
		db	'S"'
s_quote_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0022			; The value of the quote character
		dw	!parse_xt
		dw	!state_xt
		dw	!fetch_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!sliteral_xt
			dw	!doexit__xt
lbl2:		dw	!which_pockt_xt
		dw	!swap_xt
		dw	!two_dup_xt
		dw	!two_to_r_xt
		dw	!c_move_xt
		dw	!two_r_from_xt
		dw	!doexit__xt
		endl
c_quote:	dw	s_quote
		db	$82
		db	'C"'
c_quote_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!dolit__xt
		dw	$0022			; The value of the quote character
		dw	!parse_xt
		dw	!dolit__xt
		dw	!doslit__xt
		dw	!compile_com_xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	$00ff
		dw	!u_grtr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-18		; Parsed string overflow
			dw	!throw_xt
lbl2:		dw	!dup_xt
		dw	!dup_xt
		dw	!one_plus_xt
		dw	!comma_xt
		dw	!c_comma_xt
		dw	!here_xt
		dw	!over_xt
		dw	!chars_xt
		dw	!allot_xt
		dw	!swap_xt
		dw	!c_move_xt
		dw	!dolit__xt
		dw	!drop_xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
l_to_name:	dw	c_quote
		db	$06
		db	'L>NAME'
l_to_name_xt:	local
		jp	!docol__xt
		dw	!two_plus_xt
		dw	!doexit__xt
		endl
name_to_str:	dw	l_to_name
		db	$0b
		db	'NAME>STRING'
name_to_str_xt:	local
		jp	!docol__xt
		dw	!count_xt
		dw	!dolit__xt
		dw	$001f
		dw	!and_xt
		dw	!doexit__xt
		endl
name_from:	dw	name_to_str
		db	$05
		db	'NAME>'
name_from_xt:	local
		jp	!docol__xt
		dw	!name_to_str_xt
		dw	!plus_xt
		dw	!doexit__xt
		endl
to_name:	dw	name_from
		db	$05
		db	'>NAME'
to_name_xt:	local
		pushs	x			; Save IP
		mv	y,!base_address
		mv	x,y
		add	y,ba			; Y holds the searched xt
		dec	y			; Take account
		dec	y			; of the offset
		dec	y			; from the beginning of the definition (to the name)
		mv	ba,[!last_xt+3]
		add	x,ba			; X holds the address of the last definition
lbl1:		mv	a,[x+2]			; Store length and control bits
		test	a,$40			; Test if smudge bit is on
		jrz	lbl3
lbl2:		mv	ba,[x]			; Jump to the next word
		mv	x,!base_address
		add	x,ba
		dec	ba			; Test if the beginning
		inc	ba			; of the dictionary was reached
		jrnz	lbl1
		mv	ba,-24			; Invalid numeric argument
		mv	i,!throw_xt
		rc
		jp	!throw_xt
lbl3:		mv	(!zi),x			; Save the address of the next word to search
		and	a,$2f			; Discard control bits
		add	x,a			; X holds the current xt
		sub	x,y
		jrz	lbl5
lbl4:		mv	x,(!zi)			; Restore the address of the next word to search
		jr	lbl2
lbl5:		mv	ba,(!zi)		; Set new TOS
		inc	ba			;
		inc	ba			;
		pops	x			; Restore IP
		rc
		jp	!interp__
		endl
to_body:	dw	to_name
		db	$05
		db	'>BODY'
to_body_xt:	local
		mv	il,3
		add	ba,il
		jp	!interp__
		endl
find_word:	dw	to_body
		db	$09
		db	'FIND-WORD'
find_word_xt:	local
		pushs	x			; Save IP
		mv	y,!base_address
		mv	x,y
		mv	i,ba			; I holds the length of the searched string
		popu	ba
		add	y,ba			; Y holds the address of the counted string
		mv	ba,[!last_xt+3]
		add	x,ba			; X holds the address of the last definition
lbl1:		mv	a,[x+2]			; Store length and control bits
		test	a,$40			; Test if smudge bit is on
		jrnz	lbl2
		and	a,$3f			; Discard control bits
		sub	a,il			; Are lengths the same?
		jrz	lbl3
lbl2:		mv	ba,[x]			; Jump to the next word
		mv	x,!base_address
		add	x,ba
		dec	ba			; Test if the beginning
		inc	ba			; of the dictionary was reached
		jrnz	lbl1
		mv	ba,$0000		; Set new TOS (word not found)
		pushu	ba			; Push an invalid execution token on the stack
		jr	lbl7
lbl3:		mv	(!zi),x			; Save the address of the next word to search
		inc	x
		inc	x
		inc	x			; X holds the address of the current string
		pushu	il			; Save the length of the searched string
		pushu	y			; Save the address of the searched string
		mv	(!el),il
lbl4:		mv	il,[x++]		; Read next character of the current word string
		mv	a,[y++]			; Read next character of the searched string
		sub	il,a			; Compare the characters
		jrz	lbl5
		popu	y			; Restore the address of the searched string
		popu	il			; Restore the length of the searched string
		mv	x,(!zi)			; Restore the address of the next word to search
		jr	lbl2
lbl5:		dec	(!el)
		jrnz	lbl4
		popu	y			; Clean up the stack and
		popu	a			; store the length of the searched string into A 
		mv	x,(!zi)			; Restore the address of the next word to search
		mv	i,x
		add	i,a
		mv	a,3			; Add the offset from the beginning of the definition
		add	i,a			; to the beginning of the code
		pushu	i
		mv	a,[x+2]
		test	a,$80			; Test immediacy
		jrz	lbl6
		mv	ba,$0001		; Set new TOS (word is immediate)
		jr	lbl7
lbl6:		mv	ba,$ffff		; Set new TOS (word is not immediate)
lbl7:		pops	x			; Restore IP
		rc
		jp	!interp__
		endl
find:		dw	find_word
		db	$04
		db	'FIND'
find_xt:	local
		jp	!docol__xt
		dw	!dup_to_r_xt
		dw	!count_xt
		dw	!find_word_xt
		dw	!dup_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!r_from_drop_xt
			dw	!doexit__xt
lbl2:		dw	!nip_xt
		dw	!r_from_xt
		dw	!swap_xt
		dw	!doexit__xt
		endl
tick_:		dw	find
		db	$03
		db	'('')'
tick__xt:	local
		jp	!docol__xt
		dw	!blnk_xt
		dw	!parse_word_xt
		dw	!find_word_xt
		dw	!doexit__xt
		endl
tick:		dw	tick_
		db	$01
		db	''''
tick_xt:	local
		jp	!docol__xt
		dw	!tick__xt
		dw	!zero_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-13		; Undefined word exception
			dw	!throw_xt
lbl2:		dw	!doexit__xt
		endl
brkt_tick:	dw	tick
		db	$83
		db	'['']'
brkt_tick_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!tick_xt
		dw	!literal_xt
		dw	!doexit__xt
		endl
postpone:	dw	brkt_tick
		db	$88
		db	'POSTPONE'
postpone_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!tick__xt
		dw	!quest_dup_xt
		dw	!zero_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-13		; Undefined word exception
			dw	!throw_xt
lbl2:		dw	!zer_grt_thn_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!compile_com_xt
			dw	!doexit__xt
lbl4:		dw	!dolit__xt
		dw	!dolit__xt
		dw	!compile_com_xt
		dw	!compile_com_xt
		dw	!dolit__xt
		dw	!compile_com_xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
brkt_compil:	dw	postpone
		db	$89
		db	'[COMPILE]'
brkt_compil_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!tick_xt
		dw	!compile_com_xt
		dw	!doexit__xt
		endl
;fgt_limit:	dw	brkt_compil
;		db	$0
;		db	'FORGET-LIMIT'
;fgt_limit_xt:	local
;		jp	!docon__xt
;		dw	!_end_
;		endl
;forget:		dw	fgt_limit
;		db	$06
;		db	'FORGET'
;forget_xt:	local
;		jp	!docol__xt
;		dw	!tick_xt
;		dw	!dup_xt
;		dw	!fgt_limit_xt
;		dw	!u_less_than_xt
;		dw	!if__xt
;		dw	lbl2-lbl1
;lbl1:			dw	!dolit__xt
;			dw	-15		; Invalid FORGET
;			dw	!throw_xt
;lbl2:		dw	!dup_xt
;		dw	!to_name_xt
;		dw	!two_minus_xt
;		dw	!fetch_xt
;		dw	!dup_xt
;		dw	!last_xt
;		dw	!store_xt
;		dw	!l_to_name_xt
;		dw	!name_from_xt
;		dw	!lastxt_xt
;		dw	!store_xt
;		dw	!here_xt
;		dw	!minus_xt
;		dw	!allot_xt
;		dw	!doexit__xt
;		endl
char:		dw	brkt_compil
		db	$04
		db	'CHAR'
char_xt:	local
		jp	!docol__xt
		dw	!blnk_xt
		dw	!parse_word_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!c_fetch_xt
			dw	!doexit__xt
lbl2:		dw	!dolit__xt
		dw	-16			; Attempt to use zero-length string as a name
		dw	!throw_xt
		dw	!doexit__xt
		endl
brkt_char:	dw	char
		db	$86
		db	'[CHAR]'
brkt_char_xt:	local
		jp	!docol__xt
		dw	!quest_comp_xt
		dw	!char_xt
		dw	!literal_xt
		dw	!doexit__xt
		endl
dot_name:	dw	brkt_char
		db	$05
		db	'.NAME'
dot_name_xt:	local
		jp	!docol__xt
		dw	!name_to_str_xt
		dw	!type_xt
		dw	!space_xt
		dw	!doexit__xt
		endl
hp:		dw	dot_name
		db	$02
		db	'HP'
hp_xt:		local
		jp	!dovar__xt
		dw	$0000
		endl
less_nb_sgn:	dw	hp
		db	$02
		db	'<#'
less_nb_sgn_xt:	local
		jp	!docol__xt
		dw	!here_xt
		dw	!dolit__xt
		dw	40
		dw	!plus_xt
		dw	!hp_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
hold:		dw	less_nb_sgn
		db	$04
		db	'HOLD'
hold_xt:	local
		jp	!docol__xt
		dw	!hp_xt
		dw	!fetch_xt
		dw	!dup_xt
		dw	!here_xt
		dw	!u_less_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-17		; Pictured numeric output string overflow
			dw	!throw_xt
lbl2:		dw	!one_minus_xt
		dw	!dup_xt
		dw	!hp_xt
		dw	!store_xt
		dw	!c_store_xt
		dw	!doexit__xt
		endl
sign:		dw	hold
		db	$04
		db	'SIGN'
sign_xt:	local
		jp	!docol__xt
		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	$002d		; The value of '-'
			dw	!hold_xt
lbl2:		dw	!doexit__xt
		endl
nb_sgn_b:	dw	sign
		db	$02
		db	'#B'
nb_sgn_b_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!dolit__xt
		dw	$0000
		dw	!r_fetch_xt
		dw	!u_m_sl_mod_xt
		dw	!to_r_xt
		dw	!r_tick_ftch_xt
		dw	!u_m_sl_mod_xt
		dw	!swap_xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	9
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:		dw	!dolit__xt
		dw	7
		dw	!plus_xt
lbl2:		dw	!dolit__xt
		dw	$0030			; The value of '0'
		dw	!plus_xt
		dw	!hold_xt
		dw	!r_from_xt
		dw	!r_from_drop_xt
		dw	!doexit__xt
		endl
nb_sg_b_s:	dw	nb_sgn_b
		db	$03
		db	'#BS'
nb_sg_b_s_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
lbl1:			dw	!r_fetch_xt
			dw	!nb_sgn_b_xt
			dw	!two_dup_xt
			dw	!or_xt
			dw	!zero_equals_xt
		dw	!until__xt
lbl2:		dw	lbl2-lbl1+2
		dw	!r_from_drop_xt
		dw	!doexit__xt
		endl
nmbr_sign:	dw	nb_sg_b_s
		db	$01
		db	'#'
nmbr_sign_xt:	local
		jp	!docol__xt
		dw	!base_xt
		dw	!fetch_xt
		dw	!nb_sgn_b_xt
		dw	!doexit__xt
		endl
nmbr_sign_s:	dw	nmbr_sign
		db	$02
		db	'#S'
nmbr_sign_s_xt:	local
		jp	!docol__xt
		dw	!base_xt
		dw	!fetch_xt
		dw	!nb_sg_b_s_xt
		dw	!doexit__xt
		endl
nb_sgn_grtr:	dw	nmbr_sign_s
		db	$02
		db	'#>'
nb_sgn_grtr_xt:	local
		jp	!docol__xt
		dw	!two_drop_xt
		dw	!here_xt
		dw	!dolit__xt
		dw	40
		dw	!plus_xt
		dw	!hp_xt
		dw	!fetch_xt
		dw	!dup_xt
		dw	!minus_rot_xt
		dw	!minus_xt
		dw	!doexit__xt
		endl
base_dot:	dw	nb_sgn_grtr
		db	$05
		db	'BASE.'
base_dot_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!less_nb_sgn_xt
		dw	!swap_xt
		dw	!nb_sg_b_s_xt
		dw	!nb_sgn_grtr_xt
		dw	!type_xt
		dw	!space_xt
		dw	!doexit__xt
		endl
bin_dot:	dw	base_dot
		db	$04
		db	'BIN.'
bin_dot_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	2
		dw	!base_dot_xt
		dw	!doexit__xt
		endl
dec_dot:	dw	bin_dot
		db	$04
		db	'DEC.'
dec_dot_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	10
		dw	!base_dot_xt
		dw	!doexit__xt
		endl
hex_dot:	dw	dec_dot
		db	$04
		db	'HEX.'
hex_dot_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	16
		dw	!base_dot_xt
		dw	!doexit__xt
		endl
d_dot_:		dw	hex_dot
		db	$04
		db	'(D.)'
d_dot__xt:	local
		jp	!docol__xt
		dw	!tuck_xt
		dw	!d_abs_xt
		dw	!less_nb_sgn_xt
		dw	!nmbr_sign_s_xt
		dw	!rot_xt
		dw	!sign_xt
		dw	!nb_sgn_grtr_xt
		dw	!doexit__xt
		endl
d_dot:		dw	d_dot_
		db	$02
		db	'D.'
d_dot_xt:	local
		jp	!docol__xt
		dw	!d_dot__xt
		dw	!type_xt
		dw	!space_xt
		dw	!doexit__xt
		endl
d_dot_r:	dw	d_dot
		db	$03
		db	'D.R'
d_dot_r_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!d_dot__xt
		dw	!r_from_xt
		dw	!over_xt
		dw	!minus_xt
		dw	!spaces_xt
		dw	!type_xt
		dw	!doexit__xt
		endl
dot:		dw	d_dot_r
		db	$01
		db	'.'
dot_xt:		local
		jp	!docol__xt
		dw	!s_to_d_xt
		dw	!d_dot_xt
		dw	!doexit__xt
		endl
dot_r:		dw	dot
		db	$02
		db	'.R'
dot_r_xt:	local
		jp	!docol__xt
		dw	!to_r_xt
		dw	!s_to_d_xt
		dw	!r_from_xt
		dw	!d_dot_r_xt
		dw	!doexit__xt
		endl
u_dot:		dw	dot_r
		db	$02
		db	'U.'
u_dot_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!d_dot_xt
		dw	!doexit__xt
		endl
u_dot_r:	dw	u_dot
		db	$03
		db	'U.R'
u_dot_r_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!swap_xt
		dw	!d_dot_r_xt
		dw	!doexit__xt
		endl
n_dot_s:	dw	u_dot_r
		db	$03
		db	'N.S'
n_dot_s_xt:	local
		jp	!docol__xt
		dw	!depth_xt
		dw	!one_minus_xt
		dw	!min_xt
		dw	!dup_xt
		dw	!zer_grt_thn_xt
		dw	!if__xt
		dw	lbl4-lbl1
lbl1:			dw	!one_minus_xt
			dw	!dolit__xt
			dw	$0000
			dw	!swap_xt
			dw	!do__xt
			dw	lbl3
lbl2:				dw	!i_xt
				dw	!pick_xt
				dw	!dot_xt
			dw	!dolit__xt
			dw	-1
			dw	!plus_loop__xt
			dw	lbl3-lbl2
lbl3:			dw	!doexit__xt
lbl4:		dw	!drop_xt
		dw	!doexit__xt
		endl
dot_s:		dw	n_dot_s
		db	$02
		db	'.S'
dot_s_xt:	local
		jp	!docol__xt
		dw	!depth_xt
		dw	!n_dot_s_xt
		dw	!doexit__xt
		endl
question:	dw	dot_s
		db	$01
		db	'?'
question_xt:	local
		jp	!docol__xt
		dw	!fetch_xt
		dw	!dot_xt
		dw	!doexit__xt
		endl
dump:		dw	question
		db	$04
		db	'DUMP'
dump_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!quest_do__xt
		dw	lbl2
lbl1:			dw	!dup_xt
			dw	!c_fetch_xt
			dw	!hex_dot_xt
			dw	!char_plus_xt
		dw	!loop__xt
		dw	lbl2-lbl1
lbl2:		dw	!drop_xt
		dw	!doexit__xt
		endl
disp_word:	dw	dump
		db	$0c
		db	'DISPLAY-WORD'
disp_word_xt:	local
		jp	!docol__xt
		dw	!swap_xt
		dw	!l_to_name_xt
		dw	!name_to_str_xt
		dw	!rot_xt
		dw	!over_xt
		dw	!plus_xt
		dw	!one_plus_xt		; The size of a space after each word
		dw	!dup_xt
		dw	!dolit__xt
		dw	152			; 160 characters - the size of '(more) ' - 1
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!drop_xt
			dw	!dup_xt
			dw	!doslit__xt
			dw	6
			db	'(more)'
			dw	!rev_type_xt
			dw	!key_xt
			dw	!drop_xt
			dw	!page_xt
lbl2:		dw	!minus_rot_xt
		dw	!type_xt
		dw	!space_xt
		dw	!doexit__xt
		endl
words:		dw	disp_word
		db	$05
		db	'WORDS'
words_xt:	local
		jp	!docol__xt
		dw	!cr_xt
		dw	!blnk_xt
		dw	!parse_word_xt
		dw	!two_to_r_xt
		dw	!dolit__xt
		dw	0
		dw	!last_xt
		dw	!fetch_xt
lbl1:			dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl5-lbl2
lbl2:			dw	!dup_xt
			dw	!l_to_name_xt
			dw	!name_to_str_xt
			dw	!two_r_fetch_xt
			dw	!match_quest_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!dup_xt
				dw	!rot_xt
				dw	!disp_word_xt
				dw	!swap_xt
lbl4:			dw	!fetch_xt
		dw	!again__xt
		dw	lbl5-lbl1
lbl5:		dw	!doslit__xt
		dw	5
		db	'(end)'
		dw	!rev_type_xt
		dw	!key_xt
		dw	!drop_xt
		dw	!r_from_drop_xt
		dw	!r_from_drop_xt
		dw	!drop_xt
		dw	!cr_xt
		dw	!doexit__xt
		endl
unused:		dw	words
		db	$06
		db	'UNUSED'
unused_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	!dict_limit
		dw	!here_xt
		dw	!minus_xt
		dw	!doexit__xt
		endl
origx_:		dw	unused
		db	$07
		db	'(ORIGX)'
origx__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
origy_:		dw	origx_
		db	$07
		db	'(ORIGY)'
origy__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
beginning_:	dw	origy_
		db	$0b
		db	'(BEGINNING)'
beginning__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
current_:	dw	beginning_
		db	$09
		db	'(CURRENT)'
current__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
end_:		dw	current_
		db	$05
		db	'(END)'
end__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
lbound_:	dw	end_
		db	$08
		db	'(LBOUND)'
lbound__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
ubound_:	dw	lbound_
		db	$08
		db	'(UBOUND)'
ubound__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
ins_:		dw	ubound_
		db	$05
		db	'(INS)'
ins__xt:	local
		jp	!doval__xt
		dw	$0000
		endl
position_:	dw	ins_
		db	$0a
		db	'(POSITION)'
position__xt:	local
		jp	!docol__xt
		dw	!origx__xt
		dw	!current__xt
		dw	!plus_xt
		dw	!x_max_fetch_xt
		dw	!slash_mod_xt
		dw	!origy__xt
		dw	!plus_xt
		dw	!doexit__xt
		endl
scroll_up_:	dw	position_
		db	$0b
		db	'(SCROLL-UP)'
scroll_up__xt:	local
		jp	!docol__xt
		dw	!y_max_fetch_xt
		dw	!one_minus_xt
		dw	!y_store_xt
		dw	!dolit__xt
		dw	-1
		dw	!doplusto__xt
		dw	!origy__xt+3
		dw	!dolit__xt
		dw	0
		dw	!y_fetch_xt
		dw	!end__xt
		dw	!current__xt
		dw	!x_fetch_xt
		dw	!minus_xt
		dw	!dup_xt
		dw	!beginning__xt
		dw	!plus_xt
		dw	!minus_rot_xt
		dw	!minus_xt
		dw	!dolit__xt
		dw	1
		dw	!scroll__xt
		dw	!disp__xt
		dw	!doexit__xt
		endl
scroll_dwn_:	dw	scroll_up_
		db	$0d
		db	'(SCROLL-DOWN)'
scroll_dwn__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	0
		dw	!y_store_xt
		dw	!dolit__xt
		dw	1
		dw	!doplusto__xt
		dw	!origy__xt+3
		dw	!origy__xt
		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	0
			dw	!y_fetch_xt
			dw	!beginning__xt
			dw	!current__xt
			dw	!plus_xt
			dw	!x_fetch_xt
			dw	!minus_xt
		dw	!ahead__xt
		dw	lbl3-lbl2
lbl2:			dw	!origx__xt
			dw	!y_fetch_xt
			dw	!beginning__xt
lbl3:		dw	!x_max_fetch_xt
		dw	!end__xt
		dw	!min_xt
		dw	!dolit__xt
		dw	-1
		dw	!scroll__xt
		dw	!disp__xt
		dw	!doexit__xt
		endl
refresh_:	dw	scroll_dwn_
		db	$09
		db	'(REFRESH)'
refresh__xt:	local
		jp	!docol__xt
		dw	!position__xt
		dw	!swap_xt
		dw	!x_store_xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	0
		dw	!y_max_fetch_xt
		dw	!within_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!y_store_xt
			dw	!doexit__xt
lbl2:		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!scroll_dwn__xt
			dw	!doexit__xt
lbl4:		dw	!scroll_up__xt
		dw	!doexit__xt
		endl
power_off:	dw	refresh_
		db	$09
		db	'POWER-OFF'
power_off_xt:	local
		pre_on
		mvw	(!cx),$0008		; System control driver
		mv	il,$41			; 'Power off'
		callf	!iocs
		pre_off
		jp	!interp__
		endl
clear_:		dw	power_off
		db	$07
		db	'(CLEAR)'
clear__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	0
		dw	!doto__xt
		dw	!current__xt+3
		dw	!position__xt
		dw	!nip_xt
		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	0
			dw	!dup_xt
			dw	!doto__xt
			dw	!origy__xt+3
			dw	!dup_xt
			dw	!beginning__xt
			dw	!end__xt
			dw	!disp__xt
lbl2:		dw	!lbound__xt
		dw	!doto__xt
		dw	!current__xt+3
		dw	!position__xt
		dw	!two_dup_xt
		dw	!at_x_y_xt
		dw	!end__xt
		dw	!lbound__xt
		dw	!minus_xt
		dw	!clean_up__xt
		dw	!current__xt
		dw	!doto__xt
		dw	!end__xt+3
		dw	!doexit__xt
		endl
all_clear_:	dw	clear_
		db	$0b
		db	'(ALL-CLEAR)'
all_clear__xt:	local
		jp	!docol__xt
		dw	!page_xt
		dw	!dolit__xt
		dw	0
		dw	!dup_xt
		dw	!dup_xt
		dw	!doto__xt
		dw	!origx__xt+3
		dw	!doto__xt
		dw	!origy__xt+3
		dw	!doto__xt
		dw	!current__xt+3
		dw	!lbound__xt
		dw	!dup_xt
		dw	!doto__xt
		dw	!current__xt+3
		dw	!doto__xt
		dw	!end__xt+3
		dw	!doexit__xt
		endl
up_:		dw	all_clear_
		db	$04
		db	'(UP)'
up__xt:		local
		jp	!docol__xt
		dw	!current__xt
		dw	!x_max_fetch_xt
		dw	!minus_xt
		dw	!lbound__xt
		dw	!max_xt
		dw	!doto__xt
		dw	!current__xt+3
		dw	!refresh__xt
		dw	!doexit__xt
		endl
down_:		dw	up_
		db	$06
		db	'(DOWN)'
down__xt:	local
		jp	!docol__xt
		dw	!current__xt
		dw	!x_max_fetch_xt
		dw	!plus_xt
		dw	!end__xt
		dw	!min_xt
		dw	!doto__xt
		dw	!current__xt+3
		dw	!refresh__xt
		dw	!doexit__xt
		endl
left_:		dw	down_
		db	$06
		db	'(LEFT)'
left__xt:	local
		jp	!docol__xt
		dw	!current__xt
		dw	!lbound__xt
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-1
			dw	!doplusto__xt
			dw	!current__xt+3
			dw	!refresh__xt
lbl2:		dw	!doexit__xt
		endl
right_:		dw	left_
		db	$07
		db	'(RIGHT)'
right__xt:	local
		jp	!docol__xt
		dw	!ubound__xt
		dw	!one_minus_xt
		dw	!end__xt
		dw	!min_xt
		dw	!current__xt
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	1
			dw	!doplusto__xt
			dw	!current__xt+3
			dw	!refresh__xt
lbl2:		dw	!doexit__xt
		endl
return_:	dw	right_
		db	$08
		db	'(RETURN)'
return__xt:	local
		jp	!docol__xt
		dw	!beginning__xt
		dw	!lbound__xt
		dw	!plus_xt
		dw	!end__xt
		dw	!dup_xt
		dw	!doto__xt
		dw	!current__xt+3
		dw	!refresh__xt
		dw	!doexit__xt
		endl
del_:		dw	return_
		db	$05
		db	'(DEL)'
del__xt:	local
		jp	!docol__xt
		dw	!end__xt
		dw	!current__xt
		dw	!minus_xt
		dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!beginning__xt
			dw	!current__xt
			dw	!plus_xt
			dw	!dup_xt
			dw	!one_plus_xt
			dw	!swap_xt
			dw	!rot_xt
			dw	!c_move_xt
			dw	!dolit__xt
			dw	-1
			dw	!doplusto__xt
			dw	!end__xt+3
			dw	!position__xt
			dw	!beginning__xt
			dw	!current__xt
			dw	!plus_xt
			dw	!end__xt
			dw	!current__xt
			dw	!minus_xt
			dw	!disp__xt
			dw	!origx__xt
			dw	!end__xt
			dw	!plus_xt
			dw	!x_max_fetch_xt
			dw	!slash_mod_xt
			dw	!origy__xt
			dw	!plus_xt
			dw	!dolit__xt
			dw	1
			dw	!clean_up__xt
lbl2:		dw	!doexit__xt
		endl
bs_:		dw	del_
		db	$04
		db	'(BS)'
bs__xt:		local
		jp	!docol__xt
		dw	!current__xt
		dw	!lbound__xt
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-1
			dw	!doplusto__xt
			dw	!current__xt+3
			dw	!refresh__xt
			dw	!del__xt
lbl2:		dw	!doexit__xt
		endl
replace_:	dw	bs_
		db	$09
		db	'(REPLACE)'
replace__xt:	local
		jp	!docol__xt
		dw	!beginning__xt
		dw	!current__xt
		dw	!plus_xt
		dw	!c_store_xt
		dw	!position__xt
		dw	!beginning__xt
		dw	!current__xt
		dw	!plus_xt
		dw	!dolit__xt
		dw	1
		dw	!disp__xt
		dw	!current__xt
		dw	!end__xt
		dw	!equals_xt
		dw	!end__xt
		dw	!ubound__xt
		dw	!less_than_xt
		dw	!and_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	1
			dw	!doplusto__xt
			dw	!end__xt+3
lbl2:		dw	!right__xt
		dw	!doexit__xt
		endl
insert_:	dw	replace_
		db	$08
		db	'(INSERT)'
insert__xt:	local
		jp	!docol__xt
		dw	!end__xt
		dw	!ubound__xt
		dw	!less_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!beginning__xt
			dw	!current__xt
			dw	!plus_xt
			dw	!dup_xt
			dw	!dup_xt
			dw	!one_plus_xt
			dw	!end__xt
			dw	!current__xt
			dw	!minus_xt
			dw	!c_move_up_xt
			dw	!c_store_xt
			dw	!dolit__xt
			dw	1
			dw	!doplusto__xt
			dw	!end__xt+3
			dw	!position__xt
			dw	!beginning__xt
			dw	!current__xt
			dw	!plus_xt
			dw	!end__xt
			dw	!current__xt
			dw	!minus_xt
			dw	!disp__xt
			dw	!right__xt
			dw	!doexit__xt
lbl2:		dw	!drop_xt
		dw	!doexit__xt
		endl
init_edit_:	dw	insert_
		db	$0b
		db	'(INIT-EDIT)'
init_edit__xt:	local
		jp	!docol__xt
		dw	!doto__xt
		dw	!lbound__xt+3
		dw	!doto__xt
		dw	!current__xt+3
		dw	!doto__xt
		dw	!end__xt+3
		dw	!doto__xt
		dw	!ubound__xt+3
		dw	!doto__xt
		dw	!beginning__xt+3
		dw	!x_fetch_xt
		dw	!doto__xt
		dw	!origx__xt+3
		dw	!y_fetch_xt
		dw	!doto__xt
		dw	!origy__xt+3
		dw	!false_xt
		dw	!doto__xt
		dw	!ins__xt+3
		dw	!position__xt
		dw	!nip_xt
		dw	!y_max_fetch_xt
		dw	!one_minus_xt
		dw	!greatr_than_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!y_max_fetch_xt
			dw	!one_minus_xt
			dw	!y_store_xt
			dw	!position__xt
			dw	!nip_xt
			dw	!y_max_fetch_xt
			dw	!minus_xt
			dw	!one_plus_xt
			dw	!dup_xt
			dw	!scroll__xt
			dw	!y_max_fetch_xt
			dw	!swap_xt
			dw	!minus_xt
			dw	!doto__xt
			dw	!origy__xt+3
lbl2:		dw	!dolit__xt
		dw	$0000
		dw	!set_cursor_xt
		dw	!origx__xt
		dw	!origy__xt
		dw	!beginning__xt
		dw	!end__xt
		dw	!disp__xt
		dw	!position__xt
		dw	!at_x_y_xt
		dw	!doexit__xt
		endl
edit:		dw	init_edit_
		db	$04
		db	'EDIT'
edit_xt:	local
		jp	!docol__xt
		dw	!init_edit__xt
lbl1:			dw	!e_key_xt
			dw	!dolit__xt
			dw	$000d
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!drop_xt
				dw	!return__xt
				dw	!doexit__xt
			dw	!ahead__xt
			dw	lbl28-lbl3
lbl3:			dw	!dolit__xt
			dw	$0008
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl5-lbl4
lbl4:				dw	!drop_xt
				dw	!bs__xt
			dw	!ahead__xt
			dw	lbl28-lbl5
lbl5:			dw	!dolit__xt
			dw	$007f
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl7-lbl6
lbl6:				dw	!drop_xt
				dw	!del__xt
			dw	!ahead__xt
			dw	lbl28-lbl7
lbl7:			dw	!dolit__xt
			dw	$001c
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl9-lbl8
lbl8:				dw	!drop_xt
				dw	!right__xt
			dw	!ahead__xt
			dw	lbl28-lbl9
lbl9:			dw	!dolit__xt
			dw	$001d
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl11-lbl10
lbl10:				dw	!drop_xt
				dw	!left__xt
			dw	!ahead__xt
			dw	lbl28-lbl11
lbl11:			dw	!dolit__xt
			dw	$001e
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl13-lbl12
lbl12:				dw	!drop_xt
				dw	!up__xt
			dw	!ahead__xt
			dw	lbl28-lbl13
lbl13:			dw	!dolit__xt
			dw	$001f
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl15-lbl14
lbl14:				dw	!drop_xt
				dw	!down__xt
			dw	!ahead__xt
			dw	lbl28-lbl15
lbl15:			dw	!dolit__xt
			dw	$000c
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl17-lbl16
lbl16:				dw	!drop_xt
				dw	!clear__xt
			dw	!ahead__xt
			dw	lbl28-lbl17
;lbl15_:			dw	!dolit__xt
;			dw	-$2c
;			dw	!over_xt
;			dw	!equals_xt
;			dw	!if__xt
;			dw	lbl17-lbl16_
;lbl16_:				dw	!drop_xt
;				dw	!all_clear__xt
;			dw	!ahead__xt
;			dw	lbl28-lbl17
lbl17:			dw	!dolit__xt
			dw	$0012
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl19-lbl18
lbl18:				dw	!drop_xt
				dw	!ins__xt
				dw	!invert_xt
				dw	!doto__xt
				dw	!ins__xt+3
			dw	!ahead__xt
			dw	lbl28-lbl19
lbl19:			dw	!dolit__xt
			dw	$fffc
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl21-lbl20
lbl20:				dw	!drop_xt
				dw	!power_off_xt
			dw	!ahead__xt
			dw	lbl28-lbl21
lbl21:			dw	!dolit__xt
			dw	$fff1
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl23-lbl22
lbl22:				dw	!drop_xt
				dw	!power_off_xt
			dw	!ahead__xt
			dw	lbl28-lbl23
lbl23:			dw	!dup_xt
			dw	!blnk_xt
			dw	!dolit__xt
			dw	$007f
			dw	!within_xt
			dw	!if__xt
			dw	lbl27-lbl24
lbl24:				dw	!dup_xt
				dw	!ins__xt
				dw	!if__xt
				dw	lbl26-lbl25
lbl25:					dw	!insert__xt
				dw	!ahead__xt
				dw	lbl27-lbl26
lbl26:					dw	!replace__xt
lbl27:		dw	!drop_xt
lbl28:		dw	!again__xt
		dw	lbl29-lbl1
lbl29:		dw	!doexit__xt
		endl
to_binary:	dw	edit
		db	$07
		db	'>BINARY'
to_binary_xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	$0030				; The value of '0'
		dw	!dolit__xt
		dw	$003a				; The value of '9' + 1
		dw	!within_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	$0030
			dw	!minus_xt
			dw	!doexit__xt
lbl2:		dw	!dup_xt
		dw	!dolit__xt
		dw	$0041				; The value of 'A'
		dw	!dolit__xt
		dw	$005b				; The value of 'Z' + 1
		dw	!within_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!dolit__xt
			dw	$0037
			dw	!minus_xt
			dw	!doexit__xt
lbl4:		dw	!dup_xt
		dw	!dolit__xt
		dw	$0061				; The value of 'a'
		dw	!dolit__xt
		dw	$007b				; The value of 'z' + 1
		dw	!within_xt
		dw	!if__xt
		dw	lbl6-lbl5
lbl5:			dw	!dolit__xt
			dw	$0057
			dw	!minus_xt
			dw	!doexit__xt
lbl6:		dw	!drop_xt
		dw	!dolit__xt
		dw	-1				; A negative value means that a bad character has been encountered
		dw	!doexit__xt
		endl
to_number:	dw	to_binary
		db	$07
		db	'>NUMBER'
to_number_xt:	local
		jp	!docol__xt
		dw	!two_swap_xt
		dw	!two_to_r_xt
lbl1:			dw	!dup_xt
		dw	!if__xt
		dw	lbl5-lbl2
lbl2:			dw	!next_char_xt
			dw	!to_binary_xt
			dw	!dup_xt
			dw	!dolit__xt
			dw	0
			dw	!base_xt
			dw	!fetch_xt
			dw	!within_xt
			dw	!invert_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!drop_xt
				dw	!dolit__xt
				dw	-1
				dw	!slash_str_xt
				dw	!two_r_from_xt
				dw	!two_swap_xt
				dw	!doexit__xt
lbl4:			dw	!s_to_d_xt
			dw	!two_r_from_xt
			dw	!base_xt
			dw	!fetch_xt
			dw	!u_m_d_star_xt
			dw	!d_plus_xt
			dw	!two_to_r_xt
		dw	!again__xt
		dw	lbl5-lbl1
lbl5:		dw	!two_r_from_xt
		dw	!two_swap_xt
		dw	!doexit__xt
		endl
accept:		dw	to_number
		db	$06
		db	'ACCEPT'
accept_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	0
		dw	!dup_xt
		dw	!dup_xt
		dw	!edit_xt
		dw	!nip_xt
		dw	!doexit__xt
		endl
file_refill:	dw	accept
		db	$0b
		db	'FILE-REFILL'
file_refill_xt:	local
		jp	!docol__xt
		dw	!fib_xt
		dw	!dolit__xt
		dw	!ib_size
		dw	!source_id_xt
		dw	!read_line_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!two_drop_xt
			dw	!false_xt
			dw	!doexit__xt
lbl2:		dw	!fib_xt
		dw	!rot_xt
		dw	!source__xt
		dw	!two_store_xt
		dw	!to_in_xt
		dw	!off_xt
		dw	!doexit__xt
		endl
user_refill:	dw	file_refill
		db	$0b
		db	'USER-REFILL'
user_refill_xt:	local
		jp	!docol__xt
		dw	!busy_off_xt
		dw	!tib_xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	!ib_size
		dw	!stdi_xt
		dw	!peek_char_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!two_drop_xt
			dw	!busy_on_xt
			dw	!false_xt
			dw	!to_in_xt
			dw	!off_xt
			dw	!doexit__xt
lbl2:			dw	!dolit__xt
			dw	$001c			; Rigth arrow
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!stdi_xt
				dw	!read_char_xt
				dw	!two_drop_xt
				dw	!drop_xt
				dw	!source__xt
				dw	!two_fetch_xt
				dw	!nip_xt
				dw	!dolit__xt
				dw	0
			dw	!ahead__xt
			dw	lbl7-lbl4
lbl4:			dw	!dolit__xt
			dw	$001d			; Left arrow
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl6-lbl5
lbl5:				dw	!stdi_xt
				dw	!read_char_xt
				dw	!two_drop_xt
				dw	!drop_xt
				dw	!source__xt
				dw	!two_fetch_xt
				dw	!nip_xt
				dw	!dup_xt
			dw	!ahead__xt
			dw	lbl7-lbl6
lbl6:				dw	!dolit__xt
				dw	0
				dw	!dup_xt
				dw	!rot_xt
		dw	!drop_xt
lbl7:		dw	!dolit__xt
		dw	0
		dw	!edit_xt
		dw	!nip_xt
		dw	!source__xt
		dw	!two_store_xt
		dw	!busy_on_xt
		dw	!to_in_xt
		dw	!off_xt
		dw	!true_xt
		dw	!doexit__xt
		endl
refill:		dw	user_refill
		db	$06
		db	'REFILL'
refill_xt:	local
		jp	!docol__xt
		dw	!source_id_xt
		dw	!dolit__xt
		dw	-1
		dw	!equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!false_xt
			dw	!doexit__xt
lbl2:		dw	!source_id_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!file_refill_xt
			dw	!doexit__xt
lbl4:		dw	!user_refill_xt
		dw	!doexit__xt
		endl
paren:		dw	refill
		db	$81
		db	'('
paren_xt:	local
		jp	!docol__xt
lbl1:			dw	!dolit__xt
			dw	$0029				; The value of the ')' character
			dw	!parse_xt
			dw	!plus_xt
			dw	!dup_xt
			dw	!source_xt
			dw	!plus_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl3-lbl2
lbl2:				dw	!drop_xt
				dw	!refill_xt
			dw	!ahead__xt
			dw	lbl6-lbl3
lbl3:				dw	!c_fetch_xt
				dw	!dolit__xt
				dw	$0029			; The value of the ')' character
				dw	!not_equals_xt
				dw	!if__xt
				dw	lbl5-lbl4
lbl4:					dw	!refill_xt
				dw	!ahead__xt
				dw	lbl6-lbl5
lbl5:					dw	!false_xt
lbl6:			dw	!zero_equals_xt
			dw	!until__xt
			dw	lbl7-lbl1
lbl7:		dw	!doexit__xt
		endl
back_slash:	dw	paren
		db	$81
		db	'\'
back_slash_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$000a			; The value of the LF character
		dw	!parse_xt
		dw	!two_drop_xt
		dw	!doexit__xt
		endl
dot_paren:	dw	back_slash
		db	$82
		db	'.('
dot_paren_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0029			; The value of the ')' character
		dw	!parse_xt
		dw	!cr_xt
		dw	!type_xt
		dw	!doexit__xt
		endl
anew:		dw	dot_paren
		db	$04
		db	'ANEW'
anew_xt:	local
		jp	!docol__xt
		dw	!to_in_xt
		dw	!fetch_xt
		dw	!to_r_xt
		dw	!tick__xt
		dw	!over_xt
		dw	!marker_qust_xt
		dw	!and_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!execute_xt
		dw	!ahead__xt
		dw	lbl3-lbl2
lbl2:			dw	!drop_xt
lbl3:		dw	!r_from_xt
		dw	!to_in_xt
		dw	!store_xt
		dw	!marker_xt
		dw	!doexit__xt
		endl
brkt_def:	dw	anew
		db	$89
		db	'[DEFINED]'
brkt_def_xt:	local
		jp	!docol__xt
		dw	!blnk_xt
		dw	!parse_word_xt
		dw	!find_word_xt
		dw	!nip_xt
		dw	!zer_not_equ_xt
		dw	!doexit__xt
		endl
brkt_undef:	dw	brkt_def
		db	$8b
		db	'[UNDEFINED]'
brkt_undef_xt:	local
		jp	!docol__xt
		dw	!brkt_def_xt
		dw	!invert_xt
		dw	!doexit__xt
		endl
brkt_else:	dw	brkt_undef
		db	$86
		db	'[ELSE]'
brkt_else_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	1
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
		dw	!doexit__xt
		endl
brkt_if:	dw	brkt_else
		db	$84
		db	'[IF]'
brkt_if_xt:	local
		jp	!docol__xt
		dw	!zero_equals_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!brkt_else_xt
lbl2:		dw	!doexit__xt
		endl
brkt_then:	dw	brkt_if
		db	$86
		db	'[THEN]'
brkt_then_xt:	local
		jp	!docol__xt
		dw	!doexit__xt
		endl
check_stack:	dw	brkt_then
		db	$0b
		db	'CHECK-STACK'
check_stack_xt:	local
		jp	!docol__xt
		dw	!depth_xt
		dw	!dup_xt
		dw	!zer_lss_thn_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!dolit__xt
			dw	-4		; Stack underflow
			dw	!throw_xt
lbl2:		dw	!dolit__xt
		dw	!s_size/2		; One cell = 16 bits
		dw	!greatr_than_xt		; Signed integer comparison
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!dolit__xt
			dw	-3		; Stack overflow
			dw	!throw_xt
lbl4:		dw	!doexit__xt
		endl
currnt_base:	dw	check_stack
		db	$0c
		db	'CURRENT-BASE'
currnt_base_xt:	local
		jp	!dovar__xt
		dw	10
		endl
cur_base_st:	dw	currnt_base
		db	$0d
		db	'CURRENT-BASE!'
cur_base_st_xt:	local
		jp	!docol__xt
		dw	!next_char_xt
			dw	!dolit__xt
			dw	$0024			; The value of the '$' character
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl2-lbl1
lbl1:				dw	!drop_xt
				dw	!dolit__xt
				dw	16
			dw	!ahead__xt
			dw	lbl7-lbl2
lbl2:			dw	!dolit__xt
			dw	$0023			; The value of the '#' character
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!drop_xt
				dw	!dolit__xt
				dw	10
			dw	!ahead__xt
			dw	lbl7-lbl4
lbl4:			dw	!dolit__xt
			dw	$0025			; The value of the '%' character
			dw	!over_xt
			dw	!equals_xt
			dw	!if__xt
			dw	lbl6-lbl5
lbl5:				dw	!drop_xt
				dw	!dolit__xt
				dw	2
			dw	!ahead__xt
			dw	lbl7-lbl6
lbl6:			dw	!to_r_xt
			dw	!dolit__xt
			dw	-1
			dw	!slash_str_xt
			dw	!base_xt
			dw	!fetch_xt
			dw	!r_from_xt
		dw	!drop_xt
lbl7:		dw	!currnt_base_xt
		dw	!store_xt
		dw	!doexit__xt
		endl
negative:	dw	cur_base_st
		db	$08
		db	'NEGATIVE'
negative_xt:	local
		jp	!dovar__xt
		dw	$0000
		endl
negative_st:	dw	negative
		db	$09
		db	'NEGATIVE!'
negative_st_xt:	local
		jp	!docol__xt
		dw	!next_char_xt
		dw	!dolit__xt
		dw	$002d			; The value of '-'
		dw	!equals_xt
		dw	!dup_xt
		dw	!negative_xt
		dw	!store_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!doexit__xt
lbl2:		dw	!dolit__xt
		dw	-1
		dw	!slash_str_xt
		dw	!doexit__xt
		endl
double:		dw	negative_st
		db	$06
		db	'DOUBLE'
double_xt:	local
		jp	!dovar__xt
		dw	$0000
		endl
double_nb:	dw	double
		db	$0d
		db	'DOUBLE-NUMBER'
double_nb_xt:	local
		jp	!docol__xt
		dw	!double_xt
		dw	!off_xt
		dw	!dolit__xt
		dw	0
		dw	!s_to_d_xt
		dw	!two_to_r_xt
		dw	!cur_base_st_xt
		dw	!negative_st_xt
lbl1:			dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl8-lbl2
lbl2:			dw	!next_char_xt
			dw	!dup_xt
			dw	!dolit__xt
			dw	$002e		; The value of '.'
			dw	!equals_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!drop_xt
				dw	!double_xt
				dw	!on_xt
			dw	!ahead__xt
			dw	lbl7-lbl4
lbl4:				dw	!to_binary_xt
				dw	!dup_xt
				dw	!dolit__xt
				dw	0
				dw	!currnt_base_xt
				dw	!fetch_xt
				dw	!within_xt
				dw	!invert_xt
				dw	!if__xt
				dw	lbl6-lbl5
lbl5:					dw	!dolit__xt
					dw	-13		; Undefined word
					dw	!throw_xt
lbl6:				dw	!s_to_d_xt
				dw	!two_r_from_xt
				dw	!currnt_base_xt
				dw	!fetch_xt
				dw	!u_m_d_star_xt
				dw	!d_plus_xt
				dw	!two_to_r_xt
lbl7:		dw	!again__xt
		dw	lbl8-lbl1
lbl8:		dw	!drop_xt
		dw	!two_r_from_xt
		dw	!doexit__xt
		endl
float_:		dw	double_nb
		db	$07
		db	'(FLOAT)'
float__xt:	local
		pushs	x			; Save IP
		mv	y,(!xi)			; Y holds the address of the float at the top of the stack (which must be heap-allocated!)
		pushu	ba			; Save TOS
		mv	il,15			; I holds the size of a heap-allocated float
		mv	a,0
		mv	x,y
_erase:		mv	[x++],a
		dec	il
		jrnz	_erase
		popu	i			; I holds the length of the string
		popu	ba			; BA holds the short address of the string
		pushu	y			; Save the address of the float
		inc	y			; Make
		inc	y			; Y pointing to
		inc	y			; the address of the mantissa
		mv	x,!base_address		; X holds the
		add	x,ba			; address of the string
		inc	i			; Check that
		dec	i			; the string is
		jpz	_return			; not empty
		mv	(!el),0			; Used to increment the exponent (changed when dot is encountered)
		mv	(!eh),-1		; Temporary exponent value
		mv	(!fl),24		; Maximum number of significant digits
		mv	(!fh),$00		; bit0: exponent sign not encountered, bit1 : dot encountered, bit2: exponent sign, bit3: sign, bit4: digit pair
		mv	(!gl),0			; Exponent value
_sign:		mv	a,[x++]			; Search for a sign (I is > 0 when entering _sign)
		cmp	a,'+'			; Is it '+'?
		jrz	lbl3
lbl1:		cmp	a,'-'			; Is it '-'?
		jrz	lbl2
		dec	x			; Move string pointer backward
		jr	_mantissa
lbl2:		mv	a,$08			; Set sign to
		mv	[y-3],a			; negative
lbl3:		dec	i			; Update the number of parsed characters
		jrnz	lbl3_0
		inc	i			; Update the number of parsed characters
		jr	lbl8
lbl3_0:		mv	a,[x]
		cmp	a,'.'
		jrz	_mantissa
		cmp	a,'0'
		jrnc	lbl3_2
lbl3_1:		inc	i
		jr	lbl8
lbl3_2:		cmp	a,'9'+1
		jrnc	lbl3_1
_mantissa:	mv	a,[x++]			; Search for a 0 (I is > 0 when entering _remove_zeros)
		cmp	a,'0'
		jrnz	lbl5
		mv	a,(!el)
		add	(!eh),a			; Update the exponent (FIXME: underflow)
lbl4:		dec	i
		jrnz	_mantissa
		jr	_return
lbl5:		cmp	a,'.'
		jrz	lbl6
		dec	x			; Move string pointer backward
		inc	(!el)			; If previous value was -1 then a dot has been encountered
		jr	_digits
lbl6:		xor	(!fh),$02		; Have we already encountered a dot?
		test	(!fh),$02
		jrz	lbl8
lbl7:		dec	(!el)
		jr	lbl4
_digits:	mv	a,[x++]
		cmp	a,'0'
		jrnc	lbl9
		cmp	a,'.'			; Cannot occur at the first iteration (see lbl5)
		jrnz	lbl8
		xor	(!fh),$02
		test	(!fh),$02
		jrz	lbl8
		mv	(!el),0
		jr	lbl10
lbl8:		dec	x
		jr	_return
lbl9:		cmp	a,'9'+1
		jrnc	_exponent
		cmp	(!fl),0			; Test whether enough significant digits have been read or not
		jrz	lbl10
		dec	(!fl)			; Update the number of significant digits
		sub	a,'0'
		xor	(!fh),$10		; Is it the 1st or 2nd digit of a pair of BCD digits?
		test	(!fh),$10
		jrz	lbl11
		swap	a
		mv	[y],a
lbl10:		mv	a,(!el)
		add	(!eh),a			; Update the exponent
		dec	i
		jrnz	_digits
		jr	_return
lbl11:		mv	(!gh),[y]
		or	a,(!gh)
		mv	[y++],a
lbl12:		jr	lbl10
_exponent:	popu	y			; Y holds the address of the float
		pushu	y
		or	a,$20			; Convert the character to lowercase
		cmp	a,'e'
		jrz	lbl16
		cmp	a,'d'
		jrz	lbl15
		jr	lbl8
lbl15:		mv	a,[y]
		or	a,$01
		mv	[y],a
lbl16:		dec	i
		jrz	_return
_exp_sign:	mv	a,[x++]
		cmp	a,'+'
		jrz	lbl18
		cmp	a,'-'
		jrz	lbl17
		or	(!fh),$01		; Exponent sign not encountered
		dec	x
		jr	_exp_value
lbl17:		or	(!fh),$04		; Exponent sign is negative
lbl18:		dec	i
		jrnz	_exp_value
		inc	i
		jr	lbl8
_exp_value:	mv	a,[x++]
		cmp	a,'0'
		jrnc	lbl20
lbl19:		dec	x
		test	(!fh),$01		; Ignore the sign of the exponent
		jrnz	_return
		jr	lbl8
lbl20:		cmp	a,'9'+1
		jrnc	lbl19
		sub	a,'0'
		mv	(!gl),a
		dec	i
		jrz	lbl23
		mv	a,[x++]
		cmp	a,'0'
		jrnc	lbl22
lbl21:		dec	x
		jr	lbl23
lbl22:		cmp	a,'9'+1
		jrnc	lbl21
		pushu	a
		mv	a,(!gl)			; Multiply
		rc
		shl	(!gl)			; The previous
		shl	(!gl)			; digit
		shl	(!gl)			; by
		add	(!gl),a			; 10, then
		add	(!gl),a			; add the value
		popu	a
		sub	a,'0'			; of the
		add	(!gl),a			; current digit
		dec	i			; Update the number of parsed characters
lbl23:		test	(!fh),$04		; Test the sign of the exponent
		jrz	_return
		mv	a,(!gl)			; Negate
		mv	(!gl),0			; the
		sub	(!gl),a			; exponent
_return:	popu	y			; Y holds the address of the float
		cmp	(!fl),24		; Test the number of parsed characters
		jrz	lbl24
		mv	a,(!eh)
		add	a,(!gl)			; Compute the exponent value
		mv	[y+1],a			; Store the exponent value
lbl24:		mv	ba,x			; Save the address of
		pushu	ba			; the first unparsed character
		mv	ba,i			; Set TOS to the number of unparsed characters
		pops	x			; Restore IP
		rc
		jp	!interp__
		endl
number:		dw	float_
		db	$06
		db	'NUMBER'
number_xt:	local
		jp	!docol__xt
		dw	!double_nb_xt
		dw	!negative_xt
		dw	!fetch_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!d_negate_xt
lbl2:		dw	!state_xt
		dw	!fetch_xt
		dw	!if__xt
		dw	lbl6-lbl3
lbl3:			dw	!double_xt
			dw	!fetch_xt
			dw	!if__xt
			dw	lbl5-lbl4
lbl4:				dw	!dolit__xt
				dw	!do2lit__xt
				dw	!compile_com_xt
				dw	!two_comma_xt
				dw	!doexit__xt
lbl5:			dw	!d_to_s_xt
			dw	!dolit__xt
			dw	!dolit__xt
			dw	!compile_com_xt
			dw	!comma_xt
			dw	!doexit__xt
lbl6:		dw	!double_xt
		dw	!fetch_xt
		dw	!if__xt
		dw	lbl8-lbl7
lbl7:			dw	!doexit__xt
lbl8:		dw	!d_to_s_xt
		dw	!doexit__xt
		endl
interpret:	dw	number
		db	$09
		db	'INTERPRET'
interpret_xt:	local
		jp	!docol__xt
lbl1:			dw	!blnk_xt
			dw	!parse_word_xt
			dw	!quest_dup_xt
		dw	!if__xt
		dw	lbl9-lbl2
lbl2:			dw	!two_dup_xt
			dw	!find_word_xt
			dw	!quest_dup_xt
			dw	!if__xt
			dw	lbl7-lbl3
lbl3:				dw	!two_swap_xt
				dw	!two_drop_xt
				dw	!state_xt
				dw	!fetch_xt
				dw	!equals_xt
				dw	!if__xt
				dw	lbl5-lbl4
lbl4:					dw	!compile_com_xt
				dw	!ahead__xt
				dw	lbl6-lbl5
lbl5:					dw	!execute_xt
					dw	!check_stack_xt
lbl6:			dw	!ahead__xt
			dw	lbl8-lbl7
lbl7:				dw	!drop_xt
				dw	!number_xt
				dw	!check_stack_xt
lbl8:		dw	!again__xt
		dw	lbl9-lbl1
lbl9:		dw	!drop_xt
		dw	!doexit__xt
		endl
evaluate:	dw	interpret
		db	$08
		db	'EVALUATE'
evaluate_xt:	local
		jp	!docol__xt
		dw	!source__xt
		dw	!two_fetch_xt
		dw	!two_to_r_xt
		dw	!source__xt
		dw	!two_store_xt
		dw	!to_in_xt
		dw	!fetch_xt
		dw	!to_r_xt
		dw	!to_in_xt
		dw	!off_xt
		dw	!source_id_xt
		dw	!to_r_xt
		dw	!dolit__xt
		dw	-1
		dw	!doto__xt
		dw	!source_id_xt+3
		dw	!interpret_xt
		dw	!r_from_xt
		dw	!doto__xt
		dw	!source_id_xt+3
		dw	!r_from_xt
		dw	!to_in_xt
		dw	!store_xt
		dw	!two_r_from_xt
		dw	!source__xt
		dw	!two_store_xt
		dw	!doexit__xt
		endl
includ_file:	dw	evaluate
		db	$0c
		db	'INCLUDE-FILE'
includ_file_xt:	local
		jp	!docol__xt
		dw	!source_id_xt
		dw	!to_r_xt
		dw	!doto__xt
		dw	!source_id_xt+3
		dw	!source__xt
		dw	!two_fetch_xt
		dw	!two_to_r_xt
		dw	!to_in_xt
		dw	!fetch_xt
		dw	!to_r_xt
lbl1:			dw	!refill_xt
		dw	!if__xt
		dw	lbl3-lbl2
lbl2:			dw	!interpret_xt
		dw	!again__xt
		dw	lbl3-lbl1
lbl3:		dw	!r_from_xt
		dw	!to_in_xt
		dw	!store_xt
		dw	!two_r_from_xt
		dw	!source__xt
		dw	!two_store_xt
		dw	!r_from_xt
		dw	!doto__xt
		dw	!source_id_xt+3
		dw	!doexit__xt
		endl
included:	dw	includ_file
		db	$08
		db	'INCLUDED'
included_xt:	local
		jp	!docol__xt
		dw	!r_o_xt
		dw	!open_file_xt
		dw	!throw_xt
		dw	!dup_to_r_xt
		dw	!includ_file_xt
		dw	!r_from_xt
		dw	!close_file_xt
		dw	!throw_xt
		dw	!doexit__xt
		endl
envnmt_qry:	dw	included
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
			dw	32767
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
			dw	40
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
			dw	256
			dw	!true_xt
			dw	!doexit__xt
lbl6:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	17
		db	'ADDRESS-UNIT-BITS'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl8-lbl7
lbl7:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	16
			dw	!true_xt
			dw	!doexit__xt
lbl8:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	4
		db	'CORE'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl10-lbl9
lbl9:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl10:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	8
		db	'CORE-EXT'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl12-lbl11
lbl11:			dw	!two_drop_xt
			dw	!false_xt
			dw	!true_xt
			dw	!doexit__xt
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
			dw	!dolit__xt
			dw	$ffff
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
			dw	200
			dw	!true_xt
			dw	!doexit__xt
lbl26:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	11
		db	'STACK-CELLS'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl28-lbl27
lbl27:			dw	!two_drop_xt
			dw	!dolit__xt
			dw	200
			dw	!true_xt
			dw	!doexit__xt
lbl28:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	6
		db	'DOUBLE'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl30-lbl29
lbl29:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl30:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	10
		db	'DOUBLE-EXT'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl32-lbl31
lbl31:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl32:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	9
		db	'EXCEPTION'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl34-lbl33
lbl33:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl34:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	13
		db	'EXCEPTION-EXT'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl36-lbl35
lbl35:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl36:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	8
		db	'FACILITY'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl38-lbl37
lbl37:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl38:		dw	!two_dup_xt
		dw	!doslit__xt
		dw	6
		db	'STRING'
		dw	!s_equals_xt
		dw	!if__xt
		dw	lbl40-lbl39
lbl39:			dw	!two_drop_xt
			dw	!true_xt
			dw	!true_xt
			dw	!doexit__xt
lbl40:		dw	!two_drop_xt
		dw	!false_xt
		dw	!doexit__xt
		endl
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
;		mvp	[x++],(!xi)		; Save FP value
;		mvp	[x++],(!yi)		; Save free heap pointers stack pointer value
;		mv	[x++],(!ll)		; Save floating point stack's depth
;		mv	[x++],(!lh)		; Save free heap pointers stack's remaining places
		mv	ba,[!last_xt+3]
		mv	[x++],ba		; Save LAST value
		mv	ba,[!lastxt_xt+3]
		mv	[x++],ba		; Save LAST-XT value
		pre_on
		and	($fb),$7f		; Disable interruptions
		mv	s,[!s_value]		; Restore S's value
		mv	u,[!u_value]		; Restore U's value
		mv	($ec),[!bp_value]	; Restore BP's value
		or	($fb),$80		; Enable interruptions
		pre_off
		rc
		retf
		endl
bye:		dw	bye_
		db	$03
		db	'BYE'
bye_xt:		local
		jp	!docol__xt
		dw	!key_clear_xt
		dw	!page_xt
		dw	!bye__xt
		dw	!doexit__xt
		endl
error_:		dw	bye
		db	$07
		db	'(ERROR)'
error__xt:	local
		jp	!docol__xt
		dw	!dup_xt
		dw	!dolit__xt
		dw	-1			; ABORT case
		dw	!equals_xt
		dw	!over_xt
		dw	!dolit__xt
		dw	-2			; ABORT" case
		dw	!equals_xt
		dw	!or_xt
		dw	!if__xt
		dw	lbl2-lbl1
lbl1:			dw	!clear_xt
			dw	!doexit__xt
lbl2:		dw	!dup_xt
		dw	!dolit__xt
		dw	-56			; QUIT case
		dw	!equals_xt
		dw	!if__xt
		dw	lbl4-lbl3
lbl3:			dw	!drop_xt
			dw	!doexit__xt
lbl4:		dw	!doslit__xt
		dw	11
		db	'Exception #'
		dw	!type_xt
		dw	!s_to_d_xt
		dw	!d_dot__xt
		dw	!type_xt
		dw	!doexit__xt
		endl
main_refil_:	dw	error_
		db	$0d
		db	'(MAIN-REFILL)'
main_refil__xt:	local
		jp	!docol__xt
lbl1:			dw	!dolit__xt
			dw	!refill_xt
			dw	!catch_xt
		dw	!if__xt
		dw	lbl3-lbl2
lbl2:			dw	!page_xt
			dw	!dolit__xt
			dw	$0000
			dw	!source__xt
			dw	!store_xt
		dw	!again__xt
		dw	lbl3-lbl1
lbl3:		dw	!doexit__xt
		endl
quit_:		dw	main_refil_
		db	$06
		db	'(QUIT)'
quit__xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	!r_beginning
		dw	!rp_store_xt
		dw	!dolit__xt
		dw	$0000
		dw	!doto__xt
		dw	!source_id_xt+3
		dw	!key_clear_xt
		dw	!dolit__xt
		dw	$0028
		dw	!cursor_xt
		dw	!store_xt
		dw	!left_brkt_xt
lbl1:			dw	!main_refil__xt
		dw	!if__xt
		dw	lbl7-lbl2
lbl2:			dw	!space_xt
			dw	!dolit__xt
			dw	!interpret_xt
			dw	!catch_xt
			dw	!quest_dup_xt
			dw	!if__xt
			dw	lbl4-lbl3
lbl3:				dw	!error__xt
				dw	!cr_xt
				dw	!quit__xt
lbl4:			dw	!state_xt
			dw	!fetch_xt
			dw	!invert_xt
			dw	!if__xt
			dw	lbl6-lbl5
lbl5:				dw	!doslit__xt
				dw	4
				db	' OK['
				dw	!type_xt
				dw	!depth_xt
				dw	!s_to_d_xt
				dw	!d_dot__xt
				dw	!type_xt
				dw	!dolit__xt
				dw	$005d			; The ']' character
				dw	!emit_xt
lbl6:			dw	!cr_xt
		dw	!again__xt
		dw	lbl7-lbl1
lbl7:		dw	!bye_xt
		dw	!doexit__xt
		endl
startup:	dw	quit_
		db	$07
		db	'STARTUP'
startup_xt:	local
		jp	!docol__xt
		dw	!dolit__xt
		dw	$0000
		dw	!dolit__xt
		dw	3
		dw	!set_symbols_xt
		dw	!page_xt
		dw	!doslit__xt
		dw	25
		db	'Welcome into Forth world!'
		dw	!type_xt
		dw	!cr_xt
		dw	!doslit__xt
		dw	19
		db	'Type `BYE'' to exit.'
		dw	!type_xt
		dw	!cr_xt
		dw	!unused_xt
		dw	!u_dot_xt
		dw	!doslit__xt
		dw	13
		db	'byte(s) free.'
		dw	!type_xt
		dw	!cr_xt
		dw	!clear_xt
		dw	!quit__xt
		dw	!doexit__xt
		endl
_end_:		end
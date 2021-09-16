;-------------------------------------------------------------------------------
;
;		FLOAT
;
;-------------------------------------------------------------------------------
; FP width is 12 bytes in Forth and 15 bytes in internal RAM for the IOCS calls
; 12 Bytes stores both single and double floating point values:
; <sign-byte><exp><BCD0><BCD1><BCD2><BCD3><BCD4><BCD5><BCD6><BCD7><BCD8><BCD9>
; Single floating point value uses <BCD0> to <BCD4>
; The sign byte has bit 0 set for negative values
; The sign byte has bit 3 set for double floating point
; All Forth FP operations are performed on single and double floating point
;
; IOCS Function Driver:
; 2-arg fp input: $41-$46 with flag result
; 2-arg fp input: $47-$4b with float result
; 1-arg fp input: $4c-$5b with float result
; BCD->string: $78
; string->BCD: $79
; BCD->binary: $7e
; binary->BCD: $7f
;
; TODO:
;   THROW should restore FP stack pointer and size
;   f_size should be 8 for 8 floats (96 bytes) to have 2 temps above the 6 required
;   Update Forth500.s to integrate FP code and parsing
;

; ******** THIS PART ADDED TO ASSEMBLE THIS FILE INDEPENDENTLY ********

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
; floating point arguments
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
wi:		equ	$30			; Here pointer
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
blk_buff_size:	equ	1024
r_size:		equ	256			; The return stack size in bytes (must be 256, see ?STACK)
s_size:		equ	256			; The stack size in bytes (must be 256, see ?STACK)
f_size:		equ	8			; The FP stack size in number of entries
r_beginning:	equ	$bfc00			; The return stack's beginning
r_limit:	equ	r_beginning-r_size	; The return stack's low limit ($bfa00 see ?STACK)
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
cont__:
throw__:
allot__:
docol__xt:
doval__xt:
doexit__xt:
dolit__xt:
dolit0_xt:
dolit1_xt:
doslit__xt:
quest_comp_xt:
comma_xt:
compile_com_xt:
cfa_comma_xt:
create_xt:
create_hdr_xt:
if__xt:
doto__xt:
umax_xt:
umin_xt:
here_xt:
one_minus_xt:
one_plus_xt:
two_plus_xt:
drop_xt:
dup_xt:
over_xt:
swap_xt:
rot_xt:
not_rot_xt:
nip_xt:
two_dup_xt:
c_store_xt:
c_fetch_xt:
slash_str_xt:
type_xt:
emit_xt:
dot_xt:
quest_do__xt:
loop__xt:
ahead__xt:
zer_grt_thn_xt:
invert_xt:
plus_xt:
minus_xt:
less_xt:
negate_xt:
space_xt:
dash_chars_xt:
plus_field_xt:

; ******** END OF ADDED PART TO ASSEMBLE THIS FILE INDEPENDENTLY ********

;-------------------------------------------------------------------------------
f_comma:	dw	$0000
		db	$02
		db	'F,'			; ( F: r -- )
f_comma_xt:	local
		cmp	(!ll),0			; Check if FP stack is empty
		mv	il,-44			; Floating-point stack underflow
		jpz	!throw__
		dec	(!ll)			; Decrement FP stack size
		mv	y,(!xi)			; Y holds the FP
		mv	il,12			; Copy FP TOS
		mvl	(!fp),[y++]		; to (fp)
		mv	(!xi),y			; Update FP
		mv	il,12			; Copy (fp)
		mvl	[(!wi)],(!fp)		; to dictionary space at HERE
		mv	il,12			; Alloc 12 bytes to advance HERE
		jr	!allot__
		endl
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
doflit0:	dw	$0000
		db	$02
		db	'0E'			; ( F: -- 0e )
doflit0_xt:	local
		mv	il,12
		sbcl	(!fp),(!fp)		; Clears (fp)
		jr	!fppush__
		endl
;-------------------------------------------------------------------------------
dofcon_:	dw	$0000
		db	$08
		db	'(DOFCON)'		; ( F: -- r )
dofcon__xt:	local
		mv	y,!base_address+3
		add	y,i
		mv	il,12
		mvl	[y+0],(!fp)		; Copy float constant to (fp)
		jr	!fppush__
		endl
;-------------------------------------------------------------------------------
doflit_:	dw	$0000
		db	$08
		db	'(DOFLIT)'		; ( F: -- r )
doflit__xt:	local
		mv	il,12
		mvl	[x++],(!fp)		; Copy float literal to (fp)
		endl
;---------------
fppush__:	local
		mv	y,(!xi)			; Y holds the FP
		mv	il,12
		mvl	[--y],(!fp+11)		; Copy (fp) to new FP TOS
		mv	(!xi),y			; Update FP
		inc	(!ll)			; Increment FP stack size
		jp	!fpcheck__
		endl
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
f_not_equ:	dw	$0000
		db	$03
		db	'F<>'			; ( F: r1 r2 -- ; -- flag )
f_not_equ_xt:	local
		mv	il,$41
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_less_than:	dw	$0000
		db	$02
		db	'F<'			; ( F: r1 r2 -- ; -- flag )
f_less_than_xt:	local
		mv	il,$42
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_grtr_than:	dw	$0000
		db	$02
		db	'F>'			; ( F: r1 r2 -- ; -- flag )
f_grtr_than_xt:	local
		mv	il,$43
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_equals:	dw	$0000
		db	$02
		db	'F='			; ( F: r1 r2 -- ; -- flag )
f_equals_xt:	local
		mv	il,$44
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_plus:		dw	$0000
		db	$02
		db	'F+'			; ( F: r1 r2 -- r3 )
f_plus_xt:	local
		mv	il,$47
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_minus:	dw	$0000
		db	$02
		db	'F-'			; ( F: r1 r2 -- r3 )
f_minus_xt:	local
		mv	il,$48
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_star:		dw	$0000
		db	$02
		db	'F*'			; ( F: r1 r2 -- r3 )
f_star_xt:	local
		mv	il,$49
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_slash:	dw	$0000
		db	$02
		db	'F/'			; ( F: r1 r2 -- r3 )
f_slash_xt:	local
		mv	il,$4a
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
f_star_star:	dw	$0000
		db	$03
		db	'F**'			; ( F: r1 r2 -- r3 )
f_star_star_xt:	local
		mv	il,$4b
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fexp:		dw	$0000
		db	$04
		db	'FEXP'			; ( F: r1 -- r2 )
fexp_xt:	local
		mv	il,$4c
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fsin:		dw	$0000
		db	$04
		db	'FSIN'			; ( F: r1 -- r2 )
fsin_xt:	local
		mv	il,$4d
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fcos:		dw	$0000
		db	$04
		db	'FCOS'			; ( F: r1 -- r2 )
fcos_xt:	local
		mv	il,$4e
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
ftan:		dw	$0000
		db	$04
		db	'FTAN'			; ( F: r1 -- r2 )
ftan_xt:	local
		mv	il,$4f
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fasin:		dw	$0000
		db	$05
		db	'FASIN'			; ( F: r1 -- r2 )
fasin_xt:	local
		mv	il,$50
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
facos:		dw	$0000
		db	$05
		db	'FACOS'			; ( F: r1 -- r2 )
facos_xt:	local
		mv	il,$51
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fatan:		dw	$0000
		db	$05
		db	'FATAN'			; ( F: r1 -- r2 )
fatan_xt:	local
		mv	il,$52
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fdeg:		dw	$0000
		db	$04
		db	'FDEG'			; ( F: r1 -- r2 )
fdeg_xt:	local
		mv	il,$53
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fdms:		dw	$0000
		db	$04
		db	'FDMS'			; ( F: r1 -- r2 )
fdms_xt:	local
		mv	il,$54
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fabs:		dw	$0000
		db	$05
		db	'FABS'			; ( F: r1 -- r2 )
fabs_xt:	local
		mv	il,$55
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
floor:		dw	$0000
		db	$05
		db	'FLOOR'			; ( F: r1 -- r2 )
floor_xt:	local
		mv	il,$56
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fsign:		dw	$0000
		db	$05
		db	'FSIGN'			; ( F: r1 -- r2 )
fsign_xt:	local
		mv	il,$57
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
frand:		dw	$0000
		db	$05
		db	'FRAND'			; ( F: r1 -- r2 )
frand_xt:	local
		mv	il,$58
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fsqrt:		dw	$0000
		db	$05
		db	'FSQRT'			; ( F: r1 -- r2 )
fsqrt_xt:	local
		mv	il,$59
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
flog:		dw	$0000
		db	$04
		db	'FLOG'			; ( F: r1 -- r2 )
flog_xt:	local
		mv	il,$5a
		jr	!fop__
		endl
;-------------------------------------------------------------------------------
fln:		dw	$0000
		db	$03
		db	'FLN'			; ( F: r1 -- r2 )
fln_xt:		local
		mv	il,$5b
		;jr	!fop__			; Fall through to fop__
		endl
;---------------
fop__:		local
		pushu	ba			; Save TOS
		mv	a,il			; A holds the function/operation $41 to $5b
		dec	(!ll)			; Decrement FP stack size
		mv	y,(!xi)			; Y holds the FP
		mvw	(!fp),[y++]		; Copy first float argument sign/exp pair
		mv	il,10
		mvl	(!fp+3),[y++]		; Copy first float argument 20 BCD digits
		cmp	a,$4c			; Single argument operation?
		jrnc	lbl1
		dec	(!ll)			; Decrement FP stack size
		mvw	(!fp+3),[y++]		; Copy second float argument sign/exp pair
		mv	il,10
		mvl	(!fp+18),[y++]		; Copy second float argument 20 BCD digits
lbl1:		mv	(!xi),y			; Update FP
		pushu	a			; Save function/operation
		pushu	x			; Save IP (FIXME: is this needed?)
		pre_on
		mvw	(!cx),$0009		; Function driver
		mv	il,a			; Function $41 to $7f
		callf	!iocs			;
		pre_off
		popu	x			; Restore IP (FIXME: is this needed?)
		popu	a			; Restore A
		jrc	lbl2			; Error?
		cmp	a,$47			; Is this a comparison operator ($41 to $46)?
		jrc	lbl4
		mv	y,(!xi)			; Y holds the FP
		mv	il,10
		mvl	[--y],(!fp+12)		; Copy float result 20 BCD digits FIXME check if [--y] works as specified
		mvw	[--y],(!fp)		; Copy float result sign/exp pair
		inc	(!ll)			; Increment FP stack size
		mv	(!xi),y			; Update FP
		popu	ba			; Set new TOS
		jr	!fpcheck__		; Post check FP stack
lbl2:		; FIXME: throw -43 floating-point result out of range
		mv	il,-46			; Floating-point invalid argument
		cmp	a,$4a			; Division?
		jrnz	lbl3
		mv	il,-42			; Floating-point divide by zero
lbl3:		jp	!throw__
lbl4:		sub	ba,ba			; Set new TOS to FALSE
		shr	(!fp)			; Set A to sign byte (carry was unset)
		jrnc	!fpcheck__		; Result is non-negative?
		dec	ba			; Set new TOS to TRUE
		endl
;---------------
fpcheck__:	local
		cmp	(!ll),!f_size		; Check FP stack size
		jpc	!cont__
		mv	il,(!ll)
		add	il,il			; Check if FP stack size is negative
		mv	il,-45			; Floating-point stack underflow
		jrc	lbl1			; FP stack size is negative?
		mv	il,-44			; Floating-point stack overflow
lbl1:		jp	!throw__
		endl
;-------------------------------------------------------------------------------
f_drop:		dw	fop__
		db	$05
		db	'FDROP'			; ( F: r -- )
f_drop_xt:	local
		dec	(!ll)			; Decrement FP stack size
		pmdf	(!xi),12		; Increment FP by FP width
		jr	!fpcheck__		; Post check FP stack
		endl
;-------------------------------------------------------------------------------
f_dup:		dw	f_drop
		db	$04
		db	'FDUP'			; ( F: r -- r r )
f_dup_xt:	local
		mv	il,12
		mvl	(!fp),[(!xi)]		; Copy FP TOS to (fp)
		jp	!fppush__
		endl
;-------------------------------------------------------------------------------
f_over:		dw	f_dup
		db	$05
		db	'FOVER'			; ( F: r1 r2 -- r1 r2 r1 )
f_over_xt:	local
		mv	y,(!xi)			; Y holds the FP
		mv	il,12
		mvl	(!fp),[y+12]		; Copy FP 2OS to (fp)
		jp	!fppush__
		endl
;-------------------------------------------------------------------------------
f_swap:		dw	f_over
		db	$05
		db	'FSWAP'			; ( F: r1 r2 -- r2 r1 )
f_swap_xt:	local
		mv	y,(!xi)			; Y holds the FP
		mv	il,12
		mvl	(!fp),[y+0]		; Copy FP TOS to (fp)
		mv	il,12
		mvl	(!fp+12),[y+12]		; Copy FP 2OS to (fp+12)
		mv	il,12
		mvl	[y+0],(!fp+12)		; Copy (fp+12) to FP TOS
		mv	il,12
		mvl	[y+12],(!fp)		; Copy (fp) to FP 2OS
		jr	!fpcheck__		; Post check FP stack
		endl
;-------------------------------------------------------------------------------
f_rot:		dw	f_swap
		db	$04
		db	'FROT'			; ( F: r1 r2 r3 -- r2 r3 r1 )
f_rot_xt:	local
		mv	y,(!xi)			; Y holds the FP
		mv	il,12
		mvl	(!fp),[y+24]		; Copy FP 3OS to (fp)
		mv	il,24
		mvl	(!fp+12),[y+0]		; Copy FP TOS/2OS to (fp+12)
		mv	il,24
		mvl	[y+12],(!fp+15)		; Copy (fp+12) to FP 2OS/3OS
		mv	il,12
		mvl	[y+0],(!fp)		; Copy (fp) to FP TOS
		jr	!fpcheck__		; Post check FP stack
		endl
;-------------------------------------------------------------------------------
f_fetch:	dw	f_rot
		db	$02
		db	'F@'			; ( f-addr -- ; F: -- r )
f_fetch_xt:	local
		mv	y,!base_address
		add	y,ba			; Y holds the address of the float
		mv	il,12
		mvl	(!fp),[y+0]		; Copy float at address Y to (fp)
		popu	ba			; Set new TOS
		jp	!fppush__
		endl
;-------------------------------------------------------------------------------
f_store:	dw	f_fetch
		db	$02
		db	'F!'			; ( F: r -- ; f-addr -- )
f_store_xt:	local
		mv	y,(!xi)			; Y holds the FP
		mv	il,12
		mvl	(!fp),[y++]		; Copy FP TOS to (fp)
		mv	(!xi),y			; Update FP
		mv	y,!base_address
		add	y,ba			; Y holds the address of the float
		mv	il,12
		mvl	[y+0],(!fp)		; Copy (fp) to float at address Y
		popu	ba			; Set new TOS
		dec	(!ll)			; Increment FP stack size
		jr	!fpcheck__		; Post check FP stack
		endl
;-------------------------------------------------------------------------------


;-------------------------------------------------------------------------------
f_to_d:		dw	$0000
		db	$03
		db	'F>D'			; ( F: r -- ; -- d )
f_to_d_xt:	local
		pushu	ba			; Save TOS
		mv	y,(!xi)			; Y holds the FP
		mvw	(!fp),[y++]		; Copy float argument sign/exp pair
		mv	il,10
		mvl	(!fp+3),[y++]		; Copy float argument 20 BCD digits
		mv	(!xi),y			; Update FP
		pushu	x			; Save IP (FIXME: is this needed?)
		pre_on
		mvw	(!cx),$0009		; Function driver
		mv	il,$7e			; Function decimal->binary conversion
		callf	!iocs			;
		pre_off
		popu	x			; Restore IP (FIXME: is this needed?)
		jrc	lbl1			; Error?
		mv	ba,(!fp)		; Set new 2OS
		pushu	ba			; to low-order result
		mv	ba,(!fp+2)		; Set new TOS to high-order result
		dec	(!ll)			; Decrement FP stack size
		jp	!fpcheck__
lbl1:		mv	il,$46			; Floating-point invalid argument
		jp	!throw__
		endl
;-------------------------------------------------------------------------------
d_to_f:		dw	$0000
		db	$03
		db	'D>F'			; ( d -- ; F: -- r )
d_to_f_xt:	local
		mv	(!fp+2),ba		; Move TOS to high-order part of (fp)
		popu	ba			; Move 2OS to
		mv	(!fp),ba		; low-order part of (fp)
		pushu	x			; Save IP (FIXME: is this needed?)
		pre_on
		mvw	(!cx),$0009		; Function driver
		mv	il,$7f			; Function binary->decimal conversion
		callf	!iocs			;
		pre_off
		popu	x			; Restore IP (FIXME: is this needed?)
		;jrc	lbl1			; Error? FIXME can this ever happen, probably not
		mv	y,(!xi)			; Y holds the FP
		mv	il,10
		mvl	[--y],(!fp+12)		; Copy float result 20 BCD digits
		mvw	[--y],(!fp)		; Copy float result sign/exp pair
		mv	(!xi),y			; Update FP
		popu	ba			; Set new TOS
		inc	(!ll)			; Increment FP stack size
		jp	!fpcheck__
;lbl1:		mv	il,$43			; Floating-point result out of range
;		jp	!throw__
		endl
;-------------------------------------------------------------------------------
to_float:	dw	$0000
		db	$06
		db	'>FLOAT'		; ( c-addr u -- flag ; F: -- r )
to_float_xt:	local
		mv	(!fp),$80		; Set (fp) to string marker $80
		mv	(!fp+4),a		; Move TOS low-order byte to (fp+4) length argument
		popu	ba			; Move 2OS to (fp+1) string pointer argument
		mv	y,!base_address
		add	y,ba
		mv	(!fp+1),y
		pushu	x			; Save IP (FIXME: is this needed?)
		pre_on
		mvw	(!cx),$0009		; Function driver
		mv	il,$79			; Function VAL
		callf	!iocs			;
		pre_off
		popu	x			; Restore IP (FIXME: is this needed?)
		mv	y,(!xi)			; Y holds the FP
		mv	il,10
		mvl	[--y],(!fp+12)		; Copy float result 20 BCD digits
		mvw	[--y],(!fp)		; Copy float result sign/exp pair
		mv	(!xi),y			; Update FP
		mv	ba,$ffff		; Set new TOS to TRUE
		jrnc	lbl1			; Error?
		inc	ba			; Set new TOS to FALSE
lbl1:		inc	(!ll)			; Increment FP stack size
		jp	!fpcheck__
		endl
;-------------------------------------------------------------------------------
represent:	dw	$0000
		db	$09
		db	'REPRESENT'		; ( c-addr u -- n flag1 flag2 ; F: r -- )
represent_xt:	local
;		SAVE BUFFER SIZE
		mv	(!ex),ba		; Save buffer size
		ex	a,b
		cmp	a,0			; Check if high-order buffer size byte is zero
		ex	a,b
		jrz	lbl1			; High-order buffer size byte is zero?
		mv	a,$ff			; Set low-order buffer size byte to $ff
lbl1:		mv	(!fl),a			; Save adjusted low-order buffer size byte
;		MOVE FP TOS TO (fp)
		mv	y,(!xi)			; Y holds the FP
		mv	il,12
		mvl	(!fp),[y++]		; Copy FP TOS to (fp)
		mv	(!xi),y			; Update FP
;		DETERMINE NUMBER OF BCD BYTES AND DIGITS
		mv	a,5			; Number of BCD bytes in single precision float
		test	(!fp),$08		; Check if double precision
		jrz	lbl2			; Single precision?
		mv	a,10			; Number of BCD bytes in double precision float
lbl2:		mv	(!gl),a			; Save the number of BCD bytes
		add	a,a			; Double number of BCD bytes -> number of digits
		mv	(!hl),a			; Save the number of digits
;		CHECK IF ALL DIGITS FIT IN THE BUFFER
		;mv	a,(!hl)			; A holds the number of digits
		cmp	(!fl),a			; Compare A holding the number of digits to the buffer size
		jrnc	lbl4			; Buffer size can hold all digits?
;		ROUND IF WE HAVE MORE DIGITS THAN THAT CAN FIT IN THE BUFFER
		mv	a,(!fl)			; A holds the buffer size
		mv	(!hl),a			; Reduce the number of digits to the buffer size
		rc
		shr	a			; Check if A is even
		mv	il,a			; IL is half A -> number of BCD bytes
		mv	a,$50			; A holds $50
		jrnc	lbl3			; A was even?
		swap	a			; A holds $05
lbl3:		inc	il			; Increment IL to add A to the BCD byte after the last BCD we need
		mv	($ed),il
		add	($ed),!fp+1		; PX holds fp+1+IL
		dadl	(px),a			; Add A to (fp+2..fp+1+I)
		jrnc	lbl4			; No carry?
		mv	il,(!gl)		; IL holds the unadjusted number of BCD bytes
		dsrl	(!fp+2)			; Shift right BCD (fp+2..)
		or	(!fp+2),$10		; Set upper BCD digit to 1
		inc	(!fp+1)			; Increment exponent, which could become larger than 99
;		COPY DIGITS TO BUFFER
lbl4:		mv	il,(!hl)		; IL holds the number of digits to copy to the buffer
		mv	($ed),!fp+2		; PX holds fp+2 pointing to the first BCD byte to copy
		popu	ba			; BA holds the 2OS short address of the buffer
		mv	y,!base_address
		add	y,ba			; Y holds the address of the buffer
		inc	il			; Increment digit counter
lbl4a:		dec	il			; Decrement digit counter
		jrz	lbl4b			; Digit counter is zero?
		mv	a,(px)			; Get BCD byte
		swap	a			; upper digit
		and	a,$0f			; and convert
		add	a,'0'			; to ASCII
		mv	[y++],a			; Copy upper digit to the buffer
		dec	il			; Decrement digit counter
		jrz	lbl4b			; Digit counter is zero?
		mv	a,(px)			; Get lower BCD digit
		and	a,$0f			; and convert
		add	a,'0'			; to ASCII
		mv	[y++],a			; Copy lower digit to the buffer
		inc	($ed)			; Increment PX
		jr	lbl4a			; Loop until all digits are stored
;		FILL THE REST OF THE BUFFER WITH '0'
lbl4b:		mv	ba,(!ex)		; BA holds the buffer size
		mv	il,(!hl)		; I holds the number of digits copied to the buffer
		sub	ba,i			; BA holds the number of zeros to fill the rest of the buffer
		jrz	lbl4d			; No zeros to fill?
		mv	il,'0'
lbl4c:		mv	[y++],il		; Copy '0' to the buffer
		dec	ba
		jrnz	lbl4c			; Loop until buffer filled
;		RETURN EXPONENT
lbl4d:		mv	a,(!fp+1)		; A holds the exponent
		inc	a			; Increment exponent, because all digits are to the right of .
		test	a,$80			; Check if exponent is negative
		ex	a,b
		mv	a,$00			; No sign extend
		jrnz	lbl5			; Exponent is non-negative?
		mv	a,$ff			; Sign extend negative exponent to BA
lbl5:		ex	a,b			; BA holds exponent
		pushu	ba			; Set new 3OS to exponent
;		RETURN SIGN FLAG
		sub	ba,ba			; BA holds FALSE
		test	(!fp),1			; Check if negative
		jrz	lbl6			; Is non-negative?
		dec	ba			; BA holds TRUE
lbl6:		pushu	ba			; Set new 2OS
;		RETURN SECOND FLAG
		mv	ba,$ffff		; Set new TOS to TRUE
		dec	(!ll)			; Decrement FP stack size
		jp	!fpcheck__
		endl
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
fp_fetch:	dw	$0000
		db	$03
		db	'FP@'			; ( -- addr )
fp_fetch_xt:	local
		pushu	ba			; Save TOS
		mv	ba,(!xi)		; Set new TOS to FP short address
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
fp_store:	dw	$0000
		db	$03
		db	'FP!'			; ( addr -- )
fp_store_xt:	local
		mv	(!xi),ba		; Set FP to TOS (segment byte is unchanged)
		mv	i,!f_beginning
		sub	i,ba			; I is the new FP stack depth in bytes (only low-order IL is relevant)
		mv	a,12
		mv	(!ll),-1		; Set FP stack depth to -1
lbl1:		inc	(!ll)			; Increment FP stack depth
		sub	il,a			; Subtract 12 from IL
		jrnc	lbl1			; Until IL<0
		popu	ba			; Set new TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
fdepth:		dw	$0000
		db	$06
		db	'FDEPTH'		; ( -- n )
fdepth_xt:	local
		pushu	ba			; Save TOS
		sub	ba,ba
		mv	a,(!ll)			; Set new TOS to FP stack size
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
float_plus:	dw	$0000
		db	$06
		db	'FLOAT+'		; ( f-addr -- f-addr )
float_plus_xt:	local
		mv	il,12			; Set I to 12
		add	ba,i			; Increment TOS by 12
		jp	!cont__
		endl
;-------------------------------------------------------------------------------
floats:		dw	$0000
		db	$06
		db	'FLOATS'		; ( n -- n )
floats_xt:	local
		add	ba,ba
		add	ba,ba
		mv	i,ba
		add	ba,ba
		add	ba,i			; Set TOS to 12 times old TOS
		jp	!cont__
		endl
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
f_negate:	dw	$0000
		db	$07
		db	'FNEGATE'
f_negate_xt:	local
		jp	!docol__xt		; : FNEGATE ( F: r1 -- r2 )
		dw	!doflit0_xt		;   0E
		dw	!f_swap_xt		;   FSWAP
		dw	!f_minus_xt		;   F-
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_min:		dw	$0000
		db	$04
		db	'FMIN'
f_min_xt:	local
		jp	!docol__xt		; : FMIN ( F: r1 r2 -- r3 )
		dw	!f_over_xt		;   FOVER
		dw	!f_over_xt		;   FOVER
		dw	!f_grtr_than_xt		;   F>
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!f_swap_xt	;     FSWAP THEN
lbl2:		dw	!f_drop_xt		;   FDROP
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_max:		dw	$0000
		db	$04
		db	'FMAX'
f_max_xt:	local
		jp	!docol__xt		; : FMAX ( F: r1 r2 -- r3 )
		dw	!f_over_xt		;   FOVER
		dw	!f_over_xt		;   FOVER
		dw	!f_less_than_xt		;   F<
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!f_swap_xt	;     FSWAP THEN
lbl2:		dw	!f_drop_xt		;   FDROP
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_zero_less:	dw	$0000
		db	$03
		db	'F0<'
f_zero_less_xt:	local
		jp	!docol__xt		; : F0< ( F: r -- ; -- flag )
		dw	!doflit0_xt		;   0E
		dw	!f_less_than_xt		;   F<
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_zero_equ:	dw	$0000
		db	$03
		db	'F0='
f_zero_equ_xt:	local
		jp	!docol__xt		; : F0= ( F: r -- ; -- flag )
		dw	!doflit0_xt		;   0E
		dw	!f_equals_xt		;   F=
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_round:	dw	$0000
		db	$06
		db	'FROUND'
f_round_xt:	local
		jp	!docol__xt		; : FROUND ( F: r1 -- r2 )
		dw	!doflit__xt		;   .5E
		db	0,-1,$50,0,0,0,0,0,0,0,0,0
		dw	!f_plus_xt		;   F+
		dw	!floor_xt		;   FLOOR
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_align:	dw	$0000
		db	$06
		db	'FALIGN'
f_align_xt:	local
		jp	!cont__			; Does nothing
		endl
;-------------------------------------------------------------------------------
f_aligned:	dw	$0000
		db	$08
		db	'FALIGNED'
f_aligned_xt:	local
		jp	!cont__			; Does nothing
		endl
;-------------------------------------------------------------------------------
f_literal:	dw	$0000
		db	$88
		db	'FLITERAL'
f_literal_xt:	local
		jp	!docol__xt		; : FLITERAL ( F: r -- )
		dw	!quest_comp_xt		;   ?COMP
		dw	!dolit__xt		;   ['] (DOFLIT)
		dw	!doflit__xt		;
		dw	!compile_com_xt		;   COMPILE,
		dw	!f_comma_xt		;   F,
		dw	!doexit__xt		; ; IMMEDIATE
		endl
;-------------------------------------------------------------------------------
f_constant:	dw	$0000
		db	$09
		db	'FCONSTANT'
f_constant_xt:	local
		jp	!docol__xt		; : FCONSTANT ( F: r -- ; "<spaces>name" -- ; F: -- r )
		dw	!create_hdr_xt		;   CREATE-HEADER
		dw	!dolit__xt		;   ['] (DOFCON)
		dw	!dofcon__xt
		dw	!cfa_comma_xt		;   CFA,
		dw	!f_comma_xt		;   F,
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_variable:	dw	$0000
		db	$09
		db	'FVARIABLE'
f_variable_xt:	local
		jp	!docol__xt		; : FVARIABLE ( F: r -- ; "<spaces>name" -- ; -- f-addr )
		dw	!create_xt		;   CREATE
		dw	!doflit0_xt		;   0E
		dw	!f_comma_xt		;   F,
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_field:	dw	$0000
		db	$07
		db	'FFIELD:'
f_field_xt:	local
		jp	!docol__xt		; : FFIELD: ( u "<spaces>name" -- u ; addr -- addr )
		dw	!dolit__xt		;   12
		dw	12			;
		dw	!plus_field_xt		;   +FIELD
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
precision:	dw	$0000
		db	$09
		db	'PRECISION'
precision_xt:	local
		jp	!doval__xt		; 20 VALUE PRECISION
		dw	20
		endl
;-------------------------------------------------------------------------------
set_prec:	dw	$0000
		db	$0d
		db	'SET-PRECISION'
set_prec_xt:	local
		jp	!docol__xt		; : SET-PRECISION ( u -- )
		dw	!dolit__xt		;   #hold_size
		dw	!hold_size		;   \ ENVIRONMENT? /HOLD size
		dw	!umin_xt		;   UMIN
		dw	!doto__xt		;   TO PRECISION
		dw	!precision_xt+3		;
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
;dash_chars:	dw	$0000
;		db	$06
;		db	'-CHARS'		; ( c-addr u char -- c-addr u )
;dash_chars_xt:	local
;		mv	(!el),a			; Save TOS low-order byte
;		popu	i			; I holds the length of the string to adjust
;		mv	y,!base_address
;		add	y,i
;		mv	ba,[u]			; BA holds the short address of the string
;		add	y,ba			; Y holds the address of the last character of the string + 1
;		inc	i
;		jr	lbl2
;lbl1:		mv	a,[--y]			; Read characters from the end
;		cmp	(!el),a			; Compare current character
;		jrnz	lbl3
;lbl2:		dec	i			; Is the begining of the string reached?
;		jrnz	lbl1
;lbl3:		mv	ba,i			; Set new TOS
;		jp	!cont__
;		endl
;-------------------------------------------------------------------------------
zeros:		dw	$0000
		db	$05
		db	'ZEROS'
zeros_xt:	local
		jp	!docol__xt		; : ZEROS ( u -- )
		dw	!dolit0_xt		;   0
		dw	!quest_do__xt		;   ?DO
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     [CHAR] 0
			dw	'0'		;
			dw	!emit_xt	;     EMIT
		dw	!loop__xt		;   LOOP
		dw	lbl2-lbl1		;
lbl2:		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_s_dot:	dw	$0000
		db	$03
		db	'FS.'
f_s_dot_xt:	local
		jp	!docol__xt		; : FS. ( F: r -- )
		dw	!here_xt		;   HERE
		dw	!precision_xt		;   PRECISION
		dw	!represent_xt		;   REPRESENT
		dw	!drop_xt		;   DROP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     [CHAR] -
			dw	'-'		;
			dw	!emit_xt	;     EMIT THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!c_fetch_xt		;   C@
		dw	!emit_xt		;   EMIT
		dw	!dolit__xt		;   [CHAR] .
		dw	'.'			;
		dw	!here_xt		;   HERE
		dw	!c_store_xt		;   C!
		dw	!here_xt		;   HERE
		dw	!precision_xt		;   PRECISION
		dw	!type_xt		;   TYPE
		dw	!dolit__xt		;   [CHAR] E
		dw	'E'			;
		dw	!emit_xt		;   EMIT
		dw	!one_minus_xt		;   1-
		dw	!dot_xt			;   .
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
f_dot:		dw	$0000
		db	$02
		db	'F.'
f_dot_xt:	local
		jp	!docol__xt		; : F. ( F: r -- )
		dw	!here_xt		;   HERE
		dw	!precision_xt		;   PRECISION
		dw	!represent_xt		;   REPRESENT
		dw	!drop_xt		;   DROP
		dw	!if__xt			;   IF
		dw	lbl2-lbl1		;
lbl1:			dw	!dolit__xt	;     [CHAR] -
			dw	'-'		;
			dw	!emit_xt	;     EMIT THEN
lbl2:		dw	!here_xt		;   HERE
		dw	!precision_xt		;   PRECISION
		dw	!dolit__xt		;   [CHAR] 0
		dw	'0'			;
		dw	!dash_chars_xt		;   -CHARS
		dw	!dolit1_xt		;   1
		dw	!umax_xt		;   UMAX
		dw	!nip_xt			;   NIP      \ exp digits
		dw	!over_xt		;   OVER
		dw	!zer_grt_thn_xt		;   0>
		dw	!invert_xt		;   INVERT
		dw	!if__xt			;   IF       \ if exp<=0
		dw	lbl4-lbl3		;
lbl3:			dw	!doslit__xt	;     ." 0."
			dw	2		;
			db	'0.'		;
			dw	!type_xt	;
			dw	!swap_xt	;     SWAP
			dw	!negate_xt	;     NEGATE \ digits -exp
			dw	!zeros_xt	;     ZEROS
			dw	!here_xt	;     HERE
			dw	!swap_xt	;     SWAP   \ here digits
			dw	!type_xt	;     TYPE
		dw	!ahead__xt		;   ELSE
		dw	lbl7-lbl4		;
lbl4:		dw	!two_dup_xt		;   2DUP
		dw	!less_xt		;   <
		dw	!invert_xt		;   INVERT
		dw	!if__xt			;   IF       \ if exp>=digits
		dw	lbl6-lbl5		;
lbl5:			dw	!here_xt	;     HERE
			dw	!over_xt	;     OVER   \ exp digits here digits
			dw	!type_xt	;     TYPE
			dw	!minus_xt	;     -      \ exp-digits
			dw	!zeros_xt	;     ZEROS
			dw	!dolit__xt	;     [CHAR] .
			dw	'.'		;
			dw	!emit_xt	;     EMIT
		dw	!ahead__xt		;   ELSE     \ if 0<exp<digits
		dw	lbl7-lbl6		;
lbl6:			dw	!swap_xt	;     SWAP
			dw	!here_xt	;     HERE
			dw	!over_xt	;     OVER   \ digits exp here exp
			dw	!type_xt	;     TYPE
			dw	!dolit__xt	;     [CHAR] .
			dw	'.'		;
			dw	!emit_xt	;     EMIT
			dw	!here_xt	;     HERE
			dw	!over_xt	;     OVER   \ digits exp here exp
			dw	!plus_xt	;     +
			dw	!not_rot_xt	;     -ROT
			dw	!minus_xt	;     -      \ here+exp digits-exp
			dw	!type_xt	;     TYPE THEN THEN
lbl7:		dw	!space_xt		;   SPACE
		dw	!doexit__xt		; ;
		endl
;-------------------------------------------------------------------------------
;
; : F.
;   HERE PRECISION REPRESENT DROP
;   IF ." -" EMIT THEN
;   HERE PRECISION [CHAR] 0 -CHARS 1 UMAX NIP
;   OVER 0> INVERT IF
;     ." 0." SWAP NEGATE ZEROS HERE SWAP TYPE
;   ELSE 2DUP < INVERT IF
;     HERE OVER TYPE - ZEROS ." ."
;   ELSE
;     SWAP HERE OVER TYPE ." ." HERE OVER + -ROT - TYPE
;   THEN THEN SPACE ;
;
; without stripping zeros:
; : F.
;   HERE PRECISION REPRESENT DROP
;   IF ." -" THEN
;   DUP 0> INVERT IF
;     ." 0." NEGATE ZEROS HERE PRECISION TYPE
;   ELSE DUP PRECISION < INVERT IF
;     HERE PRECISION TYPE PRECISION - ZEROS
;   ELSE
;     HERE OVER TYPE ." ." PRECISION OVER - HERE + SWAP TYPE
;   THEN THEN SPACE ;

; : ZEROS 0 ?DO [CHAR] 0 EMIT LOOP ;

;
; : FS.
;   HERE PRECISION REPRESENT DROP
;   IF ." -" THEN
;   HERE C@ EMIT [CHAR] . HERE C! HERE PRECISION TYPE ." E" 1- . ;



;-------------------------------------------------------------------------------
;
; FLOAT:
;	: FVARIABLE	CREATE 0E F, ;
;	: FCONSTANT	CREATE F, DOES> F@ ;
;	: FLITERAL	?COMP POSTPONE (DOFLIT) F, ; IMMEDIATE
;	: FALIGN	;
;	: FALIGNED	;
;	: FMAX		FOVER FOVER F< IF FSWAP THEN FDROP ;
;	: FMIN		FOVER FOVER F> IF FSWAP THEN FDROP ;
;	: FNEGATE	0E FSWAP F- ;
;	: F0<		0E F< ;
;	: F0=		0E F= ;
;	: FROUND	.5E F+ FLOOR ;
;
; Note that both single and double precision floating point values are the same
; width and do not require separate words, therefore:
;	: SF!		F@ ;
;	: SF@		F@ ;
;	: SFALIGN	;
;	: SFALIGNED	;
;	: SFIELD:	FFIELD: ;
;	: SFLOAT+:	FLOAT+: ;
;	: SFLOATS:	FLOATS: ;
;	: DF!		F@ ;
;	: DF@		F@ ;
;	: DFALIGN	;
;	: DFALIGNED	;
;	: DFIELD:	FFIELD: ;
;	: DFLOAT+:	FLOAT+: ;
;	: DFLOATS:	FLOATS: ;
;
; Extra words:
;   F= F> F<> F, FDEG FDMS FSIGN FRAND
;
;   All 31 FLOAT words
;   17 FLOAT-EXT words + 14 words implicitly (all DFxxx double precision and SFxxx single precision words are the same as Fxxx words)
;
; Missing words can be implemented as follows:
; : FSINH  ... ;
;
;
;-------------------------------------------------------------------------------
_end_:		end

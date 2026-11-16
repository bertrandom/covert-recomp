; INTROLIB.ASM - INTRO's own small library (INTRO links no MSC string or DOS
; routines): BIOS/DOS interrupt calls, number formatting, text output, string
; and memory helpers. Near C calls; the piece of _TEXT between INTRO.C's code and
; the MSC runtime. INTRO.C uses set_cursor, do_interrupt, int_to_str, print_at,
; dos_newline and str_cat; the other helpers are not called.

DGROUP	GROUP	_DATA
	ASSUME	DS:DGROUP

_DATA	SEGMENT WORD PUBLIC 'DATA'
	EXTRN	_regs:BYTE		; union REGS (INTRO.C), used by set_cursor
_DATA	ENDS

_TEXT	SEGMENT WORD PUBLIC 'CODE'
	ASSUME	CS:_TEXT
	PUBLIC	_set_cursor, _str_cat, _do_interrupt, _int_to_str, _print_at, _dos_newline

; ----------------------------------------------------------------------------
; void set_cursor(int row, int col): BIOS cursor position (page 0)
; ----------------------------------------------------------------------------
_set_cursor:
	push	bp
	mov	bp, sp
	mov	byte ptr _regs+1, 2
	mov	byte ptr _regs+3, 0
	mov	al, [bp+4]
	mov	_regs+7, al
	mov	al, [bp+6]
	mov	_regs+6, al
	mov	ax, offset DGROUP:_regs
	push	ax
	push	ax
	mov	ax, 10h
	push	ax
	call	_do_interrupt
	add	sp, 6
	pop	bp
	ret

; ----------------------------------------------------------------------------
; out_port
; out_port(port, value)
; ----------------------------------------------------------------------------
out_port:
	push	bp
	mov	bp, sp
	mov	dx, [bp+4]
	sub	ax, ax
	mov	al, [bp+6]
	out	dx, al
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_upper
; str_upper(s): to upper case in place
; ----------------------------------------------------------------------------
str_upper:
	push	bp
	mov	bp, sp
	push	ds
	pop	es
	mov	si, [bp+4]
str_upper_1:
	cmp	byte ptr [si], 0
	je	str_upper_3
	mov	al, [si]
	cmp	al, 61h
	jl	str_upper_2
	cmp	al, 7Ah
	jg	str_upper_2
	sub	al, 20h
	mov	[si], al
str_upper_2:
	inc	si
	jmp	str_upper_1
str_upper_3:
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_equal
; str_equal(a, b): 1 if equal
; ----------------------------------------------------------------------------
str_equal:
	push	bp
	mov	bp, sp
	push	ds
	pop	es
	mov	si, [bp+4]
	mov	di, [bp+6]
str_equal_1:
	cmp	byte ptr [si], 0
	jne	str_equal_2
	cmp	byte ptr [di], 0
	je	str_equal_3
	jmp	str_equal_4
str_equal_2:
	cmp	byte ptr [di], 0
	je	str_equal_4
	lodsb
	cmp	al, [di]
	jne	str_equal_4
	inc	di
	jmp	str_equal_1
str_equal_3:
	mov	ax, 1
	jmp	str_equal_5
str_equal_4:
	mov	ax, 0
str_equal_5:
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_copy
; str_copy(dst, src)
; ----------------------------------------------------------------------------
str_copy:
	push	bp
	mov	bp, sp
	push	si
str_copy_1:
	mov	bx, [bp+4]
	inc	word ptr [bp+4]
	mov	si, [bp+6]
	inc	word ptr [bp+6]
	mov	al, [si]
	mov	[bx], al
	or	al, al
	jne	str_copy_1
	pop	si
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_copy_to_far
; str_copy_to_far(char far *dst, src)
; ----------------------------------------------------------------------------
str_copy_to_far:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	les	di, dword ptr [bp+4]
	mov	si, [bp+8]
str_copy_to_far_1:
	lodsb
	stosb
	or	al, al
	jne	str_copy_to_far_1
	pop	es
	pop	di
	pop	si
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_copy_from_far
; str_copy_from_far(dst, char far *src)
; ----------------------------------------------------------------------------
str_copy_from_far:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	push	ds
	push	ds
	pop	es
	lds	si, dword ptr [bp+6]
	mov	di, [bp+4]
str_copy_from_far_1:
	lodsb
	stosb
	or	al, al
	jne	str_copy_from_far_1
	pop	ds
	pop	es
	pop	di
	pop	si
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_length_neg
; str_length_neg(s): -(length + 2)
; ----------------------------------------------------------------------------
str_length_neg:
	push	bp
	mov	bp, sp
	mov	ax, [bp+4]
str_length_neg_1:
	mov	bx, [bp+4]
	inc	word ptr [bp+4]
	cmp	byte ptr [bx], 0
	jne	str_length_neg_1
	mov	bx, [bp+4]
	sub	ax, bx
	not	ax
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_length_far
; str_length_far(char far *s)
; ----------------------------------------------------------------------------
str_length_far:
	push	bp
	mov	bp, sp
	push	ds
	lds	si, dword ptr [bp+4]
	sub	bx, bx
str_length_far_1:
	lodsb
	cmp	al, 0
	je	str_length_far_2
	inc	bx
	jmp	str_length_far_1
str_length_far_2:
	mov	ax, bx
	pop	ds
	pop	bp
	ret

; ----------------------------------------------------------------------------
; void str_cat(dst, src)
; ----------------------------------------------------------------------------
_str_cat:
	push	bp
	mov	bp, sp
	push	si
str_cat_1:
	mov	bx, [bp+4]
	cmp	byte ptr [bx], 0
	je	str_cat_3
	inc	word ptr [bp+4]
	jmp	str_cat_1
str_cat_2:
	inc	word ptr [bp+4]
	mov	bx, [bp+4]
str_cat_3:
	mov	si, [bp+6]
	inc	word ptr [bp+6]
	mov	al, [si]
	mov	[bx], al
	or	al, al
	jne	str_cat_2
	pop	si
	pop	bp
	ret

; ----------------------------------------------------------------------------
; str_find_char
; str_find_char(s, c): pointer to c in s, or 0
; ----------------------------------------------------------------------------
str_find_char:
	push	bp
	mov	bp, sp
	push	si
	mov	ax, [bp+6]
str_find_char_1:
	mov	bx, [bp+4]
	cmp	byte ptr [bx], 0
	je	str_find_char_2
	cmp	[bx], al
	je	str_find_char_3
	inc	word ptr [bp+4]
	jmp	str_find_char_1
str_find_char_2:
	mov	ax, 0
	jmp	str_find_char_4
str_find_char_3:
	mov	ax, bx
str_find_char_4:
	pop	si
	pop	bp
	ret

; ----------------------------------------------------------------------------
; mem_set
; mem_set(dst, value, n)
; ----------------------------------------------------------------------------
mem_set:
	push	bp
	mov	bp, sp
	push	si
	push	ds
	pop	es
	mov	al, [bp+6]
	mov	di, [bp+4]
	mov	cx, [bp+8]
	rep	stosb
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; mem_set_far
; mem_set_far(char far *dst, value, n)
; ----------------------------------------------------------------------------
mem_set_far:
	push	bp
	mov	bp, sp
	push	si
	push	es
	mov	al, [bp+8]
	les	di, dword ptr [bp+4]
	mov	cx, [bp+0Ah]
	rep	stosb
	pop	es
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; mem_copy
; mem_copy(dst, src, n)
; ----------------------------------------------------------------------------
mem_copy:
	push	bp
	mov	bp, sp
	push	si
	mov	cx, [bp+8]
mem_copy_1:
	mov	si, [bp+4]
	inc	word ptr [bp+4]
	mov	bx, [bp+6]
	inc	word ptr [bp+6]
	mov	dl, [bx]
	mov	[si], dl
	loop	mem_copy_1
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; mem_copy_from_far
; mem_copy_from_far(dst, char far *src, n)
; ----------------------------------------------------------------------------
mem_copy_from_far:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	push	ds
	push	ds
	pop	es
	mov	cx, [bp+0Ah]
	mov	di, [bp+4]
	lds	si, dword ptr [bp+6]
	rep	movsb
	pop	ds
	pop	es
	pop	di
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; mem_equal
; mem_equal(a, b, n): 1 if equal (compares words at byte steps)
; ----------------------------------------------------------------------------
mem_equal:
	push	bp
	mov	bp, sp
	push	si
	mov	cx, [bp+8]
mem_equal_1:
	mov	si, [bp+4]
	inc	word ptr [bp+4]
	mov	ax, [si]
	mov	bx, [bp+6]
	inc	word ptr [bp+6]
	cmp	ax, [bx]
	loope	mem_equal_1
	or	cx, cx
	je	mem_equal_2
	mov	ax, 0
	jmp	mem_equal_3
mem_equal_2:
	mov	ax, 1
mem_equal_3:
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; void do_interrupt(int n, REGS *in, REGS *out): INT 10h, 21h, 16h or 1Ah
; with AX-DX from `in` (AX = -1 for other numbers)
; ----------------------------------------------------------------------------
_do_interrupt:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ax
	push	bx
	push	cx
	push	dx
	mov	di, [bp+6]
	mov	ax, [di]
	mov	bx, [di+2]
	mov	cx, [di+4]
	mov	dx, [di+6]
	cmp	word ptr [bp+4], 10h
	je	do_interrupt_1
	cmp	word ptr [bp+4], 21h
	je	do_interrupt_2
	cmp	word ptr [bp+4], 16h
	je	do_interrupt_3
	cmp	word ptr [bp+4], 1Ah
	je	do_interrupt_4
	jmp	do_interrupt_5
do_interrupt_1:
	int	10h
	jmp	do_interrupt_6
do_interrupt_2:
	int	21h
	jmp	do_interrupt_6
do_interrupt_3:
	int	16h
	jmp	do_interrupt_6
do_interrupt_4:
	int	1Ah
	jmp	do_interrupt_6
do_interrupt_5:
	sub	ax, ax
	not	ax
	jmp	do_interrupt_7
do_interrupt_6:
	mov	di, [bp+8]
	mov	[di], ax
	mov	[di+2], bx
	mov	[di+4], cx
	mov	[di+6], dx
do_interrupt_7:
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	pop	di
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; char *int_to_str(int v, char *buf, int radix): radix 10, 16 (4 digits,
; 0-9 only) or 2
; ----------------------------------------------------------------------------
_int_to_str:
	push	bp
	mov	bp, sp
	push	si
	mov	bx, [bp+6]
	mov	ax, [bp+8]
	cmp	ax, 0Ah
	je	int_to_str_1
	cmp	ax, 2
	je	int_to_str_3
	cmp	ax, 10h
	je	int_to_str_2
	jmp	int_to_str_4
int_to_str_1:
	call	to_decimal
	jmp	int_to_str_5
int_to_str_2:
	call	to_hex
	jmp	int_to_str_5
int_to_str_3:
	call	to_binary
	jmp	int_to_str_5
int_to_str_4:
	mov	bx, [bp+6]
	mov	word ptr [bx], 0
	mov	ax, 0
int_to_str_5:
	mov	ax, [bp+6]
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; to_decimal
; ----------------------------------------------------------------------------
to_decimal:
	sub	cx, cx
	mov	ax, [bp+4]
	mov	si, 0Ah
	or	ax, ax
	jns	to_decimal_1
	mov	byte ptr [bx], 2Dh
	inc	bx
	neg	ax
to_decimal_1:
	sub	dx, dx
	div	si
	add	dx, 30h
	push	dx
	inc	cx
	or	ax, ax
	jne	to_decimal_1
	mov	ax, cx
to_decimal_2:
	pop	dx
	mov	[bx], dl
	inc	bx
	loop	to_decimal_2
	mov	byte ptr [bx], 0
	ret

; ----------------------------------------------------------------------------
; to_hex
; ----------------------------------------------------------------------------
to_hex:
	mov	cx, 4
	mov	ax, [bp+4]
	and	ah, 0F0h
	mov	al, ah
	sub	ah, ah
	shr	ax, cl
	add	ax, 30h
	mov	[bx], al
	inc	bx
	mov	ax, [bp+4]
	and	ah, 0Fh
	mov	al, ah
	sub	ah, ah
	add	ax, 30h
	mov	[bx], al
	inc	bx
	mov	ax, [bp+4]
	and	al, 0F0h
	sub	ah, ah
	shr	ax, cl
	add	ax, 30h
	mov	[bx], al
	inc	bx
	mov	ax, [bp+4]
	and	al, 0Fh
	sub	ah, ah
	add	ax, 30h
	mov	[bx], al
	inc	bx
	mov	byte ptr [bx], 0
	mov	ax, 4
	ret

; ----------------------------------------------------------------------------
; to_binary
; ----------------------------------------------------------------------------
to_binary:
	mov	dx, [bp+4]
	sub	ax, ax
	mov	ah, 80h
to_binary_1:
	test	dx, ax
	jne	to_binary_2
	mov	byte ptr [bx], 30h
	inc	bx
	jmp	to_binary_3
to_binary_2:
	mov	byte ptr [bx], 31h
	inc	bx
to_binary_3:
	shr	ax, 1
	jae	to_binary_1
	mov	byte ptr [bx], 0
	mov	ax, 10h
	ret
text_attr	db	0Fh		; print_at's attribute (a \377 byte in the string sets it)

; ----------------------------------------------------------------------------
; void print_at(int row, int col, char *s): BIOS teletype output with the
; current attribute; \377 c sets the attribute to c; row -1: at the cursor
; ----------------------------------------------------------------------------
_print_at:
	push	bp
	mov	bp, sp
	push	si
	mov	ah, 2
	xor	bh, bh
	mov	dh, [bp+4]
	mov	dl, [bp+6]
	cmp	dx, -1
	je	print_at_1
	int	10h
print_at_1:
	mov	bl, cs:text_attr
	xor	bh, bh
	mov	cx, 1
	mov	si, [bp+8]
print_at_2:
	lodsb
	or	al, al
	je	print_at_4
	cmp	al, 0FFh
	je	print_at_3
	mov	dl, al
	mov	ah, 9
	mov	al, 20h
	int	10h
	mov	ah, 0Eh
	mov	al, dl
	int	10h
	jmp	print_at_2
print_at_3:
	lodsb
	or	al, al
	je	print_at_4
	mov	cs:text_attr, al
	mov	bl, al
	jmp	print_at_2
print_at_4:
	pop	si
	pop	bp
	ret

; ----------------------------------------------------------------------------
; void dos_newline(char *msg): DOS print string ($-terminated)
; ----------------------------------------------------------------------------
_dos_newline:
	push	bp
	mov	bp, sp
	mov	ah, 9
	mov	dx, [bp+4]
	int	21h
	pop	bp
	ret
_TEXT	ENDS
	END

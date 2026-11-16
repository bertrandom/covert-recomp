; MISC.EXE - Covert Action keyboard and joystick driver ("MISCOVR.EXE")
;
; Loaded as an overlay like the graphics driver; exports slots 90-97 through the
; header at CS:32h (see README "Driver interface"). All entries are far calls.
; The joystick is read through game port 201h: an axis is the number of polling
; loops its one-shot stays high; calibrate (slot 96) takes the current position
; as the centre and read_joystick (slot 97) scales each axis to -127..127.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh MISC
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/MISC.hints)

; LINK options: /CPARMAXALLOC:2
; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:150h = DATA:0) while DS references, with DS = DATA,
; get segment offsets. DATA is emitted first so MASM's pass 1 knows its labels.
DGROUP	GROUP	CODE, DATA

CODE	SEGMENT WORD PUBLIC 'CODE'
CODE	ENDS
DATA	SEGMENT PARA PUBLIC 'DATA'
DATA	ENDS
STACK	SEGMENT PARA STACK 'STACK'
STACK	ENDS

DATA	SEGMENT
	db	16 dup (0)
	db	'Copyright (C) 1989 by MicroProse Software, All Rights Reserved.',0
; Joystick state, one word per axis (x, y; room for four axes)
joy_span_low	dw	4 dup (0)
joy_span_high	dw	4 dup (0)
joy_min	dw	4 dup (0)
joy_max	dw	4 dup (0)
joy_centre	dw	4 dup (0)
joy_count	dw	0
joy_count_y	dw	0,0,0
; Result of read_joystick: signed x, y bytes
joy_pos	db	4 dup (0)
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'MISCOVR.EXE 02-20-89'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	90h		; bytes from DATA to the stack
drv_first_slot	db	90
	db	0
drv_count	dw	8		; number of exports
drv_exports	label	word
	dw	offset misc_kbhit	; slot 90
	dw	offset misc_getkey	; slot 91
	dw	offset misc_getche	; slot 92
	dw	offset misc_clear_shift	; slot 93
	dw	offset misc_clear_shift	; slot 94
	dw	offset misc_joy_button	; slot 95
	dw	offset misc_joy_calibrate	; slot 96
	dw	offset misc_read_joystick_raw	; slot 97

; ----------------------------------------------------------------------------
; misc_getche (slot 92)
; getche(): read a character with echo (DOS function 1).
; ----------------------------------------------------------------------------
misc_getche:
	mov	ah, 1
	int	21h
	retf

; ----------------------------------------------------------------------------
; misc_getkey (slot 91)
; getkey(): wait for a key; returns scan code << 8 | ASCII.
; ----------------------------------------------------------------------------
misc_getkey:
	sub	ah, ah
	int	16h
	retf

; ----------------------------------------------------------------------------
; misc_kbhit (slot 90)
; kbhit(): -1 if a key is waiting, else 0.
; ----------------------------------------------------------------------------
misc_kbhit:
	mov	ah, 1
	int	16h
	je	L_0055
	sub	ax, ax
	retf
L_0055:
	sub	ax, ax
	not	ax
	retf

; ----------------------------------------------------------------------------
; misc_clear_shift (slot 93/94)
; Slots 93, 94: clear the shift/ctrl/alt bits of the BIOS keyboard flags (0040:0017).
; ----------------------------------------------------------------------------
misc_clear_shift:
	push	es
	sub	ax, ax
	mov	es, ax
	mov	al, byte ptr es:[417h]
	and	al, 0F0h
	mov	byte ptr es:[417h], al
	pop	es
	retf
	db	0

; ----------------------------------------------------------------------------
; misc_joy_button (slot 95)
; joy_button(n): 1 if joystick button n (0-3) is pressed.
; ----------------------------------------------------------------------------
misc_joy_button:
	mov	bx, sp
	mov	dx, 201h
	in	al, dx
	not	al
	mov	cx, word ptr [bx+4]
	add	cx, 4
	shr	al, cl
	and	ax, 1
	retf

; ----------------------------------------------------------------------------
; misc_joy_calibrate (slot 96)
; joy_calibrate(): take the current stick position as centre, min and max.
; (driver_names.py and the game sources used to call this slot drv_strlen; the game
; calls it when the joystick is switched on.)
; ----------------------------------------------------------------------------
misc_joy_calibrate:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	joy_poll
	mov	bx, 0
	call	joy_reset_axis
	mov	bx, 1
	call	joy_reset_axis
	pop	ds
	retf

; ----------------------------------------------------------------------------
; joy_reset_axis
; BX = axis: centre = min = max = the last count.
; ----------------------------------------------------------------------------
joy_reset_axis:
	shl	bx, 1
	mov	ax, word ptr [bx+joy_count]
	mov	word ptr [bx+joy_centre], ax
	mov	word ptr [bx+joy_min], ax
	mov	word ptr [bx+joy_max], ax
	ret

; ----------------------------------------------------------------------------
; misc_read_joystick_raw (slot 97)
; read_joystick(): read both axes; returns joy_pos (x in AL, y in AH).
; ----------------------------------------------------------------------------
misc_read_joystick_raw:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	joy_poll
	mov	bx, 0
	call	joy_scale_axis
	mov	bx, 1
	call	joy_scale_axis
	mov	ax, word ptr joy_pos
	pop	ds
	retf

; ----------------------------------------------------------------------------
; joy_poll
; Fire the one-shots and count how long each axis stays high (joy_count).
; ----------------------------------------------------------------------------
joy_poll:
	push	bp
	xor	bx, bx
	xor	bp, bp
	mov	cx, 0FFFFh
	mov	dx, 201h
	cli
	out	dx, al
	jmp	short L_00D3
L_00D3:
	jmp	short L_00D5
L_00D5:
	in	al, dx
	and	al, 3
	je	L_00E6
	shr	al, 1
	adc	bx, 0
	shr	al, 1
	adc	bp, 0
	loop	L_00D5
L_00E6:
	sti
	mov	word ptr joy_count, bx
	mov	word ptr joy_count_y, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; joy_scale_axis
; BX = axis: widen min/max if needed and scale the count to -127..127 around the centre.
; ----------------------------------------------------------------------------
joy_scale_axis:
	shl	bx, 1
	mov	ax, word ptr [bx+joy_count]
	mov	dx, ax
	sub	dx, word ptr [bx+joy_centre]
	jb	L_0106
	ja	L_0128
	mov	ah, 0
	jmp	L_0143
L_0106:
	neg	dx
	cmp	ax, word ptr [bx+joy_min]
	ja	L_011B
	mov	word ptr [bx+joy_min], ax
	mov	word ptr [bx+joy_span_low], dx
	mov	ah, 81h
	jmp	L_0143
L_011B:
	xor	ax, ax
	div	word ptr [bx+joy_span_low]
	shr	ax, 1
	neg	ax
	jmp	L_0143
L_0128:
	cmp	ax, word ptr [bx+joy_max]
	jb	L_013B
	mov	word ptr [bx+joy_max], ax
	mov	word ptr [bx+joy_span_high], dx
	mov	ah, 7Fh
	jmp	L_0143
L_013B:
	xor	ax, ax
	div	word ptr [bx+joy_span_high]
	shr	ax, 1
L_0143:
	shr	bx, 1
	mov	byte ptr [bx+joy_pos], ah
	ret
CODE	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

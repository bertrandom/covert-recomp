; CGRAPHIC.EXE - Covert Action graphics driver for CGA (320x200, 4 colours)
;
; Same interface as MGRAPHIC (51 entry points, see MGRAPHIC.ASM and README
; "Driver interface"); the game's 16 colours are dithered to the 4 CGA colours
; through the colour map (set_color_map) and dither tables. The screen is at
; B800h with even and odd rows in two 2000h banks. Routine and variable names
; come from MGRAPHIC by aligning each export with MGRAPHIC's routine for the
; same slot ("inherit"); the descriptions are those of tools/drivers/gfx_slots.txt.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh CGRAPHIC
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/CGRAPHIC.hints)

; OP reg, imm16 in the 81 form for an immediate that fits in a byte
; (compiler output; MASM would use the sign-extended 83 form)
addw	MACRO	reg, imm
	db	81h
	IFIDNI	<reg>, <bx>
	db	0C3h
	ENDIF
	dw	imm
	ENDM

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:1B00h = DATA:0) while DS references, with DS = DATA,
; get segment offsets. DATA is emitted first so MASM's pass 1 knows its labels.
DGROUP	GROUP	CODE, DATA

CODE	SEGMENT WORD PUBLIC 'CODE'
CODE	ENDS
DATA	SEGMENT PARA PUBLIC 'DATA'
DATA	ENDS
BSS	SEGMENT BYTE PUBLIC 'BSS'
BSS	ENDS
STACK	SEGMENT PARA STACK 'STACK'
STACK	ENDS

DATA	SEGMENT
	db	16 dup (0)
	db	'Copyright (C) 1989 by MicroProse Software, All Rights Reserved.',0
row_offset	dw	0,2000h,50h,2050h,0A0h,20A0h,0F0h,20F0h
	dw	140h,2140h,190h,2190h,1E0h,21E0h,230h,2230h
	dw	280h,2280h,2D0h,22D0h,320h,2320h,370h,2370h
b_D0080	db	0C0h,3,0C0h,23h,10h,4,10h,24h,60h,4,60h,24h,0B0h,4,0B0h,24h
	db	0,5,0,25h,50h,5,50h,25h,0A0h,5,0A0h,25h,0F0h,5,0F0h,25h
	db	40h,6,40h,26h,90h,6,90h,26h,0E0h,6,0E0h,26h,30h,7,30h,27h
	db	80h,7,80h,27h,0D0h,7,0D0h,27h,20h,8,20h,28h,70h,8,70h,28h
	db	0C0h,8,0C0h,28h,10h,9,10h,29h,60h,9,60h,29h,0B0h,9,0B0h,29h
	db	0,0Ah,0,2Ah,50h,0Ah,50h,2Ah,0A0h,0Ah,0A0h,2Ah,0F0h,0Ah,0F0h,2Ah
	db	40h,0Bh,40h,2Bh,90h,0Bh,90h,2Bh,0E0h,0Bh,0E0h,2Bh,30h,0Ch,30h,2Ch
	db	80h,0Ch,80h,2Ch,0D0h,0Ch,0D0h,2Ch,20h,0Dh,20h,2Dh,70h,0Dh,70h,2Dh
b_D0100	db	0C0h,0Dh,0C0h,2Dh,10h,0Eh,10h,2Eh,60h,0Eh,60h,2Eh,0B0h,0Eh,0B0h,2Eh
	db	0,0Fh,0,2Fh,50h,0Fh,50h,2Fh,0A0h,0Fh,0A0h,2Fh,0F0h,0Fh,0F0h,2Fh
	db	40h,10h,40h,30h,90h,10h,90h,30h,0E0h,10h,0E0h,30h,30h,11h,30h,31h
	db	80h,11h,80h,31h,0D0h,11h,0D0h,31h,20h,12h,20h,32h,70h,12h,70h,32h
	db	0C0h,12h,0C0h,32h,10h,13h,10h,33h,60h,13h,60h,33h,0B0h,13h,0B0h,33h
	db	0,14h,0,34h,50h,14h,50h,34h,0A0h,14h,0A0h,34h,0F0h,14h,0F0h,34h
	db	40h,15h,40h,35h,90h,15h,90h,35h,0E0h,15h,0E0h,35h,30h,16h,30h,36h
	db	80h,16h,80h,36h,0D0h,16h,0D0h,36h,20h,17h,20h,37h,70h,17h,70h,37h
	db	0C0h,17h,0C0h,37h,10h,18h,10h,38h,60h,18h,60h,38h,0B0h,18h,0B0h,38h
	db	0,19h,0,39h,50h,19h,50h,39h,0A0h,19h,0A0h,39h,0F0h,19h,0F0h,39h
	db	40h,1Ah,40h,3Ah,90h,1Ah,90h,3Ah,0E0h,1Ah,0E0h,3Ah,30h,1Bh,30h,3Bh
	db	80h,1Bh,80h,3Bh,0D0h,1Bh,0D0h,3Bh,20h,1Ch,20h,3Ch,70h,1Ch,70h,3Ch
	db	0C0h,1Ch,0C0h,3Ch,10h,1Dh,10h,3Dh,60h,1Dh,60h,3Dh,0B0h,1Dh,0B0h,3Dh
	db	0,1Eh,0,3Eh,50h,1Eh,50h,3Eh,0A0h,1Eh,0A0h,3Eh,0F0h,1Eh,0F0h,3Eh
caps_table	dw	0,1,1,0
w_D01E8	dw	0
page_seg	dw	7 dup (0B800h)
w_D01F8	dw	0B800h
draw_seg	dw	0B800h
draw_x0	dw	0
draw_y0	dw	0
draw_xmax	dw	13Fh,0
draw_mode	db	0
draw_opcode	db	0
draw_color	db	0,0,3Fh,0CFh,0F3h,0FCh
w_D020C	dw	5500h,0FFAAh
w_D0210	dw	100h,302h,100h,302h,100h,302h,100h,302h
	dw	56 dup (0)
w_D0290	dw	0,5555h,8888h,5555h,0,1111h,2222h,0DDDDh
	dw	0EEEEh,5555h,0,5555h,0AAAAh,0FFFFh,5555h,0FFFFh
	dw	112 dup (0)
b_D0390	db	0,1,2,1,0,0,0,3,3,1,0,1,2,3,1,3
	db	112 dup (0)
b_D0410	db	0,1,0,1,0,1,2,1,2,1,0,1,2,3,1,3
	db	113 dup (0)
	db	1,2,1,0,0,0,3,3,1,0,1,2,3,1,3
	db	112 dup (0)
b_D0510	db	0,0
	db	'Out of memory$'
	db	'CGA is not supported on your machine$',0
line_x0	dw	0
line_y0	dw	32h
line_x1	dw	64h
line_y1	dw	0
w_D054E	dw	0
w_D0550	dw	0
w_D0552	dw	0
w_D0554	dw	0
w_D0556	dw	0FFFFh,0FF3Fh,0FF0Fh,0FF03h,0FF00h,3F00h,0F00h,300h
w_D0566	dw	0C0h,0F0h,0FCh,0FFh,0C0FFh,0F0FFh,0FCFFh,0FFFFh
w_D0576	dw	0
w_D0578	dw	0,4444h,8888h,0CCCCh
w_D0580	dw	0,1111h,2222h,3333h
b_D0588	db	0,0
width_table	dw	0
font_first	db	0
font_spacing	db	0
glyph_data	dw	0
glyph_shift	db	0
font_fixed_width	db	0
glyph_skip	db	0
cut_ptr	db	0,0,0
cut_skip	db	0
text_rows	dw	0
glyph_bytes	dw	0
text_x	dw	0
text_y	dw	8 dup (0)
	dw	0FCFFh,0F0F3h,0CCCFh,0C0C3h
draw_op_table	db	3Fh,3Ch,33h,30h,0Fh,0Ch,3,0,0
ptr_image	dw	0
ptr_x	dw	0
ptr_y	dw	0
ptr_width	dw	0
ptr_height	dw	0
ptr_clip_x	dw	0
ptr_clip_h	dw	0
ptr_clip_w	dw	0
w_D05CE	dw	0
ptr_visible	dw	0
ptr_page	dw	0
ptr_save	dw	256 dup (0)
; variables in the uninitialised BSS segment that follows
w_D07D4	equ	word ptr $+0
w_D4720	equ	word ptr $+16204
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'CGRAPHIC.EXE08-08-89'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	4720h		; bytes from DATA to the stack
drv_first_slot	db	0
	db	0
drv_count	dw	51		; number of exports
drv_exports	label	word
	dw	offset cgfx_alloc_page	; slot 0
	dw	offset cgfx_mem_avail	; slot 1
	dw	offset cgfx_get_image	; slot 2
	dw	offset cgfx_recolor_rect	; slot 3
	dw	offset cgfx_char_width	; slot 4
	dw	offset cgfx_clear_page	; slot 5
	dw	offset cgfx_draw_image	; slot 6
	dw	offset cgfx_end_image_grab	; slot 7
	dw	offset cgfx_free_page	; slot 8
	dw	offset cgfx_dissolve_page	; slot 9
	dw	offset cgfx_font_height	; slot 10
	dw	offset cgfx_get_row	; slot 11
	dw	offset cgfx_get_pixel	; slot 12
	dw	offset cgfx_nop13	; slot 13
	dw	offset cgfx_hide_pointer	; slot 14
	dw	offset cgfx_patch_font	; slot 15
	dw	offset cgfx_has_back_buffer	; slot 16
	dw	offset cgfx_begin_image_grab	; slot 17
	dw	offset cgfx_put_row	; slot 18
	dw	offset cgfx_copy_rect	; slot 19
	dw	offset cgfx_draw_text	; slot 20
	dw	offset cgfx_draw_image_scaled	; slot 21
	dw	offset cgfx_screen_off	; slot 22
	dw	offset cgfx_screen_on	; slot 23
	dw	offset cgfx_set_page	; slot 24
	dw	offset cgfx_set_color	; slot 25
	dw	offset cgfx_set_palette	; slot 26
	dw	offset cgfx_set_color_map	; slot 27
	dw	offset cgfx_set_shake	; slot 28
	dw	offset cgfx_show_pointer	; slot 29
	dw	offset cgfx_show_page	; slot 30
	dw	offset cgfx_draw_image_noclip	; slot 31
	dw	offset cgfx_end_image	; slot 32
	dw	offset cgfx_image_add_row	; slot 33
	dw	offset cgfx_begin_image	; slot 34
	dw	offset cgfx_swap_page	; slot 35
	dw	offset cgfx_init_mode	; slot 36
	dw	offset cgfx_put_pixel	; slot 37
	dw	offset cgfx_fill_spans	; slot 38
	dw	offset cgfx_nop39	; slot 39
	dw	offset cgfx_set_draw_color	; slot 40
	dw	offset cgfx_draw_line	; slot 41
	dw	offset cgfx_text_clip_all	; slot 42
	dw	offset cgfx_text_clip_left	; slot 43
	dw	offset cgfx_text_noclip	; slot 44
	dw	offset cgfx_text_clip_right	; slot 45
	dw	offset cgfx_text_clip_vert	; slot 46
	dw	offset cgfx_select_page	; slot 47
	dw	offset cgfx_set_port	; slot 48
	dw	offset cgfx_copy_rows_to_screen	; slot 49
	dw	offset cgfx_shake_tick	; slot 50
w_0098	dw	0
w_009A	dw	0
w_009C	dw	0
w_009E	dw	0
w_00A0	dw	0

; ----------------------------------------------------------------------------
; cgfx_nop13 (slot 13): Slot 13.
; ----------------------------------------------------------------------------
cgfx_nop13:
	cmp	word ptr cs:w_0098, 0
	je	L_00C4
	push	si
	push	di
	push	ds
	push	es
	mov	si, 0A000h
	mov	di, 0C000h
	mov	ax, 0B000h
	mov	ds, ax
	mov	es, ax
	mov	cx, 1000h
	rep	movsw
	pop	es
	pop	ds
	pop	di
	pop	si
L_00C4:
	retf

; ----------------------------------------------------------------------------
; sub_00C5
; ----------------------------------------------------------------------------
sub_00C5:
	mov	ax, es
	cmp	ax, 0B800h
	jne	L_012B
	cmp	word ptr cs:w_0098, 0
	je	L_012B
	mov	bx, word ptr cs:w_009C
	and	bx, 0FFFEh
	shl	bx, 1
	mov	bx, word ptr cs:[bx+row_offset]
	mov	ax, word ptr cs:w_009A
	shr	ax, 1
	shr	ax, 1
	add	bx, ax
	mov	ax, word ptr cs:w_009E
	add	ax, 3
	shr	ax, 1
	shr	ax, 1
	mov	dl, al
	mov	ax, word ptr cs:w_00A0
	test	word ptr cs:w_009C, 1
	je	L_0108
	inc	ax
L_0108:
	shr	ax, 1
	mov	dh, al
	push	ds
	push	es
	mov	ax, 0BA00h
	mov	ds, ax
	mov	ax, 0BC00h
	mov	es, ax
	xor	cx, cx
L_011A:
	mov	cl, dl
	mov	si, bx
	mov	di, bx
	rep	movsb
	add	bx, 50h
	dec	dh
	jne	L_011A
	pop	es
	pop	ds
L_012B:
	ret
b_012C	db	37h,28h,2Dh,8,7Ah,1,64h,6Ch,2,2,0,0

; ----------------------------------------------------------------------------
; sub_0138
; ----------------------------------------------------------------------------
sub_0138:
	mov	ax, 4
	int	10h
	mov	dx, 3BFh
	mov	al, 3
	out	dx, al
	mov	al, 2
	mov	dx, 3B8h
	out	dx, al
	xor	bx, bx
	mov	dx, 3B4h
	mov	cx, 0Ch
L_0151:
	mov	al, bl
	out	dx, al
	inc	dx
	mov	al, byte ptr cs:[bx+b_012C]
	out	dx, al
	dec	dx
	inc	bx
	loop	L_0151
	push	es
	push	di
	mov	ax, 0B800h
	mov	es, ax
	xor	di, di
	xor	ax, ax
	mov	cx, 3000h
	rep	stosw
	pop	di
	pop	es
	mov	al, 8Ah
	mov	dx, 3B8h
	out	dx, al
	ret

; ----------------------------------------------------------------------------
; cgfx_has_back_buffer (slot 16): has_back_buffer(n): capability flag.
; ----------------------------------------------------------------------------
cgfx_has_back_buffer:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	mov	ax, word ptr cs:[bx+caps_table]
	retf

; ----------------------------------------------------------------------------
; cgfx_set_port (slot 48): BX = port: page and origin for the primitives.
; ----------------------------------------------------------------------------
cgfx_set_port:
	mov	ax, word ptr [bx+2]
	mov	word ptr cs:draw_x0, ax
	mov	ax, word ptr [bx+4]
	mov	word ptr cs:draw_y0, ax
	mov	ax, word ptr [bx+6]
	mov	word ptr cs:draw_xmax, ax
	mov	ax, word ptr [bx]

; ----------------------------------------------------------------------------
; cgfx_select_page (slot 47): AX = page: the page the primitives draw on.
; ----------------------------------------------------------------------------
cgfx_select_page:
	xchg	bx, ax
	shl	bx, 1
	mov	bx, word ptr cs:[bx+page_seg]
	xchg	bx, ax
	mov	word ptr cs:draw_seg, ax
	retf

; ----------------------------------------------------------------------------
; cgfx_mem_avail (slot 1): mem_avail(): largest free DOS block, in paragraphs.
; ----------------------------------------------------------------------------
cgfx_mem_avail:
	mov	ah, 48h
	mov	bx, 0FFFFh
	int	21h
	mov	ax, bx
	retf

; ----------------------------------------------------------------------------
; cgfx_set_page (slot 24): set_page(n, seg): set the segment of page n.
; ----------------------------------------------------------------------------
cgfx_set_page:
	mov	bx, sp
	mov	ax, word ptr [bx+6]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	word ptr cs:[bx+page_seg], ax
	retf

; ----------------------------------------------------------------------------
; cgfx_alloc_page (slot 0): alloc_page(n): page 0 is the screen; otherwise allocate an off-screen page (0 if no memory).
; ----------------------------------------------------------------------------
cgfx_alloc_page:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	or	al, al
	jne	L_01D0
	mov	ax, word ptr cs:page_seg
	retf
L_01D0:
	mov	ah, 48h
	mov	bx, 400h
	cmp	al, 7
	jne	L_01DD
	add	bx, 0C00h
L_01DD:
	int	21h
	jae	L_01E3
	xor	ax, ax
L_01E3:
	retf
	db	0BAh,12h,5,0EBh,50h
	EVEN

; ----------------------------------------------------------------------------
; cgfx_free_page (slot 8): free_page(n): give page n's memory back to DOS.
; ----------------------------------------------------------------------------
cgfx_free_page:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	or	bx, bx
	je	L_0202
	shl	bx, 1
	mov	ax, word ptr cs:[bx+page_seg]
	push	es
	mov	es, ax
	mov	ah, 49h
	int	21h
	pop	es
L_0202:
	retf

; ----------------------------------------------------------------------------
; cgfx_init_mode (slot 36): init_mode(flags): set the video mode and default palette.
; ----------------------------------------------------------------------------
cgfx_init_mode:
	mov	bx, sp
	mov	ax, word ptr [bx+4]
	mov	word ptr cs:w_D01E8, 0
	test	ax, 2
	je	L_021B
	mov	word ptr cs:w_D01E8, 1
L_021B:
	and	ax, 1
	mov	word ptr cs:w_0098, ax
	je	L_0228
	call	sub_0138
	retf
L_0228:
	mov	ax, 4
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, 4
	jne	L_0236
	retf
L_0236:
	mov	dx, 520h
	mov	ax, DATA
	mov	ds, ax
	mov	ax, 3
	int	10h
	mov	ah, 9
	int	21h
	mov	ax, 4C00h
	int	21h

; ----------------------------------------------------------------------------
; cgfx_screen_off (slot 22): Blank the display.
; ----------------------------------------------------------------------------
cgfx_screen_off:
	cmp	word ptr cs:w_0098, 1
	je	L_0263
	mov	dx, 3DAh
L_0257:
	in	al, dx
	test	al, 8
	je	L_0257
	mov	dx, 3D8h
	mov	al, 2
	out	dx, al
	retf
L_0263:
	mov	dx, 3B8h
	mov	al, 82h
	out	dx, al
	retf

; ----------------------------------------------------------------------------
; cgfx_screen_on (slot 23): Turn the display back on.
; ----------------------------------------------------------------------------
cgfx_screen_on:
	cmp	word ptr cs:w_0098, 1
	je	L_0281
	mov	dx, 3DAh
L_0275:
	in	al, dx
	test	al, 8
	je	L_0275
	mov	dx, 3D8h
	mov	al, 0Ah
	out	dx, al
	retf
L_0281:
	mov	dx, 3BAh
	in	al, dx
	test	al, 80h
	jne	L_0281
	mov	dx, 3B8h
	mov	al, 8Ah
	out	dx, al
	retf

; ----------------------------------------------------------------------------
; cgfx_put_pixel (slot 37): AX = x, BX = y: plot a pixel with the current colour and mode.
; ----------------------------------------------------------------------------
cgfx_put_pixel:
	push	ds
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	es, word ptr cs:draw_seg
	add	ax, word ptr cs:draw_x0
	mov	word ptr line_x0, ax
	add	bx, word ptr cs:draw_y0
	mov	word ptr line_y0, bx
	mov	cx, es
	cmp	cx, word ptr cs:w_D01F8
	jne	L_02C4
	mov	bh, bl
	mov	bl, al
	add	bx, 4000h
	mov	al, byte ptr draw_color
	mov	byte ptr es:[bx], al
L_02C4:
	call	pixel_addr
	je	L_02D1
	add	di, word ptr [bx]
	xor	byte ptr es:[di], dl
	jmp	L_02DB
L_02D1:
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	and	al, dh
	or	al, dl
	stosb
L_02DB:
	pop	es
	pop	ds
	retf

; ----------------------------------------------------------------------------
; pixel_addr
; ----------------------------------------------------------------------------
pixel_addr:
	mov	al, byte ptr draw_color
	lea	bx, w_D0210
	xlat
	lea	bx, w_D020C
	xlat
	mov	ah, al
	mov	di, word ptr line_x0
	mov	bx, di
	and	bx, 3
	mov	dh, byte ptr [bx+draw_color+2]
	mov	dl, dh
	not	dl
	and	dl, ah
	shr	di, 1
	shr	di, 1
	mov	bx, word ptr line_y0
	shl	bx, 1
	addw	bx, 50h
	mov	al, byte ptr cs:draw_opcode
	cmp	al, 20h
	jne	L_0318
	or	dl, dh
L_0318:
	cmp	al, 88h
	ret

; ----------------------------------------------------------------------------
; cgfx_draw_line (slot 41): AX,BX - CX,DX: draw a line with the current colour and mode.
; ----------------------------------------------------------------------------
cgfx_draw_line:
	push	ds
	push	es
	mov	di, DATA
	mov	ds, di
	mov	es, word ptr cs:draw_seg
	mov	di, word ptr cs:draw_x0
	add	ax, di
	add	cx, di
	mov	di, word ptr cs:draw_y0
	add	bx, di
	add	dx, di
	cmp	ax, cx
	jbe	L_0340
	xchg	cx, ax
	xchg	bx, dx
L_0340:
	mov	word ptr line_x0, ax
	mov	word ptr line_y0, bx
	mov	word ptr line_x1, cx
	mov	word ptr line_y1, dx
	jne	L_0358
	cmp	bx, dx
	jne	L_0358
	jmp	L_02C4
L_0358:
	mov	bp, 2
	sub	cx, ax
	sub	dx, bx
	jns	L_0365
	neg	bp
	neg	dx
L_0365:
	mov	word ptr w_D054E, cx
	mov	word ptr w_D0550, dx
	cmp	dx, cx
	jbe	L_0374
	jmp	L_0403
L_0374:
	mov	cx, word ptr w_D054E
	mov	si, cx
	inc	si
	shr	si, 1
	neg	si
	call	pixel_addr
	jne	L_03DB
	mov	dl, ah
	jmp	short L_03A6
L_0388:
	sub	si, word ptr w_D054E
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	mov	byte ptr es:[di], al
	sub	di, word ptr [bx]
	add	bx, bp
	ror	dh, 1
	ror	dh, 1
	cmc
	adc	di, 0
L_03A6:
	mov	ah, dh
L_03A8:
	and	ah, dh
	dec	cx
	js	L_03CC
	add	si, word ptr w_D0550
	jns	L_0388
	ror	dh, 1
	ror	dh, 1
	jb	L_03A8
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	mov	byte ptr es:[di], al
	sub	di, word ptr [bx]
	inc	di
	jmp	L_03A6
L_03CC:
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	stosb
L_03D8:
	pop	es
	pop	ds
	retf
L_03DB:
	mov	byte ptr cs:b_03EB, al
	mov	ax, word ptr line_x0
L_03E2:
	mov	di, ax
	shr	di, 1
	shr	di, 1
	add	di, word ptr [bx]
b_03EB	equ	byte ptr $+1
	xor	byte ptr es:[di], dl
	dec	cx
	js	L_03D8
	add	si, word ptr w_D0550
	js	L_03FC
	add	bx, bp
	sub	si, word ptr w_D054E
L_03FC:
	ror	dl, 1
	ror	dl, 1
	inc	ax
	jmp	L_03E2
L_0403:
	mov	cx, word ptr w_D0550
	mov	si, cx
	inc	si
	shr	si, 1
	neg	si
	call	pixel_addr
	jne	L_043D
L_0413:
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	and	al, dh
	or	al, dl
	mov	byte ptr es:[di], al
	sub	di, word ptr [bx]
	dec	cx
	js	L_03D8
	add	bx, bp
	add	si, word ptr w_D054E
	js	L_0413
	sub	si, word ptr w_D0550
	ror	dl, 1
	ror	dl, 1
	ror	dh, 1
	ror	dh, 1
	jb	L_0413
	inc	di
	jmp	L_0413
L_043D:
	mov	byte ptr cs:b_044D, al
	mov	ax, word ptr line_x0
L_0444:
	mov	di, ax
	shr	di, 1
	shr	di, 1
	add	di, word ptr [bx]
b_044D	equ	byte ptr $+1
	xor	byte ptr es:[di], dl
	dec	cx
	js	L_03D8
	add	bx, bp
	add	si, word ptr w_D054E
	js	L_0444
	sub	si, word ptr w_D0550
	ror	dl, 1
	ror	dl, 1
	inc	ax
	jmp	L_0444
	db	0
L_0466:
	pop	es
	pop	ds
L_0468:
	retf

; ----------------------------------------------------------------------------
; cgfx_fill_spans (slot 38): AX = first row, CX = last row, BX = span table: fill each row's span.
; ----------------------------------------------------------------------------
cgfx_fill_spans:
	or	ax, ax
	js	L_0468
	push	ds
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	es, word ptr cs:draw_seg
	mov	word ptr w_D0552, ax
	mov	word ptr w_D0554, cx
	mov	dl, byte ptr draw_color
	xor	dh, dh
	mov	si, dx
	shl	si, 1
	mov	dx, word ptr [si+w_D0290]
	test	word ptr w_D0554, 1
	jne	L_049A
	ror	dx, 1
	ror	dx, 1
L_049A:
	mov	si, word ptr w_D0554
	inc	si
	shl	si, 1
L_04A1:
	ror	dx, 1
	ror	dx, 1
	shr	si, 1
	cmp	si, word ptr w_D0552
	je	L_0466
	dec	si
	shl	si, 1
	mov	cx, word ptr ss:[bx+si+1B8h]
	mov	bp, word ptr ss:[bx+si]
	cmp	cx, bp
	jb	L_04A1
	ja	L_04C9
	or	cx, cx
	je	L_04A1
	cmp	cx, word ptr cs:draw_xmax
	je	L_04A1
L_04C9:
	push	bx
	mov	bx, si
	mov	di, word ptr [bx+row_offset]
	mov	bx, cx
	and	bx, 7
	shl	bx, 1
	mov	ax, word ptr [bx+w_D0566]
	mov	word ptr w_D0576, ax
	mov	bx, bp
	and	bx, 7
	shl	bx, 1
	mov	bx, word ptr [bx+w_D0556]
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	mov	ax, bp
	shl	ax, 1
	add	di, ax
	sub	cx, bp
	je	L_0518
	mov	ax, bx
	mov	bx, word ptr es:[di]
	xor	bx, dx
	and	ax, bx
	xor	ax, word ptr es:[di]
	stosw
	mov	bx, 0FFFFh
	sub	ch, ch
	dec	cx
	je	L_0518
	mov	ax, dx
	rep	stosw
L_0518:
	and	bx, word ptr w_D0576
	mov	ax, bx
	mov	bx, word ptr es:[di]
	xor	bx, dx
	and	ax, bx
	xor	ax, word ptr es:[di]
	stosw
	pop	bx
	jmp	L_04A1
	db	0
w_052E	dw	0

; ----------------------------------------------------------------------------
; cgfx_set_color (slot 25): set_color(index, colour): set one palette entry.
; ----------------------------------------------------------------------------
cgfx_set_color:
	retf

; ----------------------------------------------------------------------------
; cgfx_set_palette (slot 26): set_palette(pal): set the 16-colour palette (17 bytes, the last is the border).
; ----------------------------------------------------------------------------
cgfx_set_palette:
	retf

; ----------------------------------------------------------------------------
; cgfx_set_color_map (slot 27): set_color_map(...): colour mapping for the dithered modes.
; ----------------------------------------------------------------------------
cgfx_set_color_map:
	mov	bx, sp
	push	si
	push	di
	push	ds
	mov	dx, DATA
	mov	es, dx
	mov	cx, 10h
	cmp	word ptr cs:w_D01E8, 1
	jne	L_054A
	mov	cx, 80h
L_054A:
	mov	word ptr cs:w_052E, cx
	mov	si, word ptr [bx+4]
	or	si, si
	je	L_055F
	mov	di, 210h
L_0559:
	lodsb
	and	al, 3
	stosb
	loop	L_0559
L_055F:
	mov	cx, word ptr cs:w_052E
	mov	si, word ptr [bx+6]
	or	si, si
	je	L_05B1
	mov	di, 390h
L_056E:
	lodsb
	mov	bl, al
	and	bl, 3
	mov	byte ptr es:[di+b_D0080], bl
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	and	al, 3
	mov	byte ptr es:[di+b_D0100], al
	stosb
	loop	L_056E
	mov	ds, dx
	mov	cx, word ptr cs:w_052E
	sub	bh, bh
	sub	si, si
	mov	di, 290h
L_0599:
	mov	bl, byte ptr [si+b_D0390]
	shl	bl, 1
	mov	ax, word ptr [bx+w_D0578]
	mov	bl, byte ptr [si+b_D0410]
	shl	bl, 1
	or	ax, word ptr [bx+w_D0580]
	stosw
	inc	si
	loop	L_0599
L_05B1:
	pop	ds
	pop	di
	pop	si
	retf
	db	88h,20h,8,30h

; ----------------------------------------------------------------------------
; cgfx_set_draw_color (slot 40): AL = colour, AH = mode (0 copy, 1 and, 2 or, 3 xor) for the primitives.
; ----------------------------------------------------------------------------
cgfx_set_draw_color:
	push	ds
	mov	bx, DATA
	mov	ds, bx
	and	al, 0Fh
	mov	byte ptr draw_color, al
	mov	al, ah
	and	al, 3
	mov	byte ptr cs:draw_mode, al
	lea	bx, draw_op_table
	xlat	byte ptr cs:[bx]
	mov	byte ptr cs:draw_opcode, al
	pop	ds
	retf

; ----------------------------------------------------------------------------
; cgfx_nop39 (slot 39): Slot 39.
; ----------------------------------------------------------------------------
cgfx_nop39:
	retf
	db	0
b_05DA	db	0
b_05DB	db	0
L_05DC:
	jmp	L_06A0

; ----------------------------------------------------------------------------
; cgfx_copy_rect (slot 19): copy_rect(src_port, x, y, w, h, dst_port, x, y): copy a rectangle between pages.
; ----------------------------------------------------------------------------
cgfx_copy_rect:
	push	bp
	mov	bp, sp
	push	di
	push	si
	push	es
	push	ds
	mov	cx, word ptr [bp+0Ch]
	mov	dx, word ptr [bp+0Eh]
	or	cx, cx
	je	L_05DC
	or	dx, dx
	je	L_05DC
	mov	si, word ptr [bp+6]
	mov	di, word ptr [bp+10h]
	mov	bx, word ptr [si]
	shl	bx, 1
	push	word ptr cs:[bx+page_seg]
	mov	bx, word ptr [di]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	mov	ax, word ptr [si+2]
	add	ax, word ptr [bp+8]
	mov	si, word ptr [si+4]
	add	si, word ptr [bp+0Ah]
	shl	si, 1
	add	si, 1B50h
	mov	bx, word ptr [di+2]
	add	bx, word ptr [bp+12h]
	mov	di, word ptr [di+4]
	add	di, word ptr [bp+14h]
	mov	word ptr cs:w_009E, cx
	mov	word ptr cs:w_00A0, dx
	mov	word ptr cs:w_009A, bx
	mov	word ptr cs:w_009C, di
	shl	di, 1
	add	di, 1B50h
	pop	ds
	mov	bp, dx
	mov	cl, bl
	and	cl, 3
	shl	cl, 1
	mov	dh, 0FFh
	shr	dh, cl
	mov	cx, bx
	add	cx, word ptr cs:w_009E
	dec	cx
	and	cl, 3
	shl	cl, 1
	mov	dl, 0C0h
	sar	dl, cl
	mov	cx, bx
	and	cx, 3
	add	cx, word ptr cs:w_009E
	dec	cx
	shr	cx, 1
	shr	cx, 1
	mov	ch, cl
	mov	cl, bl
	and	cl, 3
	shr	bx, 1
	shr	bx, 1
	mov	bh, al
	and	bh, 3
	sub	cl, bh
	shr	ax, 1
	shr	ax, 1
	mov	bh, al
	mov	byte ptr cs:b_05DA, dh
	mov	byte ptr cs:b_05DB, ch
	shl	cl, 1
	je	L_06A6
	jb	L_06F9
	jmp	L_0757
L_069D:
	call	sub_00C5
L_06A0:
	pop	ds
	pop	es
	pop	si
	pop	di
	pop	bp
	retf
L_06A6:
	push	si
	push	di
	mov	si, word ptr cs:[si]
	mov	al, bh
	xor	ah, ah
	add	si, ax
	mov	di, word ptr cs:[di]
	mov	al, bl
	add	di, ax
	mov	dh, byte ptr cs:b_05DA
	mov	ch, byte ptr cs:b_05DB
	or	ch, ch
	je	L_06DD
	lodsb
	and	al, dh
	mov	ah, byte ptr es:[di]
	not	dh
	and	ah, dh
	or	al, ah
	stosb
	jmp	L_06D7
L_06D6:
	movsb
L_06D7:
	dec	ch
	jne	L_06D6
	mov	dh, 0FFh
L_06DD:
	and	dh, dl
	lodsb
	and	al, dh
	mov	ah, byte ptr es:[di]
	not	dh
	and	ah, dh
	or	al, ah
	stosb
	pop	di
	pop	si
	add	di, 2
	add	si, 2
	dec	bp
	jne	L_06A6
	jmp	L_069D
L_06F9:
	neg	cl
L_06FB:
	push	si
	push	di
	mov	si, word ptr cs:[si]
	mov	al, bh
	xor	ah, ah
	add	si, ax
	mov	di, word ptr cs:[di]
	mov	al, bl
	add	di, ax
	mov	dh, byte ptr cs:b_05DA
	mov	ch, byte ptr cs:b_05DB
	or	ch, ch
	je	L_0738
	lodsw
	rol	ax, cl
	and	al, dh
	mov	ah, byte ptr es:[di]
	not	dh
	and	ah, dh
	or	al, ah
	stosb
	jmp	L_0731
L_072D:
	lodsw
	rol	ax, cl
	stosb
L_0731:
	dec	si
	dec	ch
	jne	L_072D
	mov	dh, 0FFh
L_0738:
	and	dh, dl
	lodsw
	rol	ax, cl
	and	al, dh
	mov	ah, byte ptr es:[di]
	not	dh
	and	ah, dh
	or	al, ah
	stosb
	pop	di
	pop	si
	add	di, 2
	add	si, 2
	dec	bp
	jne	L_06FB
	jmp	L_069D
L_0757:
	push	si
	push	di
	mov	si, word ptr cs:[si]
	mov	al, bh
	xor	ah, ah
	add	si, ax
	dec	si
	mov	di, word ptr cs:[di]
	mov	al, bl
	add	di, ax
	mov	dh, byte ptr cs:b_05DA
	mov	ch, byte ptr cs:b_05DB
	or	ch, ch
	je	L_079A
	lodsb
	mov	ah, al
	lodsb
	ror	ax, cl
	and	al, dh
	mov	ah, byte ptr es:[di]
	not	dh
	and	ah, dh
	or	al, ah
	stosb
	jmp	L_0793
L_078D:
	lodsw
	ror	ax, cl
	mov	al, ah
	stosb
L_0793:
	dec	si
	dec	ch
	jne	L_078D
	mov	dh, 0FFh
L_079A:
	and	dh, dl
	lodsb
	mov	ah, al
	lodsb
	ror	ax, cl
	and	al, dh
	mov	ah, byte ptr es:[di]
	not	dh
	and	ah, dh
	or	al, ah
	stosb
	pop	di
	pop	si
	add	di, 2
	add	si, 2
	dec	bp
	jne	L_0757
	jmp	L_069D

; ----------------------------------------------------------------------------
; cgfx_recolor_rect (slot 3): recolor_rect(port, x, y, w, h, from, to): within the rectangle, replace colour 'from' by 'to'.
; ----------------------------------------------------------------------------
cgfx_recolor_rect:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	push	es
	mov	bx, word ptr [bp+6]
	mov	si, word ptr [bx]
	shl	si, 1
	mov	ax, word ptr cs:[si+page_seg]
	mov	es, ax
	mov	si, word ptr [bp+0Ah]
	add	si, word ptr [bx+4]
	mov	word ptr cs:w_009C, si
	mov	di, word ptr [bp+8]
	add	di, word ptr [bx+2]
	mov	word ptr cs:w_009A, di
	mov	dx, DATA
	mov	ds, dx
	mov	bl, byte ptr [bp+10h]
	sub	bh, bh
	mov	bl, byte ptr [bx+w_D0210]
	mov	dl, byte ptr [bx+w_D020C]
	mov	bl, byte ptr [bp+12h]
	mov	bl, byte ptr [bx+w_D0210]
	mov	dh, byte ptr [bx+w_D020C]
	mov	ax, word ptr [bp+0Ch]
	mov	word ptr cs:w_009E, ax
	mov	ax, word ptr [bp+0Eh]
	mov	word ptr cs:w_00A0, ax
	shl	si, 1
	mov	cx, di
	shr	di, 1
	shr	di, 1
	add	cx, word ptr [bp+0Ch]
	dec	cx
	mov	byte ptr b_D0588, cl
	shr	cx, 1
	shr	cx, 1
	sub	cx, di
	inc	cx
	mov	ax, cx
	mov	cx, word ptr cs:w_009A
	mov	bx, 0FF00h
	and	cl, 3
	shl	cl, 1
	shr	bx, cl
	mov	bh, 3Fh
	mov	cl, byte ptr b_D0588
	and	cl, 3
	shl	cl, 1
	shr	bh, cl
	mov	cx, ax
	mov	bp, word ptr [bp+0Eh]
L_084C:
	push	di
	push	cx
	push	bx
	add	di, word ptr [si+row_offset]
	dec	cx
	je	L_08A0
	mov	al, byte ptr es:[di]
	xor	al, dl
	mov	ah, al
	je	L_086C
	shr	ah, 1
	or	ah, al
	and	ah, 55h
	mov	al, ah
	shl	al, 1
	or	ah, al
L_086C:
	or	ah, bl
	mov	al, byte ptr es:[di]
	xor	al, dh
	and	al, ah
	xor	al, dh
	stosb
	jmp	L_089B
L_087B:
	mov	al, byte ptr es:[di]
	xor	al, dl
	mov	ah, al
	je	L_0891
	shr	ah, 1
	or	ah, al
	and	ah, 55h
	mov	al, ah
	shl	al, 1
	or	ah, al
L_0891:
	mov	al, byte ptr es:[di]
	xor	al, dh
	and	al, ah
	xor	al, dh
	stosb
L_089B:
	loop	L_087B
	jmp	L_08A2
L_08A0:
	and	bl, bh
L_08A2:
	mov	al, byte ptr es:[di]
	xor	al, dl
	mov	ah, al
	je	L_08B8
	shr	ah, 1
	or	ah, al
	and	ah, 55h
	mov	al, ah
	shl	al, 1
	or	ah, al
L_08B8:
	or	ah, bh
	mov	al, byte ptr es:[di]
	xor	al, dh
	and	al, ah
	xor	al, dh
	stosb
	pop	bx
	pop	cx
	pop	di
	add	si, 2
	dec	bp
	je	L_08D0
	jmp	L_084C
L_08D0:
	call	sub_00C5
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
	db	0

; ----------------------------------------------------------------------------
; cgfx_show_page (slot 30): show_page(n): copy page n to the screen (with the mouse pointer).
; ----------------------------------------------------------------------------
cgfx_show_page:
	mov	bx, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bx+4]
	or	si, si
	je	L_0918
	mov	ax, si
	call	save_ptr_bg
	shl	si, 1
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:page_seg
	mov	ax, 0C8h
	lea	bx, ds:[1B50h]
	mov	dx, 50h
	shr	dx, 1
L_0904:
	mov	si, word ptr cs:[bx]
	mov	di, si
	mov	cx, dx
	rep	movsw
	add	bx, 2
	dec	ax
	jne	L_0904
	call	far ptr cgfx_nop13
L_0918:
	pop	es
	pop	ds
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; cgfx_swap_page (slot 35): swap_page(n): exchange the contents of page n and the screen.
; ----------------------------------------------------------------------------
cgfx_swap_page:
	retf

; ----------------------------------------------------------------------------
; cgfx_clear_page (slot 5): clear_page(page, colour): fill a whole page.
; ----------------------------------------------------------------------------
cgfx_clear_page:
	mov	bx, sp
	push	si
	push	di
	push	es
	mov	ax, DATA
	mov	es, ax
	mov	di, word ptr [bx+6]
	shl	di, 1
	mov	ax, word ptr es:[di+w_D0290]
	mov	di, word ptr [bx+4]
	shl	di, 1
	mov	es, word ptr cs:[di+page_seg]
	mov	si, 0C8h
	lea	bx, ds:[1B50h]
	mov	dx, 50h
	shr	dx, 1
L_0948:
	mov	di, word ptr cs:[bx]
	mov	cx, dx
	rep	stosw
	ror	ax, 1
	ror	ax, 1
	add	bx, 2
	dec	si
	jne	L_0948
	call	far ptr cgfx_nop13
	pop	es
	pop	di
	pop	si
	retf
b_0962	db	0C0h,30h,0Ch,3
dissolve_delay	dw	0
L_0968:
	jmp	L_0A7D

; ----------------------------------------------------------------------------
; cgfx_dissolve_page (slot 9): dissolve_page(n): copy page n to the screen in a pseudo-random dissolve.
; ----------------------------------------------------------------------------
cgfx_dissolve_page:
	mov	bx, sp
	push	bp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bx+4]
	shl	si, 1
	je	L_0968
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:page_seg
	xor	bx, bx
	mov	bx, word ptr cs:dissolve_delay
	or	bx, bx
	jne	L_09F0
L_098E:
	inc	bx
L_098F:
	mov	dx, 3DAh
	in	al, dx
	test	al, 8
	je	L_098F
L_0997:
	in	al, dx
	test	al, 8
	jne	L_0997
	mov	bp, 1
	xor	cx, cx
L_09A1:
	shr	bp, 1
	jae	L_09A9
	xor	bp, 0B400h
L_09A9:
	cmp	bp, 0
	jb	L_09A1
	mov	si, bp
	dec	si
	mov	di, si
	and	di, 3
	cmp	si, 7D00h
	jb	L_09C0
	add	si, 300h
L_09C0:
	shr	si, 1
	shr	si, 1
	mov	ah, byte ptr cs:[di+b_0962]
	mov	di, 0FFFFh
	lodsb
	mov	dl, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	stosb
	mov	ax, bx
L_09D9:
	dec	ax
	jne	L_09D9
	inc	cx
	mov	dx, 3DAh
	in	al, dx
	test	al, 8
	je	L_09A1
	cmp	cx, 215h
	ja	L_098E
	mov	word ptr cs:dissolve_delay, bx
L_09F0:
	mov	bp, 1
	mov	cx, 0FA00h
	cmp	bx, 1
	je	L_0A40
L_09FB:
	shr	bp, 1
	jae	L_0A03
	xor	bp, 0B400h
L_0A03:
	cmp	bp, 0FA00h
	ja	L_09FB
	mov	si, bp
	dec	si
	mov	di, si
	and	di, 3
	cmp	si, 7D00h
	jb	L_0A1B
	add	si, 300h
L_0A1B:
	shr	si, 1
	shr	si, 1
	mov	ah, byte ptr cs:[di+b_0962]
	mov	di, si
	lodsb
	mov	dl, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	stosb
	mov	ax, bx
L_0A33:
	dec	ax
	jne	L_0A33
	loop	L_09FB
	call	far ptr cgfx_nop13
	jmp	L_0A7D
L_0A40:
	shr	bp, 1
	jae	L_0A48
	xor	bp, 0B400h
L_0A48:
	cmp	bp, 0FA00h
	ja	L_0A40
	mov	si, bp
	dec	si
	mov	di, si
	and	di, 3
	cmp	si, 7D00h
	jb	L_0A60
	add	si, 300h
L_0A60:
	shr	si, 1
	shr	si, 1
	mov	ah, byte ptr cs:[di+b_0962]
	mov	di, si
	lodsb
	mov	dl, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	stosb
	loop	L_0A40
	call	far ptr cgfx_nop13
L_0A7D:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
	db	0
img_ptr	dw	0
img_seg	dw	0
img_block	dw	0
img_block_end	dw	0
img_limit	dw	0
img_skip	dw	0
img_trail	dw	0
img_len	dw	0
w_0A94	dw	0
w_0A96	dw	0
b_0A98	db	0
b_0A99	db	0
b_0A9A	db	0
	EVEN
img_rows	dw	0
img_width	dw	0
blit_rows	dw	0
blit_cols	dw	0,0,0
dst_width	dw	0
dst_height	dw	0
flip_x	dw	0
flip_y	dw	0
blit_rect	dw	0
blit_rect_y	dw	0
blit_rect_w	dw	0
blit_rect_h	dw	0
clip_top	dw	0
clip_left	dw	0
clip_bottom	dw	0
clip_right	dw	6 dup (0)
w_0ACA	dw	0
b_0ACC	db	0
b_0ACD	db	0
b_0ACE	db	0
b_0ACF	db	0
b_0AD0	db	0
b_0AD1	db	0
w_0AD2	dw	161 dup (0)

; ----------------------------------------------------------------------------
; cgfx_begin_image_grab (slot 17): begin_image_grab(): allocate the largest free DOS block to collect images in.
; ----------------------------------------------------------------------------
cgfx_begin_image_grab:
	call	far ptr cgfx_mem_avail
	mov	bx, ax
	or	bx, bx
	je	L_0C25
	mov	ah, 48h
	int	21h
	jae	L_0C29
L_0C25:
	xor	ax, ax
	xor	bx, bx
L_0C29:
	add	bx, ax
	mov	word ptr cs:img_ptr, 0
	mov	word ptr cs:img_seg, ax
	mov	word ptr cs:img_block, ax
	mov	word ptr cs:img_block_end, bx
	mov	byte ptr cs:b_D0510, 1
	retf

; ----------------------------------------------------------------------------
; cgfx_end_image_grab (slot 7): end_image_grab(): shrink the image block to what was used; returns its segment.
; ----------------------------------------------------------------------------
cgfx_end_image_grab:
	mov	byte ptr cs:b_D0510, 0
	mov	ax, word ptr cs:img_block
	or	ax, ax
	je	L_0C6C
	mov	bx, word ptr cs:img_seg
	sub	bx, ax
	mov	es, ax
	mov	ah, 4Ah
	or	bx, bx
	jne	L_0C65
	mov	ah, 49h
L_0C65:
	int	21h
	jb	L_0C6C
	mov	ax, es
	retf
L_0C6C:
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; cgfx_begin_image (slot 34): begin_image(w, h): start an image; returns its segment (0 if out of room).
; ----------------------------------------------------------------------------
cgfx_begin_image:
	mov	ax, word ptr cs:img_block_end
	sub	ax, word ptr cs:img_seg
	jbe	L_0CD6
	cmp	ax, 1000h
	jb	L_0C82
	mov	ax, 0FFFh
L_0C82:
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	word ptr cs:img_limit, ax
	mov	bx, sp
	push	di
	les	di, dword ptr cs:img_ptr
	mov	ax, word ptr ss:[bx+4]
	stosw
	mov	cx, 0E5Ah
	mov	word ptr cs:w_0A96, cx
	mov	byte ptr cs:b_0A98, 1
	mov	cx, ax
	add	ax, 3
	shr	ax, 1
	shr	ax, 1
	mov	word ptr cs:img_width, ax
	dec	cx
	and	cl, 3
	shl	cl, 1
	mov	al, 0C0h
	sar	al, cl
	mov	byte ptr cs:b_0A99, al
	mov	ax, word ptr ss:[bx+6]
	stosw
	mov	word ptr cs:img_rows, ax
	mov	word ptr cs:img_ptr, di
	mov	ax, es
	pop	di
	retf
L_0CD6:
	xor	ax, ax
	mov	word ptr cs:img_ptr, ax
	mov	word ptr cs:img_seg, ax
	retf

; ----------------------------------------------------------------------------
; cgfx_end_image (slot 32): end_image(): close the image being built; returns its segment.
; ----------------------------------------------------------------------------
cgfx_end_image:
	xor	ax, ax
	xchg	word ptr cs:img_ptr, ax
	add	ax, 0Fh
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	ax, word ptr cs:img_seg
	xchg	word ptr cs:img_seg, ax
	retf

; ----------------------------------------------------------------------------
; cgfx_image_add_row (slot 33): image_add_row(row): append a row to the image being built.
; ----------------------------------------------------------------------------
cgfx_image_add_row:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	si, word ptr [bp+6]
	les	di, dword ptr cs:img_ptr
	mov	ax, es
	or	ax, ax
	jne	L_0D14
	jmp	L_0DC0
L_0D14:
	xor	ax, ax
	mov	word ptr cs:img_skip, ax
	mov	word ptr cs:img_trail, ax
	mov	word ptr cs:img_len, ax
	xor	byte ptr cs:b_0A98, 1
	mov	bx, 1E90h
	je	L_0D31
	add	bx, 80h
L_0D31:
	mov	ax, word ptr cs:img_width
	shl	ax, 1
	add	ax, 4
	add	ax, di
	cmp	ax, word ptr cs:img_limit
	jbe	L_0D51
	dec	word ptr es:[2]
	xor	ax, ax
	mov	word ptr cs:img_block_end, ax
	jmp	L_0DC0
L_0D51:
	mov	bp, di
	stosw
	stosw
	mov	ax, word ptr cs:img_width
	mov	word ptr cs:w_0A94, ax
L_0D5D:
	call	word ptr cs:w_0A96
	je	L_0D6E
	mov	word ptr cs:img_trail, 0
	jmp	L_0D8A
L_0D6E:
	cmp	word ptr cs:img_len, 0
	jne	L_0D85
	inc	word ptr cs:img_skip
	dec	word ptr cs:w_0A94
	jne	L_0D5D
	jmp	L_0D99
L_0D85:
	inc	word ptr cs:img_trail
L_0D8A:
	inc	word ptr cs:img_len
	mov	ax, dx
	stosw
	dec	word ptr cs:w_0A94
	jne	L_0D5D
L_0D99:
	mov	ax, word ptr cs:img_len
	mov	bx, word ptr cs:img_skip
	mov	cx, word ptr cs:img_trail
	or	cx, cx
	je	L_0DB1
	sub	ax, cx
	shl	cx, 1
	sub	di, cx
L_0DB1:
	mov	word ptr es:[bp], ax
	mov	word ptr es:[bp+2], bx
	mov	word ptr cs:img_ptr, di
	mov	ax, es
L_0DC0:
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_get_image (slot 2): get_image(page, x, y, w, h): grab a block of a page as an image.
; ----------------------------------------------------------------------------
cgfx_get_image:
	push	bp
	mov	bp, sp
	push	si
	push	ds
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	call	far ptr cgfx_begin_image
	add	sp, 4
	or	ax, ax
	je	L_0E32
	cmp	word ptr cs:img_rows, 0
	je	L_0E32
	cmp	word ptr cs:img_width, 0
	je	L_0E32
	mov	si, word ptr [bp+0Ah]
	shl	si, 1
	mov	bx, word ptr [bp+6]
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
	mov	bp, word ptr [bp+8]
	mov	ax, bp
	and	ax, 3
	shl	ax, 1
	mov	byte ptr cs:b_0A9A, al
	shr	bp, 1
	shr	bp, 1
	mov	word ptr cs:w_0A96, 0E3Bh
L_0E13:
	mov	cl, byte ptr cs:b_0A9A
	mov	ax, word ptr cs:[si+row_offset]
	add	ax, bp
	push	ax
	call	far ptr cgfx_image_add_row
	add	sp, 2
	add	si, 2
	dec	word ptr cs:img_rows
	jne	L_0E13
L_0E32:
	call	far ptr cgfx_end_image
	pop	ds
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; L_0E3B
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0E3B:
	mov	dx, word ptr cs:[si+w_D07D4]
	rol	dx, cl
	mov	dh, dl
	lodsw
	rol	ax, cl
	mov	dl, al
	dec	si
	cmp	word ptr cs:w_0A94, 1
	jne	L_0E57
	and	dh, byte ptr cs:b_0A99
L_0E57:
	or	dh, dh
	ret

; ----------------------------------------------------------------------------
; L_0E5A
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0E5A:
	sub	dh, dh
	lodsw
	or	al, al
	je	L_0E64
	or	dh, 0C0h
L_0E64:
	or	ah, ah
	je	L_0E6B
	or	dh, 30h
L_0E6B:
	xlat	byte ptr cs:[bx]
	mov	dl, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dl, 1
	shl	dl, 1
	or	dl, al
	shl	dl, 1
	shl	dl, 1
	lodsw
	or	al, al
	je	L_0E8D
	or	dh, 0Ch
L_0E8D:
	or	ah, ah
	je	L_0E94
	or	dh, 3
L_0E94:
	xlat	byte ptr cs:[bx]
	or	dl, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dl, 1
	shl	dl, 1
	or	dl, al
	cmp	word ptr cs:w_0A94, 1
	jne	L_0EB7
	and	dh, byte ptr cs:b_0A99
L_0EB7:
	or	dh, dh
	ret

; ----------------------------------------------------------------------------
; cgfx_draw_image_scaled (slot 21): draw_image_scaled(port, x, y, w, h, image, param): draw an image scaled (mirrored when w or h < 0).
; ----------------------------------------------------------------------------
cgfx_draw_image_scaled:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	mov	ax, word ptr [bp+0Ch]
	cwd
	xor	ax, dx
	sub	ax, dx
	mov	word ptr cs:dst_width, ax
	mov	word ptr cs:flip_x, dx
	mov	ax, word ptr [bp+0Eh]
	cwd
	xor	ax, dx
	sub	ax, dx
	mov	word ptr cs:dst_height, ax
	mov	word ptr cs:flip_y, dx
	mov	dx, word ptr [bp+8]
	mov	di, word ptr [bp+0Ah]
	mov	ds, word ptr [bp+10h]
	xor	si, si
	mov	bp, word ptr [bp+6]
	call	reset_clip
	je	L_0EFF
	call	clip_image
	jb	L_0EFF
	call	far ptr thunk_FUN_1000_1036
L_0EFF:
	mov	ax, 0AB0h
	mov	dx, cs
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_draw_image (slot 6): draw_image(port, x, y, image): draw an image clipped to the port; returns a far pointer to the drawn rectangle.
; ----------------------------------------------------------------------------
cgfx_draw_image:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	mov	dx, word ptr [bp+8]
	mov	di, word ptr [bp+0Ah]
	mov	ds, word ptr [bp+0Ch]
	xor	si, si
	mov	bp, word ptr [bp+6]
	mov	ax, word ptr [si]
	mov	word ptr cs:dst_width, ax
	mov	ax, word ptr [si+2]
	mov	word ptr cs:dst_height, ax
	call	reset_clip
	je	L_0F39
	call	clip_image
	jb	L_0F39
	call	far ptr blit_image
L_0F39:
	mov	ax, 0AB0h
	mov	dx, cs
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; clip_image
; ----------------------------------------------------------------------------
clip_image:
	or	di, di
	jns	L_0F56
	mov	ax, di
	neg	ax
	cmp	ax, word ptr cs:dst_height
	jae	L_0FA2
	mov	word ptr cs:clip_top, ax
L_0F56:
	mov	ax, di
	add	ax, word ptr cs:dst_height
	dec	ax
	mov	bx, word ptr [bp+8]
	or	bx, bx
	js	L_0FA2
	cmp	di, bx
	jg	L_0FA2
	sub	ax, bx
	jle	L_0F71
	mov	word ptr cs:clip_bottom, ax
L_0F71:
	or	dx, dx
	jns	L_0F84
	mov	ax, dx
	neg	ax
	cmp	ax, word ptr cs:dst_width
	jae	L_0FA2
	mov	word ptr cs:clip_left, ax
L_0F84:
	mov	ax, dx
	add	ax, word ptr cs:dst_width
	dec	ax
	mov	bx, word ptr [bp+6]
	or	bx, bx
	js	L_0FA2
	cmp	dx, bx
	jg	L_0FA2
	sub	ax, bx
	jle	L_0FA4
	mov	word ptr cs:clip_right, ax
	jmp	L_0FA4
L_0FA2:
	stc
	ret
L_0FA4:
	mov	ax, word ptr cs:clip_left
	add	ax, dx
	mov	word ptr cs:blit_rect, ax
	mov	ax, word ptr cs:clip_top
	add	ax, di
	mov	word ptr cs:blit_rect_y, ax
	mov	ax, word ptr cs:dst_width
	sub	ax, word ptr cs:clip_left
	sub	ax, word ptr cs:clip_right
	mov	word ptr cs:blit_rect_w, ax
	mov	ax, word ptr cs:dst_height
	sub	ax, word ptr cs:clip_top
	sub	ax, word ptr cs:clip_bottom
	mov	word ptr cs:blit_rect_h, ax
	clc
	ret

; ----------------------------------------------------------------------------
; reset_clip
; ----------------------------------------------------------------------------
reset_clip:
	xor	ax, ax
	mov	word ptr cs:clip_top, ax
	mov	word ptr cs:clip_left, ax
	mov	word ptr cs:clip_bottom, ax
	mov	word ptr cs:clip_right, ax
	mov	word ptr cs:blit_rect, ax
	mov	word ptr cs:blit_rect_y, ax
	mov	word ptr cs:blit_rect_w, ax
	mov	word ptr cs:blit_rect_h, ax
	mov	ax, ds
	or	ax, ax
	je	L_1012
	mov	ax, word ptr ds:[0]
	or	ax, ax
	je	L_1012
	mov	ax, word ptr ds:[2]
	or	ax, ax
L_1012:
	ret

; ----------------------------------------------------------------------------
; cgfx_draw_image_noclip (slot 31): draw_image_noclip(port, x, y, image): draw an image without clipping.
; ----------------------------------------------------------------------------
cgfx_draw_image_noclip:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	mov	dx, word ptr [bp+8]
	mov	di, word ptr [bp+0Ah]
	mov	ds, word ptr [bp+0Ch]
	xor	si, si
	mov	bp, word ptr [bp+6]
	call	reset_clip
	je	L_1031
	call	far ptr blit_image
L_1031:
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; blit_image
; ----------------------------------------------------------------------------
blit_image:
	push	bp
	push	es
	mov	bx, word ptr [bp]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	add	dx, word ptr [bp+2]
	add	di, word ptr [bp+4]
	add	di, word ptr cs:clip_top
	mov	word ptr cs:w_009C, di
	shl	di, 1
	lodsw
	mov	bp, ax
	sub	ax, word ptr cs:clip_left
	sub	ax, word ptr cs:clip_right
	mov	word ptr cs:w_009E, ax
	mov	cx, dx
	and	cx, 3
	shl	cl, 1
	mov	byte ptr cs:b_0AD1, cl
	mov	al, 0FFh
	shr	al, cl
	mov	byte ptr cs:b_0ACC, al
	xor	bx, bx
	or	cl, cl
	je	L_1082
	not	al
	inc	bx
L_1082:
	mov	byte ptr cs:b_0ACD, al
	mov	word ptr cs:w_0ACA, bx
	mov	cx, dx
	add	cx, word ptr cs:clip_left
	mov	word ptr cs:w_009A, cx
	mov	bx, cx
	and	cx, 3
	shl	cl, 1
	mov	al, 0FFh
	shr	al, cl
	mov	byte ptr cs:b_0ACF, al
	shr	bx, 1
	shr	bx, 1
	mov	word ptr cs:w_0AD2, bx
	add	dx, bp
	dec	dx
	sub	dx, word ptr cs:clip_right
	mov	cx, dx
	and	cl, 3
	shl	cl, 1
	mov	al, 0C0h
	sar	al, cl
	mov	byte ptr cs:b_0AD0, al
	mov	ax, dx
	shr	ax, 1
	shr	ax, 1
	sub	ax, bx
	inc	ax
	mov	word ptr cs:blit_cols, ax
	lodsw
	sub	ax, word ptr cs:clip_top
	sub	ax, word ptr cs:clip_bottom
	mov	word ptr cs:w_00A0, ax
	jg	L_10E7
	jmp	L_11AB
L_10E7:
	mov	word ptr cs:blit_rows, ax
	mov	cx, word ptr cs:clip_top
	jcxz	L_10FC
L_10F2:
	lodsw
	add	si, 2
	shl	ax, 1
	add	si, ax
	loop	L_10F2
L_10FC:
	xor	ah, ah
	mov	al, byte ptr cs:b_0AD1
	shr	al, 1
	add	ax, word ptr cs:clip_left
	shr	ax, 1
	shr	ax, 1
	mov	word ptr cs:clip_left, ax
L_1111:
	lodsw
	mov	dx, ax
	lodsw
	or	dx, dx
	je	L_1195
	mov	bp, dx
	shl	bp, 1
	add	bp, si
	push	di
	mov	di, word ptr cs:[di+row_offset]
	add	di, word ptr cs:w_0AD2
	mov	bh, byte ptr cs:b_0ACF
	mov	bl, byte ptr cs:b_0AD0
	mov	cx, word ptr cs:blit_cols
	add	dx, word ptr cs:w_0ACA
	sub	ax, word ptr cs:clip_left
	je	L_1162
	jb	L_1155
	add	di, ax
	sub	cx, ax
	jbe	L_1192
	mov	bh, byte ptr cs:b_0ACC
	jmp	L_1167
L_1155:
	neg	ax
	sub	dx, ax
	jbe	L_1192
	shl	ax, 1
	add	si, ax
	jmp	L_1167
L_1162:
	and	bh, byte ptr cs:b_0ACC
L_1167:
	cmp	dx, cx
	je	L_1177
	ja	L_117C
	mov	cx, dx
	mov	bl, byte ptr cs:b_0ACD
	jmp	L_117C
L_1177:
	and	bl, byte ptr cs:b_0ACD
L_117C:
	mov	byte ptr cs:b_0ACE, bl
	mov	bl, cl
	sub	si, 2
	mov	cl, byte ptr cs:b_0AD1
	or	cl, cl
	je	L_11A2
	jmp	L_11AE
L_1192:
	mov	si, bp
	pop	di
L_1195:
	add	di, 2
	dec	byte ptr cs:blit_rows
	je	L_11A8
	jmp	L_1111
L_11A2:
	add	si, 2
	jmp	L_11DE
L_11A8:
	call	sub_00C5
L_11AB:
	pop	es
	pop	bp
	retf
L_11AE:
	lodsw
	mov	dx, word ptr [si]
	xchg	ah, dl
	ror	ax, cl
	ror	dx, cl
	mov	al, ah
	cmp	bl, 1
	je	L_11D4
L_11BE:
	and	dh, bh
	je	L_11DB
	mov	dl, byte ptr es:[di]
	xor	al, dl
	and	al, dh
	xor	al, dl
	stosb
L_11CC:
	mov	bh, 0FFh
	dec	bl
	jne	L_11AE
	jmp	L_1192
L_11D4:
	and	bh, byte ptr cs:b_0ACE
	jmp	L_11BE
L_11DB:
	inc	di
	jmp	L_11CC
L_11DE:
	lodsw
	cmp	bl, 1
	je	L_11FA
L_11E4:
	and	ah, bh
	je	L_1201
	mov	dl, byte ptr es:[di]
	xor	al, dl
	and	al, ah
	xor	al, dl
	stosb
L_11F2:
	mov	bh, 0FFh
	dec	bl
	jne	L_11DE
	jmp	L_1192
L_11FA:
	and	bh, byte ptr cs:b_0ACE
	jmp	L_11E4
L_1201:
	inc	di
	jmp	L_11F2

; ----------------------------------------------------------------------------
; thunk_FUN_1000_1036
; ----------------------------------------------------------------------------
thunk_FUN_1000_1036:
	jmp	far ptr blit_image

; ----------------------------------------------------------------------------
; L_1209
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_1209:
	push	bp
	push	es
	pop	es
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_copy_rows_to_screen (slot 49): AX = first row, CX = last row, BX = span table, SI/DI = pages: copy each row's span.
; ----------------------------------------------------------------------------
cgfx_copy_rows_to_screen:
	or	ax, ax
	js	L_1255
	push	ds
	push	es
	shl	si, 1
	shl	di, 1
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:[di+page_seg]
	mov	bp, bx
	mov	bx, ax
	shl	bx, 1
	mov	dx, cx
	shl	dx, 1
L_122C:
	mov	si, bx
	mov	ax, word ptr [bp+si]
	mov	cx, word ptr [bp+si+190h]
	shr	ax, 1
	shr	ax, 1
	shr	cx, 1
	shr	cx, 1
	sub	cx, ax
	jb	L_124C
	inc	cx
	mov	di, word ptr cs:[si+row_offset]
	add	di, ax
	mov	si, di
	rep	movsb
L_124C:
	add	bx, 2
	cmp	bx, dx
	jbe	L_122C
	pop	es
	pop	ds
L_1255:
	retf

; ----------------------------------------------------------------------------
; cgfx_patch_font (slot 15): patch_font(font, data): copy a font image over font n.
; ----------------------------------------------------------------------------
cgfx_patch_font:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	mov	ax, DATA
	mov	es, ax
	mov	si, word ptr [bp+8]
	mov	di, word ptr [bp+6]
	cmp	di, word ptr es:w_D4720
	ja	L_12A1
	shl	di, 1
	je	L_12A1
	mov	di, word ptr es:[di+w_D4720]
	add	di, 4720h
	mov	cl, byte ptr [si-7]
	sub	cl, byte ptr [si-8]
	inc	cl
	xor	ch, ch
	mov	ah, byte ptr [si-4]
	add	ah, byte ptr [si-2]
	mov	al, byte ptr [si-6]
	mul	ah
	mul	cl
	add	cx, 8
	add	ax, cx
	sub	si, cx
	sub	di, cx
	mov	cx, ax
	shr	cx, 1
	rep	movsw
L_12A1:
	pop	es
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_char_width (slot 4): char_width(font, ch): width of a character (0 if not in the font).
; ----------------------------------------------------------------------------
cgfx_char_width:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	cl, byte ptr [bp+8]
	or	cl, cl
	js	L_12F1
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr w_D4720
	ja	L_12F1
	shl	bx, 1
	je	L_12F1
	mov	bx, word ptr [bx+w_D4720]
	add	bx, 4720h
	cmp	cl, byte ptr [bx-8]
	jb	L_12F1
	cmp	cl, byte ptr [bx-7]
	ja	L_12F1
	mov	ah, byte ptr [bx-3]
	mov	al, byte ptr [bx-5]
	or	al, al
	jne	L_12F1
	mov	al, cl
	mov	cl, byte ptr [bx-7]
	sub	cl, al
	xor	ch, ch
	add	bx, -9
	sub	bx, cx
	mov	al, byte ptr [bx]
L_12F1:
	add	al, ah
	cbw
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_font_height (slot 10): font_height(font): height of a font's characters.
; ----------------------------------------------------------------------------
cgfx_font_height:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr w_D4720
	ja	L_131D
	shl	bx, 1
	je	L_131D
	mov	bx, word ptr [bx+w_D4720]
	add	bx, 4720h
	mov	al, byte ptr [bx-4]
	add	al, byte ptr [bx-2]
L_131D:
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_draw_text (slot 20): draw_text(port, x, y, string, ?): draw a string clipped to the port.
; ----------------------------------------------------------------------------
cgfx_draw_text:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	bx, word ptr [bp+0Ch]
	mov	cx, word ptr [bp+8]
	mov	dx, word ptr [bp+0Ah]
	mov	bp, word ptr [bp+6]
	call	far ptr cgfx_text_clip_all
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; cgfx_text_clip_all (slot 42): BP = port, CX = x, DX = y, BX = string (SS): draw text clipped on all sides.
; ----------------------------------------------------------------------------
cgfx_text_clip_all:
	call	text_setup
	call	clip_text_right
	call	clip_text_left
	call	clip_text_vert
	jmp	L_1425

; ----------------------------------------------------------------------------
; cgfx_text_clip_left (slot 43): As text_clip_all, clipped on the left only.
; ----------------------------------------------------------------------------
cgfx_text_clip_left:
	call	text_setup
	call	clip_text_left
	jmp	L_1425

; ----------------------------------------------------------------------------
; clip_text_left
; ----------------------------------------------------------------------------
clip_text_left:
	cmp	byte ptr ds:[591h], 0
	je	L_138A
	cmp	word ptr [bp+6], 0
	js	L_1386
	mov	ax, word ptr ds:[59Bh]
	or	ax, ax
	jns	L_138A
	mov	word ptr ds:[59Bh], 0
	neg	ax
	div	byte ptr ds:[591h]
	mov	byte ptr ds:[592h], ah
	inc	al
L_1378:
	dec	al
	je	L_138A
L_137C:
	mov	ah, byte ptr ss:[bx]
	inc	bx
	or	ah, ah
	js	L_137C
	jne	L_1378
L_1386:
	pop	ax
	jmp	L_143A
L_138A:
	ret

; ----------------------------------------------------------------------------
; cgfx_text_clip_right (slot 45): As text_clip_all, clipped on the right only.
; ----------------------------------------------------------------------------
cgfx_text_clip_right:
	call	text_setup
	call	clip_text_right
	jmp	L_1425

; ----------------------------------------------------------------------------
; clip_text_right
; ----------------------------------------------------------------------------
clip_text_right:
	cmp	byte ptr ds:[591h], 0
	je	L_13D7
	mov	dx, word ptr ds:[59Bh]
	mov	cx, word ptr [bp+6]
	or	cx, cx
	js	L_13D8
	cmp	dx, cx
	jg	L_13D8
	dec	dx
	xor	ah, ah
	mov	al, byte ptr ds:[591h]
	mov	di, ax
	mov	si, bx
	dec	si
L_13B5:
	inc	si
	cmp	byte ptr ss:[si], ah
	js	L_13B5
	je	L_13D7
	add	dx, di
	cmp	dx, cx
	jl	L_13B5
	sub	dx, cx
	mov	byte ptr ds:[596h], dl
	inc	si
	mov	al, byte ptr ss:[si]
	mov	byte ptr ss:[si], ah
	mov	byte ptr ds:[595h], al
	mov	word ptr ds:[593h], si
L_13D7:
	ret
L_13D8:
	pop	ax
	jmp	L_143A

; ----------------------------------------------------------------------------
; cgfx_text_clip_vert (slot 46): As text_clip_all, clipped at the top and bottom only.
; ----------------------------------------------------------------------------
cgfx_text_clip_vert:
	call	text_setup
	call	clip_text_vert
	jmp	L_1425

; ----------------------------------------------------------------------------
; clip_text_vert
; ----------------------------------------------------------------------------
clip_text_vert:
	mov	cx, word ptr [bp+8]
	or	cx, cx
	js	L_141E
	mov	ax, word ptr ds:[59Dh]
	or	ax, ax
	jns	L_1409
	neg	ax
	sub	word ptr ds:[597h], ax
	jbe	L_141E
	mov	word ptr ds:[59Dh], 0
	mul	word ptr ds:[599h]
	add	word ptr ds:[58Eh], ax
L_1409:
	mov	ax, word ptr ds:[59Dh]
	cmp	ax, cx
	ja	L_141E
	add	ax, word ptr ds:[597h]
	dec	ax
	sub	ax, cx
	jbe	L_141D
	sub	word ptr ds:[597h], ax
L_141D:
	ret
L_141E:
	pop	ax
	jmp	L_143A

; ----------------------------------------------------------------------------
; cgfx_text_noclip (slot 44): As text_clip_all, without clipping.
; ----------------------------------------------------------------------------
cgfx_text_noclip:
	call	text_setup
L_1425:
	mov	ax, word ptr [bp+2]
	add	word ptr ds:[59Bh], ax
	mov	ax, word ptr [bp+4]
	add	word ptr ds:[59Dh], ax
	mov	si, bx
	call	far ptr draw_glyphs
L_143A:
	mov	bx, word ptr ds:[593h]
	or	bx, bx
	je	L_1448
	mov	al, byte ptr ds:[595h]
	mov	byte ptr ss:[bx], al
L_1448:
	mov	ax, word ptr ds:[59Bh]
	sub	ax, word ptr [bp+2]
	pop	es
	pop	ds
	retf

; ----------------------------------------------------------------------------
; text_setup
; ----------------------------------------------------------------------------
text_setup:
	pop	si
	push	ds
	push	es
	mov	ax, DATA
	mov	ds, ax
	mov	es, word ptr [bp]
	mov	word ptr text_x, cx
	mov	word ptr text_y, dx
	xor	ax, ax
	mov	word ptr cut_ptr, ax
	mov	byte ptr glyph_skip, al
	mov	byte ptr cut_skip, al
	cmp	byte ptr ss:[bx], al
	je	L_143A
	mov	di, word ptr [bp+10h]
	cmp	di, word ptr w_D4720
	ja	L_143A
	shl	di, 1
	je	L_143A
	mov	di, word ptr [di+w_D4720]
	add	di, 4720h
	mov	word ptr glyph_data, di
	mov	al, byte ptr [di-4]
	test	byte ptr [bp+0Ah], 1
	je	L_1499
	add	al, byte ptr [di-2]
L_1499:
	cbw
	mov	word ptr text_rows, ax
	mov	ah, byte ptr [di-3]
	mov	byte ptr font_spacing, ah
	mov	al, byte ptr [di-5]
	or	al, al
	je	L_14AD
	add	al, ah
L_14AD:
	mov	byte ptr font_fixed_width, al
	mov	ah, byte ptr [di-8]
	mov	byte ptr font_first, ah
	mov	al, byte ptr [di-7]
	sub	al, ah
	xor	ah, ah
	mov	cl, byte ptr [di-6]
	dec	cl
	mov	byte ptr glyph_shift, cl
	add	di, -9
	sub	di, ax
	mov	word ptr width_table, di
	inc	ax
	shl	ax, cl
	mov	word ptr glyph_bytes, ax
	jmp	si
L_14D8:
	and	al, 7Fh
	mov	byte ptr ds:[5A0h], al
L_14DD:
	lea	bx, ds:[210h]
	xlat
	lea	bx, ds:[20Ch]
	xlat
	mov	byte ptr ds:[5A1h], al
	jmp	L_1567
L_14ED:
	mov	ax, word ptr ds:[59Bh]
	sub	ax, word ptr cs:w_009A
	mov	word ptr cs:w_009E, ax
	call	sub_00C5
	pop	bp
	mov	al, byte ptr ds:[5A0h]
	mov	byte ptr [bp+0Ch], al
	retf
L_1504:
	jmp	L_14D8
L_1506:
	jmp	L_14ED

; ----------------------------------------------------------------------------
; draw_glyphs
; ----------------------------------------------------------------------------
draw_glyphs:
	mov	al, byte ptr [bp+0Ch]
	mov	byte ptr ds:[5A0h], al
	mov	al, byte ptr [bp+0Eh]
	lea	bx, ds:[210h]
	xlat
	lea	bx, ds:[20Ch]
	xlat
	mov	byte ptr ds:[5A2h], al
	mov	al, byte ptr [bp+0Ah]
	mov	byte ptr ds:[5A7h], al
	cmp	al, 3
	je	L_1532
	cmp	al, 2
	jne	L_153C
	cmp	di, 0F0h
	ja	L_153C
L_1532:
	mov	byte ptr ds:[5A7h], 1
	mov	byte ptr ds:[5A0h], 0
L_153C:
	mov	al, byte ptr ds:[597h]
	xor	ah, ah
	mov	word ptr cs:w_00A0, ax
	mov	ax, word ptr ds:[59Bh]
	mov	word ptr cs:w_009A, ax
	mov	ax, word ptr ds:[59Dh]
	mov	word ptr cs:w_009C, ax
	push	bp
	mov	bp, word ptr ds:[599h]
	mov	bx, es
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	mov	al, byte ptr ds:[5A0h]
	jmp	L_14DD
L_1567:
	mov	ax, word ptr ss:[si]
	inc	si
	or	al, al
	js	L_1504
	je	L_1506
	push	si
	sub	al, byte ptr ds:[58Ch]
	mov	si, ax
	and	si, 0FFh
	mov	cl, byte ptr ds:[591h]
	or	cl, cl
	jne	L_158E
	mov	bx, word ptr ds:[58Ah]
	mov	cl, byte ptr [bx+si]
	add	cl, byte ptr ds:[58Dh]
L_158E:
	or	ah, ah
	jne	L_1596
	sub	cl, byte ptr ds:[596h]
L_1596:
	sub	cl, byte ptr ds:[592h]
	mov	byte ptr ds:[5A3h], cl
	mov	cl, byte ptr ds:[590h]
	shl	si, cl
	add	si, word ptr ds:[58Eh]
	mov	ax, word ptr ds:[59Bh]
	mov	bx, ax
	shr	ax, 1
	shr	ax, 1
	mov	word ptr ds:[5ABh], ax
	and	bx, 3
	mov	al, byte ptr [bx+208h]
	mov	byte ptr ds:[5A4h], al
	shl	bx, 1
	mov	byte ptr ds:[5AAh], bl
	mov	al, byte ptr ds:[5A3h]
	mov	cl, byte ptr ds:[592h]
	mov	ch, byte ptr ds:[597h]
	mov	dl, byte ptr ds:[5A1h]
	mov	dh, byte ptr ds:[5A2h]
	mov	di, word ptr ds:[59Dh]
	shl	di, 1
	cmp	byte ptr ds:[5A7h], 1
	je	L_1631
L_15E4:
	push	di
	mov	di, word ptr [di+row_offset]
	add	di, word ptr ds:[5ABh]
	mov	bx, word ptr [si]
	xchg	bh, bl
	shl	bx, cl
	mov	ah, byte ptr ds:[5A3h]
	mov	dh, byte ptr ds:[5A4h]
L_15FB:
	shl	bx, 1
	jae	L_160B
	mov	al, byte ptr es:[di]
	xor	al, dl
	and	al, dh
	xor	al, dl
	mov	byte ptr es:[di], al
L_160B:
	ror	dh, 1
	ror	dh, 1
	jb	L_1612
	inc	di
L_1612:
	dec	ah
	jne	L_15FB
	pop	di
	add	di, 2
	add	si, bp
	dec	ch
	jne	L_15E4
L_1620:
	pop	si
	xor	ah, ah
	mov	byte ptr ds:[592h], ah
	mov	al, byte ptr ds:[5A3h]
	add	word ptr ds:[59Bh], ax
	jmp	L_1567
L_1631:
	cmp	al, 4
	ja	L_1639
	or	cl, cl
	je	L_1682
L_1639:
	push	di
	mov	di, word ptr [di+row_offset]
	add	di, word ptr ds:[5ABh]
	mov	bx, word ptr [si]
	xchg	bh, bl
	mov	cl, byte ptr ds:[592h]
	shl	bx, cl
	mov	ah, byte ptr ds:[5A3h]
	mov	cl, byte ptr ds:[5A4h]
L_1654:
	mov	al, byte ptr es:[di]
	shl	bx, 1
	jb	L_1664
	xor	al, dh
	and	al, cl
	xor	al, dh
	jmp	L_166A
L_1664:
	xor	al, dl
	and	al, cl
	xor	al, dl
L_166A:
	stosb
	ror	cl, 1
	ror	cl, 1
	jae	L_1672
	dec	di
L_1672:
	dec	ah
	jne	L_1654
	pop	di
	add	di, 2
	add	si, bp
	dec	ch
	jne	L_1639
	jmp	L_1620
L_1682:
	mov	cl, byte ptr ds:[5AAh]
	cmp	al, 4
	jne	L_168E
	or	cl, cl
	je	L_16E5
L_168E:
	xchg	cl, al
	shl	cl, 1
	dec	cl
	mov	bx, 8000h
	sar	bx, cl
	xchg	bh, bl
	not	bx
	mov	cl, al
	ror	bx, cl
	mov	word ptr ds:[5A5h], bx
	dec	bp
L_16A6:
	push	di
	mov	di, word ptr [di+row_offset]
	add	di, word ptr ds:[5ABh]
	lodsb
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	lea	bx, ds:[5ADh]
	xlat
	mov	bl, al
	not	bl
	and	bl, dl
	and	al, dh
	or	bl, al
	xor	bh, bh
	ror	bx, cl
	mov	ax, word ptr es:[di]
	xor	ax, bx
	and	ax, word ptr ds:[5A5h]
	xor	ax, bx
	stosw
	pop	di
	add	di, 2
	add	si, bp
	dec	ch
	jne	L_16A6
	inc	bp
	jmp	L_1620
L_16E5:
	or	dl, dl
	je	L_1722
	mov	ah, dh
	mov	cl, dl
	lea	dx, ds:[50h]
	add	dx, di
	dec	bp
L_16F4:
	mov	di, dx
	mov	di, word ptr [di]
	add	di, word ptr ds:[5ABh]
	lodsb
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	lea	bx, ds:[5ADh]
	xlat
	mov	bh, al
	not	bh
	and	bh, cl
	and	al, ah
	or	al, bh
	stosb
	add	dx, 2
	add	si, bp
	dec	ch
	jne	L_16F4
	inc	bp
	jmp	L_1620
L_1722:
	mov	ah, dh
	lea	bx, ds:[5ADh]
	lea	dx, ds:[50h]
	add	dx, di
	dec	bp
L_172F:
	mov	di, dx
	mov	di, word ptr [di]
	add	di, word ptr ds:[5ABh]
	lodsb
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	xlat
	and	al, ah
	stosb
	add	dx, 2
	add	si, bp
	dec	ch
	jne	L_172F
	inc	bp
	jmp	L_1620
	db	0,0Ch,4,0Ch,0Eh
shake_seed	dw	4D2h
shake_count	db	0

; ----------------------------------------------------------------------------
; cgfx_set_shake (slot 28): set_shake(n): shake the screen for the next n calls of shake_tick.
; ----------------------------------------------------------------------------
cgfx_set_shake:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	mov	byte ptr cs:shake_count, al
	retf

; ----------------------------------------------------------------------------
; cgfx_shake_tick (slot 50): shake_tick(): while shaking, move the display start at random.
; ----------------------------------------------------------------------------
cgfx_shake_tick:
	mov	ax, word ptr cs:shake_seed
	shl	ax, 1
	shl	ax, 1
	add	ax, word ptr cs:shake_seed
	inc	ax
	mov	word ptr cs:shake_seed, ax
	cmp	byte ptr cs:shake_count, 0
	je	L_178F
	and	ah, 3
	dec	byte ptr cs:shake_count
	jne	L_1789
	xor	ah, ah
L_1789:
	mov	dx, 3D4h
	mov	al, 0Dh
	out	dx, ax
L_178F:
	retf

; ----------------------------------------------------------------------------
; cgfx_get_pixel (slot 12): get_pixel(page, x, y): colour of a pixel.
; ----------------------------------------------------------------------------
cgfx_get_pixel:
	mov	bx, sp
	mov	cx, word ptr [bx+6]
	mov	dx, word ptr [bx+8]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	cmp	bx, 0Eh
	je	L_17CB
	mov	bx, dx
	shl	bx, 1
	mov	bx, word ptr cs:[bx+row_offset]
	mov	ax, cx
	shr	ax, 1
	shr	ax, 1
	add	bx, ax
	and	cl, 3
	neg	cl
	add	cl, 3
	shl	cl, 1
	mov	al, byte ptr es:[bx]
	shr	al, cl
	and	ax, 3
	retf
L_17CB:
	mov	bh, dl
	mov	bl, cl
	add	bx, 4000h
	mov	al, byte ptr es:[bx]
	xor	ah, ah
	retf

; ----------------------------------------------------------------------------
; cgfx_get_row (slot 11): get_row(buf, page, y, x, n): copy n pixels of a row to DS:buf.
; ----------------------------------------------------------------------------
cgfx_get_row:
	mov	bx, sp
	push	si
	push	di
	push	ds
	mov	di, word ptr [bx+4]
	mov	ax, ds
	mov	es, ax
	mov	si, word ptr [bx+8]
	mov	ax, word ptr [bx+0Ah]
	mov	cx, word ptr [bx+0Ch]
	mov	bx, word ptr [bx+6]
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
	cmp	bx, 0Eh
	je	L_1836
	shl	si, 1
	mov	si, word ptr cs:[si+row_offset]
	shr	ax, 1
	shr	ax, 1
	add	si, ax
	add	cx, 3
	shr	cx, 1
	shr	cx, 1
L_1811:
	lodsb
	mov	ah, al
	rol	ax, 1
	rol	ax, 1
	and	al, 3
	stosb
	rol	ax, 1
	rol	ax, 1
	and	al, 3
	stosb
	rol	ax, 1
	rol	ax, 1
	and	al, 3
	stosb
	rol	ax, 1
	rol	ax, 1
	and	al, 3
	stosb
	loop	L_1811
L_1832:
	pop	ds
	pop	di
	pop	si
	retf
L_1836:
	mov	bx, si
	mov	bh, bl
	mov	bl, al
	add	bx, 4000h
	mov	si, bx
	rep	movsb
	jmp	L_1832

; ----------------------------------------------------------------------------
; cgfx_put_row (slot 18): put_row(buf, page, y, x, n): copy n pixels from DS:buf to a row.
; ----------------------------------------------------------------------------
cgfx_put_row:
	mov	bx, sp
	push	si
	push	di
	mov	si, word ptr [bx+4]
	mov	dx, word ptr [bx+8]
	mov	ax, word ptr [bx+0Ah]
	mov	cx, word ptr [bx+0Ch]
	mov	bx, word ptr [bx+6]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	cmp	bx, 0Eh
	jne	L_1882
	cmp	dx, 0C0h
	jae	L_1882
	mov	bh, dl
	mov	bl, 0
	add	bx, 4000h
	mov	di, bx
	add	di, ax
	mov	bx, cx
	mov	cx, 100h
	push	si
	rep	movsb
	pop	si
	mov	cx, bx
L_1882:
	mov	di, dx
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	shr	ax, 1
	shr	ax, 1
	add	di, ax
	add	cx, 3
	shr	cx, 1
	shr	cx, 1
	mov	bx, 1E90h
	test	dx, 1
	je	L_18A5
	add	bx, 80h
L_18A5:
	cmp	byte ptr cs:b_D0510, 0
	jne	L_191B
	shr	cx, 1
L_18AF:
	lodsw
	xlat	byte ptr cs:[bx]
	mov	dl, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dl, 1
	shl	dl, 1
	or	dl, al
	shl	dl, 1
	shl	dl, 1
	lodsw
	xlat	byte ptr cs:[bx]
	or	dl, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dl, 1
	shl	dl, 1
	or	dl, al
	lodsw
	xlat	byte ptr cs:[bx]
	mov	dh, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dh, 1
	shl	dh, 1
	or	dh, al
	shl	dh, 1
	shl	dh, 1
	lodsw
	xlat	byte ptr cs:[bx]
	or	dh, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dh, 1
	shl	dh, 1
	or	dh, al
	mov	ax, dx
	stosw
	loop	L_18AF
	pop	di
	pop	si
	retf
L_191B:
	sub	dh, dh
	lodsw
	or	al, al
	je	L_1925
	or	dh, 0C0h
L_1925:
	or	ah, ah
	je	L_192C
	or	dh, 30h
L_192C:
	xlat	byte ptr cs:[bx]
	mov	dl, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dl, 1
	shl	dl, 1
	or	dl, al
	shl	dl, 1
	shl	dl, 1
	lodsw
	or	al, al
	je	L_194E
	or	dh, 0Ch
L_194E:
	or	ah, ah
	je	L_1955
	or	dh, 3
L_1955:
	xlat	byte ptr cs:[bx]
	or	dl, al
	mov	al, ah
	add	bx, 80h
	xlat	byte ptr cs:[bx]
	sub	bx, 80h
	shl	dl, 1
	shl	dl, 1
	or	al, dl
	mov	byte ptr cs:[di+w_D07D4], dh
	stosb
	loop	L_191B
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; cgfx_hide_pointer (slot 14): hide_pointer(): restore the background under the mouse pointer.
; ----------------------------------------------------------------------------
cgfx_hide_pointer:
	call	restore_ptr_bg
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	word ptr ptr_visible, 0
	pop	ds
	retf

; ----------------------------------------------------------------------------
; restore_ptr_bg
; ----------------------------------------------------------------------------
restore_ptr_bg:
	push	si
	push	di
	push	ds
	push	es
	mov	ax, DATA
	mov	ds, ax
	cmp	word ptr ptr_visible, 0
	je	L_19BF
	lea	si, ptr_save
	mov	es, word ptr cs:page_seg
	mov	ax, word ptr ptr_clip_w
	mov	bx, word ptr ptr_clip_h
	shl	bx, 1
	mov	dx, word ptr w_D05CE
L_19AD:
	mov	cx, ax
	mov	di, word ptr [bx+row_offset]
	add	di, word ptr ptr_clip_x
	rep	movsb
	add	bx, 2
	dec	dx
	jne	L_19AD
L_19BF:
	pop	es
	pop	ds
	pop	di
	pop	si
	ret

; ----------------------------------------------------------------------------
; cgfx_show_pointer (slot 29): show_pointer(x, y, image): save the screen under the mouse pointer and draw it.
; ----------------------------------------------------------------------------
cgfx_show_pointer:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	ax, word ptr [bp+0Ah]
	mov	word ptr ptr_image, ax
	mov	es, ax
	mov	ax, word ptr [bp+6]
	mov	word ptr ptr_x, ax
	mov	bx, word ptr es:[0]
	mov	word ptr ptr_width, bx
	or	bx, bx
	je	L_1A29
	or	ax, ax
	jns	L_19F4
	neg	ax
	sub	bx, ax
	jbe	L_1A29
	xor	ax, ax
L_19F4:
	mov	cx, 50h
	shl	cx, 1
	shl	cx, 1
	sub	cx, ax
	jbe	L_1A29
	cmp	bx, cx
	jbe	L_1A05
	mov	bx, cx
L_1A05:
	mov	cx, ax
	and	cx, 3
	add	bx, cx
	add	bx, 3
	shr	bx, 1
	shr	bx, 1
	mov	word ptr ptr_clip_w, bx
	shr	ax, 1
	shr	ax, 1
	mov	word ptr ptr_clip_x, ax
	mov	ax, 200h
	cwd
	div	bx
	mov	dx, ax
	jmp	L_1A32
L_1A29:
	mov	word ptr ptr_visible, 0
	jmp	L_1A77
L_1A32:
	mov	ax, word ptr [bp+8]
	mov	word ptr ptr_y, ax
	mov	bx, word ptr es:[2]
	mov	word ptr ptr_height, bx
	or	bx, bx
	je	L_1A29
	or	ax, ax
	jns	L_1A51
	neg	ax
	sub	bx, ax
	jbe	L_1A29
	xor	ax, ax
L_1A51:
	mov	cx, 0C8h
	sub	cx, ax
	jbe	L_1A29
	cmp	bx, cx
	jbe	L_1A5E
	mov	bx, cx
L_1A5E:
	cmp	bx, dx
	jbe	L_1A64
	mov	bx, dx
L_1A64:
	mov	word ptr w_D05CE, bx
	mov	word ptr ptr_clip_h, ax
	mov	word ptr ptr_visible, 1
	mov	ax, 0
	call	save_ptr_bg
L_1A77:
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; save_ptr_bg
; ----------------------------------------------------------------------------
save_ptr_bg:
	push	ds
	push	si
	push	di
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	word ptr ptr_page, ax
	cmp	word ptr ptr_visible, 0
	je	L_1AF1
	mov	bx, ax
	shl	bx, 1
	mov	cx, word ptr cs:[bx+page_seg]
	lea	di, ptr_save
	mov	es, dx
	mov	ax, word ptr ptr_clip_w
	mov	bx, word ptr ptr_clip_h
	shl	bx, 1
	mov	dx, word ptr w_D05CE
	mov	ds, cx
L_1AAB:
	mov	si, word ptr cs:[bx+row_offset]
	add	si, word ptr es:ptr_clip_x
	mov	cx, ax
	rep	movsb
	add	bx, 2
	dec	dx
	jne	L_1AAB
	mov	dx, DATA
	mov	ds, dx
	mov	dx, 0C8h
	dec	dx
	push	dx
	mov	dx, 50h
	shl	dx, 1
	shl	dx, 1
	dec	dx
	push	dx
	xor	dx, dx
	push	dx
	push	dx
	push	word ptr ptr_page
	mov	cx, sp
	push	word ptr ptr_image
	push	word ptr ptr_y
	push	word ptr ptr_x
	push	cx
	call	far ptr cgfx_draw_image
	add	sp, 12h
L_1AF1:
	pop	es
	pop	di
	pop	si
	pop	ds
	ret
CODE	ENDS

BSS	SEGMENT BYTE PUBLIC 'BSS'
	db	16204 dup (?)
BSS	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

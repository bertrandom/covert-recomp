; TGRAPHIC.EXE - Covert Action graphics driver for Tandy 1000 / PCjr (320x200, 16 colours)
;
; Same interface as MGRAPHIC (51 entry points, see MGRAPHIC.ASM and README
; "Driver interface"); the screen is the Tandy 16-colour mode at B800h, two
; pixels per byte and rows interleaved over four 2000h banks. With flag 2,
; init_mode checks the machine (int 15h AH=C0h) for the wider Tandy mode. Routine and variable names come from
; MGRAPHIC by aligning each export with MGRAPHIC's routine for the same slot
; ("inherit"); the descriptions are those of tools/drivers/gfx_slots.txt.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh TGRAPHIC
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/TGRAPHIC.hints)

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:1C10h = DATA:0) while DS references, with DS = DATA,
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
ptr_image	dw	0
ptr_x	dw	0
ptr_y	dw	0
ptr_width	dw	0
ptr_height	dw	0
ptr_clip_x	dw	0
ptr_clip_h	dw	0
ptr_clip_w	dw	0
w_D0060	dw	0
ptr_visible	dw	0
ptr_page	dw	0
ptr_save	dw	256 dup (0)
caps_table	dw	1,1,1
w_D026C	dw	0
w_D026E	dw	0
row_offset	db	0,0,0,20h,0,40h,0,60h,0A0h,0,0A0h,20h,0A0h,40h,0A0h,60h
	db	40h,1,40h,21h,40h,41h,40h,61h,0E0h,1,0E0h,21h,0E0h,41h,0E0h,61h
	db	80h,2,80h,22h,80h,42h,80h,62h,20h,3,20h,23h,20h,43h,20h,63h
	db	0C0h,3,0C0h,23h,0C0h,43h,0C0h,63h,60h,4,60h,24h,60h,44h,60h,64h
	db	0,5,0,25h,0,45h,0,65h,0A0h,5,0A0h,25h,0A0h,45h,0A0h,65h
	db	40h,6,40h,26h,40h,46h,40h,66h,0E0h,6,0E0h,26h,0E0h,46h,0E0h,66h
	db	80h,7,80h,27h,80h,47h,80h,67h,20h,8,20h,28h,20h,48h,20h,68h
	db	0C0h,8,0C0h,28h,0C0h,48h,0C0h,68h,60h,9,60h,29h,60h,49h,60h,69h
	db	0,0Ah,0,2Ah,0,4Ah,0,6Ah,0A0h,0Ah,0A0h,2Ah,0A0h,4Ah,0A0h,6Ah
	db	40h,0Bh,40h,2Bh,40h,4Bh,40h,6Bh,0E0h,0Bh,0E0h,2Bh,0E0h,4Bh,0E0h,6Bh
	db	80h,0Ch,80h,2Ch,80h,4Ch,80h,6Ch,20h,0Dh,20h,2Dh,20h,4Dh,20h,6Dh
	db	0C0h,0Dh,0C0h,2Dh,0C0h,4Dh,0C0h,6Dh,60h,0Eh,60h,2Eh,60h,4Eh,60h,6Eh
	db	0,0Fh,0,2Fh,0,4Fh,0,6Fh,0A0h,0Fh,0A0h,2Fh,0A0h,4Fh,0A0h,6Fh
	db	40h,10h,40h,30h,40h,50h,40h,70h,0E0h,10h,0E0h,30h,0E0h,50h,0E0h,70h
	db	80h,11h,80h,31h,80h,51h,80h,71h,20h,12h,20h,32h,20h,52h,20h,72h
	db	0C0h,12h,0C0h,32h,0C0h,52h,0C0h,72h,60h,13h,60h,33h,60h,53h,60h,73h
	db	0,14h,0,34h,0,54h,0,74h,0A0h,14h,0A0h,34h,0A0h,54h,0A0h,74h
	db	40h,15h,40h,35h,40h,55h,40h,75h,0E0h,15h,0E0h,35h,0E0h,55h,0E0h,75h
	db	80h,16h,80h,36h,80h,56h,80h,76h,20h,17h,20h,37h,20h,57h,20h,77h
	db	0C0h,17h,0C0h,37h,0C0h,57h,0C0h,77h,60h,18h,60h,38h,60h,58h,60h,78h
	db	0,19h,0,39h,0,59h,0,79h,0A0h,19h,0A0h,39h,0A0h,59h,0A0h,79h
	db	40h,1Ah,40h,3Ah,40h,5Ah,40h,7Ah,0E0h,1Ah,0E0h,3Ah,0E0h,5Ah,0E0h,7Ah
	db	80h,1Bh,80h,3Bh,80h,5Bh,80h,7Bh,20h,1Ch,20h,3Ch,20h,5Ch,20h,7Ch
	db	0C0h,1Ch,0C0h,3Ch,0C0h,5Ch,0C0h,7Ch,60h,1Dh,60h,3Dh,60h,5Dh,60h,7Dh
	db	0,1Eh,0,3Eh,0,5Eh,0,7Eh,0A0h,1Eh,0A0h,3Eh,0A0h,5Eh,0A0h,7Eh
page_seg	dw	8 dup (0B800h)
draw_seg	dw	0
draw_x0	dw	0
draw_y0	dw	0
draw_xmax	dw	13Fh
w_D0418	dw	0A0h
w_D041A	dw	800h
w_D041C	dw	0
w_D041E	dw	0
draw_color	db	0Fh
draw_mode	db	0
draw_opcode	db	0,0
	db	'Out of memory$'
	db	'TNDY is not supported on your machine$'
line_y0	dw	0
w_D045A	dw	32h
line_x1	dw	64h
line_y1	dw	0
w_D0460	dw	0
w_D0462	dw	0,2000h,3008h,0,0,0
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
text_y	db	0,0,0
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'TGRAPHIC.EXE02-20-89'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	490h		; bytes from DATA to the stack
drv_first_slot	db	0
	db	0
drv_count	dw	51		; number of exports
drv_exports	label	word
	dw	offset tgfx_alloc_page	; slot 0
	dw	offset tgfx_mem_avail	; slot 1
	dw	offset tgfx_get_image	; slot 2
	dw	offset tgfx_recolor_rect	; slot 3
	dw	offset tgfx_char_width	; slot 4
	dw	offset tgfx_clear_page	; slot 5
	dw	offset tgfx_draw_image	; slot 6
	dw	offset tgfx_end_image_grab	; slot 7
	dw	offset tgfx_free_page	; slot 8
	dw	offset tgfx_dissolve_page	; slot 9
	dw	offset tgfx_font_height	; slot 10
	dw	offset tgfx_get_row	; slot 11
	dw	offset tgfx_get_pixel	; slot 12
	dw	offset tgfx_nop13	; slot 13
	dw	offset tgfx_hide_pointer	; slot 14
	dw	offset tgfx_patch_font	; slot 15
	dw	offset tgfx_has_back_buffer	; slot 16
	dw	offset tgfx_begin_image_grab	; slot 17
	dw	offset tgfx_put_row	; slot 18
	dw	offset tgfx_copy_rect	; slot 19
	dw	offset tgfx_draw_text	; slot 20
	dw	offset tgfx_draw_image_scaled	; slot 21
	dw	offset tgfx_screen_off	; slot 22
	dw	offset tgfx_screen_on	; slot 23
	dw	offset tgfx_set_page	; slot 24
	dw	offset tgfx_set_color	; slot 25
	dw	offset tgfx_set_palette	; slot 26
	dw	offset tgfx_set_color_map	; slot 27
	dw	offset tgfx_set_shake	; slot 28
	dw	offset tgfx_show_pointer	; slot 29
	dw	offset tgfx_show_page	; slot 30
	dw	offset tgfx_draw_image_noclip	; slot 31
	dw	offset tgfx_end_image	; slot 32
	dw	offset tgfx_image_add_row	; slot 33
	dw	offset tgfx_begin_image	; slot 34
	dw	offset tgfx_swap_page	; slot 35
	dw	offset tgfx_init_mode	; slot 36
	dw	offset tgfx_put_pixel	; slot 37
	dw	offset tgfx_fill_spans	; slot 38
	dw	offset tgfx_nop39	; slot 39
	dw	offset tgfx_set_draw_color	; slot 40
	dw	offset tgfx_draw_line	; slot 41
	dw	offset tgfx_text_clip_all	; slot 42
	dw	offset tgfx_text_clip_left	; slot 43
	dw	offset tgfx_text_noclip	; slot 44
	dw	offset tgfx_text_clip_right	; slot 45
	dw	offset tgfx_text_clip_vert	; slot 46
	dw	offset tgfx_select_page	; slot 47
	dw	offset tgfx_set_port	; slot 48
	dw	offset tgfx_copy_rows_to_screen	; slot 49
	dw	offset tgfx_shake_tick	; slot 50
w_0098	dw	0
w_009A	dw	0

; ----------------------------------------------------------------------------
; tgfx_recolor_rect (slot 3): recolor_rect(port, x, y, w, h, from, to): within the rectangle, replace colour 'from' by 'to'.
; ----------------------------------------------------------------------------
tgfx_recolor_rect:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bp+6]
	mov	cl, 4
	mov	dh, byte ptr [bp+10h]
	and	dh, 0Fh
	mov	al, dh
	shl	al, cl
	or	dh, al
	mov	dl, byte ptr [bp+12h]
	and	dl, 0Fh
	mov	al, dl
	shl	al, cl
	or	dl, al
	mov	bx, word ptr [bp+0Ch]
	mov	cx, word ptr [bp+0Eh]
	mov	di, word ptr [bp+8]
	add	di, word ptr [si+2]
	mov	bp, word ptr [bp+0Ah]
	add	bp, word ptr [si+4]
	shl	bp, 1
	cmp	word ptr cs:w_D026C, 0
	je	L_00E0
	shl	bx, 1
	shl	di, 1
L_00E0:
	mov	ax, word ptr [si]
	call	sub_05FF
	mov	ax, es
	mov	ds, ax
	shr	di, 1
	mov	word ptr cs:w_009A, di
	jae	L_00F3
	dec	bx
L_00F3:
	mov	si, bx
	rcr	bh, 1
	shr	si, 1
	rcr	bh, 1
	mov	word ptr cs:w_0098, si
	mov	bl, cl
L_0102:
	mov	si, word ptr cs:[bp+1E80h]
	add	si, word ptr cs:w_009A
	mov	di, si
	mov	cx, word ptr cs:w_0098
	test	bh, 40h
	je	L_012B
	lodsb
	mov	ah, al
	xor	ah, dh
	test	ah, 0Fh
	jne	L_0129
	xor	al, dl
	and	al, 0F0h
	xor	al, dl
	stosb
L_0129:
	mov	di, si
L_012B:
	jcxz	L_014B
	lodsb
	mov	ah, al
	xor	ah, dh
	test	ah, 0F0h
	jne	L_013D
	xor	al, dl
	and	al, 0Fh
	xor	al, dl
L_013D:
	test	ah, 0Fh
	jne	L_0148
	xor	al, dl
	and	al, 0F0h
	xor	al, dl
L_0148:
	stosb
	loop	L_012B
L_014B:
	test	bh, 80h
	je	L_0161
	lodsb
	mov	ah, al
	xor	ah, dh
	test	ah, 0F0h
	jne	L_0161
	xor	al, dl
	and	al, 0Fh
	xor	al, dl
	stosb
L_0161:
	add	bp, 2
	dec	bl
	jne	L_0102
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_set_color (slot 25): set_color(index, colour): set one palette entry.
; ----------------------------------------------------------------------------
tgfx_set_color:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	mov	ah, byte ptr [bx+6]
	mov	bx, ax
	mov	ax, 1000h
	int	10h
	retf

; ----------------------------------------------------------------------------
; tgfx_set_palette (slot 26): set_palette(pal): set the 16-colour palette (17 bytes, the last is the border).
; ----------------------------------------------------------------------------
tgfx_set_palette:
	mov	bx, sp
	mov	ax, 1002h
	mov	dx, ds
	mov	es, dx
	mov	dx, word ptr [bx+4]
	int	10h
	call	far ptr tgfx_screen_on
	retf

; ----------------------------------------------------------------------------
; tgfx_set_color_map (slot 27): set_color_map(...): colour mapping for the dithered modes.
; ----------------------------------------------------------------------------
tgfx_set_color_map:
	retf
	db	88h,20h,8,30h

; ----------------------------------------------------------------------------
; tgfx_set_draw_color (slot 40): AL = colour, AH = mode (0 copy, 1 and, 2 or, 3 xor) for the primitives.
; ----------------------------------------------------------------------------
tgfx_set_draw_color:
	mov	byte ptr cs:draw_color, al
	mov	al, ah
	and	al, 3
	mov	byte ptr cs:draw_mode, al
	lea	bx, ds:[193h]
	xlat	byte ptr cs:[bx]
	mov	byte ptr cs:draw_opcode, al
	retf

; ----------------------------------------------------------------------------
; tgfx_nop39 (slot 39): Slot 39.
; ----------------------------------------------------------------------------
tgfx_nop39:
	retf
	db	0

; ----------------------------------------------------------------------------
; tgfx_get_pixel (slot 12): get_pixel(page, x, y): colour of a pixel.
; ----------------------------------------------------------------------------
tgfx_get_pixel:
	mov	bx, sp
	mov	cx, word ptr [bx+6]
	mov	dx, word ptr [bx+8]
	mov	ax, word ptr [bx+4]
	call	sub_05FF
	mov	bx, dx
	shl	bx, 1
	mov	bx, word ptr cs:[bx+row_offset]
	mov	ax, cx
	shr	ax, 1
	add	bx, ax
	mov	al, byte ptr es:[bx]
	shr	cx, 1
	jb	L_01DC
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
L_01DC:
	and	ax, 0Fh
	retf

; ----------------------------------------------------------------------------
; tgfx_get_row (slot 11): get_row(buf, page, y, x, n): copy n pixels of a row to DS:buf.
; ----------------------------------------------------------------------------
tgfx_get_row:
	mov	bx, sp
	push	si
	push	di
	push	ds
	mov	di, word ptr [bx+4]
	mov	si, word ptr [bx+8]
	shl	si, 1
	mov	si, word ptr cs:[si+row_offset]
	mov	ax, word ptr [bx+0Ah]
	shr	ax, 1
	add	si, ax
	mov	cx, word ptr [bx+0Ch]
	inc	cx
	shr	cx, 1
	mov	ax, word ptr [bx+6]
	call	sub_05FF
	push	ds
	push	es
	pop	ds
	pop	es
L_0209:
	lodsb
	mov	ah, al
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	and	ax, 0F0Fh
	stosw
	loop	L_0209
	pop	ds
	pop	di
	pop	si
	retf
	db	0,0,11h,11h,22h,22h,33h,33h,44h,44h,55h,55h,66h,66h,77h,77h
	db	88h,88h,99h,99h,0AAh,0AAh,0BBh,0BBh,0CCh,0CCh,0DDh,0DDh,0EEh,0EEh,0FFh,0FFh
	db	0,0,8,80h,88h,88h,0Fh,0F0h,77h,77h,7Fh,0F7h
	db	20 dup (0FFh)
	db	4,40h,0Ch,0C0h,47h,74h,44h,44h,46h,64h,4Ch,0C4h,6Ch,0C6h,4Fh,0F4h
	db	0CCh,0CCh,0CFh,0FCh
	db	12 dup (0FFh)
	db	6,60h,68h,86h,67h,76h,66h,66h,4Eh,0E4h,6Fh,0F6h,0CEh,0ECh,0FFh,0FFh
	db	24h,42h,0Eh,0E0h,26h,62h,8Eh,0E8h,7Eh,0E7h,6Eh,0E6h,0EFh,0FEh,0EEh,0EEh
	db	2,20h,36h,63h,0Ah,0A0h,6Bh,0B6h,27h,72h,6Ah,0A6h,22h,22h,23h,32h
	db	2Fh,0F2h,2Eh,0E2h,2Ah,0A2h,2Bh,0B2h,0AFh,0FAh,0AEh,0EAh,0AAh,0AAh,0ABh,0BAh
	db	3,30h,0Bh,0B0h,37h,73h,33h,33h,3Fh,0F3h,3Bh,0B3h,0BFh,0FBh,0BBh,0BBh
	db	16 dup (0FFh)
	db	1,10h,9,90h,17h,71h,13h,31h,11h,11h,15h,51h,19h,91h,1Bh,0B1h
	db	1Dh,0D1h,1Fh,0F1h,99h,99h,9Bh,0B9h,9Dh,0D9h,9Fh,0F9h,0FFh,0FFh,0FFh,0FFh
	db	16h,61h,5,50h,69h,96h,0Dh,0D0h,57h,75h,55h,55h,5Fh,0F5h,5Dh,0D5h
	db	0DDh,0DDh,0DFh,0FDh,0FFh,0FFh,56h,65h,45h,54h,6Dh,0D6h,4Dh,0D4h,0CDh,0DCh

; ----------------------------------------------------------------------------
; tgfx_put_row (slot 18): put_row(buf, page, y, x, n): copy n pixels from DS:buf to a row.
; ----------------------------------------------------------------------------
tgfx_put_row:
	mov	bx, sp
	push	si
	push	di
	mov	si, word ptr [bx+4]
	mov	di, word ptr [bx+8]
	mov	dx, di
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	mov	ax, word ptr [bx+0Ah]
	shr	ax, 1
	add	di, ax
	mov	cx, word ptr [bx+0Ch]
	mov	ax, word ptr [bx+6]
	call	sub_05FF
	cmp	word ptr cs:w_D026E, 1
	je	L_0360
	inc	cx
	shr	cx, 1
L_034C:
	lodsw
	and	ax, 0F0Fh
	shl	al, 1
	shl	al, 1
	shl	al, 1
	shl	al, 1
	or	al, ah
	stosb
	loop	L_034C
	pop	di
	pop	si
	retf
L_0360:
	cmp	word ptr cs:w_D026C, 0
	jne	L_038A
	shr	cx, 1
	mov	bx, 21Eh
	and	dx, 1
	add	bx, dx
L_0372:
	lodsb
	shl	al, 1
	xlat	byte ptr cs:[bx]
	and	al, 0F0h
	mov	dl, al
	lodsb
	shl	al, 1
	xlat	byte ptr cs:[bx]
	and	al, 0Fh
	or	al, dl
	stosb
	loop	L_0372
	pop	di
	pop	si
	retf
L_038A:
	mov	bx, 21Eh
	and	dx, 1
	add	bx, dx
L_0392:
	lodsb
	shl	al, 1
	xlat	byte ptr cs:[bx]
	stosb
	loop	L_0392
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; tgfx_hide_pointer (slot 14): hide_pointer(): restore the background under the mouse pointer.
; ----------------------------------------------------------------------------
tgfx_hide_pointer:
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
	je	L_03F0
	lea	si, ptr_save
	push	word ptr cs:w_D041E
	mov	ax, word ptr ptr_page
	call	sub_05FF
	mov	ax, word ptr ptr_clip_w
	mov	bx, word ptr ptr_clip_h
	shl	bx, 1
	mov	dx, word ptr w_D0060
L_03DA:
	mov	cx, ax
	mov	di, word ptr [bx+row_offset]
	add	di, word ptr ptr_clip_x
	rep	movsb
	add	bx, 2
	dec	dx
	jne	L_03DA
	pop	ax
	call	sub_05FF
L_03F0:
	pop	es
	pop	ds
	pop	di
	pop	si
	ret

; ----------------------------------------------------------------------------
; tgfx_show_pointer (slot 29): show_pointer(x, y, image): save the screen under the mouse pointer and draw it.
; ----------------------------------------------------------------------------
tgfx_show_pointer:
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
	je	L_0456
	or	ax, ax
	jns	L_0425
	neg	ax
	sub	bx, ax
	jbe	L_0456
	xor	ax, ax
L_0425:
	mov	cx, word ptr cs:w_D0418
	shl	cx, 1
	sub	cx, ax
	jbe	L_0456
	cmp	bx, cx
	jbe	L_0436
	mov	bx, cx
L_0436:
	mov	cx, ax
	and	cx, 1
	add	bx, cx
	add	bx, 1
	shr	bx, 1
	mov	word ptr ptr_clip_w, bx
	shr	ax, 1
	mov	word ptr ptr_clip_x, ax
	mov	ax, 200h
	cwd
	div	bx
	mov	dx, ax
	jmp	L_045F
L_0456:
	mov	word ptr ptr_visible, 0
	jmp	L_04A4
L_045F:
	mov	ax, word ptr [bp+8]
	mov	word ptr ptr_y, ax
	mov	bx, word ptr es:[2]
	mov	word ptr ptr_height, bx
	or	bx, bx
	je	L_0456
	or	ax, ax
	jns	L_047E
	neg	ax
	sub	bx, ax
	jbe	L_0456
	xor	ax, ax
L_047E:
	mov	cx, 0C8h
	sub	cx, ax
	jbe	L_0456
	cmp	bx, cx
	jbe	L_048B
	mov	bx, cx
L_048B:
	cmp	bx, dx
	jbe	L_0491
	mov	bx, dx
L_0491:
	mov	word ptr w_D0060, bx
	mov	word ptr ptr_clip_h, ax
	mov	word ptr ptr_visible, 1
	mov	ax, word ptr ptr_page
	call	save_ptr_bg
L_04A4:
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
	je	L_0523
	push	word ptr cs:w_D041E
	call	sub_05FF
	mov	cx, es
	lea	di, ptr_save
	mov	es, dx
	mov	ax, word ptr ptr_clip_w
	mov	bx, word ptr ptr_clip_h
	shl	bx, 1
	mov	dx, word ptr w_D0060
	mov	ds, cx
L_04D9:
	mov	si, word ptr cs:[bx+row_offset]
	add	si, word ptr es:[5Ah]
	mov	cx, ax
	rep	movsb
	add	bx, 2
	dec	dx
	jne	L_04D9
	mov	dx, DATA
	mov	ds, dx
	mov	dx, 0C8h
	dec	dx
	push	dx
	mov	dx, word ptr cs:w_D0418
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
	call	far ptr tgfx_draw_image
	add	sp, 12h
	pop	ax
	call	sub_05FF
L_0523:
	pop	es
	pop	di
	pop	si
	pop	ds
	ret

; ----------------------------------------------------------------------------
; tgfx_fill_spans (slot 38): AX = first row, CX = last row, BX = span table: fill each row's span.
; ----------------------------------------------------------------------------
tgfx_fill_spans:
	or	ax, ax
	jns	L_052F
	jmp	L_05C2
L_052F:
	push	es
	call	far ptr sub_05F5
	mov	si, ax
	shl	si, 1
	sub	cx, ax
	inc	cx
	mov	dl, cl
	mov	al, byte ptr cs:draw_color
	mov	cl, 4
	mov	ah, al
	shl	ah, cl
	or	al, ah
	mov	ah, al
	mov	bp, word ptr cs:w_D026C
L_0551:
	mov	di, word ptr [bx+si]
	mov	cx, word ptr [bx+si+1B8h]
	cmp	cx, di
	jb	L_05BA
	ja	L_0568
	or	cx, cx
	je	L_05BA
	cmp	cx, word ptr cs:draw_xmax
	je	L_05BA
L_0568:
	cmp	bp, 0
	je	L_0572
	shl	di, 1
	shl	cx, 1
	inc	cx
L_0572:
	sub	cx, di
	inc	cx
	shr	di, 1
	jae	L_057A
	dec	cx
L_057A:
	rcr	dh, 1
	shr	cx, 1
	rcr	dh, 1
	add	di, word ptr cs:[si+row_offset]
	test	dh, 40h
	je	L_0596
	mov	al, byte ptr es:[di]
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
	stosb
	mov	al, ah
L_0596:
	jcxz	L_05A9
	test	di, 1
	je	L_05A2
	stosb
	dec	cx
	je	L_05A9
L_05A2:
	shr	cx, 1
	rep	stosw
	jae	L_05A9
	stosb
L_05A9:
	test	dh, 80h
	je	L_05BA
	mov	al, byte ptr es:[di]
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
	mov	al, ah
L_05BA:
	add	si, 2
	dec	dl
	jne	L_0551
	pop	es
L_05C2:
	retf
	db	0
w_05C4	dw	0
b_05C6	db	0,1,2,3,4,5,6,7,9,0Ch,10h,11h,12h
b_05D3	db	71h,50h,5Ah,0Eh,0FFh,6,0C8h,0E2h,0,0,18h,0,46h
b_05E0	db	1,2,3,5,8
b_05E5	db	0Fh,0,10h,1,2

; ----------------------------------------------------------------------------
; tgfx_has_back_buffer (slot 16): has_back_buffer(n): capability flag.
; ----------------------------------------------------------------------------
tgfx_has_back_buffer:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	mov	ax, word ptr cs:[bx+caps_table]
	retf

; ----------------------------------------------------------------------------
; sub_05F5
; ----------------------------------------------------------------------------
sub_05F5:
	push	ax
	mov	ax, word ptr cs:draw_seg
	call	sub_05FF
	pop	ax
	retf

; ----------------------------------------------------------------------------
; sub_05FF
; ----------------------------------------------------------------------------
sub_05FF:
	and	ax, 7
	mov	word ptr cs:w_D041E, ax
	push	bx
	mov	bx, ax
	shl	bx, 1
	mov	ax, word ptr cs:[bx+page_seg]
	mov	es, ax
	cmp	ax, word ptr cs:page_seg
	jne	L_0630
	add	bx, 2
	cmp	word ptr cs:w_D026C, 0
	je	L_0626
	shl	bx, 1
L_0626:
	sub	bx, 8
	neg	bx
	mov	ax, 581h
	int	10h
L_0630:
	pop	bx
	ret

; ----------------------------------------------------------------------------
; tgfx_set_port (slot 48): BX = port: page and origin for the primitives.
; ----------------------------------------------------------------------------
tgfx_set_port:
	mov	ax, word ptr [bx+2]
	mov	word ptr cs:draw_x0, ax
	mov	ax, word ptr [bx+4]
	mov	word ptr cs:draw_y0, ax
	mov	ax, word ptr [bx+6]
	mov	word ptr cs:draw_xmax, ax
	mov	ax, word ptr [bx]

; ----------------------------------------------------------------------------
; tgfx_select_page (slot 47): AX = page: the page the primitives draw on.
; ----------------------------------------------------------------------------
tgfx_select_page:
	mov	word ptr cs:draw_seg, ax
	retf

; ----------------------------------------------------------------------------
; tgfx_mem_avail (slot 1): mem_avail(): largest free DOS block, in paragraphs.
; ----------------------------------------------------------------------------
tgfx_mem_avail:
	mov	ah, 48h
	mov	bx, 0FFFFh
	int	21h
	cmp	ax, 8
	jne	L_067D
	mov	ax, 40h
	mov	es, ax
	mov	ax, word ptr es:[15h]
	sub	ax, word ptr es:[13h]
	je	L_0673
	mov	cl, 6
	shl	ax, cl
	add	bx, ax
	sub	bx, 1
L_0673:
	sub	bx, word ptr cs:w_05C4
	jb	L_067D
	mov	ax, bx
	retf
L_067D:
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; tgfx_set_page (slot 24): set_page(n, seg): set the segment of page n.
; ----------------------------------------------------------------------------
tgfx_set_page:
	mov	bx, sp
	mov	ax, word ptr [bx+6]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	word ptr cs:[bx+page_seg], ax
	retf

; ----------------------------------------------------------------------------
; tgfx_alloc_page (slot 0): alloc_page(n): page 0 is the screen; otherwise allocate an off-screen page (0 if no memory).
; ----------------------------------------------------------------------------
tgfx_alloc_page:
	mov	bx, sp
	mov	ax, word ptr [bx+4]
	cmp	ax, 8
	jae	L_06E9
	cmp	ax, 2
	jae	L_06D4
	cmp	ax, 1
	je	L_06AB
	mov	word ptr cs:w_05C4, 0
L_06AB:
	mov	ax, 40h
	mov	es, ax
	mov	dx, word ptr es:[15h]
	cmp	dx, word ptr es:[13h]
	je	L_06CF
	call	far ptr tgfx_mem_avail
	mov	bx, word ptr cs:w_D041A
	cmp	bx, ax
	ja	L_06E9
	add	word ptr cs:w_05C4, bx
L_06CF:
	mov	ax, word ptr cs:page_seg
	retf
L_06D4:
	call	far ptr tgfx_mem_avail
	mov	bx, word ptr cs:w_D041A
	cmp	bx, ax
	ja	L_06E9
	mov	ah, 48h
	int	21h
	jb	L_06E9
	retf
L_06E9:
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; tgfx_free_page (slot 8): free_page(n): give page n's memory back to DOS.
; ----------------------------------------------------------------------------
tgfx_free_page:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	cmp	bx, 4
	jae	L_0726
	cmp	bx, 2
	jae	L_0717
	mov	ax, 40h
	mov	es, ax
	mov	dx, word ptr es:[15h]
	cmp	dx, word ptr es:[13h]
	je	L_0726
	mov	bx, word ptr cs:w_D041A
	sub	word ptr cs:w_05C4, bx
	retf
L_0717:
	shl	bx, 1
	mov	ax, word ptr cs:[bx+page_seg]
	push	es
	mov	es, ax
	mov	ah, 49h
	int	21h
	pop	es
L_0726:
	retf

; ----------------------------------------------------------------------------
; tgfx_init_mode (slot 36): init_mode(flags): set the video mode and default palette.
; ----------------------------------------------------------------------------
tgfx_init_mode:
	mov	bx, sp
	test	word ptr [bx+4], 2
	je	L_0784
	mov	dx, word ptr [bx+4]
	mov	word ptr cs:w_D026E, 1
	mov	ah, 0C0h
	int	15h
	jb	L_078B
	cmp	byte ptr es:[bx+2], 0FFh
	jne	L_078B
	cmp	byte ptr es:[bx+3], 1
	ja	L_078B
	mov	word ptr cs:w_D026C, 1
	mov	word ptr cs:w_D0418, 140h
	mov	word ptr cs:w_D041A, 1000h
	call	sub_080D
	and	dx, 80h
	mov	ax, dx
	add	dx, 3
	int	10h
	call	sub_082B
	or	dx, dx
	jne	L_077B
	call	sub_0886
L_077B:
	mov	dx, 3D8h
	mov	al, 1Bh
	out	dx, al
	jmp	L_07BA
L_0784:
	mov	word ptr cs:w_D026E, 0
L_078B:
	mov	dx, 9
	mov	word ptr cs:w_D026C, 0
	mov	word ptr cs:w_D0418, 0A0h
	mov	word ptr cs:w_D041A, 800h
	call	sub_07DC
	mov	ax, dx
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, dl
	jne	L_07C6
	mov	ax, 583h
	mov	bx, 606h
	int	10h
L_07BA:
	xor	ax, ax
	push	ax
	call	far ptr tgfx_alloc_page
	add	sp, 2
	retf
L_07C6:
	mov	dx, 432h
	mov	ax, DATA
	mov	ds, ax
	mov	ax, 3
	int	10h
	mov	ah, 9
	int	21h
	mov	ax, 4C00h
	int	21h

; ----------------------------------------------------------------------------
; sub_07DC
; ----------------------------------------------------------------------------
sub_07DC:
	push	di
	push	es
	push	cs
	pop	es
	mov	word ptr cs:page_seg, 0B800h
	xor	ax, ax
	mov	di, 1E80h
	mov	cx, 0C8h
	shr	cx, 1
	shr	cx, 1
L_07F3:
	stosw
	add	ax, 2000h
	stosw
	add	ax, 2000h
	stosw
	add	ax, 2000h
	stosw
	and	ax, 1FFFh
	add	ax, word ptr cs:w_D0418
	loop	L_07F3
	pop	es
	pop	di
	ret

; ----------------------------------------------------------------------------
; sub_080D
; ----------------------------------------------------------------------------
sub_080D:
	push	di
	push	es
	push	cs
	pop	es
	mov	word ptr cs:page_seg, 0A000h
	xor	ax, ax
	mov	di, 1E80h
	mov	cx, 0C8h
L_0820:
	stosw
	add	ax, word ptr cs:w_D0418
	loop	L_0820
	pop	es
	pop	di
	ret

; ----------------------------------------------------------------------------
; sub_082B
; ----------------------------------------------------------------------------
sub_082B:
	push	dx
	mov	dx, 3DAh
L_082F:
	in	al, dx
	test	al, 8
	je	L_082F
L_0834:
	in	al, dx
	test	al, 8
	jne	L_0834
	mov	dx, 3D8h
	mov	al, 13h
	out	dx, al
	sub	bx, bx
	mov	dx, 3D4h
L_0844:
	mov	al, byte ptr cs:[bx+b_05C6]
	out	dx, al
	inc	dx
	mov	al, byte ptr cs:[bx+b_05D3]
	out	dx, al
	dec	dx
	inc	bx
	cmp	bx, 0Ch
	jbe	L_0844
	mov	dx, 3D9h
	mov	al, 0
	out	dx, al
	mov	dx, 3DDh
	mov	al, 0
	out	dx, al
	sub	bx, bx
L_0866:
	mov	dx, 3DAh
	mov	al, byte ptr cs:[bx+b_05E0]
	out	dx, al
	mov	dx, 3DEh
	mov	al, byte ptr cs:[bx+b_05E5]
	out	dx, al
	inc	bx
	cmp	bx, 4
	jbe	L_0866
	mov	dx, 3DFh
	mov	al, 24h
	out	dx, al
	pop	dx
	ret

; ----------------------------------------------------------------------------
; sub_0886
; ----------------------------------------------------------------------------
sub_0886:
	push	es
	push	di
	mov	cx, 7D00h
	sub	di, di
	mov	ax, 0A000h
	mov	es, ax
	sub	ax, ax
	rep	stosw
	pop	di
	pop	es
	ret

; ----------------------------------------------------------------------------
; tgfx_screen_off (slot 22): Blank the display.
; ----------------------------------------------------------------------------
tgfx_screen_off:
	push	dx
	mov	dx, 3DAh
L_089D:
	in	al, dx
	test	al, 8
	je	L_089D
	mov	dx, 3D8h
	mov	al, 3
	cmp	word ptr cs:w_D026C, 0
	je	L_08B1
	mov	al, 13h
L_08B1:
	out	dx, al
	pop	dx
	retf

; ----------------------------------------------------------------------------
; tgfx_screen_on (slot 23): Turn the display back on.
; ----------------------------------------------------------------------------
tgfx_screen_on:
	push	dx
	mov	dx, 3DAh
L_08B8:
	in	al, dx
	test	al, 8
	je	L_08B8
	mov	dx, 3D8h
	mov	al, 0Bh
	cmp	word ptr cs:w_D026C, 0
	je	L_08CC
	mov	al, 1Bh
L_08CC:
	out	dx, al
	pop	dx
	retf
	db	0

; ----------------------------------------------------------------------------
; tgfx_put_pixel (slot 37): AX = x, BX = y: plot a pixel with the current colour and mode.
; ----------------------------------------------------------------------------
tgfx_put_pixel:
	push	ds
	push	es
	mov	di, DATA
	mov	ds, di
	call	far ptr sub_05F5
	cmp	word ptr cs:w_D026C, 0
	je	L_08E6
	shl	ax, 1
L_08E6:
	add	ax, word ptr cs:draw_x0
	add	bx, word ptr cs:draw_y0
	mov	word ptr line_y0, ax
	mov	word ptr w_D045A, bx
L_08F7:
	call	pixel_addr
	je	L_0904
	add	di, word ptr [bx]
	xor	byte ptr es:[di], dl
	jmp	L_090E
L_0904:
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	and	al, ah
	or	al, dl
	stosb
L_090E:
	pop	es
	pop	ds
	retf

; ----------------------------------------------------------------------------
; pixel_addr
; ----------------------------------------------------------------------------
pixel_addr:
	mov	ah, 0F0h
	mov	dl, byte ptr cs:draw_color
	mov	dh, dl
	shl	dh, 1
	shl	dh, 1
	shl	dh, 1
	shl	dh, 1
	or	dh, dl
	mov	di, word ptr line_y0
	shr	di, 1
	jb	L_0930
	not	ah
	xor	dl, dh
L_0930:
	mov	bx, word ptr w_D045A
	shl	bx, 1
	add	bx, 270h
	mov	al, byte ptr cs:draw_opcode
	cmp	al, 20h
	jne	L_0946
	or	dl, ah
	not	dh
L_0946:
	cmp	al, 88h
	ret

; ----------------------------------------------------------------------------
; tgfx_draw_line (slot 41): AX,BX - CX,DX: draw a line with the current colour and mode.
; ----------------------------------------------------------------------------
tgfx_draw_line:
	push	ds
	push	es
	mov	di, DATA
	mov	ds, di
	call	far ptr sub_05F5
	mov	di, word ptr cs:draw_x0
	add	ax, di
	add	cx, di
	mov	di, word ptr cs:draw_y0
	add	bx, di
	add	dx, di
	cmp	word ptr cs:w_D026C, 0
	je	L_0973
	shl	ax, 1
	shl	cx, 1
L_0973:
	cmp	ax, cx
	jbe	L_097A
	xchg	cx, ax
	xchg	bx, dx
L_097A:
	mov	word ptr line_y0, ax
	mov	word ptr w_D045A, bx
	mov	word ptr line_x1, cx
	mov	word ptr line_y1, dx
	jne	L_0992
	cmp	bx, dx
	jne	L_0992
	jmp	L_08F7
L_0992:
	mov	bp, 2
	sub	cx, ax
	sub	dx, bx
	jns	L_099F
	neg	bp
	neg	dx
L_099F:
	mov	word ptr w_D0460, cx
	mov	word ptr w_D0462, dx
	cmp	dx, cx
	ja	L_0A09
	mov	cx, word ptr w_D0460
	mov	si, cx
	inc	si
	shr	si, 1
	neg	si
	call	pixel_addr
	jne	L_09E2
L_09BB:
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	and	al, ah
	or	al, dl
	mov	byte ptr es:[di], al
	sub	di, word ptr [bx]
	dec	cx
	js	L_0A06
	add	si, word ptr w_D0462
	js	L_09D8
	add	bx, bp
	sub	si, word ptr w_D0460
L_09D8:
	xor	dl, dh
	xor	ah, 0FFh
	js	L_09BB
	inc	di
	jmp	L_09BB
L_09E2:
	mov	byte ptr cs:b_09F0, al
	mov	ax, word ptr line_y0
L_09E9:
	mov	di, ax
	shr	di, 1
	add	di, word ptr [bx]
b_09F0	equ	byte ptr $+1
	xor	byte ptr es:[di], dl
	dec	cx
	js	L_0A06
	add	si, word ptr w_D0462
	js	L_0A01
	add	bx, bp
	sub	si, word ptr w_D0460
L_0A01:
	xor	dl, dh
	inc	ax
	jmp	L_09E9
L_0A06:
	pop	es
	pop	ds
	retf
L_0A09:
	mov	cx, word ptr w_D0462
	mov	si, cx
	inc	si
	shr	si, 1
	neg	si
	call	pixel_addr
	jne	L_0A40
L_0A19:
	add	di, word ptr [bx]
	mov	al, byte ptr es:[di]
	and	al, ah
	or	al, dl
	mov	byte ptr es:[di], al
	sub	di, word ptr [bx]
	dec	cx
	js	L_0A06
	add	bx, bp
	add	si, word ptr w_D0460
	js	L_0A19
	sub	si, word ptr w_D0462
	xor	dl, dh
	xor	ah, 0FFh
	js	L_0A19
	inc	di
	jmp	L_0A19
L_0A40:
	mov	byte ptr cs:b_0A4E, al
	mov	ax, word ptr line_y0
L_0A47:
	mov	di, ax
	shr	di, 1
	add	di, word ptr [bx]
b_0A4E	equ	byte ptr $+1
	xor	byte ptr es:[di], dl
	dec	cx
	js	L_0A06
	add	bx, bp
	add	si, word ptr w_D0460
	js	L_0A47
	sub	si, word ptr w_D0462
	xor	dl, dh
	inc	ax
	jmp	L_0A47

; ----------------------------------------------------------------------------
; tgfx_show_page (slot 30): show_page(n): copy page n to the screen (with the mouse pointer).
; ----------------------------------------------------------------------------
tgfx_show_page:
	call	restore_ptr_bg
	mov	bx, sp
	mov	ax, word ptr [bx+4]
	mov	word ptr cs:w_D041C, ax
	call	save_ptr_bg
	mov	bx, word ptr cs:w_D041C
	shl	bx, 1
	mov	cx, word ptr cs:[bx+page_seg]
	mov	dx, word ptr cs:page_seg
	cmp	cx, dx
	jne	L_0AA9
	add	bx, 2
	cmp	word ptr cs:w_D026C, 0
	je	L_0A95
	shl	bx, 1
L_0A95:
	sub	bx, 8
	neg	bx
	mov	dh, bl
	mov	ax, 580h
	int	10h
	mov	ax, 583h
	mov	bh, dh
	int	10h
	retf
L_0AA9:
	push	si
	push	di
	push	ds
	push	es
	mov	ds, cx
	mov	es, dx
	mov	ax, 0C8h
	lea	bx, ds:[1E80h]
	mov	dx, word ptr cs:w_D0418
	shr	dx, 1
L_0ABF:
	mov	si, word ptr cs:[bx]
	mov	di, si
	mov	cx, dx
	rep	movsw
	add	bx, 2
	dec	ax
	jne	L_0ABF
	pop	es
	pop	ds
	pop	di
	pop	si
	retf
w_0AD3	dw	0
b_0AD5	db	0
L_0AD6:
	jmp	L_0C1B
L_0AD9:
	jmp	L_0C21
L_0ADC:
	jmp	L_0B9A

; ----------------------------------------------------------------------------
; tgfx_dissolve_page (slot 9): dissolve_page(n): copy page n to the screen in a pseudo-random dissolve.
; ----------------------------------------------------------------------------
tgfx_dissolve_page:
	mov	bx, sp
	push	bp
	push	si
	push	di
	push	ds
	push	es
	mov	ax, word ptr [bx+4]
	or	ax, ax
	je	L_0AD6
	mov	dx, 40h
	mov	ds, dx
	call	sub_05FF
	mov	bh, byte ptr ds:[8Ah]
	push	es
	xor	ax, ax
	call	sub_05FF
	mov	bl, byte ptr ds:[8Ah]
	pop	ds
	mov	bp, word ptr cs:w_0AD3
	or	bp, bp
	jne	L_0ADC
L_0B0D:
	inc	bp
L_0B0E:
	mov	dx, 3DAh
	in	al, dx
	test	al, 8
	je	L_0B0E
L_0B16:
	in	al, dx
	test	al, 8
	jne	L_0B16
	mov	si, 1
	mov	dx, 3DFh
	xor	cx, cx
	cmp	word ptr cs:w_D026C, 0
	jne	L_0AD9
L_0B2B:
	shr	si, 1
	jae	L_0B33
	xor	si, 0B400h
L_0B33:
	cmp	si, 0
	jb	L_0B2B
	dec	si
	shr	si, 1
	mov	di, 0FFFFh
	mov	al, bh
	out	dx, al
	mov	ah, byte ptr [si]
	mov	al, bl
	out	dx, al
	mov	al, byte ptr [si]
	jb	L_0B68
	rcl	si, 1
	inc	si
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
	mov	ax, bp
L_0B56:
	dec	ax
	jne	L_0B56
	inc	cx
	mov	dx, 3DAh
	in	al, dx
	mov	dx, 3DFh
	test	al, 8
	je	L_0B2B
	jmp	L_0B83
L_0B68:
	rcl	si, 1
	inc	si
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
	stosb
	mov	ax, bp
L_0B74:
	dec	ax
	jne	L_0B74
	inc	cx
	mov	dx, 3DAh
	in	al, dx
	mov	dx, 3DFh
	test	al, 8
	je	L_0B2B
L_0B83:
	cmp	cx, 21Eh
	ja	L_0B0D
	cmp	cx, 10Fh
	ja	L_0B95
	mov	byte ptr cs:b_0AD5, 1
L_0B95:
	mov	word ptr cs:w_0AD3, bp
L_0B9A:
	mov	si, 1
	mov	dx, 3DFh
	cmp	word ptr cs:w_D026C, 0
	je	L_0BAB
	jmp	L_0C4E
L_0BAB:
	cmp	byte ptr cs:b_0AD5, 0
	jne	L_0BFD
	mov	cx, 0FE80h
L_0BB6:
	shr	si, 1
	jae	L_0BBE
	xor	si, 0B400h
L_0BBE:
	cmp	si, 0FE80h
	ja	L_0BB6
	dec	si
	shr	si, 1
	mov	di, si
	mov	al, bh
	out	dx, al
	mov	ah, byte ptr [si]
	mov	al, bl
	out	dx, al
	mov	al, byte ptr [si]
	jb	L_0BE9
	rcl	si, 1
	inc	si
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
	mov	ax, bp
L_0BE1:
	dec	ax
	jne	L_0BE1
	loop	L_0BB6
	jmp	L_0AD6
L_0BE9:
	rcl	si, 1
	inc	si
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
	stosb
	mov	ax, bp
L_0BF5:
	dec	ax
	jne	L_0BF5
	loop	L_0BB6
	jmp	L_0C1B
L_0BFD:
	mov	cx, 7F40h
L_0C00:
	shr	si, 1
	jae	L_0C08
	xor	si, 6000h
L_0C08:
	cmp	si, 7F40h
	ja	L_0C00
	dec	si
	mov	di, si
	mov	al, bh
	out	dx, al
	lodsb
	xchg	bx, ax
	out	dx, al
	xchg	bx, ax
	stosb
	loop	L_0C00
L_0C1B:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
L_0C21:
	shr	si, 1
	jae	L_0C29
	xor	si, 0B400h
L_0C29:
	cmp	si, 0
	jb	L_0C21
	dec	si
	mov	di, 0FFFFh
	mov	al, bh
	out	dx, al
	lodsb
	xchg	bx, ax
	out	dx, al
	xchg	bx, ax
	stosb
	mov	ax, bp
L_0C3C:
	dec	ax
	jne	L_0C3C
	inc	cx
	mov	dx, 3DAh
	in	al, dx
	mov	dx, 3DFh
	test	al, 8
	je	L_0C21
	jmp	L_0B83
L_0C4E:
	mov	cx, 0FA00h
L_0C51:
	shr	si, 1
	jae	L_0C59
	xor	si, 0B400h
L_0C59:
	cmp	si, 0FA00h
	ja	L_0C51
	dec	si
	mov	di, si
	mov	al, bh
	out	dx, al
	lodsb
	xchg	bx, ax
	out	dx, al
	xchg	bx, ax
	stosb
	mov	ax, bp
L_0C6C:
	dec	ax
	jne	L_0C6C
	loop	L_0C51
	jmp	L_0C1B

; ----------------------------------------------------------------------------
; tgfx_swap_page (slot 35): swap_page(n): exchange the contents of page n and the screen.
; ----------------------------------------------------------------------------
tgfx_swap_page:
	retf

; ----------------------------------------------------------------------------
; tgfx_clear_page (slot 5): clear_page(page, colour): fill a whole page.
; ----------------------------------------------------------------------------
tgfx_clear_page:
	mov	bx, sp
	push	si
	push	di
	push	es
	mov	ax, word ptr [bx+4]
	call	sub_05FF
	mov	al, byte ptr [bx+6]
	mov	cl, 4
	mov	ah, al
	shl	ah, cl
	or	al, ah
	mov	ah, al
	mov	si, 0C8h
	lea	bx, ds:[1E80h]
	mov	dx, word ptr cs:w_D0418
	shr	dx, 1
L_0C9A:
	mov	di, word ptr cs:[bx]
	mov	cx, dx
	rep	stosw
	add	bx, 2
	dec	si
	jne	L_0C9A
	pop	es
	pop	di
	pop	si
	retf
	db	0
b_0CAC	db	0
b_0CAD	db	0
b_0CAE	db	0
w_0CAF	dw	0
L_0CB1:
	jmp	L_0E05

; ----------------------------------------------------------------------------
; tgfx_copy_rect (slot 19): copy_rect(src_port, x, y, w, h, dst_port, x, y): copy a rectangle between pages.
; ----------------------------------------------------------------------------
tgfx_copy_rect:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bp+6]
	mov	di, word ptr [bp+10h]
	mov	ax, word ptr [si]
	mov	byte ptr cs:b_0CAC, al
	mov	ax, word ptr [di]
	mov	byte ptr cs:b_0CAD, al
	mov	ax, word ptr [si+4]
	mov	bx, word ptr [si+2]
	mov	cx, word ptr [di+4]
	mov	dx, word ptr [di+2]
	add	ax, word ptr [bp+0Ah]
	add	bx, word ptr [bp+8]
	add	cx, word ptr [bp+14h]
	add	dx, word ptr [bp+12h]
	mov	si, ax
	shl	si, 1
	mov	di, cx
	shl	di, 1
	mov	ax, 40h
	mov	ds, ax
	mov	al, byte ptr cs:b_0CAC
	call	sub_05FF
	mov	al, byte ptr ds:[8Ah]
	mov	byte ptr cs:b_0CAC, al
	push	es
	mov	al, byte ptr cs:b_0CAD
	call	sub_05FF
	mov	al, byte ptr ds:[8Ah]
	mov	byte ptr cs:b_0CAD, al
	pop	ds
	mov	ax, ds
	mov	cx, es
	sub	ax, cx
	or	al, ah
	mov	byte ptr cs:b_0CAE, al
	mov	cx, word ptr [bp+0Eh]
	mov	bp, word ptr [bp+0Ch]
	xchg	bp, bx
	or	cx, cx
	je	L_0CB1
	or	bx, bx
	je	L_0CB1
	cmp	word ptr cs:w_D026C, 0
	je	L_0D3A
	shl	bx, 1
	shl	dx, 1
	shl	bp, 1
L_0D3A:
	mov	ax, dx
	xor	ax, bp
	shr	ax, 1
	jb	L_0D45
	jmp	L_0DA4
L_0D45:
	push	si
	push	di
	push	bx
	push	cx
	mov	cx, bx
	mov	si, word ptr cs:[si+row_offset]
	mov	ax, bp
	shr	ax, 1
	add	si, ax
	mov	di, word ptr cs:[di+row_offset]
	mov	ax, dx
	shr	ax, 1
	mov	bl, 0Fh
	jae	L_0D65
	not	bl
L_0D65:
	add	di, ax
	cmp	byte ptr cs:b_0CAE, 0
	jne	L_0D72
	jmp	L_0E0B
L_0D72:
	mov	ah, byte ptr [si]
	ror	ah, 1
	ror	ah, 1
	ror	ah, 1
	ror	ah, 1
	mov	al, byte ptr es:[di]
	xor	al, ah
	and	al, bl
	xor	al, ah
	mov	byte ptr es:[di], al
	xor	bl, 0FFh
	js	L_0D92
	inc	di
	loop	L_0D72
	jmp	short L_0D95
L_0D92:
	inc	si
	loop	L_0D72
L_0D95:
	pop	cx
	pop	bx
	pop	di
	pop	si
	add	di, 2
	add	si, 2
	loop	L_0D45
	jmp	L_0E05
L_0DA4:
	shr	bp, 1
	shr	dx, 1
	jae	L_0DAB
	dec	bx
L_0DAB:
	mov	ax, bx
	rcr	bh, 1
	shr	ax, 1
	rcr	bh, 1
	mov	word ptr cs:w_0CAF, ax
L_0DB7:
	push	si
	push	di
	push	cx
	mov	si, word ptr cs:[si+row_offset]
	add	si, bp
	mov	di, word ptr cs:[di+row_offset]
	add	di, dx
	mov	cx, word ptr cs:w_0CAF
	cmp	byte ptr cs:b_0CAE, 0
	jne	L_0DD8
	jmp	L_0E40
L_0DD8:
	test	bh, 40h
	je	L_0DE8
	lodsb
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
L_0DE8:
	rep	movsb
	test	bh, 80h
	je	L_0DFA
	lodsb
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
	stosb
L_0DFA:
	pop	cx
	pop	di
	pop	si
	add	di, 2
	add	si, 2
	loop	L_0DB7
L_0E05:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
L_0E0B:
	push	dx
	mov	dx, 3DFh
L_0E0F:
	mov	al, byte ptr cs:b_0CAC
	out	dx, al
	mov	ah, byte ptr [si]
	ror	ah, 1
	ror	ah, 1
	ror	ah, 1
	ror	ah, 1
	mov	al, byte ptr cs:b_0CAD
	out	dx, al
	mov	al, byte ptr es:[di]
	xor	al, ah
	and	al, bl
	xor	al, ah
	mov	byte ptr es:[di], al
	xor	bl, 0FFh
	js	L_0E39
	inc	di
	loop	L_0E0F
	jmp	short L_0E3C
L_0E39:
	inc	si
	loop	L_0E0F
L_0E3C:
	pop	dx
	jmp	L_0D95
L_0E40:
	push	dx
	mov	dx, 3DFh
	test	bh, 40h
	je	L_0E62
	mov	al, byte ptr cs:b_0CAC
	out	dx, al
	lodsb
	mov	ah, al
	mov	al, byte ptr cs:b_0CAD
	out	dx, al
	mov	al, ah
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
L_0E62:
	jcxz	L_0E76
L_0E64:
	mov	al, byte ptr cs:b_0CAC
	out	dx, al
	lodsb
	mov	ah, al
	mov	al, byte ptr cs:b_0CAD
	out	dx, al
	mov	al, ah
	stosb
	loop	L_0E64
L_0E76:
	test	bh, 80h
	je	L_0E94
	mov	al, byte ptr cs:b_0CAC
	out	dx, al
	lodsb
	mov	ah, al
	mov	al, byte ptr cs:b_0CAD
	out	dx, al
	mov	al, ah
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
	stosb
L_0E94:
	pop	dx
	jmp	L_0DFA

; ----------------------------------------------------------------------------
; tgfx_copy_rows_to_screen (slot 49): AX = first row, CX = last row, BX = span table, SI/DI = pages: copy each row's span.
; ----------------------------------------------------------------------------
tgfx_copy_rows_to_screen:
	or	ax, ax
	js	L_0EE7
	push	ds
	push	es
	mov	bp, bx
	mov	bx, ax
	shl	bx, 1
	mov	dx, cx
	shl	dx, 1
	mov	ax, si
	call	sub_05FF
	push	es
	mov	ax, di
	call	sub_05FF
	pop	ds
L_0EB4:
	mov	si, bx
	mov	ax, word ptr [bp+si]
	mov	cx, word ptr [bp+si+190h]
	shr	cx, 1
	shr	ax, 1
	cmp	word ptr cs:w_D026C, 0
	jne	L_0ECC
	shr	cx, 1
	shr	ax, 1
L_0ECC:
	sub	cx, ax
	jb	L_0EDE
	inc	cx
	mov	di, word ptr cs:[si+row_offset]
	shl	ax, 1
	add	di, ax
	mov	si, di
	rep	movsw
L_0EDE:
	add	bx, 2
	cmp	bx, dx
	jbe	L_0EB4
	pop	es
	pop	ds
L_0EE7:
	retf
img_ptr	dw	0
img_seg	dw	0
img_block	dw	0
img_block_end	dw	0
img_limit	dw	0
img_skip	dw	0
img_trail	dw	0
img_len	dw	0
w_0EF8	dw	0
w_0EFA	dw	0
b_0EFC	db	0
	EVEN
img_rows	dw	0
img_width	dw	0
blit_rows	dw	0
blit_cols	dw	0
src_width	dw	0
src_height	dw	0
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
clip_right	dw	0
step_x	dw	0
step_y	dw	0
row_step	dw	0
src_seg	dw	0
dst_seg	dw	0
w_0F2C	dw	0
b_0F2E	db	0,0
b_0F30	db	0
b_0F31	db	0
b_0F32	db	0
b_0F33	db	0
row_buffer	dw	160 dup (0)

; ----------------------------------------------------------------------------
; tgfx_begin_image_grab (slot 17): begin_image_grab(): allocate the largest free DOS block to collect images in.
; ----------------------------------------------------------------------------
tgfx_begin_image_grab:
	call	far ptr tgfx_mem_avail
	mov	bx, ax
	or	bx, bx
	je	L_1085
	mov	ah, 48h
	int	21h
	jae	L_1089
L_1085:
	xor	ax, ax
	xor	bx, bx
L_1089:
	add	bx, ax
	mov	word ptr cs:img_ptr, 0
	mov	word ptr cs:img_seg, ax
	mov	word ptr cs:img_block, ax
	mov	word ptr cs:img_block_end, bx
	retf

; ----------------------------------------------------------------------------
; tgfx_end_image_grab (slot 7): end_image_grab(): shrink the image block to what was used; returns its segment.
; ----------------------------------------------------------------------------
tgfx_end_image_grab:
	mov	ax, word ptr cs:img_block
	or	ax, ax
	je	L_10C0
	mov	bx, word ptr cs:img_seg
	sub	bx, ax
	mov	es, ax
	mov	ah, 4Ah
	or	bx, bx
	jne	L_10B9
	mov	ah, 49h
L_10B9:
	int	21h
	jb	L_10C0
	mov	ax, es
	retf
L_10C0:
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; tgfx_begin_image (slot 34): begin_image(w, h): start an image; returns its segment (0 if out of room).
; ----------------------------------------------------------------------------
tgfx_begin_image:
	mov	ax, word ptr cs:img_block_end
	sub	ax, word ptr cs:img_seg
	jbe	L_112F
	cmp	ax, 1000h
	jb	L_10D6
	mov	ax, 0FFFh
L_10D6:
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	word ptr cs:img_limit, ax
	mov	bx, sp
	push	di
	les	di, dword ptr cs:img_ptr
	mov	word ptr cs:w_0EF8, 1298h
	mov	ax, word ptr [bx+4]
	stosw
	cmp	word ptr cs:w_D026C, 0
	je	L_1106
	shl	ax, 1
	mov	word ptr cs:w_0EF8, 12B2h
L_1106:
	mov	word ptr cs:w_0EFA, 1
	inc	ax
	shr	ax, 1
	mov	word ptr cs:img_width, ax
	mov	al, 0FFh
	jb	L_111A
	mov	al, 0F0h
L_111A:
	mov	byte ptr cs:b_0EFC, al
	mov	ax, word ptr [bx+6]
	stosw
	mov	word ptr cs:img_rows, ax
	mov	word ptr cs:img_ptr, di
	mov	ax, es
	pop	di
	retf
L_112F:
	xor	ax, ax
	mov	word ptr cs:img_ptr, ax
	mov	word ptr cs:img_seg, ax
	retf

; ----------------------------------------------------------------------------
; tgfx_end_image (slot 32): end_image(): close the image being built; returns its segment.
; ----------------------------------------------------------------------------
tgfx_end_image:
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
; tgfx_image_add_row (slot 33): image_add_row(row): append a row to the image being built.
; ----------------------------------------------------------------------------
tgfx_image_add_row:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	si, word ptr [bp+6]
	les	di, dword ptr cs:img_ptr
	mov	ax, es
	or	ax, ax
	jne	L_116D
	jmp	L_1207
L_116D:
	mov	ax, word ptr cs:img_width
	add	ax, 4
	add	ax, di
	cmp	ax, word ptr cs:img_limit
	jbe	L_118B
	dec	word ptr es:[2]
	xor	ax, ax
	mov	word ptr cs:img_block_end, ax
	jmp	L_1207
L_118B:
	xor	ax, ax
	mov	word ptr cs:img_skip, ax
	mov	word ptr cs:img_trail, ax
	mov	word ptr cs:img_len, ax
	xor	word ptr cs:w_0EFA, 1
	mov	bp, di
	stosw
	stosw
	mov	bx, 21Eh
	add	bx, word ptr cs:w_0EFA
	mov	cx, word ptr cs:img_width
L_11B0:
	call	word ptr cs:w_0EF8
	or	al, al
	je	L_11C3
	mov	word ptr cs:img_trail, 0
	jmp	L_11DA
L_11C3:
	cmp	word ptr cs:img_len, 0
	jne	L_11D5
	inc	word ptr cs:img_skip
	loop	L_11B0
	jmp	L_11E2
L_11D5:
	inc	word ptr cs:img_trail
L_11DA:
	inc	word ptr cs:img_len
	stosb
	loop	L_11B0
L_11E2:
	mov	ax, word ptr cs:img_len
	mov	bx, word ptr cs:img_skip
	mov	cx, word ptr cs:img_trail
	or	cx, cx
	je	L_11F8
	sub	ax, cx
	sub	di, cx
L_11F8:
	mov	word ptr es:[bp], ax
	mov	word ptr es:[bp+2], bx
	mov	word ptr cs:img_ptr, di
	mov	ax, es
L_1207:
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_get_image (slot 2): get_image(page, x, y, w, h): grab a block of a page as an image.
; ----------------------------------------------------------------------------
tgfx_get_image:
	push	bp
	mov	bp, sp
	push	si
	push	ds
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	call	far ptr tgfx_begin_image
	add	sp, 4
	or	ax, ax
	je	L_1278
	cmp	word ptr cs:img_rows, 0
	je	L_1278
	cmp	word ptr cs:img_width, 0
	je	L_1278
	mov	ax, word ptr [bp+6]
	call	sub_05FF
	mov	ax, es
	mov	ds, ax
	mov	si, word ptr [bp+0Ah]
	shl	si, 1
	mov	bp, word ptr [bp+8]
	cmp	word ptr cs:w_D026C, 0
	jne	L_124E
	shr	bp, 1
L_124E:
	mov	word ptr cs:w_0EF8, 1281h
	jae	L_125E
	mov	word ptr cs:w_0EF8, 1288h
L_125E:
	mov	ax, word ptr cs:[si+row_offset]
	add	ax, bp
	push	ax
	call	far ptr tgfx_image_add_row
	add	sp, 2
	add	si, 2
	dec	word ptr cs:img_rows
	jne	L_125E
L_1278:
	call	far ptr tgfx_end_image
	pop	ds
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; L_1281
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_1281:
	lodsb
	cmp	cx, 1
	je	L_12AC
	ret

; ----------------------------------------------------------------------------
; L_1288
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_1288:
	lodsw
	dec	si
	rol	ax, 1
	rol	ax, 1
	rol	ax, 1
	rol	ax, 1
	cmp	cx, 1
	je	L_12AC
	ret

; ----------------------------------------------------------------------------
; L_1298
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_1298:
	lodsw
	and	ax, 0F0Fh
	shl	al, 1
	shl	al, 1
	shl	al, 1
	shl	al, 1
	or	al, ah
	cmp	cx, 1
	je	L_12AC
	ret
L_12AC:
	and	al, byte ptr cs:b_0EFC
	ret

; ----------------------------------------------------------------------------
; L_12B2
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_12B2:
	lodsb
	shl	al, 1
	xlat	byte ptr cs:[bx]
	ret

; ----------------------------------------------------------------------------
; tgfx_draw_image_scaled (slot 21): draw_image_scaled(port, x, y, w, h, image, param): draw an image scaled (mirrored when w or h < 0).
; ----------------------------------------------------------------------------
tgfx_draw_image_scaled:
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
	je	L_12FD
	call	clip_image
	jb	L_12FD
	call	far ptr blit_image_scaled
L_12FD:
	mov	ax, 0F12h
	mov	dx, cs
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_draw_image (slot 6): draw_image(port, x, y, image): draw an image clipped to the port; returns a far pointer to the drawn rectangle.
; ----------------------------------------------------------------------------
tgfx_draw_image:
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
	je	L_1337
	call	clip_image
	jb	L_1337
	call	far ptr blit_image
L_1337:
	mov	ax, 0F12h
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
	jns	L_1354
	mov	ax, di
	neg	ax
	cmp	ax, word ptr cs:dst_height
	jae	L_13A0
	mov	word ptr cs:clip_top, ax
L_1354:
	mov	ax, di
	add	ax, word ptr cs:dst_height
	dec	ax
	mov	bx, word ptr [bp+8]
	or	bx, bx
	js	L_13A0
	cmp	di, bx
	jg	L_13A0
	sub	ax, bx
	jle	L_136F
	mov	word ptr cs:clip_bottom, ax
L_136F:
	or	dx, dx
	jns	L_1382
	mov	ax, dx
	neg	ax
	cmp	ax, word ptr cs:dst_width
	jae	L_13A0
	mov	word ptr cs:clip_left, ax
L_1382:
	mov	ax, dx
	add	ax, word ptr cs:dst_width
	dec	ax
	mov	bx, word ptr [bp+6]
	or	bx, bx
	js	L_13A0
	cmp	dx, bx
	jg	L_13A0
	sub	ax, bx
	jle	L_13A2
	mov	word ptr cs:clip_right, ax
	jmp	L_13A2
L_13A0:
	stc
	ret
L_13A2:
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
	je	L_1410
	mov	ax, word ptr ds:[0]
	or	ax, ax
	je	L_1410
	mov	ax, word ptr ds:[2]
	or	ax, ax
L_1410:
	ret

; ----------------------------------------------------------------------------
; tgfx_draw_image_noclip (slot 31): draw_image_noclip(port, x, y, image): draw an image without clipping.
; ----------------------------------------------------------------------------
tgfx_draw_image_noclip:
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
	je	L_142F
	call	far ptr blit_image
L_142F:
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
	mov	ax, word ptr [bp]
	call	sub_05FF
	add	dx, word ptr [bp+2]
	add	di, word ptr [bp+4]
	add	di, word ptr cs:clip_top
	shl	di, 1
	lodsw
	mov	bp, ax
	cmp	word ptr cs:w_D026C, 0
	je	L_1462
	shl	dx, 1
	shl	bp, 1
	shl	word ptr cs:clip_left, 1
	shl	word ptr cs:clip_right, 1
L_1462:
	mov	ax, dx
	and	ax, 1
	mov	byte ptr cs:b_0F2E, al
	mov	ax, 0FFFFh
	je	L_1473
	mov	ax, 0FF0h
L_1473:
	mov	byte ptr cs:b_0F30, ah
	mov	byte ptr cs:b_0F31, al
	mov	bx, dx
	add	bx, word ptr cs:clip_left
	shr	bx, 1
	mov	word ptr cs:w_0F2C, bx
	mov	al, 0FFh
	jae	L_1490
	mov	al, 0Fh
L_1490:
	mov	byte ptr cs:b_0F32, al
	add	dx, bp
	dec	dx
	sub	dx, word ptr cs:clip_right
	mov	al, 0FFh
	test	dx, 1
	jne	L_14A6
	mov	al, 0F0h
L_14A6:
	mov	byte ptr cs:b_0F33, al
	mov	ax, dx
	shr	ax, 1
	sub	ax, bx
	inc	ax
	mov	word ptr cs:blit_cols, ax
	lodsw
	sub	ax, word ptr cs:clip_top
	sub	ax, word ptr cs:clip_bottom
	ja	L_14C5
	jmp	L_156A
L_14C5:
	mov	word ptr cs:blit_rows, ax
	mov	cx, word ptr cs:clip_top
	jcxz	L_14D7
L_14D0:
	add	si, word ptr [si]
	add	si, 4
	loop	L_14D0
L_14D7:
	xor	ah, ah
	mov	al, byte ptr cs:b_0F2E
	add	ax, word ptr cs:clip_left
	shr	ax, 1
	mov	word ptr cs:clip_left, ax
L_14E8:
	lodsw
	mov	dx, ax
	lodsw
	or	dx, dx
	je	L_155D
	mov	bp, dx
	add	bp, si
	push	di
	mov	di, word ptr cs:[di+row_offset]
	add	di, word ptr cs:w_0F2C
	mov	bh, byte ptr cs:b_0F32
	mov	bl, byte ptr cs:b_0F33
	mov	cx, word ptr cs:blit_cols
	add	dx, word ptr cs:b_0F2E
	sub	ax, word ptr cs:clip_left
	je	L_1535
	jb	L_152A
	add	di, ax
	sub	cx, ax
	jbe	L_155A
	mov	bh, byte ptr cs:b_0F30
	jmp	L_153A
L_152A:
	neg	ax
	add	si, ax
	sub	dx, ax
	jbe	L_155A
	jmp	L_153A
L_1535:
	and	bh, byte ptr cs:b_0F30
L_153A:
	cmp	dx, cx
	je	L_154A
	ja	L_154F
	mov	cx, dx
	mov	bl, byte ptr cs:b_0F31
	jmp	L_154F
L_154A:
	and	bl, byte ptr cs:b_0F31
L_154F:
	cmp	byte ptr cs:b_0F2E, 0
	je	L_156D
	jmp	L_15AA
L_155A:
	mov	si, bp
	pop	di
L_155D:
	add	di, 2
	dec	byte ptr cs:blit_rows
	je	L_156A
	jmp	L_14E8
L_156A:
	pop	es
	pop	bp
	retf
L_156D:
	cmp	cx, 1
	je	L_15A6
L_1572:
	lodsb
	and	al, bh
	je	L_159F
	test	al, 0F0h
	jne	L_158B
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
	mov	bh, 0FFh
	loop	L_156D
	jmp	L_155A
L_158B:
	test	al, 0Fh
	jne	L_1598
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
L_1598:
	stosb
	mov	bh, 0FFh
	loop	L_156D
	jmp	L_155A
L_159F:
	inc	di
	mov	bh, 0FFh
	loop	L_156D
	jmp	L_155A
L_15A6:
	and	bh, bl
	jmp	L_1572
L_15AA:
	mov	dh, byte ptr [si-1]
L_15AD:
	cmp	cl, 1
	je	L_15F4
L_15B2:
	lodsb
	mov	ah, dh
	mov	dh, al
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	and	al, bh
	je	L_15EC
	test	al, 0F0h
	jne	L_15D7
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0Fh
	xor	al, ah
	stosb
	mov	bh, 0FFh
	loop	L_15AD
	jmp	L_155A
L_15D7:
	test	al, 0Fh
	jne	L_15E4
	mov	ah, byte ptr es:[di]
	xor	al, ah
	and	al, 0F0h
	xor	al, ah
L_15E4:
	stosb
	mov	bh, 0FFh
	loop	L_15AD
	jmp	L_155A
L_15EC:
	inc	di
	mov	bh, 0FFh
	loop	L_15AD
	jmp	L_155A
L_15F4:
	and	bh, bl
	jmp	L_15B2
L_15F8:
	jmp	L_1700

; ----------------------------------------------------------------------------
; blit_image_scaled
; ----------------------------------------------------------------------------
blit_image_scaled:
	push	bp
	push	es
	mov	ax, word ptr [bp]
	call	sub_05FF
	mov	word ptr cs:dst_seg, es
	add	dx, word ptr [bp+2]
	add	di, word ptr [bp+4]
	lodsw
	mov	word ptr cs:src_width, ax
	lodsw
	mov	word ptr cs:src_height, ax
	mov	ax, ds
	mov	es, ax
	mov	word ptr cs:src_seg, ax
	mov	ax, cs
	mov	ds, ax
	ASSUME	DS:DGROUP
	mov	ax, word ptr dst_width
	sub	ax, word ptr clip_left
	sub	ax, word ptr clip_right
	jle	L_15F8
	mov	word ptr blit_cols, ax
	mov	ax, word ptr dst_height
	sub	ax, word ptr clip_top
	sub	ax, word ptr clip_bottom
	jle	L_15F8
	mov	word ptr blit_rows, ax
	mov	word ptr row_step, 2
	mov	cx, word ptr clip_top
	add	di, cx
	cmp	word ptr flip_y, 0
	je	L_1664
	neg	word ptr row_step
	mov	cx, word ptr clip_bottom
	add	di, word ptr blit_rows
	dec	di
L_1664:
	mov	ax, word ptr dst_height
	inc	ax
	shr	ax, 1
	neg	ax
L_166C:
	dec	cx
	js	L_1683
	add	ax, word ptr src_height
	js	L_166C
L_1675:
	add	si, word ptr es:[si]
	add	si, 4
	sub	ax, word ptr dst_height
	jns	L_1675
	jmp	L_166C
L_1683:
	mov	word ptr step_y, ax
	mov	cx, word ptr clip_left
	add	dx, cx
	mov	al, byte ptr b_17D1
	mov	bx, word ptr w_17D2
	cmp	word ptr flip_x, 0
	je	L_16AA
	mov	al, byte ptr b_17D5
	mov	bx, word ptr w_17D6
	mov	cx, word ptr clip_right
	add	dx, word ptr blit_cols
	dec	dx
L_16AA:
	mov	byte ptr L_1796, al
	mov	word ptr L_1797, bx
	mov	byte ptr L_17B8, al
	mov	word ptr L_17B9, bx
	mov	ax, word ptr dst_width
	inc	ax
	shr	ax, 1
	neg	ax
	xor	bx, bx
L_16C2:
	dec	cx
	js	L_16D4
	add	ax, word ptr src_width
	js	L_16C2
L_16CB:
	inc	bx
	sub	ax, word ptr dst_width
	jns	L_16CB
	jmp	L_16C2
L_16D4:
	mov	word ptr step_x, ax
	mov	word ptr clip_left, bx
	mov	al, 0Fh
	shr	dx, 1
	jae	L_16E3
	not	al
L_16E3:
	mov	byte ptr b_0F32, al
	mov	word ptr w_0F2C, dx
	mov	al, 0F0h
	shr	word ptr clip_left, 1
	jae	L_16F4
	not	al
L_16F4:
	mov	byte ptr b_0F30, al
	shl	di, 1
	mov	ds, word ptr src_seg
	jmp	L_1706
L_1700:
	pop	es
	pop	bp
	retf
L_1703:
	jmp	L_17DA
L_1706:
	push	si
	lodsw
	or	ax, ax
	je	L_1703
	mov	bx, ax
	lodsw
	mov	cx, ax
	push	di
	mov	di, word ptr cs:[di+row_offset]
	add	di, word ptr cs:w_0F2C
	mov	bp, di
	mov	ax, cs
	mov	es, ax
	lea	di, row_buffer
	mov	dx, word ptr cs:src_width
	inc	dx
	shr	dx, 1
	sub	dx, bx
	sub	dx, cx
	xor	al, al
	rep	stosb
	mov	cx, bx
	rep	movsb
	mov	cx, dx
	rep	stosb
	mov	ax, cs
	mov	ds, ax
	lea	si, row_buffer
	mov	di, bp
	mov	es, word ptr dst_seg
	add	si, word ptr clip_left
	mov	dl, byte ptr b_0F30
	mov	dh, byte ptr b_0F32
	mov	bx, word ptr src_width
	mov	bp, word ptr step_x
	mov	cx, word ptr blit_cols
L_1764:
	mov	al, byte ptr [si]
	and	al, dl
	not	dl
	rol	dl, 1
	ror	dl, 1
	adc	si, 0
	or	al, al
	je	L_17AF
	mov	ah, al
	ror	ah, 1
	ror	ah, 1
	ror	ah, 1
	ror	ah, 1
	or	al, ah
L_1781:
	dec	cx
	js	L_17D9
	mov	ah, byte ptr es:[di]
	xor	ah, al
	and	ah, dh
	xor	ah, al
	mov	byte ptr es:[di], ah
	not	dh
	rol	dh, 1
	ror	dh, 1
L_1796:
	cmc
L_1797:
	adc	di, 0
	add	bp, bx
	js	L_1781
L_179E:
	sub	bp, word ptr dst_width
	js	L_1764
	not	dl
	rol	dl, 1
	ror	dl, 1
	adc	si, 0
	jmp	L_179E
L_17AF:
	dec	cx
	js	L_17D9
	not	dh
	rol	dh, 1
	ror	dh, 1
L_17B8:
	cmc
L_17B9:
	adc	di, 0
	add	bp, bx
	js	L_17AF
L_17C0:
	sub	bp, word ptr dst_width
	js	L_1764
	not	dl
	rol	dl, 1
	ror	dl, 1
	adc	si, 0
	jmp	L_17C0
b_17D1	db	0F5h
w_17D2	db	83h,0D7h,0
b_17D5	db	90h
w_17D6	db	83h,0DFh,0
L_17D9:
	pop	di
L_17DA:
	pop	si
	dec	word ptr cs:blit_rows
	je	L_180A
	add	di, word ptr cs:row_step
	mov	ds, word ptr cs:src_seg
	mov	ax, word ptr cs:step_y
	add	ax, word ptr cs:src_height
	js	L_1803
L_17F7:
	add	si, word ptr [si]
	add	si, 4
	sub	ax, word ptr cs:dst_height
	jns	L_17F7
L_1803:
	mov	word ptr cs:step_y, ax
	jmp	L_1706
L_180A:
	jmp	L_1700
	db	0,0Ch,4,0Ch,0Eh
shake_seed	dw	4D2h
shake_count	db	0

; ----------------------------------------------------------------------------
; tgfx_set_shake (slot 28): set_shake(n): shake the screen for the next n calls of shake_tick.
; ----------------------------------------------------------------------------
tgfx_set_shake:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	mov	byte ptr cs:shake_count, al
	retf

; ----------------------------------------------------------------------------
; tgfx_shake_tick (slot 50): shake_tick(): while shaking, move the display start at random.
; ----------------------------------------------------------------------------
tgfx_shake_tick:
	mov	ax, word ptr cs:shake_seed
	shl	ax, 1
	shl	ax, 1
	add	ax, word ptr cs:shake_seed
	inc	ax
	mov	word ptr cs:shake_seed, ax
	cmp	byte ptr cs:shake_count, 0
	je	L_184B
	and	ah, 3
	dec	byte ptr cs:shake_count
	jne	L_1845
	xor	ah, ah
L_1845:
	mov	dx, 3D4h
	mov	al, 0Dh
	out	dx, ax
L_184B:
	retf
L_184C:
	and	al, 7Fh
	mov	byte ptr ds:[468h], al
	jmp	L_1878
L_1854:
	pop	bp
	mov	al, byte ptr ds:[468h]
	mov	byte ptr [bp+0Ch], al
	retf

; ----------------------------------------------------------------------------
; draw_glyphs
; ----------------------------------------------------------------------------
draw_glyphs:
	mov	al, byte ptr [bp+0Ch]
	mov	byte ptr ds:[468h], al
	mov	al, byte ptr [bp+0Eh]
	mov	byte ptr ds:[469h], al
	mov	al, byte ptr [bp+0Ah]
	mov	byte ptr ds:[46Ah], al
	push	bp
	mov	bp, word ptr ds:[47Dh]
	mov	ax, es
	call	sub_05FF
L_1878:
	mov	ax, word ptr ss:[si]
	inc	si
	or	al, al
	je	L_1854
	js	L_184C
	push	si
	sub	al, byte ptr ds:[470h]
	mov	si, ax
	and	si, 0FFh
	mov	cl, byte ptr ds:[475h]
	or	cl, cl
	jne	L_189F
	mov	bx, word ptr ds:[46Eh]
	mov	cl, byte ptr [bx+si]
	add	cl, byte ptr ds:[471h]
L_189F:
	or	ah, ah
	jne	L_18A7
	sub	cl, byte ptr ds:[47Ah]
L_18A7:
	sub	cl, byte ptr ds:[476h]
	mov	byte ptr ds:[46Ch], cl
	mov	cl, byte ptr ds:[474h]
	shl	si, cl
	add	si, word ptr ds:[472h]
	mov	cl, 4
	mov	dh, byte ptr ds:[469h]
	mov	dl, byte ptr ds:[468h]
	mov	ax, dx
	shl	ax, cl
	or	dx, ax
	mov	al, byte ptr ds:[47Bh]
	mov	cl, byte ptr ds:[476h]
	mov	di, word ptr ds:[481h]
	shl	di, 1
	cmp	byte ptr ds:[46Ah], 1
	je	L_1930
	mov	dh, al
L_18DF:
	push	di
	mov	bx, word ptr [si]
	xchg	bh, bl
	shl	bx, cl
	mov	di, word ptr [di+270h]
	mov	ax, word ptr ds:[47Fh]
	shr	ax, 1
	mov	ch, 0Fh
	jae	L_18F5
	not	ch
L_18F5:
	add	di, ax
	mov	ah, byte ptr ds:[46Ch]
L_18FB:
	shl	bx, 1
	jae	L_190B
	mov	al, byte ptr es:[di]
	xor	al, dl
	and	al, ch
	xor	al, dl
	mov	byte ptr es:[di], al
L_190B:
	xor	ch, 0FFh
	js	L_1911
	inc	di
L_1911:
	dec	ah
	jne	L_18FB
	pop	di
	add	di, 2
	add	si, bp
	dec	dh
	jne	L_18DF
L_191F:
	pop	si
	xor	ah, ah
	mov	byte ptr ds:[476h], ah
	mov	al, byte ptr ds:[46Ch]
	add	word ptr ds:[47Fh], ax
	jmp	L_1878
L_1930:
	mov	byte ptr ds:[46Bh], al
L_1933:
	push	di
	mov	bx, word ptr [si]
	xchg	bh, bl
	shl	bx, cl
	mov	di, word ptr [di+270h]
	mov	ax, word ptr ds:[47Fh]
	shr	ax, 1
	mov	ch, 0Fh
	jae	L_1949
	not	ch
L_1949:
	add	di, ax
	mov	ah, byte ptr ds:[46Ch]
L_194F:
	shl	bx, 1
	jae	L_1962
	mov	al, byte ptr es:[di]
	xor	al, dl
	and	al, ch
	xor	al, dl
	mov	byte ptr es:[di], al
	jmp	L_196E
L_1962:
	mov	al, byte ptr es:[di]
	xor	al, dh
	and	al, ch
	xor	al, dh
	mov	byte ptr es:[di], al
L_196E:
	xor	ch, 0FFh
	js	L_1974
	inc	di
L_1974:
	dec	ah
	jne	L_194F
	pop	di
	add	di, 2
	add	si, bp
	dec	byte ptr ds:[46Bh]
	jne	L_1933
	jmp	L_191F

; ----------------------------------------------------------------------------
; tgfx_patch_font (slot 15): patch_font(font, data): copy a font image over font n.
; ----------------------------------------------------------------------------
tgfx_patch_font:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	mov	ax, DATA
	mov	es, ax
	mov	si, word ptr [bp+8]
	mov	di, word ptr [bp+6]
	cmp	di, word ptr es:[490h]
	ja	L_19D1
	shl	di, 1
	je	L_19D1
	mov	di, word ptr es:[di+490h]
	add	di, 490h
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
L_19D1:
	pop	es
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_char_width (slot 4): char_width(font, ch): width of a character (0 if not in the font).
; ----------------------------------------------------------------------------
tgfx_char_width:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	cl, byte ptr [bp+8]
	or	cl, cl
	js	L_1A21
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr ds:[490h]
	ja	L_1A21
	shl	bx, 1
	je	L_1A21
	mov	bx, word ptr [bx+490h]
	add	bx, 490h
	cmp	cl, byte ptr [bx-8]
	jb	L_1A21
	cmp	cl, byte ptr [bx-7]
	ja	L_1A21
	mov	ah, byte ptr [bx-3]
	mov	al, byte ptr [bx-5]
	or	al, al
	jne	L_1A21
	mov	al, cl
	mov	cl, byte ptr [bx-7]
	sub	cl, al
	xor	ch, ch
	add	bx, -9
	sub	bx, cx
	mov	al, byte ptr [bx]
L_1A21:
	add	al, ah
	cbw
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_font_height (slot 10): font_height(font): height of a font's characters.
; ----------------------------------------------------------------------------
tgfx_font_height:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr ds:[490h]
	ja	L_1A4D
	shl	bx, 1
	je	L_1A4D
	mov	bx, word ptr [bx+490h]
	add	bx, 490h
	mov	al, byte ptr [bx-4]
	add	al, byte ptr [bx-2]
L_1A4D:
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_draw_text (slot 20): draw_text(port, x, y, string, ?): draw a string clipped to the port.
; ----------------------------------------------------------------------------
tgfx_draw_text:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	bx, word ptr [bp+0Ch]
	mov	cx, word ptr [bp+8]
	mov	dx, word ptr [bp+0Ah]
	mov	bp, word ptr [bp+6]
	call	far ptr tgfx_text_clip_all
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; tgfx_text_clip_all (slot 42): BP = port, CX = x, DX = y, BX = string (SS): draw text clipped on all sides.
; ----------------------------------------------------------------------------
tgfx_text_clip_all:
	call	text_setup
	call	clip_text_right
	call	clip_text_left
	call	clip_text_vert
	jmp	L_1B55

; ----------------------------------------------------------------------------
; tgfx_text_clip_left (slot 43): As text_clip_all, clipped on the left only.
; ----------------------------------------------------------------------------
tgfx_text_clip_left:
	call	text_setup
	call	clip_text_left
	jmp	L_1B55

; ----------------------------------------------------------------------------
; clip_text_left
; ----------------------------------------------------------------------------
clip_text_left:
	cmp	byte ptr ds:[475h], 0
	je	L_1ABA
	cmp	word ptr [bp+6], 0
	js	L_1AB6
	mov	ax, word ptr ds:[47Fh]
	or	ax, ax
	jns	L_1ABA
	mov	word ptr ds:[47Fh], 0
	neg	ax
	div	byte ptr ds:[475h]
	mov	byte ptr ds:[476h], ah
	inc	al
L_1AA8:
	dec	al
	je	L_1ABA
L_1AAC:
	mov	ah, byte ptr ss:[bx]
	inc	bx
	or	ah, ah
	js	L_1AAC
	jne	L_1AA8
L_1AB6:
	pop	ax
	jmp	L_1B6A
L_1ABA:
	ret

; ----------------------------------------------------------------------------
; tgfx_text_clip_right (slot 45): As text_clip_all, clipped on the right only.
; ----------------------------------------------------------------------------
tgfx_text_clip_right:
	call	text_setup
	call	clip_text_right
	jmp	L_1B55

; ----------------------------------------------------------------------------
; clip_text_right
; ----------------------------------------------------------------------------
clip_text_right:
	cmp	byte ptr ds:[475h], 0
	je	L_1B07
	mov	dx, word ptr ds:[47Fh]
	mov	cx, word ptr [bp+6]
	or	cx, cx
	js	L_1B08
	cmp	dx, cx
	jg	L_1B08
	dec	dx
	xor	ah, ah
	mov	al, byte ptr ds:[475h]
	mov	di, ax
	mov	si, bx
	dec	si
L_1AE5:
	inc	si
	cmp	byte ptr ss:[si], ah
	js	L_1AE5
	je	L_1B07
	add	dx, di
	cmp	dx, cx
	jl	L_1AE5
	sub	dx, cx
	mov	byte ptr ds:[47Ah], dl
	inc	si
	mov	al, byte ptr ss:[si]
	mov	byte ptr ss:[si], ah
	mov	byte ptr ds:[479h], al
	mov	word ptr ds:[477h], si
L_1B07:
	ret
L_1B08:
	pop	ax
	jmp	L_1B6A

; ----------------------------------------------------------------------------
; tgfx_text_clip_vert (slot 46): As text_clip_all, clipped at the top and bottom only.
; ----------------------------------------------------------------------------
tgfx_text_clip_vert:
	call	text_setup
	call	clip_text_vert
	jmp	L_1B55

; ----------------------------------------------------------------------------
; clip_text_vert
; ----------------------------------------------------------------------------
clip_text_vert:
	mov	cx, word ptr [bp+8]
	or	cx, cx
	js	L_1B4E
	mov	ax, word ptr ds:[481h]
	or	ax, ax
	jns	L_1B39
	neg	ax
	sub	word ptr ds:[47Bh], ax
	jbe	L_1B4E
	mov	word ptr ds:[481h], 0
	mul	word ptr ds:[47Dh]
	add	word ptr ds:[472h], ax
L_1B39:
	mov	ax, word ptr ds:[481h]
	cmp	ax, cx
	ja	L_1B4E
	add	ax, word ptr ds:[47Bh]
	dec	ax
	sub	ax, cx
	jbe	L_1B4D
	sub	word ptr ds:[47Bh], ax
L_1B4D:
	ret
L_1B4E:
	pop	ax
	jmp	L_1B6A

; ----------------------------------------------------------------------------
; tgfx_text_noclip (slot 44): As text_clip_all, without clipping.
; ----------------------------------------------------------------------------
tgfx_text_noclip:
	call	text_setup
L_1B55:
	mov	ax, word ptr [bp+2]
	add	word ptr ds:[47Fh], ax
	mov	ax, word ptr [bp+4]
	add	word ptr ds:[481h], ax
	mov	si, bx
	call	far ptr draw_glyphs
L_1B6A:
	mov	bx, word ptr ds:[477h]
	or	bx, bx
	je	L_1B78
	mov	al, byte ptr ds:[479h]
	mov	byte ptr ss:[bx], al
L_1B78:
	mov	ax, word ptr ds:[47Fh]
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
	ASSUME	DS:DATA
	mov	word ptr text_x, cx
	mov	word ptr text_y, dx
	xor	ax, ax
	mov	word ptr cut_ptr, ax
	mov	byte ptr glyph_skip, al
	mov	byte ptr cut_skip, al
	cmp	byte ptr ss:[bx], al
	je	L_1B6A
	mov	di, word ptr [bp+10h]
	cmp	di, word ptr ds:[490h]
	ja	L_1B6A
	shl	di, 1
	je	L_1B6A
	mov	di, word ptr [di+490h]
	add	di, 490h
	mov	word ptr glyph_data, di
	mov	al, byte ptr [di-4]
	test	byte ptr [bp+0Ah], 1
	je	L_1BC9
	add	al, byte ptr [di-2]
L_1BC9:
	cbw
	mov	word ptr text_rows, ax
	mov	ah, byte ptr [di-3]
	mov	byte ptr font_spacing, ah
	mov	al, byte ptr [di-5]
	or	al, al
	je	L_1BDD
	add	al, ah
L_1BDD:
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

; ----------------------------------------------------------------------------
; tgfx_nop13 (slot 13): Slot 13.
; ----------------------------------------------------------------------------
tgfx_nop13:
	retf
CODE	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

; MGRAPHIC.EXE - Covert Action graphics driver for MCGA/VGA (mode 13h, 320x200, 256 colours)
;
; The game loads a graphics driver as an overlay and calls its 51 entry points
; through the far-jump stubs that link_driver_stubs patches from the export
; table at CS:32h (see README "Driver interface"). Most entries take C-style far
; calls with stack arguments; the primitives at slots 37-48 take registers.
;
; Pages are 64000-byte buffers, one byte per pixel; page_seg holds their segments
; (page 0 is the screen). A "port" is a small structure in the caller's data
; segment: page, x0, y0, xmax, ymax, flags, foreground, background, font.
; Images are a word width and height followed by rows of (count, skip, pixels);
; colour 0 is transparent.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh MGRAPHIC
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/MGRAPHIC.hints)

FONT_TABLE	equ	630h	; The game loads the fonts at DATA:630h, right after this driver (drv_data_size)

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:1240h = DATA:0) while DS references, with DS = DATA,
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
; DAC values (R,G,B) for the 16 colours of the last set_palette
dac_pal16	db	48 dup (0)
; Default DAC table (R,G,B, 6 bits each) for colours 0..127
default_dac	db	0,0,0,0,0,2Ah,0,2Ah,0,0,2Ah,2Ah
	db	2Ah,0,0,2Ah,0,2Ah,2Ah,15h,0,2Ah,2Ah,2Ah
	db	15h,15h,15h,15h,15h,3Fh,15h,3Fh,15h,15h,3Fh,3Fh
	db	3Fh,15h,15h,3Fh,15h,3Fh,3Fh,3Fh,15h,3Fh,3Fh,3Fh
	db	0,0,0,0Ah,0Ah,0Ah,15h,15h,15h,1Fh,1Fh,1Fh
	db	2Ah,2Ah,2Ah,35h,35h,35h,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	15h,0,0,1Fh,0Ah,0Ah,2Ah,15h,15h,2Ah,0,0
	db	2Ah,0Ah,0,35h,0Ah,0Ah,35h,15h,0Ah,35h,1Fh,1Fh
	db	3Fh,15h,15h,3Fh,2Ah,2Ah,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	15h,0Ah,0,1Fh,15h,0Ah,2Ah,1Fh,15h,2Ah,15h,0
	db	35h,1Fh,0Ah,35h,2Ah,1Fh,3Fh,2Ah,15h,3Fh,3Fh,3Fh
	db	15h,15h,0,1Fh,1Fh,0Ah,15h,1Fh,0,2Ah,2Ah,15h
	db	35h,35h,1Fh,35h,2Ah,0Ah,3Fh,3Fh,2Ah,3Fh,3Fh,15h
	db	0,15h,0,15h,1Fh,15h,0Ah,1Fh,0Ah,1Fh,2Ah,1Fh
	db	15h,2Ah,15h,1Fh,2Ah,0Ah,0,2Ah,0,0,2Ah,15h
	db	1Fh,35h,1Fh,1Fh,35h,0Ah,0Ah,35h,0Ah,0Ah,35h,1Fh
	db	2Ah,3Fh,2Ah,2Ah,3Fh,15h,15h,3Fh,15h,15h,3Fh,2Ah
	db	0,15h,15h,0Ah,1Fh,1Fh,15h,2Ah,2Ah,0,2Ah,2Ah
	db	1Fh,35h,35h,0Ah,35h,35h,2Ah,3Fh,3Fh,15h,3Fh,3Fh
	db	3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	0,0,15h,0Ah,0Ah,1Fh,15h,15h,2Ah,0,15h,2Ah
	db	0,0,2Ah,15h,0,2Ah,0Ah,0Ah,35h,0Ah,1Fh,35h
	db	1Fh,0Ah,35h,1Fh,1Fh,35h,15h,15h,3Fh,15h,2Ah,3Fh
	db	2Ah,15h,3Fh,2Ah,2Ah,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh,3Fh
	db	15h,0Ah,15h,15h,0,15h,1Fh,15h,1Fh,1Fh,0Ah,1Fh
	db	2Ah,15h,2Ah,2Ah,0,2Ah,35h,1Fh,35h,35h,0Ah,35h
	db	3Fh,15h,3Fh,3Fh,2Ah,3Fh,3Fh,3Fh,3Fh,2Ah,0Ah,15h
	db	2Ah,0,15h,35h,15h,1Fh,35h,0Ah,1Fh,3Fh,15h,2Ah
; Mouse pointer: position of the image, its clipped area and the saved background
ptr_image	dw	0
ptr_x	dw	0
ptr_y	dw	0
ptr_width	dw	0
ptr_height	dw	0
ptr_clip_x	dw	0
ptr_clip_y	dw	0
ptr_clip_w	dw	0
ptr_clip_h	dw	0
ptr_visible	dw	0
ptr_page	dw	0
ptr_save	dw	256 dup (0)
caps_table	db	0,0,1
	db	7 dup (0)
; Offset of each of the 200 rows in a 320-byte-wide page
row_offset	dw	0,140h,280h,3C0h,500h,640h,780h,8C0h
	dw	0A00h,0B40h,0C80h,0DC0h,0F00h,1040h,1180h,12C0h
	dw	1400h,1540h,1680h,17C0h,1900h,1A40h,1B80h,1CC0h
	dw	1E00h,1F40h,2080h,21C0h,2300h,2440h,2580h,26C0h
	dw	2800h,2940h,2A80h,2BC0h,2D00h,2E40h,2F80h,30C0h
	dw	3200h,3340h,3480h,35C0h,3700h,3840h,3980h,3AC0h
	dw	3C00h,3D40h,3E80h,3FC0h,4100h,4240h,4380h,44C0h
	dw	4600h,4740h,4880h,49C0h,4B00h,4C40h,4D80h,4EC0h
	dw	5000h,5140h,5280h,53C0h,5500h,5640h,5780h,58C0h
	dw	5A00h,5B40h,5C80h,5DC0h,5F00h,6040h,6180h,62C0h
	dw	6400h,6540h,6680h,67C0h,6900h,6A40h,6B80h,6CC0h
	dw	6E00h,6F40h,7080h,71C0h,7300h,7440h,7580h,76C0h
	dw	7800h,7940h,7A80h,7BC0h,7D00h,7E40h,7F80h,80C0h
	dw	8200h,8340h,8480h,85C0h,8700h,8840h,8980h,8AC0h
	dw	8C00h,8D40h,8E80h,8FC0h,9100h,9240h,9380h,94C0h
	dw	9600h,9740h,9880h,99C0h,9B00h,9C40h,9D80h,9EC0h
	dw	0A000h,0A140h,0A280h,0A3C0h,0A500h,0A640h,0A780h,0A8C0h
	dw	0AA00h,0AB40h,0AC80h,0ADC0h,0AF00h,0B040h,0B180h,0B2C0h
	dw	0B400h,0B540h,0B680h,0B7C0h,0B900h,0BA40h,0BB80h,0BCC0h
	dw	0BE00h,0BF40h,0C080h,0C1C0h,0C300h,0C440h,0C580h,0C6C0h
	dw	0C800h,0C940h,0CA80h,0CBC0h,0CD00h,0CE40h,0CF80h,0D0C0h
	dw	0D200h,0D340h,0D480h,0D5C0h,0D700h,0D840h,0D980h,0DAC0h
	dw	0DC00h,0DD40h,0DE80h,0DFC0h,0E100h,0E240h,0E380h,0E4C0h
	dw	0E600h,0E740h,0E880h,0E9C0h,0EB00h,0EC40h,0ED80h,0EEC0h
	dw	0F000h,0F140h,0F280h,0F3C0h,0F500h,0F640h,0F780h,0F8C0h
; Segment of each page (0 = the screen at A000h)
page_seg	dw	8 dup (0A000h)
; Drawing state for the primitives (slots 37-48): page, origin, clip, colour, mode
draw_seg	dw	0A000h
draw_x0	dw	0
draw_y0	dw	0
draw_xmax	dw	13Fh
draw_color	db	0
draw_mode	db	0
draw_opcode	db	0,0
msg_no_memory	db	'Out of memory$'
msg_no_mcga	db	'MCGA is not supported on your machine$'
; Line drawing
line_x0	dw	0
line_y0	dw	32h
line_x1	dw	64h
line_y1	dw	0
line_step	dw	0
; Text drawing state
text_fg	db	0
text_bg	db	0
text_opaque	db	0
glyph_width	db	0
width_table	dw	0
font_first	db	0
font_spacing	db	0
glyph_data	dw	0
glyph_shift	db	0
font_fixed_width	db	0
glyph_skip	db	0
cut_ptr	dw	0
cut_char	db	0
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
drv_ident	db	'MGRAPHIC.EXE02-20-89'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	FONT_TABLE		; bytes from DATA to the stack
drv_first_slot	db	0
	db	0
drv_count	dw	51		; number of exports
drv_exports	label	word
	dw	offset mgfx_alloc_page	; slot 0
	dw	offset mgfx_mem_avail	; slot 1
	dw	offset mgfx_get_image	; slot 2
	dw	offset mgfx_recolor_rect	; slot 3
	dw	offset mgfx_char_width	; slot 4
	dw	offset mgfx_clear_page	; slot 5
	dw	offset mgfx_draw_image	; slot 6
	dw	offset mgfx_end_image_grab	; slot 7
	dw	offset mgfx_free_page	; slot 8
	dw	offset mgfx_dissolve_page	; slot 9
	dw	offset mgfx_font_height	; slot 10
	dw	offset mgfx_get_row	; slot 11
	dw	offset mgfx_get_pixel	; slot 12
	dw	offset mgfx_nop13	; slot 13
	dw	offset mgfx_hide_pointer	; slot 14
	dw	offset mgfx_patch_font	; slot 15
	dw	offset mgfx_has_back_buffer	; slot 16
	dw	offset mgfx_begin_image_grab	; slot 17
	dw	offset mgfx_put_row	; slot 18
	dw	offset mgfx_copy_rect	; slot 19
	dw	offset mgfx_draw_text	; slot 20
	dw	offset mgfx_draw_image_scaled	; slot 21
	dw	offset mgfx_screen_off	; slot 22
	dw	offset mgfx_screen_on	; slot 23
	dw	offset mgfx_set_page	; slot 24
	dw	offset mgfx_set_color	; slot 25
	dw	offset mgfx_set_palette	; slot 26
	dw	offset mgfx_set_color_map	; slot 27
	dw	offset mgfx_set_shake	; slot 28
	dw	offset mgfx_show_pointer	; slot 29
	dw	offset mgfx_show_page	; slot 30
	dw	offset mgfx_draw_image_noclip	; slot 31
	dw	offset mgfx_end_image	; slot 32
	dw	offset mgfx_image_add_row	; slot 33
	dw	offset mgfx_begin_image	; slot 34
	dw	offset mgfx_swap_page	; slot 35
	dw	offset mgfx_init_mode	; slot 36
	dw	offset mgfx_put_pixel	; slot 37
	dw	offset mgfx_fill_spans	; slot 38
	dw	offset mgfx_nop39	; slot 39
	dw	offset mgfx_set_draw_color	; slot 40
	dw	offset mgfx_draw_line	; slot 41
	dw	offset mgfx_text_clip_all	; slot 42
	dw	offset mgfx_text_clip_left	; slot 43
	dw	offset mgfx_text_noclip	; slot 44
	dw	offset mgfx_text_clip_right	; slot 45
	dw	offset mgfx_text_clip_vert	; slot 46
	dw	offset mgfx_select_page	; slot 47
	dw	offset mgfx_set_port	; slot 48
	dw	offset mgfx_copy_rows_to_screen	; slot 49
	dw	offset mgfx_shake_tick	; slot 50

; ----------------------------------------------------------------------------
; mgfx_recolor_rect (slot 3)
; recolor_rect(port, x, y, w, h, from, to): within the rectangle, replace colour 'from' by 'to'.
; ----------------------------------------------------------------------------
mgfx_recolor_rect:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bp+6]
	mov	di, word ptr [bp+0Ah]
	add	di, word ptr [si+4]
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	add	di, word ptr [bp+8]
	add	di, word ptr [si+2]
	mov	ah, byte ptr [bp+10h]
	mov	al, byte ptr [bp+12h]
	mov	bx, word ptr [bp+0Ch]
	mov	bp, word ptr [bp+0Eh]
	mov	dx, 140h
	sub	dx, bx
	mov	si, word ptr [si]
	shl	si, 1
	mov	si, word ptr cs:[si+page_seg]
	mov	ds, si
	mov	es, si
L_00D3:
	mov	cx, bx
L_00D5:
	cmp	ah, byte ptr [di]
	jne	L_00E7
	stosb
	loop	L_00D5
L_00DC:
	add	di, dx
	dec	bp
	jne	L_00D3
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
L_00E7:
	inc	di
	loop	L_00D5
	jmp	L_00DC

; ----------------------------------------------------------------------------
; mgfx_set_color (slot 25)
; set_color(index, colour): set DAC register 'index' to default_dac[colour].
; ----------------------------------------------------------------------------
mgfx_set_color:
	mov	bx, sp
	push	es
	mov	ax, DATA
	mov	es, ax
	mov	ax, word ptr [bx+4]
	mov	cx, word ptr [bx+6]
	mov	bx, cx
	add	bx, cx
	add	bx, cx
	mov	dh, byte ptr es:[bx+default_dac]
	mov	ch, byte ptr es:[bx+default_dac+1]
	mov	cl, byte ptr es:[bx+default_dac+2]
	mov	bx, ax
	mov	ax, 1010h
	int	10h
	pop	es
	retf

; ----------------------------------------------------------------------------
; mgfx_set_palette (slot 26)
; set_palette(pal): pal = 17 colour numbers (SS). Load DAC 0..15 from default_dac;
; the 17th entry, if it is one of the 16, becomes the border colour. Turns the screen on.
; ----------------------------------------------------------------------------
mgfx_set_palette:
	mov	bx, sp
	push	si
	push	di
	push	ds
	mov	si, word ptr [bx+4]
	mov	bx, 10h
	mov	al, byte ptr [bx+si]
L_0125:
	dec	bx
	js	L_0133
	cmp	al, byte ptr [bx+si]
	jne	L_0125
	mov	ax, 1001h
	mov	bh, bl
	int	10h
L_0133:
	mov	ax, DATA
	mov	ds, ax
	mov	es, ax
	mov	bx, si
	lea	di, dac_pal16
	xor	ah, ah
	mov	cx, 10h
L_0145:
	mov	al, byte ptr ss:[bx]
	inc	bx
	lea	si, default_dac
	add	si, ax
	add	si, ax
	add	si, ax
	movsb
	movsb
	movsb
	loop	L_0145
	mov	ax, 1012h
	mov	bx, 0
	mov	cx, 10h
	lea	dx, dac_pal16
	int	10h
	call	far ptr mgfx_screen_on
	pop	ds
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; mgfx_set_color_map (slot 27)
; set_color_map: nothing to do in 256 colours.
; ----------------------------------------------------------------------------
mgfx_set_color_map:
	retf

; ----------------------------------------------------------------------------
; load_default_dac
; Load the default DAC table (colours 0..127); called by init_mode.
; ----------------------------------------------------------------------------
load_default_dac:
	mov	ax, DATA
	mov	es, ax
	mov	ax, 1012h
	mov	bx, 0
	mov	cx, 80h
	lea	dx, default_dac
	int	10h
	call	far ptr mgfx_screen_on
	retf
; Opcodes patched into the pixel/line loops: mov, and, or, xor (draw modes 0-3)
draw_op_table	db	88h,20h,8,30h

; ----------------------------------------------------------------------------
; mgfx_set_draw_color (slot 40)
; AL = colour, AH = mode (0 copy, 1 and, 2 or, 3 xor) for the primitives.
; ----------------------------------------------------------------------------
mgfx_set_draw_color:
	mov	byte ptr cs:draw_color, al
	mov	al, ah
	and	al, 3
	mov	byte ptr cs:draw_mode, al
	lea	bx, draw_op_table
	xlat	byte ptr cs:[bx]
	mov	byte ptr cs:draw_opcode, al
	retf

; ----------------------------------------------------------------------------
; mgfx_nop39 (slot 39)
; Slot 39: nothing to do on MCGA.
; ----------------------------------------------------------------------------
mgfx_nop39:
	retf
	db	0

; ----------------------------------------------------------------------------
; mgfx_get_pixel (slot 12)
; get_pixel(page, x, y): colour of a pixel.
; ----------------------------------------------------------------------------
mgfx_get_pixel:
	mov	bx, sp
	mov	cx, word ptr [bx+6]
	mov	dx, word ptr [bx+8]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	mov	bx, dx
	shl	bx, 1
	mov	bx, word ptr cs:[bx+row_offset]
	add	bx, cx
	xor	ah, ah
	mov	al, byte ptr es:[bx]
	retf

; ----------------------------------------------------------------------------
; mgfx_get_row (slot 11)
; get_row(buf, page, y, x, n): copy n pixels of a row to DS:buf.
; ----------------------------------------------------------------------------
mgfx_get_row:
	mov	bx, sp
	push	si
	push	di
	push	ds
	mov	di, word ptr [bx+4]
	mov	ax, ds
	mov	es, ax
	mov	si, word ptr [bx+8]
	shl	si, 1
	mov	si, word ptr cs:[si+row_offset]
	add	si, word ptr [bx+0Ah]
	mov	cx, word ptr [bx+0Ch]
	mov	bx, word ptr [bx+6]
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
	rep	movsb
	pop	ds
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; mgfx_put_row (slot 18)
; put_row(buf, page, y, x, n): copy n pixels (rounded up to a word) from DS:buf to a row.
; ----------------------------------------------------------------------------
mgfx_put_row:
	mov	bx, sp
	push	si
	push	di
	mov	si, word ptr [bx+4]
	mov	di, word ptr [bx+8]
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	add	di, word ptr [bx+0Ah]
	mov	cx, word ptr [bx+0Ch]
	inc	cx
	shr	cx, 1
	mov	bx, word ptr [bx+6]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	rep	movsw
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; mgfx_hide_pointer (slot 14)
; hide_pointer(): restore the background under the mouse pointer.
; ----------------------------------------------------------------------------
mgfx_hide_pointer:
	call	restore_ptr_bg
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	word ptr ptr_visible, 0
	pop	ds
	retf

; ----------------------------------------------------------------------------
; restore_ptr_bg
; Put the background saved under the pointer back on the screen.
; ----------------------------------------------------------------------------
restore_ptr_bg:
	push	si
	push	di
	push	ds
	push	es
	mov	ax, DATA
	mov	ds, ax
	cmp	word ptr ptr_visible, 0
	je	L_026D
	lea	si, ptr_save
	mov	di, word ptr ptr_clip_y
	shl	di, 1
	mov	di, word ptr [di+row_offset]
	add	di, word ptr ptr_clip_x
	mov	es, word ptr cs:page_seg
	mov	ax, word ptr ptr_clip_w
	mov	bx, word ptr ptr_clip_h
	mov	dx, 140h
	sub	dx, ax
L_0264:
	mov	cx, ax
	rep	movsb
	add	di, dx
	dec	bx
	jne	L_0264
L_026D:
	pop	es
	pop	ds
	pop	di
	pop	si
	ret

; ----------------------------------------------------------------------------
; mgfx_show_pointer (slot 29)
; show_pointer(x, y, image): clip the pointer image (at most 512 pixels are saved),
; save the screen under it and draw it.
; ----------------------------------------------------------------------------
mgfx_show_pointer:
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
	je	L_0306
	or	ax, ax
	jns	L_02A2
	neg	ax
	sub	bx, ax
	jbe	L_0306
	xor	ax, ax
L_02A2:
	mov	cx, 140h
	sub	cx, ax
	jbe	L_0306
	cmp	bx, cx
	jbe	L_02AF
	mov	bx, cx
L_02AF:
	mov	word ptr ptr_clip_w, bx
	mov	word ptr ptr_clip_x, ax
	mov	ax, 200h
	cwd
	div	bx
	mov	dx, ax
	mov	ax, word ptr [bp+8]
	mov	word ptr ptr_y, ax
	mov	bx, word ptr es:[2]
	mov	word ptr ptr_height, bx
	or	bx, bx
	je	L_0306
	or	ax, ax
	jns	L_02DD
	neg	ax
	sub	bx, ax
	jbe	L_0306
	xor	ax, ax
L_02DD:
	mov	cx, 0C8h
	sub	cx, ax
	jbe	L_0306
	cmp	bx, cx
	jbe	L_02EA
	mov	bx, cx
L_02EA:
	cmp	bx, dx
	jbe	L_02F0
	mov	bx, dx
L_02F0:
	mov	word ptr ptr_clip_h, bx
	mov	word ptr ptr_clip_y, ax
	mov	word ptr ptr_visible, 1
	mov	ax, 0
	call	save_ptr_bg
L_0303:
	pop	ds
	pop	bp
	retf
L_0306:
	mov	word ptr ptr_visible, 0
	jmp	L_0303

; ----------------------------------------------------------------------------
; save_ptr_bg
; AX = page. Save the background under the pointer from that page,
; then draw the pointer image there (through draw_image).
; ----------------------------------------------------------------------------
save_ptr_bg:
	push	si
	push	di
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	word ptr ptr_page, ax
	cmp	word ptr ptr_visible, 0
	je	L_0382
	mov	si, word ptr ptr_clip_y
	shl	si, 1
	mov	si, word ptr [si+row_offset]
	add	si, word ptr ptr_clip_x
	mov	bx, ax
	shl	bx, 1
	mov	cx, word ptr cs:[bx+page_seg]
	lea	di, ptr_save
	mov	es, dx
	mov	ax, word ptr ptr_clip_w
	mov	bx, word ptr ptr_clip_h
	mov	dx, 140h
	sub	dx, ax
	mov	ds, cx
L_034B:
	mov	cx, ax
	rep	movsb
	add	si, dx
	dec	bx
	jne	L_034B
	mov	dx, DATA
	mov	ds, dx
	mov	dx, 0C8h
	dec	dx
	push	dx
	mov	dx, 140h
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
	call	far ptr mgfx_draw_image
	add	sp, 12h
L_0382:
	pop	es
	pop	di
	pop	si
	ret

; ----------------------------------------------------------------------------
; mgfx_fill_spans (slot 38)
; AX = first row, CX = last row, BX = span table (left edges, right edges at +1B8h):
; fill each row's span in draw_seg with draw_color.
; ----------------------------------------------------------------------------
mgfx_fill_spans:
	or	ax, ax
	js	L_03D8
	push	es
	mov	es, word ptr cs:draw_seg
	mov	si, ax
	shl	si, 1
	mov	dx, cx
	shl	dx, 1
	mov	al, byte ptr cs:draw_color
	mov	ah, al
L_039E:
	mov	bp, word ptr [bx+si]
	mov	cx, word ptr [bx+si+1B8h]
	sub	cx, bp
	jb	L_03D0
	ja	L_03B5
	or	bp, bp
	je	L_03D0
	cmp	bp, word ptr cs:draw_xmax
	je	L_03D0
L_03B5:
	inc	cx
	mov	di, word ptr cs:[si+row_offset]
	add	di, bp
	test	di, 1
	je	L_03C7
	stosb
	dec	cx
	je	L_03D0
L_03C7:
	shr	cx, 1
	je	L_03CD
	rep	stosw
L_03CD:
	jae	L_03D0
	stosb
L_03D0:
	add	si, 2
	cmp	si, dx
	jbe	L_039E
	pop	es
L_03D8:
	retf
	db	0

; ----------------------------------------------------------------------------
; mgfx_has_back_buffer (slot 16)
; has_back_buffer(n): word from caps_table.
; ----------------------------------------------------------------------------
mgfx_has_back_buffer:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	mov	ax, word ptr cs:[bx+caps_table]
	retf

; ----------------------------------------------------------------------------
; mgfx_set_port (slot 48)
; BX = port (page, x0, y0, xmax): set draw_seg and the origin for the primitives.
; ----------------------------------------------------------------------------
mgfx_set_port:
	mov	ax, word ptr [bx+2]
	mov	word ptr cs:draw_x0, ax
	mov	ax, word ptr [bx+4]
	mov	word ptr cs:draw_y0, ax
	mov	ax, word ptr [bx+6]
	mov	word ptr cs:draw_xmax, ax
	mov	ax, word ptr [bx]

; ----------------------------------------------------------------------------
; mgfx_select_page (slot 47)
; AX = page: draw_seg = page_seg[page].
; ----------------------------------------------------------------------------
mgfx_select_page:
	xchg	bx, ax
	shl	bx, 1
	mov	bx, word ptr cs:[bx+page_seg]
	xchg	bx, ax
	mov	word ptr cs:draw_seg, ax
	retf

; ----------------------------------------------------------------------------
; mgfx_mem_avail (slot 1)
; mem_avail(): largest free DOS block, in paragraphs.
; ----------------------------------------------------------------------------
mgfx_mem_avail:
	mov	ah, 48h
	mov	bx, 0FFFFh
	int	21h
	mov	ax, bx
	retf

; ----------------------------------------------------------------------------
; mgfx_set_page (slot 24)
; set_page(n, seg): page_seg[n] = seg.
; ----------------------------------------------------------------------------
mgfx_set_page:
	mov	bx, sp
	mov	ax, word ptr [bx+6]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	word ptr cs:[bx+page_seg], ax
	retf

; ----------------------------------------------------------------------------
; mgfx_alloc_page (slot 0)
; alloc_page(n): page 0 is the screen; otherwise allocate 64000 bytes from DOS (0 if none).
; ----------------------------------------------------------------------------
mgfx_alloc_page:
	mov	bx, sp
	cmp	word ptr [bx+4], 0
	jne	L_0431
	mov	ax, word ptr cs:page_seg
	retf
L_0431:
	mov	ah, 48h
	mov	bx, 0FA0h
	int	21h
	jae	L_043C
	xor	ax, ax
L_043C:
	retf

; ----------------------------------------------------------------------------
; out_of_memory
; Not referenced: print "Out of memory" and exit.
; ----------------------------------------------------------------------------
out_of_memory:
	mov	dx, offset msg_no_memory
	jmp	fatal_exit

; ----------------------------------------------------------------------------
; mgfx_free_page (slot 8)
; free_page(n): give page n's memory back to DOS (not page 0).
; ----------------------------------------------------------------------------
mgfx_free_page:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	or	bx, bx
	je	L_045B
	shl	bx, 1
	mov	ax, word ptr cs:[bx+page_seg]
	push	es
	mov	es, ax
	mov	ah, 49h
	int	21h
	pop	es
L_045B:
	retf

; ----------------------------------------------------------------------------
; mgfx_init_mode (slot 36)
; init_mode(flags): set mode 13h (flags bit 7: keep the screen contents) and load
; the default DAC; exits to DOS with a message if the mode can't be set.
; ----------------------------------------------------------------------------
mgfx_init_mode:
	mov	bx, sp
	mov	ax, word ptr [bx+4]
	and	ax, 80h
	or	ax, 13h
	mov	bl, al
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, bl
	jne	L_0479
	call	far ptr load_default_dac
	retf
L_0479:
	mov	dx, offset msg_no_mcga
fatal_exit:
	mov	ax, DATA
	mov	ds, ax
	mov	ax, 3
	int	10h
	mov	ah, 9
	int	21h
	mov	ax, 4C00h
	int	21h

; ----------------------------------------------------------------------------
; mgfx_screen_off (slot 22)
; Blank the display (wait for vertical retrace, set the sequencer screen-off bit).
; ----------------------------------------------------------------------------
mgfx_screen_off:
	mov	dx, 3DAh
L_0492:
	in	al, dx
	test	al, 8
	je	L_0492
	mov	dx, 3D8h
	mov	al, 2
	out	dx, al
	mov	dx, 3C4h
	mov	al, 1
	out	dx, al
	inc	dx
	in	al, dx
	or	al, 20h
	out	dx, al
	retf

; ----------------------------------------------------------------------------
; mgfx_screen_on (slot 23)
; Turn the display back on.
; ----------------------------------------------------------------------------
mgfx_screen_on:
	mov	dx, 3DAh
L_04AC:
	in	al, dx
	test	al, 8
	je	L_04AC
	mov	dx, 3D8h
	mov	al, 0Ah
	out	dx, al
	mov	dx, 3C4h
	mov	al, 1
	out	dx, al
	inc	dx
	in	al, dx
	and	al, 0DFh
	out	dx, al
	retf
	db	0

; ----------------------------------------------------------------------------
; mgfx_put_pixel (slot 37)
; AX = x, BX = y: plot a pixel with draw_color/draw_mode.
; ----------------------------------------------------------------------------
mgfx_put_pixel:
	push	ds
	push	es
	mov	di, DATA
	mov	ds, di
	mov	es, word ptr cs:draw_seg
	add	ax, word ptr cs:draw_x0
	add	bx, word ptr cs:draw_y0
	mov	word ptr line_x0, ax
	mov	word ptr line_y0, bx
L_04E1:
	call	pixel_addr
	mov	byte ptr cs:pset_op, ah
pset_op	equ	byte ptr $+1
	mov	byte ptr es:[di], al
	pop	es
	pop	ds
	retf

; ----------------------------------------------------------------------------
; pixel_addr
; DI = draw_seg offset of (line_x0, line_y0); AL = colour, AH = opcode.
; ----------------------------------------------------------------------------
pixel_addr:
	mov	al, byte ptr cs:draw_color
	mov	ah, byte ptr cs:draw_opcode
	mov	di, word ptr line_y0
	shl	di, 1
	mov	di, word ptr [di+row_offset]
	add	di, word ptr line_x0
	ret

; ----------------------------------------------------------------------------
; mgfx_draw_line (slot 41)
; AX,BX - CX,DX: draw a line with draw_color/draw_mode (Bresenham).
; ----------------------------------------------------------------------------
mgfx_draw_line:
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
	jbe	L_052C
	xchg	cx, ax
	xchg	bx, dx
L_052C:
	mov	word ptr line_x0, ax
	mov	word ptr line_y0, bx
	mov	word ptr line_x1, cx
	mov	word ptr line_y1, dx
	jne	L_0541
	cmp	bx, dx
	je	L_04E1
L_0541:
	mov	si, 1
	mov	bp, 140h
	sub	cx, ax
	sub	dx, bx
	jns	L_0551
	neg	bp
	neg	dx
L_0551:
	mov	bx, si
	add	bx, bp
	cmp	cx, dx
	jae	L_055D
	xchg	si, bp
	xchg	cx, dx
L_055D:
	je	L_0594
	or	cx, cx
	mov	bx, bp
	je	L_0594
	or	dx, dx
	mov	bx, si
	je	L_0594
	call	pixel_addr
	mov	byte ptr cs:line_op_diag, ah
	mov	word ptr line_step, bp
	mov	bp, cx
	inc	bp
	shr	bp, 1
	neg	bp
	mov	bx, cx
L_0580:
line_op_diag	equ	byte ptr $+1
	mov	byte ptr es:[di], al
	dec	cx
	js	L_05A6
	add	di, si
	add	bp, dx
	js	L_0580
	sub	bp, bx
	add	di, word ptr line_step
	jmp	L_0580
L_0594:
	call	pixel_addr
	mov	byte ptr cs:line_op_axis, ah
	or	cx, dx
	inc	cx
L_059F:
line_op_axis	equ	byte ptr $+1
	mov	byte ptr es:[di], al
	add	di, bx
	loop	L_059F
L_05A6:
	pop	es
	pop	ds
	retf
	db	0

; ----------------------------------------------------------------------------
; mgfx_show_page (slot 30)
; show_page(n): copy page n to the screen (with the mouse pointer drawn into it).
; ----------------------------------------------------------------------------
mgfx_show_page:
	mov	bx, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bx+4]
	or	si, si
	je	L_05D1
	mov	ax, si
	call	save_ptr_bg
	shl	si, 1
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:page_seg
	xor	si, si
	xor	di, di
	mov	cx, 7D00h
	rep	movsw
L_05D1:
	pop	es
	pop	ds
	pop	di
	pop	si
	retf
dissolve_delay	dw	0
L_05D8:
	jmp	L_0671

; ----------------------------------------------------------------------------
; mgfx_dissolve_page (slot 9)
; dissolve_page(n): copy page n to the screen pixel by pixel in pseudo-random order
; (LFSR, polynomial B400h). The first call times a frame to calibrate dissolve_delay.
; ----------------------------------------------------------------------------
mgfx_dissolve_page:
	mov	bx, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bx+4]
	shl	si, 1
	je	L_05D8
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:page_seg
	mov	bx, word ptr cs:dissolve_delay
	or	bx, bx
	jne	L_0636
L_05FB:
	inc	bx
L_05FC:
	mov	dx, 3DAh
	in	al, dx
	test	al, 8
	je	L_05FC
L_0604:
	in	al, dx
	test	al, 8
	jne	L_0604
	mov	si, 1
	xor	cx, cx
L_060E:
	shr	si, 1
	jae	L_0616
	xor	si, 0B400h
L_0616:
	cmp	si, 0
	jb	L_060E
	dec	si
	mov	di, 0FFFFh
	movsb
	mov	ax, bx
L_0622:
	dec	ax
	jne	L_0622
	inc	cx
	in	al, dx
	test	al, 8
	je	L_060E
	cmp	cx, 215h
	ja	L_05FB
	mov	word ptr cs:dissolve_delay, bx
L_0636:
	mov	si, 1
	mov	cx, 0FA00h
	cmp	bx, 1
	je	L_065D
L_0641:
	shr	si, 1
	jae	L_0649
	xor	si, 0B400h
L_0649:
	cmp	si, 0FA00h
	ja	L_0641
	dec	si
	mov	di, si
	movsb
	mov	ax, bx
L_0655:
	dec	ax
	jne	L_0655
	loop	L_0641
	jmp	L_0671
L_065D:
	shr	si, 1
	jae	L_0665
	xor	si, 0B400h
L_0665:
	cmp	si, 0FA00h
	ja	L_065D
	dec	si
	mov	di, si
	movsb
	loop	L_065D
L_0671:
	pop	es
	pop	ds
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; mgfx_swap_page (slot 35)
; swap_page(n): exchange the contents of page n and the screen.
; ----------------------------------------------------------------------------
mgfx_swap_page:
	mov	bx, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bx+4]
	shl	si, 1
	je	L_069D
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:page_seg
	xor	si, si
	xor	di, di
	mov	cx, 7D00h
L_0694:
	lodsw
	mov	bx, word ptr es:[di]
	mov	word ptr [di], bx
	stosw
	loop	L_0694
L_069D:
	pop	es
	pop	ds
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; mgfx_clear_page (slot 5)
; clear_page(page, colour): fill a whole page.
; ----------------------------------------------------------------------------
mgfx_clear_page:
	mov	bx, sp
	push	di
	push	es
	mov	al, byte ptr [bx+6]
	mov	ah, al
	mov	di, word ptr [bx+4]
	shl	di, 1
	mov	es, word ptr cs:[di+page_seg]
	xor	di, di
	mov	cx, 7D00h
	rep	stosw
	pop	es
	pop	di
	retf
	db	0

; ----------------------------------------------------------------------------
; mgfx_copy_rect (slot 19)
; copy_rect(src_port, x, y, w, h, dst_port, x, y): copy a rectangle between pages.
; ----------------------------------------------------------------------------
mgfx_copy_rect:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bp+6]
	mov	di, word ptr [bp+10h]
	mov	ax, word ptr [si+2]
	mov	bx, word ptr [si+4]
	mov	cx, word ptr [di+2]
	mov	dx, word ptr [di+4]
	add	ax, word ptr [bp+8]
	add	bx, word ptr [bp+0Ah]
	add	cx, word ptr [bp+12h]
	add	dx, word ptr [bp+14h]
	mov	si, word ptr [si]
	mov	di, word ptr [di]
	shl	si, 1
	shl	di, 1
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:[di+page_seg]
	shl	bx, 1
	mov	si, word ptr cs:[bx+row_offset]
	add	si, ax
	mov	bx, dx
	shl	bx, 1
	mov	di, word ptr cs:[bx+row_offset]
	add	di, cx
	mov	ax, word ptr [bp+0Ch]
	mov	bx, word ptr [bp+0Eh]
	or	ax, ax
	je	L_0729
	or	bx, bx
	je	L_0729
	mov	dx, 140h
	sub	dx, ax
L_071E:
	mov	cx, ax
	rep	movsb
	add	si, dx
	add	di, dx
	dec	bx
	jne	L_071E
L_0729:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
	db	0

; ----------------------------------------------------------------------------
; mgfx_copy_rows_to_screen (slot 49)
; AX = first row, CX = last row, BX = span table (left, right at +190h), SI = source
; page, DI = destination page: copy each row's span.
; ----------------------------------------------------------------------------
mgfx_copy_rows_to_screen:
	or	ax, ax
	js	L_0780
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
L_074E:
	mov	si, bx
	mov	ax, word ptr [bp+si]
	mov	cx, word ptr [bp+si+190h]
	sub	cx, ax
	jb	L_0777
	inc	cx
	mov	di, word ptr cs:[si+row_offset]
	add	di, ax
	mov	si, di
	test	di, 1
	je	L_076E
	movsb
	dec	cx
	je	L_0777
L_076E:
	shr	cx, 1
	je	L_0774
	rep	movsw
L_0774:
	jae	L_0777
	movsb
L_0777:
	add	bx, 2
	cmp	bx, dx
	jbe	L_074E
	pop	es
	pop	ds
L_0780:
	retf
	db	0
; Image building (begin_image_grab .. end_image_grab): a far pointer into the
; DOS block being filled, the block's limits and per-row counters
img_ptr	dw	0
img_seg	dw	0
img_block	dw	0
img_block_end	dw	0
img_limit	dw	0
img_skip	dw	0
img_trail	dw	0
img_len	dw	0
img_rows	dw	0
img_width	dw	0
; Image blitting: clipped size, scaling and the result rectangle
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
blit_param	db	0
	EVEN
row_buffer	dw	160 dup (0)

; ----------------------------------------------------------------------------
; mgfx_begin_image_grab (slot 17)
; begin_image_grab(): allocate the largest free DOS block to collect images in.
; ----------------------------------------------------------------------------
mgfx_begin_image_grab:
	call	far ptr mgfx_mem_avail
	mov	bx, ax
	or	bx, bx
	je	L_0913
	mov	ah, 48h
	int	21h
	jae	L_0917
L_0913:
	xor	ax, ax
	xor	bx, bx
L_0917:
	add	bx, ax
	mov	word ptr cs:img_ptr, 0
	mov	word ptr cs:img_seg, ax
	mov	word ptr cs:img_block, ax
	mov	word ptr cs:img_block_end, bx
	retf

; ----------------------------------------------------------------------------
; mgfx_end_image_grab (slot 7)
; end_image_grab(): shrink the block to what was used (free it if empty); returns its segment.
; ----------------------------------------------------------------------------
mgfx_end_image_grab:
	mov	ax, word ptr cs:img_block
	or	ax, ax
	je	L_094E
	mov	bx, word ptr cs:img_seg
	sub	bx, ax
	mov	es, ax
	mov	ah, 4Ah
	or	bx, bx
	jne	L_0947
	mov	ah, 49h
L_0947:
	int	21h
	jb	L_094E
	mov	ax, es
	retf
L_094E:
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; mgfx_begin_image (slot 34)
; begin_image(w, h): start an image at img_ptr; returns its segment (0 if out of room).
; ----------------------------------------------------------------------------
mgfx_begin_image:
	mov	ax, word ptr cs:img_block_end
	sub	ax, word ptr cs:img_seg
	jbe	L_0991
	cmp	ax, 1000h
	jb	L_0964
	mov	ax, 0FFFh
L_0964:
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	word ptr cs:img_limit, ax
	mov	bx, sp
	push	di
	les	di, dword ptr cs:img_ptr
	mov	ax, word ptr [bx+4]
	stosw
	mov	word ptr cs:img_width, ax
	mov	ax, word ptr [bx+6]
	stosw
	mov	word ptr cs:img_rows, ax
	mov	word ptr cs:img_ptr, di
	mov	ax, es
	pop	di
	retf
L_0991:
	xor	ax, ax
	mov	word ptr cs:img_ptr, ax
	mov	word ptr cs:img_seg, ax
	retf

; ----------------------------------------------------------------------------
; mgfx_end_image (slot 32)
; end_image(): close the image, paragraph-align img_ptr; returns the image's segment.
; ----------------------------------------------------------------------------
mgfx_end_image:
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
; mgfx_image_add_row (slot 33)
; image_add_row(row): append a row (count, leading skip, pixels without the trailing zeros).
; ----------------------------------------------------------------------------
mgfx_image_add_row:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	si, word ptr [bp+6]
	les	di, dword ptr cs:img_ptr
	mov	ax, es
	or	ax, ax
	jne	L_09CF
	jmp	L_0A57
L_09CF:
	mov	ax, word ptr cs:img_width
	add	ax, 4
	add	ax, di
	cmp	ax, word ptr cs:img_limit
	jbe	L_09ED
	dec	word ptr es:[2]
	xor	ax, ax
	mov	word ptr cs:img_block_end, ax
	jmp	L_0A57
L_09ED:
	xor	ax, ax
	mov	word ptr cs:img_skip, ax
	mov	word ptr cs:img_trail, ax
	mov	word ptr cs:img_len, ax
	mov	bp, di
	stosw
	stosw
	mov	cx, word ptr cs:img_width
L_0A04:
	lodsb
	or	al, al
	je	L_0A13
	mov	word ptr cs:img_trail, 0
	jmp	L_0A2A
L_0A13:
	cmp	word ptr cs:img_len, 0
	jne	L_0A25
	inc	word ptr cs:img_skip
	loop	L_0A04
	jmp	L_0A32
L_0A25:
	inc	word ptr cs:img_trail
L_0A2A:
	inc	word ptr cs:img_len
	stosb
	loop	L_0A04
L_0A32:
	mov	ax, word ptr cs:img_len
	mov	bx, word ptr cs:img_skip
	mov	cx, word ptr cs:img_trail
	or	cx, cx
	je	L_0A48
	sub	ax, cx
	sub	di, cx
L_0A48:
	mov	word ptr es:[bp], ax
	mov	word ptr es:[bp+2], bx
	mov	word ptr cs:img_ptr, di
	mov	ax, es
L_0A57:
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_get_image (slot 2)
; get_image(page, x, y, w, h): grab a block of a page as an image (negative page: ?).
; ----------------------------------------------------------------------------
mgfx_get_image:
	push	bp
	mov	bp, sp
	push	si
	push	ds
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	call	far ptr mgfx_begin_image
	add	sp, 4
	or	ax, ax
	je	L_0AB6
	cmp	word ptr cs:img_rows, 0
	je	L_0AB6
	cmp	word ptr cs:img_width, 0
	je	L_0AB6
	mov	si, word ptr [bp+0Ah]
	shl	si, 1
	mov	si, word ptr cs:[si+row_offset]
	add	si, word ptr [bp+8]
	mov	ax, word ptr [bp+6]
	cwd
	xor	ax, dx
	sub	ax, dx
	mov	bp, dx
	mov	bx, ax
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
L_0AA2:
	push	si
	call	far ptr mgfx_image_add_row
	add	sp, 2
	add	si, 140h
	dec	word ptr cs:img_rows
	jne	L_0AA2
L_0AB6:
	call	far ptr mgfx_end_image
	pop	ds
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_draw_image_scaled (slot 21)
; draw_image_scaled(port, x, y, w, h, image, param): draw an image scaled to |w| x |h|,
; mirrored when w or h is negative. Returns a far pointer to the drawn rectangle.
; ----------------------------------------------------------------------------
mgfx_draw_image_scaled:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	mov	al, byte ptr [bp+12h]
	mov	byte ptr cs:blit_param, al
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
	je	L_0B0B
	call	clip_image
	jb	L_0B0B
	call	far ptr blit_image_scaled
L_0B0B:
	mov	ax, offset blit_rect
	mov	dx, cs
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_draw_image (slot 6)
; draw_image(port, x, y, image): draw an image clipped to the port (0 = transparent).
; Returns a far pointer to the drawn rectangle (x, y, w, h).
; ----------------------------------------------------------------------------
mgfx_draw_image:
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
	je	L_0B45
	call	clip_image
	jb	L_0B45
	call	far ptr blit_image
L_0B45:
	mov	ax, offset blit_rect
	mov	dx, cs
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; clip_image
; Clip the image (DX = x, DI = y) to the port at SS:BP; CF set if nothing is visible.
; Fills clip_* and blit_rect.
; ----------------------------------------------------------------------------
clip_image:
	or	di, di
	jns	L_0B62
	mov	ax, di
	neg	ax
	cmp	ax, word ptr cs:dst_height
	jae	L_0BAE
	mov	word ptr cs:clip_top, ax
L_0B62:
	mov	ax, di
	add	ax, word ptr cs:dst_height
	dec	ax
	mov	bx, word ptr [bp+8]
	or	bx, bx
	js	L_0BAE
	cmp	di, bx
	jg	L_0BAE
	sub	ax, bx
	jle	L_0B7D
	mov	word ptr cs:clip_bottom, ax
L_0B7D:
	or	dx, dx
	jns	L_0B90
	mov	ax, dx
	neg	ax
	cmp	ax, word ptr cs:dst_width
	jae	L_0BAE
	mov	word ptr cs:clip_left, ax
L_0B90:
	mov	ax, dx
	add	ax, word ptr cs:dst_width
	dec	ax
	mov	bx, word ptr [bp+6]
	or	bx, bx
	js	L_0BAE
	cmp	dx, bx
	jg	L_0BAE
	sub	ax, bx
	jle	L_0BB0
	mov	word ptr cs:clip_right, ax
	jmp	L_0BB0
L_0BAE:
	stc
	ret
L_0BB0:
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
; Clear clip_* and blit_rect; ZF set if the image at DS:0 is empty (0 wide or high).
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
	je	L_0C1E
	mov	ax, word ptr ds:[0]
	or	ax, ax
	je	L_0C1E
	mov	ax, word ptr ds:[2]
	or	ax, ax
L_0C1E:
	ret

; ----------------------------------------------------------------------------
; mgfx_draw_image_noclip (slot 31)
; draw_image_noclip(port, x, y, image): draw an image without clipping.
; ----------------------------------------------------------------------------
mgfx_draw_image_noclip:
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
	je	L_0C3D
	call	far ptr blit_image
L_0C3D:
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; blit_image
; Draw the image at DS:SI (rows: length, skip, pixels; 0 = transparent) at
; DX, DI in the port at SS:BP, honouring clip_*.
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
	shl	di, 1
	mov	bp, word ptr cs:[di+row_offset]
	add	bp, dx
	lodsw
	sub	ax, word ptr cs:clip_right
	jle	L_0CCF
	mov	word ptr cs:blit_cols, ax
	lodsw
	sub	ax, word ptr cs:clip_top
	sub	ax, word ptr cs:clip_bottom
	jle	L_0CCF
	mov	word ptr cs:blit_rows, ax
	mov	cx, word ptr cs:clip_top
	jcxz	L_0C8D
L_0C86:
	add	si, word ptr [si]
	add	si, 4
	loop	L_0C86
L_0C8D:
	lodsw
	mov	cx, ax
	mov	dx, ax
	lodsw
	jcxz	L_0CC2
	mov	bx, ax
	add	cx, ax
	sub	ax, word ptr cs:clip_left
	ja	L_0CA6
	sub	si, ax
	sub	bx, ax
	add	dx, ax
L_0CA6:
	mov	ax, word ptr cs:blit_cols
	cmp	ax, cx
	ja	L_0CB0
	mov	cx, ax
L_0CB0:
	sub	cx, bx
	jbe	L_0CC2
	mov	di, bp
	add	di, bx
	sub	dx, cx
L_0CBA:
	lodsb
	or	al, al
	je	L_0CD2
	stosb
	loop	L_0CBA
L_0CC2:
	add	bp, 140h
	add	si, dx
	dec	word ptr cs:blit_rows
	jne	L_0C8D
L_0CCF:
	pop	es
	pop	bp
	retf
L_0CD2:
	inc	di
	loop	L_0CBA
	jmp	L_0CC2
L_0CD7:
	jmp	L_0DC4

; ----------------------------------------------------------------------------
; blit_image_scaled
; As blit_image, scaled to dst_width x dst_height and mirrored by flip_x/flip_y.
; Patches scale_dir (cld/std) and scale_skip (inc/dec di).
; ----------------------------------------------------------------------------
blit_image_scaled:
	push	bp
	push	es
	add	dx, word ptr [bp+2]
	add	di, word ptr [bp+4]
	mov	bx, word ptr [bp]
	shl	bx, 1
	mov	ax, word ptr cs:[bx+page_seg]
	mov	word ptr cs:dst_seg, ax
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
	jle	L_0CD7
	mov	word ptr blit_cols, ax
	mov	ax, word ptr dst_height
	sub	ax, word ptr clip_top
	sub	ax, word ptr clip_bottom
	jle	L_0CD7
	mov	word ptr blit_rows, ax
	mov	ax, 140h
	mov	word ptr row_step, ax
	mov	cx, word ptr clip_top
	add	di, cx
	cmp	word ptr flip_y, 0
	je	L_0D46
	neg	word ptr row_step
	mov	cx, word ptr clip_bottom
	add	di, word ptr blit_rows
	dec	di
L_0D46:
	mov	ax, word ptr dst_height
	inc	ax
	shr	ax, 1
	neg	ax
L_0D4E:
	dec	cx
	js	L_0D65
	add	ax, word ptr src_height
	js	L_0D4E
L_0D57:
	add	si, word ptr es:[si]
	add	si, 4
	sub	ax, word ptr dst_height
	js	L_0D4E
	jmp	L_0D57
L_0D65:
	mov	word ptr step_y, ax
	mov	cx, word ptr clip_left
	add	dx, cx
	mov	byte ptr scale_dir, 0FCh
	mov	byte ptr scale_skip, 47h
	cmp	word ptr flip_x, 0
	je	L_0D92
	mov	byte ptr scale_dir, 0FDh
	mov	byte ptr scale_skip, 4Fh
	mov	cx, word ptr clip_right
	add	dx, word ptr blit_cols
	dec	dx
L_0D92:
	mov	ax, word ptr dst_width
	inc	ax
	shr	ax, 1
	neg	ax
	xor	bx, bx
L_0D9C:
	dec	cx
	js	L_0DAE
	add	ax, word ptr src_width
	js	L_0D9C
L_0DA5:
	inc	bx
	sub	ax, word ptr dst_width
	js	L_0D9C
	jmp	L_0DA5
L_0DAE:
	mov	word ptr step_x, ax
	mov	word ptr clip_left, bx
	shl	di, 1
	mov	di, word ptr [di+row_offset]
	add	di, dx
	mov	ds, word ptr src_seg
	jmp	L_0DC7
L_0DC4:
	pop	es
	pop	bp
	retf
L_0DC7:
	push	si
	lodsw
	mov	bx, ax
	or	ax, ax
	je	L_0E34
	lodsw
	mov	cx, ax
	add	ax, bx
	cmp	ax, word ptr cs:clip_left
	jbe	L_0E34
	push	di
	mov	bp, di
	mov	ax, cs
	mov	es, ax
	lea	di, row_buffer
	mov	dx, word ptr cs:src_width
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
	mov	bx, word ptr src_width
	mov	dx, word ptr dst_width
	mov	bp, word ptr step_x
	add	si, word ptr clip_left
	mov	cx, word ptr blit_cols
L_0E1D:
	lodsb
L_0E1E:
	dec	cx
	js	L_0E33
	or	al, al
	je	scale_skip
scale_dir:
	cld
	stosb
	cld
	add	bp, bx
	js	L_0E1E
L_0E2C:
	sub	bp, dx
	js	L_0E1D
	inc	si
	jmp	L_0E2C
L_0E33:
	pop	di
L_0E34:
	pop	si
	dec	word ptr cs:blit_rows
	je	L_0E64
	add	di, word ptr cs:row_step
	mov	ds, word ptr cs:src_seg
	mov	ax, word ptr cs:step_y
	add	ax, word ptr cs:src_height
	js	L_0E5D
L_0E51:
	add	si, word ptr [si]
	add	si, 4
	sub	ax, word ptr cs:dst_height
	jns	L_0E51
L_0E5D:
	mov	word ptr cs:step_y, ax
	jmp	L_0DC7
L_0E64:
	jmp	L_0DC4
L_0E67:
	dec	cx
	js	L_0E33
scale_skip:
	inc	di
	add	bp, bx
	js	L_0E67
L_0E6F:
	sub	bp, dx
	js	L_0E1D
	inc	si
	jmp	L_0E6F
L_0E76:
	and	al, 7Fh
	ASSUME	DS:DATA
	mov	byte ptr text_fg, al
	jmp	L_0EB4
L_0E7E:
	pop	bp
	mov	al, byte ptr text_fg
	mov	byte ptr [bp+0Ch], al
	retf

; ----------------------------------------------------------------------------
; draw_glyphs
; Draw the string at SS:SI with the font set up by text_setup.
; ----------------------------------------------------------------------------
draw_glyphs:
	mov	al, byte ptr [bp+0Ch]
	mov	byte ptr text_fg, al
	mov	al, byte ptr [bp+0Eh]
	mov	byte ptr text_bg, al
	mov	al, byte ptr [bp+0Ah]
	mov	byte ptr text_opaque, al
	push	bp
	mov	bp, word ptr glyph_bytes
	mov	bx, es
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	mov	di, word ptr text_y
	shl	di, 1
	mov	di, word ptr [di+row_offset]
	add	di, word ptr text_x
L_0EB4:
	mov	ax, word ptr ss:[si]
	inc	si
	or	al, al
	je	L_0E7E
	js	L_0E76
	push	si
	push	di
	sub	al, byte ptr font_first
	mov	si, ax
	and	si, 0FFh
	mov	cl, byte ptr font_fixed_width
	or	cl, cl
	jne	L_0EDC
	mov	bx, word ptr width_table
	mov	cl, byte ptr [bx+si]
	add	cl, byte ptr font_spacing
L_0EDC:
	or	ah, ah
	jne	L_0EE4
	sub	cl, byte ptr cut_skip
L_0EE4:
	sub	cl, byte ptr glyph_skip
	mov	byte ptr glyph_width, cl
	mov	cl, byte ptr glyph_shift
	shl	si, cl
	add	si, word ptr glyph_data
	mov	cl, byte ptr glyph_skip
	mov	ch, byte ptr text_rows
	mov	dl, byte ptr text_fg
	mov	dh, byte ptr text_bg
	cmp	byte ptr text_opaque, 1
	je	L_0F4C
	mov	al, byte ptr glyph_width
	or	ah, ah
	je	L_0F18
	sub	al, byte ptr font_spacing
L_0F18:
	push	di
	mov	ah, al
	mov	bx, word ptr [si]
	xchg	bh, bl
	shl	bx, cl
L_0F21:
	shl	bx, 1
	jae	L_0F28
	mov	byte ptr es:[di], dl
L_0F28:
	inc	di
	dec	ah
	jne	L_0F21
	pop	di
	add	di, 140h
	add	si, bp
	dec	ch
	jne	L_0F18
L_0F38:
	pop	di
	pop	si
	xor	ah, ah
	mov	byte ptr glyph_skip, ah
	mov	al, byte ptr glyph_width
	add	di, ax
	add	word ptr text_x, ax
	jmp	L_0EB4
L_0F4C:
	push	di
	mov	ah, byte ptr glyph_width
	mov	bx, word ptr [si]
	xchg	bh, bl
	shl	bx, cl
L_0F57:
	mov	al, dl
	shl	bx, 1
	jb	L_0F5F
	mov	al, dh
L_0F5F:
	stosb
	dec	ah
	jne	L_0F57
	pop	di
	add	di, 140h
	add	si, bp
	dec	ch
	jne	L_0F4C
	jmp	L_0F38
unused_0f71	db	0,0Ch,4,0Ch,0Eh
shake_seed	dw	4D2h
shake_count	db	0

; ----------------------------------------------------------------------------
; mgfx_set_shake (slot 28)
; set_shake(n): shake the screen for the next n calls of shake_tick.
; ----------------------------------------------------------------------------
mgfx_set_shake:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	mov	byte ptr cs:shake_count, al
	retf

; ----------------------------------------------------------------------------
; mgfx_shake_tick (slot 50)
; shake_tick(): while shaking, set a random CRTC start address (0-3FFh).
; ----------------------------------------------------------------------------
mgfx_shake_tick:
	mov	ax, word ptr cs:shake_seed
	shl	ax, 1
	shl	ax, 1
	add	ax, word ptr cs:shake_seed
	inc	ax
	mov	word ptr cs:shake_seed, ax
	cmp	byte ptr cs:shake_count, 0
	je	L_0FAF
	and	ah, 3
	dec	byte ptr cs:shake_count
	jne	L_0FA9
	xor	ah, ah
L_0FA9:
	mov	dx, 3D4h
	mov	al, 0Dh
	out	dx, ax
L_0FAF:
	retf

; ----------------------------------------------------------------------------
; mgfx_patch_font (slot 15)
; patch_font(font, data): copy a font image (header before 'data') over font n.
; ----------------------------------------------------------------------------
mgfx_patch_font:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	mov	ax, DATA
	mov	es, ax
	mov	si, word ptr [bp+8]
	mov	di, word ptr [bp+6]
	cmp	di, word ptr es:[FONT_TABLE]
	ja	L_0FFB
	shl	di, 1
	je	L_0FFB
	mov	di, word ptr es:[di+FONT_TABLE]
	add	di, FONT_TABLE
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
L_0FFB:
	pop	es
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_char_width (slot 4)
; char_width(font, ch): width of a character (0 if not in the font).
; ----------------------------------------------------------------------------
mgfx_char_width:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	cl, byte ptr [bp+8]
	or	cl, cl
	js	L_104B
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr ds:[FONT_TABLE]
	ja	L_104B
	shl	bx, 1
	je	L_104B
	mov	bx, word ptr [bx+FONT_TABLE]
	add	bx, FONT_TABLE
	cmp	cl, byte ptr [bx-8]
	jb	L_104B
	cmp	cl, byte ptr [bx-7]
	ja	L_104B
	mov	ah, byte ptr [bx-3]
	mov	al, byte ptr [bx-5]
	or	al, al
	jne	L_104B
	mov	al, cl
	mov	cl, byte ptr [bx-7]
	sub	cl, al
	xor	ch, ch
	add	bx, -9
	sub	bx, cx
	mov	al, byte ptr [bx]
L_104B:
	add	al, ah
	cbw
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_font_height (slot 10)
; font_height(font): height of a font's characters.
; ----------------------------------------------------------------------------
mgfx_font_height:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr ds:[FONT_TABLE]
	ja	L_1077
	shl	bx, 1
	je	L_1077
	mov	bx, word ptr [bx+FONT_TABLE]
	add	bx, FONT_TABLE
	mov	al, byte ptr [bx-4]
	add	al, byte ptr [bx-2]
L_1077:
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_draw_text (slot 20)
; draw_text(port, x, y, string, ?): draw a string clipped to the port.
; ----------------------------------------------------------------------------
mgfx_draw_text:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	bx, word ptr [bp+0Ch]
	mov	cx, word ptr [bp+8]
	mov	dx, word ptr [bp+0Ah]
	mov	bp, word ptr [bp+6]
	call	far ptr mgfx_text_clip_all
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; mgfx_text_clip_all (slot 42)
; BP = port, CX = x, DX = y, BX = string (SS): draw text clipped on all sides.
; Returns the x after the text, relative to the port. Slots 43-46: other clipping.
; ----------------------------------------------------------------------------
mgfx_text_clip_all:
	call	text_setup
	call	clip_text_right
	call	clip_text_left
	call	clip_text_vert
	jmp	text_draw

; ----------------------------------------------------------------------------
; mgfx_text_clip_left (slot 43): As text_clip_all, clipped on the left only.
; ----------------------------------------------------------------------------
mgfx_text_clip_left:
	call	text_setup
	call	clip_text_left
	jmp	text_draw

; ----------------------------------------------------------------------------
; clip_text_left
; ----------------------------------------------------------------------------
clip_text_left:
	cmp	byte ptr font_fixed_width, 0
	je	L_10E4
	cmp	word ptr [bp+6], 0
	js	L_10E0
	mov	ax, word ptr text_x
	or	ax, ax
	jns	L_10E4
	mov	word ptr text_x, 0
	neg	ax
	div	byte ptr font_fixed_width
	mov	byte ptr glyph_skip, ah
	inc	al
L_10D2:
	dec	al
	je	L_10E4
L_10D6:
	mov	ah, byte ptr ss:[bx]
	inc	bx
	or	ah, ah
	js	L_10D6
	jne	L_10D2
L_10E0:
	pop	ax
	jmp	text_done
L_10E4:
	ret

; ----------------------------------------------------------------------------
; mgfx_text_clip_right (slot 45): As text_clip_all, clipped on the right only.
; ----------------------------------------------------------------------------
mgfx_text_clip_right:
	call	text_setup
	call	clip_text_right
	jmp	text_draw

; ----------------------------------------------------------------------------
; clip_text_right
; ----------------------------------------------------------------------------
clip_text_right:
	cmp	byte ptr font_fixed_width, 0
	je	L_1131
	mov	dx, word ptr text_x
	mov	cx, word ptr [bp+6]
	or	cx, cx
	js	L_1132
	cmp	dx, cx
	jg	L_1132
	dec	dx
	xor	ah, ah
	mov	al, byte ptr font_fixed_width
	mov	di, ax
	mov	si, bx
	dec	si
L_110F:
	inc	si
	cmp	byte ptr ss:[si], ah
	js	L_110F
	je	L_1131
	add	dx, di
	cmp	dx, cx
	jl	L_110F
	sub	dx, cx
	mov	byte ptr cut_skip, dl
	inc	si
	mov	al, byte ptr ss:[si]
	mov	byte ptr ss:[si], ah
	mov	byte ptr cut_char, al
	mov	word ptr cut_ptr, si
L_1131:
	ret
L_1132:
	pop	ax
	jmp	text_done

; ----------------------------------------------------------------------------
; mgfx_text_clip_vert (slot 46): As text_clip_all, clipped at the top and bottom only.
; ----------------------------------------------------------------------------
mgfx_text_clip_vert:
	call	text_setup
	call	clip_text_vert
	jmp	text_draw

; ----------------------------------------------------------------------------
; clip_text_vert
; ----------------------------------------------------------------------------
clip_text_vert:
	mov	cx, word ptr [bp+8]
	or	cx, cx
	js	L_1178
	mov	ax, word ptr text_y
	or	ax, ax
	jns	L_1163
	neg	ax
	sub	word ptr text_rows, ax
	jbe	L_1178
	mov	word ptr text_y, 0
	mul	word ptr glyph_bytes
	add	word ptr glyph_data, ax
L_1163:
	mov	ax, word ptr text_y
	cmp	ax, cx
	ja	L_1178
	add	ax, word ptr text_rows
	dec	ax
	sub	ax, cx
	jbe	L_1177
	sub	word ptr text_rows, ax
L_1177:
	ret
L_1178:
	pop	ax
	jmp	text_done

; ----------------------------------------------------------------------------
; mgfx_text_noclip (slot 44): As text_clip_all, without clipping.
; ----------------------------------------------------------------------------
mgfx_text_noclip:
	call	text_setup
text_draw:
	mov	ax, word ptr [bp+2]
	add	word ptr text_x, ax
	mov	ax, word ptr [bp+4]
	add	word ptr text_y, ax
	mov	si, bx
	call	far ptr draw_glyphs
text_done:
	mov	bx, word ptr cut_ptr
	or	bx, bx
	je	L_11A2
	mov	al, byte ptr cut_char
	mov	byte ptr ss:[bx], al
L_11A2:
	mov	ax, word ptr text_x
	sub	ax, word ptr [bp+2]
	pop	es
	pop	ds
	retf

; ----------------------------------------------------------------------------
; text_setup
; Common text set-up: BP = port, CX = x, DX = y, BX = string (SS).
; Loads the font of port+10h; returns with DS = DATA and DS, ES pushed.
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
	je	text_done
	mov	di, word ptr [bp+10h]
	cmp	di, word ptr ds:[FONT_TABLE]
	ja	text_done
	shl	di, 1
	je	text_done
	mov	di, word ptr [di+FONT_TABLE]
	add	di, FONT_TABLE
	mov	word ptr glyph_data, di
	mov	al, byte ptr [di-4]
	test	byte ptr [bp+0Ah], 1
	je	L_11F3
	add	al, byte ptr [di-2]
L_11F3:
	cbw
	mov	word ptr text_rows, ax
	mov	ah, byte ptr [di-3]
	mov	byte ptr font_spacing, ah
	mov	al, byte ptr [di-5]
	or	al, al
	je	L_1207
	add	al, ah
L_1207:
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
; mgfx_nop13 (slot 13)
; Slot 13: nothing to do on MCGA.
; ----------------------------------------------------------------------------
mgfx_nop13:
	retf
CODE	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

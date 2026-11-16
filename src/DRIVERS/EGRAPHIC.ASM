; EGRAPHIC.EXE - Covert Action graphics driver for EGA (320x200, 16 colours)
;
; Same interface as MGRAPHIC (51 entry points, see MGRAPHIC.ASM and README
; "Driver interface"); the screen is EGA mode 0Dh at A000h, four bit planes
; of 40 bytes per row (init_mode flag 2 selects mode 0Eh, 640x200, 80 bytes
; per row), written through the sequencer map mask and graphics controller. Routine and variable names come from MGRAPHIC by
; aligning each export with MGRAPHIC's routine for the same slot ("inherit");
; the descriptions are those of tools/drivers/gfx_slots.txt.
;
; The original's header checksum does not match its contents (the file was
; probably patched after linking), so the build sets it (EXE checksum line).
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh EGRAPHIC
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/EGRAPHIC.hints)

; EXE checksum: 01FDh (the original's checksum does not match its contents: probably patched after linking; tools/drivers/build.sh sets it)
; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:21A0h = DATA:0) while DS references, with DS = DATA,
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
w_D0050	dw	9 dup (0)
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
w_D0078	dw	0
ptr_save	dw	256 dup (0)
row_offset	dw	0,28h,50h,78h,0A0h,0C8h,0F0h,118h
	dw	140h,168h,190h,1B8h,1E0h,208h,230h,258h
	dw	280h,2A8h,2D0h,2F8h,320h,348h,370h,398h
	dw	3C0h,3E8h,410h,438h,460h,488h,4B0h,4D8h
	dw	500h,528h,550h,578h,5A0h,5C8h,5F0h,618h
	dw	640h,668h,690h,6B8h,6E0h,708h,730h,758h
	dw	780h,7A8h,7D0h,7F8h,820h,848h,870h,898h
	dw	8C0h,8E8h,910h,938h,960h,988h,9B0h,9D8h
	dw	0A00h,0A28h,0A50h,0A78h,0AA0h,0AC8h,0AF0h,0B18h
	dw	0B40h,0B68h,0B90h,0BB8h,0BE0h,0C08h,0C30h,0C58h
	dw	0C80h,0CA8h,0CD0h,0CF8h,0D20h,0D48h,0D70h,0D98h
	dw	0DC0h,0DE8h,0E10h,0E38h,0E60h,0E88h,0EB0h,0ED8h
	dw	0F00h,0F28h,0F50h,0F78h,0FA0h,0FC8h,0FF0h,1018h
	dw	1040h,1068h,1090h,10B8h,10E0h,1108h,1130h,1158h
	dw	1180h,11A8h,11D0h,11F8h,1220h,1248h,1270h,1298h
	dw	12C0h,12E8h,1310h,1338h,1360h,1388h,13B0h,13D8h
	dw	1400h,1428h,1450h,1478h,14A0h,14C8h,14F0h,1518h
	dw	1540h,1568h,1590h,15B8h,15E0h,1608h,1630h,1658h
	dw	1680h,16A8h,16D0h,16F8h,1720h,1748h,1770h,1798h
	dw	17C0h,17E8h,1810h,1838h,1860h,1888h,18B0h,18D8h
	dw	1900h,1928h,1950h,1978h,19A0h,19C8h,19F0h,1A18h
	dw	1A40h,1A68h,1A90h,1AB8h,1AE0h,1B08h,1B30h,1B58h
	dw	1B80h,1BA8h,1BD0h,1BF8h,1C20h,1C48h,1C70h,1C98h
	dw	1CC0h,1CE8h,1D10h,1D38h,1D60h,1D88h,1DB0h,1DD8h
	dw	1E00h,1E28h,1E50h,1E78h,1EA0h,1EC8h,1EF0h,1F18h
caps_table	dw	1,1,1
w_D0410	dw	0
w_D0412	dw	0
page_seg	dw	8 dup (0A000h)
draw_seg	dw	0A000h
draw_x0	dw	0
draw_y0	dw	0
draw_xmax	dw	13Fh
w_D042C	db	28h,0,0
b_D042F	db	0FFh
b_D0430	db	0
draw_color	db	0
b_D0432	db	0
b_D0433	db	0
b_D0434	db	0
b_D0435	db	0
b_D0436	db	0
b_D0437	db	0Fh
w_D0438	dw	0
w_D043A	dw	0FFFFh,0FF7Fh,0FF3Fh,0FF1Fh,0FF0Fh,0FF07h,0FF03h,0FF01h
	dw	0FF00h,7F00h,3F00h,1F00h,0F00h,700h,300h,100h
w_D045A	dw	80h,0C0h,0E0h,0F0h,0F8h,0FCh,0FEh,0FFh
	dw	80FFh,0C0FFh,0E0FFh,0F0FFh,0F8FFh,0FCFFh,0FEFFh,0FFFFh
w_D047A	dw	0
w_D047C	db	0,0
	db	'Out of memory$'
	db	'EGA is not supported on your machine$',0
b_D04B2	db	80h,40h,20h,10h,8,4,2,1
line_x0	dw	0
line_y0	dw	32h
line_x1	dw	64h
line_y1	dw	0
w_D04C2	dw	0
w_D04C4	dw	0
w_D04C6	dw	0
w_D04C8	dw	0
w_D04CA	dw	0
w_D04CC	dw	0
w_D04CE	dw	0
w_D04D0	dw	8 dup (0)
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
drv_ident	db	'EGRAPHIC.EXE02-20-89'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	500h		; bytes from DATA to the stack
drv_first_slot	db	0
	db	0
drv_count	dw	51		; number of exports
drv_exports	label	word
	dw	offset egfx_alloc_page	; slot 0
	dw	offset egfx_mem_avail	; slot 1
	dw	offset egfx_get_image	; slot 2
	dw	offset egfx_recolor_rect	; slot 3
	dw	offset egfx_char_width	; slot 4
	dw	offset egfx_clear_page	; slot 5
	dw	offset egfx_draw_image	; slot 6
	dw	offset egfx_end_image_grab	; slot 7
	dw	offset egfx_free_page	; slot 8
	dw	offset egfx_dissolve_page	; slot 9
	dw	offset egfx_font_height	; slot 10
	dw	offset egfx_get_row	; slot 11
	dw	offset egfx_get_pixel	; slot 12
	dw	offset egfx_nop13	; slot 13
	dw	offset egfx_hide_pointer	; slot 14
	dw	offset egfx_patch_font	; slot 15
	dw	offset egfx_has_back_buffer	; slot 16
	dw	offset egfx_begin_image_grab	; slot 17
	dw	offset egfx_put_row	; slot 18
	dw	offset egfx_copy_rect	; slot 19
	dw	offset egfx_draw_text	; slot 20
	dw	offset egfx_draw_image_scaled	; slot 21
	dw	offset egfx_screen_off	; slot 22
	dw	offset egfx_screen_on	; slot 23
	dw	offset egfx_set_page	; slot 24
	dw	offset egfx_set_color	; slot 25
	dw	offset egfx_set_palette	; slot 26
	dw	offset egfx_set_color_map	; slot 27
	dw	offset egfx_set_shake	; slot 28
	dw	offset egfx_show_pointer	; slot 29
	dw	offset egfx_show_page	; slot 30
	dw	offset egfx_draw_image_noclip	; slot 31
	dw	offset egfx_end_image	; slot 32
	dw	offset egfx_image_add_row	; slot 33
	dw	offset egfx_begin_image	; slot 34
	dw	offset egfx_swap_page	; slot 35
	dw	offset egfx_init_mode	; slot 36
	dw	offset egfx_put_pixel	; slot 37
	dw	offset egfx_fill_spans	; slot 38
	dw	offset egfx_nop39	; slot 39
	dw	offset egfx_set_draw_color	; slot 40
	dw	offset egfx_draw_line	; slot 41
	dw	offset egfx_text_clip_all	; slot 42
	dw	offset egfx_text_clip_left	; slot 43
	dw	offset egfx_text_noclip	; slot 44
	dw	offset egfx_text_clip_right	; slot 45
	dw	offset egfx_text_clip_vert	; slot 46
	dw	offset egfx_select_page	; slot 47
	dw	offset egfx_set_port	; slot 48
	dw	offset egfx_copy_rows_to_screen	; slot 49
	dw	offset egfx_shake_tick	; slot 50

; ----------------------------------------------------------------------------
; egfx_recolor_rect (slot 3): recolor_rect(port, x, y, w, h, from, to): within the rectangle, replace colour 'from' by 'to'.
; ----------------------------------------------------------------------------
egfx_recolor_rect:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bp+6]
	mov	di, word ptr [bp+0Ch]
	mov	dx, word ptr [bp+8]
	add	dx, word ptr [si+2]
	cmp	word ptr cs:w_D0412, 1
	jne	L_00B7
	shl	dx, 1
	shl	di, 1
L_00B7:
	add	di, dx
	dec	di
	mov	ax, di
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	bx, dx
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	sub	ax, bx
	inc	ax
	mov	bx, 0FF80h
	mov	cx, dx
	and	cl, 7
	shr	bh, cl
	mov	cx, di
	and	cl, 7
	sar	bl, cl
	mov	cx, ax
	mov	di, word ptr [bp+0Ah]
	add	di, word ptr [si+4]
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1
	add	di, dx
	mov	dx, 3CEh
	mov	al, 0
	mov	ah, byte ptr [bp+12h]
	mov	byte ptr cs:draw_color, ah
	out	dx, ax
	mov	ax, 0F01h
	mov	byte ptr cs:b_D0432, ah
	out	dx, ax
	mov	al, 2
	mov	ah, byte ptr [bp+10h]
	mov	byte ptr cs:b_D0433, ah
	out	dx, ax
	mov	ax, 805h
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
	mov	al, 8
	mov	byte ptr cs:b_D0430, al
	out	dx, al
	inc	dx
	mov	bp, word ptr [bp+0Eh]
	mov	si, word ptr [si]
	shl	si, 1
	mov	si, word ptr cs:[si+page_seg]
	mov	ds, si
	mov	es, si
	mov	si, di
L_013A:
	nop
	mov	di, si
	mov	ch, cl
	mov	ah, bh
	and	ah, bl
	dec	ch
	je	L_015B
	mov	al, byte ptr [di]
	and	al, bh
	out	dx, al
	stosb
	mov	ah, bl
	dec	ch
	je	L_015B
L_0153:
	mov	al, byte ptr [di]
	out	dx, al
	stosb
	dec	ch
	jne	L_0153
L_015B:
	mov	al, byte ptr [di]
	and	al, ah
	out	dx, al
	stosb
	nop
	add	si, word ptr cs:w_D042C
	dec	bp
	jne	L_013A
	dec	dx
	mov	ax, 1
	mov	byte ptr cs:b_D0432, ah
	out	dx, ax
	mov	ax, 5
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
	mov	ax, 0FF08h
	out	dx, ax
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf
	db	0

; ----------------------------------------------------------------------------
; egfx_set_color (slot 25): set_color(index, colour): set one palette entry.
; ----------------------------------------------------------------------------
egfx_set_color:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	mov	ah, byte ptr [bx+6]
	and	ah, 0Fh
	add	ah, 8
	and	ah, 17h
	mov	bx, ax
	mov	ax, 1000h
	int	10h
	retf

; ----------------------------------------------------------------------------
; egfx_set_palette (slot 26): set_palette(pal): set the 16-colour palette (17 bytes, the last is the border).
; ----------------------------------------------------------------------------
egfx_set_palette:
	mov	bx, sp
	push	si
	push	di
	mov	ax, DATA
	mov	es, ax
	mov	si, word ptr [bx+4]
	lea	dx, w_D0050
	mov	di, dx
	mov	cx, 11h
L_01B6:
	lodsb
	and	al, 0Fh
	add	al, 8
	and	al, 17h
	stosb
	loop	L_01B6
	mov	ax, 1002h
	int	10h
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; egfx_set_color_map (slot 27): set_color_map(...): colour mapping for the dithered modes.
; ----------------------------------------------------------------------------
egfx_set_color_map:
	retf

; ----------------------------------------------------------------------------
; egfx_set_draw_color (slot 40): AL = colour, AH = mode (0 copy, 1 and, 2 or, 3 xor) for the primitives.
; ----------------------------------------------------------------------------
egfx_set_draw_color:
	mov	bx, dx
	mov	dx, 3CEh
	mov	byte ptr cs:draw_color, al
	mov	al, 3
	and	ah, al
	shl	ah, 1
	shl	ah, 1
	shl	ah, 1
	mov	byte ptr cs:b_D0434, ah
	out	dx, ax
	mov	al, 0
	mov	ah, byte ptr cs:draw_color
	out	dx, ax
	mov	ax, 0F01h
	mov	byte ptr cs:b_D0432, ah
	out	dx, ax
	mov	dx, bx
	retf

; ----------------------------------------------------------------------------
; egfx_nop39 (slot 39): Slot 39.
; ----------------------------------------------------------------------------
egfx_nop39:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	dx, 3C4h
	mov	ax, 0F02h
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
	mov	dx, 3CEh
	mov	ax, 1
	mov	byte ptr cs:b_D0432, ah
	out	dx, ax
	mov	ax, 3
	mov	byte ptr cs:b_D0434, ah
	out	dx, ax
	mov	ax, 4
	mov	byte ptr cs:b_D0435, ah
	out	dx, ax
	mov	ax, 5
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
	mov	ax, 0FF08h
	mov	byte ptr cs:b_D042F, ah
	out	dx, ax
	pop	ds
	retf

; ----------------------------------------------------------------------------
; sub_023A
; ----------------------------------------------------------------------------
sub_023A:
	mov	dx, 3C4h
	mov	ax, 0F02h
	out	dx, ax
	mov	dx, 3CEh
	mov	ax, 1
	out	dx, ax
	mov	ax, 3
	out	dx, ax
	mov	ax, 4
	out	dx, ax
	mov	ax, 5
	out	dx, ax
	mov	ax, 0FF08h
	out	dx, ax
	ret

; ----------------------------------------------------------------------------
; save_ptr_bg
; ----------------------------------------------------------------------------
save_ptr_bg:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	dx, 3C4h
	mov	al, 2
	mov	ah, byte ptr cs:b_D0437
	out	dx, ax
	mov	dx, 3CEh
	mov	al, 1
	mov	ah, byte ptr cs:b_D0432
	out	dx, ax
	mov	al, 3
	mov	ah, byte ptr cs:b_D0434
	out	dx, ax
	mov	al, 4
	mov	ah, byte ptr cs:b_D0435
	out	dx, ax
	mov	al, 5
	mov	ah, byte ptr cs:b_D0436
	out	dx, ax
	mov	al, 8
	mov	ah, byte ptr cs:b_D042F
	out	dx, ax
	pop	ds
	ret
	db	0
w_0298	dw	160 dup (0)
w_03D8	db	4 dup (0)
	db	11h,11h,22h,22h,33h,33h,44h,44h,55h,55h,66h,66h,77h,77h,88h,88h
	db	99h,99h,0AAh,0AAh,0BBh,0BBh,0CCh,0CCh,0DDh,0DDh,0EEh,0EEh,0FFh,0FFh,0,0
	db	8,80h,88h,88h,0Fh,0F0h,77h,77h,7Fh,0F7h
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
b_04DA	db	0

; ----------------------------------------------------------------------------
; egfx_get_pixel (slot 12): get_pixel(page, x, y): colour of a pixel.
; ----------------------------------------------------------------------------
egfx_get_pixel:
	mov	bx, sp
	push	si
	mov	cx, word ptr [bx+6]
	mov	si, word ptr [bx+8]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	shl	si, 1
	mov	si, word ptr cs:[si+row_offset]
	mov	ax, cx
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	si, ax
	and	cl, 7
	mov	ch, 80h
	shr	ch, cl
	mov	dx, 3CEh
	mov	ax, 304h
	xor	bl, bl
L_050E:
	nop
	out	dx, ax
	mov	bh, byte ptr es:[si]
	nop
	and	bh, ch
	neg	bh
	rol	bx, 1
	dec	ah
	jns	L_050E
	mov	al, bl
	xor	ah, ah
	pop	si
	retf

; ----------------------------------------------------------------------------
; egfx_get_row (slot 11): get_row(buf, page, y, x, n): copy n pixels of a row to DS:buf.
; ----------------------------------------------------------------------------
egfx_get_row:
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
	mov	ax, word ptr [bx+0Ah]
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	si, ax
	mov	cx, word ptr [bx+0Ch]
	add	cx, 7
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	mov	bx, word ptr [bx+6]
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
L_055B:
	nop
	mov	al, 4
	mov	dx, 3CEh
	out	dx, al
	inc	dx
	dec	al
	out	dx, al
	mov	bh, byte ptr [si]
	dec	al
	out	dx, al
	mov	bl, byte ptr [si]
	dec	al
	out	dx, al
	mov	ah, byte ptr [si]
	dec	al
	out	dx, al
	lodsb
	mov	dx, ax
	nop
	mov	ah, 1
L_057B:
	xor	al, al
	shl	bh, 1
	rcl	al, 1
	shl	bl, 1
	rcl	al, 1
	shl	dh, 1
	rcl	al, 1
	shl	dl, 1
	rcl	ax, 1
	stosb
	jae	L_057B
	loop	L_055B
	pop	ds
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; egfx_put_row (slot 18): put_row(buf, page, y, x, n): copy n pixels from DS:buf to a row.
; ----------------------------------------------------------------------------
egfx_put_row:
	mov	bx, sp
	push	si
	push	di
	mov	si, word ptr [bx+4]
	mov	dx, word ptr [bx+8]
	mov	di, dx
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	mov	ax, word ptr [bx+0Ah]
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	di, ax
	mov	cx, word ptr [bx+0Ch]
	add	cx, 0Fh
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	mov	bx, word ptr [bx+6]
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	push	es
	push	di
	mov	bx, cs
	mov	es, bx
	ASSUME	DS:DGROUP
	lea	di, w_0298
	and	dx, 1
	xor	dx, 1
	mov	byte ptr cs:b_04DA, dl
	xor	bx, bx
	xor	dx, dx
	inc	dh
	cmp	word ptr cs:w_D0412, 1
	je	L_0628
	mov	word ptr cs:w_03D8, cx
	shl	cx, 1
L_05F6:
	lodsb
	shr	al, 1
	rcl	bl, 1
	shr	al, 1
	rcl	bh, 1
	shr	al, 1
	rcl	dl, 1
	shr	al, 1
	rcl	dh, 1
	jae	L_05F6
	mov	byte ptr es:[di+28h], bh
	mov	byte ptr es:[di+50h], dl
	mov	byte ptr es:[di+78h], dh
	mov	al, bl
	stosb
	xor	bx, bx
	xor	dx, dx
	inc	dh
	loop	L_05F6
L_0620:
	pop	di
	pop	es
	call	sub_0681
	pop	di
	pop	si
	retf
L_0628:
	shl	cx, 1
	mov	word ptr cs:w_03D8, cx
	shl	cx, 1
	push	bp
L_0632:
	lodsb
	shl	al, 1
	add	al, byte ptr cs:b_04DA
	xor	ah, ah
	mov	bp, ax
	mov	al, byte ptr cs:[bp+3DAh]
	shr	al, 1
	rcl	bl, 1
	shr	al, 1
	rcl	bh, 1
	shr	al, 1
	rcl	dl, 1
	shr	al, 1
	rcl	dh, 1
	shr	al, 1
	rcl	bl, 1
	shr	al, 1
	rcl	bh, 1
	shr	al, 1
	rcl	dl, 1
	shr	al, 1
	rcl	dh, 1
	jae	L_0632
	mov	byte ptr es:[di+50h], bh
	mov	byte ptr es:[di+0A0h], dl
	mov	byte ptr es:[di+0F0h], dh
	mov	al, bl
	stosb
	xor	bx, bx
	xor	dx, dx
	inc	dh
	loop	L_0632
	pop	bp
	jmp	L_0620

; ----------------------------------------------------------------------------
; sub_0681
; ----------------------------------------------------------------------------
sub_0681:
	push	bp
	push	ds
	mov	ax, cs
	mov	ds, ax
	lea	si, w_0298
	mov	bx, di
	mov	dx, 3C4h
	mov	al, 2
	nop
	out	dx, al
	inc	dx
	mov	al, 1
	out	dx, al
	mov	cx, word ptr cs:w_03D8
	mov	bp, word ptr cs:w_D042C
	shr	bp, 1
	sub	bp, cx
	shl	bp, 1
	mov	di, bx
	rep	movsw
	mov	al, 2
	out	dx, al
	mov	cx, word ptr cs:w_03D8
	add	si, bp
	mov	di, bx
	rep	movsw
	mov	al, 4
	out	dx, al
	mov	cx, word ptr cs:w_03D8
	add	si, bp
	mov	di, bx
	rep	movsw
	mov	al, 8
	out	dx, al
	mov	cx, word ptr cs:w_03D8
	add	si, bp
	mov	di, bx
	rep	movsw
	mov	al, 0Fh
	out	dx, al
	nop
	pop	ds
	pop	bp
	ret

; ----------------------------------------------------------------------------
; egfx_hide_pointer (slot 14): hide_pointer(): restore the background under the mouse pointer.
; ----------------------------------------------------------------------------
egfx_hide_pointer:
	call	restore_ptr_bg
	push	ds
	mov	ax, DATA
	mov	ds, ax
	ASSUME	DS:DATA
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
	call	sub_023A
	mov	ax, DATA
	mov	ds, ax
	cmp	word ptr ptr_visible, 0
	je	L_0742
	lea	si, ptr_save
	mov	di, word ptr ptr_clip_y
	shl	di, 1
	mov	di, word ptr [di+row_offset]
	add	di, word ptr ptr_clip_x
	mov	bx, word ptr ptr_page
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	mov	dx, 3C4h
	mov	ax, 802h
L_0724:
	push	di
	nop
	out	dx, ax
	mov	bx, word ptr ptr_clip_h
L_072B:
	mov	cx, word ptr ptr_clip_w
	rep	movsb
	add	di, word ptr w_D0078
	dec	bx
	jne	L_072B
	nop
	pop	di
	shr	ah, 1
	jae	L_0724
	mov	ax, 0F02h
	out	dx, ax
L_0742:
	pop	es
	pop	ds
	pop	di
	pop	si
	ret

; ----------------------------------------------------------------------------
; egfx_show_pointer (slot 29): show_pointer(x, y, image): save the screen under the mouse pointer and draw it.
; ----------------------------------------------------------------------------
egfx_show_pointer:
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
	je	L_07C1
	or	ax, ax
	jns	L_0777
	neg	ax
	sub	bx, ax
	jbe	L_07C1
	xor	ax, ax
L_0777:
	mov	cx, word ptr cs:w_D042C
	shl	cx, 1
	shl	cx, 1
	shl	cx, 1
	sub	cx, ax
	jbe	L_07C1
	cmp	bx, cx
	jbe	L_078C
	mov	bx, cx
L_078C:
	mov	cx, ax
	and	cx, 7
	add	bx, cx
	add	bx, 7
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	mov	word ptr ptr_clip_w, bx
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	word ptr ptr_clip_x, ax
	mov	ax, word ptr cs:w_D042C
	sub	ax, bx
	mov	word ptr w_D0078, ax
	mov	ax, 200h
	shr	ax, 1
	shr	ax, 1
	cwd
	div	bx
	mov	dx, ax
	jmp	L_07CA
L_07C1:
	mov	word ptr ptr_visible, 0
	jmp	L_080F
L_07CA:
	mov	ax, word ptr [bp+8]
	mov	word ptr ptr_y, ax
	mov	bx, word ptr es:[2]
	mov	word ptr ptr_height, bx
	or	bx, bx
	je	L_07C1
	or	ax, ax
	jns	L_07E9
	neg	ax
	sub	bx, ax
	jbe	L_07C1
	xor	ax, ax
L_07E9:
	mov	cx, 0C8h
	sub	cx, ax
	jbe	L_07C1
	cmp	bx, cx
	jbe	L_07F6
	mov	bx, cx
L_07F6:
	cmp	bx, dx
	jbe	L_07FC
	mov	bx, dx
L_07FC:
	mov	word ptr ptr_clip_h, bx
	mov	word ptr ptr_clip_y, ax
	mov	word ptr ptr_visible, 1
	mov	ax, word ptr ptr_page
	call	sub_0815
L_080F:
	call	save_ptr_bg
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; sub_0815
; ----------------------------------------------------------------------------
sub_0815:
	push	si
	push	di
	push	ds
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	word ptr ptr_page, ax
	cmp	word ptr ptr_visible, 0
	je	L_089E
	mov	si, word ptr ptr_clip_y
	shl	si, 1
	mov	si, word ptr [si+row_offset]
	add	si, word ptr ptr_clip_x
	mov	bx, ax
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
	mov	es, dx
	lea	di, ptr_save
	mov	dx, 3CEh
	mov	ax, 304h
L_084B:
	push	si
	nop
	out	dx, ax
	mov	bx, word ptr es:ptr_clip_h
L_0853:
	mov	cx, word ptr es:ptr_clip_w
	rep	movsb
	add	si, word ptr es:w_D0078
	dec	bx
	jne	L_0853
	nop
	pop	si
	dec	ah
	jns	L_084B
	mov	dx, DATA
	mov	ds, dx
	mov	dx, 0C8h
	dec	dx
	push	dx
	mov	dx, word ptr cs:w_D042C
	shl	dx, 1
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
	call	far ptr egfx_draw_image
	add	sp, 12h
L_089E:
	pop	es
	pop	ds
	pop	di
	pop	si
	ret
	db	0
L_08A4:
	pop	es
	pop	ds
L_08A6:
	retf

; ----------------------------------------------------------------------------
; egfx_fill_spans (slot 38): AX = first row, CX = last row, BX = span table: fill each row's span.
; ----------------------------------------------------------------------------
egfx_fill_spans:
	or	ax, ax
	js	L_08A6
	push	ds
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	es, word ptr cs:draw_seg
	shl	ax, 1
	mov	si, ax
	mov	word ptr w_D047C, bx
	shl	cx, 1
	mov	word ptr w_D0438, cx
	mov	dx, 3CEh
	mov	al, 8
	mov	byte ptr cs:b_D0430, al
	out	dx, al
	inc	dx
	mov	ah, byte ptr cs:w_D0412
	sub	si, 2
L_08D8:
	add	si, 2
	cmp	si, word ptr w_D0438
	ja	L_08A4
	mov	cx, word ptr ss:[bx+si+1B8h]
	mov	bp, word ptr ss:[bx+si]
	cmp	cx, bp
	jb	L_08D8
	ja	L_08FA
	or	cx, cx
	je	L_08D8
	cmp	cx, word ptr cs:draw_xmax
	je	L_08D8
L_08FA:
	cmp	ah, 1
	jne	L_0904
	shl	bp, 1
	shl	cx, 1
	inc	cx
L_0904:
	mov	bx, cx
	and	bx, 0Fh
	shl	bx, 1
	mov	bx, word ptr [bx+w_D045A]
	mov	word ptr w_D047A, bx
	mov	bx, bp
	and	bx, 0Fh
	shl	bx, 1
	mov	bx, word ptr [bx+w_D043A]
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	mov	di, bp
	shl	di, 1
	add	di, word ptr [si+row_offset]
	sub	cx, bp
	nop
	je	L_0954
	mov	al, bl
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	mov	al, bh
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	mov	bx, 0FFFFh
	dec	cx
	je	L_0954
	mov	al, bl
	out	dx, al
	rep	stosw
L_0954:
	and	bx, word ptr w_D047A
	mov	al, bl
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	mov	al, bh
	out	dx, al
	inc	byte ptr es:[di]
	nop
	mov	bx, word ptr w_D047C
	jmp	L_08D8
	db	0

; ----------------------------------------------------------------------------
; egfx_has_back_buffer (slot 16): has_back_buffer(n): capability flag.
; ----------------------------------------------------------------------------
egfx_has_back_buffer:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	mov	ax, word ptr cs:[bx+caps_table]
	retf

; ----------------------------------------------------------------------------
; egfx_set_port (slot 48): BX = port: page and origin for the primitives.
; ----------------------------------------------------------------------------
egfx_set_port:
	mov	ax, word ptr [bx+2]
	mov	word ptr cs:draw_x0, ax
	mov	ax, word ptr [bx+4]
	mov	word ptr cs:draw_y0, ax
	mov	ax, word ptr [bx+6]
	mov	word ptr cs:draw_xmax, ax
	mov	ax, word ptr [bx]

; ----------------------------------------------------------------------------
; egfx_select_page (slot 47): AX = page: the page the primitives draw on.
; ----------------------------------------------------------------------------
egfx_select_page:
	xchg	bx, ax
	shl	bx, 1
	mov	bx, word ptr cs:[bx+page_seg]
	xchg	bx, ax
	mov	word ptr cs:draw_seg, ax
	retf

; ----------------------------------------------------------------------------
; egfx_mem_avail (slot 1): mem_avail(): largest free DOS block, in paragraphs.
; ----------------------------------------------------------------------------
egfx_mem_avail:
	mov	ah, 48h
	mov	bx, 0FFFFh
	int	21h
	mov	ax, bx
	retf

; ----------------------------------------------------------------------------
; egfx_set_page (slot 24): set_page(n, seg): set the segment of page n.
; ----------------------------------------------------------------------------
egfx_set_page:
	mov	bx, sp
	mov	ax, word ptr [bx+6]
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	word ptr cs:[bx+page_seg], ax
	retf

; ----------------------------------------------------------------------------
; egfx_alloc_page (slot 0): alloc_page(n): page 0 is the screen; otherwise allocate an off-screen page (0 if no memory).
; ----------------------------------------------------------------------------
egfx_alloc_page:
	mov	bx, sp
	mov	bx, word ptr [bx+4]
	shl	bx, 1
	mov	ax, word ptr cs:[bx+page_seg]
	retf

; ----------------------------------------------------------------------------
; egfx_free_page (slot 8): free_page(n): give page n's memory back to DOS.
; ----------------------------------------------------------------------------
egfx_free_page:
	retf

; ----------------------------------------------------------------------------
; egfx_init_mode (slot 36): init_mode(flags): set the video mode and default palette.
; ----------------------------------------------------------------------------
egfx_init_mode:
	mov	bx, sp
	test	word ptr [bx+4], 2
	je	L_09ED
	mov	dx, 0Eh
	mov	bx, 400h
	mov	word ptr cs:w_D0412, 1
	mov	word ptr cs:w_D042C, 50h
	mov	word ptr cs:w_D0410, 1
	jmp	L_0A08
L_09ED:
	mov	dx, 0Dh
	mov	bx, 200h
	mov	word ptr cs:w_D0412, 0
	mov	word ptr cs:w_D042C, 28h
	mov	word ptr cs:w_D0410, 0
L_0A08:
	call	sub_0A2E
	mov	ax, dx
	int	10h
	mov	ah, 0Fh
	int	10h
	cmp	al, dl
	jne	L_0A18
	retf
L_0A18:
	mov	dx, 48Ch
	mov	ax, DATA
	mov	ds, ax
	mov	ax, 3
	int	10h
	mov	ah, 9
	int	21h
	mov	ax, 4C00h
	int	21h

; ----------------------------------------------------------------------------
; sub_0A2E
; ----------------------------------------------------------------------------
sub_0A2E:
	push	di
	push	es
	push	cs
	pop	es
	mov	ax, 0A000h
	mov	di, 25B4h
	mov	cx, 8
L_0A3B:
	stosw
	add	ax, bx
	loop	L_0A3B
	xor	ax, ax
	mov	di, 241Ah
	mov	cx, 0C8h
L_0A48:
	stosw
	add	ax, word ptr cs:w_D042C
	loop	L_0A48
	pop	es
	pop	di
	ret

; ----------------------------------------------------------------------------
; egfx_screen_off (slot 22): Blank the display.
; ----------------------------------------------------------------------------
egfx_screen_off:
	nop
	push	dx
	mov	dx, 3DAh
L_0A58:
	in	al, dx
	test	al, 8
	je	L_0A58
	mov	dx, 3C0h
	mov	al, 12h
	out	dx, al
	mov	al, 0
	out	dx, al
	mov	al, 20h
	out	dx, al
	pop	dx
	nop
	retf

; ----------------------------------------------------------------------------
; egfx_screen_on (slot 23): Turn the display back on.
; ----------------------------------------------------------------------------
egfx_screen_on:
	nop
	push	dx
	mov	dx, 3DAh
L_0A71:
	in	al, dx
	test	al, 8
	je	L_0A71
	mov	dx, 3C0h
	mov	al, 12h
	out	dx, al
	mov	al, 0Fh
	out	dx, al
	mov	al, 20h
	out	dx, al
	pop	dx
	nop
	retf
	db	0

; ----------------------------------------------------------------------------
; egfx_put_pixel (slot 37): AX = x, BX = y: plot a pixel with the current colour and mode.
; ----------------------------------------------------------------------------
egfx_put_pixel:
	push	ds
	push	es
	mov	dx, DATA
	mov	ds, dx
	mov	es, word ptr cs:draw_seg
	cmp	word ptr cs:w_D0412, 1
	jne	L_0A9C
	shl	ax, 1
L_0A9C:
	add	ax, word ptr cs:draw_x0
	mov	word ptr line_x0, ax
	add	bx, word ptr cs:draw_y0
	mov	word ptr line_y0, bx
L_0AAD:
	call	pixel_addr
	out	dx, al
	inc	byte ptr es:[di]
	nop
	pop	es
	pop	ds
	retf

; ----------------------------------------------------------------------------
; pixel_addr
; ----------------------------------------------------------------------------
pixel_addr:
	mov	bx, word ptr line_x0
	mov	di, bx
	shr	di, 1
	shr	di, 1
	shr	di, 1
	mov	si, word ptr line_y0
	shl	si, 1
	add	di, word ptr [si+row_offset]
	mov	dx, 3CEh
	mov	al, 8
	nop
	out	dx, al
	inc	dx
	and	bx, 7
	mov	al, byte ptr [bx+b_D04B2]
	ret

; ----------------------------------------------------------------------------
; egfx_draw_line (slot 41): AX,BX - CX,DX: draw a line with the current colour and mode.
; ----------------------------------------------------------------------------
egfx_draw_line:
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
	jbe	L_0B03
	xchg	cx, ax
	xchg	bx, dx
L_0B03:
	cmp	word ptr cs:w_D0412, 1
	jne	L_0B10
	shl	ax, 1
	shl	cx, 1
	inc	cx
L_0B10:
	mov	word ptr line_x0, ax
	mov	word ptr line_y0, bx
	mov	word ptr line_x1, cx
	mov	word ptr line_y1, dx
	cmp	ax, cx
	jne	L_0B27
	cmp	bx, dx
	je	L_0AAD
L_0B27:
	mov	bp, word ptr cs:w_D042C
	dec	bp
	sub	cx, ax
	mov	word ptr w_D04C2, cx
	sub	dx, bx
	jns	L_0B3E
	neg	bp
	sub	bp, 2
	neg	dx
L_0B3E:
	mov	word ptr w_D04C4, dx
	or	cx, cx
	je	L_0B94
	or	dx, dx
	je	L_0B91
	cmp	cx, dx
	je	L_0BC1
	jb	L_0B97
	call	pixel_addr
	mov	cx, word ptr w_D04C2
	mov	bx, cx
	inc	bx
	shr	bx, 1
	neg	bx
	mov	si, word ptr w_D04C4
	mov	ah, al
	jmp	short L_0B75
L_0B66:
	sub	bx, word ptr w_D04C2
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	ror	ah, 1
	adc	di, bp
L_0B73:
	mov	al, ah
L_0B75:
	or	al, ah
	dec	cx
	js	L_0B89
	add	bx, si
	jns	L_0B66
	ror	ah, 1
	jae	L_0B75
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	jmp	L_0B73
L_0B89:
	out	dx, al
	inc	byte ptr es:[di]
L_0B8D:
	nop
	pop	es
	pop	ds
	retf
L_0B91:
	jmp	L_0BE6
L_0B94:
	jmp	L_0BD5
L_0B97:
	call	pixel_addr
	mov	cx, word ptr w_D04C4
	mov	bx, cx
	inc	bx
	shr	bx, 1
	neg	bx
	mov	si, word ptr w_D04C2
	jmp	short L_0BAD
L_0BAB:
	adc	di, bp
L_0BAD:
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	dec	cx
	js	L_0B8D
	add	bx, si
	js	L_0BAB
	sub	bx, word ptr w_D04C4
	ror	al, 1
	jmp	L_0BAB
L_0BC1:
	call	pixel_addr
	inc	cx
	inc	bp
L_0BC6:
	out	dx, al
	inc	byte ptr es:[di]
	add	di, bp
	ror	al, 1
	adc	di, 0
	loop	L_0BC6
	jmp	L_0B8D
L_0BD5:
	mov	cx, dx
	inc	cx
	inc	bp
	call	pixel_addr
	out	dx, al
L_0BDD:
	inc	byte ptr es:[di]
	add	di, bp
	loop	L_0BDD
	jmp	L_0B8D
L_0BE6:
	call	pixel_addr
	nop
	mov	bx, word ptr line_x0
	mov	bp, word ptr line_x1
	mov	cx, bx
	and	cl, 7
	mov	al, 0FFh
	shr	al, cl
	mov	cx, bp
	and	cl, 7
	mov	ah, 80h
	sar	ah, cl
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	shr	bp, 1
	shr	bp, 1
	shr	bp, 1
	sub	bp, bx
	mov	cx, bp
	nop
	jcxz	L_0C28
	out	dx, al
	inc	byte ptr es:[di]
	inc	di
	mov	al, 0FFh
	dec	cx
	je	L_0C28
	out	dx, al
L_0C22:
	inc	byte ptr es:[di]
	inc	di
	loop	L_0C22
L_0C28:
	and	al, ah
	out	dx, al
	inc	byte ptr es:[di]
	nop
	jmp	L_0B8D

; ----------------------------------------------------------------------------
; egfx_show_page (slot 30): show_page(n): copy page n to the screen (with the mouse pointer).
; ----------------------------------------------------------------------------
egfx_show_page:
	mov	bx, sp
	push	si
	mov	si, word ptr [bx+4]
	call	restore_ptr_bg
	mov	ax, si
	call	sub_0815
	shl	si, 1
	mov	ax, word ptr cs:[si+page_seg]
	mov	cl, 4
	shl	ax, cl
	mov	al, 0Ch
	mov	dx, 3D4h
	out	dx, ax
	pop	si
	retf

; ----------------------------------------------------------------------------
; egfx_swap_page (slot 35): swap_page(n): exchange the contents of page n and the screen.
; ----------------------------------------------------------------------------
egfx_swap_page:
	retf

; ----------------------------------------------------------------------------
; egfx_clear_page (slot 5): clear_page(page, colour): fill a whole page.
; ----------------------------------------------------------------------------
egfx_clear_page:
	mov	bx, sp
	push	di
	push	es
	mov	di, word ptr [bx+4]
	shl	di, 1
	mov	es, word ptr cs:[di+page_seg]
	mov	dx, 3CEh
	mov	ax, 205h
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
	mov	cx, 0FA0h
	mov	al, byte ptr [bx+6]
	mov	ah, al
	cmp	word ptr cs:w_D0412, 1
	jne	L_0C80
	shl	cx, 1
L_0C80:
	xor	di, di
	rep	stosw
	mov	ax, 5
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
	pop	es
	pop	di
	retf
b_0C90	db	80h,40h,20h,10h,8,4,2,1,8,4,2,1
b_0C9C	db	0F0h,0Fh
w_0C9E	dw	0
w_0CA0	dw	0
L_0CA2:
	jmp	L_0E5D
L_0CA5:
	jmp	L_0DA4

; ----------------------------------------------------------------------------
; egfx_dissolve_page (slot 9): dissolve_page(n): copy page n to the screen in a pseudo-random dissolve.
; ----------------------------------------------------------------------------
egfx_dissolve_page:
	mov	bx, sp
	push	bp
	push	si
	push	di
	push	ds
	push	es
	mov	si, word ptr [bx+4]
	shl	si, 1
	mov	si, word ptr cs:[si+page_seg]
	mov	dx, 3D4h
	mov	al, 0Ch
	out	dx, al
	inc	dx
	in	al, dx
	xor	ah, ah
	mov	cl, 4
	shl	ax, cl
	add	ax, word ptr cs:page_seg
	cmp	ax, si
	je	L_0CA2
	mov	ds, si
	mov	es, ax
	cmp	word ptr cs:w_0C9E, 0
	jne	L_0CA5
L_0CDC:
	inc	word ptr cs:w_0C9E
L_0CE1:
	mov	dx, 3DAh
	in	al, dx
	test	al, 8
	je	L_0CE1
L_0CE9:
	in	al, dx
	test	al, 8
	jne	L_0CE9
	mov	bp, 1
	xor	cx, cx
	mov	dx, 3CEh
	mov	ax, 205h
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
L_0CFF:
	shr	bp, 1
	jae	L_0D07
	xor	bp, 0B400h
L_0D07:
	cmp	bp, 0
	jb	L_0CFF
	mov	si, 0FFFFh
	dec	si
	mov	di, si
	and	di, 7
	shr	si, 1
	shr	si, 1
	shr	si, 1
	push	di
	mov	ah, byte ptr cs:[di+b_0C90]
	nop
	mov	al, 8
	out	dx, ax
	mov	al, 0FFh
	mov	di, ax
	xor	bl, bl
	mov	ax, 304h
L_0D2E:
	out	dx, ax
	mov	bh, byte ptr [si]
	and	bx, di
	neg	bh
	rol	bx, 1
	dec	ah
	jns	L_0D2E
	mov	al, byte ptr es:[si]
	mov	byte ptr es:[si], bl
	nop
	pop	di
	cmp	word ptr cs:w_D0412, 1
	jne	L_0D77
	mov	ah, byte ptr cs:[di+b_0C90]
	nop
	mov	al, 8
	out	dx, ax
	mov	al, 0FFh
	mov	di, ax
	xor	bl, bl
	mov	ax, 304h
L_0D5D:
	out	dx, ax
	mov	bh, byte ptr [si+1F40h]
	and	bx, di
	neg	bh
	rol	bx, 1
	dec	ah
	jns	L_0D5D
	mov	al, byte ptr es:[si+1F40h]
	mov	byte ptr es:[si+1F40h], bl
	nop
L_0D77:
	mov	ax, word ptr cs:w_0C9E
L_0D7B:
	dec	ax
	jne	L_0D7B
	inc	cx
	mov	dx, 3DAh
	in	al, dx
	mov	dx, 3CEh
	test	al, 8
	je	L_0D8D
	jmp	L_0D93
L_0D8D:
	jmp	L_0CFF
L_0D90:
	jmp	L_0CDC
L_0D93:
	cmp	cx, 163h
	ja	L_0D90
	cmp	cx, 0B1h
	ja	L_0DA4
	inc	word ptr cs:w_0CA0
L_0DA4:
	cmp	word ptr cs:w_0CA0, 0
	je	L_0DB2
	call	sub_0E63
	jmp	L_0E5D
L_0DB2:
	mov	bp, 1
	mov	cx, 0FA00h
	mov	dx, 3CEh
	mov	ax, 205h
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
L_0DC4:
	shr	bp, 1
	jae	L_0DCC
	xor	bp, 0B400h
L_0DCC:
	cmp	bp, 0FA00h
	ja	L_0DC4
	mov	si, bp
	dec	si
	mov	di, si
	and	di, 7
	shr	si, 1
	shr	si, 1
	shr	si, 1
	push	di
	mov	ah, byte ptr cs:[di+b_0C90]
	nop
	mov	al, 8
	out	dx, ax
	mov	al, 0FFh
	mov	di, ax
	xor	bl, bl
	mov	ax, 304h
L_0DF3:
	out	dx, ax
	mov	bh, byte ptr [si]
	and	bx, di
	neg	bh
	rol	bx, 1
	dec	ah
	jns	L_0DF3
	mov	al, byte ptr es:[si]
	mov	byte ptr es:[si], bl
	nop
	pop	di
	cmp	word ptr cs:w_D0412, 1
	jne	L_0E3C
	mov	ah, byte ptr cs:[di+b_0C90]
	nop
	mov	al, 8
	out	dx, ax
	mov	al, 0FFh
	mov	di, ax
	xor	bl, bl
	mov	ax, 304h
L_0E22:
	out	dx, ax
	mov	bh, byte ptr [si+1F40h]
	and	bx, di
	neg	bh
	rol	bx, 1
	dec	ah
	jns	L_0E22
	mov	al, byte ptr es:[si+1F40h]
	mov	byte ptr es:[si+1F40h], bl
	nop
L_0E3C:
	mov	ax, word ptr cs:w_0C9E
L_0E40:
	dec	ax
	jne	L_0E40
	loop	L_0E48
	jmp	L_0E4B
L_0E48:
	jmp	L_0DC4
L_0E4B:
	mov	ax, 5
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
	mov	ax, 0FF08h
	mov	byte ptr cs:b_D042F, ah
	out	dx, ax
L_0E5D:
	pop	es
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; sub_0E63
; ----------------------------------------------------------------------------
sub_0E63:
	mov	bp, 1
	mov	cx, 3E80h
	mov	dx, 3CEh
	mov	ax, 5
	mov	byte ptr cs:b_D0436, ah
	out	dx, ax
L_0E75:
	shr	bp, 1
	jae	L_0E7D
	xor	bp, 6000h
L_0E7D:
	cmp	bp, 3E80h
	ja	L_0E75
	mov	si, bp
	dec	si
	mov	bx, si
	and	bx, 1
	shr	si, 1
	mov	ah, byte ptr cs:[bx+b_0C9C]
	nop
	mov	al, 8
	out	dx, ax
	mov	ah, 3
	mov	bh, 8
L_0E9A:
	mov	al, 4
	out	dx, ax
	mov	di, dx
	mov	dx, 3C4h
	xchg	ah, bh
	mov	al, 2
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
	mov	dx, di
	xchg	ah, bh
	mov	al, byte ptr [si]
	mov	bl, byte ptr es:[si]
	mov	byte ptr es:[si], al
	cmp	word ptr cs:w_D0412, 1
	jne	L_0ECE
	mov	al, byte ptr [si+1F40h]
	mov	bl, byte ptr es:[si+1F40h]
	mov	byte ptr es:[si+1F40h], al
L_0ECE:
	shr	bh, 1
	dec	ah
	jns	L_0E9A
	nop
	loop	L_0E75
	mov	ax, 0FF08h
	mov	byte ptr cs:b_D042F, ah
	out	dx, ax
	mov	dx, 3C4h
	mov	ax, 0F02h
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
	ret
	db	0
b_0EEE	db	1,2,4,8
w_0EF2	dw	0
w_0EF4	dw	0
L_0EF6:
	jmp	L_1078

; ----------------------------------------------------------------------------
; egfx_copy_rect (slot 19): copy_rect(src_port, x, y, w, h, dst_port, x, y): copy a rectangle between pages.
; ----------------------------------------------------------------------------
egfx_copy_rect:
	push	bp
	mov	bp, sp
	push	di
	push	si
	push	es
	push	ds
	mov	si, word ptr [bp+6]
	mov	di, word ptr [bp+10h]
	mov	ax, word ptr [si]
	mov	word ptr cs:w_0EF2, ax
	mov	ax, word ptr [di]
	mov	word ptr cs:w_0EF4, ax
	mov	ax, word ptr [si+2]
	mov	bx, word ptr [si+4]
	mov	cx, word ptr [di+2]
	mov	dx, word ptr [di+4]
	mov	si, word ptr [bp+0Ch]
	mov	di, word ptr [bp+0Eh]
	or	si, si
	je	L_0EF6
	or	di, di
	je	L_0EF6
	add	ax, word ptr [bp+8]
	add	bx, word ptr [bp+0Ah]
	add	cx, word ptr [bp+12h]
	add	dx, word ptr [bp+14h]
	cmp	word ptr cs:w_D0412, 1
	jne	L_0F46
	shl	ax, 1
	shl	cx, 1
	shl	si, 1
L_0F46:
	mov	bp, DATA
	mov	ds, bp
	mov	word ptr w_D04C6, ax
	mov	word ptr w_D04C8, bx
	mov	word ptr w_D04CA, cx
	mov	word ptr w_D04CC, dx
	mov	word ptr w_D04CE, si
	mov	word ptr w_D04D0, di
	mov	cl, 3
	mov	bx, word ptr w_D04CC
	shl	bx, 1
	mov	di, word ptr [bx+row_offset]
	mov	ax, word ptr w_D04CA
	shr	ax, cl
	add	di, ax
	mov	bx, word ptr w_D04C8
	shl	bx, 1
	mov	si, word ptr [bx+row_offset]
	mov	ax, word ptr w_D04C6
	shr	ax, cl
	add	si, ax
	dec	si
	mov	cx, word ptr w_D04CA
	and	cl, 7
	mov	bl, 0FFh
	shr	bl, cl
	mov	cx, word ptr w_D04CA
	add	cx, word ptr w_D04CE
	dec	cx
	and	cl, 7
	mov	ax, 0FF80h
	shr	ax, cl
	mov	bh, al
	mov	ax, word ptr w_D04CA
	and	ax, 7
	add	ax, word ptr w_D04CE
	dec	ax
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	ch, al
	mov	bp, word ptr w_D04D0
	mov	ax, word ptr w_D04CA
	and	al, 7
	mov	dx, word ptr w_D04C6
	and	dl, 7
	sub	al, dl
	js	L_0FD4
	je	L_0FD1
	jmp	L_107E
L_0FD1:
	jmp	L_111C
L_0FD4:
	neg	al
	inc	si
	mov	cl, al
	push	di
	mov	di, word ptr cs:w_0EF2
	shl	di, 1
	mov	ds, word ptr cs:[di+page_seg]
	mov	di, word ptr cs:w_0EF4
	shl	di, 1
	mov	es, word ptr cs:[di+page_seg]
	pop	di
	mov	ah, 3
L_0FF5:
	push	ax
	push	bp
	push	si
	push	di
	mov	dx, 3CEh
	mov	al, 4
	mov	byte ptr cs:b_D0435, ah
	out	dx, ax
	xchg	dx, bx
	mov	bl, ah
	sub	bh, bh
	mov	al, 2
	mov	ah, byte ptr cs:[bx+b_0EEE]
	xchg	dx, bx
	mov	dx, 3C4h
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
L_101C:
	push	si
	push	di
	push	cx
	mov	ah, bl
	or	ch, ch
	je	L_1044
	mov	dx, word ptr [si]
	inc	si
	rol	dx, cl
	and	dl, ah
	not	ah
	and	ah, byte ptr es:[di]
	or	ah, dl
	mov	al, ah
	stosb
	jmp	L_103E
L_1039:
	lodsw
	dec	si
	rol	ax, cl
	stosb
L_103E:
	dec	ch
	jne	L_1039
	mov	ah, 0FFh
L_1044:
	and	ah, bh
	mov	dx, word ptr [si]
	rol	dx, cl
	and	dl, ah
	not	ah
	and	ah, byte ptr es:[di]
	or	ah, dl
	mov	al, ah
	stosb
	pop	cx
	pop	di
	pop	si
	mov	ax, word ptr cs:w_D042C
	add	di, ax
	add	si, ax
	dec	bp
	jne	L_101C
	pop	di
	pop	si
	pop	bp
	pop	ax
	dec	ah
	jns	L_0FF5
L_106C:
	mov	dx, 3C4h
	mov	ax, 0F02h
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
L_1078:
	pop	ds
	pop	es
	pop	si
	pop	di
	pop	bp
	retf
L_107E:
	mov	cl, al
	push	di
	mov	di, word ptr cs:w_0EF2
	shl	di, 1
	mov	ds, word ptr cs:[di+page_seg]
	mov	di, word ptr cs:w_0EF4
	shl	di, 1
	mov	es, word ptr cs:[di+page_seg]
	pop	di
	mov	ah, 3
L_109C:
	push	ax
	push	bp
	push	si
	push	di
	mov	dx, 3CEh
	mov	al, 4
	mov	byte ptr cs:b_D0435, ah
	out	dx, ax
	xchg	dx, bx
	mov	bl, ah
	sub	bh, bh
	mov	al, 2
	mov	ah, byte ptr cs:[bx+b_0EEE]
	xchg	dx, bx
	mov	dx, 3C4h
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
L_10C3:
	push	si
	push	di
	push	cx
	mov	al, bl
	or	ch, ch
	je	L_10EE
	mov	dh, byte ptr [si]
	mov	dl, byte ptr [si+1]
	inc	si
	shr	dx, cl
	and	dl, al
	not	al
	and	al, byte ptr es:[di]
	or	al, dl
	stosb
	jmp	L_10E8
L_10E1:
	lodsw
	dec	si
	ror	ax, cl
	mov	al, ah
	stosb
L_10E8:
	dec	ch
	jne	L_10E1
	mov	al, 0FFh
L_10EE:
	and	al, bh
	mov	dh, byte ptr [si]
	mov	dl, byte ptr [si+1]
	shr	dx, cl
	and	dl, al
	not	al
	and	al, byte ptr es:[di]
	or	al, dl
	stosb
	pop	cx
	pop	di
	pop	si
	add	di, word ptr cs:w_D042C
	add	si, word ptr cs:w_D042C
	dec	bp
	jne	L_10C3
	pop	di
	pop	si
	pop	bp
	pop	ax
	dec	ah
	jns	L_109C
	jmp	L_106C
L_111C:
	inc	si
	mov	cl, ch
	sub	ch, ch
	push	di
	mov	di, word ptr cs:w_0EF2
	shl	di, 1
	mov	ds, word ptr cs:[di+page_seg]
	mov	di, word ptr cs:w_0EF4
	shl	di, 1
	mov	es, word ptr cs:[di+page_seg]
	pop	di
	dec	cx
	jle	L_1170
	push	bp
	push	si
	push	di
	mov	dx, 3CEh
	mov	ax, 8
	mov	byte ptr cs:b_D042F, ah
	out	dx, ax
L_114D:
	push	si
	push	di
	push	cx
	inc	di
	inc	si
	rep	movsb
	pop	cx
	pop	di
	pop	si
	add	di, word ptr cs:w_D042C
	add	si, word ptr cs:w_D042C
	dec	bp
	jne	L_114D
	pop	di
	pop	si
	pop	bp
	mov	ax, 0FF08h
	mov	byte ptr cs:b_D042F, ah
	out	dx, ax
L_1170:
	inc	cx
	mov	ah, 3
L_1173:
	push	ax
	push	bp
	push	si
	push	di
	mov	dx, 3CEh
	mov	al, 4
	mov	byte ptr cs:b_D0435, ah
	out	dx, ax
	xchg	dx, bx
	mov	bl, ah
	sub	bh, bh
	mov	al, 2
	mov	ah, byte ptr cs:[bx+b_0EEE]
	xchg	dx, bx
	mov	dx, 3C4h
	mov	byte ptr cs:b_D0437, ah
	out	dx, ax
L_119A:
	push	si
	push	di
	push	cx
	mov	ah, bl
	or	cl, cl
	je	L_11BA
	mov	ch, byte ptr [si]
	and	ch, ah
	not	ah
	and	ah, byte ptr es:[di]
	or	ah, ch
	mov	al, ah
	stosb
	sub	ch, ch
	add	si, cx
	dec	cx
	add	di, cx
	mov	ah, 0FFh
L_11BA:
	and	ah, bh
	mov	ch, byte ptr [si]
	and	ch, ah
	not	ah
	and	ah, byte ptr es:[di]
	or	ah, ch
	mov	al, ah
	stosb
	pop	cx
	pop	di
	pop	si
	add	di, word ptr cs:w_D042C
	add	si, word ptr cs:w_D042C
	dec	bp
	jne	L_119A
	pop	di
	pop	si
	pop	bp
	pop	ax
	dec	ah
	jns	L_1173
	jmp	L_106C
	db	0
img_ptr	dw	0
img_seg	dw	0
img_block	dw	0
img_block_end	dw	0
img_limit	dw	0
img_skip	dw	0
img_trail	dw	0
img_len	dw	0
w_11F6	dw	0
w_11F8	dw	0
b_11FA	db	0
b_11FB	db	0
b_11FC	db	0
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
w_122C	dw	0
b_122E	db	0
b_122F	db	0
b_1230	db	0
b_1231	db	0
b_1232	db	0
b_1233	db	0
b_1234	db	0
	EVEN
row_buffer	dw	160 dup (0)

; ----------------------------------------------------------------------------
; egfx_begin_image_grab (slot 17): begin_image_grab(): allocate the largest free DOS block to collect images in.
; ----------------------------------------------------------------------------
egfx_begin_image_grab:
	call	far ptr egfx_mem_avail
	mov	bx, ax
	or	bx, bx
	je	L_1387
	mov	ah, 48h
	int	21h
	jae	L_138B
L_1387:
	xor	ax, ax
	xor	bx, bx
L_138B:
	add	bx, ax
	mov	word ptr cs:img_ptr, 0
	mov	word ptr cs:img_seg, ax
	mov	word ptr cs:img_block, ax
	mov	word ptr cs:img_block_end, bx
	retf

; ----------------------------------------------------------------------------
; egfx_end_image_grab (slot 7): end_image_grab(): shrink the image block to what was used; returns its segment.
; ----------------------------------------------------------------------------
egfx_end_image_grab:
	mov	ax, word ptr cs:img_block
	or	ax, ax
	je	L_13C2
	mov	bx, word ptr cs:img_seg
	sub	bx, ax
	mov	es, ax
	mov	ah, 4Ah
	or	bx, bx
	jne	L_13BB
	mov	ah, 49h
L_13BB:
	int	21h
	jb	L_13C2
	mov	ax, es
	retf
L_13C2:
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; egfx_begin_image (slot 34): begin_image(w, h): start an image; returns its segment (0 if out of room).
; ----------------------------------------------------------------------------
egfx_begin_image:
	mov	ax, word ptr cs:img_block_end
	sub	ax, word ptr cs:img_seg
	jbe	L_1437
	cmp	ax, 1000h
	jb	L_13D8
	mov	ax, 0FFFh
L_13D8:
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
	mov	cx, 15F1h
	cmp	word ptr cs:w_D0412, 1
	jne	L_1400
	shl	ax, 1
	mov	cx, 1625h
L_1400:
	mov	word ptr cs:w_11F8, cx
	mov	byte ptr cs:b_11FA, 1
	mov	cx, ax
	add	ax, 7
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	word ptr cs:img_width, ax
	dec	cx
	and	cl, 7
	mov	al, 80h
	sar	al, cl
	mov	byte ptr cs:b_11FB, al
	mov	ax, word ptr [bx+6]
	stosw
	mov	word ptr cs:img_rows, ax
	mov	word ptr cs:img_ptr, di
	mov	ax, es
	pop	di
	retf
L_1437:
	xor	ax, ax
	mov	word ptr cs:img_ptr, ax
	mov	word ptr cs:img_seg, ax
	retf

; ----------------------------------------------------------------------------
; egfx_end_image (slot 32): end_image(): close the image being built; returns its segment.
; ----------------------------------------------------------------------------
egfx_end_image:
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
; egfx_image_add_row (slot 33): image_add_row(row): append a row to the image being built.
; ----------------------------------------------------------------------------
egfx_image_add_row:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	si, word ptr [bp+6]
	les	di, dword ptr cs:img_ptr
	mov	ax, es
	or	ax, ax
	jne	L_1475
	jmp	L_151F
L_1475:
	mov	ax, word ptr cs:img_width
	shl	ax, 1
	shl	ax, 1
	add	ax, 4
	add	ax, di
	cmp	ax, word ptr cs:img_limit
	jbe	L_1497
	dec	word ptr es:[2]
	xor	ax, ax
	mov	word ptr cs:img_block_end, ax
	jmp	L_151F
L_1497:
	xor	ax, ax
	mov	word ptr cs:img_skip, ax
	mov	word ptr cs:img_trail, ax
	mov	word ptr cs:img_len, ax
	xor	byte ptr cs:b_11FA, 1
	mov	bp, di
	stosw
	stosw
	mov	ax, word ptr cs:img_width
	mov	word ptr cs:w_11F6, ax
L_14B7:
	call	word ptr cs:w_11F8
	je	L_14C8
	mov	word ptr cs:img_trail, 0
	jmp	L_14E4
L_14C8:
	cmp	word ptr cs:img_len, 0
	jne	L_14DF
	inc	word ptr cs:img_skip
	dec	word ptr cs:w_11F6
	jne	L_14B7
	jmp	L_14F6
L_14DF:
	inc	word ptr cs:img_trail
L_14E4:
	inc	word ptr cs:img_len
	mov	ax, bx
	stosw
	mov	ax, dx
	stosw
	dec	word ptr cs:w_11F6
	jne	L_14B7
L_14F6:
	mov	ax, word ptr cs:img_len
	mov	bx, word ptr cs:img_skip
	mov	cx, word ptr cs:img_trail
	or	cx, cx
	je	L_1510
	sub	ax, cx
	shl	cx, 1
	shl	cx, 1
	sub	di, cx
L_1510:
	mov	word ptr es:[bp], ax
	mov	word ptr es:[bp+2], bx
	mov	word ptr cs:img_ptr, di
	mov	ax, es
L_151F:
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; egfx_get_image (slot 2): get_image(page, x, y, w, h): grab a block of a page as an image.
; ----------------------------------------------------------------------------
egfx_get_image:
	push	bp
	mov	bp, sp
	push	si
	push	ds
	push	word ptr [bp+0Eh]
	push	word ptr [bp+0Ch]
	call	far ptr egfx_begin_image
	add	sp, 4
	or	ax, ax
	je	L_1598
	cmp	word ptr cs:img_rows, 0
	je	L_1598
	cmp	word ptr cs:img_width, 0
	je	L_1598
	mov	si, word ptr [bp+0Ah]
	shl	si, 1
	mov	si, word ptr cs:[si+row_offset]
	mov	bx, word ptr [bp+6]
	shl	bx, 1
	mov	ds, word ptr cs:[bx+page_seg]
	mov	bx, word ptr [bp+8]
	cmp	word ptr cs:w_D0412, 1
	jne	L_156B
	shl	bx, 1
L_156B:
	mov	ax, bx
	and	ax, 7
	mov	byte ptr cs:b_11FC, al
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	add	si, bx
	mov	word ptr cs:w_11F8, 15A1h
L_1583:
	push	si
	call	far ptr egfx_image_add_row
	add	sp, 2
	add	si, word ptr cs:w_D042C
	dec	word ptr cs:img_rows
	jne	L_1583
L_1598:
	call	far ptr egfx_end_image
	pop	ds
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; L_15A1
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_15A1:
	mov	cl, byte ptr cs:b_11FC
	mov	dx, 3CEh
	mov	ax, 304h
	cli
	out	dx, ax
	inc	dx
	mov	ax, word ptr [si]
	rol	ax, cl
	mov	bh, al
	mov	al, 2
	out	dx, al
	mov	ax, word ptr [si]
	rol	ax, cl
	mov	bl, al
	mov	al, 1
	out	dx, al
	mov	ax, word ptr [si]
	rol	ax, cl
	mov	ch, al
	mov	al, 0
	out	dx, ax
	mov	ax, word ptr [si]
	rol	ax, cl
	mov	dl, al
	sti
	mov	dh, ch
	xchg	dx, bx
	inc	si
	cmp	word ptr cs:w_11F6, 1
	jne	L_15E8
	mov	al, byte ptr cs:b_11FB
	mov	ah, al
	and	bx, ax
	and	dx, ax
L_15E8:
	mov	al, dh
	or	al, dl
	or	al, bh
	or	al, bl
	ret

; ----------------------------------------------------------------------------
; L_15F1
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_15F1:
	xor	bx, bx
	xor	dx, dx
	inc	dh
L_15F7:
	lodsb
	shr	al, 1
	rcl	bl, 1
	shr	al, 1
	rcl	bh, 1
	shr	al, 1
	rcl	dl, 1
	shr	al, 1
	rcl	dh, 1
	jae	L_15F7
	cmp	word ptr cs:w_11F6, 1
	jne	L_161C
	mov	al, byte ptr cs:b_11FB
	mov	ah, al
	and	bx, ax
	and	dx, ax
L_161C:
	mov	al, dh
	or	al, dl
	or	al, bh
	or	al, bl
	ret

; ----------------------------------------------------------------------------
; L_1625
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_1625:
	push	bp
	xor	bx, bx
	xor	dx, dx
	inc	dh
L_162C:
	lodsb
	shl	al, 1
	add	al, byte ptr cs:b_11FA
	xor	ah, ah
	mov	bp, ax
	mov	al, byte ptr cs:[bp+3DAh]
	shr	al, 1
	rcl	bl, 1
	shr	al, 1
	rcl	bh, 1
	shr	al, 1
	rcl	dl, 1
	shr	al, 1
	rcl	dh, 1
	shr	al, 1
	rcl	bl, 1
	shr	al, 1
	rcl	bh, 1
	shr	al, 1
	rcl	dl, 1
	shr	al, 1
	rcl	dh, 1
	jae	L_162C
	cmp	word ptr cs:w_11F6, 1
	jne	L_1671
	mov	al, byte ptr cs:b_11FB
	mov	ah, al
	and	bx, ax
	and	dx, ax
L_1671:
	mov	al, dh
	or	al, dl
	or	al, bh
	or	al, bl
	pop	bp
	ret

; ----------------------------------------------------------------------------
; egfx_draw_image_scaled (slot 21): draw_image_scaled(port, x, y, w, h, image, param): draw an image scaled (mirrored when w or h < 0).
; ----------------------------------------------------------------------------
egfx_draw_image_scaled:
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
	je	L_16C0
	call	clip_image
	jb	L_16C0
	call	far ptr blit_image_scaled
L_16C0:
	mov	ax, 1212h
	mov	dx, cs
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; egfx_draw_image (slot 6): draw_image(port, x, y, image): draw an image clipped to the port; returns a far pointer to the drawn rectangle.
; ----------------------------------------------------------------------------
egfx_draw_image:
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
	je	L_16FA
	call	clip_image
	jb	L_16FA
	call	far ptr blit_image
L_16FA:
	mov	ax, 1212h
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
	jns	L_1717
	mov	ax, di
	neg	ax
	cmp	ax, word ptr cs:dst_height
	jae	L_1763
	mov	word ptr cs:clip_top, ax
L_1717:
	mov	ax, di
	add	ax, word ptr cs:dst_height
	dec	ax
	mov	bx, word ptr [bp+8]
	or	bx, bx
	js	L_1763
	cmp	di, bx
	jg	L_1763
	sub	ax, bx
	jle	L_1732
	mov	word ptr cs:clip_bottom, ax
L_1732:
	or	dx, dx
	jns	L_1745
	mov	ax, dx
	neg	ax
	cmp	ax, word ptr cs:dst_width
	jae	L_1763
	mov	word ptr cs:clip_left, ax
L_1745:
	mov	ax, dx
	add	ax, word ptr cs:dst_width
	dec	ax
	mov	bx, word ptr [bp+6]
	or	bx, bx
	js	L_1763
	cmp	dx, bx
	jg	L_1763
	sub	ax, bx
	jle	L_1765
	mov	word ptr cs:clip_right, ax
	jmp	L_1765
L_1763:
	stc
	ret
L_1765:
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
	je	L_17D3
	mov	ax, word ptr ds:[0]
	or	ax, ax
	je	L_17D3
	mov	ax, word ptr ds:[2]
	or	ax, ax
L_17D3:
	ret

; ----------------------------------------------------------------------------
; egfx_draw_image_noclip (slot 31): draw_image_noclip(port, x, y, image): draw an image without clipping.
; ----------------------------------------------------------------------------
egfx_draw_image_noclip:
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
	je	L_17F2
	call	far ptr blit_image
L_17F2:
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
	shl	di, 1
	mov	di, word ptr cs:[di+row_offset]
	lodsw
	mov	bp, ax
	cmp	word ptr cs:w_D0412, 1
	jne	L_182E
	shl	dx, 1
	shl	bp, 1
	shl	word ptr cs:clip_left, 1
	shl	word ptr cs:clip_right, 1
L_182E:
	mov	cx, dx
	and	cx, 7
	mov	byte ptr cs:b_1233, cl
	mov	al, 0FFh
	shr	al, cl
	mov	byte ptr cs:b_122E, al
	xor	bx, bx
	or	cl, cl
	je	L_1849
	not	al
	inc	bx
L_1849:
	mov	byte ptr cs:b_122F, al
	mov	word ptr cs:w_122C, bx
	mov	cx, dx
	add	cx, word ptr cs:clip_left
	mov	bx, cx
	and	cx, 7
	mov	al, 0FFh
	shr	al, cl
	mov	byte ptr cs:b_1231, al
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	add	di, bx
	add	dx, bp
	dec	dx
	sub	dx, word ptr cs:clip_right
	mov	cx, dx
	and	cl, 7
	mov	al, 80h
	sar	al, cl
	mov	byte ptr cs:b_1232, al
	mov	ax, dx
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	sub	ax, bx
	inc	ax
	mov	word ptr cs:blit_cols, ax
	lodsw
	sub	ax, word ptr cs:clip_top
	sub	ax, word ptr cs:clip_bottom
	jg	L_18A2
	jmp	L_1970
L_18A2:
	mov	word ptr cs:blit_rows, ax
	mov	cx, word ptr cs:clip_top
	jcxz	L_18B9
L_18AD:
	lodsw
	add	si, 2
	shl	ax, 1
	shl	ax, 1
	add	si, ax
	loop	L_18AD
L_18B9:
	xor	ah, ah
	mov	al, byte ptr cs:b_1233
	add	ax, word ptr cs:clip_left
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	word ptr cs:clip_left, ax
	mov	al, byte ptr cs:b_1233
	cmp	al, 4
	jbe	L_18D8
	sub	al, 8
L_18D8:
	mov	byte ptr cs:b_1233, al
L_18DC:
	lodsw
	mov	dx, ax
	lodsw
	or	dx, dx
	je	L_1961
	mov	bp, dx
	shl	bp, 1
	shl	bp, 1
	add	bp, si
	push	bp
	push	di
	mov	bh, byte ptr cs:b_1231
	mov	bl, byte ptr cs:b_1232
	mov	cx, word ptr cs:blit_cols
	add	dx, word ptr cs:w_122C
	sub	ax, word ptr cs:clip_left
	je	L_1928
	jb	L_1919
	add	di, ax
	sub	cx, ax
	jbe	L_195F
	mov	bh, byte ptr cs:b_122E
	jmp	L_192D
L_1919:
	neg	ax
	sub	dx, ax
	jbe	L_195F
	shl	ax, 1
	shl	ax, 1
	add	si, ax
	jmp	L_192D
L_1928:
	and	bh, byte ptr cs:b_122E
L_192D:
	cmp	dx, cx
	je	L_193D
	ja	L_1942
	mov	cx, dx
	mov	bl, byte ptr cs:b_122F
	jmp	L_1942
L_193D:
	and	bl, byte ptr cs:b_122F
L_1942:
	mov	byte ptr cs:b_1230, bl
	mov	bl, cl
	sub	si, 4
	cmp	byte ptr cs:b_1233, 0
	je	L_1959
	js	L_1981
	jmp	L_19EF
L_1959:
	add	si, 4
	jmp	L_1A5D
L_195F:
	pop	di
	pop	si
L_1961:
	add	di, word ptr cs:w_D042C
	dec	byte ptr cs:blit_rows
	je	L_1970
	jmp	L_18DC
L_1970:
	mov	dx, 3C4h
	mov	ax, 0F02h
	out	dx, ax
	mov	dx, 3CEh
	mov	ax, 0FF08h
	out	dx, ax
	pop	es
	pop	bp
	retf
L_1981:
	xchg	bx, bp
	mov	cl, byte ptr cs:b_1233
	neg	cl
	lodsw
	mov	dx, ax
	lodsw
	mov	bx, ax
	lodsw
	xchg	dl, ah
	shl	ax, cl
	shl	dx, cl
	mov	dl, ah
	lodsw
	sub	si, 4
	xchg	bl, ah
	shl	ax, cl
	shl	bx, cl
	mov	bl, ah
	or	ah, bh
	or	ah, dl
	or	ah, dh
	mov	cx, dx
	xchg	bp, bx
	cmp	bl, 1
	je	L_19E5
L_19B4:
	and	ah, bh
	je	L_19EC
	nop
	mov	al, 8
	mov	dx, 3CEh
	out	dx, ax
	mov	dl, 0C4h
	mov	ax, 102h
	out	dx, ax
	xchg	byte ptr es:[di], cl
	inc	dx
	out	dx, al
	mov	byte ptr es:[di], ch
	shl	al, 1
	out	dx, al
	mov	cx, bp
	mov	byte ptr es:[di], cl
	shl	al, 1
	out	dx, al
	mov	al, ch
	stosb
	nop
L_19DC:
	mov	bh, 0FFh
	dec	bl
	jne	L_1981
	jmp	L_195F
L_19E5:
	and	bh, byte ptr cs:b_1230
	jmp	L_19B4
L_19EC:
	inc	di
	jmp	L_19DC
L_19EF:
	xchg	bx, bp
	mov	cl, byte ptr cs:b_1233
	lodsw
	mov	dx, ax
	lodsw
	mov	bx, ax
	lodsw
	xchg	dl, ah
	shr	ax, cl
	shr	dx, cl
	mov	dh, al
	lodsw
	sub	si, 4
	xchg	bl, ah
	ror	ax, cl
	ror	bx, cl
	mov	bh, al
	mov	ah, bl
	or	ah, bh
	or	ah, dl
	or	ah, dh
	mov	cx, dx
	xchg	bp, bx
	cmp	bl, 1
	je	L_1A53
L_1A22:
	and	ah, bh
	je	L_1A5A
	nop
	mov	al, 8
	mov	dx, 3CEh
	out	dx, ax
	mov	dl, 0C4h
	mov	ax, 102h
	out	dx, ax
	xchg	byte ptr es:[di], ch
	inc	dx
	out	dx, al
	mov	byte ptr es:[di], cl
	shl	al, 1
	out	dx, al
	mov	cx, bp
	mov	byte ptr es:[di], ch
	shl	al, 1
	out	dx, al
	mov	al, cl
	stosb
	nop
L_1A4A:
	mov	bh, 0FFh
	dec	bl
	jne	L_19EF
	jmp	L_195F
L_1A53:
	and	bh, byte ptr cs:b_1230
	jmp	L_1A22
L_1A5A:
	inc	di
	jmp	L_1A4A
L_1A5D:
	lodsw
	mov	cx, ax
	lodsw
	mov	bp, ax
	or	ah, al
	or	ah, cl
	or	ah, ch
	cmp	bl, 1
	je	L_1A9F
L_1A6E:
	and	ah, bh
	je	L_1AA6
	nop
	mov	al, 8
	mov	dx, 3CEh
	out	dx, ax
	mov	dl, 0C4h
	mov	ax, 102h
	out	dx, ax
	xchg	byte ptr es:[di], cl
	inc	dx
	out	dx, al
	mov	byte ptr es:[di], ch
	shl	al, 1
	out	dx, al
	mov	cx, bp
	mov	byte ptr es:[di], cl
	shl	al, 1
	out	dx, al
	mov	al, ch
	stosb
	nop
L_1A96:
	mov	bh, 0FFh
	dec	bl
	jne	L_1A5D
	jmp	L_195F
L_1A9F:
	and	bh, byte ptr cs:b_1230
	jmp	L_1A6E
L_1AA6:
	inc	di
	jmp	L_1A96
L_1AA9:
	jmp	L_1BCE

; ----------------------------------------------------------------------------
; blit_image_scaled
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
	jle	L_1AA9
	mov	word ptr blit_cols, ax
	mov	ax, word ptr dst_height
	sub	ax, word ptr clip_top
	sub	ax, word ptr clip_bottom
	jle	L_1AA9
	mov	word ptr blit_rows, ax
	mov	ax, word ptr w_D042C
	mov	word ptr row_step, ax
	mov	cx, word ptr clip_top
	add	di, cx
	cmp	word ptr flip_y, 0
	je	L_1B18
	neg	word ptr row_step
	mov	cx, word ptr clip_bottom
	add	di, word ptr blit_rows
	dec	di
L_1B18:
	mov	ax, word ptr dst_height
	inc	ax
	shr	ax, 1
	neg	ax
L_1B20:
	dec	cx
	js	L_1B3D
	add	ax, word ptr src_height
	js	L_1B20
L_1B29:
	mov	bx, word ptr es:[si]
	shl	bx, 1
	shl	bx, 1
	add	si, bx
	add	si, 4
	sub	ax, word ptr dst_height
	js	L_1B20
	jmp	L_1B29
L_1B3D:
	mov	word ptr step_y, ax
	mov	cx, word ptr clip_left
	add	dx, cx
	mov	byte ptr scale_dir, 0CFh
	mov	byte ptr scale_skip, 0D7h
	mov	byte ptr b_1CD1, 0CFh
	mov	byte ptr b_1CD3, 0D7h
	cmp	word ptr flip_x, 0
	je	L_1B7E
	mov	byte ptr scale_dir, 0C7h
	mov	byte ptr scale_skip, 0DFh
	mov	byte ptr b_1CD1, 0C7h
	mov	byte ptr b_1CD3, 0DFh
	mov	cx, word ptr clip_right
	add	dx, word ptr blit_cols
	dec	dx
L_1B7E:
	mov	ax, word ptr dst_width
	inc	ax
	shr	ax, 1
	neg	ax
	xor	bx, bx
L_1B88:
	dec	cx
	js	L_1B9A
	add	ax, word ptr src_width
	js	L_1B88
L_1B91:
	inc	bx
	sub	ax, word ptr dst_width
	js	L_1B88
	jmp	L_1B91
L_1B9A:
	mov	word ptr step_x, ax
	mov	word ptr clip_left, bx
	mov	cx, dx
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1
	and	cx, 7
	mov	al, 80h
	shr	al, cl
	mov	byte ptr b_1234, al
	shl	di, 1
	mov	di, word ptr [di+row_offset]
	add	di, dx
	mov	ds, word ptr src_seg
	mov	dx, 3CEh
	mov	ax, 0F01h
	mov	byte ptr cs:b_D0432, ah
	out	dx, ax
	jmp	L_1BE4
L_1BCE:
	mov	dx, 3CEh
	mov	ax, 1
	mov	byte ptr cs:b_D0432, ah
	out	dx, ax
	mov	ax, 0FF08h
	out	dx, ax
	pop	es
	pop	bp
	retf
L_1BE1:
	jmp	L_1C94
L_1BE4:
	push	si
	lodsw
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, ax
	je	L_1BE1
	lodsw
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	cx, ax
	add	ax, bx
	cmp	ax, word ptr cs:clip_left
	jbe	L_1BE1
	push	di
	mov	bp, di
	mov	ax, cs
	mov	es, ax
	lea	di, row_buffer
	xor	al, al
	rep	stosb
	mov	cx, bx
L_1C13:
	test	cx, 7
	jne	L_1C1F
	lodsw
	mov	bx, ax
	lodsw
	mov	dx, ax
L_1C1F:
	xor	al, al
	shl	dh, 1
	rcl	al, 1
	shl	dl, 1
	rcl	al, 1
	shl	bh, 1
	rcl	al, 1
	shl	bl, 1
	rcl	al, 1
	stosb
	loop	L_1C13
	lea	cx, row_buffer
	add	cx, word ptr cs:src_width
	sub	cx, di
	jbe	L_1C45
	xor	al, al
	rep	stosb
L_1C45:
	mov	ax, cs
	mov	ds, ax
	lea	si, row_buffer
	mov	di, bp
	mov	es, word ptr dst_seg
	mov	bh, byte ptr b_1234
	mov	dx, 3CEh
	mov	bp, word ptr step_x
	add	si, word ptr clip_left
	mov	cx, word ptr blit_cols
L_1C66:
	lodsb
	mov	bl, al
L_1C69:
	dec	cx
	js	L_1C93
	or	bl, bl
	je	L_1CD0
	mov	al, 0
	mov	ah, bl
	nop
	out	dx, ax
	mov	al, 8
	mov	ah, bh
	out	dx, ax
	inc	byte ptr es:[di]
	nop
scale_dir	equ	byte ptr $+1
	ror	bh, 1
scale_skip	equ	byte ptr $+1
	adc	di, 0
	add	bp, word ptr src_width
	js	L_1C69
L_1C8A:
	sub	bp, word ptr dst_width
	js	L_1C66
	inc	si
	jmp	L_1C8A
L_1C93:
	pop	di
L_1C94:
	pop	si
	dec	word ptr cs:blit_rows
	je	L_1CCA
	add	di, word ptr cs:row_step
	mov	ds, word ptr cs:src_seg
	mov	ax, word ptr cs:step_y
	add	ax, word ptr cs:src_height
	js	L_1CC3
L_1CB1:
	mov	bx, word ptr [si]
	shl	bx, 1
	shl	bx, 1
	add	si, bx
	add	si, 4
	sub	ax, word ptr cs:dst_height
	jns	L_1CB1
L_1CC3:
	mov	word ptr cs:step_y, ax
	jmp	L_1BE4
L_1CCA:
	jmp	L_1BCE
L_1CCD:
	dec	cx
	js	L_1C93
L_1CD0:
b_1CD1	equ	byte ptr $+1
	ror	bh, 1
b_1CD3	equ	byte ptr $+1
	adc	di, 0
	add	bp, word ptr cs:src_width
	js	L_1CCD
L_1CDC:
	sub	bp, word ptr cs:dst_width
	js	L_1C66
	inc	si
	jmp	L_1CDC

; ----------------------------------------------------------------------------
; egfx_copy_rows_to_screen (slot 49): AX = first row, CX = last row, BX = span table, SI/DI = pages: copy each row's span.
; ----------------------------------------------------------------------------
egfx_copy_rows_to_screen:
	or	ax, ax
	js	L_1D47
	push	ds
	push	es
	shl	si, 1
	shl	di, 1
	mov	ds, word ptr cs:[si+page_seg]
	mov	es, word ptr cs:[di+page_seg]
	mov	bp, bx
	mov	bx, ax
	shl	bx, 1
	mov	dx, 3CEh
	mov	ax, 8
	out	dx, ax
	mov	dx, cx
	shl	dx, 1
L_1D0B:
	mov	si, bx
	mov	ax, word ptr [bp+si]
	mov	cx, word ptr [bp+si+190h]
	shr	ax, 1
	shr	ax, 1
	shr	cx, 1
	shr	cx, 1
	cmp	word ptr cs:w_D0412, 1
	je	L_1D27
	shr	cx, 1
	shr	ax, 1
L_1D27:
	sub	cx, ax
	jb	L_1D37
	inc	cx
	mov	di, word ptr cs:[si+row_offset]
	add	di, ax
	mov	si, di
	rep	movsb
L_1D37:
	add	bx, 2
	cmp	bx, dx
	jbe	L_1D0B
	mov	dx, 3CEh
	mov	ax, 0FF08h
	out	dx, ax
	pop	es
	pop	ds
L_1D47:
	retf
	db	14h,16h,14h,16h,14h,16h,14h,16h,14h,4,14h,16h,14h,4,14h,16h
shake_seed	dw	4D2h
shake_count	db	0

; ----------------------------------------------------------------------------
; egfx_set_shake (slot 28): set_shake(n): shake the screen for the next n calls of shake_tick.
; ----------------------------------------------------------------------------
egfx_set_shake:
	mov	bx, sp
	mov	al, byte ptr [bx+4]
	mov	byte ptr cs:shake_count, al
	retf

; ----------------------------------------------------------------------------
; egfx_shake_tick (slot 50): shake_tick(): while shaking, move the display start at random.
; ----------------------------------------------------------------------------
egfx_shake_tick:
	mov	dx, 3DAh
	in	al, dx
	test	al, 8
	je	L_1DA4
	mov	ax, word ptr cs:shake_seed
	shl	ax, 1
	shl	ax, 1
	add	ax, word ptr cs:shake_seed
	inc	ax
	mov	word ptr cs:shake_seed, ax
	nop
	mov	dx, 3C0h
	cmp	byte ptr cs:shake_count, 0
	je	L_1D9C
	dec	byte ptr cs:shake_count
	jne	L_1D94
	xor	bl, bl
L_1D94:
	mov	al, 13h
	out	dx, al
	mov	al, bl
	and	al, 7
	out	dx, al
L_1D9C:
	mov	al, 20h
	out	dx, al
	mov	dx, 3DAh
	in	al, dx
	nop
L_1DA4:
	retf
	db	0
L_1DA6:
	and	al, 7Fh
	mov	ah, byte ptr ds:[4DEh]
	mov	byte ptr ds:[4DAh], al
	call	far ptr egfx_set_draw_color
	jmp	L_1E16
L_1DB7:
	call	far ptr egfx_nop39
	pop	bp
	mov	al, byte ptr ds:[4DAh]
	mov	byte ptr [bp+0Ch], al
	retf
L_1DC4:
	jmp	L_1DB7
L_1DC6:
	jmp	L_1DA6

; ----------------------------------------------------------------------------
; draw_glyphs
; ----------------------------------------------------------------------------
draw_glyphs:
	mov	ax, word ptr [bp+0Ch]
	mov	byte ptr ds:[4DAh], al
	mov	byte ptr ds:[4DEh], ah
	call	far ptr egfx_set_draw_color
	mov	al, byte ptr [bp+0Eh]
	mov	byte ptr ds:[4DBh], al
	mov	al, byte ptr [bp+0Ah]
	mov	byte ptr ds:[4DCh], al
	push	bp
	mov	bp, word ptr ds:[4EFh]
	mov	bx, es
	shl	bx, 1
	mov	es, word ptr cs:[bx+page_seg]
	mov	bx, word ptr ds:[4F3h]
	shl	bx, 1
	mov	ax, word ptr [bx+27Ah]
	mov	word ptr ds:[4D8h], ax
	mov	ax, word ptr cs:w_D042C
	mul	byte ptr ds:[4EDh]
	mov	word ptr ds:[4D4h], ax
	mov	ax, word ptr ds:[4EFh]
	mul	byte ptr ds:[4EDh]
	mov	word ptr ds:[4D6h], ax
	mov	dx, 3CEh
L_1E16:
	mov	ax, word ptr ss:[si]
	inc	si
	or	al, al
	je	L_1DC4
	js	L_1DC6
	push	si
	sub	al, byte ptr ds:[4E2h]
	mov	si, ax
	and	si, 0FFh
	mov	cl, byte ptr ds:[4E7h]
	or	cl, cl
	jne	L_1E3D
	mov	bx, word ptr ds:[4E0h]
	mov	cl, byte ptr [bx+si]
	add	cl, byte ptr ds:[4E3h]
L_1E3D:
	or	ah, ah
	jne	L_1E45
	sub	cl, byte ptr ds:[4ECh]
L_1E45:
	sub	cl, byte ptr ds:[4E8h]
	mov	byte ptr ds:[4DFh], cl
	dec	cl
	mov	bx, 8000h
	sar	bx, cl
	mov	word ptr ds:[4D2h], bx
	mov	ax, word ptr ds:[4F1h]
	mov	cl, al
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	di, word ptr ds:[4D8h]
	add	di, ax
	and	cl, 7
	shr	bx, cl
	sub	cl, 8
	neg	cl
	mov	byte ptr ds:[4DDh], cl
	mov	cl, byte ptr ds:[4E6h]
	shl	si, cl
	add	si, word ptr ds:[4E4h]
L_1E81:
	nop
	cmp	byte ptr ds:[4DCh], 0
	je	L_1EA9
	xor	al, al
	mov	ah, byte ptr ds:[4DBh]
	out	dx, ax
	mov	al, 8
	mov	ah, bh
	out	dx, ax
	mov	cl, byte ptr ds:[4EDh]
	xor	ch, ch
L_1E9B:
	inc	byte ptr es:[di]
	add	di, word ptr cs:w_D042C
	loop	L_1E9B
	sub	di, word ptr ds:[4D4h]
L_1EA9:
	mov	ah, byte ptr ds:[4DAh]
	sub	al, al
	out	dx, ax
	mov	al, 8
	out	dx, al
	inc	dx
	mov	cl, byte ptr ds:[4DDh]
	add	cl, byte ptr ds:[4E8h]
	and	cl, 0Fh
	mov	ch, byte ptr ds:[4EDh]
L_1EC3:
	mov	ax, word ptr [si]
	xchg	ah, al
	rol	ax, cl
	and	al, bh
	out	dx, al
	inc	byte ptr es:[di]
	add	di, word ptr cs:w_D042C
	add	si, bp
	dec	ch
	jne	L_1EC3
	nop
	dec	dx
	inc	di
	sub	di, word ptr ds:[4D4h]
	sub	si, word ptr ds:[4D6h]
	mov	cl, byte ptr ds:[4DDh]
	cmp	cl, byte ptr ds:[4DFh]
	jae	L_1EFC
	mov	bx, word ptr ds:[4D2h]
	shl	bx, cl
	add	byte ptr ds:[4DDh], 8
	jmp	L_1E81
L_1EFC:
	pop	si
	xor	ah, ah
	mov	byte ptr ds:[4E8h], ah
	mov	al, byte ptr ds:[4DFh]
	add	word ptr ds:[4F1h], ax
	jmp	L_1E16
	db	0

; ----------------------------------------------------------------------------
; egfx_patch_font (slot 15): patch_font(font, data): copy a font image over font n.
; ----------------------------------------------------------------------------
egfx_patch_font:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	mov	ax, DATA
	mov	es, ax
	mov	si, word ptr [bp+8]
	mov	di, word ptr [bp+6]
	cmp	di, word ptr es:[500h]
	ja	L_1F59
	shl	di, 1
	je	L_1F59
	mov	di, word ptr es:[di+500h]
	add	di, 500h
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
L_1F59:
	pop	es
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; egfx_char_width (slot 4): char_width(font, ch): width of a character (0 if not in the font).
; ----------------------------------------------------------------------------
egfx_char_width:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	cl, byte ptr [bp+8]
	or	cl, cl
	js	L_1FA9
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr ds:[500h]
	ja	L_1FA9
	shl	bx, 1
	je	L_1FA9
	mov	bx, word ptr [bx+500h]
	add	bx, 500h
	cmp	cl, byte ptr [bx-8]
	jb	L_1FA9
	cmp	cl, byte ptr [bx-7]
	ja	L_1FA9
	mov	ah, byte ptr [bx-3]
	mov	al, byte ptr [bx-5]
	or	al, al
	jne	L_1FA9
	mov	al, cl
	mov	cl, byte ptr [bx-7]
	sub	cl, al
	xor	ch, ch
	add	bx, -9
	sub	bx, cx
	mov	al, byte ptr [bx]
L_1FA9:
	add	al, ah
	cbw
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; egfx_font_height (slot 10): font_height(font): height of a font's characters.
; ----------------------------------------------------------------------------
egfx_font_height:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	xor	ax, ax
	mov	bx, word ptr [bp+6]
	cmp	bx, word ptr ds:[500h]
	ja	L_1FD5
	shl	bx, 1
	je	L_1FD5
	mov	bx, word ptr [bx+500h]
	add	bx, 500h
	mov	al, byte ptr [bx-4]
	add	al, byte ptr [bx-2]
L_1FD5:
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; egfx_draw_text (slot 20): draw_text(port, x, y, string, ?): draw a string clipped to the port.
; ----------------------------------------------------------------------------
egfx_draw_text:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	bx, word ptr [bp+0Ch]
	mov	cx, word ptr [bp+8]
	mov	dx, word ptr [bp+0Ah]
	mov	bp, word ptr [bp+6]
	call	far ptr egfx_text_clip_all
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; egfx_text_clip_all (slot 42): BP = port, CX = x, DX = y, BX = string (SS): draw text clipped on all sides.
; ----------------------------------------------------------------------------
egfx_text_clip_all:
	call	text_setup
	call	clip_text_right
	call	clip_text_left
	call	clip_text_vert
	jmp	L_20DD

; ----------------------------------------------------------------------------
; egfx_text_clip_left (slot 43): As text_clip_all, clipped on the left only.
; ----------------------------------------------------------------------------
egfx_text_clip_left:
	call	text_setup
	call	clip_text_left
	jmp	L_20DD

; ----------------------------------------------------------------------------
; clip_text_left
; ----------------------------------------------------------------------------
clip_text_left:
	cmp	byte ptr ds:[4E7h], 0
	je	L_2042
	cmp	word ptr [bp+6], 0
	js	L_203E
	mov	ax, word ptr ds:[4F1h]
	or	ax, ax
	jns	L_2042
	mov	word ptr ds:[4F1h], 0
	neg	ax
	div	byte ptr ds:[4E7h]
	mov	byte ptr ds:[4E8h], ah
	inc	al
L_2030:
	dec	al
	je	L_2042
L_2034:
	mov	ah, byte ptr ss:[bx]
	inc	bx
	or	ah, ah
	js	L_2034
	jne	L_2030
L_203E:
	pop	ax
	jmp	L_20F2
L_2042:
	ret

; ----------------------------------------------------------------------------
; egfx_text_clip_right (slot 45): As text_clip_all, clipped on the right only.
; ----------------------------------------------------------------------------
egfx_text_clip_right:
	call	text_setup
	call	clip_text_right
	jmp	L_20DD

; ----------------------------------------------------------------------------
; clip_text_right
; ----------------------------------------------------------------------------
clip_text_right:
	cmp	byte ptr ds:[4E7h], 0
	je	L_208F
	mov	dx, word ptr ds:[4F1h]
	mov	cx, word ptr [bp+6]
	or	cx, cx
	js	L_2090
	cmp	dx, cx
	jg	L_2090
	dec	dx
	xor	ah, ah
	mov	al, byte ptr ds:[4E7h]
	mov	di, ax
	mov	si, bx
	dec	si
L_206D:
	inc	si
	cmp	byte ptr ss:[si], ah
	js	L_206D
	je	L_208F
	add	dx, di
	cmp	dx, cx
	jl	L_206D
	sub	dx, cx
	mov	byte ptr ds:[4ECh], dl
	inc	si
	mov	al, byte ptr ss:[si]
	mov	byte ptr ss:[si], ah
	mov	byte ptr ds:[4EBh], al
	mov	word ptr ds:[4E9h], si
L_208F:
	ret
L_2090:
	pop	ax
	jmp	L_20F2

; ----------------------------------------------------------------------------
; egfx_text_clip_vert (slot 46): As text_clip_all, clipped at the top and bottom only.
; ----------------------------------------------------------------------------
egfx_text_clip_vert:
	call	text_setup
	call	clip_text_vert
	jmp	L_20DD

; ----------------------------------------------------------------------------
; clip_text_vert
; ----------------------------------------------------------------------------
clip_text_vert:
	mov	cx, word ptr [bp+8]
	or	cx, cx
	js	L_20D6
	mov	ax, word ptr ds:[4F3h]
	or	ax, ax
	jns	L_20C1
	neg	ax
	sub	word ptr ds:[4EDh], ax
	jbe	L_20D6
	mov	word ptr ds:[4F3h], 0
	mul	word ptr ds:[4EFh]
	add	word ptr ds:[4E4h], ax
L_20C1:
	mov	ax, word ptr ds:[4F3h]
	cmp	ax, cx
	ja	L_20D6
	add	ax, word ptr ds:[4EDh]
	dec	ax
	sub	ax, cx
	jbe	L_20D5
	sub	word ptr ds:[4EDh], ax
L_20D5:
	ret
L_20D6:
	pop	ax
	jmp	L_20F2

; ----------------------------------------------------------------------------
; egfx_text_noclip (slot 44): As text_clip_all, without clipping.
; ----------------------------------------------------------------------------
egfx_text_noclip:
	call	text_setup
L_20DD:
	mov	ax, word ptr [bp+2]
	add	word ptr ds:[4F1h], ax
	mov	ax, word ptr [bp+4]
	add	word ptr ds:[4F3h], ax
	mov	si, bx
	call	far ptr draw_glyphs
L_20F2:
	mov	bx, word ptr ds:[4E9h]
	or	bx, bx
	je	L_2100
	mov	al, byte ptr ds:[4EBh]
	mov	byte ptr ss:[bx], al
L_2100:
	mov	ax, word ptr ds:[4F1h]
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
	je	L_20F2
	mov	di, word ptr [bp+10h]
	cmp	di, word ptr ds:[500h]
	ja	L_20F2
	shl	di, 1
	je	L_20F2
	mov	di, word ptr [di+500h]
	add	di, 500h
	mov	word ptr glyph_data, di
	mov	al, byte ptr [di-4]
	test	byte ptr [bp+0Ah], 1
	je	L_2151
	add	al, byte ptr [di-2]
L_2151:
	cbw
	mov	word ptr text_rows, ax
	mov	ah, byte ptr [di-3]
	mov	byte ptr font_spacing, ah
	mov	al, byte ptr [di-5]
	or	al, al
	je	L_2165
	add	al, ah
L_2165:
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
; egfx_nop13 (slot 13): Slot 13.
; ----------------------------------------------------------------------------
egfx_nop13:
	retf
CODE	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

; GFX.ASM - the graphics library's primitives: filled rectangles and polygon
; spans, clipped lines and pixels (all programs but COVERT and INTRO), the
; picture decoder (not CODE), the sprite blitter's dirty-row bookkeeping (FINAL,
; GAME) and the mouse pointer (MOUSE.INC). The last object of the assembly
; segment, linked after the C code.
;
; The primitives draw through the graphics driver's low-level slots (select_page,
; set_port, set_draw_color, fill_spans, draw_line, put_pixel). A "port" is the
; C library's window structure: +0 page, +2 x, +4 y, +6 width - 1, +8 height - 1.

IFNDEF PROG_CODE
WITH_PICTURES	EQU	1
ENDIF
IFDEF PROG_FINAL
WITH_SPRITES	EQU	1
ENDIF
IFDEF PROG_GAME
WITH_SPRITES	EQU	1
ENDIF

ROWS		EQU	200		; screen rows
ROW_BYTES	EQU	2 * ROWS	; a row table (one word per row)

DGROUP	GROUP	_DATA, _BSS
	ASSUME	DS:DGROUP, SS:DGROUP	; before _DATA: the PUBDEFs then carry DGROUP

_DATA	SEGMENT WORD PUBLIC 'DATA'
IFDEF WITH_PICTURES
	EXTRN	_stream_ptr:WORD, _stream_end:WORD, _refill_fn:DWORD	; FILEIO.C
	EXTRN	_pic_width:WORD, _pic_height:WORD, _block_size:WORD
ENDIF
	db	0			; (padding)
line_x0		dw	0		; the line (or polygon edge) being drawn
line_x1		dw	0
line_y0		dw	0
line_y1		dw	0
span_min	dw	220 dup (-1)	; per row: the leftmost and rightmost x to fill
span_max	dw	220 dup (0)
span_dx		dw	0
span_dy		dw	0
span_top	dw	-1		; the rows with spans set
span_bottom	dw	0
origin_x	dw	0
origin_y	dw	0
	db	0			; (padding)
clip_code	db	0		; outcode of the first end point
clip_dx		dw	0
clip_dy		dw	0
clip_half_dx	dw	0
clip_half_dy	dw	0
clip_xmax	dw	319		; the port's width and height - 1
clip_ymax	dw	111
	db	0			; (padding)
IFDEF WITH_SPRITES
; per page (0, 1): the range of rows the sprites touched, and per row the
; leftmost and rightmost column
dirty_top	dw	-1, -1
dirty_bottom	dw	0, 0
dirty_min_rows	dw	offset DGROUP:rows_min0, offset DGROUP:rows_min1
dirty_max_rows	dw	offset DGROUP:rows_max0, offset DGROUP:rows_max1
rows_min0	db	ROW_BYTES dup (0FFh)
rows_max0	db	ROW_BYTES dup (0)
rows_min1	db	ROW_BYTES dup (0FFh)
rows_max1	db	ROW_BYTES dup (0)
ENDIF
_DATA	ENDS

; the picture decoder's state is in _BSS, linked with the program's (DATA.ASM)
_BSS	SEGMENT WORD PUBLIC 'BSS'
IFDEF WITH_PICTURES
	EXTRN	lzw_codes:WORD, lzw_chars:BYTE, lzw_stack_top:BYTE
	EXTRN	lzw_saved_sp:WORD, lzw_count:WORD, lzw_run:BYTE, lzw_run_byte:BYTE
	EXTRN	lzw_bits:BYTE, lzw_max_bits:BYTE, lzw_mask:WORD, lzw_next_code:WORD
	EXTRN	lzw_input:WORD, lzw_input_bits:BYTE, pic_nibbles:BYTE
	EXTRN	lzw_prev_code:WORD, lzw_first_char:BYTE
ENDIF
_BSS	ENDS

; the next word of the picture stream (refilling the buffer when it runs out)
get_word	MACRO
	LOCAL	have
	mov	si, _stream_ptr
	cmp	si, _stream_end
	jb	have
	push	bx
	push	cx
	push	dx
	call	dword ptr _refill_fn
	pop	dx
	pop	cx
	pop	bx
	mov	si, _stream_ptr
have:
	lodsw
	mov	_stream_ptr, si
	ENDM

ASM0	SEGMENT WORD PUBLIC 'CODE'
	ASSUME	CS:ASM0
	EXTRN	_drv_select_page:FAR, _drv_set_port:FAR, _drv_set_draw_color:FAR
	EXTRN	_drv_fill_spans:FAR, _drv_nop39:FAR, _drv_draw_line:FAR, _drv_put_pixel:FAR
	PUBLIC	_gfx_fill_rect, _gfx_draw_spans, _gfx_clear_spans, _gfx_line, _gfx_put_pixel
IFDEF WITH_PICTURES
	EXTRN	_drv_set_color_map:FAR
	PUBLIC	_pic_begin_decode, _lzw_begin, _lzw_decode_row_b, _lzw_decode_row
ENDIF
IFDEF WITH_SPRITES
	EXTRN	_drv_blit_sprite_var:FAR, _drv_copy_rows_to_screen:FAR
	PUBLIC	_blit_sprite, _blit_sprite_restore, _present_dirty_rows, _clear_dirty_rows
ENDIF

; ----------------------------------------------------------------------------
; void far gfx_fill_rect(port, x, y, w, h, colour): a filled rectangle,
; as spans through the driver's fill_spans
; ----------------------------------------------------------------------------
_gfx_fill_rect:
	push	bp
	mov	bp, sp
	push	di
	push	si
	call	clear_spans
	mov	bx, [bp+6]
	mov	ax, [bx]
	call	far ptr _drv_select_page
	mov	si, [bp+0Ah]
	add	si, [bx+4]
	mov	span_top, si
	mov	cx, [bp+0Eh]
	shl	si, 1
	lea	di, span_min
	add	di, si
	mov	ax, [bp+8]
	add	ax, [bx+2]
	mov	dx, cx
	rep	stosw
	mov	cx, dx
	lea	di, span_max
	add	di, si
	mov	ax, [bp+8]
	add	ax, [bx+2]
	add	ax, [bp+0Ch]
	dec	ax
	rep	stosw
	mov	ax, [bp+10h]
	call	far ptr _drv_set_draw_color
	mov	ax, span_top
	mov	cx, ax
	add	cx, [bp+0Eh]
	dec	cx
	mov	span_bottom, cx
	mov	bx, offset DGROUP:span_min
	call	far ptr _drv_fill_spans
	call	far ptr _drv_nop39
	pop	si
	pop	di
	pop	bp
	retf
	db	0			; (padding)

; ----------------------------------------------------------------------------
; void far gfx_draw_spans(void): fill the spans collected so far
; ----------------------------------------------------------------------------
_gfx_draw_spans:
	push	di
	push	si
	push	bp
	mov	ax, span_top
	mov	cx, span_bottom
	mov	bx, offset DGROUP:span_min
	call	far ptr _drv_fill_spans
	pop	bp
	pop	si
	pop	di
	retf

; ----------------------------------------------------------------------------
; void far gfx_clear_spans(void): forget the collected spans
; ----------------------------------------------------------------------------
_gfx_clear_spans:
	push	di
	call	clear_spans
	pop	di
	retf

; ----------------------------------------------------------------------------
; clear_spans: reset the span tables between span_top and span_bottom
; ----------------------------------------------------------------------------
clear_spans:
	mov	ax, DGROUP
	mov	es, ax
	mov	di, span_top
	or	di, di
	js	clear_spans_1
	mov	cx, span_bottom
	inc	cx
	sub	cx, di
	shl	di, 1
	mov	bx, cx
	mov	dx, di
	add	di, offset DGROUP:span_min
	mov	ax, 0FFFFh
	rep	stosw
	mov	span_top, ax
	mov	cx, bx
	mov	di, dx
	add	di, offset DGROUP:span_max
	sub	ax, ax
	rep	stosw
	mov	span_bottom, ax
clear_spans_1:
	ret

; ----------------------------------------------------------------------------
; span_clip_edge: an edge clipped at x = SI (0 or the right edge): rows CX..DX of the
; polygon reach that column
; ----------------------------------------------------------------------------
span_clip_edge:
	mov	ax, DGROUP
	mov	es, ax
	mov	cx, di
	or	si, si
	lea	di, span_min
	je	span_clip_edge_1
	cmp	si, clip_xmax
	jne	span_clip_edge_7
	lea	di, span_max
span_clip_edge_1:
	cmp	cx, dx
	jge	span_clip_edge_2
	xchg	cx, dx
span_clip_edge_2:
	or	dx, dx
	jns	span_clip_edge_3
	sub	dx, dx
span_clip_edge_3:
	cmp	cx, clip_ymax
	jle	span_clip_edge_4
	mov	cx, clip_ymax
span_clip_edge_4:
	add	si, origin_x
	add	cx, origin_y
	add	dx, origin_y
	cmp	cx, span_bottom
	jbe	span_clip_edge_5
	mov	span_bottom, cx
span_clip_edge_5:
	cmp	dx, span_top
	jae	span_clip_edge_6
	mov	span_top, dx
span_clip_edge_6:
	add	di, dx
	add	di, dx
	sub	cx, dx
	inc	cx
	mov	ax, si
	rep	stosw
span_clip_edge_7:
	ret

; ----------------------------------------------------------------------------
; span_clip_x: BX < 0 or past clip_xmax: the edge runs along that side
; ----------------------------------------------------------------------------
span_clip_x:
	sub	si, si
	or	bx, bx
	js	span_clip_edge
	mov	si, clip_xmax
	cmp	bx, si
	jg	span_clip_edge
	ret

; ----------------------------------------------------------------------------
; span_add_line: widen the spans by the edge line_x0,y0 - line_x1,y1 (DDA)
; ----------------------------------------------------------------------------
span_add_line:
	mov	ax, origin_x
	add	line_x0, ax
	add	line_x1, ax
	mov	ax, origin_y
	add	line_y0, ax
	add	line_y1, ax
	mov	ax, line_x1
	cmp	ax, line_x0
	jae	span_add_line_1
	mov	bx, line_x0
	mov	line_x1, bx
	mov	line_x0, ax
	mov	ax, line_y1
	mov	bx, line_y0
	mov	line_y1, bx
	mov	line_y0, ax
span_add_line_1:
	mov	bx, line_x1
	sub	bx, line_x0
	mov	span_dx, bx
	mov	ax, line_y1
	mov	dx, ax
	mov	cx, line_y0
	sub	ax, cx
	mov	bp, 2
	jns	span_add_line_2
	xchg	cx, dx
	neg	bp
	neg	ax
span_add_line_2:
	mov	span_dy, ax
	cmp	dx, span_bottom
	jbe	span_add_line_3
	mov	span_bottom, dx
span_add_line_3:
	cmp	cx, span_top
	jae	span_add_line_4
	mov	span_top, cx
span_add_line_4:
	cmp	ax, bx
	jae	span_add_line_11
	mov	di, line_y0
	shl	di, 1
	mov	ax, line_x0
	mov	dx, span_dx
	mov	cx, dx
	mov	bx, cx
	inc	bx
	shr	bx, 1
	neg	bx
	mov	si, span_dy
	jmp	span_add_line_7
span_add_line_5:
	cmp	ax, [di+span_max]
	jbe	span_add_line_6
	mov	[di+span_max], ax
span_add_line_6:
	inc	ax
	sub	bx, dx
	add	di, bp
span_add_line_7:
	cmp	ax, [di+span_min]
	jae	span_add_line_8
	mov	[di+span_min], ax
span_add_line_8:
	dec	cx
	js	span_add_line_9
	add	bx, si
	jns	span_add_line_5
	inc	ax
	jmp	span_add_line_8
span_add_line_9:
	cmp	ax, [di+span_max]
	jbe	span_add_line_10
	mov	[di+span_max], ax
span_add_line_10:
	ret
span_add_line_11:
	mov	di, line_y0
	shl	di, 1
	mov	ax, line_x0
	mov	dx, span_dy
	mov	cx, dx
	mov	bx, cx
	inc	bx
	shr	bx, 1
	neg	bx
	mov	si, span_dx
span_add_line_12:
	cmp	ax, [di+span_min]
	jae	span_add_line_13
	mov	[di+span_min], ax
span_add_line_13:
	cmp	ax, [di+span_max]
	jbe	span_add_line_14
	mov	[di+span_max], ax
span_add_line_14:
	dec	cx
	js	span_add_line_15
	add	di, bp
	add	bx, si
	js	span_add_line_12
	sub	bx, dx
	inc	ax
	jmp	span_add_line_12
span_add_line_15:
	ret
	db	0			; (padding)

; ----------------------------------------------------------------------------
; clip_line_far: far entries of clip_line (the second saves BP, SI, DI and ES)
; ----------------------------------------------------------------------------
clip_line_far:
	call	clip_line
	retf

; ----------------------------------------------------------------------------
; clip_line_far_save
; ----------------------------------------------------------------------------
clip_line_far_save:
	push	bp
	push	si
	push	di
	push	es
	call	clip_line
	pop	es
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; clip_line: draw line_x0,y0 - line_x1,y1 clipped to 0..clip_xmax, 0..clip_ymax
; (Cohen-Sutherland). INT 0 is pointed at div_overflow meanwhile: an overflowing
; IDIV gives the largest result of the right sign. CF set: nothing visible
; ----------------------------------------------------------------------------
clip_line:
	sub	ax, ax
	mov	es, ax
	push	word ptr es:[0]
	push	word ptr es:[2]
	lea	ax, div_overflow
	mov	es:[0], ax
	mov	word ptr es:[2], ASM0
	push	ds
	pop	es
	jmp	clip_loop
clip_accept:
	sub	ax, ax
	mov	es, ax
	pop	word ptr es:[2]
	pop	word ptr es:[0]
	push	ds
	pop	es
	mov	ax, line_x0
	mov	bx, line_y0
	mov	cx, line_x1
	mov	dx, line_y1
	call	far ptr _drv_draw_line
	clc
	ret
clip_reject:
	sub	ax, ax
	mov	es, ax
	pop	word ptr es:[2]
	pop	word ptr es:[0]
	push	ds
	pop	es
	stc
	ret
clip_reject_1:
	cmc
	rcr	dx, 1
	mov	clip_dx, dx
	sar	dx, 1
	mov	clip_half_dx, dx
	mov	dx, di
	sub	dx, bp
	jno	clip_reject_2
	cmc
	rcr	dx, 1
	jmp	clip_loop_3
clip_reject_2:
	sar	dx, 1
	jmp	clip_loop_3
clip_reject_3:
	cmc
	rcr	dx, 1
	sar	word ptr clip_dx, 1
	sar	word ptr clip_half_dx, 1
	jmp	clip_loop_3
clip_reject_4:
	jmp	clip_reject
clip_loop:
	mov	cx, line_x0
	mov	dx, line_y0
	mov	si, line_x1
	mov	di, line_y1
	mov	bx, cx
	mov	bp, dx
	call	outcode
	mov	clip_code, al
	mov	bx, si
	mov	bp, di
	call	outcode
	jne	clip_loop_2
	cmp	byte ptr clip_code, 0
	jne	clip_loop_1
	jmp	clip_accept
clip_loop_1:
	xchg	cx, si
	xchg	dx, di
	xchg	clip_code, al
	mov	line_x0, cx
	mov	line_y0, dx
clip_loop_2:
	test	clip_code, al
	jne	clip_reject_4
	mov	bp, dx
	mov	dx, si
	sub	dx, cx
	jo	clip_reject_1
	mov	clip_dx, dx
	sar	dx, 1
	mov	clip_half_dx, dx
	mov	dx, di
	sub	dx, bp
	jo	clip_reject_3
clip_loop_3:
	mov	clip_dy, dx
	sar	dx, 1
	mov	clip_half_dy, dx
clip_loop_4:
	test	al, 9
	je	clip_div_dx_3
	sub	bx, bx
	or	si, si
	js	clip_loop_5
	mov	bx, clip_xmax
clip_loop_5:
	mov	ax, bx
	sub	ax, cx
	imul	word ptr clip_dy
	push	bx
	mov	bx, dx
clip_div_dx:
	idiv	word ptr clip_dx
	mov	bl, bh
	xor	bl, byte ptr clip_dx+1	; the signs of dx and the remainder
	jns	clip_div_dx_1
	neg	dx
	dec	ax
clip_div_dx_1:
	sub	dx, clip_half_dx
	xor	dh, bh
	js	clip_div_dx_2
	inc	ax
clip_div_dx_2:
	pop	bx
	add	ax, bp
	js	clip_div_dx_4
	cmp	ax, clip_ymax
	jle	clip_div_dy_3
clip_div_dx_3:
	mov	bx, clip_ymax
	cmp	di, bx
	jg	clip_div_dx_5
clip_div_dx_4:
	sub	bx, bx
clip_div_dx_5:
	mov	ax, bx
	sub	ax, bp
	imul	word ptr clip_dx
	push	bx
	mov	bx, dx
clip_div_dy:
	idiv	word ptr clip_dy
	mov	bl, bh
	xor	bl, byte ptr clip_dy+1
	jns	clip_div_dy_1
	neg	dx
	dec	ax
clip_div_dy_1:
	sub	dx, clip_half_dy
	xor	dh, bh
	js	clip_div_dy_2
	inc	ax
clip_div_dy_2:
	pop	bx
	add	ax, cx
	js	clip_div_dy_4
	cmp	ax, clip_xmax
	jg	clip_div_dy_4
	xchg	bx, ax
clip_div_dy_3:
	cmp	byte ptr clip_code, 0
	jne	clip_div_dy_5
	mov	line_y1, ax
	mov	line_x1, bx
	jmp	clip_accept
clip_div_dy_4:
	jmp	clip_reject
clip_div_dy_5:
	mov	line_y0, ax
	mov	line_x0, bx
	xchg	cx, si
	xchg	bp, di
	mov	al, clip_code
	mov	byte ptr clip_code, 0
	jmp	clip_loop_4

; ----------------------------------------------------------------------------
; outcode
; outcode of BX (x), BP (y): 8 left, 1 right, 4 above, 2 below
; ----------------------------------------------------------------------------
outcode:
	mov	al, 0Fh
	or	bx, bx
	js	outcode_1
	and	al, 0F7h
outcode_1:
	cmp	bx, clip_xmax
	jg	outcode_2
	and	al, 0FEh
outcode_2:
	or	bp, bp
	js	outcode_3
	and	al, 0FBh
outcode_3:
	cmp	bp, clip_ymax
	jg	outcode_4
	and	al, 0FDh
outcode_4:
	or	al, al
	ret

; ----------------------------------------------------------------------------
; div_overflow: INT 0 during clip_line: return +-7F00h and skip the IDIV
; ----------------------------------------------------------------------------
div_overflow:
	push	bp
L_09E7	equ	byte ptr $+1
	mov	bp, sp
	cmp	word ptr [bp+2], offset clip_div_dy
	mov	ax, clip_dy
	je	div_overflow_1
	mov	ax, clip_dx
div_overflow_1:
	xor	dx, ax
	mov	ax, 7F00h
	jns	div_overflow_2
	neg	ax
div_overflow_2:
	add	word ptr [bp+2], 4
	sub	dx, dx
	pop	bp
	iret

; ----------------------------------------------------------------------------
; void far gfx_line(port, x0, y0, x1, y1, colour)
; ----------------------------------------------------------------------------
_gfx_line:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	bx, [bp+6]
	mov	ax, [bx+6]
	mov	clip_xmax, ax
	mov	ax, [bx+8]
	mov	clip_ymax, ax
	call	far ptr _drv_set_port
	mov	ax, [bp+8]
	mov	line_x0, ax
	mov	ax, [bp+0Ah]
	mov	line_y0, ax
	mov	ax, [bp+0Ch]
	mov	line_x1, ax
	mov	ax, [bp+0Eh]
	mov	line_y1, ax
	mov	ax, [bp+10h]
	call	far ptr _drv_set_draw_color
	call	clip_line
	call	far ptr _drv_nop39
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; void far gfx_put_pixel(port, x, y, colour)
; ----------------------------------------------------------------------------
_gfx_put_pixel:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	bx, [bp+6]
	mov	cx, [bp+8]
	or	cx, cx
	js	gfx_put_pixel_1
	cmp	cx, [bx+6]
	jg	gfx_put_pixel_1
	mov	dx, [bp+0Ah]
	or	dx, dx
	js	gfx_put_pixel_1
	cmp	dx, [bx+8]
	jg	gfx_put_pixel_1
	call	far ptr _drv_set_port
	mov	ax, [bp+0Ch]
	call	far ptr _drv_set_draw_color
	mov	ax, cx
	mov	bx, dx
	call	far ptr _drv_put_pixel
	call	far ptr _drv_nop39
gfx_put_pixel_1:
	pop	di
	pop	si
	pop	bp
	retf

IFDEF WITH_PICTURES
; ----------------------------------------------------------------------------
; void far pic_begin_decode(void): read a picture header from the stream
; (flags, width, height, an optional 16- or 128-byte colour map) and start the
; LZW decoder
; ----------------------------------------------------------------------------
_pic_begin_decode:
	push	si
	get_word
	mov	dx, ax
	and	al, 1
	mov	pic_nibbles, al
	get_word
	mov	_pic_width, ax
	get_word
	mov	_pic_height, ax
	test	dx, 8
	je	pic_begin_decode_4
	add	word ptr _stream_ptr, 10h
	jmp	pic_begin_decode_5
pic_begin_decode_4:
	test	dx, 10h
	je	pic_begin_decode_6
	add	word ptr _stream_ptr, 80h
pic_begin_decode_5:
	xor	ax, ax
	push	si
	push	ax
	call	far ptr _drv_set_color_map
	add	sp, 4
pic_begin_decode_6:
	call	lzw_start
	pop	si
	retf

; ----------------------------------------------------------------------------
; void far lzw_begin(void): start decoding an LZW block (flags, size)
; ----------------------------------------------------------------------------
_lzw_begin:
	push	si
	get_word
	and	al, 1
	mov	pic_nibbles, al
	get_word
	mov	_block_size, ax
	call	lzw_start
	pop	si
	retf

; ----------------------------------------------------------------------------
; void far lzw_decode_row_b(char far *dst, int n): decode n pixels
; ----------------------------------------------------------------------------
_lzw_decode_row_b:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	si, _stream_ptr
	les	di, dword ptr [bp+6]
	mov	cx, [bp+0Ah]
	call	lzw_decode
	mov	_stream_ptr, si
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; void far lzw_decode_row(char *dst): decode a row of pic_width pixels
; ----------------------------------------------------------------------------
_lzw_decode_row:
	push	bp
	mov	bp, sp
	push	si
	push	di
	mov	ax, ds
	mov	es, ax
	mov	si, _stream_ptr
	mov	di, [bp+6]
	mov	cx, _pic_width
	call	lzw_decode
	mov	_stream_ptr, si
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; lzw_start: read the maximum code width and reset the decoder
; ----------------------------------------------------------------------------
lzw_start:
	mov	byte ptr lzw_run, 0
	mov	byte ptr lzw_run_byte, 0
	mov	ax, offset DGROUP:lzw_stack_top
	mov	lzw_saved_sp, ax
	get_word
	cmp	al, 0Bh
	jbe	lzw_start_2
	mov	al, 0Bh
lzw_start_2:
	mov	lzw_max_bits, al
	mov	lzw_input, ax
	mov	byte ptr lzw_input_bits, 8

; ----------------------------------------------------------------------------
; lzw_init: reset the string table to the 256 single bytes, 9-bit codes
; ----------------------------------------------------------------------------
lzw_init:
	mov	byte ptr lzw_bits, 9
	mov	word ptr lzw_mask, 1FFh
	mov	dx, 100h
	mov	lzw_next_code, dx
	mov	ax, 0FFFFh
	xor	bx, bx
	mov	cx, 800h
lzw_init_1:
	mov	lzw_codes[bx], ax
	add	bx, 3
	loop	lzw_init_1
	mov	al, 0
	xor	bx, bx
	mov	cx, 100h
lzw_init_2:
	mov	lzw_chars[bx], al
	inc	al
	add	bx, 3
	loop	lzw_init_2
	ret

; ----------------------------------------------------------------------------
; lzw_decode: decode CX pixels to ES:DI, expanding runs (90h n: the previous byte n
; times); runs on its own stack (lzw_saved_sp) whose contents are the pending
; bytes of the current string
; ----------------------------------------------------------------------------
lzw_decode:
	cmp	byte ptr pic_nibbles, 0
	je	lzw_decode_1
	inc	cx
	shr	cx, 1
lzw_decode_1:
	mov	lzw_count, cx
	mov	ax, lzw_saved_sp
	mov	lzw_saved_sp, sp
	mov	sp, ax
	mov	dx, lzw_next_code
lzw_decode_2:
	cmp	byte ptr lzw_run, 0
	jne	lzw_decode_5
	call	lzw_next_byte
	cmp	al, 90h
	je	lzw_decode_3
	mov	lzw_run_byte, al
	jmp	lzw_decode_6
lzw_decode_3:
	call	lzw_next_byte
	or	al, al
	jne	lzw_decode_4
	mov	al, 90h
	mov	lzw_run_byte, al
	jmp	lzw_decode_6
lzw_decode_4:
	dec	al
	mov	lzw_run, al
lzw_decode_5:
	mov	al, lzw_run_byte
	dec	byte ptr lzw_run
lzw_decode_6:
	cmp	byte ptr pic_nibbles, 0
	je	lzw_decode_7
	mov	ah, al
	and	al, 0Fh
	shr	ah, 1
	shr	ah, 1
	shr	ah, 1
	shr	ah, 1
	stosw
	dec	word ptr lzw_count
	jne	lzw_decode_2
	jmp	lzw_decode_8
lzw_decode_7:
	stosb
	dec	word ptr lzw_count
	jne	lzw_decode_2
lzw_decode_8:
	mov	lzw_next_code, dx
	mov	ax, lzw_saved_sp
	mov	lzw_saved_sp, sp
	mov	sp, ax
	ret

; ----------------------------------------------------------------------------
; lzw_next_byte: the next decoded byte: pop it from the decoder stack, or read the next
; code and push its string
; ----------------------------------------------------------------------------
lzw_next_byte:
	pop	bp
	cmp	sp, offset DGROUP:lzw_stack_top
	je	lzw_next_byte_2
lzw_next_byte_1:
	pop	ax
	jmp	bp
lzw_next_byte_2:
	mov	bx, lzw_input
	mov	cl, 10h
	mov	ch, lzw_input_bits
	sub	cl, ch
	shr	bx, cl
	mov	cl, ch
lzw_next_byte_3:
	cmp	cl, lzw_bits
	jge	lzw_next_byte_5
	cmp	si, _stream_end
	jb	lzw_next_byte_4
	push	bx
	push	cx
	push	dx
	call	dword ptr _refill_fn
	pop	dx
	pop	cx
	pop	bx
	mov	si, _stream_ptr
lzw_next_byte_4:
	lodsw
	mov	lzw_input, ax
	shl	ax, cl
	or	bx, ax
	add	cl, 10h
	jmp	lzw_next_byte_3
lzw_next_byte_5:
	sub	cl, lzw_bits
	mov	lzw_input_bits, cl
	mov	ax, bx
	and	ax, lzw_mask
	mov	cx, ax
	cmp	ax, dx
	jl	lzw_next_byte_6
	mov	cx, dx
	mov	ax, lzw_prev_code
	mov	bl, lzw_first_char
	push	bx
lzw_next_byte_6:
	mov	bx, ax
	add	bx, ax
	add	bx, ax
	mov	ax, lzw_codes[bx]
	inc	ax
	je	lzw_next_byte_7
	dec	ax
	mov	bl, lzw_chars[bx]
	push	bx
	jmp	lzw_next_byte_6
lzw_next_byte_7:
	mov	al, lzw_chars[bx]
	mov	lzw_first_char, al
	push	ax
	mov	bx, dx
	add	bx, dx
	add	bx, dx
	mov	lzw_chars[bx], al
	mov	ax, lzw_prev_code
	mov	lzw_codes[bx], ax
	inc	dx
	cmp	dx, lzw_mask
	jle	lzw_next_byte_8
	inc	byte ptr lzw_bits
	stc
	rcl	word ptr lzw_mask, 1
lzw_next_byte_8:
	mov	al, lzw_bits
	cmp	al, lzw_max_bits
	jle	lzw_next_byte_9
	call	lzw_init
lzw_next_byte_9:
	mov	lzw_prev_code, cx
	jmp	lzw_next_byte_1
	db	0			; (padding)
ENDIF

IFDEF WITH_SPRITES
blit_return	dd	0		; the caller's return address

; ----------------------------------------------------------------------------
; void far blit_sprite(...): draw a sprite through the driver (slot 6) and
; mark the rows it covers dirty on its page
; ----------------------------------------------------------------------------
_blit_sprite:
	pop	word ptr cs:blit_return
	pop	word ptr cs:blit_return+2
	call	far ptr _drv_blit_sprite_var
	push	bp
	mov	bp, sp
	mov	bp, [bp+2]
	call	mark_sprite_rows
	pop	bp
	jmp	dword ptr cs:blit_return

; ----------------------------------------------------------------------------
; blit_sprite_restore: as blit_sprite, marking the rows on both pages
; ----------------------------------------------------------------------------
_blit_sprite_restore:
	pop	word ptr cs:blit_return
	pop	word ptr cs:blit_return+2
	call	far ptr _drv_blit_sprite_var
	push	bp
	mov	bp, sp
	mov	bp, [bp+2]
	push	ax
	push	dx
	call	mark_sprite_rows
	pop	dx
	pop	ax
	xor	byte ptr [bp], 1
	call	mark_sprite_rows
	xor	byte ptr [bp], 1
	pop	bp
	jmp	dword ptr cs:blit_return

; ----------------------------------------------------------------------------
; mark_sprite_rows: extend page [BP]'s dirty rows by the sprite at DX:AX
; ----------------------------------------------------------------------------
mark_sprite_rows:
	push	es
	push	di
	push	si
	mov	si, [bp]
	and	si, 1
	shl	si, 1
	mov	bx, ax
	mov	es, dx
	mov	dx, es:[bx+4]
	dec	dx
	js	mark_sprite_rows_6
	mov	di, es:[bx+2]
	add	di, [bp+4]
	cmp	di, [si+dirty_top]
	jae	mark_sprite_rows_1
	mov	[si+dirty_top], di
mark_sprite_rows_1:
	mov	cx, es:[bx+6]
	add	cx, di
	dec	cx
	cmp	cx, [si+dirty_bottom]
	jbe	mark_sprite_rows_2
	mov	[si+dirty_bottom], cx
mark_sprite_rows_2:
	shl	di, 1
	shl	cx, 1
	mov	ax, [si+dirty_min_rows]
	add	di, ax
	add	cx, ax
	mov	ax, es:[bx]
	add	ax, [bp+2]
	add	dx, ax
mark_sprite_rows_3:
	cmp	ax, [di]
	jae	mark_sprite_rows_4
	mov	[di], ax
mark_sprite_rows_4:
	cmp	dx, [di+ROW_BYTES]
	jbe	mark_sprite_rows_5
	mov	[di+ROW_BYTES], dx
mark_sprite_rows_5:
	add	di, 2
	cmp	di, cx
	jbe	mark_sprite_rows_3
mark_sprite_rows_6:
	pop	si
	pop	di
	pop	es
	ret

; ----------------------------------------------------------------------------
; void far present_dirty_rows(int src, int page): copy the dirty rows of
; `page` to the screen (driver slot 49) and clear them
; ----------------------------------------------------------------------------
_present_dirty_rows:
	mov	bx, sp
	push	bp
	push	si
	push	di
	mov	si, [bx+4]
	mov	di, [bx+6]
	mov	bp, di
	and	bp, 1
	shl	bp, 1
	mov	ax, dirty_top[bp]
	mov	cx, dirty_bottom[bp]
	mov	bx, dirty_min_rows[bp]
	push	bp
	call	far ptr _drv_copy_rows_to_screen
	pop	bp
	mov	ax, ds
	mov	es, ax
	mov	di, dirty_top[bp]
	or	di, di
	js	present_dirty_rows_1
	mov	cx, dirty_bottom[bp]
	inc	cx
	sub	cx, di
	shl	di, 1
	mov	bx, cx
	mov	dx, di
	add	di, dirty_min_rows[bp]
	mov	ax, 0FFFFh
	rep	stosw
	mov	dirty_top[bp], ax
	mov	cx, bx
	mov	di, dx
	add	di, dirty_max_rows[bp]
	sub	ax, ax
	rep	stosw
	mov	dirty_bottom[bp], ax
present_dirty_rows_1:
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; void far clear_dirty_rows(int page)
; ----------------------------------------------------------------------------
_clear_dirty_rows:
	push	si
	push	di
	mov	ax, ds
	mov	es, ax
	mov	di, dirty_top
	or	di, di
	js	clear_dirty_rows_1
	mov	cx, dirty_bottom
	inc	cx
	sub	cx, di
	shl	di, 1
	mov	bx, cx
	mov	dx, di
	add	di, dirty_min_rows
	mov	ax, 0FFFFh
	rep	stosw
	mov	dirty_top, ax
	mov	cx, bx
	mov	di, dx
	add	di, dirty_max_rows
	sub	ax, ax
	rep	stosw
	mov	dirty_bottom, ax
clear_dirty_rows_1:
	mov	di, dirty_top+2
	or	di, di
	js	clear_dirty_rows_2
	mov	cx, dirty_bottom+2
	inc	cx
	sub	cx, di
	shl	di, 1
	mov	bx, cx
	mov	dx, di
	add	di, dirty_min_rows+2
	mov	ax, 0FFFFh
	rep	stosw
	mov	dirty_top+2, ax
	mov	cx, bx
	mov	di, dx
	add	di, dirty_max_rows+2
	sub	ax, ax
	rep	stosw
	mov	dirty_bottom+2, ax
clear_dirty_rows_2:
	pop	di
	pop	si
	retf
ENDIF
ASM0	ENDS

	INCLUDE	MOUSE.INC
	END

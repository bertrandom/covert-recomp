; PALETTE.ASM - set the 16-colour palette, programming EGA and Tandy palette
; hardware directly (BUG, TAC, FINAL; linked right after PROBE).
;
; void far anim_set_pal(char pal[17])     (BUG and TAC call it drv_call_gate)
;   pal: 16 colours as IRGB nibbles, then the border colour. MCGA and CGA hand the
;   table to the graphics driver (set_palette, slot 26); EGA writes the attribute
;   controller's palette and overscan registers, Tandy its palette registers.

DGROUP	GROUP	_DATA
	ASSUME	DS:DGROUP

_DATA	SEGMENT WORD PUBLIC 'DATA'
	EXTRN	_video_mode:BYTE	; graphics driver letter: M, C, E or T
_DATA	ENDS

ASM0	SEGMENT WORD PUBLIC 'CODE'
	ASSUME	CS:ASM0
	EXTRN	_drv_set_palette:FAR
	PUBLIC	_anim_set_pal, _drv_call_gate

_drv_call_gate	LABEL	FAR
_anim_set_pal:
	mov	al, _video_mode
	cmp	al, 'M'
	je	by_driver
	cmp	al, 'C'
	je	by_driver
	cmp	al, 'E'
	je	ega_palette
	cmp	al, 'T'
	je	tandy_palette
	retf
by_driver:
	jmp	_drv_set_palette

; EGA: attribute controller registers 0-15 and 17 (overscan)
ega_palette:
	push	si
	mov	si, sp
	mov	si, [si+6]		; pal
	mov	cl, 0
	mov	dx, 3DAh
ega_wait:
	in	al, dx			; wait for vertical retrace
	test	al, 8
	je	ega_wait
ega_next:
	mov	dl, 0DAh		; (resets the address/data flip-flop)
	in	al, dx
	test	al, 1
	je	ega_wait		; and display enable off
	cli
	mov	dl, 0C0h
	mov	al, cl			; register
	out	dx, al
	jmp	short $+2
	lodsb				; IRGB -> the EGA's rgbRGB: I sets the low
	and	al, 0Fh			; intensity bits (and bright black is dark grey)
	add	al, 8
	and	al, 17h
	out	dx, al
	jmp	short $+2
	mov	ax, 20h			; palette address source: video on again
	out	dx, al
	sti
	inc	cl			; 16 -> 17: inc sets AF when the low nibble
	aaa				; wraps, AAA then makes AH 1
	add	cl, ah
	cmp	cl, 11h
	jbe	ega_next
	pop	si
	retf

; Tandy: palette registers 10h-1Fh, then the border (register 2)
tandy_palette:
	push	si
	mov	si, sp
	mov	si, [si+6]		; pal
	mov	cl, 10h
	mov	dx, 3DAh
tandy_wait:
	in	al, dx			; wait for vertical retrace
	test	al, 8
	je	tandy_wait
tandy_next:
	in	al, dx
	test	al, 1
	je	tandy_wait
	cli
	mov	al, cl			; register
	out	dx, al
	jmp	short $+2
	mov	dl, 0DEh
	lodsb				; value
	out	dx, al
	jmp	short $+2
	mov	dl, 0DAh
	mov	al, 0
	out	dx, al
	sti
	cmp	cl, 2
	je	tandy_done
	inc	cl
	cmp	cl, 20h
	jb	tandy_next
	mov	cl, 2			; after 1Fh: the border
	jmp	tandy_next
tandy_done:
	pop	si
	retf
ASM0	ENDS
	END

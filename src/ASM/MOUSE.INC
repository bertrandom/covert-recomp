; MOUSE.INC - the mouse pointer: INT 33h set-up, the event handler and the
; pointer drawn by the graphics driver (show_pointer, hide_pointer). Included by
; GFX.ASM, and by DRVLOAD.ASM in COVERT and INTRO (MOUSE_IN_LOADER), whose
; call gate (in_driver, pointer_shown) keeps the event handler from redrawing
; the pointer while a driver call is drawing.

_DATA	SEGMENT WORD PUBLIC 'DATA'
IFNDEF MOUSE_IN_LOADER
	EXTRN	in_driver:BYTE, pointer_shown:BYTE	; DRVLOAD.ASM
ENDIF
ptr_x		dw	0		; the mouse position and buttons
ptr_y		dw	0
ptr_buttons	dw	0
ptr_clicks	dw	0		; buttons pressed since ptr_get_clicks
ptr_image	dw	0		; the pointer (ptr_set_shape)
ptr_hot_x	dw	0		; its hot spot
ptr_hot_y	dw	0
ptr_halve_x	dw	0		; the driver reports x in 0-639: halve it
ptr_regs	dw	4 dup (0)	; AX, BX, CX, DX after ptr_int33
_DATA	ENDS

ASM0	SEGMENT WORD PUBLIC 'CODE'
	ASSUME	CS:ASM0
IFNDEF MOUSE_IN_LOADER
	EXTRN	_drv_hide_pointer:FAR, _drv_show_pointer:FAR		; DRVLOAD.ASM
	EXTRN	hide_pointer_ptr:DWORD, show_pointer_ptr:DWORD
ENDIF
	PUBLIC	_ptr_init, _ptr_shutdown, _ptr_get_clicks, _ptr_set_shape, _ptr_hide
	PUBLIC	_ptr_show, _ptr_int33, drv_callback

; ----------------------------------------------------------------------------
; void far ptr_init(void): reset the mouse driver, install ptr_event
; ----------------------------------------------------------------------------
_ptr_init:
	xor	ax, ax
	mov	es, ax
	mov	bx, 0CCh
	mov	ax, es:[bx]
	or	ax, es:[bx+2]
	je	ptr_init_2
	mov	ax, 0
	int	33h
	or	ax, ax
	je	ptr_init_2
	mov	ax, 0Ch
	mov	cx, 1Fh
	mov	dx, cs
	mov	es, dx
	lea	dx, ptr_event
	int	33h
	mov	ax, 3
	int	33h
	mov	word ptr ptr_halve_x, 0
	cmp	cx, 0C8h
	jb	ptr_init_1
	shr	cx, 1
	mov	word ptr ptr_halve_x, 1
ptr_init_1:
	mov	ptr_buttons, bx
	mov	ptr_x, cx
	mov	ptr_y, dx
ptr_init_2:
	retf

; ----------------------------------------------------------------------------
; void far ptr_shutdown(void): hide the pointer, reset the mouse driver
; ----------------------------------------------------------------------------
_ptr_shutdown:
	xor	ax, ax
	mov	es, ax
	mov	bx, 0CCh
	mov	ax, es:[bx]
	or	ax, es:[bx+2]
	je	ptr_shutdown_1
	call	far ptr _ptr_hide
	mov	ax, 0
	int	33h
ptr_shutdown_1:
	retf

; ----------------------------------------------------------------------------
; int far ptr_get_clicks(void): the buttons pressed since the last call
; ----------------------------------------------------------------------------
_ptr_get_clicks:
	xor	ax, ax
	xchg	ptr_clicks, ax
	retf

; ----------------------------------------------------------------------------
; void far ptr_set_shape(int hot_x, int hot_y, int image)
; ----------------------------------------------------------------------------
_ptr_set_shape:
	push	bp
	mov	bp, sp
	mov	ax, [bp+6]
	mov	ptr_hot_x, ax
	mov	ax, [bp+8]
	mov	ptr_hot_y, ax
	mov	ax, [bp+0Ah]
	mov	ptr_image, ax
	pop	bp
	retf

; ----------------------------------------------------------------------------
; void far ptr_hide(void)
; ----------------------------------------------------------------------------
_ptr_hide:
	mov	byte ptr pointer_shown, 0
	call	far ptr _drv_hide_pointer
	retf

; ----------------------------------------------------------------------------
; void far ptr_show(void)
; ----------------------------------------------------------------------------
_ptr_show:
	push	word ptr ptr_image
	mov	ax, ptr_y
	sub	ax, ptr_hot_y
	push	ax
	mov	ax, ptr_x
	sub	ax, ptr_hot_x
	push	ax
	call	far ptr _drv_show_pointer
	add	sp, 6
	mov	byte ptr pointer_shown, 1
	retf

; ----------------------------------------------------------------------------
; int *far ptr_int33(ax, bx, cx, dx): call the mouse driver; returns ptr_regs
; ----------------------------------------------------------------------------
_ptr_int33:
	push	bp
	mov	bp, sp
	mov	ax, [bp+6]
	mov	bx, [bp+8]
	mov	cx, [bp+0Ah]
	mov	dx, [bp+0Ch]
	int	33h
	mov	ptr_regs, ax
	mov	ptr_regs+2, bx
	mov	ptr_regs+4, cx
	mov	ptr_regs+6, dx
	lea	ax, ptr_regs
	pop	bp
	retf

; ----------------------------------------------------------------------------
; drv_callback: redraw the pointer at the new position (bypassing the call gate)
; ----------------------------------------------------------------------------
drv_callback:
	push	ax
	push	dx
	push	es
	mov	ax, ASM0
	mov	es, ax
	call	dword ptr es:hide_pointer_ptr
	push	word ptr ptr_image
	mov	ax, ptr_y
	sub	ax, ptr_hot_y
	push	ax
	mov	ax, ptr_x
	sub	ax, ptr_hot_x
	push	ax
	mov	ax, ASM0
	mov	es, ax
	call	dword ptr es:show_pointer_ptr
	add	sp, 6
	pop	es
	pop	dx
	pop	ax
	retf

; ----------------------------------------------------------------------------
; ptr_event: the mouse driver's event handler (AX events, BX buttons, CX, DX position)
; ----------------------------------------------------------------------------
ptr_event:
	mov	di, DGROUP
	mov	ds, di
	cmp	word ptr ptr_halve_x, 0
	je	ptr_event_1
	shr	cx, 1
ptr_event_1:
	or	ptr_clicks, bx
	mov	ptr_buttons, bx
	mov	ptr_x, cx
	mov	ptr_y, dx
	test	ax, 1
	je	ptr_event_2
	cmp	byte ptr pointer_shown, 0
	je	ptr_event_2
	mov	al, 2
	xchg	in_driver, al
	or	al, al
	jne	ptr_event_2
	call	far ptr drv_callback
	mov	byte ptr in_driver, 0
ptr_event_2:
	retf
ASM0	ENDS

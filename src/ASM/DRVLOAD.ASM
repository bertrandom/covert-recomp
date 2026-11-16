; DRVLOAD.ASM - the driver interface of every program: the driver stub table,
; the call gate, link_driver_stubs and the overlay loader (README "Driver
; interface"). In the game modules it is the third object of the assembly
; segment (the second in CHASE, GAME and CODE); COVERT and INTRO link it after
; _TEXT and it carries the mouse pointer routines too (MOUSE.INC; in the game
; modules they are part of GFX.ASM).
;
; The stub table has a 7-byte entry per driver slot: graphics 0-50, MISC 90-97,
; sound 100-110. A plain entry is `dw 0` and a JMP FAR that link_driver_stubs
; patches with the driver's entry point. The entries of the slots that draw on
; the screen (6, 14, 21, 29, 30, 31) instead call call_gate, followed by the
; driver's entry point: the gate keeps the mouse interrupt (MOUSE.INC) from
; redrawing the pointer while the driver works, and redraws it afterwards if the
; mouse moved meanwhile.
;
; The loader is used by COVERT (it loads the graphics, sound and MISC drivers
; and leaves their segments in the environment block for the game modules) and
; is dead code elsewhere.

IFDEF PROG_COVERT
MOUSE_IN_LOADER	EQU	1
ENDIF
IFDEF PROG_INTRO
MOUSE_IN_LOADER	EQU	1
ENDIF

DGROUP	GROUP	_DATA
	ASSUME	DS:DGROUP		; before _DATA: the PUBDEFs then carry DGROUP

_DATA	SEGMENT WORD PUBLIC 'DATA'
	PUBLIC	in_driver, pointer_shown
in_driver	db	0		; 1 during a gated driver call, 2 if the mouse
					; moved meanwhile
pointer_shown	db	0		; the mouse pointer is on the screen
gate_return	dd	0		; the gated call's return address
ovl_name	dw	0		; load_overlay's arguments: the driver file
ovl_data_name	dw	0		; and a data file loaded after it (or 0)
ovl_saved_sp	dw	0		; SP across the EXEC call
ovl_paras	dw	0		; size of the memory block for the overlay
ovl_exec	dw	0, 0		; EXEC 4B03h parameters: load segment, relocation
msg_alloc	db	'Allocated 1Mb of space????$'
msg_dos_lied	db	'MS-DOS lied to us about how much memory was available$'
msg_not_found	db	'Filename not found$'
msg_no_memory	db	'Not enough memory to load file$'
msg_load_failed	db	'Overlay load failed for some reason$'
msg_overrun	db	'Overlay has overrun allocated memory$'
msg_shrink	db	'Unable to shrink overlay memory allocation$'
msg_release	db	'Error releasing overlay memory$'
_DATA	ENDS

; the far address the stubs jump to until link_driver_stubs patches them
ABS0	SEGMENT AT 0
unlinked	LABEL	FAR
ABS0	ENDS

; a plain driver entry: the label is at the JMP FAR (+2), the far pointer at +3
stub	MACRO	entry, other
	dw	0
entry	LABEL	FAR
	IFNB	<other>
other	LABEL	FAR
	ENDIF
	jmp	unlinked
	ENDM

; a gated entry: the label is at the call, the driver's entry point follows it
gated	MACRO	entry, other, fptr
entry	LABEL	FAR
	IFNB	<other>
other	LABEL	FAR
	ENDIF
	call	call_gate
	IFNB	<fptr>
fptr	LABEL	DWORD
	ENDIF
	dd	0
	ENDM

unused	MACRO
	db	7 dup (0)
	ENDM

ASM0	SEGMENT WORD PUBLIC 'CODE'
	ASSUME	CS:ASM0
IFNDEF MOUSE_IN_LOADER
	EXTRN	drv_callback:FAR
ENDIF
	PUBLIC	_drv_alloc_page, _drv_mem_avail, _drv_get_image, _drv_recolor_rect
	PUBLIC	_drv_char_width, _drv_clear_page, _drv_blit_sprite_var, _drv_end_image_grab
	PUBLIC	_drv_free_page, _drv_slot8, _drv_dissolve_page, _drv_slot9, _drv_font_height
	PUBLIC	_drv_get_row, _drv_get_pixel, _drv_slot12, _drv_nop13, _drv_hide_pointer
	PUBLIC	hide_pointer_ptr, _drv_patch_font, _drv_has_back_buffer, _drv_begin_image_grab
	PUBLIC	_drv_put_row, _drv_copy_rect, _drv_draw_text, _drv_draw_image_scaled
	PUBLIC	_drv_screen_off, _drv_screen_on, _drv_set_page, _drv_set_color
	PUBLIC	_drv_set_palette, _drv_set_color_map, _drv_set_shake, _drv_show_pointer
	PUBLIC	show_pointer_ptr, _drv_show_page, _gfx_show_page, _drv_gate_slot30
	PUBLIC	_drv_draw_image, _drv_end_image, _drv_image_add_row, _drv_begin_image
	PUBLIC	_drv_swap_page, _drv_init_mode, _drv_slot36, _drv_put_pixel, _drv_slot37
	PUBLIC	_drv_fill_spans, _drv_prim_38, _drv_nop39, _drv_prim_39
	PUBLIC	_drv_set_draw_color, _drv_prim_40, _drv_draw_line, _drv_draw_line_seg
	PUBLIC	_drv_text_clip_all, _drv_text_clip_left, _drv_text_noclip
	PUBLIC	_drv_text_clip_right, _drv_text_clip_vert, _drv_select_page, _drv_prim_47
	PUBLIC	_drv_set_port, _drv_prim_48, _drv_copy_rows_to_screen, _drv_shake_tick
	PUBLIC	_drv_kbhit, _drv_getkey, _drv_getche, _drv_misc2, _drv_clear_shift
	PUBLIC	_drv_clear_shift2, _drv_joy_button, _drv_joy_calibrate, _drv_read_joystick_raw
	PUBLIC	_drv_sound_init, _drv_sound100, _drv_play_sound, _drv_sound_shutdown
	PUBLIC	_drv_sound102, _drv_sound_tick, _drv_sound104, _drv_sound_ticks
	PUBLIC	_drv_sound106, _drv_sound107, _drv_sound108, _drv_sound109, _drv_sound110
IFDEF PROG_CHASE
	PUBLIC	_gate_thunk_b
ENDIF
IFDEF PROG_BUG
	PUBLIC	_gate_thunk_b
ENDIF
IFDEF PROG_TAC
	PUBLIC	_gate_thunk_b
ENDIF
IFDEF PROG_GAME
	PUBLIC	_anim_set_pal
ENDIF
	PUBLIC	_load_overlay, _link_driver_stubs, _free_overlay

; ----------------------------------------------------------------------------
; call_gate: entered by `call call_gate` from a gated stub. If the pointer is
; not shown, jump straight to the driver (through the dword after the call);
; otherwise mark the driver busy, call it, and redraw the pointer afterwards if
; the mouse interrupt flagged a move (in_driver 2).
; ----------------------------------------------------------------------------
call_gate:
	cmp	pointer_shown, 0
	jne	gate_busy
	pop	word ptr cs:jump_through	; the stub's dword: our return address
	jmp	short $+2		; (flush the prefetch queue)
jump_through	EQU	word ptr $+3
	jmp	dword ptr cs:[0]
gate_busy:
	mov	in_driver, 1
	pop	word ptr cs:call_through
	pop	word ptr gate_return	; the C caller's return address
	pop	word ptr gate_return+2
	jmp	short $+2
call_through	EQU	word ptr $+3
	call	dword ptr cs:[0]
	dec	in_driver
	je	gate_done
	call	far ptr drv_callback	; the mouse moved: redraw the pointer
	mov	in_driver, 0
gate_done:
	jmp	gate_return

; ----------------------------------------------------------------------------
; the stub table (link_driver_stubs: CS:stub_table + 7 * slot)
; ----------------------------------------------------------------------------
stub_table	LABEL	BYTE
	stub	_drv_alloc_page			; 0
	stub	_drv_mem_avail			; 1
	stub	_drv_get_image			; 2
	stub	_drv_recolor_rect		; 3
	stub	_drv_char_width			; 4
	stub	_drv_clear_page			; 5
IFDEF PROG_CHASE
	gated	_drv_blit_sprite_var, _gate_thunk_b	; 6 draw_image
ELSE
	gated	_drv_blit_sprite_var		; 6 draw_image
ENDIF
	stub	_drv_end_image_grab		; 7
	stub	_drv_free_page, _drv_slot8	; 8
	stub	_drv_dissolve_page, _drv_slot9	; 9
	stub	_drv_font_height		; 10
	stub	_drv_get_row			; 11
	stub	_drv_get_pixel, _drv_slot12	; 12
	stub	_drv_nop13			; 13
	gated	_drv_hide_pointer, , hide_pointer_ptr	; 14
	stub	_drv_patch_font			; 15
	stub	_drv_has_back_buffer		; 16
	stub	_drv_begin_image_grab		; 17
	stub	_drv_put_row			; 18
	stub	_drv_copy_rect			; 19
	stub	_drv_draw_text			; 20
	gated	_drv_draw_image_scaled		; 21
	stub	_drv_screen_off			; 22
	stub	_drv_screen_on			; 23
	stub	_drv_set_page			; 24
	stub	_drv_set_color			; 25
IFDEF PROG_GAME
	stub	_drv_set_palette, _anim_set_pal	; 26
ELSE
	stub	_drv_set_palette		; 26
ENDIF
	stub	_drv_set_color_map		; 27
	stub	_drv_set_shake			; 28
	gated	_drv_show_pointer, , show_pointer_ptr	; 29
_drv_show_page	LABEL	FAR
_drv_gate_slot30	LABEL	FAR
	gated	_gfx_show_page			; 30
IFDEF PROG_BUG
THUNK31	EQU	1
ENDIF
IFDEF PROG_TAC
THUNK31	EQU	1
ENDIF
IFDEF THUNK31
	gated	_drv_draw_image, _gate_thunk_b	; 31 draw_image_noclip
ELSE
	gated	_drv_draw_image			; 31 draw_image_noclip
ENDIF
	stub	_drv_end_image			; 32
	stub	_drv_image_add_row		; 33
	stub	_drv_begin_image		; 34
	stub	_drv_swap_page			; 35
	stub	_drv_init_mode, _drv_slot36	; 36
	stub	_drv_put_pixel, _drv_slot37	; 37
	stub	_drv_fill_spans, _drv_prim_38	; 38
	stub	_drv_nop39, _drv_prim_39	; 39
	stub	_drv_set_draw_color, _drv_prim_40	; 40
	stub	_drv_draw_line, _drv_draw_line_seg	; 41
	stub	_drv_text_clip_all		; 42
	stub	_drv_text_clip_left		; 43
	stub	_drv_text_noclip		; 44
	stub	_drv_text_clip_right		; 45
	stub	_drv_text_clip_vert		; 46
	stub	_drv_select_page, _drv_prim_47	; 47
	stub	_drv_set_port, _drv_prim_48	; 48
	stub	_drv_copy_rows_to_screen	; 49
	stub	_drv_shake_tick			; 50
	REPT	90 - 51				; 51-89
	unused
	ENDM
	stub	_drv_kbhit			; 90 MISC
	stub	_drv_getkey			; 91
	stub	_drv_getche, _drv_misc2		; 92
	stub	_drv_clear_shift		; 93
	stub	_drv_clear_shift2		; 94
	stub	_drv_joy_button			; 95
	stub	_drv_joy_calibrate		; 96
	stub	_drv_read_joystick_raw		; 97
	unused					; 98
	unused					; 99
	stub	_drv_sound_init, _drv_sound100	; 100 sound
	stub	_drv_play_sound			; 101
	stub	_drv_sound_shutdown, _drv_sound102	; 102
	stub	_drv_sound_tick			; 103
	stub	_drv_sound104			; 104
	stub	_drv_sound_ticks		; 105
	stub	_drv_sound106			; 106
	stub	_drv_sound107			; 107
	stub	_drv_sound108			; 108
	stub	_drv_sound109			; 109
	stub	_drv_sound110			; 110
	db	0			; (padding)

; ----------------------------------------------------------------------------
; int far load_overlay(char *file, char *data_file)
;   Loads a driver with EXEC 4B03h (load overlay) into the largest free memory
;   block less 4 KB, then `data_file` (if not 0) after it, and shrinks the block
;   to what the driver reserves (header +2Ah: data segment, +2Ch: data size)
;   plus the data file. Returns the driver's segment. Any error prints a message
;   and exits to DOS.
; ----------------------------------------------------------------------------
_load_overlay:
	mov	bx, sp
	mov	dx, [bx+4]
	mov	bx, [bx+6]
	push	si
	push	di
	push	ds
	push	es
	mov	ovl_name, dx
	mov	ovl_data_name, bx
	mov	ah, 48h			; ask for 1 MB to learn the largest block
	mov	bx, 0FFFFh
	int	21h
	jb	ovl_alloc
	mov	dx, offset DGROUP:msg_alloc
	jmp	ovl_fail
ovl_alloc:
	mov	ah, 48h
	sub	bx, 100h
	mov	ovl_paras, bx
	int	21h
	jae	ovl_exec_it
	mov	dx, offset DGROUP:msg_dos_lied
	jmp	ovl_fail
ovl_exec_it:
	mov	bx, offset DGROUP:ovl_exec
	mov	[bx], ax		; load segment = relocation factor
	mov	[bx+2], ax
	mov	ax, 4B03h
	mov	dx, ovl_name
	push	ds
	pop	es
	mov	ovl_saved_sp, sp
	int	21h
	mov	dx, DGROUP		; DOS 2 may not preserve the registers
	mov	ds, dx
	mov	es, dx
	mov	ss, dx
	mov	sp, ovl_saved_sp
	jae	ovl_loaded
	cmp	ax, 2
	jne	ovl_err8
	mov	dx, offset DGROUP:msg_not_found
	jmp	ovl_fail
ovl_err8:
	cmp	ax, 8
	jne	ovl_err
	mov	dx, offset DGROUP:msg_no_memory
	jmp	ovl_fail
ovl_err:
	mov	dx, offset DGROUP:msg_load_failed
	jmp	ovl_fail
ovl_loaded:
	mov	es, ovl_exec
	mov	bx, es:[2Ah]		; the driver's data segment
	mov	ax, es:[2Ch]		; + its data size in paragraphs
	add	ax, 0Fh
	rcr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	add	bx, ax
	call	load_data_file
	mov	ax, es
	sub	bx, ax
	add	bx, 8
	cmp	bx, ovl_paras
	jbe	ovl_shrink
	mov	dx, offset DGROUP:msg_overrun
	jmp	ovl_fail
ovl_shrink:
	mov	ah, 4Ah
	int	21h
	jae	ovl_done
	mov	dx, offset DGROUP:msg_shrink
	jmp	ovl_fail
ovl_done:
	mov	ax, es
	pop	es
	pop	ds
	pop	di
	pop	si
	retf
ovl_fail:				; DS:DX = the message
	mov	ah, 9
	int	21h
	mov	ax, 4C00h
	int	21h

; Read ovl_data_name (if set) to segment BX (up to 64 KB); returns BX = the
; paragraph after it.
load_data_file:
	push	ds
	mov	dx, ovl_data_name
	or	dx, dx
	je	data_done
	mov	ax, 3D00h		; open
	int	21h
	jae	data_open
	mov	dx, offset DGROUP:msg_not_found
	jmp	ovl_fail
data_open:
	mov	ds, bx
	mov	bx, ax
	mov	ax, 3F00h		; read 32 KB to BX:0
	mov	cx, 8000h
	xor	dx, dx
	int	21h
	jae	data_read
	mov	dx, offset DGROUP:msg_not_found
	jmp	ovl_fail
data_read:
	cmp	ax, cx
	jb	data_size
	mov	ax, ds			; (a full 32 KB read: DS moves on by
	add	ax, 800h		; 32 KB as well, so it counts twice)
	mov	ds, ax
data_size:
	add	ax, 0Fh
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	mov	dx, ds
	add	dx, ax
	mov	ax, 3E00h		; close
	int	21h
	jae	data_closed
	mov	dx, offset DGROUP:msg_not_found
	jmp	ovl_fail
data_closed:
	mov	bx, dx
data_done:
	pop	ds
	ret

; ----------------------------------------------------------------------------
; void far link_driver_stubs(int driver_seg)
;   Copies the driver's export table (header: +28h code segment, +2Eh first
;   slot, +30h count, +32h offsets) into the stubs' far pointers.
; ----------------------------------------------------------------------------
_link_driver_stubs:
	mov	bx, sp
	mov	dx, [bx+4]
	push	si
	push	di
	push	ds
	push	es
	mov	ds, dx
	ASSUME	DS:NOTHING
	mov	si, 32h
	mov	ax, ds:[2Eh]
	mov	dl, 7
	mul	dl
	lea	di, stub_table
	add	di, ax
	mov	ax, ASM0
	mov	es, ax
	mov	cx, ds:[30h]
	mov	ax, ds:[28h]
link_next:
	add	di, 3
	movsw				; offset
	stosw				; segment
	loop	link_next
	pop	es
	pop	ds
	ASSUME	DS:DGROUP
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; void far free_overlay(int seg): release a driver's memory
; ----------------------------------------------------------------------------
_free_overlay:
	mov	bx, sp
	mov	ax, [bx+4]
	push	es
	mov	es, ax
	mov	ah, 49h
	int	21h
	jae	free_done
	mov	dx, offset DGROUP:msg_release
	jmp	ovl_fail
free_done:
	pop	es
	retf
ASM0	ENDS

IFDEF MOUSE_IN_LOADER
	INCLUDE	MOUSE.INC
ENDIF
	END

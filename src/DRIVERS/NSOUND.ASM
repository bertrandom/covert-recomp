; NSOUND.CA
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh NSOUND
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/NSOUND.hints)

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:50h = DATA:0) while DS references, with DS = DATA,
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
	db	'Copyright (C) 1990 by MicroProse Software, All Rights Reserved.',0
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'CV Tnd NoSnd09-13-90'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	50h		; bytes from DATA to the stack
drv_first_slot	db	100
	db	0
drv_count	dw	11		; number of exports
drv_exports	label	word
	dw	offset nsnd_init	; slot 100
	dw	offset nsnd_play_sound	; slot 101
	dw	offset nsnd_play_sound	; slot 102
	dw	offset nsnd_play_sound	; slot 103
	dw	offset nsnd_play_sound	; slot 104
	dw	offset nsnd_play_sound	; slot 105
	dw	offset nsnd_play_sound	; slot 106
	dw	offset nsnd_play_sound	; slot 107
	dw	offset nsnd_play_sound	; slot 108
	dw	offset nsnd_play_sound	; slot 109
	dw	offset nsnd_play_sound	; slot 110

; ----------------------------------------------------------------------------
; nsnd_init (slot 100): Sound driver: initialise (COVERT, at start-up).
; ----------------------------------------------------------------------------
nsnd_init:
	xor	ax, ax

; ----------------------------------------------------------------------------
; nsnd_play_sound (slot 101/102/103/104/105/106/107/108/109/110): Sound driver: play a sound effect.
; ----------------------------------------------------------------------------
nsnd_play_sound:
	retf
CODE	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

; INT24.ASM - critical-error (INT 24h) handler for saving and loading games
; (FINAL, GAME: the first piece of _TEXT, linked before the C code).
;
; install_int24_handler / restore_int24_handler bracket the disk access of the
; save/load screens: while installed, DOS critical errors ("drive not ready",
; "write protected") are ignored instead of ending in Abort, Retry, Fail, and
; the C code sees the failed DOS call.

DGROUP	GROUP	_DATA
	ASSUME	DS:DGROUP		; before _DATA: the PUBDEFs then carry DGROUP

_DATA	SEGMENT WORD PUBLIC 'DATA'
installed	db	0		; 1 while our handler is installed
old_int24	dd	0		; the previous INT 24h vector
new_int24	dd	int24_handler	; the vector we install
_DATA	ENDS

_TEXT	SEGMENT WORD PUBLIC 'CODE'
	ASSUME	CS:_TEXT
	PUBLIC	_install_int24_handler, _restore_int24_handler

; INT 24h: answer "ignore" (AL = 0)
int24_handler:
	mov	al, 0
	iret

; void install_int24_handler(void)
_install_int24_handler:
	mov	al, 1
	xchg	installed, al
	or	al, al
	jne	install_done		; already installed
	mov	ah, 35h			; get the INT 24h vector
	mov	al, 24h
	int	21h
	mov	word ptr old_int24, bx
	mov	word ptr old_int24+2, es
	push	ds
	mov	ah, 25h			; set it to int24_handler
	mov	al, 24h
	lds	dx, new_int24
	int	21h
	pop	ds
install_done:
	ret

; void restore_int24_handler(void)
_restore_int24_handler:
	mov	al, 0
	xchg	installed, al
	or	al, al
	je	restore_done		; not installed
	push	ds
	mov	ah, 25h			; put the old vector back
	mov	al, 24h
	lds	dx, old_int24
	int	21h
	pop	ds
restore_done:
	ret
_TEXT	ENDS
	END

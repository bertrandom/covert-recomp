; PROBE.ASM - probe_drive: is a file on the disk in a drive? (the six game
; programs: the first object of the assembly segment, at 1000:0000)
;
; int far probe_drive(char *pattern, int drive)
;   Parses `pattern` into an FCB and searches for it (FCB find first), first on
;   the default drive, then after selecting `drive`, then (a one-floppy system:
;   INT 11h reports a single drive) on the other floppy. A DOS critical error
;   during a search counts as "not found": the INT 24h handler installed meanwhile
;   only sets `crit_error`. Returns 0 (AL of the last search) when found, -1 when
;   not. DISK.C uses it to ask for the right game disk.

DGROUP	GROUP	_DATA
	ASSUME	DS:DGROUP		; before _DATA: the PUBDEFs then carry DGROUP

_DATA	SEGMENT WORD PUBLIC 'DATA'
old_int24_seg	dw	0		; the previous INT 24h vector
old_int24_off	dw	0
	db	0			; (padding)
search_fcb	db	0		; FCB for find first: drive, then the name
	db	11 dup ('?')
	db	25 dup (0)
IFDEF PROG_CODE
	INCLUDE	CODEDATA.INC		; CODE: graphics library notes, colour maps
ENDIF
_DATA	ENDS

ASM0	SEGMENT PARA PUBLIC 'CODE'
	ASSUME	CS:ASM0
	PUBLIC	_probe_drive

crit_error	dw	0		; set by crit_handler

_probe_drive:
	push	bp
	mov	bp, sp
	push	si
	push	di
	push	es
	mov	ah, 35h			; save the INT 24h vector
	mov	al, 24h
	int	21h
	mov	old_int24_seg, es
	mov	old_int24_off, bx
	mov	ah, 25h			; and install crit_handler
	mov	al, 24h
	mov	dx, offset crit_handler
	push	ds
	push	cs
	pop	ds
	int	21h
	pop	ds
	mov	ax, DGROUP
	mov	es, ax
	mov	si, [bp+6]		; parse the pattern into the FCB
	mov	di, offset DGROUP:search_fcb
	mov	ax, 2900h
	int	21h
	mov	crit_error, 0
	mov	ah, 11h			; find first, default drive
	mov	dx, offset DGROUP:search_fcb
	int	21h
	or	al, al
	je	probe_done
	mov	ah, 0Eh			; select `drive` and try again
	mov	dx, [bp+8]
	int	21h
	mov	crit_error, 0
	mov	ah, 11h
	mov	dx, offset DGROUP:search_fcb
	int	21h
	or	al, al
	jne	one_floppy
	cmp	crit_error, 0
	je	probe_done
one_floppy:
	int	11h			; equipment: number of floppies - 1
	rol	al, 1
	rol	al, 1
	and	al, 3
	jne	other_floppy
not_found:
	mov	ax, -1
	jmp	probe_done
other_floppy:
	mov	crit_error, 0
	mov	ah, 19h			; switch between A: and B:
	int	21h
	xor	al, 1
	mov	dl, al
	mov	ah, 0Eh
	int	21h
	mov	ah, 11h
	mov	dx, offset DGROUP:search_fcb
	int	21h
	cmp	crit_error, 0
	jne	not_found
probe_done:
	cbw
	push	ax
	mov	ah, 25h			; restore INT 24h
	mov	al, 24h
	push	ds
	mov	ds, old_int24_seg
	mov	dx, old_int24_off	; (read through the new DS: not the saved offset)
	int	21h
	pop	ds
	pop	ax
	pop	es
	pop	di
	pop	si
	pop	bp
	retf

; INT 24h during the searches: note it and fail the call (AL = 0: ignore)
crit_handler:
	sti
	push	si
	push	di
	push	es
	push	ds
	push	bx
	push	cx
	push	dx
	mov	crit_error, 1
	mov	al, 0
	pop	dx
	pop	cx
	pop	bx
	pop	ds
	pop	es
	pop	di
	pop	si
	iret
ASM0	ENDS
	END

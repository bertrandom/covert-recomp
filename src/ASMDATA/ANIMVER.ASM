; ANIMVER.ASM - anim_version (3) in CONST: the .PAN file version the animation
; loader accepts (pan_check_header in ANIMPAN.C compares the file's with it). GAME and
; FINAL have it right after ANIMOBJ's CONST (the segment temporary for anim_mem). An
; int in CONST is not something MSC 5.1 emits for C data, so it is hand-written
; (see CONSTW.ASM).
DGROUP	GROUP	CONST
	ASSUME	DS:DGROUP
CONST	SEGMENT WORD PUBLIC 'CONST'
	PUBLIC	_anim_version
_anim_version	dw	3
CONST	ENDS
	END

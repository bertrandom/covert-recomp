; CONSTW.ASM - one word, 3, in CONST. Every program's CONST holds such words (one in
; CODE, BUG, CHASE and TAC; GAME and FINAL have two more, see ANIMVER.ASM) and nothing
; references them. C cannot put a plain word in CONST (MSC 5.1 uses CONST only for
; its floating-point constants and far-data segment temporaries, and the word is not
; relocated, so it is no segment), so it is hand-written; the module that owned it is
; not known. The CONST segment follows _DATA, so where it is linked only matters
; among the CONST contributions (ANIMOBJ's segment temporary in GAME and FINAL).
DGROUP	GROUP	CONST
	ASSUME	DS:DGROUP
CONST	SEGMENT WORD PUBLIC 'CONST'
	dw	3
CONST	ENDS
	END

; ASOUND.CA - Covert Action sound driver for the AdLib (OPL2 FM) card ("Covert Adlib")
;
; Loaded by COVERT as an overlay; exports slots 100-110 (see README "Driver
; interface"). play_sound(n) starts effect n (0-46) from fx_table. The music
; and effect player (from sub_0048 to sub_0B64) is C compiler output (BP
; frames, sub sp with a 16-bit immediate); the timer, OPL access and effect
; handlers are assembly. Registers are written through port 388h/389h with a
; calibrated delay and mirrored in opl_shadow. The sequencer runs from the
; timer interrupt (about 60 Hz, or about 300 Hz while noise effects play),
; chaining to the BIOS handler.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh ASOUND
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/ASOUND.hints)

; JMP rel16 to a label within short range (MASM would make it a short jump)
jmpnear	MACRO	target
	db	0E9h
	dw	target-($+2)
	ENDM

; OP reg, imm16 in the 81 form for an immediate that fits in a byte
; (compiler output; MASM would use the sign-extended 83 form)
subw	MACRO	reg, imm
	db	81h
	IFIDNI	<reg>, <sp>
	db	0ECh
	ENDIF
	dw	imm
	ENDM

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:1AC0h = DATA:0) while DS references, with DS = DATA,
; get segment offsets. DATA is emitted first so MASM's pass 1 knows its labels.
DGROUP	GROUP	CODE, DATA

CODE	SEGMENT WORD PUBLIC 'CODE'
CODE	ENDS
DATA	SEGMENT PARA PUBLIC 'DATA'
DATA	ENDS
BSS	SEGMENT BYTE PUBLIC 'BSS'
BSS	ENDS
STACK	SEGMENT PARA STACK 'STACK'
STACK	ENDS

DATA	SEGMENT
	db	16 dup (0)
	db	'Copyright (C) 1990 by MicroProse Software, All Rights Reserved.',0
	db	0Eh,7,2,2,1,0,30h,0,1,1,5,0,0,1
	db	8 dup (0)
	db	0Dh,2,3,3,1,1,3Fh,0,0,3,6,0,0,1
	db	8 dup (0)
	db	0Dh,5,4,0Bh,1,0,2Bh,0,1,1,5,0,0,1
	db	8 dup (0)
	db	0Fh,1,5,6,1,0,3Fh,0,0,1,6,0,0,1
	db	8 dup (0)
	db	0Ch,7,1,4,0,1,33h,0,0,0,5,0,0,1
	db	8 dup (0)
	db	0Dh,4,7,0Bh,1,0,3Fh,0,0,2,5,1,0,1
	db	8 dup (0)
	db	0Fh,2,0Fh,1,0,0,25h,0,1,0Fh,6,0,0,1
	db	8 dup (0)
	db	0Fh,1,0Fh,5,0,1,3Fh,0,3,1,6,0,0,1
	db	8 dup (0)
	db	0Ah,7,0Fh,0Fh,0,1,3Eh,0,2,0,4,0,0,1
	db	8 dup (0)
	db	0Ah,5,0Fh,0Fh,0,0,3Fh,0,0,1,4,0,0,1
	db	8 dup (0)
	db	0Fh,9,3,1,0,0,3Fh,0,2,4,7,0,0,1
	db	8 dup (0)
	db	0Ch,7,0Fh,0Fh,0,1,3Fh,0,0,2,7,0,0,1
	db	8 dup (0)
	db	0Eh,9,3,6,0,0,3Dh,0,0,1,2,0,0,1
	db	8 dup (0)
	db	0Dh,5,8,6,0,0,3Fh,0,1,1,2,0,0,1
	db	8 dup (0)
	db	0Dh,8,8,0Fh,1,0,36h,0,0,0,5,0,0,1,14h,0
	db	0FFh,3
	db	4 dup (0)
	db	0Ch,3,0Fh,0Fh,1,0,3Fh,0,0,0Ch,5,0,0,1
	db	8 dup (0)
	db	9,0,0Fh,6,1,0,3Dh,0,1,1,3,0,0,1
	db	8 dup (0)
	db	8,0,0Fh,0Ah,1,0,3Fh,0,0,5,3,0,0,1
	db	8 dup (0)
	db	0Fh,1,0Bh,0Bh,0,0,2Eh,0,1,2,0,0,0,1,64h,0
	db	99h,9,33h,3,0,0,0Fh,2,6,0Dh,0,0,3Fh,0,0,5
	db	5,0,0,1
	db	8 dup (0)
	db	0Fh,7,0,1
	db	4 dup (0)
	db	1
	db	4 dup (0)
	db	1,64h,0,11h,11h,0,1,0,0,0Fh,3,6,0Ch,0,0,3Fh
	db	6 dup (0)
	db	1
	db	8 dup (0)
	db	0Fh,8,0,9,1,0,2Ch,0,1,0,5,0,0,1
	db	8 dup (0)
	db	0Ch,3,0,9,1,0,3Fh,0,0,6,5,1,0,1
	db	8 dup (0)
	db	0Fh,0Bh,3,1,0,0,3Fh,0,2,2,7,0,0,1
	db	8 dup (0)
	db	0Fh,7,0Fh,0Fh,0,1,3Fh,0,0,2,7,0,0,1
	db	8 dup (0)
	db	0Fh,6,0Bh,0Dh,0,0,3Fh,0,2
	db	4 dup (0)
	db	1,14h,0,11h,11h,0,1,0,0,0Fh,3,6,0Dh,0,0,3Fh
	db	0,0,1,0,0,0,1
	db	8 dup (0)
	db	0Fh,6,0Bh,0Dh,0,0,3Fh
	db	6 dup (0)
	db	1,14h,0,11h,11h,0,1,0,0,0Fh,5,6,0Dh,0,0,3Fh
	db	6 dup (0)
	db	1
	db	8 dup (0)
	db	7,9,0,1,1,1,3Bh,0,0,1,7,0,0,1
	db	8 dup (0)
	db	9,0Fh,0,0Ah,0,0,3Fh,0,0,5,6,0,0,1
	db	8 dup (0)
	db	0Ch,8,0,6,0,1,35h,0,0,8,7,0,0,1,0Ah,0
	db	76h,2,66h,6,0E0h,0FFh,0Dh,0Ah,0,6,1,0,3Fh,0,0,0Bh
	db	1,0,0,1
	db	8 dup (0)
	db	0Fh,0Fh,0Ah,1,0,0,3Fh,0,2,2,7,0,0,1
	db	8 dup (0)
	db	0Ah,2,0Fh,0Fh,0,1,3Fh,0,0,1,7,0,0,1
	db	8 dup (0)
	db	0Fh,8,0,9,1,0,2Ch,0,0,0,5,0,0,1
	db	8 dup (0)
	db	0Ch,3,0,9,1,0,3Fh,0,0,6,5,1,0,1
	db	8 dup (0)
	db	0Fh,9,0,0Fh,1,0,31h,0,1,0,5,0,0,1
	db	8 dup (0)
	db	0Ah,0Fh,0,0Fh,1,0,3Fh,0,3,3,5,0,0,1
	db	8 dup (0)
	db	9,6,0,2,1,1,28h,0,2,0,4,0,0,1
	db	8 dup (0)
	db	0Ah,6,0,0Bh,1,0,3Fh,0,0,1,4,0,0,1
	db	8 dup (0)
	db	0Ah,2,8,3,1,0,27h,0,0,1,3,0,0,1
	db	8 dup (0)
	db	9,2,5,9,1,1,3Fh,0,0,1,3,0,0,1
	db	8 dup (0)
	db	0Eh,1,0,3,1,0,13h,0,0,1,0,0,0,1
	db	8 dup (0)
	db	4,1,0,8,1,0,3Fh,0,0,2,0,0,0,1
	db	8 dup (0)
	db	0Fh,4,8,4,0,0,2Bh,0,1,2,5,0,0,1
	db	8 dup (0)
	db	0Fh,4,5,4,0,1,3Fh,0,0,2,5,0,0,1
	db	8 dup (0)
	db	6,3,4,0Dh,1,1,11h,0,0,2,5,1,0,1
	db	8 dup (0)
	db	6,1,2,7,1,0,38h,0,0,1,5,0,0,1
	db	8 dup (0)
	db	5,2,1,4,1,1,25h,0,0,1,7,0,0,1
	db	8 dup (0)
	db	5,2,2,0Ah,1,0,3Fh,0,0,1,7,0,1,1
	db	8 dup (0)
	db	0Fh,8,5,0Eh,1,0,2Fh,0,1,0Ah,5,0,0,1
	db	8 dup (0)
	db	0Fh,5,0Fh,0Bh,1,1,3Fh,0,0,2,5,0,0,1
	db	8 dup (0)
	db	0Fh,0Ah,6,6,1,0,21h,0,0,2,5,0,0,1
	db	8 dup (0)
	db	0Fh,5,0Fh,8,1,1,3Fh,0,0,1,5,0,0,1
	db	8 dup (0)
	db	0Fh,6,8,6,0,0,2Ch,0,1,1,5,0,0,1
	db	8 dup (0)
	db	0Fh,5,7,3,0,1,3Fh,0,0,2,5,0,0,1
	db	8 dup (0)
	db	0Dh,0Bh,0Fh,0Fh,0,0,31h
	db	6 dup (0)
	db	1
	db	8 dup (0)
	db	0Dh,8,0Fh,6,0,0,3Fh,0,0,1,0,0,0,1
	db	8 dup (0)
	db	0Fh,9,0Bh,8,0,0,2Ch,3,1,7,0,0,0,1,32h,0
	db	22h,2,0A2h,27h,0,0,0Fh,5,0Ah,0Dh,0,0,3Fh,1,0,1
	db	7,0,0,1
	db	8 dup (0)
	db	0Fh,8,0Fh,0Fh,0,0,25h,0,1,8,1,0,0,1
	db	8 dup (0)
	db	0Fh,9,0Fh,3,0,0,3Fh,0,0,4,1,0,0,1
	db	8 dup (0)
	db	6,4,0Fh,6,0,0,3Fh
	db	6 dup (0)
	db	1
	db	8 dup (0)
	db	6,8,0Fh,6,0,0,3Fh,0,2,0,7,0,0,1
	db	8 dup (0)
	db	0Bh,1,0Fh,6,0,0,3Fh
	db	6 dup (0)
	db	1
	db	8 dup (0)
	db	0Fh,8,0Fh,6,0,0,3Fh,0,3,0,7,0,0,1
	db	8 dup (0)
	db	0Fh,1,0,3,1,0,1Eh
	db	6 dup (0)
	db	1
	db	8 dup (0)
	db	0Fh,1,0,6,1,0,3Fh,0,0,1,0,0,0,1
	db	8 dup (0)
	db	0Fh,9,0,0Fh,0,0,31h,0,1,0,5,0,0,1
	db	8 dup (0)
	db	0Ah,0Fh,0,0Fh,0,0,3Fh,0,3,3,5,0,0,1
	db	8 dup (0)
	db	7,9,0,1,1,0,3Fh,0,0,7,7,0,0,1
	db	8 dup (0)
	db	6,0Fh,0,0Ah,0,0,3Fh,0,0,5,7,0,0,1
	db	8 dup (0)
	db	7,9,0,1,1,1,3Bh,0,0,7,7,0,0,1
	db	8 dup (0)
	db	8,0Fh,0,0Ch,0,0,3Fh,0,0,4,7,0,0,1
	db	8 dup (0)
	db	7,9,0,1,1,1,3Bh,0,0,7,7,0,0,1
	db	8 dup (0)
	db	6,0Fh,0,0Ah,0,0,3Fh,0,0,4,7,0,0,1
	db	8 dup (0)
	db	0Ah,8,2,0,1,1,3Bh,0,0,0Ch,0,0,0,1
	db	8 dup (0)
	db	0Eh,0Ah,0,6,1,0,3Fh,0,0,0Bh,0,0,0,1
	db	8 dup (0)
	db	7,9,0,1,1,1,30h,0,0,7,7,0,0,1
	db	8 dup (0)
	db	7,0Fh,0,6,0,0,3Fh,0,0,2,7,0,0,1
	db	8 dup (0)
	db	5,2,0,0,1,1,3Fh,0,0,7,7,0,0,1
	db	8 dup (0)
	db	2,2,0,3,1,0,20h,0,0,4,6,0,0,1
	db	8 dup (0)
fx_1_data	dw	0F8h,0FA00h,0,0
w_D0790	dw	0
w_D0792	dw	0
w_D0794	dw	0
w_D0796	dw	0
w_D0798	dw	0
w_D079A	db	0FCh,0,0F9h,30h,0FBh,2,0F7h,3,26h,70h,24h,70h,22h,70h,22h,1Ch
	db	21h,1Ch,20h,1Ch,1Fh,0Eh,1Fh,7,20h,7,0FEh,0,0FFh,0,0,70h
	db	0FFh,3,0FCh,0,0F9h,35h,0FFh,0,0F7h,2,26h,15h,26h,15h,24h,0Eh
	db	2Dh,15h,30h,23h,32h,15h,34h,15h,35h,0Eh,2Dh,0Eh,35h,7,32h,7
	db	30h,7,2Dh,7,37h,7,34h,7,26h,15h,26h,15h,24h,0Eh,2Dh,15h
	db	32h,23h,26h,15h,28h,15h,29h,0Eh,2Dh,0Eh,35h,7,30h,7,32h,7
	db	2Dh,7,32h,7,35h,7,0FFh,1,39h,7,3Eh,15h,0,54h,0FFh,0
	db	0,70h,0FFh,2,0FEh,3,0F9h,37h,26h,0Eh,0,62h,0,0
w_D0818	db	0FCh,1,0F9h,33h,0FBh,2,26h,70h,24h,70h,22h,70h,22h,1Ch,21h,1Ch
	db	20h,1Ch,1Fh,0Eh,1Fh,7,20h,7,0FEh,0,0,70h,0FCh,0,0F9h,2Eh
	db	1Ah,0Eh,29h,7,1Ch,0Eh,28h,0Eh,1Dh,0Eh,26h,7,1Ah,7,18h,7
	db	1Ah,0Eh,16h,7,18h,7,0,62h,0F9h,2Eh,14h,7,1Fh,7,1Ah,0Eh
	db	29h,7,1Ch,0Eh,28h,0Eh,1Dh,0Eh,26h,7,1Ah,7,18h,7,1Ah,0Eh
	db	16h,7,18h,7,0FFh,0,0F9h,35h,21h,15h,1Fh,15h,21h,0Eh,0F7h,1
	db	24h,15h,2Bh,23h,0F7h,0,26h,15h,28h,15h,29h,0Eh,2Dh,0Eh,0,2Ah
	db	21h,15h,1Fh,15h,21h,0Eh,24h,15h,2Bh,93h,0FFh,1,1Ah,7,1Ah,7
	db	18h,7,1Ah,0Eh,15h,7,18h,7,1Bh,7,21h,7,0,23h,14h,7
	db	1Fh,7,1Ah,0Eh,29h,7,1Ch,0Eh,28h,0Eh,1Dh,0Eh,26h,7,1Ah,7
	db	18h,7,1Ah,0Eh,16h,7,18h,7,0F9h,30h,0FFh,1,0FEh,3,0F9h,36h
	db	21h,0Eh,0,62h,0,0
w_D08CE	dw	2FCh,33F9h,1FBh,1526h,1526h,2A26h,724h,72Bh
	dw	72Eh,726h,1524h,1524h,2A24h,722h,729h,72Dh
	dw	727h,1522h,1522h,2A22h,721h,728h,72Bh,724h
	dw	0E22h,724h,726h,0E21h,722h,724h,0E20h,721h
	dw	722h,0E1Fh,71Fh,720h,0FEh,37F9h,71Ah,71Ah
	dw	718h,0E1Ah,715h,718h,71Bh,721h,3100h,0E1Ah
	dw	729h,0E1Ch,0E28h,0E1Dh,726h,71Ah,718h,0E1Ah
	dw	716h,718h,71Ah,71Ah,718h,0E1Ah,715h,718h
	dw	71Bh,721h,2300h,714h,71Fh,0E1Ah,729h,0E1Ch
	dw	0E28h,0E1Dh,726h,71Ah,718h,0E1Ah,716h,718h
	dw	33F9h,0FFh,71Ah,71Ah,718h,0E1Ah,715h,718h
	dw	71Bh,721h,3100h,71Ah,724h,729h,0E1Ch,72Ch
	dw	726h,0E1Dh,71Ch,71Ah,724h,0E1Ah,722h,724h
	dw	726h,71Ah,718h,0E26h,715h,718h,71Bh,721h
	dw	2300h,720h,72Bh,71Ah,724h,72Bh,0E1Ch,728h
	dw	722h,0E1Dh,729h,71Ah,718h,0E1Ah,722h,724h
	dw	1FFh,71Ah,71Ah,718h,0E1Ah,715h,718h,71Bh
	dw	721h,2300h,714h,71Fh,0E1Ah,729h,0E1Ch,0E28h
	dw	0E1Dh,726h,71Ah,718h,0E1Ah,716h,718h,1FFh
	dw	3FEh,35F9h,0E1Ah,6200h,0
w_D0A08	dw	3FCh,33F9h,7050h,7000h,7050h,7000h,0FEh,3FCh
	dw	33F9h,7050h,6FCh,38F9h,716h,716h,716h,715h
	dw	2300h,716h,716h,716h,3FCh,33F9h,1C00h,7050h
	dw	6FCh,38F9h,716h,716h,716h,715h,2300h,716h
	dw	716h,716h,1C00h,0FFh,3FCh,30F9h,7050h,6FCh
	dw	38F9h,716h,716h,716h,715h,2300h,716h,716h
	dw	716h,1C00h,3FFh,3FCh,33F9h,7050h,6FCh,38F9h
	dw	716h,716h,716h,715h,2300h,716h,716h,716h
	dw	1C00h,1FFh,3FEh,3FCh,36F9h,7050h,0
w_D0A96	dw	7000h,7000h,7000h,5FCh,38F9h,713h,713h,0E13h
	dw	713h,713h,0E13h,0E13h
	dw	4 dup (713h)
	dw	0E13h,0FEh,1C00h,1C13h,1C00h,1C13h,1C00h,0E13h
	dw	0E13h,1C00h,1C13h,1C00h,1C13h,1C00h,1C13h,1C00h
	dw	713h,713h,0E13h,1C00h,1C13h,0FFh,34F9h,1C00h
	dw	1C13h,1C00h,713h,713h,0E13h,1C00h,0E13h,0E13h
	dw	1C00h,713h,713h,0E13h,1C00h,1C13h,1C00h,1C13h
	dw	1C00h,0E13h,0E13h,1C00h,0E13h,713h,713h,1FFh
	dw	1C00h,1C13h,1C00h,1C13h,1C00h,0E13h,0E13h,1C00h
	dw	1C13h,1FFh,3FEh,1FCh,36F9h,0E1Ah,6200h,0
w_D0B36	dw	4FCh,33F9h,1C11h,1C11h,0E11h,0E11h,1C11h,1C11h
	dw	1511h,711h,0E11h,0E11h,1C11h,1C11h,1C11h,0E11h
	dw	0E11h,1C11h,7000h,0FEh,38F9h,1C11h,1C00h,0E11h
	dw	711h,711h,1C00h,1C11h,1C11h,1C11h,1C00h,1C11h
	dw	1C00h,0E11h,711h,711h,1C00h,1C11h,1C11h,1C11h
	dw	1C00h,0FFh,1C11h,1C00h,0E11h,711h,711h,1C00h
	dw	1C11h,1C11h,1C11h,1C00h,0E11h,0E11h,1C00h,0E11h
	dw	711h,711h,1C00h,1C11h,1C11h,1C11h,1C00h,1FFh
	dw	1C11h,1C00h,0E11h,711h,711h,1C00h,1C11h,1C11h
	dw	1C11h,1C00h,1FFh,3FEh,7000h,0
w_D0BD2	dw	0FFh,7000h,2FFh,2FCh,34F9h,2FBh,1C16h,1C15h
	dw	1C14h,1C13h,0FEh,7000h,7000h,36F9h,726h,726h
	dw	724h,0E26h,721h,724h,727h,72Dh,3100h,7000h
	dw	33F9h,0FFh,726h,726h,724h,0E26h,721h,724h
	dw	727h,72Dh,3100h,7000h,7000h,7000h,1FFh,7000h
	dw	3FFh,3FEh,7000h,0
w_D0C2A	dw	18FCh,24F9h,2FBh,1845h,844h,1845h,844h,1845h
	dw	940h,843h,0C00h,841h,0E00h,503Eh,839h,83Bh
	dw	103Dh,103Eh,5040h,1039h,83Eh,83Fh,1040h,5841h
	dw	839h,1845h,443h,444h,1845h,443h,444h,1845h
	dw	443h,444h,1945h,440h,441h,843h,0C00h,841h
	dw	0E00h,503Eh,1039h,83Ch,83Dh,103Eh,5840h,839h
	dw	841h,800h,840h,800h,583Eh,840h,841h,800h
	dw	842h,843h,5845h,83Ah,846h,800h,845h,844h
	dw	5843h,839h,845h,845h,843h,800h,5841h,837h
	dw	843h,800h,841h,800h,0A040h,1845h,443h,444h
	dw	1945h,443h,444h,1A45h,443h,444h,1B45h,440h
	dw	441h,843h,1100h,841h,1500h,503Eh,1039h,103Dh
	dw	103Eh,5840h,839h,841h,800h,840h,800h,703Eh
	dw	1000h,0
w_D0CFE	dw	1CFCh,1FF9h,2FBh,1000h,1038h,1000h,1038h,1000h
	dw	1038h,2B00h,18FCh,1BF9h,803Eh,8040h,7041h,1000h
	dw	1CFCh,1000h,1038h,1000h,1038h,1000h,1038h,2B00h
	dw	1EF9h,8039h,8037h,8035h,18FCh,803Ch,803Ah,8039h
	dw	0A037h,0BC00h,8039h,8037h,7035h,1000h,0
w_D0D4C	dw	1CFCh,24F9h,2FBh,1000h,102Dh,1000h,102Dh,1000h
	dw	102Dh,2B00h,8000h,8000h,8000h,1000h,102Dh,1000h
	dw	102Dh,1000h,102Dh,2B00h,8035h,8034h,8032h,8000h
	dw	8000h,8000h,0A000h,0BC00h,8000h,8000h,8000h,0
w_D0D8C	dw	1CFCh,24F9h,2FBh,8B00h,8000h,8000h,8000h,8B00h
	dw	802Dh,802Eh,802Dh,8000h,8000h,8000h,0A000h,0BC00h
	dw	8000h,8000h,6000h,1CFCh,2026h,0
w_D0DB8	dw	1DFCh,26F9h,2FBh,8B00h,1037h,1037h,1000h,1037h
	dw	2000h,1BFCh,2044h,1DFCh,1037h,1037h,1000h,1037h
	dw	2000h,1BFCh,1044h,1044h,1DFCh,1037h,1037h,1000h
	dw	1037h,4000h,8B00h,1037h,1037h,1000h,1037h,2000h
	dw	1BFCh,2044h,1DFCh,1037h,1037h,1000h,1037h,2000h
	dw	1BFCh,1044h,1044h,1DFCh,1037h,1037h,1000h,1037h
	dw	4000h,8000h,8000h,8000h,0A000h,0BC00h,1037h,1037h
	dw	1000h,1037h,2000h,1BFCh,2044h,1DFCh,1037h,1037h
	dw	1000h,1037h,2000h,1BFCh,1044h,1044h,6000h,1CFCh
	dw	24F9h,201Ah,0
w_D0E4E	dw	1CFCh,27F9h,2FBh,8B00h,180Eh,815h,101Ah,1021h
	dw	1026h,102Dh,2000h,180Dh,815h,101Ch,101Fh,1021h
	dw	1025h,2000h,180Eh,815h,101Ah,1021h,1026h,1029h
	dw	2000h,8B00h,180Eh,815h,101Ah,1021h,1026h,102Dh
	dw	2000h,180Dh,815h,101Ch,101Fh,1021h,1025h,2000h
	dw	180Eh,815h,101Ah,1021h,1026h,1029h,2000h,1811h
	dw	818h,101Dh,1021h,1024h,1029h,2000h,1813h,81Ah
	dw	101Fh,1022h,1026h,102Bh,2000h,1815h,81Ah,101Dh
	dw	1021h,1026h,1029h,2000h,1815h,81Ch,101Fh,1021h
	dw	1025h,102Dh,1031h,1039h,102Dh,1039h,0BC00h,180Eh
	dw	815h,101Ah,1021h,1026h,102Dh,2000h,1815h,81Ch
	dw	1021h,1025h,1028h,102Dh,2000h,1832h,82Dh,1026h
	dw	1021h,101Ah,1015h,200Eh,0
w_D0F18	db	0
b_D0F19	db	0,0FDh,0,0FCh,15h,0F9h,23h,2Eh,6,30h,6,34h,6,36h,7,3Ah
	db	7,45h,4,45h,4,45h,4,45h,4,45h,4,45h,4,45h,4,45h
	db	4,45h,8,45h,8,45h,8,45h,8,45h,0Ah,45h,0Bh,45h,0Bh,0
	db	0,0FCh,15h,0F9h,28h,3Fh,6,3Fh,6,3Fh,6,3Fh,7,3Fh,7,3Eh
	db	5,38h,5,2Fh,5,29h,5,2Ch,6,32h,6,0,0,0FCh,1Ch,0F9h
	db	23h,1Ah,4,1Bh,4,26h,4,25h,4,1Dh,4,0,0,0FCh,1Ch,0F9h
	db	28h,27h,4,1Eh,4,1Dh,4,20h,4,24h,4,0,0,0FCh,1Ch,0F9h
	db	28h,27h,4,1Eh,4,0,0,0FCh,15h,0F9h,23h,39h,10h,30h,10h,27h
	db	10h,2Dh,10h,0,0,0FCh,15h,0F9h,25h,44h,5,42h,5,40h,5,3Eh
	db	5,3Ch,6,3Ah,6,0,0,0FCh,19h,0F9h,23h,2Eh,80h,0,0,0FCh
	db	15h,0F9h,28h,0F8h,8,0FEh,42h,8,3Eh,8,3Ch,8,38h,8,36h,8
	db	0F8h,0Ah,4,0FFh,0,41h,0Ah,0FFh,3,0F8h,5,0FCh,41h,5,0FFh,6
	db	0F8h,0,0,41h,2Dh,0,0,0FCh,15h,0F9h,25h,49h,8,45h,8,43h
	db	8,3Fh,8,3Dh,8,0F8h,5,0FEh,0FFh,0,48h,5,0FFh,0Ah,0F8h,0
	db	0,30h,19h,0,0,0FCh,15h,0F9h,1Dh,0FBh,3,0FFh,0,2Eh,8,0FFh
	db	4,0FBh,1,0F8h,8,0FCh,2Dh,7,33h,7,24h,7,36h,7,3Fh,7
	db	45h,7,0F8h
	db	4 dup (0)
	db	0FCh,22h,0F9h,2Eh,0FBh,5,1Ah,55h,0FBh,3,28h,5,0F8h,5,0FEh,0FFh
	db	0,1Ah,5,0FFh,3,1Ch,5,1Ah,5,0F8h
	db	4 dup (0)
	db	0FCh,17h,0F9h,23h,2Bh,14h,0F9h,28h,34h,14h,0F9h,23h,3Dh,14h,0F9h,28h
	db	37h,14h,0,0,0FCh,18h,0F9h,2Bh,0F8h,0Ah,0FFh,42h,0A7h,0F8h
	db	4 dup (0)
	db	0FCh,16h,0F9h,2Bh,0FBh,2,0FFh,0,2Eh,7,0FFh,2,32h,7,3Bh,38h
	db	36h,7,35h,7,0F9h,28h,25h,7,0F9h,25h,24h,7,0,0,0FCh,15h
	db	0F9h,23h,43h,0Eh,0F9h,25h,35h,0Eh,0F9h,23h,2Fh,7,0F9h,25h,3Dh,1Ch
	db	0,0,0FCh,1Ch,0F9h,25h,0FBh,4,1Ch,5,1Fh,5,22h,5,0FBh,0
	db	19h,5,0,0,0FCh,1Ah,0F9h,23h,26h,0Ah,26h,0Ah,26h,0Ah,26h,0Ah
	db	0,0,0FCh,1Bh,0F9h,25h,43h,0Dh,43h,0Dh,43h,0Dh,0,0,0FCh,1Ch
	db	0F9h,23h,0FBh,5,45h,5Ah,0F9h,23h,0FBh,4,0F8h,0Ah,1,0FFh,0,45h
	db	5,0FFh,2,45h,0Ah,0FFh,1,45h,5,0FFh,2,45h,0Ah,0FFh,1,0F8h
	db	4 dup (0)
	db	0FCh,22h,0F9h,25h,0F8h,0Ah,0FEh,0FBh,6,22h,0A0h,0,0,0,0FCh,1Ch
	db	0F9h,2Bh,1Fh,5,0FBh,4,22h,5,19h,5,28h,5,0,0,0FCh,1Bh
	db	0F9h,28h,0FFh,0,46h,0Ah,46h,0Ah,0F9h,25h,0FFh,1,0F9h,28h,46h,5
	db	0FFh,1,0F9h,2Bh,46h,5,0FFh,1,0F9h,2Eh,46h,4,0FFh,2,0F9h,2Bh
	db	46h,5,0FFh,1,0F9h,28h,46h,5,0FFh,1,0F9h,25h,46h,0Ah,0FFh,1
	db	0F9h,23h,46h,0Ah,0FFh,1,0,0,0FCh,1Ch,0F9h,2Eh,0FBh,4,1Ch,0Ah
	db	1Bh,0Ah,1Ah,0Ah,1Ch,0Ah,0,0,0FCh,1Ch,0F9h,25h,1Ch,7,2Bh,7
	db	2Eh,7,19h,7,0,0,0FCh,1Ch,0F9h,25h,23h,7,1Ah,7,29h,7
	db	20h,7,0,0,0FCh,15h,0F9h,25h,1Ah,7,1Dh,7,1Fh,7,22h,7
	db	31h,7,29h,7,2Ch,7,2Fh,7,0,0,0FCh,1Ch,0F9h,25h,3Fh,7
	db	39h,7,30h,7,36h,7,0,0,0FCh,15h,0F9h,25h,49h,7,40h,7
	db	3Ah,7,43h,7,0,0,0FCh,1Ch,0F9h,32h,2Ch,7,2Ah,7,18h,7
	db	0,0,0FCh,1Ch,0F9h,32h,2Ch,7,2Ah,7,18h,7,0,7,2Ch,7
	db	37h,7,24h,7,0,0,0FCh,1Ch,0F9h,25h,0F8h,7,2,24h,7,25h
	db	7,33h,7,35h,7,37h,7,39h,1Ch,0F8h
	db	4 dup (0)
	db	0FCh,1Ch,0F9h,32h,0FBh,4,0Ch,7,0Dh,7,0Ch,7,10h,7,0,0
	db	0FCh,1Ch,0F9h,32h,0FBh,0Ah,0Ch,0Eh,0Dh,0Eh,0Ch,0Eh,10h,0Eh,0,0
	db	0FCh,1Ch,0F9h,32h,0,7,1Ch,3,40h,4,0,0,0FCh,1Ch,0F9h,32h
	db	0,0Eh,3Fh,3,1Bh,4,3Fh,3,1Bh,4,0,0,0FCh,22h,0F9h,2Bh
	db	0FBh,5,3Fh,7,3Eh,7,3Ah,7,39h,7,0,0,0FCh,1Ch,0F9h,32h
	db	44h,7,2Ch,7,0,0,0FCh,15h,0F9h,2Eh,0Ah,0Eh,15h,0Eh,18h,0Eh
	db	22h,0Eh,0,0,0FCh,1Ch,0F9h,32h,0FBh,3,0Ah,0Eh,7,0Eh,0Ah,0Eh
	db	9,0Eh,0,0,0FCh,1Ch,0F9h,32h,0FFh,0,18h,1Ch,0FFh,3,0FDh,0
	db	0FCh,1Ch,0F9h,32h,18h,1Ch,14h,4,12h,4,0Ch,14h,18h,1Ch,18h,1Ch
	db	0FDh,0,0FCh,1Ch,0F9h,32h,18h,1Ch,18h,0Eh,16h,0Eh,18h,1Ch,18h,1Ch
	db	0FDh,0,0FCh,1Ch,0F9h,32h,14h,4,12h,4,0Ch,14h,14h,4,1Eh,4
	db	18h,14h,18h,1Ch,16h,1Ch,18h,0Eh,16h,0Eh,0FDh,0,0FCh,1Ch,0F9h,32h
	db	18h,1Ch,19h,1Ch,1Bh,1Ch,18h,1Ch,0FDh,0,0FCh,1Ch,0F9h,32h,18h,1Ch
	db	19h,1Ch,1Bh,1Ch,1Ah,1Ch,0FDh,0,0FCh,1Ch,0F9h,32h,18h,1Ch,18h,1Ch
	db	16h,1Ch,18h,1Ch,0FDh,0,0FCh,1Ch,0F9h,32h,18h,1Ch,16h,1Ch,18h,1Ch
	db	1Ah,1Ch,0FDh,0
w_D12C6	dw	7000h,18FCh,5FBh,34F9h,7037h,1CFCh,34F9h,733h
	dw	6900h,3800h,333h,426h,3100h,15FCh,34F9h,0E00h
	dw	324h,325h,333h,335h,237h,1C39h,3800h,1CFCh
	dw	733h,6900h,15FCh,0E00h,324h,325h,333h,335h
	dw	237h,1C39h,3800h,18FCh,7037h,15FCh,0E00h,324h
	dw	325h,333h,335h,237h,1C39h,3800h,1CFCh,3800h
	dw	333h,426h,3100h,7000h,7000h,0FDh
w_D1332	db	0FCh,15h,0F9h
b_D1335	db	23h,0FBh,0Ah,0Ch,0Eh,0Dh,0Eh,0Ch,0Eh,0Eh,0Eh,0Fh,0Eh,0Dh,0Eh,0Ch
	db	0Eh,0Eh,0Eh,0FDh,0,0FCh,15h,0F9h
b_D134D	db	23h,0FBh,0Ah,0Ch,0Eh,0Dh,0Eh,0Ch,0Eh,0Eh,0Eh,8,0Eh,0Dh,0Eh,0Ch
	db	0Eh,0Ah,0Eh,0FDh,0,0FCh,15h,0F9h
b_D1365	db	23h,0FBh,0Ah,0Ch,0Eh,0Dh,0Eh,0Ch,0Eh,0Eh,0Eh,8,0Eh,0Dh,0Eh,0Ch
	db	0Eh,0Eh,0Eh,0FDh,0,0FCh,15h,0F9h
b_D137D	db	23h,0FBh,0Ah,0Ch,0Eh,0Dh,0Eh,0Ch,0Eh,0Eh,0Eh,6,0Eh,0Dh,0Eh,0Ch
	db	0Eh,0Eh,0Eh,0FDh,0
w_D1392	dw	18FCh,32F9h,5FBh
	dw	4 dup (0B000h)
	dw	0FFh,1634h,0B37h,0B37h,1634h,0B37h,1639h,0B39h
	dw	2C37h,0B37h,0B37h,1634h,1637h,1634h,0B37h,1634h
	dw	0B34h,2C32h,0B37h,0B37h,1634h,0B37h,0B37h,1634h
	dw	0B37h,1639h,0B39h,2C37h,0B37h,0B37h,1634h,0B34h
	dw	1632h,0B32h,5830h,1637h,36F9h,1FFh,1640h,0B40h
	dw	163Eh,0B3Eh,163Ch,0
w_D13F8	dw	18FCh,38F9h,5FBh,0FFh,1628h,0B2Bh,0B2Bh,1628h
	dw	0B2Bh,162Dh,0B2Dh,2C2Bh,0B2Bh,0B2Bh,1628h,162Bh
	dw	1628h,0B2Bh,1628h,0B28h,2C26h,0B2Bh,0B2Bh,1628h
	dw	0B2Bh,0B2Bh,1628h,0B2Bh,162Dh,0B2Dh,2C2Bh,0B2Bh
	dw	0B2Bh,1628h,0B28h,1626h,0B26h,5824h,162Bh,2FFh
	dw	1628h,0B28h,1626h,0B26h,1624h,0
w_D1454	dw	15FCh,32F9h,2FBh,0B000h,0B000h,0B000h,9A00h,0FBFAh
	dw	161Fh,0FAh,36F9h,0FFh,4218h,4218h,0B24h,1624h
	dw	0B1Fh,4218h,4218h,0B1Fh,161Fh,0B1Ah,4218h,4218h
	dw	0B28h,1628h,0B1Fh,2118h,211Fh,4218h,39F9h,0FBFAh
	dw	2C1Fh,36F9h,0FAh,1FFh,2118h,211Fh,0B18h,0
w_D14A4	dw	1EFCh,38F9h,5800h,7FFh,1626h,0B26h,0B26h,1626h
	dw	1626h,1626h,0B26h,0B26h
	dw	5 dup (1626h)
	dw	0B26h,0B26h,1626h,1626h,1626h,0B26h,0B26h,3FFh
	dw	2126h,2126h,0B26h,0
w_D14DE	dw	1FFCh,32F9h
	dw	4 dup (0B000h)
	dw	0FFh,0B00h,0B16h,515h,600h,1600h,0B16h,0B15h
	dw	1600h,0B16h,0B15h,1600h,0B16h,0B15h,0B00h,7FFh
	dw	0
w_D150C	dw	20FCh,32F9h
	dw	4 dup (0B000h)
	dw	0FFh,0B36h,0B36h,0B35h,0B35h,1636h,0B35h,0B35h
	dw	1636h,0B35h,0B35h,0B00h,0B35h,0B36h,0B35h,7FFh
	dw	0
w_D153A	dw	9000h,0CFFh,6C00h,18FCh,3AF9h,0FFh,2435h,1B34h
	dw	1B37h,1239h,1B3Ah,93Eh,243Ch,2445h,946h,93Eh
	dw	93Ah,939h,2441h,1B40h,1B43h,945h,1B46h,943h
	dw	94Ah,2448h,945h,940h,93Ch,939h,945h,93Eh
	dw	93Ah,937h,1FFh,0
w_D1582	dw	9000h,9000h,0FCh,32F9h,2429h,928h,924h,921h
	dw	2D2Bh,92Bh,92Eh,92Bh,2D30h,92Dh,928h,924h
	dw	2D2Dh,39F9h,122Dh,122Bh,32F9h,2435h,934h,930h
	dw	92Dh,2D37h,937h,93Ah,937h,932h,243Ch,939h
	dw	934h,930h,2D39h,92Dh,932h,93Ah,937h,1FFh
	dw	9000h,6C00h,0FFh,30F9h,2429h,928h,930h,92Dh
	dw	1B2Bh,92Dh,92Eh,92Bh,92Eh,92Bh,932h,2430h
	dw	939h,934h,930h,92Dh,93Ah,932h,92Eh,92Dh
	dw	2429h,928h,930h,92Dh,1B2Bh,92Dh,92Eh,92Bh
	dw	92Eh,92Bh,932h,2430h,939h,934h,930h,92Dh
	dw	939h,932h,92Eh,92Bh,1FFh,3AF9h,93Ch,93Eh
	dw	0
w_D1634	dw	2FCh,35F9h,2F7h,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,121Dh,91Fh,91Ah,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,121Dh,91Fh,915h,33F9h,0FFh
	dw	918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,1224h,926h,91Ah,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,39F9h,1224h,922h,33F9h,915h
	dw	1FFh,37F9h,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,1224h,926h,91Ah,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,39F9h,1224h,922h,37F9h,915h
	dw	34F9h,0FFh,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,1224h,926h,91Ah,918h
	dw	4 dup (121Ah)
	dw	91Ah,918h,91Ah,39F9h,1224h,922h,34F9h,915h
	dw	1FFh,3DF9h,918h,91Ah,5A00h,91Dh,91Fh,5A00h
	dw	1220h,121Fh,37F9h,0FFh,918h,91Ah,5A00h,91Dh
	dw	91Fh,5A00h,1220h,121Fh,3FFh,3AF9h,918h,91Ah
	dw	0
w_D1734	dw	21FCh,26F9h,0FEh,0FFh,121Bh,7FFh,4FEh,121Bh
	dw	121Bh,2EF9h,0FFh,121Bh,5FFh,26F9h,0FFh,121Bh
	dw	7FFh,121Bh,121Bh,2EF9h,0FFh,121Bh,5FFh,26F9h
	dw	0FFh,121Bh,7FFh,121Bh,7FFh,121Bh,7FFh,121Bh
	dw	121Bh,26F9h,0FFh,121Bh,5FFh,1B1Bh,2D1Bh,1B00h
	dw	91Bh,241Bh,1B00h,91Bh,1B1Bh,91Bh,241Bh,0FFh
	dw	1B00h,91Bh,241Bh,1B00h,91Bh,241Bh,1B00h,91Bh
	dw	1B1Bh,91Bh,241Bh,3FFh,121Bh,0
w_D17B0	dw	5FCh,37F9h,4FCh,2411h,5FCh,2413h,4FCh,1B11h
	dw	911h,5FCh,1B13h,913h,4FCh,2411h,5FCh,2413h
	dw	4FCh,2411h,5FCh,91Dh,91Ah,91Ah,918h,1FFh
	dw	37F9h,4FCh,2411h,5FCh,2413h,4FCh,1B11h,911h
	dw	5FCh,1B13h,913h,4FCh,2411h,5FCh,2413h,3CF9h
	dw	4FCh,2411h,5FCh,51Dh,41Ah,918h,51Ah,41Ah
	dw	913h,1FFh,37F9h,4FCh,2411h,5FCh,2413h,4FCh
	dw	1B11h,911h,5FCh,1B13h,913h,4FCh,2411h,5FCh
	dw	2413h,4FCh,2411h,5FCh,91Dh,91Ah,91Ah,918h
	dw	4FCh,2411h,5FCh,2413h,4FCh,1B11h,911h,5FCh
	dw	1B13h,913h,4FCh,2411h,5FCh,2413h,3CF9h,2411h
	dw	51Dh,41Ah,918h,51Ah,41Ah,913h,3DF9h,4FCh
	dw	1211h,1211h,5FCh,913h,91Ah,918h,4FCh,911h
	dw	1211h,1211h,5FCh,913h,1B00h,4FCh,1211h,1211h
	dw	5FCh,913h,91Ah,918h,4FCh,911h,5FCh,913h
	dw	918h,913h,91Ah,3CF9h,0FFh,4FCh,1211h,1211h
	dw	5FCh,913h,91Ah,918h,4FCh,911h,1211h,1211h
	dw	5FCh,913h,1B00h,4FCh,1211h,1211h,5FCh,913h
	dw	91Ah,918h,4FCh,911h,5FCh,913h,918h,913h
	dw	91Ah,3FFh,4FCh,1211h,5FCh,0
w_D18EC	dw	2FCh,39F9h,90Ch,360Eh,1200h,900h,900h,900h
	dw	1200h,900h,900h,90Ch,360Eh,1200h,900h,900h
	dw	900h,1200h,900h,900h,30F9h,0FFh,900h
	dw	4 dup (1200h)
	dw	900h,900h,900h,121Dh,91Fh,900h,900h
	dw	4 dup (1200h)
	dw	900h,900h,900h,121Dh,91Fh,900h,1FFh,39F9h
	dw	90Ch,360Eh,1200h,900h,900h,900h,121Dh,91Fh
	dw	900h,90Ch,360Eh,1200h,900h,900h,900h,121Dh
	dw	91Fh,900h,30F9h,0FFh,900h
	dw	4 dup (1200h)
	dw	900h,900h,900h,121Dh,91Fh,900h,900h
	dw	4 dup (1200h)
	dw	900h,900h,900h,121Dh,91Fh,900h,1FFh,3DF9h
	dw	90Ch,90Eh,5A00h,911h,913h,5A00h,1214h,1213h
	dw	37F9h,0FFh,900h,900h,5A00h,911h,913h,5A00h
	dw	1214h,1213h,3FFh,3AF9h,90Ch,90Eh,0
w_D19CE	dw	9000h,9000h,0FCh,32F9h,2F7h,2429h,928h,924h
	dw	921h,2D2Bh,92Bh,92Eh,92Bh,2D30h,92Dh,928h
	dw	924h,2D2Dh,1226h,1226h,2435h,934h,930h,92Dh
	dw	2D37h,937h,93Ah,937h,932h,243Ch,939h,934h
	dw	930h,2D39h,92Dh,932h,93Ah,937h,1FFh,9000h
	dw	6C00h,0FFh,30F9h,2429h,928h,930h,92Dh,1B2Bh
	dw	92Dh,92Eh,92Bh,92Eh,92Bh,932h,2430h,939h
	dw	934h,930h,92Dh,93Ah,932h,92Eh,92Dh,2435h
	dw	928h,93Ch,939h,1B37h,939h,93Ah,937h,93Ah
	dw	937h,93Eh,243Ch,945h,940h,93Ch,939h,945h
	dw	93Eh,93Ah,937h,1FFh,3AF9h,930h,932h,0
w_D1A7E	dw	0FCh,0F9h,0AF8h,2,3C3Ch,0Ah,3A0Ah,0Ah
	dw	0Ah,28h,0F83Ch,0,0A37h,0A00h,0A35h,0A00h
	dw	0A37h,0A00h,1400h,0FEh,0FFh,3C00h,0A3Ch,0A00h
	dw	0A3Ah,0A00h,2800h,3C00h,0A37h,0A00h,0A35h,0A00h
	dw	0A37h,0A00h,1400h,3C00h,0A3Ch,0A00h,0A3Ah,0A00h
	dw	2800h,3C00h,0A37h,0A00h,0A35h,0A00h,0A37h,0A00h
	dw	1400h,537h,2300h,535h,2300h,1FFh,537h,2300h
	dw	64FEh
w_D1AF0	dw	0FCh,0F9h,0AF8h,2,373Ch,0Ah,350Ah,0Ah
	dw	0Ah,28h,0F83Ch,0,0A30h,0A00h,0A2Eh,0A00h
	dw	0A32h,0A00h,1400h,0FEh,0FFh,3C00h,0A37h,0A00h
	dw	0A35h,0A00h,2800h,3C00h,0A30h,0A00h,0A2Eh,0A00h
	dw	0A32h,0A00h,1400h,3C00h,0A37h,0A00h,0A35h,0A00h
	dw	2800h,3C00h,0A30h,0A00h,0A2Eh,0A00h,0A32h,0A00h
	dw	1400h,530h,2300h,52Eh,2300h,1FFh,532h,2300h
	dw	64FEh
w_D1B62	dw	2FCh,0F9h,0AF8h,1D02h,1F0Ah,0Ah,1F0Ah,210Ah
	dw	240Ah,270Ah,0Ah,260Ah,1D0Ah,1F0Ah,0Ah,220Ah
	dw	240Ah,1D0Ah,1F0Ah,0Ah,1F0Ah,210Ah,240Ah,0F80Ah
	dw	0,0A27h,0A00h,0A1Dh,0A1Dh,0A1Fh,0A00h,0A1Dh
	dw	0A1Fh,0FEh,0FFh,0A1Dh,0A1Fh,0A00h,0A1Fh,0A21h
	dw	0A24h,0A27h,0A00h,0A26h,0A1Dh,0A1Fh,0A00h,0A22h
	dw	0A24h,0A1Dh,0A1Fh,0A00h,0A1Fh,0A21h,0A24h,0A27h
	dw	0A00h,0A1Dh,0A1Dh,0A1Fh,0A00h,0A1Dh,0A1Fh,0A1Dh
	dw	0A1Fh,0A00h,0A1Fh,0A21h,0A24h,0A27h,0A00h,0A26h
	dw	0A1Dh,0A1Fh,0A00h,0A22h,0A24h,0A1Dh,0A1Fh,0A00h
	dw	0A1Fh,0A21h,0A24h,0A27h,0A00h,0A1Dh,0A1Dh,0A1Fh
	dw	0A00h,0A1Dh,0A1Fh,282Bh,2829h,1FFh,282Bh,64FEh
w_D1C22	dw	2FCh,0F9h,0AF8h,2902h,2B0Ah,0Ah,2946h,2B0Ah
	dw	0Ah,2E0Ah,300Ah,290Ah,2B0Ah,0Ah,0F828h,0
	dw	1E00h,0A29h,0A2Bh,0A00h,0A29h,0A2Bh,0FEh,0FFh
	dw	0A29h,0A2Bh,4600h,0A29h,0A2Bh,0A00h,0A2Eh,0A30h
	dw	0A29h,0A2Bh,4600h,0A29h,0A2Bh,0A00h,0A29h,0A2Bh
	dw	0A29h,0A2Bh,4600h,0A29h,0A2Bh,0A00h,0A2Eh,0A30h
	dw	0A29h,0A2Bh,4600h,0A29h,0A2Bh,0A00h,0A29h,0A2Bh
	dw	282Bh,2829h,1FFh,282Bh,64FEh
w_D1C9C	dw	21FCh,0F9h,0AF8h,2,3214h,3214h,3214h,0Fh
	dw	3205h,3214h,3214h,0Ah,0Ah,3214h,3214h,0F814h
	dw	0,0F32h,500h,1432h,1432h,0A32h,0A00h,0FEh
	dw	0FFh,1400h,1432h,1432h,0F32h,500h,1432h,1432h
	dw	0A32h,0A00h,1400h,1432h,1432h,0F32h,500h,1432h
	dw	1432h,0A32h,0A00h,1400h,1432h,1432h,0F32h,500h
	dw	1432h,1432h,0A32h,0A00h,1400h,1432h,1432h,0F32h
	dw	500h,1432h,1432h,0A32h,0A00h,2800h,2800h,1FFh
	dw	2800h,64FEh
w_D1D20	dw	5FCh,0F9h,0AF8h,2,3214h,14h,3214h,0Fh
	dw	5,3214h,14h,320Ah,0Ah,3214h,14h,0F814h
	dw	0,0F32h,500h,1400h,1432h,0A00h,0A32h,0FEh
	dw	0FFh,1400h,1432h,1400h,0F32h,500h,1400h,1432h
	dw	0A00h,0A32h,1400h,1432h,1400h,0F32h,500h,1400h
	dw	1432h,0A00h,0A32h,1400h,1432h,1400h,0F32h,500h
	dw	1400h,1432h,0A00h,0A32h,1400h,1432h,1400h,0F32h
	dw	500h,1400h,1432h,0A00h,0A32h,2800h,2800h,1FFh
	dw	2800h,64FEh
w_D1DA4	dw	4FCh,0F9h,0AF8h,1102h,14h,14h,14h,130Fh
	dw	1105h,14h,14h,0Ah,110Ah,14h,14h,0F814h
	dw	0,0F00h,513h,1411h,1400h,0A00h,0A00h,0FEh
	dw	0FFh,1411h,1400h,1400h,0F00h,513h,1411h,1400h
	dw	0A00h,0A00h,1411h,1400h,1400h,0F00h,513h,1411h
	dw	1400h,0A00h,0A00h,1411h,1400h,1400h,0F00h,513h
	dw	1411h,1400h,0A00h,0A00h,1411h,1400h,1400h,0F00h
	dw	513h,1411h,1400h,0A00h,0A00h,2800h,2800h,1FFh
	dw	2800h,64FEh
w_D1E28	dw	16FCh,35F9h,2FBh,0FFFAh,122Fh,600h,3AF9h,182Eh
	dw	0C00h,3BF9h,182Dh,1800h,0FAh,37F9h,3F8h,2CFFh
	dw	94h,0
w_D1E4C	dw	16FCh,35F9h,2FBh,0FFFAh,1225h,600h,3AF9h,1824h
	dw	0C00h,3BF9h,1822h,1800h,0FAh,37F9h,3F8h,1EFFh
	dw	94h,0
w_D1E70	dw	3FCh,37F9h,2FBh,0C00h,1825h,4800h,5FCh,101Fh
	dw	101Fh,101Fh,3FCh,7850h,0
w_D1E8A	dw	4FCh,39F9h,2FBh,0C00h,1800h,4800h,1000h,1011h
	dw	1000h,3FCh,7800h,0
w_D1EA2	dw	0DFCh,3FF9h,144Dh,10FCh,37F9h,0A30h,0
w_D1EB0	dw	0EFCh,3DF9h,144Dh,10FCh,3FF9h,0A30h,0
w_D1EBE	dw	4FCh,3DF9h,0FFh,60Eh,5FFh,60Eh,0
w_D1ECC	dw	0CFCh,3BF9h,55Eh,0
w_D1ED4	dw	25FCh,3AF9h,64Dh,454h,0
w_D1EDE	dw	26FCh,3AF9h,144Dh,0
w_D1EE6	dw	4FCh,3AF9h,1410h,0
w_D1EEE	dw	13FCh,3CF9h,5FAh,1E24h,0FAh,0,12FCh,3CF9h
	dw	6401h,0
w_D1F02	dw	28FCh,3BF9h,5FAh,1421h,0FAh,0,12FCh,3CF9h
	dw	5FAh,0F502h,0FAh,0
w_D1F1A	dw	9FCh,3FF9h,6415h,0
w_D1F22	dw	0AFCh,3FF9h,6411h,0
w_D1F2A	dw	8FCh,37F9h,1E1Dh,0
w_D1F32	dw	8FCh,37F9h,0A3Ch,0A3Ch,0
w_D1F3C	dw	8FCh,39F9h,2FBh,748h,748h,745h,74Ah,749h
	dw	746h,0
w_D1F50	dw	23FCh,39F9h,143Eh,0
w_D1F58	dw	24FCh,39F9h,5FAh,1459h,0FAh,0
w_D1F64	dw	4FCh,2FF9h,0A10h,0
w_D1F6C	dw	14FCh,38F9h,5FAh,1411h,0FAh,0
w_D1F78	dw	14FCh,38F9h,0FBFAh,1411h,0FAh,0
w_D1F84	dw	0CFCh,32F9h,1411h,0
w_D1F8C	dw	0CFCh,3CF9h,33Ch,33Ch,0
w_D1F96	dw	13FCh,3CF9h,5FAh,1E24h,0FAh,0
w_D1FA2	dw	0FFCh,37F9h,52Bh,626h,0FDh,0
w_D1FAE	dw	0DFCh,3FF9h,6411h,0
w_D1FB6	dw	0EFCh,3FF9h,6411h,0
w_D1FBE	dw	0CFCh,38F9h,354h,354h,354h,348h,348h,348h
	dw	33Ch,33Ch,33Ch,335h,335h,335h
	dw	4 dup (33Ch)
	dw	354h,354h,354h,0
w_D1FEA	dw	8FCh,3AF9h,34Ah,345h,341h,33Eh,341h,345h
	dw	34Ah,345h,341h,33Eh,341h,345h,34Ah,34Dh
	dw	351h,0
w_D200E	dw	27FCh,37F9h,0E35h,0
w_D2016	dw	11FCh,3CF9h,55Eh,552h,554h,0,64h,0EBh
w_D2026	dw	4D2h,9248h
w_D202A	dw	200h,21Eh,23Fh,261h,285h,2ABh,2D4h,2FFh
	dw	32Dh,35Dh,390h,3C7h
b_D2042	db	1
b_D2043	db	1
b_D2044	db	1,0
b_D2046	db	0,3,1,4,2,5,6,9,7,0Ah,8,0Bh,0Ch,0Fh,0Dh,10h
	db	0Eh,11h
b_D2058	db	0,1,2,3,4,5,8,9,0Ah,0Bh,0Ch,0Dh,10h,11h,12h,13h
	db	14h,15h
	db	512 dup (53h)
	db	0,0
w_D226C	dw	0,0
w_D2270	dw	0
w_D2272	dw	0
w_D2274	dw	3Eh
w_D2276	dw	9
w_D2278	dw	0
w_D227A	dw	0
w_D227C	dw	0
w_D227E	dw	0
w_D2280	dw	0
b_D2282	db	0
w_D2283	dw	0
b_D2285	db	0
b_D2286	db	0
b_D2287	db	0
b_D2288	db	0
b_D2289	db	0
w_D228A	dw	0
b_D228C	db	0
b_D228D	db	0
b_D228E	db	0
b_D228F	db	0
w_D2290	dw	0
b_D2292	db	0
b_D2293	db	0
b_D2294	db	0
w_D2295	dw	60h,240h,2A0h,300h,360h,1DA0h,0,0
w_D22A5	dw	0F1Ch,0F4Ah,0F66h,0F76h,0F86h,0F90h,0F9Eh,0FB0h
w_D22B5	dw	0FB8h,0FE0h,0FFEh,1020h,103Eh,1052h,1060h,107Eh
	dw	1092h,10A4h,10B2h,10BEh,10E4h,10F2h,1102h,113Ch
	dw	114Ch,115Ah,1168h,117Eh,118Ch,119Ah,11A6h,11BAh
	dw	11D2h,11E2h,11F2h,11FEh,120Eh,121Eh,1228h,1236h
	dw	1246h,1252h,1264h,1274h,128Eh,129Ch,12AAh,12B8h
w_D2305	dw	1332h,134Ah,1362h,137Ah
; variables in the uninitialised BSS segment that follows
w_D2316	equ	word ptr $+9
w_D2318	equ	word ptr $+11
w_D231A	equ	word ptr $+13
w_D231C	equ	word ptr $+15
b_D2320	equ	byte ptr $+19
w_D2322	equ	word ptr $+21
w_D232C	equ	word ptr $+31
w_D232E	equ	word ptr $+33
w_D233C	equ	word ptr $+47
w_D2348	equ	word ptr $+59
w_D2356	equ	word ptr $+73
w_D2360	equ	word ptr $+83
w_D2362	equ	word ptr $+85
w_D2370	equ	word ptr $+99
w_D238A	equ	word ptr $+125
w_D23A4	equ	word ptr $+151
w_D23BE	equ	word ptr $+177
w_D23D8	equ	word ptr $+203
b_D23F2	equ	byte ptr $+229
b_D23F3	equ	byte ptr $+230
w_D23F4	equ	word ptr $+231
w_D23F6	equ	word ptr $+233
b_D23FC	equ	byte ptr $+239
b_D23FD	equ	byte ptr $+240
b_D23FE	equ	byte ptr $+241
opl_shadow	equ	byte ptr $+243
b_D24BD	equ	byte ptr $+432
b_D2500	equ	byte ptr $+499
w_D2558	equ	word ptr $+587
w_D255E	equ	word ptr $+593
w_D2560	equ	word ptr $+595
w_D2562	equ	word ptr $+597
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'Covert Adlib10-18-90'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	2570h		; bytes from DATA to the stack
drv_first_slot	db	100
	db	0
drv_count	dw	11		; number of exports
drv_exports	label	word
	dw	offset asnd_init	; slot 100
	dw	offset asnd_play_sound	; slot 101
	dw	offset asnd_shutdown	; slot 102
	dw	offset asnd_nop103	; slot 103
	dw	offset asnd_nop104	; slot 104
	dw	offset asnd_get_ticks	; slot 105
	dw	offset asnd_nop106	; slot 106
	dw	offset asnd_nop107	; slot 107
	dw	offset asnd_nop108	; slot 108
	dw	offset asnd_nop109	; slot 109
	dw	offset asnd_nop110	; slot 110

; ----------------------------------------------------------------------------
; sub_0048
; ----------------------------------------------------------------------------
sub_0048:
	push	bp
	mov	bp, sp
	subw	sp, 4
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	mov	bx, 2046h
	add	bx, ax
	mov	al, byte ptr [bx+1]
	cbw
	mov	bx, ax
	mov	al, byte ptr [bx+b_D2058]
	cbw
	add	ax, 40h
	mov	word ptr [bp-2], ax
	mov	bx, ax
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 0C0h
	mov	word ptr [bp-4], ax
	mov	ax, word ptr [bp+4]
	and	ax, 3Fh
	mov	cx, 3Fh
	sub	cx, ax
	or	word ptr [bp-4], cx
	mov	ax, word ptr [bp-4]
	push	ax
	mov	ax, word ptr [bp-2]
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_009A
; ----------------------------------------------------------------------------
sub_009A:
	push	bp
	mov	bp, sp
	subw	sp, 0Ch
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	add	ax, 0A0h
	mov	word ptr [bp-2], ax
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	mov	cx, 0Ch
	cwd
	idiv	cx
	mov	byte ptr [bp-8], dl
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	mov	cx, 0Ch
	cwd
	idiv	cx
	mov	byte ptr [bp-0Ah], al
	mov	al, byte ptr [bp+6]
	cbw
	mov	word ptr [bp-0Ch], ax
	mov	al, byte ptr [bp-8]
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	mov	ax, word ptr [bp-0Ch]
	add	ax, word ptr [bx+w_D202A]
	mov	word ptr [bp-4], ax
	and	ax, 0FFh
	push	ax
	mov	ax, word ptr [bp-2]
	push	ax
	call	opl_write_c
	add	sp, 4
	add	word ptr [bp-2], 10h
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 20h
	mov	byte ptr [bp-6], al
	mov	cx, 8
	mov	ax, word ptr [bp-4]
	shr	ax, cl
	mov	word ptr [bp-0Ch], ax
	mov	al, byte ptr [bp-0Ah]
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	mov	cx, word ptr [bp-0Ch]
	or	cx, ax
	or	byte ptr [bp-6], cl
	mov	al, byte ptr [bp-6]
	and	ax, 0FFh
	push	ax
	mov	ax, word ptr [bp-2]
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	db	90h,55h,8Bh,0ECh,81h,0ECh,4,0,0A0h,0FCh,23h,25h,0FFh,0,5,0A0h
	db	0,89h,46h,0FEh,8Bh,46h,4,25h,0FFh,0,50h,8Bh,46h,0FEh,50h,0E8h
	db	0F0h,0Ch,83h,0C4h,4,83h,46h,0FEh,10h,8Bh,5Eh,0FEh,8Ah,87h,0,24h
	db	25h,20h,0,88h,46h,0FCh,0B9h,8,0,8Bh,46h,4,0D3h,0E8h,8,46h
	db	0FCh,8Ah,46h,0FCh,25h,0FFh,0,50h,8Bh,46h,0FEh,50h,0E8h,0C3h,0Ch,83h
	db	0C4h,4,8Bh,0E5h,5Dh,0C3h
	EVEN

; ----------------------------------------------------------------------------
; sub_018E
; ----------------------------------------------------------------------------
sub_018E:
	push	bp
	mov	bp, sp
	subw	sp, 0Ah
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	add	ax, 0A0h
	mov	word ptr [bp-2], ax
	add	ax, 10h
	mov	word ptr [bp-4], ax
	mov	bx, ax
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 1Fh
	mov	cx, 8
	shl	ax, cl
	mov	word ptr [bp-6], ax
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 0FFh
	mov	word ptr [bp-0Ah], ax
	mov	al, byte ptr [bp+4]
	cbw
	mov	cx, word ptr [bp-0Ah]
	add	cx, ax
	add	word ptr [bp-6], cx
	and	word ptr [bp-6], 1FFFh
	mov	ax, word ptr [bp-6]
	and	ax, 0FFh
	push	ax
	mov	ax, word ptr [bp-2]
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	bx, word ptr [bp-4]
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 20h
	mov	byte ptr [bp-8], al
	mov	cx, 8
	mov	ax, word ptr [bp-6]
	shr	ax, cl
	or	byte ptr [bp-8], al
	mov	al, byte ptr [bp-8]
	and	ax, 0FFh
	push	ax
	mov	ax, word ptr [bp-4]
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; L_0214
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0214:
	push	bp
	mov	bp, sp
	subw	sp, 8
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	mov	bx, 2046h
	add	bx, ax
	mov	al, byte ptr [bx+1]
	cbw
	mov	bx, ax
	mov	al, byte ptr [bx+b_D2058]
	cbw
	add	ax, 40h
	mov	word ptr [bp-2], ax
	mov	bx, ax
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 0FFh
	mov	word ptr [bp-6], ax
	and	ax, 3Fh
	mov	word ptr [bp-8], ax
	mov	al, byte ptr [bp+4]
	cbw
	mov	cx, word ptr [bp-8]
	sub	cx, ax
	mov	word ptr [bp-4], cx
	mov	ax, word ptr [bp-6]
	and	ax, 0FFC0h
	or	word ptr [bp-4], ax
	mov	ax, word ptr [bp-4]
	push	ax
	mov	ax, word ptr [bp-2]
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; sub_0272
; ----------------------------------------------------------------------------
sub_0272:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	add	ax, 0B0h
	mov	word ptr [bp-2], ax
	mov	bx, ax
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 0DFh
	push	ax
	push	bx
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; sub_029A
; ----------------------------------------------------------------------------
sub_029A:
	push	bp
	mov	bp, sp
	subw	sp, 4
	push	si
	push	di
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	mov	al, byte ptr [bx+b_D2500]
	and	ax, 0FFh
	jne	L_02BD
	jmp	L_0391
L_02BD:
	mov	al, byte ptr b_D23F2
	and	ax, 0FFh
	je	L_02C8
	jmpnear	L_032E
L_02C8:
	mov	al, byte ptr b_D23FC
	mov	byte ptr b_D23FD, al
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	mov	al, byte ptr [bx+b_D2500]
	mov	byte ptr b_D23F2, al
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bx+2]
	mov	word ptr w_D23F4, ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bx+4]
	mov	word ptr w_D2316, ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bx+6]
	mov	word ptr w_D231A, ax
	call	timer_fast
	jmpnear	L_0391
L_032E:
	mov	al, byte ptr b_D23FC
	mov	byte ptr b_D23FE, al
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	mov	al, byte ptr [bx+b_D2500]
	mov	byte ptr b_D23F3, al
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bx+2]
	mov	word ptr w_D23F6, ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bx+4]
	mov	word ptr w_D2318, ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bx+6]
	mov	word ptr w_D231C, ax
	call	timer_fast
L_0391:
	mov	al, byte ptr [bp+8]
	cbw
	push	ax
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	push	ax
	call	sub_009A
	add	sp, 4
	mov	al, byte ptr [bp+6]
	and	ax, 0FFh
	push	ax
	call	sub_0048
	add	sp, 2
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	add	ax, 0B0h
	mov	word ptr [bp-2], ax
	mov	bx, ax
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 0FFh
	or	ax, 20h
	push	ax
	push	bx
	call	opl_write_c
	add	sp, 4
	pop	di
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; sub_03D6
; ----------------------------------------------------------------------------
sub_03D6:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D24BD
	and	ax, 3Fh
	mov	byte ptr [bp-2], al
	mov	al, byte ptr b_D2042
	and	ax, 0FFh
	je	L_03F4
	mov	ax, 80h
	jmp	L_03F6
L_03F4:
	xor	ax, ax
L_03F6:
	or	byte ptr [bp-2], al
	mov	al, byte ptr b_D2043
	and	ax, 0FFh
	je	L_0406
	mov	ax, 40h
	jmp	short L_0408
L_0406:
	xor	ax, ax
L_0408:
	or	byte ptr [bp-2], al
	mov	al, byte ptr [bp-2]
	and	ax, 0FFh
	push	ax
	mov	ax, 0BDh
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; sub_0420
; ----------------------------------------------------------------------------
sub_0420:
	mov	al, byte ptr b_D2044
	and	ax, 0FFh
	je	L_042E
	mov	ax, 40h
	jmp	L_0430
L_042E:
	xor	ax, ax
L_0430:
	push	ax
	mov	ax, 8
	push	ax
	call	opl_write_c
	add	sp, 4
	ret

; ----------------------------------------------------------------------------
; sub_043C
; ----------------------------------------------------------------------------
sub_043C:
	push	bp
	mov	bp, sp
	subw	sp, 4
	mov	ax, word ptr w_D255E
	add	ax, 40h
	mov	word ptr [bp-4], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+6]
	and	ax, 3Fh
	mov	cx, 3Fh
	sub	cx, ax
	mov	word ptr [bp-2], cx
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+7]
	and	ax, 0FFh
	mov	cx, 6
	shl	ax, cl
	or	word ptr [bp-2], ax
	mov	ax, word ptr [bp-2]
	push	ax
	push	word ptr [bp-4]
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_0482
; ----------------------------------------------------------------------------
sub_0482:
	push	bp
	mov	bp, sp
	subw	sp, 4
	mov	ax, word ptr w_D2558
	add	ax, 0C0h
	mov	word ptr [bp-4], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+0Ah]
	and	ax, 0FFh
	shl	ax, 1
	mov	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+0Dh]
	and	ax, 0FFh
	je	L_04B2
	xor	ax, ax
	jmp	L_04B5
L_04B2:
	mov	ax, 1
L_04B5:
	or	word ptr [bp-2], ax
	mov	ax, word ptr [bp-2]
	push	ax
	push	word ptr [bp-4]
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_04CA
; ----------------------------------------------------------------------------
sub_04CA:
	push	bp
	mov	bp, sp
	subw	sp, 4
	mov	ax, word ptr w_D255E
	add	ax, 60h
	mov	word ptr [bp-4], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+1]
	and	ax, 0Fh
	or	word ptr [bp-2], ax
	mov	ax, word ptr [bp-2]
	push	ax
	push	word ptr [bp-4]
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; sub_050C
; ----------------------------------------------------------------------------
sub_050C:
	push	bp
	mov	bp, sp
	subw	sp, 4
	mov	ax, word ptr w_D255E
	add	ax, 80h
	mov	word ptr [bp-4], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+2]
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+3]
	and	ax, 0Fh
	or	word ptr [bp-2], ax
	mov	ax, word ptr [bp-2]
	push	ax
	push	word ptr [bp-4]
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_0550
; ----------------------------------------------------------------------------
sub_0550:
	push	bp
	mov	bp, sp
	subw	sp, 4
	mov	ax, word ptr w_D255E
	add	ax, 20h
	mov	word ptr [bp-4], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+0Bh]
	and	ax, 0FFh
	je	L_0572
	mov	ax, 80h
	jmp	L_0574
L_0572:
	xor	ax, ax
L_0574:
	mov	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+0Ch]
	and	ax, 0FFh
	je	L_0588
	mov	ax, 40h
	jmp	short L_058A
L_0588:
	xor	ax, ax
L_058A:
	add	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+4]
	and	ax, 0FFh
	je	L_059E
	mov	ax, 20h
	jmp	short L_05A0
L_059E:
	xor	ax, ax
L_05A0:
	add	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+5]
	and	ax, 0FFh
	je	L_05B4
	mov	ax, 10h
	jmp	short L_05B6
L_05B4:
	xor	ax, ax
L_05B6:
	add	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+9]
	and	ax, 0Fh
	add	word ptr [bp-2], ax
	mov	ax, word ptr [bp-2]
	push	ax
	push	word ptr [bp-4]
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_05D8
; ----------------------------------------------------------------------------
sub_05D8:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	ax, word ptr w_D255E
	add	ax, 0E0h
	mov	word ptr [bp-2], ax
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+8]
	and	ax, 3
	push	ax
	mov	ax, word ptr [bp-2]
	push	ax
	call	opl_write_c
	add	sp, 4
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_0602
; ----------------------------------------------------------------------------
sub_0602:
	call	sub_03D6
	call	sub_0420
	call	sub_043C
	call	sub_0482
	call	sub_04CA
	call	sub_050C
	call	sub_0550
	call	sub_05D8
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_061C
; ----------------------------------------------------------------------------
sub_061C:
	push	bp
	mov	bp, sp
	subw	sp, 2
	push	si
	push	di
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	add	ax, 0B0h
	mov	word ptr w_D2558, ax
	mov	bx, ax
	mov	al, byte ptr [bx+opl_shadow]
	and	ax, 0DFh
	push	ax
	push	bx
	call	opl_write_c
	add	sp, 4
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	mov	word ptr w_D2558, ax
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	mov	cx, 2Ch
	imul	cx
	mov	cx, 50h
	add	cx, ax
	mov	word ptr w_D2562, cx
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	mov	al, byte ptr [bx+b_D2046]
	cbw
	mov	bx, ax
	mov	al, byte ptr [bx+b_D2058]
	cbw
	mov	word ptr w_D255E, ax
	call	sub_0602
	mov	bx, word ptr w_D2562
	mov	al, byte ptr [bx+0Eh]
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	mov	ax, word ptr [bp-2]
	mov	byte ptr [bx+b_D2500], al
	mov	bx, word ptr w_D2562
	mov	ax, word ptr [bx+10h]
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bp-2]
	mov	word ptr [bx+2], ax
	mov	bx, word ptr w_D2562
	mov	ax, word ptr [bx+12h]
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bp-2]
	mov	word ptr [bx+4], ax
	mov	bx, word ptr w_D2562
	mov	ax, word ptr [bx+14h]
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2500h
	add	bx, ax
	mov	ax, word ptr [bp-2]
	mov	word ptr [bx+6], ax
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	mov	cx, 2Ch
	imul	cx
	mov	cx, 50h
	add	cx, ax
	mov	ax, 16h
	add	cx, ax
	mov	word ptr w_D2562, cx
	mov	al, byte ptr b_D23FC
	and	ax, 0FFh
	shl	ax, 1
	mov	bx, 2046h
	add	bx, ax
	mov	al, byte ptr [bx+1]
	cbw
	mov	bx, ax
	mov	al, byte ptr [bx+b_D2058]
	cbw
	mov	word ptr w_D255E, ax
	call	sub_0602
	pop	di
	pop	si
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; sub_073A
; ----------------------------------------------------------------------------
sub_073A:
	push	bp
	mov	bp, sp
	subw	sp, 6
	push	si
	push	di
	mov	byte ptr [bp-4], 0
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	jne	L_0755
	jmp	L_0AEB
L_0755:
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+7]
	and	ax, 0FFh
	je	L_0773
	mov	bx, word ptr w_D2560
	dec	byte ptr [bx+7]
	mov	al, byte ptr [bx+7]
	and	ax, 0FFh
	jne	L_0773
	call	sub_0272
L_0773:
	mov	bx, word ptr w_D2560
	dec	byte ptr [bx]
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	jle	L_0783
	jmp	L_0AEB
L_0783:
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	word ptr [bp-2], ax
	mov	bx, ax
	mov	al, byte ptr [bx]
	cbw
	and	ax, 80h
	jne	L_079A
	jmp	L_0A58
L_079A:
	mov	bx, word ptr [bp-2]
	cmp	byte ptr [bx], 0F6h
	jg	L_07A6
	jmp	L_0A58
	EVEN
L_07A6:
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	jmp	L_0A2E
	EVEN
L_07B0:
	mov	bx, word ptr w_D2560
	cmp	word ptr [bx+12h], 0
	je	L_07BD
	jmpnear	L_0808
L_07BD:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	cmp	byte ptr [bx], 0
	jne	L_07EA
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Eh], ax
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+12h], 0
	jmp	L_0805
L_07EA:
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+12h], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Eh]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ch], ax
L_0805:
	jmp	L_0840
L_0808:
	mov	bx, word ptr w_D2560
	dec	word ptr [bx+12h]
	mov	bx, word ptr w_D2560
	cmp	word ptr [bx+12h], 0
	jne	L_0832
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Eh], ax
	jmp	L_0840
L_0832:
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Eh]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ch], ax
L_0840:
	jmp	L_0A54
	EVEN
L_0844:
	mov	bx, word ptr w_D2560
	cmp	word ptr [bx+14h], 0
	je	L_0851
	jmpnear	L_08B2
L_0851:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	cmp	byte ptr [bx], 0
	jne	L_0894
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+10h], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Eh], ax
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+12h], 0
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+14h], 0
	jmp	short L_08AF
L_0894:
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+14h], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+10h]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ch], ax
L_08AF:
	jmpnear	L_08F8
L_08B2:
	mov	bx, word ptr w_D2560
	dec	word ptr [bx+14h]
	mov	bx, word ptr w_D2560
	cmp	word ptr [bx+14h], 0
	jne	L_08EA
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+10h], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Eh], ax
	jmp	L_08F8
L_08EA:
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+10h]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ch], ax
L_08F8:
	jmp	L_0A54
	EVEN
L_08FC:
	mov	bx, word ptr w_D2560
	cmp	word ptr [bx+16h], 0
	jne	L_0916
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ah]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ch], ax
	jmp	short L_094E
L_0916:
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ah], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Ch], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+0Eh], ax
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr w_D2560
	mov	word ptr [bx+10h], ax
L_094E:
	jmp	L_0A54
	EVEN
L_0952:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+4], al
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+4]
	and	ax, 0FFh
	push	ax
	call	sub_061C
	add	sp, 2
	jmp	L_0A54
	EVEN
L_097E:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+6], al
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	jmp	L_0A54
L_0998:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+1], al
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	jmp	L_0A54
L_09B2:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+5], al
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+5]
	and	ax, 0FFh
	push	ax
	call	sub_0048
	add	sp, 2
	jmpnear	L_0A54
	EVEN
L_09DE:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+9], al
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+2], al
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+8], 1
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 3
	jmpnear	L_0A54
	EVEN
L_0A10:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+18h], al
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	jmpnear	L_0A54
	db	0E9h,27h,0
	EVEN
L_0A2E:
	sub	ax, 0FFF7h
	cmp	ax, 8
	jbe	L_0A39
	jmpnear	L_0A54
L_0A39:
	shl	ax, 1
	mov	bx, ax
	jmp	word ptr cs:[bx+w_0A42]
w_0A42	dw	offset L_0A10
	dw	offset L_09DE
	dw	offset L_09B2
	dw	offset L_0998
	dw	offset L_097E
	dw	offset L_0952
	dw	offset L_08FC
	dw	offset L_0844
	dw	offset L_07B0
L_0A54:
	jmp	L_0783
	EVEN
L_0A58:
	mov	bx, word ptr w_D2560
	mov	ax, word ptr [bx+0Ch]
	mov	word ptr [bp-2], ax
	mov	bx, word ptr [bp-2]
	inc	word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+3], al
	mov	bx, word ptr [bp-2]
	inc	word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx], al
	mov	bx, word ptr w_D2560
	add	word ptr [bx+0Ch], 2
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+3]
	and	ax, 0FFh
	je	L_0A9E
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	jne	L_0AA4
L_0A9E:
	call	sub_0272
	jmpnear	L_0AEB
L_0AA4:
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	mov	bx, word ptr w_D2560
	mov	cl, byte ptr [bx+6]
	mov	word ptr [bp-6], ax
	mov	ax, cx
	cbw
	mov	cx, word ptr [bp-6]
	sub	cx, ax
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+7], cl
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+18h]
	cbw
	push	ax
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+5]
	and	ax, 0FFh
	push	ax
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+3]
	and	ax, 0FFh
	push	ax
	call	sub_029A
	add	sp, 6
L_0AEB:
	mov	bx, word ptr w_D2560
	cmp	byte ptr [bx+1], 0
	je	L_0B04
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+1]
	cbw
	push	ax
	call	sub_018E
	add	sp, 2
L_0B04:
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+8]
	and	ax, 0FFh
	jne	L_0B13
	jmpnear	L_0B59
L_0B13:
	mov	bx, word ptr w_D2560
	dec	byte ptr [bx+8]
	mov	al, byte ptr [bx+8]
	and	ax, 0FFh
	jne	L_0B59
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+9]
	mov	bx, word ptr w_D2560
	mov	byte ptr [bx+8], al
	mov	bx, word ptr w_D2560
	cmp	byte ptr [bx+2], 0
	je	L_0B59
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+2]
	mov	bx, word ptr w_D2560
	add	byte ptr [bx+5], al
	mov	bx, word ptr w_D2560
	mov	al, byte ptr [bx+5]
	and	ax, 0FFh
	push	ax
	call	sub_0048
	add	sp, 2
L_0B59:
	inc	byte ptr b_D23FC
	pop	di
	pop	si
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; sub_0B64
; ----------------------------------------------------------------------------
sub_0B64:
	cmp	byte ptr b_D2320, 0
	jne	L_0B6E
	jmp	L_0BB2
L_0B6E:
	mov	byte ptr b_D23FC, 0
	mov	word ptr w_D2560, 2322h
	call	sub_073A
	mov	word ptr w_D2560, 233Ch
	call	sub_073A
	mov	word ptr w_D2560, 2356h
	call	sub_073A
	mov	word ptr w_D2560, 2370h
	call	sub_073A
	mov	word ptr w_D2560, 238Ah
	call	sub_073A
	mov	word ptr w_D2560, 23A4h
	call	sub_073A
	mov	word ptr w_D2560, 23BEh
	call	sub_073A
L_0BB2:
	ret
	db	0
old_int8	dw	0
w_0BB6	dw	0
timer_mode	db	0
chain_count	db	0
tick_div	db	0
timer_hooked	db	0
tick_count	dw	0
w_0BBE	dw	0
w_0BC0	dw	0
w_0BC2	dw	0
w_0BC4	dw	0

; ----------------------------------------------------------------------------
; hook_timer
; Save the int 8 vector and install the 60 Hz handler.
; ----------------------------------------------------------------------------
hook_timer:
	cmp	byte ptr cs:timer_hooked, 0
	jne	L_0BF5
	cli
	mov	byte ptr cs:timer_hooked, 0FFh
	push	ds
	xor	ax, ax
	mov	byte ptr cs:timer_mode, al
	mov	ds, ax
	mov	bx, word ptr ds:[20h]
	mov	cx, word ptr ds:[22h]
	pop	ds
	mov	word ptr cs:old_int8, bx
	mov	word ptr cs:w_0BB6, cx
	call	timer_slow
	sti
L_0BF5:
	ret

; ----------------------------------------------------------------------------
; unhook_timer
; ----------------------------------------------------------------------------
unhook_timer:
	cli
	push	ax
	push	bx
	push	cx
	push	ds
	mov	bx, word ptr cs:old_int8
	mov	cx, word ptr cs:w_0BB6
	xor	ax, ax
	mov	ds, ax
	mov	word ptr ds:[20h], bx
	mov	word ptr ds:[22h], cx
	pop	ds
	pop	cx
	pop	bx
	mov	al, 36h
	out	43h, al
	xor	ax, ax
	out	40h, al
	mov	al, ah
	out	40h, al
	mov	byte ptr cs:timer_mode, al
	mov	byte ptr cs:timer_hooked, 0
	pop	ax
	sti
	ret

; ----------------------------------------------------------------------------
; pit_elapsed
; BX = PIT channel 0 ticks taken by a 256-iteration loop.
; ----------------------------------------------------------------------------
pit_elapsed:
	push	cx
	cli
	mov	al, 0
	out	43h, al
	in	al, 40h
	mov	bl, al
	in	al, 40h
	mov	bh, al
	mov	cx, 100h
L_0C3E:
	loop	L_0C3E
	mov	al, 0
	out	43h, al
	in	al, 40h
	mov	dl, al
	in	al, 40h
	mov	dh, al
	sti
	sub	bx, dx
	pop	cx
	ret

; ----------------------------------------------------------------------------
; calibrate_delays
; Set the OPL address/data write delays from the CPU speed.
; ----------------------------------------------------------------------------
calibrate_delays:
	mov	word ptr w_D2272, 0
	mov	cx, 10h
L_0C5A:
	call	pit_elapsed
	add	word ptr w_D2272, bx
	loop	L_0C5A
	mov	bx, word ptr w_D2272
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	cmp	bx, 0A28h
	jle	L_0C78
	mov	bx, 0A28h
L_0C78:
	mov	dx, 0
	mov	ax, 5140h
	div	bx
	inc	ax
	mov	ah, 0
	mov	word ptr w_D2274, ax
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1
	inc	ax
	mov	ah, 0
	mov	word ptr w_D2276, ax
	ret

; ----------------------------------------------------------------------------
; detect_adlib
; Reset the OPL timers and check that timer 1 fires (the usual AdLib test).
; ----------------------------------------------------------------------------
detect_adlib:
	call	calibrate_delays
	mov	al, 4
	mov	bl, 60h
	call	opl_write
	mov	bl, 80h
	call	opl_write
	mov	dx, 388h
	in	al, dx
	push	ax
	mov	al, 2
	mov	bl, 0FFh
	call	opl_write
	mov	al, 4
	mov	bl, 21h
	call	opl_write
	mov	cx, 0C8h
	mov	dx, 388h
L_0CBB:
	in	al, dx
	loop	L_0CBB
	push	ax
	mov	al, 4
	mov	bl, 60h
	call	opl_write
	mov	bl, 80h
	call	opl_write
	pop	ax
	pop	bx
	mov	dx, 0
	and	al, 0E0h
	cmp	al, 0C0h
	jne	L_0CDE
	and	bl, 0E0h
	cmp	bl, 0
	je	L_0CE4
L_0CDE:
	mov	ax, 41h
	jmp	L_0CE7
L_0CE4:
	mov	ax, 0
L_0CE7:
	push	ax
	call	sub_0CED
	pop	ax
	ret

; ----------------------------------------------------------------------------
; sub_0CED
; ----------------------------------------------------------------------------
sub_0CED:
	xor	ax, ax
	mov	word ptr w_D227E, ax
	mov	word ptr w_D227C, ax
	mov	word ptr w_D2280, ax
	mov	byte ptr b_D2320, al
	lea	bx, w_D2322
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D233C
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D2356
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D2370
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D238A
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D23A4
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D23BE
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	lea	bx, w_D23D8
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr b_D23F2, al
	mov	byte ptr b_D23F3, al
	mov	word ptr w_D23F4, ax
	mov	word ptr w_D23F6, ax
	mov	word ptr w_D2316, ax
	mov	word ptr w_D2318, ax
	mov	word ptr w_D231A, ax
	mov	word ptr w_D231C, ax
	mov	byte ptr b_D2320, 0FFh
	mov	bx, 0
	mov	ax, 0FFh
L_0D7E:
	push	ax
	call	opl_write
	pop	ax
	dec	ax
	jne	L_0D7E
	mov	al, 1
	mov	bl, 20h
	call	opl_write
	ret

; ----------------------------------------------------------------------------
; L_0D8E
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0D8E:
	mov	al, 80h
	mov	bl, 0Eh
L_0D92:
	push	ax
	call	opl_write
	pop	ax
	inc	ax
	cmp	al, 96h
	jne	L_0D92
	xor	ax, ax
	mov	byte ptr b_D2320, al
	mov	byte ptr b_D23F2, al
	mov	byte ptr b_D23F3, al
	mov	word ptr w_D23F4, ax
	mov	word ptr w_D23F6, ax
	mov	word ptr w_D2316, ax
	mov	word ptr w_D2318, ax
	mov	word ptr w_D231A, ax
	mov	word ptr w_D231C, ax
	lea	cx, fx_1_data
	lea	bx, w_D2322
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D233C
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D2356
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D2370
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D238A
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D23A4
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D23BE
	mov	byte ptr [bx], 1
	mov	word ptr [bx+0Ch], cx
	mov	byte ptr b_D2320, 0FFh
L_0E08:
	mov	al, byte ptr w_D2322
	or	al, byte ptr w_D233C
	or	al, byte ptr w_D2356
	or	al, byte ptr w_D2370
	or	al, byte ptr w_D238A
	or	al, byte ptr w_D23A4
	or	al, byte ptr w_D23BE
	cmp	al, 0
	jne	L_0E08
	ret

; ----------------------------------------------------------------------------
; sub_0E28
; ----------------------------------------------------------------------------
sub_0E28:
	mov	ah, 0
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	or	bl, 3Fh
	jmp	opl_write

; ----------------------------------------------------------------------------
; sub_0E36
; ----------------------------------------------------------------------------
sub_0E36:
	xor	bh, 3Fh
	mov	ah, 0
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	and	bl, 0C0h
	or	bl, bh
	jmp	opl_write

; ----------------------------------------------------------------------------
; opl_write_c
; opl_write(reg, value) for the C code.
; ----------------------------------------------------------------------------
opl_write_c:
	push	bp
	mov	bp, sp
	mov	ax, word ptr [bp+4]
	mov	bl, byte ptr [bp+6]
	pop	bp

; ----------------------------------------------------------------------------
; opl_write
; AL = register, BL = value.
; ----------------------------------------------------------------------------
opl_write:
	push	di
	mov	ah, 0
	mov	di, ax
	mov	byte ptr [di+opl_shadow], bl
	pop	di
	mov	dx, 388h
	mov	cx, word ptr w_D2274
L_0E64:
	loop	L_0E64
	out	dx, al
	mov	al, bl
	mov	dx, 389h
	mov	cx, word ptr w_D2276
L_0E70:
	loop	L_0E70
	out	dx, al
	ret

; ----------------------------------------------------------------------------
; opl_write_freq
; ----------------------------------------------------------------------------
opl_write_freq:
	push	ax
	add	al, 0A0h
	call	opl_write
	pop	ax
	add	al, 0B0h
	mov	bl, bh
	or	bl, 20h
	call	opl_write
L_0E85:
	ret

; ----------------------------------------------------------------------------
; sound_tick
; Sequencer step, called from the timer handlers.
; ----------------------------------------------------------------------------
sound_tick:
	cmp	byte ptr b_D2320, 0
	je	L_0E85
	push	es
	push	si
	push	di
	push	bp
	mov	word ptr cs:w_0BBE, ss
	mov	word ptr cs:w_0BC0, sp
	mov	ax, DATA
	mov	es, ax
	mov	ss, ax
	mov	sp, 226Ah
	inc	word ptr cs:tick_count
	cmp	byte ptr b_D2282, 0
	je	L_0EB4
	call	sub_1991
L_0EB4:
	cmp	word ptr w_D228A, 0
	je	L_0EBE
	call	sub_140A
L_0EBE:
	call	sub_0B64
	mov	bx, word ptr cs:w_0BBE
	mov	ss, bx
	mov	sp, word ptr cs:w_0BC0
	pop	bp
	pop	di
	pop	si
	pop	es
	mov	al, byte ptr b_D23F3
	or	al, byte ptr b_D23F2
	je	timer_slow
	cmp	byte ptr b_D23F2, 0
	je	L_0F11
	mov	ax, word ptr w_D2316
	add	ax, word ptr w_D231A
	mov	word ptr w_D2316, ax
	dec	byte ptr b_D23F2
	jne	L_0F11
	cmp	byte ptr b_D23F3, 0
	je	L_0F01
	mov	al, byte ptr b_D23FD
	cmp	al, byte ptr b_D23FE
	je	L_0F11
L_0F01:
	push	ax
	add	al, 0A0h
	mov	bl, 0
	call	opl_write
	pop	ax
	add	al, 0B0h
	mov	bl, 0
	call	opl_write
L_0F11:
	cmp	byte ptr b_D23F3, 0
	je	fx_25
	mov	ax, word ptr w_D2318
	add	ax, word ptr w_D231C
	mov	word ptr w_D2318, ax
	dec	byte ptr b_D23F3
	jne	fx_25
	cmp	byte ptr b_D23F2, 0
	jne	L_0F38
	mov	al, byte ptr b_D23FE
	cmp	al, byte ptr b_D23FD
	je	fx_25
L_0F38:
	push	ax
	add	al, 0A0h
	mov	bl, 0
	call	opl_write
	pop	ax
	add	al, 0B0h
	mov	bl, 0
	call	opl_write

; ----------------------------------------------------------------------------
; fx_25
; ----------------------------------------------------------------------------
fx_25:
	ret

; ----------------------------------------------------------------------------
; timer_slow
; ----------------------------------------------------------------------------
timer_slow:
	cmp	byte ptr cs:timer_mode, 1
	je	L_0F7F
	cli
	mov	byte ptr cs:timer_mode, 1
	mov	byte ptr cs:tick_div, 3
	push	ax
	push	ds
	sub	ax, ax
	mov	ds, ax
	lea	ax, slow_timer_isr
	mov	word ptr ds:[20h], ax
	mov	word ptr ds:[22h], cs
	pop	ds
	mov	al, 36h
	out	43h, al
	mov	ax, 4C90h
	out	40h, al
	mov	al, ah
	out	40h, al
	pop	ax
	sti
L_0F7F:
	ret
; Int 8 handler at about 300 Hz: noise on two voices; the sequencer every
; 5th tick and the BIOS handler every 16th.
fast_timer_isr:
	sti
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	bx, 9248h
	add	bx, word ptr w_D2026
	ror	bx, 1
	ror	bx, 1
	ror	bx, 1
	mov	word ptr w_D2026, bx
	cmp	byte ptr b_D23F2, 0
	je	L_0FB4
	xor	bx, 0FFFFh
	and	bx, word ptr w_D23F4
	add	bx, word ptr w_D2316
	mov	al, byte ptr b_D23FD
	call	opl_write_freq
L_0FB4:
	cmp	byte ptr b_D23F3, 0
	je	L_0FCD
	mov	bx, word ptr w_D2026
	and	bx, word ptr w_D23F6
	add	bx, word ptr w_D2318
	mov	al, byte ptr b_D23FE
	call	opl_write_freq
L_0FCD:
	dec	byte ptr cs:tick_div
	jne	L_0FDD
	mov	byte ptr cs:tick_div, 5
	call	sound_tick
L_0FDD:
	dec	byte ptr cs:chain_count
	je	L_0FEF
	cli
	mov	al, 20h
	out	20h, al
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
L_0FEF:
	mov	byte ptr cs:chain_count, 10h
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	jmp	dword ptr cs:old_int8

; ----------------------------------------------------------------------------
; timer_fast
; ----------------------------------------------------------------------------
timer_fast:
	cmp	byte ptr cs:timer_mode, 0FFh
	je	L_1035
	cli
	mov	byte ptr cs:timer_mode, 0FFh
	mov	byte ptr cs:chain_count, 10h
	push	ax
	push	ds
	sub	ax, ax
	mov	ds, ax
	lea	ax, fast_timer_isr
	mov	word ptr ds:[20h], ax
	mov	word ptr ds:[22h], cs
	pop	ds
	mov	al, 36h
	out	43h, al
	mov	ax, 0F88h
	out	40h, al
	mov	al, ah
	out	40h, al
	pop	ax
	sti
L_1035:
	ret
; Int 8 handler at about 60 Hz: the sequencer; the BIOS handler every 3rd tick.
slow_timer_isr:
	sti
	push	ax
	push	bx
	push	cx
	push	dx
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	sound_tick
	dec	byte ptr cs:tick_div
	je	L_1056
	cli
	mov	al, 20h
	out	20h, al
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
L_1056:
	mov	byte ptr cs:tick_div, 3
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	jmp	dword ptr cs:old_int8

; ----------------------------------------------------------------------------
; start_voice
; BX = voice block, CX = note data: start a voice.
; ----------------------------------------------------------------------------
start_voice:
	mov	dl, byte ptr b_D2320
	push	dx
	mov	byte ptr b_D2320, 0
	mov	byte ptr [bx+1], 0
	mov	byte ptr [bx+9], 0FFh
	mov	byte ptr [bx+2], 0
	mov	byte ptr [bx+18h], 0
	mov	word ptr [bx+0Ah], cx
	mov	word ptr [bx+0Ch], cx
	mov	word ptr [bx+0Eh], cx
	mov	word ptr [bx+10h], cx
	mov	word ptr [bx+12h], 0
	mov	word ptr [bx+14h], 0
	mov	byte ptr [bx+6], 0
	mov	word ptr [bx+16h], ax
	mov	byte ptr [bx], 1
	pop	dx
	mov	byte ptr b_D2320, dl
	ret

; ----------------------------------------------------------------------------
; fx_1
; ----------------------------------------------------------------------------
fx_1:
	lea	cx, fx_1_data
	lea	bx, w_D2322
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D233C
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D2356
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D2370
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D238A
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D23A4
	mov	word ptr [bx+0Ch], cx
	lea	bx, w_D23BE
	mov	word ptr [bx+0Ch], cx
	ret

; ----------------------------------------------------------------------------
; fx_2
; ----------------------------------------------------------------------------
fx_2:
	mov	ax, 0
	lea	bx, w_D2322
	lea	cx, w_D079A
	call	start_voice
	lea	bx, w_D233C
	lea	cx, w_D0818
	call	start_voice
	lea	bx, w_D2356
	lea	cx, w_D08CE
	call	start_voice
	lea	bx, w_D2370
	lea	cx, w_D0A08
	call	start_voice
	lea	bx, w_D238A
	lea	cx, w_D0A96
	call	start_voice
	lea	bx, w_D23A4
	lea	cx, w_D0B36
	call	start_voice
	lea	bx, w_D23BE
	lea	cx, w_D0BD2
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_3
; ----------------------------------------------------------------------------
fx_3:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1EA2
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_4
; ----------------------------------------------------------------------------
fx_4:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1EB0
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_6
; ----------------------------------------------------------------------------
fx_6:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1EBE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_5
; ----------------------------------------------------------------------------
fx_5:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1ECC
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_7
; ----------------------------------------------------------------------------
fx_7:
	xor	ax, ax
	lea	bx, w_D23A4
	lea	cx, w_D1F1A
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_8
; ----------------------------------------------------------------------------
fx_8:
	xor	ax, ax
	lea	bx, w_D23BE
	lea	cx, w_D1F22
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_9
; ----------------------------------------------------------------------------
fx_9:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1ED4
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_10
; ----------------------------------------------------------------------------
fx_10:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D2016
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_13
; ----------------------------------------------------------------------------
fx_13:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1EDE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_14
; ----------------------------------------------------------------------------
fx_14:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1EE6
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_18
; ----------------------------------------------------------------------------
fx_18:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1EEE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_22
; ----------------------------------------------------------------------------
fx_22:
	ret

; ----------------------------------------------------------------------------
; fx_23
; ----------------------------------------------------------------------------
fx_23:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1F02
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_24
; ----------------------------------------------------------------------------
fx_24:
	ret

; ----------------------------------------------------------------------------
; fx_19
; ----------------------------------------------------------------------------
fx_19:
	xor	ax, ax
	lea	bx, w_D23A4
	lea	cx, w_D1F2A
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_20
; ----------------------------------------------------------------------------
fx_20:
	xor	ax, ax
	lea	bx, w_D23A4
	lea	cx, w_D1F32
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_11
; ----------------------------------------------------------------------------
fx_11:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1F50
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_12
; ----------------------------------------------------------------------------
fx_12:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1F58
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_15
; ----------------------------------------------------------------------------
fx_15:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1F64
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_16
; ----------------------------------------------------------------------------
fx_16:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1F6C
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_17
; ----------------------------------------------------------------------------
fx_17:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1F78
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_21
; ----------------------------------------------------------------------------
fx_21:
	xor	ax, ax
	lea	bx, w_D23A4
	lea	cx, w_D1F84
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_26
; ----------------------------------------------------------------------------
fx_26:
	mov	byte ptr b_D2285, 0FFh
	jmp	L_123F

; ----------------------------------------------------------------------------
; fx_27
; ----------------------------------------------------------------------------
fx_27:
	mov	byte ptr b_D2285, 0
L_123F:
	cmp	byte ptr b_D2286, 0
	jne	L_128C
L_1246:
	mov	ax, word ptr [bp+8]
	cmp	al, 0
	je	L_12B4
	cmp	byte ptr b_D2285, 0FFh
	jne	L_1270
	mov	byte ptr b_D2286, 1
	call	sub_135E
	mov	ax, word ptr [bp+8]
	mov	byte ptr b_D2288, al
	call	sub_1346
	call	sub_13E2
	mov	bx, word ptr [bp+8]
	mov	byte ptr b_D2287, bl
	ret
L_1270:
	mov	byte ptr b_D2286, 2
	call	sub_135E
	mov	ax, word ptr [bp+8]
	mov	byte ptr b_D2289, al
	call	sub_1346
	call	sub_13E2
	mov	bx, word ptr [bp+8]
	mov	byte ptr b_D2287, bl
	ret
L_128C:
	cmp	byte ptr b_D2286, 1
	jne	L_12E1
	cmp	byte ptr b_D2285, 0FFh
	jne	L_12B5
	mov	ax, word ptr [bp+8]
	mov	byte ptr b_D2288, al
	cmp	byte ptr b_D2287, 0
	je	L_1246
	call	sub_1346
	call	sub_13E2
	mov	bx, word ptr [bp+8]
	mov	byte ptr b_D2287, bl
L_12B4:
	ret
L_12B5:
	call	sub_14AB
	mov	byte ptr b_D2286, 2
	mov	al, byte ptr b_D2289
	mov	byte ptr b_D2287, al
	or	al, byte ptr [bp+8]
	je	L_1314
	call	sub_135E
	mov	ax, word ptr [bp+8]
	mov	byte ptr b_D2289, al
	call	sub_1346
	call	sub_13E2
	mov	bx, word ptr [bp+8]
	mov	byte ptr b_D2287, bl
	jmp	L_1479
L_12E1:
	cmp	byte ptr b_D2285, 0FFh
	jne	L_1317
	call	sub_14AB
	mov	byte ptr b_D2286, 1
	mov	al, byte ptr b_D2288
	mov	byte ptr b_D2287, al
	or	al, byte ptr [bp+8]
	je	L_1314
	call	sub_135E
	mov	ax, word ptr [bp+8]
	mov	byte ptr b_D2288, al
	call	sub_1346
	call	sub_13E2
	mov	bx, word ptr [bp+8]
	mov	byte ptr b_D2287, bl
	jmp	L_1479
L_1314:
	jmp	L_1246
L_1317:
	mov	ax, word ptr [bp+8]
	mov	byte ptr b_D2289, al
	cmp	byte ptr b_D2287, 0
	je	L_1314
	call	sub_1346
	call	sub_13E2
	mov	bx, word ptr [bp+8]
	mov	byte ptr b_D2287, bl
	ret

; ----------------------------------------------------------------------------
; sub_1332
; ----------------------------------------------------------------------------
sub_1332:
	mov	bh, 0
	mov	bl, byte ptr b_D2287
	shl	bx, 1
	mov	ax, word ptr [bx+w_D2295]
	mov	byte ptr b_D228C, ah
	mov	byte ptr b_D228D, al
	ret

; ----------------------------------------------------------------------------
; sub_1346
; ----------------------------------------------------------------------------
sub_1346:
	mov	bx, word ptr [bp+8]
	shl	bx, 1
	mov	ax, word ptr [bx+w_D2295]
	mov	word ptr w_D2290, ax
	ret

; ----------------------------------------------------------------------------
; sub_1353
; ----------------------------------------------------------------------------
sub_1353:
	mov	ax, 1A85h
	mov	byte ptr b_D228E, ah
	mov	byte ptr b_D228F, al
	ret

; ----------------------------------------------------------------------------
; sub_135E
; ----------------------------------------------------------------------------
sub_135E:
	mov	byte ptr b_D2320, 0
	mov	byte ptr b_D23FC, 8
	push	es
	push	si
	push	di
	push	bp
	mov	word ptr cs:w_0BC2, ss
	mov	word ptr cs:w_0BC4, sp
	mov	ax, DATA
	mov	es, ax
	mov	ss, ax
	mov	sp, 226Ah
	cmp	byte ptr b_D2292, 14h
	je	L_139A
	cmp	byte ptr b_D2286, 1
	jne	L_1394
	mov	bx, 12h
	jmp	L_13AC
L_1394:
	mov	bx, 0Bh
	jmp	L_13AC
L_139A:
	mov	bx, 19h
	push	bx
	call	sub_061C
	add	sp, 2
	mov	byte ptr b_D23FC, 7
	mov	bx, 29h
L_13AC:
	push	bx
	call	sub_061C
	add	sp, 2
	mov	bx, word ptr cs:w_0BC2
	mov	ss, bx
	mov	sp, word ptr cs:w_0BC4
	pop	bp
	pop	di
	pop	si
	pop	es
	call	sub_1332
	call	sub_14C7
	call	sub_147F
	cmp	byte ptr b_D2292, 14h
	jne	L_13DC
	call	sub_1353
	call	sub_14E0
	call	sub_1495
L_13DC:
	mov	byte ptr b_D2320, 0FFh
	ret

; ----------------------------------------------------------------------------
; sub_13E2
; ----------------------------------------------------------------------------
sub_13E2:
	mov	ah, byte ptr b_D228C
	mov	al, byte ptr b_D228D
	cmp	word ptr w_D2290, ax
	jg	L_1403
	jl	L_13FA
	mov	word ptr w_D228A, 0
	jmp	L_1409
L_13FA:
	mov	word ptr w_D228A, 0FFFCh
	jmp	L_1409
L_1403:
	mov	word ptr w_D228A, 4
L_1409:
	ret

; ----------------------------------------------------------------------------
; sub_140A
; ----------------------------------------------------------------------------
sub_140A:
	mov	byte ptr b_D2320, 0
	push	di
	mov	di, 0B8h
	mov	bh, byte ptr [di+opl_shadow]
	mov	di, 0A8h
	mov	bl, byte ptr [di+opl_shadow]
	add	bx, word ptr w_D228A
	and	bx, 1FFFh
	mov	byte ptr b_D228C, bh
	mov	byte ptr b_D228D, bl
	push	bx
	mov	al, 0A8h
	call	opl_write
	pop	bx
	mov	di, 0B8h
	mov	al, byte ptr [di+opl_shadow]
	and	al, 20h
	push	bx
	mov	bl, bh
	or	bl, al
	mov	al, 0B8h
	call	opl_write
	pop	bx
	pop	di
	cmp	bx, word ptr w_D2290
	je	L_1453
	jmp	L_1479
L_1453:
	mov	word ptr w_D228A, 0
	cmp	byte ptr b_D2287, 0
	jne	L_1479
	cmp	word ptr w_D2290, 1DA1h
	jg	L_1479
	push	di
	mov	ax, 0B8h
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	and	bl, 0DFh
	call	opl_write
	pop	di
L_1479:
	mov	byte ptr b_D2320, 0FFh
	ret

; ----------------------------------------------------------------------------
; sub_147F
; ----------------------------------------------------------------------------
sub_147F:
	mov	al, 0A8h
	mov	bl, byte ptr b_D228D
	call	opl_write
	mov	al, 0B8h
	mov	bl, byte ptr b_D228C
	or	bl, 20h
	call	opl_write
	ret

; ----------------------------------------------------------------------------
; sub_1495
; ----------------------------------------------------------------------------
sub_1495:
	mov	al, 0A7h
	mov	bl, byte ptr b_D228F
	call	opl_write
	mov	al, 0B7h
	mov	bl, byte ptr b_D228E
	or	bl, 20h
	call	opl_write
	ret

; ----------------------------------------------------------------------------
; sub_14AB
; ----------------------------------------------------------------------------
sub_14AB:
	mov	byte ptr b_D2320, 0
	push	di
	mov	ax, 0B8h
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	and	bl, 0DFh
	call	opl_write
	pop	di
	mov	byte ptr b_D2320, 0FFh
	ret

; ----------------------------------------------------------------------------
; sub_14C7
; ----------------------------------------------------------------------------
sub_14C7:
	push	di
	mov	ax, 55h
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	and	bl, 0C0h
	or	bl, 1
	add	bl, byte ptr b_D2292
	call	opl_write
	pop	di
	ret

; ----------------------------------------------------------------------------
; sub_14E0
; ----------------------------------------------------------------------------
sub_14E0:
	push	di
	mov	ax, 54h
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	and	bl, 0C0h
	or	bl, 17h
	call	opl_write
	pop	di
	ret

; ----------------------------------------------------------------------------
; fx_28
; ----------------------------------------------------------------------------
fx_28:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1F8C
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_29
; ----------------------------------------------------------------------------
fx_29:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1F3C
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_30
; ----------------------------------------------------------------------------
fx_30:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1F96
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_31
; ----------------------------------------------------------------------------
fx_31:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1FA2
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_32
; ----------------------------------------------------------------------------
fx_32:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D200E
	call	start_voice
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D200E
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_33
; ----------------------------------------------------------------------------
fx_33:
	xor	ax, ax
	lea	bx, w_D2370
	lea	cx, w_D1FAE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_34
; ----------------------------------------------------------------------------
fx_34:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1FB6
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_45
; ----------------------------------------------------------------------------
fx_45:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1FBE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_46
; ----------------------------------------------------------------------------
fx_46:
	xor	ax, ax
	lea	bx, w_D238A
	lea	cx, w_D1FEA
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_35
; ----------------------------------------------------------------------------
fx_35:
	mov	byte ptr b_D2292, 14h
	mov	byte ptr b_D2287, 5
	mov	word ptr w_D2290, 1FF0h
	call	sub_135E
	call	sub_13E2
	ret

; ----------------------------------------------------------------------------
; fx_36
; ----------------------------------------------------------------------------
fx_36:
	mov	word ptr w_D2290, 1DA0h
	call	sub_13E2
	mov	byte ptr b_D2320, 0
	push	di
	mov	ax, 0B7h
	mov	di, ax
	mov	bl, byte ptr [di+opl_shadow]
	and	bl, 0DFh
	call	opl_write
	pop	di
	mov	byte ptr b_D2320, 0FFh
	mov	byte ptr b_D2287, 0
	mov	byte ptr b_D2286, 0
	mov	byte ptr b_D2292, 0
	ret

; ----------------------------------------------------------------------------
; fx_37
; ----------------------------------------------------------------------------
fx_37:
	mov	ax, 0
	mov	bl, byte ptr b_D23F2
	mov	byte ptr b_D2293, bl
	mov	byte ptr b_D23F2, al
	mov	bl, byte ptr b_D23F3
	mov	byte ptr b_D2294, bl
	mov	byte ptr b_D23F3, al
	mov	byte ptr b_D2320, 0
	push	di
	mov	al, 43h
	call	sub_0E28
	mov	al, 44h
	call	sub_0E28
	mov	al, 45h
	call	sub_0E28
	mov	al, 4Bh
	call	sub_0E28
	mov	al, 4Ch
	call	sub_0E28
	mov	al, 4Dh
	call	sub_0E28
	mov	al, 53h
	call	sub_0E28
	mov	al, 54h
	call	sub_0E28
	mov	al, 55h
	call	sub_0E28
	pop	di
	ret

; ----------------------------------------------------------------------------
; fx_38
; ----------------------------------------------------------------------------
fx_38:
	push	di
	mov	al, 43h
	lea	di, w_D2322
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 44h
	lea	di, w_D233C
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 45h
	lea	di, w_D2356
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 4Bh
	lea	di, w_D2370
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 4Ch
	lea	di, w_D238A
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 4Dh
	lea	di, w_D23A4
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 53h
	lea	di, w_D23BE
	mov	bh, byte ptr [di+5]
	call	sub_0E36
	mov	al, 54h
	mov	bh, 28h
	call	sub_0E36
	mov	al, 55h
	mov	bh, 3Eh
	call	sub_0E36
	mov	ah, byte ptr b_D2293
	mov	byte ptr b_D23F2, ah
	mov	al, byte ptr b_D2294
	mov	byte ptr b_D23F3, al
	or	al, ah
	je	L_1688
	call	timer_fast
L_1688:
	mov	byte ptr b_D2320, 0FFh
	pop	di
	ret

; ----------------------------------------------------------------------------
; fx_40
; ----------------------------------------------------------------------------
fx_40:
	mov	ax, 0
	lea	bx, w_D2322
	lea	cx, w_D1E28
	call	start_voice
	lea	bx, w_D233C
	lea	cx, w_D1E4C
	call	start_voice
	lea	bx, w_D2356
	lea	cx, w_D1E70
	call	start_voice
	lea	bx, w_D2370
	lea	cx, w_D1E8A
	call	start_voice
	lea	bx, w_D238A
	lea	cx, w_D0794
	call	start_voice
	lea	bx, w_D23A4
	lea	cx, w_D0796
	call	start_voice
	lea	bx, w_D23BE
	lea	cx, w_D0798
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_39
; ----------------------------------------------------------------------------
fx_39:
	mov	ax, 0
	lea	bx, w_D2322
	lea	cx, w_D1A7E
	call	start_voice
	lea	bx, w_D233C
	lea	cx, w_D1AF0
	call	start_voice
	lea	bx, w_D2356
	lea	cx, w_D1B62
	call	start_voice
	lea	bx, w_D2370
	lea	cx, w_D1C22
	call	start_voice
	lea	bx, w_D238A
	lea	cx, w_D1C9C
	call	start_voice
	lea	bx, w_D23A4
	lea	cx, w_D1D20
	call	start_voice
	lea	bx, w_D23BE
	lea	cx, w_D1DA4
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_44
; ----------------------------------------------------------------------------
fx_44:
	mov	ax, word ptr [bp+8]
	mov	word ptr w_D227E, ax
	mov	ax, word ptr [bp+0Ah]
	mov	word ptr w_D2280, ax
	mov	byte ptr b_D2282, 0FFh
	ret

; ----------------------------------------------------------------------------
; fx_41
; ----------------------------------------------------------------------------
fx_41:
	mov	ax, 0
	lea	bx, w_D2322
	lea	cx, w_D0C2A
	call	start_voice
	lea	bx, w_D233C
	lea	cx, w_D0CFE
	call	start_voice
	lea	bx, w_D2356
	lea	cx, w_D0D4C
	call	start_voice
	lea	bx, w_D2370
	lea	cx, w_D0D8C
	call	start_voice
	lea	bx, w_D238A
	lea	cx, w_D0DB8
	call	start_voice
	lea	bx, w_D23A4
	lea	cx, w_D0E4E
	call	start_voice
	lea	bx, w_D23BE
	lea	cx, w_D0790
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_42
; ----------------------------------------------------------------------------
fx_42:
	mov	ax, 0
	lea	bx, w_D2322
	lea	cx, w_D1392
	call	start_voice
	lea	bx, w_D233C
	lea	cx, w_D13F8
	call	start_voice
	lea	bx, w_D2356
	lea	cx, w_D1454
	call	start_voice
	lea	bx, w_D2370
	lea	cx, w_D14A4
	call	start_voice
	lea	bx, w_D238A
	lea	cx, w_D14DE
	call	start_voice
	lea	bx, w_D23A4
	lea	cx, w_D150C
	call	start_voice
	lea	bx, w_D23BE
	lea	cx, w_D0792
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_43
; ----------------------------------------------------------------------------
fx_43:
	mov	ax, 0
	lea	bx, w_D2322
	lea	cx, w_D153A
	call	start_voice
	lea	bx, w_D233C
	lea	cx, w_D1582
	call	start_voice
	lea	bx, w_D2356
	lea	cx, w_D1634
	call	start_voice
	lea	bx, w_D2370
	lea	cx, w_D1734
	call	start_voice
	lea	bx, w_D238A
	lea	cx, w_D17B0
	call	start_voice
	lea	bx, w_D23A4
	lea	cx, w_D18EC
	call	start_voice
	lea	bx, w_D23BE
	lea	cx, w_D19CE
	jmp	start_voice
	db	0C3h

; ----------------------------------------------------------------------------
; fx_0
; ----------------------------------------------------------------------------
fx_0:
	mov	byte ptr b_D2286, 0
	mov	byte ptr b_D2287, 0
	mov	byte ptr b_D2288, 0
	mov	byte ptr b_D2289, 0
	jmp	sub_0CED
; Effect handlers for play_sound(n), n = 0..46
fx_table	dw	offset fx_0
	dw	offset fx_1
	dw	offset fx_2
	dw	offset fx_3
	dw	offset fx_4
	dw	offset fx_5
	dw	offset fx_6
	dw	offset fx_7
	dw	offset fx_8
	dw	offset fx_9
	dw	offset fx_10
	dw	offset fx_11
	dw	offset fx_12
	dw	offset fx_13
	dw	offset fx_14
	dw	offset fx_15
	dw	offset fx_16
	dw	offset fx_17
	dw	offset fx_18
	dw	offset fx_19
	dw	offset fx_20
	dw	offset fx_21
	dw	offset fx_22
	dw	offset fx_23
	dw	offset fx_24
	dw	offset fx_25
	dw	offset fx_26
	dw	offset fx_27
	dw	offset fx_28
	dw	offset fx_29
	dw	offset fx_30
	dw	offset fx_31
	dw	offset fx_32
	dw	offset fx_33
	dw	offset fx_34
	dw	offset fx_35
	dw	offset fx_36
	dw	offset fx_37
	dw	offset fx_38
	dw	offset fx_39
	dw	offset fx_40
	dw	offset fx_41
	dw	offset fx_42
	dw	offset fx_43
	dw	offset fx_44
	dw	offset fx_45
	dw	offset fx_46

; ----------------------------------------------------------------------------
; asnd_init (slot 100)
; init(port?): store the argument, hook the timer and detect/reset the card.
; ----------------------------------------------------------------------------
asnd_init:
	push	bp
	mov	bp, sp
	mov	bx, word ptr [bp+6]
	push	si
	push	di
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	word ptr w_D2270, bx
	call	hook_timer
	call	detect_adlib
	pop	ds
	pop	di
	pop	si
	pop	bp
	retf

; ----------------------------------------------------------------------------
; asnd_play_sound (slot 101)
; play_sound(n): start effect n.
; ----------------------------------------------------------------------------
asnd_play_sound:
	push	bp
	mov	bp, sp
	mov	bx, word ptr [bp+6]
	cmp	bx, 2Eh
	jg	L_18DD
	push	ds
	mov	ax, DATA
	mov	ds, ax
	shl	bx, 1
	call	word ptr cs:[bx+fx_table]
	pop	ds
L_18DD:
	pop	bp
	retf

; ----------------------------------------------------------------------------
; asnd_shutdown (slot 102)
; shutdown(): stop all sounds and restore the timer; returns w_D226C.
; ----------------------------------------------------------------------------
asnd_shutdown:
	push	di
	push	bp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	fx_0
	call	unhook_timer
	mov	ax, word ptr w_D226C
	mov	word ptr w_D226C, 0
	pop	ds
	pop	bp
	pop	di
	retf

; ----------------------------------------------------------------------------
; asnd_nop103 (slot 103)
; ----------------------------------------------------------------------------
asnd_nop103:
	retf

; ----------------------------------------------------------------------------
; asnd_nop104 (slot 104)
; ----------------------------------------------------------------------------
asnd_nop104:
	retf

; ----------------------------------------------------------------------------
; asnd_get_ticks (slot 105)
; Slot 105: number of sequencer ticks so far.
; ----------------------------------------------------------------------------
asnd_get_ticks:
	mov	ax, word ptr cs:tick_count
	retf

; ----------------------------------------------------------------------------
; asnd_nop106 (slot 106)
; ----------------------------------------------------------------------------
asnd_nop106:
	retf

; ----------------------------------------------------------------------------
; asnd_nop107 (slot 107)
; ----------------------------------------------------------------------------
asnd_nop107:
	retf

; ----------------------------------------------------------------------------
; asnd_nop108 (slot 108)
; ----------------------------------------------------------------------------
asnd_nop108:
	retf

; ----------------------------------------------------------------------------
; asnd_nop109 (slot 109)
; ----------------------------------------------------------------------------
asnd_nop109:
	retf

; ----------------------------------------------------------------------------
; asnd_nop110 (slot 110)
; ----------------------------------------------------------------------------
asnd_nop110:
	retf

; ----------------------------------------------------------------------------
; random
; ----------------------------------------------------------------------------
random:
	mov	ax, word ptr w_D2283
	adc	ax, 7131h
	adc	ax, word ptr cs:tick_count
	mov	word ptr w_D2283, ax
	ret

; ----------------------------------------------------------------------------
; sub_1915
; ----------------------------------------------------------------------------
sub_1915:
	cmp	word ptr w_D2322, 0
	je	L_1936
	cmp	word ptr w_D2322, 1
	jne	L_1935
	mov	ax, word ptr w_D2283
	and	ax, 6
	lea	bx, w_D2305
	add	bx, ax
	mov	bx, word ptr [bx]
	mov	word ptr w_D232C, bx
L_1935:
	ret
L_1936:
	mov	ax, 70h
	mov	word ptr w_D227A, ax
	inc	ax
	inc	ax
	mov	word ptr w_D2278, ax
	call	sub_1982
	xor	ax, ax
	lea	bx, w_D2322
	lea	cx, w_D1332
	jmp	start_voice
L_1951:
	mov	byte ptr b_D2282, 0
	lea	bx, fx_1_data
	mov	word ptr w_D232E, bx
	mov	word ptr w_D2348, bx
	mov	word ptr w_D2362, bx
	mov	word ptr w_D227C, 0
	ret

; ----------------------------------------------------------------------------
; sub_196D
; ----------------------------------------------------------------------------
sub_196D:
	lea	bx, fx_1_data
	mov	word ptr w_D232E, bx
	ret

; ----------------------------------------------------------------------------
; sub_1976
; ----------------------------------------------------------------------------
sub_1976:
	lea	bx, fx_1_data
	mov	word ptr w_D2348, bx
	mov	word ptr w_D2362, bx

; ----------------------------------------------------------------------------
; sub_1982
; ----------------------------------------------------------------------------
sub_1982:
	mov	al, 21h

; ----------------------------------------------------------------------------
; sub_1984
; ----------------------------------------------------------------------------
sub_1984:
	mov	byte ptr b_D1335, al
	mov	byte ptr b_D134D, al
	mov	byte ptr b_D1365, al
	mov	byte ptr b_D137D, al
	ret

; ----------------------------------------------------------------------------
; sub_1991
; ----------------------------------------------------------------------------
sub_1991:
	cmp	word ptr w_D227E, 0
	je	L_1951
	cmp	word ptr w_D2280, 0
	je	L_1951
	call	random
	cmp	word ptr w_D227E, 4
	jb	L_19AF
	call	sub_19D4
	jmp	L_19B2
L_19AF:
	call	sub_19B9
L_19B2:
	mov	ax, word ptr w_D227E
	mov	word ptr w_D227C, ax
	ret

; ----------------------------------------------------------------------------
; sub_19B9
; ----------------------------------------------------------------------------
sub_19B9:
	cmp	word ptr w_D227C, 4
	jb	L_19CD
	call	sub_196D
	cmp	word ptr w_D227C, 4
	jb	L_19CD
	call	sub_1976
L_19CD:
	call	sub_1A48
	call	sub_1A91
	ret

; ----------------------------------------------------------------------------
; sub_19D4
; ----------------------------------------------------------------------------
sub_19D4:
	call	sub_1915
	cmp	word ptr w_D2278, 0
	jne	L_19E6
	mov	bx, word ptr w_D227A
	mov	word ptr w_D2278, bx
L_19E6:
	dec	word ptr w_D2278
	cmp	word ptr w_D227E, 5
	je	L_1A09
	cmp	word ptr w_D227C, 4
	je	L_1A02
	cmp	word ptr w_D227C, 5
	jne	L_1A02
	call	sub_1976
L_1A02:
	call	sub_1A48
	call	sub_1A91
	ret
L_1A09:
	cmp	word ptr w_D227C, 5
	je	L_1A3D
	mov	al, 2Fh
	call	sub_1984
	lea	ax, w_D12C6
	lea	bx, w_D233C
	lea	cx, w_D0F18
	call	start_voice
	xor	ax, ax
	lea	bx, w_D2356
	lea	cx, w_D0F18
	call	start_voice
	mov	ax, word ptr w_D2278
	dec	ax
	jns	L_1A3A
	mov	ax, word ptr w_D227A
L_1A3A:
	call	sub_1AB7
L_1A3D:
	cmp	byte ptr w_D2356, 1
	jne	L_1A90
	call	sub_1A5C
	ret

; ----------------------------------------------------------------------------
; sub_1A48
; ----------------------------------------------------------------------------
sub_1A48:
	cmp	byte ptr w_D2356, 0
	jne	L_1A90
	xor	ax, ax
	lea	bx, w_D2356
	lea	cx, w_D0F18
	call	start_voice

; ----------------------------------------------------------------------------
; sub_1A5C
; ----------------------------------------------------------------------------
sub_1A5C:
	mov	bx, word ptr w_D227E
	dec	bx
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	call	random
	cmp	word ptr w_D227E, 1
	jne	L_1A7F
	and	ax, 1Eh
	add	ax, bx
	lea	bx, w_D22A5
	jmp	L_1A88
L_1A7F:
	and	ax, 0Eh
	add	ax, bx
	lea	bx, w_D22B5
L_1A88:
	add	bx, ax
	mov	bx, word ptr [bx]
	mov	word ptr w_D2360, bx
L_1A90:
	ret

; ----------------------------------------------------------------------------
; sub_1A91
; ----------------------------------------------------------------------------
sub_1A91:
	mov	ax, word ptr w_D2283
	and	ax, 0FFh
	inc	ax
	xor	dx, dx
	mov	bx, word ptr w_D227E
	div	bx
	or	ax, 1
	mov	bx, ax
	mov	ax, word ptr w_D2280
	mov	dx, 14h
	mul	dx
	add	ax, bx
	cmp	ax, 0FFh
	jle	sub_1AB7
	mov	ax, 0FFh

; ----------------------------------------------------------------------------
; sub_1AB7
; ----------------------------------------------------------------------------
sub_1AB7:
	mov	byte ptr b_D0F19, al
	ret
CODE	ENDS

BSS	SEGMENT BYTE PUBLIC 'BSS'
	db	611 dup (?)
BSS	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

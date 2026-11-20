; RSOUND.CA - Covert Action sound driver for the Roland MT-32 ("RolandMT-32g")
;
; Loaded by COVERT as an overlay; exports slots 100-110 (see README "Driver
; interface"). play_sound(n) starts effect n (0-54) from fx_table. The MT-32
; is driven through an MPU-401 in UART mode (mpu_port, normally 330h); the
; init sends SysEx set-up data (send_sysex). The music player from 0E02h on
; is C compiler output. The sequencer (sound_tick) runs from the timer
; interrupt at about 60 Hz on its own stack in DATA, chaining to the BIOS
; handler every third tick; IRQ 2 (int 0Ah) is hooked to drain MPU input.
;
; Names of the music player's, engine's and gunfire routines follow the C# port
; in Covert Action Enhanced
; (github.com/Arkana-Mechanika-Studios/covert-action-enhanced), matched by
; address; the gunfire routines take its RSOUND names in all three drivers.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh RSOUND
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/RSOUND.hints)

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
; get group offsets (CS:1780h = DATA:0) while DS references, with DS = DATA,
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
fx_1_data	dw	0F8h,0F600h,0FA64h,0,0F700h,40h,0
w_D005E	dw	7000h,7000h,7000h,3FCh,78F9h,1C29h,1C28h,1C27h
	dw	1C26h,7000h,7000h,72Dh,72Dh,72Bh,0E2Dh,728h
	dw	72Bh,72Eh,734h,3100h,7000h,0FFh,2FCh,64F9h
	dw	1539h,1539h,0E37h,1540h,2343h,1FCh,64F9h,1545h
	dw	1547h,0E48h,0E4Ch,748h,745h,74Fh,74Ch,756h
	dw	753h,2FCh,64F9h,1539h,1539h,0E37h,1540h,2345h
	dw	1FCh,64F9h,1545h,1547h,0E48h,0E4Ch,748h,743h
	dw	745h,74Ch,751h,754h,1FFh,74Ch,6951h,0FFh
	dw	7000h,2FFh,2FCh,64F9h,0E39h,6200h,3FEh,0
w_D00EE	db	0FCh,2,0F9h,64h,39h,70h,37h,70h,35h,70h,35h,1Ch,34h,1Ch,33h,1Ch
	db	32h,0Eh,32h,7,33h,7,0,70h,2Dh,0Eh,3Ch,7,2Fh,0Eh,3Bh,0Eh
	db	30h,0Eh,39h,7,2Dh,7,2Bh,7,2Dh,0Eh,29h,7,2Bh,7,0,62h
	db	27h,7,32h,7,2Dh,0Eh,3Ch,7,2Fh,0Eh,3Bh,0Eh,30h,0Eh,39h,7
	db	2Dh,7,2Bh,7,2Dh,0Eh,29h,7,2Bh,7,0FFh,0,0FCh,2,0F9h,64h
	db	34h,15h,32h,15h,34h,0Eh,37h,15h,3Eh,23h,0FCh,1,0F9h,64h,39h,15h
	db	3Bh,15h,3Ch,0Eh,40h,0Eh,0,2Ah,0FCh,2,0F9h,64h,34h,15h,32h,15h
	db	34h,0Eh,37h,15h,3Eh,93h,0FFh,1,2Dh,7,2Dh,7,2Bh,7,2Dh,0Eh
	db	28h,7,2Bh,7,2Eh,7,34h,7,0,23h,27h,7,32h,7,2Dh,0Eh
	db	3Ch,7,2Fh,0Eh,3Bh,0Eh,30h,0Eh,39h,7,2Dh,7,2Bh,7,2Dh,0Eh
	db	29h,7,2Bh,7,0FFh,1,34h,0Eh,0,62h,0FEh,3,0,0
w_D019C	dw	3FCh,78F9h,1539h,1539h,2A39h,737h,73Eh,741h
	dw	739h,1537h,1537h,2A37h,735h,73Ch,740h,73Ah
	dw	1535h,1535h,2A35h,734h,73Bh,73Eh,737h,0E35h
	dw	737h,739h,0E34h,735h,737h,0E33h,734h,735h
	dw	0E32h,732h,733h,72Dh,72Dh,72Bh,0E2Dh,728h
	dw	72Bh,72Eh,734h,3100h,0E2Dh,73Ch,0E2Fh,0E3Bh
	dw	0E30h,739h,72Dh,72Bh,0E2Dh,729h,72Bh,739h
	dw	739h,737h,0E39h,734h,737h,73Ah,740h,2300h
	dw	727h,732h,0E2Dh,73Ch,0E2Fh,0E3Bh,0E30h,739h
	dw	72Dh,72Bh,0E2Dh,729h,72Bh,0FFh,739h,739h
	dw	737h,0E39h,734h,737h,73Ah,740h,3100h,72Dh
	dw	737h,73Ch,0E2Fh,73Fh,739h,0E30h,72Fh,72Dh
	dw	737h,0E2Dh,735h,737h,739h,72Dh,72Bh,0E39h
	dw	728h,72Bh,72Eh,734h,2300h,733h,73Eh,72Dh
	dw	737h,73Eh,0E2Fh,73Bh,735h,0E30h,73Ch,72Dh
	dw	72Bh,0E2Dh,735h,737h,1FFh,72Dh,72Dh,72Bh
	dw	0E2Dh,728h,72Bh,72Eh,734h,2300h,727h,732h
	dw	0E2Dh,73Ch,0E2Fh,0E3Bh,0E30h,739h,72Dh,72Bh
	dw	0E2Dh,729h,72Bh,1FFh,0E2Dh,6200h,3FEh,0
w_D02CC	dw	4FCh,73F9h,702Eh,7000h,702Eh,7000h,702Eh,7FCh
	dw	6EF9h,729h,729h,729h,728h,2300h,729h,729h
	dw	729h,4FCh,73F9h,1C00h,702Eh,7FCh,6EF9h,729h
	dw	729h,729h,728h,2300h,729h,729h,729h,1C00h
	dw	0FFh,4FCh,73F9h,702Eh,7FCh,6EF9h,729h,729h
	dw	729h,728h,2300h,729h,729h,729h,1C00h,3FFh
	dw	4FCh,73F9h,702Eh,7FCh,6EF9h,729h,729h,729h
	dw	728h,2300h,729h,729h,729h,1C00h,1FFh,4FCh
	dw	73F9h,702Eh,3FEh,0
w_D0354	dw	7000h,7000h,7000h,6FCh,69F9h,726h,726h,0E26h
	dw	726h,726h,0E26h,0E26h
	dw	4 dup (726h)
	dw	0E26h,0F4h,1C00h,1C26h,1C00h,1C26h,1C00h,0E26h
	dw	0E26h,1C00h,1C26h,1C00h,1C26h,1C00h,1C26h,1C00h
	dw	726h,726h,0E26h,1C00h,1C26h,0FFh,1C00h,1C26h
	dw	1C00h,726h,726h,0E26h,1C00h,0E26h,0E26h,1C00h
	dw	726h,726h,0E26h,1C00h,1C26h,1C00h,1C26h,1C00h
	dw	0E26h,0E26h,1C00h,0E26h,726h,726h,1FFh,1C00h
	dw	1C26h,1C00h,1C26h,1C00h,0E26h,0E26h,1C00h,1C26h
	dw	1FFh,2FCh,64F9h,40F4h,0E2Dh,6200h,3FEh,0
w_D03F4	dw	5FCh,7DF9h,1C24h,1C24h,0E24h,0E24h,1C24h,1C24h
	dw	1524h,724h,0E24h,0E24h,1C24h,1C24h,1C24h,0E24h
	dw	0E24h,1C24h,7000h,7FF4h,1C24h,1C00h,0E24h,724h
	dw	724h,1C00h,1C24h,1C24h,1C24h,1C00h,1C24h,1C00h
	dw	0E24h,724h,724h,1C00h,1C24h,1C24h,1C24h,1C00h
	dw	0FFh,1C24h,1C00h,0E24h,724h,724h,1C00h,1C24h
	dw	1C24h,1C24h,1C00h,0E24h,0E24h,1C00h,0E24h,724h
	dw	724h,1C00h,1C24h,1C24h,1C24h,1C00h,1FFh,1C24h
	dw	1C00h,0E24h,724h,724h,1C00h,1C24h,1C24h,1C24h
	dw	1C00h,1FFh,7000h,40F4h,3FEh,0
w_D0490	dw	0FFh,7000h,7FFh,3FCh,78F9h,0FFh,72Dh,72Dh
	dw	72Bh,0E2Dh,728h,72Bh,72Eh,734h,3100h,7000h
	dw	7000h,7000h,1FFh,7000h,4FFh,3FEh,0
w_D04BE	db	0
b_D04BF	db	0,0FDh,0,0FCh,15h,0F9h,5Ah,0FBh,1,41h,6,43h,6,47h,6,49h
	db	7,4Dh,7,58h,4,58h,4,58h,4,58h,4,58h,4,58h,4,58h
	db	4,58h,4,58h,8,58h,8,58h,8,58h,8,58h,0Ah,58h,0Bh,58h
	db	0Bh,0,0,0FCh,15h,0F9h,64h,0FBh,2,52h,6,52h,6,52h,6,52h
	db	7,52h,7,51h,5,4Bh,5,42h,5,3Ch,5,3Fh,6,45h,6,0
	db	0,0FCh,1Ch,0F9h,5Ah,2Dh,4,2Eh,4,39h,4,38h,4,30h,4,0
	db	0,0FCh,1Ch,0F9h,64h,3Ah,4,31h,4,30h,4,33h,4,37h,4,0
	db	0,0FCh,7,0F9h,64h,30h,4,2Fh,4,0,0,0FCh,15h,0F9h,56h,0FBh
	db	2,4Ch,10h,43h,10h,3Ah,10h,40h,10h,0,0,0FCh,15h,0F9h,5Ah,0FBh
	db	1,57h,5,55h,5,53h,5,51h,5,4Fh,6,4Dh,6,0,0,0FCh
	db	19h,0F9h,53h,41h,80h,0,0,0FCh,15h,0F9h,5Ah,0F8h,8,0FBh,55h,8
	db	51h,8,43h,8,4Bh,8,49h,8,0F8h,0Ah,5,0FFh,0,54h,0Ah,0FFh
	db	3,0F8h,5,0FBh,54h,5,0FFh,6,0F8h,0,0,54h,2Dh,0F6h,64h,0
	db	0,0FCh,15h,0F9h,56h,44h,8,4Ch,8,4Ah,8,46h,8,38h,8,0F8h
	db	0Ah,0FCh,0FFh,0,43h,5,0FFh,0Ah,0F8h,0,0,43h,19h,0F6h,64h,0
	db	0,0FCh,15h,0F9h,50h,0FBh,3,0FFh,0,41h,8,0FFh,4,0FBh,1,0F8h
	db	8,4,40h,8,46h,8,37h,7,49h,7,52h,7,58h,7,0F8h,0
	db	0,0F6h,64h,0,0,0FCh,16h,0F9h,5Ah,0FBh,5,2Dh,55h,0FBh,1,3Bh
	db	5,0FFh,0,2Dh,5,0FFh,3,2Fh,5,2Dh,5,0,0,0FCh,17h,0F9h
	db	53h,3Eh,14h,0F9h,64h,47h,14h,0F9h,4Dh,50h,14h,0F9h,64h,4Ah,14h,0
	db	0,0FCh,18h,0F9h,56h,55h,0A7h,0,0,0FCh,19h,0F9h,53h,0FBh,2,0FFh
	db	0,41h,7,0FFh,2,45h,7,4Eh,38h,49h,7,48h,7,0F9h,4Dh,38h
	db	7,0F9h,45h,37h,7,0,0,0FCh,15h,0F9h,45h,56h,0Eh,0F9h,5Ah,48h
	db	0Eh,0F9h,45h,42h,7,0F9h,5Ah,50h,7,0,0,0FCh,16h,0F9h,4Dh,0FBh
	db	4,2Fh,5,32h,5,35h,5,0FBh,0,2Ch,5,0,0,0FCh,1Ah,0F9h
	db	56h,2Dh,0Ah,2Dh,0Ah,2Dh,0Ah,2Dh,0Ah,0,0,0FCh,1Bh,0F9h,5Ah,32h
	db	0Dh,32h,0Dh,32h,0Dh,0,0,0FCh,19h,0F9h,45h,0FBh,5,58h,5Ah,0F9h
	db	3Ch,0F8h,0Ah,3,0FFh,0,58h,5,0FFh,2,58h,0Ah,0FFh,1,58h,5
	db	0FFh,2,58h,0Ah,0FFh,1,0F8h,0,0,0F6h,64h,0,0,0FCh,16h,0F9h
	db	4Dh,34h,28h,0F9h,53h,0FBh,50h,2Eh,7Fh,0,0,0FCh,16h,0F9h,4Dh,32h
	db	5,0FBh,4,35h,5,2Ch,5,3Bh,5,0,0,0FCh,1Bh,0F9h,4Dh,0FFh
	db	0,35h,0Ah,35h,0Ah,0F9h,53h,0FFh,1,0F9h,5Ah,35h,5,0FFh,1,0F9h
	db	64h,35h,5,0FFh,1,0F9h,6Eh,35h,4,0FFh,2,0F9h,64h,35h,5,0FFh
	db	1,0F9h,5Ah,35h,5,0FFh,1,0F9h,53h,35h,0Ah,0FFh,1,0F9h,4Dh,35h
	db	0Ah,0FFh,1,0,0,0FCh,16h,0F9h,50h,0FBh,4,2Fh,0Ah,2Eh,0Ah,2Dh
	db	0Ah,2Fh,0Ah,0,0,0FCh,1Ch,0F9h,5Fh,2Fh,5,3Eh,5,41h,5,2Ch
	db	5,0,0,0FCh,1Ch,0F9h,5Fh,36h,0Ah,2Dh,0Ah,3Ch,0Ah,33h,0Ah,0
	db	0,0FCh,1Ch,0F9h,5Fh,2Dh,5,30h,5,32h,5,35h,5,44h,5,3Ch
	db	5,3Fh,5,42h,5,0,0,0FCh,1Ch,0F9h,5Fh,52h,5,4Ch,5,43h
	db	5,49h,5,0,0,0FCh,1Ch,0F9h,5Fh,5Ch,5,53h,5,4Dh,5,56h
	db	5,0,0,0FCh,1Ch,0F9h,5Fh,3Fh,5,3Dh,5,2Bh,5,0,0,0FCh
	db	1Ch,0F9h,5Fh,3Fh,5,3Dh,5,2Bh,5,0,5,3Fh,5,4Ah,5,37h
	db	5,0,0,0FCh,1Ch,0F9h,5Fh,0F8h,7,4,0F5h,2,41h,37h,7,0F5h
	db	2,41h,38h,7,0F5h,2,41h,46h,7,0F5h,2,41h,48h,7,0F5h,2
	db	41h,4Ah,7,0F5h,2,41h,4Ch,1Ch,0F8h,0,0,0F6h,64h,0,0,0FCh
	db	16h,0F9h,64h,0FBh,2,2Dh,0Ah,2Eh,0Ah,2Dh,0Ah,30h,0Ah,0,0,0FCh
	db	16h,0F9h,69h,0FBh,5,2Dh,0Ah,2Eh,0Ah,2Dh,0Ah,2Fh,0Ah,0,0,0FCh
	db	1Ch,0F9h,69h,0F5h,2,3Bh,53h,0Ah,2Fh,0Ah,0,0,0,0FCh,1Ch,0F9h
	db	6Eh,46h,0Ah,46h,0Ah,2Eh,0Ah,46h,0Ah,0,0,0FCh,19h,0F9h,56h,52h
	db	7,51h,7,4Dh,7,4Ch,7,0,0,0FCh,1Ch,0F9h,5Ah,5Ah,7,3Fh
	db	7,0,0,0FCh,1Ch,0F9h,5Fh,2Dh,0Eh,37h,0Eh,47h,0Eh,55h,0Eh,0
	db	0,0FCh,16h,0F9h,5Ah,0FBh,3,31h,0Eh,2Dh,0Eh,31h,0Eh,2Fh,0Eh,0
	db	0,0FCh,1Ch,0F9h,69h,0FFh,0,3Bh,1Ch,0FFh,3,0FDh,0,0FCh,1Ch,0F9h
	db	5Fh,3Bh,1Ch,2Bh,4,2Fh,14h,3Bh,1Ch,3Bh,1Ch,0FDh,0,0FCh,1Ch,0F9h
	db	5Fh,3Bh,1Ch,3Bh,0Eh,39h,0Eh,3Bh,1Ch,3Bh,1Ch,0FDh,0,0FCh,1Ch,0F9h
	db	5Fh,2Bh,4,35h,4,2Fh,6,2Bh,4,41h,4,3Bh,6,3Bh,1Ch,39h
	db	1Ch,3Bh,0Eh,39h,0Eh,0FDh,0,0FCh,1Ch,0F9h,5Fh,3Bh,1Ch,3Ch,1Ch,3Eh
	db	1Ch,3Bh,1Ch,0FDh,0,0FCh,1Ch,0F9h,5Fh,3Bh,1Ch,3Ch,1Ch,3Eh,1Ch,3Dh
	db	1Ch,0FDh,0,0FCh,1Ch,0F9h,5Fh,3Bh,1Ch,3Bh,1Ch,39h,1Ch,3Bh,1Ch,0FDh
	db	0,0FCh,1Ch,0F9h,5Fh,3Bh,1Ch,39h,1Ch,3Bh,1Ch,3Dh,1Ch,0FDh,0
w_D087E	dw	7000h,19FCh,37F9h,1C4Eh,53F9h,544Eh,0FBh,704Ah
	dw	3800h,5FF9h,74Ah,3F3Dh,33Bh,33Ch,33Eh,340h
	dw	242h,50F9h,1C44h,5400h,5AF9h,704Ah,0E00h,33Bh
	dw	33Ch,33Eh,340h,242h,50F9h,1C44h,5400h,37F9h
	dw	1C4Eh,53F9h,544Eh,5AF9h,0E00h,33Bh,33Ch,33Eh
	dw	340h,242h,50F9h,1C44h,5400h,3800h,5AF9h,74Ah
	dw	313Dh,7000h,7000h,0FDh
w_D08E6	db	0FCh,16h,0F9h
b_D08E9	db	49h,0FBh,0Ah,2Fh,0Eh,30h,0Eh,2Fh,0Eh,31h,0Eh,2Bh,0Eh,30h,0Eh,2Fh
	db	0Eh,2Dh,0Eh,0FDh,0,0FCh,16h,0F9h
b_D0901	db	49h,0FBh,0Ah,2Fh,0Eh,30h,0Eh,2Eh,0Eh,31h,0Eh,2Bh,0Eh,30h,0Eh,2Eh
	db	0Eh,31h,0Eh,0FDh,0,0FCh,16h,0F9h
b_D0919	db	49h,0FBh,0Ah,2Fh,0Eh,30h,0Eh,35h,0Eh,31h,0Eh,32h,0Eh,30h,0Eh,2Eh
	db	0Eh,31h,0Eh,0FDh,0,0FCh,16h,0F9h
b_D0931	db	49h,0FBh,0Ah,2Fh,0Eh,30h,0Eh,2Fh,0Eh,31h,0Eh,35h,0Eh,30h,0Eh,2Fh
	db	0Eh,31h,0Eh,0FDh,0
w_D0946	dw	1EFCh,64F9h,8FBh,1842h,2441h,3040h,903Fh,0
w_D0956	dw	21FCh,5FF9h,8FBh,1836h,2435h,3034h,9031h,0
w_D0966	dw	50F9h,0C00h,182Ch,4800h,826h,2F5h,2624h,2608h
	dw	3108h,48h,0
w_D097C	dw	1EFCh,64F9h,2FBh,1858h,857h,1858h,857h,1858h
	dw	4FBh,953h,1456h,1654h,2FBh,69F9h,5051h,84Ch
	dw	84Eh,1050h,1051h,5053h,104Ch,854h,855h,1056h
	dw	64F9h,5854h,84Ch,1858h,456h,457h,1858h,456h
	dw	457h,1858h,456h,457h,1958h,453h,454h,5FBh
	dw	1456h,1654h,2FBh,5051h,104Ch,84Fh,850h,1051h
	dw	5853h,84Ch,5FBh,1054h,1053h,2FBh,5851h,853h
	dw	1054h,5FBh,855h,856h,2FBh,5858h,84Dh,1059h
	dw	5FBh,858h,857h,2FBh,5856h,84Ch,5FBh,858h
	dw	858h,1056h,2FBh,5854h,84Ah,5FBh,1056h,1054h
	dw	2FBh,0A053h,19FCh,3CF9h,1858h,456h,457h,1958h
	dw	456h,457h,1A58h,456h,457h,1B58h,453h,454h
	dw	5FBh,1956h,1D54h,2FBh,5051h,104Ch,1050h,1051h
	dw	5853h,84Ch,5FBh,1054h,1053h,2FBh,7051h,1000h
	dw	0
w_D0A5E	dw	1CFCh,55F9h,2FBh,1000h,1057h,1000h,1057h,1000h
	dw	1057h,2B00h,19FCh,37F9h,8051h,8053h,7054h,1000h
	dw	1CFCh,55F9h,1000h,1057h,1000h,1057h,1000h,1057h
	dw	2B00h,804Ch,804Ah,8048h,19FCh,37F9h,804Fh,804Dh
	dw	804Ch,0A04Ah,0BC00h,1EFCh,4BF9h,804Ch,804Ah,7048h
	dw	1000h,0
w_D0AB2	dw	1CFCh,55F9h,2FBh,1000h,104Ch,1000h,104Ch,1000h
	dw	104Ch,2B00h,8000h,8000h,8000h,1000h,104Ch,1000h
	dw	104Ch,1000h,104Ch,2B00h,8048h,8047h,8045h,8000h
	dw	8000h,8000h,0A000h,0BC00h,8000h,8000h,8000h,0
w_D0AF2	dw	1CFCh,55F9h,2FBh,8B00h,8000h,8000h,8000h,8B00h
	dw	8040h,8041h,8040h,8000h,8000h,8000h,0A000h,0BC00h
	dw	8000h,8000h,6000h,2039h,0
w_D0B1C	dw	22FCh,64F9h,2FBh,8B00h,103Eh,103Eh,1000h,103Eh
	dw	2000h,1BFCh,204Bh,22FCh,103Eh,103Eh,1000h,103Eh
	dw	2000h,1BFCh,104Bh,104Bh,22FCh,103Eh,103Eh,1000h
	dw	103Eh,4000h,8B00h,103Eh,103Eh,1000h,103Eh,2000h
	dw	1BFCh,204Bh,22FCh,103Eh,103Eh,1000h,103Eh,2000h
	dw	1BFCh,104Bh,104Bh,22FCh,103Eh,103Eh,1000h,103Eh
	dw	4000h,8000h,8000h,8000h,0A000h,0BC00h,103Eh,103Eh
	dw	1000h,103Eh,2000h,1BFCh,204Bh,22FCh,103Eh,103Eh
	dw	1000h,103Eh,2000h,1BFCh,104Bh,104Bh,6000h,1CFCh
	dw	202Dh,0
w_D0BB0	dw	1CFCh,6EF9h,2FBh,8B00h,1821h,828h,102Dh,1034h
	dw	1039h,1040h,2000h,1820h,828h,102Fh,1032h,1034h
	dw	1038h,2000h,1821h,828h,102Dh,1034h,1039h,1040h
	dw	2000h,8B00h,1821h,828h,102Dh,1034h,1039h,1040h
	dw	2000h,1820h,828h,102Fh,1032h,1034h,1038h,2000h
	dw	1821h,828h,102Dh,1034h,1039h,1040h,2000h,1824h
	dw	82Bh,1030h,1034h,1037h,103Ch,2000h,1826h,82Dh
	dw	1032h,1035h,1039h,103Eh,2000h,1828h,82Dh,1030h
	dw	1034h,1039h,103Ch,2000h,10F8h,2801h,2F18h,3208h
	dw	3410h,2C10h,4010h,4410h,4C10h,3C10h,4C10h,0F810h
	dw	0,64F6h,0BC00h,1821h,828h,102Dh,1034h,1039h
	dw	1040h,2000h,1828h,82Fh,1034h,1038h,103Bh,1040h
	dw	2000h,1845h,840h,1039h,1034h,102Dh,1028h,2021h
	dw	0
w_D0C82	dw	1DFCh,4EF9h,0FFh,1647h,0B4Ah,0B4Ah,1647h,0B4Ah
	dw	164Ch,0B4Ch,2C4Ah,0B4Ah,0B4Ah,1647h,164Ah,1647h
	dw	0B4Ah,1647h,0B47h,2C45h,0B4Ah,0B4Ah,1647h,0B4Ah
	dw	0B4Ah,1647h,0B4Ah,164Ch,0B4Ch,2C4Ah,0B4Ah,0B4Ah
	dw	1647h,0B47h,1645h,0B45h,5843h,164Ah,44F9h,2FFh
	dw	1653h,0B53h,1651h,0B51h,0B4Fh,0
w_D0CDE	dw	1DFCh,4EF9h,41F7h,0FFh,1743h,0B47h,0B47h,1643h
	dw	0B47h,1648h,0B48h,2C47h,0B47h,0B47h,1643h,1647h
	dw	1643h,0B47h,1643h,0B43h,2C3Eh,0B47h,0B47h,1643h
	dw	0B47h,0B47h,1643h,0B47h,1648h,0B48h,2C47h,0B47h
	dw	0B47h,1643h,0B43h,163Eh,0B3Eh,583Eh,1547h,44F9h
	dw	2FFh,1643h,0B43h,163Eh,0B3Eh,0B3Eh,40F7h,0
w_D0D3E	dw	0B000h,3FFh,1EFCh,3FBh,6CF9h,0FFh,1647h,0B4Ah
	dw	0B4Ah,1647h,0B4Ah,164Ch,0B4Ch,214Ah,0B00h,0B4Ah
	dw	0B4Ah,1647h,164Ah,1647h,0B4Ah,1647h,0B47h,2145h
	dw	0B00h,0B4Ah,0B4Ah,1647h,0B4Ah,0B4Ah,1647h,0B4Ah
	dw	164Ch,0B4Ch,214Ah,0B00h,0B4Ah,0B4Ah,1647h,0B47h
	dw	1645h,0B45h,2143h,3700h,163Eh,1FFh,1647h,0B47h
	dw	1645h,0B45h,1643h,0
w_D0DA6	db	0,0B0h,0,0B0h,0FCh,1Fh,0F9h,6Ch,0FBh,5,0,0B0h,0,84h,0FAh,1
	db	0FFh,2Ch,32h,26h,0FAh,0,0,0,0F7h,40h,0,6,0FFh,0,0F9h,64h
	db	2Bh,42h,2Bh,42h,37h,0Bh,37h,16h,32h,0Bh,2Bh,42h,2Bh,42h,32h,0Bh
	db	32h,16h,2Dh,0Bh,2Bh,42h,2Bh,42h,3Bh,0Bh,3Bh,16h,32h,0Bh,2Bh,21h
	db	32h,21h,2Bh,42h,0F9h,6Ch,0FAh,1,0FFh,2Ch,32h,26h,0FAh,0,0,0
	db	0F7h,40h,0,6,0FFh,1,37h,21h,32h,21h,37h,0Bh,0,0
w_D0E04	dw	0B000h,3FFh,20FCh,3AF9h,0FFh,1645h,0B45h,0B45h
	dw	1645h,1645h,1645h,0B45h,0B45h
	dw	5 dup (1645h)
	dw	0B45h,0B45h,1645h,1645h,1645h,0B45h,0B45h,3FFh
	dw	2145h,2145h,0B45h,0
w_D0E40	dw	0B000h,3FFh,3CF9h,0B3Dh,2F5h,403Dh,0F50Bh,3C02h
	dw	0B3Fh,53Eh,63Ch,0B3Dh,0B40h,2F5h,3F3Ch,3C0Bh
	dw	3D0Bh,400Bh,0F50Bh,3C02h,0B3Fh,0B3Ch,0B00h,2F5h
	dw	403Ch,0F50Bh,3D02h,0B3Fh,0B3Ch,7FFh,0
w_D0E7E	dw	9000h,0CFFh,6C00h,3FBh,24FCh,5FF9h,0FFh,2448h
	dw	1B47h,1B4Ah,124Ch,1B4Dh,951h,244Fh,2458h,959h
	dw	951h,94Dh,94Ch,2454h,1B53h,1B56h,958h,1B59h
	dw	956h,95Dh,245Bh,2F5h,584Ch,0F509h,4702h,953h
	dw	2F5h,4F43h,0F509h,4002h,94Ch,2F5h,584Ch,0F509h
	dw	4502h,951h,2F5h,4D41h,0F509h,3E02h,94Ah,1FFh
	dw	64F9h,2F5h,4F43h,0F509h,4502h,951h,0
w_D0EEC	dw	9000h,9000h,1FCh,61F9h,243Ch,93Bh,937h,934h
	dw	2D3Eh,93Eh,941h,93Eh,2D43h,940h,93Bh,937h
	dw	2D40h,6BF9h,2F5h,4039h,0F512h,3902h,123Eh,61F9h
	dw	2448h,947h,943h,940h,2D4Ah,94Ah,94Dh,94Ah
	dw	945h,244Fh,94Ch,947h,943h,2D4Ch,67F9h,940h
	dw	945h,94Dh,94Ah,1FFh,9000h,6C00h,0FFh,55F9h
	dw	243Ch,93Bh,943h,940h,1B3Eh,940h,941h,93Eh
	dw	941h,93Eh,945h,2443h,94Ch,947h,943h,940h
	dw	94Dh,945h,941h,940h,2F5h,3C48h,0F524h,3B02h
	dw	93Bh,2F5h,434Fh,0F509h,4C02h,940h,2F5h,3E4Ah
	dw	0F51Bh,4C02h,940h,2F5h,414Dh,0F509h,4A02h,93Eh
	dw	2F5h,414Dh,0F509h,4A02h,93Eh,2F5h,4551h,0F509h
	dw	4F02h,2443h,2F5h,4C58h,0F509h,5302h,947h,2F5h
	dw	434Fh,0F509h,4C02h,940h,2F5h,4C58h,0F509h,5102h
	dw	945h,2F5h,414Dh,0F509h,4A02h,93Eh,1FFh,5AF9h
	dw	2F5h,4F43h,0F509h,4502h,951h,0
w_D0FE8	dw	1FCh,5FF9h,2F5h,2B1Fh,0F509h,2102h
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,6EF9h,1230h,932h,92Dh,5FF9h
	dw	2F5h,2B1Fh,0F509h,2102h
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,6EF9h,1230h,932h,928h,55F9h
	dw	0FFh,92Bh
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,5FF9h,3F5h,3024h,1237h,3F5h
	dw	3226h,939h,55F9h,92Dh,92Bh
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,5FF9h,3F5h,3024h,1237h,3F5h
	dw	3228h,935h,55F9h,928h,1FFh,64F9h,92Bh
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,69F9h,3F5h,3024h,1237h,3F5h
	dw	3226h,939h,64F9h,92Dh,92Bh
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,69F9h,3F5h,3024h,1237h,3F5h
	dw	3228h,935h,64F9h,928h,55F9h,0FFh,92Bh
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,5BF9h,3F5h,3024h,1237h,3F5h
	dw	3226h,939h,55F9h,92Dh,92Bh
	dw	4 dup (122Dh)
	dw	92Dh,92Bh,92Dh,5BF9h,3F5h,3024h,1237h,3F5h
	dw	3228h,935h,55F9h,928h,1FFh,73F9h,2F5h,2B1Fh
	dw	0F509h,2102h,92Dh,5A00h,2F5h,3024h,0F509h,2602h
	dw	932h,5A00h,2F5h,3327h,0F512h,2602h,1232h,64F9h
	dw	0FFh,92Bh,92Dh,5A00h,2F5h,3024h,0F509h,2602h
	dw	932h,5A00h,2F5h,3327h,0F512h,2602h,1232h,3FFh
	dw	69F9h,2F5h,2B1Fh,0F509h,2102h,92Dh,0
w_D1158	dw	23FCh,37F9h,0FEh,0FFh,122Eh,7FFh,4FEh,122Eh
	dw	122Eh,50F9h,0FFh,122Eh,5FFh,41F9h,0FFh,122Eh
	dw	7FFh,122Eh,122Eh,50F9h,0FFh,122Eh,5FFh,41F9h
	dw	0FFh,122Eh,7FFh,122Eh,7FFh,122Eh,7FFh,122Eh
	dw	122Eh,41F9h,0FFh,122Eh,5FFh,1B2Eh,2D2Eh,1B00h
	dw	92Eh,242Eh,1B00h,92Eh,1B2Eh,92Eh,242Eh,0FFh
	dw	1B00h,92Eh,242Eh,1B00h,92Eh,242Eh,1B00h,92Eh
	dw	1B2Eh,92Eh,242Eh,3FFh,46F9h,92Eh,92Eh,0
w_D11D8	db	0F9h,64h,24h,24h,26h,24h,24h,1Bh,24h,9,26h,1Bh,26h,9,24h,24h
	db	26h,24h,24h,24h,0F5h,2,26h,30h,9,2Dh,9,2Dh,9,2Bh,9,0FFh
	db	1,0F9h,64h,24h,24h,26h,24h,24h,1Bh,24h,9,26h,1Bh,26h,9,24h
	db	24h,26h,24h,0F9h,6Eh,24h,24h,30h,5,2Dh,4,2Bh,9,2Dh,5,2Dh
	db	4,26h,9,0FFh,1,0F9h,64h,24h,24h,26h,24h,24h,1Bh,24h,9,26h
	db	1Bh,26h,9,24h,24h,26h,24h,24h,24h,0F5h,2,26h,30h,9,2Dh,9
	db	2Dh,9,2Bh,9,24h,24h,26h,24h,24h,1Bh,24h,9,26h,1Bh,26h,9
	db	24h,24h,26h,24h,0F9h,6Eh,24h,24h,30h,5,2Dh,4,2Bh,9,2Dh,5
	db	2Dh,4,26h,9,0F9h,76h,24h,12h,24h,12h,26h,9,2Dh,9,0F5h,2
	db	24h,2Bh,9,24h,9,24h,12h,24h,12h,26h,9,0,1Bh,24h,12h,24h
	db	12h,26h,9,2Dh,9,0F5h,2,24h,2Bh,9,24h,9,26h,9,2Bh,9
	db	26h,9,2Dh,9,0F9h,6Eh,0FFh,0,24h,12h,24h,12h,26h,9,2Dh,9
	db	0F5h,2,24h,2Bh,9,24h,9,24h,12h,24h,12h,26h,9,0,1Bh,24h
	db	12h,24h,12h,26h,9,2Dh,9,0F5h,2,24h,2Bh,9,24h,9,26h,9
	db	2Bh,9,26h,9,2Dh,9,0FFh,3,24h,12h,0,0
w_D12C4	dw	2FCh,58F9h,0FFh,3C00h,2F5h,433Eh,0Ah,0F50Ah
	dw	3C02h,0A41h,3200h,3C00h,2F5h,3E37h,0Ah,0F50Ah
	dw	3502h,0A3Ch,0A00h,2F5h,3E39h,0Ah,0FF1Eh,0F501h
	dw	3702h,283Eh,2F5h,3C35h,0FE28h,0F501h,3902h,283Eh
	dw	0FDh
w_D1306	dw	1FCh,62F9h,0FFh,2F5h,3024h,0F50Ah,2602h,0A32h
	dw	0A00h,0A26h,0A28h,0A2Bh,0A2Eh,0A00h,0A2Dh,2F5h
	dw	3024h,0F50Ah,2602h,0A32h,0A00h,2F5h,3529h,0F50Ah
	dw	2B02h,0A37h,2F5h,3024h,0F50Ah,2602h,0A32h,0A00h
	dw	0A26h,0A28h,0A2Bh,2F5h,2E22h,0Ah,0F50Ah,2402h
	dw	0A2Dh,2F5h,3024h,0F50Ah,2602h,0A32h,0A00h,2F5h
	dw	3024h,0F50Ah,2602h,0A32h,1FFh,2F5h,3226h,0F528h
	dw	2402h,2830h,1FEh,2F5h,3226h,0FD28h
w_D1382	dw	23FCh,49F9h,0FFh,1400h,142Eh,142Eh,0F2Eh,500h
	dw	142Eh,142Eh,0A2Eh,0A00h,1400h,142Eh,142Eh,0F2Eh
	dw	500h,142Eh,142Eh,0A2Eh,0A00h,1FFh,2800h,2800h
	dw	1FEh,2800h,0FDh
w_D13B8	dw	6FCh,58F9h,0F4h,0FFh,1400h,1426h,1400h,0F26h
	dw	500h,1400h,1426h,0A00h,0A26h,1400h,1426h,1400h
	dw	0F26h,500h,1400h,1426h,0A00h,0A26h,1FFh,2800h
	dw	2800h,1FEh,2800h,0FDh
w_D13F0	dw	5FCh,71F9h,7FF4h,0FFh,1424h,1400h,1400h,0F00h
	dw	524h,1424h,1400h,0A00h,0A00h,1424h,1400h,1400h
	dw	0F00h,524h,1424h,1400h,0A00h,0A00h,1FFh,2800h
	dw	2800h,1FEh,2800h,0FDh
w_D1428	dw	1E00h,2F2h,736Eh,0F901h,6473h,0F214h,4404h,3325h
	dw	136h,40F7h,3464h,4F2h,2544h,3633h,0F701h,6440h
	dw	0F227h,4404h,3325h,136h,40F7h,1964h,4F2h,2544h
	dw	3633h,0F701h,6440h,0F714h,40h,0
w_D1464	dw	0AFCh,78F9h,1937h,12FCh,6CF9h,3C3Ch,0
w_D1472	dw	0AFCh,5AF9h,1937h,12FCh,7BF9h,3C37h,0
w_D1480	dw	0AFCh,78F9h,5A37h,0
w_D1488	dw	0AFCh,5AF9h,637h,0
w_D1490	dw	0AFCh,6EF9h,0FFh,639h,5FFh,639h,0,3FCh
	dw	0FF55h,3900h,0FF06h,3905h,6,0
w_D14AC	dw	0BFCh,5FF9h,0A54h,0
w_D14B4	dw	0BFCh,64F9h,0A5Fh,0A60h,0
w_D14BE	dw	0DFCh,78F9h,6E3Ch,0
w_D14C6	dw	0EFCh,73F9h,1E3Ch,0
w_D14CE	dw	0DFCh,64F9h,2340h,0
w_D14D6	dw	0DFCh,73F9h,232Bh,0
w_D14DE	dw	0DFCh,73F9h,2326h,0EFCh,75F9h,142Bh,0
w_D14EC	db	0FCh,0Fh,0F9h,6Ch,0FBh,0Ah,3Ch,32h,3Ch,32h,3Ch,32h,3Ch,32h,0,0
w_D14FC	dw	78F9h,3257h,0
w_D1502	dw	50F9h,5A58h,0
w_D1508	dw	14FCh,20F9h,2D64h,0
w_D1510	dw	0
w_D1512	dw	8FCh,7FF9h,6428h,0
w_D151A	dw	8FCh,5AF9h,6424h,0
w_D1522	dw	9FCh,55F9h,1E30h,0
w_D152A	dw	9FCh,55F9h,4FBh,0A4Fh,0A4Fh,0
w_D1536	dw	9FCh,4BF9h,2FBh,0FFh,4F2h,5A58h,5E5Ch,5C00h
	dw	0FF07h,4,0
w_D154C	dw	9FCh,4BF9h,2FBh,0FFh,4F2h,6464h,6562h,6400h
	dw	0FF07h,4,0
w_D1562	dw	9FCh,4BF9h,2FBh,764h,762h,765h,0
w_D1570	dw	9FCh,4BF9h,2FBh,750h,758h,75Ah,0
w_D157E	dw	11FCh,5AF9h,283Ch,0
w_D1586	dw	0FFCh,6EF9h,5FBh,1E3Ch,1E3Ch,1E3Ch,0
w_D1594	dw	0BFCh,5FF9h,0A5Fh,600h,13FCh,692Bh,0
w_D15A2	dw	0EFCh,64F9h,1E35h,0
w_D15AA	dw	25FCh,73F9h,0FFh,2F2h,706h,2101h,0FF06h,0FFh
	dw	0
w_D15BC	dw	0
w_D15BE	dw	0BFCh,5AF9h,0FFh,2F2h,625Dh,5F00h,0F205h,5D02h
	dw	62h,45Fh,4FFh,0
w_D15D6	dw	9FCh,55F9h,2FBh,748h,74Ch,74Fh,0
mpu_port	db	30h,3
	db	512 dup (53h)
	db	0,0
b_D17E8	db	0
b_D17E9	db	0
w_D17EA	dw	0
w_D17EC	dw	0
w_D17EE	dw	3Eh,9
w_D17F2	db	5Ch,0,0
	db	'At controlled CRASH!$'
w_D180A	dw	0
w_D180C	dw	0
w_D180E	dw	0
w_D1810	dw	0
w_D1812	dw	0
b_D1814	db	0
w_D1815	dw	0
w_D1817	dw	4C2h,4F2h,510h,520h,530h,53Ah,54Ah,55Eh
w_D1827	dw	566h,590h,5B0h,5D4h,5ECh,600h,608h,626h
	dw	63Ah,64Ch,65Ah,666h,68Ch,69Ah,6AAh,6E4h
	dw	6F4h,702h,710h,726h,734h,742h,74Eh,762h
	dw	78Eh,79Eh,7AEh,7BCh,7CAh,7D8h,7E2h,7F0h
	dw	800h,80Ch,81Ch,82Ch,846h,854h,862h,870h
w_D1877	dw	8E6h,8FEh,916h,92Eh
w_D187F	dw	0
w_D1881	dw	0
w_D1883	dw	0
w_D1885	dw	0
w_D1887	dw	0FFFFh
w_D1889	dw	41F0h,1610h,0FF12h
w_D188F	db	20h,0,0
	db	'   Covert Action    '
	db	0FFh
w_D18A7	db	10h,0,0,40h,1,3,4
	db	9 dup (0)
	db	1,2,3,4,5,6,7,0,9,64h,0FFh
w_D18C2	dw	5,200h,1800h,832h,100h,200h,1801h,232h
	dw	100h,200h,1802h,232h,100h,200h,1803h,232h
	dw	100h,200h,1804h,232h,100h,200h,1805h,232h
	dw	100h,200h,1806h,232h,100h,200h,1807h,232h
	dw	100h,200h,1808h,232h,100h,200h,1809h,232h
	dw	100h,200h,180Ah,232h,100h,200h,180Bh,232h
	dw	100h,200h,180Ch,232h,100h,200h,180Dh,232h
	dw	100h,200h,180Eh,232h,100h,200h,180Fh,232h
	dw	100h,200h,1810h,232h,100h,200h,1811h,232h
	dw	100h,200h,1812h,232h,100h,200h,1813h,232h
	dw	100h,200h,1814h,832h,100h,200h,1815h,832h
	dw	100h,200h,1816h,832h,100h,200h,1817h,832h
	dw	100h,200h,1818h,832h,100h,200h,1819h,832h
	dw	100h,200h,181Ah,832h,100h,200h,181Bh,832h
	dw	100h,200h,181Ch,832h,100h,200h,181Dh,832h
	dw	100h,200h,181Eh,832h,100h,200h,181Fh,832h
	dw	100h,0FF00h
w_D19C6	dw	205h,200h,1820h,832h,100h,200h,1821h,832h
	dw	100h,200h,1822h,832h,100h,200h,1823h,832h
	dw	100h,200h,1824h,832h,100h,200h,1825h,832h
	dw	0,0FF00h
w_D19FA	db	8,0,0
	db	'Car Engine'
	db	0,0,3,0,0Ch,32h,0Bh,1,1,0Ah,1Ah,7,5,0,0,32h
	db	28h,34h,32h,32h,0,0Fh,32h,32h,5Ah,50h,0,43h,3,3,0,7
	db	64h,5,0,0,0,1Eh,35h,2Dh,26h,5Ah,64h,64h,64h,50h,64h,0
	db	0Ch,0,0Ch,0,0,0,12h,33h,33h,34h,5Ah,64h,64h,64h,0Ch,32h
	db	0Bh,1,1,0Ah,1Ah,7,5,0,0,31h,29h,32h,32h,32h,0,10h
	db	32h,32h,5Ah,50h,0,35h,2,3,0,7,64h,5,0,0,0,1Eh
	db	35h,2Dh,26h,5Ah,64h,64h,64h,5Ah,64h,0,0Ch,0,0Ch,0,0,0
	db	12h,33h,33h,34h,5Ah,64h,64h,64h,0,0FFh
w_D1A81	db	8,2,0
	db	'Elec Gtr 1'
	db	7,5,0Fh,0,24h,37h,10h,1,0,0,3Ch,7,4,0,0,1
	db	1,12h,0,32h,64h,29h,32h,32h,41h,13h,3Ch,55h,0,9,69h,3
	db	32h
	db	4 dup (0)
	db	20h,48h,50h,64h,54h,2Eh,0Eh,0,44h,5Fh,5Bh,0Ch,1Bh,0Ch,3,4
	db	2,0Fh,2Eh,55h,48h,64h,5Bh,53h,0,24h,2Dh,10h,1,1,0,24h
	db	7,4,0,0,1,1,12h,0,32h,64h,29h,32h,32h,3Dh,12h,30h
	db	5Ah,0,9,69h,3,32h
	db	4 dup (0)
	db	20h,4Dh,64h,64h,54h,2Dh,0Dh,0,4Fh,5Fh,5Bh,0Ch,1Bh,0Ch,3,4
	db	2,0Fh,2Eh,50h,48h,64h,5Bh,53h,0,24h,2Eh,10h,1,0,27h,0
	db	7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	0Bh,0,7
	db	13 dup (0)
	db	59h,64h,5Bh,0Ch,27h,4
	db	5 dup (0)
	db	4Bh,4Ah,64h,64h,64h,0,24h,32h,10h,1,0,28h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	0Bh,0,7
	db	13 dup (0)
	db	58h,64h,5Bh,8,1Bh,0Ch
	db	5 dup (0)
	db	4Bh,4Ah,64h,64h,64h,0,0FFh
w_D1B7B	db	8,4,0
	db	'Elec Gtr 2'
	db	1,2,7,0,24h,32h,10h,1,0,0,55h,7,3,3,4,10h
	db	14h,37h,0,21h,2Bh,2Eh,32h,32h,3Eh,0Ch,34h,45h,0,6,66h,8
	db	25h,53h,0,0,0,11h,0Bh,3Ch,24h,54h,27h,1Ah,0,5Fh,5Ah,4Bh
	db	0Ch,1Bh,0Ch,2,1,0,0Dh,64h,64h,28h,64h,5Bh,26h,0Ch,53h,16h
	db	10h,1,0,0,55h,7,6,3,4,1,1,9,0,2Eh,64h,2Bh
	db	32h,32h,3Eh,0Ch,4Fh,33h,0,9,66h,4,5Dh,19h,0,0,3,2
	db	0Bh,3Ch,24h,54h,38h,20h,0,50h,5Ah,44h,7,1Bh,0Ch,2,1,0
	db	0Dh,42h,64h,64h,64h,5Bh,26h,0Ch,24h,35h,10h,1,0,28h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	0Bh,0,7
	db	13 dup (0)
	db	64h,64h,7Fh,0,1Bh,0Ch,0,0,0,3Dh,32h,2Eh,1,64h,60h,48h
	db	0,24h,32h,0Bh
	db	4 dup (0)
	db	7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	0Bh,0,7
	db	14 dup (0)
	db	32h,5Bh,0Ch,1Bh,0Ch
	db	11 dup (0)
	db	0FFh
w_D1C75	db	8,6,0
	db	'Slap Bass2'
	db	5,0,3,0,18h,31h,10h,1,0,24h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,5Ch,53h,4,1Bh,0Ch
	db	6 dup (0)
	db	46h,64h,64h,64h,64h,18h,33h,10h,1,0,25h,0,7,3,0,0
	db	0Ch,0Dh,0Eh,0,18h,23h,2Ch,32h,32h,43h,0,3Dh,0,0,3,0
	db	7
	db	13 dup (0)
	db	52h,64h,53h,4,1Bh,0Ch,0,0,3,8,0Ch,5Eh,28h,57h,61h,64h
	db	0,24h,0FFh
w_D1CFC	db	8,8,0,43h,79h,6Dh,62h,61h,6Ch,20h,20h,20h,20h,5,0,3
	db	1,32h,32h,10h,0,0,5,0,7,4,2,0,0Ah,0Ch,17h,0
	db	5Eh,4Bh,3Fh,32h,32h,3Fh,1Dh,53h,0,0,3,0,7
	db	4 dup (0)
	db	1
	db	8 dup (0)
	db	64h,64h,62h,0Ch,0,0Ch,0,0,0,0Ch,32h,51h,48h,64h,54h,47h
	db	0,32h,32h,10h,0,0,8,0,7
	db	10 dup (0)
	db	32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	1
	db	8 dup (0)
	db	64h,64h,62h,0Ch,0,0Ch,0,0,0,0Bh,26h,49h,52h,64h,64h,5Eh
	db	0,0,0FFh
w_D1D83	db	8,0Ah,0
	db	'Kick Drum '
	db	5,0,1,1,3Ch,32h,0Bh
	db	4 dup (0)
	db	7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,55h,0,0,0,64h,0,0
	db	0FFh
w_D1DCE	db	8,0Ch,0,53h,6Eh,61h,72h,65h,20h,20h,20h,20h,20h,5,0,1
	db	1,3Ah,32h,0Bh,0,0,1,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,55h,0,0,0,64h,0,0
	db	0FFh
w_D1E19	db	8,0Eh,0,54h,6Fh,6Dh,73h,20h,20h,20h,20h,20h,20h,5,0,1
	db	1,35h,32h,0Dh,0,0,3,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,55h,0,0,0,64h,0,0
	db	0FFh
w_D1E64	db	8,10h,0,45h,78h,70h,6Ch,6Fh,73h,69h,6Fh,6Eh,31h,8,0,3
	db	1,7,32h,0Bh,0,0,2
	db	9 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	17h
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,5Dh,53h,0,0,64h,0Fh,0
	db	0,1,32h,0Bh,0,0,2
	db	9 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	1Dh
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,5Bh,5Ch,0,0,64h,14h,0
	db	0,0,0FFh
w_D1EEB	db	8,12h,0,42h,65h,65h,70h,20h,20h,20h,20h,20h,20h,0,0,1
	db	0,18h,32h,0Bh,1,0,2,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h,0,0,0,64h,0,3,0,7,2Dh,0,0
	db	0,14h,2Eh,0,1Dh,1Dh,64h,64h,64h,64h,64h,64h,0,0Ch,0,0Ch
	db	0,0,0,29h,0,1Dh,1Eh,64h,64h,64h,64h
	db	11 dup (0)
	db	0FFh
w_D1F42	db	8,14h,0,47h,75h,6Eh,73h,68h,6Fh,74h,20h,20h,20h,5,0,3
	db	1,0Ch,32h,0Bh,0,0,1,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,35h,26h,0,0,64h,50h,0
	db	0,0Ch,32h,0Bh,0,0,1,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,36h,25h,0,0,64h,50h,0
	db	0,0,0FFh
w_D1FC9	db	8,16h,0,43h,6Ch,69h,63h,6Bh,20h,20h,20h,20h,20h,5,0,3
	db	1,18h,32h,0Bh,0,0,3Fh,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	16h
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,50h,0,0,23h,64h,0,0
	db	0,18h,32h,0Bh,0,0,40h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	16h
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,50h,0,0,23h,64h
	db	4 dup (0)
	db	0FFh
w_D2050	db	8,18h,0
	db	'Jet Plane '
	db	5,1,0Fh,0,0,32h,0Bh,1,0,18h,0,7,8,0,0,48h
	db	0,0,3Dh,32h,64h,64h,64h,32h
	db	5 dup (0)
	db	3,0,7,0,32h
	db	11 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,28h,0,57h,57h,64h,64h,64h
	db	64h,5,32h,0Bh,1,0,18h,0,7,8,0,0,48h,0,0,3Ch
	db	32h,64h,64h,64h,32h
	db	5 dup (0)
	db	3,0,7,0,32h
	db	11 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,28h,0,58h,58h,64h,64h,64h
	db	64h,59h,32h,0Bh,1,1,2,0,7,6,0,0,48h,0,0,42h
	db	32h,64h,64h,64h,32h,0,0,0,4Fh,0,3,0,7,0,32h
	db	11 dup (0)
	db	18h,64h,0,0Ch,0,0Ch,0,0,0,28h,0,5Ah,58h,64h,64h,64h
	db	64h,60h,34h,0Bh,1,1,2,0,7,6,0,0,48h,0,0,42h
	db	32h,64h,64h,64h,32h,0,0,0,4Fh,0,3,0,7,0,32h
	db	11 dup (0)
	db	20h,64h,0,0Ch,0,0Ch,0,0,0,28h,0,59h,59h,64h,64h,64h
	db	64h,0FFh
w_D214A	db	8,1Ah,0
	db	'Door opens'
	db	5,0,1,0,7,32h,0Bh,0,0,5,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	49h
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,3Eh,32h,0,0,3Ch,64h
	db	13 dup (0)
	db	0FFh
w_D21A1	db	8,1Ch,0
	db	'Close door'
	db	5,0,3,1,0,32h,0Bh,0,0,2,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,4Bh,0,0,0,64h
	db	4 dup (0)
	db	32h,0Bh,0,0,1,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,4Bh,0,0,0,64h
	db	4 dup (0)
	db	0FFh
w_D2228	db	8,1Eh,0,42h,75h,7Ah,7Ah,65h,72h,20h,20h,20h,20h,9,0,3
	db	0,24h,32h,0Bh,1,1,2,32h,7,6,0,0,2Fh,0,0,0
	db	32h,64h,64h,64h,32h,0,0,0,32h,0,3,0,7,64h,0,0
	db	0,5,0,0,0,25h,64h,64h,64h,64h,64h,64h,0,0Ch,0,0Ch
	db	0,0,0,28h,0,0,2Ch,64h,64h,64h,64h,39h,22h,0Bh,1,1
	db	2,32h,7,6,0,0,2Fh,0,0,0,32h,64h,64h,64h,32h,0
	db	0,0,32h,0,3,0,7,64h,0,0,0,5,0,0,0,25h
	db	64h,64h,64h,64h,64h,64h,0,0Ch,0,0Ch,0,0,0,28h,0,0
	db	2Ch,64h,64h,64h,64h,0,0FFh
w_D22AF	db	8,20h,0
	db	'CloseDrawr'
	db	5,0,1,1,0,32h,0Bh,0,0,12h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,32h,0,0Ch,0,0Ch,0,0,0,44h,0,0,0,64h
	db	4 dup (0)
	db	32h,0Bh,0,0,1,0,7,0,0,0,0FFh
w_D2306	db	8,22h,0
	db	'PhoneRings'
	db	5,0,1,0,2Dh,32h,0Bh,0,0,33h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	28h
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch
	db	5 dup (0)
	db	1Eh,1Eh,64h,64h,64h,64h
	db	11 dup (0)
	db	0FFh
w_D235D	db	8,24h,0,48h,69h,74h,20h,20h,20h,20h,20h,20h,20h,5,0,3
	db	1,24h,35h,10h,0,0,30h,0,7,8,0,0,26h,2Ch,3Eh,0
	db	2Dh,15h,0,32h,32h,0,0,0,58h,7,3,21h,0,22h,32h,0
	db	0,23h,16h,1Eh,3Eh,2Dh,4Ch,37h,29h,1Dh,64h,64h,1Bh,0Ch,1Bh,0Ch
	db	0,0,0,22h,49h,0,0,29h,64h,0,0,24h,2Fh,10h,0,0
	db	30h,0,7,8,0,0,26h,2Ch,3Eh,0,2Dh,15h,0,32h,32h,0
	db	0,0,58h,7,3,21h,0,22h,32h,0,0,23h,15h,1Eh,3Eh,2Dh
	db	4Ch,37h,29h,1Dh,64h,64h,1Bh,0Ch,1Bh,0Ch,0,0,0,22h,49h,0
	db	0,29h,64h,0,0,0,0FFh
w_D23E4	db	8,26h,0,54h,6Fh,73h,73h,20h,20h,20h,20h,20h,20h,5,0,3
	db	1,18h,32h,10h,0,0,18h,0,7,0Ah,0,0,27h,33h,48h,44h
	db	14h,32h,14h,14h,14h
	db	5 dup (0)
	db	3,16h,7,0,32h,0,0,1Eh
	db	8 dup (0)
	db	64h,64h,1Bh,0Ch,1Bh,0Ch,0,0,0,24h,35h,3Ah,32h,50h,64h,46h
	db	0,1Ch,32h,10h,0,0,18h,0,7,0Ah,0,0,27h,38h,47h,3Ah
	db	14h,32h,14h,14h,14h
	db	5 dup (0)
	db	3,16h,7,0,32h,0,0,1Eh
	db	8 dup (0)
	db	64h,64h,1Bh,0Ch,1Bh,0Ch,0,0,0,2Fh,35h,39h,1Eh,50h,64h,46h
	db	0,0,0FFh
w_D246B	db	8,28h,0,42h,72h,61h,6Bh,69h,6Eh,67h,20h,20h,20h,0,5,3
	db	0,24h,2Bh,10h,1,0,0,59h,7,7,1,0,2Ch,40h,40h,3Ch
	db	30h,9,32h,32h,32h,62h,64h,0,5Fh,0,9,1Bh,0Ah,1Eh,14h,0
	db	0,10h,18h,18h,50h,58h,64h,60h,5Ah,12h,50h,50h,5Bh,0Ch,1Bh,0Ch
	db	4,1,10h,0Ah,12h,4Ah,3Ch,38h,50h,60h,64h,30h,39h,10h,1,0
	db	0,50h,7,7,1,0,29h,42h,3Bh,3Ch,31h,0,35h,32h,32h,62h
	db	64h,0,55h,0,9,27h,0Ah,0Fh,14h,0,0,8,20h,1Ch,59h,58h
	db	55h,44h,1Ah,12h,3Ch,50h,70h,9,5Bh,0Ch,4,1,0Ch,0Eh,12h,4Eh
	db	3Ch,30h,4Ah,5Ah,64h,24h,0FFh
w_D24F2	db	8,2Ah,0,41h,63h,6Fh,75h,50h,69h,61h,6Eh,6Fh,31h,1,5,0Fh
	db	0,24h,32h,10h,1,0,0,4Bh,7,3,0,0,0Bh,0Ch,11h,0
	db	46h,3Dh,36h,32h,32h,40h,3,39h,4Ch,0,6,0Fh,9,1Eh,50h,0
	db	2,0,2,0Fh,5Dh,60h,46h,3Ch,1Bh,10h,64h,5Fh,5Bh,0Ch,1Bh,0Ch
	db	3,2,1,0Bh,28h,56h,44h,64h,5Ah,56h,0,50h,16h,0Ah,1,0
	db	0,4Bh,7,3,0,0,0Bh,0Ch,11h,0,46h,3Dh,36h,32h,32h,40h
	db	3,28h,46h,0,8,0Ah,0Bh,19h,15h,0,1,0,7,1Dh,64h,60h
	db	61h,3Ch,2Dh,0,23h,5Fh,40h,8,1Bh,0Ch,1,0,1,0Ah,20h,64h
	db	64h,64h,5Ah,42h,0,24h,3Ah,10h,1,0,2Bh,44h,7,3,0,0
	db	0Bh,0Ch,11h,0,46h,3Dh,36h,32h,32h,40h,3,2Ch,46h,0,8,0Fh
	db	0Ah,19h,64h,1,1,1,2,0Fh,5Dh,60h,46h,3Ch,1Bh,10h,28h,5Fh
	db	40h,5,1Bh,0Ch,2,2,0,0Ah,35h,59h,46h,64h,4Fh,24h,0,31h
	db	32h,6,0,0,14h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	0Bh,0,7
	db	13 dup (0)
	db	50h,64h,5Bh,0Ch,3Bh,6
	db	6 dup (0)
	db	64h,0,0,0,63h,0FFh
w_D25EC	db	8,2Ch,0
	db	'Contrabass'
	db	2,0,3,0,24h,39h,10h,1,0,2Ch,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,4Ah,4,1Bh,0Ch,0,0,2,4,8,8,4Ah,53h,5Ch,62h
	db	64h,24h,32h,10h,1,0,0,4Fh,7,7,3,0,0Fh,0Eh,21h,64h
	db	1Ah,25h,2Ch,32h,31h,3Eh,0Bh,2Ah,57h,0,0Ah,26h,0Ah,0Ah,18h,0
	db	0,11h,18h,18h,51h,58h,1Ch,30h,3Ah,13h,55h,64h,5Bh,0Ch,1Bh,0Ch
	db	0,1,11h,0Ah,13h,19h,44h,38h,50h,5Fh,64h,24h,0FFh
w_D2673	db	8,2Eh,0
	db	'Harp 1    '
	db	2,2,7,0,24h,35h,0Fh,1,0,2Ah,3Ch,7,0,0,1,0Ah
	db	7,16h,0,32h,42h,33h,32h,32h,0,0,0,26h,11h,8,16h,0Ah
	db	3Eh,1Eh,1,2,1,13h,22h,64h,5Fh,5Bh,4Ch,36h,0,64h,64h,5Ch
	db	0Ch,10h
	db	4 dup (0)
	db	34h,47h,64h,50h,64h,0,0,0,24h,32h,0Fh,1,0,0,3Ch,7
	db	3,0,1,0Ah,7,16h,0,32h,42h,33h,32h,32h,3Eh,0,43h,27h
	db	11h,8,16h,0Ah,32h,1Bh,1,2,1,23h,22h,64h,5Fh,5Bh,4Ch,36h
	db	0,51h,64h,5Ch,0Ch,59h,0Ch,3,0,5,9,47h,64h,50h,64h,56h
	db	28h,0,24h,2Eh,0Fh,1,0,27h,3Ch,7,0,0,1,0Ah,7,16h
	db	0,32h,42h,33h,32h,32h,0,0,0,26h,11h,8,16h,0Ah,3Eh,46h
	db	1,2,1,13h,22h,64h,5Fh,5Bh,4Ch,36h,0,64h,5Eh,5Ch,9,10h
	db	0Ch,0,0,0,43h,47h,64h,50h,64h,0,0,0,24h,32h,0Bh,0FFh
w_D2736	db	8,30h,0
	db	'Flute 2   '
	db	2,0,3,0,24h,32h,10h,1,1,1Ah,0,7,2,2,2,9
	db	0Bh,2Bh,0,1Bh,26h,2Ch,32h,32h,40h,16h,0,38h,0,0Ah,27h,0Bh
	db	38h,56h,0,0,0,17h,29h,33h,5Ah,58h,33h,2Ch,1Ah,64h,64h,5Bh
	db	0Ch,1Bh,0Ch,0,4,0,0,0,54h,2Eh,41h,51h,64h,0,24h,32h
	db	10h,1,1,0,0,7,2,2,2,9,0Bh,2Bh,0,1Bh,26h,2Ch
	db	32h,32h,40h,16h,2Ch,38h,0,0Ah,27h,0Bh,38h,56h,0,0,0,17h
	db	29h,33h,5Ah,58h,33h,2Ch,1Ah,55h,5Fh,5Bh,0Ch,1Bh,0Ch,3,4,0Dh
	db	4,0Ah,10h,2Eh,35h,46h,5Dh,62h,24h,0FFh
w_D27BD	db	8,32h,0,53h,74h,72h,69h,6Eh,67h,73h,20h,20h,20h,7,2,3
	db	0,24h,39h,10h,1,0,0,54h,7,7,3,4,9,0Ah,18h,0
	db	26h,2Ch,30h,32h,32h,3Eh,1Dh,29h,55h,0,9,27h,0Ah,0Fh,15h,0
	db	0,12h,20h,1Ch,59h,58h,55h,44h,1Ah,12h,4Ch,64h,70h,9,1Bh,0Ch
	db	4,1,0Ch,0Eh,12h,1Ch,3Ch,30h,4Ah,5Ah,64h,24h,2Bh,0Fh,1,0
	db	0,60h,7,7,3,3,0Ch,0Ch,18h,0,1Bh,26h,2Eh,32h,32h,42h
	db	1Ah,25h,4Bh,0,9,1Bh,0Ah,1Eh,15h,0,0,10h,18h,18h,50h,58h
	db	64h,60h,5Ah,12h,4Ch,64h,5Bh,0Ch,1Bh,0Ch,4,1,10h,0Ah,12h,18h
	db	3Ch,38h,50h,60h,64h,24h,0FFh
w_D2844	db	8,34h,0,43h,6Fh,77h,62h,65h,6Ch,6Ch,20h,20h,20h,5,0,1
	db	1,1Fh,32h,0Bh,0,0,10h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,4Bh,0,0,0,64h
	db	14 dup (0)
	db	0FFh
w_D289B	db	8,36h,0
	db	'Wood Block'
	db	5,0,1,1,15h,32h,0Bh,0,0,11h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,4Bh,0,0,0,64h
	db	14 dup (0)
	db	0FFh
w_D28F2	db	8,38h,0
	db	'Pizzicato '
	db	2,2,3,0,24h,2Bh,10h,1,0,29h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	0Bh,1Bh,7
	db	13 dup (0)
	db	64h,5Fh,7Fh,0Ch,21h,7
	db	5 dup (0)
	db	41h,46h,64h,64h,64h,0,24h,32h,10h,1,1,0,16h,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h,40h,5,36h,1Fh,0,7,25h,7,4Bh,32h,3
	db	0,0Ah,1Dh,1,3Ch,64h,64h,30h,61h,1Ch,50h,64h,7Fh,0Ah,1Bh,0Ch
	db	0,0,1,20h,1,3Eh,41h,64h,54h,64h,0,24h,0FFh
w_D2979	db	8,3Ah,0
	db	'Steel Drum'
	db	1,0,3,0,24h,38h,10h,1,0,0,0Dh,7,5,0,0,0
	db	1,0,0,32h,5Ah,2,32h,32h,41h,9,25h,4Eh,16h,8,77h,3
	db	64h,3Ah,0,0,0,5,28h,41h,2Ah,64h,12h,8,0,64h,47h,5Bh
	db	0Ch,1Bh,0Ch,1,1,1,6,20h,55h,4Eh,64h,58h,48h,0,24h,2Ch
	db	10h,1,0,0,0Dh,7,5,0,0,0,1,0,0,32h,5Ah,2
	db	32h,32h,41h,9,25h,4Dh,1Bh,8,77h,3,64h,3Ah,0,0,0,5
	db	28h,41h,2Ah,64h,12h,8,0,64h,47h,5Bh,0Ch,1Bh,0Ch,1,1,1
	db	6,20h,55h,4Eh,64h,58h,48h,0,24h,0FFh
w_D2A00	db	8,3Ch,0
	db	'Flute 2   '
	db	2,0,3,0,24h,32h,10h,1,1,1Ah,0,7,2,2,2,9
	db	0Bh,2Bh,0,1Bh,26h,2Ch,32h,32h,40h,16h,0,38h,0,0Ah,27h,0Bh
	db	38h,56h,0,0,0,17h,29h,33h,5Ah,58h,33h,2Ch,1Ah,64h,64h,5Bh
	db	0Ch,1Bh,0Ch,0,4,0,0,0,54h,2Eh,41h,51h,64h,0,24h,32h
	db	10h,1,1,0,0,7,2,2,2,9,0Bh,2Bh,0,1Bh,26h,2Ch
	db	32h,32h,40h,16h,2Ch,3Ch,0,0Ah,27h,0Bh,38h,56h,0,0,0,17h
	db	29h,33h,5Ah,58h,33h,2Ch,1Ah,55h,5Fh,5Bh,0Ch,1Bh,0Ch,3,4,0Dh
	db	4,0Ah,10h,2Eh,35h,46h,5Dh,62h,24h,0FFh
w_D2A87	db	8,3Eh,0
	db	'Fretless 2'
	db	2,0,3,0,24h,2Ah,10h,1,1,23h,58h,7,3,0,0,0Eh
	db	0Eh,0Dh,0,18h,27h,2Eh,32h,32h,3Eh,6,42h,41h,0Eh,0Ah,1Eh,0Ah
	db	19h
	db	4 dup (0)
	db	11h,2Eh,24h,3Fh,44h,4Dh,26h,14h,64h,5Fh,7Fh,9,1Bh,0Ch,3,0
	db	0,4,0Eh,5Dh,28h,4Eh,5Ch,64h,0,30h,32h,10h,1,1,0,4Dh
	db	7,3,0,0,0Eh,0Eh,0Dh,0,18h,27h,2Eh,32h,32h,3Eh,6,3Dh
	db	41h,0Fh,0Ah,1Eh,0Ah,19h
	db	4 dup (0)
	db	11h,2Eh,24h,3Fh,44h,4Dh,26h,14h,52h,60h,7Fh,9,1Bh,0Ch,3,0
	db	0,4,0Eh,5Ah,28h,64h,5Ch,64h,0,24h,0FFh
w_D2B0E	db	8,40h,0,43h,61h,62h,61h,73h,61h,20h,20h,20h,20h,5,0,1
	db	1,1Ah,32h,0Bh,0,0,13h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,4Bh,0,0,0,64h,0,0
	db	0FFh
w_D2B59	db	8,42h,0
	db	'Clarinet 1'
	db	1,2,7,0,24h,32h,10h,1,0,0,0,7,2,1,0,0Ah
	db	0Eh,36h,36h,24h,2Ch,32h,32h,2Dh,40h,0Ch,22h,50h,0Ah,8,22h,0Ah
	db	0Ah,48h,0,2,0Bh,16h,1Bh,32h,64h,1Bh,30h,3Dh,45h,48h,60h,7Fh
	db	0Bh,1Bh,0Bh,3,3,8,6,0Ch,10h,36h,39h,4Dh,5Bh,64h,4Ch,0Dh
	db	10h,1,0,0,0,7,2,1,0,0Ah,0Eh,36h,36h,24h,2Ch,32h
	db	32h,2Dh,40h,0Ch,23h,64h,0Ah,8,22h,0Ah,0Ah,48h,0,2,0Bh,16h
	db	1Bh,32h,64h,1Bh,30h,3Dh,45h,19h,64h,7Fh,0Bh,1Bh,0Ch,0,3,7
	db	16h,23h,37h,36h,39h,64h,3Eh,2Bh,24h,34h,10h,1,0,19h,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,60h,7Ah,2,12h
	db	4 dup (0)
	db	16h,2Eh,21h,36h,63h,64h,55h,0,24h,32h,0Bh,0FFh
w_D2C1C	db	8,44h,0,4Dh,75h,74h,48h,69h,43h,6Fh,6Eh,67h,61h,5,0,1
	db	1,22h,32h,0Bh,0,0,0Bh,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,4Bh,0,0,0,64h
	db	14 dup (0)
	db	0FFh
w_D2C73	db	8,46h,0
	db	'Open HiHat'
	db	5,0,1,1,32h,38h,0Bh,0,0,5,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	13 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,2Dh,50h,0,0,64h,50h
	db	13 dup (0)
	db	0FFh
w_D2CCA	db	8,48h,0,53h,79h,6Eh,42h,72h,61h,73h,73h,34h,62h,7,0,3
	db	0,24h,37h,10h,1,1,0,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h,40h,0Ch,23h,2Ch,0Ah,9,33h,0Ah,3Ch,1Eh,2
	db	3,0Fh,4,20h,2Dh,39h,52h,1Fh,61h,3Ah,5Fh,62h,5Bh,0Ch,1Bh,0Ch
	db	2,4,6,0Ah,0Ah,11h,3Ah,3Ch,5Ch,64h,64h,24h,2Eh,10h,1,1
	db	0,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h,3Eh,0Ch,31h,2Ch,0Ah,9,33h,0Ah,3Ch,1Eh,2
	db	0,0Fh,4,20h,2Dh,39h,52h,1Fh,61h,3Ah,5Fh,62h,5Bh,0Ch,1Bh,0Ch
	db	2,4,0,5,0Ah,11h,3Ah,54h,5Fh,64h,64h,24h,0FFh
w_D2D51	db	8,4Ah,0
	db	'Typewriter'
	db	5,0,1,1,18h,32h,0Bh,0,0,5Ch,0,7
	db	7 dup (0)
	db	32h,32h,32h,32h,32h
	db	5 dup (0)
	db	3,0,7
	db	4 dup (0)
	db	16h
	db	8 dup (0)
	db	64h,64h,0,0Ch,0,0Ch,0,0,0,38h,0,0,23h,64h,0,0
	db	0FFh
b_D2D9C	db	0
b_D2D9D	db	0
b_D2D9E	db	0
; variables in the uninitialised BSS segment that follows
b_D2DA0	equ	byte ptr $+1
w_D2DA2	equ	word ptr $+3
w_D2DB6	equ	word ptr $+23
w_D2DB8	equ	word ptr $+25
w_D2DC4	equ	word ptr $+37
w_D2DDA	equ	word ptr $+59
w_D2DE6	equ	word ptr $+71
w_D2DFA	equ	word ptr $+91
w_D2DFC	equ	word ptr $+93
w_D2E08	equ	word ptr $+105
w_D2E2A	equ	word ptr $+139
w_D2E4C	equ	word ptr $+173
w_D2E6E	equ	word ptr $+207
w_D2E90	equ	word ptr $+241
b_D2EB2	equ	byte ptr $+275
b_D2EB4	equ	byte ptr $+277
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'RolandMT-32g15-10-90'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	2F00h		; bytes from DATA to the stack
drv_first_slot	db	100
	db	0
drv_count	dw	11		; number of exports
drv_exports	label	word
	dw	offset rsnd_init	; slot 100
	dw	offset rsnd_play_sound	; slot 101
	dw	offset rsnd_shutdown	; slot 102
	dw	offset rsnd_tick	; slot 103
	dw	offset rsnd_nop104	; slot 104
	dw	offset rsnd_get_ticks	; slot 105
	dw	offset rsnd_nop106	; slot 106
	dw	offset rsnd_nop107	; slot 107
	dw	offset rsnd_nop108	; slot 108
	dw	offset rsnd_nop109	; slot 109
	dw	offset rsnd_nop110	; slot 110
old_int8	dw	0
w_004A	dw	0
old_int0a	dw	0
w_004E	db	0,0,0
timer_mode	db	0,0
tick_div	db	0
timer_hooked	db	0
saved_ss	dw	0
saved_sp	dw	0
tick_count	dw	0

; ----------------------------------------------------------------------------
; hook_interrupts
; Save and replace the int 0Ah (IRQ 2) vector, save int 8 and start the 60 Hz timer.
; ----------------------------------------------------------------------------
hook_interrupts:
	cmp	byte ptr cs:timer_hooked, 0
	jne	L_00AC
	cli
	mov	byte ptr cs:timer_hooked, 0FFh
	push	ds
	xor	ax, ax
	mov	ds, ax
	mov	bx, word ptr ds:[28h]
	mov	cx, word ptr ds:[2Ah]
	mov	word ptr cs:old_int0a, bx
	mov	word ptr cs:w_004E, cx
	lea	ax, irq2_isr
	mov	word ptr ds:[28h], ax
	mov	word ptr ds:[2Ah], cs
	pop	ds
	xor	ax, ax
	mov	byte ptr cs:timer_mode, al
	push	ds
	mov	ds, ax
	mov	bx, word ptr ds:[20h]
	mov	cx, word ptr ds:[22h]
	pop	ds
	mov	word ptr cs:old_int8, bx
	mov	word ptr cs:w_004A, cx
	call	timer_slow
L_00AC:
	sti
	ret

; ----------------------------------------------------------------------------
; unhook_interrupts
; ----------------------------------------------------------------------------
unhook_interrupts:
	cli
	push	ax
	push	bx
	push	cx
	push	ds
	xor	ax, ax
	mov	ds, ax
	mov	bx, word ptr cs:old_int0a
	mov	cx, word ptr cs:w_004E
	mov	word ptr ds:[28h], bx
	mov	word ptr ds:[2Ah], cx
	mov	bx, word ptr cs:old_int8
	mov	cx, word ptr cs:w_004A
	mov	word ptr ds:[20h], bx
	mov	word ptr ds:[22h], cx
	mov	al, 36h
	out	43h, al
	jmp	short L_00E1
L_00E1:
	xor	ax, ax
	out	40h, al
	jmp	short L_00E7
L_00E7:
	mov	al, ah
	out	40h, al
	jmp	short L_00ED
L_00ED:
	mov	byte ptr cs:timer_mode, al
	mov	byte ptr cs:timer_hooked, 0
	pop	ds
	pop	cx
	pop	bx
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
	jmp	short L_0105
L_0105:
	in	al, 40h
	jmp	short L_0109
L_0109:
	mov	bl, al
	in	al, 40h
	jmp	short L_010F
L_010F:
	mov	bh, al
	mov	al, 0
	mov	cx, 100h
L_0116:
	loop	L_0116
	out	43h, al
	jmp	short L_011C
L_011C:
	in	al, 40h
	jmp	short L_0120
L_0120:
	mov	dl, al
	in	al, 40h
	jmp	short L_0126
L_0126:
	mov	dh, al
	sti
	sub	bx, dx
	pop	cx
	ret

; ----------------------------------------------------------------------------
; calibrate_delay
; ----------------------------------------------------------------------------
calibrate_delay:
	mov	word ptr w_D17EC, 0
	mov	cx, 10h
L_0136:
	call	pit_elapsed
	add	word ptr w_D17EC, bx
	loop	L_0136
	mov	bx, word ptr w_D17EC
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	shr	bx, 1
	cmp	bx, 0A28h
	jle	L_0154
	mov	bx, 0A28h
L_0154:
	mov	dx, 0
	mov	ax, 5140h
	div	bx
	inc	ax
	cmp	ax, 3Fh
	jbe	L_0165
	mov	ax, 3Fh
L_0165:
	mov	ah, al
	mov	al, 0
	shl	ax, 1
	shl	ax, 1
	mov	word ptr w_D17EE, ax
	ret

; ----------------------------------------------------------------------------
; L_0171
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0171:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	reset_voices
	call	start_music
	pop	ds
	pop	bp
	ret

; ----------------------------------------------------------------------------
; reset_voices
; ----------------------------------------------------------------------------
reset_voices:
	xor	ax, ax
	mov	word ptr w_D1812, ax
	mov	word ptr w_D1810, ax
	mov	word ptr w_D180E, ax
	mov	byte ptr b_D2DA0, al
	lea	bx, w_D2DA2
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2DC4
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2DE6
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2E08
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2E2A
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2E4C
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2E6E
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	lea	bx, w_D2E90
	mov	byte ptr [bx], al
	mov	byte ptr [bx+1], al
	mov	byte ptr [bx+2], al
	mov	byte ptr [bx+3], al
	mov	byte ptr b_D2DA0, 0FFh
	ret

; ----------------------------------------------------------------------------
; random
; ----------------------------------------------------------------------------
random:
	mov	ax, 9248h
	add	ax, word ptr w_D17F2
	ror	ax, 1
	ror	ax, 1
	ror	ax, 1
	mov	word ptr w_D17F2, ax
	retf

; ----------------------------------------------------------------------------
; sound_tick
; Sequencer step on the driver's own stack (DATA:17E6h).
; ----------------------------------------------------------------------------
sound_tick:
	push	es
	push	si
	push	di
	push	bp
	mov	word ptr cs:saved_ss, ss
	mov	word ptr cs:saved_sp, sp
	mov	ax, DATA
	mov	es, ax
	mov	ss, ax
	mov	sp, 17E6h
	inc	word ptr cs:tick_count
	cmp	byte ptr b_D1814, 0
	je	L_0247
	call	gunfire_tick
L_0247:
	call	far ptr random
	call	voices_tick
	mov	bx, word ptr cs:saved_ss
	mov	ss, bx
	mov	sp, word ptr cs:saved_sp
	pop	bp
	pop	di
	pop	si
	pop	es
	ret

; ----------------------------------------------------------------------------
; timer_slow
; ----------------------------------------------------------------------------
timer_slow:
	cmp	byte ptr cs:timer_mode, 1
	je	L_029C
	cli
	mov	byte ptr cs:timer_mode, 1
	mov	byte ptr cs:tick_div, 3
	push	ax
	push	ds
	sub	ax, ax
	mov	ds, ax
	lea	ax, timer_isr
	mov	word ptr ds:[20h], ax
	mov	word ptr ds:[22h], cs
	pop	ds
	mov	al, 36h
	out	43h, al
	jmp	short L_028D
L_028D:
	mov	ax, 4C90h
	out	40h, al
	jmp	short L_0294
L_0294:
	mov	al, ah
	out	40h, al
	jmp	short L_029A
L_029A:
	pop	ax
	sti
L_029C:
	ret
; Int 8 handler at about 60 Hz.
timer_isr:
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
	je	L_02BD
	cli
	mov	al, 20h
	out	20h, al
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	iret
L_02BD:
	mov	byte ptr cs:tick_div, 3
	pop	ds
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	jmp	dword ptr cs:old_int8

; ----------------------------------------------------------------------------
; start_music
; ----------------------------------------------------------------------------
start_music:
	cmp	byte ptr b_D17E8, 0
	je	L_02D7
	jmp	L_0405
L_02D7:
	call	fx_0
	lea	ax, w_D188F
	call	send_sysex
	lea	ax, w_D18A7
	call	send_sysex
	lea	ax, w_D18C2
	call	send_sysex
	lea	ax, w_D19C6
	call	send_sysex
	lea	ax, w_D19FA
	call	send_sysex
	lea	ax, w_D1A81
	call	send_sysex
	lea	ax, w_D1B7B
	call	send_sysex
	lea	ax, w_D1C75
	call	send_sysex
	lea	ax, w_D1CFC
	call	send_sysex
	lea	ax, w_D1D83
	call	send_sysex
	lea	ax, w_D1DCE
	call	send_sysex
	lea	ax, w_D1E19
	call	send_sysex
	lea	ax, w_D1E64
	call	send_sysex
	lea	ax, w_D1EEB
	call	send_sysex
	lea	ax, w_D1F42
	call	send_sysex
	lea	ax, w_D1FC9
	call	send_sysex
	lea	ax, w_D2050
	call	send_sysex
	lea	ax, w_D214A
	call	send_sysex
	lea	ax, w_D21A1
	call	send_sysex
	lea	ax, w_D2228
	call	send_sysex
	lea	ax, w_D22AF
	call	send_sysex
	lea	ax, w_D2306
	call	send_sysex
	lea	ax, w_D235D
	call	send_sysex
	lea	ax, w_D23E4
	call	send_sysex
	lea	ax, w_D246B
	call	send_sysex
	lea	ax, w_D24F2
	call	send_sysex
	lea	ax, w_D25EC
	call	send_sysex
	lea	ax, w_D2673
	call	send_sysex
	lea	ax, w_D2736
	call	send_sysex
	lea	ax, w_D27BD
	call	send_sysex
	lea	ax, w_D2844
	call	send_sysex
	lea	ax, w_D289B
	call	send_sysex
	lea	ax, w_D28F2
	call	send_sysex
	lea	ax, w_D2979
	call	send_sysex
	lea	ax, w_D2A00
	call	send_sysex
	lea	ax, w_D2A87
	call	send_sysex
	lea	ax, w_D2B0E
	call	send_sysex
	lea	ax, w_D2B59
	call	send_sysex
	lea	ax, w_D2C1C
	call	send_sysex
	lea	ax, w_D2C73
	call	send_sysex
	lea	ax, w_D2CCA
	call	send_sysex
	lea	ax, w_D2D51
	call	send_sysex
	mov	byte ptr b_D17E8, 0FFh
L_0405:
	ret

; ----------------------------------------------------------------------------
; send_sysex
; AX = data bytes (FFh-terminated): send them as a Roland SysEx message
; (header from w_D1889, checksum, F7h) and wait.
; ----------------------------------------------------------------------------
send_sysex:
	push	ax
	lea	ax, w_D1889
	mov	si, ax
L_040D:
	mov	bl, byte ptr [si]
	cmp	bl, 0FFh
	je	L_041A
	call	mpu_data
	inc	si
	jmp	L_040D
L_041A:
	mov	byte ptr b_D17E9, 0
	pop	ax
	mov	si, ax
L_0422:
	mov	bl, byte ptr [si]
	cmp	bl, 0FFh
	je	L_042F
	call	mpu_data_sum
	inc	si
	jmp	L_0422
L_042F:
	mov	bl, byte ptr b_D17E9
	xor	bl, 0FFh
	add	bl, 1
	and	bl, 7Fh
	call	mpu_data
	mov	bl, 0F7h
	call	mpu_data
	mov	cx, word ptr w_D17EE
L_0448:
	nop
	nop
	nop
	loop	L_0448
	ret

; ----------------------------------------------------------------------------
; mpu_command
; BL = command for the MPU-401 command port; AX = 1 if acknowledged (FEh).
; ----------------------------------------------------------------------------
mpu_command:
	mov	dx, word ptr mpu_port
	inc	dx
	mov	cx, 0FFFFh
L_0456:
	in	al, dx
	jmp	short L_0459
L_0459:
	and	al, 40h
	je	L_0463
	loop	L_0456
	xor	ax, ax
	je	L_047F
L_0463:
	mov	al, bl
	out	dx, al
	jmp	short L_0468
L_0468:
	mov	dx, word ptr mpu_port
	mov	cx, 0FFFFh
L_046F:
	in	al, dx
	jmp	short L_0472
L_0472:
	cmp	al, 0FEh
	je	L_047C
	loop	L_046F
	xor	ax, ax
	je	L_047F
L_047C:
	mov	ax, 1
L_047F:
	ret

; ----------------------------------------------------------------------------
; mpu_data_sum
; BL = data byte: add it to the SysEx checksum and send it.
; ----------------------------------------------------------------------------
mpu_data_sum:
	push	bx
	add	bl, byte ptr b_D17E9
	mov	byte ptr b_D17E9, bl
	pop	bx

; ----------------------------------------------------------------------------
; mpu_data
; BL = data byte for the MPU-401 data port.
; ----------------------------------------------------------------------------
mpu_data:
	mov	dx, word ptr mpu_port
	inc	dx
	mov	cx, 0FFFFh
L_0492:
	in	al, dx
	jmp	short L_0495
L_0495:
	and	al, 40h
	je	L_049F
	loop	L_0492
	xor	ax, ax
	je	L_04AB
L_049F:
	mov	al, bl
	mov	dx, word ptr mpu_port
	out	dx, al
	jmp	short L_04A8
L_04A8:
	mov	ax, 1
L_04AB:
	push	ax
	mov	dx, word ptr mpu_port
	add	dx, 1
L_04B3:
	in	al, dx
	jmp	short L_04B6
L_04B6:
	and	al, 80h
	jne	L_04C1
	dec	dx
	in	al, dx
	jmp	short L_04BE
L_04BE:
	inc	dx
	jmp	L_04B3
L_04C1:
	pop	ax
	ret

; ----------------------------------------------------------------------------
; mpu_reset
; Reset the MPU-401 (up to five tries); AX = 0, or 52h if it never acknowledges.
; ----------------------------------------------------------------------------
mpu_reset:
	mov	bl, 5
	cli
L_04C6:
	mov	dx, word ptr mpu_port
	inc	dx
	mov	al, 0FFh
	out	dx, al
	jmp	short L_04D0
L_04D0:
	mov	cx, 0FFFFh
L_04D3:
	in	al, dx
	and	al, 80h
	je	L_04DA
	loop	L_04D3
L_04DA:
	mov	dx, word ptr mpu_port
	in	al, dx
	cmp	al, 0FEh
	je	L_04ED
	dec	bl
	jne	L_04C6
	mov	ax, 52h
	jmp	L_04F0
L_04ED:
	mov	ax, 0
L_04F0:
	sti
	ret
; IRQ 2 handler: read and discard a byte from the MPU-401.
irq2_isr:
	push	ds
	push	dx
	push	ax
	mov	ax, DATA
	mov	ds, ax
	mov	dx, word ptr mpu_port
	inc	dx
	in	al, dx
	jmp	short L_0502
L_0502:
	and	al, 80h
	jne	L_050A
	dec	dx
	in	al, dx
	jmp	short L_050A
L_050A:
	cli
	mov	al, 20h
	out	20h, al
	pop	ax
	pop	dx
	pop	ds
	iret

; ----------------------------------------------------------------------------
; L_0513
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0513:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	bx, word ptr [bp+6]
	call	mpu_command
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; sub_0525
; ----------------------------------------------------------------------------
sub_0525:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	bx, word ptr [bp+6]
	call	mpu_data
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; L_0537
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0537:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	mpu_reset
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; start_voice
; ----------------------------------------------------------------------------
start_voice:
	mov	dl, byte ptr b_D2DA0
	push	dx
	mov	byte ptr b_D2DA0, 0
	mov	byte ptr [bx+1], 0
	mov	byte ptr [bx+2], 0
	mov	byte ptr [bx+3], 0
	mov	byte ptr [bx+0Fh], 0FFh
	mov	byte ptr [bx+0Ch], 64h
	mov	byte ptr [bx+0Dh], 40h
	mov	byte ptr [bx+0Eh], 40h
	mov	word ptr [bx+14h], cx
	mov	word ptr [bx+16h], cx
	mov	word ptr [bx+18h], cx
	mov	word ptr [bx+1Ah], cx
	mov	word ptr [bx+1Ch], 0
	mov	word ptr [bx+1Eh], 0
	mov	byte ptr [bx+7], 0
	mov	word ptr [bx+20h], ax
	mov	byte ptr [bx], 1
	pop	dx
	mov	byte ptr b_D2DA0, dl
	ret
L_0592:
	mov	dl, byte ptr b_D2DA0
	push	dx
	mov	byte ptr b_D2DA0, 0
	mov	byte ptr [bx+1], 0
	mov	byte ptr [bx+0Fh], 0FFh
	mov	byte ptr [bx+2], 0
	mov	cx, word ptr [bx+14h]
	mov	word ptr [bx+16h], cx
	mov	word ptr [bx+18h], cx
	mov	word ptr [bx+1Ah], cx
	mov	word ptr [bx+1Ch], 0
	mov	word ptr [bx+1Eh], 0
	mov	byte ptr [bx+7], 0
	mov	byte ptr [bx], 1
	pop	dx
	mov	byte ptr b_D2DA0, dl
	ret

; ----------------------------------------------------------------------------
; fx_1
; ----------------------------------------------------------------------------
fx_1:
	lea	cx, fx_1_data
	lea	bx, w_D2DA2
	mov	word ptr [bx+16h], cx
	lea	bx, w_D2DC4
	mov	word ptr [bx+16h], cx
	lea	bx, w_D2DE6
	mov	word ptr [bx+16h], cx
	lea	bx, w_D2E08
	mov	word ptr [bx+16h], cx
	lea	bx, w_D2E2A
	mov	word ptr [bx+16h], cx
	lea	bx, w_D2E4C
	mov	word ptr [bx+16h], cx
	lea	bx, w_D2E6E
	mov	word ptr [bx+16h], cx
	ret

; ----------------------------------------------------------------------------
; fx_2
; ----------------------------------------------------------------------------
fx_2:
	mov	ax, 0
	lea	bx, w_D2DA2
	lea	cx, w_D005E
	call	start_voice
	lea	bx, w_D2DC4
	lea	cx, w_D00EE
	call	start_voice
	lea	bx, w_D2DE6
	lea	cx, w_D019C
	call	start_voice
	lea	bx, w_D2E08
	lea	cx, w_D02CC
	call	start_voice
	lea	bx, w_D2E2A
	lea	cx, w_D0354
	call	start_voice
	lea	bx, w_D2E4C
	lea	cx, w_D03F4
	call	start_voice
	lea	bx, w_D2E6E
	lea	cx, w_D0490
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_39
; ----------------------------------------------------------------------------
fx_39:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D12C4
	call	start_voice
	lea	bx, w_D2DC4
	lea	cx, w_D1306
	call	start_voice
	lea	bx, w_D2DE6
	lea	cx, w_D1382
	call	start_voice
	lea	bx, w_D2E08
	lea	cx, w_D13B8
	call	start_voice
	lea	bx, w_D2E2A
	lea	cx, w_D13F0
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_40
; ----------------------------------------------------------------------------
fx_40:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D0946
	call	start_voice
	lea	bx, w_D2DC4
	lea	cx, w_D0956
	call	start_voice
	lea	bx, w_D2E90
	lea	cx, w_D0966
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_41
; ----------------------------------------------------------------------------
fx_41:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D097C
	call	start_voice
	lea	bx, w_D2DC4
	lea	cx, w_D0A5E
	call	start_voice
	lea	bx, w_D2DE6
	lea	cx, w_D0AB2
	call	start_voice
	lea	bx, w_D2E08
	lea	cx, w_D0AF2
	call	start_voice
	lea	bx, w_D2E2A
	lea	cx, w_D0B1C
	call	start_voice
	lea	bx, w_D2E4C
	lea	cx, w_D0BB0
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_42
; ----------------------------------------------------------------------------
fx_42:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D0C82
	call	start_voice
	lea	bx, w_D2DC4
	lea	cx, w_D0D3E
	call	start_voice
	lea	bx, w_D2DE6
	lea	cx, w_D0DA6
	call	start_voice
	lea	bx, w_D2E08
	lea	cx, w_D0E04
	call	start_voice
	lea	bx, w_D2E2A
	lea	cx, w_D0CDE
	call	start_voice
	lea	bx, w_D2E90
	lea	cx, w_D0E40
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_43
; ----------------------------------------------------------------------------
fx_43:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D0E7E
	call	start_voice
	lea	bx, w_D2DC4
	lea	cx, w_D0EEC
	call	start_voice
	lea	bx, w_D2DE6
	lea	cx, w_D0FE8
	call	start_voice
	lea	bx, w_D2E08
	lea	cx, w_D1158
	call	start_voice
	lea	bx, w_D2E90
	lea	cx, w_D11D8
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_3
; ----------------------------------------------------------------------------
fx_3:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D1464
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_4
; ----------------------------------------------------------------------------
fx_4:
	xor	ax, ax
	lea	bx, w_D2E2A
	lea	cx, w_D1472
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_33
; ----------------------------------------------------------------------------
fx_33:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D1480
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_34
; ----------------------------------------------------------------------------
fx_34:
	xor	ax, ax
	lea	bx, w_D2E2A
	lea	cx, w_D1488
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_6
; ----------------------------------------------------------------------------
fx_6:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D1490
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_5
; ----------------------------------------------------------------------------
fx_5:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D14AC
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_7
; ----------------------------------------------------------------------------
fx_7:
	xor	ax, ax
	lea	bx, w_D2E4C
	lea	cx, w_D1512
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_8
; ----------------------------------------------------------------------------
fx_8:
	xor	ax, ax
	lea	bx, w_D2E4C
	lea	cx, w_D151A
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_9
; ----------------------------------------------------------------------------
fx_9:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D14B4
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_10
; ----------------------------------------------------------------------------
fx_10:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D1562
	call	start_voice
	lea	bx, w_D2E2A
	lea	cx, w_D1570
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_13
; ----------------------------------------------------------------------------
fx_13:
	xor	ax, ax
	lea	bx, w_D2E2A
	lea	cx, w_D14BE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_14
; ----------------------------------------------------------------------------
fx_14:
	xor	ax, ax
	lea	bx, w_D2E2A
	lea	cx, w_D14C6
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_15
; ----------------------------------------------------------------------------
fx_15:
	xor	ax, ax
	lea	bx, w_D2E2A
	lea	cx, w_D14CE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_18
; ----------------------------------------------------------------------------
fx_18:
	xor	ax, ax
	lea	bx, w_D2E4C
	lea	cx, w_D14EC
	call	start_voice
	lea	bx, w_D2E90
	lea	cx, w_D1428
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_30
; ----------------------------------------------------------------------------
fx_30:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D1586
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_22
; ----------------------------------------------------------------------------
fx_22:
	xor	ax, ax
	lea	bx, w_D2E90
	lea	cx, w_D14FC
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_23
; ----------------------------------------------------------------------------
fx_23:
	xor	ax, ax
	lea	bx, w_D2DC4
	lea	cx, w_D1508
	call	start_voice
	lea	bx, w_D2E90
	lea	cx, w_D1502
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_24
; ----------------------------------------------------------------------------
fx_24:
	xor	ax, ax
	lea	bx, w_D2E90
	lea	cx, w_D1510
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_19
; ----------------------------------------------------------------------------
fx_19:
	xor	ax, ax
	lea	bx, w_D2DE6
	lea	cx, w_D1522
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_20
; ----------------------------------------------------------------------------
fx_20:
	xor	ax, ax
	lea	bx, w_D2DE6
	lea	cx, w_D152A
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_28
; ----------------------------------------------------------------------------
fx_28:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D1536
	call	start_voice
	lea	bx, w_D2E2A
	lea	cx, w_D154C
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_29
; ----------------------------------------------------------------------------
fx_29:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D157E
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_35
; ----------------------------------------------------------------------------
fx_35:
	mov	bl, 0C7h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bl, 0Ch
	call	mpu_data
	mov	bl, 97h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bl, 30h
	call	mpu_data
	mov	bl, 64h
	jmp	mpu_data

; ----------------------------------------------------------------------------
; fx_36
; ----------------------------------------------------------------------------
fx_36:
	mov	bl, 97h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bl, 30h
	call	mpu_data
	mov	bl, 0
	jmp	mpu_data

; ----------------------------------------------------------------------------
; fx_16
; ----------------------------------------------------------------------------
fx_16:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D14D6
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_17
; ----------------------------------------------------------------------------
fx_17:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D14DE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_12
; ----------------------------------------------------------------------------
fx_12:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D1594
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_11
; ----------------------------------------------------------------------------
fx_11:
	xor	ax, ax
	lea	bx, w_D2E08
	lea	cx, w_D15A2
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_31
; ----------------------------------------------------------------------------
fx_31:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D15AA
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_32
; ----------------------------------------------------------------------------
fx_32:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D15BC
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_44
; ----------------------------------------------------------------------------
fx_44:
	mov	ax, word ptr [bp+8]
	mov	word ptr w_D1810, ax
	mov	ax, word ptr [bp+0Ah]
	mov	word ptr w_D1812, ax
	mov	byte ptr b_D1814, 0FFh
	ret

; ----------------------------------------------------------------------------
; fx_45
; ----------------------------------------------------------------------------
fx_45:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D15BE
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_46
; ----------------------------------------------------------------------------
fx_46:
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D15D6
	jmp	start_voice

; ----------------------------------------------------------------------------
; fx_26
; ----------------------------------------------------------------------------
fx_26:
	mov	word ptr w_D187F, 2Bh
	mov	bx, word ptr [bp+8]
	jmp	L_097B

; ----------------------------------------------------------------------------
; fx_27
; ----------------------------------------------------------------------------
fx_27:
	mov	word ptr w_D187F, 30h
	mov	bx, word ptr [bp+8]
L_097B:
	mov	word ptr w_D1883, bx
	cmp	bx, 0
	je	L_09DB
	mov	ax, word ptr w_D187F
	cmp	ax, word ptr w_D1881
	jne	L_0993
	cmp	bx, word ptr w_D1885
	je	L_09FC
L_0993:
	cmp	word ptr w_D1885, 0
	jne	L_09A8
	mov	bl, 0C7h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bl, 0
	call	mpu_data
L_09A8:
	mov	bl, 97h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bx, word ptr w_D1887
	cmp	bx, -1
	je	L_09C2
	call	mpu_data
	mov	bl, 0
	call	mpu_data
L_09C2:
	mov	bx, word ptr w_D1883
	shl	bx, 1
	add	bx, word ptr w_D187F
	mov	word ptr w_D1887, bx
	call	mpu_data
	mov	bl, 69h
	call	mpu_data
	jmp	L_09FC
L_09DB:
	mov	bl, 97h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bx, word ptr w_D1887
	call	mpu_data
	mov	bl, 0
	call	mpu_data
	mov	word ptr w_D1887, 0FFFFh
	mov	word ptr w_D187F, 0FFFFh
L_09FC:
	mov	ax, word ptr w_D1883
	mov	word ptr w_D1885, ax
	mov	ax, word ptr w_D187F
	mov	word ptr w_D1881, ax
	ret

; ----------------------------------------------------------------------------
; fx_21
; ----------------------------------------------------------------------------
fx_21:
	ret

; ----------------------------------------------------------------------------
; sub_0A0A
; ----------------------------------------------------------------------------
sub_0A0A:
	call	mpu_data
	mov	bl, 7
	call	mpu_data
	mov	bl, 0
	call	mpu_data
	mov	bl, 7Bh
	call	mpu_data
	mov	bl, 0
	jmp	mpu_data

; ----------------------------------------------------------------------------
; fx_37
; ----------------------------------------------------------------------------
fx_37:
	mov	ax, 0
	mov	byte ptr b_D2DA0, al
	mov	bx, 0B1h
	call	sub_0A0A
	mov	bx, 0B2h
	call	sub_0A0A
	mov	bx, 0B3h
	call	sub_0A0A
	mov	bx, 0B4h
	call	sub_0A0A
	mov	bx, 0B5h
	call	sub_0A0A
	mov	bx, 0B6h
	call	sub_0A0A
	mov	bx, 0B7h
	call	sub_0A0A
	mov	bx, 0B9h
	call	sub_0A0A
	ret

; ----------------------------------------------------------------------------
; sub_0A58
; ----------------------------------------------------------------------------
sub_0A58:
	call	mpu_data
	mov	bl, 7
	call	mpu_data
	mov	bl, bh
	jmp	mpu_data

; ----------------------------------------------------------------------------
; fx_38
; ----------------------------------------------------------------------------
fx_38:
	push	di
	mov	bl, 0B1h
	lea	di, w_D2DA2
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B2h
	lea	di, w_D2DC4
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B3h
	lea	di, w_D2DE6
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B4h
	lea	di, w_D2E08
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B5h
	lea	di, w_D2E2A
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B6h
	lea	di, w_D2E4C
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B7h
	lea	di, w_D2E6E
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	bl, 0B9h
	lea	di, w_D2E90
	mov	bh, byte ptr [di+0Ch]
	call	sub_0A58
	mov	byte ptr b_D2DA0, 0FFh
	pop	di
	ret

; ----------------------------------------------------------------------------
; fx_0
; ----------------------------------------------------------------------------
fx_0:
	call	reset_voices
	mov	cx, 9
L_0AD3:
	push	cx
	mov	bl, cl
	or	bl, 0B0h
	mov	byte ptr b_D2D9C, bl
	call	mpu_data
	mov	bl, 7Bh
	call	mpu_data
	mov	bl, 0
	call	mpu_data
	mov	bl, 79h
	call	mpu_data
	mov	bl, 0
	call	mpu_data
	mov	bl, 7
	call	mpu_data
	mov	bl, 64h
	call	mpu_data
	mov	bl, 0Ah
	call	mpu_data
	mov	bl, 40h
	call	mpu_data
	pop	cx
	loop	L_0AD3
	lea	ax, w_D188F
	call	send_sysex
	ret

; ----------------------------------------------------------------------------
; fx_47
; ----------------------------------------------------------------------------
fx_47:
	lea	bx, w_D2DA2
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_48
; ----------------------------------------------------------------------------
fx_48:
	lea	bx, w_D2DC4
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_49
; ----------------------------------------------------------------------------
fx_49:
	lea	bx, w_D2DE6
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_50
; ----------------------------------------------------------------------------
fx_50:
	lea	bx, w_D2E08
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_51
; ----------------------------------------------------------------------------
fx_51:
	lea	bx, w_D2E2A
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_52
; ----------------------------------------------------------------------------
fx_52:
	lea	bx, w_D2E4C
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_53
; ----------------------------------------------------------------------------
fx_53:
	lea	bx, w_D2E6E
	jmp	L_0592

; ----------------------------------------------------------------------------
; fx_54
; ----------------------------------------------------------------------------
fx_54:
	lea	bx, w_D2E90
	jmp	L_0592
; Effect handlers for play_sound(n), n = 0..54
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
	dw	offset fx_23
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
	dw	offset fx_47
	dw	offset fx_48
	dw	offset fx_49
	dw	offset fx_50
	dw	offset fx_51
	dw	offset fx_52
	dw	offset fx_53
	dw	offset fx_54

; ----------------------------------------------------------------------------
; rsnd_init (slot 100)
; init(): calibrate the delay, reset the voices, hook the timers, reset the
; MPU-401 and switch it to UART mode; returns 0, or 52h if there is no MPU.
; ----------------------------------------------------------------------------
rsnd_init:
	push	si
	push	di
	push	bp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	calibrate_delay
	call	reset_voices
	call	hook_interrupts
	call	mpu_reset
	cmp	ax, 0
	jne	L_0BDE
	mov	bl, 3Fh
	call	mpu_command
	call	start_music
	mov	ax, 0
L_0BDE:
	pop	ds
	pop	bp
	pop	di
	pop	si
	retf

; ----------------------------------------------------------------------------
; rsnd_play_sound (slot 101)
; play_sound(n): start effect n.
; ----------------------------------------------------------------------------
rsnd_play_sound:
	push	bp
	mov	bp, sp
	mov	bx, word ptr [bp+6]
	cmp	bx, 36h
	jg	L_0BFC
	push	ds
	mov	ax, DATA
	mov	ds, ax
	shl	bx, 1
	call	word ptr cs:[bx+fx_table]
	pop	ds
L_0BFC:
	pop	bp
	retf

; ----------------------------------------------------------------------------
; rsnd_shutdown (slot 102)
; shutdown(): stop the music, reset the MPU and restore the interrupts; returns w_D17EA.
; ----------------------------------------------------------------------------
rsnd_shutdown:
	push	di
	push	bp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	fx_0
	call	mpu_reset
	call	unhook_interrupts
	mov	ax, word ptr w_D17EA
	mov	word ptr w_D17EA, 0
	pop	ds
	pop	bp
	pop	di
	retf

; ----------------------------------------------------------------------------
; rsnd_tick (slot 103)
; Slot 103: run one sequencer step; returns (and clears) w_D17EA.
; ----------------------------------------------------------------------------
rsnd_tick:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	sound_tick
	mov	ax, word ptr w_D17EA
	mov	word ptr w_D17EA, 0
	pop	ds
	retf

; ----------------------------------------------------------------------------
; rsnd_nop104 (slot 104)
; ----------------------------------------------------------------------------
rsnd_nop104:
	retf

; ----------------------------------------------------------------------------
; rsnd_get_ticks (slot 105)
; Slot 105: number of sequencer ticks so far.
; ----------------------------------------------------------------------------
rsnd_get_ticks:
	mov	ax, word ptr cs:tick_count
	retf

; ----------------------------------------------------------------------------
; rsnd_nop106 (slot 106)
; ----------------------------------------------------------------------------
rsnd_nop106:
	retf

; ----------------------------------------------------------------------------
; rsnd_nop107 (slot 107)
; ----------------------------------------------------------------------------
rsnd_nop107:
	retf

; ----------------------------------------------------------------------------
; rsnd_nop108 (slot 108)
; ----------------------------------------------------------------------------
rsnd_nop108:
	retf

; ----------------------------------------------------------------------------
; rsnd_nop109 (slot 109)
; ----------------------------------------------------------------------------
rsnd_nop109:
	retf

; ----------------------------------------------------------------------------
; rsnd_nop110 (slot 110)
; ----------------------------------------------------------------------------
rsnd_nop110:
	retf

; ----------------------------------------------------------------------------
; random2
; ----------------------------------------------------------------------------
random2:
	mov	ax, word ptr w_D1815
	adc	ax, 7131h
	adc	ax, word ptr cs:tick_count
	mov	word ptr w_D1815, ax
	ret

; ----------------------------------------------------------------------------
; keep_shooting
; Gunfire: start the shot voice if it is idle, else move it to a random place in its tune.
; ----------------------------------------------------------------------------
keep_shooting:
	cmp	word ptr w_D2DA2, 0
	je	L_0C6B
	cmp	word ptr w_D2DA2, 1
	jne	L_0C6A
	mov	ax, word ptr w_D1815
	and	ax, 6
	lea	bx, w_D1877
	add	bx, ax
	mov	bx, word ptr [bx]
	mov	word ptr w_D2DB6, bx
L_0C6A:
	ret
L_0C6B:
	mov	ax, 70h
	mov	word ptr w_D180C, ax
	inc	ax
	inc	ax
	mov	word ptr w_D180A, ax
	call	default_shot_sound
	xor	ax, ax
	lea	bx, w_D2DA2
	lea	cx, w_D08E6
	jmp	start_voice
L_0C86:
	mov	byte ptr b_D1814, 0
	lea	bx, fx_1_data
	mov	word ptr w_D2DB8, bx
	mov	word ptr w_D2DDA, bx
	mov	word ptr w_D2DFC, bx
	mov	word ptr w_D180E, 0
	ret

; ----------------------------------------------------------------------------
; end_shots
; Gunfire: let the shot voice end (its loop goes to the silent effect fx_1_data).
; ----------------------------------------------------------------------------
end_shots:
	lea	bx, fx_1_data
	mov	word ptr w_D2DB8, bx
	ret

; ----------------------------------------------------------------------------
; end_barrage
; Gunfire: let the two rhythm voices end, then set the default shot sound.
; ----------------------------------------------------------------------------
end_barrage:
	lea	bx, fx_1_data
	mov	word ptr w_D2DDA, bx
	mov	word ptr w_D2DFC, bx

; ----------------------------------------------------------------------------
; default_shot_sound
; Gunfire: set the default shot sound (falls into set_shot_sound).
; ----------------------------------------------------------------------------
default_shot_sound:
	mov	al, 45h

; ----------------------------------------------------------------------------
; set_shot_sound
; AL = shot sound, written into the four sound bytes of the shot tune.
; ----------------------------------------------------------------------------
set_shot_sound:
	mov	byte ptr b_D08E9, al
	mov	byte ptr b_D0901, al
	mov	byte ptr b_D0919, al
	mov	byte ptr b_D0931, al
	ret

; ----------------------------------------------------------------------------
; gunfire_tick
; Gunfire, each tick: stop when the level or the second word is 0, else light fire (levels 1-3) or heavy fire (4 and 5).
; ----------------------------------------------------------------------------
gunfire_tick:
	cmp	word ptr w_D1810, 0
	je	L_0C86
	cmp	word ptr w_D1812, 0
	je	L_0C86
	call	random2
	cmp	word ptr w_D1810, 4
	jb	L_0CE4
	call	heavy_gunfire
	jmp	L_0CE7
L_0CE4:
	call	light_gunfire
L_0CE7:
	mov	ax, word ptr w_D1810
	mov	word ptr w_D180E, ax
	ret

; ----------------------------------------------------------------------------
; light_gunfire
; ----------------------------------------------------------------------------
light_gunfire:
	cmp	word ptr w_D180E, 4
	jb	L_0D02
	call	end_shots
	cmp	word ptr w_D180E, 4
	jb	L_0D02
	call	end_barrage
L_0D02:
	call	keep_rhythm
	call	choose_shot_gap
	ret

; ----------------------------------------------------------------------------
; heavy_gunfire
; ----------------------------------------------------------------------------
heavy_gunfire:
	call	keep_shooting
	cmp	word ptr w_D180A, 0
	jne	L_0D1B
	mov	bx, word ptr w_D180C
	mov	word ptr w_D180A, bx
L_0D1B:
	dec	word ptr w_D180A
	cmp	word ptr w_D1810, 5
	je	L_0D3E
	cmp	word ptr w_D180E, 4
	je	L_0D37
	cmp	word ptr w_D180E, 5
	jne	L_0D37
	call	end_barrage
L_0D37:
	call	keep_rhythm
	call	choose_shot_gap
	ret
L_0D3E:
	cmp	word ptr w_D180E, 5
	je	L_0D72
	mov	al, 5Fh
	call	set_shot_sound
	lea	ax, w_D087E
	lea	bx, w_D2DC4
	lea	cx, w_D04BE
	call	start_voice
	xor	ax, ax
	lea	bx, w_D2DE6
	lea	cx, w_D04BE
	call	start_voice
	mov	ax, word ptr w_D180A
	dec	ax
	jns	L_0D6F
	mov	ax, word ptr w_D180C
L_0D6F:
	call	set_rhythm_gap
L_0D72:
	cmp	byte ptr w_D2DE6, 1
	jne	L_0DC5
	call	choose_rhythm
	ret

; ----------------------------------------------------------------------------
; keep_rhythm
; Gunfire: start the rhythm voice if it is idle.
; ----------------------------------------------------------------------------
keep_rhythm:
	cmp	byte ptr w_D2DE6, 0
	jne	L_0DC5
	xor	ax, ax
	lea	bx, w_D2DE6
	lea	cx, w_D04BE
	call	start_voice

; ----------------------------------------------------------------------------
; choose_rhythm
; Gunfire: pick the rhythm voice's next pattern at random for the level.
; ----------------------------------------------------------------------------
choose_rhythm:
	mov	bx, word ptr w_D1810
	dec	bx
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	call	random2
	cmp	word ptr w_D1810, 1
	jne	L_0DB4
	and	ax, 1Eh
	add	ax, bx
	lea	bx, w_D1817
	jmp	L_0DBD
L_0DB4:
	and	ax, 0Eh
	add	ax, bx
	lea	bx, w_D1827
L_0DBD:
	add	bx, ax
	mov	bx, word ptr [bx]
	mov	word ptr w_D2DFA, bx
L_0DC5:
	ret

; ----------------------------------------------------------------------------
; choose_shot_gap
; Gunfire: the gap from the random number, the level and the second word, at most FFh (falls into set_rhythm_gap).
; ----------------------------------------------------------------------------
choose_shot_gap:
	mov	ax, word ptr w_D1815
	and	ax, 0FFh
	inc	ax
	xor	dx, dx
	mov	bx, word ptr w_D1810
	div	bx
	or	ax, 1
	mov	bx, ax
	mov	ax, word ptr w_D1812
	mov	dx, 14h
	mul	dx
	add	ax, bx
	cmp	ax, 0FFh
	jle	set_rhythm_gap
	mov	ax, 0FFh

; ----------------------------------------------------------------------------
; set_rhythm_gap
; AL = gap, written into the rhythm tune.
; ----------------------------------------------------------------------------
set_rhythm_gap:
	mov	byte ptr b_D04BF, al
	ret
	db	0B8h,3,0,0CDh,10h,0BAh,0F5h,17h,0B4h,9,0CDh,21h,0B8h,0,4Ch,0CDh
	db	21h,0

; ----------------------------------------------------------------------------
; notes_off
; ----------------------------------------------------------------------------
notes_off:
	push	bp
	mov	bp, sp
	subw	sp, 6
	mov	byte ptr [bp-2], 0
	jmp	L_0EA8
L_0E10:
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2EB4h
	add	bx, ax
	mov	al, byte ptr [bp-2]
	and	ax, 0FFh
	add	bx, ax
	mov	al, byte ptr [bx]
	mov	byte ptr [bp-4], al
	mov	al, byte ptr [bp-4]
	and	ax, 0FFh
	cmp	ax, 0FFh
	jne	L_0E3A
	jmpnear	L_0EB6
L_0E3A:
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	or	ax, 90h
	mov	byte ptr b_D2D9D, al
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	mov	word ptr [bp-6], ax
	mov	al, byte ptr b_D2D9C
	and	ax, 0FFh
	mov	cx, word ptr [bp-6]
	cmp	cx, ax
	je	L_0E71
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2D9D
	mov	byte ptr b_D2D9C, al
L_0E71:
	mov	al, byte ptr [bp-4]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	xor	ax, ax
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2EB4h
	add	bx, ax
	mov	al, byte ptr [bp-2]
	and	ax, 0FFh
	add	bx, ax
	mov	byte ptr [bx], 0FFh
	inc	byte ptr [bp-2]
L_0EA8:
	mov	al, byte ptr [bp-2]
	and	ax, 0FFh
	cmp	ax, 4
	jge	L_0EB6
	jmp	L_0E10
L_0EB6:
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; note_on
; ----------------------------------------------------------------------------
note_on:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	or	ax, 90h
	mov	byte ptr b_D2D9D, al
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D2D9C
	and	ax, 0FFh
	mov	cx, word ptr [bp-2]
	cmp	cx, ax
	je	L_0EF8
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2D9D
	mov	byte ptr b_D2D9C, al
L_0EF8:
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr [bp+6]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; program_change
; ----------------------------------------------------------------------------
program_change:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	or	ax, 0C0h
	mov	byte ptr b_D2D9D, al
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D2D9C
	and	ax, 0FFh
	mov	cx, word ptr [bp-2]
	cmp	cx, ax
	je	L_0F58
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2D9D
	mov	byte ptr b_D2D9C, al
L_0F58:
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; set_volume
; ----------------------------------------------------------------------------
set_volume:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	or	ax, 0B0h
	mov	byte ptr b_D2D9D, al
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D2D9C
	and	ax, 0FFh
	mov	cx, word ptr [bp-2]
	cmp	cx, ax
	je	L_0FAA
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2D9D
	mov	byte ptr b_D2D9C, al
L_0FAA:
	mov	ax, 7
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; set_bend
; ----------------------------------------------------------------------------
set_bend:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	or	ax, 0E0h
	mov	byte ptr b_D2D9D, al
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D2D9C
	and	ax, 0FFh
	mov	cx, word ptr [bp-2]
	cmp	cx, ax
	je	L_1008
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2D9D
	mov	byte ptr b_D2D9C, al
L_1008:
	xor	ax, ax
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	sp, bp
	pop	bp
	ret

; ----------------------------------------------------------------------------
; set_pan
; ----------------------------------------------------------------------------
set_pan:
	push	bp
	mov	bp, sp
	subw	sp, 2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	or	ax, 0B0h
	mov	byte ptr b_D2D9D, al
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	mov	word ptr [bp-2], ax
	mov	al, byte ptr b_D2D9C
	and	ax, 0FFh
	mov	cx, word ptr [bp-2]
	cmp	cx, ax
	je	L_1064
	mov	al, byte ptr b_D2D9D
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr b_D2D9D
	mov	byte ptr b_D2D9C, al
L_1064:
	mov	ax, 0Ah
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	al, byte ptr [bp+4]
	and	ax, 0FFh
	push	ax
	call	far ptr sub_0525
	add	sp, 2
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; voice_tick
; ----------------------------------------------------------------------------
voice_tick:
	push	bp
	mov	bp, sp
	subw	sp, 8
	push	si
	push	di
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	jne	L_109A
	jmp	L_162F
L_109A:
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+8]
	and	ax, 0FFh
	je	L_10B6
	mov	bx, word ptr [bp+4]
	dec	byte ptr [bx+8]
	mov	al, byte ptr [bx+8]
	and	ax, 0FFh
	jne	L_10B6
	call	notes_off
L_10B6:
	mov	bx, word ptr [bp+4]
	dec	byte ptr [bx]
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	jle	L_10C5
	jmp	L_162F
L_10C5:
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	word ptr [bp-2], ax
	mov	bx, ax
	mov	al, byte ptr [bx]
	cbw
	and	ax, 80h
	jne	L_10DB
	jmp	L_154E
L_10DB:
	mov	bx, word ptr [bp-2]
	cmp	byte ptr [bx], 0F1h
	jg	L_10E6
	jmp	L_154E
L_10E6:
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	jmp	L_1510
	EVEN
L_10F0:
	mov	bx, word ptr [bp+4]
	cmp	word ptr [bx+1Ch], 0
	je	L_10FC
	jmpnear	L_113E
L_10FC:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	cmp	byte ptr [bx], 0
	jne	L_1124
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+18h], ax
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Ch], 0
	jmp	short L_113C
L_1124:
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Ch], ax
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+18h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+16h], ax
L_113C:
	jmp	short L_116E
L_113E:
	mov	bx, word ptr [bp+4]
	dec	word ptr [bx+1Ch]
	mov	bx, word ptr [bp+4]
	cmp	word ptr [bx+1Ch], 0
	jne	L_1162
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+18h], ax
	jmp	short L_116E
L_1162:
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+18h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+16h], ax
L_116E:
	jmp	L_1540
	EVEN
L_1172:
	mov	bx, word ptr [bp+4]
	cmp	word ptr [bx+1Eh], 0
	je	L_117E
	jmpnear	L_11CA
L_117E:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	cmp	byte ptr [bx], 0
	jne	L_11AE
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Ah], ax
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Ch], 0
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Eh], 0
	jmp	short L_11C6
L_11AE:
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Eh], ax
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+1Ah]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+16h], ax
L_11C6:
	jmpnear	L_1206
	EVEN
L_11CA:
	mov	bx, word ptr [bp+4]
	dec	word ptr [bx+1Eh]
	mov	bx, word ptr [bp+4]
	cmp	word ptr [bx+1Eh], 0
	jne	L_11FA
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Ah], ax
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+18h], ax
	jmp	short L_1206
L_11FA:
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+1Ah]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+16h], ax
L_1206:
	jmp	L_1540
	EVEN
L_120A:
	mov	bx, word ptr [bp+4]
	cmp	word ptr [bx+20h], 0
	jne	L_1222
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+14h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+16h], ax
	jmp	L_1252
L_1222:
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+20h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+14h], ax
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+20h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+16h], ax
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+20h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+18h], ax
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+20h]
	mov	bx, word ptr [bp+4]
	mov	word ptr [bx+1Ah], ax
L_1252:
	jmp	L_1540
	EVEN
L_1256:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+5], al
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	push	ax
	call	program_change
	add	sp, 2
	jmp	L_1540
	EVEN
L_127C:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+7], al
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	jmp	L_1540
L_1294:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+10h], al
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+1], al
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+12h], al
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Ah], 1
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 4
	jmp	L_1540
	EVEN
L_12D0:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+6], al
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	jmp	L_1540
L_12E8:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Fh], al
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+2], al
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+9], 1
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 3
	jmp	L_1540
	EVEN
L_1316:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Dh], al
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	push	ax
	call	set_bend
	add	sp, 2
	jmp	L_1540
	EVEN
L_133C:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Ch], al
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	cbw
	push	ax
	call	set_volume
	add	sp, 2
	jmp	L_1540
	EVEN
L_1362:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	byte ptr [bp-6], al
	mov	byte ptr [bp-4], 0
	jmpnear	L_13C7
L_1374:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	word ptr [bp-8], ax
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2EB4h
	add	bx, ax
	mov	al, byte ptr [bp-4]
	cbw
	add	bx, ax
	mov	ax, word ptr [bp-8]
	mov	byte ptr [bx], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+6]
	and	ax, 0FFh
	push	ax
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2EB4h
	add	bx, ax
	mov	al, byte ptr [bp-4]
	cbw
	add	bx, ax
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	push	ax
	call	note_on
	add	sp, 4
	inc	byte ptr [bp-4]
L_13C7:
	mov	al, byte ptr [bp-4]
	cbw
	mov	word ptr [bp-8], ax
	mov	al, byte ptr [bp-6]
	cbw
	mov	cx, word ptr [bp-8]
	cmp	cx, ax
	jge	L_13DC
	jmpnear	L_1374
L_13DC:
	mov	al, byte ptr [bp-6]
	mov	byte ptr [bp-4], al
	jmp	short L_13FF
L_13E4:
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	shl	ax, 1
	shl	ax, 1
	mov	bx, 2EB4h
	add	bx, ax
	mov	al, byte ptr [bp-4]
	cbw
	add	bx, ax
	mov	byte ptr [bx], 0FFh
	inc	byte ptr [bp-4]
L_13FF:
	cmp	byte ptr [bp-4], 4
	jl	L_13E4
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	mov	bx, word ptr [bp+4]
	mov	cl, byte ptr [bx+7]
	mov	word ptr [bp-8], ax
	mov	ax, cx
	cbw
	mov	cx, word ptr [bp-8]
	sub	cx, ax
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+8], cl
	mov	al, byte ptr [bp-6]
	cbw
	add	ax, 3
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], ax
	mov	byte ptr b_D2D9E, 1
	jmp	L_1540
L_1446:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Eh], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+0Eh]
	and	ax, 0FFh
	push	ax
	call	set_pan
	add	sp, 2
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	jmp	L_1540
L_146E:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+11h], al
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+3], al
	mov	bx, word ptr [bp+4]
	cmp	byte ptr [bx+3], 0
	jne	L_149D
	mov	ax, 40h
	push	ax
	call	set_pan
	add	sp, 2
L_149D:
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Bh], 1
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 3
	jmp	L_1540
L_14AE:
	inc	word ptr [bp-2]
	mov	bx, word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	byte ptr [bp-6], al
	inc	word ptr [bp-2]
	call	far ptr random
	mov	al, byte ptr [bp-6]
	cbw
	dec	ax
	and	ax, word ptr w_D17F2
	mov	byte ptr [bp-4], al
	mov	al, byte ptr [bp-4]
	cbw
	mov	bx, word ptr [bp-2]
	add	bx, ax
	mov	al, byte ptr [bx]
	mov	word ptr [bp-8], ax
	mov	al, byte ptr [bp-6]
	cbw
	mov	bx, word ptr [bp-2]
	add	bx, ax
	mov	ax, 1
	add	bx, ax
	mov	al, byte ptr [bp-6]
	cbw
	mov	si, word ptr [bp-2]
	add	si, ax
	mov	al, byte ptr [si]
	cbw
	add	bx, ax
	mov	ax, word ptr [bp-8]
	mov	byte ptr [bx], al
	mov	al, byte ptr [bp-6]
	cbw
	add	ax, 3
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], ax
	jmpnear	L_1540
	db	0E9h,31h,0
	EVEN
L_1510:
	sub	ax, 0FFF2h
	cmp	ax, 0Dh
	jbe	L_151B
	jmpnear	L_1540
L_151B:
	shl	ax, 1
	mov	bx, ax
	jmp	word ptr cs:[bx+w_1524]
w_1524	dw	offset L_14AE
	dw	offset L_146E
	dw	offset L_1446
	dw	offset L_1362
	dw	offset L_133C
	dw	offset L_1316
	dw	offset L_12E8
	dw	offset L_12D0
	dw	offset L_1294
	dw	offset L_127C
	dw	offset L_1256
	dw	offset L_120A
	dw	offset L_1172
	dw	offset L_10F0
L_1540:
	mov	al, byte ptr b_D2D9E
	and	ax, 0FFh
	je	L_154A
	jmp	short L_154E
L_154A:
	jmp	L_10C5
	EVEN
L_154E:
	mov	al, byte ptr b_D2D9E
	and	ax, 0FFh
	je	L_1559
	jmp	L_162A
L_1559:
	mov	bx, word ptr [bp+4]
	mov	ax, word ptr [bx+16h]
	mov	word ptr [bp-2], ax
	mov	bx, word ptr [bp-2]
	inc	word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+4], al
	mov	bx, word ptr [bp-2]
	inc	word ptr [bp-2]
	mov	al, byte ptr [bx]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx], al
	mov	bx, word ptr [bp+4]
	add	word ptr [bx+16h], 2
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+4]
	and	ax, 0FFh
	je	L_1599
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	jne	L_15A0
L_1599:
	call	notes_off
	jmp	L_1628
	EVEN
L_15A0:
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx]
	and	ax, 0FFh
	mov	bx, word ptr [bp+4]
	mov	cl, byte ptr [bx+7]
	mov	word ptr [bp-8], ax
	mov	ax, cx
	cbw
	mov	cx, word ptr [bp-8]
	sub	cx, ax
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+8], cl
	mov	bx, word ptr [bp+4]
	cmp	byte ptr [bx+7], 0
	jge	L_15F2
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	mov	al, byte ptr [bx+b_D2EB4]
	and	ax, 0FFh
	mov	bx, word ptr [bp+4]
	mov	cl, byte ptr [bx+4]
	mov	word ptr [bp-8], ax
	mov	ax, cx
	and	ax, 0FFh
	mov	cx, word ptr [bp-8]
	cmp	cx, ax
	jne	L_15F2
	jmp	short L_160C
L_15F2:
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+6]
	and	ax, 0FFh
	push	ax
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+4]
	and	ax, 0FFh
	push	ax
	call	note_on
	add	sp, 4
L_160C:
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+4]
	mov	word ptr [bp-8], ax
	mov	al, byte ptr b_D2EB2
	and	ax, 0FFh
	mov	bx, ax
	shl	bx, 1
	shl	bx, 1
	mov	ax, word ptr [bp-8]
	mov	byte ptr [bx+b_D2EB4], al
L_1628:
	jmp	short L_162F
L_162A:
	mov	byte ptr b_D2D9E, 0
L_162F:
	mov	bx, word ptr [bp+4]
	cmp	byte ptr [bx+2], 0
	je	L_166E
	mov	bx, word ptr [bp+4]
	dec	byte ptr [bx+9]
	mov	al, byte ptr [bx+9]
	and	ax, 0FFh
	jne	L_166E
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+0Fh]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+9], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+2]
	mov	bx, word ptr [bp+4]
	add	byte ptr [bx+0Ch], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+0Ch]
	and	ax, 0FFh
	push	ax
	call	set_volume
	add	sp, 2
L_166E:
	mov	bx, word ptr [bp+4]
	cmp	byte ptr [bx+1], 0
	jne	L_167A
	jmpnear	L_16C4
L_167A:
	mov	bx, word ptr [bp+4]
	dec	byte ptr [bx+0Ah]
	mov	al, byte ptr [bx+0Ah]
	and	ax, 0FFh
	jne	L_16B0
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+10h]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Ah], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+1]
	mov	bx, word ptr [bp+4]
	add	byte ptr [bx+0Dh], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+0Dh]
	and	ax, 0FFh
	push	ax
	call	set_bend
	add	sp, 2
L_16B0:
	mov	bx, word ptr [bp+4]
	dec	byte ptr [bx+12h]
	mov	al, byte ptr [bx+12h]
	and	al, al
	jne	L_16C4
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+1], 0
L_16C4:
	mov	bx, word ptr [bp+4]
	cmp	byte ptr [bx+3], 0
	je	L_1703
	mov	bx, word ptr [bp+4]
	dec	byte ptr [bx+0Bh]
	mov	al, byte ptr [bx+0Bh]
	and	ax, 0FFh
	jne	L_1703
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+11h]
	mov	bx, word ptr [bp+4]
	mov	byte ptr [bx+0Bh], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+3]
	mov	bx, word ptr [bp+4]
	add	byte ptr [bx+0Eh], al
	mov	bx, word ptr [bp+4]
	mov	al, byte ptr [bx+0Eh]
	and	ax, 0FFh
	push	ax
	call	set_pan
	add	sp, 2
L_1703:
	inc	byte ptr b_D2EB2
	pop	di
	pop	si
	mov	sp, bp
	pop	bp
	ret
	EVEN

; ----------------------------------------------------------------------------
; voices_tick
; ----------------------------------------------------------------------------
voices_tick:
	cmp	byte ptr b_D2DA0, 0
	jne	L_1718
	jmpnear	L_1772
L_1718:
	mov	byte ptr b_D2EB2, 1
	mov	ax, 2DA2h
	push	ax
	call	voice_tick
	add	sp, 2
	mov	ax, 2DC4h
	push	ax
	call	voice_tick
	add	sp, 2
	mov	ax, 2DE6h
	push	ax
	call	voice_tick
	add	sp, 2
	mov	ax, 2E08h
	push	ax
	call	voice_tick
	add	sp, 2
	mov	ax, 2E2Ah
	push	ax
	call	voice_tick
	add	sp, 2
	mov	ax, 2E4Ch
	push	ax
	call	voice_tick
	add	sp, 2
	mov	ax, 2E6Eh
	push	ax
	call	voice_tick
	add	sp, 2
	mov	byte ptr b_D2EB2, 9
	mov	ax, 2E90h
	push	ax
	call	voice_tick
	add	sp, 2
L_1772:
	ret
CODE	ENDS

BSS	SEGMENT BYTE PUBLIC 'BSS'
	db	353 dup (?)
BSS	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

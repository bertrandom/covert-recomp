; TSOUND.CA - Covert Action sound driver for the Tandy / PCjr sound chip ("Tandy Covert")
;
; Loaded by COVERT as an overlay; exports slots 100-110 (see README "Driver
; interface"). The chip (SN76496 type, port C0h) has three tone voices and a
; noise voice. play_sound(n) starts effect n (0-46) from fx_table; each voice
; (a 29-byte block from voice0) steps through its note list with its own
; volume and pitch envelopes. The sequencer (sound_tick) runs from the timer
; interrupt at about 60 Hz, chaining to the BIOS handler every third tick.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh TSOUND
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/TSOUND.hints)

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:0A10h = DATA:0) while DS references, with DS = DATA,
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
; Voice blocks, 1Dh bytes each: note pointer (+0), pitch step (+2), envelope
; counters and volumes (+4..+1Bh); the fifth block drives the noise voice
voice0	db	29 dup (0)
voice1	db	29 dup (0)
voice2	db	29 dup (0)
voice3	db	29 dup (0)
voice4	db	29 dup (0)
last_noise	db	0
w_D00E2	dw	0
w_D00E4	dw	0
w_D00E6	dw	0
w_D00E8	dw	0
w_D00EA	dw	0
b_D00EC	db	0
b_D00ED	db	0
rand_seed	dw	0
sound_muted	db	0
sound_paused	db	0,0,0
has_tandy_bios	db	0,0,0
tick_div	db	0
fx_2_data	db	0C0h,2,0A0h,12h,0D0h,0Eh,15h,0FEh,0,15h,0FEh,0,2Ah,0FEh,0,7
	db	1Dh,1,7,0BEh,0,7,0A0h,0,7,0FEh,0,15h,1Dh,1,15h,1Dh
	db	1,2Ah,1Dh,1,7,40h,1,7,0D5h,0,7,0A9h,0,7,0EFh,0
	db	15h,40h,1,15h,40h,1,2Ah,40h,1,7,53h,1,7,0E2h,0,7
	db	0BEh,0,7,1Dh,1,0Eh,40h,1,7,1Dh,1,7,0FEh,0,0Eh,53h
	db	1,7,40h,1,7,1Dh,1,0Eh,65h,1,7,53h,1,7,40h,1
	db	0Eh,7Dh,1,7,7Dh,1,7,65h,1,7,0FCh,1,7,0FCh,1,7
	db	3Bh,2,0Eh,0FCh,1,7,0A7h,2,7,3Bh,2,7,0DFh,1,7,53h
	db	1,31h,0FFh,0FFh,0Eh,0FCh,1,7,0D5h,0,0Eh,0C4h,1,0Eh,0E2h,0
	db	0Eh,0ABh,1,7,0FEh,0,7,0FCh,1,7,3Bh,2,0Eh,0FCh,1,7
	db	81h,2,7,3Bh,2,7,0FEh,0,7,0FEh,0,7,1Dh,1,0Eh,0FEh
	db	0,7,53h,1,7,1Dh,1,7,0EFh,0,7,0A9h,0,23h,0FFh,0FFh
	db	7,0CAh,2,7,7Dh,1,0Eh,0FCh,1,7,0D5h,0,0Eh,0C4h,1,0Eh
	db	0E2h,0,0Eh,0ABh,1,7,0FEh,0,7,0FCh,1,7,3Bh,2,0Eh,0FCh
	db	1,7,81h,2,7,3Bh,2,0F3h,0,7,0FEh,0,7,0FEh,0,7
	db	1Dh,1,0Eh,0FEh,0,7,53h,1,7,1Dh,1,7,0EFh,0,7,0A9h
	db	0,31h,0FFh,0FFh,7,0FCh,1,7,1Dh,1,7,0D5h,0,0Eh,0C4h,1
	db	7,0B2h,0,7,0FEh,0,0Eh,0ABh,1,7,0C4h,1,7,0FCh,1,7
	db	1Dh,1,0Eh,0FCh,1,7,40h,1,7,1Dh,1,7,0FEh,0,7,0FCh
	db	1,7,3Bh,2,0Eh,0FEh,0,7,0A7h,2,7,3Bh,2,7,0DFh,1
	db	7,53h,1,23h,0FFh,0FFh,7,65h,1,7,0BEh,0,7,0FCh,1,7
	db	1Dh,1,7,0BEh,0,0Eh,0C4h,1,7,0E2h,0,7,40h,1,0Eh,0ABh
	db	1,7,0D5h,0,7,0FCh,1,7,3Bh,2,0Eh,0FCh,1,7,40h,1
	db	7,1Dh,1,0F3h,1,7,0FCh,1,7,0FCh,1,7,3Bh,2,0Eh,0FCh
	db	1,7,0A7h,2,7,3Bh,2,7,0DFh,1,7,53h,1,23h,0FFh,0FFh
	db	7,0CAh,2,7,7Dh,1,0Eh,0FCh,1,7,0D5h,0,0Eh,0C4h,1,0Eh
	db	0E2h,0,0Eh,0ABh,1,7,0FEh,0,7,0FCh,1,7,3Bh,2,0Eh,0FCh
	db	1,7,81h,2,7,3Bh,2,0F3h,1,80h,3,0Eh,0FCh,1,0
w_D02B7	db	0C0h,2,0A0h,14h,0D0h,0Eh,1Ch,0FCh,1,1Ch,0F8h,3,1Ch,0F8h,3,0Eh
	db	0FCh,1,0Eh,0F8h,3,1Ch,3Bh,2,1Ch,0F8h,3,1Ch,0F8h,3,0Eh,0FCh
	db	1,0Eh,0F8h,3,1Ch,81h,2,1Ch,0F8h,3,1Ch,0F8h,3,0Eh,0FCh,1
	db	0Eh,0F8h,3,1Ch,81h,2,1Ch,0A7h,2,1Ch,0CAh,2,0Eh,7Dh,1,7
	db	0FAh,2,7,0CAh,2,0F3h,0,1Ch,0F8h,3,1Ch,0F8h,3,1Ch,0F8h,3
	db	0Eh,0A7h,2,0Eh,0F8h,3,0F3h,3,0C0h,4,0A0h,12h,0F3h,0,7,0FCh
	db	1,7,0FCh,1,7,3Bh,2,0Eh,0FCh,1,7,0A7h,2,7,3Bh,2
	db	7,0DFh,1,15h,53h,1,23h,1Dh,1,15h,0FEh,0,15h,0E2h,0,0Eh
	db	0D5h,0,0Eh,0A9h,0,7,0D5h,0,7,0FEh,0,7,1Dh,1,7,0A9h
	db	0,7,0BEh,0,7,0E2h,0,7,0FCh,1,7,0FCh,1,7,3Bh,2
	db	0Eh,0FCh,1,7,0A7h,2,7,3Bh,2,7,0DFh,1,15h,53h,1,23h
	db	1Dh,1,15h,7Fh,0,15h,71h,0,0Eh,6Ah,0,0Eh,54h,0,7,6Ah
	db	0,7,8Eh,0,7,7Fh,0,7,0A9h,0,7,54h,0,7,6Ah,0
	db	0B0h,7,0C0h,2,0F3h,1,0C0h,0,0A0h,14h,0D0h,0Ch,0B0h,0FFh,1Ch,0FCh
	db	1,1Ch,0F8h,3,1Ch,0F8h,3,0Eh,0FCh,1,0Eh,0F8h,3,1Ch,3Bh,2
	db	1Ch,0F8h,3,1Ch,0F8h,3,0Eh,0FCh,1,0Eh,0F8h,3,1Ch,81h,2,1Ch
	db	0F8h,3,1Ch,0F8h,3,0Eh,0FCh,1,0Eh,0F8h,3,1Ch,81h,2,1Ch,0A7h
	db	2,1Ch,0CAh,2,0Eh,0FAh,2,7,0FAh,2,7,0CAh,2,80h,3,38h
	db	0F8h,3,0
w_D03DA	db	0A0h,31h,70h,0FEh,0,70h,1Dh,1,70h,40h,1,1Ch,40h,1,1Ch,53h
	db	1,1Ch,65h,1,0Eh,7Dh,1,7,7Dh,1,7,65h,1,70h,0FFh,0FFh
	db	0Eh,0FCh,1,7,0D5h,0,0Eh,0C4h,1,0Eh,0E2h,0,0Eh,0ABh,1,7
	db	0FEh,0,7,0FCh,1,7,3Bh,2,0Eh,0FCh,1,7,81h,2,7,3Bh
	db	2,62h,0FFh,0FFh,7,0CAh,2,7,7Dh,1,0Eh,0FCh,1,7,0D5h,0
	db	0Eh,0C4h,1,0Eh,0E2h,0,0Eh,0ABh,1,7,0FEh,0,7,0FCh,1,7
	db	3Bh,2,0Eh,0FCh,1,7,81h,2,7,3Bh,2,0F3h,0,15h,53h,1
	db	15h,7Dh,1,0Eh,53h,1,15h,1Dh,1,23h,0BEh,0,15h,0FEh,0,15h
	db	0E2h,0,0Eh,0D5h,0,0Eh,0A9h,0,2Ah,0FFh,0FFh,15h,53h,1,15h,7Dh
	db	1,0Eh,53h,1,15h,1Dh,1,23h,0BEh,0,70h,0BEh,0,0F3h,1,7
	db	0FEh,1,7,0FEh,1,7,3Dh,2,0Eh,0FEh,1,7,0AAh,2,7,3Dh
	db	2,7,0E1h,1,7,55h,1,23h,0FFh,0FFh,7,0CDh,2,7,7Eh,1
	db	0Eh,0FEh,1,7,0D6h,0,0Eh,0C6h,1,0Eh,0E3h,0,0Eh,0ADh,1,7
	db	0FFh,0,7,0FEh,1,7,3Dh,2,0Eh,0FEh,1,7,83h,2,7,3Dh
	db	2,7,0FEh,0,7,0FEh,0,7,1Dh,1,0Eh,0FEh,0,7,53h,1
	db	7,1Dh,1,7,0EFh,0,7,0A9h,0,23h,0FFh,0FFh,7,65h,1,7
	db	0BEh,0,0Eh,0FEh,0,7,6Ah,0,0Eh,0E2h,0,0Eh,71h,0,0Eh,0D5h
	db	0,7,7Fh,0,7,0FEh,0,7,1Dh,1,0Eh,0FEh,0,7,40h,1
	db	7,1Dh,1,80h,3,7,0FEh,0,0
w_D0503	db	0A0h,16h,0F3h,0,1Ch,2,0,0F3h,0Bh,7,6,0,7,4,0,0Eh
	db	6,0,7,6,0,7,5,0,0Eh,6,0,0Eh,6,0,7,4
	db	0,7,6,0,7,5,0,7,4,0,0Eh,6,0,7,6,0
	db	7,5,0,7,5,0,7,6,0,23h,0FFh,0FFh,7,6,0,7
	db	4,0,7,6,0,1Ch,0FFh,0FFh,0F3h,1,7,6,0,7,5,0
	db	7,5,0,7,6,0,23h,0FFh,0FFh,7,6,0,7,4,0,7
	db	6,0,1Ch,0FFh,0FFh,0F3h,0,1Ch,0FFh,0FFh,1Ch,6,0,1Ch,0FFh,0FFh
	db	7,6,0,7,5,0,0Eh,6,0,1Ch,0FFh,0FFh,0Eh,6,0,0Eh
	db	5,0,1Ch,0FFh,0FFh,7,6,0,7,4,0,0Eh,6,0,7,6
	db	0,7,5,0,7,5,0,7,6,0,23h,0FFh,0FFh,7,6,0
	db	7,4,0,7,6,0,1Ch,0FFh,0FFh,7,6,0,7,5,0,7
	db	5,0,7,6,0,23h,0FFh,0FFh,7,6,0,7,4,0,7,6
	db	0,1Ch,0FFh,0FFh,0F3h,1,1Ch,0FFh,0FFh,1Ch,6,0,1Ch,0FFh,0FFh,1Ch
	db	6,0,7,6,0,7,5,0,7,5,0,7,6,0,23h,0FFh
	db	0FFh,7,6,0,7,4,0,7,6,0,1Ch,0FFh,0FFh,0F3h,1,80h
	db	3,7,6,0,0
fx_42_data	db	0C0h,0Ah,0A0h,14h,0D0h,0Eh,0F3h,0,16h,0E2h,0,0Bh,0BEh,0,0Bh,0BEh
	db	0,16h,0E2h,0,0Bh,0BEh,0,16h,0A9h,0,0Bh,0A9h,0,2Ch,0BEh,0
	db	0Bh,0BEh,0,0Bh,0BEh,0,16h,0E2h,0,16h,0BEh,0,16h,0E2h,0,0Bh
	db	0BEh,0,16h,0E2h,0,0Bh,0E2h,0,2Ch,0FEh,0,0Bh,0BEh,0,0Bh,0BEh
	db	0,16h,0E2h,0,0Bh,0BEh,0,0Bh,0BEh,0,16h,0E2h,0,0Bh,0BEh,0
	db	16h,0A9h,0,0Bh,0A9h,0,2Ch,0BEh,0,0Bh,0BEh,0,0Bh,0BEh,0,16h
	db	0E2h,0,0Bh,0E2h,0,16h,0FEh,0,0Bh,0FEh,0,58h,1Dh,1,16h,0BEh
	db	0,0A0h,31h,0C0h,3,0F3h,2,16h,71h,0,0Bh,71h,0,16h,7Fh,0
	db	0Bh,7Fh,0,0Bh,8Eh,0,0
w_D067F	db	0C0h,2,0A0h,13h,0D0h,0Eh,0F3h,0,16h,0C4h,1,0Bh,7Dh,1,0Bh,7Dh
	db	1,16h,0C4h,1,0Bh,7Dh,1,16h,53h,1,0Bh,53h,1,2Ch,7Dh,1
	db	0Bh,7Dh,1,0Bh,7Dh,1,16h,0C4h,1,16h,7Dh,1,16h,0C4h,1,0Bh
	db	7Dh,1,16h,0C4h,1,0Bh,0C4h,1,2Ch,0FCh,1,0Bh,7Dh,1,0Bh,7Dh
	db	1,16h,0C4h,1,0Bh,7Dh,1,0Bh,7Dh,1,16h,0C4h,1,0Bh,7Dh,1
	db	16h,53h,1,0Bh,53h,1,2Ch,7Dh,1,0Bh,7Dh,1,0Bh,7Dh,1,16h
	db	0C4h,1,0Bh,0C4h,1,16h,0FCh,1,0Bh,0FCh,1,58h,3Bh,2,16h,7Dh
	db	1,0F3h,2,16h,0C4h,1,0Bh,0C4h,1,16h,0FCh,1,0Bh,0FCh,1,16h
	db	3Bh,2,0
w_D0702	dw	8C0h,31A0h,0ED0h,8916h,0B03h,2FAh,0FA0Bh,1602h
	dw	389h,0FA0Bh,1602h,2A7h,0A70Bh,2C02h,2FAh,0FA0Bh
	dw	0B02h,2FAh,8916h,1603h,2FAh,8916h,0B03h,2FAh
	dw	8916h,0B03h,389h,0F82Ch,0B03h,2FAh,0FA0Bh,1602h
	dw	389h,0FA0Bh,0B02h,2FAh,8916h,0B03h,2FAh,0A716h
	dw	0B02h,2A7h,0FA2Ch,0B02h,2FAh,0FA0Bh,1602h,389h
	dw	890Bh,1603h,3F8h,0F80Bh,4203h,23Bh,3C0h,51A0h
	dw	0FA16h,0C002h,9007h,0F801h,16FFh,2FAh,0B0E0h,0C0FFh
	dw	0F303h,4200h,23Bh,3B42h,0B02h,23Bh,3B16h,0B02h
	dw	2FAh,3B42h,4202h,23Bh,0FA0Bh,1602h,2FAh,0F80Bh
	dw	4203h,23Bh,3B42h,0B02h,23Bh,3B16h,0B02h,2FAh
	dw	3B21h,2102h,2FAh,3B42h,0C002h,0A003h,1651h,2FAh
	dw	7C0h,190h,0FFF8h,0FA16h,0E002h,0FFB0h,3C0h,1F3h
	dw	3B21h,2102h,2FAh,3B0Bh,2
w_D07DC	db	58h,0FFh,0FFh,0F3h,7,0A0h,16h,16h,5,0,0Bh,5,0,0Bh,5,0
	db	16h,5,0,16h,5,0,16h,5,0,0Bh,5,0,0Bh,5,0,16h
	db	5,0,16h,5,0,16h,5,0,16h,5,0,16h,5,0,0Bh,5
	db	0,0Bh,5,0,16h,5,0,16h,5,0,16h,5,0,0Bh,5,0
	db	0Bh,5,0,0F3h,3,21h,5,0,21h,5,0,0Bh,5,0,0
fx_40_data	dw	8C0h,2FA0h,3D0h,190h,0FFFFh,400Ch,0C001h,0A003h
	dw	0D071h,0E00Fh,2E0Ch,0C001h,0A008h,0D02Fh,9003h,0FE03h
	dw	12FFh,153h,3C0h,71A0h,0FD0h,12E0h,140h,8C0h
	dw	2FA0h,3D0h,290h,0FFFFh,6518h,0C001h,0A003h,0D071h
	dw	0E00Fh,5318h,0C001h,0A008h,0D02Fh,9003h,0FF02h,24FFh
	dw	17Dh,3C0h,0A0h,0FD0h,60E0h,165h,71A0h,2F1h
	dw	6560h,1
w_D088F	dw	8C0h,2FA0h,3D0h,190h,0FFFFh,1D0Ch,0C001h,0A003h
	dw	0D071h,0E00Fh,0D0Ch,0C001h,0A008h,0D02Fh,9003h,0FF01h
	dw	12FFh,12Eh,3C0h,71A0h,0FD0h,12E0h,11Dh,8C0h
	dw	2FA0h,3D0h,290h,0FFFFh,5318h,0C001h,0A003h,0D071h
	dw	0E00Fh,4018h,0C001h,0A008h,0D02Fh,9003h,0FF02h,24FFh
	dw	1ABh,3C0h,0A0h,0FD0h,60E0h,193h,2F1h,71A0h
	dw	9360h,1
w_D08F3	dw	0FC0h,4824h,6000h,0FFFFh,0FF30h,10FFh,65h,7210h
	dw	1000h,65h,6C08h,0
w_D090B	db	18h,0FFh,0FFh,0C0h,8,0A0h,2Fh,0D0h,3,30h,3,0,3Ch,0FFh,0FFh,30h
	db	0FFh,0FFh,10h,3,0,10h,3,0,10h,3,0,0C0h,3,0A0h,81h,0D0h
	db	0Fh,0F1h,2,7Fh,3,0,0
fx_43_data	dw	2C0h,13A0h,0ED0h,0F3h,3D09h,1202h,1FEh,0FE12h
	dw	1201h,1FEh,0FE12h,901h,1FEh,3D09h,902h,1FEh
	dw	0AD12h,901h,17Eh,0FE09h,901h,23Dh,0FE12h,1201h
	dw	1FEh,0FE12h,1201h,1FEh,0FE09h,901h,23Dh,0FE09h
	dw	1201h,1ADh,7E09h,901h,2AAh,2C0h,12A0h,0CD0h
	dw	2F1h,12B0h,0AB24h,901h,1C4h,3B09h,902h,2A7h
	dw	7D2Dh,901h,17Dh,4009h,901h,17Dh,1D2Dh,901h
	dw	153h,0C409h,901h,23Bh,532Dh,1201h,153h,7D12h
	dw	2401h,0D5h,0E209h,900h,11Dh,5309h,2D01h,0BEh
	dw	0BE09h,900h,0A0h,0BE09h,900h,0FEh,8E24h,900h
	dw	0A9h,0E209h,900h,11Dh,0A92Dh,900h,153h,0FE09h
	dw	900h,0A0h,0BE09h,0D000h,0B00Eh,0F3FFh,0C001h,0A000h
	dw	917h,11Dh,0FE09h,5A00h,0FFFFh,0D509h,900h,0BEh
	dw	0FF5Ah,12FFh,0B2h,0BE12h,0C000h,0D002h,0A00Ah,0F111h
	dw	2402h,357h,891Bh,1B03h,2FAh,0A712h,1B02h,281h
	dw	0FC09h,2401h,23Bh,5324h,0D001h,90Eh,140h,0FC09h
	dw	901h,281h,0A709h,0D002h,2408h,1ABh,0C41Bh,1B01h
	dw	17Dh,5309h,1B01h,140h,7D09h,901h,0FEh,1D24h
	dw	0D001h,90Eh,0A9h,0E209h,900h,11Dh,5309h,901h
	dw	0A9h,0FE09h,900h,153h,7D09h,0D001h,2406h,1ABh
	dw	0C41Bh,1B01h,17Dh,5312h,1B01h,140h,0FE09h,2400h
	dw	11Dh,0A924h,0D000h,90Eh,0A0h,0FE09h,900h,140h
	dw	5309h,0D001h,2404h,0D5h,0E21Bh,1B00h,0BEh,0A909h
	dw	1B00h,0A0h,0BE09h,900h,7Fh,8E24h,0D000h,90Eh
	dw	54h,7109h,900h,8Eh,0A909h,900h,140h,0FE09h
	dw	900h,50h,5F09h,0C000h,0A000h,0D017h,90Eh,47h
	dw	3F12h,0
w_D0AD6	db	0C0h,2,0A0h,13h,0D0h,0Eh,0F3h,0,9,3Bh,2,12h,0FCh,1,12h,0FCh
	db	1,12h,0FCh,1,12h,0FCh,1,9,0FCh,1,9,3Bh,2,9,0FCh,1
	db	12h,0ABh,1,9,7Dh,1,9,0FCh,1,9,3Bh,2,12h,0FCh,1,12h
	db	0FCh,1,12h,0FCh,1,12h,0FCh,1,9,0FCh,1,9,3Bh,2,9,0FCh
	db	1,12h,0ABh,1,9,7Dh,1,9,0A7h,2,0F3h,5,0C0h,0,0A0h,17h
	db	0D0h,0Eh,9,3Bh,2,9,0FCh,1,5Ah,0FFh,0FFh,9,0ABh,1,9,7Dh
	db	1,5Ah,0FFh,0FFh,12h,65h,1,12h,7Dh,1,0F3h,4,9,1Dh,1,12h
	db	0FEh,0,0
w_D0B49	db	0C0h,2,0A0h,13h,0D0h,0Eh,0F3h,0,24h,0F8h,3,24h,0F8h,3,1Bh,0F8h
	db	3,9,0F8h,3,1Bh,89h,3,9,89h,3,24h,0F8h,3,24h,0F8h,3
	db	24h,89h,3,9,0CAh,2,9,0FAh,2,9,0FAh,2,9,57h,3,0F3h
	db	5,12h,57h,3,12h,57h,3,9,0FAh,2,9,0FCh,1,9,3Bh,2
	db	9,57h,3,12h,57h,3,12h,57h,3,24h,0FAh,2,12h,57h,3,12h
	db	57h,3,9,0FAh,2,9,0FCh,1,9,3Bh,2,9,57h,3,9,57h
	db	3,9,81h,2,9,57h,3,9,3Bh,2,0F3h,4,0C0h,0,0A0h,17h
	db	0D0h,0Eh,9,3Bh,2,12h,0FCh,1,0
w_D0BC2	db	0C0h,5,0A0h,15h,0F3h,0,12h,5,0,0F3h,5Fh,1Bh,0FFh,0FFh,9,5
	db	0,24h,5,0,1Bh,0FFh,0FFh,9,5,0,24h,5,0,1Bh,0FFh,0FFh
	db	9,5,0,1Bh,5,0,9,5,0,24h,5,0,0F3h,4,9,5
	db	0,9,5,0,0
fx_41_data	dw	2C0h,51A0h,3F1h,0ED0h,0A91Bh,900h,0B2h,0A91Bh
	dw	900h,0B2h,0A91Bh,0A00h,0E2h,12A0h,0BE16h,1800h
	dw	0D5h,51A0h,0FE5Ah,900h,153h,2E09h,1201h,10Dh
	dw	0FE12h,5A00h,0E2h,5312h,901h,0FEh,0EF09h,1200h
	dw	0E2h,0D563h,900h,153h,0A91Bh,500h,0BEh,0B204h
	dw	1B00h,0A9h,0BE05h,400h,0B2h,0A91Bh,500h,0BEh
	dw	0B204h,1C00h,0A9h,0E205h,400h,0D5h,12A0h,0BE16h
	dw	1800h,0D5h,51A0h,0FE5Ah,1200h,153h,1D09h,901h
	dw	10Dh,0FE12h,6300h,0E2h,5309h,1201h,0D5h,0E212h
	dw	6300h,0FEh,0E209h,1200h,0D5h,0C909h,900h,0BEh
	dw	0A963h,900h,140h,0A012h,900h,0A9h,0B209h,6300h
	dw	0BEh,5309h,901h,0A9h,0A909h,1200h,0BEh,0D563h
	dw	900h,17Dh,0BE12h,1200h,0D5h,0E27Eh,3600h,0FFFFh
	dw	0A91Bh,500h,0BEh,0B204h,1C00h,0A9h,0BE05h,400h
	dw	0B2h,0A91Dh,500h,0BEh,0B204h,1E00h,0A9h,0E205h
	dw	400h,0D5h,12A0h,0BE1Bh,1F00h,0D5h,51A0h,0FE5Ah
	dw	1200h,153h,0D12h,1201h,0FEh,0E263h,900h,153h
	dw	0D512h,1200h,0E2h,0FE7Eh,0
w_D0D11	dw	33A0h,0FF12h,24FFh,0B2h,0B224h,4100h,0B2h,0FA12h
	dw	2402h,2FAh,0FA36h,2402h,165h,0FA12h,2402h,2FAh
	dw	0FA36h,1202h,165h,6512h,1201h,2FAh,0FA24h,5A02h
	dw	2FAh,1F3h,0B0h,1F1h,7C0h,1D48h,4801h,11Dh
	dw	4048h,4801h,140h,5348h,4801h,153h,7D48h,6C01h
	dw	17Dh,0FF64h,6CFFh,0FFFFh,0C0F2h,0B003h,12FFh,2FAh
	dw	0FA24h,3602h,2FAh,6524h,1201h,2FAh,0FA24h,3602h
	dw	2FAh,6512h,1201h,165h,0B0h,1F1h,7C0h,0AB75h
	dw	1
w_D0D93	dw	3C0h,44A0h,0FF12h,24FFh,153h,5324h,4101h,153h
	dw	0FC0h,881Bh,900h,5Ah,4412h,1200h,2Dh,2212h
	dw	3600h,16h,901Bh,900h,5Ah,3C12h,1200h,32h
	dw	2D12h,3600h,24h,881Bh,900h,5Ah,4412h,1200h
	dw	2Dh,2212h,3600h,1Ch,1F3h,721Bh,900h,4Ch
	dw	3912h,1200h,2Dh,2612h,3600h,1Ch,651Bh,900h
	dw	44h,3212h,1200h,2Bh,2212h,3600h,19h,5A1Bh
	dw	900h,44h,3912h,1200h,2Dh,2212h,3600h,1Ch
	dw	0B41Bh,900h,78h,6512h,1200h,5Ah,4812h,1200h
	dw	2Dh,2412h,1200h,16h,2D12h,1200h,0Bh,0FF64h
	dw	6CFFh,0FFFFh,881Bh,900h,5Ah,4412h,1200h,2Dh
	dw	2212h,3600h,16h,0B41Bh,900h,78h,5A12h,1200h
	dw	48h,3C12h,3600h,2Dh,111Bh,900h,16h,2212h
	dw	1200h,2Dh,4412h,1200h,5Ah,8812h,0
w_D0E71	db	48h,0FFh,0FFh,0F3h,1,0Bh,0FFh,0FFh,0F3h,0,0B0h,12h,0A0h,11h,1Bh,3
	db	0,9,3,0,12h,3,0,12h,3,0,12h,3,0,12h,3,0
	db	24h,0FFh,0FFh,0F3h,2,48h,0FFh,0FFh,0F3h,1,0Bh,0FFh,0FFh,0F3h,0,1Bh
	db	3,0,9,3,0,12h,3,0,12h,3,0,12h,3,0,12h,3
	db	0,24h,0FFh,0FFh,0F3h,5,1Bh,3,0,9,3,0,12h,3,0,12h
	db	3,0,12h,3,0,12h,3,0,12h,3,0,12h,3,0,12h,3
	db	0,12h,3,0,64h,0FFh,0FFh,6Ch,0FFh,0FFh,0F3h,0,1Bh,3,0,9
	db	3,0,12h,3,0,12h,3,0,12h,3,0,12h,3,0,24h,0FFh
	db	0FFh,0F3h,1,1Bh,3,0,9,3,0,12h,3,0,12h,3,0,12h
	db	3,0,12h,3,0,12h,3,0,0
fx_39_data	dw	2C0h,16A0h,0ED0h,5B0Ah,1403h,2FDh,0FD0Ah,0A02h
	dw	2AAh,3D0Ah,0D002h,1408h,8Eh,0A00Ah,0D000h,0A0Eh
	dw	35Bh,0FD14h,0A02h,283h,3D0Ah,0A02h,35Bh,0FD14h
	dw	0A02h,2FDh,0AA0Ah,0A02h,23Dh,8D0h,0BE14h,0A00h
	dw	0D5h,0ED0h,5B0Ah,0D003h,1408h,0BEh,0ED0h,5B0Ah
	dw	0A03h,2FDh,1F3h,8D0h,0BE28h,2800h,0D5h,180h
	dw	0BE28h,0F000h
w_D0F6E	dw	2C0h,16A0h,0ED0h,0AB0Ah,1401h,17Dh,0FA0Ah,0A02h
	dw	2A7h,3B0Ah,0D002h,1408h,0BEh,0D50Ah,0D000h,0A0Eh
	dw	1ABh,7D14h,0A01h,140h,1D0Ah,0A01h,1ABh,7D14h
	dw	0A01h,2FAh,0A70Ah,0A02h,23Bh,8D0h,1D14h,0A01h
	dw	140h,0ED0h,0FC0Ah,0D001h,1408h,0FEh,0ED0h,0AB0Ah
	dw	0A01h,17Dh,1F3h,8D0h,1D28h,2801h,140h,180h
	dw	1D28h,0F001h
w_D0FD2	dw	0C0h,17A0h,0ED0h,570Ah,1403h,2FAh,0FA0Ah,0A02h
	dw	2A7h,3B0Ah,1402h,389h,0F80Ah,0A03h,357h,0FA14h
	dw	0A02h,281h,3B0Ah,0A02h,357h,0FA14h,0A02h,2FAh
	dw	0A70Ah,0A02h,23Bh,8914h,0A03h,3F8h,570Ah,1403h
	dw	2FAh,570Ah,0A03h,2FAh,1F3h,8D0h,0AB28h,2801h
	dw	1DFh,180h,0AB28h,0F001h
w_D102A	db	0C0h,4,0A0h,15h,0D0h,0Eh,14h,2,0,14h,6,0,14h,2,0,0Fh
	db	6,0,5,6,0,14h,6,0,14h,2,0,0Ah,6,0,0Ah,6
	db	0,0F3h,3,0D0h,8,28h,0FFh,0FFh,28h,0FFh,0FFh,80h,1,28h,0FFh,0FFh
	db	0F0h
w_D105B	db	7Fh,0FFh,0FFh
b_D105E	db	7Fh,0FFh,0FFh,0F0h
fx_46_data	db	0A0h,12h,0D0h,0Dh,0F3h,1,0A0h,12h,0C0h,5,0D0h,0Dh,8,40h,1,8
	db	1Dh,1,8,0E2h,0,8,0C9h,0,8,0A0h,0,0F3h,0,5,54h,0
	db	0F3h,7,0Ah,54h,0,0F3h,3,0Ch,54h,0,0F3h,1,0F1h,3,0A0h,31h
	db	0B0h,28h,2Dh,54h,0,0,0A0h,12h,0C0h,5,0D0h,0Dh,0F3h,0,8,77h
	db	0,0F3h,7,8,7Fh,0,8,0B2h,0,8,2Eh,1,8,0ABh,1,8
	db	65h,1,8,0FEh,0,0,0A0h,1Eh,0C0h,0Eh,5,0BFh,3,5,89h,3
	db	5,0DFh,1,5,0F8h,3,5,27h,3,0,0A0h,1Eh,0C0h,0Eh,5,0DFh
	db	1,5,27h,3,5,0ABh,1,5,0CAh,2,5,3Bh,2,0,0A0h,1Eh
	db	0C0h,0Eh,5,57h,3,5,89h,3,0,0F1h,2,0A0h,1Fh,0C0h,0Bh,0D0h
	db	4,14h,54h,0,0A0h,41h,0C0h,5,0D0h,0Eh,14h,8Eh,0,0A0h,1Fh,0C0h
	db	0Bh,0D0h,4,14h,0EFh,0,0A0h,41h,0C0h,5,0D0h,0Eh,14h,0A9h,0,0
	db	0A0h,18h,0C0h,5,4,59h,0,4,64h,0,4,71h,0,4,7Fh,0
	db	4,8Eh,0,4,0A0h,0,0,0A0h,4Fh,0C0h,0Dh,0F1h,3,28h,0BFh,3
	db	0A0h,41h,0C0h,4,0B0h,50h,7Fh,0BFh,3,0,0A0h,12h,0C0h,5,0D0h,0Dh
	db	8,64h,0,8,7Fh,0,8,8Eh,0,8,0B2h,0,8,0C9h,0
w_D1151	db	0F3h,0,0Ah,6Ah,0,0F3h,3,5,6Ah,0,0F3h,6,0F1h,3,0A0h,31h
	db	0B0h,28h,2Dh,6Ah,0,0,0A0h,12h,0C0h,5,0D0h,0Dh,8,86h,0,8
	db	0A9h,0,8,0BEh,0,8,0EFh,0,8,0Dh,1
w_D117C	db	0F3h,0,5,8Eh,0,0F3h,0Ah,0F1h,3,0A0h,31h,0B0h,28h,19h,8Eh,0
	db	0,0A0h,12h,0C0h,5,8,40h,1,0F3h,4,0F1h,3,0A0h,31h,8,53h
	db	1,8,0EFh,0,7,1Dh,1,7,0C9h,0,7,77h,0,7,54h,0
	db	0,0A0h,12h,0C0h,5,0D0h,0Eh,0B0h,5,0F1h,3,55h,0F8h,3,0F2h,5
	db	89h,3,0F3h,0,5,0F8h,3,0F3h,3,5,89h,3,5,0F8h,3,0
	db	0F1h,2,0A0h,1Fh,0C0h,0Bh,0D0h,4,14h,7Dh,1,0A0h,41h,0C0h,5,0D0h
	db	0Eh,14h,0E2h,0,0A0h,1Fh,0C0h,0Bh,0D0h,4,14h,86h,0,0A0h,41h,0C0h
	db	5,0D0h,0Eh,14h,0BEh,0,0,0A0h,4Fh,0C0h,0Dh,0F1h,3,28h,64h,0
	db	0A0h,41h,0C0h,4,0B0h,50h,7Fh,64h,0,0,0A0h,13h,0C0h,2,0D0h,8
	db	0F3h,0,7,40h,1,0F3h,2,7,0FEh,0,0A0h,0,0F1h,3,38h,97h
	db	0,0A0h,41h,7,0C9h,0,7,0D5h,0,0C0h,4,7,0Dh,1,0C0h,6
	db	7,1Dh,1,0,0F1h,2,0A0h,1Fh,0C0h,0Bh,0D0h,4,0Eh,5Fh,0,0A0h
	db	41h,0C0h,5,0D0h,0Eh,0Eh,0D5h,0,0A0h,1Fh,0C0h,0Bh,0D0h,4,7,2Eh
	db	1,0A0h,31h,0C0h,5,0D0h,0Eh,7,86h,0,0,0A0h,1Eh,0C0h,0Eh,5
	db	89h,3,5,0FAh,2,5,81h,2,5,1Bh,2,0,0A0h,13h,0C0h,2
	db	0D0h,0Bh,0Ah,0F8h,3,0Ah,0F8h,3,0Ah,0F8h,3,0Ah,0F8h,3,0,0A0h
	db	1Dh,0C0h,5,0D0h,0Ch,0Dh,0FAh,2,0Dh,0FAh,2,0Dh,0FAh,2,0,0A0h
	db	12h,0C0h,4,0D0h,0Eh,0B0h,5,0F1h,3,5Ah,54h,0,0F2h,0C0h,0Ah,0F3h
	db	0,5,54h,0,0F3h,2,0C0h,8,0Ah,54h,0,0F3h,1,5,54h,0
	db	0F3h,2,0C0h,0Ah,0Ah,54h,0,0F3h,1,0,0A0h,4Fh,0C0h,0Dh,0F1h,4
	db	28h,0A7h,2,0A0h,81h,0C0h,4,0B0h,50h,7Fh,0BFh,3,0,0A0h,1Eh,0C0h
	db	0Eh,5,0FAh,2,5,81h,2,5,1Bh,2,5,0C4h,1,0,0A0h,15h
	db	0C0h,5,0F3h,0,0Ah,81h,2,0Ah,81h,2,0C0h,4,0D0h,0Eh,0F3h,1
	db	0C0h,3,0D0h,0Dh,5,81h,2,0F3h,1,0C0h,2,0D0h,0Ch,5,81h,2
	db	0F3h,1,0C0h,1,0D0h,0Bh,4,81h,2,0F3h,2,0C0h,2,0D0h,0Ch,5
	db	81h,2,0F3h,1,0C0h,3,0D0h,0Dh,5,81h,2,0F3h,1,0C0h,4,0D0h
	db	0Eh,0Ah,81h,2,0F3h,1,0C0h,5,0D0h,0Fh,0Ah,81h,2,0F3h,1,0
	db	0A0h,1Dh,0C0h,6,0D0h,0Dh,0Ah,89h,3,0Ah,0BFh,3,0Ah,0F8h,3,0Ah
	db	89h,3,0,0A0h,15h,0C0h,4,0D0h,0Eh,5,89h,3,5,7Dh,1,5
	db	40h,1,5,1Bh,2,0,0A0h,21h,0C0h,4,0Ah,5Dh,2,0Ah,0F8h,3
	db	0Ah,0ABh,1,0Ah,0CAh,2,0,0A0h,19h,0C0h,5,0D0h,0Eh,5,0F8h,3
	db	5,57h,3,5,0FAh,2,5,81h,2,5,0EFh,0,5,0ABh,1,5
	db	65h,1,5,2Eh,1,0,0A0h,1Eh,0C0h,0Eh,5,77h,0,5,0A9h,0
	db	5,8Eh,0,5,0C9h,0,0,0A0h,12h,5,21h,0,5,71h,0,5
	db	0A0h,0,5,5Fh,0,0,0A0h,14h,5,0B2h,0,5,0C9h,0,5,1Dh
	db	1,0,0A0h,16h,5,65h,1,5,93h,1,5,3Bh,2,5,0FFh,0FFh
	db	5,65h,1,5,0BEh,0,5,1Dh,1,0,0A0h,11h,0C0h,5,7,1Dh
	db	1,7,0Dh,1,0C0h,4,7,0EFh,0,7,0D5h,0,0C0h,3,7,0BEh
	db	0,0F1h,3,0A0h,81h,1Ch,0A9h,0,0,0A0h,13h,0C0h,1,0D0h,0Ah,0Ah
	db	0F8h,3,0Ah,0BFh,3,0Ah,0F8h,3,0Ah,57h,3,0,0A0h,13h,0C0h,0
	db	0D0h,6,0Ah,0F8h,3,0Ah,0BFh,3,0Ah,0F8h,3,0Ah,89h,3,0,0A0h
	db	16h,0C0h,2,0D0h,0Eh,0Ah,71h,0,0Ah,89h,3,0,0A0h,13h,0C0h,1
	db	0D0h,0Dh,0Ah,0EFh,0,0Ah,0EFh,0,0Ah,0BFh,3,0Ah,0EFh,0,0,0A0h
	db	13h,0C0h,0,0D0h,6,7,77h,0,7,7Fh,0,7,0A0h,0,7,0A9h
	db	0,0,0A0h,19h,0C0h,1,0D0h,0Ah,7,4Bh,0,7,65h,1,0,0A0h
	db	13h,0C0h,1,0D0h,0Ah,0Eh,0F8h,3,0Eh,1Dh,1,0Eh,0E2h,0,0Eh,64h
	db	0,0,0A0h,13h,0C0h,1,0D0h,0Ah,0Eh,27h,3,0Eh,0F8h,3,0Eh,27h
	db	3,0Eh,89h,3,0,0A0h,11h,0C0h,2,0D0h,0Eh,0F3h,0,1Ch,0C4h,1
	db	0F3h,3,0F0h,0A0h,11h,0C0h,2,0D0h,0Eh,1Ch,0C4h,1,4,3Bh,2,4
	db	81h,2,14h,89h,3,1Ch,0C4h,1,1Ch,0C4h,1,0F0h,0A0h,11h,0C0h,2
	db	0D0h,0Eh,1Ch,0C4h,1,0Eh,0C4h,1,0Eh,0FCh,1,1Ch,0C4h,1,1Ch,0C4h
	db	1,0F0h,0A0h,11h,0C0h,2,4,3Bh,2,4,81h,2,6,89h,3,4
	db	3Bh,2,4,40h,1,6,0C4h,1,1Ch,0C4h,1,1Ch,0FCh,1,0Eh,0C4h
	db	1,0Eh,0FCh,1,0F0h,0A0h,11h,0C0h,2,0D0h,0Eh,1Ch,0C4h,1,1Ch,0ABh
	db	1,1Ch,7Dh,1,1Ch,0C4h,1,0F0h,0A0h,11h,0C0h,2,0D0h,0Eh,1Ch,0C4h
	db	1,1Ch,0ABh,1,1Ch,7Dh,1,1Ch,93h,1,0F0h,0A0h,11h,0C0h,2,0D0h
	db	0Eh,1Ch,0C4h,1,1Ch,0C4h,1,1Ch,0FCh,1,1Ch,0C4h,1,0F0h,0A0h,11h
	db	0C0h,2,0D0h,0Eh,1Ch,0C4h,1,1Ch,0FCh,1,1Ch,0C4h,1,1Ch,93h,1
	db	0F0h
w_D151D	dw	0FF70h,0A0FFh,0C03Fh,0F10Dh,1C04h,97h,0A0h,2C0h
	dw	9754h,0B000h,70FFh,0BEh,0A1A0h,0FF38h,0C0FFh,0A003h
	dw	714h,0BEh,933Fh,301h,1C4h,0AB03h,301h,17Dh
	dw	5303h,201h,12Eh,31A0h,8654h,0A000h,7014h,0BEh
	dw	0FF0Eh,3FFh,1C4h,0AB03h,301h,17Dh,5303h,201h
	dw	12Eh,31A0h,8654h,0A000h,0C03Fh,0F10Dh,1C04h,97h
	dw	0C1A0h,2C0h,9754h,0C000h,0A003h,0E14h,0FFFFh,0C403h
	dw	301h,1ABh,7D03h,301h,153h,2E02h,0A001h,5431h
	dw	86h,0FF38h,0A0FFh,714h,0BEh,9331h,7001h,0FFFFh
	dw	0FF70h,0F0FFh
w_D15B1	db	0A0h,11h,0C0h
b_D15B4	db	7,0D0h,0Eh,0Eh,89h,3,0Eh,57h,3,0Eh,89h,3,0Eh,27h,3,0Eh
	db	3Bh,2,0Eh,57h,3,0Eh,89h,3,0Eh,0F8h,3,0F0h,0A0h,11h,0C0h
b_D15D3	db	7,0D0h,0Eh,0Eh,89h,3,0Eh,57h,3,0Eh,0BFh,3,0Eh,27h,3,0Eh
	db	3Bh,2,0Eh,57h,3,0Eh,0BFh,3,0Eh,27h,3,0F0h,0A0h,11h,0C0h
b_D15F2	db	7,0D0h,0Eh,0Eh,89h,3,0Eh,57h,3,0Eh,40h,1,0Eh,27h,3,0Eh
	db	0FAh,2,0Eh,57h,3,0Eh,0BFh,3,0Eh,27h,3,0F0h,0A0h,11h,0C0h
b_D1611	db	7,0D0h,0Eh,0Eh,89h,3,0Eh,57h,3,0Eh,89h,3,0Eh,27h,3,0Eh
	db	81h,2,0Eh,57h,3,0Eh,89h,3,0Eh,27h,3,0F0h
w_D162D	dw	1068h,1098h,10B8h,10CCh,10E0h,10EBh,1112h,1129h
w_D163D	dw	113Ch,1167h,118Dh,11ADh,11CCh,11F3h,1206h,1230h
	dw	1257h,1268h,127Bh,128Bh,12B6h,12C9h,12DAh,132Ch
	dw	133Fh,1352h,1363h,1382h,1393h,13A2h,13AEh,13C6h
	dw	13E5h,13F8h,140Bh,1418h,142Bh,143Eh,144Bh,145Eh
	dw	1471h,147Fh,1498h,14AEh,14D1h,14E4h,14F7h,150Ah
w_D168D	dw	15B1h,15D0h,15EFh,160Eh
fx_17_data	dw	0EC0h,1FA0h,190h,20h,3F0Eh,2
fx_16_data	db	0C0h,0Eh,0A0h,1Fh,90h,1,2Ah,0,0Bh,2Fh,2,0C0h,5,0A0h,11h,90h
	db	1,0D6h,0FFh,0Ah,0FFh,3,0
fx_45_data	db	0C0h,7,0A0h,0A1h,90h,1,0,1,0F5h,0Fh,10h,0C6h,16h,50h,12h,0
	db	0
fx_10_data	dw	3C0h,28A0h,190h,200h,120Ah,0
fx_11_data	dw	4C0h,21A0h,190h,5,14h,1
fx_28_data	dw	5C0h,4AA0h,190h,1,107h,0
fx_29_data	dw	5C0h,206h,600h,0FFFFh,206h,0
fx_5_data	dw	0C0h,15A0h
fx_32_data	dw	190h,0FFFFh,603h,0
fx_31_data	dw	190h,1,102h,0F500h,307h,1711h,0FF02h,0F0FFh
fx_36_data	dw	0DC0h,0F1A0h,190h,1,215Ah,0
w_D1721	dw	7C0h,91A0h,32B0h,77Fh,0
fx_35_data	dw	0CC0h,0F1A0h,390h,0FFFFh,2D24h,0
w_D1737	dw	0AC0h,2FA0h,5D0h,71Eh,0C000h,0D005h,0A008h,1EA1h
	dw	7,8C0h,0A0h,0F3h,51Eh,0F300h,0FFh
fx_9_data	dw	0C0h,15A0h,190h,0FFFFh,203h,0
fx_14_data	db	0C0h,0Eh,0A0h,18h,2,0FFh,3,0C0h,1,0A0h,16h,3,0FFh,3,0
w_D1770	dw	0FC0h,190h,0FFFEh,380Fh,9000h,101h,0A00h,1Ah
	dw	190h,0FFFEh,240Fh,0
w_D1788	db	0C0h
b_D1789	db	0Ah,0A0h,2Fh,0Fh,3,0,0C0h
b_D1790	db	4,0A0h,11h,0D0h
b_D1794	db	0Ah,0Fh,3,0,0C0h
b_D1799	db	5,0Ah,3,0,0
fx_6_data	dw	2C0h,11A0h,490h,1,508h,0F300h,5
fx_3_data	dw	11A0h,10Ah,0
fx_33_data	dw	2C0h,51A0h,51Eh,0C000h,0F304h,1
fx_34_data	dw	6C0h,31A0h,614h,0C000h,0F308h,1
fx_12_data	dw	190h,202h,0A1A0h,3E78h,1
w_D17D4	dw	190h,201h,91A0h,1668h,1
fx_20_data	dw	5C0h,17A0h,290h,0FF63h,3B04h,0F301h,1
fx_19_data	dw	5C0h,17A0h,290h,0FEEBh,2B04h,0F302h,1
fx_8_data	dw	5C0h,41A0h,52Dh,0
fx_7_data	dw	1C0h,81A0h,608h,6400h,6
fx_1_data	db	0
fx_18_data	dw	190h,1FFh,2019h,0F301h
b_D1815	db	3,0
w_D1817	db	0C0h
b_D1818	db	5,0A0h
b_D181A	db	0,90h,1
w_D181D	dw	201h
b_D181F	db	6
w_D1820	db	22h,2,0F0h
w_D1823	dw	21A0h,290h,1
b_D1829	db	6,54h,0
b_D182C	db	9,54h,0,0A0h,0,90h,1,1,0,0Fh,51h,0,0A0h,21h,90h,1
	db	0FFh,0FFh,19h,58h,0,0
w_D1842	dw	21A0h,290h,1
b_D1848	db	6,52h,0
b_D184B	db	9,52h,0,0A0h,0,90h,1,1,0,0Fh,4Fh,0,0A0h,21h,90h,1
	db	0FFh,0FFh,19h,56h,0,0
w_D1861	dw	21A0h,190h,2
b_D1867	db	6,50h,0,9,50h,0,0A0h,0,90h,1,1,0,0Fh,4Dh,0,0A0h
	db	21h,90h,1,0FFh,0FFh,19h,54h,0,0
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'Tandy Covert10-09-90'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	1880h		; bytes from DATA to the stack
drv_first_slot	db	100
	db	0
drv_count	dw	11		; number of exports
drv_exports	label	word
	dw	offset tsnd_init	; slot 100
	dw	offset tsnd_play_sound	; slot 101
	dw	offset tsnd_shutdown	; slot 102
	dw	offset tsnd_tick	; slot 103
	dw	offset tsnd_nop	; slot 104
	dw	offset tsnd_get_ticks	; slot 105
	dw	offset tsnd_nop	; slot 106
	dw	offset tsnd_nop	; slot 107
	dw	offset tsnd_nop	; slot 108
	dw	offset tsnd_nop	; slot 109
	dw	offset tsnd_nop	; slot 110
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
	dw	offset fx_21
	dw	offset fx_23
	dw	offset fx_21
	dw	offset fx_21
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
; tsnd_init (slot 100)
; init(): stop everything, check for the Tandy BIOS sound interrupt (int 1Ah
; AH=81h) and start the 60 Hz timer.
; ----------------------------------------------------------------------------
tsnd_init:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	fx_0
	mov	ah, 0
	mov	byte ptr has_tandy_bios, ah
	mov	ah, 81h
	int	1Ah
	test	ax, 0F000h
	jne	L_00C6
	mov	byte ptr has_tandy_bios, 0FFh
L_00C6:
	call	hook_timer
	mov	byte ptr sound_paused, 0
	mov	byte ptr sound_muted, 0
	pop	ds
	pop	bp
	xor	ax, ax

; ----------------------------------------------------------------------------
; tsnd_nop (slot 104/106/107/108/109/110)
; Slots 104, 106-110: nothing.
; ----------------------------------------------------------------------------
tsnd_nop:
	retf

; ----------------------------------------------------------------------------
; tsnd_play_sound (slot 101)
; play_sound(n): start effect n.
; ----------------------------------------------------------------------------
tsnd_play_sound:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	mov	bx, word ptr [bp+6]
	cmp	bx, 2Eh
	jg	L_00F2
	push	di
	shl	bx, 1
	call	word ptr cs:[bx+fx_table]
	pop	di
L_00F2:
	pop	ds
	pop	bp
	retf
tick_count	dw	0

; ----------------------------------------------------------------------------
; tsnd_tick (slot 103)
; Slot 103: run one sequencer step (as the timer handler does).
; ----------------------------------------------------------------------------
tsnd_tick:
	push	di
	push	bx
	push	cx
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	sound_tick
	pop	ds
	pop	cx
	pop	bx
	pop	di
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; tsnd_get_ticks (slot 105)
; Slot 105: number of sequencer ticks so far.
; ----------------------------------------------------------------------------
tsnd_get_ticks:
	mov	ax, word ptr cs:tick_count
	retf

; ----------------------------------------------------------------------------
; tsnd_shutdown (slot 102)
; shutdown(): silence the chip and restore the timer.
; ----------------------------------------------------------------------------
tsnd_shutdown:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	fx_0
	call	unhook_timer
	pop	ds
	retf

; ----------------------------------------------------------------------------
; clear_voices
; ----------------------------------------------------------------------------
clear_voices:
	mov	cx, 0A0h
	lea	bx, voice0
L_0124:
	xor	ax, ax
	add	bx, cx
L_0128:
	dec	bx
	mov	byte ptr [bx], al
	loop	L_0128
	ret
	db	5Bh,58h

; ----------------------------------------------------------------------------
; fx_21
; ----------------------------------------------------------------------------
fx_21:
	ret

; ----------------------------------------------------------------------------
; sound_tick
; Sequencer step: the music engine, then each voice.
; ----------------------------------------------------------------------------
sound_tick:
	inc	word ptr cs:tick_count
	call	random
	cmp	byte ptr sound_paused, 0FFh
	je	fx_21
	cmp	byte ptr b_D00EC, 0
	je	L_014A
	call	sub_030A
L_014A:
	lea	di, voice0
	call	voice_tick
	lea	di, voice1
	call	voice_tick
	lea	di, voice2
	call	voice_tick
	lea	di, voice3
	call	voice_tick
	lea	di, voice4

; ----------------------------------------------------------------------------
; voice_tick
; DI = voice block: advance its envelopes and send its pitch and volume to the chip.
; ----------------------------------------------------------------------------
voice_tick:
	cmp	byte ptr [di+1Bh], 0
	je	fx_21
	dec	byte ptr [di+1Bh]
	jne	L_0178
	jmp	L_042D
L_0178:
	cmp	word ptr [di], -1
	je	fx_21
	mov	al, byte ptr [di+16h]
	cmp	al, byte ptr [di+1Bh]
	jb	L_01AD
	cmp	byte ptr [di+7], 0
	je	L_01AD
	dec	byte ptr [di+8]
	jne	L_01AD
	mov	al, byte ptr [di+7]
	mov	byte ptr [di+8], al
	mov	ah, byte ptr [di+17h]
	mov	al, ah
	and	ax, 0F00Fh
	cmp	al, byte ptr [di+19h]
	je	L_01AD
	add	al, byte ptr [di+6]
	and	al, 0Fh
	or	al, ah
	mov	byte ptr [di+17h], al
L_01AD:
	cmp	byte ptr [di+5], 0
	je	L_01C8
	dec	byte ptr [di+5]
	jne	L_01C8
	mov	al, byte ptr [di+4]
	mov	byte ptr [di+5], al
	mov	ax, word ptr [di]
	add	ax, word ptr [di+2]
	and	ax, 3FFh
	mov	word ptr [di], ax
L_01C8:
	cmp	byte ptr [di+0Bh], 0
	jne	L_01DC
	mov	al, byte ptr [di+16h]
	cmp	byte ptr [di+1Bh], al
	jae	L_01DC
	cmp	byte ptr [di+7], 0
	jne	L_0224
L_01DC:
	dec	byte ptr [di+0Bh]
	jne	L_0224
	mov	al, byte ptr [di+0Ah]
	mov	byte ptr [di+0Bh], al
	mov	al, byte ptr [di+18h]
	cmp	al, 0
	jne	L_01F1
	mov	al, byte ptr [di+17h]
L_01F1:
	mov	ah, al
	and	ax, 0F00Fh
	cmp	al, 0Fh
	je	L_0224
	add	al, byte ptr [di+9]
	and	ax, 0F00Fh
	or	ah, al
	mov	byte ptr [di+18h], ah
	cmp	ah, byte ptr [di+17h]
	je	L_0224
	inc	ah
	cmp	ah, byte ptr [di+17h]
	je	L_0224
	dec	ah
	dec	ah
	cmp	ah, byte ptr [di+17h]
	je	L_0224
	mov	ah, byte ptr [di+17h]
	mov	byte ptr [di+18h], ah
	xor	byte ptr [di+9], 0FEh
L_0224:
	cmp	byte ptr sound_muted, 0FFh
	je	L_0293
	mov	bx, word ptr [di]
	cmp	bx, -1
	je	L_0293
	mov	al, bl
	and	al, 0Fh
	ror	bx, 1
	ror	bx, 1
	ror	bx, 1
	ror	bx, 1
	mov	bh, al
	and	bx, 0F3Fh
	mov	al, byte ptr [di+18h]
	cmp	byte ptr [di+0Ah], 0
	jne	L_0250
	mov	al, byte ptr [di+17h]
L_0250:
	out	0C0h, al
	and	al, 0E0h
	or	bh, al
	mov	al, bh
	cmp	al, 0E0h
	jb	L_027E
	lea	bx, voice3
	cmp	di, bx
	jne	L_0272
	cmp	byte ptr voice4+1Bh, 0
	je	L_0272
	cmp	word ptr voice4, 7
	jbe	L_0293
L_0272:
	cmp	al, byte ptr last_noise
	je	L_0293
	mov	byte ptr last_noise, al
	jmp	L_0282
L_027E:
	out	0C0h, al
	mov	al, bl
L_0282:
	out	0C0h, al
	ret

; ----------------------------------------------------------------------------
; random
; AX = next pseudo-random number.
; ----------------------------------------------------------------------------
random:
	mov	ax, word ptr rand_seed
	adc	ax, 7131h
	adc	ax, word ptr cs:tick_count
	mov	word ptr rand_seed, ax
L_0293:
	ret

; ----------------------------------------------------------------------------
; sub_0294
; ----------------------------------------------------------------------------
sub_0294:
	cmp	word ptr voice0+1Bh, 0
	je	L_02B5
	cmp	word ptr voice0+1Bh, 1
	jne	L_02B4
	call	random
	and	ax, 6
	lea	bx, w_D168D
	add	bx, ax
	mov	bx, word ptr [bx]
	mov	word ptr voice0+12h, bx
L_02B4:
	ret
L_02B5:
	mov	ax, 70h
	mov	word ptr w_D00E4, ax
	inc	ax
	inc	ax
	mov	word ptr w_D00E2, ax
	call	sub_02FB
	lea	bx, w_D15B1
	jmp	start_voice0
L_02CA:
	mov	byte ptr b_D00EC, 0
	lea	bx, fx_1_data
	mov	word ptr voice0+14h, bx
	mov	word ptr voice1+14h, bx
	mov	word ptr voice2+14h, bx
	mov	word ptr w_D00E6, 0
	ret

; ----------------------------------------------------------------------------
; sub_02E6
; ----------------------------------------------------------------------------
sub_02E6:
	lea	bx, fx_1_data
	mov	word ptr voice0+14h, bx
	ret

; ----------------------------------------------------------------------------
; sub_02EF
; ----------------------------------------------------------------------------
sub_02EF:
	lea	bx, fx_1_data
	mov	word ptr voice1+14h, bx
	mov	word ptr voice2+14h, bx

; ----------------------------------------------------------------------------
; sub_02FB
; ----------------------------------------------------------------------------
sub_02FB:
	mov	al, 7

; ----------------------------------------------------------------------------
; sub_02FD
; ----------------------------------------------------------------------------
sub_02FD:
	mov	byte ptr b_D15B4, al
	mov	byte ptr b_D15D3, al
	mov	byte ptr b_D15F2, al
	mov	byte ptr b_D1611, al
	ret

; ----------------------------------------------------------------------------
; sub_030A
; ----------------------------------------------------------------------------
sub_030A:
	cmp	word ptr w_D00E8, 0
	je	L_02CA
	cmp	word ptr w_D00EA, 0
	je	L_02CA
	cmp	word ptr w_D00E8, 4
	jb	L_0325
	call	sub_034A
	jmp	L_0328
L_0325:
	call	sub_032F
L_0328:
	mov	ax, word ptr w_D00E8
	mov	word ptr w_D00E6, ax
	ret

; ----------------------------------------------------------------------------
; sub_032F
; ----------------------------------------------------------------------------
sub_032F:
	cmp	word ptr w_D00E6, 4
	jb	L_0343
	call	sub_02E6
	cmp	word ptr w_D00E6, 4
	jb	L_0343
	call	sub_02EF
L_0343:
	call	sub_03B8
	call	sub_03FB
	ret

; ----------------------------------------------------------------------------
; sub_034A
; ----------------------------------------------------------------------------
sub_034A:
	call	sub_0294
	cmp	word ptr w_D00E2, 0
	jne	L_035C
	mov	bx, word ptr w_D00E4
	mov	word ptr w_D00E2, bx
L_035C:
	dec	word ptr w_D00E2
	cmp	word ptr w_D00E8, 5
	je	L_037F
	cmp	word ptr w_D00E6, 4
	je	L_0378
	cmp	word ptr w_D00E6, 5
	jne	L_0378
	call	sub_02EF
L_0378:
	call	sub_03B8
	call	sub_03FB
	ret
L_037F:
	cmp	word ptr w_D00E6, 5
	je	L_03AD
	mov	al, 3
	call	sub_02FD
	lea	bx, w_D105B
	call	start_voice1
	lea	bx, w_D151D
	mov	word ptr voice1+12h, bx
	lea	bx, w_D105B
	call	start_voice2
	mov	ax, word ptr w_D00E2
	dec	ax
	jns	L_03AA
	mov	ax, word ptr w_D00E4
L_03AA:
	call	sub_0421
L_03AD:
	cmp	byte ptr voice2+1Bh, 1
	jne	L_03FA
	call	sub_03C6
	ret

; ----------------------------------------------------------------------------
; sub_03B8
; ----------------------------------------------------------------------------
sub_03B8:
	cmp	byte ptr voice2+1Bh, 0
	jne	L_03FA
	lea	bx, w_D105B
	call	start_voice2

; ----------------------------------------------------------------------------
; sub_03C6
; ----------------------------------------------------------------------------
sub_03C6:
	mov	bx, word ptr w_D00E8
	dec	bx
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	shl	bx, 1
	call	random
	cmp	word ptr w_D00E8, 1
	jne	L_03E9
	and	ax, 1Eh
	add	ax, bx
	lea	bx, w_D162D
	jmp	L_03F2
L_03E9:
	and	ax, 0Eh
	add	ax, bx
	lea	bx, w_D163D
L_03F2:
	add	bx, ax
	mov	bx, word ptr [bx]
	mov	word ptr voice2+12h, bx
L_03FA:
	ret

; ----------------------------------------------------------------------------
; sub_03FB
; ----------------------------------------------------------------------------
sub_03FB:
	call	random
	and	ax, 0FFh
	inc	ax
	xor	dx, dx
	mov	bx, word ptr w_D00E8
	div	bx
	or	ax, 1
	mov	bx, ax
	mov	ax, word ptr w_D00EA
	mov	dx, 14h
	mul	dx
	add	ax, bx
	cmp	ax, 0FFh
	jle	sub_0421
	mov	ax, 0FFh

; ----------------------------------------------------------------------------
; sub_0421
; ----------------------------------------------------------------------------
sub_0421:
	shr	ax, 1
	mov	byte ptr w_D105B, al
	adc	ax, 0
	mov	byte ptr b_D105E, al
	ret
L_042D:
	mov	bx, word ptr [di+14h]
	mov	al, byte ptr [bx]
	or	al, al
	je	sub_0439
	jmp	L_044F

; ----------------------------------------------------------------------------
; sub_0439
; ----------------------------------------------------------------------------
sub_0439:
	mov	al, byte ptr [di+17h]
	or	al, al
	je	L_0444
	or	al, 9Fh
	out	0C0h, al
L_0444:
	mov	bx, di
	mov	cx, 1Dh
	jmp	L_0124
L_044C:
	jmp	L_0224
L_044F:
	call	sub_0483
	jne	L_0481
	mov	byte ptr [di+1Bh], al
	cmp	al, 0
	je	sub_0439
	mov	al, byte ptr [di+1Ah]
	mov	byte ptr [di+17h], al
	cmp	byte ptr [di+0Ah], 0
	je	L_046A
	mov	byte ptr [di+18h], al
L_046A:
	mov	ax, word ptr [bx]
	mov	word ptr [di], ax
	inc	bx
	inc	bx
	mov	word ptr [di+14h], bx
	cmp	ax, 0FFFFh
	jne	L_044C
	xor	ax, ax
	mov	al, byte ptr [di+1Ah]
	or	al, 9Fh
	out	0C0h, al
L_0481:
	ret
L_0482:
	inc	bx

; ----------------------------------------------------------------------------
; sub_0483
; ----------------------------------------------------------------------------
sub_0483:
	mov	al, byte ptr [bx]
	inc	bx
	test	al, 80h
	je	L_0481
	cmp	al, 0C0h
	jne	L_049D
	mov	al, byte ptr [di+1Ah]
	and	al, 0F0h
	or	al, byte ptr [bx]
	mov	byte ptr [di+1Ah], al
	mov	byte ptr [di+17h], al
	jmp	L_0482
L_049D:
	cmp	al, 0A0h
	jne	L_04B9
	mov	al, byte ptr [bx]
	and	al, 0Fh
	mov	byte ptr [di+6], al
	mov	al, byte ptr [bx]
	shr	al, 1
	shr	al, 1
	shr	al, 1
	shr	al, 1
	mov	ah, al
	mov	word ptr [di+7], ax
	jmp	L_0482
L_04B9:
	cmp	al, 90h
	jne	L_04CD
	mov	al, byte ptr [bx]
	inc	bx
	mov	ah, al
	mov	word ptr [di+4], ax
	mov	ax, word ptr [bx]
	mov	word ptr [di+2], ax
	inc	bx
	jmp	L_0482
L_04CD:
	cmp	al, 80h
	jne	L_04F6
	mov	al, byte ptr [bx]
	inc	bx
	cmp	byte ptr [di+0Fh], 0
	je	L_04E7
	dec	byte ptr [di+0Fh]
	jne	L_04EE
L_04DF:
	mov	word ptr [di+10h], bx
	mov	word ptr [di+0Dh], bx
	jmp	sub_0483
L_04E7:
	cmp	al, 0
	je	L_04DF
	mov	byte ptr [di+0Fh], al
L_04EE:
	mov	bx, word ptr [di+10h]
	mov	word ptr [di+0Dh], bx
	jmp	sub_0483
L_04F6:
	cmp	al, 0F3h
	jne	L_051B
	mov	al, byte ptr [bx]
	inc	bx
	cmp	byte ptr [di+0Ch], 0
	je	L_050E
	dec	byte ptr [di+0Ch]
	jne	L_0515
L_0508:
	mov	word ptr [di+0Dh], bx
	jmp	sub_0483
L_050E:
	cmp	al, 0
	je	L_0508
	mov	byte ptr [di+0Ch], al
L_0515:
	mov	bx, word ptr [di+0Dh]
	jmp	sub_0483
L_051B:
	cmp	al, 0B0h
	jne	L_0527
	mov	al, byte ptr [bx]
	mov	byte ptr [di+16h], al
	jmp	L_0482
L_0527:
	cmp	al, 0D0h
	jne	L_0533
	mov	al, byte ptr [bx]
	mov	byte ptr [di+19h], al
	jmp	L_0482
L_0533:
	cmp	al, 0F1h
	jne	L_0545
	mov	al, byte ptr [bx]
	mov	ah, al
	mov	word ptr [di+0Ah], ax
	mov	byte ptr [di+9], 1
	jmp	L_0482
L_0545:
	cmp	al, 0F2h
	jne	L_0554
	xor	ax, ax
	mov	word ptr [di+0Ah], ax
	mov	byte ptr [di+9], al
	jmp	sub_0483
L_0554:
	cmp	al, 0E0h
	jne	L_0563
	xor	ax, ax
	mov	word ptr [di+2], ax
	mov	word ptr [di+4], ax
	jmp	sub_0483
L_0563:
	cmp	al, 0F5h
	jne	L_057E
	call	random
	xor	cx, cx
	mov	cx, word ptr [bx]
	inc	bx
	inc	bx
	and	al, cl
	add	al, ch
	push	bx
	mov	bx, word ptr [bx]
	mov	byte ptr [bx], al
	pop	bx
	inc	bx
	jmp	L_0482
L_057E:
	cmp	al, 0F4h
	jne	L_0599
	xor	ax, ax
	mov	byte ptr [di+9], al
	mov	word ptr [di+0Ah], ax
	mov	word ptr [di+2], ax
	mov	word ptr [di+4], ax
	mov	byte ptr [di+6], al
	mov	word ptr [di+7], ax
	jmp	sub_0483
L_0599:
	cmp	al, 0F0h
	mov	bx, word ptr [di+12h]
	mov	word ptr [di+0Dh], bx
	mov	word ptr [di+10h], bx
	mov	byte ptr [di+16h], 0FFh
	mov	word ptr [di+2], 0
	mov	word ptr [di+6], 0
	mov	word ptr [di+0Ah], 0
	jmp	sub_0483
	db	39h,1Eh,0D6h,0,76h,57h
; BX = note list, AL = the chip's volume register: start the fifth voice block.
start_voice4:
	lea	di, voice4
	jmp	start_voice

; ----------------------------------------------------------------------------
; start_voice0
; BX = note list: start a voice (0-3; voice3 is the noise voice).
; ----------------------------------------------------------------------------
start_voice0:
	lea	di, voice0
	mov	al, 93h
	jmp	start_voice

; ----------------------------------------------------------------------------
; start_voice1
; ----------------------------------------------------------------------------
start_voice1:
	lea	di, voice1
	mov	al, 0B3h
	jmp	start_voice

; ----------------------------------------------------------------------------
; start_voice2
; ----------------------------------------------------------------------------
start_voice2:
	lea	di, voice2
	mov	al, 0D3h
	jmp	start_voice

; ----------------------------------------------------------------------------
; start_voice3
; ----------------------------------------------------------------------------
start_voice3:
	lea	di, voice3
	mov	al, 0F3h
start_voice:
	mov	ah, byte ptr sound_paused
	mov	byte ptr sound_paused, 0FFh
	push	ax
	push	bx
	call	sub_0439
	pop	bx
	pop	ax
	mov	byte ptr [di+1Ah], al
	mov	word ptr [di+0Dh], bx
	mov	word ptr [di+10h], bx
	mov	word ptr [di+12h], bx
	mov	word ptr [di+14h], bx
	mov	byte ptr [di+16h], 0FFh
	mov	byte ptr [di+19h], 0Fh
stop_all	equ	byte ptr $+3
	mov	byte ptr [di+1Bh], 1
	mov	byte ptr sound_paused, ah
	ret

; ----------------------------------------------------------------------------
; fx_0
; ----------------------------------------------------------------------------
fx_0:
	call	pause_voices
	call	clear_voices
	call	resume_voices
chip_silence:
	mov	al, 82h
	out	0C0h, al
	xor	al, al
	out	0C0h, al
	mov	al, 0A3h
	out	0C0h, al
	xor	al, al
	out	0C0h, al
	mov	al, 0C4h
	out	0C0h, al
	xor	al, al
	out	0C0h, al
	mov	al, 0E3h
	out	0C0h, al
	mov	al, 9Fh
	out	0C0h, al
	mov	al, 0BFh
	out	0C0h, al
	mov	al, 0DFh
	out	0C0h, al
	mov	al, 0FFh
	out	0C0h, al
	ret

; ----------------------------------------------------------------------------
; pause_voices
; ----------------------------------------------------------------------------
pause_voices:
	mov	byte ptr sound_paused, 0FFh
	ret

; ----------------------------------------------------------------------------
; resume_voices
; ----------------------------------------------------------------------------
resume_voices:
	mov	byte ptr sound_paused, 0
	ret
L_065A:
	mov	al, 93h
	jmp	start_voice4

; ----------------------------------------------------------------------------
; sub_065F
; ----------------------------------------------------------------------------
sub_065F:
	mov	al, 0B3h
	jmp	start_voice4

; ----------------------------------------------------------------------------
; sub_0664
; ----------------------------------------------------------------------------
sub_0664:
	mov	al, 0D3h
	jmp	start_voice4

; ----------------------------------------------------------------------------
; L_0669
; Not reached from the exports (an interrupt handler, or dead code).
; ----------------------------------------------------------------------------
L_0669:
	mov	al, 0F3h
	jmp	start_voice4

; ----------------------------------------------------------------------------
; fx_29
; ----------------------------------------------------------------------------
fx_29:
	lea	bx, fx_29_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_28
; ----------------------------------------------------------------------------
fx_28:
	lea	bx, fx_28_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_32
; ----------------------------------------------------------------------------
fx_32:
	lea	bx, fx_32_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_31
; ----------------------------------------------------------------------------
fx_31:
	lea	bx, fx_31_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_35
; ----------------------------------------------------------------------------
fx_35:
	lea	bx, fx_35_data
	call	start_voice2
	lea	bx, w_D1737
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_36
; ----------------------------------------------------------------------------
fx_36:
	lea	bx, fx_36_data
	call	start_voice2
	lea	bx, w_D1721
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_39
; ----------------------------------------------------------------------------
fx_39:
	lea	bx, fx_39_data
	call	start_voice0
	lea	bx, w_D0F6E
	call	start_voice1
	lea	bx, w_D0FD2
	call	start_voice2
	lea	bx, w_D102A
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_41
; ----------------------------------------------------------------------------
fx_41:
	lea	bx, fx_41_data
	call	start_voice0
	lea	bx, w_D0D11
	call	start_voice1
	lea	bx, w_D0D93
	call	start_voice2
	lea	bx, w_D0E71
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_43
; ----------------------------------------------------------------------------
fx_43:
	lea	bx, fx_43_data
	call	start_voice0
	lea	bx, w_D0AD6
	call	start_voice1
	lea	bx, w_D0B49
	call	start_voice2
	lea	bx, w_D0BC2
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_40
; ----------------------------------------------------------------------------
fx_40:
	lea	bx, fx_40_data
	call	start_voice0
	lea	bx, w_D088F
	call	start_voice1
	lea	bx, w_D08F3
	call	start_voice2
	lea	bx, w_D090B
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_42
; ----------------------------------------------------------------------------
fx_42:
	lea	bx, fx_42_data
	call	start_voice0
	lea	bx, w_D067F
	call	start_voice1
	lea	bx, w_D0702
	call	start_voice2
	lea	bx, w_D07DC
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_20
; ----------------------------------------------------------------------------
fx_20:
	lea	bx, fx_20_data
	jmp	start_voice0

; ----------------------------------------------------------------------------
; fx_19
; ----------------------------------------------------------------------------
fx_19:
	lea	bx, fx_19_data
	jmp	start_voice0

; ----------------------------------------------------------------------------
; fx_12
; ----------------------------------------------------------------------------
fx_12:
	lea	bx, fx_12_data
	call	sub_065F
	lea	bx, w_D17D4
	jmp	sub_0664

; ----------------------------------------------------------------------------
; fx_16
; ----------------------------------------------------------------------------
fx_16:
	lea	bx, fx_16_data
	jmp	sub_0664

; ----------------------------------------------------------------------------
; fx_17
; ----------------------------------------------------------------------------
fx_17:
	lea	bx, fx_17_data
	jmp	sub_0664

; ----------------------------------------------------------------------------
; fx_30
; ----------------------------------------------------------------------------
fx_30:
	mov	bl, 0FFh
	jmp	L_0763

; ----------------------------------------------------------------------------
; fx_18
; ----------------------------------------------------------------------------
fx_18:
	xor	bl, bl
L_0763:
	mov	byte ptr b_D1815, bl
	lea	bx, fx_18_data
	jmp	sub_0664

; ----------------------------------------------------------------------------
; fx_9
; ----------------------------------------------------------------------------
fx_9:
	lea	bx, fx_9_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_14
; ----------------------------------------------------------------------------
fx_14:
	lea	bx, fx_14_data
	jmp	sub_0664

; ----------------------------------------------------------------------------
; fx_15
; ----------------------------------------------------------------------------
fx_15:
	mov	al, 0Ch
	mov	bl, 7
	mov	cl, 0Eh
	jmp	L_078B

; ----------------------------------------------------------------------------
; fx_13
; ----------------------------------------------------------------------------
fx_13:
	mov	al, 8
	mov	bl, 2
	mov	cl, 0Ah
L_078B:
	mov	byte ptr b_D1789, al
	mov	byte ptr b_D1790, bl
	mov	byte ptr b_D1799, al
	mov	byte ptr b_D1794, cl
	lea	bx, w_D1770
	call	sub_0664
	lea	bx, w_D1788
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_6
; ----------------------------------------------------------------------------
fx_6:
	lea	bx, fx_6_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_5
; ----------------------------------------------------------------------------
fx_5:
	lea	bx, fx_5_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_4
; ----------------------------------------------------------------------------
fx_4:
	call	fx_34
	jmp	L_07C8

; ----------------------------------------------------------------------------
; fx_34
; ----------------------------------------------------------------------------
fx_34:
	lea	bx, fx_34_data
	call	start_voice3
	jmp	L_07D6

; ----------------------------------------------------------------------------
; fx_3
; ----------------------------------------------------------------------------
fx_3:
	call	fx_33
L_07C8:
	lea	bx, fx_3_data
	jmp	L_07DA

; ----------------------------------------------------------------------------
; fx_33
; ----------------------------------------------------------------------------
fx_33:
	lea	bx, fx_33_data
	call	start_voice3
L_07D6:
	lea	bx, fx_1_data
L_07DA:
	mov	word ptr voice3+0Dh, bx
	ret

; ----------------------------------------------------------------------------
; fx_8
; ----------------------------------------------------------------------------
fx_8:
	lea	bx, fx_8_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_7
; ----------------------------------------------------------------------------
fx_7:
	lea	bx, fx_7_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_46
; ----------------------------------------------------------------------------
fx_46:
	lea	bx, fx_46_data
	call	start_voice2
	lea	bx, fx_46_data
	call	start_voice1
	lea	bx, w_D1151
	mov	word ptr voice2+0Dh, bx
	lea	bx, w_D117C
	mov	word ptr voice1+0Dh, bx
	mov	bl, 15h
	mov	byte ptr voice1+1Bh, bl
	mov	bx, 0FFFFh
	mov	word ptr voice1, bx
	ret

; ----------------------------------------------------------------------------
; fx_45
; ----------------------------------------------------------------------------
fx_45:
	lea	bx, fx_45_data
	jmp	start_voice2

; ----------------------------------------------------------------------------
; fx_10
; ----------------------------------------------------------------------------
fx_10:
	lea	bx, fx_10_data
	jmp	sub_0664

; ----------------------------------------------------------------------------
; fx_11
; ----------------------------------------------------------------------------
fx_11:
	lea	bx, fx_11_data
	jmp	start_voice3

; ----------------------------------------------------------------------------
; fx_2
; ----------------------------------------------------------------------------
fx_2:
	lea	bx, fx_2_data
	call	start_voice0
	lea	bx, w_D02B7
	call	start_voice1
	lea	bx, w_D03DA
	call	start_voice2
	lea	bx, w_D0503
	jmp	start_voice3

; ----------------------------------------------------------------------------
; sub_084A
; ----------------------------------------------------------------------------
sub_084A:
	call	random
	and	ax, 7
	add	ax, 6
	ret
L_0854:
	lea	bx, w_D1823
	mov	word ptr voice0+12h, bx

; ----------------------------------------------------------------------------
; fx_23
; ----------------------------------------------------------------------------
fx_23:
	call	sub_084A
	mov	byte ptr b_D1829, al
	mov	byte ptr b_D1848, al
	mov	byte ptr b_D1867, al
	call	sub_084A
	mov	byte ptr b_D182C, al
	mov	byte ptr b_D184B, al
	mov	byte ptr b_D184B, al
	call	sub_084A
	lea	bx, w_D1823
	call	start_voice1
	lea	bx, w_D1842
	call	start_voice2
	lea	bx, w_D1861
	jmp	L_065A

; ----------------------------------------------------------------------------
; fx_26
; ----------------------------------------------------------------------------
fx_26:
	mov	bx, 18h
	jmp	L_0895

; ----------------------------------------------------------------------------
; fx_27
; ----------------------------------------------------------------------------
fx_27:
	mov	bx, 200h
L_0895:
	cmp	byte ptr voice0+1Bh, 0
	jne	L_08A5
	push	bx
	lea	bx, w_D1817
	call	start_voice0
	pop	bx
L_08A5:
	mov	ax, word ptr [bp+8]
	cmp	ax, 0
	je	L_0854
	mov	byte ptr b_D181A, bl
	mov	bl, 4
	sub	bl, al
	mov	word ptr w_D181D, bx
	mov	bx, 7
	sub	bx, ax
	mov	byte ptr b_D1818, bl
	shl	ax, 1
	shl	ax, 1
	mov	bx, 18h
	sub	bx, ax
	mov	byte ptr b_D181F, bl
	shl	ax, 1
	mov	bx, 3D0h
	sub	bx, ax
	mov	word ptr w_D1820, bx
	ret

; ----------------------------------------------------------------------------
; fx_44
; ----------------------------------------------------------------------------
fx_44:
	mov	ax, word ptr [bp+8]
	mov	word ptr w_D00E8, ax
	mov	ax, word ptr [bp+0Ah]
	mov	word ptr w_D00EA, ax
	mov	byte ptr b_D00EC, 0FFh
	ret

; ----------------------------------------------------------------------------
; fx_37
; ----------------------------------------------------------------------------
fx_37:
	mov	al, byte ptr b_D00EC
	mov	byte ptr b_D00ED, al
	mov	byte ptr b_D00EC, 0
	mov	al, byte ptr voice0+1Bh
	mov	byte ptr voice0+1Ch, al
	mov	al, byte ptr voice1+1Bh
	mov	byte ptr voice1+1Ch, al
	mov	al, byte ptr voice2+1Bh
	mov	byte ptr voice2+1Ch, al
	mov	al, byte ptr voice3+1Bh
	mov	byte ptr voice3+1Ch, al
	mov	al, byte ptr voice4+1Bh
	mov	byte ptr voice4+1Ch, al
	xor	al, al
	mov	byte ptr voice0+1Bh, al
	mov	byte ptr voice1+1Bh, al
	mov	byte ptr voice2+1Bh, al
	mov	byte ptr voice3+1Bh, al
	mov	byte ptr voice4+1Bh, al
	jmp	chip_silence

; ----------------------------------------------------------------------------
; fx_38
; ----------------------------------------------------------------------------
fx_38:
	mov	al, byte ptr b_D00ED
	mov	byte ptr b_D00EC, al
	mov	al, byte ptr voice0+1Ch
	mov	byte ptr voice0+1Bh, al
	mov	al, byte ptr voice1+1Ch
	mov	byte ptr voice1+1Bh, al
	mov	al, byte ptr voice2+1Ch
	mov	byte ptr voice2+1Bh, al
	mov	al, byte ptr voice3+1Ch
	mov	byte ptr voice3+1Bh, al
	mov	al, byte ptr voice4+1Ch
	mov	byte ptr voice4+1Bh, al
	ret

; ----------------------------------------------------------------------------
; fx_1
; ----------------------------------------------------------------------------
fx_1:
	lea	bx, fx_1_data
	mov	word ptr voice0+14h, bx
	mov	word ptr voice1+14h, bx
	mov	word ptr voice2+14h, bx
	mov	word ptr voice3+14h, bx
	mov	word ptr voice4+14h, bx
	ret
old_int8	db	0,0
w_096A	dw	0
timer_hooked	db	0
; Int 8 handler, about 60 Hz.
timer_isr:
	push	ax
	push	ds
	mov	ax, DATA
	mov	ds, ax
	push	bx
	push	cx
	push	dx
	push	di
	call	sound_tick
	pop	di
	pop	dx
	pop	cx
	pop	bx
	dec	byte ptr tick_div
	je	L_098C
	pop	ds
	mov	al, 20h
	out	20h, al
	pop	ax
	iret
L_098C:
	mov	byte ptr tick_div, 3
	pop	ds
	pop	ax
	jmp	dword ptr cs:old_int8

; ----------------------------------------------------------------------------
; hook_timer
; ----------------------------------------------------------------------------
hook_timer:
	cmp	byte ptr cs:timer_hooked, 0
	jne	L_09D7
	mov	byte ptr cs:timer_hooked, 0FFh
	cli
	mov	byte ptr tick_div, 3
	push	ds
	sub	ax, ax
	mov	ds, ax
	lea	ax, timer_isr
	mov	bx, cs
	xchg	word ptr ds:[20h], ax
	xchg	word ptr ds:[22h], bx
	mov	word ptr cs:old_int8, ax
	mov	word ptr cs:w_096A, bx
	pop	ds
	mov	al, 36h
	out	43h, al
	mov	ax, 4C90h
	out	40h, al
	mov	al, ah
	out	40h, al
	sti
L_09D7:
	ret

; ----------------------------------------------------------------------------
; unhook_timer
; ----------------------------------------------------------------------------
unhook_timer:
	cmp	byte ptr cs:timer_hooked, 0FFh
	jne	L_09D7
	mov	byte ptr cs:timer_hooked, 0
	cli
	push	ds
	mov	bx, word ptr cs:old_int8
	mov	cx, word ptr cs:w_096A
	sub	ax, ax
	mov	ds, ax
	mov	word ptr ds:[20h], bx
	mov	word ptr ds:[22h], cx
	pop	ds
	mov	al, 36h
	out	43h, al
	xor	ax, ax
	out	40h, al
	mov	al, ah
	out	40h, al
	sti
	ret
CODE	ENDS

STACK	SEGMENT PARA STACK 'STACK'
	db	16 dup (?)
STACK	ENDS

	END	start

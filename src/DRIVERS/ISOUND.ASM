; ISOUND.CA - Covert Action sound driver for the PC speaker ("CovertActIBM")
;
; Loaded by COVERT as an overlay; exports slots 100-110 (see README "Driver
; interface"). play_sound(n, param) starts effect n (0-46) from fx_table. An
; effect is a list of tone records (priority, duration, divisor span, base
; divisor, step), or of sweep records, ending with a 0 word; a new effect only
; replaces one of lower or equal priority. The sequencer runs from the timer
; interrupt (int 8), which the driver reprograms: about 60 Hz while idle,
; about 300 Hz while a sweep plays, chaining to the BIOS handler.
;
; Rebuilds byte-identical with MASM 5.10 / LINK 5.01: tools/drivers/build.sh ISOUND
; (first pass by tools/drivers/disasm_masm.py with tools/drivers/ISOUND.hints)

; Segments: CODE (header, code and code-segment variables), DATA, then the
; stack. CODE and DATA form DGROUP so that cs: references to DATA variables
; get group offsets (CS:6F0h = DATA:0) while DS references, with DS = DATA,
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
fx_34_data	dw	63h,0Ch,0BBBh,136h,0FDh,0
fx_33_data	dw	5Fh,0Ah,0BA9h,3B6h,8Ch,0
fx_35_data	dw	5Fh,6Dh,1819h,0EEEh,0FFF0h
w_D0072	dw	60h,6Dh,1819h,924h,0,0
fx_36_data	dw	61h,6Dh,1819h,924h,19h,0
fx_3_data	dw	63h,0Ah,0BA9h,3B6h,8Ch,63h,2,0
	dw	63h,10h,0B84h,0CEEh,0Dh,0
fx_4_data	dw	5Fh,0Ch,0BBBh,136h,0FDh,63h,2,0
	dw	5Fh,12h,0BC8h,371h,8,0
fx_5_data	dw	63h,2,551h,30Ch,0,0
fx_45_data	dw	63h,2,771h,30Ch,0,63h,2,0
	dw	63h,2,771h,30Ch,0,63h,2,0
	dw	63h,2,810h,30Ch,0,63h,2,0
	dw	63h,2,810h,30Ch,0,63h,2,0
	dw	63h,2,810h,30Ch,0,63h,2,0
	dw	63h,2,771h,30Ch,0,63h,2,0
	dw	63h,2,551h,30Ch,0,63h,2,0
	dw	63h,2,810h,30Ch,0,63h,2,0
	dw	63h,2,771h,30Ch,0,63h,2,0
	dw	63h,2,551h,30Ch,0,63h,2,0
	dw	63h,2,810h,30Ch,0,63h,2,0
	dw	63h,2,771h,30Ch,0,63h,2,0
	dw	63h,2,551h,30Ch,0,63h,2,0
	dw	63h,2,551h,30Ch,0,0
fx_46_data	dw	63h,4,2,4C0h,0,62h,4,2
	dw	400h,0,62h,4,2,260h,0,62h
	dw	4,2,400h,0,62h,4,2,4C0h
	dw	0,63h,4,3,260h,0,63h,4
	dw	3,4C0h,0,63h,4,3,260h,0
	dw	63h,4,3,4C0h,0,63h,4,3
	dw	400h,0,63h,4,3,260h,0,63h
	dw	4,3,400h,0,63h,4,3,4C0h
	dw	0,63h,4,3,400h,0,63h,4
	dw	3,260h,0,0
fx_6_data	dw	63h,4,0BE8h,276h,0D0h,0
fx_7_data	dw	61h,2Ah,0FFFh,3B6h,1Eh,0
fx_8_data	dw	5Ah,1Eh,2C74h,9BAh,0,0
fx_9_data	dw	63h,2,4DBh,200h,0,63h,3,0
	dw	63h,2,4DBh,211h,0,0
fx_10_data	dw	63h,4,4,44Ch,0,63h,4,4
	dw	267h,0,63h,4,4,725h,0,63h
	dw	4,4,336h,0,0
fx_11_data	dw	63h,3,17FEh,3B6h,1Eh,0
fx_12_data	dw	63h,3,1343h,1AEh,1Eh,0
fx_13_data	dw	4Bh,2,8CBh,7BCh,0,0
fx_14_data	dw	4Bh,3,12BCh,974h,0,0
fx_15_data	dw	50h,4,156Bh,1090h,0D0h,0
fx_16_data	dw	46h,6,11A2h,8C0h,0FF90h,0
fx_17_data	dw	46h,6,11A2h,7BCh,6Ch,0
fx_18_data	dw	59h,16h,91Ch,0B1Ah,0FFF4h,0
fx_19_data	dw	63h,0Dh,1C46h,10A4h,0FFFEh,0
fx_20_data	dw	63h,0Ah,0A1Bh,0A32h,0FFFEh,0
fx_21_data	dw	63h,0Dh,2,3Ch,3,0
fx_22_data	dw	4Bh,15h,0BBBh,0D8Eh,2Fh,0
fx_23_data	dw	55h,15h,19Ch,6D6h,0FFFEh,0
fx_24_data	dw	50h,9,9F6h,0D8Eh,0Dh,50h,7,9F6h
	dw	0D00h,0Dh,50h,6,9F6h,0C8Eh,0Dh,50h
	dw	5,9F6h,0C00h,0Dh,50h,4,9F6h,0B8Eh
	dw	0Dh,50h,3,9F6h,0B00h,0Dh,50h,3
	dw	9F6h,0A8Eh,0Dh,50h,2,9F6h,0A00h,0Dh
	dw	0
fx_25_data	dw	63h,1Fh,3B9h,6D6h,0FFFEh,0
fx26_record	dw	50h,9,9F6h,0D8Eh,0Dh,0
fx27_record	dw	50h,9,0C6Eh,0D8Eh,0Dh,0
fx_26_data	dw	62h,3,111h,1A4h,0,0
fx_29_data	dw	63h,4,2,980h,0,62h,4,2
	dw	800h,0,62h,4,2,4C0h,0,62h
	dw	4,2,800h,0,62h,4,2,980h
	dw	0,62h,4,2,1000h,0,62h,4
	dw	2,980h,0,62h,4,2,800h,0
	dw	62h,4,2,4C0h,0,0
fx_30_data	dw	63h,16h,91Ch,0B1Ah,0FFF4h,0
; Effect 31's record; pick_random_31 patches its pitches from rand_pitches
rand_record	dw	4Bh,1,876h,276h,0D0h,4Bh,5,0
	dw	0
fx_32_data	dw	5Ah,6,19Ch,111h,34h,0
; An empty record list (just the 0 terminator)
silence	dw	0
; Pitches selected by the parameter of effects 26 and 27
param_pitches	dw	9,0D8Eh,7,0D00h,6,0C8Eh,5,0C00h
	dw	4,0B8Eh
rand_pitches	dw	876h,5,111h,4
fx_2_data	dw	32h,7,77h,0E8Ch,0,32h,0Eh,0
	dw	32h,5,77h,0E8Ch,0,32h,10h,0
	dw	32h,5,77h,0E8Ch,0,32h,17h,0
	dw	32h,4,1,1D18h,0,32h,0Ah,0
	dw	32h,3,1,1054h,0,32h,4,0
	dw	32h,3,1,0AE6h,0,32h,4,0
	dw	32h,3,1,92Bh,0,32h,4,0
	dw	32h,3,1,0E8Ch,0,32h,4,0
	dw	32h,7,77h,1054h,0,32h,0Eh,0
	dw	32h,5,77h,1054h,0,32h,10h,0
	dw	32h,5,77h,1054h,0,32h,17h,0
	dw	32h,4,1,1D18h,0,32h,0Ah,0
	dw	32h,3,1,1256h,0,32h,4,0
	dw	32h,3,1,0C3Eh,0,32h,4,0
	dw	32h,3,1,9B6h,0,32h,4,0
	dw	32h,3,1,0DBEh,0,32h,4,0
	dw	32h,7,77h,1256h,0,32h,0Eh,0
	dw	32h,5,77h,1256h,0,32h,10h,0
	dw	32h,5,77h,1256h,0,32h,17h,0
	dw	32h,4,1,1D18h,0,32h,0Ah,0
	dw	32h,3,1,136Ch,0,32h,4,0
	dw	32h,3,1,0E8Ch,0,32h,4,0
	dw	32h,3,1,0AE6h,0,32h,4,0
	dw	32h,3,1,1054h,0,32h,4,0
	dw	32h,6,77h,24ACh,0,32h,8,0
	dw	32h,3,77h,1054h,0,32h,4,0
	dw	32h,3,77h,0E8Ch,0,32h,4,0
	dw	32h,6,77h,26D8h,0,32h,8,0
	dw	32h,3,77h,1256h,0,32h,4,0
	dw	32h,3,77h,1054h,0,32h,4,0
	dw	32h,6,77h,2928h,0,32h,8,0
	dw	32h,3,77h,136Ch,0,32h,4,0
	dw	32h,3,77h,1256h,0,32h,4,0
	dw	32h,6,77h,2B98h,0,32h,8,0
	dw	32h,3,77h,15CCh,0,32h,4,0
	dw	32h,3,77h,1494h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,3,1,136Ch,0,32h,0Bh,0
	dw	32h,4,77h,26D8h,0,32h,1Ch,0
	dw	32h,6,77h,26D8h,0,32h,8,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,2,3,0C3Eh,0,32h,5,0
	dw	32h,6,1,19F0h,0,32h,8,0
	dw	32h,3,3,0CF8h,0,32h,0Bh,0
	dw	32h,6,1,187Ch,0,32h,8,0
	dw	32h,2,3,0E8Ch,0,32h,5,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,24ACh,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,3,1,136Ch,0,32h,0Bh,0
	dw	32h,4,77h,26D8h,0,32h,1Ch,0
	dw	32h,3,1,2928h,0,32h,4,0
	dw	32h,3,1,15CCh,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,3,0C3Eh,0,32h,4,0
	dw	32h,6,1,19F0h,0,32h,8,0
	dw	32h,3,3,0CF8h,0,32h,0Bh,0
	dw	32h,6,1,187Ch,0,32h,8,0
	dw	32h,3,3,0E8Ch,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,24ACh,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,4,77h,0E8Ch,0,32h,3,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,77h,0E8Ch,0,32h,8,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,4,77h,1054h,0,32h,3,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,9,77h,9B6h,0,32h,0Ch,0
	dw	32h,6,77h,82Ah,0,32h,8,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,746h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,67Ch,0,32h,4,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,3,1,61Fh,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,4DBh,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,61Fh,0,32h,4,0
	dw	32h,3,1,746h,0,32h,4,0
	dw	32h,3,1,82Ah,0,32h,4,0
	dw	32h,3,1,9B6h,0,32h,4,0
	dw	32h,3,1,573h,0,32h,4,0
	dw	32h,3,1,67Ch,0,32h,4,0
	dw	32h,3,1,746h,0,32h,4,0
	dw	32h,3,1,4DBh,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,77h,0E8Ch,0,32h,8,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,4,77h,1054h,0,32h,3,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,9,77h,9B6h,0,32h,0Ch,0
	dw	32h,6,77h,746h,0,32h,8,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,746h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,67Ch,0,32h,4,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,3,1,61Fh,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,4DBh,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,30Fh,0,32h,4,0
	dw	32h,3,1,415h,0,32h,4,0
	dw	32h,3,1,3A3h,0,32h,4,0
	dw	32h,3,1,4DBh,0,32h,4,0
	dw	32h,3,1,26Dh,0,32h,4,0
	dw	32h,3,1,30Fh,0,32h,4,0
	dw	32h,3,1,4DBh,0,32h,4,0
	dw	32h,3,1,3A3h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,0Bh,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,3,1,136Ch,0,32h,0Bh,0
	dw	32h,4,77h,26D8h,0,32h,1Ch,0
	dw	32h,3,1,2928h,0,32h,4,0
	dw	32h,3,1,15CCh,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,3,0C3Eh,0,32h,4,0
	dw	32h,6,1,19F0h,0,32h,8,0
	dw	32h,3,3,0CF8h,0,32h,0Bh,0
	dw	32h,6,1,187Ch,0,32h,8,0
	dw	32h,3,3,0E8Ch,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,24ACh,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,26D8h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,3,1,1B7Ch,0,32h,4,0
	dw	32h,3,1,136Ch,0,32h,0Bh,0
	dw	32h,4,77h,26D8h,0,32h,1Ch,0
	dw	32h,6,77h,26D8h,0,32h,8,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,3,0C3Eh,0,32h,4,0
	dw	32h,6,1,19F0h,0,32h,8,0
	dw	32h,3,3,0CF8h,0,32h,0Bh,0
	dw	32h,6,1,187Ch,0,32h,8,0
	dw	32h,3,3,0E8Ch,0,32h,4,0
	dw	32h,3,1,1D18h,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	32h,6,1,1D18h,0,32h,8,0
	dw	32h,3,1,24ACh,0,32h,4,0
	dw	32h,3,1,20A8h,0,32h,4,0
	dw	0
; Sequencer state
chain_count	db	0
tick_div	db	0
vector_saved	db	0
cur_priority	dw	0
tone_repeat	dw	0,0
tone_seq	dw	0
tone_ptr	dw	0
sweep_repeat	dw	0,0
sweep_seq	dw	0
sweep_ptr	dw	0
sweep_count	dw	0
tone_count	dw	0
sweep_div	dw	0
tone_div	dw	0
tone_mask	dw	0
div_step	dw	0
warble_period	dw	0
warble_count	dw	0
param26	dw	0
param27	dw	0
rand_index	dw	0
rand_seed	dw	0
repeat_random	dw	0,0,0
timer_mode	db	0,0,0
noise_seed	db	0,0,0
sound_on	db	0
noise_on	db	0FFh
DATA	ENDS

CODE	SEGMENT
	ASSUME	CS:DGROUP, DS:DATA, ES:NOTHING, SS:NOTHING
; ---- driver header (read by the game's driver loader) -------------------
	db	16 dup (0)
start:				; EXE entry point (the driver is loaded, never run)
drv_ident	db	'CovertActIBM10-12-90'	; name and date
	db	0,0,0,0
drv_code_seg	dw	CODE
drv_data_seg	dw	DATA
drv_data_size	dw	0FD0h		; bytes from DATA to the stack
drv_first_slot	db	100
	db	0
drv_count	dw	11		; number of exports
drv_exports	label	word
	dw	offset isnd_init	; slot 100
	dw	offset isnd_play_sound	; slot 101
	dw	offset isnd_shutdown	; slot 102
	dw	offset isnd_nop103	; slot 103
	dw	offset isnd_noise_tick	; slot 104
	dw	offset isnd_get_ticks	; slot 105
	dw	offset isnd_nop	; slot 106
	dw	offset isnd_nop	; slot 107
	dw	offset isnd_nop	; slot 108
	dw	offset isnd_nop	; slot 109
	dw	offset isnd_nop	; slot 110
; Effect handlers for play_sound(n), n = 0..46
fx_table	dw	offset stop_sound
	dw	offset stop_sound
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
	dw	offset fx_none
	dw	offset fx_none
	dw	offset fx_none
	dw	offset fx_none
	dw	offset fx_none
	dw	offset fx_none
	dw	offset fx_45
	dw	offset fx_46

; ----------------------------------------------------------------------------
; isnd_init (slot 100)
; init(): reset the sequencer, save the timer vector and start the 60 Hz tick.
; ----------------------------------------------------------------------------
isnd_init:
	push	bp
	mov	bp, sp
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	reset_all
	mov	byte ptr sound_on, 0FFh
	pop	ds
	pop	bp
	xor	ax, ax
	retf

; ----------------------------------------------------------------------------
; isnd_shutdown (slot 102)
; shutdown(): silence the speaker and restore the timer.
; ----------------------------------------------------------------------------
isnd_shutdown:
	push	ds
	mov	ax, DATA
	mov	ds, ax
	call	stop_sound
	call	restore_int8
	pop	ds

; ----------------------------------------------------------------------------
; isnd_nop (slot 106/107/108/109/110)
; Slots 106-110 (and the end of shutdown): nothing.
; ----------------------------------------------------------------------------
isnd_nop:
	retf

; ----------------------------------------------------------------------------
; isnd_play_sound (slot 101)
; play_sound(n, param): n = 31 repeats a random variant; 26 and 27 take a
; parameter that selects the pitch of their record.
; ----------------------------------------------------------------------------
isnd_play_sound:
	push	bp
	mov	bp, sp
	mov	bx, word ptr [bp+6]
	push	ds
	mov	ax, DATA
	mov	ds, ax
	cmp	bx, 1Fh
	jne	L_00E4
	mov	word ptr repeat_random, 1
	jmp	L_0115
L_00E4:
	mov	word ptr repeat_random, 0
	cmp	bx, 1Ah
	jne	L_0101
	mov	ax, word ptr [bp+8]
	mov	word ptr param26, ax
	mov	word ptr param27, 0
	call	set_param26
	jmp	L_0115
L_0101:
	cmp	bx, 1Bh
	jne	L_0115
	mov	ax, word ptr [bp+8]
	mov	word ptr param27, ax
	mov	word ptr param26, 0
	call	set_param27
L_0115:
	cmp	bx, 2Eh
	jg	L_0123
	push	di
	shl	bx, 1
	call	word ptr cs:[bx+fx_table]
	pop	di
L_0123:
	pop	ds
	pop	bp
	retf

; ----------------------------------------------------------------------------
; isnd_get_ticks (slot 105)
; Slot 105: number of sequencer ticks so far (tick_count).
; ----------------------------------------------------------------------------
isnd_get_ticks:
	mov	ax, word ptr cs:tick_count
	retf

; ----------------------------------------------------------------------------
; unused_012b
; Not referenced.
; ----------------------------------------------------------------------------
unused_012b:
	pop	bx
	pop	ax
	ret

; ----------------------------------------------------------------------------
; pick_random_31
; Effect 31 repeating: pick one of four pitches at random for its record.
; ----------------------------------------------------------------------------
pick_random_31:
	mov	ax, 4567h
	add	ax, word ptr rand_seed
	ror	ax, 1
	ror	ax, 1
	ror	ax, 1
	mov	word ptr rand_seed, ax
	and	ax, 4
	shr	ax, 1
	shr	ax, 1
	mov	word ptr rand_index, ax
	push	si
	lea	bx, rand_record
	lea	si, rand_pitches
	mov	ax, word ptr rand_index
	shl	ax, 1
	shl	ax, 1
	add	si, ax
	mov	ax, word ptr [si]
	mov	word ptr [bx+4], ax
	mov	ax, word ptr [si+2]
	mov	word ptr [bx+0Ch], ax
	pop	si
	ret

; ----------------------------------------------------------------------------
; set_param26
; ----------------------------------------------------------------------------
set_param26:
	push	si
	lea	bx, fx26_record
	lea	si, param_pitches
	mov	ax, word ptr param26
	shl	ax, 1
	shl	ax, 1
	add	si, ax
	mov	ax, word ptr [si]
	mov	word ptr [bx+2], ax
	mov	ax, word ptr [si+2]
	mov	word ptr [bx+6], ax
	pop	si
	ret

; ----------------------------------------------------------------------------
; set_param27
; ----------------------------------------------------------------------------
set_param27:
	push	si
	lea	bx, fx27_record
	lea	si, param_pitches
	mov	ax, word ptr param27
	shl	ax, 1
	shl	ax, 1
	add	si, ax
	mov	ax, word ptr [si]
	mov	word ptr [bx+2], ax
	mov	ax, word ptr [si+2]
	mov	word ptr [bx+6], ax
	pop	si
	ret

; ----------------------------------------------------------------------------
; isnd_nop103 (slot 103)
; Slot 103: nothing.
; ----------------------------------------------------------------------------
isnd_nop103:
	retf
tick_count	dw	0
warble_step:
	cmp	word ptr sweep_div, 0
	je	L_01D4
	dec	word ptr warble_count
	cmp	word ptr warble_count, 0
	jg	L_01D4
	mov	ax, word ptr warble_period
	mov	word ptr warble_count, ax
	neg	word ptr tone_mask
	mov	ax, word ptr sweep_div
	add	ax, word ptr tone_mask
	out	42h, al
	mov	word ptr sweep_div, ax
	mov	al, ah
	out	42h, al
L_01D4:
	retf

; ----------------------------------------------------------------------------
; isnd_noise_tick (slot 104)
; Slot 104 (also called by the fast timer handler): play the next step of
; the noise generator or the warble.
; ----------------------------------------------------------------------------
isnd_noise_tick:
	cmp	byte ptr noise_on, 0FFh
	jne	L_0201
	cmp	word ptr warble_period, 0
	jne	warble_step
	mov	ax, 9248h
	add	ax, word ptr noise_seed
	ror	ax, 1
	ror	ax, 1
	ror	ax, 1
	mov	word ptr noise_seed, ax
	and	ax, word ptr tone_mask
	add	ax, word ptr tone_div
	out	42h, al
	mov	al, ah
	out	42h, al
L_0201:
	retf

; ----------------------------------------------------------------------------
; reset_all
; ----------------------------------------------------------------------------
reset_all:
	call	stop_sound
	call	save_int8
	jmp	timer_slow

; ----------------------------------------------------------------------------
; stop_sound
; Clear the sequencer and turn the speaker off.
; ----------------------------------------------------------------------------
stop_sound:
	mov	word ptr param26, 0
	mov	word ptr param27, 0
	mov	word ptr sweep_div, 0
	mov	word ptr div_step, 0
	mov	word ptr sweep_count, 0
	mov	word ptr tone_count, 0
	mov	word ptr cur_priority, 0
	mov	word ptr tone_repeat, 0
	mov	word ptr sweep_repeat, 0
	mov	word ptr warble_period, 0
	mov	word ptr warble_count, 0
	lea	bx, silence
	mov	word ptr tone_ptr, bx
	mov	word ptr sweep_ptr, bx
speaker_off:
	in	al, 61h
	and	al, 0FCh
	out	61h, al

; ----------------------------------------------------------------------------
; fx_none
; ----------------------------------------------------------------------------
fx_none:
	ret
L_0260:
	jmp	L_0321

; ----------------------------------------------------------------------------
; sound_tick
; Sequencer step, called from the timer handlers.
; ----------------------------------------------------------------------------
sound_tick:
	inc	word ptr cs:tick_count
	cmp	byte ptr sound_on, 0FFh
	jne	fx_none
	mov	ax, word ptr sweep_count
	or	ax, word ptr sweep_repeat
	jne	L_0260
	mov	ax, word ptr tone_count
	or	ax, word ptr tone_repeat
	je	L_02F7
	dec	word ptr tone_count
	cmp	word ptr tone_count, 0
	jne	L_0298
	mov	bx, word ptr tone_ptr
	cmp	word ptr [bx], 0
	je	L_02F2
	jmp	next_tone
L_0298:
	cmp	word ptr tone_mask, 0
	je	L_02F1
	cmp	word ptr tone_count, 1
	jne	L_02C5
	mov	bx, word ptr tone_ptr
	cmp	word ptr [bx], 0
	jne	L_02C5
	cmp	word ptr tone_repeat, 0
	jne	L_02C5
	xor	ax, ax
	mov	word ptr div_step, ax
	mov	word ptr noise_seed, ax
	dec	ax
	mov	word ptr tone_div, ax
	mov	word ptr tone_mask, ax
L_02C5:
	mov	ax, word ptr div_step
	add	word ptr tone_div, ax
	cmp	word ptr tone_count, 0
	je	L_02F1
	mov	ax, 9248h
	add	ax, word ptr noise_seed
	ror	ax, 1
	ror	ax, 1
	ror	ax, 1
	mov	word ptr noise_seed, ax
	and	ax, word ptr tone_mask
	add	ax, word ptr tone_div

; ----------------------------------------------------------------------------
; set_divisor
; AX = PIT channel 2 divisor (the speaker's pitch).
; ----------------------------------------------------------------------------
set_divisor:
	out	42h, al
	mov	al, ah
	out	42h, al
L_02F1:
	ret
L_02F2:
	cmp	word ptr tone_repeat, 0
L_02F7:
	je	L_030A
	dec	word ptr tone_repeat
	mov	bx, word ptr tone_seq
	jmp	next_tone
L_0304:
	mov	word ptr warble_period, 0
L_030A:
	cmp	word ptr repeat_random, 0
	je	L_031B
	call	pick_random_31
	lea	bx, rand_record
	jmp	next_tone
L_031B:
	call	stop_sound
	jmp	timer_slow
L_0321:
	dec	word ptr sweep_count
	cmp	word ptr sweep_count, 0
	jne	L_0338
	mov	bx, word ptr sweep_ptr
	cmp	word ptr [bx], 0
	je	L_0350
	jmp	next_sweep
L_0338:
	cmp	word ptr sweep_div, 0
	je	L_02F1
	mov	ax, word ptr div_step
	add	word ptr sweep_div, ax
	mov	ax, word ptr sweep_div
	push	ax
	call	speaker_on
	pop	ax
	jmp	set_divisor
L_0350:
	cmp	word ptr sweep_repeat, 0
	je	L_0304
	dec	word ptr sweep_repeat
	mov	bx, word ptr sweep_seq
	jmp	next_sweep
	db	50h,51h,0A1h,93h,0Fh,3Bh,7,59h,58h,77h,1Dh,89h,0Eh,0B1h,0Fh,0EBh
	db	10h
	EVEN
; BX = sweep records, CX = warble period.
play_sweep:
	push	cx
	mov	ax, word ptr cur_priority
	cmp	ax, word ptr [bx]
	pop	cx
	ja	L_038A
	mov	word ptr warble_period, cx
	xor	ax, ax
	push	ax
	mov	ax, word ptr cur_priority
	cmp	ax, word ptr [bx]
	pop	ax
L_038A:
	ja	L_03EC
	mov	word ptr tone_count, 0
	mov	word ptr tone_repeat, 0
	mov	word ptr sweep_repeat, ax
	lea	ax, silence
	mov	word ptr tone_seq, ax
	mov	word ptr sweep_seq, bx
next_sweep:
	mov	ax, word ptr [bx]
	mov	word ptr cur_priority, ax
	inc	bx
	inc	bx
	mov	ax, word ptr [bx]
	mov	word ptr sweep_count, ax
	inc	bx
	inc	bx
	mov	ax, word ptr [bx]
	mov	word ptr sweep_div, ax
	inc	bx
	inc	bx
	cmp	ax, 0
	je	L_03E5
	sub	ax, word ptr [bx]
	mov	word ptr tone_mask, ax
	inc	bx
	inc	bx
	mov	ax, word ptr [bx]
	mov	word ptr div_step, ax
	inc	bx
	inc	bx
	mov	word ptr sweep_ptr, bx
	call	speaker_on
	mov	ax, word ptr sweep_div
	call	set_divisor
	cmp	word ptr warble_period, 0
	je	L_03EC
	jmp	timer_fast
L_03E5:
	mov	word ptr sweep_ptr, bx
	jmp	speaker_off
L_03EC:
	ret

; ----------------------------------------------------------------------------
; play_tones
; BX = tone records, AX = repeat count: start them unless a higher priority sound plays.
; ----------------------------------------------------------------------------
play_tones:
	xor	ax, ax

; ----------------------------------------------------------------------------
; play_tones_n
; ----------------------------------------------------------------------------
play_tones_n:
	push	ax
	mov	ax, word ptr cur_priority
	cmp	ax, word ptr [bx]
	pop	ax
	ja	L_03EC
	mov	word ptr warble_period, 0
	mov	word ptr sweep_count, 0
	mov	word ptr sweep_repeat, 0
	mov	word ptr tone_repeat, ax
	lea	ax, silence
	mov	word ptr sweep_seq, ax
	mov	word ptr tone_seq, bx
next_tone:
	mov	word ptr noise_seed, 0
	mov	ax, word ptr [bx]
	mov	word ptr cur_priority, ax
	inc	bx
	inc	bx
	mov	ax, word ptr [bx]
	mov	word ptr tone_count, ax
	inc	bx
	inc	bx
	mov	ax, word ptr [bx]
	mov	word ptr tone_mask, ax
	inc	bx
	inc	bx
	cmp	ax, 0
	jne	L_043F
	mov	word ptr tone_ptr, bx
	jmp	speaker_off
L_043F:
	mov	ax, word ptr [bx]
	mov	word ptr tone_div, ax
	inc	bx
	inc	bx
	mov	ax, word ptr [bx]
	mov	word ptr div_step, ax
	inc	bx
	inc	bx
	mov	word ptr tone_ptr, bx
	call	timer_fast

; ----------------------------------------------------------------------------
; speaker_on
; ----------------------------------------------------------------------------
speaker_on:
	mov	al, 0B6h
	out	43h, al
L_0458:
	in	al, 61h
	or	al, 3
	out	61h, al
	ret

; ----------------------------------------------------------------------------
; fx_37
; ----------------------------------------------------------------------------
fx_37:
	mov	byte ptr sound_on, 0
	mov	byte ptr noise_on, 0
	jmp	speaker_off

; ----------------------------------------------------------------------------
; fx_38
; ----------------------------------------------------------------------------
fx_38:
	mov	byte ptr sound_on, 0FFh
	mov	byte ptr noise_on, 0FFh
	jmp	L_0458

; ----------------------------------------------------------------------------
; fx_2
; ----------------------------------------------------------------------------
fx_2:
	mov	ax, 4
	lea	bx, fx_2_data
	mov	cx, 0FFFFh
	jmp	play_tones_n

; ----------------------------------------------------------------------------
; fx_33
; ----------------------------------------------------------------------------
fx_33:
	lea	bx, fx_33_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_34
; ----------------------------------------------------------------------------
fx_34:
	lea	bx, fx_34_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_35
; ----------------------------------------------------------------------------
fx_35:
	lea	bx, fx_35_data
	mov	ax, 0FFh
	call	play_tones_n
	lea	bx, w_D0072
	mov	word ptr tone_seq, bx
	ret

; ----------------------------------------------------------------------------
; fx_36
; ----------------------------------------------------------------------------
fx_36:
	lea	bx, fx_36_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_3
; ----------------------------------------------------------------------------
fx_3:
	lea	bx, fx_3_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_4
; ----------------------------------------------------------------------------
fx_4:
	lea	bx, fx_4_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_5
; ----------------------------------------------------------------------------
fx_5:
	lea	bx, fx_5_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_45
; ----------------------------------------------------------------------------
fx_45:
	lea	bx, fx_45_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_46
; ----------------------------------------------------------------------------
fx_46:
	lea	bx, fx_46_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_6
; ----------------------------------------------------------------------------
fx_6:
	lea	bx, fx_6_data
	mov	ax, 7
	jmp	play_tones_n

; ----------------------------------------------------------------------------
; fx_7
; ----------------------------------------------------------------------------
fx_7:
	lea	bx, fx_7_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_8
; ----------------------------------------------------------------------------
fx_8:
	lea	bx, fx_8_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_9
; ----------------------------------------------------------------------------
fx_9:
	lea	bx, fx_9_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_10
; ----------------------------------------------------------------------------
fx_10:
	lea	bx, fx_10_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_11
; ----------------------------------------------------------------------------
fx_11:
	lea	bx, fx_11_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_12
; ----------------------------------------------------------------------------
fx_12:
	lea	bx, fx_12_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_13
; ----------------------------------------------------------------------------
fx_13:
	lea	bx, fx_13_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_14
; ----------------------------------------------------------------------------
fx_14:
	lea	bx, fx_14_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_15
; ----------------------------------------------------------------------------
fx_15:
	lea	bx, fx_15_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_16
; ----------------------------------------------------------------------------
fx_16:
	lea	bx, fx_16_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_17
; ----------------------------------------------------------------------------
fx_17:
	lea	bx, fx_17_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_18
; ----------------------------------------------------------------------------
fx_18:
	lea	bx, fx_18_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_19
; ----------------------------------------------------------------------------
fx_19:
	lea	bx, fx_19_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_20
; ----------------------------------------------------------------------------
fx_20:
	lea	bx, fx_20_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_21
; ----------------------------------------------------------------------------
fx_21:
	lea	bx, fx_21_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_22
; ----------------------------------------------------------------------------
fx_22:
	lea	bx, fx_22_data
	mov	ax, 2
	jmp	play_tones_n

; ----------------------------------------------------------------------------
; fx_23
; ----------------------------------------------------------------------------
fx_23:
	lea	bx, fx_23_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_24
; ----------------------------------------------------------------------------
fx_24:
	lea	bx, fx_24_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_25
; ----------------------------------------------------------------------------
fx_25:
	lea	bx, fx_25_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_26
; ----------------------------------------------------------------------------
fx_26:
	ret

; ----------------------------------------------------------------------------
; fx_27
; ----------------------------------------------------------------------------
fx_27:
	ret

; ----------------------------------------------------------------------------
; fx_28
; ----------------------------------------------------------------------------
fx_28:
	lea	bx, fx_26_data
	call	play_tones
	jmp	wait_sound_end

; ----------------------------------------------------------------------------
; fx_29
; ----------------------------------------------------------------------------
fx_29:
	lea	bx, fx_29_data
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_30
; ----------------------------------------------------------------------------
fx_30:
	lea	bx, fx_30_data
	mov	cx, 1
	jmp	play_sweep

; ----------------------------------------------------------------------------
; fx_31
; ----------------------------------------------------------------------------
fx_31:
	lea	bx, rand_record
	jmp	play_tones

; ----------------------------------------------------------------------------
; fx_32
; ----------------------------------------------------------------------------
fx_32:
	lea	bx, fx_32_data
	jmp	play_tones
wait_sound_end:
	mov	bx, 0
	mov	bx, word ptr tone_repeat
	or	bx, word ptr sweep_repeat
	or	bx, word ptr tone_count
	or	bx, word ptr sweep_count
	cmp	bx, 0
	jne	wait_sound_end
	ret
old_int8	db	0,0
w_05C0	dw	0
; Int 8 handler at about 300 Hz: the sequencer every 5th tick, the noise
; generator otherwise; the BIOS handler every 16th tick.
fast_timer_isr:
	push	ax
	push	ds
	mov	ax, DATA
	mov	ds, ax
	dec	byte ptr tick_div
	jne	L_05DE
	mov	byte ptr tick_div, 5
	push	bx
	push	cx
	call	sound_tick
	pop	cx
	pop	bx
	jmp	L_05E3
L_05DE:
	call	far ptr isnd_noise_tick
L_05E3:
	dec	byte ptr chain_count
	je	L_05F0
	pop	ds
	mov	al, 20h
	out	20h, al
	pop	ax
	iret
L_05F0:
	mov	byte ptr chain_count, 10h
	pop	ds
	pop	ax
	jmp	dword ptr cs:old_int8
; Int 8 handler at about 60 Hz: the sequencer, and the BIOS handler every 3rd tick.
slow_timer_isr:
	push	ax
	push	ds
	mov	ax, DATA
	mov	ds, ax
	push	bx
	push	cx
	call	sound_tick
	pop	cx
	pop	bx
	dec	byte ptr tick_div
	je	L_0617
	pop	ds
	mov	al, 20h
	out	20h, al
	pop	ax
	iret
L_0617:
	mov	byte ptr tick_div, 3
	pop	ds
	pop	ax
	jmp	dword ptr cs:old_int8

; ----------------------------------------------------------------------------
; timer_fast
; ----------------------------------------------------------------------------
timer_fast:
	cmp	byte ptr timer_mode, 1
	je	L_0654
	mov	byte ptr timer_mode, 1
	cli
	mov	byte ptr chain_count, 10h
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
	sti
L_0654:
	ret
timer_slow:
	cmp	byte ptr timer_mode, 0FFh
	je	L_0654
	mov	byte ptr timer_mode, 0FFh
	cli
	mov	byte ptr tick_div, 3
	push	ds
	xor	ax, ax
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
	sti
	ret

; ----------------------------------------------------------------------------
; save_int8
; ----------------------------------------------------------------------------
save_int8:
	cmp	byte ptr vector_saved, 0
	jne	L_06AD
	mov	byte ptr vector_saved, 0FFh
	cli
	push	ds
	sub	ax, ax
	mov	ds, ax
	mov	bx, word ptr ds:[20h]
	mov	cx, word ptr ds:[22h]
	pop	ds
	mov	word ptr cs:old_int8, bx
	mov	word ptr cs:w_05C0, cx
	sti
L_06AD:
	ret

; ----------------------------------------------------------------------------
; restore_int8
; ----------------------------------------------------------------------------
restore_int8:
	cmp	byte ptr vector_saved, 0
	je	L_06AD
	mov	byte ptr vector_saved, 0
	mov	byte ptr timer_mode, 0
	cli
	push	ds
	mov	bx, word ptr cs:old_int8
	mov	cx, word ptr cs:w_05C0
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

 ; Guru Logic Champ - Name Entry Screen tweaks
 ; by Spikeman

.gba
.open "rom/output.gba",0x08000000
.thumb

; first, load the graphics for ABC input instead of kana:

; load ABC tiles instead of hirigana tiles
.org 0x08017AD4
	.dcd 0x082779C4 ; change ldr at 80178E0

; load ABC tilemap instead of hirigana tilemap
.org 0x08017B04
	.dcd 0x083848FC ; change ldr at 801793A
	
; make it so we're always on the ABC screen as far as typing is concerned
.org 0x0801814C
	mov r2, 2	; hirigana = 0, katakana = 1, ABC = 2; was a ldrh
	
; disable changing of pages
.org 0x08017FDC
	b 0x080180C4	; was beq if r5 = 0 (r5 = 1 or -1 if changing page)
	
; don't display L and R arrows - same routine set both arrows, so only need to change one
.org 0x08017A9A
	nop		;was bl 0x08001148 - create sprite
	nop

.close

 ; make sure to leave an empty line at the end
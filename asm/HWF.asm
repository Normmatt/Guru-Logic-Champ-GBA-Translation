 ; Guru Logic Champ HWF
 ; by Spikeman

.gba				; Set the architecture to GBA
.open "rom/output.gba",0x08000000		; Open input.gba for output.
					; 0x08000000 will be used as the
					; header size
					
.macro adr,destReg,Address
here:
	.if (here & 2) != 0
		add destReg, r15, (Address-here)-2
	.else
		add destReg, r15, (Address-here)
	.endif
.endmacro

.thumb

; note this replaces it bitmasking off the end, presumably to set shape to 0 so that it sets it to verticle
.org 0x08003E30
	mov r0, #0x80
	orr r0, r1
	nop
	
.org 0x08003E98
	mov r0, #0x40
	mul r0, r2
	add r0, r0, r1
	ldrh r1, [r3]
	ldr r2, =HWF_Main+1
    mov r3, pc
    bx r2
    b 0x08003EF4
	
.pool
	
.org 0x08003EFE
	;add r1, #1
	add r1, #2
	
.org 0x08003F2E
	;adds    r0, r2, #0
	;adds    r0, #0x2c
	;ldrb    r0, [r0]

	bl getWidth
	nop
	
	;8010D7A stores 01 to 3000DBA when intro screen starts
	;1 is hardcoded but used twice, store r4,r6 instead (they are 0)
.org 0x08010D7A
	;strb r1, [r0]
	;add r0, #2
	;mov r2, #0x10
	;strb r2, [r0]
	;add r0, #1

	strb r6, [r0]
	mov r2, #8
	strb r2, [r0,#2]
	mov r2, #0x10
	add r0, #3
	
.org 0x08010DC4
	;.dcd 0x08274078
	.dcd 0x08243190

	;hardcoded 58 change to 5b
.org 0x0801100E
	.db 0x5B
.org 0x08011034
	.db 0x5B
.org 0x8011724
	.db 0x5B
.org 0x8011D08
	.db 0x5B

	;80115D6 stores 01 to 3000DBA when 2nd rule dialogue loads
	;1 is hardcoded but used twice, store r4 (it's 0)
.org 0x080115D6
	;strb r1, [r0]
	;add r0, #2
	;mov r2, #0x10
	;strb r2, [r0]
	;add r0, #1
	;strb r2, [r0]

	strb r4, [r0]
	add r0, #2
	mov r2, #8
	strb r2, [r0]
	mov r2, #0x10
	strb r2, [r0,#1]
	
.org 0x08011624
	;.dcd 0x08274078
	.dcd 0x08243190

.org 0x08011BBA
	;strb r1, [r0]
	;add r0, #2
	;mov r2, #0x10
	;strb r2, [r0]
	;add r0, #1
	;strb r2, [r0]

	strb r4, [r0]
	add r0, #2
	mov r2, #8
	strb r2, [r0]
	mov r2, #0x10
	strb r2, [r0,#1]

.org 0x08011C08
	;.dcd 0x08274078
	.dcd 0x08243190

.pool

.org 0x083D6000
getWidth:
	;r0 and r1 are free
	ldr r0, [sp]
	
getWidth_CheckSpace:
	ldr r1, [space]
	cmp r0, r1
	bne getWidth_CheckApostrophe
	
	mov r0, #5
	b getWidth_Exit
	
getWidth_CheckApostrophe:
	ldr r1, [apostrophe]
	cmp r0, r1
	bne getWidth_Return
	
	mov r0, #5
	b getWidth_Exit

getWidth_Return:
	mov r0, #8
	
getWidth_Exit:
	bx lr
	
.align 4
space: .dw 0x4081
apostrophe: .dw 0x6681
	
HWF_Main:
	lsl r1,r1,0x16		;original routine
	lsr r1,r1,0x11
	ldr r2,=0x6010000
	add r1,r1,r2

	ldr r2,=0x40000D4	;DMA3
	str r0,[r2]		;source in r0
	str r1,[r2,0x4]		;tiledata addr
	ldr r0,=0x80000040	;enable DMA 40bytes
	str r0,[r2,0x8]

    mov r15,r3		;return
	
.pool
.close

 ; make sure to leave an empty line at the end
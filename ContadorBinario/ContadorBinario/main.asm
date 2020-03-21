;
; ContadorBinario.asm
;
; Created: 21/03/2020 19:05:28
; Author : SaFteiNZz
;

ldi r16, 0xFF
out ddrb, r16
clr r16

start:
	; 1s 400ms at 16 MHz

    ldi  r18, 114
    ldi  r19, 163
    ldi  r20, 156
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1

	out portb, r16
    inc r16
    rjmp start

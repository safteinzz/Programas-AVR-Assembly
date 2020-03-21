;
; Blink led 13.asm
;
; Created: 21/03/2020 20:36:31
; Author : SaFteiNZz
;


ldi r16, 0x80
out ddrb, r16
clr r16

start:
	ldi r16, 0x80
	out portb, r16
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

	clr r16
	out portb, r16

	ldi  r18, 114
    ldi  r19, 163
    ldi  r20, 156
L2: dec  r20
    brne L2
    dec  r19
    brne L2
    dec  r18
    brne L2

    rjmp start


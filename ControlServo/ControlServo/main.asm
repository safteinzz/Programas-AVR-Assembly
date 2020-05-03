;
; ControlServo.asm
;
; Created: 26/04/2020 16:46:40
; Author : SaFteiNZz
;
;http://blog.grozak.com/2013/09/29/01-atmega328p-pu-and-sm-s2309s-servo/

sbi ddrb, 6
start:
 
ldi r17, 75
cerogrados:
    sbi portb, 6
    call delay1ms
    cbi portb, 6
    call delay18ms
    dec r17
    brne cerogrados
 
ldi r17, 75
cientoochentagrados:
    sbi portb, 6
    call delay2ms
    cbi portb, 6
    call delay18ms
    dec r17
    brne cientoochentagrados
 
ldi r17, 75
centrogrados:
    sbi portb, 6
    call delay1500ms
    cbi portb, 6
    call delay18ms
    dec r17
    brne centrogrados
 
    rjmp start
 
 
; 1ms at 16 MHz
delay1ms:
    ldi  r18, 16
    ldi  r19, 149
d1: dec  r19
    brne d1
    dec  r18
    brne d1
    ret
 
; 2ms at 16 MHz
delay2ms:
    ldi  r18, 47
    ldi  r19, 192
d2: dec  r19
    brne d2
    dec  r18
    brne d2
    nop
    ret
 
delay18ms:
    ldi  r18, 2
    ldi  r19, 119
    ldi  r20, 4
d3: dec  r20
    brne d3
    dec  r19
    brne d3
    dec  r18
    brne d3
    ret
 
    ; 1ms 500us at 16 MHz
delay1500ms:
    ldi  r18, 32
    ldi  r19, 42
d4: dec  r19
    brne d4
    dec  r18
    brne d4
    nop
    ret
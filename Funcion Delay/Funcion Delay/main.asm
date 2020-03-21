;
; Funcion Delay.asm
;
; Created: 21/03/2020 20:47:27
; Author : SaFteiNZz
;

ldi r21, 0xff
out ddrd, r21

ldi r16, 0b10000000
out portb, r16

; Replace with your application code
start:
	ldi r22, 7 ;configuramos las veces que se va a repetir el for

forDerecha: ;for, mover uno de izquierda a derecha
	
	LDI R23, 5 ;Cargamos el parámetro en el registro
	PUSH R23 ;Guardamos el registro en la pila
	RCALL fncDelayParam //llamada de funcion
	POP R23
	
    LSR r16 ;desplazamos el numero del registro 16 un byte a la derecha
	out portb, r16 ;lo enviamos al puerto d
	DEC r22 ;decremos uno el registro 22
	BRNE forDerecha ;si el valor anterior no es 0 volvemos al forDerecha

	ldi r22, 7

forIzquierda: ;for mover uno de derecha a izquierda

	LDI R23, 10 ;Cargamos el parámetro en el registro
	PUSH R23 ;Guardamos el registro en la pila
	RCALL fncDelayParam //llamada de funcion
	POP R23
	
	LSL r16 ;mover el uno hacia la izquierda
	out portb, r16

	DEC r22 ;decrementar el numero del for
	BRNE forIzquierda

    rjmp start ;volver a empezar


; funcion delay con parametro
fncDelayParam:
	PUSH YH
	PUSH YL
	IN YL, SPL
	IN YH, SPH
	PUSH R23

	LDD R23, Y+5

forDelay:
	;delay 100ms
	ldi  r18, 5
    ldi  r19, 15
    ldi  r20, 242
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1	

		DEC R23

	BRNE forDelay

	POP R23
	POP YL
	POP YH
	RET

;fin fncDelayParam

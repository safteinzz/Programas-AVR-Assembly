;
; Funcion Delay.asm
;
; Created: 21/03/2020 20:47:27
; Author : SaFteiNZz
;

ldi r16, 0xFF
out DDRF, r16
clr r16

; Pongo el primer bit a 1 para poder moverlo
ldi r16, 0x80
out PORTF, r16

; Replace with your application code
start:
	ldi r22, 7 ; nº de repeticiones

forDerecha:
	
	LDI R23, 1
	PUSH R23
	RCALL fncDelayParam
	POP R23
	
    LSR r16 ; Mover bit a la derecha
	out PORTF, r16
	DEC r22
	BRNE forDerecha

	ldi r22, 7

forIzquierda:

	LDI R23, 10
	PUSH R23
	RCALL fncDelayParam
	POP R23
	
	LSL r16 ; Mover bit a la izquierda
	out PORTF, r16

	DEC r22
	BRNE forIzquierda

    rjmp start


; funcion delay con parametro
fncDelayParam:
	PUSH YH ; Guardar parte alta de Y en la pila
	PUSH YL ; Guardar parte baja de Y en la pila
	IN YL, SPL ; Inicializamos Y a SP : Parte alta
	IN YH, SPH ; Inicializamos Y a SP : Parte baja
	PUSH R23 ; Backup

	LDD R23, Y+6 ; Metemos el parametro en R23

forDelay:
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

	; Quitar de la pila
	POP R23
	POP YL
	POP YH
	; Retornar
	RET

;fin fncDelayParam

;
; BlinkEchoParImpar.asm
;
; Created: 03/04/2020 21:39:49
; Author : SaFteiNZz
;

.EQU Clock = 16000000                   ;frecuencia de reloj, en Hz
.EQU Baud = 9600                        ;velocidad de transmisión deseada (bits por segundo)
.EQU UBRRvalue = Clock / ( Baud * 16 ) - 1  ;formula para calcula el valor que se colocará en UBRR0H:L
 
.EQU LED_PERMABLINK = 0 ; Led que se enciende y apaga todo el rato
.EQU LED_PAR = 7 ; Led que se enciende y apaga dependiendo si es par o impar respectivamente

.ORG 0x0000                             ;punto de entrada en el inicio del sistema
    JMP PPrincipal                      ;ir al programa princiapal para saltar el Vector de Interrupciones
 
.ORG 0x0032                             ;puntos de entrada en vectores de interrupción para USART0
    JMP USART0_reception_completed      ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
    RETI                                ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
    RETI					            ;saltar a la rutina de manejo de interrupciones cuando ocurre este INT
 
;.org 0x0100     si dejo esta linea no funciona nada                       ;Fin del espacio reservado para el Vector de Interrupciones

/************************************************************************************
    Programa principal
************************************************************************************/

PPrincipal:   

	ldi r16, (1 << LED_PERMABLINK)|(1 << LED_PAR) ; Tambien se puede hacer en dos pasos con un ldi y un ori como muestra el ejemplo del init usart
	out DDRF, r16	
	clr r16

	RCALL init_USART0               ;llamada a la funcion de configuración de la USART
	SEI                             ;habilitar interrupciones glovales

loop:
	sbi PORTF, LED_PERMABLINK
	call delay1sec
	cbi PORTF, LED_PERMABLINK
	call delay1sec	
	RJMP loop
	
init_USART0:                                  
        ;cargar en UBRR el valor para obtener la velocidad de transmisión deseada
        PUSH r16
        LDI R16, LOW(UBRRvalue)     ; Low byte of Vaud Rate
        STS UBRR0L, R16             ; UBRR0L - USART Baud Rate Register Low Byte
        LDI R16, HIGH(UBRRvalue)    ; High byte of Vaud Rate
        STS UBRR0H, R16             ; UBRR0H - USART Baud Rate Register High Byte
        ;habilitar recibir y transmitir, habilitar interrupcion USART0 "Rx terminado" (No las: UDR vacío, Tx terminado)
        ldi r16, (1<<RXCIE0)        ; RX Complete Interrupt Enable
        ori r16, (1<<RXEN0)         ; Receiver Enable
        ori r16, (1<<TXEN0)         ; Transmitter Enable
        STS UCSR0B, R16             ; UCSR0B - USART Control and Status Register B
        ; configure USART 0 como asíncrono, establezca el formato de trama ->
        ; -> 8 bits de datos, 1 bit de parada, sin paridad
        ldi r16, (3<<UCSZ00)        ; Character Size = 8 bits
        STS UCSR0C, R16             ; UCSR0C - USART Control and Status Register C
        POP r16
        RET


/************************************************************************************
    Funcion de atencion de la interrupcion de Dato recibido por USART
    Se dispara cuando un nuevo byte está listo en el registro UDR0
************************************************************************************/
USART0_reception_completed:
    PUSH R16
    IN R16, SREG                ; Copia de seguridad SREG. OBLIGATORIO en las rutinas de manejo de interrupciones
    PUSH R16
    ; **** Aqui empieza el cuerpo de la funcion de atencion de la interrupcion
    LDS R16, UDR0               ; recoger el byte recibido para procesarlo

	//HACER EL ECHO
	PUSH R16
	rcall ECHO
	POP R16

	//ECHO HECHO

	//ILUMINAR LED SI PAR, APAGAR SI IMPAR, TOGGLEAR SI NUM = 0

	CPI R16, 0b00110000 ; 0b00110000
	BRNE NoEsCero ; Si es cero hay que toglear el bit del led simplemente no hace falta comparar si es par o no

	

	SiEsCero:		
		IN r18, PINF
		ANDI r18, 0x80
		BRNE EstaEncendido
		
		EstaApagado:
			sbi PORTF, LED_PAR
			rjmp fin
		EstaEncendido:
			cbi PORTF, LED_PAR  
			
		rjmp fin


	NoEsCero:
		principio_if:
			andi r16, 0x01          ;Limpiamos el valor recibido, nos quedamos con el último bit
			brne else_if            ;Si es uno nos vamos al else
			sbi PORTF, LED_PAR      ;Apagamos el led integrado Ard.UNO
			rjmp fin             ;desde el then saltamos el else
		else_if:                    ;Parte ELSE
			cbi PORTF, LED_PAR      ;Encendemos el LED  integrado Ard.Uno


	fin:
		; **** Fin del cuerpo de la funcion de atencion de la interrupcion
		POP R16
		OUT SREG, R16               ; Recuperar SREG de la copia de seguridad anterior
		POP R16
		RETI                        ; RETI es OBLIGATORIO al regresar de una rutina de manejo de interrupciones



ECHO:
	PUSH YH ; bckp reg. Y parte alta
	PUSH YL ; bckp reg. Y parte baja
	IN YL, SPL ; inicia reg a la cima de la pila
	IN YH, SPH ; inicia reg a la cima de la pila
	PUSH r16 ; bckp R16
	LDD r16, Y+6 ; sacamos var1 de la pila
	inc r16
	TX:
		; Wait for empty transmit buffer
		lds r17,UCSR0A			;Load into R17 from SRAM UCSR0A			
		sbrs r17,UDRE0 			;Skip next instruction If Bit Register is set
		rjmp TX
	; Put data (r0) into buffer, sends the data
	sts UDR0,r16

    POP r16 ; Restauramos r16 antes de terminar
	POP YL ; Restauramos YL antes de terminar
	POP YH ; Restauramos YH antes de terminar
	RET



delay1sec:
		ldi  r18, 82
		ldi  r19, 43
		ldi  r20, 0
	L1: dec  r20
		brne L1
		dec  r19
		brne L1
		dec  r18
		brne L1
		lpm
		nop
		ret
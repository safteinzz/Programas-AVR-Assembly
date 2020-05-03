;
; Atenuador.asm
;
; Created: 19/04/2020 15:45:30
; Author : SaFteiNZz
;

;seteo del timer 1 segundo -> calculadora de timer https://eleccelerator.com/avr-timer-calculator/
.equ timer = 0xC2F7 ; 16000000 / 1024 rescaler = 15625 tics -> C2F7

;seteo del serial
.EQU Clock = 16000000						;frecuencia de reloj, en Hz
.EQU Baud = 9600							;velocidad de transmisión deseada (bits por segundo)
.EQU UBRRvalue = Clock / ( Baud * 16 ) - 1  ;formula para calcula el valor que se colocará en UBRR0H:L
 
.ORG 0x0000                             ;punto de entrada en el inicio del sistema
    RJMP PPrincipal                     ;ir al programa princiapal para saltar el Vector de Interrupciones
 
.ORG 0x0028                             ;vector overflow timer 1 para sacar el valor cada 1 seg
    RJMP mostrarValor
    RETI

/************************************************************************************
    Programa principal
************************************************************************************/
PPrincipal:
	RCALL config_timer1				;Configurar timer 1 para el ECHO
	RCALL config_ADC				;Configurar el conversos ADC
	RCALL config_PWM				;Configurar el timer 0 para PWM
	RCALL init_USART0               ;Configurar puerto serial USART0
	SEI                             ;habilitar interrupciones glovales

loopGeneral:
    ;Disparo de la lectura
    LDS R17, ADCSRA             ; -> ADCSRA: The ADC Control and Status register A
    ori r17, (1<<ADSC)          ;Aciva el bit de la conversion ADC por software
    sts ADCSRA, R17             ;Dispara la Operacion ADC

	esperaADC:
		;Espera activa hasta que la lectura termine
		clr r17
		lds r17, ADCSRA             ;Carga ek registro ADCSRA para chequear si la conversion ha terminado
		sbrc r17, ADSC              ;Si el bit ADSC esta activo, la conversion no ha terminado, entonces saltar RJMP
		rjmp esperaADC
 
	;Cargar el valor de la conversion
	LDS R16, ADCH               ;En ADCH, tenemos el valor de la conversion con 8 bits.
	
	
	COM r16 ;Invertir r16
	
	;Iluminar en funcion del valor
	out OCR0A, r16
	rjmp loopGeneral
 

/*************************************************************************************
  Funcion inicializa timer 1 contar 1 segundo  y lanzar overflow
**************************************************************************************/
config_timer1:	
	push r16	
	/* SI dejo esto no va
	ldi r16,HIGH(RAMEND) ;Initiate Stackpointer
	sts SPH,r16 ; for the use by interrupts and subroutines
	ldi r16,LOW(RAMEND)
	sts SPL,r16
	*/
	
	ldi r16, HIGH(timer)
	sts TCNT1H, r16

	ldi r16, LOW(timer)
	sts TCNT1L, r16
 
	;ldi r16, 0b00000101 //cs10 y cs12 -> 1024 prescaler
	ldi r16, (1<<CS10)|(1<<CS12)
	sts TCCR1B, r16
 
	;ldi r16, 0b10000000 //setear bit 7 -> overflow interrupt
	ldi r16, (1<<TOIE1)
	sts TIMSK1, r16

	pop r16
	ret
 
/*************************************************************************************
  Funcion Inicializa el ADC
**************************************************************************************/
config_ADC:
    push r16
    LDI R16, (1<<ADEN)      ;ADC Enable
    ORI R16, (0<<ADATE)                         ;ADC Auto Trigger Enable
    ORI R16, (1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)   ;ADPSx=3: ADC Prescaler Select Bits (ADPS2:0=11 -> 128)
    STS ADCSRA, R16                             ; -> ADCSRA: The ADC Control and Status register A

    LDI R16, (0<<ADTS2)|(0<<ADTS1)|(1<<ADTS0)   ;ADTSx=1: trigger source Analog Comparator
    STS ADCSRB, R16                             ; -> ADCSRB: The ADC Control and Status register B

    LDI R16, (1<<MUX0)                          ;MUXx=1: input channel 1: MUX5:0=00001
    ORI R16, (0<<REFS1)|(1<<REFS0)              ;AREF=1: internal 5V reference (REFS1:0=01)
    ORI R16, (1<<ADLAR)                         ;ADC 8 bits resolution
    STS ADMUX, R16                              ; -> ADMUX: The ADC multiplexer Selection Register

    LDI R16, (1<<ADC1D)                         ;ADC disable digital input circuitry for channel 1 (saves energy)
    STS DIDR0, R16                              ; -> DIDR0: Digital Input Disable Register -> aisla entrada analogica para señar pura

    LDI R16, (0<<PRADC)                         ;ADC disable the power reduction saving for the ADC circuitry (not necesary)
    STS PRR0, R16                               ; -> PRR: Power Reduction Register -> asegurarse de que el modulo esta encendido

    pop r16
    RET

/*************************************************************************************
  Funcion Inicializa el PWM
**************************************************************************************/
config_PWM:
	push r16
	sbi DDRB, DDB7 ; setear pin 13 del arduino mega como output

	ldi r16, 0x00
	out OCR0A, r16 ; poner el pwm a 0% intensidad

	;Setear PWM
	ldi r16, (2 << COM0A0)|(2 << COM0B0) ; set none-inverting mode
	ori r16, (3 << WGM00) ; set fast PWM Mode
	out TCCR0A, r16
	ldi r16, (2 << CS00) ; set prescaler to 8 and starts PW
	out TCCR0B, r16
	ldi r16, (0 << PRTIM0) ; Power reduction timer/counter 0 disable (no es necesario)
	STS PRR0, r16
	pop r16
	RET

/*************************************************************************************
  Funcion Inicializa el USART
**************************************************************************************/
init_USART0:                                  
    ;cargar en UBRR el valor para obtener la velocidad de transmisión deseada
    PUSH r16
    LDI R16, LOW(UBRRvalue)     ; Low byte of Vaud Rate
    STS UBRR0L, R16             ; UBRR0L - USART Baud Rate Register Low Byte
    LDI R16, HIGH(UBRRvalue)    ; High byte of Vaud Rate
    STS UBRR0H, R16             ; UBRR0H - USART Baud Rate Register High Byte
    ldi r16, (1<<TXEN0)         ; Transmitter Enable
    STS UCSR0B, R16             ; UCSR0B - USART Control and Status Register B
    ldi r16, (3<<UCSZ00)        ; Character Size = 8 bits
    STS UCSR0C, R16             ; UCSR0C - USART Control and Status Register C
    POP r16
    RET

/*************************************************************************************
  Funcion MOSTRAR VALOR DEL PWM
**************************************************************************************/
mostrarValor:
	push r16
	in r16, SREG ; Al ser interrupcion necesitamos guardar sreg
	push r16
 
	;ldi r16, 0
	;sts TCCR1B, r16 ;parar timer

	;resetear el reloj para abajo para que cuente otra vez el segundo
	ldi r16, high(timer)
	sts TCNT1H, r16
	ldi r16, low(timer)
	sts TCNT1L, r16
 
	LDS R16, ADCH

	;ECHO valor de la iluminacion
	TX:
		; Wait for empty transmit buffer
		lds r17,UCSR0A			;Load into R17 from SRAM UCSR0A			
		sbrs r17,UDRE0 			;Skip next instruction If Bit Register is set
		rjmp TX
	; Put data (r0) into buffer, sends the data
	sts UDR0,r16

	pop r16
	out SREG, r16
	pop r16
	RETI ;RETurn desde la Interrupcion
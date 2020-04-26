;
; MedidaDeLuzADConvert.asm
;
; Created: 12/04/2020 11:44:40
; Author : SaFteiNZz
;


/*************************************************************************************

**************************************************************************************/
 
.cseg

	sbi DDRH, DDH6 ; PD6 is now an output -> Pin D6
	ldi r16, 0x00
	out OCR4A, r16 ; PWM 0% duty cycle 

	clr r16
	ldi r16, (1 << COM0A1)|(1 << COM0B1) ; set none-inverting mode
	ori r16, (1 << WGM01)|(1 << WGM00) ; set fast PWM Mode
	out TCCR0A, r16
	ldi r16, (0b010 << CS00) ; set prescaler to 8 and starts PW
	out TCCR0B, r16
	ldi r16, (0 << PRTIM0) ; Power reduction timer/counter 0 disable (no es necesario)
	STS PRR, r16

	clr r16

    ;RCALL config_ADC            ;Configurar el conversos ADC

loopGeneral:
    ;Disparo de la lectura
    //LDS R17, ADCSRA             ; -> ADCSRA: The ADC Control and Status register A
    //ori r17, (1<<ADSC)          ;Aciva el bit de la conversion ADC por software
    //sts ADCSRA, R17             ;Dispara la Operacion ADC
	inc r16;
	out OCR4A, r16
	call Delay
	rjmp loopGeneral

esperaADC:
    ;Espera activa hasta que la lectura termine
    clr r17
    lds r17, ADCSRA             ;Carga ek registro ADCSRA para chequear si la conversion ha terminado
    sbrc r17, ADSC              ;Si el bit ADSC esta activo, la conversion no ha terminado, entonces saltar RJMP
    rjmp esperaADC
 
    ;Cargar el valor de la conversion
    LDS R16, ADCH               ;En ADCH, tenemos el valor de la conversion con 8 bits.
    out portd, r16              ;Muestra con Led´s el valor leido por el puerto "d"
 
    ;If (valor > 128)
    cpi r16, 0b10000000         ;Comparamos contra 128
    brpl encender               ;Si es mayor, saltamos a encender
    ;Parte Then
    ldi r20, 0x00
    out portb, r20              ;Apagamos el puerto b
    rjmp seguir
    ;parte Else
	encender:
		ldi r20, 0xff
		out portb, r20              ;Encendemos el puerto b
		;fin if
	seguir: 
		rjmp loopGeneral
 
 
/*************************************************************************************
  Funcion Inicializa el ADC
**************************************************************************************/
config_ADC:
    push r16
    LDI R16, (1<<ADEN)                          ;ADC Enable
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
    STS DIDR0, R16                              ; -> DIDR0: Digital Input Disable Register
    LDI R16, (0<<PRADC)                         ;ADC disable the power reduction saving for the ADC circuitry (not necesary)
    STS PRR, R16                                ; -> PRR: Power Reduction Register
    pop r16
    RET


Delay:
	push r18
	push r19
	push r20
	ldi  r18, 5
	ldi  r19, 15
	ldi  r20, 242
L1: dec  r20
	brne L1
	dec  r19
	brne L1
	dec  r18
	brne L1
	lpm
	nop
	pop r18
	pop r19
	pop r20
	ret
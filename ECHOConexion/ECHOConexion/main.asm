.nolist
.include "m2560def.inc" 
.list

// oscilator:
.equ F_CPU = 16000000

// Baud rate:
.equ BAUD = 9600

// UMBR:
.equ MYUBRR = (F_CPU / (16 * BAUD) - 1)

// Program start: #####################################################################
.cseg
.org 0
	rcall main



main:

	RCALL USART_Init
	rjmp bucle


USART_Init:

	// set baudrate:
	clr r17
	ldi r17, HIGH(MYUBRR)

	clr r16
	ldi r16, LOW(MYUBRR)

	sts UBRR0H, r17
	sts UBRR0L, r16

	// enable receiver and transmitter:
	ldi r16, (1 << RXEN0) | (1 << TXEN0)
	sts UCSR0B, r16

	// Set frame format: 8data, 1 stop bit
	ldi r16, (1 << USBS0) | (3 << UCSZ00)
	sts UCSR0C, r16

	ret


bucle: 

	RCALL TX
	RCALL RX
	rjmp bucle

TX:
	; Wait for empty transmit buffer
	lds r17,UCSR0A			;Load into R17 from SRAM UCSR0A			
	sbrs r17,UDRE0 			;Skip next instruction If Bit Register is set
	rjmp TX
	; Put data (r0) into buffer, sends the data
	sts UDR0,r0
	ret

RX:
	; Wait for data to be received
	lds r17,UCSR0A
	sbrs r17,RXC0
	rjmp RX
	; Get and return received data from buffer
	lds r18, UDR0

	ldi r20, 0xFF
	ldi r21, 0x00
	out ddrb, r20	

	SBRC r18, 0    ; skip Si esta seteado el ultimo bit (1) -> es impar -> se apaga
	out portb, r21
	out portb, r20 ; -> sino se enciende

	inc r18 //SIGUIENTE LETRA EN ASCII
	mov	r0,r18 //DEVOLVER
	
	ret



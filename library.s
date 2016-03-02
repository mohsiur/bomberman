	AREA library, CODE, READWRITE
	EXPORT div_and_mod
	EXPORT output_character
	EXPORT read_string
	EXPORT output_string
	EXPORT read_character
	EXPORT display_digit
	EXPORT read_push_btns
	EXPORT LEDs
	EXPORT RGB_LED
	EXPORT Display_time
	EXPORT Display_score
	EXPORT uart_init
	EXPORT interrupt_init
	EXPORT pin_direction
	EXPORT pin_connect_block
	EXPORT Enable_Timer0
	EXPORT Disable_Timer0
	EXPORT Reset_Timer0
	EXPORT Enable_Timer1
	EXPORT Disable_Timer1
	EXPORT Reset_Timer1
	EXPORT Enable_UART0_Interrupt
	EXPORT Disable_UART0_Interrupt
	EXPORT Random_generator
		
	IMPORT Score
	IMPORT Time
	IMPORT Seed_1
	IMPORT Seed_2


U0LSR EQU 0x14 					; UART0 Line Status Register
T0MR0 EQU 0xE0004018 			; Timer0 Match Register 0
T0MR1 EQU 0x04					; Timer0 Match Register 1
		
S_Segment_SET
	DCD 0x00001F80		; 0
	DCD 0x00000300		; 1
	DCD 0x00002D80		; 2
	DCD 0x00002780		; 3
	DCD 0x00003300		; 4
	DCD 0x00003680		; 5
	DCD 0x00003E80		; 6
	DCD 0x00000380		; 7
	DCD 0x00003F80		; 8
	DCD 0x00003780		; 9
	DCD 0x00003B80		; A
	DCD 0x00003F80		; B	Same as 8
	DCD 0x00001C80		; C
	DCD 0x00001F80		; D	Same as 0
	DCD 0x00003C80		; E
	DCD 0x00003880		; F
	DCD 0x00000000		; OFF (16)

LED_SET
	DCD 0x0000000F		; 0
	DCD 0x00000007		; 1
	DCD 0x0000000B		; 2
	DCD 0x00000003		; 3
	DCD 0x0000000D		; 4
	DCD 0x00000005		; 5
	DCD 0x00000009		; 6
	DCD 0x00000001		; 7
	DCD 0x0000000E		; 8
	DCD 0x00000006		; 9
	DCD 0x0000000A		; 10
	DCD 0x00000002		; 11
	DCD 0x0000000C		; 12
	DCD 0x00000004		; 13
	DCD 0x00000008		; 14
	DCD 0x00000000		; 15

RGB_LED_SET
	DCD 0x00000026		; 0 [off]
	DCD 0x00000024		; 1 [red]
	DCD 0x00000006		; 2 [green]
	DCD 0x00000022		; 3 [blue]
	DCD 0x00000020		; 4 [purple]
	DCD 0x00000004		; 5 [yellow]
	DCD 0x00000000		; 6 [white]

	ALIGN


div_and_mod
		; Two arguments are needed to be passed in r0 and r1 
		; carrying the dividend and divisor respectively
		
		; Two return values will be passed to r0 and r1
		; carrying the quotient and remainder respectively
	STMFD SP!, {r4}
	MOV r2, #15					; r2 = Counter
	MOV r3, #0					; r3 = Quotient
	MOV r4, #0					; r4 = Sign indicator	
	CMP r0, #0					; check whether dividend negative
	BGE cont1		
	ADD r4, r4, #1				; increment the sign indicator if negative and make it positive
	RSB r0, r0, #0
cont1
	CMP r1, #0					; check whether divisor negative
	BGE cont2
	ADD r4, r4, #1				; increment the sign indicator if negative and make it positive
	RSB r1, r1, #0
cont2
	MOV r1, r1, LSL #15			; left shift the divisor 15 bits
loop_1	
	SUB r0, r0, r1				; Dividend minus Divisor
	CMP r0, #0					; check whether the result negative
	MOV r3, r3, LSL #1
	BLT back
	ADD r3, r3, #1				; left shift in 1 to quotient if positive
	B cont3
back
	ADD r0, r0, r1				; restore dividend and left shift in 0 to quotient if negative
cont3
	MOV r1, r1, LSR #1			; right shift divisor 1 bit
	CMP r2, #0
	SUB r2, r2, #1				; decrement the counter
	BGT loop_1					; loop if counter (before decrement) > 0
	MOV r1, r0					; move remainder to r1
	MOV r0, r3					; move quotient to r0
	CMP r4, #1					; check whether signs are different
	BNE done				
	RSB r0, r0, #0				; change quotient to negative if they are different
done
	LDMFD SP!, {r4}
	BX lr      						

	

output_character
		; One argument is needed to be passed in r0 carrying 
		; the character that will be displayed in UART
	LDR r1, =0xE000C000			; Base address
	LDRB r2, [r1, #U0LSR]		; Clear all bits of U0LSR except THRE (6th bit of U0LSR)
	AND r2, r2, #0x20
	CMP r2, #0					; Check if THRE is 1
	BEQ output_character			; If not, loop
	STRB r0, [r1]				; Else, output the value in r0 and display it to PuTTY
	BX lr
	
	
output_string
		; One argument is needed to be passed in r4 carrying 
		; the base address where the string will be loaded from
	STMFD SP!,{r4, lr}	
	LDRB r0, [r4] 				; Load byte from memory
loop_s
	CMP r0, #0 					; Check if the byte is null
	BEQ then
	BL output_character 		; Go to output_character if not NULL
	LDRB r0, [r4, #1]!			; Check next character
	B loop_s 
then
	LDMFD sp!, {r4, lr}
	BX lr 
	
	
read_character
		; One return value is passed to r0 carrying 
		; the character entered by user
	LDR r1, =0xE000C014 		; U0LSR address
	LDRB r2, [r1] 				; Clear all bits of U0LSR except RDR (1st bit of U0LSR)
	AND r2, r2, #1 		
	CMP r2, #0 					; Compare the RDR flag to 0
	BEQ read_character 			; If RDR = 0, then do it again
	LDR r1, =0xE000C000			; If RDR = 1, loading from receive buffer
	LDRB r0, [r1] 
	BX lr
	
	
read_string
		; One argument is needed to be passed in r4 carrying 
		; the base address where the string will be stored to
	STMFD sp!, {r4, lr}	
loop
	BL read_character			; Read a character, result is in r0
	CMP r0, #0x0D				; Check whether the character is a ENTER key
	BEQ cont	
	STRB r0, [r4], #1			; Store character to memory
	B loop
cont
	MOV r0, #0x00				; Store NULL to memory
	STRB r0, [r4], #1
	LDMFD sp!, {r4, lr}
	BX lr
	
	
display_digit
		; One argument is needed to be passed in r0 carrying 
		; the number (0-16) which will be displayed on 7-segments display
	STMFD sp!, {r4, r5}
	LDR r3, =0xC07F				; Used to clear bits
	LDR r4, =S_Segment_SET		; Load half word of address in r4 with offset (r0*4) into r2
	MOV r0, r0, LSL #2
	LDRH r2, [r4, r0]		
	LDR r5, =0xE0028004			; Load address of Port 0 of GPIO output set
	LDR r4, =0xE002800C 		; Load address of Port 0 of GPIO output clear
	
	LDRH r1, [r5]				; Load half word from output_set
	AND r1, r1, r3				; Set the 7-segments bits to correct value (based on lookup table)
	ORR r1, r1, r2	
	STRH r1, [r5]				; Store back to output_set
	
	LDRH r1, [r4]				; Load half word from output_clear
	MVN r2, r2					; Get the 1's complement of r2 (bits 7-13 only)
	AND r2, r2, #0x3F80
	AND r1, r1, r3				; Set the 7-segments bits to correct value
	ORR r1, r1, r2
	STRH r1, [r4]				; Store back to output_clear
	LDMFD sp!, {r4, r5}
	BX lr;
	
	
read_push_btns
		; One return value is passed to r0 carrying 
		; the number (0-15) which read from buttons
	STMFD sp!, {r4}
	LDR r4, =0xE0028010 		; Load address of Port1 of GPIO value
	LDRH r2, [r4, #2] 			; Load second half word from GPIO value
	MOV r3, #0	 				; initialize r3 to 0 (counter)
	MOV r0, #0					; Initialize r0 to 0 (base number/return value)
loop_push
	ADD r4, r3, #4				; Calculate shift amount by counter(r3) + #4
	MOV r1, r2, LSR r4			; Get an integer from buttons (starting from MSB, bit_20)
	AND r1, r1, #1			
	MOV r0, r0, LSL #1			; Combine that integer with previous value
	MVN r1, r1					; 0 = pushed, 1 = not
	AND r1, r1, #1
	ADD r0, r0, r1			
	CMP r3, #2					; Compare if counter(r3) < 3 (the loop will run 4 times)
	BGT then_b
	ADD r3, r3, #1				; Increment counter(r3) by 1
	B loop_push
then_b
	LDMFD sp!, {r4}
	BX lr

	
LEDs
		; One argument is needed to be passed in r0 carrying 
		; the number (0-15) which will be displayed on LEDs
	STMFD sp!, {r4}
	LDR r4, =LED_SET			; Load byte of address in r4 with offset (r0*4) into r2
    LDRB r2, [r4, r0, LSL #2]		
	LDR r3, =0xE0028014			; Load address of GPIO Port1_set
	LDR r4, =0xE002801C			; Load address of GPIO Port1_clear
	LDRB r1, [r3, #2]			; Load third byte from Port1_set
	AND r1, r1, #0xF0			; Change bits 16 to 19 to the one in lookup table
	ORR r1, r1, r2
	STRB r1, [r3, #2]			; Store it back to Port1_set
	
	LDRB r1, [r4, #2]			; Load third byte from Port1_clear
	MVN r2, r2					; Get the 1's complement of r2 (lower 4 bits only)
	AND r2, r2, #0x0F
	AND r1, r1, #0xF0			; Change bits 16 to 19 to correct value
	ORR r1, r1, r2
	STRB r1, [r4, #2]			; Store it back to Port1_clear
	LDMFD sp!, {r4}
	BX lr
	
	
RGB_LED
		; One argument is needed to be passed in r0 carrying 
		; the number (0-6) which is representing the color to show on RGB_LED
	STMFD sp!, {r4}			
	LDR r4, =RGB_LED_SET		; Load byte of address in r2 with offset (r0*4) into r2
	LDRB r2, [r4, r0, LSL #2]
	LDR r3, =0xE0028004			; Load address of GPIO Port0_set
	LDR r4, =0xE002800C			; Load address of GPIO Port0_clear

	LDRB r1, [r3, #2]			; Load third byte from Port0_set
	;AND r1, r1, #0xD9			; Change bits 17, 18, 21 to the one in lookup table
	ORR r1, r1, r2
	LSL r1, r1, #16
	STR r1, [r3]				; Store it back to Port0_set
	
	LDRB r1, [r4, #2]			; Load third byte from Port0_clear
	MVN r2, r2					; Get the 1's complement of r2 (bits 17, 18, 21 only)
	AND r2, r2, #0x26
	;AND r1, r1, #0xD9			; Change bits 17, 18, 21 to correct value
	ORR r1, r1, r2
	LSL r1, r1, #16
	STR r1, [r4]				; Store it back to Port0_set
	LDMFD sp!, {r4}
	BX lr


Display_score
		; No argument is needed 
	STMFD sp!, {lr}
	LDR r4, =Score
	LDR r0, [r4]
	MOV r1, #1000					; Calculate "Score/1000"
	BL div_and_mod
	ORR r0, r0, #0x30				; Convert the quotient into string, and print it out
	STMFD sp!, {r1}
	BL output_character
	LDMFD sp!, {r1}
	
	MOV r0, r1						; Calculate "(Score%1000)/100"					
	MOV r1, #100
	BL div_and_mod
	ORR r0, r0, #0x30				; Convert the quotient into string, and print it out
	STMFD sp!, {r1}
	BL output_character
	LDMFD sp!, {r1}

	MOV r0, r1						; Calculate "((Score%1000)%100)/10"					
	MOV r1, #10
	BL div_and_mod
	ORR r0, r0, #0x30				; Convert the quotient into string, and print it out
	STMFD sp!, {r1}
	BL output_character
	LDMFD sp!, {r1}
	
	ORR r0, r1, #0x30				; Convert the remainder into string, and print it out
	BL output_character

	LDMFD sp!, {lr}
	BX lr


Display_time
		; No argument is needed 
	STMFD sp!, {lr}
	LDR r4, =Time
	LDR r0, [r4]
	MOV r1, #100					; Calculate "Score/100"
	BL div_and_mod
	ORR r0, r0, #0x30				; Convert the quotient into string, and print it out
	STMFD sp!, {r1}
	BL output_character
	LDMFD sp!, {r1}
	
	MOV r0, r1						; Calculate "(Score%100)/10"					
	MOV r1, #10
	BL div_and_mod
	ORR r0, r0, #0x30				; Convert the quotient into string, and print it out
	STMFD sp!, {r1}
	BL output_character
	LDMFD sp!, {r1}
	
	ORR r0, r1, #0x30				; Convert the remainder into string, and print it out
	BL output_character

	LDMFD sp!, {lr}
	BX lr
	

pin_connect_block
	LDR r0, =0xF0003FF0			; Used to clear bits
	LDR r1, =0xE002C000			; Address of PINSEL0
	LDR r2, [r1]
	AND r2, r2, r0				; clear bits
	ORR r2, r2, #5
	STR r2, [r1]				; Store back to PINSEL0
	
	LDR r0, =0xFFFFF333			; Used to clear bits
	LDR r2, [r1, #0x04]			; load from Address of PINSEL1
	AND r2, r2, r0				; clear bits
	ORR r2, r2, #0
	STR r2, [r1, #0x04]			; Store back to PINSEL1
	
	LDR r0, =0xFFFFFFF7			; Used to clear bits
	LDR r2, [r1, #0x14]			; load from Address of PINSEL2
	AND r2, r2, r0				; clear bit
	ORR r2, r2, #0
	STR r2, [r1, #0x14]			; Store back to PINSEL2
	BX lr


pin_direction
	LDR r0, =0xFFD9C073			; Used to clear bits
	LDR r1, =0x00263F8C			; Used to set bits
	LDR r2, =0xE0028008			; Address of IO0DIR
	LDR r3, [r2]
	AND r3, r3, r0				; clear bits
	ORR r3, r3, r1				; set bits
	STR r3, [r2]				; store back to IO0DIR
	
	LDR r0, =0xFF00FFFF			; Used to clear bits
	LDR r3, [r2, #0x10]			; load from Address of IO1DIR
	AND r3, r3, r0				; clear bits
	ORR r3, r3, #0x000F0000		; set bits
	STR r3, [r2, #0x10]			; store back to IO1DIR
	BX lr


uart_init
	LDR r2, =0xE000C000 	
	MOV r1, #131 			
	STRB r1, [r2, #0xC]		 	; Change content of 0xE000C000C to 0x83	
	MOV r1, #1 					; Baud Rate = 1,152,000 (max)
	STRB r1, [r2]	 			; Change content of 0xE000C0000 to 0x78
	MOV r1, #0 				
	STRB r1, [r2, #4]	 		; Change content of 0xE000C0004 to 0x00
	MOV r1, #3 				
	STRB r1, [r2, #0xC] 		; Change content of 0xE000C000C to 0x03
	BX lr 					
	

interrupt_init       
		; Push button setup		 
	LDR r0, =0xE002C000
	LDR r1, [r0]
	ORR r1, r1, #0x20000000
	BIC r1, r1, #0x10000000
	STR r1, [r0]  				; PINSEL0 bits 29:28 = 10

		; Classify sources as IRQ or FIQ
	LDR r2, =0x8040
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x0C]
	ORR r1, r1, r2
	ORR r1, r1, #0x8000			; External Interrupt 1
	ORR r1, r1, #0x70			; UART0[bit6], Timer1[bit5], Timer0[bit4]			
	STR r1, [r0, #0x0C]

		; Enable Interrupts
	LDR r0, =0xFFFFF000
	LDR r1, [r0, #0x10]
	ORR r1, r1, r2 
	ORR r1, r1, #0x8000			; External Interrupt 1
	ORR r1, r1, #0x70			; UART0[bit6], Timer1[bit5], Timer0[bit4]
	STR r1, [r0, #0x10]

		; External Interrupt 1 setup for edge sensitive
	LDR r0, =0xE01FC148
	LDR r1, [r0]
	ORR r1, r1, #2 				 ; EINT1 = Edge Sensitive
	STR r1, [r0]
	
		; Enable Timer0 to interrupt
	LDR r0, =0xE0004014			; Match_Control_Register for Timer0
	LDR r1, [r0]
	ORR r1, r1, #0x01			; Generate Interrupt of MR0 by bit0 to 1
	BIC r1, r1, #0x06			; Disable reset and stop function of MR0 by bit[2:1] to 00
	ORR r1, r1, #0x18			; Generate Interrupt and reset function of MR1 by bit[4:3] to 11
	BIC r1, r1, #0x20			; Disable stop function of MR1 by bit5 to 0
	STR r1, [r0]
	
		; Enable Timer1 to interrupt
	LDR r0, =0xE0008014			; Match_Control_Register for Timer1
	LDR r1, [r0]
	ORR r1, r1, #0x03			; Generate Interrupt and reset function of MR0 by bit[1:0] to 11
	BIC r1, r1, #0x04			; Disable stop function of MR0 by bit2 to 0
	STR r1, [r0]
	
		; Set Timer0 Time-out period
	LDR r0, =T0MR0			; Initially set Time-out Period of MR0 to 0.25 second - fast
	LDR r1, =0x00465000
	STR r1, [r0]
	LDR r1, =0x008CA000		; Initially set Time-out Period of MR1 to 0.50 second - normal
	STR r1, [r0, #T0MR1]
	
		; Set Timer1 Time-out period
	LDR r0, =0xE0008018
	LDR r1, =0x1194000			; Permanently set Time-out Period of MR0 to 1.00 second
	STR r1, [r0]	
	
		; Enable FIQ's, Disable IRQ's
	MRS r0, CPSR
	BIC r0, r0, #0x40
	ORR r0, r0, #0x80
	MSR CPSR_c, r0
	BX lr             	 		


Enable_Timer0
	LDR r0, =0xE0004004			; Enable Timer0 by setting bit0 of Timer Control Register
	LDR r1, [r0]
	ORR r1, r1, #0x01			
	STR r1, [r0]
	BX lr


Disable_Timer0
	LDR r0, =0xE0004004			; Disable Timer0 by clearing bit0 of Timer Control Register
	LDR r1, [r0]
	BIC r1, r1, #0x01			
	STR r1, [r0]
	BX lr
	
	
Reset_Timer0
	LDR r0, =0xE0004004			; Reset and disable Timer0 by changing bit[1:0] of TCR to 10, and then 00
	LDR r1, [r0]
	ORR r1, r1, #0x02
	BIC r1, r1, #0x01
	STR r1, [r0]
	BIC r1, r1, #0x02	
	STR r1, [r0]
	BX lr
	
	
Reset_Timer0_Period
	LDR r0, =T0MR0			; Initially set Time-out Period of MR0 to 0.25 second - fast
	LDR r1, =0x00465000
	STR r1, [r0]
	LDR r1, =0x008CA000		; Initially set Time-out Period of MR1 to 0.50 second - normal
	STR r1, [r0, #T0MR1]
	BX lr
	

Enable_Timer1
	LDR r0, =0xE0008004			; Enable Timer1 by setting bit0 of Timer Control Register
	LDR r1, [r0]
	ORR r1, r1, #0x01			
	STR r1, [r0]
	BX lr

	
Disable_Timer1
	LDR r0, =0xE0008004			; Disable Timer1 by clearing bit0 of Timer Control Register
	LDR r1, [r0]
	BIC r1, r1, #0x01			
	STR r1, [r0]
	BX lr
	
	
Reset_Timer1
	LDR r0, =0xE0008004			; Reset and disable Timer0 by changing bit[1:0] of TCR to 10, and then 00
	LDR r1, [r0]
	ORR r1, r1, #0x02
	BIC r1, r1, #0x01
	STR r1, [r0]
	BIC r1, r1, #0x02	
	STR r1, [r0]
	BX lr


Enable_UART0_Interrupt
	LDR r0, =0xE000C004			; Set up UART0 to Interrupt When Data is Received
	LDR r1, [r0]
	ORR r1, r1, #0x01
	STR r1, [r0]
	BX lr
	
	
Disable_UART0_Interrupt
	LDR r0, =0xE000C004			; No UART0 Interrupt Even When Data is Received
	LDR r1, [r0]
	BIC r1, r1, #0x01
	STR r1, [r0]
	BX lr


Random_generator
		; The subroutine will generate two random number based on two seeds
		; The return values are in r0 (random number 0-3) and r1 (random number 30-333)
	STMFD SP!, {r4-r6, lr}
	LDR r4, =Seed_1				; Obtain both seeds to generate two random numbers
	LDR r5, =Seed_2
	LDR r2, [r4]
	LDR r3, [r5]
	SUBS r6, r2, r3, ASR #1		; Obtain the first random number
	LSRVS r6, r6, #7
	LSRLE r6, r6, #13

	ADDS r0, r3, r2, LSR #3		; Obtain the second random number
	RORVC r0, r0, #4
	RORGE r0, r0, #21
	ASR r1, r0, #8				; The two instructions are used to reduce the number
	BIC r0, r0, #0xFF000000		; since div_and_mod can't take in a huge dividend
	EOR r0, r0, r1
	MOV r1, #304
	STMFD sp!, {r2, r3}
	BL div_and_mod
	LDMFD sp!, {r2, r3}

	AND r0, r6, #0x03			; r0 = random number (0-3)
	ADD r1, r1, #30				; r1 = random number (30-333)
	
	ADD r2, r2, r1, ROR r1		; Update both seeds, the operations don't
	EOR r2, r3, r2, ROR r0		; matter as long as new seeds can be generated
	SUB r3, r1, r3, ROR r0
	STR r2, [r4]
	STR r3, [r5]
	
	LDMFD sp!, {r4-r6, lr}
	BX lr
	
	
	END
	AREA board, CODE, READWRITE
	EXPORT Display_board
	EXPORT Copy_board
	EXPORT Add_brick
	EXPORT Board_array
	EXPORT Board_array_initial
		
	IMPORT output_character
	IMPORT output_string
	IMPORT Display_time
	IMPORT Display_score
	IMPORT Random_generator
	IMPORT Pause


			;	   [3:0]	   [7:4]	   [11:8]      [15:12]     [20:16]     [23:21]	   [24]
Board_array	DCD 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0xFFFFFF0F 		; 0 [Wall]
			DCD 0x0000030F, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x02010000, 0xFFFFFF0F 		; 1
			DCD 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x010F000F, 0xFFFFFF0F 		; 2
			DCD 0x0000000F, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xFFFFFF0F 		; 3
			DCD 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0xFFFFFF0F 		; 4
			DCD 0x0000000F, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xFFFFFF0F 		; 5
			DCD 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0xFFFFFF0F		; 6
			DCD 0x0000000F, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xFFFFFF0F		; 7
			DCD 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0xFFFFFF0F		; 8
			DCD 0x0000000F, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0xFFFFFF0F		; 9
			DCD 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0x000F000F, 0xFFFFFF0F 		; 10
			DCD 0x0000070F, 0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x03000000, 0xFFFFFF0F 		; 11
			DCD 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0x0F0F0F0F, 0xFFFFFF0F 		; 12 [Wall]
				
Board_array_initial		; 91 words
			DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
			DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
			DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
			DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0				
			DCD 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
				
Status 	DCD Empty, Unused, Bomberman, Enemy_Nor, H_Bombblast		; 0-4
		DCD V_Bombblast, Unused, Enemy_Fast, Bomb, Unused			; 5-9
		DCD Bomberman, Brick, Unused, Unused, Unused, Wall			; 10-15
	   
Title			= "                                Bomberman\n\r", 0
Time_S			= "               Time: ", 0
Score_S			= "                         Score: ", 0
Score_S_Paused	= "          PAUSED          Score: ", 0
Wall 			= "█", 0
Brick 			= "░", 0
Bomberman 		= "B", 0
Bomb			= "o", 0
Enemy_Nor 		= "+", 0
Enemy_Fast		= "x", 0
V_Bombblast 	= "|", 0
H_Bombblast 	= "-", 0
Empty 			= " ", 0
Unused			= "?", 0			; Unused, for debug purpose only
New_line 		= "\n\r", 0
	ALIGN


Copy_board
		; This function replaces the contents (91 words) in r4 with the contents in r5
		; Two arguments are needed in r4 and r5 as the base address of Board_array
	MOV r0, #91
loop_copy
	LDR r1, [r4], #4				; Load a word from address in r4
	STR r1, [r5], #4				; Store that word into address in r5
	SUBS r0, r0, #1
	BNE loop_copy					; Loop for 91 times
	BX lr


Display_board
		; This function prints out the game board based on the info in Board_array
		; No argument is needed
	STMFD sp!, {r4-r7, lr}
	MOV r0, #0x0C					; New page
	BL output_character
	LDR r4, =Title					; Print title, time and score
	BL output_string
	LDR r4, =Time_S
	BL output_string
	BL Display_time
	LDR r4, =Pause					; Print one of the two versions of "Score_S" based on whether
	LDR r0, [r4]					; the game is paused
	CMP r0, #0
	LDREQ r4, =Score_S
	LDRNE r4, =Score_S_Paused
	BL output_string
	BL Display_score
	
	MOV r7, #-28 					; The base offset used to calculate effective offset
	MOV r0, #-1						; r0 = Y-coordinate counter
	LDR r5, =Board_array
	LDR r6, =Status
loop_board_1
	LDR r4, =New_line				; New line
	STMFD sp!, {r0}
	BL output_string
	LDMFD sp!, {r0}
	ADD r0, r0, #1					; Increment y-counter(next line) and reset x-counter (to 24) when a line is done
	CMP r0, #13						; Done after 13 lines are done
	BEQ quit_board
	MOV r1, #24						; r1 = X-coordinate counter
	ADD r7, r7, #28					
loop_board_2
	ADD r3, r7, r1					; Corresponding offset for that coordinates
	LDRB r2, [r5, r3]				; Use that offset to get info from Board_array
	LDR r4, [r6, r2, LSL #2]		; Use that info to get string from Status and print it out
	STMFD sp!, {r0, r1}
	BL output_string
	LDMFD sp!, {r0, r1}
	SUBS r1, r1, #1					; Next coordinate
	BLT loop_board_1
	B loop_board_2
quit_board
	LDMFD sp!, {r4-r7, lr}
	BX lr


Add_brick
		; This function adds a given amount of brick into the Board_array
		; One argument is needed in r0 carrying the required amount of brick to add
	STMFD sp!, {r4, lr}
	CMP r0, #0						; Brick counter, initialize to # of brick needed
	BLE quit_brick
	LDR r4, =Board_array
loop_brick
	STMFD sp!, {r0}
	BL Random_generator				; Return a random number (30-333) in r1
	LDMFD sp!, {r0}
	LDRB r3, [r4, r1]				; Use the random number (offset) to get info from Board_array
	CMP r3, #0x00
	BNE loop_brick
	MOV r3, #0x0B					; Change to "brick" (0x0B) only if it is initially "empty space" (0x00)
	STRB r3, [r4, r1]
	SUBS r0, r0, #1
	BNE loop_brick					; Keep adding brick if not yet reach the required amount
quit_brick
	MOV r3, #0x00					; Change the two coordinates with 0x01 to 0x00
	STRB r3, [r4, #50]
	STRB r3, [r4, #79]
	LDMFD sp!, {r4, lr}
	BX lr
	
	
	END
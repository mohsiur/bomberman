	AREA main, CODE, READWRITE
	EXPORT lab7
	
	IMPORT output_string
	IMPORT read_character
	IMPORT Display_score
	IMPORT Display_board
	IMPORT Enable_UART0_Interrupt
	IMPORT Disable_UART0_Interrupt
	IMPORT Enable_Timer0
	IMPORT Enable_Timer1
	IMPORT Reset_Timer0
	IMPORT Reset_Timer1
	IMPORT Add_brick
	IMPORT Copy_board
	IMPORT display_digit
	IMPORT RGB_LED
	IMPORT LEDs
	IMPORT Board_array
	IMPORT Board_array_initial
	IMPORT Bomberman_direction
	IMPORT Bomberman_status
	IMPORT Enemy_A_status
	IMPORT Enemy_B_status
	IMPORT Enemy_SP_status
	IMPORT Bomb_detonate
	IMPORT Bomb_status
	IMPORT Time
	IMPORT Life
	IMPORT Score
	IMPORT Pause
	IMPORT Game_over
	IMPORT Seed_1
	IMPORT Seed_2
	IMPORT Level

message_start_1 	= "\f\n\r\t\t\t\t\tWelcome to the game of 'Bomberman'\n\r\n\r\n\r", 0
message_start_2 	= "RULES:\n\r", 0
message_start_2_1	= "\t- Player controls bomberman to  use bomb to kill all enemies (3) to clear each level\n\r\t- Life (4 initially) loses if bomberman is killed by bomb detonation or got in touch with an enemy\n\r", 0
message_start_2_2	= "\t- Range of bomb detonation (bomb blast) is horizontally 4 positions and vertically 2 positions from the detonation point\n\r\t- Bomb blast can only be stopped by indestructible walls within its range\n\r", 0
message_start_2_3	= "\t- Only one bomb can be placed at a time\n\r\t- Bomb detonates after 5 moves (both success and failure) of bomberman\n\r", 0
message_start_2_4	= "\t- One enemy is moving twice as fast as other enemies and bomberman\n\r\t- Speed of the game increases when level up until level 5\n\r", 0
message_start_2_5	= "\t- Game board resets with bricks and all enemies when bomberman dies or level up\n\r\t- Destructible bricks are randomly generated every time the board resets\n\r", 0
message_start_2_6	= "\t- Level up if both the last enemy and bomberman die at the same refresh (time)\n\r\t- Score will be awarded when a brick is destroyed, an enemy is killed, and level up\n\r", 0
message_start_2_7	= "\t- Game over after 120 seconds, or used up all lives\n\r\t- Each unused life contributes 25 points toward the final score when game over\n\r", 0
message_start_2_8	= "\t- Bomberman will stay if player tries to move it through bricks, walls, or bomb (failure move)\n\r\t- Keystroke to place bomb will be ignored if a bomb is already placed and is not yet detonated\n\r", 0
message_start_2_9	= "\t- Only the first valid keystroke functions if more than 1 keystrokes are pressed to move bomberman within one refresh time\n\r\t- An external button can be used to pause the game\n\r", 0
message_start_3 	= "CONTROLS:\n\r" ,0
message_start_3_1	= "\t'w' - Move bomberman one position up\n\r\t'd' - Move bomberman one position right\n\r\t's' - Move bomberman one position down\n\r", 0
message_start_3_2	= "\t'a' - Move bomberman one position left\n\r\t'b' - Place a bomb in current location\n\r", 0
message_start_4 	= "NOTES:\n\r", 0
message_start_4_1	= "\t- Make sure to setup in the following ways otherwise some characters may not show up properly\n\r\t\t- PuTTY with 'UTF-8' by going to Translation under Window > Character set translation on received data\n\r", 0
message_start_4_2	= "\t\t- Keil with 'Encode in UTF-8 without signature' by going to Edit > Configuration > Editor tab > Encoding under General Editor Setting\n\r\t- Simply reopen PuTTY if PuTTY doesn't respond to any keystroke\n\t", 0
message_start_5 	= "\n\r\t\t\t\t\t...Press a Key to Start...", 0

message_end_1 = "\f\n\r\n\r\n\r\t\tGAME OVER\n\r\n\r", 0
message_end_2 = "\tFinal Score: ", 0
message_end_3 = "\n\r\tReplay?(Y/N): ", 0
message_end_4 = "\f\t\tEND OF THE GAME", 0
	ALIGN
		

lab7
	STMFD SP!, {lr}
	LDR r4, =Board_array			; Make a initial copy of Board_array
	LDR r5, =Board_array_initial
	BL Copy_board
	
restart
	BL Enable_Timer1
	
	MOV r0, #0						; Display '0' on 7 segment before game start
	BL display_digit
	MOV r0, #15						; Turn on all 4 LEDs
	BL LEDs
	MOV r0, #6						; White on RGB_LED
	BL RGB_LED
	
	LDR r4, =message_start_1		; Print title
	BL output_string
	LDR r4, =message_start_2		; Print rules
	BL output_string
	LDR r4, =message_start_2_1
	BL output_string
	LDR r4, =message_start_2_2
	BL output_string
	LDR r4, =message_start_2_3
	BL output_string
	LDR r4, =message_start_2_4
	BL output_string
	LDR r4, =message_start_2_5
	BL output_string
	LDR r4, =message_start_2_6
	BL output_string
	LDR r4, =message_start_2_7
	BL output_string
	LDR r4, =message_start_2_8
	BL output_string
	LDR r4, =message_start_2_9
	BL output_string
	LDR r4, =message_start_3		; Print control intructions
	BL output_string
	LDR r4, =message_start_3_1
	BL output_string
	LDR r4, =message_start_3_2
	BL output_string
	LDR r4, =message_start_4		; Print notes
	BL output_string
	LDR r4, =message_start_4_1
	BL output_string
	LDR r4, =message_start_4_2
	BL output_string
	LDR r4, =message_start_5
	BL output_string
	
	BL read_character
	LDR r4, =Seed_1					; Update the first seed for random generator using the user-entered character
	LDR r1, [r4]
	ADD r1, r0, r1, ROR #1
	STR r1, [r4]
	LDR r4, =Seed_2					; Update the second seed for random generator using Timer1 Counter
	LDR r5, =0xE0008008
	LDR r1, [r4]
	LDR r2, [r5]
	ADD r1, r1, r2, ROR #2
	STR r1, [r4]
	
	MOV r0, #10						; Randomly add 10 bricks to Board_array and display the board to PuTTY
	BL Add_brick
	BL Display_board
	
	MOV r0, #2						; Green on RGB_LED
	BL RGB_LED
	MOV r0, #1						; Display '1' on 7 segments display
	BL display_digit
	LDR r4, =Level					; To level 1
	LDR r0, [r4]
	ADD r0, r0, #1
	STR r0, [r4]
	
	BL Enable_UART0_Interrupt		; Reset and enable all timers and UART interrupt
	BL Reset_Timer1
	BL Enable_Timer0
	BL Enable_Timer1
	LDR r4, =Game_over
	
loop
	LDR r0, [r4]					; Keep checking the flag for game over
	CMP r0, #0
	BEQ loop
	
game_over
	BL Disable_UART0_Interrupt		; Disable all timers and UART interrupt
	MOV r0, #4						; Purple on RGB_LED
	BL RGB_LED

	LDR r4, =Life					; Calculate the final score if there are lives left
	LDR r5, =Score
	LDR r0, [r4]
	CMP r0, #0
	BEQ message
	LDR r1, [r5]
loop_final_score
	ADD r1, r1, #25
	SUBS r0, r0, #1
	BNE loop_final_score
	STR r1, [r5]

message
	LDR r4, =message_end_1
	BL output_string
	LDR r4, =message_end_2
	BL output_string
	BL Display_score
	LDR r4, =message_end_3
	BL output_string

	BL read_character
	CMP r0, #0x59					; 'Y' - restart
	BEQ Reset
	CMP r0, #0x4E					; 'N' - quit
	BNE message						; Else - invalid input
	
	LDR r4, =message_end_4
	BL output_string	
	LDMFD SP!, {lr}
	BX lr							; END of the program
	
	


Reset								; Resets data and timers to the initial values and Restart the game
	LDR r5, =Board_array			; Reset the Board_array
	LDR r4, =Board_array_initial
	BL Copy_board	
	
	LDR r4, =Bomberman_status		; Reset the Bomberman_status to 0x33 (upper left)
	MOV r5, #0x0033
	STR r5, [r4]
	LDR r4, =Enemy_A_status			; Reset the Enemy_A_status to 0x1D (upper right)
	MOV r5, #0x001D
	STR r5, [r4]
	LDR r4, =Enemy_B_status			; Reset the Enemy_B_status to 0x14B (lower left)
	LDR r5, =0x014B
	STR r5, [r4]
	LDR r4, =Enemy_SP_status		; Reset the Enemy_SP_status to 0x135 (lower right)
	LDR r5, =0x0135
	STR r5, [r4]
	LDR r4, =Time					; Reset the Time to 120
	MOV r5, #0x78
	STR r5, [r4]
	LDR r4, =Life					; Reset the Life to 4
	MOV r5, #0x04
	STR r5, [r4]
	LDR r4, =Bomb_status			; Reset the Bomb_status to negative (not placed)
	MOV r5, #0x80000000
	STR r5, [r4]
	LDR r4, =Bomb_detonate			; Reset the Bomb_detonate to 1 (not detonating)
	MOV r5, #0x01
	STR r5, [r4]
	LDR r4, =Bomberman_direction	; Reset the Bomberman_direction to 0 (stay)
	MOV r5, #0x00
	STR r5, [r4]
	LDR r4, =Score					; Reset the Score to 0
	STR r5, [r4]
	LDR r4, =Level					; Reset the Level to 0
	STR r5, [r4]
	LDR r4, =Game_over				; Reset the Game_over to 0 (new game)
	STR r5, [r4]

	BL Reset_Timer0					; Reset Timer0 for new game (but not Timer1 since it will be resetted later)
	B restart
	

	END

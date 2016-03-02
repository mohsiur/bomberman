	AREA handler, CODE, READWRITE
	EXPORT FIQ_Handler
	EXPORT Bomberman_status
	EXPORT Bomberman_direction
	EXPORT Enemy_A_status
	EXPORT Enemy_B_status
	EXPORT Enemy_SP_status
	EXPORT Life
	EXPORT Score
	EXPORT Time
	EXPORT Level
	EXPORT Pause
	EXPORT Bomb_status
	EXPORT Bomb_detonate
	EXPORT Game_over
	EXPORT Seed_1
	EXPORT Seed_2
		
	IMPORT Bomb_blast_operation
	IMPORT Clear_bomb
	IMPORT read_character
	IMPORT Enable_Timer0
	IMPORT Disable_Timer0
	IMPORT Reset_Timer0
	IMPORT Enable_Timer1
	IMPORT Disable_Timer1
	IMPORT Display_board
	IMPORT Copy_board
	IMPORT Move_enemy
	IMPORT Random_generator
	IMPORT RGB_LED
	IMPORT LEDs
	IMPORT display_digit
	IMPORT Add_brick
	IMPORT Board_array
	IMPORT Board_array_initial

T0MR0 		EQU 0xE0004018 			; Timer0 Match Register 0
T0MR1 		EQU 0x04				; Timer0 Match Register 1
Sec005 		EQU 0x000E1000			; Equivalent to 0.05 second 


Bomberman_status 		DCD 0x00000033		; Alive[bit31==0], offset:  51 [(23, 1)]
Enemy_A_status			DCD 0x0000001D		; Alive[bit31==0], offset:  29 [( 1, 1)]
Enemy_B_status			DCD 0x0000014B		; Alive[bit31==0], offset: 331 [(23,11)]
Enemy_SP_status			DCD 0x00000135		; Alive[bit31==0], offset: 309 [( 1,11)]
Bomberman_direction 	DCD 0x00000000		; 0=stop, 1=up, 2=right, 3=down, 4=left
Score					DCD 0x00000000
Time					DCD 0x00000078		; Time: 120
Level					DCD 0x00000000
Life					DCD 0x00000004
Bomb_status				DCD 0x80000000		; Not placed[bit31==1], offset: don't care
Bomb_counter			DCD 0x00000006		; Initialize to any number will be fine
Bomb_detonate			DCD 0x00000001		; 0=detonating, 1=not detonating
Pause					DCD 0x00000000		; 0=playing, 1=paused
Game_over				DCD 0x00000000		; 0=playing, 1=game over
Seed_1					DCD 0x2468ACE7
Seed_2					DCD 0xEDCB1379



FIQ_Handler
 	STMFD SP!, {r0-r7, lr}			; Handler_Stack_Push_1

	LDR r0, =0xE000C008				; Check if it is UART0 interrupt
	LDR r1, [r0]
	TST r1, #1
	BEQ	UART0_Handler		 		; Branch is taken when bit0 == 0, UART0 interrupt

	LDR r0, =0xE0004000				; Check if it is Timer0 interrupt
	LDR r1, [r0]
	TST r1, #1
	BNE Timer0_Handler_Fast			; Branch is taken when bit0 == 1, Timer0 interrupt (MR0) - fast movement
	TST r1, #2
	BNE Timer0_Handler_Normal		; Branch is taken when bit1 == 1, Timer0 interrupt (MR1) - slow movement
	
	LDR r0, =0xE0008000				; Check if it is Timer1 interrupt
	LDR r1, [r0]
	TST r1, #1
	BNE Timer1_Handler				; Branch is taken when bit2 == 1, Timer1 interrupt (MR0) - time
		
	LDR r0, =0xE01FC140				; Check if it is EINT1 interrupt
	LDR r1, [r0]
	TST r1, #2
	BNE EINT1_Handler				; Branch is taken when bit1 == 1, EINT1 interrupt (button)

FIQ_Exit
	LDMFD SP!, {r0-r7, lr}	 		; Handler_Stack_Pop_1
	SUBS pc, lr, #4					; Return to original program



UART0_Handler
	STMFD SP!, {r0-r6, lr}			; Handler_Stack_Push_2-1
	
	BL read_character
	LDR r4, =Seed_1					; Update the first seed using the user-entered character
	LDR r1, [r4]
	ADD r1, r0, r1, ROR #1
	STR r1, [r4]
	LDR r4, =Seed_2					; Update the second seed using Timer1 Counter
	LDR r5, =0xE0008008
	LDR r1, [r4]
	LDR r2, [r5]
	ADD r1, r1, r2, ROR #2			
	STR r1, [r4]
	
;Pause/GameOver_Condition
	LDR r4, =Pause					; Do nothing if paused or game over
	LDR r1, [r4]
	CMP r1, #1
	LDRNE r4, =Game_over
	LDRNE r1, [r4]
	CMPNE r1, #1
	BEQ UART0_Exit
	
	CMP r0, #0x62					; Key_B - place bomb
	BEQ Key_B

	LDR r4, =Bomberman_direction
	LDR r1, [r4]					; Load Bomberman_direction
	CMP r1, #0
	BNE UART0_Exit					; Check if direction has changed, if so, exit
	
	CMP r0, #0x77					; Key_W - up
	LDREQ r5, =Bomb_counter			; Increment Bomb_counter for every movement
	LDREQ r3, [r5]
	ADDEQ r3, r3, #1
	STREQ r3, [r5]
	BEQ Key_W
	
	CMP r0, #0x64					; Key_D - right
	LDREQ r5, =Bomb_counter			; Increment Bomb_counter for every movement
	LDREQ r3, [r5]
	ADDEQ r3, r3, #1
	STREQ r3, [r5]
	BEQ Key_D
	
	CMP r0, #0x73					; Key_S - down
	LDREQ r5, =Bomb_counter			; Increment Bomb_counter for every movement
	LDREQ r3, [r5]
	ADDEQ r3, r3, #1
	STREQ r3, [r5]
	BEQ Key_S
	
	CMP r0, #0x61					; Key_A - left
	LDREQ r5, =Bomb_counter			; Increment Bomb_counter for every movement
	LDREQ r3, [r5]
	ADDEQ r3, r3, #1
	STREQ r3, [r5]
	BEQ Key_A
	
	B UART0_Exit					; Other cases

Key_W
	MOV r1, #1						; Set direction (r1) to 1 (up)
	STR r1, [r4]					; Store Bomberman_direction
	B UART0_Exit
Key_D
	MOV r1, #2						; Set direction (r1) to 2 (right)
	STR r1, [r4]					; Store Bomberman_direction
	B UART0_Exit
Key_S
	MOV r1, #3						; Set direction (r1) to 3 (down)
	STR r1, [r4]					; Store Bomberman_direction
	B UART0_Exit
Key_A
	MOV r1, #4						; Set direction (r1) to 4 (left)
	STR r1, [r4]					; Store Bomberman_direction	
	B UART0_Exit
Key_B
	LDR r4, =Bomberman_status		; Update Bomb_status to Bomberman_status
	LDR r0, [r4]
	LDR r5, =Bomb_status
	LDR r3, [r5]
	CMP r3, #0						; Check if a bomb is already placed (Bomb_status is positive)
	STRLT r0, [r5]
	LDRLT r6, =Bomb_counter			; Reset counter to 0
	MOVLT r4, #0
	STRLT r4, [r6]

UART0_Exit
	LDMFD SP!, {r0-r6, lr}	 		; Handler_Stack_Pop_2-1
	B FIQ_Exit
	
	

Timer0_Handler_Fast
	STMFD SP!, {r0-r7, lr}			; Handler_Stack_Push_2-2
	
	
	LDR r4, =Enemy_SP_status	
	LDR r1, [r4]				; Check if the enemy is dead (Enemy_SP_status < 0)
	CMP r1, #0
	BLT Timer0_Fast_Exit
	
	MOV r3, #0					; Initialize r3 (Flag) to 0x00
	LDR r5, =Board_array
	
loop_random
	MOV r8, #0x01
	STMFD sp!, {r1, r3}
	BL Random_generator			; Return a random number (0-3) in r0
	LDMFD sp!, {r1, r3}
	LSL r8, r8, r0				; Value used to set the flag (r3)
	ADD r0, r0, #1				
	CMP r0, #1					; Move up, new location = old location - 28
	SUBEQ r2, r1, #28
	CMP r0, #2					; Move right, new location = old location - 1
	SUBEQ r2, r1, #1	
	CMP r0, #3					; Move down, new location = old location + 28
	ADDEQ r2, r1, #28
	CMP r0, #4					; Move left, new location = old location + 1
	ADDEQ r2, r1, #1		
	
	LDRB r7, [r5, r2]			; Check if the new location available
	TST r7, #8
	BNE set_flag				; If not, set a flag
	
	
check_bomb_blast
	TST r7, #4					; check if new location is a bomb blast
	BEQ check_bomberman	
	
	MOV r3, #-1				; if yes, update enemy_sp_status = -1
	STR r3, [r4]
	
update_score
	LDR r4, =Level
	LDR r0, [r4]
	ADD r3, r0, r0, LSL #3			; r0(point to add) := r0(level) * 10 if an enemy is killed
	ADD r0, r0, r3
										; r0(point to add) := r0(level) if a brick is destroyed
	LDR r4, =Score						; Update the score			
	LDR r3, [r4]
	ADD r3, r3, r0
	STR r3, [r4]

check_all_enemy
	LDR r4, =Enemy_A_status
	LDR r0, [r4]
	CMP r0, #0
	BGE update_array
	
	LDR r4, =Enemy_B_status
	LDR r0, [r4]
	CMP r0, #0
	BGE update_array
	MOV r0, #0
	B Reset_board
	
	
check_bomberman
	CMP r7, #2					; If the new location is bomberman
	LDREQ r0, =Bomberman_status	; if yes, update bomberman_status = -1
	MOVEQ r1, #-1
	STREQ r1, [r0]
	MOVEQ r0, #1
	BEQ Reset_board
	
	STR r2, [r4]				; Update the Enemy_status and board array
	MOV r6, #0x07
	STRB r6, [r5, r2]
update_array
	LDR r4, =Enemy_A_status
	LDR r0, [r4]
	CMP r1, r0
	
	LDRNE r4, =Enemy_B_status
	LDRNE r0, [r4]
	CMPNE r1, r0
	
	MOVEQ r6, #0x03
	MOVNE r6, #0x00				; Clear the content of old location on Board_array
	
	STRB r6, [r5, r1]
	B Timer0_Fast_Exit

set_flag
	ORR r3, r3, r8			; Set a specified bit in flag (r3)
;Check_Flag
	CMP r3, #0x0F				; Check if all 4 bits of flag is set
	BNE loop_random
		
		

Timer0_Fast_Exit
	BL Display_board
	LDR r0, =0xE0004000				; Clear Timer0 Interrupt by writing 1 to bit0 of Interrupt Register
	LDR r1, [r0]
	ORR r1, r1, #1
	STR	r1, [r0]
	LDMFD SP!, {r0-r7, lr}	 		; Handler_Stack_Pop_2-2
	B FIQ_Exit
	

	
Timer0_Handler_Normal
	STMFD SP!, {r0-r7, lr}			; Handler_Stack_Push_2-3
	
	LDR r5, =Board_array			; These are the registers for the addresses of all needed data in this handler
	LDR r6, =Bomb_status
	LDR r7, =Bomb_counter
	LDR r8, =Bomb_detonate
	LDR r9, =Bomberman_status
	LDR r10, =Bomberman_direction
	

;Detonating_Check
	LDR r0, [r8]					; Check if the bomb is detonating (0=yes, 1=no)
	CMP r0, #0
	BNE bomb_placed					; Not detonating >> Next check
;Clear_Bomb(and blast)
	
	MOV r0, #2
	BL RGB_LED
	
	LDR r1, [r6]					; Find the location of bomb
	BL Clear_bomb					; Clear the bomb to empty space
	BL Bomb_blast_operation			; Clear surround to space (except wall)
;Clear_Detonate_Data
	MOV r0, #1						; Set Bomb_detonate to 1 (detonating)						
	STR r0, [r8]
	MOV r1, #-1
	STR r1, [r6]					; Change Bomb_status to -1 (not placed)

;Display_Bomb
bomb_placed
	LDR r1, [r6]					
	CMP r1, #0						; Check if Bomb_status is placed (positive)
	BLT enemy_movement				; Not placed >> Next check
	
	;LDR r0, [r7]					; Check whether the bomberman moves after placed the bomb
	LDR r2, [r9]					; Bomberman_status
	
	LDR r3, [r10]					; Bomberman_direction
	CMP r3, #1						; Bomberman_direction == 1, move up, new_location = current_location - 28		
	SUBEQ r0, r2, #28
	CMP r3, #2						; Bomberman_direction == 2, move right, new_location = current_location - 1
	SUBEQ r0, r2, #1	
	CMP r3, #3						; Bomberman_direction == 3, move down, new_location = current_location + 28
	ADDEQ r0, r2, #28 	
	CMP r3, #4						; Bomberman_direction == 4, move left, new_location = current_location + 1
	ADDEQ r0, r2, #1
	CMP r3, #0						; stay
	MOVEQ r0, r2
	
	LDRB r3, [r5, r0]				; If can't move to new location and bomb location == bomberman location, display 0x0A bomberman with bomb
	TST r3, #8
	;MOVNE r2, r2
	MOVEQ r2, r0

	
	CMP r2, r1
	MOVEQ r2, #0x0A					; Bomb_counter == 0 (no movement), set that coordinate to 0x0A (bomberman with bomb) 
	MOVNE r2, #0x08					; Bomb_counter >= 1 (movement), set that coordinate to 0x09 (bomb) 
	STRB r2, [r5, r1]
;Add_Bomb_Blast
	LDR r0, [r7]
	CMP r0, #5						; Check if time out (counter == 5), if so, detonate
	BNE enemy_movement
	MOV r0, #1
	BL RGB_LED
	BL Bomb_blast_operation
;Set_Detonate_Data
	MOV r0, #0						; Reset Bomb_detonate to 0 (detonating)
	STR r0, [r8]

enemy_movement
;Normal_Enemy_A	
	LDR r4, =Enemy_A_status			; Move Enemy_A randomly
	MOV r0, #0
	BL Move_enemy
	MOV r1, r0						; Keep track of dead enemy
;Normal_Enemy_B	
	LDR r4, =Enemy_B_status			; Move Enemy_B randomly
	MOV r0, #0
	STMFD sp!, {r1}
	BL Move_enemy
	LDMFD sp!, {r1}
	ADD r1, r1, r0
;Fast_Enemy
	LDR r4, =Enemy_SP_status			; Move Enemy_SP randomly
	MOV r0, #1
	STMFD sp!, {r1}
	BL Move_enemy
	LDMFD sp!, {r1}
	ADD r1, r1, r0	
;Check_Dead_Enemy
	CMP r1, #3						; Level up if r1 (dead enemy) == 3
	MOVEQ r0, #0
	BEQ Reset_board

;Move_Bomberman	
move_bomberman
	LDR r1, [r9]					; Check if bomberman is dead (Bomberman_status < 0)
	CMP r1, #0
	MOVLT r0, #1					; Dead >> Reset the board (game)
	BLT Reset_board
	
	LDR r3, [r10]					; Check if bomberman should stay (Bomberman_direction == 0)
	CMP r3, #0
	BEQ stay_bomberman
;Movement_Direction
	CMP r3, #1						; Bomberman_direction == 1, move up, new_location = current_location - 28		
	SUBEQ r0, r1, #28
	CMP r3, #2						; Bomberman_direction == 2, move right, new_location = current_location - 1
	SUBEQ r0, r1, #1	
	CMP r3, #3						; Bomberman_direction == 3, move down, new_location = current_location + 28
	ADDEQ r0, r1, #28 	
	CMP r3, #4						; Bomberman_direction == 4, move left, new_location = current_location + 1
	ADDEQ r0, r1, #1
;Check_Availability_New_Location
	LDRB r2, [r5, r0]
	
	;CMP r2, #0x08
	;LDREQ r0, [r8]
	;CMPEQ r0, #0
	;MOVEQ r0, #1
	;BEQ Reset_board
	
	TST r2, #8						; If bomberman can't move to new location (brick, bomb, wall, etc.), stay
	BNE stay_bomberman
	
	CMP r2, #0x00					; If the new location is neither obstacle nor empty space (0x00) , Reset the board (bomberman dies)
	MOVNE r0, #1
	BNE Reset_board
		
;Move_To_New_Location
	STR r0, [r9]					; Update Bomberman_status and Board_array to new location
	MOV r2, #0x02
	STRB r2, [r5, r0]
;Deal_With_Old_Location	
	LDRB r2, [r5, r1]				; Load content of old location from board array
	
	CMP r2, #0x0A					; Check if it is 0x10 (Bomberman with bomb), if so, update to 0x08 (bomb)
	MOVEQ r2, #0x08
	STREQB r2, [r5, r1]	
	CMP r2, #0x02					; Check if it is 0x02 (Bomberman), if so, update to 0x00 (empty)
	MOVEQ r2, #0x00
	STREQB r2, [r5, r1]
	B clear_bomberman_direction		; Else, do nothing
	
stay_bomberman
	LDRB r2, [r5, r1]				; Load content of old/new location from board array
	CMP r2, #0x03					; Check if encounter an enemy (0x03 or 0x07), if so, Reset board (bomberman dies)
	CMPNE r2, #0x07
	MOVEQ r0, #1
	BEQ Reset_board

clear_bomberman_direction
	MOV r2, #0						; Clear the Bomberman_direction to 0
	STR r2, [r10]
	BL Display_board

Timer0_Normal_Exit
	LDR r0, =0xE0004000				; Clear Timer0 Interrupt by writing 1 to bit1 of Interrupt Register
	LDR r1, [r0]
	ORR r1, r1, #2
	STR	r1, [r0]
	LDMFD SP!, {r0-r7, lr}	 		; Handler_Stack_Pop_2-3
	B FIQ_Exit



Timer1_Handler
	STMFD SP!, {r0-r7, lr}			; Handler_Stack_Push_2-4
	
	LDR r4, =Level					; Do nothing if game is not started
	LDR r0, [r4]
	CMP r0, #0
	BEQ Timer1_Exit

	LDR r4, =Time					; Decrement time
	LDR r0, [r4]
	SUBS r0, r0, #1
	STR r0, [r4]	
	LDREQ r5, =Game_over			; If time == 0, set Game_over flag and disable all timers
	MOVEQ r1, #1
	STREQ r1, [r5]
	BLEQ Disable_Timer0
	BLEQ Disable_Timer1
	BL Display_board

Timer1_Exit
	LDR r0, =0xE0008000				; Clear Timer1 Interrupt by writing 1 to bit0 of Interrupt Register
	LDR r1, [r0]
	ORR r1, r1, #1
	STR	r1, [r0]
	LDMFD SP!, {r0-r7, lr}	 		; Handler_Stack_Pop_2-4
	B FIQ_Exit



EINT1_Handler
	STMFD SP!, {r0-r7, lr}			; Handler_Stack_Push_2-5
	
	LDR r4, =Level					; Do nothing if game not started or game over
	LDR r1, [r4]
	CMP r1, #0
	LDRNE r4, =Game_over
	LDRNE r1, [r4]
	CMPNE r1, #1
	BEQ EINT1_Exit
	
	LDR r4, =Pause
	LDR r1, [r4]
	CMP r1, #0
	
	MOVNE r0, #2
	BLNE RGB_LED
	BLNE Enable_Timer0				; Currently paused (1) >> resume the game
	BLNE Enable_Timer1
	MOVNE r1, #0
	
	MOVEQ r0, #3
	BLEQ RGB_LED
	BLEQ Disable_Timer0				; Currently playing (0) >> pause the game
	BLEQ Disable_Timer1
	MOVEQ r1, #1
	
	STR r1, [r4]					; Update the data and screen (PuTTY)
	BL Display_board

EINT1_Exit
	LDR r0, =0xE01FC140				; Clear Interrupt by writing 1 to bit1
	LDR r1, [r0]
	ORR r1, r1, #2					
	STR r1, [r0]
	LDMFD SP!, {r0-r7, lr}	 		; Handler_Stack_Pop_2-5
	B FIQ_Exit





	
Reset_board
		; This function resets the board and data, and prints new board in one of the two cases, "Level cleared"(0) or "Bomberman died"(1)
		; One argument is needed in r0 indicating which case is it	
	STMFD sp!, {r0}
	BL Disable_Timer1				; Disable Timer1
	BL Reset_Timer0					; Disable and Reset Timer0
	LDMFD sp!, {r0}
	CMP r0, #0
	BEQ clear
dead
	LDR r4, =Life					; Reduce one life
	LDR r0, [r4]
	SUBS r0, r0, #1					; If life == 0, set game over flag and disable all timers
	STR r0, [r4]
	
	MOV r1, #15
	RSB r0, r0, #4					;	reverse subtract (4-r0)
	LSR r0, r1, r0
	BL LEDs							; display number of lives on LED
	
	LDREQ r4, =Game_over
	MOVEQ r0, #1
	STREQ r0, [r4]
	BEQ exit_Reset_board
	B common
clear
	LDR r4, =Score					; Add 100 points to score
	LDR r0, [r4]
	ADD r0, r0, #100
	STR r0, [r4]
	LDR r4, =Level					; Level up
	LDR r0, [r4]
	ADD r0, r0, #1
	STR r0, [r4]
	
	BL display_digit
	
	LDR r4, =T0MR0					; Update time-out period (-0.05 second) for fast movement (MR0)
	LDR r0, [r4]
	LDR r1, =Sec005				; 0.05 second
	CMP r0, r1
	SUBGT r0, r0, r1
	STRGT r0, [r4]
	MOVGT r0, r0, LSL #1			; Update time-out period (-0.1 second) for normal movement (MR1)
	STRGT r0, [r4, #T0MR1]
common
	LDR r5, =Board_array			; Reset Board_array
	LDR r4, =Board_array_initial
	BL Copy_board
	LDR r4, =Bomberman_status		; Reset Bomerman_status
	MOV r0, #0x33
	STR r0, [r4]
	LDR r4, =Enemy_A_status			; Reset Enemy_A_status
	MOV r0, #0x1D
	STR r0, [r4]	
	LDR r4, =Enemy_B_status			; Reset Enemy_B_status
	LDR r0, =0x0000014B
	STR r0, [r4]
	LDR r4, =Enemy_SP_status		; Reset Enemy_SP_status
	LDR r0, =0x00000135
	STR r0, [r4]
	LDR r4, =Bomberman_direction	; Reset Bomberman_direction
	MOV r0, #0
	STR r0, [r4]
	LDR r4, =Bomb_status			; Reset Bomb_status
	MOV r0, #0x80000000
	STR r0, [r4]
	LDR r4, =Bomb_detonate			; Reset Bomb_detonate
	MOV r0, #1
	STR r0, [r4]
	
	LDR r4, =Level					; Level
	LDR r0, [r4]
	SUB r0, r0, #1
	MOV r1, #3
	MUL r2, r0, r1					; (level-1) * 3
	ADD r0, r2, #10
	BL Add_brick
	
	BL Display_board				; new board is displayed	
	BL Enable_Timer1				; Enable Timer1
	BL Enable_Timer0				; Enable Timer0
	
exit_Reset_board
	MOV r0, #2
	BL RGB_LED

	LDR r0, =0xE0004000				; Clear Timer0 Interrupt by writing 1 to bit[1:0] of Interrupt Register
	LDR r1, [r0]
	ORR r1, r1, #3
	STR	r1, [r0]
	LDMFD SP!, {r0-r7, lr}	 		; Handler_Stack_Pop_2-3
	B FIQ_Exit
	
	END
	

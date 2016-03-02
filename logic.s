	AREA logic, CODE, READWRITE
	EXPORT Move_enemy
	EXPORT Bomb_blast_operation
	EXPORT Clear_bomb
		
	IMPORT Random_generator
	IMPORT Board_array
	IMPORT Bomberman_status
	IMPORT Enemy_A_status
	IMPORT Enemy_B_status
	IMPORT Enemy_SP_status
	IMPORT Bomb_detonate
	IMPORT Bomb_status
	IMPORT Bomberman_direction
	IMPORT Score
	IMPORT Level



Move_enemy
		; Two arguments are needed to be passed in r0 and r4
		; indicating the type of enemy (fast=1, normal=0) and the 
		; address of "Enemy_status"
		
		; One return value will be passed to r0
		; indicating whether the enemy is alive(0) or dead(1)
	STMFD SP!, {r5-r8, lr}
	LDR r1, [r4]				; Check if the enemy is dead (Enemy_status < 0)
	CMP r1, #0
	BLT dead_enemy

	MOV r3, #0					; Initialize r3 (Flag) to 0x00
	LDR r5, =Board_array
	CMP r0, #1					; Determine the type of enemy based on argument
	MOVEQ r6, #0x07
	MOVNE r6, #0x03
	
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
;Move_Direction
	LDRB r7, [r5, r2]			; Check if the new location available
	TST r7, #8
	BNE set_flag				; If not, set a flag
	
	CMP r7, #4					; Check if the new location is a bomb blast, if so, enemy dies
	CMPNE r7, #5
	MOVEQ r2, #-1
	STR r2, [r4]				; Update the Enemy_status and Board_array
	STRNEB r6, [r5, r2]
	MOV r6, #0x00				; Clear the content of old location on Board_array to 0x00
	STRB r6, [r5, r1]
	
	LDREQ r5, =Level			; Update score if enemy dies		
	LDREQ r0, [r5]
	ADDEQ r5, r0, r0, LSL #3	
	ADDEQ r0, r5, r0			
	LDREQ r5, =Score				
	LDREQ r6, [r5]
	ADDEQ r6, r6, r0
	STREQ r6, [r5]
	
	MOVEQ r0, #1				; Initialize r0 (return value) to 1 if enemy dies
	BEQ exit_Move_enemy
	
	LDR r6, =Bomberman_direction
	LDR r1, [r6]
								; r2 = new enemy location
	LDR r6, =Bomberman_status	; Load adress of bomberman status
	LDR r7, [r6]				; r7 = status of bomberman
	CMP r2, r7
	BNE skip
	
 	EOR r0, r0, r1				; Check if they are moving in opposite directions
 	LDR r1, =0xFFFFFFFE
 	ORR r0, r0, r1				; Logical OR with r1 to find whether they are moving in opposite directions
 	CMP r0, #-1
 	MOVNE r7, #-1
 	STRNE r7, [r6]
	
skip
	MOV r0, #0					; Initialize r0 (return value) to 0
	B exit_Move_enemy
	
set_flag
	ORR r3, r3, r8				; Set a specified bit in flag (r3)
;Check_Flag
	CMP r3, #0x0F				; Check if all 4 bits of flag is set
	BNE loop_random
	
	MOV r0, #0					; Initialize r0 (return value) to 0
	B exit_Move_enemy
	
dead_enemy
	MOV r0, #1					; Initialize r0 (return value) to 1
exit_Move_enemy
	LDMFD SP!, {r5-r8, lr}
	BX lr



	
Bomb_blast_operation
		; No argument is needed
	STMFD SP!, {r5, lr}
	
	LDR r5, =Bomb_status		; Get the location of the bomb (as the offset to Board_array)
	LDR r1, [r5]
	
	MOV r0, #0x04				; Flag for horizontal
	MOV r2, #4					; Counter
loop_horizontal_left	 
	ADD r1, r1, #1				; Move one position left (+1)
	SUB r2, r2, #1
	BL Bomb_blast
	CMP r2, #0
	BNE loop_horizontal_left	; Loop 4 times (usually)
	
	MOV r2, #4					; Counter
	LDR r1, [r5]
loop_horizontal_right
	SUB r1, r1, #1				; Move one position right (-1)
	SUB r2, r2, #1
	BL Bomb_blast
	CMP r2, #0
	BNE loop_horizontal_right	; Loop 4 times (usually)

	MOV r0, #0x05				; Flag for vertical
	MOV r2, #2					; Counter
	LDR r1, [r5]
loop_vertical_bottom
	ADD r1, r1, #28				; Move one position down (+28)
	SUB r2, r2, #1
	BL Bomb_blast
	CMP r2, #0
	BNE loop_vertical_bottom	; Loop 2 times (usually)
	
	MOV r2, #2					; Counter
	LDR r1, [r5]
loop_vertical_top
	SUB r1, r1, #28 			; Move one position up (-28)
	SUB r2, r2, #1
	BL Bomb_blast
	CMP r2, #0
	BNE loop_vertical_top		; Loop 2 times (usually)
	
	LDMFD SP!, {r5, lr}
	BX lr;


Bomb_blast			; Private subroutine, only called by Bomb_blast_operation (not follow AAPCS)
		; Two arguments are needed in r0 and r1
		; carrying the flag for either horizontal(4) or vertical(5)
		; and the location (as offset) to add/clear bomb blast
		
		; The r2 (counter) may be changed as the result of subroutine, Display_bomb_blast or Clear_bomb
	STMFD SP!, {r0, r1, lr}
	
	LDR r3, =Bomb_detonate
	LDR r3, [r3]
	CMP r3, #0
	BEQ clearing				; Clear bomb blast if Bomb_detonate is 0 (detonating)
	BL Display_bomb_blast		; Add bomb blast if Bomb_detonate is 1 (not detonating)
	B exit_bomb_blast
clearing
	BL Clear_bomb

exit_bomb_blast
	LDMFD SP!, {r0, r1, lr}
	BX lr


Clear_bomb
		; One argument is needed in r1
		; carrying the location (as offset) to clear bomb (blast)
		
		; The r2 (counter) may be changed as the result of this subroutine
	STMFD sp!, {r4-r5}
	
	LDR r4, =Board_array			; Obtain the content of that location
	LDRB r0, [r4, r1]
	CMP r0, #0x0A					; check if it is 0x0A (bomberman with bomb)
	LDREQ r5, =Bomberman_status		; Change Bomberman_status to negative (dead)
	MOVEQ r3, #-1
	STREQ r3, [r5]
	CMP r0, #0x0F					; check if it is 0x0F (wall)
	MOVNE r0, #0x00					; Not Equal - change it to 0x00 (empty space)
	STRNEB r0, [r4, r1]
	MOVSEQ r2, #0					; Equal - no change, and stop checking the next location in same direction

	LDMFD sp!, {r4-r5}	
	BX lr;


Display_bomb_blast			; Private subroutine, only called by Bomb_blast
		; Two arguments are needed in r0 and r1 carrying the flag for either
		; horizontal(4) or vertical(5) and the location (as offset) to add bomb blast
		
		; The r2 (counter) may be changed as the result of this subroutine
	STMFD sp!, {r4-r8, lr}
	
	LDR r4, =Board_array			; Obtain the content of that location
	LDRB r3, [r4, r1]
	CMP r3, #0x0F					; Check if it is 0x0F (wall)
	STRNEB r0, [r4, r1]				; Not Equal - change it to 0x04/0x05 (horizontal/ vertical bomb blast)
	MOVEQ r2, #0					; Equal - no change, and stop checking the next location in same direction
	BEQ exit_display_bomb_blast
	
	CMP r3, #0x03					; Check if it is 0x03 or 0x07 (enemy)
	BEQ load_normal_enemy
	CMP r3, #0x07	
	BEQ load_enemy
	CMP r3, #0x02					; Check if it is 0x02 (bomberman)
	BNE skip_1
			
	LDR r7, =Bomberman_direction
	LDR r6, [r7]
	LDR r8, =Bomberman_status
	LDR r5, [r8]
	CMP r6, #1						; Bomberman_direction == 1, move up, new_location = current_location - 28		
	SUBEQ r0, r5, #28
	CMP r6, #2						; Bomberman_direction == 2, move right, new_location = current_location - 1
	SUBEQ r0, r5, #1	
	CMP r6, #3						; Bomberman_direction == 3, move down, new_location = current_location + 28
	ADDEQ r0, r5, #28 	
	CMP r6, #4						; Bomberman_direction == 4, move left, new_location = current_location + 1
	ADDEQ r0, r5, #1
	CMP r6, #0						; Bomberman_direction == 0, stay, new_location = current_location
	MOVEQ r0, r5

	STMFD sp!, {r2}
	LDRB r2, [r4, r0]	
	CMP r2, #0x00					; If the new location is not empty space (0x00) , bomberman dies
	LDRNE r4, =Bomberman_status		; Update Bomberman_status to negative (-1)
	MOVNE r0, #-1
	STRNE r0, [r4]
	LDMFD sp!, {r2}
	BNE exit_display_bomb_blast

	STMFD sp!, {r2}
	STR r0, [r8]					; Update Bomberman_status, Bomberman_direction and Board_array
	MOV r2, #0x02
	STRB r2, [r4, r0]
	MOV r2, #0
	STR r2, [r7]
	LDMFD sp!, {r2}
	
skip_1
	CMP r3, #0x0B					; Check if it is 0x0B (brick)
	BLEQ Update_score
	B exit_display_bomb_blast
	
load_enemy
	LDR r4, =Enemy_SP_status		; Update Enemy_SP_status to negative (-1)
	LDR r0, [r4]
	CMP r0, r1	
	MOVEQ r0, #-1					; If yes, update Enemy_SP_status to negative (-1)
	STREQ r0, [r4]
	BLEQ Update_score				; Update the score

	
load_normal_enemy
	LDR r4, =Enemy_A_status			; Check if Enemy A is in same location
	LDR r0, [r4]					
	CMP r0, r1
	MOVEQ r0, #-1					; If yes, update Enemy_A_status to negative (-1)
	STREQ r0, [r4]
	BLEQ Update_score				; Update the score
	
	LDR r4, =Enemy_B_status			; Check if Enemy B is in same location
	LDR r0, [r4]
	CMP r0, r1	
	MOVEQ r0, #-1					; If yes, update Enemy_B_status to negative (-1)
	STREQ r0, [r4]
	BLEQ Update_score				; Update the score

exit_display_bomb_blast
	LDMFD SP!, {r4-r8, lr}	 	
	BX lr



Update_score			; Private subroutine, only called by Display_bomb_blast (not follow AAPCS)
		; One argument is needed in r3 (0x03/0x07/0x0B, Enemy/Brick) 
		; indicating how many points needed to be added to the score
	LDR r4, =Level						; Load current level to determine the point to add
	LDR r0, [r4]
	CMP r3, #0x0B
	ADDNE r3, r0, r0, LSL #3			; r0(point to add) := r0(level) * 10 if an enemy is killed
	ADDNE r0, r0, r3
										; r0(point to add) := r0(level) if a brick is destroyed
	LDR r4, =Score						; Update the score			
	LDR r3, [r4]
	ADD r3, r3, r0
	STR r3, [r4]
	BX lr
	


	END
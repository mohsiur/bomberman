# Bomberman

## Materials needed to run game

* Keil uVision v4
* ARM7 board LPC2138 by NXP(Phillips)
* PuTTy

## Installation

* Start a new Project in Keil with board LPC2138 by NXP(Phillips) 
* Add files to target1
	* board.s
	* main.s
	* Startup.s
	* handler.s
	* library.s
	* logic.s
	* wrapper.c
* Build Target and Load onto ARM board
* Open PuTTy and run a serial connection to the respective port COMX (X being port number)
* PuTTy will need to be run at a baud rate = 1,152,000

## How to play and Rules

This program is a game which allows the player to control bomberman to move around a 23x11 game board. Player has to use one of the 4 keystrokes to move bomberman and a keystroke to release one (and only one) bomb in order to destroy bricks and kill enemies to earn points. These keystrokes are:

* w  –  Move bomberman one position up if possible
* d  –  Move bomberman one position right if possible
* s  –  Move bomberman one position down if possible
* a  –  Move bomberman one position left if possible
* b  –  Release a bomb

Player has to kill as many enemies (and probably bricks) as possible within the game time of 120 seconds in order to earn as many points as s/he can. Bomb will be detonated after 5 movements (including those attempted by player but not success) of bomberman from the time it released, and the range of detonation is vertically 2 positions and horizontally 4 positions from the detonation point. Everytime a brick is destroyed or an enemy is killed, points equivalent to the current level or 10 times the current level are rewarded respectively. When all three enemies in the same level are killed, the game board will be reset with new level and faster speed (initially 0.25 sec for the fast-moving enemy and 0.5 sec for all others), and rewards 100 points toward the score. When bomberman is killed either by bomb or enemy, the game board will be reset with everything being restored (same level). Player can pause/resume the game at anytime by pressing the external button. The LEDs lights are indicating the remaining lives for bomberman (initially 4), and the 7-segments displaying is indicating the current level of the game. Also, the state of the game is shown by the RGB LED. The game is over when 120 second is passed or when all lives are used up. Any unused life is counted as 25 points to the score. At the end, player will be provided the final score and the option to restart the game.

## Pictures

![Board](/img/board.jpg)

## Contributors

* Mohsiur Rahman
* Zhen Rong Huang

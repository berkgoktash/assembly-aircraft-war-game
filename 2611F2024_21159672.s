# Berk Goktas
# 21159672
# bgoktas@connect.ust.hk

.data
title: 		.asciiz "COMP2611 Aircraft War Game"

space_string:		.asciiz " "

total_cnt:	.word 1 # the total number of 30 milliseconds

bullet_number:	.word 0 # the number of 30 milliseconds, every 10 * 30 milliseconds, generate a bullet

small_enemy_number:	.word 0 # the number of small enemies, 2 small enemies, one medium boss

medium_enemy_number:	.word 0 # the number of medium enemies, 2 medium enemies, one large boss

bullet_enemy_number:	.word 0 # the number of 30 milliseconds, 40 to generate a bullet for the enemy

input_key:	.word 0 # input key from the player

width:		.word 480 # the width of the screen
height:		.word 700 # the height of the screen

# list of self bullets, 100-119
self_bullet_list:	.word -1:25
# [100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119]
# all the elements are -1 at first, which means no bullet
# if a bullet is created, the id of the bullet will be stored in the list
# if a bullet is destoried, the id of the bullet will be set to -1
self_bullet_address:	.word self_bullet_list

# list of enemies, 500-519
enemy_list:		.word -1:25
# [500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519]
# all the elements are -1 at first, which means no enemy
# if an enemy is created, the id of the enemy will be stored in the list
# if an enemy is destoried, the id of the enemy will be set to -1
enemy_address:	.word enemy_list

# list of enemy bullets, 900-999
enemy_bullet_list:	.word -1:105
# [900, 901, ..., 999]
# all the elements are -1 at first, which means no bullet
# if a bullet is created, the id of the bullet will be stored in the list
# if a bullet is destoried, the id of the bullet will be set to -1
enemy_bullet_address:	.word enemy_bullet_list


# score and left blood
score:		.word 0
left_blood:	.word 20
# destor small enemy: +3, medium enemy: +5, large enemy: +10, the score is obtained by syscall, you should not use 3 5 10 directly

# current_enemy_number
current_enemy_number:	.word 0 # temporary variable to store the current enemy number for your reference
current_enemy_number_2:	.word 0 # temporary variable to store the current enemy number for your reference

# current enemy bullet number
current_enemy_bullet_number:	.word 0 # temporary variable to store the current enemy bullet number for your reference

# current self bullet number
current_self_bullet_number:	.word 0 # temporary variable to store the current self bullet number for your reference

# TODO: [Optional] You can add more data variables here
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.text
main:		
	la $a0, title
	la $t0, width
	lw $a1, 0($t0)
	la $t0, height
	lw $a2, 0($t0)
	li $a3, 0 # 1: play the music, 0: stop the music
	li $v0, 100 # Create the Game Screen
	syscall		


init_game:
	# 1. create the ship
	li $v0, 101
	li $a0, 1 # the id of ship is 1
	li $a1, 180 # the x_loc of ship
	li $a2, 500 # the y_loc of ship
	li $a3, 25 # set the speed
	syscall

m_loop:		
	jal get_time
	add $s6, $v0, $zero # $s6: starting time of the game

	# store s6
	addi $sp, $sp, -4
	sw $s6, 0($sp)

	jal is_game_over # task 1: 15 points

	jal process_input # task 2: 15 points
	jal generate_self_bullet
	jal move_self_bullet
	jal destory_self_bullet

	jal create_enemy
	jal move_enemy
	jal destory_enemy

	jal generate_enemy_bullet # task 3: 20 points
	jal move_enemy_bullet
	jal destory_enemy_bullet

	jal collide_detection_enemy # task 4: 15 points
	jal collide_detection_shoot_by_enemy # task 5: 15 points
	jal collide_detection_shoot_enemy # task 6: 20 points


	# refresh the screen
	li $v0, 119
	syscall

	# restore s6
	lw $s6, 0($sp)
	addi $sp, $sp, 4
	add $a0, $s6, $zero
	addi $a1, $zero, 30 # iteration gap: 30 milliseconds
	jal have_a_nap

	# total_cnt += 1
	lw $t0, total_cnt
	addi $t0, $t0, 1
	sw $t0, total_cnt


	j m_loop	


#--------------------------------------------------------------------
# func: is_game_over
# Check whether the game is over
# Pseduo code:
# if total_cnt >= 2000, then game over, win (2000 means 2000 * 30 ms)
# if blood <= 0, then game over, lose
#--------------------------------------------------------------------
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TODO: check the total_cnt and blood {
is_game_over:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	lw $t7, total_cnt
	lw $t6, left_blood
	ble $t6, $zero, game_over_lose
	bge $t7, 2000, game_over_win
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
game_over_win:
	li $v0, 140
	li $a0, 1
	syscall
	li $v0, 10 # exit
	syscall	
	addi $sp, $sp, 4
	jr $ra
game_over_lose:
	li $v0, 140
	li $a0, 0
	syscall
	li $v0, 10 # exit
	syscall	
	addi $sp, $sp, 4
	jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

#--------------------------------------------------------------------
# func process_input
# Read the keyboard input and handle it!
#--------------------------------------------------------------------
process_input:	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal get_keyboard_input # $v0: the return value
	addi $t0, $zero, 119 # corresponds to key 'w'
	beq $v0, $t0, move_airplane_up
	addi $t0, $zero, 115
	beq $v0, $t0, move_airplane_down
	addi $t0, $zero, 97
	beq $v0, $t0, move_airplane_left
	addi $t0, $zero, 100
	beq $v0, $t0, move_airplane_right	 
	# TODO: add more key bindings here, e.g., move_airplane_down: key 's', value 115, move_airplane_left: key 'a', value 97, move_airplane_right: key 'd', value 100 {
	#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}
	j pi_exit
pi_exit:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

#--------------------------------------------------------------------
# func get_keyboard_input
# $v0: ASCII value of the input character if input is available;
#      otherwise, the value is 0;
#--------------------------------------------------------------------
get_keyboard_input:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	add $v0, $zero, $zero
	lui $a0, 0xFFFF
	lw $a1, 0($a0)
	andi $a1, $a1, 1
	beq $a1, $zero, gki_exit
	lw $v0, 4($a0)


gki_exit:	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra


#--------------------------------------------------------------------
# func: move_airplane
# Move the airplane
#--------------------------------------------------------------------
move_airplane_up:
	# if keyboard input is 'w', move the airplane up
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110 # get the location of the airplane
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location
	
	# judge $s1 - 25 >= 0
	addi $t0, $s1, -25
	bltz $t0, move_airplane_exit
	# move the airplane up
	addi $s1, $s1, -25
	li $v0, 120
	li $a0, 1 # id of the airplane
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

# TODO: add more contents here, e.g., move_airplane_down, move_airplane_left, move_airplane_right, please consider the boundary of the screen {
move_airplane_down:
	# if keyboard input is 's', move the airplane down
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110 # get the location of the airplane
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location
	
	# judge $s1 + 126 + 25 >= 700
	addi $t0, $s1, 25
	bge $t0, 574, move_airplane_exit
	# move the airplane down
	addi $s1, $s1, 25
	li $v0, 120
	li $a0, 1 # id of the airplane
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

move_airplane_left:
	# if keyboard input is 'a', move the airplane left
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110 # get the location of the airplane
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location
	
	# judge $s0 - 25 <= 0
	addi $t0, $s0, -25
	bltz $t0, move_airplane_exit
	# move the airplane left
	addi $s0, $s0, -25
	li $v0, 120
	li $a0, 1 # id of the airplane
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

move_airplane_right:
	# if keyboard input is 'd', move the airplane right
	addi $sp, $sp, -12
	sw $ra, 8($sp)
	sw $s0, 4($sp)
	sw $s1, 0($sp)
	li $v0, 110 # get the location of the airplane
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location
	
	# judge $s0 + 25 + 102 >= 480
	addi $t0, $s0, 25
	bge $t0, 378, move_airplane_exit
	# move the airplane right
	addi $s0, $s0, 25
	li $v0, 120
	li $a0, 1 # id of the airplane
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	syscall
	j move_airplane_exit

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

move_airplane_exit:
	lw $ra, 8($sp)
	lw $s0, 4($sp)
	lw $s1, 0($sp)
	addi $sp, $sp, 12
	jr $ra

	
#--------------------------------------------------------------------
# func: generate_self_bullet
# Generate airplane's bullet
#--------------------------------------------------------------------
generate_self_bullet:
	# if bullet_number == 10, generate a bullet, else bullet_number++
	lw $t0, bullet_number
	addi $t1, $zero, 10

	beq $t0, $t1, generate_self_bullet_create
	addi $t0, $t0, 1
	sw $t0, bullet_number
	jr $ra


generate_self_bullet_create:
	# set bullet_number = 0
	addi $t0, $zero, 0
	sw $t0, bullet_number

	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall
	add $s0, $v0, $zero # x location
	add $s1, $v1, $zero # y	location

	# create a bullet, id starts from 100
	addi $t0, $zero, 100
	lw $t1, self_bullet_address
	la $t2, self_bullet_list

	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	beq $t2, 20, generate_self_bullet_from_beginning

	add $t0, $t0, $t2

	# store t0 to t1-th element of self_bullet_list
	sw $t0, 0($t1)

	addi $t1, $t1, 4
	sw $t1, self_bullet_address

	li $v0, 106 # create a bullet
	move $a0, $t0 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	add $a3, $s2, $zero
	syscall

	jr $ra

generate_self_bullet_from_beginning:
	la $t2, self_bullet_list
	sw $t2, self_bullet_address
	j generate_self_bullet_create

#--------------------------------------------------------------------
# func: move_self_bullet
# Move the airplane's bullet
#--------------------------------------------------------------------
move_self_bullet:
	# find all the bullets in the self_bullet_list
	la $t0, self_bullet_list
	li $t3, -1

	j find_all_self_bullet


find_all_self_bullet:
	# get the first element of self_bullet_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, move_self_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available


	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	j move_self_bullet_up


continue_find_next_available:
	addi $t0, $t0, 4
	j find_all_self_bullet

move_self_bullet_up:

	addi $s1, $s1, -6
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1


	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_self_bullet
	
move_self_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: destory_self_bullet
# Destory the airplane's bullet if it is out of the screen
#--------------------------------------------------------------------
destory_self_bullet:
	# find all the bullets in the self_bullet_list
	la $t0, self_bullet_list
	li $t3, -1

	j find_all_self_bullet_destory

find_all_self_bullet_destory:
	# get the first element of self_bullet_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, destory_self_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available_destory

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	# if y location <= 0, destory the bullet
	bltz $s1, destory_self_bullet_destory

	addi $t0, $t0, 4
	j find_all_self_bullet_destory

continue_find_next_available_destory:
	addi $t0, $t0, 4
	j find_all_self_bullet_destory

destory_self_bullet_destory:
	# destory the bullet
	move $a0, $t1
	li $v0, 116
	syscall

	# set the bullet to -1
	addi $t2, $zero, -1
	sw $t2, ($t0)

	addi $t0, $t0, 4
	j find_all_self_bullet_destory

destory_self_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: create_enemy
# Create the enemy
#--------------------------------------------------------------------
create_enemy:
	# if total_cnt % 120 == 0, create an enemy
	lw $t0, total_cnt
	addi $t1, $zero, 120
	div $t0, $t1
	mfhi $t2
	beq $t2, $zero, create_enemy_generate

	jr $ra

create_enemy_generate:
	# create an enemy, id starts from 500
	# small_enemy_number += 1
	lw $t7, small_enemy_number
	addi $t7, $t7, 1
	sw $t7, small_enemy_number

	addi $t0, $zero, 500
	lw $t1, enemy_address
	la $t2, enemy_list

	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	beq $t2, 20, create_enemy_from_beginning

	add $t0, $t0, $t2

	# store t0 to t1-th element of enemy_list
	sw $t0, 0($t1)

	addi $t1, $t1, 4
	sw $t1, enemy_address

	# judge small_enemy_number == 3
	lw $t4, small_enemy_number
	addi $t5, $zero, 3
	beq $t4, $t5, create_enemy_boss_1

	li $v0, 130 # create an enemy
	move $a0, $t0 # the id of the enemy
	li $a1, 1
	syscall

	jr $ra

create_enemy_boss_1:

	# compare medium_enemy_number == 2
	lw $t4, medium_enemy_number
	addi $t5, $zero, 2
	beq $t4, $t5, create_enemy_boss_2

	# medium_enemy_number += 1
	lw $t7, medium_enemy_number
	addi $t7, $t7, 1
	sw $t7, medium_enemy_number

	sw $zero, small_enemy_number

	li $v0, 130 # create an enemy
	move $a0, $t0 # the id of the enemy
	li $a1, 2
	syscall

	jr $ra

create_enemy_boss_2:

	sw $zero, medium_enemy_number
	sw $zero, small_enemy_number

	li $v0, 130 # create an enemy
	move $a0, $t0 # the id of the enemy
	li $a1, 3
	syscall

	jr $ra


create_enemy_from_beginning:
	la $t2, enemy_list
	sw $t2, enemy_address
	j create_enemy_generate

#--------------------------------------------------------------------
# func: move_enemy
# Move the enemy automatically
#--------------------------------------------------------------------
move_enemy:
	# find all the enemies in the enemy_list
	la $t0, enemy_list
	li $t3, -1

	j find_all_enemy

find_all_enemy:
	# get the first element of enemy_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, move_enemy_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available_enemy

	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	j move_enemy_down


continue_find_next_available_enemy:
	addi $t0, $t0, 4
	j find_all_enemy

move_enemy_down:

	addi $s1, $s1, 2
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1


	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy

move_enemy_exit:
	jr $ra

#--------------------------------------------------------------------
# func: destory_enemy
# Destory the enemy if it is out of the screen
#--------------------------------------------------------------------
destory_enemy:
	# find all the enemies in the enemy_list
	la $t0, enemy_list
	li $t3, -1

	j find_all_enemy_destory

find_all_enemy_destory:

	# get the first element of enemy_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, destory_enemy_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_available_enemy_destory

	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location

	# if y location >= 700, destory the enemy
	addi $t7, $s1, -700
	bgez $t7, destory_enemy_destory

	addi $t0, $t0, 4
	j find_all_enemy_destory

continue_find_next_available_enemy_destory:
	addi $t0, $t0, 4
	j find_all_enemy_destory

destory_enemy_destory:
	# destory the enemy
	move $a0, $t1
	li $v0, 116
	syscall

	# set the enemy to -1
	addi $t2, $zero, -1
	sw $t2, ($t0)

	addi $t0, $t0, 4
	j find_all_enemy_destory

destory_enemy_exit:
	jr $ra

#--------------------------------------------------------------------
# func: generate_enemy_bullet
# Generate enemy's bullet, each 40 * 30 milliseconds, generate a bullet
#--------------------------------------------------------------------
generate_enemy_bullet:
	la $t0, enemy_list
	li $t3, -1

	# if total_cnt % 41 == 0, generate a bullet
	lw $t4, total_cnt
	addi $t1, $zero, 41
	div $t4, $t1
	mfhi $t2
	beq $t2, $zero, generate_enemy_bullet_create

	jr $ra

# TODO: add more contents here {
generate_enemy_bullet_create:
# Pseduo code
# enemy_bullet_list: array of enemy bullets from 900 to 999, 100 slots. Consider circular search.
# enemy_list: array of enemies from 500 to 519, 20 slots. Consider circular search.
# for each enemy in enemy_list:
# 	if enemy != -1:
#		get the location of the enemy with syscall 110
#		generate a bullet for the enemy
#		if enemy is type 1:
#			generate a bullet for the enemy
#		if enemy is type 2:
#			generate two bullets for the enemy
#		if enemy is type 3:
#			generate three bullets for the enemy
#   else: continue to the next enemy
	# get the first element of enemy_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	beq $t3, 20, generate_enemy_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy
	
	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall
	
	move $s0, $v0 # x location
	move $s1, $v1 # y location	
	
	# get the type of the enemy (last 2 bits)
	andi $t6, $a1, 3
	
	# if enemy is type 1
	beq $t6, 1, generate_bullet_instance_type1
	# if enemy is type 2
	beq $t6, 2, generate_bullet_instance_type2
	# if enemy is type 3
	beq $t6, 3, generate_bullet_instance_type3	

continue_find_next_enemy:
	addi $t0, $t0, 4
	j generate_enemy_bullet_create

generate_bullet_instance_type1:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 1

	
	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall
	
	move $s0, $v0 # x location
	move $s1, $v1 # y location
	
	# create a bullet, id starts from 900
	addi $t4, $zero, 900
	lw $t1, enemy_bullet_address
	la $t2, enemy_bullet_list
	
	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	add $t4, $t4, $t2
	
	li $v0, 106 # create a bullet
	move $a0, $t4 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	addi $a3, $zero, 1
	syscall

	# store the bullet to enemy_bullet_list by taking the mod 100 of id
	la $t2, enemy_bullet_list
	li $t5, 100             # load 100 into $t5
	div $t4, $t5            # divide $t4 by $t5
	mfhi $t7                # move the remainder into $t7
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	sw $t4, 0($t2)

	addi $t1, $t1, 4
	sw $t1, enemy_bullet_address
	j continue_find_next_enemy


generate_bullet_instance_type2:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 2 and 3
	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall
	
	move $s0, $v0 # x location
	move $s1, $v1 # y location
	
	# create a bullet, id starts from 900
	addi $t4, $zero, 900
	lw $t1, enemy_bullet_address
	la $t2, enemy_bullet_list
	
	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	add $t4, $t4, $t2
	
	li $v0, 106 # create a bullet
	move $a0, $t4 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	addi $a3, $zero, 2
	syscall

	# store the bullet to enemy_bullet_list by taking the mod 100 of id
	la $t2, enemy_bullet_list
	li $t5, 100             # load 100 into $t5
	div $t4, $t5            # divide $t4 by $t5
	mfhi $t7                # move the remainder into $t7
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	sw $t4, 0($t2)

	addi $t1, $t1, 4
	sw $t1, enemy_bullet_address
	
	# create a bullet, id starts from 900
	addi $t4, $zero, 900
	lw $t1, enemy_bullet_address
	la $t2, enemy_bullet_list
	
	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	add $t4, $t4, $t2
	
	li $v0, 106 # create a bullet
	move $a0, $t4 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	addi $a3, $zero, 3
	syscall

	# store the bullet to enemy_bullet_list by taking the mod 100 of id
	la $t2, enemy_bullet_list
	li $t5, 100             # load 100 into $t5
	div $t4, $t5            # divide $t4 by $t5
	mfhi $t7                # move the remainder into $t7
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	sw $t4, 0($t2)

	addi $t1, $t1, 4
	sw $t1, enemy_bullet_address
	j continue_find_next_enemy

generate_bullet_instance_type3:
# Pseduo code:
# create a bullet, id starts from 900
# store the id into the enemy_bullet_list and maintain the pointer
# get the location of the enemy
# store the location of the enemy to the bullet
# syscall 106 to create a bullet, with bullet_type is 4, 5 and 6

# Note: enemy type is different from bullet type. Enemy type 1: small enemy, 2: medium enemy, 3: large enemy
# small enemy: bullet_type 1, medium enemy: bullet_type 2 and 3, large enemy: bullet_type 4, 5 and 6
	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall
	
	move $s0, $v0 # x location
	move $s1, $v1 # y location
	
	# create a bullet, id starts from 900
	addi $t4, $zero, 900
	lw $t1, enemy_bullet_address
	la $t2, enemy_bullet_list
	
	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	add $t4, $t4, $t2
	
	li $v0, 106 # create a bullet
	move $a0, $t4 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	addi $a3, $zero, 4
	syscall

	# store the bullet to enemy_bullet_list by taking the mod 100 of id
	la $t2, enemy_bullet_list
	li $t5, 100             # load 100 into $t5
	div $t4, $t5            # divide $t4 by $t5
	mfhi $t7                # move the remainder into $t7
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	sw $t4, 0($t2)

	addi $t1, $t1, 4
	sw $t1, enemy_bullet_address
	
	# create a bullet, id starts from 900
	addi $t4, $zero, 900
	lw $t1, enemy_bullet_address
	la $t2, enemy_bullet_list
	
	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	add $t4, $t4, $t2
	
	li $v0, 106 # create a bullet
	move $a0, $t4 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	addi $a3, $zero, 5
	syscall

	# store the bullet to enemy_bullet_list by taking the mod 100 of id
	la $t2, enemy_bullet_list
	li $t5, 100             # load 100 into $t5
	div $t4, $t5            # divide $t4 by $t5
	mfhi $t7                # move the remainder into $t7
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	sw $t4, 0($t2)

	addi $t1, $t1, 4
	sw $t1, enemy_bullet_address
	
	# create a bullet, id starts from 900
	addi $t4, $zero, 900
	lw $t1, enemy_bullet_address
	la $t2, enemy_bullet_list
	
	# difference between t1 and t2
	sub $t2, $t1, $t2

	# t2 = t2 / 4
	srl $t2, $t2, 2

	add $t4, $t4, $t2
	
	li $v0, 106 # create a bullet
	move $a0, $t4 # the id of the bullet
	add $a1, $s0, $zero
	add $a2, $s1, $zero
	addi $a3, $zero, 6
	syscall

	# store the bullet to enemy_bullet_list by taking the mod 100 of id
	la $t2, enemy_bullet_list
	li $t5, 100             # load 100 into $t5
	div $t4, $t5            # divide $t4 by $t5
	mfhi $t7                # move the remainder into $t7
	sll $t7, $t7, 2
	add $t2, $t2, $t7
	sw $t4, 0($t2)

	addi $t1, $t1, 4
	sw $t1, enemy_bullet_address
	j continue_find_next_enemy



generate_enemy_bullet_exit:
	jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}

#--------------------------------------------------------------------
# func: move_enemy_bullet
# Move the enemy's bullet
#--------------------------------------------------------------------
move_enemy_bullet:
	# find all the bullets in the enemy_bullet_list
	la $t0, enemy_bullet_list
	li $t3, -1

	j find_all_enemy_bullet

find_all_enemy_bullet:
	# get the first element of enemy_bullet_list
	lw $t1, ($t0)

	# if t3 == 100 then exit
	beq $t3, 100, move_enemy_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy_bullet

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	andi $s2, $a1, 3 # type, here are only 3 types 0 1 2

	# if s2 == 1, move_enemy_bullet_down
	addi $t7, $zero, 1
	beq $s2, 1, move_enemy_bullet_down

	# if s2 == 2, move_enemy_bullet_right_down
	addi $t7, $zero, 2
	beq $s2, 2, move_enemy_bullet_right_down

	# if s2 == 0, move_enemy_bullet_left_down
	addi $t7, $zero, 0
	beq $s2, 0, move_enemy_bullet_left_down


continue_find_next_enemy_bullet:
	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_down: # 1
	
	addi $s1, $s1, 3
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1

	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_right_down: # 0

	addi $s0, $s0, 2
	addi $s1, $s1, 3
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1

	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_left_down: # 2
	addi $s0, $s0, -2
	addi $s1, $s1, 3
	move $a0, $t1
	move $a1, $s0
	move $a2, $s1

	li $v0, 120
	syscall

	addi $t0, $t0, 4
	j find_all_enemy_bullet

move_enemy_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: destory_enemy_bullet
# Destory the enemy's bullet if it is out of the screen
#--------------------------------------------------------------------
destory_enemy_bullet:
	# find all the bullets in the enemy_bullet_list
	la $t0, enemy_bullet_list
	li $t3, -1

	j find_all_enemy_bullet_destory

find_all_enemy_bullet_destory:

	# get the first element of enemy_bullet_list
	lw $t1, ($t0)

	# if t3 == 100 then exit
	beq $t3, 100, destory_enemy_bullet_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy_bullet_destory

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	andi $s2, $a1, 3 # type, here are only 3 types 0 1 2

	# if y location >= 700, destory the bullet
	addi $t7, $s1, -700
	bgez $t7, destory_enemy_bullet_destory

	addi $t0, $t0, 4
	j find_all_enemy_bullet_destory

continue_find_next_enemy_bullet_destory:
	addi $t0, $t0, 4
	j find_all_enemy_bullet_destory

destory_enemy_bullet_destory:
	# destory the bullet
	move $a0, $t1
	li $v0, 116
	syscall

	# set the bullet to -1
	addi $t2, $zero, -1
	sw $t2, ($t0)

	addi $t0, $t0, 4
	j find_all_enemy_bullet_destory

destory_enemy_bullet_exit:
	jr $ra

#--------------------------------------------------------------------
# func: collide_detection_enemy
# Detect whether the airplane crashes with the enemy
#--------------------------------------------------------------------

collide_detection_enemy:
	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	move $s7, $a2 # blood left

	# find all the enemies in the enemy_list
	la $t0, enemy_list
	li $t3, -1

	j find_all_enemy_collide

# TODO: add more contents here {

find_all_enemy_collide:
# Pseduo code:
# for each enemy in enemy_list:
# 	if enemy != -1:
#		get the location of the enemy with syscall 110
#		jump to collide_detection_enemy_with_airplane
#   else: continue to the next enemy

	# get the first element of enemy_list
	lw $t1, ($t0)

	# if t3 == 20 then exit
	addi $t3, $t3, 1
	beq $t3, 20, collide_detection_enemy_exit
	
	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy_collide

	# get the location of the enemy
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	j collide_detection_enemy_with_airplane

	addi $t0, $t0, 4
	j find_all_enemy_collide


collide_detection_enemy_with_airplane:
# This is the basic function for collision detection, you can use this function to detect the collision between the airplane and the enemy
# These three collide_detection functions all have one basic function, they are extremely similar except for some minor different variables
# Pseduo code:
# x_enermy, y_enermy, width, height, x_self, y_self
# if (x_self <= x_enermy + width && x_self + 102 >= x_enermy && y_self <= y_enermy + height && y_self + 126 >= y_enermy), collide, where 102 is the width of the airplane, 126 is the height of the airplane
# if collide, destory the enemy, set the enemy to -1, blood left -= enemy attribute, score += enemy attribute, update the blood left, update the score, check the next enemy
# else: check the next enemy

#s0: x_enemy , s1: y_enemy, s2: x_self, s3: y_self, s4: width, s5: height, s6: enemy attribute, s7: blood left
	move $s6, $a3 # enemy attribute
	andi $s4, $a1, 67092480 # width
	srl $s4, $s4, 14
	andi $s5, $a1, 16380 # height
	srl $s5, $s5, 2
	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall
	move $s2, $v0 # x_self
	move $s3, $v1 # y_self
	move $s7, $a2 # blood left
	

    
    add $t4, $s0, $s4           # x_enemy + width
    
    # check if x_self <= x_enemy + width
    ble $s2, $t4, check_x_self_plus_102  
    j continue_find_next_enemy_collide                   

check_x_self_plus_102:
    
    addi $t5, $s2, 102          # x_self + 102
    
    # check if x_self + 102 >= x_enemy
    bge $t5, $s0, check_y_self_plus_height 
    j continue_find_next_enemy_collide         

check_y_self_plus_height:
    
    add $t2, $s1, $s5           # y_enemy + height
    
    # check if y_self <= y_enemy + height
    ble $s3, $t2, check_y_self_plus_126  
    j continue_find_next_enemy_collide                   

check_y_self_plus_126:
    
    addi $t4, $s3, 126          # y_self + 126
    
    # check if y_self + 126 >= y_enemy
    bge $t4, $s1, if_body       
    j continue_find_next_enemy_collide                    

if_body:
    # destroy the enemy
    	move $a0, $t1
	li $v0, 116
	syscall
	li $t8, -1
	sw $t8, ($t0)
	
	# update the score and blood
	sub $a1, $s7, $s6
	sw $a1, left_blood
	lw $a0, score
	add $a0, $a0, $s6
	sw $a0, score
	li $v0, 117
	syscall 

continue_find_next_enemy_collide:
	addi $t0, $t0, 4
	j find_all_enemy_collide

collide_detection_enemy_exit:
	jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}


#--------------------------------------------------------------------
# func: collide_detection_shoot_by_enemy
# Detect whether the airplane is shoot by the enemy
#--------------------------------------------------------------------
collide_detection_shoot_by_enemy:
	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall

	move $s0, $v0 # x location
	move $s1, $v1 # y location
	move $s7, $a2 # blood left

	# find all the bullets in the enemy_bullet_list
	la $t0, enemy_bullet_list
	li $t3, -1

	j find_all_enemy_bullet_shoot

# TODO: add more contents here {
find_all_enemy_bullet_shoot:
# Pseduo code:
# for each bullet in enemy_bullet_list:
# 	if bullet != -1:
#		get the location of the bullet with syscall 110
#		jump to collide_detection_shoot_by_enemy_down
#   else: jump to continue to the next bullet

	# get the first element of enemy_bullet_list
	lw $t1, ($t0)

	# if t3 == 100 then exit
	beq $t3, 100, collide_detection_shoot_by_enemy_exit
	addi $t3, $t3, 1

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_enemy_bullet_shoot

	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x_bullet
	move $s1, $v1 # y_bullet

collide_detection_shoot_by_enemy_down:
# Basic function for collision detection, you can use this function to detect the collision between the airplane and the enemy's bullet
# Pseduo code:
# x_bullet, y_bullet, x_self, y_self
# if (x_self <= x_bullet + 5 && x_self + 102 >= x_bullet && y_self <= y_bullet + 11 && y_self + 126 >= y_bullet), collide, where 102 is the width of the airplane, 126 is the height of the airplane
# if collide, destory the bullet, set the bullet to -1, self blood left -= 1, score unchanged, check the next bullet
# else: check the next bullet
# s0: x_bullet, s1: y_bullet, s2: x_self, s3: y_self, s7: blood_left

	# get the location of the airplane
	li $v0, 110
	li $a0, 1 # id of the airplane
	syscall
	move $s2, $v0 # x_self
	move $s3, $v1 # y_self
	move $s7, $a2 # blood left
	
    
    addi $t2, $s0, 5           # x_bullet + 5
    
    # check if x_self <= x_bullet + 5
    ble $s2, $t2, condition_1   
    j continue_find_next_enemy_bullet_shoot                  

condition_1:
    
    addi $t2, $s2, 102          # x_self + 102
    
    # check if x_self + 102 >= x_bullet
    bge $t2, $s0, condition_2    
    j continue_find_next_enemy_bullet_shoot                

condition_2:
   
    addi $t2, $s1, 11           # y_bullet + 11
    
    # check if y_self <= y_bullet + 11
    ble $s3, $t2, condition_3   
    j continue_find_next_enemy_bullet_shoot                   

condition_3:
   
    addi $t2, $s3, 126          # y_self + 126
    
    # check if y_self + 126 >= y_bullet
    bge $t2, $s1, if       
    j continue_find_next_enemy_bullet_shoot                  

if:
        # destroy the bullet
    	move $a0, $t1
	li $v0, 116
	syscall
	li $t8, -1
	sw $t8, ($t0)
	
	addi $a1, $s7, -1
	sw $a1, left_blood
	lw $a0, score
	li $v0, 117
	syscall 
    
continue_find_next_enemy_bullet_shoot:
	addi $t0, $t0, 4
	j find_all_enemy_bullet_shoot

collide_detection_shoot_by_enemy_exit:
	jr $ra
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}


#--------------------------------------------------------------------
# func: collide_detection_shoot_enemy
# Detect whether the enemy is shoot by the airplane
#--------------------------------------------------------------------
collide_detection_shoot_enemy:
	# find all the bullets in the bullet_list
	la $t0, self_bullet_list
	li $t3, -1 # like counter
	j find_all_bullet

# TODO: add more contents here {
find_all_bullet:
# Pseduo code:
# for each bullet in bullet_list:
# 	if bullet != -1:
#		get the location of the bullet with syscall 110
#		jump to collide_detection_shoot_enemy_down
#   else: jump to continue to the next bullet

# get the first element of self_bullet_list
	addi $t3, $t3, 1
	la $t0, self_bullet_list
	sll $t1, $t3, 2
	add $t0, $t0, $t1
	move $s7, $t0
	lw $t1, ($t0)


	# if t3 == 20 then exit
	beq $t3, 20, collide_detection_shoot_enemy_exit

	# if t1 == -1, then continue
	beq $t1, -1, continue_find_next_bullet
	
	# get the location of the bullet
	move $a0, $t1
	li $v0, 110
	syscall

	move $s0, $v0 # x_bullet
	move $s1, $v1 # y_bullet

collide_detection_shoot_enemy_down:
	# get all the enemies in the enemy_list
	la $t0, enemy_list
	li $t5, -1 # like counter
	j find_all_enemy_in_enemy_list

find_all_enemy_in_enemy_list:
# Pseduo code:
# for each enemy in enemy_list:
# 	if enemy != -1:
#		get the location of the enemy with syscall 110
#		jump to judge_hit_enermy
#   else: continue to the next enemy
	# get the first element of enemy_list
	lw $t2, ($t0)

	# if t3 == 20 then exit
	beq $t5, 20, continue_find_next_bullet
	addi $t5, $t5, 1
	
	# if t1 == -1, then continue
	beq $t2, -1, continue_find_next_enemy_in_enemy_list

	# get the location of the enemy
	move $a0, $t2
	li $v0, 110
	syscall

	move $s2, $v0 # x_enemy
	move $s3, $v1 # y_enemy
	andi $s4, $a1, 67092480 # width
	srl $s4, $s4, 14
	andi $s5, $a1, 16380 # height
	srl $s5, $s5, 2
	


judge_hit_enermy:
# Basic function for collision detection, you can use this function to detect the collision between the enemy and the airplane's bullet.
# Pseduo code:
# x_bullet, y_bullet, width, height, x_enemy, y_enemy
# if (x_enemy <= x_bullet + 5 && x_enemy + width >= x_bullet && y_enemy <= y_bullet + 11 && y_enemy + height >= y_bullet), collide
# if collide, destory the bullet, set the bullet to -1, enemy blood left -= 1
# if enemy blood left <= 0, destory the enemy, set the enemy to -1, score += enemy attribute, update the score, check the next enemy
# else: check the next enemy

#s0: x_bullet, s1: y_bullet, s2: x_enemy, s3: y_enemy, s4: width, s5: height, s6,a2: blood left, a3: enemy attribute
    addi $t4, $s0, 5           # x_bullet + 5
    
    # check if x_enemy <= x_bullet + 5
    ble $s2, $t4, check_1  
    j continue_find_next_enemy_in_enemy_list                    

check_1:
    andi $t4, $t4, 0
   
    add $t4, $s2, $s4           # x_enemy + width
    
    # check if x_enemy + width >= x_bullet
    bge $t4, $s0, check_2      
    j continue_find_next_enemy_in_enemy_list                    

check_2:
    andi $t4, $t4, 0
   
    addi $t4, $s1, 11           # y_bullet + 11
    
    # check if y_enemy <= y_bullet + 11
    ble $s3, $t4, check_3  
    j continue_find_next_enemy_in_enemy_list                    

check_3:
    andi $t4, $t4, 0
    
    add $t4, $s3, $s5           # y_enemy + height
    
    # check if y_enemy + height >= y_bullet
    bge $t4, $s1, body      
    j continue_find_next_enemy_in_enemy_list                    

body:	
    	move $s6, $a2 # blood left
    	move $t9, $a3 # enemy attribute
    	lw $t1, ($s7)
        # destroy the bullet
    	move $a0, $t1
	li $v0, 116
	syscall
	li $t8, -1
	sw $t8, ($s7)
	
	move $a0, $t2
	addi $s6, $s6, -1
	move $a1, $s6
	li $v0, 123
	syscall
	bgtz $s6, continue_find_next_enemy_in_enemy_list
	# destroy the enemy
    	move $a0, $t2
	li $v0, 116
	syscall
	li $t8, -1
	sw $t8, ($t0)
	lw $a0, score
	add $a0, $a0, $t9
	sw $a0, score
	lw $a1, left_blood
	li $v0, 117
	syscall

continue_find_next_enemy_in_enemy_list:
	addi $t0, $t0, 4
 	j find_all_enemy_in_enemy_list

continue_find_next_bullet:
 	j find_all_bullet

collide_detection_shoot_enemy_exit:
	jr $ra

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++}



#--------------------------------------------------------------------
# func: get_time
# Get the current time
# $v0 = current time
#--------------------------------------------------------------------
get_time:	li $v0, 30
		syscall # this syscall also changes the value of $a1
		andi $v0, $a0, 0x3FFFFFFF # truncated to milliseconds from some years ago
		jr $ra

#--------------------------------------------------------------------
# func: have_a_nap(last_iteration_time, nap_time)
# Let the program sleep for a while
#--------------------------------------------------------------------
have_a_nap:
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $s0, 0($sp)
	add $s0, $a0, $a1
	jal get_time
	sub $a0, $s0, $v0
	slt $t0, $zero, $a0 
	bne $t0, $zero, han_p
	li $a0, 1 # sleep for at least 1ms
han_p:	li $v0, 32 # syscall: let mars java thread sleep $a0 milliseconds
	syscall
	lw $ra, 4($sp)
	lw $s0, 0($sp)
	addi $sp, $sp, 8
	jr $ra

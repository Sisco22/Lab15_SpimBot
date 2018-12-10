.data
# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024

TIMER                   = 0xffff001c

RIGHT_WALL_SENSOR 		  = 0xffff0054
PICK_TREASURE           = 0xffff00e0
TREASURE_MAP            = 0xffff0058
MAZE_MAP                = 0xffff0050

REQUEST_PUZZLE          = 0xffff00d0
SUBMIT_SOLUTION         = 0xffff00d4

BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000
TIMER_ACK               = 0xffff006c

REQUEST_PUZZLE_INT_MASK = 0x800
REQUEST_PUZZLE_ACK      = 0xffff00d8


# struct spim_treasure
#{
#    short x;
#    short y;
#    int points;
#};
#
#struct spim_treasure_map
#{
#    unsigned length;
#    struct spim_treasure treasures[50];
#};
.data
treasure: .word 0:404
#Insert whatever static memory you need here

.text
main:
# Insert code here
    lw $s0 0($sp)

    li $t4 TIMER_INT_MASK
    or $t4 $t4 BONK_INT_MASK
    or $t4 $t4 REQUEST_PUZZLE_INT_MASK
    or $t4 $t4 1
    mtc0 $t4 $12

    lw $t5 RIGHT_WALL_SENSOR($zero)  #oldState #should be 1
    la $t3 treasure
    sw $t3 TREASURE_MAP


    li $a0 10
    sw $a0 0xffff0010($zero)
    li      $s0, 1

loop:

    # lw $s0 RIGHT_WALL_SENSOR   #curr sensor
    lw      $t5, RIGHT_WALL_SENSOR($zero)
    li $a0 10
    sw $a0 0xffff0010($zero)
    # bne $s0 $zero UPDATE
    # beq $t5 1 TURN
    #check to see old is 1
    #new is 0

    # move $t5 $s0
#doesnt reachg hetre

    beq     $t5, 0, turn_1
    li      $s0, 1
    li $a0 10
    sw $a0 0xffff0010($zero)

    j loop
#
# UPDATE:
#   move $t5 $s0
#   j loop

turn_1:
    beq     $s0, 1, TURN
    j       loop
TURN:

  # li $a0 90
  #
  # sw $a0 0xffff0014($zero)
  # sw $zero 0xffff0018($zero)
  #
  # # lw $s0 RIGHT_WALL_SENSOR($zero)
  # # lw $t5 RIGHT_WALL_SENSOR($zero)
  #
  # move $t5 $s0
  # li $a0 10
  # sw $a0 0xffff0010($zero)
  li       $s0, 0
  li       $t1, 90
  sw       $t1, 0xffff0014                 #set the angle
  sw       $zero, 0xffff0018($zero)
  li       $a0, 10
  sw       $a0, 0xffff0010($zero)          #drive? velocity = 1?
 # j        loop                           # jump tomain

  #
  # j get_location

get_location:
    li $a0 0
    sw $a0 0xffff0010($zero)

    lw  $s1, 0xffff0020($zero)  #bot x
    lw  $s2, 0xffff0024($zero)  #bot y

    div $s1, $s1, 10
    div $s2, $s2, 10

scan_treasure_map:
    lw $t0, 0($t3)          #$t0 is the size of the array
    li $s3, 0               #i counter


scan_loop:
    bge  $s3, $t0, loop  #break out of loop when done

    mul  $t2, $s3, 8
    add  $t2, $t3, $t2

      #go inside the array
    lhu  $t4, 4($t2)                        #$t2 is the  array of treasures at i (offset by 4 because its the second part of struct)
    beq  $t4, $s1, second_check             #if x is equal to i
    j    incr


second_check:
    lhu   $t6, 6($t2)                           #load  short j
    beq   $t6, $s2, stop                         #tell the bot to stop moving


incr:
    add  $s3, 1
    j scan_loop



stop:
    li $a0 0
    sw $a0 0xffff0010($zero)



.text    #Suduko puzzle solution code
  .globl has_single_bit_set
has_single_bit_set:
	beq	$a0, 0, hsbs_ret_zero	# return 0 if value == 0
	sub	$a1, $a0, 1
	and	$a1, $a0, $a1
	bne	$a1, 0, hsbs_ret_zero	# return 0 if (value & (value - 1)) == 0
	li	$v0, 1
	jr	$ra
hsbs_ret_zero:
	li	$v0, 0
	jr	$ra


.globl get_lowest_set_bit
get_lowest_set_bit:
	li	$v0, 0			# i
	li	$t1, 1

glsb_loop:
	sll	$t2, $t1, $v0		# (1 << i)
	and	$t2, $t2, $a0		# (value & (1 << i))
	bne	$t2, $0, glsb_done
	add	$v0, $v0, 1
	blt	$v0, 16, glsb_loop	# repeat if (i < 16)

	li	$v0, 0			# return 0
glsb_done:
	jr	$ra

  .globl board_done
  board_done:
  	sub	$sp, $sp, 16
  	sw	$ra, 0($sp)		# save $ra and free up 3 $s registers for
  	sw	$s0, 4($sp)		# i
  	sw	$s1, 8($sp)		# j
  	sw	$s2, 12($sp)		# the function argument
  	move	$s2, $a0

  	li	$s0, 0			# i
  bd_loop1:
  	li	$s1, 0			# j
  bd_loop2:
  	mul	$t0, $s0, 16		# i*16
  	add	$t0, $t0, $s1		# (i*16)+j
  	sll	$t0, $t0, 1		# ((i*16)+j)*2
  	add	$a0, $s2, $t0
  	lhu	$a0, 0($a0)
  	jal	has_single_bit_set
  	beq	$v0, 0, bd_done		# can return false as soon as we see one false case

  	add	$s1, $s1, 1		# j++
  	blt	$s1, 16, bd_loop2

  	add	$s0, $s0, 1		# i++
  	blt	$s0, 16, bd_loop1

  bd_done:
  	lw	$ra, 0($sp)		# restore registers and return
  	lw	$s0, 4($sp)
  	lw	$s1, 8($sp)
  	lw	$s2, 12($sp)
  	add	$sp, $sp, 16
  	jr	$ra

  .globl print_board
  print_board:
  	sub	$sp, $sp, 20
  	sw	$ra, 0($sp)		# save $ra and free up 4 $s registers for
  	sw	$s0, 4($sp)		# i
  	sw	$s1, 8($sp)		# j
  	sw	$s2, 12($sp)		# the function argument
  	sw	$s3, 16($sp)		# the computed pointer (which is used for 2 calls)
  	move	$s2, $a0

  	li	$s0, 0			# i
  pb_loop1:
  	li	$s1, 0			# j
  pb_loop2:
  	mul	$t0, $s0, 16		# i*16
  	add	$t0, $t0, $s1		# (i*16)+j
  	sll	$t0, $t0, 1		# ((i*16)+j)*2
  	add	$s3, $s2, $t0
  	lhu	$a0, 0($s3)
  	jal	has_single_bit_set
  	beq	$v0, 0, pb_star		# if it has more than one bit set, jump
  	lhu	$a0, 0($s3)
  	jal	get_lowest_set_bit	#
  	add	$v0, $v0, 1		# $v0 = num
  	la	$t0, symbollist
  	add	$a0, $v0, $t0		# &symbollist[num]
  	lb	$a0, 0($a0)		#  symbollist[num]
  	li	$v0, 11
  	syscall
  	j	pb_cont

  pb_star:
  	li	$v0, 11			# print a "*"
  	li	$a0, '*'
  	syscall

  pb_cont:
  	add	$s1, $s1, 1		# j++
  	blt	$s1, 16, pb_loop2

  	li	$v0, 11			# at the end of a line, print a newline char.
  	li	$a0, '\n'
  	syscall

  	add	$s0, $s0, 1		# i++
  	blt	$s0, 16, pb_loop1

  	lw	$ra, 0($sp)		# restore registers and return
  	lw	$s0, 4($sp)
  	lw	$s1, 8($sp)
  	lw	$s2, 12($sp)
  	lw	$s3, 16($sp)
  	add	$sp, $sp, 20
  	jr	$ra

# Kernel Text
.kdata
chunkIH:    .space 28
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
        move      $k1, $at        # Save $at
.set at
        la        $k0, chunkIH
        sw        $a0, 0($k0)        # Get some free registers
        sw        $v0, 4($k0)        # by storing them to a global variable
        sw        $t0, 8($k0)
        sw        $t1, 12($k0)
        sw        $t2, 16($k0)
        sw        $t3, 20($k0)

        mfc0      $k0, $13             # Get Cause register
        srl       $a0, $k0, 2
        and       $a0, $a0, 0xf        # ExcCode field
        bne       $a0, 0, non_intrpt



interrupt_dispatch:            # Interrupt:
        mfc0       $k0, $13        # Get Cause register, again
        beq        $k0, 0, done        # handled all outstanding interrupts

        and        $a0, $k0, BONK_INT_MASK    # is there a bonk interrupt?
        bne        $a0, 0, bonk_interrupt

        and        $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
        bne        $a0, 0, timer_interrupt

        and 	$a0, $k0, REQUEST_PUZZLE_INT_MASK
        bne 	$a0, 0, request_puzzle_interrupt

        li        $v0, PRINT_STRING    # Unhandled interrupt types
        la        $a0, unhandled_str
        syscall
        j    done

bonk_interrupt:
        sw $a1 0xffff0060($zero)
        li $a1 180
        sw $a1 ANGLE($zero)
        sw $zero ANGLE_CONTROL($zero)

        li $a0 10
        sw $a0 0xffff0010($zero)


          j       interrupt_dispatch

request_puzzle_interrupt:
	sw	$a1, REQUEST_PUZZLE_fACK 	#acknowledge interrupt
  li $a0 0
  sw  $a0 VELOCITY



	j	interrupt_dispatch	 # see if other interrupts are waiting

timer_interrupt:
        sw       $v0, TIMER_ACK        # acknowledge interrupt
        j        interrupt_dispatch    # see if other interrupts are waiting

non_intrpt:                # was some non-interrupt
        li        $v0, PRINT_STRING
        la        $a0, non_intrpt_str
        syscall                # print out an error message
        # fall through to done

done:
        la      $k0, chunkIH
        lw      $a0, 0($k0)        # Restore saved registers
        lw      $v0, 4($k0)
	lw      $t0, 8($k0)
        lw      $t1, 12($k0)
        lw      $t2, 16($k0)
        lw      $t3, 20($k0)
.set noat
        move    $at, $k1        # Restore $at
.set at
        eret

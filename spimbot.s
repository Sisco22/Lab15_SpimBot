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
puzzle: .space 512
solution:.space 4
has_puzzle: .word 1
puzzle_ready: .space 4

symbollist: .ascii  "0123456789ABCDEFG"
#Insert whatever static memory you need here

.text
main:
# Insert code here
    sub     $sp, $sp, 12
    sw      $s0 0($sp)                      # wall
    sw      $s4, 4($sp)                     #counter for keys
    sw      $t1, 8($sp)                     #Puzzle



    li      $t4 TIMER_INT_MASK
    or      $t4 $t4 BONK_INT_MASK
    or      $t4 $t4 REQUEST_PUZZLE_INT_MASK
    or      $t4 $t4 1
    mtc0    $t4 $12



    la      $t1, puzzle
    sw      $t1, REQUEST_PUZZLE($zero)

    lw      $t5 RIGHT_WALL_SENSOR($zero)  #oldState #should be 1
    la      $t3 treasure
    sw      $t3 TREASURE_MAP
    li      $t0, 1
    # sw      $zero, 0($t0)


    # li      $a0 10
    # sw      $a0 0xffff0010($zero)
    # li      $s0, 1            # wall boolean
    # li      $s4, 0            #treasure counter

    la      $t0, has_puzzle                 #i dont have a puzzle yet
    sw      $zero, 0($t0)                   #no interupt

    puzz_loop:
        bgt     $s4, 1, loop                 #not yet dne
        la      $t0, has_puzzle                 # do we have a puzzle
        sw      $zero, 0($t0)                   # we dont
        la      $t1, puzzle
        sw      $t1, REQUEST_PUZZLE($zero)     #request
        add     $s4, 1

    wait:
        la      $t0, has_puzzle
        lw      $t0, 0($t0)
        bne     $t0, 0, puzz_loop
        j       wait

loop:

    lw      $t5, RIGHT_WALL_SENSOR($zero)
    li      $a0 10
    sw      $a0 0xffff0010($zero)
    beq     $t5, 0, turn_1
    li      $s0, 1
    li      $a0 10
    sw      $a0 0xffff0010($zero)
    j       loop

turn_1:
    beq     $s0, 1, TURN
    j       loop

TURN:
  li       $s0, 0
  li       $t1, 90
  sw       $t1, 0xffff0014                 #set the angle
  sw       $zero, 0xffff0018($zero)
  li       $a0, 10
  sw       $a0, 0xffff0010($zero)          #drive? velocity = 1?


get_location:


    lw  $s1, 0xffff0020($zero)  #bot x
    lw  $s2, 0xffff0024($zero)  #bot y
    div $a2, $s1, 10
    div $a3, $s2, 10

scan_treasure_map:
    lw $t0, 0($t3)          #$t0 is the size of the array
    li $s3, 0               #i counter


scan_loop:
    jal binarySearch
    beq $v0 1 pick_up

    j loop

pick_up:
    sw      $a0, PICK_TREASURE($zero)
    li      $a0, 0
    sw      $a0, 0xffff0010($zero)
    j       loop

binarySearch:                                         #implements a binary search to find treasure
    sub	$sp, $sp, 36
    sw	$ra, 0($sp)		#
    sw	$s0, 4($sp)		#
    sw	$s1, 8($sp)		#
    sw	$s2, 12($sp)		#
    sw	$s3, 16($sp)		#
    sw	$s4, 20($sp)		#
    sw	$s5, 24($sp)		#
    sw	$s6, 28($sp)		#

    sw $s7, 32($sp)

    sub $t7 $t0 1
    mul $t7 $t7 8
    add $t7 $t3 $t7
    lhu $s7 4($t7)      #gets largest possible x value in array

    move $s3 $a2        #x to find the array
    move $s4 $a3        #y to find in the array

    #lhu $s7 4($t7)      #gets largest possible x value in array
    la $t3 treasure
    li $s7 50            #left
    li $s2 0           #used to help with iteration
    li $s1 0            #right
    li $s0 50            #min Y

recursive_step:                         #searches for X conditions to be met
    blt  $s7, $s1, binaryFail  # i$s1 >=  then


    sub $s0 $s7 $s1
    div $t7 $s0 2
    add $t7 $t7 $s1

    mul $s5 $t7 8
    add $t6 $t3 $s5
    lhu $s5 4($t6)            #S5 is the current treasure_map index x

    beq $s3 $s5 recursive_Y #ends sends recursion to find y state

    bgt $s5 $s3 recursive_right #checks right side

    blt $s5 $s3 recursive_left  #checks left side

    li $v0 0
    j recursive_done

recursive_right:
    add $s7 $t7 -1
    j recursive_step

recursive_left:
    add $s1 $t7 1
    j recursive_step

recursive_Y:                           #iterate through Y
    lhu $s6 6($t6)
    li $v0 1
    beq $s4 $s6 recursive_done #ends sends recursion to find y state


    bgt $s6 $s4 setupRightLoop #checks right side


    blt $s6 $s4 setupLeftLoop  #checks left side

    li $v0 0
    j recursive_done


setupLeftLoop:
    add $s2 $t7 -1
    j loopLeft


loopLeft:
    mul $s5 $s2 8
    add $t7 $t3 $s5
    lhu $s5 4($t7)

    bne $s5 $s3 binaryFail

    lhu $s5 6($t7)

    li $v0 1
    beq $s5 $s4 recursive_done

    add $s2 $s2 -1
    j loopLeft


setupRightLoop:
    add $s2 $t7 1
    j loopRight

loopRight:
    mul $s5 $s2 8
    add $t7 $t3 $s5
    lhu $s5 4($t7)

    bne $s5 $s3 binaryFail

    lhu $s5 6($t7)

    li $v0 1
    beq $s5 $s4 recursive_done

    add $s2 $t7 1
    j loopRight


binaryFail:
     li $v0 0
     j recursive_done

recursive_done:
    lw	$ra, 0($sp)
    lw	$s0, 4($sp)		#
    lw	$s1, 8($sp)		#
    lw	$s2, 12($sp)		#
    lw	$s3, 16($sp)		#
    lw	$s4, 20($sp)		#
    lw	$s5, 24($sp)		#
    lw	$s6, 28($sp)		#
    lw $s7, 32($sp)
    add $sp $sp 36
    jr $ra



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
        sw          $a1, REQUEST_PUZZLE_ACK($zero)      # acknowledge interrupt
        la          $a0, puzzle                         # tree                            # input
        jal         rule1
        bne         $v0, 0, again

    end:
        # la          $t0, solution   #changed from solution
        la          $t8, puzzle
        # sw          $t8, 0($t0)
        # move        $a0, $t8
        # j           print_board

        sw          $t8, SUBMIT_SOLUTION($zero)
        la          $t0, has_puzzle
        li          $t1, 1
        sw          $t1, 0($t0)
    	#Fill in your code here
    	j	        interrupt_dispatch

again:
    # move $v0, $a0
        la          $a0, puzzle
        jal         rule1
        beq         $v0, 0, end
        j           again

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
board_address:
        mul	$v0, $a1, 16		# i*16
        add	$v0, $v0, $a2		# (i*16)+j
        sll	$v0, $v0, 1		# ((i*9)+j)*2
        add	$v0, $a0, $v0
        jr	$ra

        # .globl rule1
rule1:
            sub	$sp, $sp, 32
            sw	$ra, 0($sp)		# save $ra and free up 7 $s registers for
            sw	$s0, 4($sp)		# i
            sw	$s1, 8($sp)		# j
            sw	$s2, 12($sp)		# board
            sw	$s3, 16($sp)		# value
            sw	$s4, 20($sp)		# k
            sw	$s5, 24($sp)		# changed
            sw	$s6, 28($sp)		# temp
            move	$s2, $a0		# store the board base address
            li	$s5, 0			# changed = false

            li	$s0, 0			# i = 0
r1_loop1:
            li	$s1, 0			# j = 0
r1_loop2:
            move	$a0, $s2		# board
            move 	$a1, $s0		# i
            move	$a2, $s1		# j
            jal	board_address
            lhu	$s3, 0($v0)		# value = board[i][j]
            move	$a0, $s3
            jal	has_single_bit_set
            beq	$v0, 0, r1_loop2_bot	# if not a singleton, we can go onto the next iteration

            li	$s4, 0			# k = 0
r1_loop3:
            beq	$s4, $s1, r1_skip_row	# skip if (k == j)
            move	$a0, $s2		# board
            move 	$a1, $s0		# i
            move	$a2, $s4		# k
            jal	board_address
            lhu	$t0, 0($v0)		# board[i][k]
            and	$t1, $t0, $s3
            beq	$t1, 0, r1_skip_row
            not	$t1, $s3
            and	$t1, $t0, $t1
            sh	$t1, 0($v0)		# board[i][k] = board[i][k] & ~value
            li	$s5, 1			# changed = true

r1_skip_row:
            beq	$s4, $s0, r1_skip_col	# skip if (k == i)
            move	$a0, $s2		# board
            move 	$a1, $s4		# k
            move	$a2, $s1		# j
            jal	board_address
            lhu	$t0, 0($v0)		# board[k][j]
            and	$t1, $t0, $s3
            beq	$t1, 0, r1_skip_col
            not	$t1, $s3
            and	$t1, $t0, $t1
            sh	$t1, 0($v0)		# board[k][j] = board[k][j] & ~value
            li	$s5, 1			# changed = true

r1_skip_col:
            add	$s4, $s4, 1		# k ++
            blt	$s4, 16, r1_loop3

                ## doubly nested loop
            move	$a0, $s0		# i
            jal	get_square_begin
            move	$s6, $v0		# ii
            move	$a0, $s1		# j
            jal	get_square_begin	# jj

            move 	$t0, $s6		# k = ii
            add	$t1, $t0, 4		# ii + GRIDSIZE
            add 	$s6, $v0, 4		# jj + GRIDSIZE

r1_loop4_outer:
        sub	$t2, $s6, 4		# l = jj  (= jj + GRIDSIZE - GRIDSIZE)

r1_loop4_inner:
            bne	$t0, $s0, r1_loop4_1
            beq	$t2, $s1, r1_loop4_bot

r1_loop4_1:
            mul	$v0, $t0, 16		# k*16
            add	$v0, $v0, $t2		# (k*16)+l
            sll	$v0, $v0, 1		# ((k*16)+l)*2
            add	$v0, $s2, $v0		# &board[k][l]
            lhu	$v1, 0($v0)		# board[k][l]
            and	$t3, $v1, $s3		# board[k][l] & value
            beq	$t3, 0, r1_loop4_bot

            not	$t3, $s3
            and	$v1, $v1, $t3
            sh	$v1, 0($v0)		# board[k][l] = board[k][l] & ~value
            li	$s5, 1			# changed = true

r1_loop4_bot:
            add	$t2, $t2, 1		# l++
            blt	$t2, $s6, r1_loop4_inner

            add	$t0, $t0, 1		# k++
            blt	$t0, $t1, r1_loop4_outer


r1_loop2_bot:
            add	$s1, $s1, 1		# j ++
            blt	$s1, 16, r1_loop2

            add	$s0, $s0, 1		# i ++
            blt	$s0, 16, r1_loop1

            move	$v0, $s5		# return changed
            lw	$ra, 0($sp)		# restore registers and return
            lw	$s0, 4($sp)
            lw	$s1, 8($sp)
            lw	$s2, 12($sp)
            lw	$s3, 16($sp)
            lw	$s4, 20($sp)
            lw	$s5, 24($sp)
            lw	$s6, 28($sp)
            add	$sp, $sp, 32
            jr	$ra

get_square_begin:
            div	$v0, $a0, 4
            mul	$v0, $v0, 4
            jr $ra
                #.text    #Suduko puzzle solution code
                  #.globl has_single_bit_set
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


                #.globl get_lowest_set_bit
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

                  #.globl board_done
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

    #.globl print_board
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

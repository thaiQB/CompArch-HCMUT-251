.data
buffer:			.space 256	# 256 bytes for reading buffer
signal_input:		.space 40 	# 40 bytes for 10 float values
signal_desired:		.space 40	# //

inpFile:		.asciiz "input.txt"
inpFile1:		.asciiz "desired.txt"
outFile:		.asciiz "output.txt"
error_msg:		.asciiz "Error opening file." 



.text
# 1. INPUT FILE HANDLING
## 1.1. Open The Signal File For Reading, Then Save It In `buffer`
la $a0, inpFile
jal file_read
li $a0, 0	# reset $a0
j sect_1_2

file_read:
# Procedure `file_read`: read a file stored in $a0 and store it inside `buffer`
# used reg:	$a0: contains the label holding input file name
# consumed reg: $a0: used in `read_buffer` and `close_file`
#		$a1: read mode
#		$a2: need to be set to 0
#		$v0: return value of the file reading syscall
#		$s0: store the file descriptor of reading file
	# Push $a0, $a1, $a2, $v0, $s0 to the stack
	addi $sp, $sp, -4
	sw $a0, 0($sp)
	addi $sp, $sp, -4
	sw $a1, 0($sp)
	addi $sp, $sp, -4
	sw $a2, 0($sp)
	addi $sp, $sp, -4
	sw $v0, 0($sp)
	addi $sp, $sp, -4
	sw $s0, 0($sp)
	# Open file
	li $v0, 13
	li $a1, 0	# read mode
	li $a2, 0
	syscall
	move $s0, $v0	# $s0 = $v0
	# Check if file opened successfully
	blt $s0, $zero, file_error
	# Store return addr in stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Save file to buffer
	jal read_buffer
	# Close file
	jal close_file
	# Pop the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	lw $s0, 0($sp)
	addi $sp, $sp, 4
	lw $v0, 0($sp)
	addi $sp, $sp, 4
	lw $a2, 0($sp)
	addi $sp, $sp, 4
	lw $a1, 0($sp)
	addi $sp, $sp, 4
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	# End procedure
	jr $ra

file_error:
# Handle file open error
li $v0, 4
la $a0, error_msg
syscall
# Release stack
addi $sp, $sp, 20
j exit


read_buffer:
	# Read Data From File Into `buffer`
	li $v0, 14           
	move $a0, $s0	# $a0 = $s0         
	la $a1, buffer
	li $a2, 256
	syscall

	li $a1, 0	# reset $a1
	li $a2, 0	# reset $a2
	jr $ra
	
close_file:
	# Close Input File After Reading
	li $v0, 16
	move $a0, $s0
	syscall

	li $v0, 0	# reset $v0
	li $s0, 0	# reset $s0
	li $a0, 0	# reset $a0
	jr $ra
##--------


## 1.2. Save Char From `buffer` As Float Values In `input_signal`
sect_1_2:
la $t0, buffer
la $t1, signal_input
jal buffer_handling
li $t0, 0	# reset $t0
li $t1, 0	# reset $t1
j sect_1_3

buffer_handling:
# Procedure `buffer_handling`: Convert the characters in $t0 (`buffer`) to respective FP values in $t1 (`signal_input`)
# used reg:	$t0: hold addr of `buffer`
#		$t1: hold addr of `input_signal`
# consumed reg: $t0: hold int 10 to loaded to $f1
#		$t2: extract char from `buffer`
#		$t3: a "mark" register for negativity checking
#		$f0: hold char from `buffer` to converted to float
#		$f1: hold float 10
#		$f2: hold float to saved to `input_signal`
	# Push $t2, $t3, $f0, $f1, $f2 into the stack
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	addi $sp, $sp, -4
	swc1 $f0, 0($sp)
	addi $sp, $sp, -4
	swc1 $f1, 0($sp)
	addi $sp, $sp, -4
	swc1 $f2, 0($sp)
	# Push $t0 into the stack
	addi $sp, $sp, -4
	sw $t0, 0($sp)
	# Assign an FPU register to 10.0 for later calculations
	li $t0, 10
	mtc1 $t0, $f1
	cvt.s.w $f1, $f1 # $f1 = 10
	# Pop $t0 out of the stack
	lw $t0, 0($sp)
	addi $sp, $sp, 4

loop_1_2:
	lb $t2, 0($t0)			# load char from `buffer`, $t2 now holding ASCII code
	beq $t2, 0, meet_end		# if meets `\0` (end of file), endloop
	beq $t2, 32, meet_space		# if meets ` ` (space), save float
	beq $t2, 45, meet_hyphen	# if meets `-`, set float to negative 1
	beq $t2, 46, loop_1_2_incre_iterator
					# if meets `.`, continue

	# Else: ASCII code of a number (0-9)	
	addi $t2, $t2, -48		# convert ASCII code to number
					# 48 is ASCII code of 0
	mtc1 $t2, $f0
	cvt.s.w $f0, $f0
	mul.s $f2, $f2, $f1
	bltz $t3, handle_hyphen
	add.s $f2, $f2, $f0

loop_1_2_incre_iterator:
	addi $t0, $t0, 1	# move to the next char of buffer
	j loop_1_2


meet_hyphen:
	# Set $t3 to -1
	li $t3, -1
	j loop_1_2_incre_iterator

handle_hyphen:
	sub.s $f2, $f2, $f0
	j loop_1_2_incre_iterator

meet_space:
	# divide $f2 by 10 to set 1 decimal place
	div.s $f2, $f2, $f1
	# save float to signal_input
	swc1 $f2, 0($t1)
	
	li $t3, 0		# reset $t3
	mtc1 $zero, $f2		# reset $f2
	addi $t1, $t1, 4	# move to next word of signal_input
	j loop_1_2_incre_iterator
	
meet_end:
	# save last float
	div.s $f2, $f2, $f1	# divide $f2 by 10 to set 1 decimal place
	# save float to signal_input
	swc1 $f2, 0($t1)
	
	li $t3, 0		# reset $t3
	mtc1 $zero, $f1		# reset $f1
	mtc1 $zero, $f2		# reset $f2
	
	# Pop the stack (from `buffer_handling`)
	lwc1 $f2, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f1, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f0, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t2, 0($sp)
	addi $sp, $sp, 4
	# Return to the caller (of `buffer_handling`)
	jr $ra
##--------

### 1.2.1. Testing retriving float values from `signal_input`
#la $t0, signal_input
#li $t1, 0
#loop_1_2_1:
	#bge $t1, 10, outloop_1_2_1
	# load value to $f12 to print to console
	#lwc1 $f12, 0($t0)
    	#li $v0, 2
    	#syscall
    	# print blank space
    	#addi $a0, $zero, ' '
    	#li $v0, 11
    	#syscall
    	# increment_iterator
    	#addi $t0, $t0, 4
    	#addi $t1, $t1, 1
    	#j loop_1_2_1

#outloop_1_2_1:
##--------


## 1.3. Do the same for destired signal (desired.txt - inpFile1)
sect_1_3:
la $a0, inpFile1
jal file_read
li $a0, 0	# reset $a0

la $t0, buffer
la $t1, signal_desired
jal buffer_handling
li $t0, 0	# reset $t0
li $t1, 0	# reset $t1
##--------


### 1.3.1. Testing retriving float values from `signal_desired`
la $t0, signal_desired
li $t1, 0
loop_1_2_1:
	bge $t1, 10, outloop_1_2_1
	# load value to $f12 to print to console
	lwc1 $f12, 0($t0)
    	li $v0, 2
    	syscall
    	# print blank space
    	addi $a0, $zero, ' '
    	li $v0, 11
    	syscall
    	# increment_iterator
    	addi $t0, $t0, 4
    	addi $t1, $t1, 1
    	j loop_1_2_1

outloop_1_2_1:
##--------


j sect_2
#========



# 2. CALC AUTO-CORRELATION h(0), h(1), h(2) OF INPUT SIGNAL x(n)
sect_2:
# Assign an FPU register to 10.0 for later calculations
li $t0, 10
mtc1 $t0, $f1
cvt.s.w $f1, $f1 # $f1 = 10
## 2.1. Calc h(0)
la $t0, signal_input
li $t1, 0

loop_2_1:
	# h(0) = (x(1)^2 + x(2)^2 + ... + x(10)^2) / 10
	# result is kept in $f2
	beq $t1, 10, endloop_2_1
	lwc1 $f0, 0($t0)
	mul.s $f0, $f0, $f0
	add.s $f2, $f2, $f0
	# increase iterator
	addi $t0, $t0, 4	# move to next float
	addi $t1, $t1, 1
	j loop_2_1

endloop_2_1:
	# divide $f2 by 10
	div.s $f2, $f2, $f1	# $f1 value holds from line 97
##--------


## 2.2. Calc h(1)
la $t0, signal_input
li $t1, 0

loop_2_2:
	# h(1) = (x(1) * x(2) + x(2) * x(3) + ... + x(8) * x(9)) / 10
	# we are using biased estimator for this file
	# result is kept in $f3
	beq $t1, 9, endloop_2_2
	lwc1 $f0, 0($t0)
	addi $t2, $t0, 4	# access x(i + 1)
	lwc1 $f4, 0($t2)
	mul.s $f0, $f0, $f4
	add.s $f3, $f3, $f0
	# increse iterator
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	j loop_2_2

endloop_2_2:
	# divide $f3 by 10
	div.s $f3, $f3, $f1
##--------


## 2.3. Calc h(2)
la $t0, signal_input
li $t1, 0
mtc1 $zero, $f4		# reset $f4

loop_2_3:
	# h(2) = (x(1) * x(3) + x(2) * x(4) + ... + x(8) * x(10)) / 10
	# result is kept in $f4
	beq $t1, 8, endloop_2_3
	lwc1 $f0, 0($t0)
	addi $t2, $t0, 8	# access x(i + 2)
	lwc1 $f5, 0($t2)
	mul.s $f0, $f0, $f5
	add.s $f4, $f4, $f0
	# increase iterator
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	j loop_2_3
	
endloop_2_3:
	# divide $f4 by 10
	div.s $f4, $f4, $f1
##--------

li $t0, 0		# reset $t0
li $t1, 0		# reset $t1
li $t2, 0		# reset $t2
mtc1 $zero, $f0		# reset $f0
mtc1 $zero, $f1		# reset $f1
mtc1 $zero, $f5		# reset $f5
#========



# 3. CALCULATE CROSS-CORRELATION BETWEEN INPUT SIGNAL x(n) and DESIRED SIGNAL d(n)

j exit




exit:
# Exit program
li $v0, 10
syscall

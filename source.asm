.data
buffer:			.space 256	# 256 bytes for reading buffer
signal_input:		.space 40 	# 40 bytes for 10 float values
signal_desired:		.space 40	# //
signal_output:		.space 40	# //

inpFile:		.asciiz "input.txt"
inpFile1:		.asciiz "desired.txt"
outFile:		.asciiz "output.txt"
error_msg:		.asciiz "Error opening file."
error_msg1:		.asciiz "Error: size not match"



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

li $t0, 0		# reset $t0
li $t1, 0		# reset $t1
add $t5, $t5, $t4	# store num of ele of input signal to $t5
j sect_1_3

buffer_handling:
# Procedure `buffer_handling`: Convert the characters in $t0 (`buffer`) to respective FP values in $t1 (`signal_input`)
# used reg:		$t0: hold addr of `buffer`
#			$t1: hold addr of `input_signal`
# consumed reg: 	$t0: hold int 10 to loaded to $f1
#			$t2: extract char from `buffer`
#			$t3: a "mark" register for negativity checking
#			$t4: hold num of ele in the buffer
#			$f0: hold char from `buffer` to converted to float
#			$f1: hold float 10
#			$f2: hold float to saved to `input_signal`
# returned reg:		$t4: num of converted float
	# Push $t2, $t3, $t4, $f0, $f1, $f2 into the stack
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $sp, $sp, -4
	sw $t3, 0($sp)
	addi $sp, $sp, -4
	sw $t4, 0($sp)
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
	# reset $t4
	li $t4, 0

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
	# $f2 = $f2 * 10 - $f0 to maintain negativity
	sub.s $f2, $f2, $f0
	j loop_1_2_incre_iterator

meet_space:
	# divide $f2 by 10 to set 1 decimal place
	div.s $f2, $f2, $f1
	# save float to signal_input
	swc1 $f2, 0($t1)
	# $t4++
	addi $t4, $t4, 1
	
	li $t3, 0		# reset $t3
	mtc1 $zero, $f2		# reset $f2
	addi $t1, $t1, 4	# move to next word of signal_input
	j loop_1_2_incre_iterator
	
meet_end:
	# save last float
	div.s $f2, $f2, $f1	# divide $f2 by 10 to set 1 decimal place
	# save float to signal_input
	swc1 $f2, 0($t1)
	# $t4++
	addi $t4, $t4, 1
	
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

li $t0, 0			# reset $t0
li $t1, 0			# reset $t1
bne $t4, $t5, err_size		# compare num of ele between `input.txt` and `desire.txt`
j sect_2

err_size:
# Handle size error
li $v0, 4
la $a0, error_msg1
syscall
# Terminate program
j exit
##--------


### 1.3.1. Testing retriving float values from `signal_desired`
#la $t0, signal_desired
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
#========



# 2. CALC AUTO-CORRELATION h(0), h(1), h(2) OF INPUT SIGNAL x(n)
sect_2:
# Assign an FPU register to 10.0 for later calculations
li $t0, 10
mtc1 $t0, $f1
cvt.s.w $f1, $f1 # $f1 = 10
## 2.1. Calc r(0)
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
	#div.s $f2, $f2, $f1
##--------


## 2.2. Calc r(1)
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
	#div.s $f3, $f3, $f1
##--------


## 2.3. Calc r(2)
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
	#div.s $f4, $f4, $f1

li $t0, 0		# reset $t0
li $t1, 0		# reset $t1
li $t2, 0		# reset $t2
mtc1 $zero, $f0		# reset $f0
mtc1 $zero, $f1		# reset $f1
mtc1 $zero, $f5		# reset $f5
##--------
#========



# 3. CALCULATE CROSS-CORRELATION BETWEEN INPUT SIGNAL x(n) and DESIRED SIGNAL d(n)
sect_3:
## 3.1. Calc g(0)
la $t0, signal_input
la $t1, signal_desired
li $t2, 0			# h (the "lag" of the signal)
jal cross_corr
mov.s $f5, $f8		# store result in $f5

mtc1 $zero, $f8		# reset $f8
##--------


## 3.2. Calc g(1)
la $t0, signal_input
la $t1, signal_desired
li $t2, 1
jal cross_corr
mov.s $f6, $f8		# store result in $f6

mtc1 $zero, $f8		# reset $f8
##--------


## 3.3. Calc g(2)
la $t0, signal_input
la $t1, signal_desired
li $t2, 2
jal cross_corr
mov.s $f7, $f8		# store result in $f7

mtc1 $zero, $f8		# reset $f8
li $t0, 0		# reset $t0
li $t1, 0		# reset $t1
li $t2, 0		# reset $t2
j sect_4

cross_corr:
# Procedure `cross_corr`: Calculate cross-correlation between the input signal and the desired signal
# used reg:		$t0: hold addr of input signal
#			$t1: hold addr of desired signal
#			$t2: the "lag"
# consumed reg:		$f0: store values loaded from $t0
#			$f9: store the result of the multiplication before added to $f8
# returned reg:		$f8: store the result value
	
	# push $f0, $f9 into the stack
	addi $sp, $sp, -4
	swc1 $f0, 0($sp)
	addi $sp, $sp, -4
	swc1 $f9, 0($sp)
	# accessing signal_desired[i + h]
	sll $t2, $t2, 2		# $t2 *= 4
	add $t1, $t1, $t2	# d(i + h)
	srl $t2, $t2, 2		# $t2 /= 4

loop_cross:
	beq $t2, 10, endloop_cross
	lwc1 $f0, 0($t0)
	lwc1 $f9, 0($t1)
	mul.s $f9, $f0, $f9
	add.s $f8, $f8, $f9
	# increment iterator
	addi $t0, $t0, 4
	addi $t1, $t1, 4
	addi $t2, $t2, 1
	j loop_cross

endloop_cross:
	# pop the stack
	lwc1 $f9, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f0, 0($sp)
	addi $sp, $sp, 4
	# end procedure
	jr $ra
##--------
#========



# 4. CALCULATE THE OPTIMIZED FILTER COEFFICIENTS
sect_4:
# A = r(2)^2 - r(1)^2
# B = r(0) * r(1) − r(1) * r(2)
# C = r(0)^2 - r(2)^2
# p = g(1) * r(0) − r(1) * g(0)
# q = g(2) * r(0) − r(2) * g(0)
# D = AC − B^2
# h1 = (p * C − q * B) / D
# h2 = (q * A − p * B) / D
# h0 = (g0 − r1 * h1 − r2 * h2) / r0

optimize_coef:
# Procedure `optimize_coef`: Calculate filter coefficients (not sure whether it is optimized, I just follow my teammate's Python code)
# used reg:		$f2: hold r(0)
#			$f3: hold r(1)
#			$f4: hold r(2)
#			$f5: hold g(0)
#			$f6: hold g(1)
#			$f7: hold g(2)
# consumed reg:		$f0: hold tmp val
#			$f1: hold tmp val
#			$f11: hold A
#			$f12: hold B
#			$f13: hold C
#			$f14: hold p
#			$f15: hold q
#			$f16: hold D
# returned reg:		$f8: hold h(0)
#			$f9: hold h(1)
#			$f10: hold h(2)
	# push $f0, $f1, $f11, $f12, $f13, $f14, $f15, $f16 into stack
	addi $sp, $sp, -4
	swc1 $f0, 0($sp)
	addi $sp, $sp, -4
	swc1 $f1, 0($sp)
	addi $sp, $sp, -4
	swc1 $f11, 0($sp)
	addi $sp, $sp, -4
	swc1 $f12, 0($sp)
	addi $sp, $sp, -4
	swc1 $f13, 0($sp)
	addi $sp, $sp, -4
	swc1 $f14, 0($sp)
	addi $sp, $sp, -4
	swc1 $f15, 0($sp)
	addi $sp, $sp, -4
	swc1 $f16, 0($sp)
	# A = r(0)^2 - r(1)^2
	mul.s $f0, $f2, $f2
	mul.s $f1, $f3, $f3
	sub.s $f11, $f0, $f1
	# B = r(0) * r(1) − r(1) * r(2)
	mul.s $f0, $f2, $f3
	mul.s $f1, $f3, $f4
	sub.s $f12, $f0, $f1
	# C = r(0)^2 - r(2)^2
	mul.s $f0, $f2, $f2
	mul.s $f1, $f4, $f4
	sub.s $f13, $f0, $f1
	# p = g(1) * r(0) − r(1) * g(0)
	mul.s $f0, $f6, $f2
	mul.s $f1, $f3, $f5
	sub.s $f14, $f0, $f1
	# q = g(2) * r(0) − r(2) * g(0)
	mul.s $f0, $f7, $f2
	mul.s $f1, $f4, $f5
	sub.s $f15, $f0, $f1
	# D = AC − B^2
	mul.s $f0, $f11, $f13
	mul.s $f1, $f12, $f12
	sub.s $f16, $f0, $f1
	# h1 = (p * C − q * B) / D
	mul.s $f0, $f14, $f13
	mul.s $f1, $f15, $f12
	sub.s $f9, $f0, $f1
	div.s $f9, $f9, $f16
	# h2 = (q * A − p * B) / D
	mul.s $f0, $f15, $f11
	mul.s $f1, $f14, $f12
	sub.s $f10, $f0, $f1
	div.s $f10, $f10, $f16
	# h0 = (g0 − r1 * h1 − r2 * h2) / r0
	mul.s $f0, $f3, $f9
	mul.s $f1, $f4, $f10
	sub.s $f8, $f5, $f0
	sub.s $f8, $f8, $f1
	div.s $f8, $f8, $f2
	# pop the stack
	lwc1 $f16, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f15, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f14, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f13, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f12, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f11, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f1, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f0, 0($sp)
	addi $sp, $sp, 4
#========



# 5. CALCULATE OUTPUT SIGNAL y(n)
## 5.1. Calc of h(0)
la $t0, signal_input	# input signal
la $t1, signal_output	# output signal
jal out_sig_calc

li $t0, 0	# reset $t0
li $t1, 0	# reset $t1
j sect_5_1_1

out_sig_calc:
# Procedure `out_sig_calc`: Calculate the output signal y(n) based on input signal x(n) and filter coefficients h(0), h(1), h(2); then save output signal to `signal_output`
# used reg		$t0: hold addr of `signal_input`
#			$t1: hold addr of `signal_output`
#			$f8: hold h(0)
#			$f9: hold h(1)
#			$f10: hold h(2)
# consumed reg:		$t2: count var
#			$t3: addr of x[n - k]
#			$f0: hold extracted value from `signal_input`
#			$f1: hold tmp val
# returned reg:		NULL
	# push $t2, $t3, $f0, $f1 into the stack
	addi $sp, $sp, -4
	sw $t2, 0($sp)
	addi $sp, $sp, -4
	sw $t3, 0($sp)	
	addi $sp, $sp, -4
	swc1 $f0, 0($sp)
	addi $sp, $sp, -4
	swc1 $f1, 0($sp)
	# init count var to 0
	li $t2, 0

loop_5:
	beq $t2, 10, outloop_5
	# load x(n)
	lwc1 $f1, 0($t0)
	# x(n - 0) * h(0)
	mul.s $f1, $f1, $f8
	add.s $f0, $f0, $f1
	beq $t2, 0, loop_5_incre_iter
	# x(n - 1) * h(1)
	addi $t3, $t0, -4
	lwc1 $f1, 0($t3)
	mul.s $f1, $f1, $f9
	add.s $f0, $f0, $f1
	beq $t2, 1, loop_5_incre_iter
	# x(n - 2) * h(2)
	addi $t3, $t3, -4
	lwc1 $f1, 0($t3)
	mul.s $f1, $f1, $f10
	add.s $f0, $f0, $f1

loop_5_incre_iter:
	# save y(n)
	swc1 $f0, 0($t1)
	# increasing iterator
	addi $t0, $t0, 4
	addi $t1, $t1, 4
	addi $t2, $t2, 1
	mtc1 $zero, $f0		# reset $f0
	j loop_5

outloop_5:
	# pop the stack
	lwc1 $f1, 0($sp)
	addi $sp, $sp, 4
	lwc1 $f0, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t2, 0($sp)
	addi $sp, $sp, 4
	# end procedure
	jr $ra

### 5.1.1. Testing float values from `signal_output`
sect_5_1_1:
#la $t0, signal_output
#li $t1, 0
#loop_5_1_1:
	#bge $t1, 10, outloop_5_1_1
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
    	#j loop_5_1_1

outloop_5_1_1:
##--------
#========



#===========END OF TASK 1, TASK 2 AND TASK 3============#
#							#
# Residual values in the registers are listed below:	#
# - $f2: Hold r(0)					#
# - $f3: Hold r(1)					#
# - $f4: Hold r(2)					#
# - $f5: Hold g(0)					#
# - $f6: Hold g(1)					#
# - $f7: Hold g(2)					#
# - $f8: Hold h(0)					#
# - $f9: Hold h(1)					#
# - $f10: Hold h(2)					#
#							#
# These registers CAN BE reused, or cleared depends on	#
# disires of the user of this file, feel free~		#
#							#
# Data used in computations are listed by the lables	#
# below:						#
# - signal_input: Store data of `input.txt`		#
# - signal_desired: Store data of `desired.txt`		#
# - signal_output: Store data of computed output signal #
# - buffer: Used for processing the input files		#
# - inpFile: Store string "input.txt"			#
# - inpFile1: Store string "desired.txt"		#
# - err_msg: Store the file error message		#
# - err_msg1: Store the size error message		#
#							#
# These labels MUST BE kept as is, any modification may #
# result in undefined behaviours or errors.		#
#########################################################



exit:
# Exit program
li $v0, 10
syscall
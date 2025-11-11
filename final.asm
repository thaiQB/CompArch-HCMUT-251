.data
buffer:			.space 256	# 256 bytes for reading buffer
input_signal:		.space 40 	# 40 bytes for 10 float values
desired_signal:		.space 40	# //
output_signal:		.space 40	# //
optimize_coefficient: 	.space 12
mmse:                 	.space 4 

.align 2 

inpFile:		.asciiz "input.txt"
inpFile1:		.asciiz "desired.txt"
outFile:		.asciiz "output.txt"
error_msg:		.asciiz "Error opening file."
error_msg1:		.asciiz "Error: size not match"

msg_output:     .asciiz "Filtered output: "
msg_mmse:       .asciiz "MMSE: "
msg_variance:	.asciiz "Variance: "
space:          .asciiz " "
newline:        .asciiz "\n"
msg_buffer:	.asciiz "Buffer debugging: "

# --- New labels for float printing ---
dot:            .asciiz "."
neg:            .asciiz "-"
zero_float:     .float 0.0
ten_float:      .float 10.0
round_float:    .float 0.05
half_float:	.float 0.5
saved_mmse_float: .float 0.0
float_buffer:	.space 40
rounded_output_signal: .float 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0

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
	
	# Null-terminate buffer so parser can detect end reliably
	move $t9, $v0         # bytes read
	la   $t0, buffer
	add  $t0, $t0, $t9
	sb   $zero, 0($t0)     # buffer[bytes_read] = '\0'

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
la $t1, input_signal
jal buffer_handling

li $t0, 0		# reset $t0
li $t1, 0		# reset $t1
move $t5, $t4	# store num of ele of input signal to $t5
j sect_1_3

buffer_handling:
# Procedure `buffer_handling`: Convert the characters in $t0 (`buffer`) to respective FP values in $t1 (`input_signal`)
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
	# reset counters and accumulators
	li $t4, 0          # number count
	li $t3, 0          # negativity flag
	mtc1 $zero, $f2    # $f2 = 0.0 (accumulator for current number)

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
	# save float to input_signal
	swc1 $f2, 0($t1)
	# $t4++
	addi $t4, $t4, 1
	
	li $t3, 0		# reset $t3
	mtc1 $zero, $f2		# reset $f2
	addi $t1, $t1, 4	# move to next word of input_signal
	j loop_1_2_incre_iterator
	
meet_end:
	# save last float
	div.s $f2, $f2, $f1	# divide $f2 by 10 to set 1 decimal place
	# save float to input_signal
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

### 1.2.1. Testing retrieving float values from `input_signal`
#la $t0, input_signal
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


## 1.3. Do the same for desired signal (desired.txt - inpFile1)
sect_1_3:
la $a0, inpFile1
jal file_read
li $a0, 0	# reset $a0

la $t0, buffer
la $t1, desired_signal
jal buffer_handling

li $t0, 0			# reset $t0
li $t1, 0			# reset $t1
bne $t4, $t5, err_size		# compare num of ele between `input.txt` and `desired.txt`
j sect_2

err_size:
# Handle size error
li $v0, 4
la $a0, error_msg1
syscall
# Terminate program
j write_error_output
##--------


### 1.3.1. Testing retriving float values from `desired_signal`
#la $t0, desired_signal
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



# 2. CALC AUTO-CORRELATION r(0), r(1), r(2) OF INPUT SIGNAL x(n)
sect_2:
# Assign an FPU register to 10.0 for later calculations
li $t0, 10
mtc1 $t0, $f1
cvt.s.w $f1, $f1 # $f1 = 10
## 2.1. Calc r(0)
la $t0, input_signal
li $t1, 0

loop_2_1:
	# r(0) = (x(1)^2 + x(2)^2 + ... + x(10)^2) / 10
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
	# div.s $f2, $f2, $f1
##--------


## 2.2. Calc r(1)
la $t0, input_signal
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
	# increase iterator
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	j loop_2_2

endloop_2_2:
	# divide $f3 by 10
	# div.s $f3, $f3, $f1
##--------


## 2.3. Calc r(2)
la $t0, input_signal
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
la $t0, input_signal
la $t1, desired_signal
li $t2, 0			# h (the "lag" of the signal)
jal cross_corr
mov.s $f5, $f8		# store result in $f5

mtc1 $zero, $f8		# reset $f8
##--------


## 3.2. Calc g(1)
la $t0, input_signal
la $t1, desired_signal
li $t2, 1
jal cross_corr
mov.s $f6, $f8		# store result in $f6

mtc1 $zero, $f8		# reset $f8
##--------


## 3.3. Calc g(2)
la $t0, input_signal
la $t1, desired_signal
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
la $t0, input_signal	# input signal
la $t1, output_signal	# output signal
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

    	# initialize accumulator $f0 to 0.0 (important for first y[0])
    	mtc1 $zero, $f0
    	# optionally also clear $f1 (scratch) to be safe
    	mtc1 $zero, $f1


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
	# --- store h0,h1,h2 into memory (optimize_coefficient) ---
    	la   $t0, optimize_coefficient
    	swc1 $f8, 0($t0)      # h0 -> optimize_coefficient[0]
    	swc1 $f9, 4($t0)      # h1 -> optimize_coefficient[1]
    	swc1 $f10,8($t0)      # h2 -> optimize_coefficient[2]
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
#la $t0, output_signal
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

#outloop_5_1_1:
    # --- Print newline to TERMINAL ---
    #la $a0, newline
    #li $v0, 4
    #syscall
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
# - input_signal: Store data of `input.txt`		#
# - desired_signal: Store data of `desired.txt`		#
# - output_signal: Store data of computed output signal #
# - buffer: Used for processing the input files		#
# - inpFile: Store string "input.txt"			#
# - inpFile1: Store string "desired.txt"		#
# - err_msg: Store the file error message		#
# - err_msg1: Store the size error message		#
#							#
# These labels MUST BE kept as is, any modification may #
# result in undefined behaviours or errors.		#
#########################################################



#=======================================================#
# START OF STEP 4 & 5 (Variance and MMSE)               #
#=======================================================#

# -------------------------------------------------------------------
# PHASE 1: PRINT ALL OUTPUT TO TERMINAL
# -------------------------------------------------------------------

start_terminal_print_section:
    # --- Print "Filtered output: " to TERMINAL ---
    la $a0, msg_output
    li $v0, 4                 # Print string
    syscall

    # --- Loop to print 10 filtered values to TERMINAL ---
    la $t0, output_signal     # $t0 = &output_signal[0]
    la $t3, rounded_output_signal # $t3 = &rounded_output_signal[0]
    li $t1, 0                 # $t1 = i
    li $t2, 10                # $t2 = N

loop_print_y:
    beq $t1, $t2, end_loop_print_y
    
    # 1. Load and round y[i]
    lwc1 $f12, 0($t0)
    jal round_1_decimal       # $f12 now contains the rounded float

    # 3. *** NEW: Save the rounded float for Phase 2 ***
    swc1 $f12, 0($t3)	# rounded float saved in array
            
    # 2. Print to TERMINAL
    li $v0, 2                 # Print float
    syscall
    
    # 4. Print space to TERMINAL
    la $a0, space
    li $v0, 4                 # Print string
    syscall
    
    addi $t0, $t0, 4          # Next original float
    addi $t3, $t3, 4          # Next storage slot
    addi $t1, $t1, 1
    j loop_print_y

end_loop_print_y:
    #reset $f12
    l.s $f12, zero_float
    
    j calc_variance_final # skip debug here!
    
    # AFTER DEBUGGING: array stored correcly!
# print array to terminal
    #la $t0, rounded_output_signal
    #li $t1, 0
    #li $t2, 10
    
# use to debug
print_float_array:
    beq $t1, $t2, calc_variance_final
    
    # 1. Load and round y[i]
    lwc1 $f12, 0($t0)

    # 2. Print to TERMINAL
    li $v0, 2                 # Print float
    syscall

    # 4. Print space to TERMINAL
    la $a0, space
    li $v0, 4                 # Print string
    syscall
    
    addi $t0, $t0, 4          # Next element
    addi $t1, $t1, 1
    j print_float_array
    

# 7. COMPUTE POWER OF DESIRED SIGNAL (Variance)
calc_variance_final:
    # --- Print newline to TERMINAL ---
    la $a0, newline
    li $v0, 4
    syscall
    
    la $t0, desired_signal
    li $t1, 0
    li $t2, 10
    mtc1 $zero, $f12

loop_var_final:
    beq $t1, $t2, end_loop_var_final
    lwc1 $f0, 0($t0)
    mul.s $f1, $f0, $f0
    add.s $f12, $f12, $f1
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    j loop_var_final

end_loop_var_final:
    l.s $f13, ten_float
    div.s $f14, $f12, $f13     # $f14 = variance
    j calc_mmse_final

# 8. COMPUTE & PRINT FINAL MMSE (Line 2)
calc_mmse_final:
    mul.s $f16, $f5, $f8
    mul.s $f17, $f6, $f9
    mul.s $f18, $f7, $f10
    add.s $f16, $f16, $f17
    add.s $f16, $f16, $f18
    div.s $f16, $f16, $f13
    
    sub.s $f20, $f14, $f16    # $f20 = FINAL MMSE VALUE

    la $a0, msg_mmse	# print the mmse
    li $v0, 4
    syscall

    mov.s $f12, $f20
    jal round_1_decimal
    
    swc1 $f12, saved_mmse_float	# save the mmse
    # --- Store final MMSE into variable mmse (for grading) ---
    la   $t0, mmse
    swc1 $f12, 0($t0)

    
    li $v0, 2
    syscall
    
    la $a0, newline
    li $v0, 4
    syscall
    
    #reset $f12
    l.s $f12, zero_float
    
    j start_file_write_section
 
# -------------------------------------------------------------------
# PHASE 2: WRITE ALL OUTPUT TO FILE (USING SAVED VALUES)
# -------------------------------------------------------------------
start_file_write_section:
    # --- Open output.txt for writing ---
    li $v0, 13
    la $a0, outFile
    li $a1, 1                 # $a1 = flags (1 = write-only)
    li $a2, 0
    syscall
    move $s6, $v0             # Save file descriptor in $s6

    # --- Write "Filtered output: " to FILE ---
    li $v0, 15                # Write to file
    move $a0, $s6
    la $a1, msg_output
    li $a2, 17                # length("Filtered output: ")
    syscall

    # --- Loop to write 10 *rounded* values to FILE ---
    la $t0, rounded_output_signal # $t0 = &rounded_output_signal[0]
    li $t1, 0                 # $t1 = i
    li $t2, 10                # $t2 = N
    
    #reset $f12
    l.s $f12, zero_float
    j loop_write_y
    
    # for debug
    la $a0, msg_buffer
    li $v0, 4
    syscall

loop_write_y:
    beq $t1, $t2, end_loop_write_y
    
    #reset $f12
    l.s $f12, zero_float
    
    # 1. Load the PRE-ROUNDED float
    lwc1 $f12, 0($t0)
    
    # for debug
    #li $v0, 2       # Syscall 2 = print float
    # $f12 already has the value we just loaded
    #syscall
    
    # --- BEGIN BUGFIX ---
    # We must save $f12 because the $v0=4 syscall will clobber it.
    addi $sp, $sp, -4
    swc1 $f12, 0($sp)
    # --- END BUGFIX ---
    
    # Print a space to separate it
    la $a0, space
    li $v0, 4
    syscall
    
    # --- BEGIN BUGFIX ---
    # Restore $f12 to its correct value (e.g., 0.3)
    lwc1 $f12, 0($sp)
    addi $sp, $sp, 4
    # --- END BUGFIX ---
        
    # 2. Convert rounded float in $f12 to string
    la $a1, float_buffer      # $a1 = address of buffer
    jal ftoa_1_decimal        # $v0 now holds the string length
    
    move $t5, $v0             # $t5 = length = $v0
    
    # 3. Write string to FILE
    li $v0, 15                # $v0 = syscall code (clobbers old length)
    move $a0, $s6             # $a0 = file descriptor
    la $a1, float_buffer      # $a1 = buffer
    move $a2, $t5             # $a2 = length (from $t5)
    syscall
    
    # 4. Write space to FILE
    li $v0, 15
    move $a0, $s6
    la $a1, space
    li $a2, 1
    syscall
    
    addi $t0, $t0, 4
    addi $t1, $t1, 1
    j loop_write_y

end_loop_write_y:
    # --- Write newline to FILE ---
    li $v0, 15
    move $a0, $s6
    la $a1, newline
    li $a2, 1
    syscall

    # --- Write "MMSE: " to FILE ---
    li $v0, 15
    move $a0, $s6
    la $a1, msg_mmse
    li $a2, 6
    syscall

    # 1. Load SAVED MMSE
    l.s $f12, saved_mmse_float
    
    # 2. Convert rounded float to string
    la $a1, float_buffer
    jal ftoa_1_decimal        # $v0 = length  
    
    # 3. Write string to FILE
    li $v0, 15                # $v0 = syscall code
    move $a0, $s6
    la $a1, float_buffer
    move $a2, $t5             # $a2 = length (from $t5)
    syscall
    
    # 4. Write final newline to FILE
    li $v0, 15
    move $a0, $s6
    la $a1, newline
    li $a2, 1
    syscall
    
    # --- Close the file ---
    li $v0, 16
    move $a0, $s6
    syscall

    j exit

# -------------------------------------------------------------------
# PROCEDURE: round_1_decimal 
# -------------------------------------------------------------------
round_1_decimal:
    addi $sp, $sp, -16      
    sw $ra, 12($sp)
    swc1 $f30, 8($sp)
    swc1 $f29, 4($sp)
    swc1 $f0, 0($sp)

    l.s $f30, ten_float
    l.s $f29, half_float
    mul.s $f12, $f12, $f30
    l.s $f0, zero_float
    c.lt.s $f12, $f0
    bc1t round_neg_1d
round_pos_1d:
    add.s $f12, $f12, $f29
    j continue_1d
round_neg_1d:
    sub.s $f12, $f12, $f29
continue_1d:
    cvt.w.s $f12, $f12
    cvt.s.w $f12, $f12
    div.s $f12, $f12, $f30
    
    lwc1 $f0, 0($sp)
    lwc1 $f29, 4($sp)
    lwc1 $f30, 8($sp)
    lw $ra, 12($sp)
    
    addi $sp, $sp, 16      
    
    jr $ra

# -------------------------------------------------------------------
# ftoa_1_decimal: Converts float in $f12 to a string in $a1
#   - Handles any reasonable float value
#   - $f12: Input float (is NOT modified)
#   - $a1:  Pointer to output buffer
# Returns:
#   - $v0:  The length of the resulting string
# -------------------------------------------------------------------
ftoa_1_decimal:
    # --- Prologue: Save registers ---
    addi $sp, $sp, -48
    sw $ra, 44($sp)
    sw $t0, 40($sp)
    sw $t1, 36($sp)
    sw $t2, 32($sp)
    sw $t3, 28($sp)        # Need extra temp register
    swc1 $f0, 24($sp)
    swc1 $f1, 20($sp)
    swc1 $f2, 16($sp)
    swc1 $f3, 12($sp)
    swc1 $f29, 8($sp)
    swc1 $f30, 4($sp)
    swc1 $f31, 0($sp)
    
    move $t0, $a1          # $t0 = buffer pointer
    li $t1, 0              # $t1 = length counter
    
    # --- Load constants ---
    l.s $f30, ten_float    # $f30 = 10.0
    l.s $f29, half_float   # $f29 = 0.5
    l.s $f31, zero_float   # $f31 = 0.0
    
    # --- Make a working copy of the input float ---
    mov.s $f2, $f12
    
    # 1. Check for negative
    c.lt.s $f2, $f31
    bc1f ftoa_positive
    
    # It's negative:
    li $t2, 0x2d           # '-'
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    abs.s $f2, $f2         # Make positive
    
ftoa_positive:
    # 2. Get integer part
    trunc.w.s $f0, $f2     # Truncate to get integer part
    mfc1 $t3, $f0          # $t3 = integer part
    
    # 3. Convert integer part to string (handle multi-digit numbers)
    # We'll build the digits in reverse, then reverse them
    move $t2, $t0          # Save current position
    
    # Special case: if integer part is 0
    bne $t3, $zero, convert_integer
    li $t2, 48             # '0'
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j decimal_point
    
convert_integer:
    # Convert integer digits (in reverse order first)
    move $a0, $t0          # Start position for digits
    li $t2, 0              # Digit counter
    
digit_loop:
    beq $t3, $zero, reverse_digits
    
    # Get last digit: $t3 % 10
    li $a1, 10
    div $t3, $a1
    mfhi $a2               # $a2 = $t3 % 10
    mflo $t3               # $t3 = $t3 / 10
    
    # Store digit
    addi $a2, $a2, 48      # Convert to ASCII
    sb $a2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 1       # Increment digit count
    
    j digit_loop
    
reverse_digits:
    # Reverse the digits we just wrote
    move $a1, $a0          # Start of digits
    addi $a2, $t0, -1      # End of digits
    
reverse_loop:
    bge $a1, $a2, decimal_point
    
    # Swap bytes at $a1 and $a2
    lb $t3, 0($a1)
    lb $a3, 0($a2)
    sb $a3, 0($a1)
    sb $t3, 0($a2)
    
    addi $a1, $a1, 1
    addi $a2, $a2, -1
    j reverse_loop
    
decimal_point:
    # 4. Store decimal point
    li $t2, 0x2e           # '.'
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    
    # 5. Get fractional part
    cvt.s.w $f1, $f0       # Convert integer part back to float
    sub.s $f3, $f2, $f1    # $f3 = fractional part
    
    # 6. Get first decimal digit
    mul.s $f3, $f3, $f30   # $f3 = frac * 10.0
    add.s $f3, $f3, $f29   # Add 0.5 for rounding
    trunc.w.s $f0, $f3     # Truncate to get digit
    mfc1 $t2, $f0          # Move digit to $t2
    
    # Ensure digit is in range 0-9 (handle rounding overflow)
    blt $t2, 10, store_decimal_digit
    li $t2, 9              # Cap at 9 if rounding caused overflow
    
store_decimal_digit:
    addi $t2, $t2, 48      # Convert to ASCII
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    
    # 7. Store null terminator
    li $t2, 0
    sb $t2, 0($t0)
    
    # 8. Return length
    move $v0, $t1
    
    # --- Epilogue: Restore registers ---
    lwc1 $f31, 0($sp)
    lwc1 $f30, 4($sp)
    lwc1 $f29, 8($sp)
    lwc1 $f3, 12($sp)
    lwc1 $f2, 16($sp)
    lwc1 $f1, 20($sp)
    lwc1 $f0, 24($sp)
    lw $t3, 28($sp)
    lw $t2, 32($sp)
    lw $t1, 36($sp)
    lw $t0, 40($sp)
    lw $ra, 44($sp)
    addi $sp, $sp, 48
    jr $ra

write_error_output:
    # --- Open output.txt for writing ---
    li $v0, 13
    la $a0, outFile
    li $a1, 1                 # $a1 = flags (1 = write-only)
    li $a2, 0
    syscall
    move $s6, $v0             # Save file descriptor in $s6

    # --- Write error to FILE ---
    li $v0, 15                # Write to file
    move $a0, $s6
    la $a1, error_msg1
    li $a2, 21                # length("Error: size not match")
    syscall


exit:
# Exit program
li $v0, 10
syscall

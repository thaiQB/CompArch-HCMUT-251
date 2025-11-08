.data
buffer:			.space 256 # 256 bytes for reading buffer
signal_input:		.space 40  # 40 bytes for 10 float values

inpFile:		.asciiz "input.txt"
outFile:		.asciiz "output.txt"
error_msg:		.asciiz "Error opening file." 



.text
# 1. INPUT FILE HANDLING
## 1.1. Open The Input File For Reading
li $v0, 13            
la $a0, inpFile        
li $a1, 0	# read mode          
li $a2, 0          
syscall
move $s0, $v0	# $s0 = $v0
### 1.1.1. Check if file opened successfully
blt $s0, $zero, file_error
j sect_1_2

file_error:
# Handle file open error
li $v0, 4
la $a0, error_msg
syscall
j exit
##--------


## 1.2. Read Data From File Into `buffer`
sect_1_2:
li $v0, 14           
move $a0, $s0	# $a0 = $s0         
la $a1, buffer
li $a2, 256
syscall

li $a1, 0	# reset $a1
li $a2, 0	# reset $a2
##--------


## 1.3. Close Input File After Reading
li $v0, 16
move $a0, $s0
syscall

li $v0, 0	# reset $v0
li $s0, 0	# reset $s0
li $a0, 0	# reset $a0
##--------


## 1.4. Save Char From buffer As Float Values In `input_signal`
li $t0, 10
mtc1 $t0, $f1
cvt.s.w $f1, $f1 # f1 = 10
la $t0, buffer
la $t1, signal_input

loop_1_4:
	lb $t2, 0($t0)			# load char, $t2 now holding ASCII code
	beq $t2, 0, meet_end		# if meets `\0` (end of file), endloop
	beq $t2, 32, meet_space		# if meets ` ` (space), save float
	beq $t2, 46, loop_1_4_incre_iterator
					# if meets `.`, continue
	
	addi $t2, $t2, -48		# convert ASCII code to number
					# 48 is ASCII code of 0
	mtc1 $t2, $f0
	cvt.s.w $f0, $f0
	mul.s $f2, $f2, $f1
	add.s $f2, $f2, $f0

loop_1_4_incre_iterator:
	addi $t0, $t0, 1	# move to the next char of buffer
	j loop_1_4
	
meet_space:
	# divide $f2 by 10 to set 1 decimal place
	div.s $f2, $f2, $f1
	# save float to signal_input
	swc1 $f2, 0($t1)
	mtc1 $zero, $f2		# reset $f2
	addi $t1, $t1, 4	# move to next word of signal_input
	j loop_1_4_incre_iterator
	
meet_end:
	# save last float
	div.s $f2, $f2, $f1	# divide $f2 by 10 to set 1 decimal place
	# save float to signal_input
	swc1 $f2, 0($t1)
	
	mtc1 $zero, $f1		# reset $f1
	mtc1 $zero, $f2		# reset $f2
	
### 1.4.1. Testing retriving float values from `signal_input`
#la $t0, signal_input
#li $t1, 0
loop_1_4_1:
	#bge $t1, 10, outloop_1_4_1
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
    	#j loop_1_4_1

outloop_1_4_1:
##-------
#========



# 2. CALC AUTO-CORRELATION h(0), h(1), h(2) OF INPUT SIGNAL x(n)
## 2.1. Calc h(0)
la $t0, signal_input
li $t1, 0


loop_2_1:
	# h(0) = (x(1)^2 + x(2)^2 + ... + x(10)^2) / 10
	beq $t1, 10, endloop_2_1
	lwc1 $f0, 0($t0)
	mul.s $f0, $f0, $f0
endloop_2_1:	
##--------
#========
j exit




exit:
# Exit program
li $v0, 10
syscall

.data
buffer:			.space 256 # 256 bytes for reading buffer
signal_input:		.space 40  # 40 bytes for 10 float values
inpFile:		.asciiz "input.txt"
outFile:		.asciiz "output.txt"
error_msg:		.asciiz "Error opening file." 



.text
# 1. INPUT FILE HANDLING
## 1.1. Open the input file for reading
li $v0, 13            
la $a0, inpFile        
li $a1, 0	# read mode          
li $a2, 0          
syscall
move $s0, $v0	# $s0 = $v0
### 1.1.1. Check if file opened successfully
blt $s0, $zero, file_error
##--------


## 1.2. Read data from the file into buffer
li $v0, 14           
move $a0, $s0	# $a0 = $s0         
la $a1, buffer
li $a2, 256
syscall
##--------


## 1.3. Close the input file after reading
li $v0, 16
move $a0, $s0
syscall
##--------


## 1.4. Save char from buffer as float values in input_signal
li $t0, 10
mtc1 $t0, $f1
cvt.s.w $f1, $f1 # f1 = 10
la $t0, buffer

loop_1_4:
	lb $t1, 0($t0)			# load char, $t1 now holding ASCII code
	beq $t1, 0, outloop_1_4		# if meets `\0` (end of file), endloop
	beq $t1, 32, meet_space		# if meets ` ` (space), save float
	beq $t1, 46, meet_dot		# if meets `.`, handle decimal part
	
	addi $t1, $t1, -48		# convert ASCII code to number
					# 48 is ASCII code of 0
	mtc1 $t1, $f0
	cvt.s.w $f0, $f0
	mul.s $f2, $f2, $f1
	add.s $f2, $f2, $f0
	addi $t0, $t0, 1
	j loop_1_4
	
	# gio lam handle meet_space, meet_dot voi outloop la xong phan 1.4 :V

outloop_1_4:
#========


# 2. CALC AUTO-CORRELATION h(0), h(1), h(2) OF INPUT SIGNAL x(n)
## 2.1. Calc h(0)
j exit




file_error:
# Handle file open error
li $v0, 4
la $a0, error_msg
syscall
# Exit program
li $v0, 10
syscall

meet_space:
meet_dot:

exit:
# Exit program
li $v0, 10
syscall
# CompArch-HCMUT-251
Large Assignment - Computer Architecture - Ho Chi Minh city University of Technology - Semester 251

## Files in this repository
1. MARS MIPS Simulator 4.5
	- Can be downloaded at []()
2. `input.txt`: A text file holding 10 one-decimal place floating-point numbers
	- This served as the **input signal**
3. `test.asm`: Run this file using the simulator)
4. `.pdf`: The specfication for this large assignment)

<br>

>[!Warning]
>It is recommended to put the first 3 files above **in the same directory** in order to run normally.

## Some notes
>[!Caution]
>When coding in MARS MIPS, always put the `.asciiz` variables at **the end** of the `.data` section to avoid `Runtime exception: store address not aligned on word boundary` error in MARS MIPS.

<br>

>[!Note]
>*Usage: Sect 1.4*
>There are some ways to reset a floating-point register:
>1. `mtc1 $zero, $f3`
>2. ```asm
	li $t0, 0
	mtc1 $t0, $f0
	cvt.s.w $f0, $f0
	add.s $f3, $f0, $f0
	```
>3. `sub.s $f3, $f3, $f3`
	- Note that this will not work for `NaN`, `InF` values
>
>Cre: [StackOverFlow](https://stackoverflow.com/questions/22770778/how-to-set-a-floating-point-register-to-0-in-mips-or-clear-its-value)
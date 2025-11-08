# CompArch-HCMUT-251
Large Assignment - Computer Architecture - Ho Chi Minh city University of Technology - Semester 251

## Files in this repository
1. MARS MIPS Simulator 4.5
	- Can be downloaded at []()
2. `input.txt`: A text file holding 10 1-decimal place floating-point numbers
	- This served as the **input signal**
3. `test.asm`: Run this file using the simulator)
4. `.pdf`: The specfication for this large assignment)

>[!Warning]
>It is recommended to put the first 3 files above **in the same directory** in order to run normally.

## Some notes
>[!Caution]
>When coding in MARS MIPS, always put the `.asciiz` variables at **the end** of the `.data` section to avoid `Runtime exception: store address not aligned on word boundary` error in MARS MIPS.
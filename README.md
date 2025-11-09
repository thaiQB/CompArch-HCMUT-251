# CompArch-HCMUT-251
Large Assignment - Computer Architecture - Ho Chi Minh city University of Technology - Semester 251

## Files in this repository
1. MARS MIPS Simulator 4.5
	- Can be downloaded at []()
2. `input.txt`: A text file holding 10 one-decimal place floating-point numbers
	- This served as the **input signal**
3. `test.asm`: Run this file using the simulator)
4. `.pdf`: The specification for this large assignment)

<br>

>[!Warning]
>It is recommended to put the first 3 files above **in the same directory** in order to run normally.

## Some notes
>[!Warning]
>When coding in MARS MIPS, always put the `.asciiz` variables at **the end** of the `.data` section to avoid `Runtime exception: store address not aligned on word boundary` error in MARS MIPS.

<br>

>[!Caution]
>In the specfication of the assignment, it said that the **only** input file is the file `input.txt`, which is the combination (*a.k.a. the __sum__, according to the __test_case_files__*) of 2 signal: the **desired one** and the **noise**. But if we don't specify the **desired** signal for the MIPS file, how can we calculate the **cross-correlation** between the **input and the desired**???  
> For my implementation, I declared 2 variables: `signal_input`, and `signal_desired` to **hold 2 files**: `input.txt` and `desired.txt`, but I wonder if this violates the specifications?

<br>

>[!Caution]
>In the testcases, the files `input.txt` and `desired.txt` have a **trailing space** right after the last number of the series, which affect the **input file handling** of my implementation. I suppose that the **actual testcases** will **not have** this trailling space, so I fixed the input files to match my format (end-of-file after the last number). But am I correct, or there must be a trailing space in the input files?

<br>

>[!Warning]
>*Apply to: __Sect_1.2__*  
>The caution above is written after I implemented the file processing for the **single file** `input.txt`, so I had to rework it. It's now working as a **procedure** to process **2 files**: `input.txt` and `desired.txt`.  
>  
>The problem is that in the old version, I used the register `$t0` to hold integer 10, which is then converted into float 10 and stored in `$f1`, after that it was used to hold the address of `buffer`. With the reworked version, however, the **"hold integer 10"** must be performed **after** the **"hold address of `buffer`"**!  
>That why you'll see in the versions 0.5+, after being assigned `buffer`'s address, the value of `$t0` will be stored in `$sp` so it can perform the **"hold integer 10"**, then it is popped out and used to run the procedure (*which is, kinda overcomplicated, imo*).  
>  
>Again, sorry for my dumbness and laziness, but I really don't want to rewrite that section again since it had already taken me a whole afternoon to do that 😭.

<br>

>[!Note]
>*Apply to: __Sect_1.2__*  
>I just figured out (through the testcase file) that the numbers **can be negative**.  
>I didn't think about it when implementing the **`buffer` conversion**, so I (again) needed to rework it...  (version 0.6)

<br>

>[!Note]
>*Apply to: __Sect_1.2__*  
>There are some ways to reset a floating-point register (*e.g. `$f3`*):
>1. `mtc1 $zero, $f3`
>
>2. Load integer 0 to an FP register and assign it to `$f3`:
>	```asm
>	li $t0, 0
>	mtc1 $t0, $f0
>	cvt.s.w $f0, $f0
>	add.s $f3, $f0, $f0
>	```
>
>3. `sub.s $f3, $f3, $f3`  
	- Note that this will not work for `NaN`, `InF` values
>
>Cre: [StackOverFlow](https://stackoverflow.com/questions/22770778/how-to-set-a-floating-point-register-to-0-in-mips-or-clear-its-value)

<br>

>[!Note]
>*Apply to: __Sect_2__*  
>There **obviously** must be a better way to compute the autocorrelation and the cross-correlation by using a big loop instead of making seperate loops like I did. But at the moment, I can't seem to figure it out. Sorry for my stupidity.  
>  
> You wonder why I said "obviously"? Because I could implement that approach with C++!
>	```cpp
>	float input_signal[10] = {1234.1, 5678.2, 9012.3, 3456.4, 7890.5, 1234.6, 5678.7, 9012.8, 3456.9, 7890.0};
>	float h[3] = {0.0, 0.0, 0.0};
>	std::cout<<"Hello World\n";
>	std::cout << std::setprecision(8);
>	for (int i = 0; i < 3; i++)
>	{
>		for (int j = 0; j < 10 - i; j++)
>		{
>			h[i] += input_signal[j] * input_signal[j + i];
>		}
>  
>		h[i] /= 10;
>		std::cout << h[i] << "\n";
>	}
>
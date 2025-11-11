*THIS IS THE `beta` BRANCH, WHERE I TEST THE FINISHED CODE SENT BY MY TEAMMATES, FOR MY IMPLEMENTATION, SEE THE [`main-alpha]()` BRANCH*
# ASSIGNMENT: FILTERING AND PREDICTION SIGNAL WITH WIENER FILTER
According to the tasks derived from the assignment's specification, this files can perform the following:
- [x] Read the input files `input.txt` and `desired.txt`
- [x] Return size error if the number of elements in 2 files are different
- [x] Compute the autocorrelations and cross-correlations of the input signal $x[n]$ and $d[n]$
- [x] Compute the output signal $y[n]$
- [x] Write the result to the output file `output.txt`

## Files In This repository
1. `CA_Assignment_251_1.pdf`: The specification for this large assignment
2. `source.asm`: Run this file using the simulator
3. `test.cpp`: A C++ file to test the result of **autocorrelation** and **cross-correlation**
4. `test.py`: This served as an example for testing the computing results. The results of the `.asm` file is required to be the same as the `.py` file.
5. `Testcase` folder: A folder of testcases (*duh*)
6. `Refs` folder: A folder of references for the computation methods (*believe me, I tried my best to find the ones writing the math formulas as simple as possible. Please, I'm not a mad scientist to read the symbols in those MIT and MATLAB's documents 😓)

# PREQUISITES
You'll need these in order to test my work:
1. **MARS MIPS Simulator 4.5**
	- Can be downloaded [here](https://github.com/dpetersanderson/MARS/releases/tag/v.4.5.1)
	- More info can be found [here](https://dpetersanderson.github.io/index.html) and [there](https://computerscience.missouristate.edu/mars-mips-simulator.htm)
2. A **testcase** (*to be honest, I still don't know what is the expected result for the output signal :v*)
	- An `input.txt` and an `output.txt` files containing floating-point numbers (you can see some examples about these files in the `Testcase` folder are required for the test.
	- A test example can be viewed [here](https://github.com/thaiQB/CompArch-HCMUT-251/releases/tag/alpha)

<br>

>[!Warning]
>It is recommended to put the files above **in the same directory** in order to run normally.

## Some Notes
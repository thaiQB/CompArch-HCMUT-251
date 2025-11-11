'''

Welcome to GDB Online.
GDB online is an online compiler and debugger tool for C, C++, Python, Java, PHP, Ruby, Perl,
C#, OCaml, VB, Swift, Pascal, Fortran, Haskell, Objective-C, Assembly, HTML, CSS, JS, SQLite, Prolog.
Code, Compile, Run and Debug online from anywhere in world.

'''
import numpy as np
import matplotlib.pyplot as plt

# Read input signals
x = np.array([-0.1, 1.4, 0.8, -0.1, -0.4, -0.8, -0.9, 0.7, 1.1, 0.1])
d = np.array([0.0, 1.3, 0.7, 0.0, -0.1, -1.0, -1.1, 0.6, 1.2, 0.3])
## Handle size error
N = len(x)
if len(d) != N:
    print("Error: size not match")
    exit(1)


# Compute autocorrelation and crosscorrelation
auto_0 = np.sum(x * x)
auto_1 = np.sum(x[1:] * x[:-1])
auto_2 = np.sum(x[2:] * x[:-2])
print(f"Autocorrelation: g0 = {auto_0:.5f}, h1 = {auto_1:.5f}, h2 = {auto_2:.5f}")

cross_0 = np.sum(d * x)
cross_1 = np.sum(d[1:] * x[:-1])
cross_2 = np.sum(d[2:] * x[:-2])
print(f"Cross-correlation: h0 = {cross_0:.5f}, h1 = {cross_1:.5f}, h2 = {cross_2:.5f}")


# Solve for optimize coefficients
A = auto_0**2 - auto_1**2
B = auto_0 * auto_1 - auto_1 * auto_2
C = auto_0**2 - auto_2**2
p = cross_1 * auto_0 - auto_1 * cross_0
q = cross_2 * auto_0 - auto_2 * cross_0
Det = A * C - B**2

h1 = (p * C - q * B) / Det
h2 = (q * A - p * B) / Det
h0 = (cross_0 - auto_1 * h1 - auto_2 * h2) / auto_0

print(f"Coefficients: h0 = {h0:.5f}, h1 = {h1:.5f}, h2 = {h2:.5f}")



# Filter input x[n] to get output y[n]
y = np.zeros(N)
for n in range(N):
    if n == 0:
        y[n] = h0 * x[n]
    elif n == 1:
        y[n] = h0 * x[n] + h1 * x[n-1]
    else:
        y[n] = h0 * x[n] + h1 * x[n-1] + h2 * x[n-2]
        
print(y)



"""
# Compute MMSE

variance = np.sum(d * d) / N
MMSE_theoretical = variance - (cross_0 * h0 + cross_1 * h1 + cross_2 * h2) / N
MMSE_empirical = np.mean((d - y)**2) # For comparison

print(f"MMSE_theoretical = {MMSE_theoretical:.5f}")
print(f"MMSE_empirical   = {MMSE_empirical:.5f}")

# Save output

with open("output.txt", "w", encoding="utf-8") as f:
    f.write("Filtered output: ")
    f.write(" ".join([f"{val:.1f}" for val in y]))
    f.write("\n")
    f.write(f"MMSE: {MMSE_theoretical:.1f}\n")
"""



# Plot results
"""
time_samples = N
t = np.arange(time_samples)
plt.figure(figsize=(10, 5))
plt.plot(t, d[:time_samples], 'b--', linewidth=1.5, label='Desired signal')
plt.plot(t, y[:time_samples], 'r-', linewidth=1.5, label='Filtered output')
plt.xlabel('Time samples')
plt.ylabel('Amplitude')
plt.title(f'Estimated h = [{h0:.5f}, {h1:.5f}, {h2:.5f}], '
          f'Theoretical MSE = {MMSE_theoretical:.5f}, Empirical MSE = {MMSE_empirical:.5f}')
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
"""

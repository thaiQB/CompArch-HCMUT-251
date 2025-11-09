#include <iostream>
#include <iomanip>

int main()
{
    std::cout<<"Hello World\n";
    
    float signal[10] = {0.3, 1.1, 0.6, -0.6, -0.8, -0.0, 0.8, 0.7, -0.7, -1.0};
    float desired[10] = {0.0, 1.0, 0.6, -0.6, -1.0, -0.0, 1.0, 0.6, -0.6, -1.0};
    float h[3] = {0.0, 0.0, 0.0};
    float r[3] = {0.0, 0.0, 0.0};
    
    for (int i = 0; i < 3; i++)
    {
        for (int j = 0; j < 10 - i; j++)
        {
            h[i] += (signal[j] * signal[j + i]);
            r[i] += (signal[j] * desired[j + i]);
        }
    }
    
    for (int i = 0; i < 3; i++)
    {
        std::cout << h[i] << " ";
    }
    
    std::cout << "\n";
    
    for (int i = 0; i < 3; i++)
    {
        std::cout << r[i] << " ";
    }

    // 5.28 1.88 -2.86
    // 5.26 1.96 -3.06
    return 0;
}
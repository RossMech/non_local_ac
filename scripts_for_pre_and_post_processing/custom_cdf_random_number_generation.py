# Usage of number generator, based on the custom pdf function utilizing the accept-reject sampling (the inversion transformation sampling didn't work due to the nature of LSW theory-CDF)
import numpy as np
import typing
import sys

def custom_cdf_random_number_generation(pdf_function: typing.Callable[[float],float],
                                        pdf_max_value: float,
                                        range_min: float,
                                        range_max: float,
                                        sample_size: int) -> np.typing.NDArray[np.float64]:

    # Check if sample size is positive
    if sample_size < 0:
        raise ValueError("Sample size should be positive")
    
    if range_max <= range_min:
        raise ValueError("Range maximal value should be bigger then range minimal value")

    # result vector initialization
    random_number_custom = np.zeros((sample_size,1))

    for i in range(sample_size):
        
        for j in range(1000):

            # Boolean variable to check if the correct value for acceptance-rejection is found
            check_bool = False

            # Check if convergence is not reached
            if j == 999:
                raise RuntimeError("The suitable number was not found in given iteration number!")

            x_approx_random = np.random.uniform(range_min,range_max,1)
            y_approx_random = np.random.uniform(0.0, pdf_max_value,1)

            # Calculate the pdf value at given x point
            pdf_value = pdf_function(x_approx_random)

            # Check the pdf values for validity
            if np.isnan(pdf_value).any():
                raise ValueError("PDF function is not correct. NaN is detected")
            
            if np.isinf(pdf_value).any():
                raise ValueError("PDF function is not correct. Infinity value is detected")
            
            if np.any(pdf_value < 0.0):
                raise ValueError("PDF function is not correct. Negative value detected")
            
            # If random value of y is less then approximated density, then it is correct
            if y_approx_random <= pdf_value:
                check_bool = True
                break

        # Accept correct value
        random_number_custom[i] = x_approx_random

    
    return random_number_custom
# Usage of number generator, based on the custom cdf function utilizing the inverse transform sampling (the cdf should be monotonously increasing and provided as lambda funciton)
import numpy as np
import typing
import sys

def custom_cdf_random_number_generation(cdf_function: typing.Callable[[float],float],
                                        range: np.typing.NDArray[np.float64],
                                        sample_size: int) -> np.typing.NDArray[np.float64]:

    # generate a vector of uniformly distributed values in range
    random_number_uniform = np.random.uniform(range[0],range[1],sample_size)

    # numerical epsilon
    numerical_epsilon = sys.float_info.epsilon

    # Calculation of the numerical values of the 
    x_grid = np.linspace(range[0]+numerical_epsilon,range[1]-numerical_epsilon,100)
    y_grid = cdf_function(x_grid)

    # Check for the NaN values
    if np.isnan(y_grid).any():
        raise ValueError("CDF contains an NaN value")
    
    if np.isinf(y_grid).any():
        raise ValueError("CDF contains Inf value")
    
    # Check for the value ranges
    if np.any((y_grid < 0.0) | (y_grid > 1.0)):
        raise ValueError("CDF contains values outside [0,1] range, which deviates from definition of CDF")
    
    # Check if CDF is monotonously increasing
    if np.any(np.diff(y_grid) < 0.0):
        raise ValueError("CDF is not monotonously increasing, therefore inversion of CDF is not possible")
    
    # Calculation of the random numbers from custom cdf, 
    random_number_custom = np.interp(random_number_uniform,y_grid,x_grid)
    
    return random_number_uniform
# Script for calculation of the elongation ratios from exodus files for different ranges of adaptivity

import sys
import os
import re
sys.path.append('/home/rnizinkovskyi/projects/benchmark_postprocessing/')

from postprocessing_functions import *

# files in directory
files_in_dir = os.listdir('.')

# create empty lists
domain_size_list = []
ratio_list = []
U_list = []

# pattern for search of number of elements retrival from filename
pattern = r'domain_size_(\d+)_exodus\.e'

# iterate over exodus files
for file in files_in_dir:
    if file.endswith('.e'):

        # Search for the pattern in the filename
        match = re.search(pattern, file)
        # retrive the number
        domain_size = int(match.group(1))
        # Add the current number of elements per width to a list of elements
        domain_size_list.append(domain_size)

        # Calculate the elongation ratios using custom subroutines
        moments = moments_of_inertia(file)
        section_parameters = calculate_section_parameters(moments)
        elongation_ratio = section_parameters['ratio'][0]
        ratio_list.append(elongation_ratio)

        # Get the values of U
        U = section_parameters['U'][0]
        U_list.append(U)

# Transform lists into numpy-arrays
domain_size_list = np.array(domain_size_list)
ratio_list = np.array(ratio_list)
U_list = np.array(U_list)

# Sort in ascending order for adaptivity
sorting_array = np.argsort(domain_size_list)
domain_size_list = domain_size_list[sorting_array]
ratio_list = ratio_list[sorting_array]
U_list = U_list[sorting_array]

# # merge vectors and save data into csv file
output_array = np.vstack((domain_size_list.T,ratio_list.T,U_list.T))
output_array = output_array.T
print(output_array)
np.savetxt('elongation_domain_size.csv',output_array, delimiter=',')
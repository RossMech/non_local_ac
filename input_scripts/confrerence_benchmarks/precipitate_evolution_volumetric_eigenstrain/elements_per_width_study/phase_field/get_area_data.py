# Script for calculation of the elongation ratios from exodus files for different ranges of adaptivity

import sys
import os
import re
sys.path.append('/home/rnizinkovskyi/projects/benchmark_postprocessing/')

from postprocessing_functions import *

# files in directory
files_in_dir = os.listdir('.')

# create empty lists
n_el_list = []
ratio_list = []
U_list = []

# pattern for search of number of elements retrival from filename
pattern = r'elements_(\d+)_exodus\.e'

# iterate over exodus files
for file in files_in_dir:
    if file.endswith('.e'):

        # Search for the pattern in the filename
        match = re.search(pattern, file)
        # retrive the number
        n_el = int(match.group(1))
        # Add the current number of elements per width to a list of elements
        n_el_list.append(n_el)

        # Calculate the elongation ratios using custom subroutines
        moments = moments_of_inertia(file)
        section_parameters = calculate_section_parameters(moments)
        elongation_ratio = section_parameters['ratio'][0]
        ratio_list.append(elongation_ratio)

        U = section_parameters['U'][0]
        U_list.append(U)



# Transform lists into numpy-arrays
n_el_list = np.array(n_el_list)
ratio_list = np.array(ratio_list)
U_list = np.array(U_list)

# Sort in ascending order for adaptivity
sorting_array = np.argsort(n_el_list)
n_el_list = n_el_list[sorting_array]
ratio_list = ratio_list[sorting_array]
U_list = U_list[sorting_array]

# # merge vectors and save data into csv file
output_array = np.vstack((n_el_list.T,ratio_list.T,U_list.T))
output_array = output_array.T
print(output_array)
np.savetxt('elongation_number_of_elements.csv',output_array, delimiter=',')
# Script for calculation of the elongation ratios from exodus files for different ranges of adaptivity

import sys
import os
sys.path.append('/home/rnizinkovskyi/projects/benchmark_postprocessing/')

from postprocessing_functions import *

# files in directory
files_in_dir = os.listdir('.')

# create empty lists
adaptivity_list = []
ratio_list = []
U_list = []

# iterate over exodus files
for file in files_in_dir:
    if file.endswith('.e'):
        # Calculate the elongation ratios using custom subroutines
        moments = moments_of_inertia(file)
        section_parameters = calculate_section_parameters(moments)
        elongation_ratio = section_parameters['ratio'][0]
        ratio_list.append(elongation_ratio)

        # list of U parameters
        U = section_parameters['U'][0]
        U_list.append(U)

        # Get the adaptivity level from filename
        adaptivity_level = int(file[17])
        adaptivity_list.append(adaptivity_level)

# Transform lists into numpy-arrays
adaptivity_list = np.array(adaptivity_list)
ratio_list = np.array(ratio_list)
U_list = np.array(U_list)

# Sort in ascending order for adaptivity
sorting_array = np.argsort(adaptivity_list)
adaptivity_list = adaptivity_list[sorting_array]
ratio_list = ratio_list[sorting_array]
U_list = U_list[sorting_array]

# merge vectors and save data into csv file
output_array = np.vstack((adaptivity_list.T,ratio_list.T,U_list.T))
output_array = output_array.T
print(output_array)
np.savetxt('elongation_adaptivity.csv',output_array, delimiter=',')
# Script for generation of spreadsheet with number of particles from the exodus files

import numpy as np
import os
import re
from get_the_number_of_particles_from_exodus import get_the_number_of_particles_from_exodus
import pandas

# folder containing the simulation result exodus files
input_path = '/home/rnizinkovskyi/projects/non_local_ac/results/precipitate_interaction/r_mean_13/R_parameter_0'

output_path = '/home/rnizinkovskyi/projects/non_local_ac/results/precipitate_interaction/number_of_particles/'
output_filename_prefix = 'r_mean_13_u_param_0'

number_of_particles_array = np.zeros((1,3))

# get the content of the global folder
path_content = os.listdir(input_path)

subdirectories_angle = []

for item in path_content:
    full_path_item = input_path + '/' + item
    
    if os.path.isdir(full_path_item) & ('theta' in item):
        match_theta = re.search(r'theta_(\d+)', item)
    
        theta_val = float(match_theta.group(1))

        subfolder_content = os.listdir(full_path_item)

        for subitem in subfolder_content:
            full_path_subfolder_item = full_path_item + '/' + subitem

            if os.path.isdir(full_path_subfolder_item) & ('a_' in subitem):
                match_r = re.search(r'a_(\d+)', subitem)
                
                r_str = match_r.group(1)

                if r_str.startswith('0'):
                    r_val = float('0.'+r_str[1:])
                else:
                    r_val = float(r_str)

                r_subfolder_content = os.listdir(full_path_subfolder_item)
                
                for simulation_files in r_subfolder_content:
                    if simulation_files.endswith('.e') & ('FeCu' in simulation_files):
                        full_path_exodus_file = full_path_subfolder_item + '/' + simulation_files
                        
                        # Run subroutine
                        number_of_particles = get_the_number_of_particles_from_exodus(full_path_exodus_file)

                        number_of_particles_array = np.vstack([number_of_particles_array,np.asarray([theta_val,r_val,number_of_particles])])

number_of_particles_array = number_of_particles_array[1:,:]

number_of_particles_dataframe = pandas.DataFrame(number_of_particles_array,columns=["theta","d_norm","number_of_particles"])

number_of_particles_dataframe.to_csv(output_path+output_filename_prefix+'_number_of_particles.csv',index=False)
# Script for generation of spreadsheet with initial, equilibrium and driving force

import os
import re
import pandas
import numpy as np

# folder contatining the position-dependent energy data
input_path = '/home/rnizinkovskyi/projects/fe__cu/Results/precipitate_interaction/B1_B1/r_6_ratio_1'

output_path = '/home/rnizinkovskyi/projects/non_local_ac/results/precipitate_interaction/energy_data/'
output_filename_prefix = 'r_mean_6_u_param_0'

initial_energy_array = np.zeros((1,3))
equilibrium_energy_array = np.zeros((1,3))
driving_force_array = np.zeros((1,3))

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

            if os.path.isdir(full_path_subfolder_item) & ('r_' in subitem):
                match_r = re.search(r'r_(\d+)', subitem)
                
                r_str = match_r.group(1)

                if r_str.startswith('0'):
                    r_val = float('0.'+r_str[1:])
                else:
                    r_val = float(r_str)

                r_subfolder_content = os.listdir(full_path_subfolder_item)
                
                for simulation_files in r_subfolder_content:
                    if simulation_files.endswith('.csv') & ('FeCu' in simulation_files):
                        full_path_csv_file = full_path_subfolder_item + '/' + simulation_files
                        # Open the csv file

                        current_database = pandas.read_csv(full_path_csv_file)
                        current_database = current_database.integral_of_energy
                        current_database = current_database.values

                        initial_energy = current_database[1]
                        equilibrium_energy = current_database[-1]
                        driving_force = initial_energy - equilibrium_energy


                        initial_energy_array = np.vstack((initial_energy_array,np.asarray([theta_val,r_val,initial_energy])))
                        equilibrium_energy_array = np.vstack((equilibrium_energy_array,np.asarray([theta_val,r_val,equilibrium_energy])))
                        driving_force_array = np.vstack((driving_force_array,np.asarray([theta_val,r_val,driving_force])))


initial_energy_array = initial_energy_array[2:,:]
equilibrium_energy_array = equilibrium_energy_array[2:,:]
driving_force_array = driving_force_array[2:,:]

initial_energy_dataframe = pandas.DataFrame(initial_energy_array, columns=["theta", "d_norm", "energy"])
equilibrium_energy_dataframe = pandas.DataFrame(equilibrium_energy_array, columns=["theta", "d_norm", "energy"])
driving_force_dataframe = pandas.DataFrame(driving_force_array, columns=["theta", "d_norm", "energy"])

initial_energy_dataframe.to_csv(output_path+output_filename_prefix+'_initial_energy.csv',index=False)
equilibrium_energy_dataframe.to_csv(output_path+output_filename_prefix+'_equilibrium_energy.csv',index=False)
driving_force_dataframe.to_csv(output_path+output_filename_prefix+'_driving_force.csv',index=False)
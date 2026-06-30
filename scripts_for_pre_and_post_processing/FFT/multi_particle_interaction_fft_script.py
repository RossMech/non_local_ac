import os
import re
from fft_transformation import handle_single_simulation_FFT
import numpy as np

# Discretization size vector
n_discr = [4576,4576,2944,2176,1504]

# Root folder, containing the simulation results
root_folder_path = '/media/rnizinkovskyi/Data_drive/Calculations_archive/Fe_Cu_Project/non_local_ac/precipitate_interaction/multi_particle_interaction/homogeneous_isotropic'

root_folder_content = os.scandir(root_folder_path)

# Iterate over the elements in root folder to find the "fraction" folders, containing simulations
for root_folder_entry in root_folder_content:
    
    root_folder_entry_name = root_folder_entry.name
    if root_folder_entry.is_dir() and "fraction" in root_folder_entry.name:

        # Get the fraction value from the name of the folder
        match = re.search(r"fraction_(\d+)", root_folder_entry_name)
        fraction_value = int(match.group(1))

        # Get the content of the folder, containing simulation results
        fraction_folder_content = os.scandir(root_folder_entry.path)

        # Discretization value 
        match fraction_value:
            case 1:
                n_fft = n_discr[0]
            case 2:
                n_fft = n_discr[1]
            case 5:
                n_fft = n_discr[2]
            case 10:
                n_fft = n_discr[3]
            case 20:
                n_fft = n_discr[4]

        # Check if the path for saving files exists and if not -> create directory
        save_path = root_folder_path + "/FFT/" + 'fraction_' + str(fraction_value) + '/'
        
        if not os.path.exists(save_path):
            os.makedirs(save_path, exist_ok=False)
        
        # Get the exodus files of the simulations
        for fraction_folder_entry in fraction_folder_content:
            file_name = fraction_folder_entry.name
            file_path = fraction_folder_entry.path
            
            # Check if the file has a right exodus extension and perform the post-processing
            if file_name.endswith('.e'):
                print('Working on FFT for following simulation:')
                print('Fraction:',fraction_value)
                print(file_name)
                output_array, q, time_step_values = handle_single_simulation_FFT(file_path,n_fft,deformation_bool=True)

                # Save corresponding files
                np.save(save_path+file_name[:-2],output_array)
                np.save(save_path+file_name[:-2]+'_q',q)
                np.save(save_path+file_name[:-2]+'_time_steps',time_step_values)
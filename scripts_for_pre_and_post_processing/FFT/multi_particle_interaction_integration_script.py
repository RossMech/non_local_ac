import os
import re
from integration_over_q import handle_integration_whole_simulation
import numpy as np

# Vector for interpolation point number
n_theta = [4576,4576,2944,2176,1504]
n_q = [4576,4576,2944,2176,1504]

# q cutoff value for the integration
q_cutoff = float(np.pi/6)

# Iterate over the elements in root folder to find the "fraction" folders, containing simulations
# Root folder with FFT data
root_folder_path = '/media/rnizinkovskyi/internal_hdd/Calculations_archive/Fe_Cu_Project/non_local_ac/precipitate_interaction/multi_particle_interaction/homogeneous_isotropic/FFT'

root_folder_content = os.scandir(root_folder_path)

# The pattern for file names
pattern = re.compile(r"simulation_output_(\d+)\.npy$")

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
        n_q_map = {1: n_q[0], 2: n_q[1], 5: n_q[2], 10: n_q[3], 20: n_q[4]}
        n_q_value = n_q_map.get(fraction_value)
        n_theta_map = {1: n_theta[0], 2: n_theta[1], 5: n_theta[2], 10: n_theta[3], 20: n_theta[4]}
        n_theta_value = n_theta_map.get(fraction_value)

        # Check if the path for saving files exists and if not -> create directory
        save_path = root_folder_path + '/fraction_' + str(fraction_value) + '/'
        
        if not os.path.exists(save_path):
            os.makedirs(save_path, exist_ok=False)
        
        # Get the corresponding npy files containing the scatter profiles
        for fraction_folder_entry in fraction_folder_content:
            file_name = fraction_folder_entry.name
            file_path = fraction_folder_entry.path

            file_match = pattern.match(file_name)

            if match:
                # Get the number of simulation
                simulation_number = int(match.group(1))

                print('Working on integration of following pattern:')
                print('Fraction:',fraction_value)
                print(file_name)

                # read the scatter and wavelength data
                scatter_data_path = root_folder_entry.path + '/' + 'simulation_output_' + str(simulation_number)
                scatter_vector_path = scatter_data_path + '_q'
                scatter_data_path = scatter_data_path + '.npy'
                scatter_vector_path = scatter_vector_path + '.npy'

                # Read the numpy data
                scatter_data = np.load(scatter_data_path)
                scatter_vector = np.load(scatter_vector_path)

                # Getting the integrated data
                integrated_data, theta_vector = handle_integration_whole_simulation(scatter_data,
                                                                                    scatter_vector,
                                                                                    n_q_value,
                                                                                    n_theta_value,
                                                                                    q_cutoff)
                
                # Saving the integrated data
                np.save(save_path+'integrated_FFT_profile_'+str(simulation_number)+'.npy',integrated_data)
                np.save(save_path+'theta_vector_'+str(simulation_number)+'.npy',theta_vector)
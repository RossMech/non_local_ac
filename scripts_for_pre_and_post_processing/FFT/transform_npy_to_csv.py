import numpy as np

folder = '/media/rnizinkovskyi/internal_hdd/Calculations_archive/Fe_Cu_Project/non_local_ac/precipitate_interaction/multi_particle_interaction/no_elasticity/FFT/fraction_20'

output_file_name = 'integrated_FFT_profile_3.npy'
theta_file_name = 'theta_vector_3.npy'

output_file_name = folder + '/' + output_file_name
theta_file_name = folder + '/' + theta_file_name

output_data = np.load(output_file_name)
theta_data = np.load(theta_file_name)

output_data = np.squeeze(output_data[:,-1])

np.savetxt(output_file_name[:-3]+'csv',output_data)
np.savetxt(theta_file_name[:-3]+'csv',theta_data)
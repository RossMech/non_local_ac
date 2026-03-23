from polar_heatmap import polar_heatmap
import pandas as pd
import numpy as np

folder_path = '/home/rnizinkovskyi/projects/non_local_ac/results/precipitate_interaction/energy_data/'
file_name = 'r_mean_8_u_param_05_initial_energy.csv'
file_name_2 = 'r_mean_8_u_param_05_equilibrium_energy.csv'

energy_eq = pd.read_csv(folder_path+file_name_2)
energy_eq = energy_eq.energy.values
print(np.mean(energy_eq))
print(np.min(energy_eq))
print(np.max(energy_eq))
energy_eq = np.mean(energy_eq)


full_path = folder_path + file_name

import_dataset = pd.read_csv(full_path)

theta_vect = import_dataset.theta.values
r_vect = import_dataset.d_norm.values
energy_vect = import_dataset.energy.values - energy_eq

theta_vect = np.deg2rad(theta_vect)

fig, ax = polar_heatmap(theta_vect,r_vect,energy_vect)

fig.savefig('/home/rnizinkovskyi/projects/non_local_ac/scripts_for_pre_and_post_processing/test.png')
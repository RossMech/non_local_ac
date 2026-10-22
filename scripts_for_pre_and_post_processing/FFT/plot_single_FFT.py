import numpy as np
import matplotlib.pyplot as plt

data_folder = '/media/rnizinkovskyi/internal_hdd/Calculations_archive/Fe_Cu_Project/non_local_ac/precipitate_interaction/multi_particle_interaction/Fe_Cu_parameters/FFT/fraction_20/'
file_name = 'simulation_output_1.npy'

scattering_data = np.load(data_folder+file_name)

fig, ax = plt.subplots()

ax.contourf(np.log(scattering_data[:,:,-1]))

plt.savefig("scattering_plot.png", dpi=300)
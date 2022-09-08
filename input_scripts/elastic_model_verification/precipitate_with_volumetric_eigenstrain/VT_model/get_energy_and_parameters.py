# script for the incorporation of energies from simulations of 1d serial connections
# with different heterogenity levels and diffuse interface widthes into one csv file

import os
import numpy as np
from get_energy_from_csv import get_energy_from_csv

path = '.'
path_content = os.listdir(path)

subdirectories = []

for items in path_content:
    if os.path.isdir(items):
        subdirectories.append(items)

# array of heterogenities
heterogenities = np.array([1, 2, 5, 10, 20])
diffuse_widthes = np.array([0.2, 0.1, 0.05, 0.025])

# create array with outputs are calculated
output_energy = np.asarray([0, 0, 0])

for directory in subdirectories:

    # get content of subfolder
    files = os.listdir(path + '/' + directory)

    # get the heterogenity_name of the applied stress from directory name
    for heterogenity in heterogenities:
        char_len = len(str(heterogenity))
        if str(heterogenity) == directory[-char_len:]:
            heterogenity_dir = heterogenity

    for file_out in files:

        full_path = path + '/' + directory + '/' + file_out

        if file_out.endswith('.csv'):

            # get the diffusive width from file name
            for diffuse_width in diffuse_widthes:
                diffuse_width_str = str(diffuse_width)
                diffuse_width_str = diffuse_width_str[0]+diffuse_width_str[2:]

                if diffuse_width_str in full_path:
                    diffuse_width_file = diffuse_width

                energy = get_energy_from_csv(full_path)

            output_energy = np.vstack([output_energy, [heterogenity_dir, diffuse_width_file, energy]])

np.savetxt('precipitate_with_volumetric_eigenstrain_VT_model_elastic_energy.csv',output_energy)

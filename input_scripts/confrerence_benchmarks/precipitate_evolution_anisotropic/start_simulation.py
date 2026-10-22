import os
import re
import time
import pandas as pd

# Path for the initial folder
path = '.'

# Path for an MOOSE app
app_path = '/home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt'

# Threshold for an energy equilibrium
delta_G = 1.0e-8

# Number of processors
n_p = 16

# heterogeneity vector
heterogeneity_vector = [0.7]
heterogeneity_string_vector = [str(x).replace('.', '') for x in heterogeneity_vector]

# relative width vector 
rw_vector = [0.2, 0.1, 0.05]
rw_string_vector = [str(x).replace('.', '') for x in rw_vector] 

# Get a content of the folder
main_folder_content = os.listdir(path)

# pattern of the folder name for heterogeneity
pattern_heterogeneity = re.compile(r'^heterogeneity_\d\d$')

simulation_time_db = []

for method in main_folder_content:
    if os.path.isdir(method):
        method_subfolder = path + '/' + method
        method_content = os.listdir(method_subfolder)
        
        # Subfolders in the method folder
        heterogeneity_subfolders = [d for d in method_content if os.path.isdir(os.path.join(method_subfolder, d))]

        for heterogeneity_subfolder in heterogeneity_subfolders:
            heterogeneity_subfolder_path = os.path.join(method_subfolder,heterogeneity_subfolder)

            heterogeneity_value = 0.0
            match = re.match(r'^heterogeneity_(\d)(\d)$', heterogeneity_subfolder)
            if match:
                heterogeneity_value = float(f"{match.group(1)}.{match.group(2)}")

            if heterogeneity_value!=0.0:
                for i, rw_value in enumerate(rw_vector):
                    if method == 'khachaturyan' and heterogeneity_value == 0.7 and rw_value == 0.1:
                    #if heterogeneity_value == 0.9:
                        execution_string = 'mpiexec -n ' + str(n_p) + ' ' + app_path + ' ' + \
                            '-i ' + path + '/' + method + '/start_script.i' + ' heterogeinity=' + str(heterogeneity_value) + \
                            ' width_ratio=' + str(rw_value) + ' Outputs/exodus/file_base=' + heterogeneity_subfolder_path + \
                            '/width_' + rw_string_vector[i] + ' Outputs/csv/file_base=' + heterogeneity_subfolder_path + '/width_' + rw_string_vector[i] \
                        
                        start_time = time.time()

                        os.system(execution_string)

                        end_time = time.time()
                        simulation_time = end_time - start_time

                        simulation_time_db.append({
                                "method": method,
                                "heterogeneity": heterogeneity_value,
                                "width_ratio": rw_value,
                                "simulation_time" : simulation_time
                                })

df = pd.DataFrame(simulation_time_db)
df.to_csv('calculation_time.csv')

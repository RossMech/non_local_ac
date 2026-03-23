# script for running all simulations of multi-particle interaction in Fe-Cu system, use it just for the first simulation, as it does not search for existing simulation files
import os
import pathlib
import re
import subprocess
import pandas as pd

# base name for output files (exodus and csv)
file_base = 'output_simulation'

# full path to moose app 
app_path = '/home/rnizinkovskyi/projects/non_local_ac/non_local_ac-opt'

# get the fraction-domain size csv
domain_size_database = pd.read_csv('fraction_domain_size.csv')

# Get the current folder
current_folder_path = pathlib.Path().resolve()

# get the content of the folder
current_folder_content = os.listdir(current_folder_path)


# iterate over the subfolders of different contents
for subfolder in current_folder_content:
  # Iterate over files to get all csv files needed for simulations
  subfolder_full_path = str(current_folder_path) + '/' + subfolder
  # check if element is folder and if it contains the fraction data by name
  if os.path.isdir(subfolder_full_path) & ('fraction' in subfolder):
    fraction_value = re.match(r'fraction_(\d+)',subfolder)
    fraction_value = int(fraction_value.group(1))

    domain_size = domain_size_database.loc[domain_size_database['fraction'] == fraction_value, 'domain_size'].values[0]
    
    subfolder_content = os.listdir(subfolder_full_path)

    # Check if the simulation exists and is finished (number of the precipitates on the last step is smaller then 11)
    finished_simulations = []
    for file in subfolder_content:
      if file.endswith('.csv') & ('simulation_output' in file):
        file_full_path = str(subfolder_full_path) + '/' + file
        simulation_data = pd.read_csv(file_full_path)
        simulation_data = simulation_data.tail(1)
        particle_number = simulation_data['particle_number'].values[0].item()
        conf_number = re.match(r'simulation_output_(\d+).csv',file)
        conf_number = conf_number.group(1)
        conf_number = int(conf_number)
        # simulations are terminated when number of particles is smaller then 11. Checking is needed if it is not zero, because first output in csv is zero
        if (particle_number != 0) & (particle_number < 11):
          finished_simulations.append(conf_number)
    
    for file in subfolder_content:
      # check just for files, containing particle configurations, based on filename
     if file.endswith('.csv') & ('particle_configuration' in file):
       # get the full path of the mentioned csv files
       file_full_path = str(subfolder_full_path) + '/' + file
       # use regular expression to get the number of configuration
       conf_number = re.match(r'particle_configuration_(\d+)\.csv', file)
       conf_number = conf_number.group(1)
       # compose execution string to control simulation parameters
       execution_string = 'mpiexec -n 16' + ' ' + app_path + ' ' + \
                           '-i' + ' ' + str(current_folder_path) + '/master_script.i' + \
                           ' Variables/eta/InitialCondition/file_name=' + subfolder_full_path + '/' + file + \
                           ' Outputs/exodus/file_base=' + subfolder_full_path + '/' + 'simulation_output_' + str(conf_number) + \
                           ' Outputs/csv/file_base=' + subfolder_full_path + '/' + 'simulation_output_' + str(conf_number) + \
                           ' domain_size=' + str(domain_size)
       if int(conf_number) in finished_simulations:
         continue
       
       print('configuration number =',conf_number)
       print('fraction =',fraction_value)
       os.system(execution_string)

import os
import pandas as pd

# Path for the initial folder
path = '.'

# Threshold for an energy equilibrium
delta_G = 1.0e-8

# Number of processors
n_p = 16

# Get a content of the folder
main_folder_content = os.listdir(path)

for method in main_folder_content:
    
    if os.path.isdir(method):
        method_subfolder = path + '/' + method
        method_content = os.listdir(method_subfolder)

        for heterogeinity in method_content:
            heterogeinity_subfolder = method_subfolder + '/' + heterogeinity
            
            if os.path.isdir(heterogeinity_subfolder):
                heterogeinity_content = os.listdir(heterogeinity_subfolder)
                
                # Look for the input scripts
                for scriptfile in heterogeinity_content:
                    if scriptfile.endswith('.i'):
                        
                        # Check if the simulation was done (.csv file and .e files exist and the equilibrium is achieved)
                        # Check for csv
                        csv_name = scriptfile[:-2] + '_csv.csv'
                        equilibrium_bool = False
                        if csv_name in heterogeinity_content:
                            # full name for read
                            csv_full_name = heterogeinity_subfolder + '/' + csv_name
                            # read data from file
                            pandas_data = pd.read_csv(csv_full_name)
                            # restrict dataframe to the last timepoint
                            pandas_data = pandas_data.tail(1)
                            # get the data just from the change in energy
                            pandas_data = pandas_data['delta_f']
                            # transform the data into a float type
                            pandas_data = float(pandas_data.iloc[0])
                            
                            # Check if the equilibrium was reached in previous simulations
                            equilibrium_bool = abs(pandas_data) < delta_G

                        # Check if the exodus file exists
                        exodus_bool = False
                        if equilibrium_bool:
                            exodus_name = scriptfile[:-2] + '_exodus.e'
                            exodus_bool = exodus_name in heterogeinity_content

                        # start the simulation
                        if not exodus_bool:
                            script_full_path = heterogeinity_subfolder + '/' + scriptfile
                            execution_string = 'mpirun -n ' + str(n_p) + ' ../../../../non_local_ac-opt ' + '-i ' + script_full_path
                            os.system(execution_string)

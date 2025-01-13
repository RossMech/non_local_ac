import os
import sys
import pandas as pd
import math

# adding Folder_2 to the system path
sys.path.insert(0, '/home/rnizinkovskyi/projects/benchmark_postprocessing')

from postprocessing_functions import *
from nonlinear_optimization import *

# Path for the initial folder
path = '.'

# Threshold for an energy equilibrium
delta_G = 1.0e-8

# Get a content of the folder
main_folder_content = os.listdir(path)

# empty lists to store parameters
method_vector = []
heterogeneity_vector = []
diff_width_input_vector = []

total_energy_vector = []
elastic_energy_vector = []
interfacial_energy_vector = []

U_vector = []
diffusional_width_simulation_vector = []

area_vector = []

normalized_total_energy_simulation_vector = []
normalized_total_energy_analytic_vector = []

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
                    
                        csv_name = scriptfile[:-2] + '_csv.csv'
                        exodus_name = scriptfile[:-2] + '_exodus.e'
                        equilibrium_bool = False
                        if (csv_name in heterogeinity_content) and (exodus_name in heterogeinity_content):
                            # full name for read
                            csv_full_name = heterogeinity_subfolder + '/' + csv_name
                            exodus_full_name = heterogeinity_subfolder + '/' + exodus_name
                            
                            # read data from file
                            pandas_data = pd.read_csv(csv_full_name)
                            # restrict dataframe to the last timepoint
                            pandas_data = pandas_data.tail(1)
                            # getting the last step's delta_f
                            last_delta_F = pandas_data['delta_f']
                            # transform the data into a float type
                            last_delta_F = float(last_delta_F.iloc[0])

                            # Check if the equilibrium was reached in previous simulations
                            equilibrium_bool = abs(last_delta_F) < delta_G

                        if equilibrium_bool:
                            # get the name of the interpolation method from directory name
                            method_vector.append(method)

                            # get the heterogeinity from the folder name
                            heterogeinity_value = heterogeinity[-2:]
                            heterogeinity_value = heterogeinity_value[0] + '.' + heterogeinity_value[1]
                            heterogeinity_value = float(heterogeinity_value)
                            heterogeneity_vector.append(heterogeinity_value)

                            # interfacial width input
                            diff_width_input = scriptfile[6:-2]
                            diff_width_input = diff_width_input[0] + '.' + diff_width_input[1:]
                            diff_width_input = float(diff_width_input)
                            diff_width_input_vector.append(diff_width_input)

                            # get the values of energy contributions from csv file
                            interfacial_energy = pandas_data['f_interf']
                            # transform the data into a float type
                            interfacial_energy = float(interfacial_energy.iloc[0])
                            # append the value to vector
                            interfacial_energy_vector.append(interfacial_energy)

                            elastic_energy = pandas_data['f_elast']
                            # transform the data into a float type
                            elastic_energy = float(elastic_energy.iloc[0])
                            # append the value to vector
                            elastic_energy_vector.append(elastic_energy)

                            total_energy = elastic_energy + interfacial_energy
                            total_energy_vector.append(total_energy) 

                            # get the diffusional width
                            diffusional_width_simulation = calculate_diffusional_width(exodus_full_name)
                            
                            # get the precipitate's area
                            precipitate_area = pandas_data['eta_vol']
                            # transform the data into a float type
                            precipitate_area = float(precipitate_area.iloc[0])
                            # calculate equivalent radius based on the area
                            equivalent_radius = np.sqrt(2*precipitate_area/math.pi)
                            area_vector.append(precipitate_area)
                            
                            # normalize the diffusional width
                            diffusional_width_simulation = diffusional_width_simulation / equivalent_radius
                            diffusional_width_simulation_vector.append(float(diffusional_width_simulation[0]))

                            # calculate moments of inertia
                            moments = moments_of_inertia(exodus_full_name)
                            section_parameters = calculate_section_parameters(moments)
                            U = section_parameters["U"]
                            U = U[0]
                            U_vector.append(U)


                            L = equivalent_radius / 10

                            normalized_total_energy_analytic = energy_functional_normalized(L,0.2,calculate_kappa(0.3),heterogeinity_value,0.3)
                            normalized_total_energy_analytic_vector.append(normalized_total_energy_analytic)
                            normalized_total_energy_simulation = total_energy / math.sqrt(math.pi*precipitate_area)*2
                            normalized_total_energy_simulation_vector.append(normalized_total_energy_simulation)


df = pd.DataFrame({
    'Method' : method_vector,
    'Heterogeneity' : heterogeneity_vector,
    'DiffusionalWidthInput' : diff_width_input_vector,
    'TotalEnergy' : total_energy_vector,
    'ElasticEnergy' : elastic_energy_vector,
    'InterfacialEnergy' : interfacial_energy_vector,
    'U' : U_vector,
    'DiffusionalWidth' : diff_width_input_vector,
    'Area' : area_vector,
    'NormalizedEnergyAnalytic' : normalized_total_energy_analytic_vector,
    'NormalizedEnergySimulation' : normalized_total_energy_simulation_vector
})

print(df)

df.to_csv('postprocessing_data.csv')
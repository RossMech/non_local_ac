# The script to generate stochastic multi-particle data for moose simulations
from generate_particles_LSW_distribution import generate_particles_LSW_distribution
import pandas as pd

# Name of the folder, where the file with data should be stored
folder_path = '/home/rnizinkovskyi/projects/non_local_ac/input_scripts/precipitate_interaction/multi_particle_interaction/Fe_Cu_parameters/fraction_20/'

# file name for the file with circle data
file_name = 'particle_configuration_3.csv'

full_path = folder_path + file_name
################################
# Parameters for the simulation
# Number of particles
number_particles = 50

# Fraction of the secondary phase
phase_fraction = 0.2

# Mean radius
r_mean = 8

# diffusional width
delta = 0.005

# call the particle generator
particle_data = generate_particles_LSW_distribution(number_particles,phase_fraction,r_mean,delta)

particle_data.to_csv(full_path, index=False, sep="\t")
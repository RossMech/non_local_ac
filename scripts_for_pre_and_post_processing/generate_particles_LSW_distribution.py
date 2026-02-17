# Function for generation of the circula particle's characteristics (size and position) for MOOSE simulations
# Distribution of sizes is controlled by LSW distribution
# Inputs for the initialization:
# number_of_particles - number of generated particles
# phase_fraction - fraction of precipitate's phase
# R_mean - mean size of the particle

import numpy as np
import sys
import matplotlib.pyplot as plt
from custom_cdf_random_number_generation import custom_cdf_random_number_generation
from particle_position_generation import particle_position_generation

def generate_particles_LSW_distribution(number_of_particles: int,
                                        phase_fraction: float,
                                        mean_radius: float,
                                        diffusion_width: float) -> np.typing.NDArray[np.float64]:

    # PDF function for the LSW particle distribution
    pdf_LSW = lambda rho: 81/(2**(5/3)*np.exp(1)) * rho**2 * np.exp(3/(2*rho-3))/((rho+3)**(7/3)*(1.5-rho)**(11/3))

    # Get normalized particle sizes (rho=R/mean(R)), based on LSW distribution
    particle_radii = custom_cdf_random_number_generation(pdf_LSW,2.16,0.0,1.5,number_of_particles)

    # Multiply the precipitate radii by the mean value
    particle_radii = particle_radii * mean_radius

    # Squeeze the array to ensure it is 1D
    particle_radii = np.squeeze(particle_radii)

    # get the positions of particles
    particle_positions = particle_position_generation(particle_radii,phase_fraction,diffusion_width)

    # Joining the data for positions and radii
    particle_data = np.vstack([particle_positions,particle_radii])
    particle_data = np.transpose(particle_data)

    return particle_data

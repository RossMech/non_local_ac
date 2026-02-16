# Function to generate the random position of non-overlapping circular particles in 2D
# Inputs:
# r_vect - numpy array containing radius sizes of the particles
# phase_fraction - fraction of secondary particles (real positive number < 1.0)
# delta - relative interfacial width for phase-field simulation (width/mean_radius)

import numpy as np

def particle_position_generation(r_vect: np.typing.NDArray[np.float64],
                                 phase_fraction: float,
                                 delta: float,
                                 max_iter=1000) -> np.typing.NDArray[np.float64]:
    
    # Check the inputs
    if np.isnan(r_vect).any():
        raise ValueError("R_vect contains an NaN value")
    
    if np.isinf(r_vect).any():
        raise ValueError("R_vect contains Inf value")
    
    if np.any(r_vect < 0.0):
        raise ValueError('R_vect could not containg negative values')
    
    if r_vect.ndim != 1:
        raise ValueError('The R_vect should be one-dimensional array')
    
    if (phase_fraction < 0.0) | (phase_fraction > 1.0):
        raise ValueError('Phase fraction should lie between zero and one') 
    
    if (delta < 0.0) | (delta > 1.0):
        raise ValueError('Relative diffusional width should lie between zero and 1')
    
    # Calculate nominal diffusional width, based on mean radius
    r_mean = np.mean(r_vect)
    diff_width = delta * r_mean

    # Modify the Radii vector due to the influence of diffusional width
    r_mod = r_vect + diff_width

    number_of_particles = r_mod.size

    # Domain size calculation
    domain_size = np.sqrt(np.pi*np.sum(np.square(r_mod))/phase_fraction)
    domain_limits = np.array([-0.5*domain_size, 0.5*domain_size])

    # Generation of initial pool of points
    x_pos = np.random.uniform(domain_limits[0]+r_mod[0],domain_limits[1]-r_mod[0],1)
    y_pos = np.random.uniform(domain_limits[0]+r_mod[0],domain_limits[1]-r_mod[0],1)

    # Monte-Carlo simulation for initial particle placing in simulation
    for i in range(1,number_of_particles,1):

        # Marker if the position is found
        error_free = False
        
        for j in range(max_iter):
            # Generate approximation for a particle 
            x_approx = np.random.uniform(domain_limits[0]+r_mod[i],domain_limits[1]-r_mod[i],1)
            y_approx = np.random.uniform(domain_limits[0]+r_mod[i],domain_limits[1]-r_mod[i],1)

            # Check if the particle collides with other particles from list
            
            # Calculate the distances between centers of circles
            distance_map = np.sqrt(np.square(x_pos - x_approx) + np.square(y_pos - y_approx))
            distance_map = distance_map - r_mod[i] - r_mod[:i]


            # Check if particles are colliding
            error_free = np.all(distance_map > 0.0)

            # If the last iteration cycle is reached - Runtime error, so false values are not taken
            if j == max_iter-1:
                raise RuntimeError("The Monte Carlo solution was not found in given iterations number")

            # If there is no conflict with previous values, then the current approximation could be taken
            if error_free:
                break

        # If error free approximation was found, then
        x_pos = np.append(x_pos,x_approx)
        y_pos = np.append(y_pos,y_approx)

    return np.stack((x_pos,y_pos))
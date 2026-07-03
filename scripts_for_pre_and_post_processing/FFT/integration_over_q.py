# Python code to analyze the orientation dependencies in FFT spectra to study the alignment of the particles
import numpy as np 
import matplotlib.pyplot as plt
from scipy.interpolate import RBFInterpolator, LinearNDInterpolator

def integrate_scattering_data_over_q(scatter_input:np.typing.NDArray[np.float64],
                                     q_input:np.typing.NDArray[np.float64],
                                     n_q:int = 200,
                                     n_theta:int = 200,
                                     q_cutoff:float = float(np.pi/6)) -> tuple[np.typing.NDArray[np.float64], np.typing.NDArray[np.float64]]:
    
    # Generate the vector of q and theta values
    q_vector = np.linspace(0.0, q_cutoff, n_q)
    theta_vector = np.linspace(-np.pi, np.pi, n_theta)
    
    # Generate a mesh based on the vectors
    q_mesh, theta_mesh = np.meshgrid(q_vector,theta_vector)

    # Transform the q_mesh and theta_mesh into the q_x and q_y
    q_x_interpolation = q_mesh * np.cos(theta_mesh)
    q_y_interpolation = q_mesh * np.sin(theta_mesh)

    # generating mesh of q-vector values from input file for further flattening and input into the interpolator
    q_mesh_x, q_mesh_y = np.meshgrid(q_input,q_input)

    # Flattening the vectors for interpolation function
    q_x_flat = q_mesh_x.ravel()
    q_y_flat = q_mesh_y.ravel()
    scattering_data_flat = scatter_input.ravel()
    points = np.column_stack((q_x_flat,q_y_flat))

    # Interpolator declaration
    linear_interpolator = LinearNDInterpolator(points,scattering_data_flat, fill_value=np.nan)

    # Interpolation using linear interpolator
    scatter_data_interpolated = linear_interpolator(q_x_interpolation,q_y_interpolation)

    # Detect NaN values due to the point being outside of the range of the original data
    mask = np.isnan(scatter_data_interpolated)

    # If there are any NaN values, the RBF interpolator is used to fill the place (as extrapolator)
    if mask.any():
        rbf_interpolator = RBFInterpolator(points,
                                       scattering_data_flat,
                                       kernel='linear',
                                       smoothing=0.0,
                                       neighbors=50)
    
        points_nan = np.column_stack((q_x_interpolation[mask],q_y_interpolation[mask]))
        scatter_data_interpolated[mask] = rbf_interpolator(points_nan)

    # Get the integrated profile by integration in q space for theta=const
    integrated_profile = np.trapezoid(scatter_data_interpolated,x=q_vector,axis=1)

    return integrated_profile, theta_vector

def handle_integration_whole_simulation(scatter_data:np.typing.NDArray[np.float64],
                                        q_input:np.typing.NDArray[np.float64],
                                        n_q:int = 200,
                                        n_theta:int = 200,
                                        q_cutoff:float = float(np.pi/6)) -> tuple[np.typingNDArray[np.float64],np.typingNDArray[np.float64]]:
    
    # Number of timesteps
    n_steps = scatter_data.shape[-1]
    
    # Create the array for the output with integrated scatter data (2d array, with 1st dimension being the single plot and 2nd dimension are time steps)
    integrated_array = np.zeros((n_theta,n_steps))

    # Iterate over the timesteps to get the whole simulation
    for time_step in np.arange(n_steps):
        print('Working on time step:',time_step,'/',n_steps)
        integrated_array[:,time_step], theta_vector = integrate_scattering_data_over_q(scatter_data[:,:,time_step],
                                                                         q_input,
                                                                         n_q,
                                                                         n_theta,
                                                                         q_cutoff)

    return integrated_array, theta_vector
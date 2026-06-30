# Python code to analyze the orientation dependencies in FFT spectra to study the alignment of the particles
import numpy as np 
import matplotlib.pyplot as plt
from scipy.interpolate import RBFInterpolator, LinearNDInterpolator

# Import data
scattering_data = np.log(np.load('simulation_output_1.npy'))
q_x_vector = np.load('simulation_output_1_q.npy')

# Number of discretization points in q and theta space
n_q = 400
n_theta = 400

# Generate vectors for discretized values
q_vector = np.linspace(0.0, np.pi/6, n_q)
theta_vector = np.linspace(-np.pi, np.pi, n_theta)

# Generate a mesh based on the vectors
q_mesh, theta_mesh = np.meshgrid(q_vector,theta_vector)

# generating mesh of q-vector values for further flattening and input into the interpolator
q_mesh_x, q_mesh_y = np.meshgrid(q_x_vector,q_x_vector)

# Flattening the vectors for interpolation function
q_x_flat = q_mesh_x.ravel()
q_y_flat = q_mesh_y.ravel()
scattering_data_flat = scattering_data[:,:,-1].ravel()

points = np.column_stack((q_x_flat,q_y_flat))

# Interpolators
linear_interpolator = LinearNDInterpolator(points,scattering_data_flat, fill_value=np.nan)

# Transform the q_mesh and theta_mesh into the q_x and q_y
q_x_interpolation = q_mesh * np.cos(theta_mesh)
q_y_interpolation = q_mesh * np.sin(theta_mesh)

scatter_data_interpolated = linear_interpolator(q_x_interpolation,q_y_interpolation)

mask = np.isnan(scatter_data_interpolated)

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

fig, ax = plt.subplots()
ax.plot(theta_vector,integrated_profile)
ax.set_xlabel(r'$\theta$, rad')
ax.set_ylabel(r'$\log(I)$')
fig.savefig('output_integrated.png', dpi=300, bbox_inches='tight')
plt.close(fig)

fig, ax = plt.subplots()
ax.contourf(q_mesh, theta_mesh, scatter_data_interpolated)
fig.savefig('output_interpolated.png',dpi=300,bbox_inches='tight')

def integrate_scattering_data_over_q(scatter_input:np.typing.NDArray[np.float64],
                                     q_input:np.typing.NDArray[np.float64],
                                     n_q:int = 200,
                                     n_theta:int = 200,
                                     q_cutoff:float = float(np.pi/6)) -> np.typing.NDArray[np.float64], np.typing.NDArray[np.float64]:
    
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
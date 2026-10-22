# Python code to analyze the orientation dependencies in FFT spectra to study the alignment of the particles
import numpy as np
from scipy.interpolate import RegularGridInterpolator, RBFInterpolator
import time


def integrate_scattering_data_over_q(
    scatter_input: np.typing.NDArray[np.float64],
    q_input: np.typing.NDArray[np.float64],
    n_q: int = 200,
    n_theta: int = 200,
    q_cutoff: float = float(np.pi / 6)
) -> tuple[np.typing.NDArray[np.float64], np.typing.NDArray[np.float64]]:

    # Generate q and theta vectors
    q_vector = np.linspace(0.0, q_cutoff, n_q)
    theta_vector = np.linspace(-np.pi, np.pi, n_theta)

    # Polar interpolation grid
    cos_theta = np.cos(theta_vector)
    sin_theta = np.sin(theta_vector)

    q_x_interpolation = cos_theta[:, None] * q_vector
    q_y_interpolation = sin_theta[:, None] * q_vector

    # ------------------------------------------------------------------
    # RegularGridInterpolator
    # ------------------------------------------------------------------

    linear_interpolator = RegularGridInterpolator(
        (q_input, q_input),
        scatter_input,
        method="linear",
        bounds_error=False,
        fill_value=np.nan,
    )

    # Create query points
    query_points = np.empty(
        (q_x_interpolation.size, 2),
        dtype=q_input.dtype
    )

    query_points[:, 0] = q_x_interpolation.ravel()
    query_points[:, 1] = q_y_interpolation.ravel()

    # Perform interpolation
    scatter_data_interpolated = linear_interpolator(query_points)
    scatter_data_interpolated = scatter_data_interpolated.reshape(
        q_x_interpolation.shape
    )

    # ------------------------------------------------------------------
    # Fill outside-grid values with RBF extrapolation
    # ------------------------------------------------------------------

    mask = np.isnan(scatter_data_interpolated)

    if np.any(mask):

        n = q_input.size

        # Build point cloud only if needed
        points = np.empty((n * n, 2), dtype=q_input.dtype)
        points[:, 0] = np.repeat(q_input, n)
        points[:, 1] = np.tile(q_input, n)

        values = scatter_input.ravel()

        rbf_interpolator = RBFInterpolator(
            points,
            values,
            kernel="linear",
            smoothing=0.0,
            neighbors=50,
        )

        query_nan = np.empty((mask.sum(), 2), dtype=q_input.dtype)
        query_nan[:, 0] = q_x_interpolation[mask]
        query_nan[:, 1] = q_y_interpolation[mask]

        scatter_data_interpolated[mask] = rbf_interpolator(query_nan)

    # ------------------------------------------------------------------
    # Integrate over q
    # ------------------------------------------------------------------

    integrated_profile = np.trapezoid(
        scatter_data_interpolated,
        x=q_vector,
        axis=1,
    )

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
        print('Working on time step:',time_step+1,'/',n_steps)
        start_time = time.time()
        integrated_array[:,time_step], theta_vector = integrate_scattering_data_over_q(scatter_data[:,:,time_step],
                                                                         q_input,
                                                                         n_q,
                                                                         n_theta,
                                                                         q_cutoff)
        end_time = time.time()
        run_time = end_time - start_time
        print('The calculation_time:',run_time)
    return integrated_array, theta_vector
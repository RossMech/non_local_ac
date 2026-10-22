from paraview.simple import *
import numpy as np
from paraview.vtk.numpy_interface import dataset_adapter as dsa
from paraview import servermanager
from vtk.util.numpy_support import vtk_to_numpy
import time

def modified_fft_transformation2(eta_2d: np.typing.NDArray[np.float64]) -> np.typing.NDArray[np.float64]:
    # Discrete FFT transformation, zero-frequency shifted to center
    eta_fft = np.fft.fftshift(np.fft.fft2(eta_2d))
    # Discrete scatter density |F|^2, computed directly from real/imag parts
    # (avoids abs() -> sqrt -> squared back, which is wasted work)
    I_discrete = eta_fft.real**2 + eta_fft.imag**2
    # Calculate values of the frequency vectors
    # Number of points
    nx = eta_2d.shape[0]
    nxd2 = nx / 2
    iqcent = nxd2 + 1
    iql = np.arange(1, nx + 1, dtype=np.float64) - iqcent
    qlad2 = np.pi * iql / nx + 1e-8
    # Weighting function for convolution in Fourier space
    # np.sinc(x) = sin(pi*x)/(pi*x); with x = qlad2/pi this is exactly
    # sin(qlad2)/qlad2 as one vectorized call instead of sin() + divide
    sincsqr_vect = np.square(np.sinc(qlad2 / np.pi))
    # Convoluted I_density, applied via broadcasting instead of building
    # the full outer-product matrix first (saves one O(nx^2) allocation)
    I_convoluted = I_discrete * sincsqr_vect[:, np.newaxis]
    I_convoluted *= sincsqr_vect[np.newaxis, :]
    return I_convoluted, qlad2

def handle_single_simulation_FFT(simulation_full_name: str,
                                 resample_number: int,
                                 deformation_bool: bool):

    # Read file
    reader = OpenDataFile(simulation_full_name)
    reader.UpdatePipelineInformation()

    # Get timesteps
    timestep_values = np.asarray(reader.TimestepValues)
    n_timesteps = len(timestep_values)

    # Undeform mesh if requested
    if deformation_bool:
        warp = WarpByVector(Input=reader)
        warp.ScaleFactor = -1.0
        warp.Vectors = "disp"
        resample = ResampleToImage(Input=warp)
    else:
        resample = ResampleToImage(Input=reader)

    resample.SamplingDimensions = [resample_number, resample_number, 1]

    # ------------------------------------------------------------------
    # Determine structured grid ordering ONCE
    # ------------------------------------------------------------------
    resample.UpdatePipeline(time=timestep_values[0])

    vtk_data = servermanager.Fetch(resample)

    coords = vtk_to_numpy(vtk_data.GetPoints().GetData())

    x = coords[:, 0]
    y = coords[:, 1]

    nx = np.unique(x).size
    ny = np.unique(y).size

    idx = np.lexsort((x, y))

    # ------------------------------------------------------------------
    # Allocate output
    # ------------------------------------------------------------------
    output_array = np.empty(
        (resample_number, resample_number, n_timesteps),
        dtype=np.float64,
    )

    # ------------------------------------------------------------------
    # Time loop
    # ------------------------------------------------------------------
    for i, t in enumerate(timestep_values):

        print(f"Working on time step: {i+1}/{n_timesteps}")
        start = time.perf_counter()

        resample.UpdatePipeline(time=t)
        vtk_data = servermanager.Fetch(resample)

        eta = vtk_to_numpy(
            vtk_data.GetPointData().GetArray("eta")
        )

        eta_2d = eta[idx].reshape(ny, nx)

        fft_output, q = modified_fft_transformation2(eta_2d)
        end = time.perf_counter()

        print(f"Calculation time: {end-start:.3f} s")

        output_array[:, :, i] = fft_output

    return output_array, q, timestep_values
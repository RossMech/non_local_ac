from paraview.simple import *
import numpy as np
from paraview.vtk.numpy_interface import dataset_adapter as dsa
from paraview import servermanager
from vtk.util.numpy_support import vtk_to_numpy

def modified_fft_transformation2(eta_2d: np.typing.NDArray[np.float64]) -> np.typing.NDArray[np.float64]:

    # Discrete FFT transformation
    eta_fft = np.fft.fft2(eta_2d)
    # Shift of zero frequencies to center
    eta_fft = np.fft.fftshift(eta_fft)

    # Discrete scatter density
    I_discrete = np.absolute(eta_fft)
    I_discrete = np.power(I_discrete,2)

    # Calculate values of the frequency vectors
    # Number of points 
    nx = eta_2d.shape[0]
    nxd2 = nx/2

    iqcent = nxd2 + 1
    iql = np.linspace(1,nx,nx) - iqcent
    qlad2 = np.pi*iql/nx + 1e-8

    # Weighting function for convolution in Fourier space
    sincsqr_vect = np.pow(np.sin(qlad2)/qlad2,2)
    sincsqr_matrix = np.outer(sincsqr_vect,sincsqr_vect)

    # Convoluted I_density
    I_convoluted = I_discrete * sincsqr_matrix

    return I_convoluted, qlad2

def handle_single_simulation_FFT(simulation_full_name: str,
                                 resample_number: int,
                                 deformation_bool: bool):

    # Read file
    reader = ExodusIIReader(FileName=simulation_full_name)
    reader.UpdatePipelineInformation()

    # Get timesteps
    timestep_values = np.array(reader.TimestepValues)

    # Undeform mesh
    if deformation_bool:
        warpByVector1 = WarpByVector(Input=reader)
        warpByVector1.ScaleFactor = -1.0
        warpByVector1.Vectors = 'disp_'

        # Resample onto regular grid
        resampleToImage1 = ResampleToImage(Input=warpByVector1)
    else:
        resampleToImage1 = resampleToImage(Input=reader)

    resampleToImage1.SamplingDimensions = [resample_number,resample_number,1]


    # Allocate output
    output_array = np.zeros(
        (resample_number, resample_number, len(timestep_values))
    )

    # Loop over timesteps
    for i, t in enumerate(timestep_values):

        # Update pipeline to current timestep
        resampleToImage1.UpdatePipeline(time=t)

        # Fetch data
        vtk_data = servermanager.Fetch(resampleToImage1)

        # Point data
        eta = vtk_to_numpy(vtk_data.GetPointData().GetArray("eta"))


        # Coordinates
        coords = vtk_to_numpy(
            vtk_data.GetPoints().GetData()
        )

        x = coords[:, 0]
        y = coords[:, 1]

        # Recover structured grid ordering
        nx = len(np.unique(x))
        ny = len(np.unique(y))

        idx = np.lexsort((x, y))
        eta_2d = eta[idx].reshape(ny, nx)

        # FFT
        print('Working on time step:',i+1,'/',len(timestep_values))
        fft_output, q = modified_fft_transformation2(eta_2d)

        output_array[:, :, i] = fft_output

    return output_array, q, timestep_values
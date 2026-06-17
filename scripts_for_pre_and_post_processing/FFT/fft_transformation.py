import paraview.simple
import numpy as np
from paraview.vtk.numpy_interface import dataset_adapter as dsa
from paraview import servermanager
from vtk.util import numpy_support
import matplotlib.pyplot as plt

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

def handle_single_simulation(simulation_full_name: str,
                             resample_number: int):
    # Read the files
    reader = paraview.simple.ExodusIIReader(FileName=simulation_full_name)
    reader.UpdatePipeline()
    scene = paraview.simple.GetAnimationScene()
    scene.UpdateAnimationUsingDataTimeSteps()
    scene.GoToFirst()

    # Undeform the simulation mesh
    warpByVector1 = paraview.simple.WarpByVector(registrationName='WarpByVector1', Input=reader)
    # Properties modified on warpByVector1
    warpByVector1.ScaleFactor = -1.0

    # Resample the mesh onto the regular grid
    resampleToImage1 = paraview.simple.ResampleToImage(registrationName='ResampleToImage1', Input=warpByVector1)
    resampleToImage1.SamplingDimensions = [resample_number, resample_number, 1]

    # Get the values of the time steps
    source = paraview.simple.GetActiveSource()
    timestep_values = source.TimestepValues
    
    # Commands for handling the timesteps
    render_view = paraview.simple.GetActiveViewOrCreate('RenderView')
    animation_scene = paraview.simple.GetAnimationScene()

    # Output array
    output_array = np.zeros((resample_number,resample_number,timestep_values.length))

    # Iteration over timesteps and handling data
    i = 0
    for t in timestep_values:
        # Go to the current time step
        animation_scene.AnimationTime = t

        # Update the pipeline
        render_view.Update()
        
        # Get the data for field variable
        data = dsa.WrapDataObject(servermanager.Fetch(resampleToImage1))
        eta_2d  = data.PointData["eta"]  # numpy array, shape (n_points,)

        # Get the coordinates values for sorting the eta values onto 2D shape
        coords = numpy_support.vtk_to_numpy(data.GetPoints().GetData())  # shape (n_points, 3)
        coords = coords[:,:-1]
        x, y = coords[:,0], coords[:,1]

        # Get unique coordinates to determine grid dimensions
        idx = np.lexsort((x, y))  # sort y-first, then x
        eta_2d = eta[idx].reshape(ny, nx)

        # Get the modified FFT
        fft_output, q = modified_fft_transformation2(eta_2d)

        # Save the output array 
        output_array[:,:,i] = fft_output

        i = i+1

    return output_array, q, timestep_values
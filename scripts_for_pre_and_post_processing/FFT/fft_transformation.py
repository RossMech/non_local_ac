import paraview.simple
import numpy as np
from paraview.vtk.numpy_interface import dataset_adapter as dsa
from paraview import servermanager
from vtk.util import numpy_support
import matplotlib.pyplot as plt

# Initial lines for trying the algorithm on real data (later delete)
reader = paraview.simple.ExodusIIReader(FileName="simulation_output_1.e-s143")
reader.UpdatePipeline()
scene = paraview.simple.GetAnimationScene()
scene.UpdateAnimationUsingDataTimeSteps()
scene.GoToFirst()

# Resample to the regular grid
warpByVector1 = paraview.simple.WarpByVector(registrationName='WarpByVector1', Input=reader)
# Properties modified on warpByVector1
warpByVector1.ScaleFactor = -1.0
resampleToImage1 = paraview.simple.ResampleToImage(registrationName='ResampleToImage1', Input=warpByVector1)
resampleToImage1.SamplingDimensions = [600, 600, 1]

# Transform data to the numpy array
data = dsa.WrapDataObject(servermanager.Fetch(resampleToImage1))
eta  = data.PointData["eta"]  # numpy array, shape (n_points,)

coords = numpy_support.vtk_to_numpy(data.GetPoints().GetData())  # shape (n_points, 3)

coords = coords[:,:-1]

x, y = coords[:,0], coords[:,1]

# Reshaping the eta array into 2Didx = np.lexsort((x, y))  # sort y-first, then x
idx = np.lexsort((x, y))  # sort y-first, then x
eta_2d = eta[idx]

# Get unique coordinates to determine grid dimensions
nx = len(np.unique(x))
ny = len(np.unique(y))

x_min = np.min(nx)
x_max = np.max(nx)

eta_2d = eta[idx].reshape(ny, nx)

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

    print(sincsqr_matrix.shape)

    return I_convoluted, qlad2

# Plotting
fig, ax = plt.subplots()

fft_output, q = modified_fft_transformation2(eta_2d)
ax.pcolormesh(q,q,np.log(fft_output))

fig.savefig("output.png")
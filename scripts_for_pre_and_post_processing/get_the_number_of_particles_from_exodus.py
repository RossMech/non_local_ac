# The function for getting the number of features from the file
# using the paraview python plugin 

from paraview.simple import *
import vtk.numpy_interface.dataset_adapter as dsa
from vtk.util.numpy_support import vtk_to_numpy
import numpy as np

def get_the_number_of_particles_from_exodus(file_name: str,
                                    phase_field_variable: str='etaa') -> np.typing.NDArray[np.float64] :

    # read a file
    calculation_input = ExodusIIReader(FileName=file_name)

    # get the vector of the time step values
    #time = calculation_input.TimestepValues

    # jumping into the last step (to go to the equilibrium configuration)
    #calculation_input.UpdatePipeline(max(time))

    # get animation scene
    animationScene = GetAnimationScene()
    # go to the equilibrium step in the simulation
    animationScene.GoToLast()

    calculation_input.PointVariables = [phase_field_variable]

    # the filters needed for connectivity to work
    calculation_input = MergeBlocks(calculation_input)
    
    threshold_data = Threshold(calculation_input)


    # Thresholding to indicate the precipitates
    threshold_data.Scalars = ['POINTS', 'etaa']

    # The thresholds for precipitate indication
    threshold_data.LowerThreshold = 0.5
    threshold_data.UpperThreshold = 1.1 # due to the non-local Allen-Cahn model, values slightly deviate from 0 and 1 in the bulk

    # the connectivity analysis workaround
    connectivity_data = Connectivity(threshold_data)

    # here the transformation from vtk datatype to numpy  
    numeric_data = servermanager.Fetch(connectivity_data)
    numeric_data = dsa.WrapDataObject(numeric_data)
    numeric_data = numeric_data.PointData['RegionId'] # getting the region id list
    numeric_data = vtk_to_numpy(numeric_data)

    # the regionid identify the number of feature, therefore to count the number of features we need to get all unique values
    data_unique = np.unique(numeric_data)
    # number of features corresponds to the length of the array, containing the unique regionid entries
    number_of_precipitates = np.size(data_unique)
    
    return number_of_precipitates
import os
from paraview.simple import *
from paraview import servermanager
from vtk.numpy_interface import dataset_adapter as dsa
import numpy as np
import pandas as pd
import re
import sys

# Subroutine to calculate the equilibrium alongation ratios
def estimate_main_lengthes(filename:str,
                           domain_size:float,
                           deformation_bool:bool,
                           field_name:str='eta',
                           deformation_name:str='disp') -> tuple[float,float]:
    
    # Read the datafile
    reader = OpenDataFile(filename)
    reader.UpdatePipelineInformation()

    # Go to the last timestep
    timesteps = reader.TimestepValues
    last_time = timesteps[-1]
    reader.UpdatePipeline(time=last_time)

    # If the mesh is deformed - undeform it
    if deformation_bool:
        warpByVector1 = WarpByVector(Input=reader)
        warpByVector1.ScaleFactor = -1.0
        warpByVector1.Vectors = deformation_name
    
    # Plot over the line across [10] and [01] directions
    if deformation_bool:
        plotOverLine_x = PlotOverLine(Input=warpByVector1)
        plotOverLine_y = PlotOverLine(Input=warpByVector1)
    else:
        plotOverLine_x = plotOverLine(Input=reader)
        plotOverLine_y = plotOverLine(Input=reader)

    # Set the boundaries for plot over line filters in paraview
    plotOverLine_x.Set(
        Point1=[0.0, 0.0, 0.0],
        Point2=[domain_size, 0.0, 0.0])
    plotOverLine_y.Set(
        Point1=[0.0, 0.0, 0.0],
        Point2=[0.0,domain_size,0.0]
    )
    plotOverLine_x.UpdatePipeline()
    plotOverLine_y.UpdatePipeline()

    # Fetch the data into the python suitable numpy array
    raw_x = servermanager.Fetch(plotOverLine_x)
    raw_y = servermanager.Fetch(plotOverLine_y)
    data_x = dsa.WrapDataObject(raw_x)
    data_y = dsa.WrapDataObject(raw_y)

    eta_x = np.asarray(data_x.PointData[field_name])
    arc_length_x  = np.asarray(data_x.PointData['arc_length'])

    eta_y = np.asarray(data_y.PointData[field_name])
    arc_length_y = np.asarray(data_y.PointData['arc_length'])

    # As the first point in PlotOverLine is the precipitate's origin ->
    # the value of arc length at which eta=0.5 is the half-axis length
    #a_length = np.interp(0.5,eta_x,arc_length_x)
    a_length = arc_length_x[(np.abs(eta_x - 0.5)).argmin()]
    #b_length = np.interp(0.5,eta_y,arc_length_y)
    b_length = arc_length_y[(np.abs(eta_y - 0.5)).argmin()]

    return a_length,b_length

# Subroutine to calculate the diffuse length across x and y axes at equilibrium
def estimate_diffusional_width(filename:str,
                           domain_size:float,
                           deformation_bool:bool,
                           field_name:str='eta',
                           deformation_name:str='disp') -> tuple[float,float]:
    
    # Read the datafile
    reader = OpenDataFile(filename)
    reader.UpdatePipelineInformation()

    # Go to the last timestep
    timesteps = reader.TimestepValues
    last_time = timesteps[-1]
    reader.UpdatePipeline(time=last_time)

    # If the mesh is deformed - undeform it
    if deformation_bool:
        warpByVector1 = WarpByVector(Input=reader)
        warpByVector1.ScaleFactor = -1.0
        warpByVector1.Vectors = deformation_name
    
    # Plot over the line across [10] and [01] directions
    if deformation_bool:
        plotOverLine_x = PlotOverLine(Input=warpByVector1)
        plotOverLine_y = PlotOverLine(Input=warpByVector1)
    else:
        plotOverLine_x = plotOverLine(Input=reader)
        plotOverLine_y = plotOverLine(Input=reader)

    # Set the boundaries for plot over line filters in paraview
    plotOverLine_x.Set(
        Point1=[0.0, 0.0, 0.0],
        Point2=[domain_size, 0.0, 0.0])
    plotOverLine_y.Set(
        Point1=[0.0, 0.0, 0.0],
        Point2=[0.0,domain_size,0.0]
    )
    plotOverLine_x.UpdatePipeline()
    plotOverLine_y.UpdatePipeline()

    # Fetch the data into the python suitable numpy array
    raw_x = servermanager.Fetch(plotOverLine_x)
    raw_y = servermanager.Fetch(plotOverLine_y)

    data_x = dsa.WrapDataObject(raw_x)
    data_y = dsa.WrapDataObject(raw_y)

    eta_x = np.asarray(data_x.PointData[field_name])
    arc_length_x  = np.asarray(data_x.PointData['arc_length'])

    eta_y = np.asarray(data_y.PointData[field_name])
    arc_length_y = np.asarray(data_y.PointData['arc_length'])

    #x_min = np.interp(0.01,eta_x,arc_length_x)
    #x_max = np.interp(0.99,eta_x,arc_length_x)

    x_min = arc_length_x[(np.abs(eta_x - 0.99)).argmin()]
    x_max = arc_length_x[(np.abs(eta_x - 0.01)).argmin()]

    #y_min = np.interp(0.01,eta_y,arc_length_y)
    #y_max = np.interp(0.99,eta_y,arc_length_y)

    y_min = arc_length_y[(np.abs(eta_y - 0.99)).argmin()]
    y_max = arc_length_y[(np.abs(eta_y - 0.01)).argmin()]

    x_width = x_max - x_min
    y_width = y_max - y_min

    return x_width,y_width

def get_energy_values_from_csv(filename) -> tuple[float,float,float]:

    # read the pandas dataframe
    df = pd.read_csv(filename)
    df = df.tail(1)

    f_total = float(df['f_total'].iloc[0])
    f_elast = float(df['f_elast'].iloc[0])
    f_interf = float(df['f_interf'].iloc[0])
    return f_total, f_elast, f_interf

# Domain size, add here later
domain_size = 70

# Path for the initial folder
path = '.'

# Get a content of the folder
main_folder_content = os.listdir(path)

# pattern of the folder name for heterogeneity
pattern_heterogeneity = re.compile(r'^heterogeneity_\d\d$')
pattern_width = re.compile(r'width_(0\d*)')

# Create datastructures for storing the outputs with all metadata needed
rows_major_axes = []
rows_diffusional_widthes = []
rows_energies = []

for method in main_folder_content:
    if os.path.isdir(method):
        method_subfolder = os.path.join(path,method)
        method_content = os.listdir(method_subfolder)

        # Subfolders in the method folder
        heterogeneity_subfolders = [d for d in method_content if os.path.isdir(os.path.join(method_subfolder, d))]

        for heterogeneity_subfolder in heterogeneity_subfolders:
            heterogeneity_subfolder_path = os.path.join(method_subfolder,heterogeneity_subfolder)

            heterogeneity_value = 0.0
            match = re.match(r'^heterogeneity_(\d)(\d)$', heterogeneity_subfolder)

            if match:
                heterogeneity_value = float(f"{match.group(1)}.{match.group(2)}")
            
            if heterogeneity_value!=0.0:
                heterogeneity_content = os.listdir(heterogeneity_subfolder_path)

                for output_file in heterogeneity_content:

                    # If file ends with .e - it is exodus and you need to calculate the
                    if output_file.endswith('.e'):
                        rw_string = output_file[6:-2]
                        rw_string = rw_string[0] + '.' + rw_string[1:]
                        rw_value = float(rw_string)

                        exodus_file_path = os.path.join(heterogeneity_subfolder_path,output_file)

                        a_length, b_length = estimate_main_lengthes(exodus_file_path,
                                                                    domain_size,
                                                                    deformation_bool=True)
                        x_width, y_width = estimate_diffusional_width(exodus_file_path,
                                                                      domain_size,
                                                                      deformation_bool=True)
                        
                        rows_major_axes.append({
                            "method" : method,
                            "heterogeneity" : heterogeneity_value,
                            "width_ratio" : rw_value,
                            "a_length" : a_length,
                            "b_length" : b_length
                        })

                        rows_diffusional_widthes.append({
                            "method" : method,
                            "heterogeneity" : heterogeneity_value,
                            "width_ratio" : rw_value,
                            "width_x" : x_width,
                            "width_y" : y_width
                        })
                    
                    if output_file.endswith('.csv'):
                        rw_string = output_file[6:-4]
                        rw_string = rw_string[0] + '.' + rw_string[1:]
                        rw_value = float(rw_string)

                        csv_file_path = heterogeneity_subfolder_path+'/' + output_file

                        f_total, f_el, f_int = get_energy_values_from_csv(csv_file_path)

                        rows_energies.append({
                            "method" : method,
                            "heterogeneity" : heterogeneity_value,
                            "width_ratio" : rw_value,
                            "f_total" : f_total,
                            "f_elastic" : f_el,
                            "f_interfacial" : f_int
                        })

df_major_axes = pd.DataFrame(rows_major_axes)
df_diffusional_widthes = pd.DataFrame(rows_diffusional_widthes)
df_energies = pd.DataFrame(rows_energies)

df_major_axes.to_csv('major_axes.csv',float_format='%.8f')
df_diffusional_widthes.to_csv('diffusional_widthes.csv',float_format='%.8f')
df_energies.to_csv('energies.csv',float_format='%.8f')
# Function for generation of the polar heatmaps for interaction plots
import numpy as np
import matplotlib.pyplot as plt
import pandas as pd
import scipy 
import matplotlib as mpl

def polar_heatmap(theta_vect : np.typing.NDArray[np.float64],
                  r_vect : np.typing.NDArray[np.float64],
                  value_vect : np.typing.NDArray[np.float64]):
    
    # create a grid
    theta_ls = np.linspace(np.min(theta_vect),np.max(theta_vect),20)
    r_ls = np.linspace(np.min(r_vect),np.max(r_vect),20)

    mpl.rcParams.update(mpl.rcParamsDefault)
    mpl.rcParams["text.usetex"] = True

    theta_mesh,r_mesh = np.meshgrid(theta_ls, r_ls)
    
    value_mesh = scipy.interpolate.griddata((theta_vect, r_vect), value_vect, (theta_mesh, r_mesh), method="cubic")

    fig, ax = plt.subplots(subplot_kw={"projection": "polar"})

    mesh = ax.pcolormesh(theta_mesh,r_mesh,value_mesh, vmin=110, vmax=170)

    ax.set_thetamin(0)
    ax.set_thetamax(90)

    cbar = fig.colorbar(mesh, ax=ax)
    cbar.set_label(r"$G, \frac{\mathrm{aJ}}{\mathrm{nm}^3}$", fontsize=12)

    return fig, ax
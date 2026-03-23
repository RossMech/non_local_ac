import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

# --- Configuration ---
folder_path = '/home/rnizinkovskyi/projects/non_local_ac/results/precipitate_interaction/equilibrium_configuration/'
file_name =  'r_mean_13_u_param_0_equilibrium_configuration.csv'
full_path = folder_path + file_name

# RGB colors per value
COLORS = {
    1: [5/255, 165/255, 63/255],
    2: [120/255, 0/255, 60/255],
    3: [120/255, 0/255, 60/255],
    4: [26/255, 106/255, 122/255],
}

# --- Load data ---
df = pd.read_csv(full_path)
thetas_rad = np.radians(df['theta'])
radii = df['d_norm']
values = df['configuration_number']

# --- Plot ---
fig, ax = plt.subplots(subplot_kw={"projection": "polar"})
ax.set_thetamin(0)
ax.set_thetamax(90)

point_colors = np.array([COLORS[v] for v in values])

ax.scatter(thetas_rad, radii, c=point_colors, s=200, zorder=5,
           edgecolors='white', linewidths=1.5)


plt.savefig('/home/rnizinkovskyi/projects/non_local_ac/scripts_for_pre_and_post_processing/test.png')
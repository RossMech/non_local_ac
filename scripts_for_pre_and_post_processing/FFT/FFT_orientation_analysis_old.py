# Python code to analyze the orientation dependencies in FFT spectra to study the alignment of the particles
import numpy as np 
import matplotlib.pyplot as plt
from scipy.interpolate import RBFInterpolator, griddata
import time

start_time = time.time()
# Import data
diffraction_data = np.log(np.load('simulation_output_1.npy'))
q_vector = np.load('simulation_output_1_q.npy')

# generating mesh of q-vector values for further post-processing
q_mesh_x, q_mesh_y = np.meshgrid(q_vector,q_vector)

# Transformation to polar coordinate system
Q = np.sqrt(q_mesh_x**2 + q_mesh_y**2)
Theta = np.arctan2(q_mesh_y, q_mesh_x)

Q_flat = Q.ravel()
Theta_flat = Theta.ravel()
diff_data_flat = diffraction_data[:,:,-1].ravel()

fig, ax = plt.subplots()
contour = ax.scatter(Q_flat, Theta_flat, c=diff_data_flat)
fig.colorbar(contour, ax=ax, label='Value')

ax.set_xlabel('Q')
ax.set_ylabel(r'$\theta$ (rad)')

fig.savefig('output.png', dpi=300, bbox_inches='tight')
plt.close(fig)

n_r, n_theta = 200, 200  # resolution, adjust as needed
q_interp_vect = np.linspace(0.0, np.pi/2, n_r)
theta_interp_vect = np.linspace(-np.pi, np.pi, n_theta)

Q_interp_mesh, Theta_interp_mesh = np.meshgrid(q_interp_vect, theta_interp_vect, indexing='xy')

points = np.column_stack((Q_flat, Theta_flat))

interpolated_data = griddata(points,diff_data_flat,(Q_interp_mesh,Theta_interp_mesh),method='linear')

mask = np.isnan(interpolated_data)

if mask.any():
    rbf = RBFInterpolator(points, 
                          diff_data_flat,
                          kernel='linear',
                          smoothing=0.0,
                          neighbors=50)
    interpolated_data[mask] = rbf(np.column_stack([Q_interp_mesh[mask], Theta_interp_mesh[mask]]))

fig, ax = plt.subplots()
contour = ax.contourf(Q_interp_mesh, Theta_interp_mesh, interpolated_data)
fig.colorbar(contour, ax=ax, label='Value')

ax.set_xlabel('Q')
ax.set_ylabel(r'$\theta$ (rad)')

fig.savefig('output_interpolated.png', dpi=300, bbox_inches='tight')
plt.close(fig)

end_time = time.time()

print('execution_time=',end_time-start_time)
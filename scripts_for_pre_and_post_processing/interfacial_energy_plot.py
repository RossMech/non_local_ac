import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl

U_vect = np.linspace(0.0,1.0,50)

sigma_norm = (1 + U_vect**2) / (1+6*U_vect**2)**(2/3)

mpl.rcParams.update(mpl.rcParamsDefault)
mpl.rcParams["text.usetex"] = True


plt.plot(U_vect,sigma_norm)

plt.xlabel('$R$')
plt.ylabel(r'$F^\mathrm{int}_\mathrm{norm}$')

plt.savefig('/home/rnizinkovskyi/projects/non_local_ac/scripts_for_pre_and_post_processing/test.png')


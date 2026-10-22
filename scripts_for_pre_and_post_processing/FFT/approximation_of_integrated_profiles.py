import numpy as np
from scipy.special import i0e

# von Mises pdf function
def von_mises_pdf(theta, mu, kappa):
    return np.exp(kappa * (np.cos(theta - mu) - 1.0)) / (2.0 * np.pi * i0e(kappa))

# Fitted function
def vm_mixture(theta, k, A_vect, mu_vect, kappa_vect):

    n_components = len(A_vect)
    theta = np.asarray(theta, dtype=float)
    out = np.full_like(theta, k)
    for i in range(n_components):
        out = out + A_vect[i] * von_mises_pdf(theta, mu_vect[i], kappa_vect[i])
    return out

def fit_single_function(theta,intensity,n_components,k_i,A_i,mu_i,kappa_i)
#pragma once

// Including the "ADKernel" Kernel here so we can extend it
#include "ADKernelValue.h"

/**
 * Computes the residual contribution: K / mu * grad_u * grad_phi.
 */
class ADVolumeConservationKernel : public ADKernelValue
{
public:
  static InputParameters validParams();

  ADVolumeConservationKernel(const InputParameters & parameters);

protected:
  /// ADKernel objects must override precomputeQpResidual
  virtual ADReal precomputeQpResidual() override;

  // Structural mobility
  const ADMaterialProperty<Real> & _L;
  // Lagrange multiplicator
  const ADMaterialProperty<Real> & _langrange_mult;
  // weighting function
  const ADMaterialProperty<Real> & _w;
};

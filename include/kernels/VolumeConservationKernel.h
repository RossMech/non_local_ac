#pragma once

#include "KernelValue.h"

class VolumeConservationKernel : public KernelValue
{
public:
  static InputParameters validParams();

  VolumeConservationKernel(const InputParameters & parameters);

protected:
  // The method, which sould overwrite the KernelValue method for calculation in Integration Point
  virtual Real precomputeQpResidual() override;

  // Structural mobility
  const MaterialProperty<Real> & _L;
  // Lagrange multiplicator
  const MaterialProperty<Real> & _langrange_mult;
  // weighting function
  const MaterialProperty<Real> & _w;
};

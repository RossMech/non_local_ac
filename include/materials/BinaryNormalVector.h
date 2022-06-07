#pragma once

#include "Material.h"
#include "DerivativeMaterialInterface.h"

/**
 * Calculate phase normal tensor based on gradient
 */
class BinaryNormalVector : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  BinaryNormalVector(const InputParameters & parameters);

protected:
  virtual void computeQpProperties();

  const VariableGradient & _grad_u;
  MaterialProperty<RealGradient> & _normal_vector;
};

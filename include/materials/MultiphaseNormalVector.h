#pragma once

#include "Material.h"
#include "DerivativeMaterialInterface.h"

/**
 * Calculate phase normal tensor based on gradient
 */
class MultiphaseNormalVector : public DerivativeMaterialInterface<Material>
{
public:
  static InputParameters validParams();

  MultiphaseNormalVector(const InputParameters & parameters);

protected:
  virtual void computeQpProperties();

  const VariableValue & _u;
  const VariableValue & _v;

  const VariableGradient & _grad_u;
  const VariableGradient & _grad_v;
  MaterialProperty<RealGradient> & _normal_vector;
};

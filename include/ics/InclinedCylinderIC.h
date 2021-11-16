#pragma once

#include "InitialCondition.h"

/**
 * Makes initial condition which creates a linear ramp of the given variable
 * on the x-axis with specified side values
 */
class InclinedCylinderIC : public InitialCondition
{
public:
  static InputParameters validParams();

  InclinedCylinderIC(const InputParameters & parameters);

protected:
  virtual Real value(const Point & p);

  // Outside and inside values of the field
  const Real _outside;
  const Real _inside;

  // Geometrical parameters of inclined box
  const Real _a;
  const Real _b;
  const std::vector<Real> _Q_tens;

  // Dimension of the mesh
  const unsigned int _dim;
};

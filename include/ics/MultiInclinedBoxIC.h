#pragma once

#include "InitialCondition.h"

/**
 * Makes initial condition which creates a linear ramp of the given variable
 * on the x-axis with specified side values
 */
class MultiInclinedBoxIC : public InitialCondition
{
public:
  static InputParameters validParams();

  MultiInclinedBoxIC(const InputParameters & parameters);

protected:
  virtual Real value(const Point & p);

  // Outside and inside values of the field
  const Real _outside;
  const Real _inside;

  // Geometrical parameters of inclined box
  const std::vector<Real> _a;
  const std::vector<Real> _b;
  const std::vector<Real> _theta;
  const std::vector<Point> _c0;

  // Dimension of the mesh
  const unsigned int _dim;

  // Number of geometrical objects
  const unsigned int _nbox;
};

#pragma once

#include "InitialCondition.h"


class TwinSphereIC : public InitialCondition
{
  public:
    static InputParameters validParams();

    TwinSphereIC(const InputParameters & parameters);

  protected:
    virtual Real value(const Point & p);

    // Outside and inside values of the field
    const Real _outside;
    const Real _inside_above;
    const Real _inside_under;

    // Geometrical parameters
    const Real _r; // radius
    const std::vector<Real> _n; // normal

    // Dimension of the mesh
    const unsigned int _dim;
};

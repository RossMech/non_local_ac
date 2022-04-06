#pragma once

#include "InitialCondition.h"


class TwoTwinLowerIC : public InitialCondition
{
  public:
    static InputParameters validParams();

    TwoTwinLowerIC(const InputParameters & parameters);

  protected:
    virtual Real value(const Point & p);

    // Outside and inside values of the field
    const Real _outside;
    const Real _inside;
    const Real _int_width;

    // Geometrical parameters
    const Real _r; // radius
    const std::vector<Real> _n; // normal

    // Dimension of the mesh
    const unsigned int _dim;
};

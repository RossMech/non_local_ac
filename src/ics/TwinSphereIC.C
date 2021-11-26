#include "TwinSphereIC.h"
#include "FEProblem.h"
#include "MooseMesh.h"

registerMooseObject("MooseApp", TwinSphereIC);

InputParameters
TwinSphereIC::validParams()
{
  InputParameters params = InitialCondition::validParams();
  params.addClassDescription(
    "Initial condition for two twins inside sphere, divided by plane");
    params.addRequiredParam<Real>("outside", "The value outside of the sphere");
    params.addRequiredParam<Real>("inside_above", "The value inside above the plane");
    params.addRequiredParam<Real>("inside_under", "The value inside under the plane");
    params.addRequiredParam<Real>("r", "The radius of sphere");
    params.addRequiredParam<std::vector<Real>>("n","The normal, which divides");

    return params;
}

TwinSphereIC::TwinSphereIC(const InputParameters & parameters)
  : InitialCondition(parameters),
    _outside(getParam<Real>("outside")),
    _inside_above(getParam<Real>("inside_above")),
    _inside_under(getParam<Real>("inside_under")),
    _r(getParam<Real>("r")),
    _n(getParam<std::vector<Real>>("n")),
    _dim(_fe_problem.mesh().dimension())
{
}

Real
TwinSphereIC::value(const Point & p)
{

  // Check if the dimensionality of mesh coincides with the length of normal vector
  if (_dim != _n.size())
    paramError("The dimensionality of mesh does not coincide with the size of normal vector!");

  // Standard value is the value from the outside
  Real value = _outside;

  // radius value
  Real r_c = std::sqrt(p(0)*p(0)+p(1)*p(1)+p(2)*p(2));
  Real res = 0.0;

  if (r_c <= _r)
  {
    res = _n[0]*p(0) + _n[1]*p(1) + _n[2]*p(2);
    if (res >= 0)
    {
      value = _inside_above;
    }
    else
    {
      value = _inside_under;
    }
  }

  return value;
}

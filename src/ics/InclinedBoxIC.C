#include "InclinedBoxIC.h"
#include "FEProblem.h"
#include "MooseMesh.h"

registerMooseObject("MooseApp", InclinedBoxIC);

InputParameters
InclinedBoxIC::validParams()
{
  InputParameters params = InitialCondition::validParams();
  params.addClassDescription(
      "Initial condition for inclined box");
  params.addRequiredParam<Real>("outside", "The value outside the box");
  params.addRequiredParam<Real>("inside", "The value outside the box");
  params.addRequiredParam<Real>("a", "The horizontal half-axis of the box");
  params.addRequiredParam<Real>("b", "The vertical half-axis of the box");
  params.addRequiredParam<Real>("theta", "The inclination angle of the precipitate in degrees");

  return params;
}

InclinedBoxIC::InclinedBoxIC(const InputParameters & parameters)
  : InitialCondition(parameters),
    _outside(getParam<Real>("outside")),
    _inside(getParam<Real>("inside")),
    _a(getParam<Real>("a")),
    _b(getParam<Real>("b")),
    _theta(getParam<Real>("theta")),
    _dim(_fe_problem.mesh().dimension())
{
}

Real
InclinedBoxIC::value(const Point & p)
{

  // Check the dimensionality of the mesh
  if (_dim != 2)
    paramError("InclinedBoxIC works just with 2D meshes!");

  // Standard value is the value from the outside
  Real value = _outside;

  // Degree - radian corvesion of the angle of inclination
  Real _theta_rad = _theta / 180 * libMesh::pi;

  // Declaration and calculation of the local coordinates for the precipitate
  Point _local_p;
  _local_p(0) = p(0)*std::cos(_theta_rad) + p(1)*std::sin(_theta_rad);
  _local_p(1) = -p(0)*std::sin(_theta_rad) + p(1)*std::cos(_theta_rad);

  if (std::abs(_local_p(0)) <= _a && std::abs(_local_p(1)) <= _b)
    value = _inside;

  return value;
}

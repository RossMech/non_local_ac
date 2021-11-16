#include "InclinedCylinderIC.h"
#include "FEProblem.h"
#include "MooseMesh.h"

registerMooseObject("MooseApp", InclinedCylinderIC);

InputParameters
InclinedCylinderIC::validParams()
{
  InputParameters params = InitialCondition::validParams();
  params.addClassDescription(
      "Initial condition for inclined cylinder in 3D");
  params.addRequiredParam<Real>("outside", "The value outside the box");
  params.addRequiredParam<Real>("inside", "The value outside the box");
  params.addRequiredParam<Real>("a", "The radius of cylinder");
  params.addRequiredParam<Real>("b", "The half-length of cylinder");
  params.addRequiredParam<std::vector<Real>>("Q_tens", "The transformation tensor to local coordinates");

  return params;
}

InclinedCylinderIC::InclinedCylinderIC(const InputParameters & parameters)
  : InitialCondition(parameters),
    _outside(getParam<Real>("outside")),
    _inside(getParam<Real>("inside")),
    _a(getParam<Real>("a")),
    _b(getParam<Real>("b")),
    _Q_tens(getParam<std::vector<Real>>("Q_tens")),
    _dim(_fe_problem.mesh().dimension())
{
}

Real
InclinedCylinderIC::value(const Point & p)
{

  // Check the dimensionality of the mesh
  if (_dim != 3)
    paramError("InclinedCylinderIC works just with 3D meshes!");

  if (_Q_tens.size() != 9)
    paramError("The wrong size of the transformation tensor is given!");

  // Standard value is the value from the outside
  Real value = _outside;

  // Declaration and calculation of the local coordinates for the precipitate
  Point local_p;

  local_p(0) = _Q_tens[0]*p(0) + _Q_tens[1]*p(1) + _Q_tens[2]*p(2);
  local_p(1) = _Q_tens[3]*p(0) + _Q_tens[4]*p(1) + _Q_tens[5]*p(2);
  local_p(2) = _Q_tens[6]*p(0) + _Q_tens[7]*p(1) + _Q_tens[8]*p(2);

  Real local_r;

  local_r = local_p(0)*local_p(0) + local_p(1)*local_p(1);
  local_r = std::sqrt(local_r);

  if (local_r <= _a && std::abs(local_p(2)) <= _b)
    value = _inside;

  return value;
}

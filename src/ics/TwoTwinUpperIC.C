#include "TwoTwinUpperIC.h"
#include "FEProblem.h"
#include "MooseMesh.h"
#include <math.h>

registerMooseObject("MooseApp", TwoTwinUpperIC);

InputParameters
TwoTwinUpperIC::validParams()
{
  InputParameters params = InitialCondition::validParams();
  params.addClassDescription(
    "Initial condition for two twins inside sphere, divided by plane");
    params.addRequiredParam<Real>("outside", "The value outside of the sphere");
    params.addRequiredParam<Real>("inside", "The value inside above the plane");
    params.addRequiredParam<Real>("r", "The radius of sphere");
    params.addRequiredParam<std::vector<Real>>("n","The normal, which divides");
    params.addRequiredParam<Real>("int_width","Interfacial width");

    return params;
}

TwoTwinUpperIC::TwoTwinUpperIC(const InputParameters & parameters)
  : InitialCondition(parameters),
    _outside(getParam<Real>("outside")),
    _inside(getParam<Real>("inside")),
    _int_width(getParam<Real>("int_width")),
    _r(getParam<Real>("r")),
    _n(getParam<std::vector<Real>>("n")),
    _dim(_fe_problem.mesh().dimension())
{
}

Real
TwoTwinUpperIC::value(const Point & p)
{
  // Numerical tolerance parameter
  Real n_tol = 1e-9;

  // Check if the dimensionality of mesh coincides with the length of normal vector
  if (_dim != _n.size())
    paramError("The dimensionality of mesh does not coincide with the size of normal vector!");

  // Standard value is the value from the outside
  Real value = _outside;

  // radius value
  Real r_c = 0.0;
  for (int i=0; i < _dim; i++)
  {
     r_c += p(i)*p(i);
  }
  r_c = std::sqrt(r_c);

  // residual
  Real res = 0.0;

  // Calculate the residual
  for (int i=0; i<_dim; i++)
  {
    res += _n[i]*p(i);
  }

  // check if point is inside twin sphere
  if ((r_c <= _r) && (res >= 0))
  {
      value = _inside;
  }

  // Diffuse interface calculations
  Real delta_r = r_c - _r;
  if ((_int_width > n_tol))
  {
    if ((std::abs(res) < _int_width) && (delta_r < -_int_width))
    {
      value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(res))+1);
    }

    if ((std::abs(delta_r) < _int_width) && (res > _int_width))
    {
      value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(-delta_r))+1);
    }
    if ((delta_r >= -_int_width) && (delta_r <= 0.0) && (res >= 0.0) && (res <= _int_width))
    {
      //value = 0.7;
      if (std::abs(delta_r) < std::abs(res))
      {
        value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(-delta_r))+1);
      }
      else
      {
        value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(res))+1);
      }
    }
    if ((delta_r <= _int_width) && (delta_r >= 0.0) && (res >= 0.0) && (res <= _int_width))
    {
      value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(-delta_r))+1);
    }
    if ((delta_r <= _int_width) && (delta_r >= 0.0) && (res <= 0.0) && (res >= -_int_width))
    {
      Real dist = std::sqrt(delta_r*delta_r+res*res);
      value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(-dist))+1);
    }
    if ((delta_r >= -_int_width) && (delta_r <= 0.0) && (res <= 0.0) && (res >= -_int_width))
    {
      value = _outside + 0.5*(_inside-_outside)*(std::tanh(pi/_int_width*(res))+1);
    }
  }
  return value;
}

#include "MultiInclinedBoxIC.h"
#include "FEProblem.h"
#include "MooseMesh.h"

registerMooseObject("NonLocalACApp", MultiInclinedBoxIC);

InputParameters
MultiInclinedBoxIC::validParams()
{
  InputParameters params = InitialCondition::validParams();
  params.addClassDescription(
      "Initial condition for inclined box");
  params.addRequiredParam<Real>("outside", "The value outside the box");
  params.addRequiredParam<Real>("inside", "The value outside the box");
  params.addRequiredParam<std::vector<Real>>("a", "The horizontal half-axis of the box");
  params.addRequiredParam<std::vector<Real>>("b", "The vertical half-axis of the box");
  params.addRequiredParam<std::vector<Real>>("theta", "The inclination angle of the precipitate in degrees");
  params.addRequiredParam<std::vector<Point>>("c0","Center position");
  params.addParam<Real>("int_width", 0.0,"The width of the diffuse interface. Set 0 for sharp interface.");

  return params;
}

MultiInclinedBoxIC::MultiInclinedBoxIC(const InputParameters & parameters)
  : InitialCondition(parameters),
    _outside(getParam<Real>("outside")),
    _inside(getParam<Real>("inside")),
    _a(getParam<std::vector<Real>>("a")),
    _b(getParam<std::vector<Real>>("b")),
    _theta(getParam<std::vector<Real>>("theta")),
    _c0(getParam<std::vector<Point>>("c0")),
    _dim(_fe_problem.mesh().dimension()),
    _nbox(_a.size()),
    _int_width(getParam<Real>("int_width"))
{
}

Real
MultiInclinedBoxIC::value(const Point & p)
{

  // Check the dimensionality of the mesh
  if (_dim != 2)
    paramError("MultiInclinedBoxIC works just with 2D meshes!");

  if (_int_width < 0.0)
    paramError("Interfacial width should be non-negative!");

  // Standard value is the value from the outside
  Real value = _outside;

  for (unsigned int i=0; i < _nbox; ++i)
  {
    // Degree - radian corvesion of the angle of inclination
    Real _theta_rad = _theta[i] / 180 * libMesh::pi;

    // Declaration and calculation of the local coordinates for the precipitate
    Point _local_p;

    _local_p(0) = (p(0)-_c0[i](0))*std::cos(_theta_rad) + (p(1)-_c0[i](1))*std::sin(_theta_rad);
    _local_p(1) = -(p(0)-_c0[i](0))*std::sin(_theta_rad) + (p(1)-_c0[i](1))*std::cos(_theta_rad);

    if (_int_width == 0.0)
      if ((std::abs(_local_p(0)) <= _a[i]) && (std::abs(_local_p(1)) <= _b[i]))
        value = _inside;

    if (_int_width > 0.0)
    {

      if ((std::abs(_local_p(0)) <= (_a[i]+_int_width)) && (std::abs(_local_p(1)) <= (_b[i]+_int_width)))
      {
        Real f_in;
        f_in = 0.25 * (std::tanh(2.0*(_local_p(0)+_a[i])/_int_width) -
                       std::tanh(2.0*(_local_p(0)-_a[i])/_int_width))*
                       (std::tanh(2.0*(_local_p(1)+_b[i])/_int_width) -
                       std::tanh(2.0*(_local_p(1)-_b[i])/_int_width));
        value = _outside + (_inside - _outside) * f_in;
      }
    }
  }
  return value;
}

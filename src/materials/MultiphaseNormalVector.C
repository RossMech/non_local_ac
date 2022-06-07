#include "MultiphaseNormalVector.h"
#include "MooseMesh.h"

registerMooseObject("PhaseFieldApp", MultiphaseNormalVector);

InputParameters
MultiphaseNormalVector::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Calculate normal tensor of a phase based on gradient");
  params.addRequiredCoupledVar("phase_a", "Phase variable");
  params.addRequiredCoupledVar("phase_b", "Phase variable");
  params.addRequiredParam<MaterialPropertyName>("normal_vector_name", "Name of normal tensor");
  return params;
}

MultiphaseNormalVector::MultiphaseNormalVector(const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _u(coupledValue("phase_a")),
    _v(coupledValue("phase_b")),
    _grad_u(coupledGradient("phase_a")),
    _grad_v(coupledGradient("phase_b")),
    _normal_vector(
        declareProperty<RealGradient>(getParam<MaterialPropertyName>("normal_vector_name")))
{
}

void
MultiphaseNormalVector::computeQpProperties()
{
  // Isocontour gradient
  const RealGradient iso_grad = _grad_u[_qp] - _grad_v[_qp];
  const Real magnitude = iso_grad.norm();

  if ((_u[_qp] > 1e-8) && (_v[_qp] > 1e-8))
  {
    _normal_vector[_qp] = iso_grad / magnitude;
  }
  else
  {
    for (int i = 0; i < _mesh.dimension(); i++)
      _normal_vector[_qp](i) = 0.0;
  }
}

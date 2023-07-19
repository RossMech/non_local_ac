#include "BinaryNormalVector.h"
#include "MooseMesh.h"

registerMooseObject("PhaseFieldApp", BinaryNormalVector);

InputParameters
BinaryNormalVector::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Calculate normal tensor of a phase based on gradient");
  params.addRequiredCoupledVar("phase", "Phase variable");
  params.addRequiredParam<MaterialPropertyName>("normal_vector_name", "Name of normal tensor");
  return params;
}

BinaryNormalVector::BinaryNormalVector(const InputParameters & parameters)
  : DerivativeMaterialInterface<Material>(parameters),
    _u(coupledValue("phase")),
    _grad_u(coupledGradient("phase")),
    _normal_vector(
        declareProperty<RealGradient>(getParam<MaterialPropertyName>("normal_vector_name")))
{
}

void
BinaryNormalVector::computeQpProperties()
{
  const Real magnitude = _grad_u[_qp].norm();

  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - 1e-8;

  //if (magnitude > 1e-8)
  if ((_u[_qp] > lower_bound) && (_u[_qp] < upper_bound))
  {
    _normal_vector[_qp] = _grad_u[_qp];
    _normal_vector[_qp] /= magnitude;
  }
  else
  {
    for (int i = 0; i < _mesh.dimension(); i++)
      _normal_vector[_qp](i) = 0.0;
  }
}

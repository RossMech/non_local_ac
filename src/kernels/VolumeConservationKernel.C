#include "VolumeConservationKernel.h"

registerMooseObject("NonLocalACApp", VolumeConservationKernel);

InputParameters
VolumeConservationKernel::validParams()
{
  auto params = KernelValue::validParams();
  params.addClassDescription("The kernel, which implements the volume conservation for non-local Allen-Cahn model");
  params.addRequiredParam<MaterialPropertyName>(
                              "mob_name", "Structural mobility");
  params.addRequiredParam<MaterialPropertyName>(
                              "lagrange_mult", "Lagrange multiplicator");
  params.addRequiredParam<MaterialPropertyName>(
                              "weight_func", "Weighting function");
  return params;
}

VolumeConservationKernel::VolumeConservationKernel(const InputParameters & parameters)
      : KernelValue(parameters),
        _L(getMaterialProperty<Real>("mob_name")),
        _langrange_mult(getMaterialProperty<Real>("lagrange_mult")),
        _w(getMaterialProperty<Real>("weight_func"))
      {}

Real
VolumeConservationKernel::precomputeQpResidual()
{
  return -_L[_qp]*_langrange_mult[_qp]*_w[_qp];
}

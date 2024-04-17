#include "ADVolumeConservationKernel.h"

registerMooseObject("NonLocalACApp", ADVolumeConservationKernel);

InputParameters
ADVolumeConservationKernel::validParams()
{
  InputParameters params = ADKernelValue::validParams();
  params.addClassDescription("Compute the diffusion term for Darcy pressure ($p$) equation: "
                             "$-\\nabla \\cdot \\frac{\\mathbf{K}}{\\mu} \\nabla p = 0$");
  params.addRequiredParam<MaterialPropertyName>(
                             "mob_name", "Structural mobility");
  params.addRequiredParam<MaterialPropertyName>(
                             "lagrange_mult", "Lagrange multiplicator");
  params.addRequiredParam<MaterialPropertyName>(
                             "weight_func", "Weighting function");
  return params;
}

ADVolumeConservationKernel::ADVolumeConservationKernel(const InputParameters & parameters)
  : ADKernelValue(parameters),
    _L(getADMaterialProperty<Real>("mob_name")),
    _langrange_mult(getADMaterialProperty<Real>("lagrange_mult")),
    _w(getADMaterialProperty<Real>("weight_func"))
{
}

ADReal
ADVolumeConservationKernel::precomputeQpResidual()
{
  return -_L[_qp] * _langrange_mult[_qp] * _w[_qp];
}

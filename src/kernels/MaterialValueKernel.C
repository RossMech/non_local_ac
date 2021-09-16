#include "MaterialValueKernel.h"

registerMooseObject("MooseApp", MaterialValueKernel);

InputParameters
MaterialValueKernel::validParams()
{
  auto params = KernelValue::validParams();
  params.addClassDescription("The kernel, which uses the material as local value of kernel");
  params.addRequiredParam<MaterialPropertyName>(
                              "Mat_name", "Name of material, which is used as a local value of the kernel");
  return params;
}

MaterialValueKernel::MaterialValueKernel(const InputParameters & parameters)
      : KernelValue(parameters),
        _Mat_value(getMaterialProperty<Real>("Mat_name"))
      {}

Real
MaterialValueKernel::precomputeQpResidual()
{
  return _Mat_value[_qp];
}

#include "MaterialValueKernel.h"

registerMooseObject("MooseApp", MaterialValueKernel);

InputParameters
MaterialValueKernel::validParams()
{
  auto params = KernelValue::validParams();
  params.addClassDescription("Same as `Diffusion` in terms of physics/residual, but the Jacobian "
                             "is computed using forward automatic differentiation");
  return params;
}

MaterialValueKernel::MaterialValueKernel(const InputParameters & parameters) : KernelValue(parameters) {}

Real
MaterialValueKernel::precomputeQpResidual()
{
  return _u[_qp];
}




/*

#include "MaterialValueKernel.h"

registerMooseObject("NonLocalAC", MaterialValueKernel);

InputParameters

MaterialValueKernel::validParams()
{
  auto params = MaterialValueKernel::validParams();
  params.addClassDescription("The kernel, which takes the material value in kernel");
  params.addRequiredParam<MaterialPropertyName>("mat_name","Name of material, which is used in this kernel");
  return params
}

MaterialValueKernel::MaterialValueKernel(const InputParameters & parameters)
    : KernelValue(parameters),
      _Mat_value(getMaterialProperty<Real>("mat_name")),
{
}

RealVectorValue
MaterialValueKernel::precomputeQpResidual()
{
  return _Mat_value[_qp];
}


/**/

#include "ElasticEnergyMinimal.h"
#include "RankTwoTensor.h"

registerMooseObject("NonLocalACApp", ElasticEnergyMinimal);

InputParameters
ElasticEnergyMinimal::validParams()
{
  InputParameters params = DerivativeFunctionMaterialBase::validParams();
  params.addClassDescription("Free energy material for the elastic energy contributions.");
  params.addParam<std::string>("base_name", "Material property base name");
  params.addRequiredCoupledVar("args", "Arguments of F() - use vector coupling");
  params.addCoupledVar("displacement_gradients",
                       "Vector of displacement gradient variables (see "
                       "Modules/PhaseField/DisplacementGradients "
                       "action)");
  return params;
}

ElasticEnergyMinimal::ElasticEnergyMinimal(const InputParameters & parameters)
  : DerivativeFunctionMaterialBase(parameters),
    _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
    _stress(getMaterialPropertyByName<RankTwoTensor>(_base_name + "stress")),
    _strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "elastic_strain"))
{
}

void
ElasticEnergyMinimal::initialSetup()
{
  validateCoupling<RankTwoTensor>(_base_name + "elastic_strain");
}

Real
ElasticEnergyMinimal::computeF()
{
  return 0.5 * _stress[_qp].doubleContraction(_strain[_qp]);
}

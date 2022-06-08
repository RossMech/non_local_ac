#include "ElasticFreeEnergyMinimal.h"

registerMooseObject("TensorMechanicsApp", ElasticFreeEnergyMinimal);

InputParameters
ElasticFreeEnergyMinimal::validParams()
{
  InputParameters params = ElasticFreeEnergyMinimal::validParams();
  params.addClassDescription("Calculation of elastic free energy with the minimal interface in order to be appicable to the custom stress models");
  params.addParam<std::string>("base_name",
                             "Optional parameter that allows the user to define "
                             "multiple mechanics material systems on the same "
                             "block, i.e. for multiple phases");
  params.addRequiredParam<MaterialPropertyName>("elastic_energy_name","name_of_elastic_energy_property");
  return params;
}

ElasticFreeEnergyMinimal::ElasticFreeEnergyMinimal(const InputParameters & parameters)
  : Material(parameters),

      _base_name(getParam<std::string>("base_name_alpha") + "_"),
      _stress(getMaterialPropertyByName<RankTwoTensor>(_base_name+"stress")),
      _strain(getMaterialPropertyByName<RankTwoTensor>(_base_name+"strain")),
      _elastic_energy(declareProperty<Real>(getParam<MaterialPropertyName>("elastic_energy_name")))
{
}

void
ElasticFreeEnergyMinimal::computeQpProperties()
{
  _elastic_energy[_qp] = 0.5*_stress[_qp].doubleContraction(_strain[_qp]);
}

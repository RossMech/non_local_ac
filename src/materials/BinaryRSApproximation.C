#include "BinaryRSApproximation.h"
#include <iostream>

registerMooseObject("TensorMechanicsApp", BinaryRSApproximation);

InputParameters
BinaryRSApproximation::validParams()
{
  InputParameters params = ComputeStressBase::validParams();
  params.addClassDescription("Compute stress using elasticity for small strains");
  params.addRequiredCoupledVar("phase","Phase variable");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<MaterialPropertyName>("w_beta","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  return params;
}

BinaryRSApproximation::BinaryRSApproximation(const InputParameters & parameters)
  : ComputeStressBase(parameters),
    _u(coupledValue("phase")), // phase variable value
    _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
    _w_beta(getMaterialProperty<Real>("w_beta")), // weight of beta phase
    _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
    _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
    _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
    _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor"))
{
}

void
BinaryRSApproximation::initialSetup()
{
  if (hasBlockMaterialProperty<RankTwoTensor>(_base_name + "strain_increment"))
    mooseError("This linear elastic stress calculation only works for small strains; use "
               "ComputeFiniteStrainElasticStress for simulations using incremental and finite "
               "strains.");
}

void
BinaryRSApproximation::computeQpStress()
{
  RankFourTensor compliance_alpha = _elasticity_tensor_alpha[_qp].invSymm();
  RankFourTensor compliance_beta = _elasticity_tensor_beta[_qp].invSymm();
  RankFourTensor compliance_RS = _w_alpha[_qp] * compliance_alpha + _w_beta[_qp] * compliance_beta;
  RankFourTensor elasticity_RS = compliance_RS.invSymm();

  _stress[_qp] = elasticity_RS * _mechanical_strain[_qp];

  _Jacobian_mult[_qp] = elasticity_RS;

  // elastic strain is unchanged
  _elastic_strain[_qp] = _mechanical_strain[_qp];
}

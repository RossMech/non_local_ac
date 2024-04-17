#include "BinaryElasticEnergyEigenstrain.h"
#include "RankTwoTensor.h"

registerMooseObject("NonLocalACApp", BinaryElasticEnergyEigenstrain);

InputParameters
BinaryElasticEnergyEigenstrain::validParams()
{
  InputParameters params = DerivativeFunctionMaterialBase::validParams();
  params.addClassDescription("Free energy material for the elastic energy contributions.");
  params.addRequiredCoupledVar("phase","Phase variable");
  params.addParam<std::string>("base_name", "Material property base name");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<MaterialPropertyName>("w_beta","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in phase alpha");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in phase beta");
  params.addRequiredParam<std::string>("mismatch_tensor","Mismatch tensor");
  params.addRequiredCoupledVar("args", "Arguments of F() - use vector coupling");
  params.addCoupledVar("displacement_gradients",
                       "Vector of displacement gradient variables (see "
                       "Modules/PhaseField/DisplacementGradients "
                       "action)");
  return params;
}

BinaryElasticEnergyEigenstrain::BinaryElasticEnergyEigenstrain(const InputParameters & parameters)
  : DerivativeFunctionMaterialBase(parameters),
    _u(coupledValue("phase")), // phase variable value
    _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
    _w_beta(getMaterialProperty<Real>("w_beta")), // weight of beta phase
    _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
    _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
    _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
    _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
    _eigenstrain_name_alpha(_base_name_alpha + getParam<std::string>("eigenstrain_name_alpha")),
    _eigenstrain_alpha(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_alpha)),
    _eigenstrain_name_beta(_base_name_beta + getParam<std::string>("eigenstrain_name_beta")),
    _eigenstrain_beta(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_beta)),
    _mismatch_tensor(getMaterialProperty<RankTwoTensor>("mismatch_tensor")),
    _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
    _strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "elastic_strain"))
{
}

void
BinaryElasticEnergyEigenstrain::initialSetup()
{
//  validateCoupling<RankTwoTensor>(_base_name + "elastic_strain");
}

Real
BinaryElasticEnergyEigenstrain::computeF()
{
  // Cutoff parameters for estimation either quadrature point is in bulk or interface
  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - lower_bound;

  Real elastic_energy = 0.0;
  if (_u[_qp] > upper_bound)
  {
    // Calculate stress
    RankTwoTensor stress_local = _elasticity_tensor_alpha[_qp] * (_strain[_qp] - _eigenstrain_alpha[_qp]);
    elastic_energy += stress_local.doubleContraction(_strain[_qp] - _eigenstrain_alpha[_qp]);
  }
  else if (_u[_qp] < lower_bound)
  {
    // Calculate stress
    RankTwoTensor stress_local = _elasticity_tensor_beta[_qp] * (_strain[_qp] - _eigenstrain_beta[_qp]);
    elastic_energy += stress_local.doubleContraction(_strain[_qp] - _eigenstrain_beta[_qp]);
  }
  else
  {
    // Strain distribution between phases
    RankTwoTensor strain_alpha = _strain[_qp] + _w_beta[_qp] * _mismatch_tensor[_qp];
    RankTwoTensor strain_beta = _strain[_qp] - _w_alpha[_qp] * _mismatch_tensor[_qp];

    // Stresses local in the phases
    RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * (strain_alpha - _eigenstrain_alpha[_qp]);
    RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * (strain_beta - _eigenstrain_beta[_qp]);

    // Elastic energy
    elastic_energy += _w_alpha[_qp] * stress_alpha.doubleContraction(strain_alpha - _eigenstrain_alpha[_qp]);
    elastic_energy += _w_beta[_qp] * stress_beta.doubleContraction(strain_beta - _eigenstrain_beta[_qp]);
  }

  elastic_energy *= 0.5;

  return elastic_energy;
}

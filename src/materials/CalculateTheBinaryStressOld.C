#include "CalculateTheBinaryStressOld.h"
#include <iostream>

registerMooseObject("TensorMechanicsApp", CalculateTheBinaryStressOld);

InputParameters
CalculateTheBinaryStressOld::validParams()
{
  InputParameters params = ComputeStressBase::validParams();
  params.addClassDescription("Compute stress using elasticity for small strains");
  params.addRequiredCoupledVar("phase","Phase variable");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<MaterialPropertyName>("w_beta","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredParam<MaterialPropertyName>("normal","Normal between two phases");
  return params;
}

CalculateTheBinaryStressOld::CalculateTheBinaryStressOld(const InputParameters & parameters)
  : ComputeStressBase(parameters),
    _u(coupledValue("phase")), // phase variable value
    _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
    _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
    _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
    _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
    _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
    _n(getMaterialProperty<RealGradient>("normal")),
    _mismatch_tensor(declareProperty<RankTwoTensor>("mismatch_tensor")),
    _strain_alpha(declareProperty<RankTwoTensor>("strain_alpha")),
    _strain_beta(declareProperty<RankTwoTensor>("strain_beta")),
    _stress_alpha(declareProperty<RankTwoTensor>("stress_alpha")),
    _stress_beta(declareProperty<RankTwoTensor>("stress_beta"))
{
}

void
CalculateTheBinaryStressOld::initialSetup()
{
  if (hasBlockMaterialProperty<RankTwoTensor>(_base_name + "strain_increment"))
    mooseError("This linear elastic stress calculation only works for small strains; use "
               "ComputeFiniteStrainElasticStress for simulations using incremental and finite "
               "strains.");
}

void
CalculateTheBinaryStressOld::computeQpStress()
{
  // Cutoff parameters for estimation either quadrature point is in bulk or interface
  const Real lower_bound = 1e-6;
  const Real upper_bound = 1.0 - lower_bound;

  // Zero tensor
  const RankTwoTensor Zero_tens;

  if (_u[_qp] > upper_bound) // Check if the point is inside the bulk of alpha phase
  {
    _stress[_qp] = _elasticity_tensor_alpha[_qp] * _mechanical_strain[_qp];
    _Jacobian_mult[_qp] = _elasticity_tensor_alpha[_qp];

    _stress_alpha[_qp] = _stress[_qp];
    _strain_alpha[_qp] = _mechanical_strain[_qp];

    _mismatch_tensor[_qp] = Zero_tens;
    _strain_beta[_qp] = Zero_tens;
    _stress_beta[_qp] = Zero_tens;
  }
  else if (_u[_qp] < lower_bound) // Check if the point is inside the bulk of beta phase
  {
    _stress[_qp] = _elasticity_tensor_beta[_qp] * _mechanical_strain[_qp];
    _Jacobian_mult[_qp] = _elasticity_tensor_beta[_qp];

    _stress_beta[_qp] = _stress[_qp];
    _strain_beta[_qp] = _mechanical_strain[_qp];

    _mismatch_tensor[_qp] = Zero_tens;
    _strain_alpha[_qp] = Zero_tens;
    _stress_alpha[_qp] = Zero_tens;
  }
  else
  {

    Real w_beta = 1 - _w_alpha[_qp];

    // Calculate delta_sigma_vector, which rhs of equation for a estimation
    const RankFourTensor delta_elasticity = _elasticity_tensor_alpha[_qp] - _elasticity_tensor_beta[_qp];

    RankTwoTensor sigma_delta = delta_elasticity * _mechanical_strain[_qp];
    RealGradient sigma_delta_vector = sigma_delta * _n[_qp];

    // Voigt-Taylor approximation of elasticity tensor
    RankFourTensor elasticity_VT = _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] + w_beta * _elasticity_tensor_beta[_qp];
    //_stress[_qp] = elasticity_VT * _mechanical_strain[_qp];

    _strain_alpha[_qp] = _mechanical_strain[_qp];
    _stress_alpha[_qp] = _elasticity_tensor_alpha[_qp] * _strain_alpha[_qp];

    _strain_beta[_qp] = _mechanical_strain[_qp];
    _stress_beta[_qp] = _elasticity_tensor_beta[_qp] * _strain_beta[_qp];

    _mismatch_tensor[_qp] = Zero_tens;

    _stress[_qp] = _stress_alpha[_qp] * _w_alpha[_qp] + _stress_beta[_qp] * w_beta;
    _Jacobian_mult[_qp] = elasticity_VT;
  }
  // elastic strain is unchanged
  _elastic_strain[_qp] = _mechanical_strain[_qp];
}

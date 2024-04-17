#include "BinaryConsistentElasticEnergyEigenstrain.h"
#include "RankTwoTensor.h"

registerMooseObject("NonLocalACApp", BinaryConsistentElasticEnergyEigenstrain);

InputParameters
BinaryConsistentElasticEnergyEigenstrain::validParams()
{
  InputParameters params = DerivativeFunctionMaterialBase::validParams();
  params.addClassDescription("Free energy material for the elastic energy contributions.");
  params.addParam<std::string>("base_name", "Material property base name");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredCoupledVar("eta", "Phase field variable");
  params.addRequiredParam<MaterialPropertyName>("mismatch_tensor","Mismatch tensor");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","Weight function of alpha phase");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in alpha phase");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in beta phase");
  params.addRequiredParam<MaterialPropertyName>("delta_elasticity","Difference in elasticity tensors of both phases");
  params.addRequiredParam<MaterialPropertyName>("elasticity_VT","VT approximation of elasticity tensor");
  return params;
}

BinaryConsistentElasticEnergyEigenstrain::BinaryConsistentElasticEnergyEigenstrain(const InputParameters & parameters)
      : DerivativeFunctionMaterialBase(parameters),
      _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
      _stress(getMaterialPropertyByName<RankTwoTensor>(_base_name + "stress")),
      _mechanical_strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "mechanical_strain")),
      _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
      _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
      _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
      _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
      _eigenstrain_name_alpha(_base_name_alpha + getParam<std::string>("eigenstrain_name_alpha")),
      _eigenstrain_alpha(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_alpha)),
      _eigenstrain_name_beta(_base_name_beta + getParam<std::string>("eigenstrain_name_beta")),
      _eigenstrain_beta(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_beta)),
      _delta_elasticity(getMaterialProperty<RankFourTensor>("delta_elasticity")),
      _elasticity_VT(getMaterialProperty<RankFourTensor>("elasticity_VT")),
      _eta(coupledValue("eta")),
      _eta_var(coupled("eta")),
      _eta_name(getVar("eta",0)->name()),
      _w_alpha(getMaterialProperty<Real>("w_alpha")),
      _dw_alpha_dop(getMaterialPropertyDerivative<Real>("w_alpha",_eta_name)),
      _d2w_alpha_d2op(getMaterialPropertyDerivative<Real>("w_alpha",_eta_name,_eta_name)),
      _mismatch_tensor(getMaterialProperty<RankTwoTensor>("mismatch_tensor")),
      _dmismatch_tensor_deta(getMaterialPropertyDerivative<RankTwoTensor>("mismatch_tensor",_eta_name,_eta_name))
{
}

Real
BinaryConsistentElasticEnergyEigenstrain::computeF()
{
  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - 1e-8;

  if (_eta[_qp] > upper_bound)
    return 0.5 * _stress[_qp].doubleContraction(_mechanical_strain[_qp] - _eigenstrain_alpha[_qp]);
  else if (_eta[_qp] < lower_bound)
    return 0.5 * _stress[_qp].doubleContraction(_mechanical_strain[_qp] - _eigenstrain_beta[_qp]);
  else
  {
    Real w_beta = 1 - _w_alpha[_qp];

    // Phase strains
    RankTwoTensor strain_el_alpha = _mechanical_strain[_qp] + w_beta * _mismatch_tensor[_qp] - _eigenstrain_alpha[_qp];
    RankTwoTensor strain_el_beta = _mechanical_strain[_qp] - _w_alpha[_qp] * _mismatch_tensor[_qp] - _eigenstrain_beta[_qp];

    // Phase stresses
    RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * strain_el_alpha;
    RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * strain_el_beta;

    return 0.5*(_stress[_qp].doubleContraction(_mechanical_strain[_qp])-_w_alpha[_qp]*stress_alpha.doubleContraction(_eigenstrain_alpha[_qp])-w_beta*stress_beta.doubleContraction(_eigenstrain_beta[_qp]));
  }
}

Real
BinaryConsistentElasticEnergyEigenstrain::computeDF(unsigned int i_var)
{
  if (i_var == _eta_var)
    {
      const Real lower_bound = 1e-8;
      const Real upper_bound = 1.0 - 1e-8;

      if ((_eta[_qp] > lower_bound) && (_eta[_qp] < upper_bound))
      {

        // Weight of beta phase
        Real w_beta = 1 - _w_alpha[_qp];

        // Phase strains
        RankTwoTensor strain_el_alpha = _mechanical_strain[_qp] + w_beta * _mismatch_tensor[_qp] - _eigenstrain_alpha[_qp];
        RankTwoTensor strain_el_beta = _mechanical_strain[_qp] - _w_alpha[_qp] * _mismatch_tensor[_qp] - _eigenstrain_beta[_qp];

        // Phase stresses
        RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * strain_el_alpha;
        RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * strain_el_beta;

        // Elastic energies
        Real W_alpha = 0.5 * stress_alpha.doubleContraction(strain_el_alpha);
        Real W_beta = 0.5 * stress_beta.doubleContraction(strain_el_beta);

        Real driving_force = W_alpha - W_beta - _stress[_qp].doubleContraction(_mismatch_tensor[_qp]);

        return _dw_alpha_dop[_qp] * driving_force;
      }
      else
        return 0.0;
    }
  else
    return 0.0;
}

Real
BinaryConsistentElasticEnergyEigenstrain::computeD2F(unsigned int i_var, unsigned int j_var)
{
  if ((i_var == _eta_var) && (j_var == _eta_var))
  {
    const Real lower_bound = 1e-8;
    const Real upper_bound = 1.0 - 1e-8;

    if ((_eta[_qp] > lower_bound) && (_eta[_qp] < upper_bound))
    {
      // Weight of beta phase
      Real w_beta = 1 - _w_alpha[_qp];

      // Phase strains
      RankTwoTensor strain_el_alpha = _mechanical_strain[_qp] + w_beta * _mismatch_tensor[_qp] - _eigenstrain_alpha[_qp];
      RankTwoTensor strain_el_beta = _mechanical_strain[_qp] - _w_alpha[_qp] * _mismatch_tensor[_qp] - _eigenstrain_beta[_qp];

      // Phase stresses
      RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * strain_el_alpha;
      RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * strain_el_beta;

      // Elastic energies
      Real W_alpha = 0.5 * stress_alpha.doubleContraction(strain_el_alpha);
      Real W_beta = 0.5 * stress_beta.doubleContraction(strain_el_beta);
      Real driving_force = W_alpha - W_beta - _stress[_qp].doubleContraction(_mismatch_tensor[_qp]);

      // difference of stress
      RankTwoTensor derivative_stress = _dw_alpha_dop[_qp] * _elasticity_VT[_qp] * _mismatch_tensor[_qp] -
                                      _w_alpha[_qp] * w_beta * _delta_elasticity[_qp] * _dmismatch_tensor_deta[_qp];

      Real ddriving_force_d_eta = derivative_stress.doubleContraction(_mismatch_tensor[_qp]);

      return _d2w_alpha_d2op[_qp]*driving_force + _dw_alpha_dop[_qp] * ddriving_force_d_eta;
    }
    else
      return 0.0;
  }
  else
    return 0.0;
}

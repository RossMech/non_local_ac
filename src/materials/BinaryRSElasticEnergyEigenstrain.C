#include "BinaryRSElasticEnergyEigenstrain.h"
#include "RankTwoTensor.h"

registerMooseObject("PhaseFieldApp", BinaryRSElasticEnergyEigenstrain);

InputParameters
BinaryRSElasticEnergyEigenstrain::validParams()
{
  InputParameters params = DerivativeFunctionMaterialBase::validParams();
  params.addClassDescription("Free energy material for the elastic energy contributions.");
  params.addParam<std::string>("base_name", "Material property base name");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredCoupledVar("eta", "Phase field variable");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","Weight function of alpha phase");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in alpha phase");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in beta phase");
  return params;
}

BinaryRSElasticEnergyEigenstrain::BinaryRSElasticEnergyEigenstrain(const InputParameters & parameters)
      : DerivativeFunctionMaterialBase(parameters),
      _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
      _stress(getMaterialPropertyByName<RankTwoTensor>(_base_name + "stress")),
      _elastic_strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "elastic_strain")),
      _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
      _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
      _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
      _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
      _eigenstrain_name_alpha(_base_name_alpha + getParam<std::string>("eigenstrain_name_alpha")),
      _eigenstrain_alpha(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_alpha)),
      _eigenstrain_name_beta(_base_name_beta + getParam<std::string>("eigenstrain_name_beta")),
      _eigenstrain_beta(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_beta)),
      _eta(coupledValue("eta")),
      _eta_var(coupled("eta")),
      _eta_name(getVar("eta",0)->name()),
      _w_alpha(getMaterialProperty<Real>("w_alpha")),
      _dw_alpha_dop(getMaterialPropertyDerivative<Real>("w_alpha",_eta_name)),
      _d2w_alpha_d2op(getMaterialPropertyDerivative<Real>("w_alpha",_eta_name,_eta_name))
{
}

Real
BinaryRSElasticEnergyEigenstrain::computeF()
{
  return 0.5*_stress[_qp].doubleContraction(_elastic_strain[_qp]);
}

Real
BinaryRSElasticEnergyEigenstrain::computeDF(unsigned int i_var)
{
  Real w_beta = 1 - _w_alpha[_qp];
  RankFourTensor compliance_alpha = _elasticity_tensor_alpha[_qp].invSymm();
  RankFourTensor compliance_beta = _elasticity_tensor_beta[_qp].invSymm();
  RankFourTensor compliance_RS = _w_alpha[_qp] * compliance_alpha + w_beta * compliance_beta;
  RankFourTensor elasticity_RS = compliance_RS.invSymm();

  RankFourTensor compliance_diff = compliance_alpha - compliance_beta;
  RankTwoTensor eigenstrain_diff = _eigenstrain_alpha[_qp] - _eigenstrain_beta[_qp];
  RankFourTensor stiffness_star = elasticity_RS * elasticity_RS * compliance_diff;

  Real delta = _elastic_strain[_qp].doubleContraction(2*elasticity_RS*eigenstrain_diff+stiffness_star*_elastic_strain[_qp]);
  return -0.5*_dw_alpha_dop[_qp]*delta;
}

Real
BinaryRSElasticEnergyEigenstrain::computeD2F(unsigned int i_var, unsigned int j_var)
{
    Real w_beta = 1 - _w_alpha[_qp];
  RankFourTensor compliance_alpha = _elasticity_tensor_alpha[_qp].invSymm();
  RankFourTensor compliance_beta = _elasticity_tensor_beta[_qp].invSymm();
  RankFourTensor compliance_RS = _w_alpha[_qp] * compliance_alpha + w_beta * compliance_beta;
  RankFourTensor elasticity_RS = compliance_RS.invSymm();

  RankFourTensor compliance_diff = compliance_alpha - compliance_beta;
  RankTwoTensor eigenstrain_diff = _eigenstrain_alpha[_qp] - _eigenstrain_beta[_qp];
  RankFourTensor stiffness_star = elasticity_RS * elasticity_RS * compliance_diff;

  Real delta = _elastic_strain[_qp].doubleContraction(2*elasticity_RS*eigenstrain_diff+stiffness_star*_elastic_strain[_qp]);

  RankTwoTensor stress_star = 2 * stiffness_star * _elastic_strain[_qp] + elasticity_RS * eigenstrain_diff;
  RankFourTensor stiffness_star_star = elasticity_RS * stiffness_star * compliance_diff;

  Real ddelta_deta = -2*_dw_alpha_dop[_qp]*
                    (stress_star.doubleContraction(eigenstrain_diff)+_elastic_strain[_qp].doubleContraction(stiffness_star_star*_elastic_strain[_qp]));

  return -0.5*(_d2w_alpha_d2op[_qp]*delta+_dw_alpha_dop[_qp]*ddelta_deta);
}

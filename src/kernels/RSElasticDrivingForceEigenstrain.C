#include "RSElasticDrivingForceEigenstrain.h"

#include "Material.h"
#include "RankFourTensor.h"
#include "RankTwoTensor.h"

registerMooseObject("NonLocalACApp", RSElasticDrivingForceEigenstrain);

InputParameters
RSElasticDrivingForceEigenstrain::validParams()
{
  InputParameters params = ACBulk<Real>::validParams();
  params.addClassDescription("Adds elastic energy contribution to the Allen-Cahn equation");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addParam<std::string>("base_name",
                               "Optional parameter that allows the user to define "
                               "multiple mechanics material systems on the same "
                               "block, i.e. for multiple phases");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in phase alpha");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in phase beta");
  params.suppressParameter<bool>("use_displaced_mesh");
  return params;
}

RSElasticDrivingForceEigenstrain::RSElasticDrivingForceEigenstrain(const InputParameters & parameters)
  : ACBulk<Real>(parameters),
  _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
  _dw_alpha_dop(getMaterialPropertyDerivative<Real>("w_alpha", _var.name())),
  _d2w_alpha_dop2(getMaterialPropertyDerivative<Real>("w_alpha", _var.name(),_var.name())),
  _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
  _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
  _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
  _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
  _base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
  _mechanical_strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "mechanical_strain")),
  _stress(getMaterialPropertyByName<RankTwoTensor>(_base_name + "stress")),
  _eigenstrain_name_alpha(_base_name_alpha + getParam<std::string>("eigenstrain_name_alpha")),
  _eigenstrain_alpha(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_alpha)),
  _eigenstrain_name_beta(_base_name_beta + getParam<std::string>("eigenstrain_name_beta")),
  _eigenstrain_beta(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_beta))
{
}

Real
RSElasticDrivingForceEigenstrain::computeDFDOP(PFFunctionType type)
{

  // Compliance tensors of phases
  RankFourTensor compliance_alpha = _elasticity_tensor_alpha[_qp].invSymm();
  RankFourTensor compliance_beta = _elasticity_tensor_beta[_qp].invSymm();

  // Compliance tensor of composite
  RankFourTensor compliance_RS = _w_alpha[_qp] * compliance_alpha + (1 - _w_alpha[_qp]) * compliance_beta;

  // Compliance difference between phases
  RankFourTensor compliance_diff = compliance_alpha - compliance_beta;
  
  // difference in eigenstrains
  RankTwoTensor eigenstrain_diff = _eigenstrain_alpha[_qp] - _eigenstrain_beta[_qp];

  // Stiffness tensor of composite
  RankFourTensor elasticity_RS = compliance_RS.invSymm();

  // Stiffness derivative
  RankFourTensor stiffness_derivative = (elasticity_RS*elasticity_RS)*compliance_diff;
  // driving force
  Real driving_force = 2*_stress[_qp].doubleContraction(eigenstrain_diff) + _mechanical_strain[_qp].doubleContraction(stiffness_derivative*_mechanical_strain[_qp]);


    switch (type)
    {
      case Residual:
        return -0.5 * _dw_alpha_dop[_qp] * driving_force;
      case Jacobian:
      {    
        RankTwoTensor stress_helper = 2 * stiffness_derivative*_mechanical_strain[_qp] + elasticity_RS * eigenstrain_diff;
        RankFourTensor stiffness_helper = (elasticity_RS * stiffness_derivative) * compliance_diff;

        Real d_driving_force_d_phi = -2 * _dw_alpha_dop[_qp] * (stress_helper.doubleContraction(eigenstrain_diff) + _mechanical_strain[_qp].doubleContraction(stiffness_helper*_mechanical_strain[_qp]));
        return -0.5* (_d2w_alpha_dop2[_qp] * driving_force + _dw_alpha_dop[_qp] * d_driving_force_d_phi)  * _phi[_j][_qp];
      }
    }

  mooseError("Invalid type passed in");
}

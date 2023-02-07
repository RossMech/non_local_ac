#include "BinaryElasticPropertiesHelper.h"

registerMooseObject("PhaseFieldApp", BinaryElasticPropertiesHelper);

InputParameters
BinaryElasticPropertiesHelper::validParams()
{
  InputParameters params = Material::validParams();
  params.addClassDescription("Elastic properties, used in the calculation of the binary thermodynamic consistent homogenization");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","Weight function of alpha phase");
  params.addRequiredParam<MaterialPropertyName>("normal","normal between phases");
  params.addRequiredParam<MaterialPropertyName>("delta_elasticity","Difference in elasticity tensors of both phases");
  params.addRequiredParam<MaterialPropertyName>("elasticity_VT","VT approximation of elasticity tensor");
  params.addRequiredParam<MaterialPropertyName>("S_wave","C_alpha*h_beta + C_beta*h_alpha inversed and normalized to second order tensor");
  params.addRequiredCoupledVar("eta","Phase field variable");
  return params;
}

BinaryElasticPropertiesHelper::BinaryElasticPropertiesHelper(const InputParameters & parameters)
    : Material(parameters),
    _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
    _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
    _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
    _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
    _w_alpha(getMaterialProperty<Real>("w_alpha")),
    _n(getMaterialProperty<RealGradient>("normal")),
    _delta_elasticity(declareProperty<RankFourTensor>("delta_elasticity")),
    _elasticity_VT(declareProperty<RankFourTensor>("elasticity_VT")),
    _S_wave_2(declareProperty<RankTwoTensor>("S_wave")),
    _eta(coupledValue("eta"))
{
}

void
BinaryElasticPropertiesHelper::computeQpProperties()
{

  Real w_beta = 1 - _w_alpha[_qp];

  _delta_elasticity[_qp] = _elasticity_tensor_alpha[_qp] - _elasticity_tensor_beta[_qp];
  _elasticity_VT[_qp] = _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] + w_beta * _elasticity_tensor_beta[_qp];

  const RankFourTensor C_wave = _w_alpha[_qp] * _elasticity_tensor_beta[_qp] + w_beta * _elasticity_tensor_alpha[_qp];

  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - lower_bound;

  if ((_eta[_qp] < upper_bound) && (_eta[_qp] > lower_bound))
  {
    Real C_wave_2_array[3][3] = {};

    RankTwoTensor N_tens;
    N_tens.vectorOuterProduct(_n[_qp],_n[_qp]);

    unsigned int n_dim = LIBMESH_DIM;
    for (unsigned int i=0; i < n_dim;i++)
    {
      for (unsigned int j=0; j < n_dim;j++)
      {
        for (unsigned int k=0; k < n_dim;k++)
        {
          for (unsigned int l=0; l< n_dim;l++)
          {
            C_wave_2_array[i][l] += N_tens(k,j) * C_wave(i,j,k,l);
          }
        }
      }
    }

    RankTwoTensor C_wave_2;
    C_wave_2 = RankTwoTensor(C_wave_2_array[0][0],C_wave_2_array[1][1],C_wave_2_array[2][2],C_wave_2_array[1][2],C_wave_2_array[0][2],C_wave_2_array[0][1]);

    _S_wave_2[_qp] = C_wave_2.inverse();
  }
  else
    _S_wave_2[_qp] = 0;

}

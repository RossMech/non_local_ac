#include "CalculateTheBinaryStressEigenstrain.h"
#include <iostream>

registerMooseObject("TensorMechanicsApp", CalculateTheBinaryStressEigenstrain);

InputParameters
CalculateTheBinaryStressEigenstrain::validParams()
{
  InputParameters params = ComputeStressBase::validParams();
  params.addClassDescription("Compute stress using elasticity for small strains");
  params.addRequiredCoupledVar("phase","Phase variable");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<MaterialPropertyName>("w_beta","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in phase alpha");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in phase beta");
  params.addRequiredParam<MaterialPropertyName>("normal","Normal between two phases");
  return params;
}

CalculateTheBinaryStressEigenstrain::CalculateTheBinaryStressEigenstrain(const InputParameters & parameters)
  : ComputeStressBase(parameters),
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
    _n(getMaterialProperty<RealGradient>("normal")),
    _mismatch_tensor(declareProperty<RankTwoTensor>("mismatch_tensor"))
{
}

void
CalculateTheBinaryStressEigenstrain::initialSetup()
{
  if (hasBlockMaterialProperty<RankTwoTensor>(_base_name + "strain_increment"))
    mooseError("This linear elastic stress calculation only works for small strains; use "
               "ComputeFiniteStrainElasticStress for simulations using incremental and finite "
               "strains.");
}

void
CalculateTheBinaryStressEigenstrain::computeQpStress()
{
  // Cutoff parameters for estimation either quadrature point is in bulk or interface
  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - lower_bound;

  if (_u[_qp] > upper_bound) // Check if the point is inside the bulk of alpha phase
  {
    _stress[_qp] = _elasticity_tensor_alpha[_qp] * (_mechanical_strain[_qp] - _eigenstrain_alpha[_qp]);
    _Jacobian_mult[_qp] = _elasticity_tensor_alpha[_qp];
  }
  else if (_u[_qp] < lower_bound) // Check if the point is inside the bulk of beta phase
  {
    _stress[_qp] = _elasticity_tensor_beta[_qp] * (_mechanical_strain[_qp] - _eigenstrain_beta[_qp]);
    _Jacobian_mult[_qp] = _elasticity_tensor_beta[_qp];
  }
  else
  {
    // Calculate delta_sigma_vector, which rhs of equation for a estimation
    const RankFourTensor delta_elasticity = _elasticity_tensor_alpha[_qp] - _elasticity_tensor_beta[_qp];
    RankTwoTensor delta_sigma = delta_elasticity * _mechanical_strain[_qp]
                                - _elasticity_tensor_alpha[_qp] * _eigenstrain_alpha[_qp]
                                + _elasticity_tensor_beta[_qp] * _eigenstrain_beta[_qp];

    const RealGradient delta_sigma_vect = delta_sigma * _n[_qp];

    // Calculate the system matrix (tensor) for calculation of the mismatch vector (which is responsible for strain redistribution between phases)
    const RankFourTensor wave_elasticity = _w_alpha[_qp]*_elasticity_tensor_beta[_qp] + _w_beta[_qp]*_elasticity_tensor_alpha[_qp];

    const RankThreeTensor wave_elasticity_3 = wave_elasticity.mixedProductIjklJ(_n[_qp]);

    unsigned int n_dim = LIBMESH_DIM;

    Real wave_elasticity_2_array[3][3];

    for (unsigned int i = 0; i < n_dim; i++)
      {
        for (unsigned int j = 0; j < n_dim; j++)
        {
          Real mult_result = 0.0;
          for (unsigned int k = 0; k < n_dim; k++)
            mult_result += wave_elasticity_3(i,j,k) * _n[_qp](k);

          wave_elasticity_2_array[i][j] = mult_result;
        }

      }

      // Construction of rank two tensor for access to the built-in inversion method
      const RankTwoTensor wave_elasticity_2(wave_elasticity_2_array[0][0],wave_elasticity_2_array[1][1],
                                            wave_elasticity_2_array[2][2],wave_elasticity_2_array[2][1],
                                            wave_elasticity_2_array[2][0],wave_elasticity_2_array[1][0]);
      const RankTwoTensor wave_elasticity_2_inv = wave_elasticity_2.inverse();

      // Mismatch vector
      const RealGradient a_vect = - wave_elasticity_2_inv * delta_sigma_vect;

      // Calculation of mismatch strain tensor
      _mismatch_tensor[_qp].vectorOuterProduct(a_vect,_n[_qp]);
      _mismatch_tensor[_qp] += _mismatch_tensor[_qp].transpose();
      _mismatch_tensor[_qp] *= 0.5;

      // Approximation of elasticity tensor with Voigt-Taylor method
      RankFourTensor elasticity_VT = _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] + _w_beta[_qp] * _elasticity_tensor_beta[_qp];

      // Elastic stress of binary mixture
      _stress[_qp] = elasticity_VT * _mechanical_strain[_qp]
                      + delta_elasticity * _w_alpha[_qp] * _w_beta[_qp] * _mismatch_tensor[_qp]
                      - _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] * _eigenstrain_alpha[_qp]
                      - _w_beta[_qp] * _elasticity_tensor_beta[_qp] * _eigenstrain_beta[_qp];

                      RankThreeTensor delta_elasticity_3 = delta_elasticity.mixedProductIjklJ(_n[_qp]);
                      Real da_depsilon_array[3][3][3] = {};



                      for (unsigned int i=0; i < n_dim;i++)
                      {
                        for (unsigned int j=0; j < n_dim;j++)
                        {
                          for (unsigned int k=0; k < n_dim;k++)
                          {
                            for (unsigned int l=0; l < n_dim;l++)
                            {
                              da_depsilon_array[i][k][l] += wave_elasticity_2_inv(i,j) * delta_elasticity_3(j,k,l);
                            }
                          }
                        }
                      }

                      std::vector<Real> mismatch_contribution_vector(81);
                      unsigned int m = 0;
                      for (unsigned int i=0; i < 3; i++)
                      {
                        for (unsigned int j=0; j < 3; j++)
                        {
                          for (unsigned int k=0; k < 3; k++)
                          {
                            for (unsigned int l=0; l < 3; l++)
                            {
                              mismatch_contribution_vector[m] += _n[_qp](i)*da_depsilon_array[j][k][l];
                              m++;
                            }
                          }
                        }
                      }

                      RankFourTensor mismatch_contribution(mismatch_contribution_vector,RankFourTensor::general);
                      mismatch_contribution += mismatch_contribution.transposeIj();

                     _Jacobian_mult[_qp] = elasticity_VT - 0.5 * _w_alpha[_qp] * _w_beta[_qp] * delta_elasticity * mismatch_contribution;
  }
  // elastic strain is unchanged
  _elastic_strain[_qp] = _mechanical_strain[_qp];
}

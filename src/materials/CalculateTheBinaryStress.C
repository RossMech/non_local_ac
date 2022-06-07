#include "CalculateTheBinaryStress.h"
#include <iostream>

registerMooseObject("TensorMechanicsApp", CalculateTheBinaryStress);

InputParameters
CalculateTheBinaryStress::validParams()
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

CalculateTheBinaryStress::CalculateTheBinaryStress(const InputParameters & parameters)
  : ComputeStressBase(parameters),
    _u(coupledValue("phase")), // phase variable value
    _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
    _w_beta(getMaterialProperty<Real>("w_beta")), // weight of beta phase
    _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
    _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
    _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
    _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
    _n(getMaterialProperty<RealGradient>("normal"))
{
}

void
CalculateTheBinaryStress::initialSetup()
{
  if (hasBlockMaterialProperty<RankTwoTensor>(_base_name + "strain_increment"))
    mooseError("This linear elastic stress calculation only works for small strains; use "
               "ComputeFiniteStrainElasticStress for simulations using incremental and finite "
               "strains.");
}

void
CalculateTheBinaryStress::computeQpStress()
{
  // Cutoff parameters for estimation either quadrature point is in bulk or interface
  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - lower_bound;

  if (_u[_qp] > upper_bound) // Check if the point is inside the bulk of alpha phase
  {
    _stress[_qp] = _elasticity_tensor_alpha[_qp] * _mechanical_strain[_qp];
    _Jacobian_mult[_qp] = _elasticity_tensor_alpha[_qp];
  }
  else if (_u[_qp] < lower_bound) // Check if the point is inside the bulk of beta phase
  {
    _stress[_qp] = _elasticity_tensor_beta[_qp] * _mechanical_strain[_qp];
    _Jacobian_mult[_qp] = _elasticity_tensor_beta[_qp];
  }
  else
  {
    // Calculate delta_sigma_vector, which rhs of equation for a estimation
    const RankFourTensor delta_elasticity = _elasticity_tensor_alpha[_qp] - _elasticity_tensor_beta[_qp];
    const RankTwoTensor delta_sigma = delta_elasticity * _mechanical_strain[_qp];
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
      RankTwoTensor mismatch_tensor;
      mismatch_tensor.vectorOuterProduct(a_vect,_n[_qp]);
      mismatch_tensor += mismatch_tensor.transpose();
      mismatch_tensor *= 0.5;

      // Approximation of elasticity tensor with Voigt-Taylor method
      RankFourTensor elasticity_VT = _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] + _w_beta[_qp] * _elasticity_tensor_beta[_qp];

      // Elastic stress of binary mixture
      _stress[_qp] = elasticity_VT * _mechanical_strain[_qp]
                      + delta_elasticity * _w_alpha[_qp] * _w_beta[_qp] * mismatch_tensor;

      // Following calculations are used for the approximation of Jacobian

      // Calculation of elasticity tensor based on Reuss-Sachs method
      RankFourTensor compliance_alpha = _elasticity_tensor_alpha[_qp].invSymm();
      RankFourTensor compliance_beta = _elasticity_tensor_beta[_qp].invSymm();
      RankFourTensor compliance_RS = _w_alpha[_qp] * compliance_alpha + _w_beta[_qp] * compliance_beta;
      RankFourTensor elasticity_RS = compliance_RS.invSymm();

      // Stresses resulted from both bound-approximations
      RankTwoTensor stress_VT = elasticity_VT * _mechanical_strain[_qp];
      RankTwoTensor stress_RS = elasticity_RS * _mechanical_strain[_qp];

      // Errors of approximations
      RankTwoTensor delta_VT = stress_VT - _stress[_qp];
      RankTwoTensor delta_RS = stress_RS - _stress[_qp];

      // Scalar measure -> L2-norms of error tensors
      Real delta_VT_norm = delta_VT.L2norm();
      Real delta_RS_norm = delta_RS.L2norm();

      // use one of the bound approximations, when error is smaller
      if (delta_RS_norm < delta_VT_norm)
        _Jacobian_mult[_qp] = elasticity_RS;
      else
        _Jacobian_mult[_qp] = elasticity_VT;


  }
  // elastic strain is unchanged
  _elastic_strain[_qp] = _mechanical_strain[_qp];
}

#include "CalculateTheBinaryStressEigenstrain.h"
#include <iostream>
#include <cstdlib>

registerMooseObject("NonLocalACApp", CalculateTheBinaryStressEigenstrain);

InputParameters
CalculateTheBinaryStressEigenstrain::validParams()
{
  InputParameters params = ComputeStressBase::validParams();
  params.addClassDescription("Compute stress using elasticity for small strains");
  params.addRequiredCoupledVar("phase","Phase variable");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredParam<MaterialPropertyName>("normal","Normal between two phases");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in alpha phase");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in beta phase");
  params.addRequiredParam<MaterialPropertyName>("delta_elasticity","Difference in elasticity tensors of both phases");
  params.addRequiredParam<MaterialPropertyName>("elasticity_VT","VT approximation of elasticity tensor");
  params.addRequiredParam<MaterialPropertyName>("S_wave","C_alpha*h_beta + C_beta*h_alpha inversed and normalized to second order tensor");
  params.addRequiredParam<MaterialPropertyName>("mismatch_tensor","Mismatch_strain");
  return params;
}

CalculateTheBinaryStressEigenstrain::CalculateTheBinaryStressEigenstrain(const InputParameters & parameters)
  : ComputeStressBase(parameters),
    _u(coupledValue("phase")), // phase variable value
    _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
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
    _S_wave_2(getMaterialProperty<RankTwoTensor>("S_wave")),
    _n(getMaterialProperty<RealGradient>("normal")),
    _mismatch_tensor(getMaterialProperty<RankTwoTensor>("mismatch_tensor"))
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

    Real w_beta = 1 - _w_alpha[_qp];
    // Elastic stress of binary mixture
    _stress[_qp] = _elasticity_VT[_qp] * _mechanical_strain[_qp] + _w_alpha[_qp]* w_beta * _delta_elasticity[_qp] * _mismatch_tensor[_qp]
                   - _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] * _eigenstrain_alpha[_qp]
                   - w_beta * _elasticity_tensor_beta[_qp] * _eigenstrain_beta[_qp];

    //////////////////////////////////////////////////////////////////////////////////
    // Check the momentum balance condition on interface
    RankTwoTensor strain_el_alpha = _mechanical_strain[_qp] + w_beta*_mismatch_tensor[_qp] - _eigenstrain_alpha[_qp]; 
    RankTwoTensor strain_el_beta = _mechanical_strain[_qp] - _w_alpha[_qp]*_mismatch_tensor[_qp] - _eigenstrain_beta[_qp];

    RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * strain_el_alpha;
    RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * strain_el_beta;

    RealVectorValue a_error_vect = (stress_alpha - stress_beta) * _n[_qp];

    Real a_error = a_error_vect * a_error_vect;

    //std::cout << "a_error = " << a_error << "\n";

    if (a_error > 1e-8)
      std::cout << "Mismatch error is big!";

    //////////////////////////////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // Calculation of Jacobian
    // Multiplication with normal vector

    unsigned int n_dim = LIBMESH_DIM;

    Real delta_elasticity_3_array[3][3][3] = {};

    for (unsigned int i=0; i < n_dim; i++)
      for (unsigned int j=0; j < n_dim; j++)
        for (unsigned int k=0; k < n_dim; k++)
          for (unsigned int l=0; l < n_dim; l++)
            delta_elasticity_3_array[i][k][l] += _delta_elasticity[_qp](i,j,k,l) * _n[_qp](j); 

    Real da_depsilon_array[3][3][3] = {};


    for (unsigned int i=0; i < n_dim;i++)
    {
      for (unsigned int j=0; j < n_dim;j++)
      {
        for (unsigned int k=0; k < n_dim;k++)
        {
          for (unsigned int l=0; l < n_dim;l++)
          {
            da_depsilon_array[i][k][l] += _S_wave_2[_qp](i,j) * delta_elasticity_3_array[j][k][l];
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


    _Jacobian_mult[_qp] = _elasticity_VT[_qp] - 0.5 * _w_alpha[_qp] * w_beta * _delta_elasticity[_qp] * mismatch_contribution;
  }
  // elastic strain is unchanged
  _elastic_strain[_qp] = _mechanical_strain[_qp];
}

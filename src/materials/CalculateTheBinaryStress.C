#include "CalculateTheBinaryStress.h"

registerMooseObject("NonLocalACApp", CalculateTheBinaryStress);

InputParameters
CalculateTheBinaryStress::validParams()
{
  InputParameters params = ComputeStressBase::validParams();
  params.addClassDescription("Compute stress using elasticity for small strains");
  params.addRequiredCoupledVar("phase","Phase variable");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addRequiredParam<MaterialPropertyName>("normal","Normal between two phases");
  params.addRequiredParam<std::string>("mismatch_tensor","mismatch strain between phases on the interface");
  params.addRequiredParam<MaterialPropertyName>("delta_elasticity","Difference in elasticity tensors");
  params.addRequiredParam<MaterialPropertyName>("elasticity_VT","VT approximation of elasticity tensor");
  params.addRequiredParam<MaterialPropertyName>("S_wave","C_alpha*h_beta + C_beta*h_alpha inversed and normalized to second order tensor");
  return params;
}

CalculateTheBinaryStress::CalculateTheBinaryStress(const InputParameters & parameters)
  : ComputeStressBase(parameters),
    _u(coupledValue("phase")), // phase variable value
    _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
    _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
    _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
    _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
    _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
    _delta_elasticity(getMaterialProperty<RankFourTensor>("delta_elasticity")),
    _elasticity_VT(getMaterialProperty<RankFourTensor>("elasticity_VT")),
    _S_wave_2(getMaterialProperty<RankTwoTensor>("S_wave")),
    _n(getMaterialProperty<RealGradient>("normal")),
    _mismatch_tensor(getMaterialProperty<RankTwoTensor>("mismatch_tensor"))
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

    Real w_beta = 1 - _w_alpha[_qp];

   // Calculate delta_sigma_vector, which rhs of equation for a estimation
    // Elastic stress of binary mixture
    _stress[_qp] = _elasticity_VT[_qp] * _mechanical_strain[_qp] + _w_alpha[_qp]* w_beta * _delta_elasticity[_qp] * _mismatch_tensor[_qp];

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

#include "ConsistentElasticDrivingForceEigenstrain.h"

#include "Material.h"
#include "RankFourTensor.h"
#include "RankTwoTensor.h"

registerMooseObject("PhaseFieldApp", ConsistentElasticDrivingForceEigenstrain);

InputParameters
ConsistentElasticDrivingForceEigenstrain::validParams()
{
  InputParameters params = ACBulk<Real>::validParams();
  params.addClassDescription("Adds elastic energy contribution to the Allen-Cahn equation");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<MaterialPropertyName>("mismatch_tensor","the mismatch tensor, which results in different strain values in matrix");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  params.addParam<std::string>("base_name",
                               "Optional parameter that allows the user to define "
                               "multiple mechanics material systems on the same "
                               "block, i.e. for multiple phases");
  params.addRequiredParam<MaterialPropertyName>("normal","Normal between two phases");
  params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrain name in phase alpha");
  params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrain name in phase beta");
  params.suppressParameter<bool>("use_displaced_mesh");
  return params;
}

ConsistentElasticDrivingForceEigenstrain::ConsistentElasticDrivingForceEigenstrain(const InputParameters & parameters)
  : ACBulk<Real>(parameters),
  _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
  _dw_alpha_dop(getMaterialPropertyDerivative<Real>("w_alpha", _var.name())),
  _d2w_alpha_dop2(getMaterialPropertyDerivative<Real>("w_alpha", _var.name(),_var.name())),
  _mismatch_tensor(getMaterialProperty<RankTwoTensor>("mismatch_tensor")),
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
  _eigenstrain_beta(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_beta)),
  _n(getMaterialProperty<RealGradient>("normal"))
{
}

Real
ConsistentElasticDrivingForceEigenstrain::computeDFDOP(PFFunctionType type)
{
  // Cutoff parameters for estimation either quadrature point is in bulk or interface
  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - lower_bound;

  if ((_u[_qp] > lower_bound) && (_u[_qp] < upper_bound))
  {

    // Phase deformations
    RankTwoTensor epsilon_alpha = _mechanical_strain[_qp] + (1-_w_alpha[_qp])*_mismatch_tensor[_qp];
    RankTwoTensor epsilon_beta = _mechanical_strain[_qp] - _w_alpha[_qp]*_mismatch_tensor[_qp];

    // Phase deformations
    RankTwoTensor epsilon_el_alpha = epsilon_alpha - _eigenstrain_alpha[_qp]; 
    RankTwoTensor epsilon_el_beta = epsilon_beta - _eigenstrain_beta[_qp]; 

    // Phase stresses
    RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * epsilon_el_alpha;
    RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * epsilon_el_beta;

    // Elastc energies
    Real W_alpha = 0.5 * stress_alpha.doubleContraction(epsilon_el_alpha);
    Real W_beta = 0.5 * stress_beta.doubleContraction(epsilon_el_beta);

    // Difference between energies
    Real W_diff = W_alpha - W_beta;

    // Second term of the driving force
    Real second_term = _stress[_qp].doubleContraction(_mismatch_tensor[_qp]);

    // Driving force
    Real driving_force = W_diff - second_term;

    switch (type)
    {
      case Residual:
        return _dw_alpha_dop[_qp] * driving_force;
      case Jacobian:

        ////////////////////////////////////////////////////////////////////////
        // Calculation of da_dphi
        ////////////////////////////////////////////////////////////////////////
        RankFourTensor delta_elasticity = _elasticity_tensor_alpha[_qp] - _elasticity_tensor_beta[_qp];
        RankTwoTensor delta_sigma = delta_elasticity * _mechanical_strain[_qp] -
				    _elasticity_tensor_alpha[_qp] * _eigenstrain_alpha[_qp] +
				    _elasticity_tensor_beta[_qp] * _eigenstrain_beta[_qp];
        RealGradient delta_sigma_vect = delta_sigma * _n[_qp];

        // C_wave_2 derivative
        RankFourTensor dCwave_dphi = - delta_elasticity * _dw_alpha_dop[_qp];

        const RankThreeTensor dCwave_dphi_3 = dCwave_dphi.mixedProductIjklJ(_n[_qp]);

        unsigned int n_dim = LIBMESH_DIM;

        Real dCwave_dphi_2_array[3][3] = {};

        for (unsigned int i = 0; i < n_dim; i++)
        {
          for (unsigned int j = 0; j < n_dim; j++)
          {
            Real mult_result = 0.0;
            for (unsigned int k = 0; k < n_dim; k++)
              mult_result += dCwave_dphi_3(i,j,k) * _n[_qp](k);

              dCwave_dphi_2_array[i][j] = mult_result;
            }
          }

          const RankTwoTensor dCwave_dphi_2(dCwave_dphi_2_array[0][0],dCwave_dphi_2_array[1][1],
                                            dCwave_dphi_2_array[2][2],dCwave_dphi_2_array[2][1],
                                            dCwave_dphi_2_array[2][0],dCwave_dphi_2_array[1][0]);

    // S_wave_2
    // Calculate the system matrix (tensor) for calculation of the mismatch vector (which is responsible for strain redistribution between phases)
    const RankFourTensor wave_elasticity = _w_alpha[_qp]*_elasticity_tensor_beta[_qp] + (1 - _w_alpha[_qp])*_elasticity_tensor_alpha[_qp];

    const RankThreeTensor wave_elasticity_3 = wave_elasticity.mixedProductIjklJ(_n[_qp]);

    Real wave_elasticity_2_array[3][3] = {};

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

      // Calculation of the prefactor for a derivative
      RankTwoTensor da_prefac = wave_elasticity_2_inv * dCwave_dphi_2 * wave_elasticity_2_inv;

      RealGradient da_dphi = - da_prefac * delta_sigma_vect;
      //////////////////////////////////////////////////////////////////////////

      // Derivative of mismatch_tensor to order parameter
      RankTwoTensor deps_mism_dphi;
      deps_mism_dphi.vectorOuterProduct(da_dphi,_n[_qp]);
      deps_mism_dphi += deps_mism_dphi.transpose();
      deps_mism_dphi *= 0.5;

      // Derivative of stress to order parameter
      RankFourTensor elasticity_VT = _w_alpha[_qp] * _elasticity_tensor_alpha[_qp] + (1 - _w_alpha[_qp]) * _elasticity_tensor_beta[_qp];
      RankTwoTensor dsigma_dphi = _dw_alpha_dop[_qp] * (stress_alpha - stress_beta - elasticity_VT*_mismatch_tensor[_qp]) +
          _w_alpha[_qp]*(1-_w_alpha[_qp])*delta_elasticity*deps_mism_dphi;

      // dW_diff_dphi
      RankTwoTensor wave_stress = (_w_alpha[_qp]*stress_beta + (1-_w_alpha[_qp])*stress_alpha);
      Real dW_diff_dphi = wave_stress.doubleContraction(deps_mism_dphi)-_dw_alpha_dop[_qp]*deps_mism_dphi.doubleContraction(stress_alpha - stress_beta);

      // d_driving_force_d_phi
      Real d_driving_force_d_phi = dW_diff_dphi - (dsigma_dphi.doubleContraction(_mismatch_tensor[_qp])+_stress[_qp].doubleContraction(deps_mism_dphi));

      return (_d2w_alpha_dop2[_qp] * driving_force + _dw_alpha_dop[_qp] * d_driving_force_d_phi)  * _phi[_j][_qp];
    }
  }
  else
  {
    switch (type)
    {
      case Residual:
        return 0.0;
      case Jacobian:
        return 0.0;
    }
  }

  mooseError("Invalid type passed in");
}

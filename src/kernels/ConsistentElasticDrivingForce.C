#include "ConsistentElasticDrivingForce.h"

#include "Material.h"
#include "RankFourTensor.h"
#include "RankTwoTensor.h"

registerMooseObject("PhaseFieldApp", ConsistentElasticDrivingForce);

InputParameters
ConsistentElasticDrivingForce::validParams()
{
  InputParameters params = ACBulk<Real>::validParams();
  params.addClassDescription("Adds thermodynamic consistent elastic driving force to the Allen-Cahn equation");
  params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight");
  params.addRequiredParam<std::string>("base_name","Global base name");
  params.addRequiredParam<MaterialPropertyName>("mismatch_tensor","vector of mismatch, which results in different strains in phases");
  params.addRequiredParam<std::string>("base_name_alpha","Elasticity tensor of alpha phase eta = 1");
  params.addRequiredParam<std::string>("base_name_beta","Elasticity tensor of alpha phase eta = 0");
  return params;
}

ConsistentElasticDrivingForce::ConsistentElasticDrivingForce(const InputParameters & parameters)
  : ACBulk<Real>(parameters),
  _base_name(getParam<std::string>("base_name") + "_"),
  _mechanical_strain(getMaterialPropertyByName<RankTwoTensor>(_base_name+"mechanical_strain")),
  _stress(getMaterialPropertyByName<RankTwoTensor>(_base_name+"stress")),
  _mismatch_tensor(getMaterialProperty<RankTwoTensor>("mismatch_tensor")),
  _base_name_alpha(getParam<std::string>("base_name_alpha") + "_"), // read the elasticity tensor of alpha phase
  _elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
  _base_name_beta(getParam<std::string>("base_name_beta") + "_"), // read the elasticity tensor of beta phase
  _elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
  _w_alpha(getMaterialProperty<Real>("w_alpha")), // weight of alpha phase
  _dw_alpha_dop(getMaterialPropertyDerivative<Real>("w_alpha", _var.name())),
  _u(coupledValue(_var.name()))
{
}

Real
ConsistentElasticDrivingForce::computeDFDOP(PFFunctionType type)
{
  // Cutoff parameters for estimation either quadrature point is in bulk or interface
  const Real lower_bound = 1e-8;
  const Real upper_bound = 1.0 - lower_bound;

  // Compute the partial derivative of the stress wrt the order parameter
  //RankTwoTensor D_stress = _D_elastic_tensor[_qp] * strain;

  switch (type)
  {
    case Residual:
      // Check if code is performed on interface or in bulk
      if ((_u[_qp] > lower_bound) && (_u[_qp] < upper_bound))
      {
        // Phase deformations
        RankTwoTensor epsilon_alpha = _mechanical_strain[_qp] + (1-_w_alpha[_qp])*_mismatch_tensor[_qp];
        RankTwoTensor epsilon_beta = _mechanical_strain[_qp] - _w_alpha[_qp]*_mismatch_tensor[_qp];

        // Phase stresses
        RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * epsilon_alpha;
        RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * epsilon_beta;

        // Elastc energies
        Real W_alpha = 0.5 * stress_alpha.doubleContraction(epsilon_alpha);
        Real W_beta = 0.5 * stress_beta.doubleContraction(epsilon_beta);

        // Difference between energies
        Real W_diff = W_alpha - W_beta;

        // Second term of the driving force
        Real second_term = 0.5 * _stress[_qp].doubleContraction(_mismatch_tensor[_qp]);

        return _dw_alpha_dop[_qp] * (W_diff - second_term);
      }
      else
        return 0.0;
    case Jacobian:
      return 0.0;
  }

  mooseError("Invalid type passed in");
}

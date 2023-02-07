#include "BinaryElasticDrivingForceMaterial.h"

registerMooseObject("PhaseFieldApp", BinaryElasticDrivingForceMaterial);

InputParameters
BinaryElasticDrivingForceMaterial::validParams()
{
	InputParameters params = Material::validParams();
	params.addClassDescription("Calculation of elastic driving force in material for volume conservation kernel");
	params.addRequiredParam<MaterialPropertyName>("dw_alpha_deta","derivative of scalar weight function");
	params.addRequiredParam<MaterialPropertyName>("mismatch_tensor","the mismatch tensor, which results in different strain values in phases");
	params.addRequiredParam<MaterialPropertyName>("base_name_alpha","Base name for phase alpha");
	params.addRequiredParam<MaterialPropertyName>("base_name_beta","Base name for phase beta");
	params.addRequiredParam<MaterialPropertyName>("base_name","Global base name for mechanical properties");
	params.addRequiredCoupledVar("eta","phase variable");
	return params;
}

BinaryElasticDrivingForceMaterial::BinaryElasticDrivingForceMaterial(const InputParameters & parameters)
	: Material(parameters),
	_w_alpha(getMaterialProperty<Real>("w_alpha")),
	_dw_alpha_deta(getMaterialProperty<Real>("dw_alpha_deta")),
	_mismatch_tensor(getMaterialProperty<RankTwoTensor>("_mismatch_tensor")),
	_base_name_alpha(getParam<std::string>("base_name_alpha")+"_"),
	_elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
	_base_name_beta(getParam<std::string>("base_name_beta")+"_"),
	_elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
	_base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
	_mechanical_strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "mechanical_strain")),
	_stress(getMaterialPropertyByName<RankTwoTensor>(_base_name + "stress")),
	_u(coupledValue("eta")),
	_el_driving_force(declareProperty<Real>("el_driving_force"))
{
}

void
BinaryElasticDrivingForceMaterial::computeQpProperties()
{
	// Cutoff parameters
	const Real lower_bound = 1e-8;
	const Real upper_bound = 1 - lower_bound;

	if ((_u[_qp] > lower_bound) & (_u[_qp] < upper_bound))
	{
		// Phase deformations
		RankTwoTensor epsilon_alpha = _mechanical_strain[_qp] + (1 - _w_alpha[_qp])*_mismatch_tensor[_qp];
		RankTwoTensor epsilon_beta = _mechanical_strain[_qp] -   _w_alpha[_qp]*_mismatch_tensor[_qp];

		// Phase stresses
		RankTwoTensor stress_alpha = _elasticity_tensor_alpha[_qp] * epsilon_alpha;
		RankTwoTensor stress_beta = _elasticity_tensor_beta[_qp] * epsilon_beta;

		// Elastic energies
		Real W_alpha = 0.5 * stress_alpha.doubleContraction(epsilon_alpha);
		Real W_beta = 0.5 * stress_beta.doubleContraction(epsilon_beta);

		// Difference between energies
		Real W_diff = W_alpha - W_beta;

		// Secound term of the driving force
		Real second_term = _stress[_qp].doubleContraction(_mismatch_tensor[_qp]);

		// Driving force
		_el_driving_force[_qp] = _dw_alpha_deta[_qp] * (W_diff - second_term);	
	}
	else
		_el_driving_force[_qp] = 0.0;
}

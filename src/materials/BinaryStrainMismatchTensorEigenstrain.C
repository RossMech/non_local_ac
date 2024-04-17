#include "BinaryStrainMismatchTensorEigenstrain.h"
#include "RankTwoTensor.h"
#include "RankFourTensor.h"

registerMooseObject("NonLocalACApp", BinaryStrainMismatchTensorEigenstrain);

InputParameters
BinaryStrainMismatchTensorEigenstrain::validParams()
{
	InputParameters params = Material::validParams();
	params.addRequiredCoupledVar("eta","Phase field variable value");
	params.addRequiredParam<MaterialPropertyName>("w_alpha","scalar weight of the alpha phase");
	params.addRequiredParam<std::string>("base_name_alpha","Name of base for alpha phase");
	params.addRequiredParam<std::string>("base_name_beta","Name of base for beta phase");
	params.addRequiredParam<MaterialPropertyName>("normal","Normal between two phases");
	params.addClassDescription("Calculation of mismatch strain and respective derivatives for binary phase-field model");
	params.addRequiredParam<MaterialPropertyName>("mismatch_tensor","mismatch strain between phases on the interface");
	params.addRequiredParam<MaterialPropertyName>("delta_elasticity","Difference in elasticity tensors of both phases");
	params.addRequiredParam<MaterialPropertyName>("S_wave","C_alpha*h_beta + C_beta*h_alpha inversed and normalized to second order tensor");
	params.addRequiredParam<std::string>("eigenstrain_name_alpha","Eigenstrains in phase alpha");
	params.addRequiredParam<std::string>("eigenstrain_name_beta","Eigenstrains in phase beta");
	return params;
}

// Initiation of the class
BinaryStrainMismatchTensorEigenstrain::BinaryStrainMismatchTensorEigenstrain(const InputParameters & parameters)
 : DerivativeMaterialInterface<Material>(parameters),
	// the variable value, number and name
	_eta(coupledValue("eta")),
	_eta_var(coupled("eta")),
	_eta_name(getVar("eta",0)->name()),
	_w_alpha(getMaterialProperty<Real>("w_alpha")),
	_dw_alpha_dop(getMaterialPropertyDerivative<Real>("w_alpha",_eta_name)),
	_base_name_alpha(getParam<std::string>("base_name_alpha")+"_"),
	_elasticity_tensor_alpha(getMaterialPropertyByName<RankFourTensor>(_base_name_alpha+"elasticity_tensor")),
	_eigenstrain_name_alpha(_base_name_alpha + getParam<std::string>("eigenstrain_name_alpha")),
	_eigenstrain_alpha(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_alpha)),
	_base_name_beta(getParam<std::string>("base_name_beta")+"_"),
	_elasticity_tensor_beta(getMaterialPropertyByName<RankFourTensor>(_base_name_beta+"elasticity_tensor")),
	_eigenstrain_name_beta(_base_name_beta + getParam<std::string>("eigenstrain_name_beta")),
	_eigenstrain_beta(getMaterialPropertyByName<RankTwoTensor>(_eigenstrain_name_beta)),
	_delta_elasticity(getMaterialProperty<RankFourTensor>("delta_elasticity")),
	_S_wave_2(getMaterialProperty<RankTwoTensor>("S_wave")),
	_base_name(isParamValid("base_name") ? getParam<std::string>("base_name") + "_" : ""),
	_mechanical_strain(getMaterialPropertyByName<RankTwoTensor>(_base_name + "mechanical_strain")),
	_n(getMaterialProperty<RealGradient>("normal")),
	// declaration of the derivatives
	_mismatch_tensor(declareProperty<RankTwoTensor>("mismatch_tensor")),
  _dmismatch_tensor_deta(declarePropertyDerivative<RankTwoTensor>("mismatch_tensor",_eta_name))
{
}

void BinaryStrainMismatchTensorEigenstrain::computeQpProperties()
{
	// Cutoff parameters for bulk and interface estimation
	const Real lower_bound = 1e-8;
	const Real upper_bound = 1.0 - 1e-8;

	if ((_eta[_qp] > lower_bound) && (_eta[_qp] < upper_bound))
	{
		Real w_beta = 1 - _w_alpha[_qp];

		// Calculate delta_sigma_vector

		RankTwoTensor sigma_delta = _delta_elasticity[_qp] * _mechanical_strain[_qp]
																- _elasticity_tensor_alpha[_qp] * _eigenstrain_alpha[_qp]
																+ _elasticity_tensor_beta[_qp] * _eigenstrain_beta[_qp];
		RealGradient sigma_delta_vector = sigma_delta * _n[_qp];

		// Calculation of mismatch vector
		RealGradient a_vect = - _S_wave_2[_qp] * sigma_delta_vector;

		// Calculation of mismatch tensor
		_mismatch_tensor[_qp].vectorOuterProduct(a_vect,_n[_qp]);
    _mismatch_tensor[_qp] += _mismatch_tensor[_qp].transpose();
    _mismatch_tensor[_qp] *= 0.5;

		// Parameters for respective derivatives


      // Construction of rank two tensor for access to the built-in inversion method
			RankFourTensor dCwave_deta = - _delta_elasticity[_qp] * _dw_alpha_dop[_qp];

			Real dCwave_deta_2_array[3][3] = {};

			unsigned int n_dim = LIBMESH_DIM;
			for (unsigned int i = 0; i < n_dim; i++)
        	{
          	for (unsigned int l = 0; l < n_dim; l++)
          		{
            	Real mult_result = 0.0;
            	for (unsigned int k = 0; k < n_dim; k++)
            		{
              		for (unsigned int j = 0; j < n_dim; j++)
              			{
              			mult_result += dCwave_deta(i,j,k,l) * _n[_qp](k) *_n[_qp](j);
              			}
            		}
            	dCwave_deta_2_array[i][l] = mult_result;
          		}
        	}

				const RankTwoTensor dCwave_deta_2(dCwave_deta_2_array[0][0],dCwave_deta_2_array[1][1],
																					dCwave_deta_2_array[2][2],dCwave_deta_2_array[2][1],
																					dCwave_deta_2_array[2][0],dCwave_deta_2_array[1][0]);

			RankTwoTensor da_prefac = _S_wave_2[_qp] * dCwave_deta_2 * _S_wave_2[_qp];
			RealGradient da_deta = - da_prefac * sigma_delta_vector;

			// Calculation of derivative of mismatch tensor itself
			_dmismatch_tensor_deta[_qp].vectorOuterProduct(da_deta,_n[_qp]);
			_dmismatch_tensor_deta[_qp] += _dmismatch_tensor_deta[_qp].transpose();
			_dmismatch_tensor_deta[_qp] *= 0.5;
	}
	else
	{
		_mismatch_tensor[_qp] = 0;
		_dmismatch_tensor_deta[_qp] = 0;
	}
}

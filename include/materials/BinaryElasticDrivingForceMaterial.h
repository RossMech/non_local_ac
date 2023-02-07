#pragma once

#include "Material.h"

class BinaryElasticDrivingForceMaterial : public Material
{
public:
	BinaryElasticDrivingForceMaterial(const InputParameters & parameters);

	static InputParameters validParams();

protected:
	virtual void computeQpProperties() override;

private:
	// Weight of phase
	const MaterialProperty<Real> & _w_alpha;
	const MaterialProperty<Real> & _dw_alpha_deta;
	
	// Mismatch tensor
	const MaterialProperty<RankTwoTensor> & _mismatch_tensor;

	// Base names and elastic properties of phases
	const std::string _base_name_alpha;
	const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

	const std::string _base_name_beta;
	const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

	// Base name and global properties
	const std::string _base_name;
	const MaterialProperty<RankTwoTensor> & _mechanical_strain;
	const MaterialProperty<RankTwoTensor> & _stress;
	
	// Phase variable
	const VariableValue & _u;
	// driving force
	MaterialProperty<Real> & _el_driving_force;
};

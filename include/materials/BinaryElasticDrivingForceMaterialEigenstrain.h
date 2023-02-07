#pragma once

#include "Material.h"

class BinaryElasticDrivingForceMaterialEigenstrain : public Material
{
public:
	BinaryElasticDrivingForceMaterialEigenstrain(const InputParameters & parameters);

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
	
	// Eigenstrains in the phases
	const std::string _eigenstrain_name_alpha;
	const MaterialProperty<RankTwoTensor> & _eigenstrain_alpha;

	const std::string _eigenstrain_name_beta;
	const MaterialProperty<RankTwoTensor> & _eigenstrain_beta;

	// Phase variable
	const VariableValue & _u;
	
	// driving force
	MaterialProperty<Real> & _el_driving_force;
};

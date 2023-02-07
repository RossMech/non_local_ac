#include "Material.h"
#include "DerivativeMaterialInterface.h"
#include "RankTwoTensorForward.h"
#include "RankFourTensorForward.h"

// declare a class
class BinaryStrainMismatchTensor : public DerivativeMaterialInterface<Material>
{
public:
	static InputParameters validParams();

	BinaryStrainMismatchTensor(const InputParameters & parameters);

protected:
	virtual void computeQpProperties();

private:

	// The variable parameters
	const VariableValue & _eta;
	unsigned int _eta_var;
	std::string _eta_name;

	// Weight of phase
	const MaterialProperty<Real> & _w_alpha;
	const MaterialProperty<Real> & _dw_alpha_dop;

	// Elastic stiffness of phases
	std::string _base_name_alpha;
	const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

	std::string _base_name_beta;
	const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

	// Derivative elastic properties
	const MaterialProperty<RankFourTensor> & _delta_elasticity;
	const MaterialProperty<RankTwoTensor> & _S_wave_2;

	// Base name and mechanical strain
	std::string _base_name;
	const MaterialProperty<RankTwoTensor> & _mechanical_strain;

	// Normal vector
	const MaterialProperty<RealGradient> & _n;

	// Mismatch tensor and its derivatives
	MaterialProperty<RankTwoTensor> & _mismatch_tensor;
	MaterialProperty<RankTwoTensor> & _dmismatch_tensor_deta;
};

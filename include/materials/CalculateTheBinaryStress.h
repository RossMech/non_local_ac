 	#pragma once

 	#include "ComputeStressBase.h"

 	/**
 	 * CalculateTheBinaryStress computes the stress following linear elasticity theory (small strains)
 	 */
 	class CalculateTheBinaryStress : public ComputeStressBase
 	{
 	public:
 	  static InputParameters validParams();

 	  CalculateTheBinaryStress(const InputParameters & parameters);

 	  virtual void initialSetup() override;

  	protected:
 	  virtual void computeQpStress() override;

 	  // Phase-field variable
 	  const VariableValue & _u;

 	  // Weights of the phases
 	  const MaterialProperty<Real> & _w_alpha;

 	  // Elastic stiffness of the first and second phase
 	  std::string _base_name_alpha;
 	  const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

 	  std::string _base_name_beta;
 	  const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

    // Derivative elastic properties
    const MaterialProperty<RankFourTensor> & _delta_elasticity;
    const MaterialProperty<RankFourTensor> & _elasticity_VT;
    const MaterialProperty<RankTwoTensor> & _S_wave_2;

 	  // Normal vector
 	  const MaterialProperty<RealGradient> & _n;

	 // Mismatch tensor
	 const MaterialProperty<RankTwoTensor> & _mismatch_tensor;
 	};

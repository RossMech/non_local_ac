 	#pragma once

 	#include "ComputeStressBase.h"

 	/**
 	 * BinaryRSApproximation computes the stress following linear elasticity theory (small strains)
 	 */
 	class BinaryRSApproximation : public ComputeStressBase
 	{
 	public:
 	  static InputParameters validParams();

 	  BinaryRSApproximation(const InputParameters & parameters);

 	  virtual void initialSetup() override;

  	protected:
 	  virtual void computeQpStress() override;

 	  // Phase-field variable
 	  const VariableValue & _u;

 	  // Weights of the phases
 	  const MaterialProperty<Real> & _w_alpha;
 	  const MaterialProperty<Real> & _w_beta;

 	  // Elastic stiffness of the first and second phase
 	  std::string _base_name_alpha;
 	  const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;
 	  std::string _base_name_beta;
 	  const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;
 	};

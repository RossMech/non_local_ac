#pragma once

#include "ComputeStressBase.h"

/**
 * CalculateTheBinaryStressOld computes the stress following linear elasticity theory (small strains)
 */
class CalculateTheBinaryStressOld : public ComputeStressBase
{
public:
  static InputParameters validParams();

  CalculateTheBinaryStressOld(const InputParameters & parameters);

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

  // Normal vector
  const MaterialProperty<RealGradient> & _n;

 // Mismatch tensor
 MaterialProperty<RankTwoTensor> & _mismatch_tensor;

 MaterialProperty<RankTwoTensor> & _strain_alpha;
 MaterialProperty<RankTwoTensor> & _strain_beta;
 MaterialProperty<RankTwoTensor> & _stress_alpha;
 MaterialProperty<RankTwoTensor> & _stress_beta;
};

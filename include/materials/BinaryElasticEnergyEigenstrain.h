#pragma once

#include "DerivativeFunctionMaterialBase.h"
#include "ADRankTwoTensorForward.h"

/**
 * Material class to compute the elastic free energy and its derivatives for binary mixture with eigenstrains based on thermodynamic consistent model
 */
class BinaryElasticEnergyEigenstrain : public DerivativeFunctionMaterialBase
{
public:
  static InputParameters validParams();

  BinaryElasticEnergyEigenstrain(const InputParameters & parameters);

  virtual void initialSetup() override;

protected:
  virtual Real computeF() override;

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

  // Eigenstrain tensors
  std::string _eigenstrain_name_alpha;
  const MaterialProperty<RankTwoTensor> & _eigenstrain_alpha;

  std::string _eigenstrain_name_beta;
  const MaterialProperty<RankTwoTensor> & _eigenstrain_beta;

  // Mismatch tensor
  const MaterialProperty<RankTwoTensor> & _mismatch_tensor;

  const std::string _base_name;

  ///@{ Strain
  const MaterialProperty<RankTwoTensor> & _strain;
};

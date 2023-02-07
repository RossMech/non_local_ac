#pragma once

#include "DerivativeFunctionMaterialBase.h"

class BinaryConsistentElasticEnergyEigenstrain : public DerivativeFunctionMaterialBase
{
public:
  static InputParameters validParams();

  BinaryConsistentElasticEnergyEigenstrain(const InputParameters & parameters);

protected:
  virtual Real computeF();
  virtual Real computeDF(unsigned int i_var);
  virtual Real computeD2F(unsigned int i_var, unsigned int j_var);

private:
  // Base name and macroscopic mechanical fields
  const std::string _base_name;
  const MaterialProperty<RankTwoTensor> & _stress;
  const MaterialProperty<RankTwoTensor> & _mechanical_strain;

  // Elastic stiffness of phases
  std::string _base_name_alpha;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

  std::string _base_name_beta;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

  // Eigenstrain tensors
  std::string _eigenstrain_name_alpha;
  const MaterialProperty<RankTwoTensor> & _eigenstrain_alpha;

  std::string _eigenstrain_name_beta;
  const MaterialProperty<RankTwoTensor> & _eigenstrain_beta;

  const MaterialProperty<RankFourTensor> & _delta_elasticity;
  const MaterialProperty<RankFourTensor> & _elasticity_VT;

  // Phase field variable
  const VariableValue & _eta;
  unsigned int _eta_var;
  std::string _eta_name;

  // Weight function
  const MaterialProperty<Real> & _w_alpha;
  const MaterialProperty<Real> & _dw_alpha_dop;
  const MaterialProperty<Real> & _d2w_alpha_d2op;

  // Mismatch tensor
  const MaterialProperty<RankTwoTensor> & _mismatch_tensor;
  const MaterialProperty<RankTwoTensor> & _dmismatch_tensor_deta;
};

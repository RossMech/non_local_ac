#pragma once

#include "ComputeElasticityTensorBase.h"

class BinaryRSElasticTensor : public ComputeElasticityTensorBase
{
public:
  static InputParameters validParams();

  BinaryRSElasticTensor(const InputParameters & parameters);

protected:
  virtual void computeQpElasticityTensor();

  // Phase-field variable
  const VariableValue & _eta;
  // Name of the phase-field variable (needed to set/get derivatives)
  VariableName _eta_name;

  // Weighting function for alpha phase
  const MaterialProperty<Real> & _w;
  // Name of the weighting function (needed to set/get derivatives)
  MaterialPropertyName _w_name;

  // The derivative of the weighting function
  const MaterialProperty<Real> & _dw_deta;
  // The second derivative of the weighting function
  const MaterialProperty<Real> & _d2w_deta2;
  

  // Elastic stiffness of the first and second phase
  std::string _base_name_a;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_a;
  std::string _base_name_b;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_b;

  // Derivative of the elasticity tensor in respect to phase-field variable
  MaterialProperty<RankFourTensor> * _delasticity_tensor_deta;
  // Second derivative
  MaterialProperty<RankFourTensor> * _d2elasticity_tensor_deta2;
};
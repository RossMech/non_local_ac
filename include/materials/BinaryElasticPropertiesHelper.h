#pragma once

#include "Material.h"

class BinaryElasticPropertiesHelper : public Material
{
public:
  BinaryElasticPropertiesHelper(const InputParameters & parameters);

  static InputParameters validParams();

protected:
  virtual void computeQpProperties() override;

private:

  // Base names and stiffnesses of both phases
  std::string _base_name_alpha;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

  std::string _base_name_beta;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

  // Weight function
  const MaterialProperty<Real> & _w_alpha;

  // Normal between phases
  const MaterialProperty<RealGradient> & _n;

  // Calculated properties
  MaterialProperty<RankFourTensor> & _delta_elasticity;
  MaterialProperty<RankFourTensor> & _elasticity_VT;
  MaterialProperty<RankTwoTensor> & _S_wave_2;
  const VariableValue & _eta;
};

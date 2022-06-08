#pragma once

#include "DerivativeFunctionMaterialBase.h"
#include "ADRankTwoTensorForward.h"

/**
 * Material class to compute the elastic free energy and its derivatives
 */
class ElasticEnergyMinimal : public DerivativeFunctionMaterialBase
{
public:
  static InputParameters validParams();

  ElasticEnergyMinimal(const InputParameters & parameters);

  virtual void initialSetup() override;

protected:
  virtual Real computeF() override;

  const std::string _base_name;

  /// Stress tensor
  const MaterialProperty<RankTwoTensor> & _stress;

  ///@{ Strain
  const MaterialProperty<RankTwoTensor> & _strain;
};

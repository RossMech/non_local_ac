#pragma once

#include "Material.h"
#include "RankTwoTensor.h"
#include "RankFourTensor.h"

/**
 * ElasticFreeEnergyMinimal computes the stress following linear elasticity theory (small strains)
 */
class ElasticFreeEnergyMinimal : public Material
{
public:
  static InputParameters validParams();

  ElasticFreeEnergyMinimal(const InputParameters & parameters);

protected:
  virtual void computeQpProperties() override;

  // Phase-field variable
private:
  const std::string _base_name;

  const MaterialProperty<RankTwoTensor> & _stress;
  const MaterialProperty<RankTwoTensor> & _strain;

  MaterialProperty<Real> & _elastic_energy;
};

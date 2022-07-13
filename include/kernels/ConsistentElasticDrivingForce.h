#pragma once

#include "ACBulk.h"
#include "RankTwoTensorForward.h"
#include "RankFourTensorForward.h"

/**
 * Calculates the porton of the Allen-Cahn equation that results from the deformation energy.
 * Must access the elastic_strain stored as a material property
 * Requires the name of the elastic tensor derivative as an input.
 */
class ConsistentElasticDrivingForce : public ACBulk<Real>
{
public:
  static InputParameters validParams();

  ConsistentElasticDrivingForce(const InputParameters & parameters);

protected:
  virtual Real computeDFDOP(PFFunctionType type);

private:

  // Base name
  const std::string _base_name;
  const MaterialProperty<RankTwoTensor> & _mechanical_strain;
  const MaterialProperty<RankTwoTensor> & _stress;

  // Normal vector
  const MaterialProperty<RealGradient> & _n;

  // Mismatch vector
  const MaterialProperty<RealGradient> & _a_vect;

  // Stiffness tensors
  // Elastic stiffness of the first and second phase
  std::string _base_name_alpha;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

  std::string _base_name_beta;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

  // Weights of the phases
  const MaterialProperty<Real> & _w_alpha;
  const MaterialProperty<Real> & _dw_alpha_dop;

  // Variable value
  const VariableValue & _u;
};

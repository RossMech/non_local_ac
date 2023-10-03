#pragma once

#include "ACBulk.h"
#include "RankTwoTensorForward.h"
#include "RankFourTensorForward.h"

/**
 * Calculates the porton of the Allen-Cahn equation that results from the deformation energy.
 * Must access the elastic_strain stored as a material property
 * Requires the name of the elastic tensor derivative as an input.
 */
class RSElasticDrivingForceEigenstrain : public ACBulk<Real>
{
public:
  static InputParameters validParams();

  RSElasticDrivingForceEigenstrain(const InputParameters & parameters);

protected:
  virtual Real computeDFDOP(PFFunctionType type);
private:
  // Weights of the phases
  const MaterialProperty<Real> & _w_alpha;
  const MaterialProperty<Real> & _dw_alpha_dop;
  const MaterialProperty<Real> & _d2w_alpha_dop2;

  // Base names and elastic properties of phases
  const std::string _base_name_alpha;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_alpha;

  const std::string _base_name_beta;
  const MaterialProperty<RankFourTensor> & _elasticity_tensor_beta;

  // Base name
  const std::string _base_name;
  const MaterialProperty<RankTwoTensor> & _mechanical_strain;
  const MaterialProperty<RankTwoTensor> & _stress;
  
  // Eigenstrain tensors
  const std::string _eigenstrain_name_alpha;
  const MaterialProperty<RankTwoTensor> & _eigenstrain_alpha;
 
  const std::string _eigenstrain_name_beta;
  const MaterialProperty<RankTwoTensor> & _eigenstrain_beta;
};

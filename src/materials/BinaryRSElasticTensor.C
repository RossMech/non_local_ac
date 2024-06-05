#include "BinaryRSElasticTensor.h"

registerMooseObject("NonLocalACApp", BinaryRSElasticTensor);

InputParameters
BinaryRSElasticTensor::validParams()
{
  InputParameters params = ComputeElasticityTensorBase::validParams();
  params.addClassDescription("Calculate Elastic Stiffness Tensor for binary RS Approximation.");
  params.addRequiredCoupledVar("phase", "Phase-field variable");
  params.addRequiredParam<MaterialPropertyName>(
      "weight", "scalar weighting function of phase-field variable");
  params.addRequiredParam<std::string>("base_name_a", "Elasticity tensor for eta = 1");
  params.addRequiredParam<std::string>("base_name_b", "Elasticity tensor for eta = 0");
  return params;
}

BinaryRSElasticTensor::BinaryRSElasticTensor(const InputParameters & parameters)
  : ComputeElasticityTensorBase(parameters),
    _eta(coupledValue("phase")),
    _eta_name(coupledName("phase", 0)),
    _w(getMaterialProperty<Real>("weight")),
    _w_name(getParam<MaterialPropertyName>("weight")),
    _dw_deta(getMaterialPropertyDerivativeByName<Real>(_w_name, _eta_name)),
    _base_name_a(getParam<std::string>("base_name_a") + "_"),
    _elasticity_tensor_a(
        getMaterialPropertyByName<RankFourTensor>(_base_name_a + "elasticity_tensor")),
    _base_name_b(getParam<std::string>("base_name_b") + "_"),
    _elasticity_tensor_b(
        getMaterialPropertyByName<RankFourTensor>(_base_name_b + "elasticity_tensor")),
    _delasticity_tensor_deta(
        isCoupledConstant("phase")
            ? nullptr
            : &declarePropertyDerivative<RankFourTensor>(_elasticity_tensor_name, _eta_name))
{
}

void
BinaryRSElasticTensor::computeQpElasticityTensor()
{
  // Calculate the weight for beta phase
  Real w_a = _w[_qp];
  Real w_b = 1.0 - w_a;

  // Calculate the compliances of phases
  RankFourTensor compliance_a = _elasticity_tensor_a[_qp].invSymm();
  RankFourTensor compliance_b = _elasticity_tensor_b[_qp].invSymm();

  // Calculate the composite compliance
  RankFourTensor compliance_RS = w_a * compliance_a + w_b * compliance_b;

  // Elastic constants
  RankFourTensor elasticity_RS = compliance_RS.invSymm();

  // Assign elasticity tensor
  _elasticity_tensor[_qp] = elasticity_RS;

  // Calculate the derivatives
  if (_delasticity_tensor_deta)
  {
    // Get the derivative of the weighting function
    Real w_der = _dw_deta[_qp];

    // The difference in the compliance of phases
    RankFourTensor compliance_diff = compliance_a - compliance_b;

    // The first derivative
    RankFourTensor elasticity_tensor_der = w_der * elasticity_RS * elasticity_RS * compliance_diff;

    // Assign the derivative
    (*_delasticity_tensor_deta)[_qp] = elasticity_tensor_der;
  }
}
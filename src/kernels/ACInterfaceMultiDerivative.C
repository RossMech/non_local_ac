#include "ACInterfaceMultiDerivative.h"

registerMooseObject("PhaseFieldApp", ACInterfaceMultiDerivative);

InputParameters
ACInterfaceMultiDerivative::validParams()
{
  InputParameters params = Kernel::validParams();
  params.addClassDescription("Gradient energy term for when kappa as a function of the variable");
  params.addParam<MaterialPropertyName>("mob_name", "L", "The mobility used with the kernel");
  params.addParam<MaterialPropertyName>("kappa_name", "kappa_op", "The kappa function name");
  params.addCoupledVar("v", "Vector of order parameters");
  return params;
}

ACInterfaceMultiDerivative::ACInterfaceMultiDerivative(const InputParameters & parameters)
  : DerivativeMaterialInterface<JvarMapKernelInterface<Kernel>>(parameters),
    _L(getMaterialProperty<Real>("mob_name")),
    _dLdvar(getMaterialPropertyDerivative<Real>("mob_name", _var.name())),
    _kappa_name(getParam<MaterialPropertyName>("kappa_name")),
    _dkappadvar(getMaterialPropertyDerivative<Real>(_kappa_name, _var.name())),
    _d2kappadvar2(getMaterialPropertyDerivative<Real>(_kappa_name, _var.name(), _var.name())),
    _v_num(coupledComponents("v")),
    _v_map(getParameterJvarMap("v")),
    _grad_v(_v_num),
    _dLdv(_v_num),
    _d2kappadvardv(_v_num),
    _dkappadv(_v_num)
{
  for (unsigned int i = 0; i < _v_num; ++i)
  {
    auto v_name = getVar("v", i)->name();
    _grad_v[i] = &coupledGradient("v", i);
    _dLdv[i] = &getMaterialPropertyDerivative<Real>("mob_name", v_name);
    _d2kappadvardv[i] = &getMaterialPropertyDerivative<Real>(_kappa_name, _var.name(), v_name);
    _dkappadv[i] = &getMaterialPropertyDerivative<Real>("kappa_name", v_name);
  }
}

Real
ACInterfaceMultiDerivative::computeQpResidual()
{
  Real sum_grad_etai2 = 0.0;
  for (unsigned int i = 0; i < _v_num; ++i)
    sum_grad_etai2 += (*_dkappadv[i])[_qp] * (*_grad_v[i])[_qp] * (*_grad_v[i])[_qp];

  sum_grad_etai2 += _dkappadvar[_qp] * _grad_u[_qp] * _grad_u[_qp];

  return _test[_i][_qp] * _L[_qp] * sum_grad_etai2;
}

Real
ACInterfaceMultiDerivative::computeQpJacobian()
{
  //Real pre_jac = 0.5 * _test[_i][_qp] * _phi[_j][_qp] * computeFg();
  //Real term1 = _test[_i][_qp] * _L[_qp] * _dkappadvar[_qp] * _grad_u[_qp] * _grad_phi[_j][_qp];

  //return pre_jac * (_dLdvar[_qp] * _dkappadvar[_qp] + _L[_qp] * _d2kappadvar2[_qp]) + term1;
  return 0.0;
}

Real
ACInterfaceMultiDerivative::computeQpOffDiagJacobian(unsigned int jvar)
{
  //auto i = mapJvarToCvar(jvar, _v_map);
  //if (i >= 0)
  //{
  //  const Real pre_jac = 0.5 * _test[_i][_qp] * _phi[_j][_qp] * computeFg();
  //  const Real term1 =
  //      _test[_i][_qp] * _L[_qp] * _dkappadvar[_qp] * (*_grad_v[i])[_qp] * _grad_phi[_j][_qp];
  //  return pre_jac * ((*_dLdv[i])[_qp] * _dkappadvar[_qp] + _L[_qp] * (*_d2kappadvardv[i])[_qp]) +
  //         term1;
  //}

  return 0.0;
}

Real
ACInterfaceMultiDerivative::computeFg()
{
  Real sum_grad_etai2 = 0.0;
  for (unsigned int i = 0; i < _v_num; ++i)
    sum_grad_etai2 += (*_grad_v[i])[_qp] * (*_grad_v[i])[_qp];

  return sum_grad_etai2 + _grad_u[_qp] * _grad_u[_qp];
}

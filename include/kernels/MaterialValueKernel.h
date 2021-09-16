#pragma once

#include "KernelValue.h"

class MaterialValueKernel : public KernelValue
{
public:
  static InputParameters validParams();

  MaterialValueKernel(const InputParameters & parameters);

protected:
  // The method, which sould overwrite the KernelValue method for calculation in Integration Point
  virtual Real precomputeQpResidual() override;

};



/*
# pragma once

# include "KernelValue.h"

class MaterialValueKernel : public KernelValue
{
  public:
    static InputParameters validParams();

    MaterialValueKernel(const InputParameters & parameters);

  protected:
    // The method, which should overwritten in KernelValue method
    virtual KernelValue precomputeQpResidual() override;

    // The variable, which holds the value of material in quadrature point
#    const Real _Mat_value;

}
/**/

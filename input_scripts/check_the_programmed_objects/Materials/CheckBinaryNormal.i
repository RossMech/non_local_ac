[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0.0
  xmax = 20.0
  ymin = 0.0
  ymax = 20.0
  nx = 50
  ny = 50
[]

[Variables]
  [./eta]
    [./InitialCondition]
      type = SmoothCircleIC
      radius = 10.0
      invalue = 1.0
      outvalue = 0.0
      x1 = 0.0
      y1 = 0.0
      int_width = 2.0
    [../]
  [../]
[]

[Kernels]
  [./detadt]
    type = TimeDerivative
    variable = eta
  [../]
[]

[Materials]
  [./normal]
    type = BinaryNormalVector
    phase = eta
    normal_vector_name = eta_normal
    outputs = exodus
  [../]
  [./normaltensor]
    type = PhaseNormalTensor
    phase = eta
    normal_tensor_name = eta_tensor
    outputs = exodus
  [../]
[]

[Executioner]
  type = Transient
  num_steps = 1
[]

[Outputs]
  exodus = true
[]

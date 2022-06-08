[Mesh]
  type = GeneratedMesh
  dim = 1
  xmin = -0.5
  xmax = 0.5
  nx = 1000
[]

[Variables]
  [./disp_x]
  [../]
[]

[BCs]
  [./pinned_left]
    type = DirichletBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]
  [./stress_right]
    type = Pressure
    variable = disp_x
    displacements = 'disp_x'
    boundary = right
    component = 0
    factor = -1
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x'
  [../]
[]

[Materials]
  [./h_alpha]
    type = DerivativeParsedMaterial
    args = eta
    f_name = h_alpha
    function = 'eta*eta/(eta*eta+(1-eta)*(1-eta))'
  [../]
  [./h_beta]
    type = DerivativeParsedMaterial
    args = eta
    f_name = h_beta
    function = '1-h_alpha'
    material_property_names = h_alpha
  [../]
  [./elasticity_tensor_alpha]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1
    poissons_ratio = 0.3
    base_name = alpha_phase
  [../]
  [./elasticity_tensor_beta]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 100
    poissons_ratio = 0.3
    base_name = beta_phase
  [../]
  [./normal]
    type = BinaryNormalVector
    phase = eta
    normal_vector_name = normal
  [../]
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x'
    outputs = exodus
  [../]
  [./stress]
    type = CalculateTheBinaryStress
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    w_alpha = h_alpha
    w_beta = h_beta
    normal = normal
    phase = eta
    compliance_alpha = compliance_alpha
    outputs = exodus
  [../]
  #[./elastic_free_energy]
  #  type = ElasticEnergyMaterial
  #  f_name = f_elast
  #  args = eta
  #[../]
[]

[AuxVariables]
  [./eta]
  [../]
  #[./f_elast_aux]
  #  order = CONSTANT
  #  family = MONOMIAL
  #[../]
  [./stress_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
  #[./strain_aux]
  #  order = CONSTANT
  #  family = MONOMIAL
  #[../]
[]

[AuxKernels]
  [./eta_profile]
    type = FunctionAux
    variable = eta
    function = eta_profile_func
  [../]
  #[./elast_aux]
  #  type = MaterialRealAux
  #  property = f_elast
  #  variable = f_elast_aux
  #[../]
  #[./stress_aux]
  #  type = MaterialRealTensorValueAux
  #  property = stress
  #  variable = stress_aux
  #[../]
  #[./strain_aux]
  #  type = MaterialRealTensorValueAux
  #  property = strain
  #  variable = strain_aux
  #[../]
[]

[Functions]
  [./eta_profile_func]
    type = ParsedFunction
    value = '0.5*(tanh(pi*x/omega)+1)'
    vars = omega
    vals = 0.1
  [../]
[]

[Postprocessors]
  #[./total_f]
  #  type = ElementIntegralVariablePostprocessor
  #  variable = f_elast_aux
  #[../]
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-6
  nl_rel_tol = 1e-5
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]

[Outputs]
  exodus = true
  csv = true
[]

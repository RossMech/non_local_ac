[Mesh]
  type = GeneratedMesh
  dim = 3
  xmin = -0.5
  xmax = 0.5
  ymin = 0.0
  ymax = 1.0
  zmin = 0.0
  zmax = 1.0
  nx = 1000
  ny = 1
  nz = 1
[]

[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
[]

[BCs]
  [./pinned_x_left]
    type = DirichletBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]
  [./pinned_y_left]
    type = DirichletBC
    variable = disp_y
    boundary = left
    value = 0.0
  [../]
  [./pinned_z_left]
    type = DirichletBC
    variable = disp_z
    boundary = left
    value = 0.0
  [../]
  [./pinned_x_right]
    type = DirichletBC
    variable = disp_x
    boundary = right
    value = 0.0
  [../]
  [./pinned_y_right]
    type = DirichletBC
    variable = disp_y
    boundary = right
    value = 0.0
  [../]
  [./pinned_z_right]
    type = DirichletBC
    variable = disp_z
    boundary = right
    value = 0.0
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y disp_z'
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
    youngs_modulus = 1
    poissons_ratio = 0.3
    base_name = beta_phase
  [../]
  [./eigenstrain_alpha]
    type = ComputeEigenstrain
    eigenstrain_name = eigenstrain_alpha
    eigen_base = '1e-2 0.0 0.0 0.0 0.0 0.0'
    base_name = alpha_phase
    outputs = exodus
  [../]
  [./eigenstrain_beta]
    type = ComputeEigenstrain
    eigenstrain_name = eigenstrain_beta
    eigen_base = '1e-2 0.0 0.0 0.0 0.0 0.0'
    base_name = beta_phase
    outputs = exodus
  [../]
  [./normal]
    type = BinaryNormalVector
    phase = eta
    normal_vector_name = normal
  [../]
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
    outputs = exodus
  [../]
  [./stress]
    type = CalculateTheBinaryStressEigenstrain
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    eigenstrain_name_alpha = eigenstrain_alpha
    eigenstrain_name_beta = eigenstrain_beta
    w_alpha = h_alpha
    w_beta = h_beta
    normal = normal
    phase = eta
    outputs = exodus
    mismatch_tensor = mismatch_tensor
  [../]
  [./elastic_free_energy]
    type = BinaryElasticEnergyEigenstrain
    f_name = f_el
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    eigenstrain_name_alpha = eigenstrain_alpha
    eigenstrain_name_beta = eigenstrain_beta
    w_alpha = h_alpha
    w_beta = h_beta
    phase = eta
    args = ''
    mismatch_tensor = mismatch_tensor
  [../]
[]

[AuxVariables]
  [./eta]
  [../]
  [./f_elast_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./eta_profile]
    type = FunctionAux
    variable = eta
    function = eta_profile_func
  [../]
  [./elast_aux]
    type = MaterialRealAux
    property = f_el
    variable = f_elast_aux
  [../]
[]

[Functions]
  [./eta_profile_func]
    type = ParsedFunction
    value = '0.5*(tanh(pi*x/omega)+1)'
    vars = omega
    vals = 0.025
  [../]
[]

[Postprocessors]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_elast_aux
  [../]
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

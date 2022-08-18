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
  nz = 20
[]

[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
  [./eta]
    [./InitialCondition]
      type = FunctionIC
      function = 'if(x<0,0,1)'
    [../]
  [../]
[]

[BCs]
  [./pinned_bottom_z]
    type = DirichletBC
    variable = disp_z
    boundary = back
    value = 0.0
  [../]
  [./pinned_bottom_x]
    type = DirichletBC
    variable = disp_x
    boundary = back
    value = 0.0
  [../]
  [./pinned_bottom_y]
    type = DirichletBC
    variable = disp_y
    boundary = back
    value = 0.0
  [../]
  [./stretch_top]
    type = DirichletBC
    variable = disp_z
    boundary = front
    value = 1.0
  [../]
  [./eta_left]
    type = DirichletBC
    variable = eta
    boundary = left
    value = 0
  [../]
  [./eta_right]
    type = DirichletBC
    variable = eta
    boundary = right
    value = 1
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y disp_z'
  [../]
  [./eta_dot]
    type = TimeDerivative
    variable = eta
  [../]
  [./eta_bulk]
    type = AllenCahn
    variable = eta
    f_name = f_bulk
    mob_name = L
    args = ''
  [../]
  [./eta_interface]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  [../]
  [./eta_elastic]
    type = ConsistentElasticDrivingForce
    variable = eta
    mob_name = L
    mismatch_tensor = mismatch_tensor
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    w_alpha = h_alpha
    normal = normal
  [../]
[]

[Materials]
  [./const]
    type = GenericConstantMaterial
    prop_names = 'L gab kappa mu'
    prop_values = '1.0 1.5 0.0188 240.0'
  [../]
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
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'eta'
    material_property_names = 'mu gab'
    function = 'mu*((eta*eta*eta*eta/4-eta*eta/2)+((1-eta)*(1-eta)*(1-eta)*(1-eta)/4
    -(1-eta)*(1-eta)/2)+(gab*(1-eta)*(1-eta)*eta*eta)+1/4)'
  [../]
  [./elasticity_tensor_alpha]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1
    poissons_ratio = 0.3
    base_name = alpha_phase
  [../]
  [./elasticity_tensor_beta]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 10
    poissons_ratio = 0.3
    base_name = beta_phase
  [../]
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
    outputs = exodus
  [../]
  [./normal]
    type = BinaryNormalVector
    phase = eta
    normal_vector_name = normal
  [../]
  [./stress]
    type = CalculateTheBinaryStress
    mismatch_tensor = mismatch_tensor
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    w_alpha = h_alpha
    w_beta = h_beta
    normal = normal
    phase = eta
    outputs = exodus
  [../]
  [./elastic_free_energy]
    type = ElasticEnergyMinimal
    f_name = f_el
    args = eta
  [../]
  [./total_free_energy]
    type = DerivativeSumMaterial
    f_name = f_total
    sum_materials = 'f_el f_bulk'
    args = eta
  [../]
[]

[AuxVariables]
  [./f_elast_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./f_total_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./elast_aux]
    type = MaterialRealAux
    property = f_el
    variable = f_elast_aux
  [../]
  [./f_total_aux]
    type = TotalFreeEnergy
    variable = f_total_aux
    f_name = f_total
    interfacial_vars = eta
    kappa_names = kappa
  [../]
[]

[Postprocessors]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_total_aux
  [../]
  [./delta_f]
    type = ChangeOverTimestepPostprocessor
    postprocessor = total_f
  [../]
[]

[Preconditioning]
  [./coupling]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = implicit-euler
  end_time = 1e8
  num_steps  = 2
  l_max_its = 20#30
  nl_max_its = 50#50
	nl_rel_tol = 1e-7 #1e-8
  nl_abs_tol = 1e-8 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 5
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-2
    cutback_factor = 0.5
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    interval = 10
  [../]
  csv = true
[]

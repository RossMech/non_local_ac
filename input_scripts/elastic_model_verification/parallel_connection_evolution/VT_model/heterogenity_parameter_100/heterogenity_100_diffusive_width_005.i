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
    f_name = f_total
    mob_name = L
    args = ''
  [../]
  [./eta_interface]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  [../]
[]

[Materials]
  [./const]
    type = GenericConstantMaterial
    prop_names = 'L gab kappa mu'
    prop_values = '1.0 1.5 0.0376 120'
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
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
    outputs = exodus
  [../]
  [./elasticitytensor]
    type = CompositeElasticityTensor
    args = eta
    tensors = 'alpha_phase beta_phase'
    weights = 'h_alpha h_beta'
  [../]
  [./stress]
    type = ComputeLinearElasticStress
  [../]
  [./elastic_free_energy]
    type = ElasticEnergyMaterial
    args = 'eta'
    f_name = f_elast
  [../]
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'eta'
    material_property_names = 'mu gab'
    function = 'mu*((eta*eta*eta*eta/4-eta*eta/2)+((1-eta)*(1-eta)*(1-eta)*(1-eta)/4
    -(1-eta)*(1-eta)/2)+(gab*(1-eta)*(1-eta)*eta*eta)+1/4)'
  [../]
  [./total_free_energy]
    type = DerivativeSumMaterial
    f_name = f_total
    args = 'eta'
    sum_materials = 'f_elast f_bulk'
  [../]
[]

[AuxVariables]
  [./f_elast_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./stress_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./elast_aux]
    type = MaterialRealAux
    property = f_elast
    variable = f_elast_aux
  [../]
  [./f_total_aux]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_total
    interfacial_vars = 'eta'
    kappa_names = 'kappa'
  [../]
[]

[Postprocessors]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_dens
  [../]
  [./delta_f]
    type = ChangeOverTimestepPostprocessor
    postprocessor = total_f
  [../]
  [./time]
    type = TimePostprocessor
    execute_on = TIMESTEP_BEGIN
  [../]
[]

[Preconditioning]
  [./coupling]
    type = SMP
    full = true
  [../]
[]

[UserObjects]
  [./calculation_termination]
    type = Terminator
    expression = 'delta_f*(time > 1e-2) > 1e-8'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = bdf2
  end_time = 1e8
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
  exodus = true
  csv = true
[]

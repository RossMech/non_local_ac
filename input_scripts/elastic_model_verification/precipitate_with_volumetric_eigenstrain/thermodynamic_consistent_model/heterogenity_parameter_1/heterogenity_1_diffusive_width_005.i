[Mesh]
  type = FileMesh
  file = 'sphere_with_eigenstrains.msh'
  dim = 3
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
      type = SmoothCircleIC
      invalue = 1.0
      outvalue = 0.0
      x1 = 0.0
      y1 = 0.0
      radius = 5.0
      int_width = 0.25
    [../]
  [../]
[]

[Adaptivity]
	max_h_level = 3
	marker = box
	initial_marker = box
	initial_steps = 3
  [./Markers]
    [./box]
      type = ValueRangeMarker
      lower_bound = 0.01
      upper_bound = 0.99
      variable = eta
      third_state = DO_NOTHING
    [../]
  [../]
[]

[BCs]
  [./symmetry_x]
    type = DirichletBC
    boundary = 2
    value = 0.0
    variable = disp_x
  [../]
  [./symmetry_y]
    type = DirichletBC
    boundary = 3
    value = 0.0
    variable = disp_y
  [../]
  [./symmetry_z]
    type = DirichletBC
    boundary = 4
    value = 0.0
    variable = disp_z
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y disp_z'
  [../]
  [./TimeDerivative]
    type = TimeDerivative
    variable = eta
  [../]
[]

[Materials]
  [./h_alpha]
    type = DerivativeParsedMaterial
    args = eta
    f_name = h_alpha
    function = 'eta'
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
  [./eigenstrain_alpha]
    type = ComputeEigenstrain
    eigen_base = '0.1 0.1 0.1 0.0 0.0 0.0'
    eigenstrain_name = 'eigenstrain_alpha'
    base_name = 'alpha_phase'
  [../]
  [./eigenstrain_beta]
    type = ComputeEigenstrain
    eigen_base = '0.0 0.0 0.0 0.0 0.0 0.0'
    eigenstrain_name = 'eigenstrain_beta'
    base_name = 'beta_phase'
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
    mismatch_tensor = mismatch_tensor
    outputs = exodus
  [../]
  [./elastic_free_energy]
    type = BinaryElasticEnergyEigenstrain
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    eigenstrain_name_alpha = eigenstrain_alpha
    eigenstrain_name_beta = eigenstrain_beta
    w_alpha = h_alpha
    w_beta = h_beta
    normal = normal
    phase = eta
    mismatch_tensor = mismatch_tensor
    outputs = exodus
    args = ''
    f_name = f_el
  [../]
[]

[AuxVariables]
#  [./eta]
#  [../]
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
#  [./eta_profile]
#    type = FunctionAux
#    variable = eta
#    function = eta_profile_func
#    execute_on = 'LINEAR TIMESTEP_END NONLINEAR INITIAL TIMESTEP_BEGIN'
#  [../]
  [./elast_aux]
    type = MaterialRealAux
    property = f_el
    variable = f_elast_aux
  [../]
[]

#[Functions]
#  [./eta_profile_func]
#    type = ParsedFunction
#    value = '0.5*(tanh(pi*((r-sqrt(x*x+y*y+z*z)))/omega)+1)'
#    vars = 'omega r'
#    vals = '0.1 5'
#    execute_on = 'LINEAR TIMESTEP_END NONLINEAR INITIAL TIMESTEP_BEGIN'
#  [../]
#[]

[Preconditioning]
	[./coupling]
    type = SMP

		#full = true
    full = false
		off_diag_column = ''
		off_diag_row = ''

		#petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
	  #petsc_options_value = 'lu mumps'
    petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
    petsc_options_value = 'hypre boomeramg gmres 31 0.7'

		solve_type = PJFNK

		trust_my_coupling = true
		pc_side = default
  [../]
[]

[Postprocessors]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_elast_aux
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  dt = 1e-8
  num_steps = 1
  nl_abs_tol = 1e-6
  nl_rel_tol = 1e-5
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]

[Outputs]
  exodus = true
  csv = true
[]

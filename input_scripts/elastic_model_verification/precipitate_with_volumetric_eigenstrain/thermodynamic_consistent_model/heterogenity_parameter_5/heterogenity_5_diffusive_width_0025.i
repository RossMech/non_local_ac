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
      int_width = 0.125
    [../]
  [../]
[]

[Adaptivity]
	max_h_level = 4
	marker = box
	initial_marker = box
	initial_steps = 4
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
  [./elasticity_tensor_alpha]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1
    poissons_ratio = 0.3
    base_name = alpha_phase
  [../]
  [./elasticity_tensor_beta]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 5
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
  [./elastichelper]
    type = BinaryElasticPropertiesHelper
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    w_alpha = h_alpha
    normal = normal
    delta_elasticity = delta_elasticity
    elasticity_VT = elasticity_VT
    S_wave = S_wave
    eta = eta
  [../]
  [./mismatch_tensor]
    type = BinaryStrainMismatchTensorEigenstrain
    eta = eta
    w_alpha = h_alpha
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    normal = normal
    mismatch_tensor = mismatch_tensor
    delta_elasticity = delta_elasticity
    S_wave = S_wave
    eigenstrain_name_alpha = eigenstrain_alpha
    eigenstrain_name_beta = eigenstrain_beta
  [../]
  [./stress]
    type = CalculateTheBinaryStressEigenstrain
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    delta_elasticity = delta_elasticity
    elasticity_VT = elasticity_VT
    S_wave = S_wave
    mismatch_tensor = mismatch_tensor
    w_alpha = h_alpha
    phase = eta
    outputs = exodus
    normal = normal
    eigenstrain_name_alpha = eigenstrain_alpha
    eigenstrain_name_beta = eigenstrain_beta
  [../]
  [./elastic_energy]
    type = BinaryConsistentElasticEnergyEigenstrain
    base_name_alpha = alpha_phase
    base_name_beta = beta_phase
    eta = eta
    mismatch_tensor = mismatch_tensor
    w_alpha = h_alpha
    delta_elasticity = delta_elasticity
    elasticity_VT = elasticity_VT
    f_name = f_el
    eigenstrain_name_alpha = eigenstrain_alpha
    eigenstrain_name_beta = eigenstrain_beta
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

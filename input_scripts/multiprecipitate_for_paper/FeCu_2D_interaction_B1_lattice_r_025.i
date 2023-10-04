[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_a_025.msh
	#parallel_type = DISTRIBUTED
[]

[Adaptivity]
  max_h_level = 4
  marker = marker
  initial_marker = marker
  initial_steps = 4
  [./Markers]
    [./marker]
      type = ValueRangeMarker
      lower_bound = 0.001
      upper_bound = 0.999
      variable = c
      third_state = DO_NOTHING
    [../]
  [../]
[]

[GlobalParams]
  derivative_order = 3
[]

[Variables]
	[./c]
	[../]
	[./w]
	[../]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
[]

[ICs]
  [./c_IC]
    type = SmoothCircleFromFileIC
		variable = c
    file_name = 'circles_lattice_r_025.txt'
    invalue = 1.0
    outvalue = 0.0
    int_width = 0.4
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y'
    use_displaced_mesh = false
  [../]
  [./c_res]
    type = SplitCHParsed
    variable = c
    f_name = F
    kappa_name = kappa_c
    w = w
		displacements = 'disp_x disp_y'
  [../]
  [./w_res]
    type = SplitCHWRes
    variable = w
    mob_name = M
  [../]
  [./time]
    type = CoupledTimeDerivative
    variable = w
    v = c
  [../]
[]

[AuxVariables]
	[./f_tot]
		family = MONOMIAL
		order = CONSTANT
	[../]

	# elastic free energy
	[./f_el]
		family = MONOMIAL
		order = CONSTANT
	[../]

	# stabilization term
	[./f_stab]
		family = MONOMIAL
		order = CONSTANT
	[../]
[]

[AuxKernels]
  [./f_total]
    type = TotalFreeEnergy
    variable = f_tot
    f_name = 'F'
    kappa_names = 'kappa_c'
    interfacial_vars = c
  [../]

	# Elastic free energy
	[./elastic_energy_kernel]
		type = ElasticEnergyAux
		variable = f_el
	[../]

	# stabilization term
	[./energy_stab_kernel]
		type = MaterialRealAux
		variable = f_stab
		property = Fst
	[../]
[]

[Materials]
  [./pfmobility]
    type = GenericConstantMaterial
    prop_names  = 'M kappa_c'
    prop_values = '1.0 0.1341'
  [../]

  # simple chemical free energy with a miscibility gap
  [./chemical_free_energy]
    type = DerivativeParsedMaterial
    f_name = Fc
    args = 'c'
    constant_names       = 'omega  a2 a3 a4 a5 a6 a7 a8 a9 a10 delta_G'
    constant_expressions = '14.0091 8.072789087 -81.24549382 408.0297321 -1244.129167 2444.046270 -3120.635139 2506.663551 -1151.003178 230.2006355 0.95'
    function = 'omega*(a2*c^2+a3*c^3+a4*c^4+a5*c^5+a6*c^6+a7*c^7+a8*c^8+a9*c^9+a10*c^10) - delta_G * c^3*(6*c^2-15*c+10)'
    enable_jit = true
    derivative_order = 3
  [../]

  # stabilization contribution
	[./energy_stabilization]
		type = DerivativeParsedMaterial
		f_name = Fst
		args = 'c'
		constant_names = 'delta_G'
		constant_expressions = 0.95
		function = '- delta_G * c^3*(6*c^2-15*c+10)'
		enable_jit = true
		derivative_order = 3
	[../]

  # undersized solute (voidlike)
  [./elasticity_tensor_matrix]
    type = ComputeElasticityTensor
    C_ijkl = '145.8518 110.6975 110.6975 145.8518 110.6975 145.8518 104.6428 104.6428 104.6428'
    fill_method = symmetric9
		base_name = stiffness_matrix
  [../]
	[./elasticity_tensor_precipitate]
		type = ComputeElasticityTensor
		C_ijkl = '151.3125 107.1896 108.7447 -1.9095 -5.7284 -13.0552 189.5016 70.5556 5.7284 1.9095 6.0394 187.9465 -3.8189 3.8189 7.0158 19.53 7.0158 1.9095 57.7191 -1.9095 56.1640'
		fill_method = symmetric21
		base_name = stiffness_precipitate
	[../]

  [./stress]
    type = ComputeLinearElasticStress
  [../]
  [./var_dependence]
    type = DerivativeParsedMaterial
    # eigenstrain coefficient
    # -0.1 will result in an undersized precipitate
    #  0.1 will result in an oversized precipitate
    function = 'c^3*(6*c^2-15*c+10)'
    args = c
    f_name = var_dep
    enable_jit = true
    derivative_order = 3
  [../]
	[./var_dependence_inv]
    type = DerivativeParsedMaterial
    # eigenstrain coefficient
    # -0.1 will result in an undersized precipitate
    #  0.1 will result in an oversized precipitate
    function = '1 - c^3*(6*c^2-15*c+10)'
    args = c
    f_name = var_dep_inv
    enable_jit = true
    derivative_order = 3
  [../]

	[./effective_elastic_tensor]
		type = CompositeElasticityTensor
		args = c
		tensors = 'stiffness_precipitate stiffness_matrix'
		weights = 'var_dep var_dep_inv'
	[../]

  [./eigenstrain]
    type = ComputeVariableEigenstrain
		# right
    eigen_base = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		prefactor = var_dep
    args = 'c'
    eigenstrain_name = eigenstrain
  [../]
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y'
    eigenstrain_names = eigenstrain
  [../]
  [./elastic_free_energy]
    type = ElasticEnergyMaterial
    f_name = Fe
    args = 'c disp_x disp_y'
    derivative_order = 3
  [../]

  # Sum up chemical and elastic contributions
  [./free_energy]
    type = DerivativeSumMaterial
    f_name = F
    sum_materials = 'Fc Fe'
    args = 'c disp_x disp_y'
    derivative_order = 3
  [../]
[]

[BCs]
  [./disp_y]
    type = DirichletBC
    variable = disp_y
    boundary = 1
    value = 0
  [../]
  [./disp_x]
    type = DirichletBC
    variable = disp_x
    boundary = 1
    value = 0
  [../]
[]

[Preconditioning]
  # active = ' '
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[UserObjects]
	[./calculation_termination]
		type = Terminator
		expression = 'abs(delta_G) < 1e-8'
	[../]
[]

[Executioner]
  type = Transient
  scheme = bdf2

  solve_type = 'PJFNK'
	petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package -ksp_type'
	petsc_options_value = 'lu mumps gmres'


  l_max_its = 100
  nl_max_its = 10
  l_tol = 2.0e-4
  nl_rel_tol = 2.0e-4
  nl_abs_tol = 2.0e-5
  start_time = 0.0
  end_time = 1e20

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-4
		cutback_factor = 0.75
		growth_factor = 1.5
		iteration_window = 1
		optimal_iterations = 5
		linear_iteration_ratio = 100
  [../]
[]

[Postprocessors]
	[./integral_of_energy]
		type = ElementIntegralVariablePostprocessor
		variable = f_tot
	[../]
	[./delta_G]
		type = ChangeOverTimestepPostprocessor
		postprocessor = integral_of_energy
	[../]
	[./integral_of_elastic_energy]
		type = ElementIntegralVariablePostprocessor
		variable = f_el
	[../]
	[./integral_of_energy_stabilizer]
		type = ElementIntegralVariablePostprocessor
		variable = f_stab
	[../]
	[./dof_number]
		type = NumDOFs
		system = NL
	[../]
[]

[Outputs]
  csv = true
	[./exodus]
		type = Exodus
		interval = 10
		use_dispaced = false
	[../]
	[./console]
		type = Console
		max_rows = 10
		execute_on = TIMESTEP_END
	[../]
[]

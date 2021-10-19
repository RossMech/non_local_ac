[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_r_6.msh
[]

[Adaptivity]
	max_h_level = 4
	marker = marker
	initial_marker = marker
	initial_steps = 4
	[./Markers]
		[./box_marker]
			type = BoxMarker
			bottom_left = '-6.5 -6.5 0.0'
			top_right = '6.5 6.5 0.0'
			variable = eta
			inside = REFINE
			outside = DO_NOTHING
		[../]
		[./marker]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = eta
			third_state = DO_NOTHING
		[../]
	[../]
[]

[GlobalParams]
	derivative_order = 3
	use_displaced = false
[]

[Variables]
  # Order variables
  [./eta]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = 6
      invalue = 1.0
      outvalue = 0.0
      int_width = 0.3
    [../]
  [../]
  # Displacements
  [./disp_x]
  [../]
  [./disp_y]
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

[Kernels]
  # ===========================================================ORDER_PARAMETER_A
  [./eta_dot]
    type = TimeDerivative
    variable = eta
  [../]
  [./eta_interface]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  [../]
  [./eta_allencahn]
    type = AllenCahn
    variable = eta
    f_name = f_total
		#f_name = f_bulk
		mob_name = L
  [../]
  [./volume_conservera]
    type = ADVolumeConservationKernel
    variable = eta
    mob_name = L
		lagrange_mult = L_mult
		weight_func = wa_diff
  [../]
  #==============================================================TensorMechanics
  [./TensorMechanics]
    displacements = 'disp_x disp_y'
  [../]
[]

[Materials]
  # ===================================================================Constants
  [./const]
    type = GenericConstantMaterial
    prop_names =  'L    kappa    omega'
    prop_values = '1.0  0.03134  3.6761'
  [../]
  # =========================================================Switching Functions
  [./wa]
    type = DerivativeParsedMaterial
    args = eta
    f_name = wa
    function = '3*eta*eta - 2*eta*eta*eta'
  [../]
	[./wa_diff]
		type = DerivativeParsedMaterial
		args = eta
		f_name = wa_diff
		material_property_names = 'dwa:=D[wa(eta),eta]'
		function = 'dwa'
	[../]
	[./wb]
		type = DerivativeParsedMaterial
		args = eta
		f_name = wb
		material_property_names = 'wa'
		function = '1 - wa'
	[../]
  # ============================================================Bulk free energy
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'eta'
    material_property_names = 'omega'
    function = 'omega * eta * eta * (1 - eta) * (1 - eta)'
  [../]
  #==================================================Lagrange constant functions
  [./psi]
    type = DerivativeParsedMaterial
    f_name = psi
    args = 'eta'
    material_property_names = 'wa_diff'
    function = 'wa_diff'
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'eta'
    material_property_names = 'mu_a:=D[f_total(eta),eta]'
		#material_property_names = 'mu_a:=D[f_bulk(eta),eta]'
		function = 'mu_a'
  [../]
  [./Lagrange_multiplier]
    type = DerivativeParsedMaterial
    postprocessor_names = 'psi_int chi_int'
    function = 'if(abs(psi_int > 1e-8),chi_int / psi_int,0.0)'
    f_name = L_mult
  [../]
  #===================================================================Elasticity
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
  [./effective_elastic_tensor]
		type = CompositeElasticityTensor
		args = 'eta'
		tensors = 'stiffness_precipitate stiffness_matrix'
		weights = 'wa                    wb'
	[../]
  [./eigenstrain]
    type = ComputeVariableEigenstrain
    eigen_base = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		prefactor = wa
    args = 'eta'
    eigenstrain_name = eigenstrain
  [../]
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y'
    eigenstrain_names = eigenstrain
  [../]
  [./stress]
    type = ComputeLinearElasticStress
  [../]
  [./elastic_free_energy]
    type = ElasticEnergyMaterial
    f_name = f_elast
    args = 'eta'
    derivative_order = 3
  [../]
  #============================================================Total Free Energy
  [./total_free_energy]
    type = DerivativeSumMaterial
    f_name = f_total
    args = 'eta'
    sum_materials = 'f_elast f_bulk'
  [../]
[]

[AuxVariables]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./wa_auxvar]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./psi_auxvar]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./chi_auxvar]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./f_dens]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_total
    interfacial_vars = 'eta'
    kappa_names = 'kappa'
  [../]
  [./wa_auxkernel]
    type = MaterialRealAux
    property = wa
    variable = wa_auxvar
  [../]
  [./psi_auxkernel]
    type = MaterialRealAux
    property = psi
    variable = psi_auxvar
  [../]
  [./chi_auxkernel]
    type = MaterialRealAux
    property = chi
    variable = chi_auxvar
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
  [./eta_vol]
    type = ElementIntegralVariablePostprocessor
    variable = wa_auxvar
  [../]
  [./memory]
    type = MemoryUsage
  [../]
  [./psi_int]
    type = ElementIntegralVariablePostprocessor
    variable = psi_auxvar
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  [../]
  [./chi_int]
    type = ElementIntegralVariablePostprocessor
    variable = chi_auxvar
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  [../]
[]

#preconditioning for the coupled variables.
[Preconditioning]
  [./coupling]
    type = SMP
    full = true
  [../]
[]

[UserObjects]
  [./calculation_termination]
    type = Terminator
    expression = 'abs(delta_f) < 1e-8'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = bdf2
  end_time = 1e8
  l_max_its = 20#30
  nl_max_its = 50#50
  nl_rel_tol = 1e-4 #1e-8
  nl_abs_tol = 1e-5 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 8
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-5
    cutback_factor = 0.5
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    interval = 10
  [../]
  exodus = true
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

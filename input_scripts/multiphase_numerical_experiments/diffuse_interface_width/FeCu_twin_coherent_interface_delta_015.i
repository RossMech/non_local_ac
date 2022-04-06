# note: check elastic energy at start of the transformation
[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_delta_015_reduced_mesh.msh
[]


#[Mesh]
#	type = GeneratedMesh
#	dim = 2
#	xmin = -8
#	ymin = -8
#	xmax = 8
#	ymax = 8
#	nx = 40
#	ny = 40
#[]

[Adaptivity]
	max_h_level = 8
	marker = marker
	initial_marker = marker
	initial_steps = 3
	recompute_markers_during_cycles = true
	[./Indicators]
		[./errorb]
			type = GradientJumpIndicator
			variable = etab
		[../]
		[./errorc]
			type = GradientJumpIndicator
			variable = etac
		[../]
		[./errorx]
			type = GradientJumpIndicator
			variable = disp_x
		[../]
		[./errory]
			type = GradientJumpIndicator
			variable = disp_y
		[../]
	[../]
	[./Markers]
		[./markerb]
			type = ErrorToleranceMarker
			refine = 5e-2
			coarsen = 1e-8
			indicator = errorb
		[../]
		[./markerc]
			type = ErrorToleranceMarker
			refine = 5e-2
			coarsen = 1e-8
			indicator = errorc
		[../]
		[./markerx]
			type = ErrorToleranceMarker
			refine = 5e-2
			coarsen = 1e-8
			indicator = errorx
		[../]
		[./markery]
			type = ErrorToleranceMarker
			refine = 5e-2
			coarsen = 1e-8
			indicator = errory
		[../]
		#[./markerb]
		#	type = ValueRangeMarker
		#	lower_bound = 0.01
		#	upper_bound = 0.99
		#	variable = etab
		#	third_state = DO_NOTHING
		#[../]
		#[./markerc]
		#	type = ValueRangeMarker
		#	lower_bound = 0.01
		#	upper_bound = 0.99
		#	variable = etac
		#	third_state = DO_NOTHING
		#[../]
		[./marker]
			type = ComboMarker
			markers = 'markerb markerc markerx markery'
		[../]
	[../]
[]

[GlobalParams]
	derivative_order = 3
	use_displaced = false
[]

[Variables]
  # Order variables
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = 6.0
      invalue = 0.0
      outvalue = 1.0
      int_width = 0.0
    [../]
  [../]
	[./etab]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = TwinSphereIC
			outside = 0.0
			inside_above = 1.0
			inside_under = 0.0
			r = 6.0
			n = '1 1'
    [../]
	[../]
	[./etac]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = TwinSphereIC
			outside = 0.0
			inside_above = 0.0
			inside_under = 1.0
			r = 6.0
			n = '1 1'
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
  [./etaa_dot]
    type = TimeDerivative
    variable = etaa
  [../]
  [./etaa_interface]
    type = ACInterface
    variable = etaa
    mob_name = L
    kappa_name = 'kappa'
  [../]
  [./etaa_bulk]
    type = ACGrGrMulti
    variable = etaa
    v = 'etab etac'
    gamma_names = 'gab gab'
    mob_name = L
  [../]
	[./etaa_elastic]
		type = AllenCahn
		variable = etaa
		f_name = f_elast
		mob_name = L
		args = 'etab etac'
	[../]
  # ===========================================================ORDER_PARAMETER_B
  [./etab_dot]
    type = TimeDerivative
    variable = etab
  [../]
  [./etab_interface]
    type = ACInterface
    variable = etab
    mob_name = L
    kappa_name = 'kappa'
  [../]
  [./etab_bulk]
    type = ACGrGrMulti
    variable = etab
    v =           'etaa etac'
    gamma_names = 'gab gbc'
    mob_name = L
  [../]
	[./etab_elastic]
		type = AllenCahn
		variable = etab
		f_name = f_elast
		mob_name = L
		args = 'etaa etac'
	[../]
	#[./volume_conserverb]
	#	type = VolumeConservationKernel
	#	variable = etab
	#	mob_name = L
	#	lagrange_mult = L_mult_b
	#	weight_func = wb
	#[../]
	# ===========================================================ORDER_PARAMETER_C
	[./etac_dot]
		type = TimeDerivative
		variable = etac
	[../]
	[./etac_interface]
		type = ACInterface
		variable = etac
		mob_name = L
		kappa_name = 'kappa'
	[../]
	[./etac_bulk]
		type = ACGrGrMulti
		variable = etac
		v =           'etaa etab'
		gamma_names = 'gab gbc'
		mob_name = L
	[../]
	[./etac_elastic]
		type = AllenCahn
		variable = etac
		f_name = f_elast
		mob_name = L
		args = 'etaa etab'
	[../]
	#[./volume_conserverc]
	#	type = VolumeConservationKernel
	#	variable = etac
	#	mob_name = L
	#	lagrange_mult = L_mult_c
	#	weight_func = wc
	#[../]
	#==============================================================TensorMechanics
	[./TensorMechanics]
		displacements = 'disp_x disp_y'
	[../]
[]

[Materials]
  # ===================================================================Constants
  [./const]
    type = GenericConstantMaterial
    prop_names =  'L    gab     gbc     kappa     mu'
    prop_values = '1.0  1.37    0.53    0.0060    129.0808'
  [../]
  # ============================================================Bulk free energy
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'etaa etab etac'
    material_property_names = 'mu gab gbc'
    function = 'mu*((etaa*etaa*etaa*etaa/4-etaa*etaa/2)+(etab*etab*etab*etab/4
    -etab*etab/2)+((etac*etac*etac*etac/4-etac*etac/2))
		+(gab*etaa*etaa*(etab*etab+etac*etac)+gbc*etab*etab*etac*etac)+1/4)'
	[../]
	# =========================================================Switching Functions
	[./wb]
    type = DerivativeParsedMaterial
    args = etab
    f_name = wb
    function = '6*etab - 6*etab*etab'
  [../]
	[./wc]
    type = DerivativeParsedMaterial
    args = etac
    f_name = wc
    function = '6*etac - 6*etac*etac'
  [../]
	[./ha]
		type = SwitchingFunctionMultiPhaseMaterial
		h_name = ha
		all_etas = 'etab etaa etac'
		phase_etas = 'etaa'
	[../]
	[./hb]
		type = SwitchingFunctionMultiPhaseMaterial
		h_name = hb
		all_etas = 'etaa etab etac'
		phase_etas = 'etab'
	[../]
	[./hc]
		type = SwitchingFunctionMultiPhaseMaterial
		h_name = hc
		all_etas = 'etaa etab etac'
		phase_etas = 'etac'
	[../]
	#==================================================Lagrange constant functions
	[./psib]
    type = DerivativeParsedMaterial
    f_name = psib
    args = 'etab'
    material_property_names = 'wb'
    function = 'wb'
  [../]
	[./psic]
    type = DerivativeParsedMaterial
    f_name = psic
    args = 'etac'
    material_property_names = 'wc'
    function = 'wc'
  [../]
	[./chib]
    type = DerivativeParsedMaterial
    f_name = chib
    args = 'etaa etab etac'
    material_property_names = 'mu_b:=D[f_total(etaa,etab,etac),etab]'
		#material_property_names = 'mu_b:=D[f_bulk(etaa,etab,etac),etab]'
		function = 'mu_b'
  [../]
	[./chic]
    type = DerivativeParsedMaterial
    f_name = chic
    args = 'etaa etab etac'
    material_property_names = 'mu_c:=D[f_total(etaa,etab,etac),etac]'
		#material_property_names = 'mu_c:=D[f_bulk(etaa,etab,etac),etac]'
    function = 'mu_c'
  [../]
	[./Lagrange_multiplier_b]
		type = DerivativeParsedMaterial
		postprocessor_names = 'psi_int_b chi_int_b'
		function = 'if(abs(psi_int_b > 1e-8),chi_int_b / psi_int_b,0.0)'
		f_name = L_mult_b
	[../]
	[./Lagrange_multiplier_c]
		type = DerivativeParsedMaterial
		postprocessor_names = 'psi_int_c chi_int_c'
		function = 'if(abs(psi_int_c > 1e-8),chi_int_c / psi_int_c,0.0)'
		f_name = L_mult_c
	[../]
	#===================================================================Elasticity
	[./elasticity_tensor_matrix]
		type = ComputeElasticityTensor
		C_ijkl = '184.2973 126.4576 126.4576 184.2973 126.4576 184.2973 104.6428 104.6428 104.6428'
		fill_method = symmetric9
		base_name = stiffness_matrix
	[../]
	[./elasticity_tensor_precipitate_b]
		type = ComputeElasticityTensor
		C_ijkl = '151.3125 107.1896 108.7447 -1.9095 -5.7284 -13.0552 189.5016 70.5556 5.7284 1.9095 6.0394 187.9465 -3.8189 3.8189 7.0158 19.53 7.0158 1.9095 57.7191 -1.9095 56.1640'
		fill_method = symmetric21
		base_name = stiffness_precipitate_b
	[../]
	[./elasticity_tensor_precipitate_c]
		type = ComputeElasticityTensor
		C_ijkl = '189.5016 107.1896 70.5556 -1.9095 -5.7284 6.0394 151.3125 108.7447 5.7284 1.9095 -13.0552 187.9466 -3.8189 3.8189 7.0158 57.7191 7.0158 1.9095 19.53 -1.9095 56.164'
		fill_method = symmetric21
		base_name = stiffness_precipitate_c
	[../]
	[./effective_elastic_tensor]
		type = CompositeElasticityTensor
		args = 'etaa etab etac'
		tensors = 'stiffness_matrix   stiffness_precipitate_b stiffness_precipitate_c'
		weights = 'ha                 hb                      hc'
	[../]
	[./eigenstrain_b]
		type = GenericConstantRankTwoTensor
		tensor_values = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		tensor_name = eigenstrain_b
	[../]
	[./eigenstrain_c]
		type = GenericConstantRankTwoTensor
		tensor_values = '-0.1213 0.2417 -0.1107 -0.0183 -0.0053 -0.0290'
		tensor_name = eigenstrain_c
	[../]
	[./eigenstrain]
		type = CompositeEigenstrain
		tensors = 'eigenstrain_b eigenstrain_c'
		weights = 'hb            hc'
		args = 'etaa etab etac'
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
		args = 'etaa etab etac'
		derivative_order = 3
	[../]
	#============================================================Total Free Energy
	[./total_free_energy]
		type = DerivativeSumMaterial
		f_name = f_total
		args = 'etaa etab etac'
		sum_materials = 'f_elast f_bulk'
	[../]
[]

[AuxVariables]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
	[./psib_auxvar]
		order = CONSTANT
		family = MONOMIAL
	[../]
	[./psic_auxvar]
		order = CONSTANT
		family = MONOMIAL
	[../]
	[./chib_auxvar]
		order = CONSTANT
		family = MONOMIAL
	[../]
	[./chic_auxvar]
		order = CONSTANT
		family = MONOMIAL
	[../]
[]

[AuxKernels]
  [./f_dens]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_total
		#f_name = f_bulk
		interfacial_vars = 'etaa etab'
    kappa_names = 'kappa kappa'
  [../]
	[./psib_auxkernel]
		type = MaterialRealAux
		property = psib
		variable = psib_auxvar
	[../]
	[./psic_auxkernel]
		type = MaterialRealAux
		property = psic
		variable = psic_auxvar
	[../]
	[./chib_auxkernel]
		type = MaterialRealAux
		property = chib
		variable = chib_auxvar
	[../]
	[./chic_auxkernel]
		type = MaterialRealAux
		property = chic
		variable = chic_auxvar
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
  [./memory]
    type = MemoryUsage
  [../]
	[./etab_vol]
		type = ElementIntegralVariablePostprocessor
		variable = etab
	[../]
	[./etac_vol]
		type = ElementIntegralVariablePostprocessor
		variable = etac
	[../]
	[./ndof]
		type = NumDOFs
	[../]
	[./psi_int_b]
		type = ElementIntegralVariablePostprocessor
		variable = psib_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
	[../]
	[./psi_int_c]
		type = ElementIntegralVariablePostprocessor
		variable = psic_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
	[../]
	[./chi_int_b]
		type = ElementIntegralVariablePostprocessor
		variable = chib_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
	[../]
	[./chi_int_c]
		type = ElementIntegralVariablePostprocessor
		variable = chic_auxvar
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
	#solve_type = NEWTON
	scheme = bdf2
  end_time = 1e8
  l_max_its = 20#30
  nl_max_its = 30#50
	nl_rel_tol = 1e-5 #1e-8
  nl_abs_tol = 1e-6 #1e-11 -9 or 10 for equilibrium
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
    growth_factor = 1.5
    dt=1e-3
    cutback_factor = 0.5
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    #interval = 10
  [../]
  exodus = true
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

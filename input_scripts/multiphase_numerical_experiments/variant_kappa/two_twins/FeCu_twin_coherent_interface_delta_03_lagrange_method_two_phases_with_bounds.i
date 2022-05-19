# note: check elastic energy at start of the transformation
[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_delta_03.msh
[]

[Adaptivity]
	max_h_level = 4
	marker = marker
	initial_marker = marker
	initial_steps = 4
	[./Indicators]
		[./errorb]
			type = GradientJumpIndicator
			variable = etab
		[../]
		[./errorc]
			type = GradientJumpIndicator
			variable = etac
		[../]
	[../]
	[./Markers]
		[./markerb]
			type = ErrorToleranceMarker
			refine = 5e-2
			coarsen = 1e-7
			indicator = errorb
		[../]
		[./markerc]
			type = ErrorToleranceMarker
			refine = 5e-2
			coarsen = 1e-7
			indicator = errorc
		[../]
		[./marker]
			type = ComboMarker
			markers = 'markerb markerc'
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
      int_width = 0.3
    [../]
  [../]
	[./etab]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = TwoTwinUpperIC
			outside = 0.0
			inside = 1.0
			int_width = 0.3
			r = 6.0
			n = '1 -1'
		[../]
	[../]
	[./etac]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = TwoTwinLowerIC
			outside = 0.0
			inside = 1.0
			int_width = 0.3
			r = 6.0
			n = '1 -1'
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
		args = 'etab etac'
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
		args = 'etaa etac'
  [../]
	[./etab_bulk]
    type = ACGrGrMulti
    variable = etab
    v =           'etaa etac'
    gamma_names = 'gab gbc'
    mob_name = L
  [../]
	[./volume_conserverb]
		type = VolumeConservationKernel
		variable = etab
		mob_name = L
		lagrange_mult = L_mult_b
		weight_func = wb
	[../]
	[./etab_elastic]
		type = AllenCahn
		variable = etab
		f_name = f_elast
		mob_name = L
		args = 'etaa etac'
	[../]
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
		args = 'etab etaa'
	[../]
	[./etac_bulk]
		type = ACGrGrMulti
		variable = etac
		v =           'etaa etab'
		gamma_names = 'gab gbc'
		mob_name = L
	[../]
	[./volume_conserverc]
		type = VolumeConservationKernel
		variable = etac
		mob_name = L
		lagrange_mult = L_mult_c
		weight_func = wc
	[../]
	[./etac_elastic]
		type = AllenCahn
		variable = etac
		f_name = f_elast
		mob_name = L
		args = 'etaa etab'
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
    prop_names =  'L      gab      gbc     kappa_ab   kappa_bc   mu'
    prop_values = '1.0  2.4363    0.6608    0.0448     0.0103    12.0'
  [../]
	[./denom]
		type = DerivativeParsedMaterial
		f_name = denom
		args = 'etaa etab etac'
		function = 'etaa*etaa*etab*etab+etaa*etaa*etac*etac+etab*etab*etac*etac'
	[../]
	[./denom_mod]
		type = DerivativeParsedMaterial
		f_name = denom_mod
		args = 'etaa etab etac'
		material_property_names = 'denom'
		function = 'if(denom > 1e-8,denom,1e-8)'
	[../]
	[./kappa1]
		type = DerivativeParsedMaterial
		f_name = kappa
		args = 'etaa etab etac'
		material_property_names = 'kappa_ab kappa_bc denom_mod'
		function = '(kappa_ab*etaa*etaa*(etab*etab+etac*etac)+kappa_bc*etab*etab*etac*etac) / denom_mod'
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
		args = 'etaa etab etac'
		f_name = wb
		material_property_names = 'dhb:=D[hb,etab]'
		function = 'dhb'
	[../]
	[./wc]
		type = DerivativeParsedMaterial
		args = 'etaa etab etac'
		f_name = wc
		material_property_names = 'dhc:=D[hc,etac]'
		function = 'dhc'
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
	#===================================================================Lagrange parameters
	[./grad_part_b]
		type = DerivativeParsedMaterial
		args = 'etaa etab etac etab_x etab_y etac_x etac_y etaa_x etaa_y'
		material_property_names = 'dkappa_da:=D[kappa,etaa] dkappa_db:=D[kappa,etab] dkappa_dc:=D[kappa,etac]'
		function = 'dkappa_da*(etaa_x*etab_x+etaa_y*etab_y)+dkappa_db*(etab_x*etab_x+etab_y*etab_y)+dkappa_dc*(etab_x*etac_x+etab_y*etac_y)'
		outputs = exodus
		f_name = grad_part_b
	[../]
	[./grad_part_c]
		type = DerivativeParsedMaterial
		args = 'etaa etab etac etab_x etab_y etac_x etac_y etaa_x etaa_y'
		material_property_names = 'dkappa_da:=D[kappa,etaa] dkappa_db:=D[kappa,etab] dkappa_dc:=D[kappa,etac]'
		function = 'dkappa_da*(etaa_x*etac_x+etaa_y*etac_y)+dkappa_db*(etab_x*etac_x+etab_y*etac_y)+dkappa_dc*(etac_x*etac_x+etac_y*etac_y)'
		outputs = exodus
		f_name = grad_part_с
	[../]
	[./chi_b]
		type = DerivativeParsedMaterial
		args = 'etaa etab etac'
		material_property_names = 'grad_part_b mu_b:=D[f_total,etab]'
		function = 'mu_b+grad_part_b'
		f_name = chi_b
	[../]
	[./chi_c]
		type = DerivativeParsedMaterial
		args = 'etaa etab etac'
		material_property_names = 'grad_part_c mu_c:=D[f_total,etac]'
		function = 'mu_c+grad_part_c'
		f_name = chi_c
	[../]
	[./Lagrange_multiplier_b]
		type = DerivativeParsedMaterial
		postprocessor_names = 'psib_int chib_int'
		function = 'if(abs(psib_int > 1e-8),chib_int / psib_int,0.0)'
		f_name = L_mult_b
	[../]
	[./Lagrange_multiplier_c]
		type = DerivativeParsedMaterial
		postprocessor_names = 'psic_int chic_int'
		function = 'if(abs(psic_int > 1e-8),chic_int / psic_int,0.0)'
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
	[./etab_x]
		order = FIRST
		family = MONOMIAL
	[../]
	[./etab_y]
		order = FIRST
		family = MONOMIAL
	[../]
	[./etac_x]
		order = FIRST
		family = MONOMIAL
	[../]
	[./etac_y]
		order = FIRST
		family = MONOMIAL
	[../]
	[./etaa_x]
		order = FIRST
		family = MONOMIAL
	[../]
	[./etaa_y]
		order = FIRST
		family = MONOMIAL
	[../]
	[./psib_auxvar]
		order = FIRST
		family = MONOMIAL
	[../]
	[./chib_auxvar]
		order = FIRST
		family = MONOMIAL
	[../]
	[./psic_auxvar]
		order = FIRST
		family = MONOMIAL
	[../]
	[./chic_auxvar]
		order = FIRST
		family = MONOMIAL
	[../]
	[./bounds_dummy]
		order = FIRST
		family = LAGRANGE
	[../]
[]

[AuxKernels]
	[./grad_etab_x]
		type = VariableGradientComponent
		variable = etab_x
		component = x
		gradient_variable = etab
		execute_on = 'ALWAYS'
	[../]
	[./grad_etab_y]
		type = VariableGradientComponent
		variable = etab_y
		component = y
		gradient_variable = etab
		execute_on = 'ALWAYS'
	[../]
	[./grad_etac_x]
		type = VariableGradientComponent
		variable = etac_x
		component = x
		gradient_variable = etac
		execute_on = 'ALWAYS'
	[../]
	[./grad_etac_y]
		type = VariableGradientComponent
		variable = etac_y
		component = y
		gradient_variable = etac
		execute_on = 'ALWAYS'
	[../]
	[./grad_etaa_x]
		type = VariableGradientComponent
		variable = etaa_x
		component = x
		gradient_variable = etaa
		execute_on = 'ALWAYS'
	[../]
	[./grad_etaa_y]
		type = VariableGradientComponent
		variable = etaa_y
		component = y
		gradient_variable = etaa
		execute_on = 'ALWAYS'
	[../]
  [./f_dens]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_total
		#f_name = f_bulk
		interfacial_vars = 'etaa etab etac'
    kappa_names = 'kappa kappa kappa'
  [../]
	[./psib_auxkernel]
    type = MaterialRealAux
    property = wb
    variable = psib_auxvar
  [../]
  [./chib_auxkernel]
    type = MaterialRealAux
    property = chi_b
    variable = chib_auxvar
  [../]
	[./psic_auxkernel]
		type = MaterialRealAux
		property = wc
		variable = psic_auxvar
	[../]
	[./chic_auxkernel]
		type = MaterialRealAux
		property = chi_c
		variable = chic_auxvar
	[../]
[]

[Bounds]
	[./etab_upper_bound]
		type = ConstantBoundsAux
		variable = bounds_dummy
		bounded_variable = etab
		bound_type = upper
		bound_value = 1.0
	[../]
	[./etab_lower_bound]
		type = ConstantBoundsAux
		variable = bounds_dummy
		bounded_variable = etab
		bound_type = lower
		bound_value = 0.0
	[../]


	[./etac_upper_bound]
		type = ConstantBoundsAux
		variable = bounds_dummy
		bounded_variable = etac
		bound_type = upper
		bound_value = 1.0
	[../]
	[./etac_lower_bound]
		type = ConstantBoundsAux
		variable = bounds_dummy
		bounded_variable = etac
		bound_type = lower
		bound_value = 0.0
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
	[./dot_f]
		type = ChangeOverTimePostprocessor
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
	[./psib_int]
		type = ElementIntegralVariablePostprocessor
		variable = psib_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR'
	[../]
	[./chib_int]
		type = ElementIntegralVariablePostprocessor
		variable = chib_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR'
	[../]
	[./psic_int]
		type = ElementIntegralVariablePostprocessor
		variable = psic_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR'
	[../]
	[./chic_int]
		type = ElementIntegralVariablePostprocessor
		variable = chic_auxvar
		execute_on = 'INITIAL LINEAR NONLINEAR'
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
	scheme = implicit-euler
  end_time = 1e8
  l_max_its = 20#30
  nl_max_its = 30#50
	nl_rel_tol = 1e-7 #1e-8
  nl_abs_tol = 1e-8 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-8 # or 1e-4
	petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_type'
	petsc_options_value = 'lu          superlu_dist               vinewtonrsls'
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 7
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-3
    cutback_factor = 0.9
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    interval = 10
  [../]
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

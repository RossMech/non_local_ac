# note: check elastic energy at start of the transformation
[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_delta_03.msh
[]


[Adaptivity]
	max_h_level = 3
	marker = marker
	initial_marker = marker
	initial_steps = 3
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
	#[./etaa_interface2]
	#	type = ACInterfaceMultiDerivative
	#	variable = etaa
	#	mob_name = L
	#	kappa_name = kappa
	#	v = 'etab etac'
	#[../]
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
	#[./etab_interface2]
	#	type = ACInterfaceMultiDerivative
	#	variable = etab
	#	mob_name = L
	#	kappa_name = kappa
	#	v = 'etaa etac'
	#[../]
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
	[./volume_penalty_b]
		type = MaterialValueKernel
		variable = etab
		Mat_name = 'penalty_b'
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
	#[./etac_interface2]
	#	type = ACInterfaceMultiDerivative
	#	variable = etac
	#	mob_name = L
	#	kappa_name = kappa
	#	v = 'etaa etab'
	#[../]
	[./etac_bulk]
		type = ACGrGrMulti
		variable = etac
		v =           'etaa etab'
		gamma_names = 'gab gbc'
		mob_name = L
	[../]
	[./volume_penalty_c]
		type = MaterialValueKernel
		variable = etac
		Mat_name = 'penalty_c'
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
    prop_names =  'L      gab      gbc     kappa_ab   kappa_bc   mu   penalty_coef'
    #prop_values = '1.0  2.4363    0.6608    0.0448     0.0103    12.0   4.0e-1'
		prop_values = '1.0  2.4363    0.6608    0.0224     0.005015    24.0   1.6e0' # old 8.0e-1
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
		#f_name = kappa1
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
	#===================================================================Elasticity
	#[./elasticity_tensor_matrix]
	#	type = ComputeElasticityTensor
	#	C_ijkl = '184.2973 126.4576 126.4576 184.2973 126.4576 184.2973 104.6428 104.6428 104.6428'
	#	fill_method = symmetric9
	#	base_name = stiffness_matrix
	#[../]
	#[./elasticity_tensor_precipitate_b]
	#	type = ComputeElasticityTensor
	#	C_ijkl = '151.3125 107.1896 108.7447 -1.9095 -5.7284 -13.0552 189.5016 70.5556 5.7284 1.9095 6.0394 187.9465 -3.8189 3.8189 7.0158 19.53 7.0158 1.9095 57.7191 -1.9095 56.1640'
	#	fill_method = symmetric21
	#	base_name = stiffness_precipitate_b
	#[../]
	#[./elasticity_tensor_precipitate_c]
	#	type = ComputeElasticityTensor
	#	C_ijkl = '189.5016 107.1896 70.5556 -1.9095 -5.7284 6.0394 151.3125 108.7447 5.7284 1.9095 -13.0552 187.9466 -3.8189 3.8189 7.0158 57.7191 7.0158 1.9095 19.53 -1.9095 56.164'
	#	fill_method = symmetric21
	#	base_name = stiffness_precipitate_c
	#[../]
	[./elasticity_tensor]
		type = ComputeElasticityTensor
		C_ijkl = '81.3768 0.4'
		fill_method = symmetric_isotropic_E_nu
	[../]
	#[./effective_elastic_tensor]
	#	type = CompositeElasticityTensor
	#	args = 'etaa etab etac'
	#	tensors = 'stiffness_matrix   stiffness_precipitate_b stiffness_precipitate_c'
	#	weights = 'ha                 hb                      hc'
	#[../]
	[./eigenstrain_b]
		type = GenericConstantRankTwoTensor
		tensor_values = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		#tensor_name = eigenstrain_b
		tensor_name = eigenstrain_c
	[../]
	[./eigenstrain_c]
		type = GenericConstantRankTwoTensor
		tensor_values = '-0.1213 0.2417 -0.1107 -0.0183 -0.0053 -0.0290'
		#tensor_name = eigenstrain_c
		tensor_name = eigenstrain_b
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
	#===========================================================Volume Penalties
	[./penalty_b]
		type = DerivativeParsedMaterial
		f_name = penalty_b
		args = 'etaa etab etac'
		material_property_names = 'wb penalty_coef'
		postprocessor_names = etab_vol
		function = 'penalty_coef*wb*(etab_vol - 5.656959e+01)'
	[../]
	[./penalty_c]
		type = DerivativeParsedMaterial
		f_name = penalty_c
		args = 'etaa etab etac'
		material_property_names = 'wc penalty_coef'
		postprocessor_names = etac_vol
		function = 'penalty_coef*wc*(etac_vol - 5.656959e+01)'
	[../]
[]

[AuxVariables]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
	[./kappa_auxvar]
		order = CONSTANT
		family = MONOMIAL
	[../]
	[./f_elast]
		order = CONSTANT
		family = MONOMIAL
	[../]
[]

[AuxKernels]
	[./f_elast]
		type = MaterialRealAux
		variable = f_elast
		property = f_elast
	[../]
  [./f_dens]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_total
		#f_name = f_bulk
		interfacial_vars = 'etaa etab'
    kappa_names = 'kappa kappa'
  [../]
	[./kappa_auxkernel]
		type = MaterialRealAux
		property = kappa
		variable = kappa_auxvar
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
    growth_factor = 1.1
    dt=1e-3
    cutback_factor = 0.5
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

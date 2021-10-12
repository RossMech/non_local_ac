[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_a_025.msh
[]

[Adaptivity]
	max_h_level = 4
	marker = marker
	initial_marker = box_marker
	initial_steps = 4
	[./Markers]
		[./box_marker]
			type = BoxMarker
			bottom_left = '-12 -12 0'
			top_right = '12 12 0'
			inside = refine
			outside = do_nothing
		[../]
		[./marker_a]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = etaa
			third_state = DO_NOTHING
		[../]
		[./marker_b]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = etab
			third_state = DO_NOTHING
		[../]
		[./marker]
			type = ComboMarker
			markers = 'marker_a marker_b'
		[../]
	[../]
[]

[GlobalParams]
	derivative_order = 3
[]

[Variables]
  # Order variables
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
			type = SmoothCircleIC
	    x1 = -5.3199
			y1 = -4.1546
			radius = 2.0
	    invalue = 1.0
	    outvalue = 0.0
	    int_width = 0.3
    [../]
  [../]
  [./etab]
    family = LAGRANGE
    order = FIRST
		[./InitialCondition]
			type = SmoothCircleIC
	    x1 = 5.3199
			y1 = 4.1546
			radius = 4.0
	    invalue = 1.0
	    outvalue = 0.0
	    int_width = 0.3
    [../]
  [../]
	[./etac]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = SmoothCircleFromFileIC
			file_name = 'single_phase_verification_etaa.txt'
			invalue = 0.0
			outvalue = 1.0
			int_width = 0.3
		[../]
	[]
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
  [./volume_conservera]
    type = MaterialValueKernel
    variable = etaa
    Mat_name = func_a
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
    v = 'etaa etac'
    gamma_names = 'gab gab'
    mob_name = L
  [../]
  [./etab_elastic]
    type = AllenCahn
    variable = etab
    f_name = f_elast
    mob_name = L
    args = 'etaa etac'
  [../]
  [./volume_conserverb]
    type = MaterialValueKernel
    variable = etab
    Mat_name = func_b
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
  [../]
  [./etac_bulk]
    type = ACGrGrMulti
    variable = etac
    v =           'etaa etab'
    gamma_names = 'gab  gab'
    mob_name = L
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
    prop_names =  'L   gab  kappa   mu'
    prop_values = '1.0 1.5   0.09  8.0'
  [../]
  # =========================================================Switching Functions
  [./wa]
    type = DerivativeParsedMaterial
    args = etaa
    f_name = wa
    function = '3*etaa*etaa - 2*etaa*etaa*etaa'
  [../]
	[./wb]
		type = DerivativeParsedMaterial
		args = etab
		f_name = wb
		function = '3*etab*etab - 2*etab*etab*etab'
	[../]
	[./w_precip]
		type = DerivativeSumMaterial
		args = 'etaa etab'
		sum_materials = 'wa wb'
		f_name = w_precip
	[../]
  [./ha]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etab etaa etac'
    phase_etas = 'etaa etab'
  [../]
  [./hc]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = hc
    all_etas = 'etaa etab etac'
    phase_etas = 'etac'
  [../]
  # ============================================================Bulk free energy
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'etaa etab etac'
    material_property_names = 'mu gab'
    function = 'mu*((etaa*etaa*etaa*etaa/4-etaa*etaa/2)+(etab*etab*etab*etab/4
    -etab*etab/2)+(etac*etac*etac*etac/4-etac*etac/2)
		+(gab*etab*etab*etaa*etaa)+(gab*etac*etac*etaa*etaa)
		+(gab*etac*etac*etab*etab)+1/4)'
  [../]
  #==================================================Lagrange constant functions
  [./psi]
    type = DerivativeParsedMaterial
    f_name = psi
    args = 'etaa etab'
    material_property_names = 'dwa_a:=D[wa(etaa),etaa] dwb_b:=D[wb(etab),etab]'
    function = 'dwa_a + dwb_b'
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'etaa etab etac'
    material_property_names = 'mu_a:=D[f_total(etaa,etab,etac),etaa]
															 mu_b:=D[f_total(etaa,etab,etac),etab]'
    function = 'mu_a + mu_b'
  [../]
  [./Lagrange_multiplier]
    type = DerivativeParsedMaterial
    postprocessor_names = 'psi_int chi_int'
    function = 'if(abs(psi_int > 1e-8),chi_int / psi_int,0.0)'
    f_name = L_mult
  [../]
  [./stabilization_term_a]
    type = DerivativeParsedMaterial
    args = 'etaa'
    material_property_names = 'L_mult L dwa_a:=D[wa(etaa),etaa]'
    function = '-L*L_mult*dwa_a'
    f_name = func_a
  [../]
  [./stabilization_term_b]
    type = DerivativeParsedMaterial
    args = 'etab'
    material_property_names = 'L_mult L dwb_b:=D[wb(etab),etab]'
    function = '-L*L_mult*dwb_b'
    f_name = func_b
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
		args = 'etaa etab etac'
		tensors = 'stiffness_precipitate stiffness_matrix'
		weights = 'ha                    hc'
	[../]
  [./eigenstrain]
    type = ComputeVariableEigenstrain
    eigen_base = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		prefactor = ha
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
  [./w_precip_auxvar]
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
    interfacial_vars = 'etaa etab etac'
    kappa_names = 'kappa kappa kappa'
  [../]
  [./w_precip_auxkernel]
    type = MaterialRealAux
    property = w_precip
    variable = w_precip_auxvar
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
  [./precip_vol]
    type = ElementIntegralVariablePostprocessor
    variable = w_precip_auxvar
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

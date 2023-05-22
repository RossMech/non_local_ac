# note: check elastic energy at start of the transformation
[Mesh]
	type = FileMesh
	dim = 2
	file = mesh_case_5.msh
[]

[Adaptivity]
	max_h_level = 4
	marker = marker
	initial_marker = marker
	initial_steps = 4
	[./Markers]
		[./marker]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = etaa
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
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = SmoothCircleFromFileIC
      file_name = 'circles_case_5.txt'
      invalue = 1.0
      outvalue = 0.0
      int_width = 0.3
    [../]
  [../]
	[./etab]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
		type = SmoothCircleFromFileIC
      file_name = 'circles_case_5.txt'
      invalue = 0.0
      outvalue = 1.0
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
    v = 'etab'
    gamma_names = 'gab'
    mob_name = L
  [../]
  [./etaa_elastic]
    type = AllenCahn
    variable = etaa
    f_name = f_elast
    mob_name = L
    args = 'etab'
  [../]
  [./volume_conservera]
    type = VolumeConservationKernel
    variable = etaa
    mob_name = L
		lagrange_mult = L_mult
		weight_func = wa_diff
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
    v =           'etaa'
    gamma_names = 'gab'
    mob_name = L
  [../]
  [./etab_elastic]
    type = AllenCahn
    variable = etab
    f_name = f_elast
    mob_name = L
    args = 'etaa'
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
    prop_values = '1.0 1.5  0.1     7.2'
  [../]
  # =========================================================Switching Functions
  [./wa]
    type = DerivativeParsedMaterial
    args = etaa
    f_name = wa
    function = '3*etaa*etaa - 2*etaa*etaa*etaa'
  [../]
	[./wa_diff]
		type = DerivativeParsedMaterial
		args = etaa
		f_name = wa_diff
		material_property_names = 'dwa:=D[wa(etaa),etaa]'
		function = 'dwa'
	[../]
  [./ha]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etab etaa'
    phase_etas = 'etaa'
  [../]
  [./hb]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = hb
    all_etas = 'etaa etab'
    phase_etas = 'etab'
  [../]
  # ============================================================Bulk free energy
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'etaa etab'
    material_property_names = 'mu gab'
    function = 'mu*((etaa*etaa*etaa*etaa/4-etaa*etaa/2)+(etab*etab*etab*etab/4
    -etab*etab/2)+(gab*etab*etab*etaa*etaa)+1/4)'
  [../]
  #==================================================Lagrange constant functions
  [./psi]
    type = DerivativeParsedMaterial
    f_name = psi
    args = 'etaa etab'
    material_property_names = 'dwa_a:=D[wa(etaa),etaa]'
    function = 'dwa_a'
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'etaa'
    material_property_names = 'mu_a:=D[f_total(etaa,etab),etaa]'
    function = 'mu_a'
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
    material_property_names = 'L_mult L dwa_a:=D[wa(etaa,etab),etaa]'
    function = '-L*L_mult*dwa_a'
    f_name = func_a
  [../]
  #===================================================================Elasticity
  [./elasticity_tensor_matrix]
    type = ComputeElasticityTensor
    C_ijkl = '184.30 126.46 126.46 184.30 126.46 184.30 7.23 7.23 7.23'
    fill_method = symmetric9
    base_name = stiffness_matrix
  [../]
  [./elasticity_tensor_precipitate]
		type = ComputeElasticityTensor
		C_ijkl = '81.3768 0.4'
		fill_method = symmetric_isotropic_E_nu
		base_name = stiffness_precipitate
	[../]
  [./effective_elastic_tensor]
		type = CompositeElasticityTensor
		args = 'etaa etab'
		tensors = 'stiffness_precipitate stiffness_matrix'
		weights = 'ha                    hb'
	[../]
  [./eigenstrain]
    type = ComputeVariableEigenstrain
    eigen_base = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		prefactor = ha
    args = 'etaa etab'
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
    args = 'etaa etab'
    derivative_order = 3
  [../]
  #============================================================Total Free Energy
  [./total_free_energy]
    type = DerivativeSumMaterial
    f_name = f_total
    args = 'etaa etab'
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
    interfacial_vars = 'etaa etab'
    kappa_names = 'kappa kappa'
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
  [./etaa_vol]
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

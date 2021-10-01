[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 75
  ny = 75
  xmin = 0
  xmax = 200
  ymin = 0
  ymax = 200
[]

[Adaptivity]
	max_h_level = 3
	marker = marker
	initial_marker = box_marker
	initial_steps = 3
	[./Markers]
		[./box_marker]
			type = BoxMarker
			bottom_left = '0 0 0'
			top_right = '25 25 0'
			inside = refine
			outside = do_nothing
		[../]
		[./marker]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = etaa
			third_state = DO_NOTHING
		[../]
	[../]
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
      radius = 20
      invalue = 1.0
      outvalue = 0.0
      int_width = 4
    [../]
  [../]
  [./etab]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = 20
      invalue = 0.0
      outvalue = 1.0
      int_width = 4
    [../]
  [../]
  # Structural variable potentials
  [./mua]
  [../]
  # Displacements
  [./disp_x]
  [../]
  [./disp_y]
  [../]
[]


[BCs]
  [./left_x]
    type = DirichletBC
    variable = disp_x
    value = 0.0
    boundary = left
  [../]
  [./bottom_y]
    type = DirichletBC
    variable = disp_y
    value = 0.0
    boundary = bottom
  [../]
[]

[Kernels]
  # ===========================================================ORDER_PARAMETER_A
  [./etaa_eq]
    type = SplitCHParsed
    variable = etaa
    f_name = f_bulk
    kappa_name = kappa
    w = mua
  [../]
  #=======================================================STRUCTURAL_POTENTIAL_A
  [./etaa_dot]
    type = CoupledTimeDerivative
    variable = mua
    v = etaa
  [../]
  [./mua_kernel]
    type = MaterialValueKernel
    variable = mua
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
    v =           'etaa'
    gamma_names = 'gab'
    mob_name = L
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
    prop_names =  'L    gab kappa mu  misfit'
    prop_values = '1.0  1.5 37.5 300 0.01'
  [../]
  # =========================================================Switching Functions
  [./wa]
    type = DerivativeParsedMaterial
    args = etaa
    f_name = wa
    function = '3*etaa*etaa - 2*etaa*etaa*etaa'
  [../]
  [./ha]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etab etaa'
    phase_etas = 'etaa'
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
    function = 'dwa_a*dwa_a'
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'etaa mua'
    material_property_names = 'dwa_a:=D[wa(etaa),etaa]'
    function = 'dwa_a*mua'
  [../]
  [./Lagrange_multiplier]
    type = DerivativeParsedMaterial
    postprocessor_names = 'psi_int chi_int'
    function = 'if(abs(psi_int > 1e-8),chi_int / psi_int,0.0)'
    f_name = L_mult
  [../]
  [./stabilization_term_a]
    type = DerivativeParsedMaterial
    args = 'etaa mua'
    material_property_names = 'L_mult L dwa_a:=D[wa(etaa,etab),etaa]'
    function = 'L*(mua - L_mult*dwa_a)'
    f_name = func_a
  [../]
  #===================================================================Elasticity
  [./elasticity_tensor]
    type = ComputeElasticityTensor
    C_ijkl = '250 170 170 250 170 250 100 100 100'
    fill_method = symmetric9
  [../]
  [./prefactor]
    type = DerivativeParsedMaterial
    args = 'etaa etab'
    material_property_names = 'ha(etaa,etab) misfit'
    function = 'ha*misfit'
    f_name = prefactor
  [../]
  [./eigenstrain]
    type = ComputeVariableEigenstrain
    eigen_base = '1.0 1.0 0.0 0.0 0.0 0.0'
    prefactor = prefactor
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
    f_name = Fe
    args = 'etaa etab'
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
    f_name = f_bulk
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
  nl_rel_tol = 1e-4 #1e-8
  nl_abs_tol = 1e-5 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 8
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-2
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

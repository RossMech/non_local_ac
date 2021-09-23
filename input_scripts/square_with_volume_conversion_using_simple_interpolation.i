# Simulation of initial square phase transforming into circle and shrinking
# due to curved interface

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 250
  ny = 250
  xmin = 0
  xmax = 500
  ymin = 0
  ymax = 500
[]

[Adaptivity]
	max_h_level = 2
	marker = marker
	initial_marker = box_marker
	initial_steps = 2
	[./Markers]
		[./box_marker]
			type = BoxMarker
			bottom_left = '0 0 0'
			top_right = '28 28 0'
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
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = BoundingBoxIC
      x1 = -25
      x2 = 25
      y1 = -25
      y2 = 25
      inside = 1.0
      outside = 0.0
      int_width = 2.5
    [../]
  [../]
  [./etab]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = BoundingBoxIC
      x1 = -25
      x2 = 25
      y1 = -25
      y2 = 25
      inside = 0.0
      outside = 1.0
      int_width = 2.5
    [../]
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
    v =           'etab'
    gamma_names = 'gab'
    mob_name = L
  [../]
  [./volume_conserver_a]
    type = MaterialValueKernel
    variable = etaa
    Mat_name = stab_func_a
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
  [./volume_conserver_b]
    type = MaterialValueKernel
    variable = etab
    Mat_name = stab_func_b
  [../]
[]

[Materials]
  # ===================================================================Constants
  [./const]
    type = GenericConstantMaterial
    prop_names =  'L    gab kappa mu'
    prop_values = '1.0  1.5 1.875 2.4'
  [../]
  # =========================================================Switching Functions
  #[./ha]
  #  type = SwitchingFunctionMultiPhaseMaterial
  #  h_name = ha
  #  all_etas = 'etaa etab'
  #  phase_etas = 'etaa'
  #[../]
  #[./hb]
  #  type = SwitchingFunctionMultiPhaseMaterial
  #  h_name = hb
  #  all_etas = 'etaa etab'
  #  phase_etas = 'etab'
  #[../]
  [./ha]
    type = DerivativeParsedMaterial
    args = etaa
    f_name = ha
    function = etaa
  [../]
  [./hb]
    type = DerivativeParsedMaterial
    args = etab
    f_name = hb
    function = etab
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
    material_property_names = 'dha_a:=D[ha(etaa,etab),etaa] dha_b:=D[ha(etaa,etab),etab]'
    function = 'dha_a*dha_a + dha_b*dha_b'
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'etaa etab'
    material_property_names = 'dha_a:=D[ha(etaa,etab),etaa]
                               dha_b:=D[ha(etaa,etab),etab]
                               mu_loc_a:=D[f_bulk(etaa,etab),etaa]
                               mu_loc_b:=D[f_bulk(etaa,etab),etab]'
    function = 'dha_a*mu_loc_a + dha_b*mu_loc_b'
  [../]
  [./Lagrange_multiplier]
    type = DerivativeParsedMaterial
    postprocessor_names = 'psi_int chi_int'
    function = 'if(abs(psi_int > 1e-8),chi_int / psi_int,0.0)'
    f_name = L_mult
  [../]
  [./stabilization_term_a]
    type = DerivativeParsedMaterial
    material_property_names = 'L_mult L dha_a:=D[ha(etaa,etab),etaa]'
    function = '-L*L_mult*dha_a'
    f_name = stab_func_a
  [../]
  [./stabilization_term_b]
    type = DerivativeParsedMaterial
    material_property_names = 'L_mult L dha_b:=D[ha(etaa,etab),etab]'
    function = '-L*L_mult*dha_b'
    f_name = stab_func_b
  [../]
[]

[AuxVariables]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./ha_auxvar]
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
  [./ha_auxkernel]
    type = MaterialRealAux
    property = ha
    variable = ha_auxvar
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
    variable = ha_auxvar
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
  scheme = implicit-euler
  end_time = 1e8
  l_max_its = 15#30
  nl_max_its = 15#50
  nl_rel_tol = 1e-5 #1e-8
  nl_abs_tol = 1e-6 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 8
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.01
    dt=1
    cutback_factor = 0.5
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    interval = 5
  [../]
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

# Simulation of initial square phase transforming into circle and shrinking
# due to curved interface

[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 25
  ny = 25
  xmin = 0
  xmax = 50
  ymin = 0
  ymax = 50
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
  [./mua]
  [../]
  [./mub]
  [../]
[]

[Kernels]
  # Note, the equations are reversed. It means, that the equation for order parameter
  # is used to calculate the variable potential, as it is made in Split CahnHilliard
  #============================================================ORDER_PARAMETER_A
  [./mua_eq]
    type = SplitCHParsed
    variable = etaa
    f_name = f_bulk
    kappa_name = kappa
    w = mua
  [../]
  #=========================================================Variable_Potential_A
  [./detaa_dt]
    type = CoupledTimeDerivative
    variable = mua
    v = etaa
  [../]
  [./etaa_rhs] # maybe implement term (mu - Ldh/deta) for better convergence and automatization purpose?
    type = MaterialValueKernel
    variable = mua
    Mat_name = total_func_a
  [../]
  #============================================================ORDER_PARAMETER_B
  [./mub_eq]
    type = SplitCHParsed
    variable = etab
    f_name = f_bulk
    kappa_name = kappa
    w = mub
  [../]
  #=========================================================Variable_Potential_A
  [./detab_dt]
    type = CoupledTimeDerivative
    variable = mub
    v = etab
  [../]
  [./etab_rhs]
    type = MaterialValueKernel
    variable = mub
    Mat_name = total_func_b
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
  [./ha]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etaa etab'
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
    material_property_names = 'dha_a:=D[ha(etaa,etab),etaa] dha_b:=D[ha(etaa,etab),etab]'
    function = 'dha_a*dha_a + dha_b*dha_b'
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'etaa etab mua mub'
    material_property_names = 'dha_a:=D[ha(etaa,etab),etaa]
                               dha_b:=D[ha(etaa,etab),etab]'
    function = 'dha_a*mua + dha_b*mub'
  [../]
  [./Lagrange_multiplier]
    type = DerivativeParsedMaterial
    postprocessor_names = 'psi_int chi_int'
    function = 'if(abs(psi_int > 1e-8),chi_int / psi_int,0.0)'
    f_name = L_mult
  [../]
  # functions, which are input in kernel for order parameters
  [./kernel_term_a]
    type = DerivativeParsedMaterial
    args = 'etaa etab mua'
    material_property_names = 'L_mult L dha_a:=D[ha(etaa,etab),etaa]'
    function = 'L*(mua - L_mult*dha_a)'
    f_name = total_func_a
  [../]
  [./kernel_term_b]
    type = DerivativeParsedMaterial
    args = 'etaa etab mub'
    material_property_names = 'L_mult L dha_b:=D[ha(etaa,etab),etab]'
    function = 'L*(mub  - L_mult*dha_b)'
    f_name = total_func_b
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
    interval = 50
  [../]
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

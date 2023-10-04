[Mesh]
  type = GeneratedMesh
  dim = 2
  nx = 6
  ny = 6
  xmin = 0
  xmax = 50
  ymin = 0
  ymax = 50
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
	[./w]
	[../]
[]

[Kernels]
  [./c_res]
    type = SplitCHParsed
    variable = c
    f_name = F
    kappa_name = kappa_c
    w = w
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
[]

[AuxKernels]
	[./f_total]
		type = TotalFreeEnergy
		variable = f_tot
		f_name = 'F'
		kappa_names = 'kappa_c'
		interfacial_vars = c
	[../]
[]

[Materials]
  [./pfmobility]
    type = GenericConstantMaterial
    prop_names  = 'M kappa_c'
    prop_values = '1.0 2.0968'
    block = 0
  [../]

  # simple chemical free energy with a miscibility gap
  [./chemical_free_energy]
    type = DerivativeParsedMaterial
    block = 0
    f_name = F
    args = 'c'
    constant_names       = 'omega  a2 a3 a4 a5 a6 a7 a8 a9 a10 delta_G'
    constant_expressions = '5.6036 8.072789087 -81.24549382 408.0297321 -1244.129167 2444.046270 -3120.635139 2506.663551 -1151.003178 230.2006355 0.0'
    function = 'omega*(a2*c^2+a3*c^3+a4*c^4+a5*c^5+a6*c^6+a7*c^7+a8*c^8+a9*c^9+a10*c^10) - delta_G * c^3*(6*c^2-15*c+10)'
    enable_jit = true
    derivative_order = 3
  [../]
[]

[Preconditioning]
  # active = ' '
  [./SMP]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = implicit-euler
  end_time = 1e8
  l_max_its = 15#30
  nl_max_its = 15#50
  nl_rel_tol = 1e-8 #1e-8
  nl_abs_tol = 1e-9 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 8
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-1
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

[Postprocessors]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_tot
  [../]
  [./delta_f]
    type = ChangeOverTimestepPostprocessor
    postprocessor = total_f
  [../]
  [./memory]
    type = MemoryUsage
  [../]
[]

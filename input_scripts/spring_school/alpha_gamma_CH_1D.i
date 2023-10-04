[Mesh]
	type = GeneratedMesh
	dim = 1
	nx = 1000
	xmin = -4
	xmax = 4
[]

[GlobalParams]
	derivative_order = 3
[]

[Variables]
	[./c]
    order = FIRST
    family = LAGRANGE
    [./InitialCondition]
      type = FunctionIC
      function = 'if(x>0,1,0)'
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
    constant_names       = 'omega  a2 a3 a4 a5 a6 a7 a8 a9 a10'
    constant_expressions = '5.6036 8.072789087 -81.24549382 408.0297321 -1244.129167 2444.046270 -3120.635139 2506.663551 -1151.003178 230.2006355'
    function = 'omega*(a2*c^2+a3*c^3+a4*c^4+a5*c^5+a6*c^6+a7*c^7+a8*c^8+a9*c^9+a10*c^10)'
    enable_jit = true
    derivative_order = 3
  [../]
[]

[BCs]
  [./c_left]
    type = DirichletBC
    variable = c
    boundary = 0
    value = 0
  [../]
  [./c_right]
    type = DirichletBC
		variable = c
		boundary = 1
		value = 1
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
  scheme = bdf2

  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type  -sub_pc_type '
  petsc_options_value = 'asm       lu'

  l_max_its = 100
  nl_max_its = 10
  l_tol = 2.0e-4
  nl_rel_tol = 2.0e-4
  nl_abs_tol = 2.0e-5
  start_time = 0.0
  end_time = 1000000

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-4
		cutback_factor = 0.75
		growth_factor = 1.5
		iteration_window = 1
		optimal_iterations = 5
		linear_iteration_ratio = 100
  [../]
[]

[Postprocessors]
	[./integral_of_energy]
		type = ElementIntegralVariablePostprocessor
		variable = f_tot
	[../]
	[./delta_G]
		type = ChangeOverTimestepPostprocessor
		postprocessor = integral_of_energy
	[../]
[]

[UserObjects]
	[./calculation_termination]
		type = Terminator
		expression = 'abs(delta_G) < 1e-8'
	[../]
[]

[Outputs]
  csv = true
	exodus = true
	[./console]
		type = Console
		max_rows = 10
	[../]
[]

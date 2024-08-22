[Mesh]
	type = GeneratedMesh
	dim = 1
	nx = 220
	xmin = -5
	xmax = 5
[]

[Variables]
  [eta]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = FunctionIC
      function = 'if(x>0,1,0)'
    []
  []
[]

[BCs]
  [eta_left]
    type = DirichletBC
    variable = eta
    boundary = 0
    value = 0
  []
  [eta_right]
    type = DirichletBC
		variable = eta
		boundary = 1
		value = 1
  []
[]

[Kernels]
  #============================================================ORDER_PARAMETER_A
  [eta_dot]
    type = TimeDerivative
    variable = eta
  []
  [eta_interface]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  []
  [eta_bulk]
    type = AllenCahn
    variable = eta
    f_name = f_bulk
    mob_name = L
    args = ''
  []
[]

[AuxVariables]
	[f_tot]
		family = MONOMIAL
		order = CONSTANT
	[]
[]

[Materials]
  # ===================================================================Constants
  [const]
    type = GenericConstantMaterial
    prop_names =  'L    kappa     omega'
    prop_values = '1.0  0.652866540556528   27.570719100807533'
  []
  # ============================================================Bulk free energy
  [f_bulk]
    type = DerivativeParsedMaterial
    property_name = f_bulk
    coupled_variables = eta
    material_property_names = 'omega'
    expression = 'omega*eta*eta*(1-eta)*(1-eta)'
  []
[]

[AuxKernels]
	[f_total]
		type = TotalFreeEnergy
		variable = f_tot
		f_name = f_bulk
		kappa_names = kappa
		interfacial_vars = eta
	[]
[]

[Preconditioning]
  # active = ' '
  [SMP]
    type = SMP
    full = true
  []
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

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-5
		cutback_factor = 0.75
		growth_factor = 1.5
		iteration_window = 1
		optimal_iterations = 5
		linear_iteration_ratio = 100
  []
[]

[Postprocessors]
	[integral_of_energy]
		type = ElementIntegralVariablePostprocessor
		variable = f_tot
	[]
	[delta_G]
		type = ChangeOverTimestepPostprocessor
		postprocessor = integral_of_energy
	[]
[]

[UserObjects]
	[calculation_termination]
		type = Terminator
		expression = 'abs(delta_G) < 1e-8'
	[]
[]

[Outputs]
  csv = true
	exodus = true
	[console]
		type = Console
		max_rows = 10
	[]
[]

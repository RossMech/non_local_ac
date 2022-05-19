[Mesh]
	type = GeneratedMesh
	dim = 1
	nx = 2000
	xmin = -8
	xmax = 8
[]

[Variables]
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = FunctionIC
      function = 'if(x>0,1,0)'
    [../]
  [../]
  [./etab]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = FunctionIC
      function = 'if(x>0,0,1)'
    [../]
  [../]
[]

[BCs]
  [./etaa_left]
    type = DirichletBC
    variable = etaa
    boundary = 0
    value = 0
  [../]
  [./etaa_right]
    type = DirichletBC
		variable = etaa
		boundary = 1
		value = 1
  [../]
  [./etab_left]
    type = DirichletBC
    variable = etab
    boundary = 0
    value = 1
  [../]
  [./etab_right]
    type = DirichletBC
    variable = etab
    boundary = 1
    value = 0
  [../]
[]

[Kernels]
  #============================================================ORDER_PARAMETER_A
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
[]

[AuxVariables]
	[./f_tot]
		family = MONOMIAL
		order = CONSTANT
	[../]
[]

[Materials]
  # ===================================================================Constants
  [./const]
    type = GenericConstantMaterial
    prop_names =  'L    gab    kappa     mu'
    prop_values = '1.0  0.7    0.1189   107.625'
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
[]

[AuxKernels]
	[./f_total]
		type = TotalFreeEnergy
		variable = f_tot
		f_name = 'f_bulk'
		kappa_names = 'kappa kappa'
		interfacial_vars = 'etaa etab'
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

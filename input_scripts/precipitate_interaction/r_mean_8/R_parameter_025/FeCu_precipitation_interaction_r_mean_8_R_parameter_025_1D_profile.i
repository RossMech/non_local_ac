[Mesh]
	type = GeneratedMesh
	dim = 1
	nx = 2000
	xmin = -8
	xmax = 8
[]

[GlobalParams]
	derivative_order = 3
	use_displaced = false
[]

[Variables]
  # Order variables
  # precipitate
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = FunctionIC
      function = 'if(x>0,1,0)'
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
    type = AllenCahn
    variable = etaa
    f_name = f_bulk
    mob_name = L
    args = ''
  [../]
[]

[Materials]
  # ===================================================================Constants
  [./const]
    type = GenericConstantMaterial
    prop_names =  'L   gab  kappa mu'
    prop_values = '1.0 1.5  0.18  8.0'
  [../]
  # ============================================================Bulk free energy
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'etaa'
    material_property_names = 'mu gab'
    function = 'mu*((etaa*etaa*etaa*etaa/4-etaa*etaa/2)+((1-etaa)*(1-etaa)*(1-etaa)*(1-etaa)/4
    -(1-etaa)*(1-etaa)/2)+(gab*(1-etaa)*(1-etaa)*etaa*etaa)+1/4)'
  [../]
[]

[AuxVariables]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./f_dens]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_bulk
    interfacial_vars = 'etaa'
    kappa_names = 'kappa'
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
  [./memory]
    type = MemoryUsage
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

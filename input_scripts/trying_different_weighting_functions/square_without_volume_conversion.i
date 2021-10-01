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
    -etab*etab/2)+(gab/2*etab*etab*etaa*etaa)+(gab/2*etaa*etaa*etab*etab)+1/4)'
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
  end_time = 1000
  l_max_its = 15#30
  nl_max_its = 15#50
  nl_rel_tol = 1e-8 #1e-8
  nl_abs_tol = 1e-9 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-5 # or 1e-4
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

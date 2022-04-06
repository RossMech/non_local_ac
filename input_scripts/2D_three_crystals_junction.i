# This simulation tests the TricrystalTripleJunctionIC

[Mesh]
  # Mesh block. Meshes can be read in or automatically generated.
  type = GeneratedMesh
  dim = 2 # Problem dimension
  nx = 50 # Number of elements in the x direction
  ny = 50 # Number of elements in the y direction
  xmax = 20 # Maximum x-coordinate of mesh
  xmin = 0 # Minimum x-coordinate of mesh
  ymax = 20 # Maximum y-coordinate of mesh
  ymin = 0 # Minimum y-coordinate of mesh
  elem_type = QUAD4 # Type of elements used in the mesh
[]
[Adaptivity]
	max_h_level = 2
	marker = marker
	initial_marker = marker
	initial_steps = 2
	[./Markers]
		[./marker1]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = gr0
			third_state = DO_NOTHING
		[../]
    [./marker2]
      type = ValueRangeMarker
      lower_bound = 0.01
      upper_bound = 0.99
      variable = gr1
      third_state = DO_NOTHING
    [../]
    [./marker]
      type = ComboMarker
      markers = 'marker1 marker2'
    [../]
	[../]
[]

[GlobalParams]
  # Parameters used by several kernels that are defined globally to simplify input file
  op_num = 3 # Number of order parameters used
  var_name_base = gr # base name of grains
  v = 'gr0 gr1 gr2' # Names of the grains
  theta1 = 120 # Angle the first grain makes at the triple junction
  theta2 = 120 # Angle the second grain makes at the triple junction
  length_scale = 1.0e-9 # Length scale in nm
  time_scale = 1.0e-9 # Time scale in ns
[]

[Variables]
  [./gr0]
    order = FIRST
    family = LAGRANGE
    [./InitialCondition]
       type = TricrystalTripleJunctionIC
       op_index = 1
    [../]
  [../]

  [./gr1]
    order = FIRST
    family = LAGRANGE
    [./InitialCondition]
       type = TricrystalTripleJunctionIC
       op_index = 2
    [../]
  [../]

  [./gr2]
    order = FIRST
    family = LAGRANGE
    [./InitialCondition]
       type = TricrystalTripleJunctionIC
       op_index = 3
    [../]
  [../]
[]

[AuxVariables]
  [./bnds]
    # Variable used to visualize the grain boundaries in the simulation
    order = FIRST
    family = LAGRANGE
  [../]
[]


[Kernels]
  #============================================================ORDER_PARAMETER_A
  [./gr0_dot]
    type = TimeDerivative
    variable = gr0
  [../]
  [./gr0_interface]
    type = ACInterface
    variable = gr0
    mob_name = L
    kappa_name = kappa
  [../]
  [./gr0_interface_dep]
    type = ACKappaFunction
    variable = gr0
    kappa_name = kappa
    mob_name = L
    v = 'gr1 gr2'
  [../]
  #[./gr0_bulk]
  #  type = ACGrGrMulti
  #  variable = gr0
  #  v = 'gr1 gr2'
  #  gamma_names = 'gab gab'
  #  mob_name = L
  #[../]
  [./gr0_bulk]
    type = AllenCahn
    variable = gr0
    mob_name = L
    f_name = bulk_energy
    args = 'gr1 gr2'
  [../]
  # ===========================================================ORDER_PARAMETER_B
  [./gr1_dot]
    type = TimeDerivative
    variable = gr1
  [../]
  [./gr1_interface]
    type = ACInterface
    variable = gr1
    mob_name = L
    kappa_name = kappa
  [../]
  #[./gr1_interface_dep]
  #  type = ACKappaFunction
  #  variable = gr1
  #  kappa_name = kappa
  #  mob_name = L
  #  v = 'gr0 gr2'
  #[../]
  #[./gr1_bulk]
  #  type = ACGrGrMulti
  #  variable = gr1
  #  v =           'gr0 gr2'
  #  gamma_names = 'gab gbc'
  #  mob_name = L
  #[../]
  [./gr1_bulk]
    type = AllenCahn
    variable = gr1
    mob_name = L
    f_name = bulk_energy
    args = 'gr0 gr2'
  [../]
  # ===========================================================ORDER_PARAMETER_C
  [./gr2_dot]
    type = TimeDerivative
    variable = gr2
  [../]
  [./gr2_interface]
    type = ACInterface
    variable = gr2
    mob_name = L
    kappa_name = kappa
  [../]
  #[./gr2_interface_dep]
  #  type = ACKappaFunction
  #  variable = gr2
  #  kappa_name = kappa
  #  mob_name = L
  #  v = 'gr0 gr1'
  #[../]
  #[./gr2_bulk]
  #  type = ACGrGrMulti
  #  variable = gr2
  #  v =           'gr0 gr1'
  #  gamma_names = 'gab gbc'
  #  mob_name = L
  #[../]
  [./gr2_bulk]
    type = AllenCahn
    variable = gr2
    mob_name = L
    f_name = bulk_energy
    args = 'gr1 gr0'
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
    prop_names =  'L    gab    gbc     mu    kab     kbc'
    prop_values = '1.0  0.7093 3.8661  5.0   0.02    0.0888'
  [../]

  [./gamma_var]
    type = DerivativeParsedMaterial
    f_name = gamma
    args = 'gr0 gr1 gr2'
    material_property_names = 'gab gbc'
    function = 'gab + (gbc-gab)*gr1*gr2/(gr0*gr1+gr0*gr2+gr1*gr2+1e-7)'
    outputs = exodus
  [../]
  [./kappa_var]
    type = DerivativeParsedMaterial
    f_name = kappa
    args = 'gr0 gr1 gr2'
    material_property_names = 'kab kbc'
    function = 'kab + (kbc-kab)*gr1*gr2/(gr0*gr1+gr0*gr2+gr1*gr2+1e-7)'
    outputs = exodus
  [../]


  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = bulk_energy
    args = 'gr0 gr1 gr2'
    material_property_names = 'gamma mu'
    function = 'mu*(gr0*gr0*gr0*gr0/4-gr0*gr0/2 +
                    gr1*gr1*gr1*gr1/4-gr1*gr1/2 +
                    gr2*gr2*gr2*gr2/4-gr2*gr2/2 +
                    gamma *(gr0*gr0*gr1*gr1 +
                           gr0*gr0*gr2*gr2+gr1*gr1*gr2*gr2)
                    +0.25)'
  [../]
  # ============================================================Bulk free energy
  #[./f_bulk]
  #  type = DerivativeParsedMaterial
  #  f_name = f_bulk
  #  args = 'gr0 gr1'
  #  material_property_names = 'mu gab'
  #  function = 'mu*((gr0*gr0*gr0*gr0/4-gr0*gr0/2)+(gr1*gr1*gr1*gr1/4
  #  -gr1*gr1/2)+(gab*gr1*gr1*gr0*gr0)+1/4)'
  #[../]
[]

[AuxKernels]
	[./f_total]
		type = TotalFreeEnergy
		variable = f_tot
		f_name = 'bulk_energy'
		kappa_names = 'kappa kappa kappa'
		interfacial_vars = 'gr0 gr1 gr2'
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
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'

  l_max_its = 100
  nl_max_its = 20
  l_tol = 2.0e-4
  nl_rel_tol = 2.0e-4
  nl_abs_tol = 2.0e-5
  start_time = 0.0
  end_time = 1000000

  [./TimeStepper]
    type = IterationAdaptiveDT
    dt = 1e-8
		cutback_factor = 0.75
		growth_factor = 1.1
		iteration_window = 1
		optimal_iterations = 7
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

[Outputs]
  csv = true
	exodus = true
  #nterval = 10
	[./console]
		type = Console
		max_rows = 10
	[../]
[]

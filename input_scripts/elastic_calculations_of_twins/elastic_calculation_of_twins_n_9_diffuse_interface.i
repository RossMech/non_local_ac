[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_r_6.msh
[]

[Adaptivity]
	max_h_level = 4
	marker = marker
	initial_marker = marker
	initial_steps = 4
	[./Markers]
		[./marker]
      type = BoxMarker
			bottom_left = '-10 -10 0'
			top_right = '10 10 0'
			inside = refine
			outside = do_nothing
		[../]
	[../]
[]

[GlobalParams]
	derivative_order = 3
	use_displaced = false
[]

[Variables]
	[./disp_x]
	[../]
	[./disp_y]
	[../]
[]

[BCs]
  [./disp_y]
    type = DirichletBC
    variable = disp_y
    boundary = 1
    value = 0
  [../]
  [./disp_x]
    type = DirichletBC
    variable = disp_x
    boundary = 1
    value = 0
  [../]
[]

[Kernels]
	[./TensorMechanics]
		displacements = 'disp_x disp_y'
	[../]
[]

[Materials]

  # Interpolation function
  [./ha]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = ha
    all_etas = 'etab etaa etac'
    phase_etas = 'etaa'
  [../]
  [./hb]
    type = SwitchingFunctionMultiPhaseMaterial
    h_name = hb
    all_etas = 'etaa etab etac'
    phase_etas = 'etab'
  [../]
	[./hc]
		type = SwitchingFunctionMultiPhaseMaterial
		h_name = hc
		all_etas = 'etaa etab etac'
		phase_etas = 'etac'
	[../]

  # elastic properties
  [./elasticity_tensor_matrix]
    type = ComputeElasticityTensor
    C_ijkl = '184.2973 126.4576 126.4576 184.2973 126.4576 184.2973 104.6428 104.6428 104.6428'
    fill_method = symmetric9
    base_name = stiffness_matrix
  [../]
  [./elasticity_tensor_precipitate_b]
    type = ComputeElasticityTensor
    C_ijkl = '151.3125 107.1896 108.7447 -1.9095 -5.7284 -13.0552 189.5016 70.5556 5.7284 1.9095 6.0394 187.9465 -3.8189 3.8189 7.0158 19.53 7.0158 1.9095 57.7191 -1.9095 56.1640'
    fill_method = symmetric21
    base_name = stiffness_precipitate_b
  [../]
	[./elasticity_tensor_precipitate_c]
		type = ComputeElasticityTensor
		C_ijkl = '189.5016 107.1896 70.5556 -1.9095 -5.7284 6.0394 151.3125 108.7447 5.7284 1.9095 -13.0552 187.9466 -3.8189 3.8189 7.0158 57.7191 7.0158 1.9095 19.53 -1.9095 56.164'
		fill_method = symmetric21
		base_name = stiffness_precipitate_c
	[../]
  [./effective_elastic_tensor]
    type = CompositeElasticityTensor
    args = 'etaa etab etac'
    tensors = 'stiffness_matrix   stiffness_precipitate_b stiffness_precipitate_c'
    weights = 'ha                 	hb													hc'
  [../]

  # eigenstrain
	[./eigenstrain_b]
		type = GenericConstantRankTwoTensor
		tensor_values = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
		tensor_name = eigenstrain_b
	[../]
	[./eigenstrain_c]
		type = GenericConstantRankTwoTensor
		tensor_values = '-0.1213 0.2417 -0.1107 -0.0183 -0.0053 -0.0290'
		tensor_name = eigenstrain_c
	[../]
	[./eigenstrain]
		type = CompositeEigenstrain
		tensors = 'eigenstrain_b eigenstrain_c'
		weights = 'hb            hc'
		args = 'etaa etab etac'
		eigenstrain_name = eigenstrain
	[../]

  # strain
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y'
    eigenstrain_names = eigenstrain
  [../]

  # stress
  [./stress]
		type = ComputeLinearElasticStress
	[../]

  # elastic free energy
  [./elastic_free_energy]
    type = ElasticEnergyMaterial
    f_name = f_elast
    args = 'etaa etab etac'
    derivative_order = 3
  [../]
[]

[AuxVariables]
  [./etaa]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
      type = MultiInclinedBoxIC
      inside = 0.0
      outside = 1.0
      a = 5.3174
      b = 5.3174
			c0 = '0.0 0.0 0.0'
      theta = 45.0
			int_width = 0.1
		[../]
	[../]
	[./etab]
	 family = LAGRANGE
	 order = FIRST
	 [./InitialCondition]
		 type = MultiInclinedBoxIC
		 inside = 1.0
		 outside = 0.0
		 a = '5.3174 5.3174 5.3174 5.3174 5.3174'
		 b = '0.5908 0.5908 0.5908 0.5908 0.5908'
		 c0 = '3.3422 -3.3422 0.0
		 			 1.6711 -1.6711 0.0
					 0.0		 0.0			0.0
					 -1.6711 1.6711 0.0
					 -3.3422 3.3422 0.0'
		 theta = '45.0 45.0 45.0 45.0 45.0'
		 int_width = 0.1
	 [../]
 [../]
 [./etac]
	 family = LAGRANGE
	 order = FIRST
	 [./InitialCondition]
		 type = MultiInclinedBoxIC
		 inside = 1.0
		 outside = 0.0
		 a = '5.3174 5.3174 5.3174 5.3174'
		 b = '0.5908 0.5908 0.5908 0.5908'
		 c0 = '2.5066 -2.5066 0.0
		 			 0.8355 -0.8355 0.0
					 -0.8355 0.8355 0.0
					 -2.5066 2.5066 0.0'
		 theta = '45.0 45.0 45.0 45.0'
		 int_width = 0.1
	 [../]
[../]
  [./f_elast]
    family = MONOMIAL
    order = CONSTANT
  [../]
[]

[AuxKernels]
  [./f_elast_auxkernel]
		type = MaterialRealAux
		property = f_elast
		variable = f_elast
	[../]
[]

[Postprocessors]
	[./f_elast_int]
		type = ElementIntegralVariablePostprocessor
		variable = f_elast
	[../]
[]

[Preconditioning]
  [./coupling]
    type = SMP
    full = true
  [../]
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  l_max_its = 20#30
  nl_max_its = 30#50
	nl_rel_tol = 1e-7 #1e-8
  nl_abs_tol = 1e-8 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-8 # or 1e-4
	petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_type'
	petsc_options_value = 'lu          superlu_dist               vinewtonrsls'
[]

[Outputs]
  csv = true
	exodus = true
  perf_graph = true
  checkpoint = true
[]

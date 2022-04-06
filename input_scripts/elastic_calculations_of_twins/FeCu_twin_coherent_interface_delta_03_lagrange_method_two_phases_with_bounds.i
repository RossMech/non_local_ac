# note: check elastic energy at start of the transformation
[Mesh]
	type = FileMesh
	dim = 2
	file = square_heterogeneous_delta_03.msh
[]

[Adaptivity]
	max_h_level = 5
	marker = boxmarker
	initial_marker = boxmarker
	initial_steps = 5
	[./Markers]
		[./boxmarker]
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
	#===================================================================Elasticity
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
		weights = 'ha                 hb                      hc'
	[../]
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
	[./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y'
    eigenstrain_names = eigenstrain
  [../]
	[./stress]
		type = ComputeLinearElasticStress
	[../]
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
			type = SmoothCircleIC
			x1 = 0.0
			y1 = 0.0
			radius = 6.0
			invalue = 0.0
			outvalue = 1.0
			int_width = 0.0
		[../]
	[../]
	#[./etab]
	#	family = LAGRANGE
	#	order = FIRST
	#	[./InitialCondition]
	#		type = TwoTwinUpperIC
	#		outside = 0.0
	#		inside = 1.0
	#		int_width = 0.0
	#  	r = 6.0
	# 	 n = '1 -1'
	#	[../]
	#[../]
	[./etab]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = SmoothCircleIC
			x1 = 0.0
			y1 = 0.0
			radius = 6.0
			invalue = 1.0
			outvalue = 0.0
			int_width = 0.0
		[../]
	[../]
	[./etac]
		family = LAGRANGE
		order = FIRST
		[./InitialCondition]
			type = TwoTwinLowerIC
			outside = 0.0
			#inside = 1.0
			inside = 0.0
			int_width = 0.0
			r = 6.0
			n = '1 -1'
		[../]
	[../]
	[./f_elast]
		family = MONOMIAL
		order = CONSTANT
	[../]
	[./eig_strain_xy]
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
	[./MaterialRankTwoTensorAux]
		type = MaterialRankTwoTensorAux
		i = 1
		j = 2
		property = eigenstrain
		variable = eig_strain_xy
	[../]
[]

[Postprocessors]
  [./memory]
    type = MemoryUsage
  [../]
	[./ndof]
		type = NumDOFs
	[../]
	[./f_elast_int]
		type = ElementIntegralVariablePostprocessor
		variable = f_elast
	[../]
[]

#preconditioning for the coupled variables.
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

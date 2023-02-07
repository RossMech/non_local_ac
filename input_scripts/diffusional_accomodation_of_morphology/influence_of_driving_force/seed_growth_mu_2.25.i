[Mesh]
  type = FileMesh
  dim = 2
  file = square_heterogeneous_growth_4_100_r_5.msh
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
			variable = eta
			third_state = DO_NOTHING
		[../]
	[../]
[]

[Variables]
  [./eta]
    [./InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = 4.0
      invalue = 1.0
      outvalue = 0.0
      int_width = 0.8
    [../]
  [../]
  [./mu]
    [./InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = 4.0
      invalue = -0.5653
      outvalue = 2.25
      int_width = 0.8
    [../]
  [../]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
[]

[BCs]
  [./mu_right]
    type = DirichletBC
    variable = mu
    boundary = 3
    value = 2.25
  [../]
  [./mu_top]
    type = DirichletBC
    variable = mu
    boundary = 4
    value = 2.25
  [../]
  [./mu_left]
    type = DirichletBC
    variable = mu
    boundary = 5
    value = 2.25
  [../]
  [./mu_bottom]
    type = DirichletBC
    variable = mu
    boundary = 6
    value = 2.25
  [../]
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
  #==============================================================ORDER_PARAMETER
  [./eta_dot]
    type = TimeDerivative
    variable = eta
  [../]
  [./eta_interface]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  [../]
  [./eta_bulk]
    type = AllenCahn
    variable = eta
    f_name = f_sum
    mob_name = L
  [../]
  [./eta_chem]
    type = ACSwitching
    variable = eta
    Fj_names = 'omegaa omegab'
    hj_names = 'ha hb'
    args = 'mu'
    mob_name = L
  [../]
  #===========================================================CHEMICAL_POTENTIAL
  [./mu_dot]
    type = SusceptibilityTimeDerivative
    f_name = chi
    variable = mu
    args = eta
  [../]
  [./mu_diff]
    type = MatDiffusion
    variable = mu
    args = eta
    diffusivity = M_comp
  [../]
  [./source_contribution]
    type = CoupledSwitchingTimeDerivative
    variable = mu
    v = eta
    Fj_names = 'ca cb'
    hj_names = 'ha hb'
    args = eta
  [../]
  [./TensorMechanics]
    displacements = 'disp_x disp_y'
  [../]
[]

[Materials]
  #====================================================================CONSTANTS
  [./const_int]
    type = GenericConstantMaterial
    prop_names = '   L     gab  kappa  mu   Ma     Mb        T        R'
    prop_values = '10.9883 1.5  0.2400   3.0000 0.0387e-3 0.0817 873.15  8.31432'
    #prop_names = '   L     gab  kappa  mu    T        R'
    #prop_values = '15.055 1.5  0.24   3  873.15  8.31432'
  [../]
  [./const_therm]
    type = GenericConstantMaterial
    prop_names = 'Aa Ba Ca
                  Ab Bb Cb'
    prop_values = '1.713494024709498831e+02 -3.422385108415397781e+02 1.656187345072146684e+02
                   3.441584012822243608e+02 -1.533588297297403091e+00 -4.705899157044988179e+00'
    #prop_values = '1 -2 1
    #               1 0 0'
  [../]
  [./const_magn]
    type = GenericConstantMaterial
    prop_names = 'am bm cm'
    prop_values = '0.7763 4.492 0.3501'
  [../]
  #==========================================================SWITCHING_FUCNTIONS
  [./ha]
    type = DerivativeParsedMaterial
    f_name = ha
    #function = '3*eta*eta - 2*eta*eta*eta'
    function = 'eta*eta/(eta*eta+(1-eta)*(1-eta))'
    args = eta
  [../]
  [./hb]
    type = DerivativeParsedMaterial
    f_name = hb
    material_property_names = ha(eta)
    function = '1 - ha'
    args = eta
  [../]
  [./etab]
    type = DerivativeParsedMaterial
    f_name = etab
    function = '1 - eta'
    args = eta
  [../]
  #=========================================================THERMODYNAMIC_VALUES
  [./omegaa]
    type = DerivativeParsedMaterial
    f_name = omegaa
    args = mu
    material_property_names = 'Aa Ba Ca'
    function = 'Ca - 0.25*(mu-Ba)*(mu-Ba)/Aa'
    outputs = exodus
  [../]
  [./omegab]
    type = DerivativeParsedMaterial
    f_name = omegab
    args = mu
    material_property_names = 'Ab Bb Cb'
    function = 'Cb - 0.25*(mu-Bb)*(mu-Bb)/Ab'
    outputs = exodus
  [../]
  [./ca]
    type = DerivativeParsedMaterial
    f_name = ca
    args = mu
    material_property_names = 'Aa Ba'
    function = '0.5*(mu-Ba)/Aa'
    outputs = exodus
  [../]
  [./cb]
    type = DerivativeParsedMaterial
    f_name = cb
    args = mu
    material_property_names = 'Ab Bb'
    function = '0.5*(mu-Bb)/Ab'
    outputs = exodus
  [../]
  [./c]
    type = DerivativeParsedMaterial
    f_name = c
    args = 'eta mu'
    material_property_names = 'ca(mu) cb(mu) ha(eta) hb(eta)'
    function = 'ca*ha+cb*hb'
    outputs = exodus
  [../]
  [./chi]
    type = DerivativeParsedMaterial
    f_name = chi
    args = 'eta'
    material_property_names = 'Aa Ab ha(eta) hb(eta)'
    function = '0.5*(ha/Aa + hb/Ab)'
  [../]
  [./dzeta]
    type = DerivativeParsedMaterial
    fname = dzeta
    args = 'mu'
    material_property_names = 'am bm cm cb(mu)'
    function = '0.5*am*(tanh(bm*(cm-cb))+1)'
  [../]
  #=================================================BULK_CONTRIBUTION_INT_ENERGY
  [./f_bulk]
    type = DerivativeParsedMaterial
    f_name = f_bulk
    args = 'eta'
    material_property_names = 'mu gab etab(eta)'
    function = 'mu*((eta*eta*eta*eta/4-eta*eta/2)+(etab*etab*etab*etab/4
    -etab*etab/2)+(gab*etab*etab*eta*eta))'
  [../]
  #============================================================KINETIC_FUNCTIONS
  [./M_comp]
    type = DerivativeParsedMaterial
    f_name = M_comp
    args = 'eta mu'
    material_property_names = 'ha(eta) hb(eta) Ma(mu) Mb(mu)'
    function = 'Ma*ha + Mb*hb'
    outputs = exodus
  [../]
  #===================================================================ELASTICITY
  [./elasticity_tensor_matrix]
    type = ComputeElasticityTensor
    C_ijkl = '145.8518 110.6975 110.6975 145.8518 110.6975 145.8518 104.6428 104.6428 104.6428'
    fill_method = symmetric9
    base_name = stiffness_matrix
  [../]
  [./elasticity_tensor_precipitate]
    type = ComputeElasticityTensor
    C_ijkl = '151.3125 107.1896 108.7447 -1.9095 -5.7284 -13.0552 189.5016 70.5556 5.7284 1.9095 6.0394 187.9465 -3.8189 3.8189 7.0158 19.53 7.0158 1.9095 57.7191 -1.9095 56.1640'
    fill_method = symmetric21
    base_name = stiffness_precipitate
  [../]
  [./effective_elastic_tensor]
    type = CompositeElasticityTensor
    args = 'eta'
    tensors = 'stiffness_precipitate stiffness_matrix'
    weights = 'ha                    hb'
  [../]
  [./eigenstrain]
    type = ComputeVariableEigenstrain
    eigen_base = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
    prefactor = ha
    args = 'eta'
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
    args = 'eta'
    derivative_order = 3
  [../]
# sum of the local contribution of the interfacial energy and elastic free energy for AC Kernel
  [./sum_free_energy]
    type = DerivativeSumMaterial
    f_name = f_sum
    args = 'eta'
    sum_materials = 'f_elast f_bulk'
  [../]
[]

[Postprocessors]
  [./precip_vol]
    type = ElementIntegralVariablePostprocessor
    variable = eta
  [../]
  [./vol_change]
    type = ChangeOverTimePostprocessor
    postprocessor = precip_vol
  [../]
[]

[Preconditioning]
  [./coupling]
    type = SMP
    #full = false
    full = true
    trust_my_coupling = true
    #off_diag_column = 'disp_x disp_y'
    #off_diag_row = 'disp_x disp_y'
  [../]
[]

[UserObjects]
  [./calculation_termination]
    type = Terminator
    expression = 'precip_vol >= 31400'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = implicit-euler
  end_time = 1e8
  l_max_its = 40#30
  nl_max_its = 30#50
  nl_rel_tol = 1e-7 #1e-8
  nl_abs_tol = 1e-8 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  #petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  #petsc_options_value = 'hypre boomeramg gmres 31 0.7'
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
  #dt = 1e-4
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 5
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-4
    cutback_factor = 0.5
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    interval = 10
  [../]
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

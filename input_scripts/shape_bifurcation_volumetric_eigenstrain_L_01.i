[Mesh]
  type = FileMesh
  dim = 2
  file = single_precipitate_volumetric_strain_r_20.msh
[]

[Adaptivity]
	max_h_level = 3
	marker = marker
	initial_marker = box_marker
	initial_steps = 3
	[./Markers]
		[./box_marker]
			type = BoxMarker
			bottom_left = '0 0 0'
			top_right = '25 25 0'
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

[BCs]
  [./left_bottom_corner_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 1
  [../]
  [./left_bottom_corner_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 1
  [../]
  [./right_bottom_corner_y]
    type = DirichletBC
    variable = disp_y
    value = 0
    boundary = 2
  [../]
  [./left_top_corner_x]
    type = DirichletBC
    variable = disp_x
    value = 0
    boundary = 4
  [../]
[]

[Variables]
  [./etaa]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = SmoothCircleIC
      invalue = 1.0
      outvalue = 0.0
      radius = 20
      int_width = 1.0
      x1 = 0.0
      y1 = 0.0
    [../]
  [../]
  [./etab]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = SmoothCircleIC
      invalue = 0.0
      outvalue = 1.0
      radius = 20
      int_width = 1.0
      x1 = 0.0
      y1 = 0.0
    [../]
  [../]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
[]

[Materials]
    # ===================================================================Constants
    [./const]
      type = GenericConstantMaterial
      prop_names =  'L   gab  kappa  mu   misfit'
      prop_values = '1   1.5  37.5   300  0.00'
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
    # ==============================================================Elastic Energy
    # =====================================================================Stiffness
    [./Stiffness]
      type = ComputeElasticityTensor
      C_ijkl = '250 170 170 250 170 250 100 100 100'
      fill_method = symmetric9
    [../]
    #====================================================================Eigenstrain
    [./eigenstrain]
      type = ComputeVariableEigenstrain
      eigen_base = '0.0 0.0 0 0 0 0'
      prefactor = 'ha'
      eigenstrain_name = 'eigenstrain'
      args = 'etaa etab'
    [../]
    # ===========================================================Interpolation KHS
    [./stress]
      type = ComputeLinearElasticStress
    [../]
    [./strain]
      type = ComputeSmallStrain
      displacements = 'disp_x disp_y'
      eigenstrain_names = 'eigenstrain'
    [../]
    # ========================================================Total elastic energy
    [./elastic_free_energy_p]
      type = ElasticEnergyMaterial
      f_name = f_el_mat
      args = 'etaa etab'
    [../]
    # ===========================================================Total Free Energy
     [./f_bulk]
       type = DerivativeParsedMaterial
       f_name = f_bulk
       args = 'etaa etab'
       material_property_names = 'mu gab'
       function = 'mu*((etaa*etaa*etaa*etaa/4-etaa*etaa/2)+(etab*etab*etab*etab/4-etab*etab/2)+(gab*etab*etab*etaa*etaa)+1/4)'
     [../]
     [./f_grad]
       type = DerivativeParsedMaterial
       f_name = f_grad
       args = 'etaa etab f_dens'
       material_property_names = 'floc(etaa,etab)'
       function = 'f_dens-floc'
     [../]
     [./f_dens_tot]
       type = DerivativeParsedMaterial
       f_name = f_dens_tot
       args = 'etaa etab f_dens'
       material_property_names = 'f_el_mat(etaa,etab,disp_x,disp_y) f_bulk(etaa,etab)'
       function = 'f_el_mat+f_dens+f_bulk'
       outputs = exodus
     [../]
     #==========================================================================
     #====================================Volume conservation related parameters
     # interpolation functions
     [./h_cons_a]
       type = DerivativeParsedMaterial
       args = etaa
       f_name = ha_c
       function = etaa
     [../]
     [./h_cons_b]
       type = DerivativeParsedMaterial
       args = etab
       f_name = hb_c
       function = etab
     [../]
     #===============================================Lagrange constant functions
     [./psi]
       type = DerivativeParsedMaterial
       f_name = psi
       args = 'etaa etab'
       material_property_names = 'dha_a:=D[ha_c(etaa,etab),etaa]
                                  dha_b:=D[ha_c(etaa,etab),etab]'
       function = 'dha_a*dha_a + dha_b*dha_b'
     [../]
     [./chi]
       type = DerivativeParsedMaterial
       f_name = chi
       args = 'etaa etab disp_x disp_y'
       material_property_names = 'dha_a:=D[ha_c(etaa,etab),etaa]
                                  dha_b:=D[ha_c(etaa,etab),etab]
                                  mu_loc_a:=D[f_bulk(etaa,etab),etaa]
                                  mu_loc_b:=D[f_bulk(etaa,etab),etab]
                                  mu_el_a:=D[f_el_mat(etaa,etab,disp_x,disp_y),etaa]
                                  mu_el_b:=D[f_el_mat(etaa,etab,disp_x,disp_y),etab]'
      function = 'dha_a*(mu_loc_a+mu_el_a) + dha_b*(mu_loc_b+mu_el_b)'
      #function = 'dha_a*mu_loc_a + dha_b*mu_loc_b'
      #function = 'dha_a*(mu_loc_a-mu_el_a) + dha_b*(mu_loc_b-mu_el_b)'
      #function = 0.0
     [../]
     [./Lagrange_multiplier]
       type = DerivativeParsedMaterial
       postprocessor_names = 'psi_int chi_int'
       function = 'if(abs(psi_int > 1e-8),chi_int / psi_int,0.0)'
       f_name = L_mult
     [../]
     [./stabilization_term_a]
       type = DerivativeParsedMaterial
       material_property_names = 'L_mult L dha_a:=D[ha_c(etaa,etab),etaa]'
       function = '-L*L_mult*dha_a'
       f_name = stab_func_a
     [../]
     [./stabilization_term_b]
       type = DerivativeParsedMaterial
       material_property_names = 'L_mult L dha_b:=D[ha_c(etaa,etab),etab]'
       function = '-L*L_mult*dha_b'
       f_name = stab_func_b
     [../]
[]

[Kernels]
  # ===================================================================Mechanics
  [./TensorMechanics]
    displacements = 'disp_x disp_y'
  [../]
  # =========================================================STRUCTURE_EVOLUTION
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
  [./etaa_elasticity]
    type = AllenCahn
    variable = etaa
    args = 'etab'
    f_name = f_el_mat
    mob_name = L
  [../]
  [./volume_conserver_a]
    type = MaterialValueKernel
    variable = etaa
    Mat_name = stab_func_a
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
  [./etab_elasticity]
    type = AllenCahn
    variable = etab
    args = 'etaa'
    f_name = f_el_mat
    mob_name = L
  [../]
  [./volume_conserver_b]
    type = MaterialValueKernel
    variable = etab
    Mat_name = stab_func_b
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
  [./psi_auxvar]
    order = CONSTANT
    family = MONOMIAL
  [../]
  [./chi_auxvar]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./f_dens]
    variable = f_dens
    type = TotalFreeEnergy
    f_name = floc
    interfacial_vars = 'etaa etab'
    kappa_names = 'kappa kappa'
  [../]
  [./ha_auxkernel]
    type = MaterialRealAux
    property = ha_c
    variable = ha_auxvar
  [../]
  [./psi_auxkernel]
    type = MaterialRealAux
    property = psi
    variable = psi_auxvar
  [../]
  [./chi_auxkernel]
    type = MaterialRealAux
    property = chi
    variable = chi_auxvar
  [../]
[]

[Postprocessors]
  [./total_f_grad]
    type = ElementIntegralMaterialProperty
    mat_prop = f_grad
  [../]
  [./total_f_bulk]
    type = ElementIntegralMaterialProperty
    mat_prop = f_bulk
  [../]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_dens_tot
  [../]
  [./etaa_vol]
    type = ElementIntegralVariablePostprocessor
    variable = etaa
  [../]
  [./memory]
    type = MemoryUsage
  [../]
  [./delta_f]
    type = ChangeOverTimestepPostprocessor
    postprocessor = total_f
  [../]
  [./n_dofs]
    type = NumDOFs
  [../]
  # post-processors for Lagrange Multiplier calculation
  [./psi_int]
    type = ElementIntegralVariablePostprocessor
    variable = psi_auxvar
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  [../]
  [./chi_int]
    type = ElementIntegralVariablePostprocessor
    variable = chi_auxvar
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
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
  l_max_its = 50#30
  nl_max_its = 15#50
  nl_rel_tol = 1e-5 #1e-8
  nl_abs_tol = 1e-6 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-5 # or 1e-4
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  petsc_options_value = 'hypre    boomeramg      31                 0.7'
  # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
  # maximum of 5% increase per time step
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 5
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-3
    cutback_factor = 0.75
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    interval = 10
  [../]
  csv = true
  perf_graph = true
  checkpoint = true
[]

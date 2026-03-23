# The script for getting all the parameters and boundary conditions to work
# Size of computational domain
domain_size = 1060

# xmin and xmax
x_min = '${fparse -0.5*domain_size}'
x_max = '${fparse 0.5*domain_size}'

# mean radius of particles
r_mean = 8 

# normalized diffusional width
delta_norm = 0.1

# interfacial energy
int_energy = 0.4

# Real diffusional width
int_width = '${fparse delta_norm*r_mean}'

# Number of elements per diffusional width
n_el_delta = 5

# Level of adaptivity
adaptivity_level = 5

# number of elements with zero adaptivity
n_el_0 = '${fparse n_el_delta * domain_size / int_width}'

# number of elements with adaptive mesh
n_el = '${fparse ceil(n_el_0 * 0.5^adaptivity_level)}'

# calculation of the phase-field parameters
kappa = '${fparse 1.5*int_energy*int_width/atanh(0.98)}'
omega = '${fparse 12.0*atanh(0.98)*int_energy/int_width}'

[GlobalParams]
  use_displaced = false
  displacements = 'disp_x disp_y'
  eigenstrain_names = eigenstrain
  use_displaced_mesh = false
[]

[Mesh]
  [gmg]
    type = GeneratedMeshGenerator
    dim = 2
    nx = ${n_el}
    ny = ${n_el}
    nz = 0
    xmin = ${x_min}
    xmax = ${x_max}
    ymin = ${x_min}
    ymax = ${x_max}
    elem_type = QUAD4
  []
  [./cnode]
    input = gmg
    type = ExtraNodesetGenerator
    coord = '${x_min} ${x_min}'
    new_boundary = 100
  [../]
[]

[Adaptivity]
  max_h_level = ${adaptivity_level}
  marker = marker
  initial_marker = marker
  initial_steps = ${adaptivity_level}
  [Markers]
    [marker]
        type = ValueRangeMarker
        lower_bound = 0.01
        upper_bound = 0.99
        variable = eta
        third_state = DO_NOTHING
    []
  []
[]

[Variables]
  [eta]
    family = LAGRANGE
    order = FIRST
    [InitialCondition]
      type = SmoothCircleFromFileIC
      file_name = 'particle_configuration.csv'
      invalue = 1.0
      outvalue = 0.0
      variable = eta
      int_width = ${int_width}
      profile = tanh
    []
  []
  [disp_x]
    family = LAGRANGE
    order = FIRST
  []
  [disp_y]
    family = LAGRANGE
    order = FIRST
  []
[]

[BCs]
  [disp_y]
    type = DirichletBC
    variable = disp_y
    value = 0.0
    boundary = bottom
  []
  [disp_x]
    type = DirichletBC
    variable = disp_x
    value = 0.0
    boundary = left
  []

  [Periodic]
    [au]
      variable = 'eta disp_x disp_y'
      auto_direction = 'x y'
    []
  []
[]

[Kernels]
  [eta_dot]
    type = TimeDerivative
    variable = eta
  []
  [gradient_term]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  []
  [local_term]
    type = AllenCahn
    variable = eta
    f_name = f_total
    mob_name = L
  []
  [volum_consev]
    type = VolumeConservationKernel
    variable = eta
    mob_name = L
    lagrange_mult = L_mult
    weight_func = psi
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [all]
        strain = SMALL
        add_variables = false
        new_system = true
        formulation = TOTAL
        volumetric_locking_correction = false
        constraint_types = 'stress none none stress stress none none none none' # small
        targets = 'zero zero zero' # small
      []
    []
  []
[]

[Functions]
  [zero]
    type = ConstantFunction
    value = 0.0
  []
[]

[Materials]
  # phase-field description 
  [const]
    type = GenericConstantMaterial
    prop_names = 'L kappa omega'
    prop_values = '1.0 ${kappa} ${omega}'
  []
  [f_local]
    type = DerivativeParsedMaterial
    property_name = f_local
    coupled_variables = eta
    material_property_names = 'omega'
    expression = 'omega*eta*eta*(1-eta)*(1-eta)'
    derivative_order = 3
  []

    # weighting function
  [ha]
    type = SwitchingFunctionMaterial
    eta = eta
    function_name = ha
  []
  [hb]
    type = DerivativeParsedMaterial
    property_name = hb
    material_property_names = 'ha(eta)'
    expression = '1-ha'
    coupled_variables = eta
  []

    # Elasticity-related materials
  [elasticity_tensor_matrix]
    type = ComputeElasticityTensor
    C_ijkl = '145.8518 110.6975 110.6975 145.8518 110.6975 145.8518 104.6428 104.6428 104.6428'
    fill_method = symmetric9
    base_name = stiffness_matrix
  []
  [elasticity_tensor_precipitate]
    type = ComputeElasticityTensor
    C_ijkl = '151.3125 107.1896 108.7447 -1.9095 -5.7284 -13.0552 189.5016 70.5556 5.7284 1.9095 6.0394 187.9465 -3.8189 3.8189 7.0158 19.53 7.0158 1.9095 57.7191 -1.9095 56.1640'
    fill_method = symmetric21
    base_name = stiffness_precipitate
  []
  [composite_elasticity]
    type = CompositeElasticityTensor
    coupled_variables = eta
    tensors = 'stiffness_precipitate stiffness_matrix'
    weights = 'ha hb'
  []

    # strain and stress definition
  [eigenstrain]
    type = ComputeVariableEigenstrain
    eigen_base = '0.2417 -0.1213 -0.1107 0.0053 0.0183 -0.029'
    prefactor = ha
    args = 'eta'
    eigenstrain_name = eigenstrain
  []
  [stress]
    type = ComputeLinearElasticStress
  []
  [stress_wrapper]
    type = ComputeLagrangianWrappedStress
  []
  [elastic_free_energy]
    type = ElasticEnergyMaterial
    property_name = f_elast
    coupled_variables = eta
  []

    # total free energy
  [total_free_energy]
    type = DerivativeSumMaterial
    property_name = f_total
    coupled_variables = eta
    sum_materials = 'f_local f_elast'
  []
    #===============Functions fo Lagrange multiplier
  [psi]
    type = DerivativeParsedMaterial
    property_name = psi
    coupled_variables = eta
    material_property_names = 'dh:=D[ha(eta),eta]'
    expression = 'dh'
  []
  [chi]
    type = DerivativeParsedMaterial
    property_name = chi
    coupled_variables = eta
    material_property_names = 'chi:=D[f_total(eta),eta]'
    expression = 'chi'
  []
  [Lagrange_multiplier]
    type = DerivativeParsedMaterial
    property_name = L_mult
    postprocessor_names = 'psi_int chi_int'
    expression = 'if(abs(psi_int) > 1.0e-8, chi_int / psi_int, 0.0)'
  []
[]

[AuxVariables]
  [f_int]
    order = CONSTANT
    family = MONOMIAL
  []
  [f_elast]
    order = CONSTANT
    family = MONOMIAL
  []
  [f_total]
    order = CONSTANT
    family = MONOMIAL
  []
  [chi_auxvar]
    order = CONSTANT
    family = MONOMIAL
  []
  [psi_auxvar]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [f_int]
    type = TotalFreeEnergy
    variable = f_int
    f_name = f_local
    interfacial_vars = eta
    kappa_names = kappa
  []
  [f_elastic]
    type = MaterialRealAux
    variable = f_elast
    property = f_elast
  []
  [f_total]
    type = TotalFreeEnergy
    variable = f_total
    f_name = f_total
    interfacial_vars = eta
    kappa_names = kappa
  []
  [psi_auxkernel]
    type = MaterialRealAux
    property = psi
    variable = psi_auxvar
  []
  [chi_auxkernel]
    type = MaterialRealAux
    property = chi
    variable = chi_auxvar
  []
[]

[Postprocessors]
  [total_energy]
    type = ElementIntegralVariablePostprocessor
    variable = f_total
  []
  [elastic_energy]
    type = ElementIntegralVariablePostprocessor
    variable = f_elast
  []
  [interfacial_energy]
    type = ElementIntegralVariablePostprocessor
    variable = f_int
  []
  [energy_increment]
    type = ChangeOverTimePostprocessor
    postprocessor = total_energy
  []
    [eta_vol]
    type = ElementIntegralVariablePostprocessor
    variable = eta
  []
  [psi_int]
    type = ElementIntegralVariablePostprocessor
    variable = psi_auxvar
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  []
  [chi_int]
    type = ElementIntegralVariablePostprocessor
    variable = chi_auxvar
    execute_on = 'INITIAL LINEAR NONLINEAR TIMESTEP_BEGIN TIMESTEP_END'
  []
  [particle_number]
    type = FeatureFloodCount
    variable = eta
    use_less_than_threshold_comparison = true
  []
[]

#[Preconditioning]
#  [SMP]
#    type = SMP
#    full = true
#  []
#[]


[UserObjects]
  [./calculation_termination]
    type = Terminator
    expression = 'particle_number < 11'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  line_search = basic
  scheme = bdf2
  end_time = 1e8
  l_max_its = 30#30
  nl_max_its = 50#50
  nl_rel_tol = 1e-7 #1e-8
  nl_abs_tol = 1e-8 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  #petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  #petsc_options_value = 'lu mumps'
  petsc_options_iname = '-ksp_type -ksp_gmres_restart -pc_type'
  petsc_options_value  = 'fgmres    50                 hypre'
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 5
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.1
    dt=1e-1
    cutback_factor = 0.5
  [../]
[]

[Outputs]
  [./exodus]
    type = Exodus
    time_step_interval = 5
    file_base = simulation_output
  [../]
  [./csv]
    type = CSV
    file_base = simulation_output
  [../]
  checkpoint = true
[]
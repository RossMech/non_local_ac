# Normalized energy parameter
L = 1

#==================Interfacial parameters
# Interfacial energy
int_energy = 1.0
# Interfacial width ratio
width_ratio = 0.1
#==================

#==================Elastic parameters
# Heterogeinity
heterogeinity = 0.5
# Eigenstrain magnitude
eigenstrain_mag = 0.01
# Shear modulus of the matrix
mu_matr = 1000.0
# Shear modulus of the precipitate
mu_precip = $'{fparse mu_matr*heterogeinity}'
# Poisson ratio for both both phases
nu = 0.3
#==================

#==================Numerical parameters
# Number of elements per diffusional width
num_el = 10
# Level of mesh adaptivity
adaptivity_level = 5
#==================

#==================Geometrical parameters
# Radius of inclusion
radius = $'{fparse L*int_energy/(mu_matr*eigenstrain_mag^2)}'
# Size of the simulation domain
domain_size = $'{fparse 20*radius}'
# Interfacial width
int_width = $'{fparse width_ratio*radius}'
#==================

#==================Phase field parameters
# Gradient prefactor
kappa = $'{fparse 1.5*int_energy*int_width/atanh(0.98)}'
omega = $'{fparse 12.0*atanh(0.98)*int_energy/int_width}'
#==================



# Calculation of mesh density based on the adaptivity levels
n_y = '${fparse ceil(domain_size*num_el/(int_width*2^adaptivity_level)) }'
n_x = '${fparse 2*n_y}' 

[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = -${domain_size}
  xmax = ${domain_size}
  ymin = 0.0
  ymax = ${domain_size}
  nx = ${n_x}
  ny = ${n_y}
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
    
[GlobalParams]
    displacements = 'disp_x disp_y'
    eigenstrain_names = eigenstrain
[]
    
[Variables]
  # order variable
  [eta]
    family = LAGRANGE
    order = FIRST
    [InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = ${radius}
      invalue = 1.0
      outvalue = 0.0
      int_width = ${int_width}
    []
  []
[]
    
[BCs]
  [disp_y]
      type = DirichletBC
      variable = disp_y
      value = 0.0
      boundary = 0 # bottoms
  []
  [disp_x_left]
      type = DirichletBC
      variable = disp_x
      value = 0.0
      boundary = 3 # left
  []
  [disp_x_right]
      type = DirichletBC
      variable = disp_x
      value = 0.0
      boundary = 1 # right
  []
[]
   
[Kernels]
  # Time derivative
  [eta_dot]
    type = TimeDerivative
    variable = eta
  []
  # Gradient term
  [eta_interface]
    type = ACInterface
    variable = eta
    mob_name = L
    kappa_name = kappa
  []
  # Bulk part of Allen-Cahn energy
  [eta_bulk]
    type = AllenCahn
    variable = eta
    f_name = f_total
    mob_name = L
    args = ''
  []
  # Conservation of the volume
  [volum_conserv]
    type = VolumeConservationKernel
    variable = eta
    mob_name = L
    lagrange_mult = L_mult
    weight_func = psi
  []
[]
    
# Solid Mechanics action
[Physics/SolidMechanics/QuasiStatic]
    [all]
      add_variables = true
      strain = SMALL
    []
[]
    
[Materials]
  # Phase-field constants
  [const]
    type = GenericConstantMaterial
    prop_names = 'L kappa omega'
    prop_values = '1.0 1.958599621669584 9.190239700269178'
  []

  # weighting functions
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
  #=========================================Elasticity description
  # elastic constants
  [elasticity_alpha]
      type = ComputeIsotropicElasticityTensor
      shear_modulus = 500.0 
      poissons_ratio = 0.3333
      base_name = 'alpha_phase'
  []
  [elasticity_beta]
      type = ComputeIsotropicElasticityTensor
      shear_modulus = 1000.0
      poissons_ratio = 0.3333
      base_name = 'beta_phase'
  []
  [composite_elasticity]
      type = CompositeElasticityTensor
      coupled_variables = eta
      tensors = 'alpha_phase beta_phase'
      weights = 'ha hb'
  []
  # strains
  [eigenstrain]
      type = ComputeVariableEigenstrain
      eigen_base = '0.01 0.01 0.0 0.0 0.0 0.0'
      prefactor = ha
      args = eta
      eigenstrain_name = eigenstrain
  []

  [stress]
      type = ComputeLinearElasticStress
  []
  [elastic_free_energy]
      type = ElasticEnergyMaterial
      property_name = f_elast
      coupled_variables = eta
  []

  #==========================================Bulk free energy
  [f_bulk]
    type = DerivativeParsedMaterial
    property_name = f_bulk
    coupled_variables = eta
    material_property_names = 'omega'
    expression = 'omega*eta*eta*(1-eta)*(1-eta)'
  []
  #==========================================Total free energy
  [total_free_energy]
    type = DerivativeSumMaterial
    property_name = f_total
    coupled_variables = eta
    sum_materials = 'f_bulk f_elast'
  []
  #=========================================Functions for Lagrange multiplier
  [psi]
    type = DerivativeParsedMaterial
    property_name = psi
    coupled_variables = eta
    material_property_names = 'dha_a:=D[ha(eta),eta]'
    expression = 'dha_a'
  []
  [chi]
    type = DerivativeParsedMaterial
    property_name = chi
    coupled_variables = eta
    material_property_names = 'mu_a:=D[f_total(eta),eta]'
    expression = 'mu_a'
  []
  [Langrange_multiplier]
    type = DerivativeParsedMaterial
    property_name = L_mult
    postprocessor_names = 'psi_int chi_int'
    expression = 'if(abs(psi_int) > 1.0e-8, chi_int / psi_int, 0.0)'
  []
[]
    
[AuxVariables]
  [f_elast]
    order = CONSTANT
    family = MONOMIAL
  []
  [f_interf]
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
  [f_elast]
    type = MaterialRealAux
    property = f_elast
    variable = f_elast
  []
  [f_interf]
    type = TotalFreeEnergy
    variable = f_interf
    f_name = f_bulk
    interfacial_vars = eta
    kappa_names = kappa
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
  [f_elast]
    type = ElementIntegralVariablePostprocessor
    variable = f_elast
  []
  [f_interf]
    type = ElementIntegralVariablePostprocessor
    variable = f_interf
  []
  [f_total]
    type = ElementIntegralVariablePostprocessor
    variable = f_total
  []
  [delta_f]
    type = ChangeOverTimestepPostprocessor
    postprocessor = f_total
  []
  [eta_vol]
    type = ElementIntegralVariablePostprocessor
    variable = eta
  []
  [memory]
    type = MemoryUsage
  []

  # the integrals for Lagrange multiplier
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
[]

# Termination of simulation when the free energy does not change
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
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart -pc_hypre_boomeramg_strong_threshold'
  petsc_options_value = 'hypre    boomeramg      31                 0.7'
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
    additional_execute_on = 'FINAL' 
  [../]
  [./csv]
    type = CSV
  [../]
  perf_graph = true
  checkpoint = true
[]

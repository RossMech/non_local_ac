[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = -200.0
  xmax = 200.0
  ymin = 0.0
  ymax = 200.0
  nx = 2000
  ny = 1000
[]

[Adaptivity]
  max_h_level = 2
  marker = marker
  initial_marker = marker
  initial_steps = 2
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
      radius = 10.0
      invalue = 1.0
      outvalue = 0.0
      int_width = 1.0
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
  # dummy kernel for phase-field variable
  [eta_dot]
    type = TimeDerivative
    variable = eta
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
    # weighting functions
    [ha]
        type = DerivativeParsedMaterial
        property_name = ha
        coupled_variables = eta
        expression = 'eta*eta/(eta*eta+(1-eta)*(1-eta))'
    []
    [hb]
        type = DerivativeParsedMaterial
        property_name = hb
        material_property_names = 'ha(eta)'
        expression = '1-ha'
        coupled_variables = eta
    []
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
[]
    
[AuxVariables]
    [f_dens]
        order = CONSTANT
        family = MONOMIAL
    []
[]
  
[AuxKernels]
  [f_dens]
    type = MaterialRealAux
    property = f_elast
    variable = f_dens
  []
[]
    
[Postprocessors]
  [total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_dens
  []
[]
    
[Executioner]
  type = Transient
  solve_type = PJFNK
  end_time = 1.0
  dt = 1.0
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]
    
[Outputs]
  exodus = true
  csv = true
  perf_graph = true
[]

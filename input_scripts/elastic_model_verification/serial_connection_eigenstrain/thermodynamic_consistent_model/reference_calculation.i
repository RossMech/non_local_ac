[Mesh]
  type = GeneratedMesh
  dim = 3
  xmin = -0.5
  xmax = 0.5
  ymin = 0.0
  ymax = 1.0
  zmin = 0.0
  zmax = 1.0
  nx = 1000
  ny = 1
  nz = 1
[]

[Variables]
  [./disp_x]
  [../]
  [./disp_y]
  [../]
  [./disp_z]
  [../]
[]

[BCs]
  [./pinned_x_left]
    type = DirichletBC
    variable = disp_x
    boundary = left
    value = 0.0
  [../]
  [./pinned_y_left]
    type = DirichletBC
    variable = disp_y
    boundary = left
    value = 0.0
  [../]
  [./pinned_z_left]
    type = DirichletBC
    variable = disp_z
    boundary = left
    value = 0.0
  [../]
  [./pinned_x_right]
    type = DirichletBC
    variable = disp_x
    boundary = right
    value = 0.0
  [../]
  [./pinned_y_right]
    type = DirichletBC
    variable = disp_y
    boundary = right
    value = 0.0
  [../]
  [./pinned_z_right]
    type = DirichletBC
    variable = disp_z
    boundary = right
    value = 0.0
  [../]
[]

[Kernels]
  [./TensorMechanics]
    displacements = 'disp_x disp_y disp_z'
  [../]
[]

[Materials]
  [./elasticity_tensor_alpha]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 1.0
    poissons_ratio = 0.3
  [../]
  [./eigenstrain]
    type = ComputeEigenstrain
    eigenstrain_name = eigen
    eigen_base = '1e-2 0.0 0.0 0.0 0.0 0.0'
    outputs = exodus
  [../]
  [./strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
    outputs = exodus
    eigenstrain_names = eigen
  [../]
  [./stress]
    type = ComputeLinearElasticStress
    outputs = exodus
  [../]
  [./elastic_free_energy]
    type = ElasticEnergyMinimal
    f_name = f_el
    args = ''
  [../]
[]

[AuxVariables]
  [./f_elast_aux]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./elast_aux]
    type = MaterialRealAux
    property = f_el
    variable = f_elast_aux
  [../]
[]

[Postprocessors]
  [./total_f]
    type = ElementIntegralVariablePostprocessor
    variable = f_elast_aux
  [../]
[]

[Executioner]
  type = Steady
  solve_type = NEWTON
  nl_abs_tol = 1e-6
  nl_rel_tol = 1e-5
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
[]

[Outputs]
  exodus = true
  csv = true
[]

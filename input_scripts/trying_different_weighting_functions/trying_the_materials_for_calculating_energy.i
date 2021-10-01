[Mesh]
  type = GeneratedMesh
  dim = 1
  xmin = 0
  xmax = 1
  nx = 50
[../]

[Variables]
  [./c]
    family = LAGRANGE
    order = FIRST
    [./InitialCondition]
      type = FunctionIC
      function = x
    [../]
  [../]
[]

[Kernels]
  [./dcdt]
    type = TimeDerivative
    variable = c
  [../]
  [./Diffusion]
    type = Diffusion
    variable = c
  [../]
[]

[AuxVariables]
  [./flux]
    family = MONOMIAL
    order = FIRST
  [../]
  [./div_flux]
    family = MONOMIAL
    order = FIRST
  [../]
[]

[AuxKernels]
  [./flux_kernel]
    type = DiffusionFluxAux
    diffusivity = 1
    variable = flux
    diffusion_variable = c
    component = x
  [../]
  [./flux_divergence]
    type = INSDivergenceAux
    u = flux
    variable = div_flux
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = bdf2
  end_time = 10
  dt = 0.1
  l_max_its = 50#30
  nl_max_its = 15#50
  nl_rel_tol = 1e-5 #1e-8
  nl_abs_tol = 1e-6 #1e-11 -9 or 10 for equilibrium
[]

[Outputs]
  exodus = true
  csv = true
  perf_graph = true
  checkpoint = true
[]

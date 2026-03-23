# interfacial energy
int_energy = 0.4

# interfacial width
int_width = 0.2

# calculation of the phase-field parameters
kappa = '${fparse 1.5*int_energy*int_width/atanh(0.98)}'
omega = '${fparse 12.0*atanh(0.98)*int_energy/int_width}'

[Mesh]
    type = GeneratedMesh
    dim = 1
    nx = 800
    xmin = -1
    xmax = 1
[]

[Variables]
    [./eta]
    family = LAGRANGE
    order = FIRST
        [./InitialCondition]
            type = RampIC
            variable = eta
            value_left = 0.0
            value_right = 1.0
        [../]
    [../]
[]

[Kernels]
    [./time_derivative]
        type = TimeDerivative
        variable = eta
    [../]
    [./gradient_term]
        type = ACInterface
        variable = eta
        mob_name = L
        kappa_name = kappa
    [../]
    [./eta_bulk]
        type = AllenCahn
        f_name = f_local
        variable = eta
        mob_name = L
    [../]
[]

[Materials]
    # Constants
    [./const]
        type = GenericConstantMaterial
        prop_names = 'L kappa omega'
        prop_values = '1.0 ${kappa} ${omega}'
    [../]
    # Local Energy Function
    [./f_local]
        type = DerivativeParsedMaterial
        expression = 'omega*eta*eta*(1-eta)*(1-eta)'
        coupled_variables = 'eta'
        property_name = f_local
        material_property_names = 'omega'
        derivative_order = 4
    [../]
[]

[AuxVariables]
  [./f_dens]
    order = CONSTANT
    family = MONOMIAL
  [../]
[]

[AuxKernels]
  [./f_dens]
    type = TotalFreeEnergy
    variable = f_dens
    f_name = f_local
    interfacial_vars = eta
    kappa_names = kappa
  [../]
[]

[Postprocessors]
  [./total_energy]
    type = ElementIntegralVariablePostprocessor
    variable = f_dens
  [../]
  [./energy_increment]
    type = ChangeOverTimePostprocessor
    postprocessor = total_energy
  [../]  
[]

[Preconditioning]
  [./coupling]
    type = SMP
    full = true
  [../]
[]

[UserObjects]
  [./calculation_termination]
    type = Terminator
    expression = 'abs(energy_increment) < 1e-8'
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
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
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
    time_step_interval = 2
  [../]
  [./csv]
    type = CSV
  [../]
[]
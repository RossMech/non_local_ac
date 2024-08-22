[Mesh]
    type = GeneratedMesh
    dim = 2
    xmin = -300.0
    ymin = 0.0
    xmax = 300.0
    ymax = 300.0
    nx = 200
    ny = 100
[]

[Adaptivity]
    max_h_level = 4
    marker = marker
    initial_marker = marker
    initial_steps = 4
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
    derivative_order = 2
    use_displaced = false
[]

[Variables]
    # Order variable
    [eta]
        family = LAGRANGE
        order = FIRST
        [InitialCondition]
            type = SmoothCircleIC
            x1 = 0.0
            y1 = 0.0
            radius = 30.0
            invalue = 1.0
            outvalue = 0.0
            int_width = 1.5
        []
    []
    # Displacements
    [disp_x]
    []
    [disp_y]
    []
[]

[BCs]
    [disp_y]
        type = DirichletBC
        variable = disp_y
        boundary = 0 # bottom
        value = 0.0
    []
    [disp_x_left]
        type = DirichletBC
        variable = disp_x
        boundary = 3 # left
        value = 0.0
    []
    [disp_x_right]
        type = DirichletBC
        variable = disp_x
        boundary = 1 # right
        value = 0.0
    []
[]

[Kernels]
    # order parameter kernels
    [eta_dot]
        type = TimeDerivative
        variable = eta
    []
    [eta_interface]
        type = ACInterface
        variable = eta
        mob_name = M
        kappa_name = kappa
    []
    [eta_bulk]
       type = AllenCahn
        variable = eta
        f_name = f_total
        mob_name = M
        args = ''
    []
    [volum_conserv]
        type = VolumeConservationKernel
        variable = eta
        mob_name = M
        lagrange_mult = L_mult
        weight_func = wa_diff
    []
    # tensor mechanics kernel
    [TensorMechanics]
        displacements = 'disp_x disp_y'
    []
[]

[Materials]
    # Constants
    [const]
        type = GenericConstantMaterial
        prop_names =  'M    gab  kappa    mu    E_alpha E_beta nu'
        prop_values = '1.0  1.5  1.125   4.0    1300.0  2600.0 0.3'
    []
    # Switching and weighting functions
    [wa]
        type = DerivativeParsedMaterial
        args = eta
        f_name = wa
        function = '3*eta*eta-2*eta*eta*eta'
    []
    [wa_diff]
        type = DerivativeParsedMaterial
        args = eta
        f_name = wa_diff
        material_property_names = 'dwa:=D[wa(eta),eta]'
        function = 'dwa'
    []
    [ha]
        type = DerivativeParsedMaterial
        f_name = ha
        args = eta
        function = 'eta*eta/(eta*eta+(1-eta)*(1-eta))'
    []
    [hb]
        type = DerivativeParsedMaterial
        f_name = hb
        args = eta
        material_property_names = 'ha(eta)'
        function = '1-ha'
    []
    # Bulk contribution to free energy
    [f_bulk]
        type = DerivativeParsedMaterial
        f_name = f_bulk
        args = eta
        material_property_names = 'mu gab'
        function = 'mu*((eta*eta*eta*eta/4-eta*eta/2)+((1-eta)*(1-eta)*(1-eta)*(1-eta)/4
    -(1-eta)*(1-eta)/2)+(gab*(1-eta)*(1-eta)*eta*eta)+1/4)'
    []
    # Functions for calculation of Lagrange multiplier
    [psi]
        type = DerivativeParsedMaterial
        f_name = psi
        args = eta
        material_property_names = 'dwa_a:=D[wa(eta),eta]'
        function = 'dwa_a'
    []
    [chi]
        type = DerivativeParsedMaterial
        args = eta
        material_property_names = 'mu_a:=D[f_total(eta),eta]'
        function = 'mu_a'
        f_name = chi
    []
    [Langrange_multiplier]
        type = DerivativeParsedMaterial
        postprocessor_names = 'psi_int chi_int'
        function = 'if(abs(psi_int) > 1.0e-8, chi_int / psi_int, 0.0)'
        f_name = L_mult
    []
    [stabilization_term_a]
        type = DerivativeParsedMaterial
        args = eta
        material_property_names = 'L_mult M psi'
        function = '-M*L_mult*psi'
    []
    # Elasticity description
    # Young's modulus of the composite based on RS description
    [youngs_modulus]
        type = DerivativeParsedMaterial
        f_name = youngs_modulus
        args = eta
        material_property_names = 'E_alpha E_beta ha(eta) hb(eta)'
        function = 'E_alpha*E_beta/(ha*E_beta+hb*E_alpha)'
    []
    # Tensor with variable components
    [elastic_tensor]
        type = ComputeVariableIsotropicElasticityTensor
        args = eta
        youngs_modulus = youngs_modulus
        poissons_ratio = nu
    []
    [eigenstrain]
        type = ComputeVariableEigenstrain
        eigen_base = '0.01 0.01 0.01 0.0 0.0 0.0'
        prefactor = ha
        args = eta
        eigenstrain_name = eigenstrain
    []
    [strain]
        type = ComputeSmallStrain
        displacements = 'disp_x disp_y'
        eigenstrain_names = eigenstrain
    []
    [stress]
        type = ComputeLinearElasticStress
    []
    [elastic_free_energy]
        type = ElasticEnergyMaterial
        f_name = f_elast
        args = eta
    []
    # Total free energy as sum of different local contributions
    [total_free_energy]
        type = DerivativeSumMaterial
        f_name = f_total
        args = eta
        sum_materials = 'f_elast f_bulk'
    []
[]

[AuxVariables]
    [f_dens]
        order = CONSTANT
        family = MONOMIAL
    []
    [wa_auxvar]
        order = CONSTANT
        family = MONOMIAL
    []
    [psi_auxvar]
        order = CONSTANT
        family = MONOMIAL
    []
    [chi_auxvar]
        order = CONSTANT
        family = MONOMIAL
    []
[]

[AuxKernels]
    [f_dens]
        type = TotalFreeEnergy
        variable = f_dens
        f_name = f_total
        interfacial_vars = eta
        kappa_names = kappa
    []
    [wa_auxkernel]
        type = MaterialRealAux
        property = wa
        variable = wa_auxvar
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
    [total_f]
        type = ElementIntegralVariablePostprocessor
        variable = f_dens
    []
    [delta_f]
        type = ChangeOverTimestepPostprocessor
        postprocessor = total_f
    []
    [etaa_vol]
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

#preconditioning for the coupled variables.
[Preconditioning]
    [./coupling]
        type = SMP
        full = true
    [../]
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
    petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
    petsc_options_value = 'lu mumps'
    # Time Stepper: Using Iteration Adaptative here. 5 nl iterations (+-1), and l/nl iteration ratio of 100
    # maximum of 5% increase per time step
    [./TimeStepper]
      type = IterationAdaptiveDT
      optimal_iterations = 5
      linear_iteration_ratio = 100
      iteration_window = 0
      growth_factor = 1.5
      dt=1e-2
      cutback_factor = 0.5
    [../]
[]

[Outputs]
    [exodus]
        type = Exodus
        interval = 10
        additional_execute_on = FINAL
    []
    [csv]
        type = CSV
    []
    perf_graph = true
    checkpoint = true
[]
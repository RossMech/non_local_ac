[Mesh]
  type = GeneratedMesh
  dim = 1
  xmin = 0.0
  xmax = 10.0
  nx = 500
[]

[Variables]
  [./eta]
    [./InitialCondition]
      type = SmoothCircleIC
      x1 = 0.0
      y1 = 0.0
      radius = 1.0
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
      radius = 1.0
      invalue = -0.5653
      outvalue = 2.5
      int_width = 0.3
    [../]
  [../]
[]

[BCs]
  [./right_side_dirichlet]
    type = DirichletBC
    variable = mu
    boundary = right
    value = 2.5
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
    f_name = f_bulk
    mob_name = L
  [../]
  [./eta_chem]
    type = ACSwitching
    variable = eta
    Fj_names = 'omegaa omegab'
    hj_names = 'ha       hb'
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
[]

[Materials]
  #====================================================================CONSTANTS
  [./const_int]
    type = GenericConstantMaterial
    #prop_names = '   L     gab  kappa  mu   Ma     Mb        T        R    M_comp'
    #prop_values = '10.9883 1.5  0.06   12 0.0387e-3 0.0817 873.15  8.31432  0.01'
    prop_names = '   L     gab  kappa  mu   Ma     Mb        T        R'
    prop_values = '10.9883 1.5  0.2400   3 0.0387e-3 0.0817 873.15  8.31432'
    #prop_names = '   L     gab  kappa  mu    T        R'
    #prop_values = '15.055  1.5  0.12   6  873.15  8.31432'
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
    function = 'eta*eta*eta*(6*eta*eta-15*eta+10)'
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
    -etab*etab/2)+(gab*etab*etab*eta*eta)+1/4)'
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
  #====================================================================FCC_PHASE
  [./Qa_cu]
    type = DerivativeParsedMaterial
    f_name = Qa_cu
    material_property_names = 'ca(mu) T R'
    args = 'mu'
    function = 'ca*(-204670+R*T*log((6.0e-5)-(4.7E-8)*T+(2.5e-11)*(T^2))) +
       (1-ca)*(-286000+R*T*log(7.0e-5)) - ca*(1-ca)*(4930.84+24.75*T)'
  [../]
  [./Ma_cu]
    type = DerivativeParsedMaterial
    f_name = Ma_cu
    material_property_names = 'Qa_cu(mu) R T'
    args = 'mu'
    function = 'exp(Qa_cu/R/T)/R/T'
    outputs = exodus
  [../]
  [./Qa_fe]
    type = DerivativeParsedMaterial
    f_name = Qa_fe
    material_property_names = 'ca(mu) R T'
    args = 'mu'
    function = '(1-ca)*(-286000+R*T*log(7.0e-5))+ca*(-207421-81.91*T) +
                ca*(1-ca)*(-100000 + 125000*(1-2*ca)-50000*(1-2*ca)*(1-2*ca))'
  [../]
  [./Ma_fe]
    type = DerivativeParsedMaterial
    f_name = Ma_fe
    material_property_names = 'Qa_fe(mu) R T'
    args = 'mu'
    function = 'exp(Qa_fe/R/T)/R/T'
    outputs = exodus
  [../]
  #[./Ma]
  #  type = DerivativeParsedMaterial
  #  f_name = Ma
  #  material_property_names = 'Ma_fe(mu) Ma_cu(mu) ca(mu)'
  #  args = 'mu'
  #  function = 'max(ca*(1-ca)*(ca*Ma_fe+(1-ca)*Ma_cu)*2.0189e+18,1.0e-20)'
  #  outputs = exodus
  #[../]
  #====================================================================BCC_PHASE
  [./Qb_cu]
    type = DerivativeParsedMaterial
    f_name = Qb_cu
    material_property_names = 'cb(mu) R T'
    args = 'mu'
    function = 'cb*(-151800) + (1-cb)*(-218000) - cb*(1-cb)*191623.11'
  [../]
  [./Mfb_cu]
    type = DerivativeParsedMaterial
    f_name = Mfb_cu
    material_property_names = 'cb(mu) R T'
    args = 'mu'
    function = 'cb*(-79*T) + (1-cb)*(R*T*log(2.0*4.6e-5)) + cb*(1-cb)*1e-8'
  [../]
  [./Mmag_cu]
    type = DerivativeParsedMaterial
    f_name = Mmag_cu
    material_property_names = 'dzeta(mu) Qb_cu(mu) R T'
    args = 'mu'
    function = 'exp(0.3*dzeta*(6+Qb_cu/R/T))'
  [../]
  [./Mb_cu]
    type = DerivativeParsedMaterial
    f_name = Mb_cu
    material_property_names = 'Mmag_cu(mu) Qb_cu(mu) Mfb_cu(mu) R T'
    args = 'mu'
    function = 'exp((Mfb_cu+Qb_cu)/R/T)*Mmag_cu/R/T'
    outputs = exodus
  [../]

  [./Qb_fe]
    type = DerivativeParsedMaterial
    f_name = Qb_fe
    material_property_names = 'cb(mu) R T'
    args = 'mu'
    function = 'cb*(-151800)+(1-cb)*(-218000)'
  [../]
  [./Mfb_fe]
    type = DerivativeParsedMaterial
    f_name = Mfb_fe
    material_property_names = 'cb(mu) R T'
    args = 'mu'
    function = '(1-cb)*R*T*log(4.6E-5) - cb*79*T'
  [../]
  [./Mmag_fe]
    type = DerivativeParsedMaterial
    f_name = Mmag_fe
    material_property_names = 'dzeta(mu) Qb_fe(mu) R T'
    args = 'mu'
    function = 'exp(0.3*dzeta*(6+Qb_fe/R/T))'
  [../]
  [./Mb_fe]
    type = DerivativeParsedMaterial
    f_name = Mb_fe
    material_property_names = 'Mmag_fe(mu) Qb_fe(mu) Mfb_fe(mu) R T'
    args = 'mu'
    function = 'exp((Mfb_fe+Qb_fe)/R/T)*Mmag_fe/R/T'
    outputs = exodus
  [../]
  #[./Mb]
  #  type = DerivativeParsedMaterial
  #  f_name = Mb
  #  material_property_names = 'cb(mu) Mb_fe(mu) Mb_cu(mu)'
  #  args = 'mu'
  #  function = 'max(cb*(1-cb)*(cb*Mb_fe+(1-cb)*Mb_cu)*2.0189e+18,1.0e-20)'
  #  outputs = exodus
  #[../]
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
    full = true
  [../]
[]

[Executioner]
  type = Transient
  solve_type = PJFNK
  scheme = implicit-euler
  end_time = 1000000
  l_max_its = 20#30
  nl_max_its = 50#50
  nl_rel_tol = 1e-7 #1e-8
  nl_abs_tol = 1e-8 #1e-11 -9 or 10 for equilibrium
  l_tol = 1e-4 # or 1e-4
  petsc_options_iname = '-pc_type  -pc_factor_mat_solver_package'
  petsc_options_value = 'lu mumps'
  #dt = 1e-4
  [./TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 5
    linear_iteration_ratio = 100
    iteration_window = 1
    growth_factor = 1.5
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

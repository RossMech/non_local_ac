[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 30
  xmin = -100
  xmax = 100
  ny = 30
  ymin = -100
  ymax = 100
  nz = 30
  zmin = -100
  zmax = 100
[]

[Adaptivity]
	max_h_level = 1
	marker = marker
	initial_marker = marker
	initial_steps = 1
	[./Markers]
		[./marker1]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = eta1
			third_state = DO_NOTHING
		[../]
    [./marker2]
      type = ValueRangeMarker
      lower_bound = 0.01
      upper_bound = 0.99
      variable = eta1
      third_state = DO_NOTHING
    [../]
    [./marker]
      type = ComboMarker
      markers = 'marker1 marker2'
    [../]
	[../]
[]

[Problem]
  solve = false
[]

[Variables]
  [./eta1]
  [../]
  [./eta2]
  [../]
  [./eta3]
  [../]
[]

[ICs]
  [./eta1]
    type = TwinSphereIC
    variable = eta1
    outside = 1.0
    inside_above = 0.0
    inside_under = 0.0
    r = 80
    n = '1 1 1'
  [../]
  [./eta2]
    type = TwinSphereIC
    variable = eta2
    outside = 0.0
    inside_above = 1.0
    inside_under = 0.0
    r = 80
    n = '1 1 1'
  [../]
  [./eta3]
    type = TwinSphereIC
    variable = eta3
    outside = 0.0
    inside_above = 0.0
    inside_under = 1.0
    r = 80
    n = '1 1 1'
  [../]
[]

[Executioner]
  type = Transient
  solve_type = 'PJFNK'
  petsc_options_iname = '-pc_type -sub_pc_type   -sub_pc_factor_shift_type'
  petsc_options_value = 'asm       ilu            nonzero'
  l_max_its = 30
  nl_max_its = 10
  l_tol = 1.0e-4
  nl_rel_tol = 1.0e-10
  nl_abs_tol = 1.0e-11

  num_steps = 1
  dt = 1e-5
[]

[Outputs]
  exodus = true
[]

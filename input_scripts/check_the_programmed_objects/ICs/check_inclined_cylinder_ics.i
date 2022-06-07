[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 50
  xmin = -100
  xmax = 100
  ny = 50
  ymin = -100
  ymax = 100
  nz = 50
  zmin = -100
  zmax = 100
[]

[Adaptivity]
	max_h_level = 4
	marker = marker
	initial_marker = marker
	initial_steps = 4
	[./Markers]
		[./marker]
			type = ValueRangeMarker
			lower_bound = 0.01
			upper_bound = 0.99
			variable = c
			third_state = DO_NOTHING
		[../]
	[../]
[]

[Problem]
  solve = false
[]

[Variables]
  [./c]
  [../]
[]

[ICs]
  [./c]
    type = InclinedCylinderIC
    variable = c
    inside = 1.0
    outside = 0.0
    a = 10.0
    b = 50.0
    Q_tens = '-0.7071 0.7071 0.0
              -0.4082 -0.4082 0.8165
              0.5774 0.5774 0.5774'
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

# ============================================================
# Copper wire being pulled through a nozzle
# Adapted from coil winding simulation template
#
# Geometry (coordinates match original coil winder wire position):
#   Wire:        xmin=13.5, xmax=200, ymin=16.5, ymax=17.0  (0.5mm thick)
#   Upper jaw:   x=90..110,  y=17.1..21.1  (inner face 0.1mm above wire top at y=17.0)
#   Lower jaw:   x=90..110,  y=12.4..16.4  (inner face 0.1mm below wire bot at y=16.5)
#
# The nozzle is centred at x=100 along the wire length.
# Wire is pulled in +x direction via prescribed displacement at right end.
# Wire left end is the feed side: free in x, fixed in y (infinite spool).
#
# Units: mm, N, MPa
# ============================================================

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  # -------------------------------------------------------
  # WIRE: Thin 2D rectangle, matches original coil winder wire geometry exactly
  # -------------------------------------------------------
  [wire]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 13.5
    xmax = 200
    ymin = 16.5
    ymax = 17.0
    nx = 185
    ny = 2
    elem_type = QUAD4
    boundary_name_prefix = wire
    boundary_id_offset = 10
  []

  [wire_id]
    type = RenameBlockGenerator
    input = wire
    old_block = '0'
    new_block = '2'
  []

  # -------------------------------------------------------
  # UPPER NOZZLE JAW
  # -------------------------------------------------------
  [upper_jaw]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 90
    xmax = 110
    ymin = 17.1
    ymax = 21.1
    nx = 20
    ny = 8
    elem_type = QUAD4
    boundary_name_prefix = upper_jaw
    boundary_id_offset = 30
  []

  [upper_jaw_id]
    type = RenameBlockGenerator
    input = upper_jaw
    old_block = '0'
    new_block = '3'
  []

  # -------------------------------------------------------
  # LOWER NOZZLE JAW
  # -------------------------------------------------------
  [lower_jaw]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 90
    xmax = 110
    ymin = 12.4
    ymax = 16.4
    nx = 20
    ny = 8
    elem_type = QUAD4
    boundary_name_prefix = lower_jaw
    boundary_id_offset = 50
  []

  [lower_jaw_id]
    type = RenameBlockGenerator
    input = lower_jaw
    old_block = '0'
    new_block = '4'
  []

  # -------------------------------------------------------
  # Combine meshes
  # -------------------------------------------------------
  [combined]
    type = CombinerGenerator
    inputs = 'wire_id upper_jaw_id lower_jaw_id'
  []

  # Wire top face
  [wire_top_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = combined
    new_boundary = 'wire_top'
    block = '2'
    normal = '0 1 0'
  []

  # Wire bottom face
  [wire_bottom_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = wire_top_boundary
    new_boundary = 'wire_bottom'
    block = '2'
    normal = '0 -1 0'
  []

  # Upper jaw bottom face
  [upper_jaw_bottom_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = wire_bottom_boundary
    new_boundary = 'upper_jaw_bottom'
    block = '3'
    normal = '0 -1 0'
  []

  # Lower jaw top face
  [lower_jaw_top_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = upper_jaw_bottom_boundary
    new_boundary = 'lower_jaw_top'
    block = '4'
    normal = '0 1 0'
  []

  # Feed point at left wire end
  [feed_point]
    type = BoundingBoxNodeSetGenerator
    input = lower_jaw_top_boundary
    new_boundary = 'feed_point'
    bottom_left = '13.4 16.4 0'
    top_right   = '13.6 17.1 0'
  []

  # Pull point at right wire end
  [pull_point]
    type = BoundingBoxNodeSetGenerator
    input = feed_point
    new_boundary = 'pull_point'
    bottom_left = '199.9 16.4 0'
    top_right   = '200.1 17.1 0'
  []
[]

[AuxVariables]
  [stress_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_yy]
    order = CONSTANT
    family = MONOMIAL
  []
  [stress_xy]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_yy]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_xy]
    order = CONSTANT
    family = MONOMIAL
  []
  [vonmises]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [stress_xx_aux]
    type = RankTwoAux
    variable = stress_xx
    rank_two_tensor = stress
    index_i = 0
    index_j = 0
  []
  [stress_yy_aux]
    type = RankTwoAux
    variable = stress_yy
    rank_two_tensor = stress
    index_i = 1
    index_j = 1
  []
  [stress_xy_aux]
    type = RankTwoAux
    variable = stress_xy
    rank_two_tensor = stress
    index_i = 0
    index_j = 1
  []
  [strain_xx_aux]
    type = RankTwoAux
    variable = strain_xx
    rank_two_tensor = mechanical_strain
    index_i = 0
    index_j = 0
  []
  [strain_yy_aux]
    type = RankTwoAux
    variable = strain_yy
    rank_two_tensor = mechanical_strain
    index_i = 1
    index_j = 1
  []
  [strain_xy_aux]
    type = RankTwoAux
    variable = strain_xy
    rank_two_tensor = mechanical_strain
    index_i = 0
    index_j = 1
  []
  [vonmises_aux]
    type = RankTwoScalarAux
    variable = vonmises
    rank_two_tensor = stress
    scalar_type = VonMisesStress
  []
[]

[Functions]
  # PHASE 1 (t=0..1): Jaws squeeze to 0.15mm. Holds after t=1.
  [squeeze_ramp_upper]
    type = ParsedFunction
    expression = 'if(t <= 1.0, -0.11 * t, -0.11)'
  []
  [squeeze_ramp_lower]
    type = ParsedFunction
    expression = 'if(t <= 1.0,  0.11 * t,  0.11)'
  []

  # PHASE 2 (t=1..2): Wire pulled 5mm. Zero during squeeze phase.
  [pull_ramp]
    type = ParsedFunction
    expression = 'if(t <= 1.0, 0.0, 5.0 * (t - 1.0))'
  []

  # Returns 1 during squeeze phase, 2 during pull phase — for CSV filtering
  [phase_indicator]
    type = ParsedFunction
    expression = 'if(t <= 1.0, 1, 2)'
  []
[]

[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [wire]
        strain = FINITE
        block = '2'
        add_variables = true
      []
      [nozzle]
        strain = FINITE
        block = '3 4'
        add_variables = true
      []
    []
  []
[]

[Materials]
  [wire_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 110000
    poissons_ratio = 0.34
    block = '2'
  []
  [wire_stress]
    type = ComputeFiniteStrainElasticStress
    block = '2'
  []

  [nozzle_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200000
    poissons_ratio = 0.3
    block = '3 4'
  []
  [nozzle_stress]
    type = ComputeFiniteStrainElasticStress
    block = '3 4'
  []
[]

[Contact]
  [upper_contact]
    primary   = upper_jaw_bottom
    secondary = wire_top
    model     = coulomb
    friction_coefficient = 0.15
    formulation = penalty
    penalty     = 1e6
    normalize_penalty = true
    search_tolerance = 1.0
    search_radius    = 2.0
  []

  [lower_contact]
    primary   = lower_jaw_top
    secondary = wire_bottom
    model     = coulomb
    friction_coefficient = 0.15
    formulation = penalty
    penalty     = 1e6
    normalize_penalty = true
    search_tolerance = 1.0
    search_radius    = 2.0
  []
[]

[BCs]
  # --- Upper jaw: sides fixed, outer top face driven downward ---
  [fix_upper_jaw_sides_x]
    type     = DirichletBC
    variable = disp_x
    boundary = 'upper_jaw_left upper_jaw_right upper_jaw_top'
    value    = 0
  []
  [fix_upper_jaw_sides_y]
    type     = DirichletBC
    variable = disp_y
    boundary = 'upper_jaw_left upper_jaw_right'
    value    = 0
  []
  [squeeze_upper_jaw]
    type     = FunctionDirichletBC
    variable = disp_y
    boundary = upper_jaw_top
    function = squeeze_ramp_upper
  []

  # --- Lower jaw: sides fixed, outer bottom face driven upward ---
  [fix_lower_jaw_sides_x]
    type     = DirichletBC
    variable = disp_x
    boundary = 'lower_jaw_left lower_jaw_right lower_jaw_bottom'
    value    = 0
  []
  [fix_lower_jaw_sides_y]
    type     = DirichletBC
    variable = disp_y
    boundary = 'lower_jaw_left lower_jaw_right'
    value    = 0
  []
  [squeeze_lower_jaw]
    type     = FunctionDirichletBC
    variable = disp_y
    boundary = lower_jaw_bottom
    function = squeeze_ramp_lower
  []

  [feed_fixed_y]
    type     = DirichletBC
    variable = disp_y
    boundary = feed_point
    value    = 0
  []

  [wire_pull_x]
    type     = FunctionDirichletBC
    variable = disp_x
    boundary = pull_point
    function = pull_ramp
  []
  [wire_pull_y]
    type     = DirichletBC
    variable = disp_y
    boundary = pull_point
    value    = 0
  []
[]

[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

[Executioner]
  type = Transient
  solve_type = PJFNK

  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_type -snes_linesearch_type'
  petsc_options_value  = 'hypre    boomeramg      gmres     l2'

  dt       = 0.05
  end_time = 2.0
  dtmin    = 1e-8
  dtmax    = 0.05

  nl_rel_tol = 1e-5
  nl_abs_tol = 1e-4
  nl_max_its = 100

  l_max_its = 200
  l_tol     = 1e-4

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.02
    cutback_factor = 0.5
    growth_factor = 1.2
    optimal_iterations = 30
    iteration_window = 10
  []

  automatic_scaling = true
  compute_scaling_once = false
[]

[Outputs]
  [exodus]
    type = Exodus
    interval = 10
  []
  [csv]
    type = CSV
    interval = 10
  []
  print_linear_residuals = true

  [mesh_out]
    type = Exodus
    execute_on = 'INITIAL'
    file_base = 'mesh_check'
  []
[]

[Postprocessors]
  [wire_max_stress]
    type = ElementExtremeValue
    variable = stress_xx
    block = '2'
  []

  [wire_avg_strain]
    type = ElementAverageValue
    variable = strain_xx
    block = '2'
  []

  [wire_max_vonmises]
    type = ElementExtremeValue
    variable = vonmises
    block = '2'
  []

  [pull_disp_x]
    type = NodalExtremeValue
    variable = disp_x
    boundary = pull_point
  []

  [nozzle_axial_stress]
    type = PointValue
    variable = stress_xx
    point = '100.0 16.75 0'
  []

  # Compressive stress in wire at nozzle mid-point (y-direction)
  [nozzle_stress_yy]
    type = PointValue
    variable = stress_yy
    point = '100.0 16.75 0'
  []

  # Approximate contact force: compressive stress * nozzle contact area
  # Contact area = nozzle width (20mm) * unit depth (1mm) = 20 mm^2
  [contact_force]
    type = ParsedPostprocessor
    expression = 'abs(nozzle_stress_yy) * 20.0'
    pp_names = 'nozzle_stress_yy'
  []

  # Phase indicator: useful for filtering CSV output by phase
  [simulation_phase]
    type = FunctionValuePostprocessor
    function = phase_indicator
  []

  [pull_force]
    type = ParsedPostprocessor
    expression = 'nozzle_axial_stress * 0.5'
    pp_names = 'nozzle_axial_stress'
  []

  [nonlinear_its]
    type = NumNonlinearIterations
  []

  [linear_its]
    type = NumLinearIterations
  []

[]

[Debug]
  show_var_residual_norms = false
[]

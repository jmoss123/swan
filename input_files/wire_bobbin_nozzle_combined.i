# ============================================================
# Combined coil winding simulation with nozzle tensioner
# Merged from: wire_bobbin_sim.i + wire_through_nozzle.i
#
# Geometry:
#   Block 1 - Bobbin:     33mm square, 3mm fillets, loaded from gmsh
#   Block 2 - Wire:       xmin=13.5, xmax=200, ymin=16.5, ymax=17.0 (0.5mm thick)
#   Block 3 - Upper jaw:  x=90..110, y=17.1..21.1 (nozzle, 0.1mm clearance above wire)
#   Block 4 - Lower jaw:  x=90..110, y=12.4..16.4 (nozzle, 0.1mm clearance below wire)
#
# Simulation phases:
#   Phase 1 (t=0..1): Nozzle jaws squeeze closed around stationary wire
#   Phase 2 (t=1..2): Bobbin rotates 1 full revolution, winding wire through nozzle
#
# Units: mm, N, MPa
# Physical wire path: spool (x=200) -> nozzle (x=90..110) -> feed guide (x=60..70) -> bobbin (x=0)
# ============================================================


[GlobalParams]
  displacements = 'disp_x disp_y'
[]


# ============================================================
# MESH
# ============================================================
[Mesh]
  patch_update_strategy = iteration
  patch_size = 100
  # BOBBIN: Load from gmsh file
  [bobbin]
    type = FileMeshGenerator
    file = "bobbin_fillet.msh"
  []

  # WIRE
  [wire]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 13.5
    xmax = 200
    ymin = 16.5
    ymax = 17.0
    nx = 370        # ~1mm elements along wire length
    ny = 2
    elem_type = QUAD4
    boundary_name_prefix = wire
    boundary_id_offset = 10   # Avoids conflict with bobbin boundaries
  []

  [wire_id]
    type = RenameBlockGenerator
    input = wire
    old_block = '0'
    new_block = '2'
  []

  # UPPER NOZZLE JAW
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
    boundary_id_offset = 30   # Avoids conflict with wire and bobbin boundaries
  []

  [upper_jaw_id]
    type = RenameBlockGenerator
    input = upper_jaw
    old_block = '0'
    new_block = '3'
  []

  # LOWER NOZZLE JAW
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
    boundary_id_offset = 50   # Avoids conflict with all other boundaries
  []

  [lower_jaw_id]
    type = RenameBlockGenerator
    input = lower_jaw
    old_block = '0'
    new_block = '4'
  []

  # Combine all four meshes
  [combined]
    type = CombinerGenerator
    inputs = 'bobbin wire_id upper_jaw_id lower_jaw_id'
  []

  [bobbin_full_outer_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = combined
    new_boundary = 'bobbin_full_outer'
    block = '1'           # bobbin block ID from gmsh
  []

  # Wire top face (upper jaw contact secondary)
  [wire_top_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = bobbin_full_outer_boundary
    new_boundary = 'wire_top'
    block = '2'
    normal = '0 1 0'
  []

  # Wire bottom face (bobbin contact + lower jaw contact secondary)
  [wire_bottom_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = wire_top_boundary
    new_boundary = 'wire_bottom'
    block = '2'
    normal = '0 -1 0'
  []

  # Upper jaw bottom face (contact primary)
  [upper_jaw_bottom_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = wire_bottom_boundary
    new_boundary = 'upper_jaw_bottom'
    block = '3'
    normal = '0 -1 0'
  []

  # Lower jaw top face (contact primary)
  [lower_jaw_top_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = upper_jaw_bottom_boundary
    new_boundary = 'lower_jaw_top'
    block = '4'
    normal = '0 1 0'
  []

  # Bobbin tie point
  [tie_point_bobbin]
    type = ExtraNodesetGenerator
    input = lower_jaw_top_boundary
    new_boundary = 'tie_point_bobbin'
    coord = '13.5 16.5 0'
    tolerance = 0.5
  []

  # Wire attachment nodes at bobbin vertex
  [tie_point_wire]
    type = BoundingBoxNodeSetGenerator
    input = tie_point_bobbin
    new_boundary = 'tie_point_wire'
    bottom_left = '13.4 16.4 0'
    top_right   = '13.6 17.1 0'
  []

  [spool_end]
  type = BoundingBoxNodeSetGenerator
  input = tie_point_wire
  new_boundary = 'spool_end'
  bottom_left = '199.9 16.4 0'
  top_right   = '200.1 17.1 0' 
  []
[]


# ============================================================
# AUX VARIABLES + KERNELS
# ============================================================
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
    block = '2'
  []
  [stress_yy_aux]
    type = RankTwoAux
    variable = stress_yy
    rank_two_tensor = stress
    index_i = 1
    index_j = 1
    block = '2'
  []
  [stress_xy_aux]
    type = RankTwoAux
    variable = stress_xy
    rank_two_tensor = stress
    index_i = 0
    index_j = 0
    block = '2'
  []
  [strain_xx_aux]
    type = RankTwoAux
    variable = strain_xx
    rank_two_tensor = mechanical_strain
    index_i = 0
    index_j = 0
    block = '2'
  []
  [strain_yy_aux]
    type = RankTwoAux
    variable = strain_yy
    rank_two_tensor = mechanical_strain
    index_i = 1
    index_j = 1
    block = '2'
  []
  [strain_xy_aux]
    type = RankTwoAux
    variable = strain_xy
    rank_two_tensor = mechanical_strain
    index_i = 0
    index_j = 1
    block = '2'
  []
  [vonmises_aux]
    type = RankTwoScalarAux
    variable = vonmises
    rank_two_tensor = stress
    scalar_type = VonMisesStress
    block = '2'
  []
[]


# ============================================================
# FUNCTIONS
# ============================================================
[Functions]
  # Angular velocity — zero during squeeze, 1 rev/s during winding
  [omega]
    type = ParsedFunction
    expression = 'if(t <= 1.0, 0.0, 6.28318)'
  []

  # Cumulative rotation angle — zero during Phase 1, ramps 0->2*pi in Phase 2
  [theta]
    type = ParsedFunction
    expression = 'if(t <= 1.0, 0.0, 6.28318 * (t - 1.0))'
  []

  # Rotation displacement components — wire_bobbin_sim.i (unchanged)
  [rotate_x]
    type = ParsedFunction
    symbol_names = 'theta'
    symbol_values = 'theta'
    expression = 'x*cos(theta) - y*sin(theta) - x'
  []
  [rotate_y]
    type = ParsedFunction
    symbol_names = 'theta'
    symbol_values = 'theta'
    expression = 'x*sin(theta) + y*cos(theta) - y'
  []

  # Nozzle squeeze
  # Squeezes 0.104mm (closes 0.1mm gap + 0.004mm compression), holds at t=1
  [squeeze_ramp_upper]
    type = ParsedFunction
    expression = 'if(t <= 1.0, -0.104 * t, -0.104)'
  []
  [squeeze_ramp_lower]
    type = ParsedFunction
    expression = 'if(t <= 1.0,  0.104 * t,  0.104)'
  []

  # Phase indicator for CSV filtering — wire_through_nozzle.i
  [phase_indicator]
    type = ParsedFunction
    expression = 'if(t <= 1.0, 1, 2)'
  []
[]


# ============================================================
# PHYSICS
# ============================================================
[Physics]
  [SolidMechanics]
    [QuasiStatic]
      [bobbin]
        block = '1'
        strain = FINITE
        add_variables = true
        displacements = 'disp_x disp_y'
      []

      [wire]
        block = '2'
        strain = FINITE
        add_variables = true       
        displacements = 'disp_x disp_y'
      []

      [jaws]
        block = '3 4'
        strain = FINITE
        add_variables = true
        displacements = 'disp_x disp_y'
      []
    []
  []
[]


# ============================================================
# MATERIALS
# ============================================================
[Materials]
  # Bobbin: steel 
  [bobbin_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200000 # MPa
    poissons_ratio = 0.3
    block = '1'
  []
  [bobbin_stress]
    type = ComputeFiniteStrainElasticStress
    block = '1'
  []

  # Wire: copper
  [wire_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 110000 # MPa
    poissons_ratio = 0.34
    block = '2'
  []

  [wire_stress]
    type = ComputeFiniteStrainElasticStress
    block = '2'
  []

  # Nozzle jaws: steel
  [nozzle_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200000 # MPa
    poissons_ratio = 0.3
    block = '3 4'
  []
  [nozzle_stress]
    type = ComputeFiniteStrainElasticStress
    block = '3 4'
  []
[]


# ============================================================
# CONTACT
# 3 contact pairs: wire-bobbin (frictionless), wire-upper jaw, wire-lower jaw (Coulomb)
# ============================================================
[Contact]
  # Wire bottom vs bobbin outer face
  [wire_bobbin]
    primary   = 'bobbin_full_outer'
    secondary = 'wire_bottom'
    model     = coulomb
    friction_coefficient = 0.15
    formulation = mortar
    correct_edge_dropping = true
    normal_smoothing_distance = 0.15
  []

  # Wire top vs upper jaw bottom
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

  # Wire bottom vs lower jaw top
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


# ============================================================
# BOUNDARY CONDITIONS
# ============================================================
[BCs]
  # Bobbin rotation
  # theta=0 during Phase 1; ramps 0->2*pi during Phase 2
  [bobbin_rotate_x]
    type = DisplacementAboutAxis
    variable = disp_x
    boundary = 'bobbin_inner tie_point_wire'
    component = 0
    function = theta
    angle_units = radians
    axis_origin = '0 0 0'
    axis_direction = '0 0 1'
  []
  [bobbin_rotate_y]
    type = DisplacementAboutAxis
    variable = disp_y
    boundary = 'bobbin_inner tie_point_wire'
    component = 1
    function = theta
    angle_units = radians
    axis_origin = '0 0 0'
    axis_direction = '0 0 1'
  []

  # Upper jaw: sides fixed, top face driven downward
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

  # Lower jaw: sides fixed, bottom face driven upward
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

  [spool_fixed_y]
  type = DirichletBC
  variable = disp_y
  boundary = spool_end
  value = 0
  []
[]

# ============================================================
# PRECONDITIONING & EXECUTIONER
# ============================================================
[Preconditioning]
  [SMP]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value  = 'lu       mumps'
  []
[]

[Executioner]
  type = Transient
  solve_type = PJFNK

  petsc_options_iname = '-ksp_type -ksp_gmres_restart -snes_linesearch_type'
  petsc_options_value  = 'gmres     200                bt'

  dt       = 0.01
  end_time = 1.3
  dtmin    = 1e-9
  dtmax    = 0.075

  nl_rel_tol = 1e-4
  nl_abs_tol = 1e-3
  nl_max_its = 50

  l_max_its = 200
  l_tol     = 1e-4

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.02
    cutback_factor = 0.5
    growth_factor  = 1.2
    optimal_iterations  = 30
    iteration_window    = 10
  []

  automatic_scaling    = true
  compute_scaling_once = true
[]


# ============================================================
# OUTPUTS
# ============================================================
[Outputs]
  [exodus]
    type = Exodus
    interval = 50
  []

  [csv]
    type = CSV
    interval = 50
  []

  print_linear_residuals = true

  [mesh_out]
    type = Exodus
    execute_on = 'INITIAL'
    file_base  = 'mesh_check'
  []

  [checkpoint]
    type = Checkpoint
    num_files = 3
    interval = 20
  []
[]


# ============================================================
# POSTPROCESSORS
# ============================================================
[Postprocessors]
  # Wire stress/strain
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

  # Bobbin rotation monitoring
  [bobbin_rotation_angle]
    type = FunctionValuePostprocessor
    function = theta
  []

  # Wire tension at feed guide
  # Area = 0.5mm thickness x 1mm unit depth = 0.5 mm^2
  [feed_axial_force]
    type = PointValue
    variable = stress_xx
    point = '63.5 16.5 0'
  []

  [tension_magnitude]
    type = ParsedPostprocessor
    expression = 'feed_axial_force * 0.5'
    pp_names = 'feed_axial_force'
  []

  # Friction monitoring
  [nozzle_friction_force_upper]
    type = SideIntegralVariablePostprocessor
    variable = stress_xy
    boundary = upper_jaw_bottom
  []

  [nozzle_friction_force_lower]
    type = SideIntegralVariablePostprocessor
    variable = stress_xy
    boundary = lower_jaw_top
  []

  [total_friction_force_N]
    type = ParsedPostprocessor
    expression = 'abs(nozzle_friction_force_upper) + abs(nozzle_friction_force_lower)'
    pp_names = 'nozzle_friction_force_upper nozzle_friction_force_lower'
  []

  [nozzle_normal_force_upper]
    type = SideIntegralVariablePostprocessor
    variable = stress_yy
    boundary = upper_jaw_bottom
  []

  [nozzle_normal_force_lower]
    type = SideIntegralVariablePostprocessor
    variable = stress_yy
    boundary = lower_jaw_top
  []

  [total_normal_force_N]
    type = ParsedPostprocessor
    expression = 'abs(nozzle_normal_force_upper) + abs(nozzle_normal_force_lower)'
    pp_names = 'nozzle_normal_force_upper nozzle_normal_force_lower'
  []

  # Phase indicator
  [simulation_phase]
    type = FunctionValuePostprocessor
    function = phase_indicator
  []

  # Convergence monitoring
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

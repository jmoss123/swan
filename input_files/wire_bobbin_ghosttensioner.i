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
    xmax = 300
    ymin = 16.5
    ymax = 17.0
    nx = 1146        # ~0.25mm elements along wire length
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

  # Combine all four meshes
  [combined]
    type = CombinerGenerator
    inputs = 'bobbin wire_id'
  []

  [bobbin_full_outer_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = combined
    new_boundary = 'bobbin_full_outer'
    block = '1'           # bobbin block ID from gmsh
  []

  [wire_all_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = bobbin_full_outer_boundary
    new_boundary = 'wire_all'
    block = '2' 
  []

  # Wire top face (upper jaw contact secondary)
  [wire_top_boundary]
    type = SideSetsFromNormalsGenerator
    input = wire_all_boundary
    boundaries = 'wire_all'
    new_boundary = 'wire_top'
    normals = '0 1 0'
    variance = 0.1
  []

  # Wire bottom face (bobbin contact + lower jaw contact secondary)
  [wire_bottom_boundary]
    type = SideSetsFromNormalsGenerator
    input = wire_top_boundary
    boundaries = 'wire_all'
    new_boundary = 'wire_bottom'
    normals = '0 -1 0'
    variance = 0.1
  []

  # Wire attachment nodes at bobbin vertex
  [tie_point_wire]
    type = BoundingBoxNodeSetGenerator
    input = wire_bottom_boundary
    new_boundary = 'tie_point_wire'
    bottom_left = '13.4 16.4 0'
    top_right   = '13.6 17.1 0'
  []

  [spool_end]
    type = SideSetsFromNormalsGenerator
    input = tie_point_wire
    new_boundary = 'spool_end'
    normals = '1 0 0'
    variance = 0.1
    fixed_normal = true
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
    index_j = 1
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

  [backtension_ramp]
    type = ParsedFunction
    expression = 'if(t <= 1.0, 200 * t, 200)'
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
    []
  []
[]


# ============================================================
# MATERIALS
# ============================================================
[Materials]
  # Bobbin: Nylon 66 
  [bobbin_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 10000 # MPa
    poissons_ratio = 0.38
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
[]


# ============================================================
# CONTACT
# 3 contact pairs: wire-bobbin (frictionless), wire-upper jaw, wire-lower jaw (Coulomb)
# ============================================================
[Contact]
  # Wire bottom vs bobbin outer face
  [wire_bobbin]
    primary              = 'bobbin_full_outer'
    secondary            = 'wire_bottom'
    model                = frictionless
    formulation          = penalty
    penalty              = 1e9
    normalize_penalty    = false
    search_radius        = 0.1
    search_tolerance     = 0.01
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
    boundary = 'bobbin_inner'
    component = 0
    function = theta
    angle_units = radians
    axis_origin = '0 0 0'
    axis_direction = '0 0 1'
  []
  [bobbin_rotate_y]
    type = DisplacementAboutAxis
    variable = disp_y
    boundary = 'bobbin_inner'
    component = 1
    function = theta
    angle_units = radians
    axis_origin = '0 0 0'
    axis_direction = '0 0 1'
  []

  [backtension]
    type = FunctionNeumannBC
    variable = disp_x
    boundary = spool_end
    function = backtension_ramp   
  []

  [wire_attach_x]
    type = DisplacementAboutAxis
    variable = disp_x
    boundary = 'tie_point_wire'
    component = 0
    function = theta
    angle_units = radians
    axis_origin = '0 0 0'
    axis_direction = '0 0 1'
  []
  [wire_attach_y]
    type = DisplacementAboutAxis
    variable = disp_y
    boundary = 'tie_point_wire'
    component = 1
    function = theta
    angle_units = radians
    axis_origin = '0 0 0'
    axis_direction = '0 0 1'
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
  petsc_options_value  = 'gmres      200                  bt'

  dt       = 0.01
  end_time = 1.5
  dtmin    = 1e-8
  dtmax    = 0.05

  nl_rel_tol = 1e-4
  nl_abs_tol = 1e-3
  nl_max_its = 15

  l_max_its = 100
  l_tol     = 1e-3

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.01
    cutback_factor = 0.5
    growth_factor  = 1.2
    optimal_iterations  = 15
    iteration_window    = 7
  []

  automatic_scaling    = true
[]


# ============================================================
# OUTPUTS
# ============================================================
[Outputs]
  [exodus]
    type = Exodus
    interval = 75
  []

  [csv]
    type = CSV
    interval = 75
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
 # [feed_axial_force]
 #   type = PointValue
 #   variable = stress_xx
 #   point = '63.5 16.5 0'
 # []

 # [tension_magnitude]
 #   type = ParsedPostprocessor
 #   expression = 'feed_axial_force * 0.5'
 #   pp_names = 'feed_axial_force'
 # []

  # Friction monitoring
  #[nozzle_friction_force_upper]
  #  type = SideIntegralVariablePostprocessor
  #  variable = stress_xy
  #  boundary = upper_jaw_bottom
  #[]

  #[nozzle_friction_force_lower]
  #  type = SideIntegralVariablePostprocessor
  #  variable = stress_xy
  #  boundary = lower_jaw_top
  #[]

  #[total_friction_force_N]
  #  type = ParsedPostprocessor
  #  expression = 'abs(nozzle_friction_force_upper) + abs(nozzle_friction_force_lower)'
  #  pp_names = 'nozzle_friction_force_upper nozzle_friction_force_lower'
  #[]

  #[nozzle_normal_force_upper]
  #  type = SideIntegralVariablePostprocessor
  #  variable = stress_yy
  #  boundary = upper_jaw_bottom
  #[]

  #[nozzle_normal_force_lower]
  #  type = SideIntegralVariablePostprocessor
  #  variable = stress_yy
  #  boundary = lower_jaw_top
  #[]

  #[total_normal_force_N]
  #  type = ParsedPostprocessor
  #  expression = 'abs(nozzle_normal_force_upper) + abs(nozzle_normal_force_lower)'
  #  pp_names = 'nozzle_normal_force_upper nozzle_normal_force_lower'
  #[]

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

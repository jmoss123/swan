# Coil winding simulation: rotating square bobbin wrapping 1D wire
# Wire feeds from fixed point, bonded at one vertex, frictional contact elsewhere

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  # 2D square bobbin (33mm x 33mm, centered at origin)
  [bobbin]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = -16.5 	# mm
    xmax = 16.5 	# mm
    ymin = -16.5 	# mm
    ymax = 16.5 	# mm
    nx = 33 # 33 elements across 33mm = 1mm element size
    ny = 33 # 33 elements across 33mm = 1mm element size
    elem_type = QUAD4
    boundary_name_prefix = bobbin
  []
  
  # 1D wire - needs to be in 2D space for contact
  # Wire extends from feed point to bobbin attachment
  [wire]
    type = GeneratedMeshGenerator
    dim = 1
    xmin = 16.5      	# Starts at bobbin vertex
    xmax = 66.5    		# Extends to feed point (50mm length)
    nx = 50		 		# 1mm element size along wire
    elem_type = EDGE2
    boundary_name_prefix = wire
    boundary_id_offset = 10 	# Avoid ID conflicts with bobbin boundaries
  []
  
  # Combine bobbin and wire meshes into single mesh for contact and constraints
  [combined]
    type = CombinerGenerator #
    inputs = 'bobbin wire' 
  []
  
  # Assign block IDs 
  [bobbin_block]
    type = SubdomainBoundingBoxGenerator 
    input = combined
    block_id = 1
    block_name = 'bobbin'
    bottom_left = '-16.5 -16.5 0' 
    top_right = '16.5 16.5 0'
  []
  
  [wire_block]
    type = SubdomainBoundingBoxGenerator
    input = bobbin_block
    block_id = 2
    block_name = 'wire'
    bottom_left = '16.5 -1 0'
    top_right = '66.5 1 0'
  []
  
  # Create nodeset for tied connection point (bobbin top-right vertex)
  [tie_point_bobbin]
    type = ExtraNodesetGenerator
    input = wire_block
    new_boundary = 'tie_point_bobbin'
    coord = '16.5 16.5 0'
    tolerance = 0.1
  []
  
  # Wire attachment point (left end of wire)
  [tie_point_wire]
    type = BoundingBoxNodeSetGenerator
    input = tie_point_bobbin
    new_boundary = 'tie_point_wire'
    bottom_left = '16.4 -0.5 0'
    top_right = '16.6 0.5 0'
  []
  
  # Wire feed point (right end)
  [feed_point]
    type = BoundingBoxNodeSetGenerator
    input = tie_point_wire
    new_boundary = 'feed_point'
    bottom_left = '66 -0.5 0'
    top_right = '67 0.5 0'
  []
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
[]

[AuxVariables]
  [stress_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [strain_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [vonmises]
    order = CONSTANT
    family = MONOMIAL
  []
  [react_x]
    order = FIRST
    family = LAGRANGE
  []
  [react_y]
    order = FIRST
    family = LAGRANGE
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
  [strain_xx_aux]
    type = RankTwoAux
    variable = strain_xx
    rank_two_tensor = mechanical_strain
    index_i = 0
    index_j = 0
  []
  [vonmises_aux]
    type = RankTwoScalarAux
    variable = vonmises
    rank_two_tensor = stress
    scalar_type = VonMisesStress
  []
  [reaction_x]
    type = PenaltyReactionAux
    variable = react_x
    x_disp = disp_x
    y_disp = disp_y
    execute_on = timestep_end
  []
  [reaction_y]
    type = PenaltyReactionAux
    variable = react_y
    x_disp = disp_x
    y_disp = disp_y
    execute_on = timestep_end
  []
[]

[Functions]
  # Bobbin rotation parameters
  [omega]
    type = ParsedFunction
    expression = '6.28318'  # 2*pi rad/s = 1 revolution per second
  []
  
  # Total rotation angle: theta = omega * t
  [theta]
    type = ParsedFunction
    expression = '6.28318*t'  # Completes 360° at t=1s
  []
  
  # Rotation displacement for bobbin center at origin
  # x' = x*cos(θ) - y*sin(θ)
  # y' = x*sin(θ) + y*cos(θ)
  # Displacement = (x',y') - (x,y)
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
[]

[Kernels]
  # Bobbin mechanics
  [bobbin_stress_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
    block = bobbin
  []
  [bobbin_stress_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
    block = bobbin
  []
  
  # Wire mechanics
  [wire_stress_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
    block = wire
  []
  [wire_stress_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
    block = wire
  []
[]

[Materials]
  # Bobbin material (very stiff = quasi-rigid)
  [bobbin_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e12  # 1000x stiffer than wire
    poissons_ratio = 0.3
    block = bobbin
  []
  [bobbin_strain]
    type = ComputeSmallStrain
    block = bobbin
  []
  [bobbin_stress]
    type = ComputeLinearElasticStress
    block = bobbin
  []
  
  # Wire material (copper)
  [wire_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
    poissons_ratio = 0.3
    block = wire
  []
  [wire_strain]
    type = ComputeSmallStrain
    block = wire
  []
  [wire_stress]
    type = ComputeLinearElasticStress
    block = wire
  []
[]

[Constraints]
  # Tied connection between wire and bobbin vertex
  # This bonds the wire end to the rotating bobbin point
  [tie_wire_to_bobbin_x]
    type = EqualValueBoundaryConstraint
    variable = disp_x
    primary = tie_point_wire
    secondary = tie_point_bobbin
    penalty = 1e12
  []
  [tie_wire_to_bobbin_y]
    type = EqualValueBoundaryConstraint
    variable = disp_y
    primary = tie_point_wire
    secondary = tie_point_bobbin
    penalty = 1e12
  []
[]

[Contact]
  # Frictional contact between wire and bobbin surfaces
  # Note: This requires wire to be 2D or use specialized contact
  [wire_bobbin_friction]
    primary = bobbin_right    # Bobbin surface
    secondary = wire_left      # Wire surface closest to bobbin
    model = coulomb
    formulation = penalty
    friction_coefficient = 0.8  # High friction = "rough" contact
    penalty = 1e9
    normalize_penalty = true
  []
[]

[BCs]
  # Prescribe rigid body rotation to all bobbin nodes
  [bobbin_rotate_x]
    type = FunctionDirichletBC
    variable = disp_x
    boundary = 'bobbin_left bobbin_right bobbin_top bobbin_bottom'
    function = rotate_x
  []
  [bobbin_rotate_y]
    type = FunctionDirichletBC
    variable = disp_y
    boundary = 'bobbin_left bobbin_right bobbin_top bobbin_bottom'
    function = rotate_y
  []
  
  # Wire feed point - fixed in space, stress-free (infinite wire supply)
  [feed_fixed_x]
    type = DirichletBC
    variable = disp_x
    boundary = feed_point
    value = 0
  []
  [feed_fixed_y]
    type = DirichletBC
    variable = disp_y
    boundary = feed_point
    value = 0
  []
  
  # Zero traction at feed point (no effect on stress/strain)
  [feed_stress_free_x]
    type = NeumannBC
    variable = disp_x
    boundary = feed_point
    value = 0
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
  solve_type = NEWTON
  
  # Time stepping - 1 second = 1 full rotation
  dt = 0.01
  end_time = 1.0
  
  # Solver settings for contact problems
  petsc_options_iname = '-pc_type -pc_factor_mat_solver_package -snes_linesearch_type'
  petsc_options_value = 'lu       superlu_dist                  basic'
  
  # Relaxed tolerances for contact
  nl_rel_tol = 1e-5
  nl_abs_tol = 1e-7
  nl_max_its = 50
  
  l_max_its = 100
  l_tol = 1e-4
  
  # Automatic scaling helps with stiff bobbin
  automatic_scaling = true
  compute_scaling_once = false
[]

[Outputs]
  exodus = true
  csv = true
  print_linear_residuals = false
  interval = 5  # Output every 5 timesteps
[]

[Postprocessors]
  [wire_max_stress]
    type = ElementExtremeValue
    variable = stress_xx
    block = wire
  []
  [wire_avg_strain]
    type = ElementAverageValue
    variable = strain_xx
    block = wire
  []
  [wire_max_vonmises]
    type = ElementExtremeValue
    variable = vonmises
    block = wire
  []
  [bobbin_rotation_angle]
    type = FunctionValuePostprocessor
    function = theta
  []
  [tie_point_disp_x]
    type = NodalExtremeValue
    variable = disp_x
    boundary = tie_point_wire
  []
  [tie_point_disp_y]
    type = NodalExtremeValue
    variable = disp_y
    boundary = tie_point_wire
  []
  [tension_feed_x]
    type = NodalSum
    variable = react_x
    boundary = feed_point
  []
  [tension_feed_y]
    type = NodalSum
    variable = react_y
    boundary = feed_point
  []
  
  [tension_magnitude]
    type = ParsedPostprocessor
    expression = 'sqrt(fx^2 + fy^2)'
    pp_names = 'tension_feed_x tension_feed_y'
  []
[]

[Debug]
  show_var_residual_norms = true
[]

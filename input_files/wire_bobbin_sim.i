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
  [bobbin_id]
    type = RenameBlockGenerator
    input = bobbin
    old_block = '0'
    new_block = '1'
  []
  
  # 2D wire (50mm long x 1mm diameter))
  # Wire extends from feed point to bobbin attachment
  [wire]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 16.5      	# Starts at bobbin vertex
    xmax = 66.5    		# Extends to feed point (50mm length)
	ymin = 16.25 		# Centered at y=16.5 (bobbin vertex)
	ymax = 16.75		# 1mm diameter
    nx = 50		 		# 1mm element size along wire
	ny = 2 				# 2 elements through thickness
    elem_type = QUAD4
    boundary_name_prefix = wire
    boundary_id_offset = 10 	# Avoid ID conflicts with bobbin boundaries
  []
  [wire_id]
    type = RenameBlockGenerator
    input = wire
    old_block = '0'
    new_block = '2'
  []
  
  # Combine bobbin and wire meshes into single mesh for contact and constraints
  [combined]
    type = CombinerGenerator
    inputs = 'bobbin_id wire_id' 
  []
  
  # Create nodeset for tied connection point (bobbin top-right vertex)
  [tie_point_bobbin]
    type = ExtraNodesetGenerator
    input = combined
    new_boundary = 'tie_point_bobbin'
    coord = '16.5 16.5 0'
    tolerance = 0.5
  []
  
  # Wire attachment nodes (left edge of wire at bobbin vertex)
  [tie_point_wire]
    type = BoundingBoxNodeSetGenerator
    input = tie_point_bobbin
    new_boundary = 'tie_point_wire'
    bottom_left = '16.4 16.2 0'
    top_right = '16.6 16.8 0'
  []
  
  # Wire left edge boundary for contact
  [wire_left_boundary]
    type = SideSetsAroundSubdomainGenerator
    input = tie_point_wire
    new_boundary = 'wire_left_side'
    block = '2'
    normal = '-1 0 0'
  []

  # Bobbin right edge boundary for contact
  [bobbin_right_boundary]
	type = SideSetsAroundSubdomainGenerator
	input = wire_left_boundary
	new_boundary = 'bobbin_right_side'
	block = '1'
	normal = '1 0 0'
  []
  # Wire feed point boundary (right edge of wire)
  [feed_point]
	type = BoundingBoxNodeSetGenerator
	input = bobbin_right_boundary
	new_boundary = 'feed_point'
	bottom_left = '66.4 16.2 0'
	top_right = '66.6 16.8 0'
  []
[]

[Variables]
  [disp_x]
  []
  [disp_y]
  []
[]

[AuxVariables]
  # Stresses 
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
  # Strains
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
  # Stresses
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
  
  # Strains
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
    block = '1'
  []
  [bobbin_stress_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
    block = '1'
  []
  
  # Wire mechanics
  [wire_stress_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
    block = '2'
  []
  [wire_stress_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
    block = '2'
  []
[]

[Materials]
  # Bobbin material (very stiff = quasi-rigid)
  [bobbin_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e12  # 1000x stiffer than wire
    poissons_ratio = 0.3
    block = '1'
  []
  [bobbin_strain]
    type = ComputeSmallStrain
    block = '1'
  []
  [bobbin_stress]
    type = ComputeLinearElasticStress
    block = '1'
  []
  
  # Wire material (copper)
  [wire_elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
    poissons_ratio = 0.3
    block = '2'
  []
  [wire_strain]
    type = ComputeSmallStrain
    block = '2'
  []
  [wire_stress]
    type = ComputeLinearElasticStress
    block = '2'
  []
[]

[Constraints]
  # Tied connection between wire and bobbin vertex
  # This bonds the wire end to the rotating bobbin point
  [tie_x]
    type = TiedValueConstraint
    variable = disp_x
    primary_boundary = tie_point_bobbin
    secondary_boundary = tie_point_wire
    secondary_variable = disp_x
  []
  [tie_y]
    type = TiedValueConstraint
    variable = disp_y
    primary_boundary = tie_point_bobbin
    secondary_boundary = tie_point_wire
    secondary_variable = disp_y
  []
[]

[Contact]
  # Frictional contact between wire and bobbin surfaces
  [wire_bobbin_contact]
    primary = bobbin_right_side    # Bobbin right surface
    secondary = wire_left_side     # Wire left surface
    model = coulomb
    formulation = penalty
    friction_coefficient = 0.6     # Realistic wire-on-plastic friction
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
  
  # Wire feed point - fixed in space (infinite wire supply)
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
  
  # Wire tension calculated from stress at feed boundary
  [feed_stress_xx_avg]
    type = SideAverageValue
    variable = stress_xx
    boundary = 'wire_right'
  []
  
  [feed_stress_yy_avg]
    type = SideAverageValue
    variable = stress_yy
    boundary = 'wire_right'
  []
  
  # Approximate tension magnitude (stress * cross-section area)
  # Wire area = 0.5mm thickness * 1mm (out-of-plane) = 0.5 mm^2
  [tension_magnitude]
    type = ParsedPostprocessor
    expression = 'sqrt(sx^2 + sy^2) * 0.5'
    pp_names = 'feed_stress_xx_avg feed_stress_yy_avg'
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
  show_var_residual_norms = true
[]

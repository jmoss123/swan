# Coil winding simulation: rotating square bobbin wrapping 1D wire
# Wire feeds from fixed point, bonded at one vertex, frictional contact elsewhere

[GlobalParams]
  displacements = 'disp_x disp_y'
[]

[Mesh]
  # BOBBIN: Perimeter skin mesh (1mm wall, hollow interior)
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

  # Tag all interior elements for deletion
  [flag_interior]
    type = ParsedSubdomainMeshGenerator
    input = bobbin_id
    combinatorial_geometry = '(x > -14.5) & (x < 14.5) & (y > -14.5) & (y < 14.5)'
    block_id = '99'
    block_name = 'bobbin_interior'
  []

  # Delete th interior block
  [bobbin_perimeter]
    type = BlockDeletionGenerator
    input = flag_interior
    block = 'bobbin_interior'
    new_boundary = 'bobbin_inner_surface'
  []
  
  # WIRE: 1D Timoshenko beam elements (EDGE2)
  [wire_raw]
    type = GeneratedMeshGenerator
    dim = 1
    xmin = 16.5      	# Starts at bobbin vertex
    xmax = 66.5    		# Extends to feed point (50mm length)
    nx = 50		 		# 1mm element size along wire
    elem_type = EDGE2
    boundary_name_prefix = wire
    boundary_id_offset = 10 	# Avoid ID conflicts with bobbin boundaries
  []

  # Move wire from y=0 to y=16.5 (bobbin top-right corner height)
  [wire_positioned]
    type = TransformGenerator
    input = wire_raw
    transform = TRANSLATE
    vector_value = '0 16.5 0'
  []
  
  # Rename wire block to avoid ID conflicts with bobbin
  [wire_id]
    type = RenameBlockGenerator
    input = wire_positioned
    old_block = '0'
    new_block = '2'
  []
  
  # Combine bobbin and wire meshes into single mesh for contact and constraints
  [combined]
    type = CombinerGenerator
    inputs = 'bobbin_perimeter wire_id' 
  []
  
  # Create nodeset for tied connection point (bobbin top-right vertex)
  [tie_point_bobbin]
    type = ExtraNodesetGenerator
    input = combined
    new_boundary = 'tie_point_bobbin'
    coord = '16.5 16.5 0'
    tolerance = 0.1
  []
  
  # Wire attachment nodes (left edge of wire at bobbin vertex)
  [tie_point_wire]
    type = ExtraNodesetGenerator
    input = tie_point_bobbin
    new_boundary = 'tie_point_wire'
    coord = '16.5 16.5 0'
    tolerance = 0.1
  []
  
  # Wire feed point boundary (right edge of wire)
  [feed_point]
	  type = ExtraNodesetGenerator
	  input = tie_point_wire
	  new_boundary = 'feed_point'
	  coord = '66.5 16.5 0'
	  tolerance = 0.1
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
    youngs_modulus = 200e12    # Modelling as rigid body
    poissons_ratio = 0.3
    block = '1'
  []
  [bobbin_strain]
    type = ComputeFiniteStrain
    block = '1'
  []
  [bobbin_stress]
    type = ComputeFiniteStrainElasticStress
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
    type = ComputeFiniteStrain
    block = '2'
  []
  [wire_stress]
    type = ComputeFiniteStrainElasticStress
    block = '2'
  []
[]

[Constraints]
  [tie_x]
    type = EqualValueConstraint
    variable = disp_x
    primary_boundary = tie_point_bobbin        
    secondary_boundary = tie_point_wire       
  []
  
  [tie_y]
    type = EqualValueConstraint
    variable = disp_y
    primary_boundary = tie_point_bobbin        
    secondary_boundary = tie_point_wire       
  []
[]

[Problem]
  type = AugmentedLagrangianContactProblem
  maximum_lagrangian_update_iterations = 20
[]

[Contact]
  # Frictionless contact between wire and bobbin surfaces
  [wire_bobbin_top]
    primary = 'bobbin_top'    # Bobbin surfaces
    secondary = 'wire_bottom'          # Wire surfaces
    model = frictionless
    formulation = augmented_lagrange
    penalty = 1e6
    al_penetration_tolerance = 1e-4
  []

  [wire_bobbin_right]
    primary = 'bobbin_right'    # Bobbin surfaces
    secondary = 'wire_bottom'          # Wire surfaces
    model = frictionless
    formulation = augmented_lagrange
    penalty = 1e6
    al_penetration_tolerance = 1e-4
  []

  [wire_bobbin_left]
    primary = 'bobbin_left'    # Bobbin surfaces
    secondary = 'wire_bottom'          # Wire surfaces
    model = frictionless
    formulation = augmented_lagrange
    penalty = 1e6
    al_penetration_tolerance = 1e-4
  []

  [wire_bobbin_bottom]
    primary = 'bobbin_bottom'    # Bobbin surfaces
    secondary = 'wire_bottom'          # Wire surfaces
    model = frictionless
    formulation = augmented_lagrange
    penalty = 1e6
    al_penetration_tolerance = 1e-4
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
  dt = 0.0005
  end_time = 0.1
  
  # Relaxed tolerances for contact
  nl_rel_tol = 1e-5
  nl_abs_tol = 1e-4
  nl_max_its = 50
  
  l_max_its = 200
  l_tol = 1e-4

  petsc_options_iname = '-pc_type -pc_factor_shift_type -snes_linesearch_type'
  petsc_options_value = 'lu	NONZERO			bt'

  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.0005
    cutback_factor = 0.25
    growth_factor = 1.1
    optimal_iterations = 15
  []
  
  # Automatic scaling helps with stiff bobbin
  automatic_scaling = true
  compute_scaling_once = false
[]

[Outputs]
  [exodus]
    type = Exodus
    interval = 5
  []
  [csv]
    type = CSV
    interval = 5
  []
  print_linear_residuals = false

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
  # Wire area = pi * (0.5)^2 = 0.7854 mm^2
  [tension_magnitude]
    type = ParsedPostprocessor
    expression = 'sqrt(feed_stress_xx_avg^2 + feed_stress_yy_avg^2) * 0.7854'
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

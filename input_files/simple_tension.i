[GlobalParams]
	displacements = 'disp_x'
[]

[Mesh]
	[wire]
		type = GeneratedMeshGenerator
		dim = 1
		nx = 100
		xmin = 0
		xmax = 0.1
		boundary_id = '0 1'
		bounday_name = 'left right'
	[]
[]

[Physics/SolidMechanics/Quasistatic]
	[all]
		add_variables = true
	[]
[]

[Materials]
	[elasticity]
		type = ComputeIsotropicElasticityTensor
		youngs_modulus = 200e9
		poissons_ratio = 0.3
	[]
	[stress]
		type = ComputeLinearElasticStress
		elasticity_tensor = elasticity
	[]
[]

[BCs]
	[left]
		type = DirichletBC
		boundary = left
		variable = disp_x
		value = 0
	[]
	[right_pressure]
		type = Pressure
		variable = disp_x
		boundary = right
		factor = 100e6
	[]
[]

[Executioner]
	type = Steady
	solve_type = 'NEWTON'
	nonlinear_solver = 'PJFNK'
[]

[Outputs]
	exodus = true
[]


[AuxVariables]
	[stress_xx]
		order = CONSTANT
		family = MONOMIAL
	[]
	[strain_xx]
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
    		execute_on = timestep_end
  	[]
  	[strain_xx_aux]
    		type = RankTwoAux
    		variable = strain_xx
    		rank_two_tensor = mechanical_strain 
    		index_i = 0
    		index_j = 0
    		execute_on = timestep_end
  	[]
[]

[Mesh]
	[wire_mesh]
		type = GeneratedMeshGenerator
		dim = 1
		xmin = 0
		xmax = 100
		nx = 100
		elem_type = EDGE2
	[]
[]

[Variables]
	[disp_x]
		order = FIRST
		family = LAGRANGE
	[]
[]

[Kernels]
	[stress_divergence]
		type = StressDivergenceTensors
		variable = disp_x
		displacements = 'disp_x'
		component = 0
	[]
[]

[Materials]
	[elasticity]
		type = ComputeIsotropicElasticityTensor
		youngs_modulus = 200e9
		poissons_ratio = 0.3
	[]
	[strain]
		type = ComputeSmallStrain
		displacements = 'disp_x'
	[]
	[stress]
		type = ComputeLinearElasticStress
	[]
[]

[BCs]
	[fix_left]
		type = DirichletBC
		boundary = left
		variable = disp_x
		value = 0
	[]
	[tension_force_right]
		type = NeumannBC
		variable = disp_x
		boundary = right
		value = 5e7
	[]
[]

[Preconditioning]
	[SMP]
		type = SMP
		full = true
	[]
[]

[Executioner]
	type = Steady
	solve_type = 'NEWTON'
	nl_rel_tol = 1e-8
  	nl_abs_tol = 1e-10
[]

[Outputs]
	exodus = true
	csv = true
[]

[Postprocessors]
	[max_displacement]
		type = NodalExtremeValue
		variable = disp_x
	[]

	[max_stress]
		type = ElementExtremeValue
		variable = stress_xx
	[]

	[avg_strain]
		type = ElementAverageValue
		variable = strain_xx
	[]
[]


# 简化版 MOOSE 测试输入文件
# 适配旧版 MOOSE 语法

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [file]
    type = FileMeshGenerator
    file = cantilever_beam.msh
  []
[]

[Variables]
  [temperature]
    initial_condition = 300
  []
[]

[Kernels]
  [heat_conduction]
    type = HeatConduction
    variable = temperature
  []
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_zz vonmises_stress'
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
    poissons_ratio = 0.3
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
  
  [thermal_props]
    type = GenericConstantMaterial
    prop_names = 'thermal_conductivity density specific_heat'
    prop_values = '45.0 7850.0 500.0'
  []
[]

[BCs]
  [fix_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'fixed_end'
    value = 0
  []
  [fix_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'fixed_end'
    value = 0
  []
  [fix_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'fixed_end'
    value = 0
  []
  
  [temp_fixed]
    type = DirichletBC
    variable = temperature
    boundary = 'fixed_end'
    value = 350
  []
  
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    factor = 1e6
  []
[]

[AuxVariables]
  [von_mises]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [von_mises_kernel]
    type = RankTwoScalarAux
    variable = von_mises
    rank_two_tensor = stress
    scalar_type = VonMisesStress
    execute_on = timestep_end
  []
[]

[Postprocessors]
  [max_disp_z]
    type = NodalExtremeValue
    variable = disp_z
    value_type = min
  []
  
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises
    value_type = max
  []
  
  [max_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = max
  []
  
  [num_nodes]
    type = NumNodes
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
  
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
  
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
  l_tol = 1e-5
[]

[Outputs]
  [exodus]
    type = Exodus
    file_base = moose_result
  []
  [csv]
    type = CSV
    file_base = moose_result
  []
  [console]
    type = Console
  []
[]

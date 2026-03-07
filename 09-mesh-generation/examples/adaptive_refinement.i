# 自适应网格细化示例
# 演示基于误差指示器的自适应细化

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0
    xmax = 10
    ymin = 0
    ymax = 5
    nx = 10  # 初始粗网格
    ny = 5
    elem_type = QUAD4
  []
  
  # 均匀细化以提供更好的初始网格
  uniform_refine = 1
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    planar_formulation = WEAK_PLANE_STRESS
    add_variables = true
    generate_output = 'stress_xx stress_yy vonmises_stress'
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
  []
[]

[Functions]
  # 空间变化的压力载荷，产生高应力梯度
  [pressure_function]
    type = ParsedFunction
    expression = '1e6 * exp(-((x-5)^2 + (y-2.5)^2))'
  []
[]

[BCs]
  # 固定左边
  [fix_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  []
  
  [fix_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'left'
    value = 0
  []
  
  # 顶部压力载荷
  [pressure_top]
    type = Pressure
    variable = disp_y
    boundary = 'top'
        function = pressure_function
  []
[]

[Adaptivity]
  marker = error_marker
  max_h_level = 4  # 最多细化 4 次
  initial_steps = 2  # 初始执行 2 次细化
  
  [Indicators]
    # 基于应力梯度的误差指示器
    [stress_indicator]
      type = GradientJumpIndicator
      variable = vonmises_stress
    []
  []
  
  [Markers]
    # 标记需要细化/粗化的单元
    [error_marker]
      type = ErrorFractionMarker
      indicator = stress_indicator
      refine = 0.7   # 细化误差最大的 70%
      coarsen = 0.1  # 粗化误差最小的 10%
    []
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
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises
    value_type = max
  []
  
  [num_elements]
    type = NumElements
  []
  
  [num_dofs]
    type = NumDOFs
  []
  
  [h_max]
    type = AverageElementSize
    execute_on = 'initial timestep_end'
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
  l_max_its = 100
[]

[Outputs]
  [exodus]
    type = Exodus
    file_base = adaptive_refinement_out
    # 输出每次细化的结果
    execute_on = 'initial timestep_end'
  []
  
  [csv]
    type = CSV
    file_base = adaptive_refinement_out
  []
  
  [console]
    type = Console
    # perf_log deprecated
  []
[]

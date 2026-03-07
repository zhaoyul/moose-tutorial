# 完整的后处理示例
# 演示各种 Postprocessors 和 VectorPostprocessors

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 2.0
    ymin = 0
    ymax = 0.2
    zmin = 0
    zmax = 0.3
    nx = 40
    ny = 4
    nz = 6
    elem_type = HEX8
  []
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_zz stress_xy stress_xz stress_yz vonmises_stress'
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
  
  [density]
    type = GenericConstantMaterial
    prop_names = 'density'
    prop_values = '7850'
  []
[]

[Functions]
  [pressure_ramp]
    type = PiecewiseLinear
    x = '0   1   2'
    y = '0  1e6  1e6'
  []
[]

[BCs]
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
  
  [fix_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'left'
    value = 0
  []
  
  [pressure]
    type = Pressure
    variable = disp_z
    boundary = 'front'
        function = pressure_ramp
  []
[]

[AuxVariables]
  [von_mises]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [strain_energy_density]
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
  
  [strain_energy_kernel]
    type = RankTwoScalarAux
    variable = strain_energy_density
    rank_two_tensor = stress
    # scalar_type = VonMisesStress
    execute_on = timestep_end
  []
[]

[Postprocessors]
  # ============ 位移极值 ============
  [max_disp_x]
    type = NodalExtremeValue
    variable = disp_x
    value_type = max
  []
  
  [max_disp_y]
    type = NodalExtremeValue
    variable = disp_y
    value_type = max
  []
  
  [max_disp_z]
    type = NodalExtremeValue
    variable = disp_z
    value_type = max
  []
  
  [min_disp_z]
    type = NodalExtremeValue
    variable = disp_z
    value_type = min
  []
  
  # ============ 应力极值 ============
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises
    value_type = max
  []
  
  [max_stress_xx]
    type = ElementExtremeValue
    variable = stress_xx
    value_type = max
  []
  
  [max_stress_yy]
    type = ElementExtremeValue
    variable = stress_yy
    value_type = max
  []
  
  [max_stress_zz]
    type = ElementExtremeValue
    variable = stress_zz
    value_type = max
  []
  
  # ============ 平均值 ============
  [avg_von_mises]
    type = ElementAverageValue
    variable = von_mises
  []
  
  [avg_disp_z]
    type = ElementAverageValue
    variable = disp_z
  []
  
  # ============ 反力 ============
  [reaction_force_x]
    type = SidesetReaction
    variable = disp_x
    boundary = 'left'
    direction = '1 0 0'
    stress_tensor = stress
  []
  
  [reaction_force_y]
    type = SidesetReaction
    variable = disp_y
    boundary = 'left'
    direction = '0 1 0'
    stress_tensor = stress
  []
  
  [reaction_force_z]
    type = SidesetReaction
    variable = disp_z
    boundary = 'left'
    direction = '0 0 1'
    stress_tensor = stress
  []
  
  # 总反力
  [total_reaction]
    type = ParsedPostprocessor
    pp_names = 'reaction_force_x reaction_force_y reaction_force_z'
    expression = 'sqrt(reaction_force_x^2 + reaction_force_y^2 + reaction_force_z^2)'
  []
  
  # ============ 能量 ============
  [strain_energy]
    type = ElementIntegralVariablePostprocessor
    variable = strain_energy_density
  []
  
  # ============ 网格信息 ============
  [num_nodes]
    type = NumNodes
  []
  
  [num_elems]
    type = NumElements
  []
  
  [num_dofs]
    type = NumDOFs
  []
  
  # ============ 组合计算 ============
  # 安全系数（假设屈服应力 250 MPa）
  [safety_factor]
    type = ParsedPostprocessor
    pp_names = 'max_von_mises'
    constant_names = 'yield_stress'
    constant_expressions = '250e6'
    expression = 'yield_stress / max_von_mises'
  []
[]

[VectorPostprocessors]
  # ============ 线采样 ============
  # 沿梁长度中心线
  [centerline]
    type = LineValueSampler
    variable = 'disp_x disp_y disp_z stress_xx stress_zz von_mises'
    start_point = '0 0.1 0.15'
    end_point = '2.0 0.1 0.15'
    num_points = 100
    sort_by = x
  []
  
  # 沿高度方向（固定端）
  [height_profile]
    type = LineValueSampler
    variable = 'stress_xx stress_yy stress_zz'
    start_point = '0 0.1 0'
    end_point = '0 0.1 0.3'
    num_points = 50
    sort_by = z
  []
  
  # ============ 边界采样 ============
  # 顶面节点值
  [top_surface]
    type = NodalValueSampler
    variable = 'disp_x disp_y disp_z'
    boundary = 'front'
    sort_by = id
  []
  
  # ============ 点采样（时间历史）============
  [key_points]
    type = PointValueSampler
    variable = 'disp_z von_mises'
    points = '0.5 0.1 0.15
              1.0 0.1 0.15
              1.5 0.1 0.15
              2.0 0.1 0.15'
    sort_by = id
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
  solve_type = 'NEWTON'
  
  start_time = 0.0
  end_time = 2.0
  dt = 0.1
  
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
    file_base = complete_postprocessing_out
    interval = 5  # 每 5 步输出 Exodus
  []
  
  [csv]
    type = CSV
    file_base = complete_postprocessing_out
    # CSV 每步都输出
  []
  
  [console]
    type = Console
    # perf_log deprecated
    # 显示关键后处理器
    show = 'max_von_mises max_disp_z reaction_force_z'
  []
[]

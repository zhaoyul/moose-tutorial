# ============================================================================
# 使用 Gmsh 网格的完整仿真
# ============================================================================
# 本输入文件配合 Gmsh 生成的网格使用
# 物理组名称:
#   - beam_volume: 梁体积 (材料应用)
#   - fixed_end: 固定端 (x=0)
#   - free_end: 自由端 (x=L)
#   - top: 顶面 (z=H)
#   - bottom: 底面 (z=0)
#   - front: 前面 (y=W)
#   - back: 后面 (y=0)
#   - loading_point: 加载点 (中点)
# ============================================================================

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

# ============================================================================
# 网格 - 使用 Gmsh 生成的文件
# ============================================================================
[Mesh]
  [file]
    type = FileMeshGenerator
    file = cantilever_beam.msh
    # Gmsh 物理组会自动转换为边界名称
  []
  
  # 如果需要在 MOOSE 中进一步处理网格，可以添加其他生成器
  # 例如: 侧边界面标记等
[]

# ============================================================================
# 变量定义 - 温度场
# ============================================================================
[Variables]
  [temperature]
    initial_condition = 300  # K
  []
[]

# ============================================================================
# 力学分析模块
# ============================================================================
[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    add_variables = true
    eigenstrain_names = 'thermal_strain'
    generate_output = 'stress_xx stress_yy stress_zz stress_xy stress_xz stress_yz vonmises_stress strain_xx strain_yy strain_zz'
  []
[]

# ============================================================================
# 热传导分析
# ============================================================================
[Kernels]
  [heat_conduction]
    type = HeatConduction
    variable = temperature
  []
  
  [heat_source]
    type = HeatSource
    variable = temperature
    value = 5e5  # W/m³
  []
[]

# ============================================================================
# 函数定义
# ============================================================================
[Functions]
  # 压力随时间加载
  [pressure_ramp]
    type = PiecewiseLinear
    x = '0   1   2   5'
    y = '0  2e6  2e6  2e6'
  []
  
  # 温度随时间变化
  [temp_ramp]
    type = PiecewiseLinear
    x = '0   5'
    y = '300 400'
  []
  
  # 温度相关杨氏模量
  [E_function]
    type = ParsedFunction
    expression = '200e9 * (1.0 - 2.5e-4 * (T - 300))'
    symbol_names = 'T'
    symbol_values = 'temperature'
  []
  
  # 温度相关热膨胀系数
  [alpha_function]
    type = ParsedFunction
    expression = '1.2e-5 + 2.0e-8 * (T - 300)'
    symbol_names = 'T'
    symbol_values = 'temperature'
  []
[]

# ============================================================================
# 材料属性
# ============================================================================
[Materials]
  # 只在 beam_volume 区域应用材料
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus_function = E_function
    poissons_ratio = 0.3
    block = 'beam_volume'
  []
  
  [stress]
    type = ComputeLinearElasticStress
    block = 'beam_volume'
  []
  
  [thermal_expansion_prop]
    type = GenericFunctionMaterial
    prop_names = 'thermal_expansion_coeff'
    prop_values = 'alpha_function'
    block = 'beam_volume'
  []
  
  [thermal_strain]
    type = ComputeThermalExpansionEigenstrain
    temperature = temperature
    thermal_expansion_coeff = thermal_expansion_coeff
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
    block = 'beam_volume'
  []
  
  [thermal_props]
    type = GenericConstantMaterial
    prop_names = 'thermal_conductivity specific_heat density'
    prop_values = '45.0     500.0         7850.0'
    block = 'beam_volume'
  []
[]

# ============================================================================
# 边界条件 - 使用 Gmsh 物理组名称
# ============================================================================
[BCs]
  # ========== 力学固定约束 ==========
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
  
  # ========== 温度边界条件 ==========
  [temp_fixed]
    type = FunctionDirichletBC
    variable = temperature
    boundary = 'fixed_end'
    function = temp_ramp
  []
  
  [temp_convection]
    type = ConvectiveFluxBC
    variable = temperature
    boundary = 'free_end'
    T_infinity = 300
    heat_transfer_coefficient = 50
  []
  
  # ========== 压力载荷（顶面） ==========
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'top'
        function = pressure_ramp
  []
  
  # ========== 剪切载荷（前面） ==========
  [shear_front]
    type = Pressure
    variable = disp_y
    boundary = 'front'
        factor = 1e6
  []
[]

# ============================================================================
# 集中力与体积力
# ============================================================================
[NodalKernels]
  # 加载点集中力
  [point_load]
    type = ConstantRate
    variable = disp_z
    boundary = 'loading_point'
    rate = -10000  # -10 kN
  []
[]

[Kernels]
  # 重力载荷
  [gravity_x]
    type = Gravity
    variable = disp_x
    value = 0
  []
  
  [gravity_y]
    type = Gravity
    variable = disp_y
    value = 0
  []
  
  [gravity_z]
    type = Gravity
    variable = disp_z
    value = -9.81
  []
[]

# ============================================================================
# 辅助变量
# ============================================================================
[AuxVariables]
  [von_mises]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [strain_energy_density]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [E_aux]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [alpha_aux]
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
    execute_on = 'initial timestep_end'
  []
  
  [strain_energy_kernel]
    type = RankTwoScalarAux
    variable = strain_energy_density
    rank_two_tensor = stress
    # scalar_type = VonMisesStress
    execute_on = 'initial timestep_end'
  []
  
  [E_kernel]
    type = MaterialRealAux
    variable = E_aux
    property = youngs_modulus
    execute_on = 'initial timestep_end'
  []
  
  [alpha_kernel]
    type = MaterialRealAux
    variable = alpha_aux
    property = thermal_expansion_coeff
    execute_on = 'initial timestep_end'
  []
[]

# ============================================================================
# Postprocessors
# ============================================================================
[Postprocessors]
  # 位移
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
  
  [free_end_disp_z]
    type = NodalExtremeValue
    variable = disp_z
    boundary = 'free_end'
    value_type = min
  []
  
  # 应力
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
  
  [avg_von_mises]
    type = ElementAverageValue
    variable = von_mises
  []
  
  # 温度
  [max_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = max
  []
  
  [avg_temperature]
    type = ElementAverageValue
    variable = temperature
  []
  
  # 反力
  [reaction_x]
    type = SidesetReaction
    direction = "0 0 1"
    stress_tensor = stress
    variable = disp_x
    boundary = 'fixed_end'
  []
  
  [reaction_y]
    type = SidesetReaction
    direction = "0 0 1"
    stress_tensor = stress
    variable = disp_y
    boundary = 'fixed_end'
  []
  
  [reaction_z]
    type = SidesetReaction
    direction = "0 0 1"
    stress_tensor = stress
    variable = disp_z
    boundary = 'fixed_end'
  []
  
  [total_reaction]
    type = ParsedPostprocessor
    pp_names = 'reaction_x reaction_y reaction_z'
    expression = 'sqrt(reaction_x^2 + reaction_y^2 + reaction_z^2)'
  []
  
  # 能量
  [strain_energy]
    type = ElementIntegralVariablePostprocessor
    variable = strain_energy_density
  []
  
  # 网格信息
  [num_nodes]
    type = NumNodes
  []
  
  [num_elems]
    type = NumElements
  []
  
  # 工程计算
  [safety_factor]
    type = ParsedPostprocessor
    pp_names = 'max_von_mises'
    constant_names = 'yield_stress'
    constant_expressions = '250e6'
    expression = 'yield_stress / max_von_mises'
  []
  

  
  [avg_E]
    type = ElementAverageValue
    variable = E_aux
  []
[]

# ============================================================================
# VectorPostprocessors
# ============================================================================
[VectorPostprocessors]
  # 沿梁长度中心线采样
  [centerline]
    type = LineValueSampler
    variable = 'disp_x disp_y disp_z stress_xx stress_yy stress_zz von_mises temperature E_aux'
    start_point = '0 0.1 0.15'
    end_point = '2.0 0.1 0.15'
    num_points = 100
    sort_by = x
  []
  
  # 高度方向采样（固定端）
  [height_profile_fixed]
    type = LineValueSampler
    variable = 'stress_xx stress_yy stress_zz von_mises'
    start_point = '0 0.1 0'
    end_point = '0 0.1 0.3'
    num_points = 30
    sort_by = z
  []
  
  # 高度方向采样（自由端）
  [height_profile_free]
    type = LineValueSampler
    variable = 'stress_xx stress_yy stress_zz von_mises'
    start_point = '2.0 0.1 0'
    end_point = '2.0 0.1 0.3'
    num_points = 30
    sort_by = z
  []
  
  # 关键点时间历史
  [key_points]
    type = PointValueSampler
    variable = 'disp_z von_mises temperature stress_xx'
    points = '0.5 0.1 0.15
              1.0 0.1 0.15
              1.5 0.1 0.15
              2.0 0.1 0.15'
    sort_by = id
  []
[]

# ============================================================================
# 求解器设置
# ============================================================================
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
  end_time = 5.0
  dt = 0.1
  
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.1
    optimal_iterations = 8
    iteration_window = 2
    growth_factor = 1.2
    cutback_factor = 0.5
  []
  
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre boomeramg 101'
  
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
  l_tol = 1e-5
  l_max_its = 100
  nl_max_its = 15
  
  line_search = 'none'
[]

# ============================================================================
# 输出设置
# ============================================================================
[Outputs]
  [exodus]
    type = Exodus
    file_base = gmsh_simulation_out
    interval = 5
    elemental_as_nodal = true
  []
  
  [csv]
    type = CSV
    file_base = gmsh_simulation_out
  []
  
  [console]
    type = Console
    # perf_log deprecated
    show = 'max_von_mises max_disp_z min_disp_z safety_factor max_temperature'
  []
  
  [checkpoint]
    type = Checkpoint
    num_files = 2
    interval = 50
  []
[]

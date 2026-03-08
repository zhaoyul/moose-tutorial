# ============================================================================
# 完整仿真流程示例 - 受复合载荷的悬臂梁
# ============================================================================
# 本示例整合：
# - 完整的网格生成与标记
# - 温度-力学耦合分析
# - 多种边界条件（固定、压力、集中力、重力）
# - 温度相关材料属性
# - 全面的后处理（Postprocessors + VectorPostprocessors）
# - 多格式输出（Exodus + CSV）
# ============================================================================

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

# ============================================================================
# 网格生成
# ============================================================================
[Mesh]
  # 基础网格
  [generated]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 2.0      # 长度 2 m
    ymin = 0
    ymax = 0.2      # 宽度 0.2 m
    zmin = 0
    zmax = 0.3      # 高度 0.3 m
    nx = 40         # x方向网格
    ny = 4          # y方向网格
    nz = 6          # z方向网格
    elem_type = HEX8
  []
  
  # 创建固定端边界标记
  [fixed_end]
    type = BoundingBoxNodeSetGenerator
    input = generated
    new_boundary = 'fixed_end'
    bottom_left = '-0.01 0 0'
    top_right = '0.01 0.2 0.3'
  []
  
  # 创建自由端边界标记
  [free_end]
    type = BoundingBoxNodeSetGenerator
    input = fixed_end
    new_boundary = 'free_end'
    bottom_left = '1.99 0 0'
    top_right = '2.01 0.2 0.3'
  []
  
  # 创建中点节点集（用于集中力）
  [midpoint]
    type = BoundingBoxNodeSetGenerator
    input = free_end
    new_boundary = 'midpoint'
    bottom_left = '0.99 0.09 0.29'
    top_right = '1.01 0.11 0.31'
  []
[]

# ============================================================================
# 变量定义
# ============================================================================
[Variables]
  # 温度场（初始条件：室温）
  [temperature]
    initial_condition = 300
  []
[]

# ============================================================================
# 力学分析模块（Tensor Mechanics）
# ============================================================================
[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    add_variables = true
    temperature = temperature
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
    value = 5e5         # 内部热源 5e5 W/m³
  []
[]

# ============================================================================
# 函数定义（时间/空间相关载荷）
# ============================================================================
[Functions]
  # 压力随时间加载函数
  [pressure_ramp]
    type = PiecewiseLinear
    x = '0   1   2   5'
    y = '0  2e6  2e6  2e6'    # 最终压力 2 MPa
  []
  
  # 温度随时间变化
  [temp_ramp]
    type = PiecewiseLinear
    x = '0   5'
    y = '300 400'             # 从 300K 升温到 400K
  []
  
[]

# ============================================================================
# 材料属性
# ============================================================================
[Materials]
  # 温度相关弹性张量
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
    poissons_ratio = 0.3
  []
  
  # 应力计算
  [stress]
    type = ComputeLinearElasticStress
  []
  
  # 热特征应变
  [thermal_strain]
    type = ComputeThermalExpansionEigenstrain
    temperature = temperature
    thermal_expansion_coeff = 1.2e-5
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
  []
  
  # 热传导属性
  [thermal_props]
    type = GenericConstantMaterial
    prop_names = 'youngs_modulus thermal_expansion_coeff thermal_conductivity specific_heat density'
    prop_values = '200e9 1.2e-5 45.0 500.0 7850.0'
  []
[]

# ============================================================================
# 边界条件
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
    boundary = 'right'
    initial = 300
    final = 300
    rate = 50
  []
  
  # ========== 压力载荷（顶面） ==========
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'front'
        function = pressure_ramp
  []
  
  # ========== 剪切载荷（侧面） ==========
  [shear_side]
    type = Pressure
    variable = disp_y
    boundary = 'right'
        factor = 1e6
  []
[]

# ============================================================================
# 集中力与体积力
# ============================================================================
[NodalKernels]
  # 中点集中力
  [point_load]
    type = ConstantRate
    variable = disp_z
    boundary = 'midpoint'
    rate = -10000       # -10 kN 向下
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
# 辅助变量（用于后处理）
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
    scalar_type = FirstInvariant
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
# Postprocessors（标量结果提取）
# ============================================================================
[Postprocessors]
  # ========== 位移极值 ==========
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
  
  # 自由端最大位移
  [free_end_disp_z]
    type = NodalExtremeValue
    variable = disp_z
    boundary = 'free_end'
    value_type = min
  []
  
  # ========== 应力极值 ==========
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
  
  # ========== 应力平均值 ==========
  [avg_von_mises]
    type = ElementAverageValue
    variable = von_mises
  []
  
  # ========== 温度 ==========
  [max_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = max
  []
  
  [avg_temperature]
    type = ElementAverageValue
    variable = temperature
  []
  
  # ========== 反力 ==========
  [reaction_x]
    type = SidesetReaction
    direction = "1 0 0"
    stress_tensor = stress
    boundary = 'left'
  []
  
  [reaction_y]
    type = SidesetReaction
    direction = "0 1 0"
    stress_tensor = stress
    boundary = 'left'
  []
  
  [reaction_z]
    type = SidesetReaction
    direction = "0 0 1"
    stress_tensor = stress
    boundary = 'left'
  []
  
  # 总反力
  [total_reaction]
    type = ParsedPostprocessor
    pp_names = 'reaction_x reaction_y reaction_z'
    enable_jit = false
    expression = 'sqrt(reaction_x^2 + reaction_y^2 + reaction_z^2)'
  []
  
  # ========== 能量 ==========
  [strain_energy]
    type = ElementIntegralVariablePostprocessor
    variable = strain_energy_density
  []
  

  # ========== 材料属性平均 ==========
  [avg_E]
    type = ElementAverageValue
    variable = E_aux
  []
  
  [avg_alpha]
    type = ElementAverageValue
    variable = alpha_aux
  []
  
  # ========== 网格信息 ==========
  [num_nodes]
    type = NumNodes
  []
  
  [num_elems]
    type = NumElements
  []
  
  [num_dofs]
    type = NumDOFs
  []
  
  [dt]
    type = TimestepSize
  []
  
  # ========== 工程计算 ==========
  # 安全系数（假设屈服应力 250 MPa）
  [safety_factor]
    type = ParsedPostprocessor
    pp_names = 'max_von_mises'
    constant_names = 'yield_stress'
    constant_expressions = '250e6'
    enable_jit = false
    expression = 'yield_stress / max_von_mises'
  []
  
  # 刚度变化百分比
  [E_reduction]
    type = ParsedPostprocessor
    pp_names = 'avg_E'
    enable_jit = false
    expression = '(1.0 - avg_E / 200e9) * 100'
  []
[]

# ============================================================================
# VectorPostprocessors（向量/矩阵结果提取）
# ============================================================================
[VectorPostprocessors]
  # ========== 沿梁长度中心线采样 ==========
  [centerline]
    type = LineValueSampler
    variable = 'disp_x disp_y disp_z stress_xx stress_yy stress_zz von_mises temperature E_aux'
    start_point = '0 0.1 0.15'
    end_point = '2.0 0.1 0.15'
    num_points = 100
    sort_by = x
  []
  
  # ========== 沿高度方向采样（固定端） ==========
  [height_profile_fixed]
    type = LineValueSampler
    variable = 'stress_xx stress_yy stress_zz von_mises'
    start_point = '0 0.1 0'
    end_point = '0 0.1 0.3'
    num_points = 30
    sort_by = z
  []
  
  # ========== 沿高度方向采样（自由端） ==========
  [height_profile_free]
    type = LineValueSampler
    variable = 'stress_xx stress_yy stress_zz von_mises'
    start_point = '2.0 0.1 0'
    end_point = '2.0 0.1 0.3'
    num_points = 30
    sort_by = z
  []
  
  # ========== 顶面节点值 ==========
  [top_surface]
    type = NodalValueSampler
    variable = 'disp_x disp_y disp_z'
    boundary = 'front'
    sort_by = id
  []
  
  # ========== 自由端节点值 ==========
  [free_end_nodes]
    type = NodalValueSampler
    variable = 'disp_x disp_y disp_z temperature'
    boundary = 'free_end'
    sort_by = id
  []
  
  # ========== 关键点时间历史 ==========
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
# 预处理器设置
# ============================================================================
[Preconditioning]
  [SMP]
    type = SMP
    full = true
  []
[]

# ============================================================================
# 求解器设置
# ============================================================================
[Executioner]
  type = Transient
  solve_type = 'NEWTON'
  
  # 时间步进
  start_time = 0.0
  end_time = 5.0
  dt = 0.1
  
  # 自适应时间步长
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.1
    optimal_iterations = 8
    iteration_window = 2
    growth_factor = 1.2
    cutback_factor = 0.5
  []
  
  # PETSc 求解选项
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  
  # 收敛准则
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
  l_tol = 1e-5
  l_max_its = 100
  nl_max_its = 15
[]

# ============================================================================
# 输出设置
# ============================================================================
[Outputs]
  # Exodus 格式（用于 Paraview 可视化）
  [exodus]
    type = Exodus
    file_base = complete_simulation_out
    time_step_interval = 5
    elemental_as_nodal = true
    execute_on = 'initial timestep_end'
  []
  
  # CSV 格式（用于 Python 后处理）
  [csv]
    type = CSV
    file_base = complete_simulation_out
    execute_on = 'initial timestep_end'
  []
  
  # 控制台输出
  [console]
    type = Console
    # perf_log deprecated
    output_linear = false
    output_nonlinear = false
    # 显示关键后处理器
    show = 'max_von_mises max_disp_z min_disp_z safety_factor max_temperature'
  []
  
  # 检查点（用于重启）
  [checkpoint]
    type = Checkpoint
    num_files = 2
    time_step_interval = 50
  []
[]

[Problem]
  register_objects_from = 'SolidMechanicsApp HeatTransferApp'
  library_path = '/Users/kevinli/sandbox/rc/projects/moose/modules/solid_mechanics/lib:/Users/kevinli/sandbox/rc/projects/moose/modules/heat_transfer/lib'
[]

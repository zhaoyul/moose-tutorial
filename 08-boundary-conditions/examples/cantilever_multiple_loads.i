# 多载荷组合悬臂梁分析
# 演示各种边界条件和载荷类型的组合使用

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 2.0    # 2 m 长
    ymin = 0
    ymax = 0.2    # 0.2 m 宽
    zmin = 0
    zmax = 0.3    # 0.3 m 高
    nx = 40
    ny = 4
    nz = 6
    elem_type = HEX8
  []
  
  # 创建中点节点集用于集中力
  [midpoint]
    type = BoundingBoxNodeSetGenerator
    input = generated
    new_boundary = 'midpoint'
    bottom_left = '0.99 0.09 0.29'
    top_right = '1.01 0.11 0.31'
  []
[]

[Modules/TensorMechanics/Master]
  [all]
    strain = SMALL
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_zz vonmises_stress strain_xx strain_yy strain_zz'
  []
[]

[Materials]
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9  # 钢
    poissons_ratio = 0.3
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
  
  [density]
    type = GenericConstantMaterial
    prop_names = 'density'
    prop_values = '7850'  # kg/m³
  []
[]

[Functions]
  # 时间相关压力载荷
  [pressure_ramp]
    type = PiecewiseLinear
    x = '0   1   2'
    y = '0  1e6  1e6'  # 从 0 增加到 1 MPa
  []
  
  # 空间变化的分布载荷
  [distributed_load]
    type = ParsedFunction
    expression = 'q0 * sin(pi * x / L)'
    symbol_names = 'q0   L'
    symbol_values = '1000 2.0'  # N/m
  []
[]

[BCs]
  # ============ 固定约束（左端） ============
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
  
  # ============ 压力载荷（顶面，时间相关） ============
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'front'
    component = 2
    function = pressure_ramp
  []
  
  # ============ 剪切载荷（右端面） ============
  [shear_right_y]
    type = Pressure
    variable = disp_y
    boundary = 'right'
    component = 1
    factor = 5e5  # 0.5 MPa 剪切
  []
  
  # ============ 弹性支承（底面） ============
  [elastic_support]
    type = LinearElasticBC
    variable = disp_z
    boundary = 'back'
    stiffness = 1e7  # N/m
  []
[]

[NodalKernels]
  # ============ 集中力（中点） ============
  [point_load]
    type = ConstantRate
    variable = disp_z
    boundary = 'midpoint'
    rate = -5000  # -5000 N 向下
  []
[]

[Kernels]
  # ============ 重力载荷 ============
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
    value = -9.81  # m/s²
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
  # ============ 位移监测 ============
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
  
  # ============ 应力监测 ============
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
  
  # ============ 反力计算 ============
  [reaction_x]
    type = SidesetReaction
    variable = disp_x
    boundary = 'left'
  []
  
  [reaction_y]
    type = SidesetReaction
    variable = disp_y
    boundary = 'left'
  []
  
  [reaction_z]
    type = SidesetReaction
    variable = disp_z
    boundary = 'left'
  []
  
  # ============ 应变能 ============
  [strain_energy]
    type = StrainEnergy
  []
[]

[VectorPostprocessors]
  # 沿梁长度方向采样
  [centerline_data]
    type = LineValueSampler
    variable = 'disp_x disp_y disp_z stress_xx stress_zz von_mises'
    start_point = '0 0.1 0.15'
    end_point = '2.0 0.1 0.15'
    num_points = 100
    sort_by = x
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
  
  # 时间步进设置
  start_time = 0.0
  end_time = 2.0
  dt = 0.1
  
  petsc_options_iname = '-pc_type -pc_hypre_type -ksp_gmres_restart'
  petsc_options_value = 'hypre boomeramg 101'
  
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
  l_tol = 1e-5
  l_max_its = 100
[]

[Outputs]
  [exodus]
    type = Exodus
    file_base = cantilever_multiple_loads_out
    interval = 5
  []
  
  [csv]
    type = CSV
    file_base = cantilever_multiple_loads_out
  []
  
  [console]
    type = Console
    perf_log = true
  []
[]

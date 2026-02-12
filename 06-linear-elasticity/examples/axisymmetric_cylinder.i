# 轴对称厚壁圆筒承受内压
# 验证 Lamé 解析解

[Problem]
  coord_type = RZ  # 轴对称坐标系
[]

[GlobalParams]
  displacements = 'disp_x disp_y'  # r 和 z 方向
[]

[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0.05   # 内半径 50 mm
    xmax = 0.1    # 外半径 100 mm
    ymin = 0
    ymax = 0.5    # 长度 500 mm
    nx = 30
    ny = 100
    elem_type = QUAD4
  []
[]

[Modules/TensorMechanics/Master]
  [all]
    strain = SMALL
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_zz vonmises_stress'
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9  # 200 GPa
    poissons_ratio = 0.3
  []
  
  [strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y'
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]

[BCs]
  # 固定底端 z 方向位移
  [fix_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  []
  
  # 内表面压力 10 MPa
  [internal_pressure]
    type = Pressure
    variable = disp_x
    boundary = 'left'
    component = 0  # 径向
    factor = 10e6  # 10 MPa
  []
[]

[AuxVariables]
  [von_mises]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [hoop_stress]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [radial_stress]
    order = CONSTANT
    family = MONOMIAL
  []
  
  # Lamé 解析解
  [sigma_r_analytical]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [sigma_theta_analytical]
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
  
  # 环向应力（轴对称中为 stress_zz）
  [hoop_stress_kernel]
    type = RankTwoAux
    variable = hoop_stress
    rank_two_tensor = stress
    index_i = 2
    index_j = 2
    execute_on = timestep_end
  []
  
  # 径向应力（轴对称中为 stress_xx）
  [radial_stress_kernel]
    type = RankTwoAux
    variable = radial_stress
    rank_two_tensor = stress
    index_i = 0
    index_j = 0
    execute_on = timestep_end
  []
  
  # Lamé 解析解 - 径向应力
  [sigma_r_analytical_kernel]
    type = ParsedAux
    variable = sigma_r_analytical
    expression = 'a2*Pi*(b2-r2)/(b2-a2)/r2'
    constant_names = 'a2 b2 Pi'
    constant_expressions = '0.0025 0.01 10e6'  # a^2, b^2, 内压
    coupled_variables = 'r2'
    execute_on = timestep_end
  []
  
  # Lamé 解析解 - 环向应力
  [sigma_theta_analytical_kernel]
    type = ParsedAux
    variable = sigma_theta_analytical
    expression = 'a2*Pi*(b2+r2)/(b2-a2)/r2'
    constant_names = 'a2 b2 Pi'
    constant_expressions = '0.0025 0.01 10e6'
    coupled_variables = 'r2'
    execute_on = timestep_end
  []
  
  # 辅助变量：r^2
  [r_squared]
    type = ParsedAux
    variable = r2
    expression = 'x*x'
    use_xyzt = true
    execute_on = timestep_end
  []
[]

[AuxVariables]
  [r2]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[Postprocessors]
  # 内表面最大应力
  [max_hoop_stress_inner]
    type = SideAverageValue
    variable = hoop_stress
    boundary = 'left'
  []
  
  # 外表面最大应力
  [max_hoop_stress_outer]
    type = SideAverageValue
    variable = hoop_stress
    boundary = 'right'
  []
  
  # 最大 von Mises 应力
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises
    value_type = max
  []
  
  # 径向位移
  [max_disp_r]
    type = NodalExtremeValue
    variable = disp_x
    value_type = max
  []
[]

[VectorPostprocessors]
  # 沿径向采样
  [radial_profile]
    type = LineValueSampler
    variable = 'radial_stress hoop_stress sigma_r_analytical sigma_theta_analytical'
    start_point = '0.05 0.25 0'
    end_point = '0.1 0.25 0'
    num_points = 50
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
    file_base = axisymmetric_cylinder_out
  []
  
  [csv]
    type = CSV
    file_base = axisymmetric_cylinder_out
  []
  
  [console]
    type = Console
    perf_log = true
  []
[]

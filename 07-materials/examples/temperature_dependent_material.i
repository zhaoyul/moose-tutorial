# 温度相关材料分析
# 模拟一个受热的约束梁

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 1.0    # 1 m
    ymin = 0
    ymax = 0.1    # 0.1 m
    zmin = 0
    zmax = 0.1    # 0.1 m
    nx = 40
    ny = 10
    nz = 10
    elem_type = HEX8
  []
[]

[Variables]
  [temperature]
    initial_condition = 300  # K
  []
[]

[Kernels]
  # 热传导方程
  [heat_conduction]
    type = HeatConduction
    variable = temperature
  []
  
  [heat_source]
    type = HeatSource
    variable = temperature
    value = 1e6  # W/m³
  []
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    add_variables = true
    eigenstrain_names = 'thermal_strain'
    generate_output = 'stress_xx stress_yy stress_zz vonmises_stress'
  []
[]

[Functions]
  # 温度相关杨氏模量
  [youngs_modulus_function]
    type = ParsedFunction
    # E(T) = E0 * (1 - beta * (T - T0))
    expression = '2.0e11 * (1.0 - 5.0e-4 * (T - 300))'
    symbol_names = 'T'
    symbol_values = 'temperature'
  []
  
  # 温度相关热膨胀系数
  [alpha_function]
    type = ParsedFunction
    # alpha(T) = a0 + a1*T
    expression = '1.0e-5 + 1.0e-8 * T'
    symbol_names = 'T'
    symbol_values = 'temperature'
  []
  
  # 温度相关热导率
  [k_function]
    type = ParsedFunction
    expression = '50.0 - 0.01 * (T - 300)'
    symbol_names = 'T'
    symbol_values = 'temperature'
  []
[]

[Materials]
  # 温度相关弹性张量
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus_function = youngs_modulus_function
    poissons_ratio = 0.3
  []
  
  # 应变计算
  [strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  
  # 应力计算
  [stress]
    type = ComputeLinearElasticStress
  []
  
  # 温度相关热膨胀系数
  [thermal_expansion]
    type = GenericFunctionMaterial
    prop_names = 'thermal_expansion_coeff'
    prop_values = 'alpha_function'
  []
  
  # 热特征应变
  [thermal_strain]
    type = ComputeThermalExpansionEigenstrain
    temperature = temperature
    thermal_expansion_coeff = 1.2e-5
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
  []
  
  # 热传导材料属性
  [thermal_conductivity]
    type = GenericFunctionMaterial
    prop_names = 'thermal_conductivity'
    prop_values = 'k_function'
  []
  
  [density]
    type = GenericConstantMaterial
    prop_names = 'density specific_heat'
    prop_values = '7850   500'  # kg/m³, J/(kg·K)
  []
[]

[BCs]
  # 力学边界条件：固定左端
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
  
  # 热边界条件：左端固定温度
  [temp_left]
    type = DirichletBC
    variable = temperature
    boundary = 'left'
    value = 300
  []
  
  # 右端对流散热
  [convection_right]
    type = ConvectiveFluxBC
    variable = temperature
    boundary = 'right'
    T_infinity = 300
    heat_transfer_coefficient = 100  # W/(m²·K)
  []
[]

[AuxVariables]
  [von_mises]
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
    execute_on = timestep_end
  []
  
  # 输出材料属性用于可视化
  [E_kernel]
    type = MaterialRealAux
    variable = E_aux
    property = youngs_modulus
    execute_on = timestep_end
  []
  
  [alpha_kernel]
    type = MaterialRealAux
    variable = alpha_aux
    property = thermal_expansion_coeff
    execute_on = timestep_end
  []
[]

[Postprocessors]
  [max_temp]
    type = NodalExtremeValue
    variable = temperature
    value_type = max
  []
  
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises
    value_type = max
  []
  
  [max_disp_x]
    type = NodalExtremeValue
    variable = disp_x
    value_type = max
  []
  
  [avg_E]
    type = ElementAverageValue
    variable = E_aux
  []
[]

[VectorPostprocessors]
  [centerline_data]
    type = LineValueSampler
    variable = 'temperature stress_xx von_mises E_aux alpha_aux'
    start_point = '0 0.05 0.05'
    end_point = '1.0 0.05 0.05'
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
  type = Steady
  solve_type = 'NEWTON'
  
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
    file_base = temp_dependent_material_out
  []
  
  [csv]
    type = CSV
    file_base = temp_dependent_material_out
  []
  
  [console]
    type = Console
    # perf_log deprecated
  []
[]

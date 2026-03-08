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
    nx = 20
    ny = 6
    nz = 6
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

  [heat_capacity]
    type = SpecificHeatConductionTimeDerivative
    variable = temperature
  []
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    incremental = true
    add_variables = true
    temperature = temperature
    eigenstrain_names = 'thermal_strain'
    generate_output = 'stress_xx stress_yy stress_zz vonmises_stress'
  []
[]

[Functions]
  # 温度相关热膨胀系数，函数自变量是温度
  [alpha_function]
    type = ParsedFunction
    expression = '1.0e-5 + 1.0e-8 * t'
  []

  # 右端温度从室温逐步升高到 600 K
  [right_temperature]
    type = PiecewiseLinear
    x = '0 10'
    y = '300 600'
  []
[]

[Materials]
  [youngs_modulus]
    type = DerivativeParsedMaterial
    property_name = youngs_modulus
    coupled_variables = temperature
    enable_jit = false
    expression = '2.0e11 * (1.0 - 5.0e-4 * (temperature - 300))'
  []

  [poissons_ratio]
    type = DerivativeParsedMaterial
    property_name = poissons_ratio
    coupled_variables = temperature
    enable_jit = false
    expression = '0.3'
  []

  [elasticity_tensor]
    type = ComputeVariableIsotropicElasticityTensor
    youngs_modulus = youngs_modulus
    poissons_ratio = poissons_ratio
    args = temperature
  []
  
  # 应力计算
  [stress]
    type = ComputeFiniteStrainElasticStress
  []

  [thermal_expansion_coeff]
    type = DerivativeParsedMaterial
    property_name = thermal_expansion_coeff
    coupled_variables = temperature
    enable_jit = false
    expression = '1.0e-5 + 1.0e-8 * temperature'
  []
  
  [thermal_strain]
    type = ComputeInstantaneousThermalExpansionFunctionEigenstrain
    temperature = temperature
    thermal_expansion_function = alpha_function
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
  []
  
  [density]
    type = GenericConstantMaterial
    prop_names = 'thermal_conductivity density specific_heat'
    prop_values = '50 7850 500'  # W/(m·K), kg/m³, J/(kg·K)
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
  
  # 右端逐步升温，驱动温度相关材料响应
  [convection_right]
    type = FunctionDirichletBC
    variable = temperature
    boundary = 'right'
    function = right_temperature
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
  type = Transient
  solve_type = 'PJFNK'
  start_time = 0
  end_time = 10.0
  dt = 1.0
  
  petsc_options_iname = '-pc_type'
  petsc_options_value = 'lu'
  
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
  nl_max_its = 30
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

[Problem]
  register_objects_from = 'SolidMechanicsApp HeatTransferApp'
  library_path = '/Users/kevinli/sandbox/rc/projects/moose/modules/solid_mechanics/lib:/Users/kevinli/sandbox/rc/projects/moose/modules/heat_transfer/lib'
[]

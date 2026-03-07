# ============================================================================
# 简化版仿真示例 - 快速测试用
# ============================================================================
# 本示例：
# - 纯力学分析（无热耦合）
# - 简化网格（快速计算）
# - 基础后处理
# ============================================================================

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
    nx = 20         # 简化网格
    ny = 2
    nz = 3
    elem_type = HEX8
  []
  
  [fixed_end]
    type = BoundingBoxNodeSetGenerator
    input = generated
    new_boundary = 'fixed_end'
    bottom_left = '-0.01 0 0'
    top_right = '0.01 0.2 0.3'
  []
  
  [free_end]
    type = BoundingBoxNodeSetGenerator
    input = fixed_end
    new_boundary = 'free_end'
    bottom_left = '1.99 0 0'
    top_right = '2.01 0.2 0.3'
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
  
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'front'
        function = pressure_ramp
  []
[]

[Kernels]
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
    execute_on = 'initial timestep_end'
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
  

  [num_nodes]
    type = NumNodes
  []
  
  [num_elems]
    type = NumElements
  []
[]

[VectorPostprocessors]
  [centerline]
    type = LineValueSampler
    variable = 'disp_z stress_xx von_mises'
    start_point = '0 0.1 0.15'
    end_point = '2.0 0.1 0.15'
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
  type = Transient
  solve_type = 'NEWTON'
  
  start_time = 0.0
  end_time = 2.0
  dt = 0.2
  
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
  
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-10
  l_tol = 1e-5
[]

[Outputs]
  [exodus]
    type = Exodus
    file_base = simple_demo_out
  []
  
  [csv]
    type = CSV
    file_base = simple_demo_out
  []
  
  [console]
    type = Console
    # perf_log deprecated
  []
[]

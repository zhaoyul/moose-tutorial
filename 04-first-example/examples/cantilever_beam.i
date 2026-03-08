# 悬臂梁弹性分析 - 使用力边界条件

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [generated_mesh]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 1.0    # 长度 1 m
    ymin = 0
    ymax = 0.05   # 宽度 0.05 m
    zmin = 0
    zmax = 0.1    # 高度 0.1 m
    nx = 20       # x 方向单元数
    ny = 5        # y 方向单元数
    nz = 10       # z 方向单元数
    elem_type = HEX8
  []
  
  # 创建自由端的节点集
  [free_end]
    type = BoundingBoxNodeSetGenerator
    input = generated_mesh
    new_boundary = 'free_end'
    bottom_left = '0.99 0 0'
    top_right = '1.01 0.05 0.1'
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
    youngs_modulus = 2.0e11  # 200 GPa
    poissons_ratio = 0.3
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]

[BCs]
  # 固定左端
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
[]

[NodalKernels]
  # 在自由端施加集中力
  [force_z]
    type = ConstantRate
    variable = disp_z
    boundary = 'free_end'
    rate = -1000  # -1000 N 向下
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
  
  [num_nodes]
    type = NumNodes
  []
  
  [num_elems]
    type = NumElements
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
    file_base = cantilever_out
  []
  
  [csv]
    type = CSV
    file_base = cantilever_out
  []
  
  [console]
    type = Console
    # perf_log deprecated
  []
[]

[Problem]
  register_objects_from = 'SolidMechanicsApp'
  library_path = '/Users/kevinli/sandbox/rc/projects/moose/modules/solid_mechanics/lib'
[]

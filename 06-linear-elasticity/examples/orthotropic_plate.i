# 正交各向异性复合材料板分析

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 0.1    # 100 mm
    ymin = 0
    ymax = 0.1    # 100 mm
    zmin = 0
    zmax = 0.01   # 10 mm
    nx = 20
    ny = 20
    nz = 4
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
  # 正交各向异性弹性张量 (使用简化各向同性代替)
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 150e9
    poissons_ratio = 0.3
  []
  
  [strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]

[BCs]
  # 固定底面所有自由度
  [fix_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'back'
    value = 0
  []
  
  [fix_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'back'
    value = 0
  []
  
  [fix_z]
    type = DirichletBC
    variable = disp_z
    boundary = 'back'
    value = 0
  []
  
  # 顶面施加均布压力 1 MPa
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'front'
        factor = -1e6  # -1 MPa (向下)
  []
[]

[AuxVariables]
  [von_mises]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [max_principal]
    order = CONSTANT
    family = MONOMIAL
  []
  
  [min_principal]
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
  
  [max_principal_kernel]
    type = RankTwoScalarAux
    variable = max_principal
    rank_two_tensor = stress
    scalar_type = MaxPrincipal
    execute_on = timestep_end
  []
  
  [min_principal_kernel]
    type = RankTwoScalarAux
    variable = min_principal
    rank_two_tensor = stress
    scalar_type = MinPrincipal
    execute_on = timestep_end
  []
[]

[Postprocessors]
  # 最大位移
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
  
  # 最大应力
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises
    value_type = max
  []
  
  [max_stress_zz]
    type = ElementExtremeValue
    variable = stress_zz
    value_type = max
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
    file_base = orthotropic_plate_out
  []
  
  [csv]
    type = CSV
    file_base = orthotropic_plate_out
  []
  
  [console]
    type = Console
    # perf_log deprecated
  []
[]

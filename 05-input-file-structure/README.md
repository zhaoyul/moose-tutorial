# 第五章：MOOSE 输入文件结构详解

## 5.1 输入文件概述

MOOSE 输入文件使用分层的块结构，采用 "GetPot" 格式，文件扩展名通常为 `.i`。

### 5.1.1 基本语法

```cpp
[BlockName]
  parameter1 = value1
  parameter2 = value2
  
  [SubBlock]
    sub_parameter = sub_value
  []
[]
```

### 5.1.2 注释

```cpp
# 这是单行注释

[Mesh]
  type = GeneratedMesh  # 行尾注释
  dim = 3               # 三维网格
[]
```

## 5.2 主要块结构

### 5.2.1 必需块

以下是最小可运行输入文件的必需块：

```cpp
[Mesh]
  # 网格定义
[]

[Variables]
  # 求解变量
[]

[Kernels]
  # 控制方程
[]

[BCs]
  # 边界条件
[]

[Executioner]
  # 求解器设置
[]

[Outputs]
  # 输出控制
[]
```

### 5.2.2 可选但常用的块

```cpp
[Materials]        # 材料属性
[AuxVariables]     # 辅助变量
[AuxKernels]       # 辅助核
[Functions]        # 函数定义
[Postprocessors]   # 后处理器
[Preconditioning]  # 预条件器
[GlobalParams]     # 全局参数
```

## 5.3 GlobalParams 块

定义在多处使用的全局参数，避免重复。

```cpp
[GlobalParams]
  # 在整个输入文件中共享的参数
  displacements = 'disp_x disp_y disp_z'
  order = FIRST
  family = LAGRANGE
[]
```

## 5.4 Mesh 块详解

### 5.4.1 生成网格

```cpp
[Mesh]
  [generated]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 10
    ymin = 0
    ymax = 5
    zmin = 0
    zmax = 2
    nx = 100  # x 方向单元数
    ny = 50
    nz = 20
    elem_type = HEX8  # HEX8, HEX20, HEX27, TET4, TET10, etc.
  []
[]
```

### 5.4.2 导入网格

```cpp
[Mesh]
  type = FileMesh
  file = 'mesh.e'      # Exodus II 格式
  # file = 'mesh.msh'  # Gmsh 格式
  # file = 'mesh.inp'  # Abaqus 格式
[]
```

### 5.4.3 网格修改

```cpp
[Mesh]
  [base_mesh]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 10
    ny = 10
  []
  
  # 细化特定区域
  [refinement]
    type = RefineBlockGenerator
    input = base_mesh
    block = 1
    refinement = 2  # 细化 2 次
  []
  
  # 添加边界
  [new_boundary]
    type = SideSetsBetweenSubdomainsGenerator
    input = refinement
    primary_block = 1
    paired_block = 2
    new_boundary = 'interface'
  []
[]
```

## 5.5 Variables 块详解

### 5.5.1 标准变量定义

```cpp
[Variables]
  [temperature]
    order = FIRST      # CONSTANT, FIRST, SECOND, THIRD, FOURTH
    family = LAGRANGE  # LAGRANGE, MONOMIAL, HERMITE, etc.
    initial_condition = 300  # 初始值
  []
  
  [displacement_x]
    order = SECOND
    family = LAGRANGE
    scaling = 1e-6  # 变量缩放，改善条件数
  []
[]
```

### 5.5.2 向量变量

```cpp
[Variables]
  # 使用 TensorMechanics Master Action 自动创建
  # 或手动定义：
  [disp_x]
  []
  [disp_y]
  []
  [disp_z]
  []
[]
```

## 5.6 Kernels 块详解

### 5.6.1 内置 Kernels

```cpp
[Kernels]
  # 扩散项
  [diffusion]
    type = Diffusion
    variable = temperature
  []
  
  # 时间导数
  [time_derivative]
    type = TimeDerivative
    variable = temperature
  []
  
  # 热源
  [heat_source]
    type = BodyForce
    variable = temperature
    value = 1000  # W/m³
  []
[]
```

### 5.6.2 固体力学 Kernels

```cpp
[Kernels]
  [stress_divergence_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress_divergence_y]
    type = StressDivergenceTensors
    variable = disp_y
    component = 1
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress_divergence_z]
    type = StressDivergenceTensors
    variable = disp_z
    component = 2
    displacements = 'disp_x disp_y disp_z'
  []
[]
```

## 5.7 Materials 块详解

### 5.7.1 材料属性

```cpp
[Materials]
  # 各向同性弹性
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
    poissons_ratio = 0.3
    block = 'steel_block'  # 指定块
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
  
  # 密度
  [density]
    type = GenericConstantMaterial
    prop_names = 'density'
    prop_values = '7850'  # kg/m³
  []
[]
```

### 5.7.2 温度相关材料

```cpp
[Materials]
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    # 使用函数定义温度相关性
    youngs_modulus_function = youngs_modulus_temp
    poissons_ratio = 0.3
  []
[]

[Functions]
  [youngs_modulus_temp]
    type = ParsedFunction
    expression = '2.1e11 * (1 - 0.0005 * (T - 293))'
    symbol_names = 'T'
    symbol_values = 'temperature'
  []
[]
```

## 5.8 BCs 块详解

### 5.8.1 Dirichlet 边界条件

```cpp
[BCs]
  # 固定值
  [fixed]
    type = DirichletBC
    variable = temperature
    boundary = 'left'
    value = 300
  []
  
  # 函数边界条件
  [varying]
    type = FunctionDirichletBC
    variable = disp_x
    boundary = 'right'
    function = 'sin(pi*t)'
  []
  
  # 预设 BC
  [preset]
    type = PresetBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  []
[]
```

### 5.8.2 Neumann 边界条件

```cpp
[BCs]
  # 热通量
  [heat_flux]
    type = NeumannBC
    variable = temperature
    boundary = 'right'
    value = 1000  # W/m²
  []
  
  # 压力载荷
  [pressure]
    type = Pressure
    variable = disp_x
    boundary = 'top'
    component = 0
    factor = 1e6  # Pa
  []
[]
```

### 5.8.3 Robin 边界条件

```cpp
[BCs]
  # 对流边界条件
  [convection]
    type = ConvectiveFluxBC
    variable = temperature
    boundary = 'surface'
    T_infinity = 300
    heat_transfer_coefficient = 100  # W/(m²·K)
  []
[]
```

## 5.9 Executioner 块详解

### 5.9.1 稳态求解器

```cpp
[Executioner]
  type = Steady
  solve_type = 'NEWTON'  # NEWTON, PJFNK, JFNK, FD
  
  # 收敛准则
  nl_rel_tol = 1e-8    # 非线性相对容差
  nl_abs_tol = 1e-10   # 非线性绝对容差
  nl_max_its = 50      # 最大非线性迭代次数
  
  l_tol = 1e-5         # 线性求解器容差
  l_max_its = 100      # 最大线性迭代次数
  
  # PETSc 选项
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
[]
```

### 5.9.2 瞬态求解器

```cpp
[Executioner]
  type = Transient
  solve_type = 'NEWTON'
  
  # 时间步进
  start_time = 0.0
  end_time = 10.0
  dt = 0.1
  
  # 或使用自适应时间步
  [TimeStepper]
    type = IterationAdaptiveDT
    dt = 0.1
    optimal_iterations = 10
    iteration_window = 2
  []
  
  # 时间积分方案
  scheme = 'implicit-euler'  # bdf2, crank-nicolson, etc.
  
  nl_rel_tol = 1e-6
  nl_abs_tol = 1e-8
  l_tol = 1e-4
[]
```

## 5.10 Outputs 块详解

### 5.10.1 基本输出

```cpp
[Outputs]
  exodus = true   # Exodus II 格式
  csv = true      # CSV 格式
  console = true  # 控制台输出
  
  # 输出频率
  interval = 10   # 每 10 步输出一次
  
  # 控制输出精度
  [exodus]
    type = Exodus
    file_base = 'output'
    elemental_as_nodal = true  # 将单元变量转为节点变量
  []
  
  [csv]
    type = CSV
    file_base = 'output'
  []
  
  [console]
    type = Console
    perf_log = true          # 输出性能日志
    output_linear = true     # 输出线性迭代信息
    print_mesh_changed_info = true
  []
[]
```

### 5.10.2 Checkpoint 输出

```cpp
[Outputs]
  # 用于重启计算
  [checkpoint]
    type = Checkpoint
    num_files = 2      # 保留最近两个检查点
    interval = 100     # 每 100 步保存
  []
[]
```

## 5.11 Functions 块详解

### 5.11.1 解析函数

```cpp
[Functions]
  # 解析表达式
  [parsed_function]
    type = ParsedFunction
    expression = 'A * sin(omega * t) * exp(-x/L)'
    symbol_names = 'A omega L'
    symbol_values = '1000 6.28 0.5'
  []
[]
```

### 5.11.2 分段函数

```cpp
[Functions]
  # 分段线性
  [piecewise_linear]
    type = PiecewiseLinear
    x = '0  1  2  3  4'
    y = '0 10 15 10  0'
    # 或从文件读取
    # data_file = 'data.csv'
    # format = columns
  []
  
  # 分段常数
  [piecewise_constant]
    type = PiecewiseConstant
    x = '0  1  2  3'
    y = '5 10 15 20'
    direction = 'right'
  []
[]
```

## 5.12 Preconditioning 块详解

```cpp
[Preconditioning]
  [SMP]
    type = SMP  # Single Matrix Preconditioner
    full = true # 完整雅可比矩阵
    
    # 或指定耦合
    # off_diag_row = 'disp_x'
    # off_diag_column = 'disp_y'
  []
  
  # 或使用 FDP
  # [FDP]
  #   type = FDP  # Finite Difference Preconditioner
  #   full = true
  # []
[]
```

## 5.13 Postprocessors 块详解

```cpp
[Postprocessors]
  # 节点极值
  [max_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = max
  []
  
  # 单元极值
  [max_stress]
    type = ElementExtremeValue
    variable = von_mises_stress
    value_type = max
  []
  
  # 积分值
  [total_heat]
    type = ElementIntegralVariablePostprocessor
    variable = temperature
  []
  
  # 平均值
  [average_displacement]
    type = ElementAverageValue
    variable = disp_z
  []
  
  # 边界积分
  [total_force]
    type = SideIntegralVariablePostprocessor
    variable = stress_xx
    boundary = 'right'
  []
[]
```

## 5.14 高级特性

### 5.14.1 向量后处理器

```cpp
[VectorPostprocessors]
  [line_data]
    type = LineValueSampler
    variable = 'temperature disp_x disp_y'
    start_point = '0 0 0'
    end_point = '10 0 0'
    num_points = 100
    sort_by = id
  []
[]
```

### 5.14.2 MultiApps

用于多尺度和多物理场耦合：

```cpp
[MultiApps]
  [sub_app]
    type = TransientMultiApp
    app_type = MyApp
    input_files = 'sub_problem.i'
    positions = '0 0 0'
    execute_on = timestep_end
  []
[]

[Transfers]
  [from_sub]
    type = MultiAppMeshFunctionTransfer
    from_multi_app = sub_app
    source_variable = temperature
    variable = temperature
  []
[]
```

## 5.15 输入文件组织最佳实践

### 5.15.1 使用 !include

```cpp
# main.i
[Mesh]
  !include mesh.i
[]

[Variables]
  !include variables.i
[]
```

### 5.15.2 参数化

```cpp
# 在文件顶部定义参数
L = 10
W = 5
E = 200e9

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    xmax = ${L}
    ymax = ${W}
  []
[]

[Materials]
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = ${E}
    poissons_ratio = 0.3
  []
[]
```

### 5.15.3 命令行参数

```bash
# 运行时覆盖参数
./app-opt -i input.i \
  Mesh/gen/xmax=20 \
  Materials/elasticity/youngs_modulus=250e9
```

## 5.16 调试技巧

### 5.16.1 检查输入文件

```bash
# 验证输入文件语法
./app-opt -i input.i --check-input

# 仅显示输入
./app-opt -i input.i --show-input

# 仅显示输出
./app-opt -i input.i --show-outputs
```

### 5.16.2 详细输出

```cpp
[Outputs]
  [console]
    type = Console
    output_nonlinear = true    # 输出非线性残差
    output_linear = true       # 输出线性残差
  []
[]
```

## 5.17 练习

1. **基础练习**：创建一个包含所有必需块的最小输入文件
2. **修改练习**：修改第四章的例子，使用不同的边界条件
3. **参数化练习**：创建参数化输入文件，通过命令行改变参数
4. **组织练习**：将大型输入文件拆分为多个文件

## 5.18 检查清单

- [ ] 理解基本块结构
- [ ] 知道如何定义变量和材料
- [ ] 能够设置不同类型的边界条件
- [ ] 理解求解器设置
- [ ] 会配置输出选项
- [ ] 能够使用函数和后处理器

## 下一章

下一章将深入讨论线性弹性问题，包括各向异性材料和复杂几何。

---

**参考资源**

1. MOOSE Input File Syntax: https://mooseframework.inl.gov/syntax/
2. GetPot Documentation
3. MOOSE Examples Repository

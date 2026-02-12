# 第八章：边界条件和载荷

## 8.1 边界条件概述

### 8.1.1 边界条件的分类

**按数学类型分类**：
1. **Dirichlet 边界条件**（本质边界条件）：指定变量值
   - 固定位移
   - 指定温度
   
2. **Neumann 边界条件**（自然边界条件）：指定导数/通量
   - 力、压力
   - 热通量
   
3. **Robin 边界条件**（混合边界条件）：变量和导数的线性组合
   - 对流换热
   - 弹性支承

**按物理类型分类**：
- 位移约束
- 力和压力载荷
- 对称边界条件
- 周期边界条件
- 接触约束

### 8.1.2 边界的定义

MOOSE 中边界通过 sidesets 定义：

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    # 自动创建边界：left, right, top, bottom, front, back
  []
  
  # 或自定义边界
  [new_sideset]
    type = SideSetsAroundSubdomainGenerator
    input = gen
    block = 1
    new_boundary = 'custom_boundary'
  []
[]
```

## 8.2 Dirichlet 边界条件

### 8.2.1 固定值边界条件

**基本用法**：

```cpp
[BCs]
  [fixed_displacement]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  []
[]
```

**固定多个自由度**：

```cpp
[BCs]
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
```

### 8.2.2 PresetBC

PresetBC 在求解前设置值，对某些问题更稳定：

```cpp
[BCs]
  [preset_disp]
    type = PresetBC
    variable = disp_x
    boundary = 'right'
    value = 0.01  # 1 cm 位移
  []
[]
```

### 8.2.3 函数边界条件

**时间相关位移**：

```cpp
[Functions]
  [displacement_function]
    type = ParsedFunction
    expression = 'A * sin(omega * t)'
    symbol_names = 'A omega'
    symbol_values = '0.01 6.28'  # 振幅 1cm, 频率 1Hz
  []
[]

[BCs]
  [dynamic_displacement]
    type = FunctionDirichletBC
    variable = disp_x
    boundary = 'right'
    function = displacement_function
  []
[]
```

**空间变化的位移**：

```cpp
[Functions]
  [spatial_displacement]
    type = ParsedFunction
    expression = 'd * sin(pi * y / H)'
    symbol_names = 'd H'
    symbol_values = '0.001 1.0'
  []
[]

[BCs]
  [varying_displacement]
    type = FunctionDirichletBC
    variable = disp_x
    boundary = 'right'
    function = spatial_displacement
  []
[]
```

### 8.2.4 匹配值边界条件

使边界上的变量与另一个变量匹配：

```cpp
[BCs]
  [match_boundary]
    type = MatchedValueBC
    variable = temperature
    boundary = 'interface'
    v = temperature_other
  []
[]
```

## 8.3 Neumann 边界条件

### 8.3.1 基本 Neumann BC

```cpp
[BCs]
  [flux]
    type = NeumannBC
    variable = temperature
    boundary = 'right'
    value = 1000  # W/m²
  []
[]
```

### 8.3.2 函数 Neumann BC

```cpp
[Functions]
  [time_varying_flux]
    type = PiecewiseLinear
    x = '0   10  20  30'
    y = '0  1000 500  0'
  []
[]

[BCs]
  [varying_flux]
    type = FunctionNeumannBC
    variable = temperature
    boundary = 'top'
    function = time_varying_flux
  []
[]
```

## 8.4 力学载荷

### 8.4.1 压力载荷

**均布压力**：

```cpp
[BCs]
  [pressure_load]
    type = Pressure
    variable = disp_x
    boundary = 'top'
    component = 0  # x 方向分量
    factor = 1e6   # 1 MPa
  []
  
  # 对于法向压力，需要为每个位移分量添加
  [pressure_y]
    type = Pressure
    variable = disp_y
    boundary = 'top'
    component = 1
    factor = 1e6
  []
  
  [pressure_z]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    component = 2
    factor = 1e6
  []
[]
```

**时间相关压力**：

```cpp
[Functions]
  [pressure_ramp]
    type = PiecewiseLinear
    x = '0   1'
    y = '0  1e6'
  []
[]

[BCs]
  [ramped_pressure]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    component = 2
    function = pressure_ramp
  []
[]
```

**空间变化的压力**：

```cpp
[Functions]
  [spatial_pressure]
    type = ParsedFunction
    expression = 'p0 * (1 + 0.5*sin(pi*x/L))'
    symbol_names = 'p0  L'
    symbol_values = '1e6 1.0'
  []
[]

[BCs]
  [varying_pressure]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    component = 2
    function = spatial_pressure
  []
[]
```

### 8.4.2 集中力

**使用 NodalKernels**：

```cpp
[NodalKernels]
  [point_load]
    type = ConstantRate
    variable = disp_z
    boundary = 'load_point'
    rate = -1000  # -1000 N
  []
[]
```

**使用 DiracKernels**（任意位置）：

```cpp
[DiracKernels]
  [point_force]
    type = ConstantPointSource
    variable = disp_z
    point = '0.5 0.5 1.0'
    value = -1000  # -1000 N
  []
[]
```

### 8.4.3 分布载荷（体力）

```cpp
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
    value = -9.81  # m/s²
  []
[]

[Materials]
  [density]
    type = GenericConstantMaterial
    prop_names = 'density'
    prop_values = '7850'  # kg/m³
  []
[]
```

或使用 BodyForce：

```cpp
[Kernels]
  [body_force]
    type = BodyForce
    variable = disp_z
    value = -77000  # ρ*g = 7850 * 9.81 N/m³
  []
[]
```

### 8.4.4 热载荷（通过热应变）

参见第 6、7 章的热弹性耦合内容。

## 8.5 特殊边界条件

### 8.5.1 对称边界条件

**平面对称**（垂直于 x 轴的对称面）：

```cpp
[BCs]
  # x 方向位移为 0，其他方向自由
  [symm_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'symmetry_plane'
    value = 0
  []
[]
```

**多个对称面**：

```cpp
[BCs]
  # xz 平面对称
  [symm_xz_y]
    type = DirichletBC
    variable = disp_y
    boundary = 'bottom'
    value = 0
  []
  
  # yz 平面对称
  [symm_yz_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  []
[]
```

**使用 Action 简化**：

```cpp
[BCs]
  [Periodic]
    [x_periodic]
      variable = 'disp_x disp_y disp_z'
      auto_direction = 'x'
    []
  []
[]
```

### 8.5.2 周期边界条件

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
  []
[]

[BCs]
  [Periodic]
    [x_periodic]
      variable = 'disp_x disp_y disp_z'
      auto_direction = 'x'
    []
    
    [y_periodic]
      variable = 'disp_x disp_y disp_z'
      auto_direction = 'y'
    []
  []
[]
```

### 8.5.3 弹性支承

模拟弹簧约束：$F = k \cdot u$

```cpp
[BCs]
  [elastic_support]
    type = LinearElasticBC
    variable = disp_z
    boundary = 'bottom'
    stiffness = 1e8  # N/m
  []
[]
```

### 8.5.4 接触边界条件

基本接触（详见第 14 章）：

```cpp
[Contact]
  [contact]
    primary = 'surface1'
    secondary = 'surface2'
    model = frictionless
    penalty = 1e10
  []
[]
```

## 8.6 多点约束（MPC）

### 8.6.1 线性约束

约束一个节点的自由度依赖于另一个节点：

```cpp
[Constraints]
  [tie_constraint]
    type = EqualValueConstraint
    variable = disp_x
    primary_boundary = 'master_surface'
    secondary_boundary = 'slave_surface'
    penalty = 1e10
  []
[]
```

### 8.6.2 刚体约束

```cpp
[Constraints]
  [rigid_body]
    type = RigidBodyModes3D
    subdomains = 'rigid_part'
    modes = 'x y z rotx roty rotz'
    primary_boundary = 'control_point'
    secondary_boundaries = 'rigid_surface'
  []
[]
```

## 8.7 载荷组合

### 8.7.1 多种载荷同时作用

```cpp
[BCs]
  # 固定约束
  [fix_left]
    type = DirichletBC
    variable = 'disp_x disp_y disp_z'
    boundary = 'left'
    value = 0
  []
  
  # 压力载荷
  [pressure_top]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    component = 2
    factor = 1e6
  []
  
  # 剪切载荷
  [shear_right]
    type = Pressure
    variable = disp_y
    boundary = 'right'
    component = 1
    factor = 5e5
  []
[]

[Kernels]
  # 体力（重力）
  [gravity]
    type = Gravity
    variable = disp_z
    value = -9.81
  []
[]
```

### 8.7.2 载荷历史

```cpp
[Functions]
  # 复杂载荷历史
  [load_history]
    type = PiecewiseLinear
    x = '0   10   20   30   40   50'
    y = '0   1e6  1e6  5e5  5e5  0'
  []
[]

[BCs]
  [time_dependent_load]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    component = 2
    function = load_history
  []
[]
```

## 8.8 载荷跟随（大变形）

对于大变形问题，载荷方向可能需要跟随变形：

```cpp
[BCs]
  [follower_pressure]
    type = Pressure
    variable = disp_z
    boundary = 'top'
    component = 2
    factor = 1e6
    use_displaced_mesh = true  # 使用变形后的网格
  []
[]

[Problem]
  use_displaced_mesh = true
[]
```

## 8.9 实际工程载荷

### 8.9.1 风载荷

```cpp
[Functions]
  [wind_pressure]
    type = ParsedFunction
    # 风压分布：p = 0.5 * ρ * v² * C_p
    expression = '0.5 * 1.225 * v*v * Cp * (y/H)^alpha'
    symbol_names = 'v  Cp  H   alpha'
    symbol_values = '40 1.2 100 0.15'  # 40 m/s 风速
  []
[]

[BCs]
  [wind_load]
    type = Pressure
    variable = disp_x
    boundary = 'windward_face'
    component = 0
    function = wind_pressure
  []
[]
```

### 8.9.2 雪载荷

```cpp
[Functions]
  [snow_load]
    type = ParsedFunction
    # 雪载根据屋顶坡度变化
    expression = 's0 * Ce * Ct * Is'
    symbol_names = 's0   Ce  Ct  Is'
    symbol_values = '1000 1.0 1.0 1.0'  # 基本雪压 1 kPa
  []
[]

[BCs]
  [snow_pressure]
    type = Pressure
    variable = disp_z
    boundary = 'roof'
    component = 2
    function = snow_load
  []
[]
```

### 8.9.3 内压载荷（压力容器）

```cpp
[BCs]
  [internal_pressure]
    type = Pressure
    variable = disp_x
    boundary = 'inner_surface'
    component = 0
    factor = 10e6  # 10 MPa
  []
[]
```

### 8.9.4 热载荷

```cpp
[Modules/TensorMechanics/Master]
  [all]
    strain = SMALL
    eigenstrain_names = 'thermal_strain'
    add_variables = true
  []
[]

[Materials]
  [thermal_strain]
    type = ComputeThermalExpansionEigenstrain
    temperature = temperature
    thermal_expansion_coeff = 1.2e-5
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
  []
[]

[BCs]
  [temp_boundary]
    type = DirichletBC
    variable = temperature
    boundary = 'heated_surface'
    value = 500  # K
  []
[]
```

## 8.10 边界条件的验证

### 8.10.1 检查约束充分性

```cpp
[Postprocessors]
  # 检查刚体位移
  [avg_disp_x]
    type = ElementAverageValue
    variable = disp_x
  []
  
  [avg_disp_y]
    type = ElementAverageValue
    variable = disp_y
  []
  
  [avg_disp_z]
    type = ElementAverageValue
    variable = disp_z
  []
[]
```

如果平均位移趋于无穷，说明约束不足。

### 8.10.2 反力计算

```cpp
[Postprocessors]
  [reaction_force_x]
    type = SidesetReaction
    variable = disp_x
    boundary = 'fixed_boundary'
  []
  
  [reaction_force_y]
    type = SidesetReaction
    variable = disp_y
    boundary = 'fixed_boundary'
  []
  
  [reaction_force_z]
    type = SidesetReaction
    variable = disp_z
    boundary = 'fixed_boundary'
  []
[]
```

验证：反力总和应等于施加的外载荷。

## 8.11 完整示例

参见 `examples/` 目录：
- `pressure_vessel.i` - 压力容器分析
- `cantilever_multiple_loads.i` - 多载荷组合
- `thermal_mechanical_coupling.i` - 热机耦合

## 8.12 练习

### 练习 1：基本边界条件
创建简单梁模型：
- 一端固定（所有自由度）
- 另一端自由
- 中间施加集中力
- 验证挠度和反力

### 练习 2：压力载荷
模拟圆柱壳：
- 内表面均布压力
- 轴向约束
- 计算环向应力

### 练习 3：对称边界条件
利用对称性分析四分之一模型：
- 定义对称边界
- 与全模型结果对比

### 练习 4：时变载荷
模拟循环载荷：
- 正弦变化的压力
- 计算位移历史
- 绘制位移-时间曲线

### 练习 5：热机耦合
分析受热约束结构：
- 固定边界
- 温度场
- 计算热应力

### 练习 6：复杂载荷
组合多种载荷：
- 重力
- 压力
- 集中力
- 温度载荷

## 8.13 故障排除

### 8.13.1 常见错误

**约束不足**：
```
症状：位移趋于无穷或不收敛
诊断：
  - 检查是否消除了所有刚体位移模式
  - 3D 问题需要至少 6 个约束（3 平动 + 3 转动）
解决：
  - 添加必要的位移约束
  - 检查约束是否独立
```

**约束过多**：
```
症状：过约束导致高应力
诊断：
  - 检查是否有冗余约束
  - 检查是否限制了热膨胀
解决：
  - 移除冗余约束
  - 使用适当的支承方式
```

**载荷符号错误**：
```
症状：结果与预期相反
解决：
  - 检查载荷方向和符号
  - 使用右手坐标系
  - 压力载荷正值通常表示法向向外
```

### 8.13.2 调试技巧

**可视化边界条件**：

```cpp
[AuxVariables]
  [bc_indicator]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [mark_bc]
    type = ConstantAux
    variable = bc_indicator
    boundary = 'loaded_boundary'
    value = 1
    execute_on = initial
  []
[]
```

**输出反力**：

```cpp
[Postprocessors]
  [total_reaction_x]
    type = SidesetReaction
    variable = disp_x
    boundary = 'all_fixed_boundaries'
  []
[]
```

## 8.14 高级话题

### 8.14.1 自适应边界条件

根据求解结果调整边界条件：

```cpp
[Controls]
  [load_control]
    type = ConditionalFunctionEnableControl
    conditional_function = control_function
    disable_objects = 'BCs::initial_load'
    enable_objects = 'BCs::updated_load'
  []
[]
```

### 8.14.2 用户自定义边界条件

可以编写 C++ 代码实现自定义边界条件（高级用户）。

### 8.14.3 弱边界条件

使用 Nitsche 方法或罚函数方法实现弱施加的边界条件。

## 8.15 小结

本章详细介绍了 MOOSE 中的边界条件和载荷：

- ✓ Dirichlet、Neumann 和 Robin 边界条件
- ✓ 力学载荷（压力、集中力、体力）
- ✓ 特殊边界条件（对称、周期、弹性支承）
- ✓ 载荷组合和时间相关载荷
- ✓ 实际工程载荷的模拟
- ✓ 边界条件的验证方法

## 下一章

下一章将详细讨论网格生成技术和网格质量控制。

---

**参考文献**

1. MOOSE BCs System Documentation
2. Zienkiewicz, O.C. "The Finite Element Method"
3. Cook, R.D. "Concepts and Applications of Finite Element Analysis"
4. ASCE 7 - Minimum Design Loads for Buildings
5. ASME Boiler and Pressure Vessel Code

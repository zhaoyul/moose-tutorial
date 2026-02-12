# 第三章：MOOSE 基本概念和架构

## 3.1 MOOSE 框架概述

MOOSE 是一个基于有限元方法的多物理场仿真框架。理解其核心概念对于高效使用至关重要。

### 3.1.1 设计哲学

- **可重用性**：一次编写，多次使用
- **模块化**：独立的物理模块可以组合
- **可扩展性**：用户可以轻松添加新功能
- **性能**：优化的并行计算能力

## 3.2 核心组件

### 3.2.1 Mesh（网格）

网格是有限元分析的基础，定义了计算域的离散化。

**支持的网格类型**：
- 1D：线单元
- 2D：三角形、四边形
- 3D：四面体、六面体、楔形、棱柱

**网格来源**：
```cpp
[Mesh]
  # 内置网格生成
  type = GeneratedMesh
  dim = 3
  nx = 10
  ny = 10
  nz = 10
  
  # 或导入外部网格
  # type = FileMesh
  # file = mesh.e
[]
```

### 3.2.2 Variables（变量）

变量代表要求解的物理量（如位移、温度、压力等）。

```cpp
[Variables]
  [disp_x]  # x 方向位移
    order = FIRST
    family = LAGRANGE
  []
  [disp_y]  # y 方向位移
    order = FIRST
    family = LAGRANGE
  []
  [disp_z]  # z 方向位移
    order = FIRST
    family = LAGRANGE
  []
[]
```

**插值类型**：
- **LAGRANGE**：标准连续有限元
- **MONOMIAL**：不连续有限元
- **HERMITE**：三次 Hermite 插值

**阶数**：
- **FIRST**：线性插值
- **SECOND**：二次插值
- **THIRD**、**FOURTH**：更高阶插值

### 3.2.3 Kernels（核心方程）

Kernels 表示控制方程中的各项（如扩散项、对流项等）。

**数学形式**：
$$\int_\Omega \psi_i R(\vec{u}) \, d\Omega = 0$$

其中：
- $\psi_i$ 是测试函数
- $R(\vec{u})$ 是残差
- $\Omega$ 是计算域

**示例**：
```cpp
[Kernels]
  # 弹性问题的应力平衡方程
  [stress_divergence_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
    displacements = 'disp_x disp_y disp_z'
  []
[]
```

### 3.2.4 Materials（材料）

Materials 定义材料属性和本构关系。

```cpp
[Materials]
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 2.1e11  # 杨氏模量（Pa）
    poissons_ratio = 0.3      # 泊松比
  []
  
  [strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]
```

### 3.2.5 Boundary Conditions（边界条件）

边界条件指定边界上的约束或载荷。

**类型**：
1. **Dirichlet BC**（本质边界条件）：指定变量值
2. **Neumann BC**（自然边界条件）：指定通量或力

```cpp
[BCs]
  # 固定约束（Dirichlet）
  [fixed_x]
    type = DirichletBC
    variable = disp_x
    boundary = 'left'
    value = 0
  []
  
  # 压力载荷（Neumann）
  [pressure]
    type = Pressure
    variable = disp_x
    boundary = 'right'
    component = 0
    factor = 1e6  # 1 MPa
  []
[]
```

### 3.2.6 Executioner（执行器）

Executioner 控制求解过程和时间步进。

```cpp
[Executioner]
  type = Steady  # 稳态问题
  # type = Transient  # 瞬态问题
  
  solve_type = 'NEWTON'  # Newton-Raphson 方法
  
  petsc_options_iname = '-pc_type -pc_hypre_type'
  petsc_options_value = 'hypre boomeramg'
  
  nl_rel_tol = 1e-8  # 非线性相对容差
  nl_abs_tol = 1e-10 # 非线性绝对容差
  l_tol = 1e-5       # 线性求解器容差
  l_max_its = 100    # 最大线性迭代次数
[]
```

### 3.2.7 Outputs（输出）

Outputs 控制结果的输出格式和频率。

```cpp
[Outputs]
  exodus = true     # Exodus II 格式（用于 Paraview）
  csv = true        # CSV 格式
  
  [console]
    type = Console
    perf_log = true
  []
[]
```

## 3.3 物理场的数学描述

### 3.3.1 固体力学基本方程

**平衡方程**：
$$\nabla \cdot \boldsymbol{\sigma} + \mathbf{f} = 0$$

其中：
- $\boldsymbol{\sigma}$ 是应力张量
- $\mathbf{f}$ 是体力

**应变-位移关系**（小变形）：
$$\boldsymbol{\epsilon} = \frac{1}{2}(\nabla \mathbf{u} + (\nabla \mathbf{u})^T)$$

**本构关系**（线性弹性）：
$$\boldsymbol{\sigma} = \mathbb{C} : \boldsymbol{\epsilon}$$

其中 $\mathbb{C}$ 是弹性张量。

### 3.3.2 有限元离散化

**弱形式**：
$$\int_\Omega \nabla \psi_i : \boldsymbol{\sigma} \, d\Omega - \int_{\Gamma_t} \psi_i \cdot \mathbf{t} \, d\Gamma - \int_\Omega \psi_i \cdot \mathbf{f} \, d\Omega = 0$$

**离散化**：
$$\mathbf{u}^h = \sum_{j=1}^N N_j \mathbf{u}_j$$

其中：
- $N_j$ 是形状函数
- $\mathbf{u}_j$ 是节点位移

## 3.4 MOOSE 对象系统

### 3.4.1 对象层次结构

```
MooseObject (基类)
├── Kernel
│   ├── Diffusion
│   ├── TimeDerivative
│   └── StressDivergence
├── Material
│   ├── ComputeElasticityTensor
│   └── ComputeStress
├── BoundaryCondition
│   ├── DirichletBC
│   └── NeumannBC
└── ...
```

### 3.4.2 依赖关系

MOOSE 自动管理对象之间的依赖关系：

```
Variables → Kernels → Materials
    ↓          ↓
AuxVariables → AuxKernels
```

## 3.5 求解过程

### 3.5.1 稳态问题

1. **初始化**：设置初始猜测
2. **装配**：构建残差向量和雅可比矩阵
3. **求解**：Newton-Raphson 迭代
4. **收敛检查**：检查残差
5. **输出**：保存结果

### 3.5.2 瞬态问题

```
for t in time_steps:
    1. 预测：u_new = u_old + dt * du/dt
    2. 非线性求解
    3. 更新状态
    4. 输出（如果需要）
```

## 3.6 并行计算

### 3.6.1 区域分解

MOOSE 使用 MPI 进行区域分解：

```
┌────────┬────────┐
│ Proc 0 │ Proc 1 │
├────────┼────────┤
│ Proc 2 │ Proc 3 │
└────────┴────────┘
```

### 3.6.2 并行运行

```bash
# 使用 4 个进程
mpiexec -n 4 ./myapp-opt -i input.i

# 混合 MPI + 线程
mpiexec -n 2 ./myapp-opt -i input.i --n-threads=4
```

## 3.7 Action 系统

Actions 是 MOOSE 的高级抽象，简化复杂设置。

**不使用 Action**：
```cpp
[Variables]
  [disp_x]
  []
  [disp_y]
  []
  [disp_z]
  []
[]

[Kernels]
  [stress_x]
    type = StressDivergenceTensors
    variable = disp_x
    component = 0
  []
  # ... 更多配置
[]
```

**使用 Action**：
```cpp
[Modules/TensorMechanics/Master]
  [all]
    strain = SMALL
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_zz'
  []
[]
```

## 3.8 AuxVariables 和 AuxKernels

### 3.8.1 辅助变量

用于后处理和可视化，不参与主求解。

```cpp
[AuxVariables]
  [von_mises_stress]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [von_mises]
    type = RankTwoScalarAux
    variable = von_mises_stress
    rank_two_tensor = stress
    scalar_type = VonMisesStress
  []
[]
```

## 3.9 函数系统

Functions 用于定义空间或时间变化的参数。

```cpp
[Functions]
  # 解析函数
  [pressure_function]
    type = ParsedFunction
    expression = '1e6 * sin(pi * t / 10)'
  []
  
  # 分段线性函数
  [temperature_function]
    type = PiecewiseLinear
    x = '0   100  200  300'
    y = '300 400  450  400'
  []
[]
```

## 3.10 后处理系统

### 3.10.1 Postprocessors

计算标量值（如总能量、最大应力等）。

```cpp
[Postprocessors]
  [max_stress]
    type = ElementExtremeValue
    variable = von_mises_stress
    value_type = max
  []
  
  [total_volume]
    type = VolumePostprocessor
  []
[]
```

### 3.10.2 VectorPostprocessors

计算向量值（如沿线的数据）。

```cpp
[VectorPostprocessors]
  [line_sample]
    type = LineValueSampler
    variable = 'disp_x disp_y disp_z'
    start_point = '0 0 0'
    end_point = '1 0 0'
    num_points = 100
    sort_by = x
  []
[]
```

## 3.11 练习

### 练习 1：理解概念
阅读并理解每个核心组件的作用。

### 练习 2：分析输入文件
下载一个示例输入文件，识别各个组件。

### 练习 3：画流程图
绘制 MOOSE 求解过程的流程图。

### 练习 4：研究文档
访问 MOOSE 官方文档，查找一个 Kernel 的详细说明。

## 3.12 小结

本章介绍了 MOOSE 的核心概念：

- ✓ 网格、变量、Kernels
- ✓ 材料、边界条件
- ✓ 执行器和输出
- ✓ 对象系统和求解过程
- ✓ 并行计算和 Action 系统

## 下一章

下一章我们将创建第一个完整的 MOOSE 例子，应用本章学到的概念。

---

**参考文献**

1. MOOSE Documentation: System Overview
2. Gaston, D., et al. "Physics-based multiscale coupling for full core nuclear reactor simulation."
3. MOOSE Workshop Materials: https://mooseframework.inl.gov/workshop/

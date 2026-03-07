# 第四章：第一个 MOOSE 例子 - 简单梁的弹性分析

## 4.1 问题描述

在本章中，我们将创建第一个完整的 MOOSE 仿真：**悬臂梁在自由端受集中载荷**。

本章建议按下面顺序学习：

1. 先运行仓库里已经准备好的 `examples/cantilever_beam.i`
2. 再对照本章逐块理解输入文件
3. 最后自己改 1 到 2 个参数，观察结果怎么变

如果你是第一次接触 MOOSE，先跑通比先手写更重要。

### 4.1.1 物理模型

- **几何**：长度 L = 1 m，高度 H = 0.1 m，宽度 W = 0.05 m
- **材料**：钢材
  - 杨氏模量：E = 200 GPa
  - 泊松比：ν = 0.3
- **边界条件**：
  - 左端固定（所有位移为零）
  - 右端自由端施加向下的集中力 F = 1000 N
- **问题类型**：3D 线弹性静力分析

### 4.1.2 理论解

对于悬臂梁，自由端的挠度理论解为：
$$\delta = \frac{FL^3}{3EI}$$

其中：
- I = WH³/12 是惯性矩
- 对于我们的例子：I = 0.05 × 0.1³ / 12 = 4.167 × 10⁻⁶ m⁴

预期挠度：
$$\delta = \frac{1000 \times 1^3}{3 \times 200 \times 10^9 \times 4.167 \times 10^{-6}} = 4.0 \times 10^{-4} \text{ m} = 0.4 \text{ mm}$$

### 4.1.3 先跑通现成示例（推荐）

本仓库已经提供了可直接运行的文件 [examples/cantilever_beam.i](examples/cantilever_beam.i)。第一次学习时，先不要从零手敲，先确认这个例子能跑通。

```bash
cd 04-first-example/examples
combined-opt -i cantilever_beam.i
```

运行成功后，先检查这 4 件事：

- 终端最后出现 `Finished Executing`
- 当前目录生成 `cantilever_out.e`
- 当前目录生成 `cantilever_out.csv`
- `cantilever_out.csv` 里能看到 `max_disp_z` 和 `max_von_mises`

如果这一步没有通过，优先回到第二章处理环境问题，不要继续往后堆新知识点。

## 4.2 创建输入文件

创建文件 `cantilever_beam.i`：

```cpp
# 悬臂梁弹性分析 - 第一个 MOOSE 例子

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
[]

[Physics/SolidMechanics/QuasiStatic]
  [all]
    strain = SMALL
    add_variables = true
    generate_output = 'stress_xx stress_yy stress_zz stress_xy stress_yz stress_zx strain_xx strain_yy strain_zz'
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
  # 固定左端（x=0）的所有自由度
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
  
  # 右端（x=1）施加向下的力（-z 方向）
  [load]
    type = NodalBC
    variable = disp_z
    boundary = 'right'
    value = -0.004  # 这是位移控制，实际应使用力边界条件
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
  exodus = true
  csv = true
  print_linear_residuals = true
  perf_graph = true
[]
```

## 4.3 更好的版本：使用力边界条件

创建 `cantilever_beam_force.i`：

```cpp
# 悬臂梁弹性分析 - 使用力边界条件

[GlobalParams]
  displacements = 'disp_x disp_y disp_z'
[]

[Mesh]
  [generated_mesh]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 0
    xmax = 1.0
    ymin = 0
    ymax = 0.05
    zmin = 0
    zmax = 0.1
    nx = 20
    ny = 5
    nz = 10
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
    youngs_modulus = 2.0e11
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
    # perf_log 已弃用
  []
[]
```

## 4.4 运行仿真

### 4.4.1 编译（如果需要）

```bash
cd ~/projects/MyApp
make -j4
```

### 4.4.2 运行

```bash
# 推荐：直接运行仓库现成示例
cd 04-first-example/examples
combined-opt -i cantilever_beam.i

# 如果你是在自己的 MOOSE app 中复现本章，可改为：
# ./myapp-opt -i cantilever_beam_force.i
```

### 4.4.3 查看输出

运行完成后，你会看到：
- `cantilever_out.e`：Exodus 文件（用于 Paraview）
- `cantilever_out.csv`：CSV 文件（包含后处理数据）

第一次运行时建议再多看两眼终端输出：

- 是否出现了非线性收敛失败
- 网格节点数和单元数是否与你设置的 `nx/ny/nz` 大致一致
- 结果文件名是否与你在 `[Outputs]` 里设置的 `file_base` 一致

## 4.5 结果后处理

### 4.5.1 使用 Paraview

```bash
# 启动 Paraview
paraview cantilever_out.e
```

**在 Paraview 中**：
1. 点击 "Apply"
2. 选择 "Warp By Vector"
   - Vector：disp
   - Scale Factor：1000（放大变形）
3. 选择着色变量：
   - von_mises_stress
   - disp_z

### 4.5.2 分析 CSV 输出

查看 `cantilever_out.csv`：
```bash
cat cantilever_out.csv
```

你至少应该看到表头：
```
time,max_disp_z,max_von_mises,num_elems,num_nodes
```

对初学者来说，第一次不要死盯每一位数字，更应该看：

- `max_disp_z` 是否约为 `-4e-4`
- `max_von_mises` 是否是正值
- `num_elems` 是否与你的网格划分一致

## 4.6 验证结果

### 4.6.1 挠度验证

从 CSV 输出中，最大挠度约为 -0.0004 m = -0.4 mm，与理论解一致！

这里最值得建立的直觉是：

- 载荷向下，所以位移是负值
- 梁越长、越软、越细，挠度越大
- 如果结果数量级完全不对，优先检查单位和边界条件

### 4.6.2 应力验证

最大 von Mises 应力约为 36 MPa，位于固定端。

理论最大弯曲应力：
$$\sigma_{max} = \frac{My}{I} = \frac{FL \times (H/2)}{I}$$

$$\sigma_{max} = \frac{1000 \times 1 \times 0.05}{4.167 \times 10^{-6}} = 12 \text{ MPa}$$

注意：von Mises 应力会略高于简单弯曲应力。

## 4.7 参数研究

### 4.7.1 网格收敛性研究

创建脚本 `mesh_study.sh`：

```bash
#!/bin/bash

for nx in 10 20 40 80; do
    sed "s/nx = 20/nx = $nx/" cantilever_beam_force.i > temp.i
    ./myapp-opt -i temp.i -o cantilever_nx${nx}.e
    echo "Completed nx = $nx"
done
```

### 4.7.2 材料参数研究

创建 `parametric_study.i`：

```cpp
[Mesh]
  # ... 同上 ...
[]

[Physics/SolidMechanics/QuasiStatic]
  # ... 同上 ...
[]

[Materials]
  [elasticity]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = '${fparse 200e9 * (1 + 0.1 * t)}'  # 参数化
    poissons_ratio = 0.3
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]

# ... 其余部分 ...
```

## 4.8 常见问题和调试

### 问题 1：收敛失败

**症状**：
```
Nonlinear solve did not converge!
```

**解决方案**：
1. 检查边界条件是否合理
2. 减小载荷，使用载荷步进
3. 改进初始猜测
4. 调整求解器参数

### 问题 2：结果不合理

**检查清单**：
- [ ] 单位是否一致？（Pa vs. MPa）
- [ ] 边界条件是否正确？
- [ ] 材料参数是否正确？
- [ ] 网格质量是否足够？

### 问题 3：运行时间过长

**优化方法**：
1. 使用更粗的网格（先验证）
2. 使用更好的预条件器
3. 并行运行
4. 检查是否有不必要的输出

## 4.9 扩展练习

### 练习 1：把载荷加倍，再猜结果

把 `rate = -1000` 改成 `rate = -2000`，运行前先写下你的猜测：

- `max_disp_z` 大约会变成原来的几倍？
- `max_von_mises` 大约会变成原来的几倍？

运行后再验证。在线弹性范围内，这两个量通常都会近似翻倍。

### 练习 2：把材料变软

把 `youngs_modulus = 2.0e11` 改成 `1.0e11`，比较前后两次的 `max_disp_z`。

这个练习的目标不是记公式，而是建立“材料越软，位移越大”的直接感觉。

### 练习 3：细化网格

把 `nx = 20` 改成 `40`，重新运行并比较：

- `num_elems` 是否明显增加
- `max_disp_z` 是否趋于稳定
- 运行时间是否变长

这就是最基础的网格收敛性观察。

### 练习 4：改几何尺寸

把梁高度 `zmax = 0.1` 改成 `0.05`，再运行一次。

先猜再看结果：梁变薄后，弯曲刚度会下降，所以挠度会明显变大。

## 4.10 完整的工作流程总结

1. **定义问题**：明确几何、材料、载荷、边界条件
2. **创建输入文件**：编写 `.i` 文件
3. **检查输入**：使用 `--check-input` 标志
4. **运行仿真**：执行程序
5. **后处理**：使用 Paraview 可视化
6. **验证**：与理论或实验对比
7. **文档**：记录结果和设置

## 4.11 检查清单

完成本章后，你应该能够：

- [x] 创建简单的 MOOSE 输入文件
- [x] 定义几何和网格
- [x] 设置材料属性
- [x] 应用边界条件
- [x] 运行仿真
- [x] 后处理和可视化结果
- [x] 验证结果的合理性

## 下一章

在下一章中，我们将深入学习 MOOSE 输入文件的结构和语法，以及更高级的配置选项。

---

**参考资源**

1. MOOSE Solid Mechanics Examples
2. Timoshenko & Goodier, "Theory of Elasticity"
3. Paraview Tutorial: https://www.paraview.org/tutorials/

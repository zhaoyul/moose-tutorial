# 第七章：材料属性定义

## 7.1 材料系统概述

### 7.1.1 MOOSE 材料框架

MOOSE 的材料系统负责：
- 定义材料属性（密度、弹性模量、热导率等）
- 计算本构关系（应力-应变关系）
- 管理材料状态变量
- 处理材料的历史相关行为

### 7.1.2 材料属性的计算流程

```
初始化 → 计算材料属性 → 计算残差和雅可比 → 更新状态
    ↑                                           ↓
    └───────────────────时间步进─────────────────┘
```

### 7.1.3 材料对象的组织

```cpp
[Materials]
  # 材料属性按计算顺序组织
  [elasticity_tensor]
    # 首先计算弹性张量
  []
  
  [strain]
    # 然后计算应变
  []
  
  [stress]
    # 最后计算应力
  []
[]
```

MOOSE 自动解析依赖关系并按正确顺序计算。

## 7.2 基本材料属性

### 7.2.1 常数材料属性

**单一属性**：

```cpp
[Materials]
  [density]
    type = GenericConstantMaterial
    prop_names = 'density'
    prop_values = '7850'  # kg/m³ (钢)
  []
[]
```

**多个属性**：

```cpp
[Materials]
  [physical_properties]
    type = GenericConstantMaterial
    prop_names = 'density thermal_conductivity specific_heat'
    prop_values = '7850   50.0              500'
  []
[]
```

### 7.2.2 函数材料属性

材料属性可以是时间、空间或其他变量的函数。

**时间相关**：

```cpp
[Functions]
  [youngs_modulus_function]
    type = PiecewiseLinear
    x = '0  100  200  300'
    y = '200e9  190e9  180e9  170e9'
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus_function = youngs_modulus_function
    poissons_ratio = 0.3
  []
[]
```

**空间相关**：

```cpp
[Functions]
  [spatial_modulus]
    type = ParsedFunction
    expression = 'E0 * (1 + 0.1*sin(pi*x/L))'
    symbol_names = 'E0 L'
    symbol_values = '200e9 1.0'
  []
[]

[Materials]
  [varying_elasticity]
    type = GenericFunctionMaterial
    prop_names = 'youngs_modulus'
    prop_values = 'spatial_modulus'
  []
[]
```

## 7.3 温度依赖材料

### 7.3.1 温度相关弹性模量

许多材料的弹性模量随温度变化：

$$E(T) = E_0 [1 - \beta(T - T_0)]$$

**方法 1：使用 ParsedFunction**

```cpp
[Variables]
  [temperature]
    initial_condition = 300
  []
[]

[Functions]
  [youngs_modulus_temp]
    type = ParsedFunction
    expression = 'E0 * (1 - beta * (T - T0))'
    symbol_names = 'E0    beta    T0  T'
    symbol_values = '2e11  5e-4   300  temperature'
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus_function = youngs_modulus_temp
    poissons_ratio = 0.3
  []
[]
```

**方法 2：使用 PiecewiseLinear（从数据）**

```cpp
[Functions]
  [E_vs_T]
    type = PiecewiseLinear
    # 从实验数据文件读取
    data_file = 'E_temperature_data.csv'
    format = columns
    x_index_in_file = 0  # 温度列
    y_index_in_file = 1  # 弹性模量列
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus_function = E_vs_T
    poissons_ratio = 0.3
  []
[]
```

数据文件格式（`E_temperature_data.csv`）：
```
# Temperature(K), Youngs_Modulus(Pa)
273, 210e9
373, 205e9
473, 200e9
573, 195e9
673, 190e9
773, 185e9
```

### 7.3.2 温度相关泊松比

```cpp
[Functions]
  [poisson_temp]
    type = PiecewiseLinear
    x = '300  500  700  900'
    y = '0.30 0.31 0.32 0.33'
  []
[]

[Materials]
  [elasticity_tensor]
    type = ComputeVariableIsotropicElasticityTensor
    youngs_modulus = E
    poissons_ratio = nu
    args = 'temperature'
  []
  
  [E_material]
    type = GenericFunctionMaterial
    prop_names = 'E'
    prop_values = 'youngs_modulus_temp'
  []
  
  [nu_material]
    type = GenericFunctionMaterial
    prop_names = 'nu'
    prop_values = 'poisson_temp'
  []
[]
```

### 7.3.3 热膨胀系数

热膨胀系数也可能随温度变化：

$$\alpha(T) = \alpha_0 + \alpha_1 T + \alpha_2 T^2$$

```cpp
[Materials]
  [thermal_expansion_coeff]
    type = GenericFunctionMaterial
    prop_names = 'thermal_expansion_coeff'
    prop_values = 'alpha_function'
  []
  
  [thermal_strain]
    type = ComputeThermalExpansionEigenstrain
    temperature = temperature
    thermal_expansion_coeff = thermal_expansion_coeff
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
  []
[]

[Functions]
  [alpha_function]
    type = ParsedFunction
    expression = 'a0 + a1*T + a2*T*T'
    symbol_names = 'a0    a1      a2      T'
    symbol_values = '1e-5  1e-8   5e-12   temperature'
  []
[]
```

## 7.4 弹性张量定义

### 7.4.1 各向同性材料

```cpp
[Materials]
  [elasticity_tensor]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
    poissons_ratio = 0.3
    # 或者使用拉梅常数
    # lambda = 115e9
    # shear_modulus = 77e9
  []
[]
```

### 7.4.2 正交各向异性材料

**方法 1：使用工程常数**

```cpp
[Materials]
  [elasticity_tensor]
    type = ComputeElasticityTensor
    fill_method = orthotropic
    # E_x  E_y  E_z  nu_yx nu_zx nu_zy G_xy G_xz G_yz
    C_ijkl = '150e9 150e9 10e9 0.3 0.3 0.4 7e9 7e9 5e9'
  []
[]
```

**方法 2：直接指定刚度矩阵**

```cpp
[Materials]
  [elasticity_tensor]
    type = ComputeElasticityTensor
    fill_method = symmetric9
    # C11    C12    C13    C22    C23    C33    C44    C55    C66
    C_ijkl = '165e9  63.9e9 63.9e9 165e9  63.9e9 165e9  79.6e9 79.6e9 79.6e9'
  []
[]
```

**方法 3：完整 21 个独立分量**

```cpp
[Materials]
  [elasticity_tensor]
    type = ComputeElasticityTensor
    fill_method = symmetric21
    # C11 C12 C13 C14 C15 C16 C22 C23 C24 C25 C26 C33 C34 C35 C36 C44 C45 C46 C55 C56 C66
    C_ijkl = '...'  # 21 个值
  []
[]
```

### 7.4.3 从文件读取弹性张量

对于复杂的材料或从实验数据获得的弹性张量：

```cpp
[Materials]
  [elasticity_tensor]
    type = ComputeElasticityTensor
    fill_method = from_file
    file_name = 'elasticity_tensor.txt'
  []
[]
```

文件格式（`elasticity_tensor.txt`）：
```
# 6x6 弹性矩阵（Voigt 记号）
C11 C12 C13 C14 C15 C16
C12 C22 C23 C24 C25 C26
C13 C23 C33 C34 C35 C36
C14 C24 C34 C44 C45 C46
C15 C25 C35 C45 C55 C56
C16 C26 C36 C46 C56 C66
```

## 7.5 应变和应力计算

### 7.5.1 小应变理论

```cpp
[Materials]
  [strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]
```

### 7.5.2 有限应变理论

对于大变形问题（详见第12章）：

```cpp
[Materials]
  [strain]
    type = ComputeFiniteStrain
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress]
    type = ComputeFiniteStrainElasticStress
  []
[]
```

### 7.5.3 增量应变

某些材料模型需要应变增量：

```cpp
[Materials]
  [strain]
    type = ComputeIncrementalSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
[]
```

## 7.6 特征应变（Eigenstrain）

### 7.6.1 概念

特征应变是非机械因素产生的应变，如：
- 热膨胀
- 相变
- 湿度变化
- 塑性应变
- 蠕变应变

总应变分解：
$$\boldsymbol{\epsilon}^{total} = \boldsymbol{\epsilon}^{elastic} + \boldsymbol{\epsilon}^{eigen}$$

应力计算：
$$\boldsymbol{\sigma} = \mathbb{C} : \boldsymbol{\epsilon}^{elastic} = \mathbb{C} : (\boldsymbol{\epsilon}^{total} - \boldsymbol{\epsilon}^{eigen})$$

### 7.6.2 热特征应变

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
    thermal_expansion_coeff = 1.2e-5  # 1/K
    stress_free_temperature = 300     # K
    eigenstrain_name = thermal_strain
  []
[]
```

### 7.6.3 各向异性热膨胀

```cpp
[Materials]
  [thermal_strain]
    type = ComputeThermalExpansionEigenstrain
    temperature = temperature
    # 三个方向的热膨胀系数
    thermal_expansion_coeff = '1.0e-5 1.0e-5 2.0e-5'
    stress_free_temperature = 300
    eigenstrain_name = thermal_strain
  []
[]
```

### 7.6.4 多种特征应变

```cpp
[Modules/TensorMechanics/Master]
  [all]
    strain = SMALL
    eigenstrain_names = 'thermal_strain phase_strain plastic_strain'
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
  
  [phase_strain]
    type = ComputeVariableEigenstrain
    eigen_base = '0.01 0.01 0.01 0 0 0'
    prefactor = phase_fraction
    eigenstrain_name = phase_strain
  []
  
  # 塑性应变由塑性模型计算
  [plasticity]
    type = ComputeMultiPlasticityStress
    ...
    ep_plastic_tolerance = 1e-9
  []
[]
```

## 7.7 材料属性的后处理

### 7.7.1 输出材料属性

```cpp
[Outputs]
  [exodus]
    type = Exodus
    # 输出材料属性到结果文件
    output_material_properties = true
  []
[]
```

### 7.7.2 使用辅助变量查看材料属性

```cpp
[AuxVariables]
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
```

### 7.7.3 张量属性的可视化

```cpp
[AuxVariables]
  [C11]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [C11_kernel]
    type = RankFourAux
    variable = C11
    rank_four_tensor = elasticity_tensor
    index_i = 0
    index_j = 0
    index_k = 0
    index_l = 0
    execute_on = timestep_end
  []
[]
```

## 7.8 多块材料

### 7.8.1 不同区域不同材料

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
  []
  
  [subdomain1]
    type = SubdomainBoundingBoxGenerator
    input = gen
    block_id = 1
    block_name = 'steel'
    bottom_left = '0 0 0'
    top_right = '0.5 1 1'
  []
  
  [subdomain2]
    type = SubdomainBoundingBoxGenerator
    input = subdomain1
    block_id = 2
    block_name = 'aluminum'
    bottom_left = '0.5 0 0'
    top_right = '1 1 1'
  []
[]

[Materials]
  # 钢材料
  [elasticity_steel]
    type = ComputeIsotropicElasticityTensor
    block = 'steel'
    youngs_modulus = 200e9
    poissons_ratio = 0.30
  []
  
  [density_steel]
    type = GenericConstantMaterial
    block = 'steel'
    prop_names = 'density'
    prop_values = '7850'
  []
  
  # 铝材料
  [elasticity_aluminum]
    type = ComputeIsotropicElasticityTensor
    block = 'aluminum'
    youngs_modulus = 70e9
    poissons_ratio = 0.33
  []
  
  [density_aluminum]
    type = GenericConstantMaterial
    block = 'aluminum'
    prop_names = 'density'
    prop_values = '2700'
  []
  
  # 共同的应变和应力计算
  [strain]
    type = ComputeSmallStrain
    displacements = 'disp_x disp_y disp_z'
  []
  
  [stress]
    type = ComputeLinearElasticStress
  []
[]
```

### 7.8.2 界面处理

不同材料界面自动处理，MOOSE 确保位移连续性和力平衡。

## 7.9 高级材料模型

### 7.9.1 率相关材料

```cpp
[Materials]
  [strain_rate]
    type = ComputeStrainRate
    displacements = 'disp_x disp_y disp_z'
  []
  
  [viscoplasticity]
    type = ComputeCreepStress
    ...
  []
[]
```

### 7.9.2 损伤材料

```cpp
[Materials]
  [damage]
    type = ComputeDamageStress
    damage_model = damage
  []
  
  [damage_model]
    type = ScalarDamage
    ...
  []
[]
```

### 7.9.3 超弹性材料

```cpp
[Materials]
  [hyperelastic]
    type = ComputeNeoHookeanStress
    bulk_modulus = 160e9
    shear_modulus = 80e9
  []
[]
```

## 7.10 材料数据库

### 7.10.1 常见材料参数

**金属**：

| 材料 | E (GPa) | ν | α (1/K) | ρ (kg/m³) |
|------|---------|---|---------|-----------|
| 钢   | 200     | 0.30 | 12×10⁻⁶ | 7850 |
| 铝   | 70      | 0.33 | 23×10⁻⁶ | 2700 |
| 铜   | 120     | 0.34 | 17×10⁻⁶ | 8960 |
| 钛   | 116     | 0.32 | 8.6×10⁻⁶ | 4500 |

**复合材料**（碳纤维/环氧树脂）：

| 参数 | 值 |
|------|-----|
| E₁ (纤维方向) | 150 GPa |
| E₂ (横向) | 10 GPa |
| E₃ (横向) | 10 GPa |
| ν₁₂ | 0.30 |
| ν₁₃ | 0.30 |
| ν₂₃ | 0.40 |
| G₁₂ | 7 GPa |
| G₁₃ | 7 GPa |
| G₂₃ | 5 GPa |

**陶瓷**：

| 材料 | E (GPa) | ν | ρ (kg/m³) |
|------|---------|---|-----------|
| 氧化铝 | 380 | 0.23 | 3900 |
| 碳化硅 | 410 | 0.14 | 3210 |
| 氮化硅 | 310 | 0.27 | 3200 |

### 7.10.2 创建材料库

```cpp
# material_library.i
[Materials]
  [steel_AISI4340]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 205e9
    poissons_ratio = 0.29
  []
  
  [steel_AISI4340_density]
    type = GenericConstantMaterial
    prop_names = 'density thermal_expansion_coeff yield_stress'
    prop_values = '7850   11.5e-6                   470e6'
  []
[]

# 主输入文件
[Materials]
  !include material_library.i
[]
```

## 7.11 材料验证和测试

### 7.11.1 单元测试

创建简单的单元测试验证材料模型：

```cpp
# 单轴拉伸测试
[Mesh]
  type = GeneratedMesh
  dim = 3
  nx = 1
  ny = 1
  nz = 10
[]

[Materials]
  # 被测材料
  [test_material]
    type = ComputeIsotropicElasticityTensor
    youngs_modulus = 200e9
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
  [fix_bottom]
    type = DirichletBC
    variable = 'disp_x disp_y disp_z'
    boundary = 'back'
    value = 0
  []
  
  [pull]
    type = FunctionDirichletBC
    variable = disp_z
    boundary = 'front'
    function = '0.01*t'  # 1% 应变
  []
[]

[Postprocessors]
  [stress_zz]
    type = ElementAverageValue
    variable = stress_zz
  []
  
  [strain_zz]
    type = ElementAverageValue
    variable = strain_zz
  []
  
  # 计算有效模量
  [effective_E]
    type = ParsedPostprocessor
    pp_names = 'stress_zz strain_zz'
    expression = 'stress_zz / strain_zz'
  []
[]
```

### 7.11.2 材料参数敏感性分析

```bash
#!/bin/bash
# 参数扫描脚本

for E in 180e9 200e9 220e9; do
  for nu in 0.25 0.30 0.35; do
    echo "Running E=$E, nu=$nu"
    ./app-opt -i input.i \
      Materials/elasticity/youngs_modulus=$E \
      Materials/elasticity/poissons_ratio=$nu \
      Outputs/file_base=results_E${E}_nu${nu}
  done
done
```

## 7.12 实例：温度相关材料分析

参见 `examples/temperature_dependent_material.i`

## 7.13 练习

### 练习 1：材料定义
创建一个多材料问题：
- 两种不同材料的复合结构
- 定义所有必需的材料属性
- 验证界面连续性

### 练习 2：温度相关分析
实现温度相关的弹性模量：
- 使用 ParsedFunction 定义 E(T)
- 创建温度场
- 分析热弹耦合

### 练习 3：各向异性材料
定义一个正交各向异性材料：
- 使用工程常数
- 验证材料矩阵的对称性
- 与各向同性结果对比

### 练习 4：特征应变
实现热膨胀分析：
- 定义热膨胀系数
- 施加温度变化
- 计算热应力

### 练习 5：材料库
创建可重用的材料库：
- 定义多种常见材料
- 使用 !include 引用
- 参数化材料定义

## 7.14 故障排除

### 7.14.1 常见错误

**未定义的材料属性**：
```
错误信息：Material property 'elasticity_tensor' not defined
解决方法：确保所有需要的材料对象都已定义
```

**材料依赖顺序错误**：
```
症状：计算结果不正确或不收敛
原因：材料对象计算顺序错误
解决：MOOSE 通常自动处理，检查依赖关系
```

**不合理的材料参数**：
```
症状：数值不稳定或不物理的结果
检查：
- 泊松比范围：-1 < ν < 0.5
- 正定性：弹性矩阵必须正定
- 单位一致性
```

### 7.14.2 调试技巧

```cpp
[Debug]
  show_material_props = true  # 显示所有材料属性
[]

[Outputs]
  [debug]
    type = MaterialPropertyDebugOutput
    execute_on = timestep_end
  []
[]
```

## 7.15 小结

本章详细介绍了 MOOSE 中的材料属性定义：

- ✓ 基本材料属性和常数
- ✓ 温度依赖材料模型
- ✓ 各向同性和各向异性弹性张量
- ✓ 特征应变的概念和应用
- ✓ 多材料和材料库
- ✓ 材料验证和测试方法

## 下一章

下一章将详细讨论各种边界条件和载荷类型的定义和应用。

---

**参考文献**

1. MOOSE Materials System Documentation
2. Bower, A.F. "Applied Mechanics of Solids"
3. ASM Materials Handbook
4. MatWeb - Online Materials Database
5. Roylance, D. "Mechanics of Materials"

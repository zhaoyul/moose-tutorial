# 第九章：网格生成和管理

## 9.1 网格基础

### 9.1.1 网格的重要性

网格质量直接影响：
- **精度**：网格细化程度决定解的精度
- **计算效率**：单元数量影响计算时间
- **收敛性**：差的网格质量导致不收敛
- **结果可靠性**：扭曲单元产生不准确结果

### 9.1.2 单元类型

**1D 单元**：
- EDGE2：线性（2节点）
- EDGE3：二次（3节点）

**2D 单元**：
- TRI3：线性三角形（3节点）
- TRI6：二次三角形（6节点）
- QUAD4：线性四边形（4节点）
- QUAD8/QUAD9：二次四边形（8/9节点）

**3D 单元**：
- TET4：线性四面体（4节点）
- TET10：二次四面体（10节点）
- HEX8：线性六面体（8节点）
- HEX20/HEX27：二次六面体（20/27节点）
- PRISM6：楔形（6节点）
- PYRAMID5：金字塔（5节点）

### 9.1.3 单元选择原则

**结构化 vs 非结构化**：
- 结构化网格：规则排列，效率高，适合简单几何
- 非结构化网格：灵活，适合复杂几何

**六面体 vs 四面体**：
- 六面体：精度高，收敛快，但生成困难
- 四面体：自动生成容易，但需要更多单元

**一阶 vs 二阶单元**：
- 一阶（线性）：简单快速，需要更细的网格
- 二阶（二次）：精度高，可用粗网格，但计算成本高

## 9.2 MOOSE 内置网格生成

### 9.2.1 GeneratedMesh

最简单的网格生成器，创建规则矩形/立方体网格。

**2D 网格**：

```cpp
[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 10
  ymin = 0
  ymax = 5
  nx = 50   # x 方向单元数
  ny = 25   # y 方向单元数
  elem_type = QUAD4  # QUAD4, QUAD8, QUAD9, TRI3, TRI6
[]
```

**3D 网格**：

```cpp
[Mesh]
  type = GeneratedMesh
  dim = 3
  xmin = 0
  xmax = 10
  ymin = 0
  ymax = 5
  zmin = 0
  zmax = 2
  nx = 50
  ny = 25
  nz = 10
  elem_type = HEX8  # HEX8, HEX20, HEX27, TET4, TET10
[]
```

**偏置网格**（非均匀分布）：

```cpp
[Mesh]
  type = GeneratedMesh
  dim = 2
  xmin = 0
  xmax = 10
  ymin = 0
  ymax = 5
  nx = 50
  ny = 25
  bias_x = 1.1  # x 方向渐变，右侧更密
  bias_y = 0.9  # y 方向渐变，上方更密
[]
```

### 9.2.2 MeshGenerators 系统

更灵活的网格生成方法，支持链式操作。

**基本使用**：

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
  []
  
  [subdomain]
    type = SubdomainBoundingBoxGenerator
    input = gen
    block_id = 1
    bottom_left = '0 0 0'
    top_right = '0.5 1 1'
  []
  
  [refine]
    type = RefineBlockGenerator
    input = subdomain
    block = 1
    refinement = 2  # 细化 2 次
  []
[]
```

### 9.2.3 常用 MeshGenerators

**细化网格**：

```cpp
[Mesh]
  [base]
    type = FileMeshGenerator
    file = 'base_mesh.e'
  []
  
  [refine_box]
    type = RefineBoxGenerator
    input = base
    bottom_left = '0 0 0'
    top_right = '1 1 1'
    refinement = 2
  []
[]
```

**合并网格**：

```cpp
[Mesh]
  [mesh1]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
  []
  
  [mesh2]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
    xmin = 1
    xmax = 2
  []
  
  [combined]
    type = CombinerGenerator
    inputs = 'mesh1 mesh2'
  []
[]
```

**变换网格**：

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
  []
  
  [rotate]
    type = TransformGenerator
    input = gen
    transform = ROTATE
    vector_value = '0 0 45'  # 绕 z 轴旋转 45 度
  []
  
  [translate]
    type = TransformGenerator
    input = rotate
    transform = TRANSLATE
    vector_value = '10 0 0'  # x 方向平移 10 单位
  []
[]
```

## 9.3 导入外部网格

### 9.3.1 支持的格式

MOOSE 通过 libMesh 支持多种网格格式：
- Exodus II (`.e`, `.exo`)
- Gmsh (`.msh`)
- Abaqus (`.inp`)
- ANSYS (`.ans`)
- VTK (`.vtk`, `.vtu`)
- Tetgen (`.node`, `.ele`)

### 9.3.2 导入 Exodus II 网格

```cpp
[Mesh]
  type = FileMesh
  file = 'mesh.e'
[]
```

### 9.3.3 导入 Gmsh 网格

```cpp
[Mesh]
  type = FileMesh
  file = 'mesh.msh'
[]
```

### 9.3.4 导入 Abaqus 网格

```cpp
[Mesh]
  type = FileMesh
  file = 'mesh.inp'
[]
```

## 9.4 使用 Gmsh 生成网格

### 9.4.1 Gmsh 简介

Gmsh 是开源的 3D 有限元网格生成器，功能强大：
- 图形界面和脚本接口
- 支持复杂几何
- CAD 导入
- 网格优化

### 9.4.2 Gmsh 脚本示例

**带孔的平板**（`plate_with_hole.geo`）：

```cpp
// 几何参数
lc = 0.1;  // 特征长度
L = 10;    // 板长
W = 5;     // 板宽
R = 0.5;   // 孔半径

// 定义点
Point(1) = {0, 0, 0, lc};
Point(2) = {L, 0, 0, lc};
Point(3) = {L, W, 0, lc};
Point(4) = {0, W, 0, lc};
Point(5) = {L/2, W/2, 0, lc/5};  // 孔中心

// 外边界
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// 圆孔
Circle(5) = {L/2+R, W/2, 0, R, 2*Pi};

// 定义面
Curve Loop(1) = {1, 2, 3, 4};
Curve Loop(2) = {5};
Plane Surface(1) = {1, 2};

// 网格细化（孔附近）
Field[1] = Distance;
Field[1].NodesList = {5};

Field[2] = Threshold;
Field[2].IField = 1;
Field[2].LcMin = lc / 5;
Field[2].LcMax = lc;
Field[2].DistMin = R;
Field[2].DistMax = 2*R;

Background Field = 2;

// 物理组（边界和域）
Physical Surface("domain") = {1};
Physical Curve("left") = {4};
Physical Curve("right") = {2};
Physical Curve("top") = {3};
Physical Curve("bottom") = {1};
Physical Curve("hole") = {5};

// 网格选项
Mesh.Algorithm = 6;  // Frontal-Delaunay
Mesh.ElementOrder = 2;  // 二阶单元
```

**生成网格**：

```bash
gmsh -2 plate_with_hole.geo -o plate_with_hole.msh
```

### 9.4.3 3D Gmsh 示例

**圆柱体**（`cylinder.geo`）：

```cpp
// 参数
lc = 0.1;
R = 1.0;   // 半径
H = 3.0;   // 高度

// 底面圆心
Point(1) = {0, 0, 0, lc};

// 底面圆周
Point(2) = {R, 0, 0, lc};
Point(3) = {0, R, 0, lc};
Point(4) = {-R, 0, 0, lc};
Point(5) = {0, -R, 0, lc};

// 底面圆弧
Circle(1) = {2, 1, 3};
Circle(2) = {3, 1, 4};
Circle(3) = {4, 1, 5};
Circle(4) = {5, 1, 2};

// 底面
Curve Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// 拉伸成圆柱
Extrude {0, 0, H} {
  Surface{1}; Layers{30}; Recombine;
}

// 物理组
Physical Volume("volume") = {1};
Physical Surface("bottom") = {1};
Physical Surface("top") = {26};
Physical Surface("side") = {13, 17, 21, 25};
```

## 9.5 网格质量评估

### 9.5.1 质量指标

**长宽比（Aspect Ratio）**：
$$AR = \frac{\text{最长边}}{\text{最短边}}$$

理想值：接近 1
可接受：< 10
差：> 100

**偏斜度（Skewness）**：
$$\text{Skew} = \frac{\text{最大角} - 90°}{90°}$$

或者：
$$\text{Skew} = \frac{90° - \text{最小角}}{90°}$$

理想值：0
可接受：< 0.5
差：> 0.9

**雅可比行列式**：
$$J = \det\left(\frac{\partial \vec{x}}{\partial \vec{\xi}}\right)$$

必须：J > 0（正）
理想：J 变化不大

**正交性（Orthogonality）**：
测量单元边之间的角度接近 90° 的程度。

### 9.5.2 MOOSE 中检查网格质量

```cpp
[Mesh]
  [gen]
    type = FileMeshGenerator
    file = 'mesh.e'
  []
  
  [quality]
    type = MeshQualityGenerator
    input = gen
  []
[]

[Outputs]
  [quality_out]
    type = Exodus
    execute_on = 'initial'
  []
[]
```

然后在 Paraview 中查看质量指标。

### 9.5.3 命令行检查

```bash
# 使用 MOOSE 的网格工具
moose-mesh-quality -i input_mesh.e -o quality_output

# 在输入文件中添加
[Mesh]
  check_mesh_quality = true
  quality_threshold = 0.5
[]
```

## 9.6 网格自适应细化

### 9.6.1 h-适应性（网格细化）

根据误差估计自适应细化网格。

**基于误差指示器**：

```cpp
[Adaptivity]
  marker = error_marker
  max_h_level = 3  # 最多细化 3 次
  
  [Indicators]
    [error_indicator]
      type = GradientJumpIndicator
      variable = von_mises_stress
    []
  []
  
  [Markers]
    [error_marker]
      type = ErrorFractionMarker
      indicator = error_indicator
      refine = 0.6   # 细化误差最大的 60%
      coarsen = 0.2  # 粗化误差最小的 20%
    []
  []
[]
```

**基于几何位置**：

```cpp
[Adaptivity]
  marker = box_marker
  max_h_level = 2
  initial_steps = 2  # 初始细化步数
  
  [Markers]
    [box_marker]
      type = BoxMarker
      bottom_left = '0 0 0'
      top_right = '1 1 1'
      inside = refine
      outside = dont_mark
    []
  []
[]
```

### 9.6.2 p-适应性（阶次提升）

提高单元的插值阶次而不是细化网格（MOOSE 支持有限）。

## 9.7 网格分区（并行计算）

### 9.7.1 自动分区

MOOSE 自动使用 METIS 或 ParMETIS 进行网格分区：

```bash
mpiexec -n 4 ./app-opt -i input.i
```

### 9.7.2 手动分区

```cpp
[Mesh]
  type = FileMesh
  file = 'mesh.e'
  parallel_type = distributed  # 分布式网格
  # parallel_type = replicated  # 复制网格（所有进程有完整网格）
[]
```

### 9.7.3 可视化分区

```cpp
[AuxVariables]
  [proc_id]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [proc_id_aux]
    type = ProcessorIDAux
    variable = proc_id
    execute_on = 'initial'
  []
[]
```

## 9.8 特殊网格技术

### 9.8.1 层状网格（复合材料）

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 20
    zmax = 1.0
  []
  
  # 定义层
  [layer1]
    type = SubdomainBoundingBoxGenerator
    input = gen
    block_id = 1
    block_name = 'layer1'
    bottom_left = '0 0 0'
    top_right = '1 1 0.25'
  []
  
  [layer2]
    type = SubdomainBoundingBoxGenerator
    input = layer1
    block_id = 2
    block_name = 'layer2'
    bottom_left = '0 0 0.25'
    top_right = '1 1 0.5'
  []
  
  # ... 更多层
[]
```

### 9.8.2 扫掠网格

对 2D 网格进行拉伸生成 3D 网格：

```cpp
[Mesh]
  [base_mesh]
    type = FileMeshGenerator
    file = 'cross_section.e'  # 2D 截面
  []
  
  [extrude]
    type = AdvancedExtruderGenerator
    input = base_mesh
    heights = '0.5 0.5 1.0'  # 每层高度
    num_layers = '5 5 10'    # 每层单元数
    direction = '0 0 1'      # 拉伸方向
  []
[]
```

### 9.8.3 旋转网格（轴对称到 3D）

```cpp
[Mesh]
  [base_mesh]
    type = FileMeshGenerator
    file = 'axisymmetric.e'  # r-z 平面网格
  []
  
  [revolve]
    type = RevolveGenerator
    input = base_mesh
    angle = 360
    axis_point = '0 0 0'
    axis_direction = '0 0 1'
    num_slices = 36  # 旋转分成 36 份
  []
[]
```

## 9.9 网格优化

### 9.9.1 光顺（Smoothing）

改善网格质量：

```cpp
[Mesh]
  [gen]
    type = FileMeshGenerator
    file = 'rough_mesh.e'
  []
  
  [smooth]
    type = MeshSmoothingGenerator
    input = gen
    iterations = 5
  []
[]
```

### 9.9.2 单元转换

```cpp
[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 10
    ny = 10
    nz = 10
    elem_type = HEX8
  []
  
  # 转换为二阶单元
  [convert]
    type = MeshConvertGenerator
    input = gen
    convert_to = HEX20
  []
[]
```

## 9.10 实用工具和最佳实践

### 9.10.1 网格收敛性研究

```bash
#!/bin/bash
# 网格收敛性研究脚本

for n in 10 20 40 80 160; do
  echo "Running with nx=$n"
  ./app-opt -i input.i \
    Mesh/gen/nx=$n \
    Mesh/gen/ny=$n \
    Mesh/gen/nz=$n \
    Outputs/file_base=results_n${n}
done

# 提取和比较结果
python analyze_convergence.py
```

### 9.10.2 网格生成检查清单

- [ ] 单元类型适合问题
- [ ] 网格足够细以捕捉解的变化
- [ ] 质量指标在可接受范围
- [ ] 边界正确定义和命名
- [ ] 材料子域正确分配
- [ ] 对关键区域进行局部细化
- [ ] 验证网格收敛性

### 9.10.3 性能考虑

**最小化单元数量**：
- 利用对称性
- 使用自适应细化
- 只在需要的地方细化

**平衡精度和效率**：
- 起始网格不要太细
- 使用二阶单元减少单元数
- 在并行计算中考虑负载平衡

## 9.11 完整示例

参见 `examples/` 目录：
- `adaptive_refinement.i` - 自适应网格细化
- `imported_gmsh_mesh.i` - 导入 Gmsh 网格
- `mesh_quality_check.i` - 网格质量检查

## 9.12 练习

### 练习 1：生成简单网格
使用 GeneratedMesh 创建不同网格：
- 2D 矩形，不同单元类型
- 3D 立方体，比较 HEX8 和 TET4
- 偏置网格

### 练习 2：Gmsh 网格
使用 Gmsh 创建复杂几何：
- 带孔的平板
- L 型区域
- 3D 圆柱

### 练习 3：网格质量
评估网格质量：
- 生成不同质量的网格
- 使用质量指标比较
- 改善差的网格

### 练习 4：自适应细化
实现自适应细化：
- 设置误差指示器
- 运行细化
- 比较收敛速度

### 练习 5：网格收敛性
进行网格收敛性研究：
- 使用多个网格密度
- 绘制误差 vs 网格尺寸
- 确定收敛阶

### 练习 6：多材料网格
创建多材料结构网格：
- 定义多个子域
- 分配不同材料
- 验证界面处理

## 9.13 故障排除

### 9.13.1 常见网格问题

**负雅可比行列式**：
```
错误：Negative Jacobian detected
原因：单元严重扭曲或翻转
解决：
  - 改善网格质量
  - 检查几何定义
  - 减少单元尺寸变化率
```

**不兼容的网格**：
```
症状：导入网格失败
原因：格式不支持或文件损坏
解决：
  - 验证文件格式
  - 使用正确的导入选项
  - 转换为支持的格式
```

**边界未定义**：
```
错误：Boundary 'name' not found
解决：
  - 检查网格文件中的边界定义
  - 使用正确的边界名称
  - 在 Paraview 中可视化边界
```

## 9.14 小结

本章详细介绍了网格生成和管理：

- ✓ 网格基础和单元类型
- ✓ MOOSE 内置网格生成
- ✓ 外部网格导入（Gmsh 等）
- ✓ 网格质量评估和优化
- ✓ 自适应网格细化
- ✓ 网格分区和并行计算
- ✓ 实用技巧和最佳实践

## 下一章

下一章将详细讨论后处理技术和结果可视化。

---

**参考文献**

1. MOOSE Mesh System Documentation
2. Gmsh Documentation: http://gmsh.info
3. Knupp, P.M. "Remarks on Mesh Quality"
4. Zienkiewicz, O.C. "The Finite Element Method"
5. Geuzaine, C. and Remacle, J.F. "Gmsh: A 3-D finite element mesh generator"

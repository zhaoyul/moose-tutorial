# Gmsh 网格生成集成

本目录包含使用 Gmsh 生成网格并进行 MOOSE 仿真的完整流程。

## 安装 Gmsh

### Arch Linux (AUR)
```bash
# 安装依赖
echo "007a007b" | sudo -S pacman -S cmake blas lapack opencascade fltk

# 从 AUR 安装 yay -S gmsh
# 或手动下载安装
cd /tmp
wget https://gmsh.info/bin/Linux/gmsh-4.13.1-Linux64-sdk.tgz
tar -xzf gmsh-4.13.1-Linux64-sdk.tgz
export PATH=$PATH:/tmp/gmsh-4.13.1-Linux64-sdk/bin
export PYTHONPATH=$PYTHONPATH:/tmp/gmsh-4.13.1-Linux64-sdk/lib
```

### Ubuntu/Debian
```bash
sudo apt-get install gmsh python3-gmsh
```

### Conda
```bash
conda install -c conda-forge gmsh
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `generate_mesh_gmsh.py` | Gmsh Python 脚本，生成带物理组的网格 |
| `simulation_with_gmsh.i` | 使用 Gmsh 网格的 MOOSE 输入文件 |
| `cantilever_beam.geo` | Gmsh 几何文件（备用） |
| `run_gmsh_workflow.sh` | 完整工作流程脚本 |

## 使用流程

### 1. 生成网格

```bash
python3 generate_mesh_gmsh.py --lc 0.05 -o cantilever_beam.msh
```

选项：
- `--lc 0.05`: 网格特征长度（越小网格越密）
- `--order 2`: 使用二阶单元
- `-o filename.msh`: 输出文件名

### 2. 检查网格

```bash
# 查看网格统计
gmsh -info cantilever_beam.msh

# 可视化网格
gmsh cantilever_beam.msh
```

### 3. 运行仿真

```bash
combined-opt -i simulation_with_gmsh.i
```

### 4. 后处理

```bash
python3 postprocess.py gmsh_simulation_out
```

## 物理组定义

Gmsh 脚本自动定义以下物理组：

| 物理组名称 | 类型 | 说明 | MOOSE 中用途 |
|-----------|------|------|-------------|
| `beam_volume` | Volume (3D) | 整个梁体积 | 材料属性应用 |
| `fixed_end` | Surface (2D) | 固定端面 (x=0) | DirichletBC |
| `free_end` | Surface (2D) | 自由端面 (x=L) | 对流边界 |
| `top` | Surface (2D) | 顶面 (z=H) | 压力载荷 |
| `bottom` | Surface (2D) | 底面 (z=0) | - |
| `front` | Surface (2D) | 前面 (y=W) | 剪切载荷 |
| `back` | Surface (2D) | 后面 (y=0) | - |
| `loading_point` | Point (0D) | 加载点 | 集中力 |

## 网格细化

### 方法1: 调整特征长度
```bash
# 粗网格 (快速计算)
python3 generate_mesh_gmsh.py --lc 0.1

# 细网格 (高精度)
python3 generate_mesh_gmsh.py --lc 0.02
```

### 方法2: 自适应细化
编辑 `generate_mesh_gmsh.py`，修改场函数参数：
```python
# 在固定端和自由端细化
gmsh.model.mesh.field.setNumber(1, "VIn", lc/4)  # 细化区域网格尺寸
```

### 方法3: 二阶单元
```bash
python3 generate_mesh_gmsh.py --order 2
```

## 对比：Gmsh vs 内置生成器

| 特性 | Gmsh | MOOSE 内置 |
|------|------|-----------|
| 复杂几何 | ✅ 支持 | ❌ 简单几何 |
| 非结构化网格 | ✅ 支持 | ❌ 仅结构化 |
| 网格自适应 | ✅ 支持 | 有限支持 |
| 物理组标记 | ✅ 灵活 | 有限 |
| 混合单元 | ✅ 支持 | ❌ 不支持 |
| 学习曲线 | 较陡 | 平缓 |
| 计算效率 | 相同 | 相同 |

## 常见问题

### Q: Gmsh 网格导入 MOOSE 失败？

**A:** 检查以下事项：
1. 使用正确的 MSH 格式版本：
   ```bash
   python3 generate_mesh_gmsh.py --format msh41
   ```
2. 确认物理组名称与输入文件中的边界名称匹配
3. 检查网格质量：
   ```bash
   gmsh -check cantilever_beam.msh
   ```

### Q: 如何查看物理组？

**A:** 在 Gmsh GUI 中：
1. 打开网格文件：`gmsh cantilever_beam.msh`
2. Tools → Visibility
3. 在左侧列表中查看 Physical Groups

或使用命令行：
```bash
gmsh -info cantilever_beam.msh | grep "Physical"
```

### Q: 如何添加更多监测点？

**A:** 编辑 `generate_mesh_gmsh.py`，添加新的点物理组：
```python
# 创建点
p_monitor = gmsh.model.geo.addPoint(x, y, z, lc)
gmsh.model.geo.synchronize()

# 添加物理组
gmsh.model.addPhysicalGroup(0, [p_monitor], tag=21, name="monitor_point")
```

然后在 MOOSE 输入文件中使用：
```cpp
[NodalKernels]
  [monitor_load]
    type = ConstantRate
    variable = disp_z
    boundary = 'monitor_point'
    rate = -1000
  []
[]
```

## 高级功能

### 网格自适应

Gmsh 支持基于场的自适应网格：

```python
# 在应力集中区域细化
gmsh.model.mesh.field.add("Box", 1)
gmsh.model.mesh.field.setNumber(1, "VIn", lc/4)  # 内部网格尺寸
gmsh.model.mesh.field.setNumber(1, "VOut", lc)   # 外部网格尺寸
gmsh.model.mesh.field.setNumber(1, "XMin", 0)
gmsh.model.mesh.field.setNumber(1, "XMax", 0.3)  # 固定端区域
gmsh.model.mesh.field.setAsBackgroundMesh(1)
```

### 周期性网格

对于周期性结构：

```python
# 定义周期性边界
gmsh.model.mesh.setPeriodic(2, [surf_right], [surf_left], 
    [1, 0, 0, L, 0, 1, 0, 0, 0, 0, 1, 0])
```

### 多种单元类型

Gmsh 支持混合网格：
- HEX8/HEX20/HEX27: 六面体
- TET4/TET10: 四面体
- PRISM6/PRISM15: 棱柱
- PYRAMID5: 金字塔

```bash
# 生成四面体网格（自动）
python3 generate_mesh_gmsh.py --lc 0.05

# 强制六面体网格（需要特殊算法）
# 编辑脚本，添加：
# gmsh.model.mesh.setRecombine(2, surf_tag)
```

## 完整工作流程脚本

```bash
#!/bin/bash
# run_gmsh_workflow.sh

set -e

echo "=== Step 1: Generate Gmsh mesh ==="
python3 generate_mesh_gmsh.py --lc 0.05 --order 1 -o cantilever_beam.msh

echo "=== Step 2: Check mesh ==="
gmsh -info cantilever_beam.msh

echo "=== Step 3: Run MOOSE simulation ==="
combined-opt -i simulation_with_gmsh.i 2>&1 | tee simulation.log

echo "=== Step 4: Postprocess ==="
python3 postprocess.py gmsh_simulation_out

echo "=== Done! ==="
```

## 参考资源

- [Gmsh 文档](https://gmsh.info/doc/texinfo/gmsh.html)
- [Gmsh Python API](https://gitlab.onelab.info/gmsh/gmsh/blob/master/tutorial/python/README.txt)
- [MOOSE Mesh 文档](https://mooseframework.inl.gov/syntax/Mesh/index.html)

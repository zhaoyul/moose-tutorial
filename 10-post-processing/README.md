# 第十章：后处理和可视化

## 10.1 后处理概述

### 10.1.1 后处理的目的

- **结果验证**：检查解的合理性
- **数据提取**：获取关键数值（最大应力、位移等）
- **可视化**：直观理解场分布
- **报告生成**：为工程报告准备图表和数据
- **趋势分析**：研究参数影响和时间历史

### 10.1.2 MOOSE 后处理工具

**内置工具**：
- Postprocessors：标量值计算
- VectorPostprocessors：向量/矩阵数据
- AuxVariables/AuxKernels：派生场变量
- Outputs：多种输出格式

**外部工具**：
- **Paraview**：强大的 3D 可视化
- **MATLAB/Python**：数据分析和绘图
- **Gnuplot**：快速绘图
- **Visit**：科学可视化

## 10.2 Postprocessors

### 10.2.1 概念

Postprocessors 计算标量值，如：
- 极值（最大/最小）
- 积分（总量）
- 平均值
- 反力
- 误差估计

### 10.2.2 极值 Postprocessors

**节点极值**：

```cpp
[Postprocessors]
  [max_temperature]
    type = NodalExtremeValue
    variable = temperature
    value_type = max  # max, min, abs_max, abs_min
  []
  
  [min_displacement]
    type = NodalExtremeValue
    variable = disp_z
    value_type = min
  []
[]
```

**单元极值**：

```cpp
[Postprocessors]
  [max_von_mises]
    type = ElementExtremeValue
    variable = von_mises_stress
    value_type = max
  []
  
  [max_strain_energy_density]
    type = ElementExtremeValue
    variable = strain_energy_density
    value_type = max
  []
[]
```

**边界极值**：

```cpp
[Postprocessors]
  [max_boundary_stress]
    type = NodalExtremeValue
    variable = stress_xx
    boundary = 'top'
    value_type = max
  []
[]
```

### 10.2.3 积分 Postprocessors

**体积积分**：

```cpp
[Postprocessors]
  # 变量的体积积分
  [total_strain_energy]
    type = ElementIntegralVariablePostprocessor
    variable = strain_energy_density
  []
  
  # 材料属性的体积积分
  [total_mass]
    type = ElementIntegralMaterialProperty
    mat_prop = density
  []
[]
```

**面积积分**：

```cpp
[Postprocessors]
  # 边界上的积分
  [total_force]
    type = SideIntegralVariablePostprocessor
    variable = stress_xx
    boundary = 'right'
  []
  
  # 通量积分
  [heat_flux_out]
    type = SideFluxIntegral
    variable = temperature
    boundary = 'outer_surface'
    diffusivity = thermal_conductivity
  []
[]
```

### 10.2.4 平均值 Postprocessors

```cpp
[Postprocessors]
  # 单元平均
  [avg_temperature]
    type = ElementAverageValue
    variable = temperature
  []
  
  # 边界平均
  [avg_stress_boundary]
    type = SideAverageValue
    variable = stress_xx
    boundary = 'top'
  []
  
  # 节点平均
  [avg_displacement]
    type = NodalAverageValue
    variable = disp_z
  []
[]
```

### 10.2.5 反力计算

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
  
  # 总反力
  [total_reaction]
    type = ParsedPostprocessor
    pp_names = 'reaction_force_x reaction_force_y reaction_force_z'
    expression = 'sqrt(reaction_force_x^2 + reaction_force_y^2 + reaction_force_z^2)'
  []
[]
```

### 10.2.6 组合 Postprocessors

使用已有 Postprocessors 计算新值：

```cpp
[Postprocessors]
  [stress_xx_max]
    type = ElementExtremeValue
    variable = stress_xx
    value_type = max
  []
  
  [stress_yy_max]
    type = ElementExtremeValue
    variable = stress_yy
    value_type = max
  []
  
  # 计算组合应力
  [combined_stress]
    type = ParsedPostprocessor
    pp_names = 'stress_xx_max stress_yy_max'
    expression = 'sqrt(stress_xx_max^2 + stress_yy_max^2)'
  []
  
  # 安全系数
  [safety_factor]
    type = ParsedPostprocessor
    pp_names = 'combined_stress'
    constant_names = 'yield_stress'
    constant_expressions = '250e6'
    expression = 'yield_stress / combined_stress'
  []
[]
```

## 10.3 VectorPostprocessors

### 10.3.1 概念

VectorPostprocessors 计算向量/矩阵数据：
- 沿线采样
- 沿面采样
- 时间历史数据
- 统计分布

### 10.3.2 线采样

```cpp
[VectorPostprocessors]
  [line_sample]
    type = LineValueSampler
    variable = 'disp_x disp_y disp_z stress_xx stress_yy stress_zz'
    start_point = '0 0 0'
    end_point = '10 0 0'
    num_points = 100
    sort_by = x  # x, y, z, id
  []
[]
```

**多条线采样**：

```cpp
[VectorPostprocessors]
  [lines_y]
    type = LineValueSampler
    variable = 'temperature'
    start_point = '0 0 0
                   0 1 0
                   0 2 0'
    end_point = '10 0 0
                 10 1 0
                 10 2 0'
    num_points = 50
    sort_by = id
  []
[]
```

### 10.3.3 面采样

```cpp
[VectorPostprocessors]
  [surface_sample]
    type = PointValueSampler
    variable = 'von_mises_stress'
    points = '0 0 0
              1 0 0
              2 0 0
              0 1 0
              1 1 0
              2 1 0'
    sort_by = id
  []
[]
```

### 10.3.4 节点值采样

```cpp
[VectorPostprocessors]
  [nodal_values]
    type = NodalValueSampler
    variable = 'disp_x disp_y disp_z'
    boundary = 'top'
    sort_by = id
  []
[]
```

### 10.3.5 时间历史

```cpp
[VectorPostprocessors]
  [time_history]
    type = PointValueSampler
    variable = 'disp_z'
    points = '5.0 2.5 1.0'  # 监测点
    execute_on = 'initial timestep_end'
  []
[]
```

### 10.3.6 统计分布

```cpp
[VectorPostprocessors]
  [stress_distribution]
    type = ElementVariablesDifferenceMax
    variable1 = stress_xx
    variable2 = stress_yy
  []
[]
```

## 10.4 输出格式

### 10.4.1 Exodus II 格式

最常用的格式，用于 Paraview 可视化：

```cpp
[Outputs]
  [exodus]
    type = Exodus
    file_base = results
    interval = 1  # 每步输出
    # interval = 10  # 每 10 步输出
    elemental_as_nodal = true  # 将单元变量插值到节点
    execute_on = 'initial timestep_end'
  []
[]
```

**输出特定变量**：

```cpp
[Outputs]
  [exodus]
    type = Exodus
    # 只输出指定变量
    show = 'disp_x disp_y disp_z stress_xx stress_yy stress_zz'
    # 或排除某些变量
    hide = 'intermediate_variable'
  []
[]
```

### 10.4.2 CSV 格式

输出 Postprocessors 和 VectorPostprocessors 数据：

```cpp
[Outputs]
  [csv]
    type = CSV
    file_base = results
    execute_on = 'initial timestep_end'
  []
[]
```

**分离输出**：

```cpp
[Outputs]
  [pp_csv]
    type = CSV
    file_base = postprocessors
    execute_postprocessors_on = 'initial timestep_end'
  []
  
  [vpp_csv]
    type = CSV
    file_base = vectorpostprocessors
    execute_vector_postprocessors_on = 'initial timestep_end'
  []
[]
```

### 10.4.3 控制台输出

```cpp
[Outputs]
  [console]
    type = Console
    perf_log = true              # 性能日志
    output_linear = true         # 线性迭代信息
    output_nonlinear = true      # 非线性迭代信息
    print_mesh_changed_info = true
  []
[]
```

### 10.4.4 Checkpoint 输出

用于重启计算：

```cpp
[Outputs]
  [checkpoint]
    type = Checkpoint
    num_files = 2      # 保留最近 2 个检查点
    interval = 100     # 每 100 步保存
  []
[]
```

### 10.4.5 Nemesis 格式

并行计算的分布式输出：

```cpp
[Outputs]
  [nemesis]
    type = Nemesis
    file_base = results
  []
[]
```

## 10.5 Paraview 可视化

### 10.5.1 Paraview 基础

**启动 Paraview**：
```bash
paraview results.e
```

**基本操作**：
1. 打开文件：File → Open
2. 应用：点击 "Apply"
3. 选择变量：在左侧面板选择
4. 调整显示：工具栏中的显示选项

### 10.5.2 常用滤镜

**切片（Slice）**：
1. Filters → Slice
2. 选择切平面方向
3. 调整位置
4. Apply

**等值面（Isosurface/Contour）**：
1. Filters → Contour
2. 选择变量
3. 设置等值
4. Apply

**变形显示（Warp by Vector）**：
```
显示位移场：
1. Filters → Warp By Vector
2. Vector: displacement
3. Scale Factor: 调整放大倍数
4. Apply
```

**裁剪（Clip）**：
1. Filters → Clip
2. 选择裁剪类型（平面、盒子、球）
3. 调整位置和方向
4. Apply

**计算器（Calculator）**：
```
计算新变量：
1. Filters → Calculator
2. Result Array Name: 输入新变量名
3. Expression: 输入公式
   例如：sqrt(stress_xx^2 + stress_yy^2 + stress_zz^2)
4. Apply
```

### 10.5.3 时间动画

**创建动画**：
1. View → Animation View
2. 设置时间步
3. 添加关键帧
4. File → Save Animation

**保存截图**：
```
File → Save Screenshot
选择分辨率和格式
```

### 10.5.4 高级可视化

**矢量场（Glyph）**：
```
1. Filters → Glyph
2. Glyph Type: Arrow
3. Scale Mode: vector
4. Scale Factor: 调整箭头大小
5. Apply
```

**流线（Stream Tracer）**：
```
1. Filters → Stream Tracer
2. Seed Type: Point Source
3. 设置种子点
4. Apply
```

**体渲染（Volume Rendering）**：
```
1. 选择 3D 数据
2. 在显示属性中选择 "Volume"
3. 调整传递函数
```

### 10.5.5 Python 脚本自动化

Paraview 支持 Python 脚本：

```python
# paraview_script.py
from paraview.simple import *

# 加载数据
reader = ExodusIIReader(FileName='results.e')
reader.UpdatePipeline()

# 创建视图
view = CreateView('RenderView')
display = Show(reader, view)

# 设置颜色映射
ColorBy(display, ('POINTS', 'von_mises_stress'))

# 添加颜色条
colorbar = GetScalarBar('von_mises_stress', view)
colorbar.Title = 'Von Mises Stress (Pa)'

# 保存图像
SaveScreenshot('stress_plot.png', view, ImageResolution=[1920, 1080])
```

运行：
```bash
pvpython paraview_script.py
```

## 10.6 数据分析（Python）

### 10.6.1 读取 CSV 数据

```python
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# 读取 Postprocessor 数据
pp_data = pd.read_csv('results.csv')

# 绘制时间历史
plt.figure(figsize=(10, 6))
plt.plot(pp_data['time'], pp_data['max_von_mises'], 'b-', linewidth=2)
plt.xlabel('Time (s)', fontsize=12)
plt.ylabel('Max von Mises Stress (Pa)', fontsize=12)
plt.title('Stress History', fontsize=14)
plt.grid(True)
plt.savefig('stress_history.png', dpi=300)
plt.show()
```

### 10.6.2 读取 VectorPostprocessor 数据

```python
# 读取线采样数据
line_data = pd.read_csv('results_line_sample_0001.csv')

# 绘制分布
plt.figure(figsize=(10, 6))
plt.plot(line_data['x'], line_data['disp_z'], 'ro-', label='Displacement Z')
plt.xlabel('Position (m)', fontsize=12)
plt.ylabel('Displacement (m)', fontsize=12)
plt.legend()
plt.grid(True)
plt.savefig('displacement_profile.png', dpi=300)
plt.show()
```

### 10.6.3 多时间步分析

```python
import glob

# 读取所有时间步的数据
files = sorted(glob.glob('results_line_sample_*.csv'))

plt.figure(figsize=(10, 6))
for i, file in enumerate(files[::10]):  # 每 10 步绘制一次
    data = pd.read_csv(file)
    plt.plot(data['x'], data['stress_xx'], 
             label=f'Step {i*10}', alpha=0.7)

plt.xlabel('Position (m)')
plt.ylabel('Stress XX (Pa)')
plt.legend()
plt.grid(True)
plt.savefig('stress_evolution.png', dpi=300)
plt.show()
```

### 10.6.4 统计分析

```python
# 计算统计量
stats = {
    'mean': pp_data['max_von_mises'].mean(),
    'std': pp_data['max_von_mises'].std(),
    'max': pp_data['max_von_mises'].max(),
    'min': pp_data['max_von_mises'].min()
}

print("Statistics:")
for key, value in stats.items():
    print(f"  {key}: {value:.2e}")

# 绘制直方图
plt.figure(figsize=(10, 6))
plt.hist(pp_data['max_von_mises'], bins=50, edgecolor='black')
plt.xlabel('Von Mises Stress (Pa)')
plt.ylabel('Frequency')
plt.title('Stress Distribution')
plt.savefig('stress_histogram.png', dpi=300)
plt.show()
```

## 10.7 使用 Exodus II Python 库

### 10.7.1 安装

```bash
pip install netCDF4
# 或
conda install -c conda-forge netcdf4
```

### 10.7.2 读取 Exodus 文件

```python
from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt

# 打开 Exodus 文件
exo = Dataset('results.e', 'r')

# 读取时间步
time = exo.variables['time_whole'][:]

# 读取节点坐标
x = exo.variables['coordx'][:]
y = exo.variables['coordy'][:]
z = exo.variables['coordz'][:]

# 读取节点变量（例如位移）
disp_x = exo.variables['vals_nod_var1'][:, :]  # 所有时间步

# 读取单元变量（例如应力）
stress_xx = exo.variables['vals_elem_var1'][:, :]

exo.close()

# 绘制最后时间步的位移云图
plt.figure(figsize=(10, 6))
plt.tricontourf(x, y, disp_x[-1, :], levels=20)
plt.colorbar(label='Displacement X (m)')
plt.xlabel('X (m)')
plt.ylabel('Y (m)')
plt.title('Displacement Field')
plt.axis('equal')
plt.savefig('displacement_contour.png', dpi=300)
plt.show()
```

## 10.8 报告生成

### 10.8.1 自动化报告

```python
# generate_report.py
import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

def generate_report(csv_file, output_pdf):
    # 读取数据
    data = pd.read_csv(csv_file)
    
    # 创建 PDF
    with PdfPages(output_pdf) as pdf:
        # 第1页：时间历史
        fig, axes = plt.subplots(2, 2, figsize=(11, 8.5))
        
        axes[0, 0].plot(data['time'], data['max_von_mises'])
        axes[0, 0].set_xlabel('Time (s)')
        axes[0, 0].set_ylabel('Max Stress (Pa)')
        axes[0, 0].set_title('Stress History')
        axes[0, 0].grid(True)
        
        axes[0, 1].plot(data['time'], data['max_disp_z'])
        axes[0, 1].set_xlabel('Time (s)')
        axes[0, 1].set_ylabel('Max Displacement (m)')
        axes[0, 1].set_title('Displacement History')
        axes[0, 1].grid(True)
        
        axes[1, 0].plot(data['time'], data['strain_energy'])
        axes[1, 0].set_xlabel('Time (s)')
        axes[1, 0].set_ylabel('Strain Energy (J)')
        axes[1, 0].set_title('Energy History')
        axes[1, 0].grid(True)
        
        # 统计信息
        stats_text = f"""
        Summary Statistics:
        
        Max Stress: {data['max_von_mises'].max():.2e} Pa
        Max Displacement: {data['max_disp_z'].max():.2e} m
        Total Energy: {data['strain_energy'].iloc[-1]:.2e} J
        
        Time Steps: {len(data)}
        Total Time: {data['time'].iloc[-1]:.2f} s
        """
        axes[1, 1].text(0.1, 0.5, stats_text, 
                       fontsize=10, verticalalignment='center')
        axes[1, 1].axis('off')
        
        plt.tight_layout()
        pdf.savefig()
        plt.close()

# 使用
generate_report('results.csv', 'analysis_report.pdf')
```

### 10.8.2 LaTeX 表格生成

```python
# 生成 LaTeX 表格
def create_latex_table(data):
    latex = "\\begin{table}[h]\n"
    latex += "\\centering\n"
    latex += "\\begin{tabular}{|c|c|c|}\n"
    latex += "\\hline\n"
    latex += "Parameter & Value & Unit \\\\\n"
    latex += "\\hline\n"
    latex += f"Max Stress & {data['max_von_mises'].max():.2e} & Pa \\\\\n"
    latex += f"Max Displacement & {data['max_disp_z'].max():.2e} & m \\\\\n"
    latex += f"Strain Energy & {data['strain_energy'].iloc[-1]:.2e} & J \\\\\n"
    latex += "\\hline\n"
    latex += "\\end{tabular}\n"
    latex += "\\caption{Analysis Results}\n"
    latex += "\\end{table}\n"
    
    return latex

data = pd.read_csv('results.csv')
print(create_latex_table(data))
```

## 10.9 实用工具

### 10.9.1 MOOSE 的 peacock

图形界面工具：

```bash
peacock -i input.i
```

功能：
- 输入文件编辑
- 参数设置
- 运行模拟
- 结果可视化

### 10.9.2 MOOSEDocs 工具

```bash
# 生成文档
./moosedocs.py build --serve

# 查看语法
./moosedocs.py syntax MyApp
```

## 10.10 完整示例

参见 `examples/complete_postprocessing.i`

## 10.11 练习

### 练习 1：基本后处理
设置完整的后处理：
- 多个 Postprocessors
- 线采样
- 反力计算
- CSV 输出

### 练习 2：Paraview 可视化
使用 Paraview：
- 创建应力云图
- 添加变形显示
- 制作时间动画
- 保存高质量图像

### 练习 3：Python 数据分析
编写 Python 脚本：
- 读取 CSV 数据
- 绘制多个图表
- 计算统计量
- 生成报告

### 练习 4：对比分析
比较多个工况：
- 运行多个算例
- 提取关键结果
- 绘制对比图
- 分析差异

### 练习 5：自动化工作流
创建完整自动化流程：
- 运行模拟
- 提取数据
- 生成图表
- 创建 PDF 报告

## 10.12 最佳实践

### 10.12.1 后处理检查清单

- [ ] 验证结果合理性（数量级、趋势）
- [ ] 检查守恒量（能量、质量等）
- [ ] 验证边界条件满足
- [ ] 比较解析解或参考解
- [ ] 检查网格收敛性
- [ ] 记录关键结果和图表
- [ ] 保存原始数据和脚本

### 10.12.2 可视化技巧

- 使用合适的颜色映射
- 添加清晰的标签和单位
- 显示变形时使用适当的放大因子
- 多视角检查 3D 结果
- 使用切片查看内部场
- 保存高分辨率图像用于出版

### 10.12.3 数据管理

- 组织文件结构
- 使用描述性文件名
- 记录参数和设置
- 版本控制输入文件
- 备份重要结果

## 10.13 小结

本章详细介绍了后处理和可视化：

- ✓ Postprocessors 和 VectorPostprocessors
- ✓ 多种输出格式
- ✓ Paraview 可视化技术
- ✓ Python 数据分析
- ✓ 自动化报告生成
- ✓ 最佳实践和工作流程

## 下一章

下一章将讨论非线性问题的求解，包括材料非线性和几何非线性。

---

**参考文献**

1. Paraview Guide: https://www.paraview.org/documentation/
2. MOOSE Postprocessors Documentation
3. Python Data Science Handbook
4. Matplotlib Documentation
5. VTK User's Guide

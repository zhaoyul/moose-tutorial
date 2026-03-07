# 完整仿真流程

本目录包含一个完整的 MOOSE 仿真流程示例，整合前序章节的所有重要特性。

## 目录结构

```
complete-simulation/
├── README.md                      # 本文件
├── complete_simulation.i          # 完整仿真输入文件
├── simple_demo.i                  # 简化版（快速测试）
├── postprocess.py                 # Python 后处理脚本
├── run_simulation.sh              # 自动化运行脚本
└── postprocessing_results/        # 后处理输出（运行后生成）
```

## 功能特性

### 物理模型
- **耦合场分析**：温度-力学耦合
- **热传导**：稳态热传导方程
- **线弹性力学**：小变形假设
- **热应力**：考虑热膨胀

### 网格
- 结构化六面体网格（HEX8）
- 边界标记（固定端、自由端、中点）

### 材料
- 温度相关杨氏模量
- 温度相关热膨胀系数
- 热传导属性

### 边界条件
- Dirichlet 固定约束
- 随时间变化的压力载荷
- 对流换热边界
- 集中力载荷
- 重力载荷

### 后处理
- 全面的 Postprocessors（极值、平均值、反力、能量）
- 多个 VectorPostprocessors（线采样、点采样）
- 多格式输出（Exodus + CSV）

## 使用方法

### 1. 快速运行

```bash
# 赋予执行权限
chmod +x run_simulation.sh

# 运行完整流程（仿真 + 后处理）
./run_simulation.sh
```

### 2. 分步运行

```bash
# 第1步：运行仿真
combined-opt -i complete_simulation.i

# 第2步：运行后处理
python3 postprocess.py complete_simulation_out
```

### 3. 查看结果

```bash
# 使用 ParaView 可视化
paraview complete_simulation_out.e

# 查看文本报告
cat postprocessing_results/complete_simulation_out_summary.txt

# 查看 PDF 报告
# （使用 PDF 阅读器打开）
```

## 输入文件详解

### 完整版 (`complete_simulation.i`)

- 时间：0 ~ 5 秒
- 网格：40×4×6 单元
- 完整的热-力耦合分析
- 全面的后处理
- **适合**：完整功能演示、科研分析

### 简化版 (`simple_demo.i`)

- 时间：0 ~ 2 秒
- 网格：20×2×3 单元
- 纯力学分析（无热耦合）
- 基础后处理
- **适合**：快速测试、学习入门

## 后处理输出

运行后处理脚本后，将生成：

```
postprocessing_results/
├── complete_simulation_out_report.pdf      # 图表报告
├── complete_simulation_out_summary.txt     # 文本摘要
└── complete_simulation_out_summary.csv     # 数据汇总
```

### PDF 报告内容

1. **时间历史图**
   - 应力历史（含屈服线）
   - 位移历史
   - 温度历史
   - 反力历史
   - 应变能历史
   - 材料属性变化

2. **中心线分布图**
   - 位移沿长度分布
   - 应力沿长度分布
   - 温度沿长度分布
   - 材料属性分布

3. **高度方向分布图**
   - 固定端截面应力分布
   - 自由端截面应力分布

4. **应力分析图**
   - 多应力分量历史
   - 安全系数历史
   - 应力-位移关系
   - 应力统计直方图

5. **演变过程图**
   - 位移演变
   - 应力演变

## 关键参数

| 参数 | 数值 | 说明 |
|------|------|------|
| 梁长度 | 2.0 m | X 方向 |
| 梁宽度 | 0.2 m | Y 方向 |
| 梁高度 | 0.3 m | Z 方向 |
| 杨氏模量 | 200 GPa | 室温值 |
| 泊松比 | 0.3 | - |
| 屈服应力 | 250 MPa | 用于安全系数 |
| 最大压力 | 2 MPa | 顶面压力 |
| 集中力 | 10 kN | 中点向下 |
| 最高温度 | 400 K | 固定端 |

## 检查清单

### 运行前检查
- [ ] MOOSE 环境已配置
- [ ] 输入文件语法正确（可用 `combined-opt -i input.i --check-input` 检查）
- [ ] 磁盘空间充足

### 运行后检查
- [ ] 仿真成功完成（检查最后输出的 `Finished Executing`）
- [ ] Exodus 文件已生成
- [ ] CSV 文件已生成
- [ ] 后处理脚本运行成功
- [ ] 安全系数合理（> 1.5）

## 常见问题

### Q: 仿真运行缓慢？

**A:** 可尝试以下优化：
1. 使用简化版输入文件 `simple_demo.i`
2. 减少网格密度（修改 `nx`, `ny`, `nz`）
3. 增大时间步长（修改 `dt`）
4. 使用并行计算：`mpirun -np 4 combined-opt -i complete_simulation.i`

### Q: 后处理脚本报错？

**A:** 检查 Python 依赖：
```bash
pip install pandas matplotlib numpy
```

### Q: 如何修改载荷？

**A:** 编辑输入文件中的 `[Functions]` 和 `[BCs]` 块，修改：
- `pressure_ramp` 函数定义压力变化
- `point_load` 的 `rate` 参数定义集中力大小
- `gravity_z` 的 `value` 定义重力加速度

### Q: 如何添加新的监测点？

**A:** 在 `[VectorPostprocessors]` 中添加新的 `PointValueSampler`：
```cpp
[my_point]
  type = PointValueSampler
  variable = 'disp_z von_mises'
  points = '1.0 0.1 0.15'  # 你的监测点坐标
  sort_by = id
[]
```

## 扩展阅读

- [ParaView 文档](https://www.paraview.org/documentation/)
- [MOOSE 后处理文档](https://mooseframework.inl.gov/syntax/Postprocessors/index.html)
- [Pandas 文档](https://pandas.pydata.org/docs/)
- [Matplotlib 文档](https://matplotlib.org/stable/contents.html)

## 许可证

本示例代码遵循 MOOSE 框架许可证。

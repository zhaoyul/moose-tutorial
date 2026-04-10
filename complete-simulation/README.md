# 完整仿真流程

本目录包含一个完整的 MOOSE 仿真流程示例，整合前序章节的所有重要特性。

如果你是第一次走完整流程，不建议一上来就跑最复杂的版本。更稳妥的顺序是：

1. 先运行 `simple_demo.i`
2. 再运行 `./run_simulation.sh`
3. 最后再尝试 `./run_gmsh_workflow.sh`

这样可以把“求解器问题”“脚本问题”“网格生成问题”分开定位。

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

### 0. 先做环境自检

```bash
cd complete-simulation

# 确认仓库入口脚本存在
test -x ../run_moose_local.sh && echo "找到 ../run_moose_local.sh"

# 确认 Python 可用
python3 --version
```

更稳妥的检查方式是：

```bash
command -v combined-opt || command -v moose-opt || echo "需要设置 MOOSE_LOCAL_BIN"
python3 -c "import pandas, matplotlib, numpy" || echo "后处理会被跳过"
```

如果 MOOSE 可执行文件还没准备好，先回到安装章节，不要直接尝试运行脚本。

### 0.5 推荐先跑简化版

```bash
cd complete-simulation
../run_moose_local.sh -i simple_demo.i
```

第一次只需要确认：

- 能正常结束
- 生成 `simple_demo_out.e`
- 生成 `simple_demo_out.csv`
- 没有明显的收敛报错

把这个最小闭环跑通之后，再进入完整自动化流程。

### 1. 快速运行

```bash
# 赋予执行权限
chmod +x run_simulation.sh

# 运行默认流程（仿真 + 后处理）
./run_simulation.sh
```

默认情况下，这个脚本实际运行的是：

- `INPUT_FILE=simple_demo.i`
- `OUTPUT_PREFIX=simple_demo_out`

它会自动执行 4 个阶段：

1. 检查依赖
2. 运行 MOOSE 仿真
3. 检查输出文件
4. 运行后处理并生成报告

如果你想直接跑完整版耦合输入文件，而不是默认的轻量示例：

```bash
INPUT_FILE=complete_simulation.i OUTPUT_PREFIX=complete_simulation_out ./run_simulation.sh
```

### 2. 分步运行

```bash
# 第1步：运行仿真
../run_moose_local.sh -i complete_simulation.i

# 第2步：运行后处理
python3 postprocess.py complete_simulation_out
```

如果你只是想复现脚本默认行为，对应的分步命令是：

```bash
../run_moose_local.sh -i simple_demo.i
python3 postprocess.py simple_demo_out
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

### 3.1 运行成功的判据

第一次做完整流程时，建议只检查下面几项，不要一开始就试图读懂所有输出：

- 终端出现“完整仿真流程结束”
- 对应前缀的 `.e` 文件已生成
- 对应前缀的 `.csv` 文件已生成
- `postprocessing_results/` 中生成对应摘要
- 摘要中能看到最大应力、最大位移、安全系数

注意：如果你用默认脚本直接运行，上面这些文件前缀是 `simple_demo_out`，不是 `complete_simulation_out`。

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

对于初学者，`simple_demo.i` 是最值得反复修改的文件，因为它运行快、结构完整、改动后反馈也快。

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

### 学习时的观察重点

- 看 `max_disp_z` 的符号和数量级，不要只看绝对值大小
- 看应力热点是否出现在固定端、加载区等合理位置
- 看你改动一个参数后，结果是不是朝着符合物理直觉的方向变化

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
python3 -m pip install pandas matplotlib numpy
```

如果脚本只是提示“跳过后处理”，通常不是仿真失败，而是缺少可选 Python 包。

### Q: 为什么我运行 `./run_simulation.sh` 后没有得到 `complete_simulation_out.*`？

**A:** 因为脚本默认跑的是 `simple_demo.i`。如果你要得到 `complete_simulation_out.*`，需要显式覆盖：

```bash
INPUT_FILE=complete_simulation.i OUTPUT_PREFIX=complete_simulation_out ./run_simulation.sh
```

### Q: Gmsh 工作流默认跑的是哪个输入文件？

**A:** `run_gmsh_workflow.sh` 默认使用：

- `INPUT_FILE=simple_moose_test.i`
- `OUTPUT_PREFIX=moose_result`

如果你想跑完整的 Gmsh 版本，请显式指定：

```bash
INPUT_FILE=simulation_with_gmsh.i OUTPUT_PREFIX=gmsh_simulation_out ./run_gmsh_workflow.sh
```

### Q: 如何修改载荷？

**A:** 编辑输入文件中的 `[Functions]` 和 `[BCs]` 块，修改：
- `pressure_ramp` 函数定义压力变化
- `point_load` 的 `rate` 参数定义集中力大小
- `gravity_z` 的 `value` 定义重力加速度

### Q: 我应该先改哪个参数做实验？

**A:** 推荐按下面顺序改，反馈最直接：

1. `pressure_ramp` 的峰值，观察位移和应力变化
2. `youngs_modulus`，观察结构变软或变硬
3. `dt`，观察计算时间和输出时间点变化
4. `nx`, `ny`, `nz`，观察网格和求解时间变化

第一次实验时，每次只改一个参数，否则你很难知道结果变化是谁造成的。

## 建议的互动练习

### 练习 1：把压力减半

把压力峰值减半，重新运行一次，比较前后两次摘要里的：

- 最大位移
- 最大应力
- 安全系数

### 练习 2：把时间步长改大

把 `dt` 改大，观察运行速度是否变快，以及输出时间点是否变少。

这个练习的重点是理解“求解精度”和“计算成本”之间的折中。

### 练习 3：只改一个网格方向

只把 `nx` 增大一倍，不改 `ny`、`nz`，观察：

- 计算时间变化
- 位移结果是否趋于稳定
- 哪个方向的网格对结果更敏感

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

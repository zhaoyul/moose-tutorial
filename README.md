# MOOSE 仿真教程

系统学习 MOOSE（Multiphysics Object Oriented Simulation Environment）多物理场仿真框架的完整教程。

## 👋 如果你是第一次接触 MOOSE

这套教程更适合按“先跑通，再理解，再修改”的顺序来学，而不是一开始就把所有语法看完。

建议你先完成下面这 3 步：

1. 进入 [04-first-example](04-first-example)，直接运行现成示例 `examples/cantilever_beam.i`
2. 确认你能看到 `cantilever_out.e` 和 `cantilever_out.csv`
3. 再进入 [complete-simulation](complete-simulation)，先运行 `simple_demo.i` 或 `run_simulation.sh`

如果你在第 1 步就卡住，不要继续往后读，先解决环境问题。对初学者来说，能稳定跑通一个最小例子比一次看懂所有章节更重要。

[![MOOSE](https://mooseframework.inl.gov/static/media/moose_logo.7e94f1c9.png)](https://mooseframework.inl.gov/)

## 📚 教程目录

|                         章节                       | 内容             |  状态 |
|:--------------------------------------------------:|------------------|:----:|
|         [01-introduction](01-introduction)         | MOOSE 简介       |  ✅  |
|         [02-installation](02-installation)         | 安装配置         |  ✅  |
|       [03-basic-concepts](03-basic-concepts)       | 基础概念         |  ✅  |
|        [04-first-example](04-first-example)        | 第一个示例       |  ✅  |
| [05-input-file-structure](05-input-file-structure) | 输入文件结构     |  ✅  |
|    [06-linear-elasticity](06-linear-elasticity)    | 线弹性力学       |  ✅  |
|            [07-materials](07-materials)            | 材料模型         |  ✅  |
|  [08-boundary-conditions](08-boundary-conditions)  | 边界条件         |  ✅  |
|      [09-mesh-generation](09-mesh-generation)      | 网格生成         |  ✅  |
|      [10-post-processing](10-post-processing)      | 后处理与可视化   |  ✅  |
|     [complete-simulation](complete-simulation)     | **完整仿真流程** |  ✅  |

## 🚀 快速开始

### 环境要求

- **操作系统**: Linux (推荐), macOS, Windows (WSL)
- **MOOSE 版本**: snapshot-20-10-27 或更新
- **Gmsh**: 4.13+ (用于网格生成)
- **Python**: 3.7+ (用于后处理)

### 安装 MOOSE

```bash
# 使用 conda 安装 (推荐)
conda config --add channels https://conda.software.inl.gov/public
conda create -n moose moose mpich
conda activate moose
```

详细安装说明见 [02-installation/README.md](02-installation/README.md)。

### 运行第一个示例

```bash
# 激活 MOOSE 环境
conda activate moose

# 运行悬臂梁示例
cd 04-first-example/examples
combined-opt -i cantilever_beam.i

# 查看结果
paraview cantilever_out.e
```

第一次运行时，重点不是记住所有输入块，而是确认下面 3 件事：

- 终端最后出现 `Finished Executing`
- 目录里生成 `cantilever_out.e` 和 `cantilever_out.csv`
- CSV 中的 `max_disp_z` 是一个负值，说明梁在 z 负方向下挠

### 运行完整仿真流程

```bash
cd complete-simulation

# 第 0 步：先跑一个更快的简化例子
combined-opt -i simple_demo.i

# 方法1: 使用 Gmsh 网格 (推荐)
./run_gmsh_workflow.sh

# 方法2: 使用内置网格
./run_simulation.sh
```

如果你是第一次做完整流程，建议顺序是：

1. `simple_demo.i`
2. `run_simulation.sh`
3. `run_gmsh_workflow.sh`

这样你可以先确认 MOOSE 求解本身没有问题，再引入 Gmsh 和后处理脚本，排错会简单很多。

## 📁 项目结构

```
moose-tutorial/
├── 01-introduction/           # 理论介绍
├── 02-installation/           # 安装指南
├── 03-basic-concepts/         # 基础概念
├── 04-first-example/          # 入门示例
├── 05-input-file-structure/   # 输入文件语法
├── 06-linear-elasticity/      # 线弹性力学
├── 07-materials/              # 材料模型
├── 08-boundary-conditions/    # 边界条件
├── 09-mesh-generation/        # 网格生成
├── 10-post-processing/        # 后处理
├── complete-simulation/       # 完整流程整合
└── README.md                  # 本文件
```

详细结构说明见 [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)。

## 🔬 包含的示例

### 基础示例

| 示例                      | 物理模型       | 特点                 |
|---------------------------|----------------|----------------------|
| `cantilever_beam.i`       | 线弹性悬臂梁   | 入门示例，集中力载荷 |
| `axisymmetric_cylinder.i` | 轴对称圆筒     | 内压载荷，解析解验证 |
| `orthotropic_plate.i`     | 正交各向异性板 | 复合材料建模         |

### 高级示例

| 示例                               | 物理模型   | 特点                                 |
|------------------------------------|------------|--------------------------------------|
| `temperature_dependent_material.i` | 热-力耦合  | 温度相关材料属性                     |
| `cantilever_multiple_loads.i`      | 多载荷组合 | 压力、重力、集中力                   |
| `adaptive_refinement.i`            | 自适应网格 | 自动网格细化                         |
| `complete_postprocessing.i`        | 全面后处理 | Postprocessors, VectorPostprocessors |

### 完整流程示例

| 示例                     | 描述                         |
|--------------------------|------------------------------|
| `complete_simulation.i`  | 完整热-力耦合分析 (内置网格) |
| `simulation_with_gmsh.i` | 使用 Gmsh 网格的仿真         |
| `simple_demo.i`          | 简化版快速测试               |
| `simple_moose_test.i`    | 最小可运行示例               |

## ✅ 学习时先看哪些结果

初学阶段不要急着追求和文档中的某个“固定数值”完全一致。更重要的是先判断仿真有没有按预期工作。

### 第一个示例的成功判据

- `cantilever_out.csv` 中存在 `max_disp_z`
- `max_disp_z` 为负，数量级约为 `1e-4 m`
- `max_von_mises` 为正，且最大应力出现在固定端附近

### 完整流程示例的成功判据

- 脚本执行结束时看到“完整仿真流程结束”
- 生成 `.e`、`.csv` 和 `postprocessing_results/*_summary.txt`
- 位移是毫米量级，应力是 MPa 到百 MPa 量级，安全系数为正值

不同 MOOSE 版本、网格密度、求解器设置或载荷定义会让数值略有变化，这属于正常现象。

## 🛠️ 开发工具

### Gmsh 网格生成

```bash
# 生成网格
gmsh -3 cantilever_beam.geo -o cantilever_beam.msh

# 查看网格统计
gmsh -info cantilever_beam.msh
```

### 后处理脚本

```bash
# 运行后处理
python3 postprocess.py moose_result

# 生成报告
# 输出: postprocessing_results/moose_result_report.pdf
```

## 📖 学习路径

### 30 分钟入门路线

如果你只想先建立直觉，可以按下面顺序完成一轮最短闭环：

1. 阅读 [03-basic-concepts](03-basic-concepts) 中的 `Mesh`、`BCs`、`Executioner` 三节
2. 运行 [04-first-example](04-first-example) 的 `examples/cantilever_beam.i`
3. 打开 `cantilever_out.csv`，只观察 `max_disp_z` 和 `max_von_mises`
4. 运行 `complete-simulation/simple_demo.i`
5. 再回头看 [05-input-file-structure](05-input-file-structure) 理解输入文件结构

这条路径的目标不是“学完”，而是建立一个最基本的问题闭环：
我定义了什么物理问题，我运行了什么输入文件，我看哪几个结果判断它是否合理。

### 初学者路径

1. 阅读 [01-introduction](01-introduction) 了解 MOOSE
2. 完成 [02-installation](02-installation) 安装配置
3. 学习 [03-basic-concepts](03-basic-concepts) 基础概念
4. 运行 [04-first-example](04-first-example) 第一个示例
5. 逐步完成 05-10 章节
6. 完成 [complete-simulation](complete-simulation) 综合练习

### 快速上手路径

如果你有有限元基础：

1. 快速浏览 [03-basic-concepts](03-basic-concepts)
2. 直接运行 `complete-simulation/simple_moose_test.i`
3. 按需深入学习特定章节

## 🔧 语法兼容性

本教程已更新适配 MOOSE 新版语法：

| 旧语法                           | 新语法                               |
|----------------------------------|--------------------------------------|
| `Modules/TensorMechanics/Master` | `Physics/SolidMechanics/QuasiStatic` |
| `NodalAverageValue`              | `ElementAverageValue`                |
| `NumElems`                       | `NumElements`                        |
| `PLANE_STRESS`                   | `WEAK_PLANE_STRESS`                  |
| `component = 2` (Pressure BC)    | 移除                                 |

所有示例已修复并验证可运行。

## 📝 文件说明

### 应提交到 Git 的文件

- ✅ `*.i` - MOOSE 输入文件
- ✅ `*.geo` - Gmsh 几何文件
- ✅ `*.py` - Python 脚本
- ✅ `*.sh` - Bash 脚本
- ✅ `*.md` - Markdown 文档

### 不应提交的文件

- ❌ `*.e` - Exodus 结果文件
- ❌ `*_out.csv` - CSV 数据文件
- ❌ `*.msh` - Gmsh 网格文件
- ❌ `*.log` - 日志文件

详细说明见 [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md)。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 📄 许可证

本项目遵循 [LGPL 2.1](https://www.gnu.org/licenses/lgpl-2.1.html) 许可证。

MOOSE 框架版权归属 Idaho National Laboratory。

## 📞 联系方式

- **MOOSE 官网**: https://mooseframework.inl.gov/
- **GitHub 仓库**: https://github.com/idaholab/moose
- **讨论论坛**: https://github.com/idaholab/moose/discussions

## 🙏 致谢

感谢 Idaho National Laboratory 开发并开源 MOOSE 框架。

---

**最后更新**: 2026-03-07

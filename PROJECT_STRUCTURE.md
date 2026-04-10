# 项目结构说明

本文档说明当前仓库的真实目录结构，以及每部分在学习路径中的作用。

## 目录结构

```text
moose-tutorial/
├── README.md                         # 主入口文档（推荐先读）
├── README.org                        # 指向 README.md 的简短入口
├── PROJECT_STRUCTURE.md              # 本文档
├── run_moose_local.sh                # 仓库统一的 MOOSE 启动入口
├── fix_moose_syntax.py               # 辅助脚本
│
├── 01-introduction/
│   └── README.org                    # 第一章：MOOSE 简介
├── 02-installation/
│   └── README.org                    # 第二章：安装与仓库级自检
├── 03-basic-concepts/
│   └── README.org                    # 第三章：基本概念
├── 04-first-example/
│   ├── README.org                    # 第四章：第一个例子
│   └── examples/
│       ├── cantilever_beam.i
│       └── cantilever_beam_paraview.i
├── 05-input-file-structure/
│   └── README.org                    # 第五章：输入文件结构
├── 06-linear-elasticity/
│   └── README.org                    # 第六章：线弹性
├── 07-materials/
│   └── README.org                    # 第七章：材料
├── 08-boundary-conditions/
│   └── README.org                    # 第八章：边界条件
├── 09-mesh-generation/
│   └── README.org                    # 第九章：网格
├── 10-post-processing/
│   └── README.org                    # 第十章：后处理
│
└── complete-simulation/
    ├── README.md                     # 端到端流程说明
    ├── GMSH_README.md               # Gmsh 流程说明
    ├── WORKFLOW.md                  # ASCII 工作流图
    ├── FILES_OVERVIEW.md            # 文件概览
    ├── simple_demo.i                # 默认轻量示例
    ├── complete_simulation.i        # 完整耦合示例
    ├── simple_moose_test.i          # Gmsh 流程默认输入文件
    ├── simulation_with_gmsh.i       # 完整 Gmsh 网格示例
    ├── run_simulation.sh            # 内置网格流程脚本
    ├── run_gmsh_workflow.sh         # Gmsh 流程脚本
    ├── postprocess.py               # 完整后处理脚本
    ├── simple_postprocess.py        # 简化后处理脚本
    ├── generate_mock_data.py        # 模拟数据生成
    ├── generate_mesh_gmsh.py        # Gmsh Python 网格脚本
    ├── cantilever_beam.geo          # Gmsh 几何文件
    └── postprocessing_results/      # 示例摘要与运行输出目录
```

## 如何理解这些目录

### 章节文档层

`01-10` 目录主要承担“解释”和“按主题组织知识”的职责。

- `01-05` 更偏入门和输入文件阅读
- `06-10` 更偏专题参考

除了 `04-first-example/examples/`，这些章节目录目前主要是文档，而不是完整的示例集合。

### 可运行示例层

真正适合作为起点反复运行的文件集中在两处：

- `04-first-example/examples/`
- `complete-simulation/`

推荐优先级如下：

1. `04-first-example/examples/cantilever_beam.i`
2. `complete-simulation/simple_demo.i`
3. `complete-simulation/complete_simulation.i`
4. `complete-simulation/simulation_with_gmsh.i`

### 仓库运行入口

根目录的 `run_moose_local.sh` 是本仓库的统一入口。它会按顺序尝试：

1. `combined-opt`
2. `moose-opt`
3. `MOOSE_LOCAL_BIN`

因此文档中的推荐命令会优先使用这个脚本，而不是假定每个人都有同名二进制。

## 推荐起步方式

```bash
# 1. 先跑第一个轻量例子
cd 04-first-example/examples
../../run_moose_local.sh -i cantilever_beam.i

# 2. 再跑完整流程目录中的默认轻量示例
cd ../../complete-simulation
./run_simulation.sh

# 3. 需要时再切换到完整耦合示例
INPUT_FILE=complete_simulation.i OUTPUT_PREFIX=complete_simulation_out ./run_simulation.sh
```

## 哪些文件通常需要提交

适合版本控制的内容：

- 文档：`README.md`、`README.org`、`*.md`、`*.org`
- 输入文件：`*.i`
- 脚本：`*.py`、`*.sh`
- Gmsh 几何：`*.geo`

通常不应提交的运行产物：

- `*.e`
- `*.csv`（运行生成的结果文件）
- `*.msh`
- `*.log`
- `postprocessing_results/` 下的新生成报告和图像

仓库里保留 `postprocessing_results/` 的少量示例摘要，是为了给学习者提供结果量级参考；这不意味着所有运行产物都应该进入版本库。

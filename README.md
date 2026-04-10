# moose-tutorial

这是一个面向结构力学学习路径的 MOOSE 教程仓库。仓库内容分成两类：

- 章节文档：按主题讲解 MOOSE 基本概念、输入文件结构、材料、边界条件、网格和后处理。
- 可运行示例：提供一个入门悬臂梁算例和一个更完整的端到端流程，方便先跑通、再回头理解。

这个仓库本身不编译自定义 MOOSE app。它假设你已经有一个可用的 MOOSE 可执行文件，然后通过仓库根目录的 `run_moose_local.sh` 来统一调用。

## 你会在这里找到什么

| 路径 | 作用 | 何时打开 |
|------|------|----------|
| `01-introduction/README.org` | MOOSE 背景、能力范围、学习路径 | 第一次了解项目时 |
| `02-installation/README.org` | 安装方式、环境要求、仓库级自检 | 准备运行示例前 |
| `03-basic-concepts/README.org` | Mesh、Variables、Materials、BCs、Executioner 等核心概念 | 跑通第一个例子后 |
| `04-first-example/README.org` | 第一个悬臂梁算例讲解 | 第一个真正动手的入口 |
| `04-first-example/examples/` | 轻量、可直接运行的章节示例 | 想快速验证环境时 |
| `05-input-file-structure/README.org` | `.i` 文件块结构和常见参数 | 开始改输入文件时 |
| `06-10` 章节 `README.org` | 线弹性、材料、边界条件、网格、后处理专题 | 需要专题参考时 |
| `complete-simulation/README.md` | 端到端运行说明 | 想走完整流程时 |
| `complete-simulation/` | 完整输入文件、脚本、后处理、Gmsh 流程 | 想做一次完整演练时 |

## 先决条件

最少需要下面这些条件，才适合开始使用这个仓库：

| 组件 | 是否必需 | 用途 |
|------|----------|------|
| 可用的 MOOSE 可执行文件 | 必需 | 运行 `.i` 输入文件 |
| Python 3 | 必需 | 运行部分辅助脚本 |
| `pandas`、`matplotlib`、`numpy` | 可选但强烈推荐 | 生成后处理图表和摘要 |
| Gmsh | 仅 Gmsh 流程必需 | 生成外部网格 |
| ParaView | 可选 | 查看 `.e` 可视化结果 |

仓库根目录的 `run_moose_local.sh` 会按下面顺序查找 MOOSE：

1. `combined-opt`
2. `moose-opt`
3. 环境变量 `MOOSE_LOCAL_BIN` 指向的可执行文件

如果前两项都不在 `PATH` 中，最稳妥的做法是显式设置 `MOOSE_LOCAL_BIN`。

## 快速开始

### 1. 做一次环境自检

```bash
cd /path/to/moose-tutorial

command -v combined-opt || command -v moose-opt || echo "需要设置 MOOSE_LOCAL_BIN"
python3 --version
python3 -c "import pandas, matplotlib, numpy" || echo "后处理依赖尚未安装"
command -v gmsh || echo "如果你只跑内置网格流程，可以先不装 gmsh"
```

### 2. 先跑第一个例子

```bash
cd 04-first-example/examples
../../run_moose_local.sh -i cantilever_beam.i
```

成功的最小判据：

- 终端末尾出现 `Finished Executing`
- 当前目录生成 `cantilever_out.e`
- 当前目录生成 `cantilever_out.csv`

### 3. 再跑完整流程

```bash
cd ../../complete-simulation
./run_simulation.sh
```

`run_simulation.sh` 的默认入口是：

- `INPUT_FILE=simple_demo.i`
- `OUTPUT_PREFIX=simple_demo_out`

如果你想直接运行完整耦合示例，而不是默认的轻量示例：

```bash
cd complete-simulation
INPUT_FILE=complete_simulation.i OUTPUT_PREFIX=complete_simulation_out ./run_simulation.sh
```

### 4. 可选：运行 Gmsh 网格流程

```bash
cd complete-simulation
INPUT_FILE=simulation_with_gmsh.i OUTPUT_PREFIX=gmsh_simulation_out ./run_gmsh_workflow.sh
```

如果你只是想测试脚本链路，不想一开始就引入 Gmsh，先不要跑这一步。

## 推荐学习顺序

建议按下面顺序推进，而不是一上来直接改复杂文件：

1. 阅读 `01-introduction/README.org`，了解教程范围和前置知识。
2. 按 `02-installation/README.org` 完成环境准备和仓库级自检。
3. 运行 `04-first-example/examples/cantilever_beam.i`，先确认工具链能闭环。
4. 对照 `03-basic-concepts/README.org` 和 `05-input-file-structure/README.org` 理解输入文件。
5. 进入 `complete-simulation/README.md`，跑一次自动化流程。
6. 需要专题时，再查 `06-10` 对应章节。

如果你是第一次接触 MOOSE，优先把“能运行”“能看到输出”“能解释关键结果”这三件事跑通，再去追求模型复杂度。

## 运行与构建说明

这个仓库没有独立的 `Makefile` 或自定义 app 源码目录，因此“构建”主要指两件事：

- 你自己的 MOOSE 环境已经可用。
- 仓库脚本能找到那个可执行文件。

常见调用方式如下：

```bash
# 使用 PATH 中的 combined-opt / moose-opt
./run_moose_local.sh -i complete-simulation/simple_demo.i

# 显式指定本地 MOOSE 二进制
MOOSE_LOCAL_BIN=/path/to/moose_test-opt ./run_moose_local.sh -i complete-simulation/simple_demo.i
```

如果你已经有自己的 MOOSE app，也可以直接用自己的 `*-opt` 可执行文件运行这些 `.i` 文件，但仓库文档默认以 `run_moose_local.sh` 为主，避免每个章节重复解释路径差异。

## 教程与示例结构

这个仓库更像“文档 + 示例集合”，而不是单一演示程序。实践上可以把内容分成三层：

- 第一层：`01-05` 章节，建立概念和输入文件阅读能力。
- 第二层：`04-first-example/examples/`，最快的可运行起点。
- 第三层：`complete-simulation/`，把网格、材料、边界条件、后处理串成完整流程。

其中最值得反复修改的文件通常是：

- `04-first-example/examples/cantilever_beam.i`
- `complete-simulation/simple_demo.i`
- `complete-simulation/complete_simulation.i`
- `complete-simulation/simulation_with_gmsh.i`

## 故障排除

### 找不到 MOOSE 可执行文件

如果 `./run_moose_local.sh -i ...` 报“未找到可用的 MOOSE 可执行文件”，说明下面三种路径都失败了：

- `combined-opt`
- `moose-opt`
- `MOOSE_LOCAL_BIN`

先用下面命令显式指定路径，再继续排查：

```bash
MOOSE_LOCAL_BIN=/path/to/moose_test-opt ./run_moose_local.sh -i complete-simulation/simple_demo.i
```

### 第一个例子能跑，完整流程脚本却失败

优先检查你是不是在 `complete-simulation/` 目录里运行脚本。两个流程脚本都依赖当前目录下的输入文件、几何文件和后处理脚本。

### 后处理被跳过

`run_simulation.sh` 和 `run_gmsh_workflow.sh` 在缺少 `pandas`、`matplotlib`、`numpy` 时会继续保留仿真结果，但跳过后处理。安装后再重跑即可：

```bash
python3 -m pip install pandas matplotlib numpy
```

### Gmsh 流程报错

`run_gmsh_workflow.sh` 需要 `gmsh` 命令。只做章节学习或内置网格流程时，不需要先解决 Gmsh。

### 结果文件生成了，但不知道先看什么

先检查最少三件事：

- 是否生成 `.e` 文件，表示可在 ParaView 打开；
- 是否生成主 `.csv` 文件，表示后处理数据存在；
- 摘要文本里最大位移、最大应力的数量级是否合理。

仓库已经包含示例摘要，可作为量级参考：

- `complete-simulation/postprocessing_results/simple_demo_out_summary.txt`
- `complete-simulation/postprocessing_results/gmsh_simulation_out_summary.txt`

## 相关文档

- 仓库结构说明：`PROJECT_STRUCTURE.md`
- 完整流程说明：`complete-simulation/README.md`
- Gmsh 使用说明：`complete-simulation/GMSH_README.md`

# 项目结构说明

本文档详细说明 MOOSE Tutorial 项目的目录结构和文件组织。

## 目录结构

```
moose-tutorial/
├── .gitignore                    # Git 忽略规则
├── README.md                     # 项目主文档
├── PROJECT_STRUCTURE.md          # 本文档
├── AGENTS.md                     # AI 代理说明 (为空)
│
├── 01-introduction/              # 第一章：MOOSE 简介
│   └── README.md                 # 理论说明文档
│
├── 02-installation/              # 第二章：安装配置
│   └── README.md                 # 安装指南
│
├── 03-basic-concepts/            # 第三章：基础概念
│   └── README.md                 # 概念说明
│
├── 04-first-example/             # 第四章：第一个示例
│   ├── README.md                 # 教程说明
│   └── examples/
│       └── cantilever_beam.i     # 悬臂梁示例 [提交到 Git]
│
├── 05-input-file-structure/      # 第五章：输入文件结构
│   └── README.md                 # 语法说明
│
├── 06-linear-elasticity/         # 第六章：线弹性力学
│   ├── README.md                 # 理论说明
│   └── examples/
│       ├── axisymmetric_cylinder.i   # 轴对称圆筒 [提交到 Git]
│       └── orthotropic_plate.i       # 正交各向异性板 [提交到 Git]
│
├── 07-materials/                 # 第七章：材料模型
│   ├── README.md                 # 材料说明
│   └── examples/
│       └── temperature_dependent_material.i  # 温度相关材料 [提交到 Git]
│
├── 08-boundary-conditions/       # 第八章：边界条件
│   ├── README.md                 # 边界条件说明
│   └── examples/
│       └── cantilever_multiple_loads.i   # 多载荷组合 [提交到 Git]
│
├── 09-mesh-generation/           # 第九章：网格生成
│   ├── README.md                 # 网格生成说明
│   └── examples/
│       └── adaptive_refinement.i     # 自适应细化 [提交到 Git]
│
├── 10-post-processing/           # 第十章：后处理
│   ├── README.md                 # 后处理说明
│   └── examples/
│       └── complete_postprocessing.i # 完整后处理 [提交到 Git]
│
└── complete-simulation/          # 完整仿真流程 (整合章节)
    ├── README.md                 # 使用文档 [提交到 Git]
    ├── GMSH_README.md            # Gmsh 使用指南 [提交到 Git]
    ├── WORKFLOW.md               # 工作流程图 [提交到 Git]
    ├── FILES_OVERVIEW.md         # 文件说明 [提交到 Git]
    │
    ├── cantilever_beam.geo       # Gmsh 几何文件 [提交到 Git]
    │
    ├── complete_simulation.i     # 完整仿真输入文件 [提交到 Git]
    ├── simple_demo.i             # 简化版输入文件 [提交到 Git]
    ├── simulation_with_gmsh.i    # Gmsh 网格版输入文件 [提交到 Git]
    ├── simple_moose_test.i       # 测试输入文件 [提交到 Git]
    │
    ├── generate_mesh_gmsh.py     # Gmsh Python 脚本 [提交到 Git]
    ├── postprocess.py            # Python 后处理脚本 [提交到 Git]
    ├── simple_postprocess.py     # 简化后处理脚本 [提交到 Git]
    ├── generate_mock_data.py     # 模拟数据生成器 [提交到 Git]
    │
    ├── run_simulation.sh         # 标准流程脚本 [提交到 Git]
    ├── run_gmsh_workflow.sh      # Gmsh 流程脚本 [提交到 Git]
    │
    └── postprocessing_results/   # 后处理输出目录 [不提交]
        └── .gitkeep              # 保留空目录标记 [提交到 Git]
```

## 文件分类

### ✅ 应提交到 Git 的文件

#### 1. 源代码和输入文件
- `*.i` - MOOSE 输入文件 (仿真配置)
- `*.geo` - Gmsh 几何文件 (网格定义)
- `*.py` - Python 脚本 (后处理、网格生成)
- `*.sh` - Bash 脚本 (自动化流程)

#### 2. 文档
- `*.md` - Markdown 文档 (说明、教程)
- `README*` - 项目说明文件
- `LICENSE` - 许可证文件 (如适用)
- `AUTHORS` - 作者信息 (如适用)

#### 3. 配置文件
- `.gitignore` - Git 忽略规则
- `.gitkeep` - 保留空目录

### ❌ 不应提交到 Git 的文件

#### 1. 生成的仿真结果
- `*.e` - Exodus 结果文件 (大型二进制)
- `*_out.csv` - CSV 数据文件 (运行时生成)
- `*_out_*.csv` - 时间步数据文件
- `*.log` - 仿真日志文件

#### 2. Gmsh 生成的网格
- `*.msh` - Gmsh 网格文件 (可从 .geo 生成)

#### 3. 临时文件
- `__pycache__/` - Python 缓存
- `.jitcache/` - MOOSE JIT 缓存
- `*.pyc` - Python 字节码
- `*~` - 编辑器备份文件

#### 4. 后处理输出
- `*.pdf` - 生成的报告
- `*.png`, `*.jpg` - 图像文件
- `postprocessing_results/` 目录内容

#### 5. 备份目录
- `fixed_examples/` - 修复示例的备份

## 使用说明

### 克隆仓库后首次使用

```bash
# 1. 安装 MOOSE (参考 02-installation/README.md)
# 2. 安装 Gmsh (可选，用于 Gmsh 网格)

# 3. 运行示例
cd 04-first-example/examples
combined-opt -i cantilever_beam.i

# 4. 查看结果
paraview cantilever_out.e
```

### 清理生成的文件

```bash
# 删除所有生成的结果文件 (不包括源代码)
find . -name "*.e" -delete
find . -name "*_out.csv" -delete
find . -name "*.msh" -delete
find . -name "*.log" -delete
rm -rf */*/.jitcache/
```

## Git 工作流

### 提交更改

```bash
# 查看更改
git status

# 添加源代码更改
git add 04-first-example/examples/cantilever_beam.i
git add complete-simulation/*.i
git add complete-simulation/*.py
git add complete-simulation/*.sh
git add *.md

# 提交
git commit -m "更新输入文件适配 MOOSE 新版"

# 推送
git push
```

### 更新 .gitignore

如需添加新的忽略规则，编辑 `.gitignore` 文件：

```bash
# 编辑 .gitignore
vim .gitignore

# 提交更改
git add .gitignore
git commit -m "更新 gitignore 规则"
```

## 文件大小注意事项

- **输入文件 (*.i)**：通常 < 20 KB，适合版本控制
- **几何文件 (*.geo)**：通常 < 5 KB，适合版本控制
- **脚本文件 (*.py, *.sh)**：通常 < 25 KB，适合版本控制
- **结果文件 (*.e)**：通常 1-10 MB，**不适合**版本控制
- **网格文件 (*.msh)**：通常 100 KB - 1 MB，**不适合**版本控制

## 许可证

本项目遵循 MOOSE 框架的 LGPL 2.1 许可证。

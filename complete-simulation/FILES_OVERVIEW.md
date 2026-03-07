# 文件概览

本目录包含完整仿真流程的所有文件。

## 📁 文件列表

### 核心仿真文件

| 文件 | 类型 | 大小 | 说明 |
|------|------|------|------|
| `complete_simulation.i` | MOOSE 输入 | 14.8 KB | 完整版仿真（内置网格生成） |
| `simple_demo.i` | MOOSE 输入 | 3.8 KB | 简化版（快速测试） |
| `simulation_with_gmsh.i` | MOOSE 输入 | 12.0 KB | 使用 Gmsh 网格的仿真 |

### 网格生成

| 文件 | 类型 | 大小 | 说明 |
|------|------|------|------|
| `generate_mesh_gmsh.py` | Python 脚本 | 11.2 KB | Gmsh Python API 网格生成 |
| `cantilever_beam.geo` | Gmsh 几何 | 4.1 KB | Gmsh 几何文件（推荐） |

### 运行脚本

| 文件 | 类型 | 大小 | 说明 |
|------|------|------|------|
| `run_simulation.sh` | Bash 脚本 | 7.7 KB | 标准流程（内置网格） |
| `run_gmsh_workflow.sh` | Bash 脚本 | 10.5 KB | Gmsh 网格流程 |

### 后处理

| 文件 | 类型 | 大小 | 说明 |
|------|------|------|------|
| `postprocess.py` | Python 脚本 | 22.4 KB | Python 后处理脚本 |
| `generate_mock_data.py` | Python 脚本 | 8.3 KB | 模拟数据生成器 |

### 文档

| 文件 | 类型 | 大小 | 说明 |
|------|------|------|------|
| `README.md` | Markdown | 5.2 KB | 主要使用文档 |
| `GMSH_README.md` | Markdown | 5.8 KB | Gmsh 使用指南 |
| `WORKFLOW.md` | Markdown | 35.3 KB | 工作流程图（ASCII） |
| `FILES_OVERVIEW.md` | Markdown | - | 本文件 |

## 🚀 快速开始

### 方案1: 使用内置网格（最简单）

```bash
./run_simulation.sh
```

### 方案2: 使用 Gmsh 网格（推荐）

```bash
# 1. 安装 Gmsh
yay -S gmsh

# 2. 运行完整流程
./run_gmsh_workflow.sh

# 或分步执行:
gmsh -3 cantilever_beam.geo -o cantilever_beam.msh
combined-opt -i simulation_with_gmsh.i
python3 postprocess.py gmsh_simulation_out
```

### 方案3: 仅测试后处理

```bash
# 生成模拟数据并后处理
python3 generate_mock_data.py
python3 postprocess.py simple_demo_out
```

## 📊 输出文件

运行后将生成：

```
.
├── cantilever_beam.msh      # Gmsh 网格文件
├── gmsh_simulation_out.e    # Exodus 结果文件
├── gmsh_simulation_out.csv  # CSV 数据文件
├── gmsh.log                 # Gmsh 日志
├── simulation.log           # MOOSE 日志
└── postprocessing_results/  # 后处理结果
    ├── gmsh_simulation_out_report.pdf
    ├── gmsh_simulation_out_summary.txt
    └── gmsh_simulation_out_summary.csv
```

## 🔧 自定义参数

### 调整网格密度

```bash
# 通过环境变量
LC=0.03 ./run_gmsh_workflow.sh

# 或通过命令行参数
./run_gmsh_workflow.sh --lc 0.03

# 或直接使用 gmsh
gmsh -3 cantilever_beam.geo -clscale 0.5
```

### 二阶单元

```bash
./run_gmsh_workflow.sh --order 2
```

### 修改仿真参数

编辑输入文件：
- `end_time`: 仿真结束时间
- `dt`: 时间步长
- `youngs_modulus`: 杨氏模量
- `pressure_ramp`: 压力载荷

## 📝 文件依赖关系

```
run_gmsh_workflow.sh
    │
    ├──▶ cantilever_beam.geo ──▶ gmsh ──▶ cantilever_beam.msh
    │                                          │
    └──▶ simulation_with_gmsh.i ──▶ combined-opt ──▶ gmsh_simulation_out.*
                                                          │
                                                          ▼
                                                   postprocess.py
                                                          │
                                                          ▼
                                            postprocessing_results/
```

## 🐛 故障排除

### Gmsh 未找到
```bash
# Arch Linux
yay -S gmsh

# Ubuntu
sudo apt-get install gmsh

# 或下载预编译版本
cd /tmp
wget https://gmsh.info/bin/Linux/gmsh-4.13.1-Linux64-sdk.tgz
tar -xzf gmsh-4.13.1-Linux64-sdk.tgz
export PATH=$PATH:/tmp/gmsh-4.13.1-Linux64-sdk/bin
```

### MOOSE 未找到
需要编译安装 MOOSE 框架，参考：
- https://mooseframework.inl.gov/getting_started/index.html

### 后处理失败
```bash
# 安装 Python 依赖
pip install pandas matplotlib numpy
```

## 📚 学习路径

1. **初学者**: 
   - 阅读 `README.md`
   - 运行 `./run_simulation.sh`
   - 查看 `simple_demo.i` 理解基本结构

2. **进阶用户**:
   - 阅读 `GMSH_README.md`
   - 运行 `./run_gmsh_workflow.sh`
   - 修改 `cantilever_beam.geo` 尝试不同网格

3. **高级用户**:
   - 修改 `simulation_with_gmsh.i` 添加自定义物理
   - 扩展 `postprocess.py` 添加自定义图表
   - 使用 Gmsh Python API 生成复杂几何

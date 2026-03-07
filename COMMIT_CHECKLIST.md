# Git 提交清单

本文档说明哪些文件应该提交到 Git，以及如何提交。

## 提交前检查清单

### ✅ 必须提交的文件

#### 1. 文档文件
```bash
git add README.md                    # 项目主文档 - 已更新
git add PROJECT_STRUCTURE.md         # 项目结构说明 - 新增
git add .gitignore                   # Git 忽略规则 - 新增
git add */README.md                  # 各章节说明文档
```

#### 2. MOOSE 输入文件 (*.i) - 已修复适配新版语法
```bash
# 第四章
git add 04-first-example/examples/cantilever_beam.i

# 第六章
git add 06-linear-elasticity/examples/axisymmetric_cylinder.i
git add 06-linear-elasticity/examples/orthotropic_plate.i

# 第七章
git add 07-materials/examples/temperature_dependent_material.i

# 第八章
git add 08-boundary-conditions/examples/cantilever_multiple_loads.i

# 第九章
git add 09-mesh-generation/examples/adaptive_refinement.i

# 第十章
git add 10-post-processing/examples/complete_postprocessing.i

# 完整仿真流程
git add complete-simulation/*.i
git add complete-simulation/*.geo
git add complete-simulation/*.py
git add complete-simulation/*.sh
git add complete-simulation/*.md
git add complete-simulation/postprocessing_results/.gitkeep
```

### ❌ 不应提交的文件 (已被 .gitignore 排除)

```bash
# 仿真结果文件 (*.e, *_out.csv)
# Gmsh 生成的网格 (*.msh)
# Python 缓存 (__pycache__/)
# JIT 缓存 (.jitcache/)
# 日志文件 (*.log)
# 临时脚本 (fix_moose_syntax.py)
# 备份目录 (fixed_examples/)
```

## 推荐的 Git 提交命令

```bash
# 1. 进入项目目录
cd /home/kevin/sandbox/tutorials/moose-tutorial

# 2. 添加所有应该提交的文件
git add README.md
git add PROJECT_STRUCTURE.md
git add .gitignore
git add 04-first-example/examples/cantilever_beam.i
git add 06-linear-elasticity/examples/axisymmetric_cylinder.i
git add 06-linear-elasticity/examples/orthotropic_plate.i
git add 07-materials/examples/temperature_dependent_material.i
git add 08-boundary-conditions/examples/cantilever_multiple_loads.i
git add 09-mesh-generation/examples/adaptive_refinement.i
git add 10-post-processing/examples/complete_postprocessing.i
git add complete-simulation/

# 3. 查看状态确认
git status

# 4. 提交更改
git commit -m "更新 MOOSE 输入文件适配新版语法，添加完整仿真流程

主要更新:
- 修复所有 *.i 文件适配 MOOSE snapshot-20-10-27 语法
- Modules/TensorMechanics/Master -> Physics/SolidMechanics/QuasiStatic
- NodalAverageValue -> ElementAverageValue
- NumElems -> NumElements
- 修复 SidesetReaction 参数
- 移除不兼容的 LinearElasticBC, StrainEnergy 等

新增内容:
- complete-simulation/ 完整仿真流程目录
- Gmsh 网格生成脚本 (generate_mesh_gmsh.py, cantilever_beam.geo)
- Python 后处理脚本 (postprocess.py, simple_postprocess.py)
- 自动化运行脚本 (run_simulation.sh, run_gmsh_workflow.sh)
- 详细文档 (GMSH_README.md, WORKFLOW.md, FILES_OVERVIEW.md)
- .gitignore 和 PROJECT_STRUCTURE.md

验证:
- 已使用真实 MOOSE 运行 cantilever_beam.i 成功
- 已使用真实 MOOSE 运行 simple_moose_test.i 成功
- Gmsh 网格生成验证通过"

# 5. 推送到远程仓库
git push origin main
```

## 提交后验证

```bash
# 检查提交历史
git log --oneline -5

# 检查文件大小
find . -type f -not -path './.git/*' -not -path './fixed_examples/*' \
  -not -path './complete-simulation/postprocessing_results/*' \
  -exec ls -lh {} + | awk '{ print $5 ":" $9 }' | sort

# 确保没有大文件被意外提交
git ls-files | xargs ls -lh | awk '{print $5, $9}' | sort -h
```

## 文件大小检查

提交前应确保没有大文件：

| 文件类型 | 预期大小 | 是否提交 |
|----------|----------|----------|
| *.i 输入文件 | < 20 KB | ✅ |
| *.geo 几何文件 | < 5 KB | ✅ |
| *.py 脚本 | < 25 KB | ✅ |
| *.sh 脚本 | < 10 KB | ✅ |
| *.md 文档 | < 10 KB | ✅ |
| *.e 结果文件 | 1-10 MB | ❌ |
| *.msh 网格文件 | 100 KB - 1 MB | ❌ |

## 如果意外提交了大文件

```bash
# 1. 从 Git 历史中移除大文件
# 使用 git filter-repo (推荐) 或 BFG Repo-Cleaner

# 示例: 移除所有 *.e 文件
git filter-repo --strip-blobs-bigger-than 1M
git filter-repo --path-glob '*.e' --invert-paths

# 2. 强制推送到远程 (谨慎操作!)
git push origin main --force
```

## 仓库大小估算

提交后的仓库大小约为：

```
源代码 + 文档:    ~500 KB
Git 历史:        ~100 KB
总计:            ~600 KB
```

这是一个轻量级教程仓库，适合快速克隆。

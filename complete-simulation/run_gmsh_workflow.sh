#!/bin/bash
# =============================================================================
# Gmsh + MOOSE 完整工作流程脚本
# =============================================================================
# 本脚本自动执行：
# 1. 使用 Gmsh 生成网格
# 2. 检查网格质量
# 3. 运行 MOOSE 仿真
# 4. 运行后处理
# =============================================================================

set -e  # 出错时退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
MESH_FILE="cantilever_beam.msh"
GEO_FILE="cantilever_beam.geo"
INPUT_FILE="simulation_with_gmsh.i"
OUTPUT_PREFIX="gmsh_simulation_out"
POSTPROCESS_SCRIPT="postprocess.py"

# 默认参数
LC=${LC:-0.05}           # 网格特征长度
ORDER=${ORDER:-1}        # 单元阶数

# =============================================================================
# 辅助函数
# =============================================================================
print_header() {
    echo ""
    echo -e "${CYAN}=============================================================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}=============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# =============================================================================
# 检查依赖
# =============================================================================
check_dependencies() {
    print_header "检查依赖"
    
    # 检查 Gmsh
    if command -v gmsh &> /dev/null; then
        GMSH_VERSION=$(gmsh --version 2>&1 | head -1)
        print_success "找到 Gmsh: $GMSH_VERSION"
    else
        print_error "未找到 Gmsh"
        echo ""
        echo "请安装 Gmsh:"
        echo "  Arch Linux: yay -S gmsh"
        echo "  Ubuntu: sudo apt-get install gmsh"
        echo "  Conda: conda install -c conda-forge gmsh"
        exit 1
    fi
    
    # 检查 MOOSE
    if command -v combined-opt &> /dev/null; then
        MOOSE_CMD="combined-opt"
        print_success "找到 MOOSE: combined-opt"
    elif command -v moose-opt &> /dev/null; then
        MOOSE_CMD="moose-opt"
        print_success "找到 MOOSE: moose-opt"
    else
        print_warning "未找到 MOOSE 应用"
        MOOSE_CMD=""
    fi
    
    # 检查 Python
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
    else
        print_error "未找到 Python"
        exit 1
    fi
    print_success "找到 Python: $PYTHON_CMD"
}

# =============================================================================
# 生成网格
# =============================================================================
generate_mesh() {
    print_header "Step 1: 生成 Gmsh 网格"
    
    if [ -f "$GEO_FILE" ]; then
        print_info "使用几何文件: $GEO_FILE"
        print_info "网格参数: lc=$LC, order=$ORDER"
        
        # 使用 geo 文件生成网格
        gmsh -3 "$GEO_FILE" -o "$MESH_FILE" -clmax $LC -order $ORDER 2>&1 | tee gmsh.log
        
        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            print_success "网格生成完成"
        else
            print_error "网格生成失败"
            exit 1
        fi
    elif [ -f "generate_mesh_gmsh.py" ]; then
        print_info "使用 Python 脚本生成网格"
        
        # 检查 Python Gmsh 模块
        if $PYTHON_CMD -c "import gmsh" 2>/dev/null; then
            $PYTHON_CMD generate_mesh_gmsh.py --lc $LC --order $ORDER -o "$MESH_FILE"
        else
            print_error "未找到 Python Gmsh 模块"
            echo "请安装: pip install gmsh"
            exit 1
        fi
    else
        print_error "未找到几何文件或生成脚本"
        exit 1
    fi
    
    # 显示网格信息
    if [ -f "$MESH_FILE" ]; then
        echo ""
        print_info "网格文件信息:"
        ls -lh "$MESH_FILE"
        
        # 提取统计信息
        echo ""
        print_info "网格统计:"
        gmsh -info "$MESH_FILE" 2>&1 | grep -E "(nodes|elements|vertices|triangles|quadrilaterals|tetrahedra|hexahedra|wedges)" || true
    fi
}

# =============================================================================
# 检查网格
# =============================================================================
check_mesh() {
    print_header "Step 2: 检查网格质量"
    
    if [ ! -f "$MESH_FILE" ]; then
        print_error "网格文件不存在: $MESH_FILE"
        exit 1
    fi
    
    # 检查网格质量
    gmsh -check "$MESH_FILE" 2>&1 | tee -a gmsh.log | grep -E "(Warning|Error|quality|valid)" || true
    
    # 检查物理组
    echo ""
    print_info "物理组定义:"
    gmsh -info "$MESH_FILE" 2>&1 | grep -A 20 "Physical" || true
    
    print_success "网格检查完成"
}

# =============================================================================
# 运行仿真
# =============================================================================
run_simulation() {
    print_header "Step 3: 运行 MOOSE 仿真"
    
    if [ -z "$MOOSE_CMD" ]; then
        print_warning "未找到 MOOSE，跳过仿真步骤"
        print_info "你可以稍后手动运行:"
        echo "  combined-opt -i $INPUT_FILE"
        return 0
    fi
    
    if [ ! -f "$INPUT_FILE" ]; then
        print_error "输入文件不存在: $INPUT_FILE"
        exit 1
    fi
    
    print_info "输入文件: $INPUT_FILE"
    print_info "开始计算..."
    
    # 运行仿真
    $MOOSE_CMD -i "$INPUT_FILE" 2>&1 | tee simulation.log
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "仿真计算完成"
    else
        print_error "仿真计算失败，请检查 simulation.log"
        exit 1
    fi
}

# =============================================================================
# 运行后处理
# =============================================================================
run_postprocess() {
    print_header "Step 4: 运行后处理"
    
    # 检查输出文件
    if [ ! -f "${OUTPUT_PREFIX}.csv" ]; then
        print_warning "未找到仿真输出，跳过后处理"
        
        # 生成模拟数据进行演示
        if [ -f "generate_mock_data.py" ]; then
            print_info "生成模拟数据用于演示..."
            $PYTHON_CMD generate_mock_data.py
            OUTPUT_PREFIX="simple_demo_out"
        else
            return 0
        fi
    fi
    
    if [ -f "$POSTPROCESS_SCRIPT" ]; then
        print_info "执行后处理脚本..."
        $PYTHON_CMD "$POSTPROCESS_SCRIPT" "$OUTPUT_PREFIX"
        
        if [ $? -eq 0 ]; then
            print_success "后处理完成"
        else
            print_error "后处理失败"
        fi
    else
        print_warning "未找到后处理脚本: $POSTPROCESS_SCRIPT"
    fi
}

# =============================================================================
# 显示结果
# =============================================================================
show_results() {
    print_header "仿真结果汇总"
    
    echo ""
    print_info "生成的文件:"
    ls -lh *.msh *.csv 2>/dev/null | tail -n +2 || true
    
    if [ -d "postprocessing_results" ]; then
        echo ""
        print_info "后处理结果:"
        ls -lh postprocessing_results/ 2>/dev/null | tail -n +2 || true
    fi
    
    echo ""
    print_success "Gmsh + MOOSE 工作流程结束!"
    
    if [ -f "$MESH_FILE" ]; then
        echo ""
        print_info "查看网格:"
        echo "  gmsh $MESH_FILE"
    fi
    
    if [ -f "${OUTPUT_PREFIX}.e" ]; then
        echo ""
        print_info "查看仿真结果:"
        echo "  paraview ${OUTPUT_PREFIX}.e"
    fi
    
    if [ -f "postprocessing_results/${OUTPUT_PREFIX}_report.pdf" ]; then
        echo ""
        print_info "查看报告:"
        echo "  postprocessing_results/${OUTPUT_PREFIX}_report.pdf"
    fi
}

# =============================================================================
# 清理函数
# =============================================================================
cleanup() {
    print_header "清理临时文件"
    
    read -p "确认删除所有生成文件? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -f *.msh *.e *.csv *.log
        rm -rf postprocessing_results/
        print_success "已清理"
    else
        print_info "取消清理"
    fi
}

# =============================================================================
# 主程序
# =============================================================================
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --lc)
                LC="$2"
                shift 2
                ;;
            --order)
                ORDER="$2"
                shift 2
                ;;
            -c|--clean)
                cleanup
                exit 0
                ;;
            -h|--help)
                echo "用法: $0 [选项]"
                echo ""
                echo "选项:"
                echo "  --lc <float>     网格特征长度 (默认: 0.05)"
                echo "  --order <int>    单元阶数 1 或 2 (默认: 1)"
                echo "  -c, --clean      清理生成文件"
                echo "  -h, --help       显示帮助"
                echo ""
                echo "示例:"
                echo "  $0                    # 使用默认参数"
                echo "  $0 --lc 0.03          # 更细的网格"
                echo "  $0 --order 2          # 二阶单元"
                exit 0
                ;;
            *)
                print_error "未知选项: $1"
                exit 1
                ;;
        esac
    done
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 执行流程
    check_dependencies
    generate_mesh
    check_mesh
    run_simulation
    run_postprocess
    show_results
    
    # 计算耗时
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECONDS=$((ELAPSED % 60))
    
    echo ""
    print_info "总耗时: ${MINUTES}分 ${SECONDS}秒"
}

# 运行主程序
main "$@"

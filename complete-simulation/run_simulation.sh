#!/bin/bash
# =============================================================================
# 完整仿真流程脚本
# =============================================================================
# 本脚本自动执行：
# 1. 运行 MOOSE 仿真
# 2. 检查仿真是否成功
# 3. 运行后处理脚本
# 4. 生成报告
# =============================================================================

set -e  # 出错时退出

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
POSTPROCESS_AVAILABLE=1

# 配置
INPUT_FILE="${INPUT_FILE:-simple_demo.i}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-simple_demo_out}"
POSTPROCESS_SCRIPT="postprocess.py"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# 辅助函数
# =============================================================================
print_header() {
    echo ""
    echo "============================================================================="
    echo "  $1"
    echo "============================================================================="
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
    
    # 检查本地 MOOSE 入口
    if [ -x "$ROOT_DIR/run_moose_local.sh" ]; then
        MOOSE_CMD="$ROOT_DIR/run_moose_local.sh"
        print_success "找到 MOOSE 入口脚本: $MOOSE_CMD"
    else
        print_error "未找到 MOOSE 入口脚本: $ROOT_DIR/run_moose_local.sh"
        exit 1
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
    
    # 检查可选的 Python 包，缺失时仅跳过后处理
    print_info "检查可选 Python 依赖包..."
    if $PYTHON_CMD -c "import pandas, matplotlib, numpy" 2>/dev/null; then
        print_success "Python 后处理依赖已就绪"
    else
        POSTPROCESS_AVAILABLE=0
        print_warning "缺少 pandas/matplotlib/numpy，后处理步骤将被跳过"
    fi
}

# =============================================================================
# 运行仿真
# =============================================================================
run_simulation() {
    print_header "运行 MOOSE 仿真"
    
    if [ ! -f "$INPUT_FILE" ]; then
        print_error "输入文件不存在: $INPUT_FILE"
        exit 1
    fi
    
    print_info "输入文件: $INPUT_FILE"
    print_info "开始计算..."
    
    # 运行仿真
    "$MOOSE_CMD" -i "$INPUT_FILE" 2>&1 | tee simulation.log
    
    # 检查是否成功
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        print_success "仿真计算完成"
    else
        print_error "仿真计算失败，请检查 simulation.log"
        exit 1
    fi
}

# =============================================================================
# 检查输出
# =============================================================================
check_output() {
    print_header "检查输出文件"
    
    # 检查 Exodus 文件
    if ls ${OUTPUT_PREFIX}*.e &> /dev/null; then
        print_success "找到 Exodus 输出文件"
        ls -lh ${OUTPUT_PREFIX}*.e
    else
        print_warning "未找到 Exodus 输出文件"
    fi
    
    # 检查 CSV 文件
    if [ -f "${OUTPUT_PREFIX}.csv" ]; then
        print_success "找到 CSV 数据文件"
        ls -lh ${OUTPUT_PREFIX}.csv
    else
        print_error "未找到 CSV 数据文件"
        exit 1
    fi
    
    # 列出所有输出文件
    echo ""
    print_info "所有输出文件:"
    ls -lh ${OUTPUT_PREFIX}* 2>/dev/null || true
}

# =============================================================================
# 运行后处理
# =============================================================================
run_postprocess() {
    print_header "运行后处理"

    if [ "$POSTPROCESS_AVAILABLE" -ne 1 ]; then
        print_warning "跳过后处理：Python 依赖未就绪"
        return 0
    fi
    
    if [ ! -f "$POSTPROCESS_SCRIPT" ]; then
        print_warning "未找到后处理脚本: $POSTPROCESS_SCRIPT"
        return 0
    fi
    
    print_info "执行后处理脚本..."
    if $PYTHON_CMD $POSTPROCESS_SCRIPT $OUTPUT_PREFIX; then
        print_success "后处理完成"
    else
        print_warning "后处理失败，保留仿真结果供 ParaView 使用"
        return 0
    fi
}

# =============================================================================
# 显示结果
# =============================================================================
show_results() {
    print_header "仿真结果汇总"
    
    # 显示关键结果
    if [ -f "postprocessing_results/${OUTPUT_PREFIX}_summary.txt" ]; then
        echo ""
        cat "postprocessing_results/${OUTPUT_PREFIX}_summary.txt"
    fi
    
    echo ""
    print_info "生成的文件:"
    echo "  - 仿真日志: simulation.log"
    if [ -d "postprocessing_results" ]; then
        ls -lh postprocessing_results/ 2>/dev/null | tail -n +2
    fi
    
    echo ""
    print_success "完整仿真流程结束!"
    echo ""
    print_info "使用 ParaView 查看结果:"
    echo "  paraview ${OUTPUT_PREFIX}.e"
    echo ""
    if [ -f "postprocessing_results/${OUTPUT_PREFIX}_report.pdf" ]; then
        print_info "查看 PDF 报告:"
        echo "  postprocessing_results/${OUTPUT_PREFIX}_report.pdf"
    fi
}

# =============================================================================
# 清理函数
# =============================================================================
cleanup() {
    print_header "清理临时文件"
    
    read -p "确认删除所有仿真结果? (y/N): " confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -f ${OUTPUT_PREFIX}*.e ${OUTPUT_PREFIX}*.csv
        rm -rf postprocessing_results/
        rm -f simulation.log
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
    case "${1:-}" in
        -c|--clean)
            cleanup
            exit 0
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -c, --clean    清理仿真结果"
            echo "  -h, --help     显示帮助"
            echo ""
            echo "示例:"
            echo "  $0             # 运行完整仿真流程"
            echo "  $0 --clean     # 清理结果文件"
            exit 0
            ;;
    esac
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 执行流程
    check_dependencies
    run_simulation
    check_output
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

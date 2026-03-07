#!/usr/bin/env python3
"""
================================================================================
Gmsh 网格生成脚本 - 悬臂梁
================================================================================
生成带物理组标记的 3D 网格，用于 MOOSE 仿真

物理组定义:
- 体积: "beam_volume" (材料属性应用区域)
- 边界:
  * "fixed_end" - 固定端 (x=0)
  * "free_end" - 自由端 (x=L)
  * "top" - 顶面 (z=H)
  * "bottom" - 底面 (z=0)
  * "front" - 前面 (y=W)
  * "back" - 后面 (y=0)
  * "loading_point" - 加载点 (中点位置)

使用方法:
    python3 generate_mesh_gmsh.py [options]
    
选项:
    --lc <float>     特征长度 (默认: 0.05)
    --order <int>    单元阶数 1 或 2 (默认: 1)
    --format <str>   输出格式: msh22, msh40, msh41 (默认: msh41)
    -o <file>        输出文件名 (默认: cantilever_beam.msh)
    
示例:
    python3 generate_mesh_gmsh.py --lc 0.03 --order 2 -o fine_mesh.msh
================================================================================
"""

import sys
import argparse

# 尝试导入 gmsh
try:
    import gmsh
except ImportError:
    print("错误: 未找到 gmsh 模块。请安装 Gmsh:")
    print("  Ubuntu/Debian: sudo apt-get install gmsh python3-gmsh")
    print("  Arch Linux: sudo pacman -S gmsh")
    print("  Conda: conda install -c conda-forge gmsh")
    print("\n或者从源码安装:")
    print("  pip install gmsh")
    sys.exit(1)


def generate_cantilever_mesh(lc=0.05, order=1, output="cantilever_beam.msh", 
                             format_version="msh41"):
    """
    生成悬臂梁网格
    
    参数:
        lc: 特征长度 (网格尺寸)
        order: 单元阶数 (1=线性, 2=二次)
        output: 输出文件名
        format_version: MSH 格式版本
    """
    
    # 梁尺寸
    L = 2.0    # 长度 (m)
    W = 0.2    # 宽度 (m)
    H = 0.3    # 高度 (m)
    
    # 初始化 Gmsh
    gmsh.initialize()
    gmsh.model.add("cantilever_beam")
    
    print(f"生成悬臂梁网格:")
    print(f"  尺寸: {L}m × {W}m × {H}m")
    print(f"  特征长度: {lc}m")
    print(f"  单元阶数: {order}")
    print(f"  输出格式: {format_version}")
    print()
    
    # ============================================================
    # 创建几何点
    # ============================================================
    # 底面四个点 (z=0)
    p1 = gmsh.model.geo.addPoint(0, 0, 0, lc)      # 固定端-后-下
    p2 = gmsh.model.geo.addPoint(L, 0, 0, lc)      # 自由端-后-下
    p3 = gmsh.model.geo.addPoint(L, W, 0, lc)      # 自由端-前-下
    p4 = gmsh.model.geo.addPoint(0, W, 0, lc)      # 固定端-前-下
    
    # 顶面四个点 (z=H)
    p5 = gmsh.model.geo.addPoint(0, 0, H, lc)      # 固定端-后-上
    p6 = gmsh.model.geo.addPoint(L, 0, H, lc)      # 自由端-后-上
    p7 = gmsh.model.geo.addPoint(L, W, H, lc)      # 自由端-前-上
    p8 = gmsh.model.geo.addPoint(0, W, H, lc)      # 固定端-前-上
    
    # ============================================================
    # 创建边
    # ============================================================
    # 底面边
    e1 = gmsh.model.geo.addLine(p1, p2)   # 底面-后
    e2 = gmsh.model.geo.addLine(p2, p3)   # 底面-右
    e3 = gmsh.model.geo.addLine(p3, p4)   # 底面-前
    e4 = gmsh.model.geo.addLine(p4, p1)   # 底面-左 (固定端)
    
    # 顶面边
    e5 = gmsh.model.geo.addLine(p5, p6)   # 顶面-后
    e6 = gmsh.model.geo.addLine(p6, p7)   # 顶面-右
    e7 = gmsh.model.geo.addLine(p7, p8)   # 顶面-前
    e8 = gmsh.model.geo.addLine(p8, p5)   # 顶面-左 (固定端)
    
    # 垂直边
    e9 = gmsh.model.geo.addLine(p1, p5)   # 固定端-后-下->上
    e10 = gmsh.model.geo.addLine(p2, p6)  # 自由端-后-下->上
    e11 = gmsh.model.geo.addLine(p3, p7)  # 自由端-前-下->上
    e12 = gmsh.model.geo.addLine(p4, p8)  # 固定端-前-下->上
    
    # ============================================================
    # 创建表面
    # ============================================================
    # 底面 (z=0)
    loop_bottom = gmsh.model.geo.addCurveLoop([e1, e2, e3, e4])
    surf_bottom = gmsh.model.geo.addPlaneSurface([loop_bottom])
    
    # 顶面 (z=H)
    loop_top = gmsh.model.geo.addCurveLoop([e5, e6, e7, e8])
    surf_top = gmsh.model.geo.addPlaneSurface([loop_top])
    
    # 后面 (y=0)
    loop_back = gmsh.model.geo.addCurveLoop([e1, e10, -e5, -e9])
    surf_back = gmsh.model.geo.addPlaneSurface([loop_back])
    
    # 前面 (y=W)
    loop_front = gmsh.model.geo.addCurveLoop([e3, e12, -e7, -e11])
    surf_front = gmsh.model.geo.addPlaneSurface([loop_front])
    
    # 右面/自由端 (x=L)
    loop_right = gmsh.model.geo.addCurveLoop([e2, e11, -e6, -e10])
    surf_right = gmsh.model.geo.addPlaneSurface([loop_right])
    
    # 左面/固定端 (x=0)
    loop_left = gmsh.model.geo.addCurveLoop([e4, e9, -e8, -e12])
    surf_left = gmsh.model.geo.addPlaneSurface([loop_left])
    
    # ============================================================
    # 创建体积
    # ============================================================
    surface_loop = gmsh.model.geo.addSurfaceLoop([
        surf_bottom, surf_top, surf_back, surf_front, surf_right, surf_left
    ])
    volume = gmsh.model.geo.addVolume([surface_loop])
    
    # 同步几何
    gmsh.model.geo.synchronize()
    
    # ============================================================
    # 定义物理组
    # ============================================================
    # 体积物理组 (整个梁)
    gmsh.model.addPhysicalGroup(3, [volume], tag=1, name="beam_volume")
    
    # 边界物理组
    gmsh.model.addPhysicalGroup(2, [surf_left], tag=10, name="fixed_end")
    gmsh.model.addPhysicalGroup(2, [surf_right], tag=11, name="free_end")
    gmsh.model.addPhysicalGroup(2, [surf_top], tag=12, name="top")
    gmsh.model.addPhysicalGroup(2, [surf_bottom], tag=13, name="bottom")
    gmsh.model.addPhysicalGroup(2, [surf_front], tag=14, name="front")
    gmsh.model.addPhysicalGroup(2, [surf_back], tag=15, name="back")
    
    # 加载点 (中点, 顶面) - 使用点物理组
    # 创建中点
    p_mid = gmsh.model.geo.addPoint(L/2, W/2, H, lc/2)  # 更密的网格在加载点
    gmsh.model.geo.synchronize()
    gmsh.model.addPhysicalGroup(0, [p_mid], tag=20, name="loading_point")
    
    # ============================================================
    # 网格控制
    # ============================================================
    # 可以设置局部网格细化
    # 在固定端和自由端细化
    gmsh.model.mesh.field.add("Box", 1)
    gmsh.model.mesh.field.setNumber(1, "VIn", lc/2)
    gmsh.model.mesh.field.setNumber(1, "VOut", lc)
    gmsh.model.mesh.field.setNumber(1, "XMin", 0)
    gmsh.model.mesh.field.setNumber(1, "XMax", 0.2)
    gmsh.model.mesh.field.setNumber(1, "YMin", 0)
    gmsh.model.mesh.field.setNumber(1, "YMax", W)
    gmsh.model.mesh.field.setNumber(1, "ZMin", 0)
    gmsh.model.mesh.field.setNumber(1, "ZMax", H)
    
    gmsh.model.mesh.field.add("Box", 2)
    gmsh.model.mesh.field.setNumber(2, "VIn", lc/2)
    gmsh.model.mesh.field.setNumber(2, "VOut", lc)
    gmsh.model.mesh.field.setNumber(2, "XMin", L-0.2)
    gmsh.model.mesh.field.setNumber(2, "XMax", L)
    gmsh.model.mesh.field.setNumber(2, "YMin", 0)
    gmsh.model.mesh.field.setNumber(2, "YMax", W)
    gmsh.model.mesh.field.setNumber(2, "ZMin", 0)
    gmsh.model.mesh.field.setNumber(2, "ZMax", H)
    
    gmsh.model.mesh.field.add("Min", 3)
    gmsh.model.mesh.field.setNumbers(3, "FieldsList", [1, 2])
    gmsh.model.mesh.field.setAsBackgroundMesh(3)
    
    # ============================================================
    # 生成网格
    # ============================================================
    print("生成 3D 网格...")
    gmsh.model.mesh.generate(3)
    
    # 设置单元阶数
    if order == 2:
        print("转换为二阶单元...")
        gmsh.model.mesh.setOrder(2)
    
    # ============================================================
    # 导出网格
    # ============================================================
    # 设置格式
    format_map = {
        "msh22": ("msh", 2.2),
        "msh40": ("msh", 4.0),
        "msh41": ("msh", 4.1),
    }
    
    fmt, version = format_map.get(format_version, ("msh", 4.1))
    gmsh.option.setNumber("Mesh.MshFileVersion", version)
    
    gmsh.write(output)
    print(f"\n✓ 网格已保存: {output}")
    
    # 打印统计信息
    entities = gmsh.model.getEntities()
    nodes = gmsh.model.mesh.getNodes()
    elements = gmsh.model.mesh.getElements()
    
    print("\n网格统计:")
    print(f"  节点数: {len(nodes[0])}")
    
    # 统计各类型单元
    elem_counts = {}
    for dim, tag in entities:
        if dim == 3:  # 体积单元
            elem_types, _, _ = gmsh.model.mesh.getElements(dim, tag)
            for elem_type in elem_types:
                type_name = gmsh.model.mesh.getElementProperties(elem_type)[0]
                elem_counts[type_name] = elem_counts.get(type_name, 0) + 1
    
    print(f"  单元类型:")
    for type_name, count in elem_counts.items():
        print(f"    - {type_name}: {count} 个体积")
    
    # 物理组信息
    print("\n物理组定义:")
    groups = gmsh.model.getPhysicalGroups()
    for dim, tag in groups:
        name = gmsh.model.getPhysicalName(dim, tag)
        entities = gmsh.model.getEntitiesForPhysicalGroup(dim, tag)
        print(f"  [{tag}] {name} (dim={dim}): {len(entities)} 个实体")
    
    gmsh.finalize()
    return True


def main():
    parser = argparse.ArgumentParser(
        description="生成悬臂梁的 Gmsh 网格",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  %(prog)s                          # 使用默认参数
  %(prog)s --lc 0.03                # 更细的网格
  %(prog)s --order 2                # 二阶单元
  %(prog)s -o mesh.msh --lc 0.02    # 指定输出和网格尺寸
        """
    )
    
    parser.add_argument("--lc", type=float, default=0.05,
                       help="网格特征长度 (默认: 0.05)")
    parser.add_argument("--order", type=int, choices=[1, 2], default=1,
                       help="单元阶数: 1=线性, 2=二次 (默认: 1)")
    parser.add_argument("--format", dest="format_version", 
                       choices=["msh22", "msh40", "msh41"], default="msh41",
                       help="MSH 格式版本 (默认: msh41)")
    parser.add_argument("-o", "--output", default="cantilever_beam.msh",
                       help="输出文件名 (默认: cantilever_beam.msh)")
    
    args = parser.parse_args()
    
    try:
        generate_cantilever_mesh(
            lc=args.lc,
            order=args.order,
            output=args.output,
            format_version=args.format_version
        )
        print("\n✓ 网格生成成功!")
        return 0
    except Exception as e:
        print(f"\n✗ 错误: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())

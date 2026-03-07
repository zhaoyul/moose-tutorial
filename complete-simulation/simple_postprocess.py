#!/usr/bin/env python3
"""
简化版后处理脚本 - 纯 Python，无外部依赖
"""

import os
import sys
import glob
import math

def read_csv_simple(filename):
    """简单 CSV 读取"""
    with open(filename, 'r') as f:
        lines = f.readlines()
    
    if not lines:
        return [], []
    
    headers = lines[0].strip().split(',')
    data = []
    for line in lines[1:]:
        values = line.strip().split(',')
        row = {}
        for i, h in enumerate(headers):
            try:
                row[h] = float(values[i])
            except:
                row[h] = values[i]
        data.append(row)
    
    return headers, data


def analyze_data(prefix):
    """分析数据"""
    csv_file = f"{prefix}.csv"
    
    if not os.path.exists(csv_file):
        print(f"错误: 未找到文件 {csv_file}")
        return False
    
    headers, data = read_csv_simple(csv_file)
    
    if not data:
        print("错误: 数据为空")
        return False
    
    print("=" * 70)
    print(f"仿真结果分析 - {prefix}")
    print("=" * 70)
    print()
    
    # 基本信息
    print("【基本信息】")
    print(f"  时间步数: {len(data)}")
    print(f"  总时间: {data[-1].get('time', 0):.2f} s")
    print(f"  变量数: {len(headers)}")
    print()
    
    # 关键结果
    print("【关键结果】")
    
    # 应力
    if 'max_von_mises' in headers:
        stresses = [row['max_von_mises'] for row in data]
        max_stress = max(stresses)
        final_stress = stresses[-1]
        print(f"\n  应力分析:")
        print(f"    最大 von Mises 应力: {max_stress:.4e} Pa ({max_stress/1e6:.2f} MPa)")
        print(f"    最终 von Mises 应力: {final_stress:.4e} Pa ({final_stress/1e6:.2f} MPa)")
        
        # 安全系数
        yield_stress = 250e6
        sf = yield_stress / max_stress
        print(f"    安全系数: {sf:.4f}")
        if sf < 1.0:
            print(f"    ⚠️ 警告: 安全系数小于1，结构可能屈服!")
        elif sf < 1.5:
            print(f"    ⚠️ 注意: 安全系数较低 (< 1.5)")
        else:
            print(f"    ✓ 结构安全")
    
    # 位移
    if 'min_disp_z' in headers:
        disps = [row['min_disp_z'] for row in data]
        max_disp = min(disps)  # 负值，取最小
        print(f"\n  位移分析:")
        print(f"    最大 Z 向位移: {max_disp:.4e} m ({max_disp*1000:.4f} mm)")
    
    # 温度
    if 'max_temperature' in headers:
        temps = [row['max_temperature'] for row in data]
        max_temp = max(temps)
        print(f"\n  温度分析:")
        print(f"    最高温度: {max_temp:.2f} K")
        print(f"    温升: {max_temp - 300:.2f} K")
    
    # 能量
    if 'strain_energy' in headers:
        energies = [row['strain_energy'] for row in data]
        final_energy = energies[-1]
        print(f"\n  能量分析:")
        print(f"    最终应变能: {final_energy:.4e} J")
    
    # 反力
    if 'total_reaction' in headers:
        reactions = [row['total_reaction'] for row in data]
        max_reaction = max(reactions)
        print(f"\n  反力分析:")
        print(f"    最大总反力: {max_reaction/1000:.2f} kN")
    
    print()
    print("=" * 70)
    
    # 生成文本报告
    os.makedirs("postprocessing_results", exist_ok=True)
    report_file = f"postprocessing_results/{prefix}_summary.txt"
    
    with open(report_file, 'w') as f:
        f.write("=" * 70 + "\n")
        f.write(f"仿真结果分析报告 - {prefix}\n")
        f.write("=" * 70 + "\n\n")
        
        f.write("【基本信息】\n")
        f.write(f"  时间步数: {len(data)}\n")
        f.write(f"  总时间: {data[-1].get('time', 0):.2f} s\n")
        f.write(f"  变量数: {len(headers)}\n\n")
        
        f.write("【关键结果】\n")
        
        if 'max_von_mises' in headers:
            f.write(f"\n应力分析:\n")
            f.write(f"  最大 von Mises 应力: {max_stress:.4e} Pa\n")
            f.write(f"  安全系数: {sf:.4f}\n")
        
        if 'min_disp_z' in headers:
            f.write(f"\n位移分析:\n")
            f.write(f"  最大 Z 向位移: {max_disp:.4e} m\n")
        
        if 'max_temperature' in headers:
            f.write(f"\n温度分析:\n")
            f.write(f"  最高温度: {max_temp:.2f} K\n")
        
        if 'strain_energy' in headers:
            f.write(f"\n能量分析:\n")
            f.write(f"  最终应变能: {final_energy:.4e} J\n")
        
        f.write("\n" + "=" * 70 + "\n")
        f.write("报告生成完成\n")
    
    print(f"✓ 文本报告已保存: {report_file}")
    
    return True


def main():
    prefix = sys.argv[1] if len(sys.argv) > 1 else "simple_demo_out"
    
    print("简化版后处理脚本")
    print()
    
    if analyze_data(prefix):
        print("\n后处理完成!")
        return 0
    else:
        print("\n后处理失败!")
        return 1


if __name__ == "__main__":
    sys.exit(main())

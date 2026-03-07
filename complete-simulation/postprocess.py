#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
================================================================================
完整仿真后处理脚本
================================================================================
功能：
1. 读取 CSV 和 VectorPostprocessor 数据
2. 生成时间历史图、分布图、云图
3. 计算统计量和安全系数
4. 生成 PDF 报告

使用方法：
    python postprocess.py [output_prefix]
    
默认 output_prefix = "complete_simulation_out"
================================================================================
"""

import os
import sys
import glob
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import warnings
warnings.filterwarnings('ignore')

# 设置中文字体（如果可用）
plt.rcParams['font.size'] = 10
plt.rcParams['figure.dpi'] = 150

# ============================================================================
# 配置
# ============================================================================
DEFAULT_PREFIX = "complete_simulation_out"
OUTPUT_DIR = "postprocessing_results"

# 屈服应力（用于安全系数计算）
YIELD_STRESS = 250e6  # Pa

# 钢材理论弹性模量
E_STEEL = 200e9  # Pa

# ============================================================================
# 数据读取类
# ============================================================================
class SimulationData:
    """读取和管理仿真数据"""
    
    def __init__(self, prefix=DEFAULT_PREFIX):
        self.prefix = prefix
        self.pp_data = None          # Postprocessor 数据
        self.vpp_data = {}           # VectorPostprocessor 数据
        self._load_data()
    
    def _load_data(self):
        """加载所有数据文件"""
        # 读取主 CSV 文件（Postprocessor 数据）
        csv_file = f"{self.prefix}.csv"
        if os.path.exists(csv_file):
            self.pp_data = pd.read_csv(csv_file)
            print(f"✓ 读取 Postprocessor 数据: {csv_file} ({len(self.pp_data)} 行)")
        else:
            print(f"✗ 未找到 Postprocessor 数据: {csv_file}")
        
        # 读取 VectorPostprocessor 数据
        vpp_patterns = [
            (f"{self.prefix}_centerline_*.csv", "centerline"),
            (f"{self.prefix}_height_profile_fixed_*.csv", "height_profile_fixed"),
            (f"{self.prefix}_height_profile_free_*.csv", "height_profile_free"),
            (f"{self.prefix}_top_surface_*.csv", "top_surface"),
            (f"{self.prefix}_free_end_nodes_*.csv", "free_end_nodes"),
            (f"{self.prefix}_key_points_*.csv", "key_points"),
        ]
        
        for pattern, name in vpp_patterns:
            files = sorted(glob.glob(pattern))
            if files:
                # 读取最后一个时间步的数据
                data = pd.read_csv(files[-1])
                self.vpp_data[name] = {
                    'final': data,
                    'all_files': files
                }
                print(f"✓ 读取 {name}: {len(files)} 个时间步")
    
    def get_pp(self, column):
        """获取 Postprocessor 列数据"""
        if self.pp_data is not None and column in self.pp_data.columns:
            return self.pp_data[column]
        return None
    
    def get_vpp(self, name):
        """获取 VectorPostprocessor 数据"""
        return self.vpp_data.get(name, {}).get('final')
    
    def get_summary_stats(self):
        """获取汇总统计信息"""
        if self.pp_data is None:
            return {}
        
        stats = {}
        key_vars = ['max_von_mises', 'max_disp_z', 'min_disp_z', 
                    'max_temperature', 'strain_energy']
        
        for var in key_vars:
            if var in self.pp_data.columns:
                stats[var] = {
                    'initial': self.pp_data[var].iloc[0],
                    'final': self.pp_data[var].iloc[-1],
                    'max': self.pp_data[var].max(),
                    'min': self.pp_data[var].min(),
                }
        
        # 计算安全系数
        if 'max_von_mises' in self.pp_data.columns:
            max_stress = self.pp_data['max_von_mises'].max()
            stats['safety_factor'] = YIELD_STRESS / max_stress if max_stress > 0 else float('inf')
        
        return stats

# ============================================================================
# 绘图函数
# ============================================================================
def plot_time_histories(data, pdf):
    """绘制时间历史图"""
    if data.pp_data is None:
        return
    
    time = data.get_pp('time')
    if time is None:
        return
    
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    fig.suptitle('时间历史分析', fontsize=14, fontweight='bold')
    
    # 1. 应力历史
    ax = axes[0, 0]
    if 'max_von_mises' in data.pp_data.columns:
        ax.plot(time, data.get_pp('max_von_mises') / 1e6, 'b-', linewidth=2)
        ax.axhline(y=YIELD_STRESS/1e6, color='r', linestyle='--', 
                   label=f'Yield Stress ({YIELD_STRESS/1e6:.1f} MPa)')
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('Max Von Mises Stress (MPa)')
        ax.set_title('Maximum Stress History')
        ax.grid(True, alpha=0.3)
        ax.legend()
    
    # 2. 位移历史
    ax = axes[0, 1]
    has_disp = False
    if 'max_disp_z' in data.pp_data.columns:
        ax.plot(time, data.get_pp('max_disp_z') * 1000, 'g-', linewidth=2, label='Max disp_z')
        has_disp = True
    if 'min_disp_z' in data.pp_data.columns:
        ax.plot(time, data.get_pp('min_disp_z') * 1000, 'r-', linewidth=2, label='Min disp_z')
        has_disp = True
    if has_disp:
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('Displacement (mm)')
        ax.set_title('Displacement History')
        ax.grid(True, alpha=0.3)
        ax.legend()
    
    # 3. 温度历史
    ax = axes[0, 2]
    if 'max_temperature' in data.pp_data.columns:
        ax.plot(time, data.get_pp('max_temperature'), 'm-', linewidth=2, label='Max')
    if 'avg_temperature' in data.pp_data.columns:
        ax.plot(time, data.get_pp('avg_temperature'), 'c-', linewidth=2, label='Average')
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Temperature (K)')
    ax.set_title('Temperature History')
    ax.grid(True, alpha=0.3)
    ax.legend()
    
    # 4. 反力历史
    ax = axes[1, 0]
    if 'total_reaction' in data.pp_data.columns:
        ax.plot(time, data.get_pp('total_reaction') / 1000, 'purple', linewidth=2)
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('Total Reaction Force (kN)')
        ax.set_title('Reaction Force History')
        ax.grid(True, alpha=0.3)
    
    # 5. 应变能历史
    ax = axes[1, 1]
    if 'strain_energy' in data.pp_data.columns:
        ax.plot(time, data.get_pp('strain_energy'), 'orange', linewidth=2)
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('Strain Energy (J)')
        ax.set_title('Strain Energy History')
        ax.grid(True, alpha=0.3)
    
    # 6. 材料属性变化
    ax = axes[1, 2]
    if 'avg_E' in data.pp_data.columns:
        E_ratio = data.get_pp('avg_E') / E_STEEL
        ax.plot(time, E_ratio * 100, 'brown', linewidth=2)
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('E / E₀ (%)')
        ax.set_title('Young\'s Modulus Retention')
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    pdf.savefig(fig, bbox_inches='tight')
    plt.close()
    print("  ✓ 时间历史图")


def plot_centerline_distributions(data, pdf):
    """绘制中心线分布"""
    cl = data.get_vpp('centerline')
    if cl is None:
        return
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('沿梁长度中心线分布 (最终时间步)', fontsize=14, fontweight='bold')
    
    # 1. 位移分布
    ax = axes[0, 0]
    if 'x' in cl.columns and 'disp_z' in cl.columns:
        ax.plot(cl['x'], cl['disp_z'] * 1000, 'b-', linewidth=2)
        ax.set_xlabel('Position along beam (m)')
        ax.set_ylabel('Displacement Z (mm)')
        ax.set_title('Vertical Displacement Distribution')
        ax.grid(True, alpha=0.3)
    
    # 2. 应力分布
    ax = axes[0, 1]
    if 'x' in cl.columns:
        if 'stress_xx' in cl.columns:
            ax.plot(cl['x'], cl['stress_xx'] / 1e6, 'r-', linewidth=2, label='σ_xx')
        if 'stress_zz' in cl.columns:
            ax.plot(cl['x'], cl['stress_zz'] / 1e6, 'g-', linewidth=2, label='σ_zz')
        if 'von_mises' in cl.columns:
            ax.plot(cl['x'], cl['von_mises'] / 1e6, 'm-', linewidth=2, label='Von Mises')
        ax.axhline(y=YIELD_STRESS/1e6, color='r', linestyle='--', alpha=0.5)
        ax.set_xlabel('Position along beam (m)')
        ax.set_ylabel('Stress (MPa)')
        ax.set_title('Stress Distribution')
        ax.grid(True, alpha=0.3)
        ax.legend()
    
    # 3. 温度分布
    ax = axes[1, 0]
    if 'x' in cl.columns and 'temperature' in cl.columns:
        ax.plot(cl['x'], cl['temperature'], 'orange', linewidth=2)
        ax.set_xlabel('Position along beam (m)')
        ax.set_ylabel('Temperature (K)')
        ax.set_title('Temperature Distribution')
        ax.grid(True, alpha=0.3)
    
    # 4. 材料属性分布
    ax = axes[1, 1]
    if 'x' in cl.columns and 'E_aux' in cl.columns:
        ax.plot(cl['x'], cl['E_aux'] / 1e9, 'purple', linewidth=2)
        ax.set_xlabel('Position along beam (m)')
        ax.set_ylabel('Young\'s Modulus (GPa)')
        ax.set_title('Temperature-Dependent Stiffness')
        ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    pdf.savefig(fig, bbox_inches='tight')
    plt.close()
    print("  ✓ 中心线分布图")


def plot_height_profiles(data, pdf):
    """绘制高度方向应力分布"""
    hp_fixed = data.get_vpp('height_profile_fixed')
    hp_free = data.get_vpp('height_profile_free')
    
    if hp_fixed is None and hp_free is None:
        return
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    fig.suptitle('沿高度方向应力分布 (最终时间步)', fontsize=14, fontweight='bold')
    
    # 固定端
    ax = axes[0]
    if hp_fixed is not None and 'z' in hp_fixed.columns:
        if 'stress_xx' in hp_fixed.columns:
            ax.plot(hp_fixed['stress_xx'] / 1e6, hp_fixed['z'] * 1000, 'r-', 
                   linewidth=2, label='σ_xx')
        if 'stress_yy' in hp_fixed.columns:
            ax.plot(hp_fixed['stress_yy'] / 1e6, hp_fixed['z'] * 1000, 'g-', 
                   linewidth=2, label='σ_yy')
        if 'stress_zz' in hp_fixed.columns:
            ax.plot(hp_fixed['stress_zz'] / 1e6, hp_fixed['z'] * 1000, 'b-', 
                   linewidth=2, label='σ_zz')
        ax.axvline(x=0, color='k', linestyle='-', alpha=0.3)
        ax.set_ylabel('Height (mm)')
        ax.set_xlabel('Stress (MPa)')
        ax.set_title('Fixed End Cross-Section')
        ax.grid(True, alpha=0.3)
        ax.legend()
    
    # 自由端
    ax = axes[1]
    if hp_free is not None and 'z' in hp_free.columns:
        if 'stress_xx' in hp_free.columns:
            ax.plot(hp_free['stress_xx'] / 1e6, hp_free['z'] * 1000, 'r-', 
                   linewidth=2, label='σ_xx')
        if 'stress_yy' in hp_free.columns:
            ax.plot(hp_free['stress_yy'] / 1e6, hp_free['z'] * 1000, 'g-', 
                   linewidth=2, label='σ_yy')
        if 'stress_zz' in hp_free.columns:
            ax.plot(hp_free['stress_zz'] / 1e6, hp_free['z'] * 1000, 'b-', 
                   linewidth=2, label='σ_zz')
        ax.axvline(x=0, color='k', linestyle='-', alpha=0.3)
        ax.set_ylabel('Height (mm)')
        ax.set_xlabel('Stress (MPa)')
        ax.set_title('Free End Cross-Section')
        ax.grid(True, alpha=0.3)
        ax.legend()
    
    plt.tight_layout()
    pdf.savefig(fig, bbox_inches='tight')
    plt.close()
    print("  ✓ 高度方向分布图")


def plot_stress_analysis(data, pdf):
    """绘制详细的应力分析图"""
    if data.pp_data is None:
        return
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    fig.suptitle('应力分析详细报告', fontsize=14, fontweight='bold')
    
    time = data.get_pp('time')
    
    # 1. 多应力分量历史
    ax = axes[0, 0]
    stress_vars = ['max_stress_xx', 'max_stress_yy', 'max_stress_zz', 'max_von_mises']
    colors = ['r', 'g', 'b', 'm']
    for var, color in zip(stress_vars, colors):
        if var in data.pp_data.columns:
            label = var.replace('max_', '').replace('_', ' ').title()
            ax.plot(time, data.get_pp(var) / 1e6, color=color, 
                   linewidth=2, label=label)
    ax.axhline(y=YIELD_STRESS/1e6, color='r', linestyle='--', 
               label=f'Yield ({YIELD_STRESS/1e6:.0f} MPa)')
    ax.set_xlabel('Time (s)')
    ax.set_ylabel('Stress (MPa)')
    ax.set_title('Stress Components History')
    ax.grid(True, alpha=0.3)
    ax.legend(fontsize=8)
    
    # 2. 安全系数历史
    ax = axes[0, 1]
    if 'max_von_mises' in data.pp_data.columns:
        sf = YIELD_STRESS / data.get_pp('max_von_mises')
        ax.plot(time, sf, 'b-', linewidth=2)
        ax.axhline(y=1.0, color='r', linestyle='--', label='SF = 1.0 (Critical)')
        ax.axhline(y=1.5, color='orange', linestyle='--', label='SF = 1.5 (Minimum)')
        ax.axhline(y=2.0, color='g', linestyle='--', label='SF = 2.0 (Safe)')
        ax.set_xlabel('Time (s)')
        ax.set_ylabel('Safety Factor')
        ax.set_title('Safety Factor History')
        ax.grid(True, alpha=0.3)
        ax.legend(fontsize=8)
        ax.set_ylim(bottom=0)
    
    # 3. 应力-位移关系
    ax = axes[1, 0]
    if 'max_von_mises' in data.pp_data.columns and 'min_disp_z' in data.pp_data.columns:
        stress = data.get_pp('max_von_mises') / 1e6
        disp = data.get_pp('min_disp_z') * 1000
        ax.plot(disp, stress, 'purple', linewidth=2)
        ax.scatter(disp.iloc[0], stress.iloc[0], color='g', s=100, 
                  marker='o', label='Start', zorder=5)
        ax.scatter(disp.iloc[-1], stress.iloc[-1], color='r', s=100, 
                  marker='s', label='End', zorder=5)
        ax.set_xlabel('Max Displacement (mm)')
        ax.set_ylabel('Max Stress (MPa)')
        ax.set_title('Stress-Displacement Relationship')
        ax.grid(True, alpha=0.3)
        ax.legend()
    
    # 4. 应力统计直方图（如果有足够数据点）
    ax = axes[1, 1]
    if len(data.pp_data) > 5 and 'max_von_mises' in data.pp_data.columns:
        stress_values = data.get_pp('max_von_mises') / 1e6
        ax.hist(stress_values, bins=15, color='steelblue', edgecolor='black', alpha=0.7)
        ax.axvline(x=stress_values.mean(), color='r', linestyle='--', 
                  linewidth=2, label=f'Mean: {stress_values.mean():.2f} MPa')
        ax.axvline(x=YIELD_STRESS/1e6, color='orange', linestyle='--', 
                  linewidth=2, label=f'Yield: {YIELD_STRESS/1e6:.0f} MPa')
        ax.set_xlabel('Von Mises Stress (MPa)')
        ax.set_ylabel('Frequency')
        ax.set_title('Stress Distribution Histogram')
        ax.grid(True, alpha=0.3, axis='y')
        ax.legend()
    
    plt.tight_layout()
    pdf.savefig(fig, bbox_inches='tight')
    plt.close()
    print("  ✓ 应力分析图")


def plot_evolution_animation(data, pdf):
    """绘制演变过程"""
    cl = data.get_vpp('centerline')
    if cl is None or 'centerline' not in data.vpp_data:
        return
    
    files = data.vpp_data['centerline']['all_files']
    if len(files) < 3:
        return
    
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    fig.suptitle('位移和应力演变过程', fontsize=14, fontweight='bold')
    
    # 选取若干时间步展示
    indices = np.linspace(0, len(files)-1, min(6, len(files)), dtype=int)
    colors = plt.cm.viridis(np.linspace(0, 1, len(indices)))
    
    ax1 = axes[0]
    ax2 = axes[1]
    
    for i, idx in enumerate(indices):
        df = pd.read_csv(files[idx])
        if 'x' in df.columns and 'disp_z' in df.columns:
            ax1.plot(df['x'], df['disp_z'] * 1000, 
                    color=colors[i], linewidth=2, 
                    label=f'Step {idx}')
        if 'x' in df.columns and 'von_mises' in df.columns:
            ax2.plot(df['x'], df['von_mises'] / 1e6, 
                    color=colors[i], linewidth=2, 
                    label=f'Step {idx}')
    
    ax1.set_xlabel('Position (m)')
    ax1.set_ylabel('Displacement Z (mm)')
    ax1.set_title('Displacement Evolution')
    ax1.grid(True, alpha=0.3)
    ax1.legend(fontsize=8)
    
    ax2.set_xlabel('Position (m)')
    ax2.set_ylabel('Von Mises Stress (MPa)')
    ax2.set_title('Stress Evolution')
    ax2.grid(True, alpha=0.3)
    ax2.legend(fontsize=8)
    
    plt.tight_layout()
    pdf.savefig(fig, bbox_inches='tight')
    plt.close()
    print("  ✓ 演变过程图")


# ============================================================================
# 报告生成
# ============================================================================
def generate_text_report(data, filename):
    """生成文本报告"""
    with open(filename, 'w') as f:
        f.write("=" * 80 + "\n")
        f.write("                    仿真结果分析报告\n")
        f.write("=" * 80 + "\n\n")
        
        # 基本信息
        f.write("【基本信息】\n")
        if data.pp_data is not None:
            f.write(f"  时间步数: {len(data.pp_data)}\n")
            f.write(f"  总时间: {data.get_pp('time').iloc[-1]:.2f} s\n")
            f.write(f"  节点数: {data.get_pp('num_nodes').iloc[0]}\n")
            f.write(f"  单元数: {data.get_pp('num_elems').iloc[0]}\n")
            f.write(f"  自由度: {data.get_pp('num_dofs').iloc[0]}\n")
        
        f.write("\n" + "-" * 80 + "\n")
        
        # 关键结果
        f.write("【关键结果】\n")
        stats = data.get_summary_stats()
        
        if 'max_von_mises' in stats:
            f.write(f"\n应力结果:\n")
            f.write(f"  最大 von Mises 应力: {stats['max_von_mises']['max']:.4e} Pa\n")
            f.write(f"  最终 von Mises 应力: {stats['max_von_mises']['final']:.4e} Pa\n")
            if 'safety_factor' in stats:
                f.write(f"  安全系数: {stats['safety_factor']:.4f}\n")
                if stats['safety_factor'] < 1.0:
                    f.write(f"  ⚠️ 警告: 安全系数小于1，结构可能屈服!\n")
                elif stats['safety_factor'] < 1.5:
                    f.write(f"  ⚠️ 注意: 安全系数较低 (< 1.5)\n")
        
        if 'max_disp_z' in stats and 'min_disp_z' in stats:
            f.write(f"\n位移结果:\n")
            f.write(f"  最大 Z 位移: {stats['max_disp_z']['max']:.4e} m\n")
            f.write(f"  最小 Z 位移: {stats['min_disp_z']['min']:.4e} m\n")
        
        if 'max_temperature' in stats:
            f.write(f"\n温度结果:\n")
            f.write(f"  最高温度: {stats['max_temperature']['max']:.2f} K\n")
            f.write(f"  最终最高温度: {stats['max_temperature']['final']:.2f} K\n")
        
        if 'strain_energy' in stats:
            f.write(f"\n能量结果:\n")
            f.write(f"  最终应变能: {stats['strain_energy']['final']:.4e} J\n")
        
        f.write("\n" + "-" * 80 + "\n")
        f.write("报告生成完成\n")
    
    print(f"  ✓ 文本报告: {filename}")


def generate_csv_summary(data, filename):
    """生成 CSV 汇总"""
    if data.pp_data is None:
        return
    
    # 提取关键列
    key_cols = ['time', 'max_von_mises', 'max_disp_z', 'min_disp_z', 
                'max_temperature', 'strain_energy', 'total_reaction']
    
    summary_df = pd.DataFrame()
    for col in key_cols:
        if col in data.pp_data.columns:
            summary_df[col] = data.get_pp(col)
    
    # 计算安全系数
    if 'max_von_mises' in data.pp_data.columns:
        summary_df['safety_factor'] = YIELD_STRESS / data.get_pp('max_von_mises')
    
    summary_df.to_csv(filename, index=False)
    print(f"  ✓ CSV 汇总: {filename}")


# ============================================================================
# 主程序
# ============================================================================
def main():
    # 获取命令行参数
    prefix = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PREFIX
    
    print("=" * 80)
    print("                  仿真后处理脚本")
    print("=" * 80)
    print(f"\n数据前缀: {prefix}")
    
    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"输出目录: {OUTPUT_DIR}/\n")
    
    # 加载数据
    print("-" * 80)
    print("【数据加载】")
    data = SimulationData(prefix)
    
    if data.pp_data is None:
        print("\n✗ 未找到仿真数据，请确认仿真已成功运行！")
        return 1
    
    # 生成 PDF 报告
    print("\n" + "-" * 80)
    print("【生成图表】")
    pdf_file = os.path.join(OUTPUT_DIR, f"{prefix}_report.pdf")
    
    with PdfPages(pdf_file) as pdf:
        plot_time_histories(data, pdf)
        plot_centerline_distributions(data, pdf)
        plot_height_profiles(data, pdf)
        plot_stress_analysis(data, pdf)
        plot_evolution_animation(data, pdf)
    
    print(f"\n  PDF 报告: {pdf_file}")
    
    # 生成文本报告
    print("\n" + "-" * 80)
    print("【生成报告】")
    txt_file = os.path.join(OUTPUT_DIR, f"{prefix}_summary.txt")
    generate_text_report(data, txt_file)
    
    csv_file = os.path.join(OUTPUT_DIR, f"{prefix}_summary.csv")
    generate_csv_summary(data, csv_file)
    
    # 显示统计信息
    print("\n" + "-" * 80)
    print("【统计摘要】")
    stats = data.get_summary_stats()
    
    if 'max_von_mises' in stats:
        print(f"\n最大应力: {stats['max_von_mises']['max']:.4e} Pa")
    if 'safety_factor' in stats:
        print(f"安全系数: {stats['safety_factor']:.4f}")
    if 'max_disp_z' in stats:
        print(f"最大位移: {stats['max_disp_z']['max']:.4e} m")
    if 'max_temperature' in stats:
        print(f"最高温度: {stats['max_temperature']['max']:.2f} K")
    
    print("\n" + "=" * 80)
    print("后处理完成!")
    print("=" * 80)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())

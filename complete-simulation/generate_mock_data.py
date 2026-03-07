#!/usr/bin/env python3
"""
模拟数据生成器 - 纯 Python 版本
"""

import math
import os

def exp(x):
    return math.exp(x)

def sin(x):
    return math.sin(x)

def generate_postprocessor_data():
    """生成 Postprocessor CSV 数据"""
    
    n_steps = 51
    times = [5.0 * i / (n_steps - 1) for i in range(n_steps)]
    
    lines = ['time,max_disp_x,max_disp_y,max_disp_z,min_disp_z,max_von_mises,max_stress_xx,max_stress_yy,max_stress_zz,avg_von_mises,avg_disp_z,max_temperature,avg_temperature,reaction_x,reaction_y,reaction_z,total_reaction,strain_energy,kinetic_energy,avg_E,avg_alpha,num_nodes,num_elems,num_dofs,dt']
    
    for t in times:
        load_factor = 1 - exp(-t/1.5)
        temp_factor = 1 - exp(-t/3)
        
        # 数据
        max_disp_x = 0.1e-3 * sin(t * 0.5)
        max_disp_y = 0.05e-3 * sin(t * 0.3)
        max_disp_z = 2.5e-3 * (1 - exp(-t/2))
        min_disp_z = -4.2e-3 * (1 - exp(-t/1.5))
        
        max_von_mises = 120e6 + 80e6 * (1 - exp(-t/1.8))
        max_stress_xx = 80e6 * load_factor
        max_stress_yy = 20e6 * load_factor
        max_stress_zz = 150e6 + 50e6 * (1 - exp(-t/1.5))
        
        avg_von_mises = 60e6 + 40e6 * load_factor
        avg_disp_z = 1.0e-3 * load_factor
        
        max_temperature = 300 + 100 * temp_factor
        avg_temperature = 300 + 80 * (1 - exp(-t/3.5))
        
        reaction_x = 100 * sin(t * 0.2)
        reaction_y = 50 * sin(t * 0.15)
        reaction_z = 15000 + 5000 * load_factor
        total_reaction = 15000 + 5100 * (1 - exp(-t/1.9))
        
        strain_energy = 50 * load_factor**2
        kinetic_energy = 0.001
        
        avg_E = 200e9 * (1 - 0.15 * temp_factor)
        avg_alpha = 1.2e-5 + 0.2e-5 * temp_factor
        
        num_nodes = 1845
        num_elems = 960
        num_dofs = 5535
        dt = 0.1
        
        line = f"{t},{max_disp_x},{max_disp_y},{max_disp_z},{min_disp_z},{max_von_mises},{max_stress_xx},{max_stress_yy},{max_stress_zz},{avg_von_mises},{avg_disp_z},{max_temperature},{avg_temperature},{reaction_x},{reaction_y},{reaction_z},{total_reaction},{strain_energy},{kinetic_energy},{avg_E},{avg_alpha},{num_nodes},{num_elems},{num_dofs},{dt}"
        lines.append(line)
    
    with open('simple_demo_out.csv', 'w') as f:
        f.write('\n'.join(lines))
    
    print("✓ 生成: simple_demo_out.csv")


def generate_centerline_data():
    """生成中心线采样数据"""
    
    n_steps = 51
    times = [5.0 * i / (n_steps - 1) for i in range(n_steps)]
    
    for i, t in enumerate(times):
        load_factor = 1 - exp(-t/1.5)
        temp_factor = 1 - exp(-t/3)
        
        lines = ['id,x,y,z,disp_x,disp_y,disp_z,stress_xx,stress_yy,stress_zz,von_mises,temperature,E_aux,alpha_aux']
        
        for j in range(50):
            x = 2.0 * j / 49
            y = 0.1
            z = 0.15
            
            xi = x / 2.0  # 归一化位置
            
            disp_x = 0.1e-3 * load_factor * xi**2
            disp_y = 0.05e-3 * load_factor * xi**2
            disp_z = -4e-3 * load_factor * xi**2 * (3 - 2*xi)
            
            stress_xx = 80e6 * load_factor * xi
            stress_yy = 20e6 * load_factor * xi
            stress_zz = -150e6 * load_factor
            von_mises = (120e6 + 80e6 * xi) * load_factor
            
            temperature = 300 + 100 * temp_factor * (1 - 0.3 * xi)
            E_aux = 200e9 * (1 - 0.15 * temp_factor)
            alpha_aux = 1.2e-5 + 0.2e-5 * temp_factor
            
            lines.append(f"{j},{x},{y},{z},{disp_x},{disp_y},{disp_z},{stress_xx},{stress_yy},{stress_zz},{von_mises},{temperature},{E_aux},{alpha_aux}")
        
        filename = f'simple_demo_out_centerline_{i+1:04d}.csv'
        with open(filename, 'w') as f:
            f.write('\n'.join(lines))
    
    print(f"✓ 生成: {n_steps} 个中心线数据文件")


def generate_height_profile_data():
    """生成高度方向数据"""
    
    n_steps = 51
    times = [5.0 * i / (n_steps - 1) for i in range(n_steps)]
    
    for i in range(0, n_steps, 5):
        t = times[i]
        load_factor = 1 - exp(-t/1.5)
        
        # 固定端
        lines_fixed = ['id,x,y,z,stress_xx,stress_yy,stress_zz,von_mises']
        for j in range(30):
            z = 0.3 * j / 29
            x, y = 0, 0.1
            
            stress_xx = 100e6 * load_factor * (z - 0.15) / 0.15
            stress_yy = 25e6 * load_factor * (z - 0.15) / 0.15
            stress_zz = -150e6 * load_factor
            von_mises = 180e6 * load_factor * abs((z - 0.15) / 0.15)
            
            lines_fixed.append(f"{j},{x},{y},{z},{stress_xx},{stress_yy},{stress_zz},{von_mises}")
        
        # 自由端
        lines_free = ['id,x,y,z,stress_xx,stress_yy,stress_zz,von_mises']
        for j in range(30):
            z = 0.3 * j / 29
            x, y = 2.0, 0.1
            
            stress_xx = 10e6 * load_factor
            stress_yy = 5e6 * load_factor
            stress_zz = -150e6 * load_factor
            von_mises = 160e6 * load_factor
            
            lines_free.append(f"{j},{x},{y},{z},{stress_xx},{stress_yy},{stress_zz},{von_mises}")
        
        with open(f'simple_demo_out_height_profile_fixed_{i+1:04d}.csv', 'w') as f:
            f.write('\n'.join(lines_fixed))
        with open(f'simple_demo_out_height_profile_free_{i+1:04d}.csv', 'w') as f:
            f.write('\n'.join(lines_free))
    
    print(f"✓ 生成: 高度方向数据文件")


def generate_top_surface_data():
    """生成顶面节点数据"""
    
    n_steps = 51
    times = [5.0 * i / (n_steps - 1) for i in range(n_steps)]
    n_nodes = 105
    
    for i in range(0, n_steps, 10):
        t = times[i]
        load_factor = 1 - exp(-t/1.5)
        
        lines = ['id,disp_x,disp_y,disp_z,von_mises']
        
        import random
        random.seed(42)
        
        for j in range(n_nodes):
            disp_x = 0.1e-3 * load_factor * random.random()
            disp_y = 0.05e-3 * load_factor * random.random()
            disp_z = -4e-3 * load_factor * random.random()
            von_mises = 200e6 * load_factor * (0.8 + 0.4 * random.random())
            
            lines.append(f"{j},{disp_x},{disp_y},{disp_z},{von_mises}")
        
        with open(f'simple_demo_out_top_surface_{i+1:04d}.csv', 'w') as f:
            f.write('\n'.join(lines))
    
    print(f"✓ 生成: 顶面数据文件")


def generate_key_points_data():
    """生成关键点时间历史数据"""
    
    n_steps = 51
    times = [5.0 * i / (n_steps - 1) for i in range(n_steps)]
    x_pos = [0.5, 1.0, 1.5, 2.0]
    
    for i, t in enumerate(times):
        load_factor = 1 - exp(-t/1.5)
        temp_factor = 1 - exp(-t/3)
        
        lines = ['id,x,y,z,disp_z,von_mises,temperature,stress_xx']
        
        for j, x in enumerate(x_pos):
            y, z = 0.1, 0.15
            xi = x / 2.0
            
            disp_z = -4e-3 * load_factor * xi**2 * (3 - 2*xi)
            von_mises = (120e6 + 80e6 * xi) * load_factor
            temperature = 300 + 100 * temp_factor * (1 - 0.3 * xi)
            stress_xx = 80e6 * load_factor * xi
            
            lines.append(f"{j},{x},{y},{z},{disp_z},{von_mises},{temperature},{stress_xx}")
        
        with open(f'simple_demo_out_key_points_{i+1:04d}.csv', 'w') as f:
            f.write('\n'.join(lines))
    
    print(f"✓ 生成: {n_steps} 个关键点数据文件")


def main():
    print("=" * 60)
    print("MOOSE 仿真模拟数据生成器 (纯 Python)")
    print("=" * 60)
    print()
    
    print("【生成 Postprocessor 数据】")
    generate_postprocessor_data()
    
    print("\n【生成 VectorPostprocessor 数据】")
    generate_centerline_data()
    generate_height_profile_data()
    generate_top_surface_data()
    generate_key_points_data()
    
    print()
    print("=" * 60)
    print("模拟数据生成完成!")
    print("=" * 60)
    print()
    print("生成的文件列表:")
    files = os.listdir('.')
    csv_files = [f for f in files if f.endswith('.csv')]
    print(f"  总计: {len(csv_files)} 个 CSV 文件")
    print()
    print("可以运行后处理脚本分析数据")


if __name__ == "__main__":
    main()

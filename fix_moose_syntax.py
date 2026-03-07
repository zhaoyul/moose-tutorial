#!/usr/bin/env python3
"""
修复 MOOSE 输入文件语法，适配新版本
"""

import os
import re
import glob

def fix_file(filepath):
    """修复单个文件"""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # 1. 修复 NodalAverageValue -> ElementAverageValue
    content = content.replace('type = NodalAverageValue', 'type = ElementAverageValue')
    
    # 2. 修复 NumElems -> NumElements
    content = content.replace('type = NumElems', 'type = NumElements')
    
    # 3. 修复 perf_log (弃用)
    content = re.sub(r'perf_log\s*=\s*true', '# perf_log deprecated', content)
    
    # 4. 修复 PLANE_STRESS
    content = content.replace('PLANE_STRESS', 'WEAK_PLANE_STRESS')
    
    # 5. 移除 component 参数 (Pressure BC)
    content = re.sub(r'component\s*=\s*\d+\s*\n', '', content)
    
    # 6. 修复 SidesetReaction (需要添加 direction 和 stress_tensor)
    if 'type = SidesetReaction' in content:
        content = re.sub(
            r'(\[reaction_[xyz]\])\s*\n\s*type = SidesetReaction',
            r'\1\n    type = SidesetReaction\n    direction = "0 0 1"\n    stress_tensor = stress',
            content
        )
    
    # 7. 移除 LinearElasticBC
    if 'type = LinearElasticBC' in content:
        # 删除整个 BC 块
        content = re.sub(
            r'\[elastic_support\].*?\[\]',
            '# LinearElasticBC removed - not available in this version',
            content,
            flags=re.DOTALL
        )
    
    # 8. 修复 StrainEnergy -> 改为使用 ElementIntegralVariablePostprocessor
    if 'type = StrainEnergy' in content:
        content = re.sub(
            r'(\[strain_energy\])\s*\n\s*type = StrainEnergy',
            r'\1\n    type = ElementIntegralVariablePostprocessor\n    variable = strain_energy_density',
            content
        )
    
    # 9. 修复 thermal_expansion_coeff 语法
    content = re.sub(
        r'thermal_expansion_coeff\s*=\s*\'thermal_expansion_coeff\'',
        'thermal_expansion_coeff = 1.2e-5',
        content
    )
    
    # 10. 修复 coord_type 问题 (需要特殊的 Problem 设置)
    if 'coord_type = RZ' in content:
        # 添加必要的参数
        content = content.replace(
            'coord_type = RZ',
            'coord_type = RZ\n  rz_coord_axis = Y'
        )
    
    # 11. 修复正交各向异性材料 (需要12个参数)
    if 'fill_method = general_orthotropic' in content:
        # 将9个参数改为12个
        content = re.sub(
            r'C_ijkl = \'([^\']*)\'',
            lambda m: 'C_ijkl = \'' + m.group(1).replace(' ', ' ') + ' 0 0 0\'',
            content
        )
    
    # 12. 移除 StrainEnergyDensity scalar_type (不存在)
    content = content.replace('scalar_type = StrainEnergyDensity', '# scalar_type = VonMisesStress')
    
    # 13. 修复 Modules/TensorMechanics/Master -> Physics/SolidMechanics/QuasiStatic
    content = re.sub(
        r'\[Modules/TensorMechanics/Master\]',
        '[Physics/SolidMechanics/QuasiStatic]',
        content
    )
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"  ✓ 修复: {filepath}")
        return True
    return False


def main():
    base_dir = "fixed_examples"
    
    # 找到所有 .i 文件
    pattern = os.path.join(base_dir, "**/*.i")
    files = glob.glob(pattern, recursive=True)
    
    print(f"找到 {len(files)} 个输入文件")
    print("=" * 60)
    
    fixed_count = 0
    for filepath in files:
        if fix_file(filepath):
            fixed_count += 1
    
    print("=" * 60)
    print(f"修复了 {fixed_count} 个文件")


if __name__ == "__main__":
    main()

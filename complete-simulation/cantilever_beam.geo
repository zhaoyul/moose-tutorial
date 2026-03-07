//==============================================================================
// Gmsh 几何文件 - 悬臂梁
// 命令行使用: gmsh -3 cantilever_beam.geo -o cantilever_beam.msh
//==============================================================================

// 参数定义
L = 2.0;    // 梁长度 (m)
W = 0.2;    // 梁宽度 (m)
H = 0.3;    // 梁高度 (m)
lc = 0.05;  // 特征网格尺寸 (m)

// 顶点定义 (左下角开始，逆时针)
// 底面 (z=0)
Point(1) = {0, 0, 0, lc};      // 固定端-后-下
Point(2) = {L, 0, 0, lc};      // 自由端-后-下
Point(3) = {L, W, 0, lc};      // 自由端-前-下
Point(4) = {0, W, 0, lc};      // 固定端-前-下

// 顶面 (z=H)
Point(5) = {0, 0, H, lc};      // 固定端-后-上
Point(6) = {L, 0, H, lc};      // 自由端-后-上
Point(7) = {L, W, H, lc};      // 自由端-前-上
Point(8) = {0, W, H, lc};      // 固定端-前-上

// 加载点 (中点，顶面)
Point(9) = {L/2, W/2, H, lc/2};  // 更细的网格

// 边定义
// 底面
Line(1) = {1, 2};   // 底面-后
Line(2) = {2, 3};   // 底面-右 (自由端底边)
Line(3) = {3, 4};   // 底面-前
Line(4) = {4, 1};   // 底面-左 (固定端底边)

// 顶面
Line(5) = {5, 6};   // 顶面-后
Line(6) = {6, 7};   // 顶面-右 (自由端顶边)
Line(7) = {7, 8};   // 顶面-前
Line(8) = {8, 5};   // 顶面-左 (固定端顶边)

// 垂直边
Line(9)  = {1, 5};  // 固定端-后-下->上
Line(10) = {2, 6};  // 自由端-后-下->上
Line(11) = {3, 7};  // 自由端-前-下->上
Line(12) = {4, 8};  // 固定端-前-下->上

// 表面定义
// 底面
Line Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

// 顶面
Line Loop(2) = {5, 6, 7, 8};
Plane Surface(2) = {2};

// 后面 (y=0)
Line Loop(3) = {1, 10, -5, -9};
Plane Surface(3) = {3};

// 前面 (y=W)
Line Loop(4) = {3, 12, -7, -11};
Plane Surface(4) = {4};

// 右面/自由端 (x=L)
Line Loop(5) = {2, 11, -6, -10};
Plane Surface(5) = {5};

// 左面/固定端 (x=0)
Line Loop(6) = {4, 9, -8, -12};
Plane Surface(6) = {6};

// 体积定义
Surface Loop(1) = {1, 2, 3, 4, 5, 6};
Volume(1) = {1};

// 物理组定义
// 体积
Physical Volume("beam_volume") = {1};

// 边界
Physical Surface("fixed_end") = {6};    // 固定端 (x=0)
Physical Surface("free_end") = {5};     // 自由端 (x=L)
Physical Surface("top") = {2};          // 顶面 (z=H)
Physical Surface("bottom") = {1};       // 底面 (z=0)
Physical Surface("front") = {4};        // 前面 (y=W)
Physical Surface("back") = {3};         // 后面 (y=0)

// 加载点
Physical Point("loading_point") = {9};

// 网格控制
// 在固定端和自由端附近加密
Field[1] = Box;
Field[1].VIn = lc/2;
Field[1].VOut = lc;
Field[1].XMin = 0;
Field[1].XMax = 0.2;
Field[1].YMin = 0;
Field[1].YMax = W;
Field[1].ZMin = 0;
Field[1].ZMax = H;

Field[2] = Box;
Field[2].VIn = lc/2;
Field[2].VOut = lc;
Field[2].XMin = L-0.2;
Field[2].XMax = L;
Field[2].YMin = 0;
Field[2].YMax = W;
Field[2].ZMin = 0;
Field[2].ZMax = H;

Field[3] = Min;
Field[3].FieldsList = {1, 2};
Background Field = 3;

// 网格算法设置
// 使用 Delaunay 算法
Mesh.Algorithm = 1;     // 2D: 1=Delaunay, 6=Frontal
Mesh.Algorithm3D = 1;   // 3D: 1=Delaunay, 4=Frontal

// 生成网格
Mesh 3;

// 保存网格（如果在命令行没有指定 -o）
// Save "cantilever_beam.msh";

//==============================================================================
// 使用说明:
//
// 1. 生成网格 (默认): 
//    gmsh -3 cantilever_beam.geo
//
// 2. 生成并保存到指定文件:
//    gmsh -3 cantilever_beam.geo -o my_mesh.msh
//
// 3. 查看网格 (GUI):
//    gmsh cantilever_beam.geo
//
// 4. 调整网格密度:
//    gmsh -3 cantilever_beam.geo -clscale 0.5  // 更密的网格
//    gmsh -3 cantilever_beam.geo -clscale 2.0  // 更粗的网格
//
// 5. 生成二阶单元:
//    gmsh -3 -order 2 cantilever_beam.geo
//
// 6. 导出其他格式:
//    gmsh -3 cantilever_beam.geo -o mesh.inp   // Abaqus
//    gmsh -3 cantilever_beam.geo -o mesh.vtk   // VTK
//
//==============================================================================

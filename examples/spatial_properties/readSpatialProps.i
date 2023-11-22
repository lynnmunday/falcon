#Notes:
#This input file just makes the heterogeneous Mesh
# Permeability at injection point is k_inj
# Permeability at production point is k_prod
# fit y=a*exp(b*x) with a=k_inj
k_inj = 1e-12
k_prod = 1e-14
distance = 100
b = '${fparse (log(k_prod)-log(k_inj))/distance}'
a = ${k_inj}

# injections points:
#zone 1:
p1inx = 4.080888831e+02
p1iny = 2.584756670e+02
p1inz = 2.098508678e+02
#zone 2:
p2inx = 3.101174933e+02
p2iny = 2.501984880e+02
p2inz = 2.518588363e+02
#zone 3:
p3inx = 2.020881906e+02
p3iny = 2.410715595e+02
p3inz = 2.981794157e+02

[Mesh]
  #------ Reading in the entire domain.
  # Mesh Limits from bigForge_frac_2m_matrix_100m.e:
  # Min X = -7.000000000E+02, Max X =  1.100000000E+03, Range =  1.800000000E+03
  # Min Y = -5.000000000E+02, Max Y =  1.000000000E+03, Range =  1.500000000E+03
  # Min Z = -1.500000000E+02, Max Z =  8.500000000E+02, Range =  1.000000000E+03
  # [generated_mesh]
  #   type = GeneratedMeshGenerator
  #   dim = 3
  #   xmin = -700
  #   xmax = 1100
  #   ymin = -500
  #   ymax = 1000
  #   zmin = -150
  #   zmax = 850
  #   nx = 72
  #   ny = 60
  #   nz = 40
  # []
  #------ The below mesh only reads in a portion of the mesh
  # Mesh Limits OF DFN MESH:
  # Min X =  1.490499310E+02, Max X =  4.870499958E+02, Range =  3.380000648E+02
  # Min Y =  9.315984323E+01, Max Y =  4.181598411E+02, Range =  3.249999978E+02
  # Min Z =  1.043188761E+02, Max Z =  4.995600143E+02, Range =  3.952411383E+02
  [gmg]
    type = GeneratedMeshGenerator
    dim = 3
    xmin = 160
    xmax = 440
    ymin = 120
    ymax = 380
    zmin = 80
    zmax = 520
    nx = 14
    ny = 13
    nz = 22
  []
  [zone1]
    type = SubdomainBoundingBoxGenerator
    input = gmg
    bottom_left = '160 120 80'
    top_right = '180 140 100'
    block_id = 1
  []
  [zone2]
    type = SubdomainBoundingBoxGenerator
    input = zone1
    bottom_left = '160 360 80'
    top_right = '180 380 100'
    block_id = 2
  []
  [zone3]
    type = SubdomainBoundingBoxGenerator
    input = zone2
    bottom_left = '160 120 500'
    top_right = '180 140 520'
    block_id = 3
  []
[]

##############################################################
# 'DFN_Aleta_permeabilities_20230915/input.csv'
# preprocess csv file Local_20m_Basic_Properties_1.csv
# Remove header line and then remove windows characters with:
# dos2unix Local_20m_Basic_Properties_1.csv
# Column Headers:
# CellX[m],CellY[m],CellZ[m],Total_Perm_I,Total_Perm_J,Total_Perm_K,Total_Porosity,Total_Compressibility
[UserObjects]
  [reader_grid]
    type = PropertyReadFile
    prop_file_name = input.csv
    read_type = 'voronoi'
    nprop = 8
    nvoronoi = 337500
  []
[]

##############################################################
# mark elements along cut and move to new block

[AuxVariables]
  [cut]
    order = CONSTANT
    family = MONOMIAL
  []
  [zone]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [cut]
    type = MarkCutElems
    mesh_file = make_zone_frac_meshes_in.e
    variable = cut
    intersection_tolerance = 20
  []
  [zone]
    type = ParsedAux
    variable = zone
    coupled_variables = 'cut'
    expression = 'x*cut'
    use_xyzt = true
  []
[]

[UserObjects]
  [zone3]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'zone'
    criterion_type = ABOVE
    threshold = 180
    subdomain_id = 3
    complement_subdomain_id = 0
    execute_on = 'TIMESTEP_END'
    block = '0 3'
  []
  [zone2]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'zone'
    criterion_type = ABOVE
    threshold = 300
    subdomain_id = 2
    complement_subdomain_id = 0
    execute_on = 'TIMESTEP_END'
    block = '0 2'
  []
  [zone1]
    type = CoupledVarThresholdElementSubdomainModifier
    coupled_var = 'zone'
    criterion_type = ABOVE
    threshold = 400
    subdomain_id = 1
    complement_subdomain_id = 0
    execute_on = 'TIMESTEP_END'
    block = '0 1'
  []
[]

##############################################################
[Problem]
  solve = False
[]

##############################################################
[AuxVariables]
  [read_perm_xx]
    order = CONSTANT
    family = MONOMIAL
  []
  [read_perm_yy]
    order = CONSTANT
    family = MONOMIAL
  []
  [read_perm_zz]
    order = CONSTANT
    family = MONOMIAL
  []
  [porosity]
    order = CONSTANT
    family = MONOMIAL
  []
  [permeability]
    order = CONSTANT
    family = MONOMIAL
  []
[]

##############################################################
[AuxKernels]
  [read_perm_xx]
    type = FunctionAux
    variable = read_perm_xx
    function = read_grid_xx
  []
  [read_perm_yy]
    type = FunctionAux
    variable = read_perm_yy
    function = read_grid_yy
  []
  [read_perm_zz]
    type = FunctionAux
    variable = read_perm_zz
    function = read_grid_zz
  []
  [porosity]
    type = FunctionAux
    function = read_grid_poro
    variable = porosity
  []
  [permeability_matrix]
    type = ParsedAux
    variable = permeability
    coupled_variables = 'read_perm_xx read_perm_yy read_perm_zz'
    expression = 'sqrt(read_perm_xx^2+read_perm_yy^2+read_perm_zz^2)'
    use_xyzt = true
    block = 0
  []
  [permeability_zone1]
    type = ParsedAux
    variable = permeability
    expression = '${a}*exp(${b}*sqrt((x-${p1inx})^2+(y-${p1iny})^2+(z-${p1inz})^2))'
    use_xyzt = true
    block = 1
  []
  [porosity_zone2]
    type = ParsedAux
    variable = permeability
    expression = '${a}*exp(${b}*sqrt((x-${p2inx})^2+(y-${p2iny})^2+(z-${p2inz})^2))'
    use_xyzt = true
    block = 2
  []
  [porosity_zone3]
    type = ParsedAux
    variable = permeability
    expression = '${a}*exp(${b}*sqrt((x-${p3inx})^2+(y-${p3iny})^2+(z-${p3inz})^2))'
    use_xyzt = true
    block = 3
  []
[]

##############################################################
[Functions]
  [read_grid_poro]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = 'reader_grid'
    read_type = 'voronoi'
    column_number = '6'
  []
  [read_grid_xx]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = 'reader_grid'
    read_type = 'voronoi'
    column_number = '3'
  []
  [read_grid_yy]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = 'reader_grid'
    read_type = 'voronoi'
    column_number = '4'
  []
  [read_grid_zz]
    type = PiecewiseConstantFromCSV
    read_prop_user_object = 'reader_grid'
    read_type = 'voronoi'
    column_number = '5'
  []
[]

###########################################################
[Executioner]
  type = Transient
  num_steps = 2
  dt = 1
  solve_type = Newton
  l_tol = 1e-4
  l_max_its = 2000
  nl_max_its = 200

  nl_abs_tol = 1e-8
  nl_rel_tol = 1e-8
[]

##############################################################
[Outputs]
  exodus = true
[]

[Mesh]
  uniform_refine = 0
  [generate]
    type = GeneratedMeshGenerator
    dim = 3
    nx = 20
    xmin = -50
    xmax = 50
    ny = 20
    ymin = -50
    ymax = 50
    nz = 8
    zmin = -20
    zmax = 20
  []
[]

[Problem]
  kernel_coverage_check = false
  solve = false
[]

[GlobalParams]
  PorousFlowDictator = dictator
[]

[Variables]
  [matrix_P]
  []
  [matrix_T]
  []
[]

[ICs]
  [matrix_P]
    type = FunctionIC
    variable = matrix_P
    function = insitu_pp
  []
  [matrix_T]
    type = FunctionIC
    variable = matrix_T
    function = insitu_T
  []
[]

[BCs]
[]

[Functions]
  [insitu_pp]
    type = ParsedFunction
    value = '9.81*1000*(3000 - z)'
  []
  [insitu_T]
    type = ParsedFunction
    value = '363'
  []
[]

[PorousFlowFullySaturated]
  coupling_type = ThermoHydro
  porepressure = matrix_P
  temperature = matrix_T
  fp = water
  gravity = '0 0 -9.81'
  pressure_unit = Pa
[]

[Modules]
  [FluidProperties]
    [water]
      type = SimpleFluidProperties
      thermal_expansion = 0
    []
  []
[]

[Materials]
  [porosity]
    type = PorousFlowPorosityConst
    porosity = 0.1
  []
  [permeability]
    type = PorousFlowPermeabilityConst
    permeability = '1E-16 0 0   0 1E-16 0   0 0 1E-16'
  []
  [internal_energy]
    type = PorousFlowMatrixInternalEnergy
    density = 2875
    specific_heat_capacity = 825
  []
  [aq_thermal_conductivity]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '2.83 0 0  0 2.83 0  0 0 2.83'
  []
[]

[Executioner]
  type = Transient
  dt = 2
  num_steps = 2
[]

[Outputs]
  json = true
  csv = true
  [perfgraph]
    type = JSON
  []
  [pgraph]
    type = PerfGraphOutput
    execute_on = 'initial final'  # Default is "final"
    level = 2                     # Default is 1
    heaviest_branch = true        # Default is false
    heaviest_sections = 7         # Default is 0
  []
[]

[DiracKernels]
  [heat_from_fracture]
    type = ReporterPointSource
    variable = matrix_T
    value_name = heat_transfer_rate/transferred_joules_per_s
    x_coord_name = heat_transfer_rate/x
    y_coord_name = heat_transfer_rate/y
    z_coord_name = heat_transfer_rate/z
  []
[]

[Reporters]
  [heat_transfer_rate]
    type = ConstantReporter
    real_vector_names = 'transferred_joules_per_s x y z'
    real_vector_values = '10000; 0; 0; 0'
    outputs = none
  []
  [perf_graph]
     type = PerfGraphReporter
     outputs = perfgraph
  []
  [mesh_info]
    type = MeshInfo
    items = 'num_dofs num_dofs_nonlinear num_dofs_auxiliary num_elements
             num_nodes num_local_dofs num_local_dofs_nonlinear
             num_local_dofs_auxiliary num_local_elements num_local_nodes'
  []
[]

[AuxVariables]
  [normal_thermal_conductivity]
    family = MONOMIAL
    order = CONSTANT
  []
  [fracture_normal_x]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
  []
  [fracture_normal_y]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 1
  []
  [fracture_normal_z]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0
  []
  [element_normal_length]
    family = MONOMIAL
    order = CONSTANT
  []
  [fracDensity_AMR]
  []
[]

[AuxKernels]
  [normal_thermal_conductivity_auxk]
    type = ConstantAux
    variable = normal_thermal_conductivity
    value = 5
  []
  [element_normal_length_auxk]
    type = PorousFlowElementLength
    variable = element_normal_length
    direction = 'fracture_normal_x fracture_normal_y fracture_normal_z'
  []
[]

[MultiApps]
  [fracture_app]
    type = TransientMultiApp
    input_files = fracture.i
    execute_on = TIMESTEP_BEGIN
    sub_cycling = true
  []
[]

[Transfers]
  [normal_x_from_fracture]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = fracture_app
    source_variable = normal_dirn_x
    variable = fracture_normal_x
  []
  [normal_y_from_fracture]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = fracture_app
    source_variable = normal_dirn_y
    variable = fracture_normal_y
  []
  [normal_z_from_fracture]
    type = MultiAppNearestNodeTransfer
    direction = from_multiapp
    multi_app = fracture_app
    source_variable = normal_dirn_z
    variable = fracture_normal_z
  []
  [element_normal_length_to_fracture]
    type = MultiAppNearestNodeTransfer
    direction = to_multiapp
    multi_app = fracture_app
    source_variable = element_normal_length
    variable = enclosing_element_normal_length
  []
  [element_normal_thermal_cond_to_fracture]
    type = MultiAppNearestNodeTransfer
    direction = to_multiapp
    multi_app = fracture_app
    source_variable = normal_thermal_conductivity
    variable = enclosing_element_normal_thermal_cond
  []
  [T_to_fracture]
    type = MultiAppInterpolationTransfer
    direction = to_multiapp
    multi_app = fracture_app
    source_variable = matrix_T
    variable = transferred_matrix_T
  []
  [heat_from_fracture]
    type = MultiAppReporterTransfer
    direction = from_multiapp
    multi_app = fracture_app
    from_reporters = 'heat_transfer_rate/joules_per_s heat_transfer_rate/x heat_transfer_rate/y heat_transfer_rate/z'
    to_reporters = 'heat_transfer_rate/transferred_joules_per_s heat_transfer_rate/x heat_transfer_rate/y heat_transfer_rate/z'
  []
[]

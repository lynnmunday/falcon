[Mesh]
  uniform_refine = 5
  [generate]
    type = GeneratedMeshGenerator
    dim = 2
    nx = 20
    xmin = -40
    xmax = 40
    ny = 20
    ymin = -40
    ymax = 40
  []
  [rotate]
    type = TransformGenerator
    input = generate
    transform = ROTATE
    vector_value = '0 10 0'
  []
  [offset]
    type = TransformGenerator
    input = rotate
    transform = TRANSLATE
    vector_value = '0 0 1.1'
  []
[]

[Problem]
  kernel_coverage_check = false
  solve = false
[]

[GlobalParams]
  PorousFlowDictator = dictator
  gravity = '0 0 -9.81'
[]

[Variables]
  [frac_P]
  []
  [frac_T]
  []
[]

[ICs]
  [frac_P]
    type = FunctionIC
    variable = frac_P
    function = insitu_pp
  []
  [frac_T]
    type = FunctionIC
    variable = frac_T
    function = insitu_T
  []
[]

[PorousFlowFullySaturated]
  coupling_type = ThermoHydro
  porepressure = frac_P
  temperature = frac_T
  fp = simple_fluid
  pressure_unit = Pa
[]

[Kernels]
  [toMatrix]
    type = PorousFlowHeatMassTransfer
    variable = frac_T
    v = transferred_matrix_T
    transfer_coefficient = heat_transfer_coefficient
    save_in = joules_per_s
  []
[]

[AuxVariables]
  [transferred_matrix_T]
    initial_condition = 363
  []
  [heat_transfer_coefficient]
    family = MONOMIAL
    order = CONSTANT
    initial_condition = 0.0
  []
  [joules_per_s]
  []
  [aperture]
    family = MONOMIAL
    order = CONSTANT
  []
  [perm_times_app]
    family = MONOMIAL
    order = CONSTANT
  []
  [density]
    family = MONOMIAL
    order = CONSTANT
  []
  [viscosity]
    family = MONOMIAL
    order = CONSTANT
  []
  [insitu_pp]
  []
  [normal_dirn_x]
    family = MONOMIAL
    order = CONSTANT
  []
  [normal_dirn_y]
    family = MONOMIAL
    order = CONSTANT
  []
  [normal_dirn_z]
    family = MONOMIAL
    order = CONSTANT
  []
  [enclosing_element_normal_length]
    family = MONOMIAL
    order = CONSTANT
  []
  [enclosing_element_normal_thermal_cond]
    family = MONOMIAL
    order = CONSTANT
  []
[]

[AuxKernels]
  [normal_dirn_x_auxk]
    type = PorousFlowElementNormal
    variable = normal_dirn_x
    component = x
  []
  [normal_dirn_y]
    type = PorousFlowElementNormal
    variable = normal_dirn_y
    component = y
  []
  [normal_dirn_z]
    type = PorousFlowElementNormal
    variable = normal_dirn_z
    component = z
  []
  [heat_transfer_coefficient_auxk]
    type = ParsedAux
    variable = heat_transfer_coefficient
    args = 'enclosing_element_normal_length enclosing_element_normal_thermal_cond'
    constant_names = h_s
    constant_expressions = 1E3 #This is the value being assigned to h_s.   Should be much bigger than thermal_conductivity / L ~ 1
    function = 'if(enclosing_element_normal_length = 0, 0, h_s * enclosing_element_normal_thermal_cond * 2 * enclosing_element_normal_length / (h_s * enclosing_element_normal_length * enclosing_element_normal_length + enclosing_element_normal_thermal_cond * 2 * enclosing_element_normal_length))'
  []
  [insitu_pp]
    type = FunctionAux
    execute_on = initial
    variable = insitu_pp
    function = insitu_pp
  []
  [aperture]
    type = PorousFlowPropertyAux
    variable = aperture
    property = porosity
  []
  [perm_times_app]
    type = PorousFlowPropertyAux
    variable = perm_times_app
    property = permeability
    row = 0
    column = 0
  []
  [density]
    type = PorousFlowPropertyAux
    variable = density
    property = density
    phase = 0
  []
  [viscosity]
    type = PorousFlowPropertyAux
    variable = viscosity
    property = viscosity
    phase = 0
  []
[]

[BCs]
  [inject_heat]
    type = DirichletBC
    boundary = left
    variable = frac_T
    value = 303
  []
[]

[DiracKernels]
  [inject_fluid]
    type = PorousFlowPointSourceFromPostprocessor
    mass_flux = 0.1
    point = '0.1 -50 0'
    variable = frac_P
  []
[]

[Modules]
  [FluidProperties]
    [simple_fluid]
      type = SimpleFluidProperties
      bulk_modulus = 8
      density0 = 1
      thermal_expansion = 0
      viscosity = 1
    []
  []
[]

[Materials]
  [porosity]
    type = PorousFlowPorosityLinear
    porosity_ref = 1E-4
    P_ref = insitu_pp
    P_coeff = 3e-10
    porosity_min = 1E-5
  []
  [permeability]
    type = PorousFlowPermeabilityKozenyCarman
    k0 = 1E-15
    poroperm_function = kozeny_carman_phi0
    m = 0
    n = 3
    phi0 = 1E-4
  []
  [internal_energy]
    type = PorousFlowMatrixInternalEnergy
    density = 2700
    specific_heat_capacity = 0
  []
  [aq_thermal_conductivity]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '0.6E-4 0 0  0 0.6E-4 0  0 0 0.6E-4'
  []
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

[Postprocessors]
  [total]
    type = MemoryUsage
    mem_units = 'bytes'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [per_proc]
    type = MemoryUsage
    value_type = "average"
    mem_units = 'bytes'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [max_proc]
    type = MemoryUsage
    value_type = "max_process"
    mem_units = 'bytes'
    execute_on = 'INITIAL TIMESTEP_END'
  []
  [nelems]
    type = NumElems
  []
[]

[VectorPostprocessors]
  [heat_transfer_rate]
    type = NodalValueSampler
    outputs = none
    sort_by = id
    variable = joules_per_s
  []
[]

[Reporters]
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

[Executioner]
  type = Transient
  dt = 1
  num_steps = 10
[]

[Outputs]
  csv = true
  json = true
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

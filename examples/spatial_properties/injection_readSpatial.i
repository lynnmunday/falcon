# Units K,m,Pa,Kg,s
# Cold water injection into one side of the fracture network, and production from the other side
injection_rate_zn1 = 6 # kg/s
injection_rate_zn2 = 4 # kg/s
injection_rate_zn3 = 6 # kg/s
injection_temp = 323
endTime = 2e5 #86400 # 24 hours
dt_max = 5000 #500

#These are the injections points used to create the fractures in make_zone_frac_meshes.i
#zone 1:
p1inx = 4.080888831e+02
p1iny = 2.584756670e+02
p1inz = 2.098508678e+02

#zone 2:
p2inx = 3.101174933e+02
p2iny = 2.501984880e+02
p2inz = 2.518588363e+02

#zone 3:
p3inx = 208 # 2.020881906e+02 # shifted to create straight homogenized fracture
p3iny = 2.410715595e+02
p3inz = 2.981794157e+02

# z-offset of production from injection point
offset = 100

#--------- mesh and read in data -------------
[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = 'readSpatialProps_final.e'
    use_for_exodus_restart = true
  []
[]
[AuxVariables]
  [permeability]
    order = CONSTANT
    family = MONOMIAL
    initial_from_file_var = permeability
    initial_from_file_timestep = 'LATEST'
  []
[]

#----------------------------------------

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

[AuxVariables]
  [Pdiff]
  []
  [Tdiff]
  []
  [density]
    order = CONSTANT
    family = MONOMIAL
  []
  [viscosity]
    order = CONSTANT
    family = MONOMIAL
  []
[]

[AuxKernels]
  [Pdiff]
    type = ParsedAux
    use_xyzt = true
    variable = Pdiff
    coupled_variables = 'frac_P'
    expression = 'frac_P-(1.6025e7-8500*(z-1150))'
    execute_on = TIMESTEP_END
  []
  [Tdiff]
    type = ParsedAux
    use_xyzt = true
    variable = Tdiff
    coupled_variables = 'frac_T'
    expression = 'frac_T-(426.67-0.0733333*(z-1150))'
    execute_on = TIMESTEP_END
  []
  [density]
    type = MaterialRealAux
    variable = density
    property = PorousFlow_fluid_phase_density_qp0
    execute_on = TIMESTEP_END
  []
  [viscosity]
    type = MaterialRealAux
    variable = viscosity
    property = PorousFlow_viscosity_qp0
    execute_on = TIMESTEP_END
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
  fp = true_water #the_simple_fluid
  pressure_unit = Pa
  stabilization = full
  #gravity = '0 0 -9.81'
[]

[FluidProperties]
  [the_simple_fluid]
    type = SimpleFluidProperties
    bulk_modulus = 2E9
    viscosity = 1.0E-3
    density0 = 1000.0
  []

  [true_water]
    type = Water97FluidProperties
  []

  [tabulated_water]
    type = TabulatedBicubicFluidProperties
    fp = true_water
    fluid_property_file = tabulated_fluid_properties_v2.csv
  []
[]

[Reporters]
  [inj_zn1]
    type = ConstantReporter
    real_vector_names = 'pt_x pt_y pt_z'
    real_vector_values = '${p1inx}; ${p1iny}; ${p1inz}'
    outputs = none
  []
  [inj_zn2]
    type = ConstantReporter
    real_vector_names = 'pt_x pt_y pt_z'
    real_vector_values = '${p2inx}; ${p2iny}; ${p2inz}'
    outputs = none
  []
  [inj_zn3]
    type = ConstantReporter
    real_vector_names = 'pt_x pt_y pt_z'
    real_vector_values = '${p3inx}; ${p3iny}; ${p3inz}'
    outputs = none
  []
  [prod_zn1]
    type = ConstantReporter
    real_vector_names = 'w pt_x pt_y pt_z'
    real_vector_values = '0.1; ${p1inx}; ${p1iny}; ${fparse p1inz+offset}'
    outputs = none
  []
  [prod_zn2]
    type = ConstantReporter
    real_vector_names = 'w pt_x pt_y pt_z'
    real_vector_values = '0.1; ${p2inx}; ${p2iny}; ${fparse p2inz+offset}'
    outputs = none
  []
  [prod_zn3]
    type = ConstantReporter
    real_vector_names = 'w pt_x pt_y pt_z'
    real_vector_values = '0.1; ${p3inx}; ${p3iny}; ${fparse p3inz+offset}'
    outputs = none
  []
[]

[DiracKernels]
  [inject_fluid_mass_zn1]
    type = PorousFlowReporterPointSourcePP
    mass_flux = mass_flux_src_zn1
    variable = frac_P
    x_coord_reporter = 'inj_zn1/pt_x'
    y_coord_reporter = 'inj_zn1/pt_y'
    z_coord_reporter = 'inj_zn1/pt_z'
  []
  [inject_fluid_h_zn1]
    type = PorousFlowReporterPointEnthalpySourcePP
    variable = frac_T
    mass_flux = mass_flux_src_zn1
    T_in = 'inject_T'
    pressure = frac_P
    fp = true_water
    x_coord_reporter = 'inj_zn1/pt_x'
    y_coord_reporter = 'inj_zn1/pt_y'
    z_coord_reporter = 'inj_zn1/pt_z'
  []
  [inject_fluid_mass_zn2]
    type = PorousFlowReporterPointSourcePP
    mass_flux = mass_flux_src_zn2
    variable = frac_P
    x_coord_reporter = 'inj_zn2/pt_x'
    y_coord_reporter = 'inj_zn2/pt_y'
    z_coord_reporter = 'inj_zn2/pt_z'
  []
  [inject_fluid_h_zn2]
    type = PorousFlowReporterPointEnthalpySourcePP
    variable = frac_T
    mass_flux = mass_flux_src_zn2
    T_in = 'inject_T'
    pressure = frac_P
    fp = true_water
    x_coord_reporter = 'inj_zn2/pt_x'
    y_coord_reporter = 'inj_zn2/pt_y'
    z_coord_reporter = 'inj_zn2/pt_z'
  []
  [inject_fluid_mass_zn3]
    type = PorousFlowReporterPointSourcePP
    mass_flux = mass_flux_src_zn3
    variable = frac_P
    x_coord_reporter = 'inj_zn3/pt_x'
    y_coord_reporter = 'inj_zn3/pt_y'
    z_coord_reporter = 'inj_zn3/pt_z'
  []
  [inject_fluid_h_zn3]
    type = PorousFlowReporterPointEnthalpySourcePP
    variable = frac_T
    mass_flux = mass_flux_src_zn3
    T_in = 'inject_T'
    pressure = frac_P
    fp = true_water
    x_coord_reporter = 'inj_zn3/pt_x'
    y_coord_reporter = 'inj_zn3/pt_y'
    z_coord_reporter = 'inj_zn3/pt_z'
  []

  [withdraw_fluid_zn1]
    type = PorousFlowPeacemanBorehole
    SumQuantityUO = kg_out_uo_zn1
    bottom_p_or_t = insitu_pp
    weight_reporter = 'prod_zn1/w'
    x_coord_reporter = 'prod_zn1/pt_x'
    y_coord_reporter = 'prod_zn1/pt_y'
    z_coord_reporter = 'prod_zn1/pt_z'
    line_length = 1 # what should this be?
    unit_weight = '0 0 -0.85e4'
    fluid_phase = 0
    use_mobility = true
    variable = frac_P
    character = 1
    # block = '1 2 3'
  []
  [withdraw_heat_zn1]
    type = PorousFlowPeacemanBorehole
    SumQuantityUO = J_out_uo_zn1
    bottom_p_or_t = insitu_pp
    weight_reporter = 'prod_zn1/w'
    x_coord_reporter = 'prod_zn1/pt_x'
    y_coord_reporter = 'prod_zn1/pt_y'
    z_coord_reporter = 'prod_zn1/pt_z'
    line_length = 1 # what should this be?
    unit_weight = '0 0 -0.85e4'
    fluid_phase = 0
    use_mobility = true
    use_enthalpy = true
    variable = frac_T
    character = 1
    # block = '1 2 3'
  []
  [withdraw_fluid_zn2]
    type = PorousFlowPeacemanBorehole
    SumQuantityUO = kg_out_uo_zn2
    bottom_p_or_t = insitu_pp_borehole
    weight_reporter = 'prod_zn2/w'
    x_coord_reporter = 'prod_zn2/pt_x'
    y_coord_reporter = 'prod_zn2/pt_y'
    z_coord_reporter = 'prod_zn2/pt_z'
    line_length = 1 # what should this be?
    unit_weight = '0 0 -0.85e4'
    fluid_phase = 0
    use_mobility = true
    variable = frac_P
    character = 1
    block = '1 2 3'
  []
  [withdraw_heat_zn2]
    type = PorousFlowPeacemanBorehole
    SumQuantityUO = J_out_uo_zn2
    bottom_p_or_t = insitu_pp_borehole
    weight_reporter = 'prod_zn2/w'
    x_coord_reporter = 'prod_zn2/pt_x'
    y_coord_reporter = 'prod_zn2/pt_y'
    z_coord_reporter = 'prod_zn2/pt_z'
    line_length = 1 # what should this be?
    unit_weight = '0 0 -0.85e4'
    fluid_phase = 0
    use_mobility = true
    use_enthalpy = true
    variable = frac_T
    character = 1
    block = '1 2 3'
  []
  [withdraw_fluid_zn3]
    type = PorousFlowPeacemanBorehole
    SumQuantityUO = kg_out_uo_zn3
    bottom_p_or_t = insitu_pp_borehole
    weight_reporter = 'prod_zn3/w'
    x_coord_reporter = 'prod_zn3/pt_x'
    y_coord_reporter = 'prod_zn3/pt_y'
    z_coord_reporter = 'prod_zn3/pt_z'
    line_length = 1 # what should this be?
    unit_weight = '0 0 -0.85e4'
    fluid_phase = 0
    use_mobility = true
    variable = frac_P
    character = 1
    # block = '1 2 3'
  []
  [withdraw_heat_zn3]
    type = PorousFlowPeacemanBorehole
    SumQuantityUO = J_out_uo_zn3
    bottom_p_or_t = insitu_pp_borehole
    weight_reporter = 'prod_zn3/w'
    x_coord_reporter = 'prod_zn3/pt_x'
    y_coord_reporter = 'prod_zn3/pt_y'
    z_coord_reporter = 'prod_zn3/pt_z'
    line_length = 1 # what should this be?
    unit_weight = '0 0 -0.85e4'
    fluid_phase = 0
    use_mobility = true
    use_enthalpy = true
    variable = frac_T
    character = 1
    block = '1 2 3'
  []
[]

[UserObjects]
  [kg_out_uo_zn1]
    type = PorousFlowSumQuantity
  []
  [J_out_uo_zn1]
    type = PorousFlowSumQuantity
  []
  [kg_out_uo_zn2]
    type = PorousFlowSumQuantity
  []
  [J_out_uo_zn2]
    type = PorousFlowSumQuantity
  []
  [kg_out_uo_zn3]
    type = PorousFlowSumQuantity
  []
  [J_out_uo_zn3]
    type = PorousFlowSumQuantity
  []
[]

[Materials]
  [porosity_frac]
    type = PorousFlowPorosity
    porosity_zero = 0.9
    block = '1 2 3'
  []
  [permeability_frac]
    type = PorousFlowPermeabilityConstFromVar
    perm_xx = permeability
    perm_yy = permeability
    perm_zz = permeability
    block = '1 2 3'
  []
  [internal_energy_frac]
    type = PorousFlowMatrixInternalEnergy
    density = 2700
    specific_heat_capacity = 0
    block = '1 2 3'
  []
  [aq_thermal_conductivity_frac]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '0.6E-4 0 0  0 0.6E-4 0  0 0 0.6E-4'
    block = '1 2 3'
  []

  [permeability_matrix]
    type = PorousFlowPermeabilityConstFromVar
    perm_xx = permeability
    perm_yy = permeability
    perm_zz = permeability
    block = '0'
  []
  [porosity_matrix]
    type = PorousFlowPorosity
    porosity_zero = 0.001
    block = 0
  []
  [internal_energy_matrix]
    type = PorousFlowMatrixInternalEnergy
    density = 2750
    specific_heat_capacity = 790
    block = 0
  []
  [aq_thermal_conductivity_matrix]
    type = PorousFlowThermalConductivityIdeal
    dry_thermal_conductivity = '3.05 0 0  0 3.05 0  0 0 3.05'
    block = 0
  []
[]

[Functions]
  # NOTE: because this is used in BCs, it should be reasonably physically correct,
  # otherwise the BCs will be withdrawing or injecting heat-energy inappropriately
  [insitu_T]
    type = ParsedFunction
    expression = '426.67-0.0733333*(z-1150)'
  []
  [insitu_pp]
    type = ParsedFunction
    expression = '1.6025e7-8500*(z-1150)' # NOTE: because this is used in BCs, it should be reasonably physically correct, otherwise the BCs will be withdrawing or injecting water inappropriately.  Note also that the 8500 should be the unit_weight in the PeacemanBoreholes
  []
  [insitu_pp_borehole]
    type = ParsedFunction
    expression = '1.6025e7-8500*(z-1150)+1e6' # NOTE, Lynn used + 1e6, but i want to be more agressive
  []
  [mass_flux_in_zn1]
    type = PiecewiseLinear
    xy_data = '
    0    0.0
    50000 ${injection_rate_zn1}'
  []
  [mass_flux_in_zn2]
    type = PiecewiseLinear
    xy_data = '
    0    0.0
    50000 ${injection_rate_zn2}'
  []
  [mass_flux_in_zn3]
    type = PiecewiseLinear
    xy_data = '
    0    0.0
    50000 ${injection_rate_zn3}'
  []
  # [kg_rate_zn1]
  #   type = ParsedFunction
  #   symbol_names = 'a1_dt kg_out_zn1'
  #   symbol_values = 'a1_dt kg_out_zn1'
  #   expression = 'kg_out_zn1/a1_dt'
  # []
  # [kg_rate_zn2]
  #   type = ParsedFunction
  #   symbol_names = 'a1_dt kg_out_zn2'
  #   symbol_values = 'a1_dt kg_out_zn2'
  #   expression = 'kg_out_zn2/a1_dt'
  # []
  # [kg_rate_zn3]
  #   type = ParsedFunction
  #   symbol_names = 'a1_dt kg_out_zn3'
  #   symbol_values = 'a1_dt kg_out_zn3'
  #   expression = 'kg_out_zn3/a1_dt'
  # []
[]

[Postprocessors]
  [mass_flux_src_zn1]
    type = FunctionValuePostprocessor
    function = mass_flux_in_zn1
    execute_on = 'initial timestep_end'
  []
  [mass_flux_src_zn2]
    type = FunctionValuePostprocessor
    function = mass_flux_in_zn2
    execute_on = 'initial timestep_end'
  []
  [mass_flux_src_zn3]
    type = FunctionValuePostprocessor
    function = mass_flux_in_zn3
    execute_on = 'initial timestep_end'
  []

  [kg_out_zn1]
    type = PorousFlowPlotQuantity
    uo = kg_out_uo_zn1
  []
  [j_out_zn1]
    type = PorousFlowPlotQuantity
    uo = J_out_uo_zn1
  []
  [kg_out_zn2]
    type = PorousFlowPlotQuantity
    uo = kg_out_uo_zn2
  []
  [j_out_zn2]
    type = PorousFlowPlotQuantity
    uo = J_out_uo_zn2
  []
  [kg_out_zn3]
    type = PorousFlowPlotQuantity
    uo = kg_out_uo_zn3
  []
  [j_out_zn3]
    type = PorousFlowPlotQuantity
    uo = J_out_uo_zn3
  []
  # [kg_per_s_zn1]
  #   type = FunctionValuePostprocessor
  #   function = kg_rate_zn1
  #   execute_on = TIMESTEP_END
  # []
  # [kg_per_s_zn2]
  #   type = FunctionValuePostprocessor
  #   function = kg_rate_zn2
  #   execute_on = TIMESTEP_END
  # []
  # [kg_per_s_zn3]
  #   type = FunctionValuePostprocessor
  #   function = kg_rate_zn3
  #   execute_on = TIMESTEP_END
  # []

  [p1_in]
    type = PointValue
    point = '${p1inx} ${p1iny} ${p1inz}'
    variable = frac_P
  []
  [p2_in]
    type = PointValue
    point = '${p2inx} ${p2iny} ${p2inz}'
    variable = frac_P
  []

  [p1_out]
    type = PointValue
    point = '${p1inx} ${p1iny} ${fparse p1inz+offset}'
    variable = frac_P
  []
  [p2_out]
    type = PointValue
    point = '${p2inx} ${p2iny} ${fparse p2inz+offset}'
    variable = frac_P
  []
  [p3_out]
    type = PointValue
    point = '${p3inx} ${p3iny} ${fparse p3inz+offset}'
    variable = frac_P
  []
  [t1_out]
    type = PointValue
    point = '${p1inx} ${p1iny} ${fparse p1inz+offset}'
    variable = frac_T
  []
  [t2_out]
    type = PointValue
    point = '${p2inx} ${p2iny} ${fparse p2inz+offset}'
    variable = frac_T
  []
  [t3_out]
    type = PointValue
    point = '${p3inx} ${p3iny} ${fparse p3inz+offset}'
    variable = frac_T
  []
  ### this output named to be written first
  [a1_nl_its]
    type = NumNonlinearIterations
  []
  [a1_l_its]
    type = NumLinearIterations
  []
  [a1_dt]
    type = TimestepSize
  []
  [a0_wall_time]
    type = PerfGraphData
    section_name = "Root"
    data_type = total
  []

  [inject_T]
    type = Receiver
    default = ${injection_temp}
    outputs = none
  []
[]

[Preconditioning]
  active = hypre # NOTE - perhaps ilu is going to be necessary in the full problem?
  # NOTE: the following is how i would use hypre - probably worth an experiment on the full problem
  [hypre]
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-pc_type -pc_hypre_type'
    petsc_options_value = ' hypre    boomeramg'
  []
  [asm_ilu] #uses less memory
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-ksp_type -ksp_grmres_restart -pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = 'gmres 30 asm ilu NONZERO 2'
  []
  [asm_lu] #uses less memory
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-ksp_type -ksp_grmres_restart -pc_type -sub_pc_type -sub_pc_factor_shift_type -pc_asm_overlap'
    petsc_options_value = 'gmres 30 asm lu NONZERO 2'
  []
  [superlu]
    type = SMP
    full = true
    petsc_options = '-ksp_diagonal_scale -ksp_diagonal_scale_fix'
    petsc_options_iname = '-ksp_type -pc_type -pc_factor_mat_solver_package'
    petsc_options_value = 'gmres lu superlu_dist'
  []
  [preferred]
    type = SMP
    full = true
    petsc_options_iname = '-pc_type -pc_factor_mat_solver_package'
    petsc_options_value = ' lu       mumps'
  []
[]
[Executioner]
  type = Transient
  solve_type = NEWTON
  end_time = ${endTime}
  dtmin = 1
  dtmax = ${dt_max}
  l_tol = 1e-4
  l_max_its = 300
  nl_max_its = 50
  nl_abs_tol = 1e-4
  nl_rel_tol = 1e-5
  automatic_scaling = true
  off_diagonals_in_auto_scaling = true
  compute_scaling_once = true
  line_search = none
  [TimeStepper]
    type = IterationAdaptiveDT
    optimal_iterations = 25
    iteration_window = 10
    growth_factor = 1.2
    cutback_factor = 0.9
    cutback_factor_at_failure = 0.5
    linear_iteration_ratio = 300
    dt = 1
  []
[]

[Outputs]
  csv = true
  exodus = true
[]

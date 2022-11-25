################################################################################
# Clock constraints
################################################################################


create_clock -name pcie_refclk_p -period 10.0 [get_ports pcie_refclk_p]

################################################################################
# False path constraints
################################################################################


set_false_path -through [get_nets -hierarchical -filter {mr_ff == TRUE}]

set_false_path -to [get_pins -filter {REF_PIN_NAME == PRE} -of_objects [get_cells -hierarchical -filter {ars_ff1 == TRUE || ars_ff2 == TRUE}]]

set_max_delay -from [get_pins -filter {REF_PIN_NAME == C} -of_objects [get_cells -hierarchical -filter {ars_ff1 == TRUE}]] -to [get_pins -filter {REF_PIN_NAME == D} -of_objects [get_cells -hierarchical -filter {ars_ff2 == TRUE}]] 2.000

set_false_path -from inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/pclk_sel_reg/C -to inst0/inst1_litepcie_top/inst0_litepcie_core/pcie_support/pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1


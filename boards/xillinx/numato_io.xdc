
# Mimas A7 (Numato) Constraints
# FPGA: XC7A50T-FGG484-1


# Onboard 100 MHz oscillator
set_property PACKAGE_PIN E3 [get_ports {osc_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {osc_clk}]

# LEDs (active high)
set_property PACKAGE_PIN H17 [get_ports {LED_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_0}]

set_property PACKAGE_PIN K15 [get_ports {LED_1}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_1}]

set_property PACKAGE_PIN K17 [get_ports {LED_2}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_2}]

set_property PACKAGE_PIN J17 [get_ports {LED_3}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_3}]

set_property PACKAGE_PIN J18 [get_ports {LED_4}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_4}]

set_property PACKAGE_PIN T9 [get_ports {LED_5}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_5}]

set_property PACKAGE_PIN T10 [get_ports {LED_6}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_6}]

set_property PACKAGE_PIN U11 [get_ports {LED_7}]
set_property IOSTANDARD LVCMOS33 [get_ports {LED_7}]

# Pushbuttons (active low)
set_property PACKAGE_PIN M18 [get_ports {PB_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {PB_0}]

set_property PACKAGE_PIN P16 [get_ports {PB_1}]
set_property IOSTANDARD LVCMOS33 [get_ports {PB_1}]

set_property PACKAGE_PIN P20 [get_ports {PB_2}]
set_property IOSTANDARD LVCMOS33 [get_ports {PB_2}]

set_property PACKAGE_PIN P15 [get_ports {PB_3}]
set_property IOSTANDARD LVCMOS33 [get_ports {PB_3}]

# Slide Switches
set_property PACKAGE_PIN M19 [get_ports {SW_0}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW_0}]

set_property PACKAGE_PIN M20 [get_ports {SW_1}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW_1}]

set_property PACKAGE_PIN N20 [get_ports {SW_2}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW_2}]

set_property PACKAGE_PIN N19 [get_ports {SW_3}]
set_property IOSTANDARD LVCMOS33 [get_ports {SW_3}]

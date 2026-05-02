# Numato Mimas A7 - LED Blink Constraints
# Device: XC7A50T-1FGG484C (Artix-7 50T)

##############################################################################
## Clock Signal - 100MHz CMOS Oscillator
##############################################################################
set_property PACKAGE_PIN H4 [get_ports sys_clk]
set_property IOSTANDARD LVCMOS33 [get_ports sys_clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports sys_clk]

##############################################################################
## Reset Signal - Active Low
##############################################################################
set_property PACKAGE_PIN M2 [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]

##############################################################################
## UART (FT2232HL USB Bridge on Mimas A7 Board)
## Connected via GPIO header J21/K22
## J21 (FPGA pin) -> uart_rx (115200 baud, 8N1)
## K22 (FPGA pin) -> uart_tx
## Note: USB connection via FT2232HL enables UART bootloader for firmware upload
##############################################################################
set_property PACKAGE_PIN J21 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]
set_property PULLUP true [get_ports uart_rx]

set_property PACKAGE_PIN K22 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]
set_property SLEW FAST [get_ports uart_tx]

##############################################################################
## User LEDs (8x)
##############################################################################
set_property PACKAGE_PIN K17 [get_ports led[0]]
set_property IOSTANDARD LVCMOS33 [get_ports led[0]]
set_property SLEW FAST [get_ports led[0]]

set_property PACKAGE_PIN J17 [get_ports led[1]]
set_property IOSTANDARD LVCMOS33 [get_ports led[1]]
set_property SLEW FAST [get_ports led[1]]

set_property PACKAGE_PIN L14 [get_ports led[2]]
set_property IOSTANDARD LVCMOS33 [get_ports led[2]]
set_property SLEW FAST [get_ports led[2]]

set_property PACKAGE_PIN L15 [get_ports led[3]]
set_property IOSTANDARD LVCMOS33 [get_ports led[3]]
set_property SLEW FAST [get_ports led[3]]

set_property PACKAGE_PIN L16 [get_ports led[4]]
set_property IOSTANDARD LVCMOS33 [get_ports led[4]]
set_property SLEW FAST [get_ports led[4]]

set_property PACKAGE_PIN K16 [get_ports led[5]]
set_property IOSTANDARD LVCMOS33 [get_ports led[5]]
set_property SLEW FAST [get_ports led[5]]

set_property PACKAGE_PIN M15 [get_ports led[6]]
set_property IOSTANDARD LVCMOS33 [get_ports led[6]]
set_property SLEW FAST [get_ports led[6]]

set_property PACKAGE_PIN M16 [get_ports led[7]]
set_property IOSTANDARD LVCMOS33 [get_ports led[7]]
set_property SLEW FAST [get_ports led[7]]

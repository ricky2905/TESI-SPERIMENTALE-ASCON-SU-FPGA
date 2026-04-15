# External clock (input to PLL)
set_property PACKAGE_PIN <PIN_CLK_EXT> [get_ports clk_ext]
set_property IOSTANDARD LVCMOS33 [get_ports clk_ext]
create_clock -period 10.0 [get_ports clk_ext] -name clk_100MHz

# SPI pins 
set_property PACKAGE_PIN <PIN_SPI_MOSI>  [get_ports SPI_MOSI]
set_property IOSTANDARD LVCMOS33          [get_ports SPI_MOSI]

set_property PACKAGE_PIN <PIN_SPI_MISO>  [get_ports SPI_MISO]
set_property IOSTANDARD LVCMOS33          [get_ports SPI_MISO]

set_property PACKAGE_PIN <PIN_SPI_SCK>   [get_ports SPI_SCK]
set_property IOSTANDARD LVCMOS33          [get_ports SPI_SCK]

set_property PACKAGE_PIN <PIN_SPI_SSEL>    [get_ports SPI_SSEL]
set_property IOSTANDARD LVCMOS33           [get_ports SPI_SSEL]

# Reset
set_property PACKAGE_PIN <PIN_RST_N>     [get_ports rst_n]
set_property IOSTANDARD LVCMOS33         [get_ports rst_n]

# PUF control pins
set_property PACKAGE_PIN <PIN_PUF_ENABLE>   [get_ports PUF_ENABLE]
set_property IOSTANDARD LVCMOS33            [get_ports PUF_ENABLE]

# PUF_CHALLENGE[7:0]
set_property PACKAGE_PIN <PIN_PUF_CH0> [get_ports {PUF_CHALLENGE[0]}]
set_property PACKAGE_PIN <PIN_PUF_CH1> [get_ports {PUF_CHALLENGE[1]}]
set_property PACKAGE_PIN <PIN_PUF_CH2> [get_ports {PUF_CHALLENGE[2]}]
set_property PACKAGE_PIN <PIN_PUF_CH3> [get_ports {PUF_CHALLENGE[3]}]
set_property PACKAGE_PIN <PIN_PUF_CH4> [get_ports {PUF_CHALLENGE[4]}]
set_property PACKAGE_PIN <PIN_PUF_CH5> [get_ports {PUF_CHALLENGE[5]}]
set_property PACKAGE_PIN <PIN_PUF_CH6> [get_ports {PUF_CHALLENGE[6]}]
set_property PACKAGE_PIN <PIN_PUF_CH7> [get_ports {PUF_CHALLENGE[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PUF_CHALLENGE[*]}]

# LEDs
set_property PACKAGE_PIN <PIN_LED_BUSY>  [get_ports LED_BUSY]
set_property IOSTANDARD LVCMOS33         [get_ports LED_BUSY]

set_property PACKAGE_PIN <PIN_LED_DONE>  [get_ports LED_DONE]
set_property IOSTANDARD LVCMOS33         [get_ports LED_DONE]

set_property PACKAGE_PIN <PIN_LED_ERR>   [get_ports LED_ERROR]
set_property IOSTANDARD LVCMOS33         [get_ports LED_ERROR]
transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../ipstatic" "+incdir+../../../../ASCONTESISPERIMENTALE.gen/sources_1/ip/PLL_2" -l xpm -l xil_defaultlib \
"/tools/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"/tools/Xilinx/Vivado/2024.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work xil_defaultlib  -incr -v2k5 "+incdir+../../../ipstatic" "+incdir+../../../../ASCONTESISPERIMENTALE.gen/sources_1/ip/PLL_2" -l xpm -l xil_defaultlib \
"../../../../ASCONTESISPERIMENTALE.gen/sources_1/ip/PLL_2/PLL_clk_wiz.v" \
"../../../../ASCONTESISPERIMENTALE.gen/sources_1/ip/PLL_2/PLL.v" \

vlog -work xil_defaultlib \
"glbl.v"


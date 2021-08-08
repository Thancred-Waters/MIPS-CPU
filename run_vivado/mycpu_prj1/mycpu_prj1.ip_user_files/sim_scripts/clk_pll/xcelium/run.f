-makelib xcelium_lib/xpm -sv \
  "D:/Program_Files/vivado_2021_1/Vivado/2021.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "D:/Program_Files/vivado_2021_1/Vivado/2021.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/Program_Files/vivado_2021_1/Vivado/2021.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../../../rtl/xilinx_ip/clk_pll/clk_pll_clk_wiz.v" \
  "../../../../../../rtl/xilinx_ip/clk_pll/clk_pll.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib


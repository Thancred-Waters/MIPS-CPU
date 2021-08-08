-makelib xcelium_lib/xpm -sv \
  "D:/Program_Files/vivado_2021_1/Vivado/2021.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "D:/Program_Files/vivado_2021_1/Vivado/2021.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/Program_Files/vivado_2021_1/Vivado/2021.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/blk_mem_gen_v8_4_4 \
  "../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../../../rtl/xilinx_ip/data_ram/sim/data_ram.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib


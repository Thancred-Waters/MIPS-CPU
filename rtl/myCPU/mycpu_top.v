`include "mycpu.h"

module mycpu_top(
    input         clk,
    input         resetn,
    // inst sram interface
    output        inst_sram_en,
    output [ 3:0] inst_sram_wen,
    output [31:0] inst_sram_addr,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    // data sram interface
    output        data_sram_en,
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

wire         ds_allowin;
wire         es_allowin;
wire         ms_allowin;
wire         ws_allowin;
wire         fs_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_ms_valid;
wire         ms_to_ws_valid;
wire [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus;
wire [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus;
wire [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus;
wire [`BR_BUS_WD         :0] br_bus;//br_taken: 1 bit + br_target: 32 bit = 33 bit

wire stallD;
wire stallF;
wire [1:0] forward_rs;
wire [1:0] forward_rt;
wire ds_use_rs;
wire [4:0] rs_addr;
wire ds_use_rt;
wire [4:0] rt_addr;
wire       es_write_reg;
wire [4:0] es_reg_dest;
wire       ms_write_reg;
wire [4:0] ms_reg_dest;
wire       ws_write_reg;
wire [4:0] ws_reg_dest;
wire [31:0] ms_to_ds_bus;
wire es_read_mem;
wire [31:0] es_to_ds_bus;

// IF stage
if_stage if_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    .stallF         (stallF         ),
    //allowin
    .ds_allowin     (ds_allowin     ),
    //brbus
    .br_bus         (br_bus         ),
    //outputs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    // inst sram interface
    .inst_sram_en   (inst_sram_en   ),
    .inst_sram_wen  (inst_sram_wen  ),
    .inst_sram_addr (inst_sram_addr ),
    .inst_sram_wdata(inst_sram_wdata),
    .inst_sram_rdata(inst_sram_rdata)
);
// ID stage
id_stage id_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //stall
    .stallD         (stallD         ),
    .ds_use_rs      (ds_use_rs      ),
    .rs_addr        (rs_addr        ),
    .ds_use_rt      (ds_use_rt      ),
    .rt_addr        (rt_addr        ),
    //forward
    .forward_rs     (forward_rs     ),
    .forward_rt     (forward_rt     ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //from fs
    .fs_to_ds_valid (fs_to_ds_valid ),
    .fs_to_ds_bus   (fs_to_ds_bus   ),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to fs
    .br_bus         (br_bus         ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //from ms
    .ms_to_ds_bus   (ms_to_ds_bus   ),
    //from ds
    .es_to_ds_bus   (es_to_ds_bus   )
);
// EXE stage
exe_stage exe_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //stall
    .es_write_reg   (es_write_reg   ),
    .es_reg_dest    (es_reg_dest    ),
    //forward
    .es_read_mem    (es_read_mem    ),
    .es_to_ds_bus   (es_to_ds_bus   ),
    //allowin
    .ms_allowin     (ms_allowin     ),
    .es_allowin     (es_allowin     ),
    //from ds
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to ms
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    // data sram interface
    .data_sram_en   (data_sram_en   ),
    .data_sram_wen  (data_sram_wen  ),
    .data_sram_addr (data_sram_addr ),
    .data_sram_wdata(data_sram_wdata)
);
// MEM stage
mem_stage mem_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //stall
    .ms_write_reg   (ms_write_reg   ),
    .ms_reg_dest    (ms_reg_dest    ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .ms_allowin     (ms_allowin     ),
    //from es
    .es_to_ms_valid (es_to_ms_valid ),
    .es_to_ms_bus   (es_to_ms_bus   ),
    //to ws
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //from data-sram
    .data_sram_rdata(data_sram_rdata),
    //to ds
    .ms_to_ds_bus   (ms_to_ds_bus   )
);
// WB stage
wb_stage wb_stage(
    .clk            (clk            ),
    .reset          (reset          ),
    //stall
    .ws_write_reg   (ws_write_reg   ),
    .ws_reg_dest    (ws_reg_dest    ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    //from ms
    .ms_to_ws_valid (ms_to_ws_valid ),
    .ms_to_ws_bus   (ms_to_ws_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   (ws_to_rf_bus   ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
);

hazard hazard(
    .ds_use_rs(ds_use_rs),
    .rs_addr(rs_addr),
    .ds_use_rt(ds_use_rt),
    .rt_addr(rt_addr),
    .es_write_reg(es_write_reg),
    .es_reg_dest(es_reg_dest),
    .es_read_mem(es_read_mem),
    .ms_write_reg(ms_write_reg),
    .ms_reg_dest(ms_reg_dest),
    .ws_write_reg(ws_write_reg),
    .ws_reg_dest(ws_reg_dest),
    //stall
    .stallD(stallD),
    .stallF(stallF),
    //forward
    .forward_rs(forward_rs),
    .forward_rt(forward_rt)
);
endmodule

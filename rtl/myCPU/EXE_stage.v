`include "mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //stall
    output                         es_write_reg  ,
    output [4:0]                   es_reg_dest   ,
    output                         alu_stall     ,
    output                         es_mfc0_stall ,
    input                          stallE        ,
    //forward
    output                         es_read_mem   ,//是否读内存
    output [31:0]                  es_to_ds_bus  ,//alu计算结果
    //allowin
    input                          ms_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    input  [4:0]                   ds_load_mem_bus ,
    input  [3:0]                   ds_save_mem_bus ,
    input  [`DS_EX_BUS_WD    -1:0] ds_ex_bus     ,
    //to ms
    output                         es_to_ms_valid,
    output [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    output [6:0]                   es_load_mem_bus ,
    output [`ES_EX_BUS_WD    -1:0] es_ex_bus     , 
    //from cp0
    input                          flush         ,     
    // exception
    output                         es_ex         ,
    input                          ms_ex         ,
    input                          ws_ex         ,                  
    // data sram interface
    output        data_sram_en   ,
    output [ 3:0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata
);

reg         es_valid      ;
wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
reg  [`DS_EX_BUS_WD    -1:0] ds_ex_bus_r;
reg  [4:0]  ds_load_mem_bus_r;
reg  [3:0]  ds_save_mem_bus_r;
wire [1:0]  save_width    ;
wire [1:0]  save_lr       ;
wire [3:0]  save_lwe      ;
wire [3:0]  save_rwe      ;
wire [3:0]  save_bwe      ;
wire [3:0]  save_hwe      ;
wire [3:0]  save_we       ;
wire [31:0] save_ldata    ;
wire [31:0] save_rdata    ;
wire [31:0] save_data     ;

wire [19:0] es_alu_op     ;
wire        es_load_op    ;
wire        es_src1_is_sa ;  
wire        es_src1_is_pc ;
wire        es_src2_is_imm; 
wire        es_src2_is_8  ;
wire        es_src2_zero_extend;
wire        es_gr_we      ;
wire        es_mem_we     ;
wire [ 4:0] es_dest       ;
wire [15:0] es_imm        ;
wire [31:0] es_rs_value   ;
wire [31:0] es_rt_value   ;
wire [31:0] es_pc         ;
assign {es_alu_op      ,  //144:125
        es_load_op     ,  //124:124
        es_src1_is_sa  ,  //123:123
        es_src1_is_pc  ,  //122:122
        es_src2_is_imm ,  //121:121
        es_src2_is_8   ,  //120:120
        es_src2_zero_extend,//119:119
        es_gr_we       ,  //118:118 寄存器堆写使能
        es_mem_we      ,  //117:117 DRAM写使能
        es_dest        ,  //116:112 目标寄存器
        es_imm         ,  //111:96
        es_rs_value    ,  //95 :64
        es_rt_value    ,  //63 :32
        es_pc             //31 :0
       } = ds_to_es_bus_r;

assign {save_width,save_lr} = ds_save_mem_bus_r;

//exception
wire       es_bd;
wire       es_sys;
wire       es_mtc0;
wire       es_eret;
wire [4:0] es_addr;
assign {es_bd   ,
        es_sys  ,
        es_mfc0 ,
        es_mtc0 ,
        es_eret ,
        es_addr
       } = ds_ex_bus_r; 
assign es_ex_bus = ds_ex_bus_r;
assign es_mfc0_stall = es_mfc0 && es_valid;
assign es_ex     = (es_sys | es_eret) & es_valid;

wire   ex_stop;
assign ex_stop = ms_ex | ws_ex;

//判断是否存在寄存器冲突
assign es_write_reg=es_gr_we && es_valid;
assign es_reg_dest=es_dest;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_result ;
wire [31:0] mem_addr      ;

wire es_res_from_mem;

assign es_res_from_mem = es_load_op;
assign es_to_ms_bus = {es_res_from_mem,  //70:70
                       es_gr_we       ,  //69:69
                       es_dest        ,  //68:64
                       es_alu_result  ,  //63:32
                       es_pc             //31:0
                      };

//数据前推组件
assign es_read_mem  = es_res_from_mem & es_valid;
assign es_to_ds_bus = es_alu_result;

assign es_ready_go    = ~stallE;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid =  es_valid && es_ready_go;
always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if (flush) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r    <= ds_to_es_bus;
        ds_ex_bus_r       <= ds_ex_bus;
        ds_load_mem_bus_r <= ds_load_mem_bus;
        ds_save_mem_bus_r <= ds_save_mem_bus;
    end
end

assign es_alu_src1 = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                     es_src1_is_pc  ? es_pc[31:0] :
                                      es_rs_value;
assign es_alu_src2 = es_src2_is_imm ? {{16{es_imm[15] & ~es_src2_zero_extend}}, es_imm[15:0]} : 
                     es_src2_is_8   ? 32'd8 :
                                      es_rt_value;

wire div_stall;
alu u_alu(
    .clk        (clk          ),
    .reset      (reset        ),
    .flush      (flush        ),
    .es_mtc0    (es_mtc0      ),
    .ex_stop    (ex_stop      ),
    .alu_op     (es_alu_op    ),
    .alu_src1   (es_alu_src1  ),
    .alu_src2   (es_alu_src2  ),
    .alu_result (es_alu_result),
    .mem_addr   (mem_addr     ),
    .div_stall  (div_stall    )
    );
assign alu_stall = (div_stall===1'b1) & es_valid;

assign es_load_mem_bus = {ds_load_mem_bus_r,mem_addr[1:0]};

assign save_bwe = mem_addr[1:0]==2'b00 ? 4'b0001 :
                  mem_addr[1:0]==2'b01 ? 4'b0010 :
                  mem_addr[1:0]==2'b10 ? 4'b0100 :
                  mem_addr[1:0]==2'b11 ? 4'b1000 : 4'b0000;
assign save_hwe = mem_addr[1] ? 4'b1100 : 4'b0011;
assign save_lwe = (
                    mem_addr[1:0]==2'b00 ? 4'b0001 :
                    mem_addr[1:0]==2'b01 ? 4'b0011 : 
                    mem_addr[1:0]==2'b10 ? 4'b0111 : 4'b1111
                  ) & {4{save_lr[1]}};
assign save_rwe = (
                    mem_addr[1:0]==2'b00 ? 4'b1111 :
                    mem_addr[1:0]==2'b01 ? 4'b1110 : 
                    mem_addr[1:0]==2'b10 ? 4'b1100 : 4'b1000
                  ) & {4{save_lr[0]}};                 
assign save_we  = {4{save_width==2'b11}} & 4'b1111
                | {4{save_width==2'b10}} & save_hwe
                | {4{save_width==2'b01}} & save_bwe
                | {4{save_width==2'b00}} & (save_lwe | save_rwe);
assign save_ldata = (
                     mem_addr[1:0]==2'b00 ? {24'b0,es_rt_value[31:24]}  :
                     mem_addr[1:0]==2'b01 ? {16'b0,es_rt_value[31:16]} :
                     mem_addr[1:0]==2'b10 ? {8'b0,es_rt_value[31:8]}  : es_rt_value
                    ) & {32{save_lr[1]}};
assign save_rdata = (
                     mem_addr[1:0]==2'b00 ? es_rt_value                :
                     mem_addr[1:0]==2'b01 ? {es_rt_value[23:0],8'b0}   :
                     mem_addr[1:0]==2'b10 ? {es_rt_value[15:0],16'b0}  : {es_rt_value[7:0],24'b0} 
                    ) & {32{save_lr[0]}};
assign save_data = {32{save_width==2'b11}} & es_rt_value
                 | {32{save_width==2'b10}} & {2{es_rt_value[15:0]}}
                 | {32{save_width==2'b01}} & {4{es_rt_value[7:0]}}
                 | {32{save_width==2'b00}} & {save_ldata | save_rdata};

assign data_sram_en    = 1'b1;
assign data_sram_wen   = es_mem_we && es_valid && ~ex_stop ? save_we : 4'h0;
assign data_sram_addr  = mem_addr;
assign data_sram_wdata = save_data;

endmodule

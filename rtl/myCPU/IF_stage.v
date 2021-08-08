`include "mycpu.h"

module if_stage(
    input                          clk            ,
    input                          reset          ,
    //stall
    input                          stallF         ,
    //allwoin
    input                          ds_allowin     ,
    //brbus
    input  [`BR_BUS_WD         :0] br_bus         ,
    //to ds
    output                         fs_to_ds_valid ,
    output [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus   ,
    // inst sram interface
    output        inst_sram_en   ,
    output [ 3:0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata
);

reg         fs_valid;
wire        fs_ready_go;
wire        fs_allowin;
wire        to_fs_valid;

wire [31:0] seq_pc;
wire [31:0] nextpc;

wire         br_taken;//是否选择将nextpc置为跳转地址
wire [ 31:0] br_target;//pc跳转目标
assign br_taken = br_bus[32];
assign br_target = br_bus[31:0];

wire [31:0] fs_inst;
reg  [31:0] fs_pc;
assign fs_to_ds_bus = {fs_inst ,
                       fs_pc   };

// pre-IF stage
assign to_fs_valid  = ~reset;
assign seq_pc       = fs_pc + 3'h4;//pc+4
assign nextpc       = br_taken===1'b1 ? br_target : seq_pc; 

// IF stage
assign fs_ready_go    = ~stallF;//stall信号，控制流水线暂停
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin;//接收使能信号，在无合法数据或者流水线正常运转时有效
assign fs_to_ds_valid =  fs_valid && fs_ready_go;//数据传递有效信号
always @(posedge clk) begin
    if (reset) begin//复位
        fs_valid <= 1'b0;
    end
    else if (fs_allowin) begin//可接受新数据
        fs_valid <= to_fs_valid;
    end

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  //trick: to make nextpc be 0xbfc00000 during reset 
    end
    else if (to_fs_valid && fs_allowin) begin//保证和valid信号同拍更新
        fs_pc <= nextpc;//pc的值在上升沿结束后才会更新，因此需要nextpc取指令
    end
end

assign inst_sram_en    = to_fs_valid && fs_allowin;
assign inst_sram_wen   = 4'h0;
assign inst_sram_addr  = nextpc;//利用nextpc获取指令，保证获取的指令与当前PC一致
assign inst_sram_wdata = 32'b0;

assign fs_inst         = inst_sram_rdata;

endmodule

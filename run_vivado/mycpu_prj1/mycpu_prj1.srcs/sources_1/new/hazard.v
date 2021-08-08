`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/07 21:19:01
// Design Name: 
// Module Name: hazard
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module hazard(
input ds_use_rs,
input [4:0] rs_addr,
input ds_use_rt,
input [4:0] rt_addr,
input       es_write_reg,
input [4:0] es_reg_dest,
input       ms_write_reg,
input [4:0] ms_reg_dest,
input       ws_write_reg,
input [4:0] ws_reg_dest,
output stallD,
output stallF
    );
    //data stall
    wire rs_stall,rt_stall;
    assign rs_stall=(ds_use_rs===1'b1 && rs_addr!==5'b0) &&
        ((es_write_reg===1'b1 && rs_addr===es_reg_dest) ||
        (ms_write_reg===1'b1 && rs_addr===ms_reg_dest) ||
        (ws_write_reg===1'b1 && rs_addr===ws_reg_dest)
        );
    assign rt_stall=(ds_use_rt===1'b1 && rt_addr!==5'b0) &&
        ((es_write_reg===1'b1 && rt_addr===es_reg_dest) ||
        (ms_write_reg===1'b1 && rt_addr===ms_reg_dest) ||
        (ws_write_reg===1'b1 && rt_addr===ws_reg_dest)
        );
    assign stallD=rs_stall | rt_stall;
    assign stallF=stallD;
endmodule

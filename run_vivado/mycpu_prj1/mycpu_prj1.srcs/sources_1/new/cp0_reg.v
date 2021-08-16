`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/08/15 16:18:50
// Design Name: 
// Module Name: cp0_reg
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

`include "CP0_DEFINES.vh"

module cp0_reg(
//input
input         clk,
input         reset,
input  [ 3:0] exception,
input  [ 4:0] c0_addr,
input  [31:0] c0_wdata,
input         wb_valid,
input         wb_bd,
input  [31:0] wb_pc,
//output
output        c0_valid,
output [31:0] c0_res,
output [31:0] eret_pc,
output        eret_flush,
output        ex_flush
    );
    wire       op_mtc0;
    wire       op_mfc0;
    wire       op_sys;
    wire       op_eret;
    wire       wb_ex;
    wire [4:0] wb_excode;

    assign {
        op_sys  ,
        op_mfc0 ,
        op_mtc0 ,
        op_eret
    } = exception;

    assign wb_ex = op_sys;
    assign wb_excode = {5{op_sys}} & `EX_SYS;

    //reg status
    reg         c0_status_bev;
    reg  [ 7:0] c0_status_im;
    reg         c0_status_exl;
    reg         c0_status_ie;
    wire [31:0] c0_status;

    assign c0_status = {
        9'b0          , //31..23
        c0_status_bev , //22
        6'b0          , //21..16  
        c0_status_im  , //15..8
        6'b0          , //7..2
        c0_status_exl , //1
        c0_status_ie    //0      
    };

    //bev
    always @(posedge clk) begin
        if(reset)
            c0_status_bev <= 1'b1; 
    end

    wire mtc0_we;
    assign mtc0_we = wb_valid && op_mtc0 && !wb_ex;

    //im
    always @(posedge clk) begin
        if(mtc0_we && c0_addr==`CR_STATUS)
            c0_status_im <= c0_wdata[15:8]; 
    end
    assign eret_flush = op_eret && wb_valid;

    //exl
    always @(posedge clk) begin
        if(reset)
            c0_status_exl <= 1'b0;
        else if(wb_ex)
            c0_status_exl <= 1'b1;
        else if(eret_flush)
            c0_status_exl <= 1'b0;
        else if(mtc0_we && c0_addr==`CR_STATUS)
            c0_status_exl <= c0_wdata[1];
    end

    //ie
    always @(posedge clk) begin
        if(reset)
            c0_status_ie <= 1'b0;
        else if(mtc0_we && c0_addr==`CR_STATUS)
            c0_status_ie <= c0_wdata[0];
    end

    //reg count
    reg        tick;
    reg [31:0] c0_count;
    always @(posedge clk) begin
        if(reset) tick <= 1'b0;
        else      tick <= ~tick;

        if(reset)
            c0_count <= 32'b0;
        else if(mtc0_we && c0_addr==`CR_COUNT)
            c0_count <= c0_wdata;
        else if(tick)
            c0_count <= c0_count + 1'b1;
    end

    //reg compare
    reg [31:0] c0_compare;
    always @(posedge clk) begin
        if(mtc0_we && c0_addr==`CR_COMPARE)
            c0_compare <= c0_wdata; 
    end 

    //reg cause
    reg         c0_cause_bd;
    reg         c0_cause_ti;
    reg  [ 7:0] c0_cause_ip;
    reg  [ 4:0] c0_cause_excode;
    wire [31:0] c0_cause;

    assign c0_cause = {
        c0_cause_bd     ,
        c0_cause_ti     ,
        14'b0           ,
        c0_cause_ip     ,
        1'b0            ,
        c0_cause_excode ,
        2'b0
    };

    //bd
    always @(posedge clk) begin
        if(reset)
            c0_cause_bd <= 1'b0;
        else if(wb_ex && !c0_status_exl)
            c0_cause_bd <= wb_bd; 
    end

    //ti
    wire count_eq_compare;
    assign count_eq_compare = c0_count == c0_compare;
    always @(posedge clk) begin
        if(reset)
            c0_cause_ti <= 1'b0;
        else if(mtc0_we && c0_addr==`CR_COMPARE)
            c0_cause_ti <= 1'b0;
        else if(count_eq_compare)
            c0_cause_ti <= 1'b1; 
    end

    //ip
    always @(posedge clk) begin
        if(reset)
            c0_cause_ip[7:2] <= 6'b0;
        else begin
            c0_cause_ip[7]   <= c0_cause_ti;
            c0_cause_ip[6:2] <= 5'b0;
        end 
    end
    always @(posedge clk) begin
        if(reset)
            c0_cause_ip[1:0] <= 2'b0;
        else if(mtc0_we && c0_addr==`CR_CAUSE)
            c0_cause_ip[1:0] <= c0_wdata[9:8]; 
    end

    //excode
    always @(posedge clk) begin
        if(reset)
            c0_cause_excode <= 5'b0;
        else if(wb_ex)
            c0_cause_excode <= wb_excode; 
    end

    //reg epc
    reg [31:0] c0_epc;
    always @(posedge clk) begin
        if(wb_ex && !c0_status_exl)
            c0_epc <= wb_bd ? wb_pc - 3'h4 : wb_pc;
        else if(mtc0_we && c0_addr == `CR_EPC)
            c0_epc <= c0_wdata;
    end

    //output
    assign eret_pc  = c0_epc;
    assign ex_flush = wb_ex;
    assign c0_valid = op_mfc0 && wb_valid;
    assign c0_res   = {32{c0_addr==`CR_CAUSE}}   & c0_cause
                    | {32{c0_addr==`CR_STATUS}}  & c0_status
                    | {32{c0_addr==`CR_EPC}}     & c0_epc
                    | {32{c0_addr==`CR_COMPARE}} & c0_compare
                    | {32{c0_addr==`CR_COUNT}}   & c0_count; 
endmodule

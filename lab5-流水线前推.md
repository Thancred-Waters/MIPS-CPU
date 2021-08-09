# lab5-流水线前推

## 各阶段明细

1. **ID**阶段需求：

   - 存在与EXE阶段的写后读相关，可能依赖alu_result；
   - 存在与MEM阶段的写后读相关，可能依赖ms_final_result；
   - 存在与WB阶段的写后读相关，可能依赖ws_final_result；
   
2. **EXE**阶段数据状态：

   - alu_result可以单周期内返回，可以前推
   - lw指令取出的数据未就绪，无法前推

3. **MEM**阶段数据状态：

   - lw取出的数据已就绪，可以前推
   - alu_result已就绪，可以前推
   - 即ms_final_result可以前推

4. **WB**阶段数据状态：
- rf_wdata（ws_final_result）可以前推
## 前推逻辑
对于EXE阶段的lw指令，需要进行流水线暂停；其余指令均可以进行数据前推

```verilog
module hazard(
input        ds_use_rs,
input [4:0]  rs_addr,
input        ds_use_rt,
input [4:0]  rt_addr,
input        es_write_reg,
input [4:0]  es_reg_dest,
input        es_read_mem,//exe阶段指令是否需要读内存
input        ms_write_reg,
input [4:0]  ms_reg_dest,
input        ws_write_reg,
input [4:0]  ws_reg_dest,
output       stallD,
output       stallF,
output [1:0] forward_rs,
output [1:0] forward_rt
    );
    //forward
    wire ws_forward_rs,ws_forward_rt;
    assign ws_forward_rs=(ds_use_rs===1'b1 && rs_addr!==5'b0) && 
                         (ws_write_reg===1'b1 && rs_addr===ws_reg_dest);
    assign ws_forward_rt=(ds_use_rt===1'b1 && rt_addr!==5'b0) &&
                         (ws_write_reg===1'b1 && rt_addr===ws_reg_dest);

    wire ms_forward_rs,ms_forward_rt;
    assign ms_forward_rs=(ds_use_rs===1'b1 && rs_addr!==5'b0) &&
                         (ms_write_reg===1'b1 && rs_addr===ms_reg_dest);
    assign ms_forward_rt=(ds_use_rt===1'b1 && rt_addr!==5'b0) && 
                         (ms_write_reg===1'b1 && rt_addr===ms_reg_dest);

    wire es_forward_rs,es_forward_rt;
    assign es_forward_rs=(ds_use_rs===1'b1 && rs_addr!==5'b0) &&
                         (es_write_reg===1'b1 && es_read_mem===1'b0 && rs_addr===es_reg_dest);
    assign es_forward_rt=(ds_use_rt===1'b1 && rt_addr!==5'b0) &&
                         (es_write_reg===1'b1 && es_read_mem===1'b0 && rt_addr===es_reg_dest);                    


    assign forward_rs=es_forward_rs ? 2'b11 ://优先选择器，exe阶段数据最新，前推优先级最高
                      ms_forward_rs ? 2'b10 :
                      ws_forward_rs ? 2'b01 :
                      2'b00;
    assign forward_rt=es_forward_rt ? 2'b11 :
                      ms_forward_rt ? 2'b10 :
                      ws_forward_rt ? 2'b01 :
                      2'b00;

    //data stall
    wire rs_stall,rt_stall;
    assign rs_stall=(ds_use_rs===1'b1 && rs_addr!==5'b0) &&
                    (es_read_mem===1'b1 && rs_addr===es_reg_dest);
    assign rt_stall=(ds_use_rt===1'b1 && rt_addr!==5'b0) &&
                    (es_read_mem===1'b1 && rt_addr===es_reg_dest);
    assign stallD=rs_stall | rt_stall;
    assign stallF=stallD;
endmodule

```


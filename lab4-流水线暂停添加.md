# lab4-流水线暂停添加

## 1.流水线功能明确

### IF级

1. 取指令（利用nextpc取指令）
2. PC自增或跳转（接收ID阶段信号）

### ID级

1. 指令译码
2. 读寄存器堆
3. 写寄存器堆（WB阶段信号传入控制）

### EXE级

1. 执行运算
2. 准备写dram参数

### MEM级

1. 读写数据
2. 选择写入寄存器堆的内容

### WB级

1. 将数据写回寄存器堆

## 2.暂停逻辑

1. 首先确定只有ID阶段会产生指令冲突（写后读），需要暂停（因为只有本阶段有读寄存器操作）
2. 其次需要确定ID阶段是否使用到寄存器 以及 对应的寄存器地址（需要对rs寄存器和rt寄存器分别判断）
3. 判断ID阶段的寄存器地址是否与EXE MEM WB阶段需要写回寄存器堆的寄存器地址相同
4. 若相同则暂停IF ID阶段，否则流水线正常运行

## 3.暂停模块设置

```verilog
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
```

设计模块时，需要细化以下内容

1） ID阶段使用到寄存器,并且不是寄存器$zero

2）EXE、MEM、WB阶段的寄存器写使能信号有效 并且 流水线数据有效（存在流水线暂停后失效的情况）

es_write_reg = es_gr & es_valid

3）stallD和stallF的值保持一致

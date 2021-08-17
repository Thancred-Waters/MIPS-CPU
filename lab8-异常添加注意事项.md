# lab8-异常添加注意事项
## 概述
1. nextpc生成时，需要添加对**c0_epc**和**例外入口地址**的选择（根据**ex_flush/eret_flush**信号）
2. ID EXE MEM WB阶段需要添加flush信号，刷新**例外和eret指令**后取出的指令
3. 需要添加由mfc0引起的阻塞（**mfc0直到WB阶段才返回数据**）
4. 需要添加由eret和异常引起的写使能信号控制
5. 需要在流水线中传递异常信息
6. 例外需要跳转到**bfc00380**
7. 当流水线中有**异常或eret存在**时，**位于异常和eret后的指令**不应该再继续阻塞流水线

## pc更新逻辑

- 当触发异常时，即**ex_flush==1**，pc跳转到例外入口 **0xbfc00380**
- 当触发eret时，即**eret_flush==1**，pc跳转到**c0_epc**指向地址
- 当未发生任何异常时，pc根据**br_taken**正常生成nextpc

## 流水线阻塞逻辑

- 新增mfc0指令，在EXE和MEM无可用的前推数据，需要额外添加阻塞
- 当EXE级，MEM级和WB级存在异常指令时，取消所有阻塞
- 注意EXE级的除法运算产生阻塞也需要取消

## 流水线刷新逻辑

- 当eret或异常指令到达WB级时，生成流水线刷新信号eret_flush,ex_flush
- 在下个上升沿时，清除ID，EXE，MEM，WB阶段流水线缓存（将valid置为0），特别注意EXE级的DIV类指令
- IF阶段PC的取值根据eret_flush和ex_flush决定，不需要将valid置为0，否则跳转到的pc会被认为不合法

## CP0输出逻辑

- cp0_res为mfc0取出的数据
- cp0_valid表示当前是否有合法的cp0数据
- eret_pc表示eret命令返回的地址
- eret_flush表示是否因为eret刷新流水线（IF阶段跳转到eret_pc地址）
- ex_flush表示是否因为例外刷新流水线（IF阶段跳转到**0xbfc00380**地址）

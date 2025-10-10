`timescale 1ns / 1ps

module DlRAMRdControl_tb;

    // 输入信号
    reg clk;
    reg nRst;
    reg bus_state;
    reg DlDataRevEnable;
    reg ABitSendOk;
    reg [7:0] decodedData_8bit;
    reg send_data;
    reg [1:0] DlRAM_wr_state;

    // 输出信号
    wire [1:0] DlRAM_rd_state;
    wire rdRAMEn;
    wire [6:0] rdRAMAddr;
    wire [7:0] rdDataOut;
    wire rdDataOutEn;
    wire send_req;

    // 实例化被测试模块（UUT）
    DlRAMRdControl uut (
        .clk(clk),
        .nRst(nRst),
        .bus_state(bus_state),
        .DlDataRevEnable(DlDataRevEnable),
        .ABitSendOk(ABitSendOk),
        .decodedData_8bit(decodedData_8bit),
        .send_data(send_data),
        .DlRAM_wr_state(DlRAM_wr_state),
        .DlRAM_rd_state(DlRAM_rd_state),
        .rdRAMEn(rdRAMEn),
        .rdRAMAddr(rdRAMAddr),
        .rdDataOut(rdDataOut),
        .rdDataOutEn(rdDataOutEn),
        .send_req(send_req)
    );

    // 时钟生成（10 MHz 时钟）
    always begin
        #50 clk = ~clk;  // 10 MHz 时钟频率，每 50ns 翻转一次
    end

    // 测试激励信号
    initial begin
        // 初始化输入信号
        clk = 0;
        nRst = 0;
        bus_state = 0;
        DlDataRevEnable = 0;
        ABitSendOk = 0;
        decodedData_8bit = 8'd0;
        send_data = 0;
        DlRAM_wr_state = 2'b00;

        // 施加复位信号
        #200;
        nRst = 1; // 释放复位信号

        // 测试 ACK 发送功能
        // 启动 ACK 发送
   //     ;  // 由于时钟周期为50ns，原本的10ns延迟修改为20ns
        DlDataRevEnable = 1; // 模拟 DlDataRevEnable 信号
//        #20;  // 延时为20ns
//        DlDataRevEnable = 0; // 模拟 DlDataRevEnable 取消激活
        
        // 允许时间进行 ACK 发送
  //      #200;  // 修改为200ns，相当于4个时钟周期
  //      ABitSendOk = 1; // 模拟每次成功发送一个字节
        #20;  // 20ns 延时

        // 检查 ACK 序列
        // 发送 10 个周期的 ACK 序列数据
    //    #20;  // 20ns 延时
      //  ABitSendOk = 0; // 完成发送后停止

        // 验证 `send_req` 信号是否在适当的时机被激活
        // 并且检查 `rdDataOut` 是否发送正确的 ACK 数据

        // 结束仿真
        #500;  // 延时 100ns，保证仿真有足够时间查看结果
        $stop;  // 停止仿真
    end

endmodule

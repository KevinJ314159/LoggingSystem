`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/18 22:45:08
// Design Name: 
// Module Name: genClock_s_tb
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


module genClock_tb;

    // 输入信号
    reg ClkIn;      // 输入时钟信号（40MHz）
    reg nRst;       // 异步复位信号（低电平有效）

    // 输出信号
    wire Clk20MHz;  // 20MHz时钟信号
    wire Clk10MHz;  // 10MHz时钟信号
    wire Clk500KHz; // 500KHz时钟信号

    // 实例化待测试模块
    genClock uut (
        .ClkIn(ClkIn),
        .nRst(nRst),
        .Clk20MHz(Clk20MHz),
        .Clk10MHz(Clk10MHz),
        .Clk500KHz(Clk500KHz)
    );

    // 生成40MHz输入时钟
    initial begin
        ClkIn = 0;
        forever #12 ClkIn = ~ClkIn; // 40MHz时钟周期为25ns（12.5ns半周期）
    end

    // 测试逻辑
    initial begin
        // 初始化
        nRst = 0; // 复位信号拉低
        #100;     // 保持复位状态100ns

        // 释放复位
        nRst = 1; // 复位信号拉高
        #1000;    // 运行1000ns

        // 再次复位
        nRst = 0; // 复位信号拉低
        #100;     // 保持复位状态100ns

        // 释放复位
        nRst = 1; // 复位信号拉高
        #1000;    // 运行1000ns

        // 结束仿真
        $stop;
    end



endmodule
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/19 22:53:40
// Design Name: 
// Module Name: StoPContro_s_tb
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
module StoPControl_s_tb;

    reg CLK_100MHZ_t; // ?40Mhz?时钟信号
    reg CLK_10MHZ_t;            // 10MHz时钟输入
    reg UpSig_RClk_t;
    reg nRst_t; // 复位信号
    reg [9:0] UpSig_ROut_t; // 发送的数据
    reg [6:0] count; // 发送次数计数器
    reg UpSig_nLock_t;
    wire sync_success_t;

StoPControl_s tb1(
    .CLK_100MHZ(CLK_100MHZ_t),           // 100MHz时钟输入
    .CLK_10MHZ(CLK_10MHZ_t),            // 10MHz时钟输入
    .nRst(nRst_t),                 // 低电平有效复位信号
    .UpSig_RClk(UpSig_RClk_t),         // 来自串并转换器的恢复时钟
    .UpSig_nLock(UpSig_nLock_t),        // 来自串并转换器的锁定信号，正常工作时为低电平
    .UpSig_ROut(UpSig_ROut_t),   // 串并转换器输出的 10 位数据
    .sync_success(sync_success_t)         // 同步成功标志

    ); 
    // 时钟生成，周期200ns，即上升沿和下降沿间隔100ns
    always begin
        #50 CLK_10MHZ_t = ~CLK_10MHZ_t; // 每50ns翻转一次时钟
        end

always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // 每12ns翻转一次时钟40Mhz
    end

always begin
        #50 UpSig_RClk_t = ~UpSig_RClk_t; // 每50ns翻转一次时钟
    end

    // 发送数据逻辑：在时钟下降沿发送数据
    always @(negedge UpSig_RClk_t or negedge nRst_t) begin
        if (!nRst_t) begin
            count <= 0;
            UpSig_ROut_t <= 10'b0;
        end else begin
            if (count < 10) begin
                // 前10次发送10'b10010_00101
                UpSig_ROut_t <= 10'b10010_00101;
            end else if (count < 20) begin
                // 接下来的10次发送10'b00000_11111
                UpSig_ROut_t <= 10'b00000_11111;
            end else if (count < 30) begin
                // 接下来的10次发送10'b10010_00101
                UpSig_ROut_t <= 10'b10010_00101;
            end else if (count < 70) begin
                // 接下来的40次发送10'b00000_11111
                UpSig_ROut_t <= 10'b00000_11111;
            end else if (count == 70) begin
                // 最后一次发送10'b01111_11110
                UpSig_ROut_t <= 10'b10011_11100;
            end else begin
                UpSig_ROut_t <= 10'b11111_11111;
            end
            count <= count + 1; // 计数器递增
        end
    end

    // 初始块
    initial begin
        CLK_100MHZ_t = 0;
        CLK_10MHZ_t = 0;
        UpSig_RClk_t = 0;
        nRst_t = 0;
        UpSig_nLock_t = 1;
        #201 nRst_t = 1; // 释放复位信号
        #8000 UpSig_nLock_t = 0;
        #3000 nRst_t = 0;
        #200;
        $stop;
    end

endmodule

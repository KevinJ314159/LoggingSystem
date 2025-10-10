`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/24 22:35:26
// Design Name: 
// Module Name: PtoSControl_tb
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


module PtoSControl_s_tb;

    reg CLK_100MHZ_t; // ?40Mhz?时钟信号
    reg CLK_10MHZ_t;            // 10MHz时钟输入
    reg sync_success_t;
    reg [9:0] DownSig_Rout_t; // 发送的数据
    reg [6:0] count; // 发送次数计数器
    reg nRst_t; // 复位信号
    wire UpSig_Sync1_t;
    wire UpSig_Sync2_t;
    wire SEND_LAST_FRAME_En_t;
    wire shakehand_success_t;

PtoSControl_s tb1(
    .CLK_100MHZ(CLK_100MHZ_t),           // 100MHz时钟输入
    .CLK_10MHZ(CLK_10MHZ_t),            // 10MHz时钟输入
    .nRst(nRst_t),                 // 低电平有效复位信号
    .sync_success(sync_success_t),         // 来自串并转换器的恢复时钟
    .UpSig_Sync1(UpSig_Sync1_t),        // 来自串并转换器的锁定信号，正常工作时为低电平
    .UpSig_Sync2(UpSig_Sync2_t),   // 串并转换器输出的 10 位数据
    .SEND_LAST_FRAME_En(SEND_LAST_FRAME_En_t),         // 同步成功标志
    .shakehand_success(shakehand_success_t)
    ); 
    // 时钟生成，周期200ns，即上升沿和下降沿间隔100ns
    always begin
        #50 CLK_10MHZ_t = ~CLK_10MHZ_t; // 每50ns翻转一次时钟
        end

always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // 每12ns翻转一次时钟40Mhz
    end

    // 发送数据逻辑：在时钟下降沿发送数据
    always @(negedge CLK_10MHZ_t or negedge nRst_t) begin
        if (!nRst_t) begin
            count <= 0;
            DownSig_Rout_t <= 10'b0;
        end else begin
            if (count < 10) begin
                // 前10次发送10'b10010_00101
                DownSig_Rout_t <= 10'b10010_00101;
            end else if (count < 20) begin
                // 接下来的10次发送10'b00000_11111
                DownSig_Rout_t <= 10'b00000_11111;
            end else if (count < 30) begin
                // 接下来的10次发送10'b10010_00101
                DownSig_Rout_t <= 10'b10010_00101;
            end else if (count < 70) begin
                // 接下来的40次发送10'b00000_11111
                DownSig_Rout_t <= 10'b00000_11111;
            end else if (count == 70) begin
                // 最后一次发送10'b01111_11110
                DownSig_Rout_t <= 10'b01111_11110;
            end else begin
                DownSig_Rout_t <= 10'b11111_11111;
            end
            count <= count + 1; // 计数器递增
        end
    end

    // 初始块
    initial begin
        CLK_100MHZ_t = 0;
        CLK_10MHZ_t = 0;
        nRst_t = 0;
        sync_success_t = 0;
        #201 nRst_t = 1; // 释放复位信号
        #4000 sync_success_t = 1;
        #4000 nRst_t = 0;
        #200;
        $stop;
    end

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/22 22:27:12
// Design Name: 
// Module Name: sync_detect_tb
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


module sync_detect_tb;

    reg CLK_100MHZ_t; // 时钟信号
    reg detected_negedge_t;
    reg DownSig_RClk_t;
    reg nRst_t; // 复位信号
    reg [9:0] DownSig_Rout_t; // 发送的数据
    reg [6:0] count; // 发送次数计数器
    reg DownSig_nLock_t;
    wire sync_success_t;

sync_detect tb1(
    .CLK_100MHZ(CLK_100MHZ_t),           // ？40MHz？ 时钟输入
    .nRst(nRst_t),                 // 复位信号，低电平有效
    .detected_negedge(detected_negedge_t),         // 串并转换器的恢复时钟的下降沿
    .DownSig_Rout(DownSig_Rout_t),   // 串并转换器输出的 10 位数据
    .DownSig_nLock(DownSig_nLock_t),        // 串并转换器的锁定信号
    .sync_success(sync_success_t)          // 同步成功标志

    ); 
    // 时钟生成，周期200ns，即上升沿和下降沿间隔100ns
    always begin
        #50 detected_negedge_t = ~detected_negedge_t; // 每50ns翻转一次时钟
        end

always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // 每12ns翻转一次时钟40Mhz
    end

always begin
        #50 DownSig_RClk_t = ~DownSig_RClk_t; // 每50ns翻转一次时钟
    end

    // 发送数据逻辑：在时钟下降沿发送数据
    always @(negedge DownSig_RClk_t or negedge nRst_t) begin
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
        detected_negedge_t = 0;
        CLK_100MHZ_t = 0;
        DownSig_RClk_t = 0;
        nRst_t = 0;
        DownSig_nLock_t = 1;
        #201 nRst_t = 1; // 释放复位信号
        #8000 DownSig_nLock_t = 0;
        #3000 nRst_t = 0;
        #200;
        $stop;
    end

endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/26 21:37:09
// Design Name: 
// Module Name: DownholeSPAndPSControl_tb
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

module DownholeSPAndPSControl_tb;

    reg CLK_100MHZ_t; // ?40Mhz?时钟信号
    reg CLK_10MHZ_t;            // 10MHz时钟输入
    reg CLK_10MHZ_t_1;       // 来自串并转化器的恢复时钟
    reg DataInEn_t;     
    reg DownSig_nLock_t;
    reg [9:0] DataIn_t; // 发送的数据
    reg [9:0] DownSig_Rout_t; // 发送的数据
    reg RX_Los_t;

    reg DataIn_t_send_flag;
    reg [10:0] count; // 发送次数计数器
    reg [6:0] count1; // 发送次数计数器
    reg nRst_t; // 复位信号
    wire DownSig_RefClk_t;
    wire DownSig_RClk_RnF_t;
    wire DownSig_nPWRDN_t;
    wire [9:0] DLDataOut_t;
    wire UpSig_TClk_t;
    wire DownSig_REn_t;
    wire DLDataOutEn_t;
    wire UpSig_TClk_RnF_t;
    wire [9:0] UpSig_Din_t;
    wire UpSig_DEn_t;
    wire UpSig_nPWRDN_t;
    wire UpSig_Sync1_t;
    wire UpSig_Sync2_t;
    wire DoHole_sync_success_t;
    wire Tx_Disable_t;





DownholeSPAndPSControl tb1(
    // 输入端口
//    .CLK_100MHZ(CLK_100MHZ_t),         // ?40? MHz 时钟信号
    .CLK_10MHZ(CLK_10MHZ_t),          // 10 MHz 时钟信号
    .nRst(nRst_t),               // 复位信号，低电平有效
    .DataInEn(DataInEn_t),           // 数据输入使能信号
    .DataIn(DataIn_t),       // 10 位数据输入
    .DownSig_RClk(CLK_10MHZ_t_1),       // 来自串并转化器的恢复时钟
    .DownSig_nLock(DownSig_nLock_t),      // 锁定信号，低电平表示正常工作
    .DownSig_ROut(DownSig_Rout_t), // 串行到并行转换的10位数据输出
//    .RX_Los(RX_Los_t),             // 接收信号丢失指示

    // 输出端口
    .DownSig_RefClk(DownSig_RefClk_t),   // 串行到并行转换的参考时钟信号
    .DownSig_RClk_RnF(DownSig_RClk_RnF_t), // 串行到并行转换的接收时钟反转信号
    .DownSig_nPWRDN(DownSig_nPWRDN_t),   // 串并转换的掉电信号
    .DownSig_REn(DownSig_REn_t),      // 串并转换的数据使能信号
    .DLDataOutEn(DLDataOutEn_t),      /* 下行数据输出有效信号（不太明白这个有什么用功能和DoHole_sync_success井下同步成功指示信号重合？）
                                     目前在收到下行同步码及尾帧后将其拉高，即认为下行数据有效）*/
    .DLDataOut(DLDataOut_t),  // 下行10位数据输出
    .UpSig_TClk(UpSig_TClk_t),       // 并行到串行转换的传输时钟信号
    .UpSig_TClk_RnF(UpSig_TClk_RnF_t),   // 串并转换的传输时钟反转信号
    .UpSig_Din(UpSig_Din_t),  // 提供给并串转换器的10位数据
    .UpSig_DEn(UpSig_DEn_t),        // 串行器处并行到串行转换的数据使能信号
    .UpSig_nPWRDN(UpSig_nPWRDN_t),     // 并串转换器的掉电信号
    .UpSig_Sync1(UpSig_Sync1_t),      // 并串转换器的同步信号1
    .UpSig_Sync2(UpSig_Sync2_t),      // 并串转换器的同步信号2
    .DoHole_sync_success(DoHole_sync_success_t) // 井下同步成功指示信号(目前在井下发送同步尾帧，进入工作状态后才认为完成同步)
//    .Tx_Disable(Tx_Disable_t)        // 发送禁用信号
);
    // 时钟生成，周期200ns，即上升沿和下降沿间隔100ns
    always begin
        #50 CLK_10MHZ_t = ~CLK_10MHZ_t; // 每50ns翻转一次时钟
        #50 CLK_10MHZ_t_1 = ~CLK_10MHZ_t_1;
        end


always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // 每12ns翻转一次时钟40Mhz
    end

    //assign #15 DownSig_RClk_t = CLK_10MHZ_t;  // 延迟模拟解串器PLL造成的相位延迟


    // 发送数据逻辑：在时钟下降沿发送数据
    always @(negedge CLK_10MHZ_t_1 or negedge nRst_t) begin
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

            end else if (count == 111) begin
                DownSig_Rout_t <= 10'b10100_00111;
                // 发送10'h287
            end else if (count == 112) begin
                DownSig_Rout_t <= 10'b10100_00111;
                // 发送10'h287
            end else if (count < 120) begin
                DownSig_Rout_t <= 110'b11111_00111;

            end else if (count < 130) begin
                DownSig_Rout_t <= 10'b11111_01111;

            end else if (count < 150) begin
                DownSig_Rout_t <= 10'b11111_11111;

                end else 
                DownSig_Rout_t <= 10'b11111_00000;

            count <= count + 1; // 计数器递增
        end
    end

    // 发送数据逻辑：在时钟下降沿发送数据
    always @(posedge CLK_10MHZ_t or negedge nRst_t) begin
        if (!nRst_t) begin
            count1 <= 0;
            DataIn_t <= 10'b0;
        end else if(DataIn_t_send_flag) begin
            if (count1 < 10) begin
                // 前10次发送10'b10010_00101
                DataIn_t <= 10'b10000_00000;
            end else if (count1 < 20) begin
                // 接下来的10次发送10'b00000_11111
                DataIn_t <= 10'b11000_00000;
            end else if (count1 == 20)
                DataIn_t <= 10'b11100_00000;
                else if(count1 == 21)
                DataIn_t <= 10'b11100_00001;
                else if(count1 == 22)
                DataIn_t <= 10'b11100_00011;
                else if(count1 == 23)
                DataIn_t <= 10'b11100_00111;
                else if(count1 < 30)
                DataIn_t <= 10'b11100_01111;
            else if (count1 < 70) begin
                // 接下来的40次发送10'b00000_11111
                DataIn_t <= 10'b11110_00000;
            end else if (count1 == 70) begin
                // 最后一次发送10'b01111_11110
                DataIn_t <= 10'b11110_00000;
            end else begin
                DataIn_t <= 10'b11111_00000;
            end
            count1 <= count1 + 1; // 计数器递增
        end
    end


    // 初始块
    initial begin
        CLK_100MHZ_t = 0;
        CLK_10MHZ_t_1 = 0;
        CLK_10MHZ_t = 0;
        nRst_t = 0;
        DataInEn_t = 1;
        RX_Los_t = 0;
        DownSig_nLock_t = 0;
        DataIn_t_send_flag = 0;
        #201 nRst_t = 1; // 释放复位信号
        #15000 DataIn_t_send_flag = 1;
        #25000 RX_Los_t = 1;
        #400;
        nRst_t = 0;
        #400
        $stop;
    end

endmodule
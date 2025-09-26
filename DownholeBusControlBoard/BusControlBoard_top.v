`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/02 15:56:02
// Design Name: 
// Module Name: BusControlBoard_top
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


module BusControlBoard_top(
    input ClkIn,        // 40Mhz时钟输入
    input nRst,         // 异步复位信号（低电平有效）

    input DownSig_RClk,     // 来自解串器的恢复时钟
    input DownSig_nLock,    // 来自解串器的PLL锁定信号
    input [9:0] DownSig_ROut,     // 来自串行到并行转换（解串器）的10位数据输出

//    output wire DownSig_RefClk,      // 提供给 串行到并行转换（解串器）的参考时钟信号
    output wire DownSig_RClk_RnF,   // 提供给 串行到并行转换（解串器）的接收时钟反转信号
    output wire DownSig_nPWRDN,    // 提供给 串并转换（解串器）的掉电信号
    output wire DownSig_REn,       //. 提供给 串并转换（解串器）的数据使能信号
    output wire DownSig_RefClk,

    output wire UpSig_TClk_RnF,     // 提供给 并串转换（串行器）的传输时钟反转信号
    output wire [9:0] UpSig_Din,          // 提供给 并串转换器（串行器）的10位数据
    output wire UpSig_DEn,          // 提供给 并行到串行转换（串行器）的数据使能信号
    output wire UpSig_nPWRDN,       //  提供给 并串转换器（串行器）的掉电信号
    output wire UpSig_Sync1,
    output wire UpSig_Sync2,
    output wire UpSig_TClk,



    input McBSPFSR,        // McBSP帧同步信号（指示帧开始）
    input McBSPDR,         // McBSP串行数据输入（1-bit）


    output wire outDataToDsp,

    output wire DspUlClk        // 上行FIFO提供给井下DSP的发送参考时钟





    );

    wire Clk20MHz_o;
    wire Clk10MHz_o;


//    wire Clk10MHz_o;

//    assign DspUlClk = Clk10MHz;

    wire DLDataOutEn;  // 提供给 下行RAM 的下行数据输出有效信号（此信号在整个通信帧中拉高）
    wire [9:0] DLDataOut;  // 提供给 下行RAM 的下行10位数据输出
    wire DoHole_sync_success;

    wire [9:0] outData;       // 上行FIFO口编码后的10B待发数据
    wire outDataEn;         // 上行FIFO口编码后的10B待发数据有效使能

    genClock genClock_instance(
        .ClkIn(ClkIn),
        .nRst(nRst),
        .Clk10MHz(Clk10MHz_o),
        .Clk20MHz(Clk20MHz_o)
        

        );

    DownholeSPAndPSControl DownholeSPAndPSControl_instance(
        .CLK_10MHZ(Clk10MHz_o),
        .nRst(nRst),
        .DataInEn(outDataEn),           // 来自 上行RAM的数据输入使能信号
        .DataIn(outData),       //来自 上行RAM的 10 位数据输入

        .DownSig_RClk(DownSig_RClk),       // 来自 串并转化器 (解串器）的恢复时钟  直接用此时钟驱动解串器控制相关模块
        .DownSig_nLock(DownSig_nLock),      // 来自 串并转化器（解串器）的锁定信号，低电平表示正常工作
        .DownSig_ROut(DownSig_ROut), // 来自 串行到并行转换（解串器）的10位数据输出
        .DownSig_RefClk(DownSig_RefClk),   // 提供给 串行到并行转换（解串器）的参考时钟信号
        .DownSig_RClk_RnF(DownSig_RClk_RnF), // 提供给 串行到并行转换（解串器）的接收时钟反转信号
        .DownSig_nPWRDN(DownSig_nPWRDN),   // 提供给 串并转换（解串器）的掉电信号
        .DownSig_REn(DownSig_REn),      // 提供给 串并转换（解串器）的数据使能信号
        .DLDataOutEn(DLDataOutEn),      // 提供给 下行RAM 的下行数据输出有效信号（此信号在整个通信帧中拉高）
        .DLDataOut(DLDataOut),  // 提供给 下行RAM 的下行10位数据输出

        .UpSig_TClk(UpSig_TClk),       // 提供给 并行到串行（串行器）转换的传输时钟信号
        .UpSig_TClk_RnF(UpSig_TClk_RnF),   // 提供给 并串转换（串行器）的传输时钟反转信号
        .UpSig_Din(UpSig_Din),  // 提供给 并串转换器（串行器）的10位数据
        .UpSig_DEn(UpSig_DEn),        // 提供给 并行到串行转换（串行器）的数据使能信号
        .UpSig_nPWRDN(UpSig_nPWRDN),     // 提供给 并串转换器（串行器）的掉电信号
        .UpSig_Sync1(UpSig_Sync1),      // 提供给 并串转换器（串行器）的同步信号1
        .UpSig_Sync2(UpSig_Sync2),      // 提供给 并串转换器（串行器）的同步信号2
        .DoHole_sync_success(DoHole_sync_success) // 井下同步成功/下行链路建立指示信号(目前在井下发送同步尾帧，进入工作状态后才认为完成同步)
        );


    UlChannelDataControl_final UlChannelDataControl_final_instance(
        .DlDataRevEnable(DoHole_sync_success),
        .interfaceClk(Clk10MHz_o),
        .outClk(Clk10MHz_o),
        .nRst(nRst),
        .McBSPFSR(McBSPFSR),
        .McBSPDR(McBSPDR),
        .outData(outData),
        .outDataEn(outDataEn),
        .McBSPClkR(DspUlClk)

        );

    DlChannelDataControl DlChannelDataControl_instance(
        .Clk10MHz(DownSig_RClk),
        .nRst(nRst),
        .validDataEn(DLDataOutEn),
        .validData(DLDataOut),
        .DlDataRevEnable(DoHole_sync_success),
        .outData(outDataToDsp)
        );
endmodule

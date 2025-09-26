`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/04 00:57:43
// Design Name: 
// Module Name: FiberSurfaceCommBoard_top
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


module FiberSurfaceCommBoard_top(
    input ClkIn,        // 40Mhz时钟输入
    input nRst,         // 异步复位信号（低电平有效）

    input UpSig_RClk,     // 来自解串器的恢复时钟
    input UpSig_nLock,    // 来自解串器的PLL锁定信号
    input [9:0] UpSig_ROut,     // 来自串行到并行转换（解串器）的10位数据输出

    output wire UpSig_RClk_RnF,   // 提供给 串行到并行转换（解串器）的接收时钟反转信号
    output wire UpSig_nPWRDN,    // 提供给 串并转换（解串器）的掉电信号
    output wire UpSig_REn,       //. 提供给 串并转换（解串器）的数据使能信号
    output wire UpSig_RefClk,

    output wire DownSig_TClk_RnF,     // 提供给 并串转换（串行器）的传输时钟反转信号
    output wire [9:0] DownSig_Din,          // 提供给 并串转换器（串行器）的10位数据
    output wire DownSig_DEn,          // 提供给 并行到串行转换（串行器）的数据使能信号
    output wire DownSig_nPWRDN,       //  提供给 并串转换器（串行器）的掉电信号
    output wire DownSig_Sync1,
    output wire DownSig_Sync2,
    output wire DownSig_TClk,

    input McBSPFSR,        // McBSP帧同步信号（指示帧开始）
    input McBSPDR,         // McBSP串行数据输入（1-bit）


    output wire outDataToDsp,
    output wire outFSXToDsp,

    output wire DspDlClk        // 下行FIFO提供给地面DSP的发送参考时钟

    );

    wire Clk20MHz_o;
    wire Clk10MHz_o;
    wire Clk500KHz_o;


    wire ULDataOutEn;  // 提供给 下行RAM 的下行数据输出有效信号（此信号在整个通信帧中拉高）
    wire [9:0] UlDataOut;  // 提供给 下行RAM 的下行10位数据输出
    wire shakehand_success;

    wire [9:0] outData;       // 上行FIFO口编码后的10B待发数据
    wire outDataEn;         // 上行FIFO口编码后的10B待发数据有效使能


    genClock_s genClock_s_instance(
    .ClkIn(ClkIn),        // 输入时钟信号（40MHz）
    .nRst(nRst),         // 异步复位信号（低电平有效）
    .Clk20MHz(Clk20MHz_o), // 20MHz时钟信号
    .Clk10MHz(Clk10MHz_o), // 10MHz时钟信号
    .Clk500KHz(Clk500KHz_o) // 500KHz时钟信号
);


    UlChannelDataControl_s UlChannelDataControl_s_instance(
    .McBSPClk(Clk20MHz_o),
    .Clk10MHz(UpSig_RClk),       // 10MHz时钟
    .nRst(nRst),
    .validDataEn(ULDataOutEn),        // 接入来自井下串并控制模块的DLDataOutEn信号,该信号在完成地面到井下的串行/解串器同步后即拉高
    .validData(UlDataOut),         // 解串器处理后的DownSig_Rout并行信号
    .UlDataRevEnable(shakehand_success),     // 接入来自井下串并控制模块的DoHole_sync_success信号，该信号在井下模块发出尾帧后拉高

    .outData(outDataToDsp),         // 最终由McBSP_16B驱动输出的解码后数据
    .FSX(outFSXToDsp)
    );


     DlChannelDataControl_s DlChannelDataControl_s_instance(
    .interfaceClk(Clk500KHz_o),
    .outClk(Clk10MHz_o),       // 10Mhz时钟
    .nRst(nRst),
    .McBSPFSR(McBSPFSR),        // McBSP帧同步信号（指示帧开始）
    .McBSPDR(McBSPDR),         // McBSP串行数据输入（1-bit）
//    input [7:0] data_in,    // McBSP 输入数据
//    input data_in_en,       // 数据使能

    .McBSPClkR(DspDlClk),       // 提供给DSP的时钟；（需要确认频率）
    .outData(outData),
    .outDataEn(outDataEn),
    // 测试观测用output
    .wrAFrameDataOkFlag()
//    .wrEncContinue()
//    output [9:0] encoded_out,  // 8b/10b 编码后输出数据
//    output [9:0] ram_wd,       // 写入 RAM 的数据
//    output [9:0] ram_waddr,    // 写入 RAM 的地址
//    output ram_wen,            // 写入 RAM 的使能
//    output ram_wclk            // 写入 RAM 的时钟
);

    SurfaceSPAndPSControl_s SurfaceSPAndPSControl_s_instance(
    .CLK_10MHZ(Clk10MHz_o),          // 10 MHz 时钟信号
    .nRst(nRst),               // 复位信号，低电平有效
    .DataInEn(outDataEn),           //来自地面下行RAM读模块的 数据输入使能信号
    .DataIn(outData),       //来自地面下行RAM读模块的 10 位数据输入
    .UpSig_RClk(UpSig_RClk),       // 来自 串并转化器 (解串器）的恢复时钟  直接用此时钟驱动解串器控制相关模块
    .UpSig_nLock(UpSig_nLock),      // 锁定信号，低电平表示正常工作
    .UpSig_ROut(UpSig_ROut), // 串行到并行转换的10位数据输出
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)

    // 输出端口
    .UpSig_RefClk(UpSig_RefClk),   // 
    .UpSig_RClk_RnF(UpSig_RClk_RnF), // 提供给 串行到并行转换（解串器）的接收时钟反转信号
    .UpSig_nPWRDN(UpSig_nPWRDN),   // 提供给 串并转换（解串器）的掉电信号
    .UpSig_REn(UpSig_REn),      // 提供给 串并转换（解串器）的数据使能信号
    .UlDataOutEn(ULDataOutEn),      //提供给 上行RAM 的上行数据输出有效信号（此信号在整个通信帧中拉高）
    .UlDataOut(UlDataOut),  // 提供给 上行RAM 的上行10位数据输出

    .DownSig_TClk(DownSig_TClk),       // 提供给 并行到串行（串行器）转换的传输时钟信号
    .DownSig_TClk_RnF(DownSig_TClk_RnF),   // 提供给 并串转换（串行器）的传输时钟反转信号
    .DownSig_Din(DownSig_Din),  // 提供给 并串转换器（串行器）的10位数据
    .DownSig_DEn(DownSig_DEn),        // 提供给 并行到串行转换（串行器）的数据使能信号
    .DownSig_nPWRDN(DownSig_nPWRDN),     // 提供给 并串转换器（串行器）的掉电信号,信号为0时，串并转化器的输出DownSig_ROut进入高阻状态。
    .DownSig_Sync1(DownSig_Sync1),      // 提供给 并串转换器（串行器）的同步信号1
    .DownSig_Sync2(DownSig_Sync2),      // 提供给 并串转换器（串行器）的同步信号1
    .shakehand_success(shakehand_success) // 地面同步成功指示信号，在井下到地面链路建立后拉高
    );
endmodule

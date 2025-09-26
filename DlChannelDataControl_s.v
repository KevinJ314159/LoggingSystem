`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/21 13:47:44
// Design Name: 
// Module Name: DlChannelDataControl_s
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

module DlChannelDataControl_s(
    input interfaceClk,
    input outClk,       // 10Mhz时钟
    input nRst,
    input McBSPFSR,        // McBSP帧同步信号（指示帧开始）
    input McBSPDR,         // McBSP串行数据输入（1-bit）
//    input [7:0] data_in,    // McBSP 输入数据
//    input data_in_en,       // 数据使能

    output McBSPClkR,       // 提供给DSP的时钟；（需要确认频率）
    output [9:0] outData ,
    output reg outDataEn,
    // 测试观测用output
    output wrAFrameDataOkFlag
//    output wrEncContinue
//    output [9:0] encoded_out,  // 8b/10b 编码后输出数据
//    output [9:0] ram_wd,       // 写入 RAM 的数据
//    output [9:0] ram_waddr,    // 写入 RAM 的地址
//    output ram_wen,            // 写入 RAM 的使能
//    output ram_wclk            // 写入 RAM 的时钟
);

//    wire conditional_reset = UlDataRevEnable && nRst;
    // 信号连接
    wire data_in_en;       // 16b to 8 b 输出使能数据使能
    wire [7:0] data_in;    // 16b to 8 b 输出的8Bit数据

    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;     // 此信号为一个通信帧(262B)都长高的编码使能信号
    wire wrRAMen;
    wire [1:0] DlRAM_wr_state;

    wire [9:0] encode10b;

//    wire [9:0] ram_wd;       // 写入 RAM 的数据
    wire [6:0] ram_waddr;    // 写入 RAM 的地址(直接发给RAM)
//    wire ram_wen;            // 写入 RAM 的使能
//    wire ram_wclk;         // 写入 RAM 的时钟

    wire [6:0] rdRAMAddr;
    wire rdRAMEn;
    wire [1:0] DlRAM_rd_state;

assign McBSPClkR = interfaceClk;      // 直接将10Mhz时钟发送给DSP作为DSP驱动时钟

    McBSPDriver_16bTo8b_s McBSPDriver_16bTo8b_s_instance(
        .interfaceClk(interfaceClk),    // McBSP接口10Mhz时钟（来自DSP的串行时钟）
        .nRst(nRst),            // 低有效复位（异步复位）
        .McBSPFSR(McBSPFSR),        // McBSP帧同步信号（指示帧开始）
        .McBSPDR(McBSPDR),         // McBSP串行数据输入（1-bit）
        .McBSPDataEn(data_in_en),// 并行数据有效标志（高电平有效）
        .McBSPData(data_in) // 输出的8位并行数据)
    );

    // 写控制模块实例化
    DlRAMWrControl_s DlRAMWrControl_s_instance(
        .clk(interfaceClk),
        .nRst(nRst),
        .inData(data_in),
        .inDataEn(data_in_en),
        .DlRAM_rd_state(DlRAM_rd_state),  // 此处未接入读控制模块
        .wrDlRAMAddr(ram_waddr),  // 写入 RAM 的地址(直接发给RAM)
        .DlRAM_wr_state(DlRAM_wr_state),
        .DlEncoderEn(wrEncEn),     // 输出使能信号
        .DlEncodeContinue(wrEncContinue),
        .wrAFrameDataOkFlag(wrAFrameDataOkFlag),
        .DlEncoderData(wrEncData)
    );

    // 8b/10b 编码器实例化
    encode_8bTo10b_new_s encode_8bTo10b_new_instance(
        .clk(interfaceClk),
        .rst_n(nRst),
        .encode_en(wrEncContinue),       // 使能信号
        .encode_continue(wrEncEn),
//        .is_k(1'b1),            // 若无 K 码支持，可固定为 0（视情况更改）
//        .din_8b(wrEncData),     // 输入的 8 位数据
        .data_8b(wrEncData),
        .data_10b(encode10b),    // 输出的 10 位编码数据
        .data_10b_en(wrRAMen)
    );

    DlDualPortRAM_s DlDualPortRAM_s_instance(
        .clk_in(interfaceClk),
        .clk_out(outClk),
        .waddr(ram_waddr),
        .wdata(encode10b),
        .wen(wrRAMen),
        .raddr(rdRAMAddr),
        .rden(rdRAMEn),
        .rdata(outData)
    );

    DlRAMRdControl_s DlRAMRdControl_s_instance(
        .clk(outClk),
        .nRst(nRst),
        .DlRAM_wr_state(DlRAM_wr_state),
        .DlRAM_rd_state(DlRAM_rd_state),
        .rdRAMEn(rdRAMEn),
        .rdRAMAddr(rdRAMAddr)
//        .ramDataIn()
//        .rdDataOutEn(rdRAMEn)
        );
    // 将编码后的 10 位数据传递到 RAM
//    assign ram_wd = encode10b;
//    assign ram_wen = wrRAMen;
//    assign ram_wclk = clk;  // 写入时钟为系统时钟

//    assign encoded_out = encode10b;
always @(posedge outClk or negedge nRst) begin
    if (!nRst) begin
        outDataEn <= 0;
    end else 
        outDataEn <= rdRAMEn;
    end
    
endmodule

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
    input outClk,       // 10Mhzʱ��
    input nRst,
    input McBSPFSR,        // McBSP֡ͬ���źţ�ָʾ֡��ʼ��
    input McBSPDR,         // McBSP�����������루1-bit��
//    input [7:0] data_in,    // McBSP ��������
//    input data_in_en,       // ����ʹ��

    output McBSPClkR,       // �ṩ��DSP��ʱ�ӣ�����Ҫȷ��Ƶ�ʣ�
    output [9:0] outData ,
    output reg outDataEn,
    // ���Թ۲���output
    output wrAFrameDataOkFlag
//    output wrEncContinue
//    output [9:0] encoded_out,  // 8b/10b ������������
//    output [9:0] ram_wd,       // д�� RAM ������
//    output [9:0] ram_waddr,    // д�� RAM �ĵ�ַ
//    output ram_wen,            // д�� RAM ��ʹ��
//    output ram_wclk            // д�� RAM ��ʱ��
);

//    wire conditional_reset = UlDataRevEnable && nRst;
    // �ź�����
    wire data_in_en;       // 16b to 8 b ���ʹ������ʹ��
    wire [7:0] data_in;    // 16b to 8 b �����8Bit����

    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;     // ���ź�Ϊһ��ͨ��֡(262B)�����ߵı���ʹ���ź�
    wire wrRAMen;
    wire [1:0] DlRAM_wr_state;

    wire [9:0] encode10b;

//    wire [9:0] ram_wd;       // д�� RAM ������
    wire [6:0] ram_waddr;    // д�� RAM �ĵ�ַ(ֱ�ӷ���RAM)
//    wire ram_wen;            // д�� RAM ��ʹ��
//    wire ram_wclk;         // д�� RAM ��ʱ��

    wire [6:0] rdRAMAddr;
    wire rdRAMEn;
    wire [1:0] DlRAM_rd_state;

assign McBSPClkR = interfaceClk;      // ֱ�ӽ�10Mhzʱ�ӷ��͸�DSP��ΪDSP����ʱ��

    McBSPDriver_16bTo8b_s McBSPDriver_16bTo8b_s_instance(
        .interfaceClk(interfaceClk),    // McBSP�ӿ�10Mhzʱ�ӣ�����DSP�Ĵ���ʱ�ӣ�
        .nRst(nRst),            // ����Ч��λ���첽��λ��
        .McBSPFSR(McBSPFSR),        // McBSP֡ͬ���źţ�ָʾ֡��ʼ��
        .McBSPDR(McBSPDR),         // McBSP�����������루1-bit��
        .McBSPDataEn(data_in_en),// ����������Ч��־���ߵ�ƽ��Ч��
        .McBSPData(data_in) // �����8λ��������)
    );

    // д����ģ��ʵ����
    DlRAMWrControl_s DlRAMWrControl_s_instance(
        .clk(interfaceClk),
        .nRst(nRst),
        .inData(data_in),
        .inDataEn(data_in_en),
        .DlRAM_rd_state(DlRAM_rd_state),  // �˴�δ���������ģ��
        .wrDlRAMAddr(ram_waddr),  // д�� RAM �ĵ�ַ(ֱ�ӷ���RAM)
        .DlRAM_wr_state(DlRAM_wr_state),
        .DlEncoderEn(wrEncEn),     // ���ʹ���ź�
        .DlEncodeContinue(wrEncContinue),
        .wrAFrameDataOkFlag(wrAFrameDataOkFlag),
        .DlEncoderData(wrEncData)
    );

    // 8b/10b ������ʵ����
    encode_8bTo10b_new_s encode_8bTo10b_new_instance(
        .clk(interfaceClk),
        .rst_n(nRst),
        .encode_en(wrEncContinue),       // ʹ���ź�
        .encode_continue(wrEncEn),
//        .is_k(1'b1),            // ���� K ��֧�֣��ɹ̶�Ϊ 0����������ģ�
//        .din_8b(wrEncData),     // ����� 8 λ����
        .data_8b(wrEncData),
        .data_10b(encode10b),    // ����� 10 λ��������
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
    // �������� 10 λ���ݴ��ݵ� RAM
//    assign ram_wd = encode10b;
//    assign ram_wen = wrRAMen;
//    assign ram_wclk = clk;  // д��ʱ��Ϊϵͳʱ��

//    assign encoded_out = encode10b;
always @(posedge outClk or negedge nRst) begin
    if (!nRst) begin
        outDataEn <= 0;
    end else 
        outDataEn <= rdRAMEn;
    end
    
endmodule

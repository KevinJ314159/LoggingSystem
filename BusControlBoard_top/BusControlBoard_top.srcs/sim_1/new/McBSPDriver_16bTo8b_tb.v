
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
// 
// Create Date: 2025/01/30 15:20:12
// Design Name: 
// Module Name: McBSPDriver_16bTo8b_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  �����η���֮�䣬�ڶ��η���ʱ�� FSR ���ߵ�ʱ����ǰ 1 ��ʱ������
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module McBSPDriver_16bTo8b_tb();

//-------------------------
// �źŶ���
//-------------------------
reg         interfaceClk_tb;   // 10MHzʱ�� (���� = 100ns)
reg         nRst_tb;           // ��λ�ź�
reg         McBSPFSR_tb;       // ֡ͬ���ź�
reg         McBSPDR_tb;        // ������������
wire        McBSPDataEn_tb;    // ������Ч��־
wire [7:0]  McBSPData_tb;      // �����������

//-------------------------
// ʵ��������ģ��
//-------------------------
McBSPDriver_16bTo8b tb1 (
    .interfaceClk(interfaceClk_tb),
    .nRst(nRst_tb),
    .McBSPFSR(McBSPFSR_tb),
    .McBSPDR(McBSPDR_tb),
    .McBSPDataEn(McBSPDataEn_tb),
    .McBSPData(McBSPData_tb)
);

//-------------------------
// ����10MHzʱ��
//-------------------------
initial begin
    interfaceClk_tb = 0;
    forever #50 interfaceClk_tb = ~interfaceClk_tb;  // ����=100ns (10MHz)
end

//-------------------------
// ����������
//-------------------------
initial begin
    // ��ʼ���ź�
    nRst_tb = 0;
    McBSPFSR_tb = 0;
    McBSPDR_tb = 0;
    
    // ��λ���� (���� 2 ��ʱ������)
    #100;
    nRst_tb = 1;
    #100;
    
    // ���Գ���1: ���� 0xA55A (��һ�η���, FSR ����ʱ��)
    send_16bit_data(16'hA55A);

    // ���Գ���2: ���� 0x1234 (�ڶ��η���, ��ǰһ���������� FSR)
    send_16bit_data_earlier(16'h1234);

    // ��������
    #1000;
    $finish;
end

//-------------------------------------------------
// ����16λ�������� (ԭʼʱ��)
//-------------------------------------------------
task send_16bit_data;
    input [15:0] data;
    integer i;
begin
    // Step 1: �ȵ�һ��ʱ�������أ������� FSR
    @(posedge interfaceClk_tb);
    McBSPFSR_tb <= 1;
    @(posedge interfaceClk_tb);
    McBSPFSR_tb <= 0;  // ������ 1 ������
    
    // Step 2: ���η��� 16 λ����
    for (i = 15; i >= 0; i = i - 1) begin
        McBSPDR_tb <= data[i];
        @(posedge interfaceClk_tb);
    end
end
endtask

//-------------------------------------------------
// ����16λ�������� (FSR ��ǰ 1 ������)
//-------------------------------------------------
task send_16bit_data_earlier;
    input [15:0] data;
    integer i;
begin
    // ע��: ������һ�� @(posedge interfaceClk_tb);
    //       ֱ������ FSR, ʹ���ԭ������ǰ 1 ������
    McBSPFSR_tb <= 1;
    @(posedge interfaceClk_tb);
    McBSPFSR_tb <= 0;  // ������ 1 ������
    
    // ���� 16 λ����
    for (i = 15; i >= 0; i = i - 1) begin
        McBSPDR_tb <= data[i];
        @(posedge interfaceClk_tb);
    end
end
endtask

endmodule

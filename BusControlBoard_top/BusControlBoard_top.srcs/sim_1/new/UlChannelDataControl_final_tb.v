`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
// 
// Create Date: 2025/02/02
// Design Name: 
// Module Name: UlChannelDataControl_final_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for UlChannelDataControl_final
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

/*
//-------------------------
// �źŶ���
//-------------------------
reg         interfaceClk_tb;   // 10MHzʱ��
reg         outClk_tb;         // 10MHzʱ��
reg         nRst_tb;           // ��λ�ź�
reg         McBSPFSR_tb;       // ֡ͬ���ź�
reg         McBSPDR_tb;        // ������������
wire [9:0]  outData_tb;        // �������
wire        outDataEn_tb;      // �������ʹ��
wire        wrAFrameDataOkFlag_tb;  // ����д����ɱ�־
wire        wrEncContinue_tb;      // ��������ź�
*/

//`timescale 1ns / 1ps
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

module UlChannelDataControl_final_tb();

//-------------------------
// �źŶ���
//-------------------------
reg         interfaceClk_tb;   // 10MHzʱ�� (���� = 100ns)
reg         outClk_tb;         // 10MHzʱ��
reg         nRst_tb;           // ��λ�ź�
reg         McBSPFSR_tb;       // ֡ͬ���ź�
reg         McBSPDR_tb;        // ������������
wire [9:0]  outData_tb;        // �������
wire        outDataEn_tb;      // �������ʹ��
wire        wrAFrameDataOkFlag_tb;  // ����д����ɱ�־
wire        wrEncContinue_tb;      // ��������ź�
wire        McBSPClkR_tb;

//-------------------------
// ʵ��������ģ��
//-------------------------
UlChannelDataControl_final uut (
    .interfaceClk(interfaceClk_tb),
    .outClk(outClk_tb),
    .nRst(nRst_tb),
    .McBSPFSR(McBSPFSR_tb),
    .McBSPDR(McBSPDR_tb),
    .outData(outData_tb),
    .outDataEn(outDataEn_tb),
    .wrAFrameDataOkFlag(wrAFrameDataOkFlag_tb),
    .wrEncContinue(wrEncContinue_tb),
    .McBSPClkR(McBSPClkR_tb)
);


//-------------------------
// ����10MHzʱ��
//-------------------------
initial begin
    interfaceClk_tb = 0;
    outClk_tb = 0; 
end

always begin
    #50 interfaceClk_tb = ~interfaceClk_tb;  // ����=100ns (10MHz)
end

// ���ϣ��outClk��interfaceClk����
always begin
    #25 outClk_tb = ~outClk_tb;  // �ɸ�����Ҫ����
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
    
    // ���Գ���: ����4��ͨ��֡��ÿ��131������
    send_4_frames();

    // ��������
    #1000;
    $finish;
end

//-------------------------------------------------
// ����4��ͨ��֡��ÿ��131������ (��һ���ݹ̶��������������)
//-------------------------------------------------
task send_4_frames;
    integer i, j;
    reg [15:0] data;
begin
    for (i = 0; i < 4; i = i + 1) begin
        // ���͵�һ���ݣ��̶�Ϊ 16'h4747
        send_16bit_data(16'h4747);
        
        // ����ʣ�µ�130���������
        for (j = 0; j < 130; j = j + 1) begin
            data = $random;  // �������16λ����
            send_16bit_data(data);
        end
        
        // ÿ������һ��֡�󣬵ȴ�2000ns (200��ʱ������)
        #2000;
    end
end
endtask

//-------------------------------------------------
// ����16λ�������� (FSR ����һ������)
//-------------------------------------------------
task send_16bit_data;
    input [15:0] data;
    integer i;
begin
    // Step 1: ������ FSR �ź� 1 ������
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

endmodule





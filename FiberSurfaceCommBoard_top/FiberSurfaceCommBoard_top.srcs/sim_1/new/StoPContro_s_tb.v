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

    reg CLK_100MHZ_t; // ?40Mhz?ʱ���ź�
    reg CLK_10MHZ_t;            // 10MHzʱ������
    reg UpSig_RClk_t;
    reg nRst_t; // ��λ�ź�
    reg [9:0] UpSig_ROut_t; // ���͵�����
    reg [6:0] count; // ���ʹ���������
    reg UpSig_nLock_t;
    wire sync_success_t;

StoPControl_s tb1(
    .CLK_100MHZ(CLK_100MHZ_t),           // 100MHzʱ������
    .CLK_10MHZ(CLK_10MHZ_t),            // 10MHzʱ������
    .nRst(nRst_t),                 // �͵�ƽ��Ч��λ�ź�
    .UpSig_RClk(UpSig_RClk_t),         // ���Դ���ת�����Ļָ�ʱ��
    .UpSig_nLock(UpSig_nLock_t),        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    .UpSig_ROut(UpSig_ROut_t),   // ����ת��������� 10 λ����
    .sync_success(sync_success_t)         // ͬ���ɹ���־

    ); 
    // ʱ�����ɣ�����200ns���������غ��½��ؼ��100ns
    always begin
        #50 CLK_10MHZ_t = ~CLK_10MHZ_t; // ÿ50ns��תһ��ʱ��
        end

always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // ÿ12ns��תһ��ʱ��40Mhz
    end

always begin
        #50 UpSig_RClk_t = ~UpSig_RClk_t; // ÿ50ns��תһ��ʱ��
    end

    // ���������߼�����ʱ���½��ط�������
    always @(negedge UpSig_RClk_t or negedge nRst_t) begin
        if (!nRst_t) begin
            count <= 0;
            UpSig_ROut_t <= 10'b0;
        end else begin
            if (count < 10) begin
                // ǰ10�η���10'b10010_00101
                UpSig_ROut_t <= 10'b10010_00101;
            end else if (count < 20) begin
                // ��������10�η���10'b00000_11111
                UpSig_ROut_t <= 10'b00000_11111;
            end else if (count < 30) begin
                // ��������10�η���10'b10010_00101
                UpSig_ROut_t <= 10'b10010_00101;
            end else if (count < 70) begin
                // ��������40�η���10'b00000_11111
                UpSig_ROut_t <= 10'b00000_11111;
            end else if (count == 70) begin
                // ���һ�η���10'b01111_11110
                UpSig_ROut_t <= 10'b10011_11100;
            end else begin
                UpSig_ROut_t <= 10'b11111_11111;
            end
            count <= count + 1; // ����������
        end
    end

    // ��ʼ��
    initial begin
        CLK_100MHZ_t = 0;
        CLK_10MHZ_t = 0;
        UpSig_RClk_t = 0;
        nRst_t = 0;
        UpSig_nLock_t = 1;
        #201 nRst_t = 1; // �ͷŸ�λ�ź�
        #8000 UpSig_nLock_t = 0;
        #3000 nRst_t = 0;
        #200;
        $stop;
    end

endmodule

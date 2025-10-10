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


module PtoSControl_tb;

    reg CLK_100MHZ_t; // ?40Mhz?ʱ���ź�
    reg CLK_10MHZ_t;            // 10MHzʱ������
    reg sync_success_t;
    reg [9:0] DownSig_Rout_t; // ���͵�����
    reg [6:0] count; // ���ʹ���������
    reg nRst_t; // ��λ�ź�
    wire UpSig_Sync1_t;
    wire UpSig_Sync2_t;
    wire SEND_LAST_FRAME_En_t;

PtoSControl tb1(
//    .CLK_100MHZ(CLK_100MHZ_t),           // 100MHzʱ������
    .CLK_10MHZ(CLK_10MHZ_t),            // 10MHzʱ������
    .nRst(nRst_t),                 // �͵�ƽ��Ч��λ�ź�
    .sync_success(sync_success_t),         // ���Դ���ת�����Ļָ�ʱ��
    .UpSig_Sync1(UpSig_Sync1_t),        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    .UpSig_Sync2(UpSig_Sync2_t),   // ����ת��������� 10 λ����
    .SEND_LAST_FRAME_En(SEND_LAST_FRAME_En_t)         // ͬ���ɹ���־

    ); 
    // ʱ�����ɣ�����200ns���������غ��½��ؼ��100ns
    always begin
        #50 CLK_10MHZ_t = ~CLK_10MHZ_t; // ÿ50ns��תһ��ʱ��
        end

always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // ÿ12ns��תһ��ʱ��40Mhz
    end

    // ���������߼�����ʱ���½��ط�������
    always @(negedge CLK_10MHZ_t or negedge nRst_t) begin
        if (!nRst_t) begin
            count <= 0;
            DownSig_Rout_t <= 10'b0;
        end else begin
            if (count < 10) begin
                // ǰ10�η���10'b10010_00101
                DownSig_Rout_t <= 10'b10010_00101;
            end else if (count < 20) begin
                // ��������10�η���10'b00000_11111
                DownSig_Rout_t <= 10'b00000_11111;
            end else if (count < 30) begin
                // ��������10�η���10'b10010_00101
                DownSig_Rout_t <= 10'b10010_00101;
            end else if (count < 70) begin
                // ��������40�η���10'b00000_11111
                DownSig_Rout_t <= 10'b00000_11111;
            end else if (count == 70) begin
                // ���һ�η���10'b01111_11110
                DownSig_Rout_t <= 10'b01111_11110;
            end else begin
                DownSig_Rout_t <= 10'b11111_11111;
            end
            count <= count + 1; // ����������
        end
    end

    // ��ʼ��
    initial begin
        CLK_100MHZ_t = 0;
        CLK_10MHZ_t = 0;
        nRst_t = 0;
        sync_success_t = 0;
        #201 nRst_t = 1; // �ͷŸ�λ�ź�
        #4000 sync_success_t = 1;
        #4000 nRst_t = 0;
        #200;
        $stop;
    end

endmodule

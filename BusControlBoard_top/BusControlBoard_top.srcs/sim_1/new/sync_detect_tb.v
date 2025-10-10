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

    reg CLK_100MHZ_t; // ʱ���ź�
    reg detected_negedge_t;
    reg DownSig_RClk_t;
    reg nRst_t; // ��λ�ź�
    reg [9:0] DownSig_Rout_t; // ���͵�����
    reg [6:0] count; // ���ʹ���������
    reg DownSig_nLock_t;
    wire sync_success_t;

sync_detect tb1(
    .CLK_100MHZ(CLK_100MHZ_t),           // ��40MHz�� ʱ������
    .nRst(nRst_t),                 // ��λ�źţ��͵�ƽ��Ч
    .detected_negedge(detected_negedge_t),         // ����ת�����Ļָ�ʱ�ӵ��½���
    .DownSig_Rout(DownSig_Rout_t),   // ����ת��������� 10 λ����
    .DownSig_nLock(DownSig_nLock_t),        // ����ת�����������ź�
    .sync_success(sync_success_t)          // ͬ���ɹ���־

    ); 
    // ʱ�����ɣ�����200ns���������غ��½��ؼ��100ns
    always begin
        #50 detected_negedge_t = ~detected_negedge_t; // ÿ50ns��תһ��ʱ��
        end

always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // ÿ12ns��תһ��ʱ��40Mhz
    end

always begin
        #50 DownSig_RClk_t = ~DownSig_RClk_t; // ÿ50ns��תһ��ʱ��
    end

    // ���������߼�����ʱ���½��ط�������
    always @(negedge DownSig_RClk_t or negedge nRst_t) begin
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
        detected_negedge_t = 0;
        CLK_100MHZ_t = 0;
        DownSig_RClk_t = 0;
        nRst_t = 0;
        DownSig_nLock_t = 1;
        #201 nRst_t = 1; // �ͷŸ�λ�ź�
        #8000 DownSig_nLock_t = 0;
        #3000 nRst_t = 0;
        #200;
        $stop;
    end

endmodule


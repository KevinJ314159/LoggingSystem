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

module SurfaceSPAndPSControl_s_tb;

    reg CLK_100MHZ_t; // ?40Mhz?ʱ���ź�
    reg CLK_10MHZ_t;            // 10MHzʱ������
    reg CLK_10MHZ_t_1;       // ���Դ���ת�����Ļָ�ʱ��
    reg DataInEn_t;     
    reg UpSig_nLock_t;
    reg [9:0] DataIn_t; // ���͵�����
    reg [9:0] UpSig_ROut_t; // ���͵�����
//    reg RX_Los_t;

    reg DataIn_t_send_flag;
    reg [10:0] count; // ���ʹ���������
    reg [6:0] count1; // ���ʹ���������
    reg nRst_t; // ��λ�ź�
    wire UpSig_RefClk_t;
    wire UpSig_RClk_RnF_t;
    wire UpSig_nPWRDN_t;
    wire [9:0] UlDataOut_t;
    wire DownSig_TClk_t;
    wire UpSig_REn_t;
    wire UlDataOutEn_t;
    wire DownSig_TClk_RnF_t;
    wire [9:0] DownSig_Din_t;
    wire DownSig_DEn_t;
    wire DownSig_nPWRDN_t;
    wire DownSig_Sync1_t;
    wire DownSig_Sync2_t;
    wire shakehand_success_t;
//    wire Tx_Disable_t;


SurfaceSPAndPSControl_s tb1(
    // ����˿�
    .CLK_100MHZ(CLK_100MHZ_t),         // ?40? MHz ʱ���ź�
    .CLK_10MHZ(CLK_10MHZ_t),          // 10 MHz ʱ���ź�
    .nRst(nRst_t),               // ��λ�źţ��͵�ƽ��Ч
    .DataInEn(DataInEn_t),           // ��������ʹ���ź�
    .DataIn(DataIn_t),       // 10 λ��������
    .UpSig_RClk(CLK_10MHZ_t_1),       // ���Դ���ת�����Ļָ�ʱ��
    .UpSig_nLock(UpSig_nLock_t),      // �����źţ��͵�ƽ��ʾ��������
    .UpSig_ROut(UpSig_ROut_t), // ���е�����ת����10λ�������
//    .RX_Los(RX_Los_t),             // �����źŶ�ʧָʾ

    // ����˿�
    .UpSig_RefClk(UpSig_RefClk_t),   // ���е�����ת���Ĳο�ʱ���ź�
    .UpSig_RClk_RnF(UpSig_RClk_RnF_t), // ���е�����ת���Ľ���ʱ�ӷ�ת�ź�
    .UpSig_nPWRDN(UpSig_nPWRDN_t),   // ����ת���ĵ����ź�
    .UpSig_REn(UpSig_REn_t),      // ����ת��������ʹ���ź�
    .UlDataOutEn(UlDataOutEn_t),      /* �������������Ч�źţ���̫���������ʲô�ù��ܺ�DoHole_sync_success����ͬ���ɹ�ָʾ�ź��غϣ���
                                     Ŀǰ���յ�����ͬ���뼰β֡�������ߣ�����Ϊ����������Ч��*/
    .UlDataOut(UlDataOut_t),  // ����10λ�������
    .DownSig_TClk(DownSig_TClk_t),       // ���е�����ת���Ĵ���ʱ���ź�
    .DownSig_TClk_RnF(DownSig_TClk_RnF_t),   // ����ת���Ĵ���ʱ�ӷ�ת�ź�
    .DownSig_Din(DownSig_Din_t),  // �ṩ������ת������10λ����
    .DownSig_DEn(DownSig_DEn_t),        // �����������е�����ת��������ʹ���ź�
    .DownSig_nPWRDN(DownSig_nPWRDN_t),     // ����ת�����ĵ����ź�
    .DownSig_Sync1(DownSig_Sync1_t),      // ����ת������ͬ���ź�1
    .DownSig_Sync2(DownSig_Sync2_t),      // ����ת������ͬ���ź�2
    .shakehand_success(shakehand_success_t) // ����ͬ���ɹ�ָʾ�ź�(Ŀǰ�ھ��·���ͬ��β֡�����빤��״̬�����Ϊ���ͬ��)
//    .Tx_Disable(Tx_Disable_t)        // ���ͽ����ź�
);
/*
(
    // ����˿�
    input CLK_100MHZ,         // 100/40 MHz ʱ���ź�
    input CLK_10MHZ,          // 10 MHz ʱ���ź�
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    input DataInEn,           //���Ե�������RAM��ģ��� ��������ʹ���ź�
    input [9:0] DataIn,       //���Ե�������RAM��ģ��� 10 λ��������
    input UpSig_RClk ,       // ���Դ���ת�����Ļָ�ʱ��
    input UpSig_nLock,      // �����źţ��͵�ƽ��ʾ��������
    input [9:0] UpSig_ROut, // ���е�����ת����10λ�������
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)

    // ����˿�
    output wire UpSig_RefClk,   // ���е�����ת���Ĳο�ʱ���ź�
    output reg UpSig_RClk_RnF, // ���е�����ת���Ľ���ʱ�ӷ�ת�ź�
    output reg UpSig_nPWRDN,   // ����ת���ĵ����ź�
    output reg UpSig_REn,      // ����ת��������ʹ���ź�
    output reg UlDataOutEn,       �������������Ч�źţ���̫���������ʲô�ù��ܺ�DoHole_sync_success����ͬ���ɹ�ָʾ�ź��غϣ���
//                                     Ŀǰ���յ�����ͬ���뼰β֡�������ߣ�����Ϊ����������Ч��
    output wire [9:0] UlDataOut,  // ����10λ�������
    output wire DownSig_TClk,       // ���е�����ת���Ĵ���ʱ���ź�
    output reg DownSig_TClk_RnF,   // ����ת���Ĵ���ʱ�ӷ�ת�ź�
    output reg [9:0] DownSig_Din,  // �ṩ������ת������10λ����
    output reg DownSig_DEn,        // �����������е�����ת��������ʹ���ź�
    output reg DownSig_nPWRDN,     // ����ת�����ĵ����ź� �ź�Ϊ0ʱ������ת���������DownSig_ROut�������״̬��
    output wire DownSig_Sync1,      // ����ת������ͬ���ź�1
    output wire DownSig_Sync2,      // ����ת������ͬ���ź�2
    output reg shakehand_success // ����ͬ���ɹ�ָʾ�ź�(Ŀǰ�ھ��·���ͬ��β֡�����빤��״̬�����Ϊ���ͬ��)
//    output reg Tx_Disable        // ���ͽ����ź�
//    output reg DownSig_TDIS        // ��Ҫȷ�ϴ˽ӿ���;

);*/
    // ʱ�����ɣ�����200ns���������غ��½��ؼ��100ns
    always begin
        #50 CLK_10MHZ_t = ~CLK_10MHZ_t; // ÿ50ns��תһ��ʱ��
        #50 CLK_10MHZ_t_1 = ~CLK_10MHZ_t_1;
        end


always begin
        #12 CLK_100MHZ_t = ~CLK_100MHZ_t; // ÿ12ns��תһ��ʱ��40Mhz
    end

    //assign #15 DownSig_RClk_t = CLK_10MHZ_t;  // �ӳ�ģ��⴮��PLL��ɵ���λ�ӳ�


    // ���������߼�����ʱ���½��ط�������
    always @(negedge CLK_10MHZ_t_1 or negedge nRst_t) begin
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

            end else if (count == 111) begin
                UpSig_ROut_t <= 10'b10100_00111;
                // ����10'h287
            end else if (count == 112) begin
                UpSig_ROut_t <= 10'b10100_00111;
                // ����10'h287
            end else if (count < 120) begin
                UpSig_ROut_t <= 110'b11111_00111;

            end else if (count < 130) begin
                UpSig_ROut_t <= 10'b11111_01111;

            end else if (count < 150) begin
                UpSig_ROut_t <= 10'b11111_11111;

                end else 
                UpSig_ROut_t <= 10'b11111_00000;

            count <= count + 1; // ����������
        end
    end

    // ���������߼�����ʱ���½��ط�������
    always @(posedge CLK_10MHZ_t or negedge nRst_t) begin
        if (!nRst_t) begin
            count1 <= 0;
            DataIn_t <= 10'b0;
        end else if(DataIn_t_send_flag) begin
            if (count1 < 10) begin
                // ǰ10�η���10'b10010_00101
                DataIn_t <= 10'b10000_00000;
            end else if (count1 < 20) begin
                // ��������10�η���10'b00000_11111
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
                // ��������40�η���10'b00000_11111
                DataIn_t <= 10'b11110_00000;
            end else if (count1 == 70) begin
                // ���һ�η���10'b01111_11110
                DataIn_t <= 10'b11110_00000;
            end else begin
                DataIn_t <= 10'b11111_00000;
            end
            count1 <= count1 + 1; // ����������
        end
    end


    // ��ʼ��
    initial begin
        CLK_100MHZ_t = 0;
        CLK_10MHZ_t_1 = 0;
        CLK_10MHZ_t = 0;
        nRst_t = 0;
        DataInEn_t = 1;
//        RX_Los_t = 0;
        UpSig_nLock_t = 0;
        DataIn_t_send_flag = 0;
        #201 nRst_t = 1; // �ͷŸ�λ�ź�
        #15000 DataIn_t_send_flag = 1;
        #25000 
        #400;
        nRst_t = 0;
        #400
        $stop;
    end

endmodule
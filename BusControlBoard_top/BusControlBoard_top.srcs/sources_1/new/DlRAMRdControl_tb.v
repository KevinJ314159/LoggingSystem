`timescale 1ns / 1ps

module DlRAMRdControl_tb;

    // �����ź�
    reg clk;
    reg nRst;
    reg bus_state;
    reg DlDataRevEnable;
    reg ABitSendOk;
    reg [7:0] decodedData_8bit;
    reg send_data;
    reg [1:0] DlRAM_wr_state;

    // ����ź�
    wire [1:0] DlRAM_rd_state;
    wire rdRAMEn;
    wire [6:0] rdRAMAddr;
    wire [7:0] rdDataOut;
    wire rdDataOutEn;
    wire send_req;

    // ʵ����������ģ�飨UUT��
    DlRAMRdControl uut (
        .clk(clk),
        .nRst(nRst),
        .bus_state(bus_state),
        .DlDataRevEnable(DlDataRevEnable),
        .ABitSendOk(ABitSendOk),
        .decodedData_8bit(decodedData_8bit),
        .send_data(send_data),
        .DlRAM_wr_state(DlRAM_wr_state),
        .DlRAM_rd_state(DlRAM_rd_state),
        .rdRAMEn(rdRAMEn),
        .rdRAMAddr(rdRAMAddr),
        .rdDataOut(rdDataOut),
        .rdDataOutEn(rdDataOutEn),
        .send_req(send_req)
    );

    // ʱ�����ɣ�10 MHz ʱ�ӣ�
    always begin
        #50 clk = ~clk;  // 10 MHz ʱ��Ƶ�ʣ�ÿ 50ns ��תһ��
    end

    // ���Լ����ź�
    initial begin
        // ��ʼ�������ź�
        clk = 0;
        nRst = 0;
        bus_state = 0;
        DlDataRevEnable = 0;
        ABitSendOk = 0;
        decodedData_8bit = 8'd0;
        send_data = 0;
        DlRAM_wr_state = 2'b00;

        // ʩ�Ӹ�λ�ź�
        #200;
        nRst = 1; // �ͷŸ�λ�ź�

        // ���� ACK ���͹���
        // ���� ACK ����
   //     ;  // ����ʱ������Ϊ50ns��ԭ����10ns�ӳ��޸�Ϊ20ns
        DlDataRevEnable = 1; // ģ�� DlDataRevEnable �ź�
//        #20;  // ��ʱΪ20ns
//        DlDataRevEnable = 0; // ģ�� DlDataRevEnable ȡ������
        
        // ����ʱ����� ACK ����
  //      #200;  // �޸�Ϊ200ns���൱��4��ʱ������
  //      ABitSendOk = 1; // ģ��ÿ�γɹ�����һ���ֽ�
        #20;  // 20ns ��ʱ

        // ��� ACK ����
        // ���� 10 �����ڵ� ACK ��������
    //    #20;  // 20ns ��ʱ
      //  ABitSendOk = 0; // ��ɷ��ͺ�ֹͣ

        // ��֤ `send_req` �ź��Ƿ����ʵ���ʱ��������
        // ���Ҽ�� `rdDataOut` �Ƿ�����ȷ�� ACK ����

        // ��������
        #500;  // ��ʱ 100ns����֤�������㹻ʱ��鿴���
        $stop;  // ֹͣ����
    end

endmodule

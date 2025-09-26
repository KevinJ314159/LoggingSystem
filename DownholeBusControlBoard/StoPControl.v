/*1.��ģ�鸺���ڽ⴮���ָ�ʱ���½��ض�ȡ�źţ����������յ�30֡ͬ���룬�����յ�1026֡ͬ����֮��
��֡β���ҽ⴮��������������ʱ�ӡ�LOCK�ź�����ʱ����PtoSControlģ�鷢��ͬ���ɹ���־*/
/*2.ͬ���ɹ���־���ߺ󳤸�*/
module StoPControl(
//    input RX_Los,
//    input CLK_100MHZ,           // 100MHzʱ������
//    input CLK_10MHZ,            // 10MHzʱ������
    input nRst,                 // �͵�ƽ��Ч��λ�ź�
    input DownSig_RClk,         // ���Դ���ת�����Ļָ�ʱ��
    input DownSig_nLock,        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    input [9:0] DownSig_Rout,   // ����ת��������� 10 λ����
    output sync_success,         // ͬ���ɹ���־
    output reg [9:0] DlDataOut,    // ������RAM������
    output reg DlDataOutEn      // �������������Ч�źţ�������ͨ��֡������
);

    // �½��ؼ���ź�
//    wire negedge_detected;        // ��edge_detectģ���������ʾ�Ƿ��⵽�½���

/*    // ʵ����edge_detectģ��
    edge_detect edge_detect_instance (
        .DownSig_RClk(DownSig_RClk),    // ���Խ⴮���Ļָ�ʱ��
        .CLK_100MHZ(CLK_100MHZ),        // 100MHzʱ��
        .nRst(nRst)                    // ��λ�źţ��͵�ƽ��Ч
//        .negedge_detected(negedge_detected) // �½��ؼ���־
    );*/
    reg [5:0] hold_counter;
    reg [1:0] detect_counter;
    reg detect_flag;

    // ʵ����sync_detectģ��
    sync_detect sync_detect_instance (
//        .RX_Los(RX_Los),
//        .CLK_100MHZ(CLK_100MHZ),         // 100MHzʱ������
        .DownSig_RClk(DownSig_RClk),
        .nRst(nRst),                     // ��λ�źţ��͵�ƽ��Ч
//        .detected_negedge(negedge_detected), // ��edge_detectģ����յ����½��ر�־
        .DownSig_Rout(DownSig_Rout),     // ����ת��������� 10 λ����
        .DownSig_nLock(DownSig_nLock),   // ����ת�����������ź�
        .sync_success(sync_success)      // ͬ���ɹ���־
    );

always @(posedge DownSig_RClk or negedge nRst) begin
    if (!nRst) begin
        // ��λ��ʼ��
        DlDataOutEn <= 1'b0;
        DlDataOut <= 10'd0;
        detect_counter <= 2'd0;
        detect_flag <= 1'b0;
        hold_counter <= 6'd0;
    end else begin
        // Ĭ��ֵ
//        UlDataOutEn <= 1'b0;

        // ����ͨ·
        DlDataOut <= DownSig_Rout;

                if ((detect_flag || (DownSig_Rout == 10'h287 || DownSig_Rout == 10'h2b8)) && hold_counter < 36) begin
                    DlDataOutEn <= 1;
                end else begin
                    DlDataOutEn <= 0;
                end

        // ͬ�������߼�
        if (DownSig_Rout == 10'h287 || DownSig_Rout == 10'h2b8) begin
            if (detect_counter < 2'd2)
                detect_counter <= detect_counter + 1'b1;
        end else begin
            detect_counter <= 2'd0;
        end

        // ��⵽����2��ͬ����
        if (detect_counter == 2'd1 && (DownSig_Rout == 10'h287 || DownSig_Rout == 10'h2b8)) begin
            detect_flag <= 1'b1;
            detect_counter <= 2'd0;
        end

        // ���ּ������߼�
        if (detect_flag) begin
            if (hold_counter < 6'd36) begin               // һ��ͨ��֡38���ֽ�
                hold_counter <= hold_counter + 1'b1;
//                UlDataOutEn <= 1'b1;  // ������Ч�ź�
            end else begin
                hold_counter <= 6'd0;
                detect_flag <= 1'b0;
            end
        end
    end
end

endmodule

/*1.��ģ�鸺���ڽ⴮���ָ�ʱ���½��ض�ȡ�źţ����������յ�30֡ͬ���룬�����յ�1026֡ͬ����֮��
��֡β���ҽ⴮��������������ʱ�ӡ�LOCK�ź�����ʱ����PtoSControlģ�鷢��ͬ���ɹ���־*/
/*2.ͬ���ɹ���־���ߺ󳤸�*/
module StoPControl_s(
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)
//    input CLK_100MHZ,           // 100M/40M Hzʱ������
//    input CLK_10MHZ,            // 10MHzʱ������
    input nRst,                 // �͵�ƽ��Ч��λ�ź�
    input UpSig_RClk,         // ���Խ⴮���Ļָ�ʱ��
    input UpSig_nLock,        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    input [9:0] UpSig_ROut,   // ����ת��������� 10 λ����
    output sync_success,         // ͬ���ɹ���־
    output reg [9:0] UlDataOut,    // ������RAM������
    output reg UlDataOutEn      // �������������Ч�źţ�������ͨ��֡������
);

    // �½��ؼ���ź�
//    wire negedge_detected;        // ��edge_detectģ���������ʾ�Ƿ��⵽�½���

/*    // ʵ����edge_detectģ��
    edge_detect_s edge_detect_instance (
        .UpSig_RClk(UpSig_RClk),    // ���Խ⴮���Ļָ�ʱ��
        .CLK_100MHZ(CLK_100MHZ),        // 100MHzʱ��
        .nRst(nRst),                    // ��λ�źţ��͵�ƽ��Ч
        .negedge_detected(negedge_detected) // �½��ؼ���־
    );
*/

    reg [9:0] hold_counter;
    reg [1:0] detect_counter;
    reg detect_flag;

    // ʵ����sync_detectģ��
    sync_detect_s sync_detect_instance (
//        .RX_Los(RX_Los),
//        .CLK_100MHZ(CLK_100MHZ),         // 100MHzʱ������
        .nRst(nRst),                     // ��λ�źţ��͵�ƽ��Ч
        .UpSig_RClk (UpSig_RClk),
//        .detected_negedge(negedge_detected), // ��edge_detectģ����յ����½��ر�־
        .UpSig_ROut(UpSig_ROut),     // ����ת��������� 10 λ����
        .UpSig_nLock(UpSig_nLock),   // ����ת�����������ź�
        .sync_success(sync_success)      // ͬ���ɹ���־
    );

always @(posedge UpSig_RClk or negedge nRst) begin
    if (!nRst) begin
        // ��λ��ʼ��
        UlDataOutEn <= 1'b0;
        UlDataOut <= 10'd0;
        detect_counter <= 2'd0;
        detect_flag <= 1'b0;
        hold_counter <= 10'd0;
    end else begin
        // Ĭ��ֵ
//        UlDataOutEn <= 1'b0;

        // ����ͨ·
        UlDataOut <= UpSig_ROut;

                if ((detect_flag || (UpSig_ROut == 10'h287 || UpSig_ROut == 10'h2b8)) && hold_counter < 260) begin
                    UlDataOutEn <= 1;
                end else begin
                    UlDataOutEn <= 0;
                end

        // ͬ�������߼�
        if (UpSig_ROut == 10'h287 || UpSig_ROut == 10'h2b8) begin
            if (detect_counter < 2'd2)
                detect_counter <= detect_counter + 1'b1;
        end else begin
            detect_counter <= 2'd0;
        end

        // ��⵽����2��ͬ����
        if (detect_counter == 2'd1 && (UpSig_ROut == 10'h287 || UpSig_ROut == 10'h2b8)) begin
            detect_flag <= 1'b1;
            detect_counter <= 2'd0;
        end

        // ���ּ������߼�
        if (detect_flag) begin
            if (hold_counter < 10'd260) begin               // һ��ͨ��֡38���ֽ�
                hold_counter <= hold_counter + 1'b1;
//                UlDataOutEn <= 1'b1;  // ������Ч�ź�
            end else begin
                hold_counter <= 10'd0;
                detect_flag <= 1'b0;
            end
        end
    end
end

endmodule
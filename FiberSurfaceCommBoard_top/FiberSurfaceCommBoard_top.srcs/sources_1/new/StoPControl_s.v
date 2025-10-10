/*1.��ģ�鸺���ڽ⴮���ָ�ʱ���½��ض�ȡ�źţ����������յ�30֡ͬ���룬�����յ�1026֡ͬ����֮��
��֡β���ҽ⴮��������������ʱ�ӡ�LOCK�ź�����ʱ����PtoSControlģ�鷢��ͬ���ɹ���־*/
/*2.ͬ���ɹ���־���ߺ󳤸�*/
module StoPControl_s(
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)
    input CLK_100MHZ,           // 100M/40M Hzʱ������
    input CLK_10MHZ,            // 10MHzʱ������
    input nRst,                 // �͵�ƽ��Ч��λ�ź�
    input UpSig_RClk,         // ���Խ⴮���Ļָ�ʱ��
    input UpSig_nLock,        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    input [9:0] UpSig_ROut,   // ����ת��������� 10 λ����
    output sync_success         // ͬ���ɹ���־
);

    // �½��ؼ���ź�
    wire negedge_detected;        // ��edge_detectģ���������ʾ�Ƿ��⵽�½���

    // ʵ����edge_detectģ��
    edge_detect_s edge_detect_instance (
        .UpSig_RClk(UpSig_RClk),    // ���Խ⴮���Ļָ�ʱ��
        .CLK_100MHZ(CLK_100MHZ),        // 100MHzʱ��
        .nRst(nRst),                    // ��λ�źţ��͵�ƽ��Ч
        .negedge_detected(negedge_detected) // �½��ؼ���־
    );

    // ʵ����sync_detectģ��
    sync_detect_s sync_detect_instance (
//        .RX_Los(RX_Los),
        .CLK_100MHZ(CLK_100MHZ),         // 100MHzʱ������
        .nRst(nRst),                     // ��λ�źţ��͵�ƽ��Ч
        .detected_negedge(negedge_detected), // ��edge_detectģ����յ����½��ر�־
        .UpSig_ROut(UpSig_ROut),     // ����ת��������� 10 λ����
        .UpSig_nLock(UpSig_nLock),   // ����ת�����������ź�
        .sync_success(sync_success)      // ͬ���ɹ���־
    );

endmodule

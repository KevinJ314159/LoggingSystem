/*1.ģ�����ڼ��⴮���ָ�ʱ�ӵ��½��أ����ڶ���ģ��StoPControl�н��½��ؼ�⵽�źŷ��͸�sync_detectģ��*/
/*2.Ŀǰʹ����������*/
/*3.ʱ�� CLK_100MHZ ��Ҫȷ��Ƶ���Ƿ�Ϊ40Mhz*/

module edge_detect(
    input DownSig_RClk,       // ���Խ⴮���Ļָ�ʱ��
    input CLK_100MHZ,         // ?40MHz? ʱ��
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    output reg negedge_detected  // �½��ؼ���־
);
     reg pulse_r1, pulse_r2, pulse_r3;  // ������������ͬ��
    reg last_DownSig_RClk;    // ���ڲ�׽��ǰ��ǰһ��ʱ�ӵ�ֵ

    // �ഥ����ͬ�� (�ɼ�Ϊ 2 ��ͬ���������ӳ�)
    always @(posedge CLK_100MHZ or negedge nRst) begin
        if (!nRst) begin
            pulse_r1 <= 1'b0;
            pulse_r2 <= 1'b0;
            pulse_r3 <= 1'b0;
            last_DownSig_RClk <= 1'b0;
        end else begin
            pulse_r1 <= DownSig_RClk;  // ͬ���ָ�ʱ��
            pulse_r2 <= pulse_r1;      // �ڶ���ͬ��
            pulse_r3 <= pulse_r2;      // ������ͬ��
            last_DownSig_RClk <= DownSig_RClk;  // �洢��һ��ʱ�����ڵĻָ�ʱ��
        end
    end

    // ���ؼ���߼�
    always @(posedge CLK_100MHZ or negedge nRst) begin
        if (!nRst) begin
            negedge_detected <= 1'b0;  // ��λʱ�����־
        end else begin
            // ��⵽�½��ز�������������ź�
            if (~pulse_r2 & pulse_r3) begin
                negedge_detected <= 1'b1;  // ��⵽�½���
            end else begin
                negedge_detected <= 1'b0;  // Ĭ�����
            end
        end
    end
endmodule

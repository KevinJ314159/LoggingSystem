/*1.ģ�����ڼ��⴮���ָ�ʱ�ӵ��½��أ����ڶ���ģ��StoPControl�н��½��ؼ�⵽�źŷ��͸�sync_detectģ��*/
/*2.Ŀǰʹ����������*/
/*3.ʱ�� CLK_100MHZ ��Ҫȷ��Ƶ���Ƿ�Ϊ40Mhz*/

module Rs232clk_edge_detecter(
    input Rs232Clk,       // ���Խ⴮���Ļָ�ʱ��
    input CLK_10MHZ,         // 10MHz ʱ��
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    output reg Rs232ClkPosedge_detected  // 232������ʱ�������ؼ���־
);
     reg pulse_r1, pulse_r2, pulse_r3;  // ������������ͬ��
//    reg last_DownSig_RClk;    // ���ڲ�׽��ǰ��ǰһ��ʱ�ӵ�ֵ

    // �ഥ����ͬ�� (�ɼ�Ϊ 2 ��ͬ���������ӳ�)
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (!nRst) begin
            pulse_r1 <= 1'b0;
            pulse_r2 <= 1'b0;
            pulse_r3 <= 1'b0;
//            last_DownSig_RClk <= 1'b0;
        end else begin
            pulse_r1 <= Rs232Clk;  // ͬ���ָ�ʱ��
            pulse_r2 <= pulse_r1;      // �ڶ���ͬ��
            pulse_r3 <= pulse_r2;      // ������ͬ��
//            last_DownSig_RClk <= DownSig_RClk;  // �洢��һ��ʱ�����ڵĻָ�ʱ��
        end
    end

    // ���ؼ���߼�
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (!nRst) begin
            Rs232ClkPosedge_detected <= 1'b0;  // ��λʱ�����־
        end else begin
            // ��⵽�½��ز�������������ź�
            if (pulse_r2 & ~pulse_r3) begin
                Rs232ClkPosedge_detected <= 1'b1;  // ��⵽�½���
            end else begin
                Rs232ClkPosedge_detected <= 1'b0;  // Ĭ�����
            end
        end
    end
endmodule



/*         // ����߼������
assign pos_edge = pulse_r2 & ~pulse_r3;
assign neg_edge = ~pulse_r2 & pulse_r3; 
assign data_edge = pos_edge | neg_edge; 
*/


/*1.��ģ������20Mhz��10Mhzʱ��*/

module genClock(
    input ClkIn,        // ����ʱ���ź�
    input nRst,         // �첽��λ�źţ��͵�ƽ��Ч��
    output reg Clk20MHz, // 20MHzʱ���ź�
    output reg Clk10MHz  // 10MHzʱ���ź�
);

// ����������
reg Clk10MHzCnt; // ���ڿ���10MHzʱ���źŷ�ת��1λ������

// ʱ�����ɹ���
always @(posedge ClkIn or negedge nRst) begin
    if (!nRst) begin
        // �첽��λ
        Clk20MHz <= 0;
        Clk10MHz <= 0;
        Clk10MHzCnt <= 1'b0;
    end else begin
        // ����20MHzʱ���źţ�ÿ1��ClkIn���ڷ�תһ�Σ�
        Clk20MHz <= ~Clk20MHz;

        // ����10MHzʱ���źţ�ÿ2��ClkIn���ڷ�תһ�Σ�
        Clk10MHzCnt <= Clk10MHzCnt + 1;
        if (Clk10MHzCnt == 1'b1) begin
            Clk10MHz <= ~Clk10MHz;
        end
    end
end

endmodule

/*��ģ�����ڽ�McBSP�ӿ��յ���16bit��������ת��Ϊ8bit�������ݡ�*/

module McBSPDriver_16bTo8b (
    input interfaceClk,    // McBSP�ӿ�10Mhzʱ�ӣ�����DSP�Ĵ���ʱ�ӣ�
    input nRst,            // ����Ч��λ���첽��λ��
    input McBSPFSR,        // McBSP֡ͬ���źţ�ָʾ֡��ʼ��
    input McBSPDR,         // McBSP�����������루1-bit��
    output reg McBSPDataEn,// ����������Ч��־���ߵ�ƽ��Ч��
    output reg [7:0] McBSPData // �����8λ��������
);

//-------------------------
// �ڲ��Ĵ�������
//-------------------------
reg [3:0] bit_cnt;     // 4-bitλ��������0-15������
reg [15:0] shift_reg;  // 16λ��λ�Ĵ������洢���յĴ������ݣ�
reg frame_synced;      // ֡ͬ����־��1=���ڽ�������֡��

//-------------------------
// ���߼�����
//-------------------------
always @(negedge interfaceClk or negedge nRst) begin
    // ��λ��ʼ��
    if (!nRst) begin
        bit_cnt <= 4'd0;          
        shift_reg <= 16'h0;       
        McBSPDataEn <= 1'b0;      
        frame_synced <= 1'b0;     
        McBSPData <= 8'b0;
    end 
    // ��������ģʽ
    else begin
        McBSPDataEn <= 1'b0;  // Ĭ��������Ч
        
        // ֡ͬ����⣨�½��ش�����
        if (McBSPFSR && !frame_synced) begin
            frame_synced <= 1'b1; 
            bit_cnt <= 4'd0;      
        end
        
        // ���ݽ��ս׶�
        if (frame_synced) begin
            // ����������λ��MSB first��
            shift_reg <= {shift_reg[14:0], McBSPDR};  
            
            // λ����������
            bit_cnt <= bit_cnt + 1;  

            // ÿ����8λ���һ��
            if (bit_cnt == 4'd7) begin       // ����ǰ8λ
                McBSPData <= {shift_reg[6:0],McBSPDR}; // ȡ��8λ���Ƚ��յ�8λ��
                McBSPDataEn <= 1'b1;
            end
            else if (bit_cnt == 4'd15) begin // ���պ�8λ
                McBSPData <= {shift_reg[6:0],McBSPDR};  // ȡ��8λ������յ�8λ��
                McBSPDataEn <= 1'b1;
                frame_synced <= 1'b0;         // ����֡����
            end
        end
    end
end

endmodule
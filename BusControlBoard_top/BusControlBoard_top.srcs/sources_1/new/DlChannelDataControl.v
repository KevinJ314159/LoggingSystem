module DlChannelDataControl(
    input Clk10MHz,       // 10MHzʱ��
    input nRst,
    input validDataEn,        // �������Ծ��´�������ģ���DLDataOutEn�ź�,���ź�����ɵ��浽���µĴ���/�⴮��ͬ��������
    input [9:0] validData,         // �⴮��������DownSig_Rout�����ź�
    input DlDataRevEnable,     // �������Ծ��´�������ģ���DoHole_sync_success�źţ����ź��ھ���ģ�鷢��β֡������

    output outData         // ������RS232��������Ľ��������
);

    // �ź�����
    wire conditional_reset = DlDataRevEnable && nRst;

    wire send_req;
    wire [7:0] data_in;     // ��RAMRd����ת��������10BTo8B�������Ľ��������
    wire bus_state;         // ��RS232����ģ���ṩ������æ�ź�
    wire send_done;         // ��RS232����ģ���ṩ��һ�ֽڷ�����ɱ�־

    wire [1:0] DlRAM_rd_state;
    wire [6:0] wrDlRAMAddr;     // ��RAMWrģ���˫�˿�RAM��д��ַ
    wire [1:0] DlRAM_wr_state;
    wire DlDecodeContinue;
    wire [9:0] WrRAMData_in;          // ��RAMWrģ�������д��RAM������

    wire [7:0] decoded_8bit;        // ��10B/8B�����������8Bit��������ݣ�����RAMRdģ��ת��
    wire [9:0] RdRAMData_out;      // ��RAM������10λ���ݣ�ֱ�Ӹ���������������RAMRdģ��
    wire decoded_Data_Out_en;      // RAMRd�Ľ���������Ч�ź�

    wire [6:0]  rdRAMAddr;
    wire rdRAMEn;
    wire decode_en;     // ����������������Ч������������ʹ��
    wire decode_frame_en;   // ����������������Чʹ�ܣ���һ֡�ж�����

    
    // ��Ƶ������ 1MHz ʱ��
    reg [3:0] clk_div_counter;
    reg McBSPClk;

    always @(posedge Clk10MHz or negedge nRst) begin
        if (!nRst) begin
            clk_div_counter <= 0;
            McBSPClk <= 0;
        end else begin
            if (clk_div_counter == 4) begin  // 10MHz / 5 = 2MHz, ��ͨ����ת�õ� 1MHz
                clk_div_counter <= 0;
                McBSPClk <= ~McBSPClk;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    // RS232����ģ��ʵ����
    RS232Driver RS232Driver_instance(
        .clk(Clk10MHz),            // 10MHzʱ��
        .Rs232_clk(McBSPClk),       // 1MHzʱ�ӣ�ÿ�������ط���һ�� bit
        .rst_n(conditional_reset),          // �첽��λ������Ч
        .send_req(send_req),       // ���������ź�
        .data_in(data_in),        // �����͵� 8 λ����
    
        .tx_out(outData),         // ���з��������ߣ�����ʱΪ�ߵ�ƽ��
        .bus_state(bus_state),      // ����״̬��1 ��ʾæµ��0 ��ʾ����
        .send_done(send_done)       // ��������ź�
    );

    // д����ģ��ʵ����
    DlRAMWrControl DlRAMWrControl_instance(
        .clk(Clk10MHz),
        .nRst(conditional_reset),

        // ���� ���½⴮�� �� 10 λ���ݺ�ʹ��
        .inData(validData),
        .inDataEn(validDataEn),   // 10λ�����Чʱ����

        // ���Զ����������������д״̬�������Ŀ� RAM�������Ŀ��д����־��
        .DlRAM_rd_state(DlRAM_rd_state),

        // �����д RAM ��ַ
        .wrDlRAMAddr(wrDlRAMAddr),
        // �������ǰ���� RAM ��д״̬ (0=δд����1=д��)
        .DlRAM_wr_state(DlRAM_wr_state),  // ��д���Ƶ������ź�

        .DlDecodeContinue(DlDecodeContinue),  // ��ǰ�Ƿ���д����

        // �͸� 8b/10b ������������
        .DlDecoderData(WrRAMData_in)
    );

    // 10b/8b ������ʵ����
    decode_10bTo8b_new decode_10bTo8b_new_instance(
        .clk(Clk10MHz),              // ʱ���ź�
        .rst_n(conditional_reset),            // ��λ�ź�
        .decode_en(decode_frame_en),         // һ֡������Ч�źţ���һ֡�ж�����
        .data_10b_en(decode_en),
        .datain(RdRAMData_out),    // 10λ��������
        .dataout(decoded_8bit),  // 8λ�����������
        .dataout_en(decoded_Data_Out_en)    // ��������Ч�ź�
    );

    DualPortRAM_Dl DualPortRAM_Dl_instance(
        .clk_in(Clk10MHz),
        .clk_out(Clk10MHz),
        .waddr(wrDlRAMAddr),
        .wdata(WrRAMData_in),
        .wen(DlDecodeContinue),
        .raddr(rdRAMAddr),
        .rden(rdRAMEn),
        .rdata(RdRAMData_out)
    );

    DlRAMRdControl DlRAMRdControl_instance(
        .clk(Clk10MHz),
        .nRst(conditional_reset),
        .bus_state(bus_state),
//        .DlDataRevEnable(DlDataRevEnable),     // ���Ծ��´������Ƶĳɹ�ͬ���źţ�������浽����ͨ·����
        .ABitSendOk(send_done),          // ����RS232��һ�ֽڷ�����ɱ�־
        .decodedData_8bit(decoded_8bit),  // �������������������
        .send_data(decoded_Data_Out_en),   // ���Խ������������Ч�źţ���������RAM����ʱת����RS2323����

        // ����д���������Ŀ� RAM ��д��
        .DlRAM_wr_state(DlRAM_wr_state),

        // ���͸�д���������Ŀ� RAM �Ѷ���
        .DlRAM_rd_state(DlRAM_rd_state),

        // ���ڶ� RAM �Ľӿ�
        .rdRAMEn(rdRAMEn),       // ��ʹ��
        .rdRAMAddr(rdRAMAddr),     // ����ַ

        // ��������������ϲ������
        .rdDataOut(data_in),     // ��Rs232��8Bit����
        .rdDataOutEn(decode_en),    // ����������������Ч�ź�(��rdRAMEn�Ӻ�һ����)
        .decode_continue(decode_frame_en),
        .send_req(send_req)     // �ṩ��Rs232�ķ���������Ack_send�������������ߣ���������ȡRAM����ʱת�����Խ������������Ч�źż���
    );

endmodule
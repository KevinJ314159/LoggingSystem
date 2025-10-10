module TopModule(
    input clk,
    input nRst,
    input [7:0] data_in,    // McBSP ��������
    input data_in_en,       // ����ʹ��

    output [9:0] encoded_out,  // 8b/10b ������������
    output [9:0] ram_wd,       // д�� RAM ������
    output [9:0] ram_waddr,    // д�� RAM �ĵ�ַ
    output ram_wen,            // д�� RAM ��ʹ��
    output ram_wclk            // д�� RAM ��ʱ��
);

    // �ź�����
    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;
    wire wrRAMen;
    wire [9:0] encode10b;

    // д����ģ��ʵ����
    UlRAMWrControl u_wrCtrl(
        .clk(clk),
        .nRst(nRst),
        .inData(data_in),
        .inDataEn(data_in_en),
        .UlRAM_rd_state(2'b00),  // �˴�δ���������ģ��
        .wrUlRAMAddr(ram_waddr),
        .UlRAM_wr_state(),       // δ����
        .UlEncoderEn(wrEncEn),     // ���ʹ���ź�
        .UlEncodeContinue(wrEncContinue),
        .wrAFrameDataOkFlag(),
        .UlEncoderData(wrEncData)
    );

    // 8b/10b ������ʵ����
    encode_8bto10b u_encode(
        .clk(clk),
        .rst_n(nRst),
        .din_en(wrEncEn),       // ʹ���ź�
        .is_k(1'b0),            // ���� K ��֧�֣��ɹ̶�Ϊ 0
        .din_8b(wrEncData),     // ����� 8 λ����
        .dout_10b(encode10b),    // ����� 10 λ��������
        .dout_en(wrRAMen)
    );

    // �������� 10 λ���ݴ��ݵ� RAM
    assign ram_wd = encode10b;
    assign ram_wen = wrRAMen;
    assign ram_wclk = clk;  // д��ʱ��Ϊϵͳʱ��

    assign encoded_out = encode10b;

endmodule

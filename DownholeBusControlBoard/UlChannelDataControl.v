module UlChannelDataControl(
    input clk,
    input nRst,
    input [7:0] data_in,    // McBSP ��������
    input data_in_en,       // ����ʹ��

    output [9:0] outData ,
    output reg outDataEn,
    // ���Թ۲���output
    output wrAFrameDataOkFlag,
    output wrEncContinue
//    output [9:0] encoded_out,  // 8b/10b ������������
//    output [9:0] ram_wd,       // д�� RAM ������
//    output [9:0] ram_waddr,    // д�� RAM �ĵ�ַ
//    output ram_wen,            // д�� RAM ��ʹ��
//    output ram_wclk            // д�� RAM ��ʱ��
);

    // �ź�����
    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;
    wire wrRAMen;
    wire [1:0] UlRAM_wr_state;

    wire [9:0] encode10b;

//    wire [9:0] ram_wd;       // д�� RAM ������
    wire [9:0] ram_waddr;    // д�� RAM �ĵ�ַ(ֱ�ӷ���RAM)
    wire ram_wen;            // д�� RAM ��ʹ��
    wire ram_wclk;         // д�� RAM ��ʱ��

    wire [9:0] rdRAMAddr;
    wire rdRAMEn;
    wire [1:0] UlRAM_rd_state;

    // д����ģ��ʵ����
    UlRAMWrControl UlRAMWrControl_instance(
        .clk(clk),
        .nRst(nRst),
        .inData(data_in),
        .inDataEn(data_in_en),
        .UlRAM_rd_state(UlRAM_rd_state),  // �˴�δ���������ģ��
        .wrUlRAMAddr(ram_waddr),  // д�� RAM �ĵ�ַ(ֱ�ӷ���RAM)
        .UlRAM_wr_state(UlRAM_wr_state),
        .UlEncoderEn(wrEncEn),     // ���ʹ���ź�
        .UlEncodeContinue(wrEncContinue),
        .wrAFrameDataOkFlag(wrAFrameDataOkFlag),
        .UlEncoderData(wrEncData)
    );

    // 8b/10b ������ʵ����
    encode_8bto10b encode_8bto10b_instance(
        .clk(clk),
        .rst_n(nRst),
        .din_en(wrEncEn),       // ʹ���ź�
        .is_k(1'b0),            // ���� K ��֧�֣��ɹ̶�Ϊ 0
        .din_8b(wrEncData),     // ����� 8 λ����
        .dout_10b(encode10b),    // ����� 10 λ��������
        .dout_en(wrRAMen)
    );

    DualPortRAM DualPortRAM_instance(
        .clk(clk),
        .waddr(ram_waddr),
        .wdata(encode10b),
        .wen(wrRAMen),
        .raddr(rdRAMAddr),
        .rden(rdRAMEn),
        .rdata(outData)
    );

/*        UlRAM_1024B_PP UlRAM_1024B_PP_instance(
        .WCLK(clk),
        .RCLK(clk),
        .WADDR(ram_waddr),
        .WD(encode10b),
        .WEN(wrRAMen),
        .RADDR(rdRAMAddr),
        .REN(rdRAMEn),
        .RD(outData)
    );
*/
    UlRAMRdControl UlRAMRdControl_instance(
        .clk(clk),
        .nRst(nRst),
        .UlRAM_wr_state(UlRAM_wr_state),
        .UlRAM_rd_state(UlRAM_rd_state),
        .rdRAMEn(rdRAMEn),
        .rdRAMAddr(rdRAMAddr),
//        .ramDataIn()
        .rdDataOutEn(rdRAMEn)
        );
    // �������� 10 λ���ݴ��ݵ� RAM
//    assign ram_wd = encode10b;
//    assign ram_wen = wrRAMen;
//    assign ram_wclk = clk;  // д��ʱ��Ϊϵͳʱ��

//    assign encoded_out = encode10b;
always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        outDataEn <= 0;
    end else 
        outDataEn <= rdRAMEn;
    end
    
endmodule

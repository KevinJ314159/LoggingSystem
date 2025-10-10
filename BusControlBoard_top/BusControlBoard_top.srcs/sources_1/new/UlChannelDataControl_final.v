

module UlChannelDataControl_final(
    input DlDataRevEnable,
    input interfaceClk,
    input outClk,       // 10Mhzʱ��
    input nRst,
    input McBSPFSR,        // McBSP֡ͬ���źţ�ָʾ֡��ʼ��
    input McBSPDR,         // McBSP�����������루1-bit��
//    input [7:0] data_in,    // McBSP ��������
//    input data_in_en,       // ����ʹ��

    output [9:0] outData ,
    output reg outDataEn,
    // ���Թ۲���output
    output wrAFrameDataOkFlag,
//    output wrEncContinue,
    output wire McBSPClkR
//    output [9:0] encoded_out,  // 8b/10b ������������
//    output [9:0] ram_wd,       // д�� RAM ������
//    output [9:0] ram_waddr,    // д�� RAM �ĵ�ַ
//    output ram_wen,            // д�� RAM ��ʹ��
//    output ram_wclk            // д�� RAM ��ʱ��
);

assign McBSPClkR = interfaceClk;

    // �ź�����
    wire conditional_reset = DlDataRevEnable && nRst;

    wire data_in_en;       // 16b to 8 b ���ʹ������ʹ��
    wire [7:0] data_in;    // 16b to 8 b �����8Bit����

    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;     // ���ź�Ϊһ��ͨ��֡(262B)�����ߵı���ʹ���ź�
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


    McBSPDriver_16bTo8b McBSPDriver_16bTo8b_instance(
        .interfaceClk(interfaceClk),    // McBSP�ӿ�10Mhzʱ�ӣ�����DSP�Ĵ���ʱ�ӣ�
        .nRst(conditional_reset),            // ����Ч��λ���첽��λ��
        .McBSPFSR(McBSPFSR),        // McBSP֡ͬ���źţ�ָʾ֡��ʼ��
        .McBSPDR(McBSPDR),         // McBSP�����������루1-bit��
        .McBSPDataEn(data_in_en),// ����������Ч��־���ߵ�ƽ��Ч��
        .McBSPData(data_in) // �����8λ��������)
    );

    // д����ģ��ʵ����
    UlRAMWrControl UlRAMWrControl_instance(
        .clk(interfaceClk),
        .nRst(conditional_reset),
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
    encode_8bTo10b_new encode_8bTo10b_new_instance(
        .clk(interfaceClk),
        .rst_n(conditional_reset),
        .encode_en(wrEncContinue),       // ʹ���ź�
        .encode_continue(wrEncEn),
//        .is_k(1'b1),            // ���� K ��֧�֣��ɹ̶�Ϊ 0����������ģ�
//        .din_8b(wrEncData),     // ����� 8 λ����
        .data_8b(wrEncData),
        .data_10b(encode10b),    // ����� 10 λ��������
        .data_10b_en(wrRAMen)
    );

    DualPortRAM DualPortRAM_instance(
        .clk_in(interfaceClk),
        .clk_out(outClk),
        .waddr(ram_waddr),
        .wdata(encode10b),
        .wen(wrRAMen),
        .raddr(rdRAMAddr),
        .rden(rdRAMEn),
        .rdata(outData)
    );

    UlRAMRdControl UlRAMRdControl_instance(
        .clk(outClk),
        .nRst(conditional_reset),
        .UlRAM_wr_state(UlRAM_wr_state),
        .UlRAM_rd_state(UlRAM_rd_state),
        .rdRAMEn(rdRAMEn),
        .rdRAMAddr(rdRAMAddr)
//        .ramDataIn()
//        .rdDataOutEn(rdRAMEn)
        );
    // �������� 10 λ���ݴ��ݵ� RAM
//    assign ram_wd = encode10b;
//    assign ram_wen = wrRAMen;
//    assign ram_wclk = clk;  // д��ʱ��Ϊϵͳʱ��

//    assign encoded_out = encode10b;
always @(posedge outClk or negedge conditional_reset) begin
    if (!conditional_reset) begin
        outDataEn <= 0;
    end else 
        outDataEn <= rdRAMEn;
    end
    
endmodule

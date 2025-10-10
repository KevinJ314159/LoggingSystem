`timescale 1ns/1ps

module DlChannelDataControl_tb;

  //====================================
  // 1) �ź�����
  //====================================
  reg         Clk10MHz;
//  reg         McBSPClk;
  reg         nRst;
  reg         validDataEn;
  reg  DlDataRevEnable;
//  reg  [7:0]  inData;
//  reg         inDataEn;
//  reg  [1:0]  UlRAM_rd_state;
  reg  [7:0]  validData;

  wire [9:0]outData;
  wire outDataen;
  wire out;

//  wire [9:0]  wrUlRAMAddr;
//  wire [1:0]  UlRAM_wr_state;
//  wire        UlEncodeContinue;
//  wire        UlEncoderEn;
//  wire [7:0]  UlEncoderData;
//  wire        wrAFrameDataOkFlag;

  //====================================
  // 2) ��������ģ��
  //====================================
/*  UlRAMWrControl dut_wrCtrl (
    .clk                (clk),
    .nRst               (nRst),
    .inData             (inData),
    .inDataEn           (inDataEn),
    .UlRAM_rd_state     (UlRAM_rd_state),
    .wrUlRAMAddr        (wrUlRAMAddr),
    .UlRAM_wr_state     (UlRAM_wr_state),
    .UlEncodeContinue   (UlEncodeContinue),
    .UlEncoderEn        (UlEncoderEn),
    .UlEncoderData      (UlEncoderData),
    .wrAFrameDataOkFlag (wrAFrameDataOkFlag)
  );*/
encode_8bto10b encode_8bto10b_instance(
    .clk(Clk10MHz),
    .rst_n(nRst),
//    .encode_en()
    .din_en(validDataEn),
    .is_k(1'b1),
    .din_8b(validData),
    .dout_10b(outData),
    .dout_en(outDataen)
    );


DlChannelDataControl uut (
    .Clk10MHz(Clk10MHz),
    .nRst(nRst),
    .validDataEn(outDataen),
    .validData(outData),
    .DlDataRevEnable(DlDataRevEnable),
    .outData(out)
  );
  //====================================
  // 3) ���� 10MHz ʱ�� (���� 100ns)
  //====================================
  initial begin
    Clk10MHz = 1'b1;
    forever #50 Clk10MHz = ~Clk10MHz;  // ÿ50ns��ת => 100ns���� => 10MHz
  end

  initial begin
//    McBSPClk = 1'b1;
//    forever #4340 McBSPClk = ~McBSPClk;  // ÿ50ns��ת => 100ns���� => 10MHz
  end

  //====================================
  // 4) ����������
  //====================================
  initial begin
    // ��ʼ��
    nRst          = 1'b0;
//    inData        = 8'd0;
    validDataEn   = 1'b0;
    validData    = 10'd0;
    DlDataRevEnable  = 1'b0;
//    UlRAM_rd_state= 2'b00;

    // ��λһ��ʱ�� (3������)
    #300;  
    nRst = 1'b1;
    // �ٵȴ� 2������
    #200;

//    validDataEn <= 1'b1;

    #1000;
    DlDataRevEnable <= 1'b1;
    // 1) ��2����Ч�ֽ�(��ͬ��ͷ)�۲�д������
//    sendByte_8cycles_1pulse(8'h55);
//    sendByte_8cycles_1pulse(8'h12);
    #1000000;
    begin

    // 2) �������� 0x47 (���д����Ҫ�����ֽ� 0x47 �Ŵ���)
//    sendByte_8cycles_1pulse(8'h47);
//    sendByte_8cycles_1pulse(8'h47);

    // 3) �������� 8 ���ֽ�
//    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) ģ������������� RAM0
//    #1000;
//    UlRAM_rd_state = 2'b01;
//    #200;
//    UlRAM_rd_state = 2'b00;

    // 5) �ٷ����� 0x47 => д��һ֡
    validDataEn <= 1'b1;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);
    repeat(36) sendByte_8cycles_1pulse($random);
    #100
    validDataEn <= 1'b0;
    end

    #1000000;
    begin
    validDataEn <= 1'b1;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);
    repeat(36) sendByte_8cycles_1pulse($random);
    #100
    validDataEn <= 1'b0;
    end

     #1000000;
     begin
     validDataEn <= 1'b1;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);
    repeat(36) sendByte_8cycles_1pulse($random);
    #100
    validDataEn <= 1'b0;
    end

    #1000000;
    $stop;

  end

  //====================================
  // 5) ����ÿ�� 8bit �����������ϱ��� 8 ������,
  //    �� inDataEn ֻ�ڵ�һ������������1��(1��ʱ������).
  //====================================
  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
//    integer i;
    begin
      // ��һ���½��أ��� inDataEn=1, ��д�� inData
      @(posedge Clk10MHz);
      validData   <= dataInTask;
//      inDataEn <= 1'b1;

      // �ڶ����½��أ��������� inDataEn (ֻά��1������)
//      @(negedge clk);
//      inDataEn <= 1'b0;
      // ͬʱ inData ���ֲ���

      // �ٱ���ʣ��6���½���(�� inData �����ܹ�8������)
//      for(i=0; i<6; i=i+1) begin
//        @(negedge clk);
//      end

      // ��� 8 ���½��غ󣬲ŷ�����һ���ֽ�
      // (��ǰʱ�� inDataEn=0, inData ���ɱ���, ֱ����ʱ�л�)
    end
  endtask

endmodule

//-------------------------
/*DlChannelDataControl uut (
    .McBSPClk(McBSPClk),
    .Clk10MHz(Clk10MHz),
    .nRst(nRst),
    .validDataEn(validDataEn),
    .validData(validData),
    .DlDataRevEnable(DlDataRevEnable),
    .outData(outData)
);

endmodule
*/

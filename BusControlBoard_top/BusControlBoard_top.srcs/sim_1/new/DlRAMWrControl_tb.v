`timescale 1ns/1ps

module DlRAMWrControl_tb;

  //====================================
  // 1) �ź�����
  //====================================
  reg         clk;
  reg         nRst;
  reg  [9:0]  inData;
  reg         inDataEn;
  reg  [1:0]  DlRAM_rd_state;

  wire [6:0]  wrDlRAMAddr;
  wire [1:0]  DlRAM_wr_state;
  wire        DlDecodeContinue;
  wire [9:0]  DlDecoderData;
  wire        wrAFrameDataOkFlag;

  //====================================
  // 2) ��������ģ��
  //====================================
  DlRAMWrControl dut_wrCtrl (
    .clk                (clk),
    .nRst               (nRst),
    .inData             (inData),
    .inDataEn           (inDataEn),
    .DlRAM_rd_state     (DlRAM_rd_state),
    .wrDlRAMAddr        (wrDlRAMAddr),
    .DlRAM_wr_state     (DlRAM_wr_state),
    .DlDecodeContinue   (DlDecodeContinue),
    .DlDecoderData      (DlDecoderData),
    .wrAFrameDataOkFlag (wrAFrameDataOkFlag)
  );

  //====================================
  // 3) ���� 10MHz ʱ�� (���� 100ns)
  //====================================
  initial begin
    clk = 1'b0;
    forever #50 clk = ~clk;  // ÿ50ns��ת => 100ns���� => 10MHz
  end

  //====================================
  // 4) ����������
  //====================================
  initial begin
    // ��ʼ��
    nRst          = 1'b0;
    inData        = 10'd0;
    inDataEn      = 1'b0;
    DlRAM_rd_state= 2'b00;

    // ��λһ��ʱ�� (3������)
    #300;  
    nRst = 1'b1;

    // �ٵȴ� 2������
    #200;
    inDataEn = 1'b1;
    // 1) ��2����Ч�ֽ�(��ͬ��ͷ)�۲�д������
    sendByte_8cycles_1pulse(10'h55);
    sendByte_8cycles_1pulse(10'h12);

    // 2) �������� 0x47 (���д����Ҫ�����ֽ� 0x47 �Ŵ���)
    sendByte_8cycles_1pulse(10'h287);
    sendByte_8cycles_1pulse(10'h287);

    // 3) �������� 8 ���ֽ�
    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) ģ������������� RAM0
    #1000;
    DlRAM_rd_state = 2'b01;
    #200;
    DlRAM_rd_state = 2'b00;

    // 5) �ٷ����� 0x47 => д��һ֡
    sendByte_8cycles_1pulse(10'h287);
    sendByte_8cycles_1pulse(10'h287);
    repeat(8) sendByte_8cycles_1pulse($random);

    #2000;
    $stop;
  end

  //====================================
  // 5) ����ÿ�� 8bit �����������ϱ��� 8 ������,
  //    �� inDataEn ֻ�ڵ�һ������������1��(1��ʱ������).
  //====================================
  task sendByte_8cycles_1pulse(input [9:0] dataInTask);
    integer i;
    begin
      // ��һ���½��أ��� inDataEn=1, ��д�� inData
      @(negedge clk);
      inData   <= dataInTask;
      // inDataEn <= 1'b1;

      // �ڶ����½��أ��������� inDataEn (ֻά��1������)
    // @(negedge clk);
      // inDataEn <= 1'b0;
      // ͬʱ inData ���ֲ���

      // �ٱ���ʣ��6���½���(�� inData �����ܹ�8������)
      // for(i=0; i<6; i=i+1) begin
        // @(negedge clk);
      end

      // ��� 8 ���½��غ󣬲ŷ�����һ���ֽ�
      // (��ǰʱ�� inDataEn=0, inData ���ɱ���, ֱ����ʱ�л�)
 //   end
  endtask

endmodule

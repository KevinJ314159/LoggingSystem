`timescale 1ns/1ps

module UlChannelDataControl_w_rd_tb;

  // 1) �ź�����
      integer i;
  reg         clk;
  reg         nRst;
  reg  [7:0]  data_in;
  reg         data_in_en;

  wire [9:0]  outData;
  wire        outDataEn;
  wire        wrAFrameDataOkFlag;
  wire        wrEncContinue;

  // 2) �������ⶥ��ģ��
  UlChannelDataControl tb (
    .clk         (clk),
    .nRst        (nRst),
    .data_in     (data_in),
    .data_in_en  (data_in_en),

    .outData     (outData),
    .outDataEn   (outDataEn),

    // �۲�˿�
    .wrAFrameDataOkFlag(wrAFrameDataOkFlag),
    .wrEncContinue     (wrEncContinue)
  );

  // 3) ����10MHzʱ��
  initial begin
    clk = 1'b0;
    forever #50 clk = ~clk; // 100ns���� => 10MHz
  end

  // 4) ����������
  initial begin

    nRst       = 1'b0;
    data_in    = 8'd0;
    data_in_en = 1'b0;

    // ��λ300ns
    #300;
    nRst = 1'b1;
    // �ٵ�200ns
    #200;

    // ��ӡʱ���
    $display("----- Start sending frames at %t ----", $time);

    // ���� 4 ֡
    // ÿ֡= 2�ֽ�0x47 + 160�ֽ��������(��̶�)
    // sendOneFrame(160) => 
    //   -> sendByte_8cycles_1pulse(0x47)
    //   -> sendByte_8cycles_1pulse(0x47)
    //   -> repeat(160) ...

    for(i=0; i<4; i=i+1) begin
      sendOneFrame(260); 
      // ���Լ��һ��ʱ���ٷ���һ֡
      #2000;
    end

    #3000;
    $stop;
  end

  //----------------------------------------------------
  // ���񣺷��� 1 ֡ (2�ֽ� ͬ��ͷ + N�ֽ�����)
  //       ÿ���ֽ�ռ��8������, inDataEn=1ֻά��1��
  //----------------------------------------------------
  task sendOneFrame(input integer dataCount);
    integer i;
    begin
      // ͬ��ͷ 2�ֽ�
      sendByte_8cycles_1pulse(8'h47);
      sendByte_8cycles_1pulse(8'h47);

      // �ٷ��� dataCount ������
      for(i=0; i<dataCount; i=i+1) begin
        sendByte_8cycles_1pulse($random); 
      end
    end
  endtask

  //----------------------------------------------------
  // ���񣺵��ֽڣ�8���ڣ�inDataEn=1ֻά��1��
  //----------------------------------------------------
  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
    integer j;
    begin
      // ��һ���½��� => data_in_en=1
      @(negedge clk);
      data_in    <= dataInTask;
      data_in_en <= 1'b1;

      // �ڶ����½��� => data_in_en=0
      @(negedge clk);
      data_in_en <= 1'b0;

      // ����6���½��� => ���� data_in
      for(j=0; j<6; j=j+1) begin
        @(negedge clk);
      end
    end
  endtask

endmodule

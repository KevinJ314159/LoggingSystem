`timescale 1ns/1ps

module TopModule_tb;

  //----------------------------------------------------
  // 1) �ź�����
  //----------------------------------------------------
  reg         clk;
  reg         nRst;
  reg  [7:0]  data_in;
  reg         data_in_en;

  wire [9:0]  encoded_out;  // 8b/10b ������������
  wire [9:0]  ram_wd;       // д�� RAM ������
  wire [9:0]  ram_waddr;    // д�� RAM �ĵ�ַ
  wire        ram_wen;      // д�� RAM ��ʹ��
  wire        ram_wclk;     // д�� RAM ��ʱ��

  //----------------------------------------------------
  // 2) �������ⶥ��ģ�� TopModule
  //----------------------------------------------------
  TopModule dut_top (
    .clk         (clk),
    .nRst        (nRst),
    .data_in     (data_in),
    .data_in_en  (data_in_en),

    .encoded_out (encoded_out),
    .ram_wd      (ram_wd),
    .ram_waddr   (ram_waddr),
    .ram_wen     (ram_wen),
    .ram_wclk    (ram_wclk)
  );

  //----------------------------------------------------
  // 3) ���� 10MHz ʱ�� (���� 100ns)
  //----------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #50 clk = ~clk;  // ÿ50ns��ת => 100ns���� => 10MHz
  end

  //----------------------------------------------------
  // 4) ����������
  //----------------------------------------------------
  initial begin
    // ��ʼ��
    nRst       = 1'b0;
    data_in    = 8'd0;
    data_in_en = 1'b0;

    // ��λһ��ʱ�� (3������ => 300ns)
    #300;  
    nRst = 1'b1;
    // �ٵȴ� 2 ������ => 200ns
    #200;

    // 1) ��2����Ч�ֽ�(��ͬ��ͷ)�۲�ģ����Ϊ
    sendByte_8cycles_1pulse(8'h55);
    sendByte_8cycles_1pulse(8'h12);

    // 2) �������� 0x47 (��д���������ֽ� 0x47 �Ŵ���)
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);

    // 3) �������� 8 ������ֽ�
    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) �� 1000ns ģ���ⲿʱ��Ȼ���ٷ����� 0x47
    #1000;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);

    // �������� 8 ������ֽ�
    repeat(8) sendByte_8cycles_1pulse($random);

    #2000;
    $stop;
  end

  //----------------------------------------------------
  // 5) ����ÿ�� 8bit �����������ϱ��� 8 ������
  //    �� data_in_en ֻ�ڵ�һ������������1��
  //----------------------------------------------------
  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
    integer i;
    begin
      // ��һ���½��أ��� data_in_en=1, ��д�� data_in
      @(negedge clk);
      data_in    <= dataInTask;
      data_in_en <= 1'b1;

      // �ڶ����½��أ��������� data_in_en (ֻά��1������)
      @(negedge clk);
      data_in_en <= 1'b0;
      // ͬʱ data_in ���ֲ���

      // �ٱ���ʣ��6���½���(�� data_in �������ϳ����� 8 ������)
      for(i=0; i<6; i=i+1) begin
        @(negedge clk);
      end

      // ��� 8 ���½��غ󣬲ŷ�����һ���ֽ�
      // (��ǰʱ�� data_in_en=0, data_in ���ɱ���, ֱ����ʱ�л�)
    end
  endtask

endmodule

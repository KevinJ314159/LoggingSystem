`timescale 1ns/1ps

module UlChannelDataControl_w_rd_tb;

  // 1) 信号声明
      integer i;
  reg         clk;
  reg         nRst;
  reg  [7:0]  data_in;
  reg         data_in_en;

  wire [9:0]  outData;
  wire        outDataEn;
  wire        wrAFrameDataOkFlag;
  wire        wrEncContinue;

  // 2) 例化待测顶层模块
  UlChannelDataControl tb (
    .clk         (clk),
    .nRst        (nRst),
    .data_in     (data_in),
    .data_in_en  (data_in_en),

    .outData     (outData),
    .outDataEn   (outDataEn),

    // 观测端口
    .wrAFrameDataOkFlag(wrAFrameDataOkFlag),
    .wrEncContinue     (wrEncContinue)
  );

  // 3) 生成10MHz时钟
  initial begin
    clk = 1'b0;
    forever #50 clk = ~clk; // 100ns周期 => 10MHz
  end

  // 4) 主激励过程
  initial begin

    nRst       = 1'b0;
    data_in    = 8'd0;
    data_in_en = 1'b0;

    // 复位300ns
    #300;
    nRst = 1'b1;
    // 再等200ns
    #200;

    // 打印时间戳
    $display("----- Start sending frames at %t ----", $time);

    // 发送 4 帧
    // 每帧= 2字节0x47 + 160字节随机数据(或固定)
    // sendOneFrame(160) => 
    //   -> sendByte_8cycles_1pulse(0x47)
    //   -> sendByte_8cycles_1pulse(0x47)
    //   -> repeat(160) ...

    for(i=0; i<4; i=i+1) begin
      sendOneFrame(260); 
      // 可以间隔一段时间再发下一帧
      #2000;
    end

    #3000;
    $stop;
  end

  //----------------------------------------------------
  // 任务：发送 1 帧 (2字节 同步头 + N字节数据)
  //       每个字节占用8个周期, inDataEn=1只维持1拍
  //----------------------------------------------------
  task sendOneFrame(input integer dataCount);
    integer i;
    begin
      // 同步头 2字节
      sendByte_8cycles_1pulse(8'h47);
      sendByte_8cycles_1pulse(8'h47);

      // 再发送 dataCount 个数据
      for(i=0; i<dataCount; i=i+1) begin
        sendByte_8cycles_1pulse($random); 
      end
    end
  endtask

  //----------------------------------------------------
  // 任务：单字节：8周期；inDataEn=1只维持1拍
  //----------------------------------------------------
  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
    integer j;
    begin
      // 第一次下降沿 => data_in_en=1
      @(negedge clk);
      data_in    <= dataInTask;
      data_in_en <= 1'b1;

      // 第二个下降沿 => data_in_en=0
      @(negedge clk);
      data_in_en <= 1'b0;

      // 余下6个下降沿 => 保持 data_in
      for(j=0; j<6; j=j+1) begin
        @(negedge clk);
      end
    end
  endtask

endmodule

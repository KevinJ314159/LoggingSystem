`timescale 1ns/1ps

module DlChannelDataControl_tb;

  //====================================
  // 1) 信号声明
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
  // 2) 例化待测模块
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
  // 3) 生成 10MHz 时钟 (周期 100ns)
  //====================================
  initial begin
    Clk10MHz = 1'b1;
    forever #50 Clk10MHz = ~Clk10MHz;  // 每50ns翻转 => 100ns周期 => 10MHz
  end

  initial begin
//    McBSPClk = 1'b1;
//    forever #4340 McBSPClk = ~McBSPClk;  // 每50ns翻转 => 100ns周期 => 10MHz
  end

  //====================================
  // 4) 主激励过程
  //====================================
  initial begin
    // 初始化
    nRst          = 1'b0;
//    inData        = 8'd0;
    validDataEn   = 1'b0;
    validData    = 10'd0;
    DlDataRevEnable  = 1'b0;
//    UlRAM_rd_state= 2'b00;

    // 复位一段时间 (3个周期)
    #300;  
    nRst = 1'b1;
    // 再等待 2个周期
    #200;

//    validDataEn <= 1'b1;

    #1000;
    DlDataRevEnable <= 1'b1;
    // 1) 发2个无效字节(非同步头)观察写控制器
//    sendByte_8cycles_1pulse(8'h55);
//    sendByte_8cycles_1pulse(8'h12);
    #1000000;
    begin

    // 2) 连发两个 0x47 (如果写控需要两连字节 0x47 才触发)
//    sendByte_8cycles_1pulse(8'h47);
//    sendByte_8cycles_1pulse(8'h47);

    // 3) 继续发送 8 个字节
//    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) 模拟读控制器读完 RAM0
//    #1000;
//    UlRAM_rd_state = 2'b01;
//    #200;
//    UlRAM_rd_state = 2'b00;

    // 5) 再发两个 0x47 => 写下一帧
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
  // 5) 任务：每个 8bit 数据在总线上保持 8 个周期,
  //    但 inDataEn 只在第一个周期内拉高1拍(1个时钟周期).
  //====================================
  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
//    integer i;
    begin
      // 第一个下降沿：让 inDataEn=1, 并写入 inData
      @(posedge Clk10MHz);
      validData   <= dataInTask;
//      inDataEn <= 1'b1;

      // 第二个下降沿：立即拉低 inDataEn (只维持1个周期)
//      @(negedge clk);
//      inDataEn <= 1'b0;
      // 同时 inData 保持不变

      // 再保持剩余6个下降沿(让 inData 持续总共8个周期)
//      for(i=0; i<6; i=i+1) begin
//        @(negedge clk);
//      end

      // 完成 8 个下降沿后，才发送下一个字节
      // (当前时刻 inDataEn=0, inData 依旧保持, 直到此时切换)
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

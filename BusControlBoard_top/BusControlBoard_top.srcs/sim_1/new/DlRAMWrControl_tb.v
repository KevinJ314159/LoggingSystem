`timescale 1ns/1ps

module DlRAMWrControl_tb;

  //====================================
  // 1) 信号声明
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
  // 2) 例化待测模块
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
  // 3) 生成 10MHz 时钟 (周期 100ns)
  //====================================
  initial begin
    clk = 1'b0;
    forever #50 clk = ~clk;  // 每50ns翻转 => 100ns周期 => 10MHz
  end

  //====================================
  // 4) 主激励过程
  //====================================
  initial begin
    // 初始化
    nRst          = 1'b0;
    inData        = 10'd0;
    inDataEn      = 1'b0;
    DlRAM_rd_state= 2'b00;

    // 复位一段时间 (3个周期)
    #300;  
    nRst = 1'b1;

    // 再等待 2个周期
    #200;
    inDataEn = 1'b1;
    // 1) 发2个无效字节(非同步头)观察写控制器
    sendByte_8cycles_1pulse(10'h55);
    sendByte_8cycles_1pulse(10'h12);

    // 2) 连发两个 0x47 (如果写控需要两连字节 0x47 才触发)
    sendByte_8cycles_1pulse(10'h287);
    sendByte_8cycles_1pulse(10'h287);

    // 3) 继续发送 8 个字节
    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) 模拟读控制器读完 RAM0
    #1000;
    DlRAM_rd_state = 2'b01;
    #200;
    DlRAM_rd_state = 2'b00;

    // 5) 再发两个 0x47 => 写下一帧
    sendByte_8cycles_1pulse(10'h287);
    sendByte_8cycles_1pulse(10'h287);
    repeat(8) sendByte_8cycles_1pulse($random);

    #2000;
    $stop;
  end

  //====================================
  // 5) 任务：每个 8bit 数据在总线上保持 8 个周期,
  //    但 inDataEn 只在第一个周期内拉高1拍(1个时钟周期).
  //====================================
  task sendByte_8cycles_1pulse(input [9:0] dataInTask);
    integer i;
    begin
      // 第一个下降沿：让 inDataEn=1, 并写入 inData
      @(negedge clk);
      inData   <= dataInTask;
      // inDataEn <= 1'b1;

      // 第二个下降沿：立即拉低 inDataEn (只维持1个周期)
    // @(negedge clk);
      // inDataEn <= 1'b0;
      // 同时 inData 保持不变

      // 再保持剩余6个下降沿(让 inData 持续总共8个周期)
      // for(i=0; i<6; i=i+1) begin
        // @(negedge clk);
      end

      // 完成 8 个下降沿后，才发送下一个字节
      // (当前时刻 inDataEn=0, inData 依旧保持, 直到此时切换)
 //   end
  endtask

endmodule

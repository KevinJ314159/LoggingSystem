`timescale 1ns/1ps

module TopModule_tb;

  //----------------------------------------------------
  // 1) 信号声明
  //----------------------------------------------------
  reg         clk;
  reg         nRst;
  reg  [7:0]  data_in;
  reg         data_in_en;

  wire [9:0]  encoded_out;  // 8b/10b 编码后输出数据
  wire [9:0]  ram_wd;       // 写入 RAM 的数据
  wire [9:0]  ram_waddr;    // 写入 RAM 的地址
  wire        ram_wen;      // 写入 RAM 的使能
  wire        ram_wclk;     // 写入 RAM 的时钟

  //----------------------------------------------------
  // 2) 例化待测顶层模块 TopModule
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
  // 3) 生成 10MHz 时钟 (周期 100ns)
  //----------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #50 clk = ~clk;  // 每50ns翻转 => 100ns周期 => 10MHz
  end

  //----------------------------------------------------
  // 4) 主激励过程
  //----------------------------------------------------
  initial begin
    // 初始化
    nRst       = 1'b0;
    data_in    = 8'd0;
    data_in_en = 1'b0;

    // 复位一段时间 (3个周期 => 300ns)
    #300;  
    nRst = 1'b1;
    // 再等待 2 个周期 => 200ns
    #200;

    // 1) 发2个无效字节(非同步头)观察模块行为
    sendByte_8cycles_1pulse(8'h55);
    sendByte_8cycles_1pulse(8'h12);

    // 2) 连发两个 0x47 (若写控需两连字节 0x47 才触发)
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);

    // 3) 继续发送 8 个随机字节
    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) 等 1000ns 模拟外部时序，然后再发两连 0x47
    #1000;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);

    // 继续发送 8 个随机字节
    repeat(8) sendByte_8cycles_1pulse($random);

    #2000;
    $stop;
  end

  //----------------------------------------------------
  // 5) 任务：每个 8bit 数据在总线上保持 8 个周期
  //    但 data_in_en 只在第一个周期内拉高1拍
  //----------------------------------------------------
  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
    integer i;
    begin
      // 第一次下降沿：让 data_in_en=1, 并写入 data_in
      @(negedge clk);
      data_in    <= dataInTask;
      data_in_en <= 1'b1;

      // 第二个下降沿：立即拉低 data_in_en (只维持1个周期)
      @(negedge clk);
      data_in_en <= 1'b0;
      // 同时 data_in 保持不变

      // 再保持剩余6个下降沿(让 data_in 在总线上持续共 8 个周期)
      for(i=0; i<6; i=i+1) begin
        @(negedge clk);
      end

      // 完成 8 个下降沿后，才发送下一个字节
      // (当前时刻 data_in_en=0, data_in 依旧保持, 直到此时切换)
    end
  endtask

endmodule

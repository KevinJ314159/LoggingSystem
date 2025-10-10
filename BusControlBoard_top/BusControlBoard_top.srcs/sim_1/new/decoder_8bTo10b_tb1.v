module decoder_10bto8b_tb;

    // 定义信号
    reg clk;                // 时钟信号
    reg rst_n;              // 复位信号
    reg valid_in;           // 输入有效信号
    reg [9:0] din_10b;      // 10位输入数据
    wire [7:0] dout_8b;     // 8位输出数据
    wire valid_out;         // 输出有效信号

    // 连接解码模块
    decoder_10bto8b uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .din_10b(din_10b),
        .dout_8b(dout_8b),
        .valid_out(valid_out)
    );

    // 时钟生成，10 MHz 时钟，周期为 100ns
    always begin
        #50 clk = ~clk;  // 每 50ns 反转时钟，相当于 10MHz 时钟频率
    end

    // 复位生成
    initial begin
        rst_n = 0;
        #200 rst_n = 1;  // 复位 15ns 后解除
    end

    // 输入数据生成和 valid_in 信号控制
    initial begin
        // 初始化
        clk = 0;
        valid_in = 0;
        din_10b = 10'd0;

        // 等待复位完成
        #200;

        // 发送第一个待解码数据
        din_10b = 10'h287;  // 一个示例 10 位数据
        valid_in = 1;              // 拉高 valid_in
        #100 valid_in = 0;          // 拉低 valid_in

        // 等待 89200ns
        #89200;

        // 发送第二个待解码数据
        din_10b = 10'h0c5;  // 另一个示例 10 位数据
        valid_in = 1;              // 拉高 valid_in
        #100 valid_in = 0;          // 拉低 valid_in

        // 等待 89200ns
        #89200;

        // 发送第三个待解码数据
        din_10b = 10'b1111010100;  // 另一个示例 10 位数据
        valid_in = 1;              // 拉高 valid_in
        #100 valid_in = 0;          // 拉低 valid_in

        // 等待 89200ns
        #89200;

        // 结束模拟
        #300;
        $finish;
    end


endmodule
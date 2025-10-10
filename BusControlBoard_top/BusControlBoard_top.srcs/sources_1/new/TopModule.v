module TopModule(
    input clk,
    input nRst,
    input [7:0] data_in,    // McBSP 输入数据
    input data_in_en,       // 数据使能

    output [9:0] encoded_out,  // 8b/10b 编码后输出数据
    output [9:0] ram_wd,       // 写入 RAM 的数据
    output [9:0] ram_waddr,    // 写入 RAM 的地址
    output ram_wen,            // 写入 RAM 的使能
    output ram_wclk            // 写入 RAM 的时钟
);

    // 信号连接
    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;
    wire wrRAMen;
    wire [9:0] encode10b;

    // 写控制模块实例化
    UlRAMWrControl u_wrCtrl(
        .clk(clk),
        .nRst(nRst),
        .inData(data_in),
        .inDataEn(data_in_en),
        .UlRAM_rd_state(2'b00),  // 此处未接入读控制模块
        .wrUlRAMAddr(ram_waddr),
        .UlRAM_wr_state(),       // 未连接
        .UlEncoderEn(wrEncEn),     // 输出使能信号
        .UlEncodeContinue(wrEncContinue),
        .wrAFrameDataOkFlag(),
        .UlEncoderData(wrEncData)
    );

    // 8b/10b 编码器实例化
    encode_8bto10b u_encode(
        .clk(clk),
        .rst_n(nRst),
        .din_en(wrEncEn),       // 使能信号
        .is_k(1'b0),            // 若无 K 码支持，可固定为 0
        .din_8b(wrEncData),     // 输入的 8 位数据
        .dout_10b(encode10b),    // 输出的 10 位编码数据
        .dout_en(wrRAMen)
    );

    // 将编码后的 10 位数据传递到 RAM
    assign ram_wd = encode10b;
    assign ram_wen = wrRAMen;
    assign ram_wclk = clk;  // 写入时钟为系统时钟

    assign encoded_out = encode10b;

endmodule

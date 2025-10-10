module UlChannelDataControl(
    input clk,
    input nRst,
    input [7:0] data_in,    // McBSP 输入数据
    input data_in_en,       // 数据使能

    output [9:0] outData ,
    output reg outDataEn,
    // 测试观测用output
    output wrAFrameDataOkFlag,
    output wrEncContinue
//    output [9:0] encoded_out,  // 8b/10b 编码后输出数据
//    output [9:0] ram_wd,       // 写入 RAM 的数据
//    output [9:0] ram_waddr,    // 写入 RAM 的地址
//    output ram_wen,            // 写入 RAM 的使能
//    output ram_wclk            // 写入 RAM 的时钟
);

    // 信号连接
    wire [7:0] wrEncData;
    wire wrEncEn;
    wire wrEncContinue;
    wire wrRAMen;
    wire [1:0] UlRAM_wr_state;

    wire [9:0] encode10b;

//    wire [9:0] ram_wd;       // 写入 RAM 的数据
    wire [9:0] ram_waddr;    // 写入 RAM 的地址(直接发给RAM)
    wire ram_wen;            // 写入 RAM 的使能
    wire ram_wclk;         // 写入 RAM 的时钟

    wire [9:0] rdRAMAddr;
    wire rdRAMEn;
    wire [1:0] UlRAM_rd_state;

    // 写控制模块实例化
    UlRAMWrControl UlRAMWrControl_instance(
        .clk(clk),
        .nRst(nRst),
        .inData(data_in),
        .inDataEn(data_in_en),
        .UlRAM_rd_state(UlRAM_rd_state),  // 此处未接入读控制模块
        .wrUlRAMAddr(ram_waddr),  // 写入 RAM 的地址(直接发给RAM)
        .UlRAM_wr_state(UlRAM_wr_state),
        .UlEncoderEn(wrEncEn),     // 输出使能信号
        .UlEncodeContinue(wrEncContinue),
        .wrAFrameDataOkFlag(wrAFrameDataOkFlag),
        .UlEncoderData(wrEncData)
    );

    // 8b/10b 编码器实例化
    encode_8bto10b encode_8bto10b_instance(
        .clk(clk),
        .rst_n(nRst),
        .din_en(wrEncEn),       // 使能信号
        .is_k(1'b0),            // 若无 K 码支持，可固定为 0
        .din_8b(wrEncData),     // 输入的 8 位数据
        .dout_10b(encode10b),    // 输出的 10 位编码数据
        .dout_en(wrRAMen)
    );

    DualPortRAM DualPortRAM_instance(
        .clk(clk),
        .waddr(ram_waddr),
        .wdata(encode10b),
        .wen(wrRAMen),
        .raddr(rdRAMAddr),
        .rden(rdRAMEn),
        .rdata(outData)
    );

/*        UlRAM_1024B_PP UlRAM_1024B_PP_instance(
        .WCLK(clk),
        .RCLK(clk),
        .WADDR(ram_waddr),
        .WD(encode10b),
        .WEN(wrRAMen),
        .RADDR(rdRAMAddr),
        .REN(rdRAMEn),
        .RD(outData)
    );
*/
    UlRAMRdControl UlRAMRdControl_instance(
        .clk(clk),
        .nRst(nRst),
        .UlRAM_wr_state(UlRAM_wr_state),
        .UlRAM_rd_state(UlRAM_rd_state),
        .rdRAMEn(rdRAMEn),
        .rdRAMAddr(rdRAMAddr),
//        .ramDataIn()
        .rdDataOutEn(rdRAMEn)
        );
    // 将编码后的 10 位数据传递到 RAM
//    assign ram_wd = encode10b;
//    assign ram_wen = wrRAMen;
//    assign ram_wclk = clk;  // 写入时钟为系统时钟

//    assign encoded_out = encode10b;
always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        outDataEn <= 0;
    end else 
        outDataEn <= rdRAMEn;
    end
    
endmodule

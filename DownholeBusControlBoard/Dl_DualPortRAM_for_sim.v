module DualPortRAM_Dl(
    input         clk_in,
    input         clk_out,
    // 写端口
    input  [6:0]  waddr,
    input  [9:0]  wdata,
    input         wen,
    // 读端口
    input  [6:0]  raddr,
    input         rden,
    output reg [9:0] rdata
);
    // 简单模型：位宽10 存储深度设为128
    reg [9:0] mem [0:127];

    // 写操作（同步写）
    always @(posedge clk_in) begin
        if (wen)
            mem[waddr] <= wdata;
    end

    // 读操作（同步读）
    always @(posedge clk_out) begin
        if (rden)
            rdata <= mem[raddr];
        else
            rdata <= 10'd0;
    end
endmodule

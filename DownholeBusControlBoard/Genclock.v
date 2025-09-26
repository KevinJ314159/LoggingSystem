/*1.此模块生成20Mhz和10Mhz时钟*/

module genClock(
    input ClkIn,        // 输入时钟信号
    input nRst,         // 异步复位信号（低电平有效）
    output reg Clk20MHz, // 20MHz时钟信号
    output reg Clk10MHz  // 10MHz时钟信号
);

// 计数器声明
reg Clk10MHzCnt; // 用于控制10MHz时钟信号反转的1位计数器

// 时钟生成过程
always @(posedge ClkIn or negedge nRst) begin
    if (!nRst) begin
        // 异步复位
        Clk20MHz <= 0;
        Clk10MHz <= 0;
        Clk10MHzCnt <= 1'b0;
    end else begin
        // 生成20MHz时钟信号（每1个ClkIn周期反转一次）
        Clk20MHz <= ~Clk20MHz;

        // 生成10MHz时钟信号（每2个ClkIn周期反转一次）
        Clk10MHzCnt <= Clk10MHzCnt + 1;
        if (Clk10MHzCnt == 1'b1) begin
            Clk10MHz <= ~Clk10MHz;
        end
    end
end

endmodule

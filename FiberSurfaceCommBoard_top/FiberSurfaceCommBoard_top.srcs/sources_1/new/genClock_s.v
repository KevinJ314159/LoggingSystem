module genClock_s(
    input ClkIn,        // 输入时钟信号（40MHz）
    input nRst,         // 异步复位信号（低电平有效）
    output reg Clk20MHz, // 20MHz时钟信号
    output reg Clk10MHz, // 10MHz时钟信号
    output reg Clk500KHz // 500KHz时钟信号
);

// 计数器声明
reg Clk10MHzCnt;        // 控制10MHz时钟反转的1位计数器
reg [5:0] Clk500KHzCnt; // 控制500KHz时钟反转的6位计数器（需计数到39）

always @(posedge ClkIn or negedge nRst) begin
    if (!nRst) begin
        // 复位所有时钟和计数器
        Clk20MHz  <= 0;
        Clk10MHz  <= 0;
        Clk500KHz <= 0;
        Clk10MHzCnt <= 0;
        Clk500KHzCnt <= 0;
    end else begin
        // 生成20MHz时钟（每1个ClkIn周期反转一次）
        Clk20MHz <= ~Clk20MHz;

        // 生成10MHz时钟（每2个ClkIn周期反转一次）
        Clk10MHzCnt <= Clk10MHzCnt + 1;
        if (Clk10MHzCnt == 1) begin
            Clk10MHz <= ~Clk10MHz;
            Clk10MHzCnt <= 0;
        end

        // 生成500KHz时钟（每40个ClkIn周期反转一次）
        Clk500KHzCnt <= Clk500KHzCnt + 1;
        if (Clk500KHzCnt == 6'd39) begin // 40MHz / (40*2) = 500KHz
            Clk500KHz <= ~Clk500KHz;
            Clk500KHzCnt <= 0;
        end
    end
end

endmodule
/*1.模块用于检测解串器恢复时钟的下降沿，并在顶层模块StoPControl中将下降沿检测到信号发送给sync_detect模块*/
/*2.目前使用三拍消抖*/
/*3.时钟 CLK_100MHZ 需要确认频率是否为40Mhz*/

module Rs232clk_edge_detecter(
    input Rs232Clk,       // 来自解串器的恢复时钟
    input CLK_10MHZ,         // 10MHz 时钟
    input nRst,               // 复位信号，低电平有效
    output reg Rs232ClkPosedge_detected  // 232波特率时钟上升沿检测标志
);
     reg pulse_r1, pulse_r2, pulse_r3;  // 用三个触发器同步
//    reg last_DownSig_RClk;    // 用于捕捉当前和前一个时钟的值

    // 多触发器同步 (可简化为 2 级同步，减少延迟)
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (!nRst) begin
            pulse_r1 <= 1'b0;
            pulse_r2 <= 1'b0;
            pulse_r3 <= 1'b0;
//            last_DownSig_RClk <= 1'b0;
        end else begin
            pulse_r1 <= Rs232Clk;  // 同步恢复时钟
            pulse_r2 <= pulse_r1;      // 第二级同步
            pulse_r3 <= pulse_r2;      // 第三级同步
//            last_DownSig_RClk <= DownSig_RClk;  // 存储上一个时钟周期的恢复时钟
        end
    end

    // 边沿检测逻辑
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (!nRst) begin
            Rs232ClkPosedge_detected <= 1'b0;  // 复位时清除标志
        end else begin
            // 检测到下降沿并立即产生检测信号
            if (pulse_r2 & ~pulse_r3) begin
                Rs232ClkPosedge_detected <= 1'b1;  // 检测到下降沿
            end else begin
                Rs232ClkPosedge_detected <= 1'b0;  // 默认清除
            end
        end
    end
endmodule



/*         // 组合逻辑输出版
assign pos_edge = pulse_r2 & ~pulse_r3;
assign neg_edge = ~pulse_r2 & pulse_r3; 
assign data_edge = pos_edge | neg_edge; 
*/


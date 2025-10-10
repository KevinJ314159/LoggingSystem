`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/22 13:35:16
// Design Name: 
// Module Name: edge_detect_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module edge_detect_tb;

reg CLK_100MHZ_t;
reg nRst_t;
reg DownSig_RClk_t;
wire negedge_detected;

edge_detect tb1(
    .DownSig_RClk(DownSig_RClk_t),       // 来自解串器的恢复时钟
    .CLK_100MHZ(CLK_100MHZ_t),         // 40MHz? 时钟
    .nRst(nRst_t),               // 复位信号，低电平有效
    .negedge_detected(negedge_detected)  // 下降沿检测标志
);


initial 
    begin
CLK_100MHZ_t = 1;
DownSig_RClk_t = 0;
    end
always #12 CLK_100MHZ_t = ~CLK_100MHZ_t;
always #50 DownSig_RClk_t = ~DownSig_RClk_t;

initial begin

    nRst_t = 0;
    #201;
    nRst_t = 1;
    #1000;
    nRst_t = 0;
    #200;
    $stop;

end
endmodule

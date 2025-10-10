`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/20 01:27:45
// Design Name: 
// Module Name: Genclock_tb
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
module genClock_tb;


reg ClkIn_t;
reg nRst_t;
wire Clk20MHz_t;
wire Clk10MHz_t;

genClock tb_1(

    .ClkIn(ClkIn_t),        // 杈撳叆鏃堕挓淇″彿
    .nRst(nRst_t),         // 寮傛澶嶄綅淇″彿锛堜綆鐢靛钩鏈夋晥锛?
    .Clk20MHz(Clk20MHz_t), // 20MHz鏃堕挓淇″彿
    .Clk10MHz(Clk10MHz_t)  // 10MHz鏃堕挓淇″彿

    );


initial 
ClkIn_t = 1;
always #25 ClkIn_t = ~ClkIn_t;

initial begin

    nRst_t = 0;
    #201;
    nRst_t = 1;
    #800;
    nRst_t = 0;
    #200;
    $stop;

end


endmodule



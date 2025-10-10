`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
// 
// Create Date: 2025/02/02
// Design Name: 
// Module Name: UlChannelDataControl_final_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for UlChannelDataControl_final
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

/*
//-------------------------
// 信号定义
//-------------------------
reg         interfaceClk_tb;   // 10MHz时钟
reg         outClk_tb;         // 10MHz时钟
reg         nRst_tb;           // 复位信号
reg         McBSPFSR_tb;       // 帧同步信号
reg         McBSPDR_tb;        // 串行数据输入
wire [9:0]  outData_tb;        // 输出数据
wire        outDataEn_tb;      // 输出数据使能
wire        wrAFrameDataOkFlag_tb;  // 数据写入完成标志
wire        wrEncContinue_tb;      // 编码继续信号
*/

//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
// 
// Create Date: 2025/01/30 15:20:12
// Design Name: 
// Module Name: McBSPDriver_16bTo8b_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:  在两次发送之间，第二次发送时将 FSR 拉高的时间提前 1 个时钟周期
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module UlChannelDataControl_final_tb();

//-------------------------
// 信号定义
//-------------------------
reg         interfaceClk_tb;   // 10MHz时钟 (周期 = 100ns)
reg         outClk_tb;         // 10MHz时钟
reg         nRst_tb;           // 复位信号
reg         McBSPFSR_tb;       // 帧同步信号
reg         McBSPDR_tb;        // 串行数据输入
wire [9:0]  outData_tb;        // 输出数据
wire        outDataEn_tb;      // 输出数据使能
wire        wrAFrameDataOkFlag_tb;  // 数据写入完成标志
wire        wrEncContinue_tb;      // 编码继续信号
wire        McBSPClkR_tb;

//-------------------------
// 实例化被测模块
//-------------------------
UlChannelDataControl_final uut (
    .interfaceClk(interfaceClk_tb),
    .outClk(outClk_tb),
    .nRst(nRst_tb),
    .McBSPFSR(McBSPFSR_tb),
    .McBSPDR(McBSPDR_tb),
    .outData(outData_tb),
    .outDataEn(outDataEn_tb),
    .wrAFrameDataOkFlag(wrAFrameDataOkFlag_tb),
    .wrEncContinue(wrEncContinue_tb),
    .McBSPClkR(McBSPClkR_tb)
);


//-------------------------
// 生成10MHz时钟
//-------------------------
initial begin
    interfaceClk_tb = 0;
    outClk_tb = 0; 
end

always begin
    #50 interfaceClk_tb = ~interfaceClk_tb;  // 周期=100ns (10MHz)
end

// 如果希望outClk与interfaceClk独立
always begin
    #25 outClk_tb = ~outClk_tb;  // 可根据需要调整
end

//-------------------------
// 主测试流程
//-------------------------
initial begin
    // 初始化信号
    nRst_tb = 0;
    McBSPFSR_tb = 0;
    McBSPDR_tb = 0;
    
    // 复位操作 (持续 2 个时钟周期)
    #100;
    nRst_tb = 1;
    #100;
    
    // 测试场景: 发送4组通信帧，每组131个数据
    send_4_frames();

    // 结束仿真
    #1000;
    $finish;
end

//-------------------------------------------------
// 发送4组通信帧，每组131个数据 (第一数据固定，后续数据随机)
//-------------------------------------------------
task send_4_frames;
    integer i, j;
    reg [15:0] data;
begin
    for (i = 0; i < 4; i = i + 1) begin
        // 发送第一数据，固定为 16'h4747
        send_16bit_data(16'h4747);
        
        // 发送剩下的130个随机数据
        for (j = 0; j < 130; j = j + 1) begin
            data = $random;  // 生成随机16位数据
            send_16bit_data(data);
        end
        
        // 每发送完一组帧后，等待2000ns (200个时钟周期)
        #2000;
    end
end
endtask

//-------------------------------------------------
// 发送16位数据任务 (FSR 拉高一个周期)
//-------------------------------------------------
task send_16bit_data;
    input [15:0] data;
    integer i;
begin
    // Step 1: 先拉高 FSR 信号 1 个周期
    @(posedge interfaceClk_tb);
    McBSPFSR_tb <= 1;
    @(posedge interfaceClk_tb);
    McBSPFSR_tb <= 0;  // 仅保持 1 个周期
    
    // Step 2: 依次发送 16 位数据
    for (i = 15; i >= 0; i = i - 1) begin
        McBSPDR_tb <= data[i];
        @(posedge interfaceClk_tb);
    end
end
endtask

endmodule





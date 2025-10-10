
`timescale 1ns / 1ps
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

module McBSPDriver_16bTo8b_tb();

//-------------------------
// 信号定义
//-------------------------
reg         interfaceClk_tb;   // 10MHz时钟 (周期 = 100ns)
reg         nRst_tb;           // 复位信号
reg         McBSPFSR_tb;       // 帧同步信号
reg         McBSPDR_tb;        // 串行数据输入
wire        McBSPDataEn_tb;    // 数据有效标志
wire [7:0]  McBSPData_tb;      // 并行输出数据

//-------------------------
// 实例化被测模块
//-------------------------
McBSPDriver_16bTo8b tb1 (
    .interfaceClk(interfaceClk_tb),
    .nRst(nRst_tb),
    .McBSPFSR(McBSPFSR_tb),
    .McBSPDR(McBSPDR_tb),
    .McBSPDataEn(McBSPDataEn_tb),
    .McBSPData(McBSPData_tb)
);

//-------------------------
// 生成10MHz时钟
//-------------------------
initial begin
    interfaceClk_tb = 0;
    forever #50 interfaceClk_tb = ~interfaceClk_tb;  // 周期=100ns (10MHz)
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
    
    // 测试场景1: 发送 0xA55A (第一次发送, FSR 正常时序)
    send_16bit_data(16'hA55A);

    // 测试场景2: 发送 0x1234 (第二次发送, 提前一个周期拉高 FSR)
    send_16bit_data_earlier(16'h1234);

    // 结束仿真
    #1000;
    $finish;
end

//-------------------------------------------------
// 发送16位数据任务 (原始时序)
//-------------------------------------------------
task send_16bit_data;
    input [15:0] data;
    integer i;
begin
    // Step 1: 先等一个时钟上升沿，再拉高 FSR
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

//-------------------------------------------------
// 发送16位数据任务 (FSR 提前 1 个周期)
//-------------------------------------------------
task send_16bit_data_earlier;
    input [15:0] data;
    integer i;
begin
    // 注意: 跳过第一个 @(posedge interfaceClk_tb);
    //       直接拉高 FSR, 使其比原任务提前 1 个周期
    McBSPFSR_tb <= 1;
    @(posedge interfaceClk_tb);
    McBSPFSR_tb <= 0;  // 仅保持 1 个周期
    
    // 发送 16 位数据
    for (i = 15; i >= 0; i = i - 1) begin
        McBSPDR_tb <= data[i];
        @(posedge interfaceClk_tb);
    end
end
endtask

endmodule

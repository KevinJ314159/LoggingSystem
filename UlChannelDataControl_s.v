`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/23 01:24:14
// Design Name: 
// Module Name: UlChannelDataControl_s
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

module UlChannelDataControl_s(
    input McBSPClk,
    input Clk10MHz,       // 10MHz时钟
    input nRst,
    input validDataEn,        // 接入来自井下串并控制模块的DLDataOutEn信号,该信号在完成地面到井下的串行/解串器同步后即拉高
    input [9:0] validData,         // 解串器处理后的DownSig_Rout并行信号
    input UlDataRevEnable,     // 接入来自井下串并控制模块的DoHole_sync_success信号，该信号在井下模块发出尾帧后拉高

    output outData,         // 最终由McBSP_16B驱动输出的解码后数据
    output FSX
);

    wire conditional_reset = UlDataRevEnable && nRst;
    // 信号连接
    wire send_req;
    wire [15:0] data_in;     // 由RAMRd控制转发的来自10BTo8B解码器的解码后 经过合并的数据
    wire bus_state;         // 由McBSP驱动模块提供的总线忙信号
    wire send_done;         // 由RS232驱动模块提供的一字节发送完成标志

    wire [1:0] UlRAM_rd_state;
    wire [9:0] wrUlRAMAddr;     // 由RAMWr模块给双端口RAM的写地址
    wire [1:0] UlRAM_wr_state;
    wire UlDecodeContinue;
    wire [9:0] WrRAMData_in;          // 由RAMWr模块输出的写入RAM的数据

    wire [7:0] decoded_8bit;        // 由10B/8B解码器输出的8Bit解码后数据，交由RAMRd模块转发
    wire [9:0] RdRAMData_out;      // 从RAM读出的10位数据，直接给解码器，不经过RAMRd模块
    wire decoded_Data_Out_en;      // RAMRd的解码数据有效信号

    wire [9:0]  rdRAMAddr;
    wire rdRAMEn;
    wire decode_en;     // 给解码器的输入有效，解码器工作使能
    wire decode_frame_en;   // 给加码器的输入有效使能，在一帧中都拉高

    // 分频器生成 1MHz 时钟
    reg [3:0] clk_div_counter;
    /*reg McBSPClk;

    always @(posedge Clk10MHz or negedge nRst) begin
        if (!nRst) begin
            clk_div_counter <= 0;
            McBSPClk <= 0;
        end else begin
            if (clk_div_counter == 4) begin  // 10MHz / 5 = 2MHz, 再通过翻转得到 1MHz
                clk_div_counter <= 0;
                McBSPClk <= ~McBSPClk;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end*/

    // RS232驱动模块实例化
    McBSPDriver_16Bit_s McBSPDriver_16Bit_s_instance(
        .McBSPClk(McBSPClk),            // 10MHz时钟
//        .Rs232_clk(McBSPClk),       // 1MHz时钟：每个上升沿发送一个 bit
        .nRst(conditional_reset),          // 异步复位，低有效
        .tRequest(send_req),       // 发送请求信号
        .tData(data_in),        // 待发送的 8 位数据
    
        .FSX(FSX),         // 同步信号
        .DX(outData),      // 输出数据
        .busIdle(bus_state),       // McBSP总线状态
        .send_done(send_done)
    );

    // 写控制模块实例化
    UlWrRAMControl_s UlWrRAMControl_s_instance(
        .clk(Clk10MHz),
        .nRst(conditional_reset),

        // 来自 解串器 的 10 位数据和使能
        .inData(validData),
        .inDataEn(validDataEn),   // 10位输出有效时常高

        // 来自读控制器，用于清除写状态（读完哪块 RAM，就清哪块的写满标志）
        .UlRAM_rd_state(UlRAM_rd_state),

        // 输出：写 RAM 地址
        .wrUlRAMAddr(wrUlRAMAddr),
        // 输出：当前两块 RAM 的写状态 (0=未写满，1=写满)
        .UlRAM_wr_state(UlRAM_wr_state),  // 和写控制的握手信号

        .UlDecodeContinue(UlDecodeContinue),  // 当前是否处于写过程

        // 送给 RAM模块 的输入
        .UlDecoderData(WrRAMData_in)
    );

    // 10b/8b 解码器实例化
    decode_10bTo8b_new_s decode_10bTo8b_new_s_instance(
        .clk(McBSPClk),              // 时钟信号
        .rst_n(conditional_reset),            // 复位信号
        .decode_en(decode_frame_en),         // 一帧输入有效信号，在一帧中都拉高
        .data_10b_en(decode_en),
        .datain(RdRAMData_out),    // 10位输入数据
        .dataout(decoded_8bit),  // 8位输出解码数据
        .dataout_en(decoded_Data_Out_en)    // 解码结果有效信号
    );

    UlDualPortRAM_s UlDualPortRAM_s_instance(
        .clk_in(Clk10MHz),
        .clk_out(McBSPClk),
        .waddr(wrUlRAMAddr),
        .wdata(WrRAMData_in),
        .wen(UlDecodeContinue),
        .raddr(rdRAMAddr),
        .rden(rdRAMEn),
        .rdata(RdRAMData_out)
    );

    UlRdRAMControl_s UlRdRAMControl_s_instance(
        .clk(McBSPClk),
        .nRst(conditional_reset),
        .bus_state(bus_state),
        .UlDataRevEnable(UlDataRevEnable),     // 来自井下串并控制的成功同步信号，代表地面到井下通路建立
        .ABitSendOk(send_done),          // 来自RS232的一字节发送完成标志
        .decodedData_8bit(decoded_8bit),  // 解码后解码器输出的数据
        .send_data(decoded_Data_Out_en),   // 来自解码器的输出有效信号，在正常读RAM数据时转发给RS2323即可

        // 来自写控制器：哪块 RAM 已写满
        .UlRAM_wr_state(UlRAM_wr_state),

        // 发送给写控制器：哪块 RAM 已读完
        .UlRAM_rd_state(UlRAM_rd_state),

        // 用于读 RAM 的接口
        .rdRAMEn(rdRAMEn),       // 读使能
        .rdRAMAddr(rdRAMAddr),     // 读地址

        // 读出后输出给更上层或下游
        .rdDataOut(data_in),     // 给Rs232的8Bit数据
        .rdDataOutEn(decode_en),    // 给解码器的输入有效信号(比rdRAMEn延后一周期)
        .decode_continue(decode_frame_en),
        .send_req(send_req)     // 提供给Rs232的发送请求，在Ack_send中自行驱动拉高，在正常读取RAM数据时转发来自解码器的输出有效信号即可
    );

endmodule
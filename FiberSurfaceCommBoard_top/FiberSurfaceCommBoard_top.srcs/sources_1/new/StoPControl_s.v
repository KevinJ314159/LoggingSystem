/*1.此模块负责在解串器恢复时钟下降沿读取信号，当连续接收到30帧同步码，并且收到1026帧同步码之后
的帧尾，且解串器锁定到串行器时钟、LOCK信号拉低时，向PtoSControl模块发送同步成功标志*/
/*2.同步成功标志拉高后长高*/
module StoPControl_s(
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)
    input CLK_100MHZ,           // 100M/40M Hz时钟输入
    input CLK_10MHZ,            // 10MHz时钟输入
    input nRst,                 // 低电平有效复位信号
    input UpSig_RClk,         // 来自解串器的恢复时钟
    input UpSig_nLock,        // 来自串并转换器的锁定信号，正常工作时为低电平
    input [9:0] UpSig_ROut,   // 串并转换器输出的 10 位数据
    output sync_success         // 同步成功标志
);

    // 下降沿检测信号
    wire negedge_detected;        // 从edge_detect模块输出，表示是否检测到下降沿

    // 实例化edge_detect模块
    edge_detect_s edge_detect_instance (
        .UpSig_RClk(UpSig_RClk),    // 来自解串器的恢复时钟
        .CLK_100MHZ(CLK_100MHZ),        // 100MHz时钟
        .nRst(nRst),                    // 复位信号，低电平有效
        .negedge_detected(negedge_detected) // 下降沿检测标志
    );

    // 实例化sync_detect模块
    sync_detect_s sync_detect_instance (
//        .RX_Los(RX_Los),
        .CLK_100MHZ(CLK_100MHZ),         // 100MHz时钟输入
        .nRst(nRst),                     // 复位信号，低电平有效
        .detected_negedge(negedge_detected), // 从edge_detect模块接收到的下降沿标志
        .UpSig_ROut(UpSig_ROut),     // 串并转换器输出的 10 位数据
        .UpSig_nLock(UpSig_nLock),   // 串并转换器的锁定信号
        .sync_success(sync_success)      // 同步成功标志
    );

endmodule

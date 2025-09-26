/*1.此模块负责在解串器恢复时钟下降沿读取信号，当连续接收到30帧同步码，并且收到1026帧同步码之后
的帧尾，且解串器锁定到串行器时钟、LOCK信号拉低时，向PtoSControl模块发送同步成功标志*/
/*2.同步成功标志拉高后长高*/
module StoPControl_s(
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)
//    input CLK_100MHZ,           // 100M/40M Hz时钟输入
//    input CLK_10MHZ,            // 10MHz时钟输入
    input nRst,                 // 低电平有效复位信号
    input UpSig_RClk,         // 来自解串器的恢复时钟
    input UpSig_nLock,        // 来自串并转换器的锁定信号，正常工作时为低电平
    input [9:0] UpSig_ROut,   // 串并转换器输出的 10 位数据
    output sync_success,         // 同步成功标志
    output reg [9:0] UlDataOut,    // 给上行RAM的数据
    output reg UlDataOutEn      // 上行数据输出有效信号，在整个通信帧中拉高
);

    // 下降沿检测信号
//    wire negedge_detected;        // 从edge_detect模块输出，表示是否检测到下降沿

/*    // 实例化edge_detect模块
    edge_detect_s edge_detect_instance (
        .UpSig_RClk(UpSig_RClk),    // 来自解串器的恢复时钟
        .CLK_100MHZ(CLK_100MHZ),        // 100MHz时钟
        .nRst(nRst),                    // 复位信号，低电平有效
        .negedge_detected(negedge_detected) // 下降沿检测标志
    );
*/

    reg [9:0] hold_counter;
    reg [1:0] detect_counter;
    reg detect_flag;

    // 实例化sync_detect模块
    sync_detect_s sync_detect_instance (
//        .RX_Los(RX_Los),
//        .CLK_100MHZ(CLK_100MHZ),         // 100MHz时钟输入
        .nRst(nRst),                     // 复位信号，低电平有效
        .UpSig_RClk (UpSig_RClk),
//        .detected_negedge(negedge_detected), // 从edge_detect模块接收到的下降沿标志
        .UpSig_ROut(UpSig_ROut),     // 串并转换器输出的 10 位数据
        .UpSig_nLock(UpSig_nLock),   // 串并转换器的锁定信号
        .sync_success(sync_success)      // 同步成功标志
    );

always @(posedge UpSig_RClk or negedge nRst) begin
    if (!nRst) begin
        // 复位初始化
        UlDataOutEn <= 1'b0;
        UlDataOut <= 10'd0;
        detect_counter <= 2'd0;
        detect_flag <= 1'b0;
        hold_counter <= 10'd0;
    end else begin
        // 默认值
//        UlDataOutEn <= 1'b0;

        // 数据通路
        UlDataOut <= UpSig_ROut;

                if ((detect_flag || (UpSig_ROut == 10'h287 || UpSig_ROut == 10'h2b8)) && hold_counter < 260) begin
                    UlDataOutEn <= 1;
                end else begin
                    UlDataOutEn <= 0;
                end

        // 同步码检测逻辑
        if (UpSig_ROut == 10'h287 || UpSig_ROut == 10'h2b8) begin
            if (detect_counter < 2'd2)
                detect_counter <= detect_counter + 1'b1;
        end else begin
            detect_counter <= 2'd0;
        end

        // 检测到连续2次同步码
        if (detect_counter == 2'd1 && (UpSig_ROut == 10'h287 || UpSig_ROut == 10'h2b8)) begin
            detect_flag <= 1'b1;
            detect_counter <= 2'd0;
        end

        // 保持计数器逻辑
        if (detect_flag) begin
            if (hold_counter < 10'd260) begin               // 一个通信帧38个字节
                hold_counter <= hold_counter + 1'b1;
//                UlDataOutEn <= 1'b1;  // 数据有效信号
            end else begin
                hold_counter <= 10'd0;
                detect_flag <= 1'b0;
            end
        end
    end
end

endmodule
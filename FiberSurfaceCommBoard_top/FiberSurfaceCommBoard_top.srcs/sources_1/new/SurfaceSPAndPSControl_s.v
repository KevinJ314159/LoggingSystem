
/*需要知道input RX_Los,             // 接收信号丢失指示 的有效电平目前假设高电平丢失*/
/*需要知道output reg Tx_Disable        // 发送禁用信号的 有效电平目前假设高电平禁用*/
/*需要知道output reg UlDataOutEn,      // 下行数据输出有效信号
（不太明白这个有什么用功能和DoHole_sync_success井下同步成功指示信号重合？）的有效电平，目前假设高电平使能有效*/
/*串行器选通选择下降沿选通/下降沿发送，因为DataIn在上升沿进入*/
/*DataInEn目前假设高电平有效*/

module SurfaceSPAndPSControl_s (
    // 输入端口
    input CLK_100MHZ,         // 100/40 MHz 时钟信号
    input CLK_10MHZ,          // 10 MHz 时钟信号
    input nRst,               // 复位信号，低电平有效
    input DataInEn,           //来自地面下行RAM读模块的 数据输入使能信号
    input [9:0] DataIn,       //来自地面下行RAM读模块的 10 位数据输入
    input UpSig_RClk ,       // 来自串并转化器的恢复时钟
    input UpSig_nLock,      // 锁定信号，低电平表示正常工作
    input [9:0] UpSig_ROut, // 串行到并行转换的10位数据输出
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)

    // 输出端口
    output wire UpSig_RefClk,   // 串行到并行转换的参考时钟信号
    output reg UpSig_RClk_RnF, // 串行到并行转换的接收时钟反转信号
    output reg UpSig_nPWRDN,   // 串并转换的掉电信号
    output reg UpSig_REn,      // 串并转换的数据使能信号
    output reg UlDataOutEn,      /* 下行数据输出有效信号（不太明白这个有什么用功能和DoHole_sync_success井下同步成功指示信号重合？）
                                     目前在收到下行同步码及尾帧后将其拉高，即认为下行数据有效）*/
    output wire [9:0] UlDataOut,  // 上行10位数据输出
    output wire DownSig_TClk,       // 并行到串行转换的传输时钟信号
    output reg DownSig_TClk_RnF,   // 串并转换的传输时钟反转信号
    output reg [9:0] DownSig_Din,  // 提供给并串转换器的10位数据
    output reg DownSig_DEn,        // 串行器处并行到串行转换的数据使能信号
    output reg DownSig_nPWRDN,     // 并串转换器的掉电信号 信号为0时，串并转化器的输出DownSig_ROut进入高阻状态。
    output wire DownSig_Sync1,      // 并串转换器的同步信号1
    output wire DownSig_Sync2,      // 并串转换器的同步信号2
    output reg shakehand_success // 井下同步成功指示信号(目前在井下发送同步尾帧，进入工作状态后才认为完成同步)
//    output reg Tx_Disable        // 发送禁用信号
//    output reg DownSig_TDIS        // 需要确认此接口用途

);
    wire sync_success;      // 从StoPControl_instance模块输出，作为传输给PtoSControl模块的同步成功信号
    wire SEND_LAST_FRAME_En;    // 从PtoSControl_instance模块输出，作为传输给DownholeSPAndPSControl模块的尾帧发送信号
    //reg [9:0] DataIn_to_send;    // 缓存需要串行器发送的输入
    reg send_last_frame;    // 尾帧发送直接触发器
    reg last_frame_sended;  // 尾帧已发送标志
    // reg last_frame_sended_one_cycle_dly;  // 尾帧已发送标志一拍延迟
    // reg tem_delay;
    reg [5:0] hold_counter;  // 用于计数 38 个周期
    reg [1:0] detect_counter; // 用于检测连续两个 10'h287
    reg detect_flag;         // 标志位，表示是否检测到连续两个 10'h287

    //控制发送尾帧和直接向串行器转发数据的转态声明
    parameter SEND_FRAME_TAIL = 2'b00;        // 等待同步成功标志WAIT_SYNC_Success
    parameter WAIT_SYNC_Success = 2'b01;         // 发送帧尾SEND_FRAME_TAI
    parameter NORMAl = 2'b10;                  // 正常工作状态
    parameter NULL = 2'b11;            // 可增加其它状态

    // 当前状态和下一个状态
    reg [1:0] state, next_state;

//？可以直接转发的信号？
    assign UpSig_RefClk = CLK_10MHZ;  // 直接连接 CLK_10MHZ
    assign DownSig_TClk = CLK_10MHZ;      // 直接连接 CLK_10MHZ
    assign UlDataOut = UpSig_ROut;    // ？直接将解串器输出（包括同步码）输出到下一级？是否需要在状态机中发送以实现和UlDataOutEn信号的严格同步？

StoPControl_s StoPControl_instance(
//    .RX_Los(RX_Los),
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)
    .CLK_100MHZ(CLK_100MHZ),           // 100MHz时钟输入
    .CLK_10MHZ(CLK_10MHZ),            // 10MHz时钟输入
    .nRst(nRst),                 // 低电平有效复位信号
    .UpSig_RClk (UpSig_RClk ),         // 来自串并转换器的恢复时钟
    .UpSig_nLock(UpSig_nLock),        // 来自串并转换器的锁定信号，正常工作时为低电平
    .UpSig_ROut(UpSig_ROut),   // 串并转换器输出的 10 位数据
    .sync_success(sync_success)         // 同步成功标志
        );


PtoSControl_s PtoSControl_instance(
//    .RX_Los(RX_Los),
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)
    .CLK_100MHZ(CLK_100MHZ),       // 100 MHz 时钟
    .CLK_10MHZ(CLK_10MHZ),          // 10 MHz 时钟信号
    .sync_success(sync_success),       // 来自 StoPControl 的同步成功标志
    .nRst(nRst),               // 复位信号，低电平有效
    .DownSig_Sync1(DownSig_Sync1),   // 同步码发送使能1
    .DownSig_Sync2(DownSig_Sync2),   // 同步码发送使能2
    .SEND_LAST_FRAME_En(SEND_LAST_FRAME_En) // 1026个同步码已发送，尾帧发送使能)
        );


        //尾帧发送直接触发器逻辑
    always @(posedge SEND_LAST_FRAME_En or negedge nRst) begin
        if (~nRst)
            send_last_frame <= 0;
        else if(state == SEND_FRAME_TAIL)
            send_last_frame <= 1;
    end

        /*//尾帧已发送标志逻辑
    always @(negedge SEND_LAST_FRAME_En or negedge nRst) begin
        if (~nRst)
            last_frame_sended <= 0;
        else
            last_frame_sended <= 1;
    end

        //尾帧已发送标志一拍延迟逻辑
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)begin
            last_frame_sended_one_cycle_dly <= 0;
            tem_delay <= 0;
        end else begin
            tem_delay <= last_frame_sended;
            last_frame_sended_one_cycle_dly <= tem_delay;
            end
    end*/

    // 状态机逻辑
    always @(posedge CLK_10MHZ or negedge nRst) begin  // 按照10Mhz时钟转移状态
        if (~nRst)
            state <= SEND_FRAME_TAIL;
        else
            state <= next_state;
    end

    // 状态转移逻辑
    always @(*) begin
        case (state)

            SEND_FRAME_TAIL: begin
                if (last_frame_sended)      // 如果已发送尾帧，进入正常工作状态
                    next_state = WAIT_SYNC_Success;
                else
                    next_state = SEND_FRAME_TAIL;
            end

            WAIT_SYNC_Success: begin
                if (sync_success)
                    next_state = NORMAl;
                else
                    next_state = WAIT_SYNC_Success;
            end

            NORMAl: begin
//                if (RX_Los)                // 如果收到接收信号丢失提示则回到等待同步状态
                if (~nRst)                // 如果收到接收信号丢失提示则回到等待同步状态
                    next_state = SEND_FRAME_TAIL;
                else
                    next_state = NORMAl;
            end
            default: next_state = SEND_FRAME_TAIL;
        endcase
    end


    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            UpSig_RClk_RnF <= 0;  // 在解串器恢复时钟下降沿读数据
            DownSig_TClk_RnF <= 0;  // 串行器在下降沿发数据
            DownSig_nPWRDN <= 1;    // ？复位时就启动串行器？
            UpSig_REn <= 1;    //.？复位时就开始接收解串器输出？
            UpSig_nPWRDN <= 1;    // ？复位时就启动解串器？
            DownSig_DEn <= 1;     // ？复位时就开始使串行器输出有效？
            DownSig_Din <= 10'b00000_00000;   // 串行器缓冲区
            UlDataOutEn <= 0;       // 解串器输出数据有效性使能低
            hold_counter <= 0;      // 复位计数器
            detect_counter <= 0;    // 复位检测计数器
            detect_flag <= 0;       // 复位标志位
            last_frame_sended <= 0; 
            shakehand_success <= 0;   // 同步任务未完成
//            Tx_Disable <= 1;    // 光收发模块先关闭发送功能
        end else begin
        case (state)

                SEND_FRAME_TAIL: begin
//                    Tx_Disable <= 0;    // 光收发模块开启发送功能
                    DownSig_DEn <= 1;     // 串行器处下行数据有效开启，可以发送同步码
                    DownSig_nPWRDN <= 1;    // 串行器进入工作转态
                    UpSig_REn <= 1;    //.接收解串器输出的同步码
                    UpSig_nPWRDN <= 1;    // 解串器进入工作状态
                    UlDataOutEn <= 0;   // 下发数据已经有效？
                    shakehand_success <= 0;
                    if(send_last_frame) begin
                    DownSig_Din <= 10'b10011_11100;
                    last_frame_sended <= 1;
                    end
                end

                WAIT_SYNC_Success: begin
//                    Tx_Disable <= 1;    // 光收发模块先关闭发送功能
                    DownSig_DEn <= 1;     // 串行器处下行数据有效开启
                    DownSig_nPWRDN <= 1;    // 串行器保持工作转态
                    UpSig_REn <= 1;    //.开始接收解串器输出的同步码
                    UpSig_nPWRDN <= 1;    // 解串器进入工作状态
                    UlDataOutEn <= 0;       // 解串器输出数据有效性使能低
                    last_frame_sended <= 0; // 尾帧已发送标志置0
                    shakehand_success <= 0;   // 同步任务未完成
                end

                NORMAl: begin

                    DownSig_nPWRDN <= 1;    // 串行器进入工作转态
                    UpSig_REn <= 1;    //.接收解串器输出的数据
                    UpSig_nPWRDN <= 1;    // 解串器进入工作状态
                    send_last_frame <= 0;   // 尾帧发送直接触发器置0
                    last_frame_sended <= 0;    // 尾帧已发送标志置0
                    shakehand_success <= 1;   // 同步任务已完成

                    if (DataInEn) begin       // 进入正常工作状态后，DataInEn接管对串行器输出使能的控制
                        DownSig_DEn <= 1;
                        DownSig_Din <= DataIn;    // 直接转发下行数据给串行器
                        end else begin
                        DownSig_DEn <= 0;       // 确认这里是否需要关闭下行串行器使能？
                        DownSig_Din <= 10'b00000_00000;
                        end

                    if (UpSig_ROut == 10'h287) begin
//                        UlDataOutEn <= 1;   // 下发数据有效
                        if (detect_counter < 2)
                        detect_counter <= detect_counter + 1;  // 计数连续检测到的次数
                            end else begin 
                                detect_counter <= 0;  // 如果不是 10'h287，重置计数器
//                        UlDataOutEn <= 0;   // 下发数据无效
                     end

                     if (detect_counter == 2) begin
                        detect_flag <= 1;  // 设置标志位
                        detect_counter <= 0;  // 重置检测计数器
                    end

                    

                    if (detect_flag) begin
//                        UlDataOutEn <= 1;   // 下发数据有效
                            if (hold_counter < 35)
                            hold_counter <= hold_counter + 1;  // 计数 38 个周期
                                else begin
                                hold_counter <= 0;  // 计数完成后重置
                                detect_flag <= 0;   // 清除标志位
                                UlDataOutEn <= 0;   // 拉低 UlDataOutEn
                                end
//                    end else begin
//                    UlDataOutEn <= 0;  // 其他情况下保持低电平
                end

                if ((detect_flag || UpSig_ROut == 10'h287) && hold_counter < 35) begin
                    UlDataOutEn <= 1;
//                end else begin
//                    UlDataOutEn <= 0;
                end
                    //DataIn_to_send <= DataIn;
                    //DownSig_Din <= DataIn_to_send;
//                    DownSig_Din <= DataIn;    // 直接转发上行数据给串行器

                    //last_frame_sended_one_cycle_dly <= 0;
                    //tem_delay <= 0;
//                    UlDataOutEn <= 1;   // 下发数据已经有效

                end

            endcase
    end
end

endmodule
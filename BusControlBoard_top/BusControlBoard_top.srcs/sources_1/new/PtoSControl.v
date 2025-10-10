/*1.此模块负责接收StoPControl模块发送的同步成功信号，
并控制井下串行器向地面发送同步码，并向顶层模块发送添加尾帧信号*/
/*2.使用状态机实现，添加尾帧信号仅保持两个100Mhz时钟周期，之后拉低*/
/*3.目前为测试方便，仅延迟10个时钟周期就发送尾帧*/

module PtoSControl(
//    input RX_Los,
//    input CLK_100MHZ,       // 100 MHz 时钟
    input CLK_10MHZ,          // 10 MHz 时钟信号
    input sync_success,       // 来自 StoPControl 的同步成功标志
    input nRst,               // 复位信号，低电平有效
    input DataInEn,
    input [9:0] DataIn,       //来自地面下行RAM读模块的 10 位数据输入

    output reg UpSig_Sync1,   // 同步码发送使能1
    output reg UpSig_Sync2,   // 同步码发送使能2


    output reg [9:0] UpSig_Din  // 提供给并串转换器的10位数据
);

    // 状态定义
    parameter WAIT_SYNC_SUCCESS = 2'b00;  // 等待 sync_success 信号
    parameter SEND_SYNC = 2'b01;          // 发送同步信号
    parameter SEND_LAST_FRAME = 2'b10;     // 等待85个时钟周期
    parameter NORMAL = 2'b11;    // 发送尾帧

    // 当前状态和下一个状态
    reg [1:0] state, next_state;

    // 计数器
    reg [10:0] counter;  // 用于计数85个时钟周期（最大127）
    reg [3:0] sync_timer; // 用于同步信号维持的定时器（最大15个时钟周期）
    reg SEND_LAST_FRAME_En; // 1026个同步码已发送，尾帧发送使能
    reg last_frame_sended;
//    reg [1:0] counter_delay;    // 用于控制SEND_LAST_FRAME_En拉高延长的计时器

    //关于10MHZ（提供给解串/串行器参考时钟）的累计计数器
        always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            sync_timer <= 0;
        else if (state == SEND_SYNC)
            sync_timer <= sync_timer + 1; // 同步信号计时
        else if (state != SEND_SYNC)
            sync_timer <= 0; // 退出同步信号发送时清零
    end
    
    //关于10MHZ（提供给解串/串行器参考时钟）的累计计数器
        always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            counter <= 0;
        else if (state == SEND_LAST_FRAME)
            counter <= counter + 1; // 85时钟周期计时
        else if (state != SEND_LAST_FRAME)
            counter <= 0; // 退出尾帧发送时清零
    end

/*    //关于10MHZ（提供给解串/串行器参考时钟）的累计计数器
        always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            counter_delay <= 0;
        else if (SEND_LAST_FRAME_En == 1)
            counter_delay <= counter_delay + 1; // 同步信号计时
//        else if (state != SEND_SYNC)
//            sync_timer <= 0; // 退出同步信号发送时清零
    end*/

    // 状态机逻辑
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            state <= WAIT_SYNC_SUCCESS;
        else
            state <= next_state;
    end

    // 状态转移逻辑
    always @(*) begin
        case (state)
            WAIT_SYNC_SUCCESS: begin
                if (sync_success)
                    next_state = SEND_SYNC;
                else
                    next_state = WAIT_SYNC_SUCCESS;
            end

            SEND_SYNC: begin
                if (sync_timer == 10)  // 维持同步信号10个时钟周期后
                    next_state = SEND_LAST_FRAME;
                else
                    next_state = SEND_SYNC;
            end

            SEND_LAST_FRAME: begin
                if (last_frame_sended) // 发送尾帧使能拉高后进入正常工作转态
                    next_state = NORMAL;
                else
                    next_state = SEND_LAST_FRAME;
            end

            NORMAL: begin                               // 可添加其它退出状态条件
                if (~nRst)
                    next_state = WAIT_SYNC_SUCCESS;     // 回到等待同步状态
                else
                    next_state = NORMAL;
            end
            default: next_state = WAIT_SYNC_SUCCESS;
        endcase
    end

    // 输出控制
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            UpSig_Sync1 <= 0;
            UpSig_Sync2 <= 0;
            SEND_LAST_FRAME_En <= 0;
//            counter <= 0;
//            sync_timer <= 0;
            last_frame_sended <= 0;
//            counter_delay <= 2'd0;

        end else begin
            case (state)
                WAIT_SYNC_SUCCESS: begin
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
                    UpSig_Din <= 10'b00000_00000;
                    SEND_LAST_FRAME_En <= 0;
//                    counter <= 0;
//                    sync_timer <= 0;
                end

                SEND_SYNC: begin
                    UpSig_Sync1 <= 1;
                    UpSig_Sync2 <= 1;
//                    UpSig_Din <= 10'b00000_00000;
//                    counter <= 0;
                    SEND_LAST_FRAME_En <= 0;
                end

                SEND_LAST_FRAME: begin
                if (counter >= 1027)begin    //为测试方便，目前仅延迟10个周期发送尾帧
                    SEND_LAST_FRAME_En <= 1;

                    if (SEND_LAST_FRAME_En) begin
                        UpSig_Din <= 10'b10011_11100;
                        last_frame_sended <= 1;
//                        counter_delay <= 2'd0;
                    end
                end
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
//                    sync_timer <= 0;
                    
                end

                NORMAL: begin
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
//                    UpSig_Din <= DataIn;
//                    counter <= 0;
//                    sync_timer <= 0;
                    last_frame_sended <= 0;

                    if (DataInEn) begin       // 进入正常工作状态后，DataInEn接管对串行器输出使能的控制
                        UpSig_Din <= DataIn;    // 直接转发下行数据给串行器

                        end else begin
//                        DownSig_DEn <= 0;       // 确认这里是否需要关闭下行串行器使能？
                        UpSig_Din <= 10'b00000_11111;     // 发送空闲态直接发同步码？
                        end
                end

                default: begin
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
                    last_frame_sended <= 0;
                    UpSig_Din <= 10'b00000_00000;
                end
            endcase
        end
    end
endmodule

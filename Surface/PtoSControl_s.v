/*1.此模块负责在复位后即发送串行/解串器同步码，在StoPControl_s接收到井下传来的同步信号和尾帧后,会向此模块发送
sync_success信号，作为PtoSControl_s模块继续执行，并跳出重发1026个同步码的条件。*/
/*2.使用状态机实现，添加尾帧信号仅保持两个100Mhz时钟周期，之后拉低*/
/*3.目前为测试方便，仅延迟10个时钟周期就发送尾帧实际测试需要更改*/

module PtoSControl_s(
//    input UpSig_SD,     // 来自光电转换模块(用途需要确认)
//    input CLK_100MHZ,       // 100 MHz 时钟
    input CLK_10MHZ,          // 10 MHz 时钟信号
    input sync_success,       // 来自 StoPControl 的同步成功标志
    input nRst,               // 复位信号，低电平有效
    input DataInEn,          
    input [9:0] DataIn,       //来自地面下行RAM读模块的 10 位数据输入

    output reg DownSig_Sync1,   // 同步码发送使能1
    output reg DownSig_Sync2,   // 同步码发送使能2

//    output reg shakehand_success,   // 收到来自StoPControl_s模块的sync_success信号后，表示地面到井下通信也已完成
    output reg [9:0] DownSig_Din  // 提供给并串转换器的10位数据
);

    // 状态定义
    parameter SEND_SYNC = 2'd0;         // 发送同步信号
    parameter SEND_LAST_FRAME = 2'd1;          // 发送同步信号     // 等待85个时钟周期发送尾帧
    parameter WAIT_SYNC_SUCCESS = 2'd2;         // 等待 sync_success 信号 
    parameter NORMAL = 2'd3;    // 正常工作状态 

    // 当前状态和下一个状态
    reg [1:0] state, next_state;

    // 计数器
    reg [10:0] counter;  // 用于计数85个时钟周期（最大2048）
    reg [3:0] sync_timer; // 用于同步信号维持的定时器（最大15个时钟周期）
    reg SEND_LAST_FRAME_En;
     reg last_frame_sended; // 1026个同步码已发送，尾帧发送使能
    reg [1:0] counter_delay;    // 用于控制SEND_LAST_FRAME_En拉高延长的计时器

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

/*        //控制SEND_LAST_FRAME_En拉高延长的累计计数器
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
            state <= SEND_SYNC;
        else
            state <= next_state;
    end

    // 状态转移逻辑
    always @(*) begin
        case (state)
            SEND_SYNC: begin
                if (sync_timer == 10)  // 维持同步信号10个时钟周期后
                    next_state = SEND_LAST_FRAME;
                else
                    next_state = SEND_SYNC;
            end

            SEND_LAST_FRAME: begin
                if (last_frame_sended) // 发送尾帧使能拉高后进入正常工作转态
                    next_state = WAIT_SYNC_SUCCESS;
                else
                    next_state = SEND_LAST_FRAME;
            end

            WAIT_SYNC_SUCCESS: begin
                if (sync_success)
                    next_state = NORMAL;
                else
                    next_state = WAIT_SYNC_SUCCESS;
            end

            NORMAL: begin                               // 可添加其它退出状态条件
                if (~nRst)
                    next_state = SEND_SYNC;     // 回到等待同步状态
                else
                    next_state = NORMAL;
            end
            default: next_state = SEND_SYNC;
        endcase
    end

    // 输出控制
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            DownSig_Sync1 <= 0;
            DownSig_Sync2 <= 0;
            SEND_LAST_FRAME_En <= 0;
//            counter <= 0;
//            sync_timer <= 0;
            DownSig_Din <= 10'b00000_00000;
            last_frame_sended <= 0;
//            shakehand_success <= 0;
        end else begin
            case (state)

                SEND_SYNC: begin
                    DownSig_Sync1 <= 1;
                    DownSig_Sync2 <= 1;
//                    DownSig_Din <= 10'b00000_00000; // 此时解串器会在Sync的驱动下发送同步码（所以输入数据可以随便给？
//                    counter <= 0;
                    SEND_LAST_FRAME_En <= 0;
//                    shakehand_success <= 0;
                end

                SEND_LAST_FRAME: begin
                if (counter >= 1027)begin    //为测试方便，目前仅延迟10个周期发送尾帧
                    SEND_LAST_FRAME_En <= 1;

                if(SEND_LAST_FRAME_En) begin
                    DownSig_Din <= 10'b10011_11100;
                    last_frame_sended <= 1;
                    end
//                    if (counter_delay == 2'd1) begin
//                        last_frame_sended <= 1;
//                        counter_delay <= 2'd0;
//                    end
                end
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
//                    sync_timer <= 0;
//                    shakehand_success <= 0;
                    
                end

                WAIT_SYNC_SUCCESS: begin
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
                    DownSig_Din <= 10'b00000_00000;
                    SEND_LAST_FRAME_En <= 0;
//                    counter <= 0;
//                    sync_timer <= 0;
//                    shakehand_success <= 0;
                end

                NORMAL: begin
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
//                    counter <= 0;
//                    sync_timer <= 0;
                    last_frame_sended <= 0;
//                    shakehand_success <= 1;

                    if (DataInEn) begin       // 进入正常工作状态后，DataInEn接管对串行器输出使能的控制
                        DownSig_Din <= DataIn;    // 直接转发下行数据给串行器

                        end else begin
//                        DownSig_DEn <= 0;       // 确认这里是否需要关闭下行串行器使能？
                        DownSig_Din <= 10'b00000_11111;     // 发送空闲态直接发同步码？
                        end

                    end


                default: begin
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
                    last_frame_sended <= 0;
//                    shakehand_success <= 0;
                    DownSig_Din <= 10'b00000_00000;
                end
            endcase
        end
    end
endmodule

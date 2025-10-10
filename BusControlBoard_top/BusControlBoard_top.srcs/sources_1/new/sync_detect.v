/*1.此模块用于检测井下解串器是否与地面串行器完成同步*/
/*2.目前使用4状态状态机实现，接收30组连续的同步码，识别到同步码尾帧，解串器输出LOCK信号即认为完成同步*/
/*3.需要确认同步码尾帧，确认解串器锁定信号LOCK拉低的时机（无严重影响）*/
module sync_detect (
//    input RX_Los,           // 高电平代表信号丢失
//    input CLK_100MHZ,           // ？40MHz？ 时钟输入
    input DownSig_RClk,       // 来自解串器的恢复时钟
    input nRst,                 // 复位信号，低电平有效
//    input detected_negedge,         // 串并转换器的恢复时钟的下降沿
    input [9:0] DownSig_Rout,   // 串并转换器输出的 10 位数据
    input DownSig_nLock,        // 串并转换器的锁定信号
    output reg sync_success          // 同步成功标志
);

    // 状态定义
    parameter WAIT_SYNC = 2'b00;        // 等待同步码
    parameter WAIT_FRAME_TAIL = 2'b01;  // 等待帧尾
    parameter WAIT_DownSig_nLock = 2'b10;     // 等待锁定信号拉低
    parameter SYNC_SUCCESS = 2'b11;            // 成功

    // 当前状态和下一个状态
    reg [1:0] state,next_state;

    // 同步码检测
    reg [4:0] sync_code_count; // 用于计数检测到的同步码周期

    // 状态机逻辑
    always @(posedge DownSig_RClk or negedge nRst) begin
        if (~nRst)
            state <= WAIT_SYNC; // 复位时，状态机回到等待同步状态
        else
            state <= next_state; // 更新当前状态
    end

/*    // 生成同步码计数器
    always @(posedge detected_negedge or negedge nRst) begin
        if (~nRst)
            sync_code_count <= 5'b0;
        else if (state == WAIT_SYNC && DownSig_Rout == 10'b00000_11111)
            sync_code_count <= sync_code_count + 1;
        else if (state != WAIT_SYNC)
            sync_code_count <= 5'b0; // 状态机不在等待同步时清除计数器
    end
*/

        // 生成同步码计数器
    always @(posedge DownSig_RClk or negedge nRst) begin
        if (~nRst)
            sync_code_count <= 5'b0;
//        else if(detected_negedge) begin
            else if (state == WAIT_SYNC && DownSig_Rout == 10'b00000_11111)
                sync_code_count <= sync_code_count + 1;
            else if (state != WAIT_SYNC)
            sync_code_count <= 5'b0; // 状态机不在等待同步时清除计数器
//            end
    end

    // 状态机转移逻辑
    always @(*) begin
        case (state)
            WAIT_SYNC: begin
                // 等待同步码
                if (sync_code_count == 30)  // 如果已经检测到30个同步码
                    next_state = WAIT_FRAME_TAIL; // 转到等待帧尾状态
//                else if (RX_Los)
//                    next_state = WAIT_SYNC; // 继续等待同步码
                else 
                    next_state = WAIT_SYNC; // 继续等待同步码
            end
            WAIT_FRAME_TAIL: begin
                // 等待帧尾10'b01111_11110 且 DownSig_nLock 为低电平
                if (DownSig_Rout == 10'b01111_11110)
                    next_state = WAIT_DownSig_nLock; // 如果帧尾条件满足，转到等待锁定拉低
                else
                    next_state = WAIT_FRAME_TAIL; // 继续等待帧尾
            end
            WAIT_DownSig_nLock: begin
                if (!DownSig_nLock)
                next_state = SYNC_SUCCESS; // 保持同步成功状态
                else
                    next_state = WAIT_DownSig_nLock;
            end
            SYNC_SUCCESS: begin
                if (~nRst)
                next_state = WAIT_SYNC; // 回到等待同步码状态
                else
                next_state = SYNC_SUCCESS; // 保持同步成功状态
            end
            default: next_state = WAIT_SYNC; // 默认等待同步码状态
        endcase
    end

    // 输出控制
    always @(posedge DownSig_RClk or negedge nRst) begin
        if (~nRst)
            sync_success <= 0;
        else if (state == SYNC_SUCCESS)
            sync_success <= 1; // 当同步成功时，设置 sync_success 信号
        else
            sync_success <= 0; // 否则保持为低电平
    end

endmodule

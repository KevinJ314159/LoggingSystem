module McBSPDriver_16Bit_s (
    input McBSPClk,
    input nRst,
    input tRequest,
    input [15:0] tData,
    output reg FSX,
    output reg DX,
    output reg busIdle,
    output reg send_done          // 新增发送完成信号
);

//==================== 状态定义 ====================
parameter IDLE      = 2'b00;
parameter PRE_SEND  = 2'b01;
parameter SEND      = 2'b10;

reg [1:0] state, next_state;
reg [4:0] bit_counter;
reg [15:0] shift_reg;
reg send_phase;

//==================== 状态转移逻辑 ====================
always @(posedge McBSPClk or negedge nRst) begin
    if (!nRst) state <= IDLE;
    else state <= next_state;
end

always @(*) begin
//    next_state = state;
    case (state)
        IDLE:
             if (tRequest)
              next_state = PRE_SEND; // 进入准备状态
            else 
              next_state = IDLE;

        PRE_SEND:
         next_state = SEND;                   // 下一周期进入发送

        SEND:
             if (bit_counter == 5'd0) 
                next_state = IDLE;
            else
                next_state = SEND;

        default:  next_state = IDLE;

    endcase
end

//==================== 数据路径控制 ====================
always @(posedge McBSPClk or negedge nRst) begin
    if (!nRst) begin
        FSX       <= 1'b0;
        DX        <= 1'b0;
        busIdle   <= 1'b0;
        send_done <= 1'b0;        // 复位初始化
        shift_reg <= 16'b0;
        bit_counter <= 5'd15;
        send_phase <= 1'b0;
    end else begin
        send_done <= 1'b0;        // 默认保持低电平
        case (state)
            IDLE: begin
                FSX <= 1'b0;
                DX <= 1'b0;
                busIdle <= 1'b0;
                send_phase <= 1'b0;
                if (tRequest) begin 
                shift_reg <= tData;
                busIdle <= 1'b1;
                end
            end

            PRE_SEND: begin
                busIdle <= 1'b1;
                bit_counter <= 5'd15;  // 重置计数器
                if (!send_phase) begin
                    // Phase 1: FSX同步阶段
                    FSX <= 1'b1;
                    DX <= 1'b0;
                    send_phase <= 1'b1;
                end
            end

            SEND: begin
                busIdle <= 1'b1;
                
//                if (!send_phase) begin
//                    // Phase 1: FSX同步阶段
//                    FSX <= 1'b1;
//                    DX <= 1'b0;
//                    send_phase <= 1'b1;
//                    // Phase 2: 数据发送阶段
                    FSX <= 1'b0;
                    DX <= shift_reg[bit_counter];
                    
                    // 发送完成判断
                    if (bit_counter == 5'd0) begin
                        send_done <= 1'b1;  // 发送完成标志拉高
                        bit_counter <= 5'd15;
                    end else begin
                        bit_counter <= bit_counter - 1;
                    end
                end
        endcase
    end
end

endmodule
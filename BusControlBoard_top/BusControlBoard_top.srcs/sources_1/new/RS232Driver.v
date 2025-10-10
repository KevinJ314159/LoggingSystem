/*需要确认Rs232_clk是否就是波特率时钟*/

module RS232Driver (
    input  wire        clk,            // 10MHz时钟
    input  wire        Rs232_clk,       // 波特率时钟：每个上升沿发送一个 bit
    input  wire        rst_n,          // 异步复位，低有效
    input  wire        send_req,       // 发送请求信号
    input  wire [7:0]  data_in,        // 待发送的 8 位数据
    
    output reg         tx_out,         // 串行发送数据线（空闲时为高电平）
    output reg         bus_state,      // 总线状态：1 表示忙碌，0 表示空闲
    output reg         send_done       // 发送完成信号
);

    // 用于存储 1 起始位 + 8 数据位 + 2 停止位 = 11 位
    reg [9:0] shift_reg;
    reg [3:0] bit_cnt;  // 计数范围 0~9 即可
    reg send_req_flag;
//    reg Abit_sendOk;

    wire baud_clk;

    Rs232clk_edge_detecter Rs232clk_edge_detecter_instance(
    .Rs232Clk(Rs232_clk),       // 来自解串器的恢复时钟
    .CLK_10MHZ(clk),         // 10MHz 时钟
    .nRst(rst_n),               // 复位信号，低电平有效
    .Rs232ClkPosedge_detected(baud_clk)  // 232波特率时钟上升沿检测标志);
    );


    // 定义状态的编码
    localparam IDLE = 2'd0,        // 等待发送请求
               SENDING = 2'd1,     // 发送状态
               SEND_COMPLETE = 2'd2; // 发送完成状态

    reg [1:0] state, next_state;  // 当前状态和下一个状态


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_req_flag <= 1'b0;
        end else begin
            send_req_flag <= send_req;
        end
    end

    // 状态机的状态转移逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;  // 复位时状态机进入空闲状态
        end else begin
            state <= next_state;  // 进入下一个状态
        end
    end


    // 计算下一个状态
    always @(*) begin
        case(state)
            IDLE: begin
                if (send_req_flag) begin
                    next_state = SENDING;  // 收到发送请求，进入发送状态
                end else begin
                    next_state = IDLE;  // 保持在空闲状态
                end
            end
            SENDING: begin
                if (bit_cnt == 4'd10) begin
                    next_state = SEND_COMPLETE;  // 发送完成，进入完成状态
                end else begin
                    next_state = SENDING;  // 保持在发送状态
                end
            end
            SEND_COMPLETE: begin
                next_state = IDLE;  // 发送完成后返回到空闲状态
            end
            default: next_state = IDLE;  // 默认回到空闲状态
        endcase
    end

    // 发送数据逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_out    <= 1'b1;        // 空闲时发送线为高电平
            shift_reg <= 11'b11111_111111;
            bit_cnt   <= 4'd0;
//            send_req_flag <= 1'b0;
//            Abit_sendOk <= 1'b0;
            send_done <= 1'b0;
            bus_state <= 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    send_done <= 1'b0;  // 发送完成信号清零
                    bus_state <= 1'b0;   // 总线空闲
                    if (send_req_flag) begin
                        shift_reg <= {1'b1, data_in, 1'b0};  // 发送请求标志
                    end
                end

                 SENDING: begin
                    // 在发送状态保持 bus_state = 1
                    bus_state <= 1'b1;

                    // 只有检测到 baud_clk_rise 时，才进行发送动作、bit_cnt++ 
                    if (baud_clk) begin
                        // 用 case(bit_cnt) 逐位发送 shift_reg[bit_cnt]
                        case(bit_cnt)
                            4'd0: tx_out <= shift_reg[0];  // 起始位
                            4'd1: tx_out <= shift_reg[1];
                            4'd2: tx_out <= shift_reg[2];
                            4'd3: tx_out <= shift_reg[3];
                            4'd4: tx_out <= shift_reg[4];
                            4'd5: tx_out <= shift_reg[5];
                            4'd6: tx_out <= shift_reg[6];
                            4'd7: tx_out <= shift_reg[7];
                            4'd8: tx_out <= shift_reg[8];
                            4'd9: tx_out <= shift_reg[9];  // 停止位
//                            4'd10: tx_out <= shift_reg[10];  // 停止位
                            default: tx_out <= 1'b1;        // 冗余保护
                        endcase

                        // 发送完一位后 bit_cnt +1
                        if (bit_cnt <= 4'd9)
                            bit_cnt <= bit_cnt + 1'b1;
                        else if (bit_cnt == 4'd10) begin
//                        bus_state <= 1'b0;
//                        Abit_sendOk <= 1'b1;
                    end
                end
                end

                SEND_COMPLETE: begin
                    send_done <= 1'b1;  // 发送完成，发送完成信号为1
                    bus_state <= 1'b0;  // 总线空闲
                    bit_cnt <= 4'd0;
//                    Abit_sendOk <= 1'b0;
//                    if (Abit_sendOk) begin
//                        state <= IDLE;  // 发送完成后，返回空闲状态
//                    end
                end

                default: begin
                    tx_out    <= 1'b1;  // 空闲线高电平
                    send_done <= 1'b0;
                    bus_state <= 1'b0;
                end
            endcase
        end
    end

endmodule

module UlRdRAMControl_s(
    input  wire        clk,
    input  wire        nRst,
    input  wire        bus_state,       // McBSP_16B的发送总线状态：1表示忙，0表示空闲
    input  wire        UlDataRevEnable,     // 来自井下串并控制的成功同步信号，代表地面到井下通路建立
    input  wire        ABitSendOk,          // 来自McBSP_16B的两字节发送完成标志
    input  wire [7:0]  decodedData_8bit,  // 解码后解码器输出的数据
    input  wire        send_data,   // 来自解码器的输出有效信号，在正常读RAM数据时转发给RS2323即可

    // 来自写控制器：哪块 RAM 已写满
    input  wire [1:0]  UlRAM_wr_state,

    // 发送给写控制器：哪块 RAM 已读完
    output reg  [1:0]  UlRAM_rd_state,

    //--------------------------------------------
    // 用于读 RAM 的接口
    // 通常需要输出：读地址(rdAddr)、读使能(rdEn) 等
    // 并从外部接收 RAM 数据
    // 这里示例中，把“读到的数据”也作为本模块输出
    //--------------------------------------------
    output reg         rdRAMEn,       // 读使能
    output reg  [9:0]  rdRAMAddr,     // 读地址
//    input  wire [9:0]  ramDataIn,     // 来自 RAM 的读数据

    // 读出后输出给更上层或下游
    output reg  [15:0] rdDataOut,     // 给McBSP_16B 的 16Bit数据
    output reg         rdDataOutEn,    // 给解码器的输入有效信号(比rdRAMEn延后一周期)
    output reg         decode_continue,     // 给解码器输入的一帧有效信号
    output reg         send_req,     // 提供给McBSP_16B 的发送请求，在Ack_send状态中自行驱动拉高，在正常读取RAM数据时转发来自解码器的输出有效信号即可
    output reg         test
);

//////////////////////////////////////////////////////
// 1) 常量定义
//////////////////////////////////////////////////////

localparam RAM0_START = 10'd0;
localparam RAM0_END   = 10'd261;
localparam RAM1_START = 10'd512;
localparam RAM1_END   = 10'd773;

localparam S_IDLE     = 3'd0,
           S_READ0    = 3'd1,
           S_READ1    = 3'd2,
           S_DONE_0   = 3'd3,
           S_DONE_1   = 3'd4,
           S_SEND_ACK = 3'd5;

reg [2:0] counter;       // 维持Rd_state状态计数器
reg [2:0] cstate, nstate;
reg [9:0] rdAddrReg;
reg Ack_sendedFlag;
reg read_enable_flag;
reg [8:0] Ack_sendCount;
reg decode_continue_d1;     // 延迟一个周期

reg [1:0] phase_counter;     // 控制连续读取两个地址的计数器
reg [15:0] data_16bit_buffer; // 16位数据缓存
reg [1:0] buffer_Full;            // 16位数据缓存器满标志
reg s3_hold;
//////////////////////////////////////////////////////
// 2) 主状态机：现态/次态
//////////////////////////////////////////////////////
always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else if(UlDataRevEnable)
        cstate <= nstate;
    else 
        cstate <= S_IDLE;
end

always @(*) begin
    nstate = cstate;
    case(cstate)
    //------------------------------------------------
    // S_IDLE：空闲，等待写控制器的写满信号
    //------------------------------------------------
    S_IDLE: begin
        if ((!Ack_sendedFlag) && UlDataRevEnable)
            nstate = S_SEND_ACK;
        else if(UlRAM_wr_state[0] && !bus_state) begin
            nstate = S_READ0;
//            decode_continue <= 1'b0;
        end
        else if(UlRAM_wr_state[1] && !bus_state) begin
            nstate = S_READ1;
//            decode_continue <= 1'b0;
        end
        else
            nstate = S_IDLE;
    end

    //------------------------------------------------
    // S_READ0：读取 RAM0 地址(0~261)
    //------------------------------------------------
    S_READ0: begin
        if(rdAddrReg >= RAM0_END && !bus_state)
            nstate = S_DONE_0;
        else
            nstate = S_READ0;
    end

    //------------------------------------------------
    // S_READ1：读取 RAM1 地址(512~773)
    //------------------------------------------------
    S_READ1: begin
        if(rdAddrReg >= RAM1_END && !bus_state)
            nstate = S_DONE_1;
        else
            nstate = S_READ1;
    end

    //------------------------------------------------
    // S_DONE_0：读完 RAM0，置 rd_state[0] = 1
    //------------------------------------------------
    S_DONE_0: begin
        if (s3_hold)
            nstate = S_IDLE;
        else 
            nstate = S_DONE_0;
    end

    //------------------------------------------------
    // S_DONE_1：读完 RAM1，置 rd_state[1] = 1
    //------------------------------------------------
    S_DONE_1: begin
        if (s3_hold)
            nstate = S_IDLE;
        else 
            nstate = S_DONE_1;
    end

    S_SEND_ACK: begin
        if (Ack_sendedFlag)
            nstate = S_IDLE;
        else
            nstate = S_SEND_ACK;
    end

    default: nstate = S_IDLE;
    endcase
end

// 在读控制模块的S_DONE状态之后加一个计数器，延时清除读标志
reg [2:0] delayCounter;  // 延迟计数器


always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        delayCounter <= 3'd0;
        test <= 1'b0;
        s3_hold            <= 0;
    end else if (cstate == S_DONE_0 || cstate == S_DONE_1) begin
        if (delayCounter < 3'd5) begin
            delayCounter <= delayCounter + 1'b1;
        end else begin
            s3_hold <= 1;
            delayCounter <= 3'd0; // 重置计数器
        end
    end else begin
            s3_hold <= 0;
            delayCounter <= 3'd0; // 重置计数器
    end
end

///////////////////////////////////////////
//控制向McBSP_16B转发使能和数据
//////////////////////////////////////////
always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        ////////////////////////////////////////////////////
        // 复位信号初始化
        ////////////////////////////////////////////////////
        buffer_Full        <= 2'd0;
        data_16bit_buffer  <= 16'd0;
        send_req           <= 1'b0;
        rdRAMEn            <= 1'b0;
        rdRAMAddr          <= 10'd0;
        rdAddrReg          <= 10'd0;
        UlRAM_rd_state     <= 2'b00;
        rdDataOut          <= 16'd0;
        rdDataOutEn        <= 1'b0;
        Ack_sendCount      <= 9'd0;

        Ack_sendedFlag     <= 0;
        read_enable_flag   <= 0;
        decode_continue    <= 1'b0;
        decode_continue_d1 <= 1'b0;
        phase_counter      <= 2'd0;
    end else if (!UlDataRevEnable) begin
        ////////////////////////////////////////////////////
        // 数据接收使能关闭时的清理
        ////////////////////////////////////////////////////
        Ack_sendedFlag <= 0;
    end else begin
        ////////////////////////////////////////////////////
        // 默认值初始化
        ////////////////////////////////////////////////////
        rdRAMEn     <= 1'b0;
        rdDataOutEn <= rdRAMEn;
        decode_continue <= decode_continue_d1;
        send_req    <= 1'b0;  // 默认关闭发送请求

        case(cstate)
            //------------------------------------------------
            // S_IDLE
            //------------------------------------------------
            S_IDLE: begin
                UlRAM_rd_state  <= 2'b00;
                if (UlRAM_wr_state[0] && !bus_state) begin
                    rdAddrReg <= RAM0_START;
                    read_enable_flag <= 1'b0;
                    decode_continue <= 1'b0;
                end else if (UlRAM_wr_state[1] && !bus_state) begin
                    rdAddrReg <= RAM1_START;
                    read_enable_flag <= 1'b0;
                    decode_continue <= 1'b0;
                end else begin
                    rdAddrReg       <= 10'd0;
                    decode_continue <= 1'b0;
                    rdRAMAddr       <= 10'd0;
//                    s3_hold <= 0;
                end
            end

            //------------------------------------------------
            // S_READ0：连续读取 RAM0（整合buffer控制逻辑）
            //------------------------------------------------
            S_READ0: begin
                /* RAM读取控制 */
                    test <= 1'b1;
                if (phase_counter < 2'd2 && nstate == S_READ0) begin
                    rdRAMEn <= 1'b1;
                    rdRAMAddr <= rdAddrReg + phase_counter;
                    phase_counter <= phase_counter + 1;
                end else if (ABitSendOk) begin
                    phase_counter <= 2'd0;
                    rdAddrReg <= rdAddrReg + 2;
                end
                decode_continue_d1 <= 1'b1;

                /* 数据buffer控制 */
                if ((buffer_Full == 2'd0) && send_data) begin
                    buffer_Full <= 2'd1;
                    data_16bit_buffer[15:8] <= decodedData_8bit;
                end else if ((buffer_Full == 2'd1) && send_data) begin
                    buffer_Full <= 2'd0;
                    data_16bit_buffer[7:0] <= decodedData_8bit;
                    send_req <= 1'b1;
                    rdDataOut <= {data_16bit_buffer[15:8], decodedData_8bit};
                end else if (buffer_Full == 2'd2) begin
                    buffer_Full <= 2'd0;
                end else begin
                    buffer_Full <= 2'd0;
                    data_16bit_buffer <= 16'd0;
                end
            end

            //------------------------------------------------
            // S_READ1：连续读取 RAM1（整合buffer控制逻辑）
            //------------------------------------------------
            S_READ1: begin
                /* RAM读取控制 */
                if (phase_counter < 2'd2 && nstate == S_READ1) begin
                    rdRAMEn <= 1'b1;
                    rdRAMAddr <= rdAddrReg + phase_counter;
                    phase_counter <= phase_counter + 1;
                end else if (ABitSendOk) begin
                    phase_counter <= 2'd0;
                    rdAddrReg <= rdAddrReg + 2;
                end
                decode_continue_d1 <= 1'b1;

                /* 数据buffer控制 */
                if ((buffer_Full == 2'd0) && send_data) begin
                    buffer_Full <= 2'd1;
                    data_16bit_buffer[15:8] <= decodedData_8bit;
                end else if ((buffer_Full == 2'd1) && send_data) begin
                    buffer_Full <= 2'd0;
                    data_16bit_buffer[7:0] <= decodedData_8bit;
                    send_req <= 1'b1;
                    rdDataOut <= {data_16bit_buffer[15:8], decodedData_8bit};
                end else if (buffer_Full == 2'd2) begin
                    buffer_Full <= 2'd0;
                end else begin
                    buffer_Full <= 2'd0;
                    data_16bit_buffer <= 16'd0;
                end
            end

            //------------------------------------------------
            // 其他状态（保持原有功能）
            //------------------------------------------------
            S_DONE_0: begin
                UlRAM_rd_state[0] <= 1'b1;
                decode_continue_d1 <= 1'b0;
                phase_counter <= 2'd0;
            end

            S_DONE_1: begin
                UlRAM_rd_state[1] <= 1'b1;
                decode_continue_d1 <= 1'b0;
                phase_counter <= 2'd0;
            end

            S_SEND_ACK: begin
                if (!read_enable_flag) begin
                    send_req <= 1'b1;
                    read_enable_flag <= 1'b1;
                end else 
                    send_req <= 1'b0;

                case(Ack_sendCount)
                    9'd0:  rdDataOut <= 16'h4747;
                    9'd1:  rdDataOut <= 16'h0F00;
                    9'd2:  rdDataOut <= 16'h55AA;
                    9'd3:  rdDataOut <= 16'h00FF;
                    9'd4:  rdDataOut <= 16'h0100;
                    default: rdDataOut <= 16'h0000;
                endcase

                if (ABitSendOk && (Ack_sendCount < 9'd131)) begin
                    Ack_sendCount <= Ack_sendCount + 1'b1;
                    read_enable_flag <= 1'b0;
                end else if (!bus_state && Ack_sendCount >= 9'd131)
                    Ack_sendedFlag <= 1'b1;
            end
        endcase
    end
end

endmodule
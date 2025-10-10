module DlRAMRdControl(
    input  wire        clk,
    input  wire        nRst,
    input  wire        bus_state,
//    input  wire        DlDataRevEnable,     // 来自井下串并控制的成功同步信号，代表地面到井下通路建立
    input  wire        ABitSendOk,          // 来自RS232的一字节发送完成标志
    input  wire [7:0]      decodedData_8bit,  // 解码后解码器输出的数据
    input  wire send_data,   // 来自解码器的输出有效信号，在正常读RAM数据时转发给RS2323即可

    // 来自写控制器：哪块 RAM 已写满
    input  wire [1:0]  DlRAM_wr_state,

    // 发送给写控制器：哪块 RAM 已读完
    output reg  [1:0]  DlRAM_rd_state,

    //--------------------------------------------
    // 用于读 RAM 的接口
    // 通常需要输出：读地址(rdAddr)、读使能(rdEn) 等
    // 并从外部接收 RAM 数据
    // 这里示例中，把“读到的数据”也作为本模块输出
    //--------------------------------------------
    output reg         rdRAMEn,       // 读使能
    output reg  [6:0]  rdRAMAddr,     // 读地址
//    input  wire [9:0]  ramDataIn,     // 来自 RAM 的读数据

    // 读出后输出给更上层或下游
    output reg  [7:0]  rdDataOut,     // 给Rs232的8Bit数据
    output reg         rdDataOutEn,    // 给解码器的输入有效信号(比rdRAMEn延后一周期)
    output reg         decode_continue,     // 给解码器输入的一帧有效信号
    output reg         send_req     // 提供给Rs232的发送请求，在Ack_send状态中自行驱动拉高，在正常读取RAM数据时转发来自解码器的输出有效信号即可

);

//////////////////////////////////////////////////////
// 1) 常量定义
//////////////////////////////////////////////////////

localparam RAM0_START = 7'd0;
localparam RAM0_END   = 7'd37;
localparam RAM1_START = 7'd64;
localparam RAM1_END   = 7'd101;


localparam S_IDLE     = 3'd0,
           S_READ0    = 3'd1,
           S_READ1    = 3'd2,
           S_DONE_0   = 3'd3,
           S_DONE_1   = 3'd4,
           S_SEND_ACK = 3'd5;


reg [2:0]counter;       // 维持Rd_state状态计数器
reg [2:0] cstate, nstate;
reg [6:0] rdAddrReg;
//reg AckInsertFlag;      // 需要发送Ack内容标志，进入发送Ack状态后即拉低
reg Ack_sendedFlag;
reg read_enable_flag;
reg [6:0] Ack_sendCount;
reg decode_continue_d1;     // 延迟一个周期
reg s3_hold;
/*always @(posedge DlDataRevEnable or negedge nRst) begin
    if(!nRst)
        AckInsertFlag <= 1'b0;
    else
        AckInsertFlag <= 1'b1;
end*/

//////////////////////////////////////////////////////
// 2) 主状态机：现态/次态
//////////////////////////////////////////////////////
always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else
        cstate <= nstate;
end


always @(*) begin
    nstate = cstate;
    case(cstate)
    //------------------------------------------------
    // S_IDLE：空闲，等待写控制器的写满信号
    //------------------------------------------------
    S_IDLE: begin
        // 每当
        if (!Ack_sendedFlag)
            nstate = S_SEND_ACK;
        // 如果 RAM0 写满 => 读 RAM0
        else if(DlRAM_wr_state[0] && !bus_state)
            begin
            nstate = S_READ0;
//            decode_continue <= 1'b0;
            end
        // 否则如果 RAM1 写满 => 读 RAM1
        else if(DlRAM_wr_state[1] && !bus_state)
            begin
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
        // 若读到最后地址 => 转去 S_DONE_0
        if(rdAddrReg == RAM0_END && ABitSendOk)
            nstate = S_DONE_0;
        else
            nstate = S_READ0;
    end

    //------------------------------------------------
    // S_READ1：读取 RAM1 地址(512~773)
    //------------------------------------------------
    S_READ1: begin
        if(rdAddrReg == RAM1_END && ABitSendOk)
            nstate = S_DONE_1;
        else
            nstate = S_READ1;
    end

    //------------------------------------------------
    // S_DONE_0：读完 RAM0，置 rd_state[0] = 1
    //------------------------------------------------
    S_DONE_0: begin
        // 下拍回到空闲
        if ( s3_hold )
        nstate = S_IDLE;
        else 
        nstate = S_DONE_0;
            

    end

    //------------------------------------------------
    // S_DONE_1：读完 RAM1，置 rd_state[1] = 1
    //------------------------------------------------
    S_DONE_1: begin
        if ( s3_hold )
        nstate = S_IDLE;
        else 
        nstate = S_DONE_1;
    end

    S_SEND_ACK: begin
        if ( Ack_sendedFlag )
        nstate = S_IDLE;
        else
        nstate = S_SEND_ACK;
    end


    default: nstate = S_IDLE;

    endcase
end




// 在读控制模块的S_DONE状态之后加一个计数器，延时清除读标志
reg [2:0] delayCounter;  // 延迟计数器
//
reg send_reqAck,send_reqAck1,send_reqAck2,send_reqAck3,send_reqAck4,send_reqAck5;

always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        delayCounter <= 3'd0;
        s3_hold <= 0;
    end else if (cstate == S_DONE_0 || cstate == S_DONE_1) begin
        // 在读完数据后延迟5个周期再清除状态
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


//////////////////////////////////////////////////////
// 3) 输出与寄存器更新
//////////////////////////////////////////////////////
always @(posedge clk or negedge nRst) begin
    if(!nRst) begin
        rdRAMEn       <= 1'b0;
        rdRAMAddr     <= 10'd0;
        rdAddrReg     <= 10'd0;
        DlRAM_rd_state<= 2'b00;
        rdDataOut     <= 10'd0;
        rdDataOutEn   <= 1'b0;
        Ack_sendCount <= 7'd0;
//        counter       <= 3'd0;
//       s3_hold <= 0;
        Ack_sendedFlag <= 0;
        read_enable_flag <= 0;
        send_req <= 1'b0;
        decode_continue <= 1'b0;
        decode_continue_d1 <= 1'b0;


        send_reqAck5<= 0;
        send_reqAck4<= 0;
        send_reqAck3 <= 0;
        send_reqAck2 <= 0;
        send_reqAck1 <= 0;
        send_reqAck <= 0;

//        end else if(!DlDataRevEnable)
//        Ack_sendedFlag <= 0;
      end else begin
        // 默认
        rdRAMEn     <= 1'b0;
        rdDataOutEn <= rdRAMEn;
        decode_continue <= decode_continue_d1;



        // 使DlRAM_rd_state保持数个周期以便写控制能读到


        case(cstate)
        //------------------------------------------------
        // S_IDLE
        //------------------------------------------------
        S_IDLE: begin
            // 清读地址 & rd_state

        send_reqAck5<= 0;
        send_reqAck4<= 0;
        send_reqAck3 <= 0;
        send_reqAck2 <= 0;
        send_reqAck1 <= 0;
        send_reqAck <= 0;

        DlRAM_rd_state  <= 2'b00;

        if(DlRAM_wr_state[0] && !bus_state) begin
            rdAddrReg <= RAM0_START;
            read_enable_flag <= 1'b0;
            decode_continue <= 1'b0;
            end
        // 否则如果 RAM1 写满 => 读 RAM1
        else if(DlRAM_wr_state[1] && !bus_state) begin
            rdAddrReg <= RAM1_START;
            read_enable_flag <= 1'b0;
            decode_continue <= 1'b0;
            end
        else
            rdAddrReg       <= 7'd0;
            decode_continue <= 1'b0;
            rdRAMAddr       <= 7'd0;
//            DlRAM_rd_state  <= 2'b00;
//            s3_hold <= 0;
//            rdDataOut       <= 10'd0;
        end

        //------------------------------------------------
        // S_READ0：连续读取 RAM0
        //------------------------------------------------
        S_READ0: begin
            // 打开读使能
            if(!read_enable_flag) begin
            rdRAMEn   <= 1'b1;
//            rdDataOutEn <= 1'b1; // 读过程中维持高
            read_enable_flag <= 1'b1;
            end
            // 给解码器的使能和给RAM的读地址
            rdDataOutEn <= rdRAMEn;
            rdRAMAddr <= rdAddrReg;

            // 给RS232的输出
            send_req <= send_data;
            rdDataOut <= decodedData_8bit;

            decode_continue_d1 <= 1'b1;
//            decode_continue <= decode_continue_d1;
            // 将读到的数据输出
//            rdDataOut <= ramDataIn;

            if (ABitSendOk && (rdAddrReg < RAM0_END)) begin
                rdAddrReg <= rdAddrReg + 1'b1;
                read_enable_flag <= 1'b0;
                end
        end

        //------------------------------------------------
        // S_READ1：连续读取 RAM1
        //------------------------------------------------
        S_READ1: begin
            // 打开读使能
            if(!read_enable_flag) begin
            rdRAMEn   <= 1'b1;
//            rdDataOutEn <= 1'b1; // 读过程中维持高
            read_enable_flag <= 1'b1;
            end
            // 输出地址

            rdDataOutEn <= rdRAMEn;
            rdRAMAddr <= rdAddrReg;

            send_req <= send_data;
            rdDataOut <= decodedData_8bit;

            decode_continue_d1 <= 1'b1;
//            decode_continue <= decode_continue_d1;

            if (ABitSendOk && (rdAddrReg < RAM1_END)) begin
                rdAddrReg <= rdAddrReg + 1'b1;
                read_enable_flag <= 1'b0;
                end
        end

        //------------------------------------------------
        // S_DONE_0：读完 RAM0，一拍后回到空闲
        //------------------------------------------------
        S_DONE_0: begin
            DlRAM_rd_state[0] <= 1'b1; // 告知写控制器，“RAM0 读完”
            decode_continue_d1 <= 1'b0;
        end

        //------------------------------------------------
        // S_DONE_1：读完 RAM1
        //------------------------------------------------
        S_DONE_1: begin
            DlRAM_rd_state[1] <= 1'b1;
            decode_continue_d1 <= 1'b0;
        end

        S_SEND_ACK: begin

        
        send_reqAck4 <= send_reqAck5;
        send_reqAck3 <= send_reqAck4;
        send_reqAck2 <= send_reqAck3;
        send_reqAck1 <= send_reqAck2;
        send_reqAck <= send_reqAck1;
        send_req <= send_reqAck;


        if (!read_enable_flag) begin
            send_reqAck5 <= 1'b1;
            read_enable_flag <= 1'b1;
            end else 
            send_reqAck5 <= 1'b0;


            case(Ack_sendCount)
                4'd0:  rdDataOut <= 8'h47;
                4'd1:  rdDataOut <= 8'h47;
                4'd2:  rdDataOut <= 8'h0F;
                4'd3:  rdDataOut <= 8'h00;
                4'd4:  rdDataOut <= 8'h55;
                4'd5:  rdDataOut <= 8'hAA;
                4'd6:  rdDataOut <= 8'h00;
                4'd7:  rdDataOut <= 8'hFF;
                4'd8:  rdDataOut <= 8'h01;
                4'd9:  rdDataOut <= 8'h00;

                default: rdDataOut <= 8'h00;
            endcase

            if (ABitSendOk && (Ack_sendCount < 7'd37)) begin
                Ack_sendCount <= Ack_sendCount + 1'b1;
                read_enable_flag <= 1'b0;
                end else if (ABitSendOk && Ack_sendCount >= 7'd37)
                    Ack_sendedFlag <= 1'b1;
        end

        endcase
    end
end

endmodule

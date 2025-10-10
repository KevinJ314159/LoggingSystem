module UlRAMRdControl_abondon(
    input  wire        clk,
    input  wire        nRst,
    input  wire        bus_state,
    input  wire        DlDataRevEnable,     // 来自井下串并控制的成功同步信号，代表地面到井下通路建立

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
    output reg  [6:0]  rdRAMAddr,     // 读地址
//    input  wire [9:0]  ramDataIn,     // 来自 RAM 的读数据

    // 读出后输出给更上层或下游
//    output reg  [9:0]  rdDataOut,
    output reg         rdDataOutEn    // 输出有效信号(读过程保持高)
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
reg [9:0] rdAddrReg;
reg AckInsertFlag;      // 需要发送Ack内容标志，进入发送Ack状态后即拉低

always @(posedge DlDataRevEnable or negedge nRst) begin
    if(!nRst)
        AckInsertFlag <= 1'b0;
    else
        AckInsertFlag <= 1'b1;
end

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
        // 如果 RAM0 写满 => 读 RAM0
        if(UlRAM_wr_state[0] && !bus_state)
            nstate = S_READ0;
        // 否则如果 RAM1 写满 => 读 RAM1
        else if(UlRAM_wr_state[1])
            nstate = S_READ1;
        else
            nstate = S_IDLE;
    end

    //------------------------------------------------
    // S_READ0：读取 RAM0 地址(0~261)
    //------------------------------------------------
    S_READ0: begin
        // 若读到最后地址 => 转去 S_DONE_0
        if(rdAddrReg == RAM0_END)
            nstate = S_DONE_0;
        else
            nstate = S_READ0;
    end

    //------------------------------------------------
    // S_READ1：读取 RAM1 地址(512~773)
    //------------------------------------------------
    S_READ1: begin
        if(rdAddrReg == RAM1_END)
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

    default: nstate = S_IDLE;
    endcase
end


// 在读控制模块的S_DONE状态之后加一个计数器，延时清除读标志
reg [2:0] delayCounter;  // 延迟计数器
reg s3_hold;

always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        delayCounter <= 3'd0;
    end else if (cstate == S_DONE_0 || cstate == S_DONE_1) begin
        // 在读完数据后延迟5个周期再清除状态
        if (delayCounter < 3'd5) begin
            delayCounter <= delayCounter + 1'b1;
        end else begin
            s3_hold <= 1;
            delayCounter <= 3'd0; // 重置计数器
        end
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
        UlRAM_rd_state<= 2'b00;
//        rdDataOut     <= 10'd0;
        rdDataOutEn   <= 1'b0;
//        counter       <= 3'd0;
        s3_hold <= 0;
    end else begin
        // 默认
        rdRAMEn     <= 1'b0;
        rdDataOutEn <= 1'b0;

        // 使UlRAM_rd_state保持数个周期以便写控制能读到


        case(cstate)
        //------------------------------------------------
        // S_IDLE
        //------------------------------------------------
        S_IDLE: begin
            // 清读地址 & rd_state
        if(UlRAM_wr_state[0])
            rdAddrReg <= RAM0_START;
        // 否则如果 RAM1 写满 => 读 RAM1
        else if(UlRAM_wr_state[1])
            rdAddrReg <= RAM1_START;
        else
            rdAddrReg       <= 10'd0;

            rdRAMAddr       <= 10'd0;
            UlRAM_rd_state  <= 2'b00;
            s3_hold <= 0;
//            rdDataOut       <= 10'd0;
        end

        //------------------------------------------------
        // S_READ0：连续读取 RAM0
        //------------------------------------------------
        S_READ0: begin
            // 打开读使能
            rdRAMEn   <= 1'b1;
            rdDataOutEn <= 1'b1; // 读过程中维持高

            // 输出地址
            rdRAMAddr <= rdAddrReg;
            // 将读到的数据输出
//            rdDataOut <= ramDataIn;

            // 地址累加
            if(rdAddrReg < RAM0_END)
                rdAddrReg <= rdAddrReg + 1'b1;
        end

        //------------------------------------------------
        // S_READ1：连续读取 RAM1
        //------------------------------------------------
        S_READ1: begin
            rdRAMEn   <= 1'b1;
            rdDataOutEn <= 1'b1;

            rdRAMAddr <= rdAddrReg;
//            rdDataOut <= ramDataIn;

            if(rdAddrReg < RAM1_END)
                rdAddrReg <= rdAddrReg + 1'b1;
        end

        //------------------------------------------------
        // S_DONE_0：读完 RAM0，一拍后回到空闲
        //------------------------------------------------
        S_DONE_0: begin
            UlRAM_rd_state[0] <= 1'b1; // 告知写控制器，“RAM0 读完”
        end

        //------------------------------------------------
        // S_DONE_1：读完 RAM1
        //------------------------------------------------
        S_DONE_1: begin
            UlRAM_rd_state[1] <= 1'b1;
        end

        endcase
    end
end

endmodule

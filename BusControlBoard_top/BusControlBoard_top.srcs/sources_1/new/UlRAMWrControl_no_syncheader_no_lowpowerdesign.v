module UlRAMWrControl(
    input  wire         clk,
    input  wire         nRst,

    // 来自 McBSPDriver_16bTo8b 的 8 位数据和使能
    input  wire [7:0]   inData,
    input  wire         inDataEn,

    // 来自读控制器，用于清除写状态（读完哪块 RAM，就清哪块的写满标志）
    input  wire [1:0]   UlRAM_rd_state,

    // 输出：写 RAM 地址
    output reg  [9:0]   wrUlRAMAddr,
    // 输出：当前两块 RAM 的写状态 (0 = 未写满，1 = 已写满)
    output reg  [1:0]   UlRAM_wr_state,

    // （原来叫 UlEncodeContinue）→ 改名为 UlEncoderEn
    // 用于 8b/10b 编码器使能 
    output reg          UlEncoderEn,

    // （原来叫 UlEncoderEn）→ 改名为 UlEncodeContinue
    // 表示“编码是否继续进行”或“写状态中” 
    output reg          UlEncodeContinue,

    // 输出：写一帧数据完成标志（写满时脉冲一下）
    output reg          wrAFrameDataOkFlag,

    // 送给 8b/10b 编码器的输入
    output reg  [7:0]   UlEncoderData
);

//--------------------------------------
// 1) 参数/寄存器定义
//--------------------------------------

// 同步头：连续两字节 0x47
localparam SYNC_BYTE = 8'h47;  

// RAM0：地址 0 ~ 261
localparam RAM0_START = 10'd0;
localparam RAM0_END   = 10'd261;

// RAM1：地址 512 ~ 773
localparam RAM1_START = 10'd512;
localparam RAM1_END   = 10'd773;

// 状态机
localparam  S_IDLE      = 3'd0,
            S_WAIT_SYNC = 3'd1,
            S_WR_RAM0   = 3'd2,
            S_WR_RAM1   = 3'd3,
            S_DONE      = 3'd4;

reg [2:0] cstate, nstate;
reg [9:0] wrAddrReg;

// 用来检测连续 2 个 0x47
reg [1:0] sync47_cnt;
reg       syncDetected;  

//--------------------------------------
// 2) 主状态机：现态/次态
//--------------------------------------
always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else
        cstate <= nstate;
end



always @(*) begin
    nstate = cstate;
    case(cstate)
    //-------------------------------------
    // S_IDLE：空闲
    //-------------------------------------
    S_IDLE: begin
        if(inDataEn)
            nstate = S_WAIT_SYNC;
    end

    //-------------------------------------
    // S_WAIT_SYNC：检测连续两个 0x47
    //-------------------------------------
    S_WAIT_SYNC: begin
        if(syncDetected) begin
            // 如果 RAM0 未写满 => 写 RAM0
            if(!UlRAM_wr_state[0])
                nstate = S_WR_RAM0;
            // 否则写 RAM1
            else if(!UlRAM_wr_state[1])
                nstate = S_WR_RAM1;
            else
                nstate = S_IDLE; // 都写满就回空闲
        end
    end

    //-------------------------------------
    // S_WR_RAM0：写 RAM0
    //-------------------------------------
    S_WR_RAM0: begin
        if((wrAddrReg == RAM0_END) && inDataEn)
            nstate = S_DONE;
    end

    //-------------------------------------
    // S_WR_RAM1：写 RAM1
    //-------------------------------------
    S_WR_RAM1: begin
        if((wrAddrReg == RAM1_END) && inDataEn)
            nstate = S_DONE;
    end

    //-------------------------------------
    // S_DONE：写满收尾
    //-------------------------------------
    S_DONE: begin
        nstate = S_IDLE;
    end

    default: nstate = S_IDLE;
    endcase
end

//--------------------------------------
// 3) 输出与内部寄存器更新
//--------------------------------------
always @(posedge clk or negedge nRst) begin
    if(!nRst) begin
        UlRAM_wr_state     <= 2'b00;
        UlEncoderEn        <= 1'b0;  // （原UlEncodeContinue）
        UlEncodeContinue   <= 1'b0;  // （原UlEncoderEn）
        wrAFrameDataOkFlag <= 1'b0;
        UlEncoderData      <= 8'd0;
        wrUlRAMAddr        <= 10'd0;
        wrAddrReg          <= 10'd0;
        sync47_cnt         <= 2'd0;
        syncDetected       <= 1'b0;
    end
    else begin
        // 默认
        UlEncoderEn        <= 1'b0; // 原先UlEncodeContinue
        wrAFrameDataOkFlag <= 1'b0;

        // 如果读控制器读完某块 RAM，则清对应的写满标志
        if(UlRAM_rd_state[0])
            UlRAM_wr_state[0] <= 1'b0;
        if(UlRAM_rd_state[1])
            UlRAM_wr_state[1] <= 1'b0;

        case(cstate)
        //-------------------------------------
        // S_IDLE
        //-------------------------------------
        S_IDLE: begin
            UlEncodeContinue <= 1'b0; // （原UlEncoderEn）
            wrAddrReg        <= 10'd0;
            wrUlRAMAddr      <= 10'd0;
            sync47_cnt       <= 2'd0;
            syncDetected     <= 1'b0;
        end

        //-------------------------------------
        // S_WAIT_SYNC
        //-------------------------------------
        S_WAIT_SYNC: begin
            UlEncodeContinue <= 1'b0;
            if(inDataEn) begin
                if(inData == SYNC_BYTE) begin
                    sync47_cnt <= sync47_cnt + 1'b1;
                end
                else begin
                    sync47_cnt <= 2'd0;
                end
                if(sync47_cnt == 2'd1 && (inData == SYNC_BYTE))
                    syncDetected <= 1'b1;
            end
        end

        //-------------------------------------
        // S_WR_RAM0：写 RAM0
        //-------------------------------------
        S_WR_RAM0: begin
            UlEncodeContinue <= 1'b1;  // （原UlEncoderEn）
            if(wrAddrReg < RAM0_START)
                wrAddrReg <= RAM0_START;

            if(inDataEn) begin
                wrUlRAMAddr   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;   // （原UlEncodeContinue）
                UlEncoderData <= inData;
            end

            if((wrAddrReg == RAM0_END) && inDataEn) begin
                UlRAM_wr_state[0]  <= 1'b1;
                wrAFrameDataOkFlag <= 1'b1;
            end
        end

        //-------------------------------------
        // S_WR_RAM1：写 RAM1
        //-------------------------------------
        S_WR_RAM1: begin
            UlEncodeContinue <= 1'b1;  // （原UlEncoderEn）
            if(wrAddrReg < RAM1_START)
                wrAddrReg <= RAM1_START;

            if(inDataEn) begin
                wrUlRAMAddr   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;  // （原UlEncodeContinue）
                UlEncoderData <= inData;
            end

            if((wrAddrReg == RAM1_END) && inDataEn) begin
                UlRAM_wr_state[1]  <= 1'b1;
                wrAFrameDataOkFlag <= 1'b1;
            end
        end

        //-------------------------------------
        // S_DONE：写满收尾
        //-------------------------------------
        S_DONE: begin
            UlEncodeContinue <= 1'b0;
        end

        endcase
    end
end

endmodule

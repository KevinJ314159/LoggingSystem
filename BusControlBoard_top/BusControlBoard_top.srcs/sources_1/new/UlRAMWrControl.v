/*此模块用于控制将经过8b/10b编码的数据写入RAM*/
/*目前通过parameter TIMEOUT_MAX参数来控制超时发送机制*/
/*已添加写完成转态拖尾5个周期，仿真结果显示无需添加似乎也能正常读到尾帧*/

module UlRAMWrControl #(
    parameter TIMEOUT_MAX = 32'd100_000 // 超时阈值（可视要求修改）
)

(
    input  wire         clk,
    input  wire         nRst,

    // 来自 McBSPDriver_16bTo8b 的 8 位数据和使能
    input  wire [7:0]   inData,
    input  wire         inDataEn,

    // 来自读控制器，用于清除写状态（读完哪块 RAM，就清哪块的写满标志）
    input  wire [1:0]   UlRAM_rd_state,

    // 输出：写 RAM 地址
    output reg  [9:0]   wrUlRAMAddr,
    // 输出：当前两块 RAM 的写状态 (0=未写满，1=写满)
    output reg  [1:0]   UlRAM_wr_state,

    // 8b/10b编码器使能(单字节) 以及写过程状态指示（写过程常高）

    output reg          UlEncoderEn,       // 给编码器的“单字节使能”
    output reg          UlEncodeContinue,  // 当前是否处于写过程

    // 写一帧数据完成标志（写满时拉高一周期）
    output reg          wrAFrameDataOkFlag,

    // 送给 8b/10b 编码器的输入
    output reg  [7:0]   UlEncoderData

    // 新增：写控制器发现长时间无数据的信号

);



//--------------------------------------
// 1) 参数/寄存器定义
//--------------------------------------
localparam SYNC_BYTE  = 8'h47;  
localparam RAM0_START = 10'd0;
localparam RAM0_END   = 10'd261;
localparam RAM1_START = 10'd512;
localparam RAM1_END   = 10'd773;

localparam S_IDLE       = 3'd0,
           S_WAIT_SYNC  = 3'd1,
           S_WR_RAM0    = 3'd2,
           S_WR_RAM1    = 3'd3,
           S_DONE       = 3'd4;

reg [2:0] cstate, nstate;
reg [9:0] wrAddrReg;

// 检测到的0x47个数
reg [1:0] sync47_cnt;  
reg       syncDetected;

// 超时计数器
reg [31:0] timeOutCnt;
//reg forceReadFlag_done;

reg [2:0] delayCounter;  // 延迟计数器
reg s4_hold;
reg forceReadFlag_done;
reg          forceReadFlag;

reg [9:0] wrUlRAMAddr_delay1 , wrUlRAMAddr_delay2;

// 写完状态延长尾（5个周期）
always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        delayCounter <= 3'd0;
        s4_hold <= 0;
    end else if (cstate == S_DONE) begin
        // 在写完数据后延迟5个周期再清除状态
        if (delayCounter < 3'd5) begin
            delayCounter <= delayCounter + 1'b1;
        end else begin
            s4_hold <= 1;   // 拉高后才能回到空闲态
            delayCounter <= 3'd0; // 重置计数器
        end
    end else begin
            s4_hold <= 0;
            delayCounter <= 3'd0; // 重置计数器
    end
end


//--------------------------------------
// 2) 主状态机：现态/次态
//--------------------------------------
    // 状态机逻辑
always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else
        cstate <= nstate;
end

    // 状态转移逻辑
always @(*) begin
    nstate = cstate;      // 暂时删除
    case(cstate)
    //-------------------------------------
    // S_IDLE：空闲
    //-------------------------------------
    /*S_IDLE: begin               // (早期版本，疑似会在同步头前有其它干扰时出错)
        // 如果在本拍检测到 0x47，就先做部分检测+写操作，然后下一拍再正式转入 S_WAIT_SYNC
        // 否则，继续维持空闲状态

        if(inDataEn) begin
            // 不管是否47，都可先转到S_WAIT_SYNC, 
            // 但写不写，要看inData是否=47
            nstate = S_WAIT_SYNC;
        end
    end*/

        S_IDLE: begin
        // 如果在本拍检测到 0x287，就先做部分检测+写操作，然后下一拍再正式转入 S_WAIT_SYNC
        // 否则，继续维持空闲状态

        if(inDataEn && inData == SYNC_BYTE) begin
            // 检测是否287，是的话转到S_WAIT_SYNC, 
            // 同时将inData=287写入RAM
            nstate = S_WAIT_SYNC;
        end
        else 
        nstate = S_IDLE;
    end

    //-------------------------------------
    // S_WAIT_SYNC：等待第二个 0x47
    //-------------------------------------

/*    S_WAIT_SYNC: begin              (早期版本，疑似会在同步头前有其它干扰时出错)
        if(syncDetected) begin
            // 连续两次47已检测到
            if(!UlRAM_wr_state[0]) 
                nstate = S_WR_RAM0;
            else if(!UlRAM_wr_state[1])
                nstate = S_WR_RAM1;
            else
                nstate = S_IDLE;
        end
    end     */


        S_WAIT_SYNC: begin            // (同下行数据版本)
        if(inData == SYNC_BYTE) begin
            // 连续两次287已检测到
            if(!UlRAM_wr_state[0]) 
                nstate = S_WR_RAM0;
            else if(!UlRAM_wr_state[1])
                nstate = S_WR_RAM1;
            end
            
            else
                nstate = S_IDLE;
        
    end

    S_WR_RAM0: begin
        if(((wrAddrReg == RAM0_END) && inDataEn) || forceReadFlag_done)
            nstate = S_DONE;
    end

    S_WR_RAM1: begin
        if(((wrAddrReg == RAM1_END) && inDataEn) || forceReadFlag_done)
            nstate = S_DONE;
    end

    S_DONE: begin
        if (s4_hold)
            nstate = S_IDLE;
        else 
            nstate = S_DONE;

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
        UlEncoderEn        <= 1'b0; 
        UlEncodeContinue   <= 1'b0; 
        wrAFrameDataOkFlag <= 1'b0;
        UlEncoderData      <= 8'd0;
        wrUlRAMAddr        <= 10'b0;
        sync47_cnt         <= 2'd0;
        syncDetected       <= 1'b0;
        timeOutCnt         <= 32'd0;
        forceReadFlag      <= 1'b0;
//        s4_hold <= 0;
        forceReadFlag_done <= 1'b0;
        wrAddrReg          <= 10'd0;
        wrUlRAMAddr_delay1 <= 10'b0;
        wrUlRAMAddr_delay2 <= 10'b0;
//        forceReadFlag_done <= 1'b0;
    end
    else begin
        // 默认

        wrUlRAMAddr_delay2 <= wrUlRAMAddr_delay1;       // 用于将输出到RAM的地址线延迟两拍，用以预防RAM延迟
        wrUlRAMAddr <= wrUlRAMAddr_delay2;

        UlEncoderEn        <= 1'b0; 
        wrAFrameDataOkFlag <= 1'b0;

        // 超时计数逻辑
        if(inDataEn)
            timeOutCnt <= 32'd0;
        else if(timeOutCnt < TIMEOUT_MAX)
            timeOutCnt <= timeOutCnt + 1'b1;

        if(timeOutCnt >= TIMEOUT_MAX) begin
            forceReadFlag <= 1'b1;
        end
//        else begin
            // forceReadFlag <= 1'b0; // 视需求
//        end

        // 读控制器读完 => 清写满
        if(UlRAM_rd_state[0])
            UlRAM_wr_state[0] <= 1'b0;
        if(UlRAM_rd_state[1])
            UlRAM_wr_state[1] <= 1'b0;

        case(cstate)
        //-------------------------------------
        // S_IDLE
        //-------------------------------------
        S_IDLE: begin
            UlEncodeContinue <= 1'b0;
            if (UlRAM_wr_state[0])
            wrAddrReg        <= RAM1_START;
            else if (UlRAM_wr_state[1])
            wrAddrReg        <= RAM0_START;
            else 
            wrAddrReg <= 10'd0;

            wrUlRAMAddr_delay1      <= 10'd0;
            sync47_cnt       <= 2'd0;
            syncDetected     <= 1'b0;
            wrAFrameDataOkFlag <= 1'b0;
//            s4_hold <= 0;

            // 在 S_IDLE 时，若本拍inDataEn=1 && inData=0x47
            // 就立即写这第一个47
            if(inDataEn && inData == SYNC_BYTE) begin
                wrUlRAMAddr_delay1   <= wrAddrReg;  
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;
                UlEncodeContinue <= 1'b1;
                UlEncoderData <= inData;

                // 第一个47
                sync47_cnt <= 2'd1;
            end else begin
                sync47_cnt <= 2'd0;
                UlEncodeContinue <= 1'b0;
            end
        end

        //-------------------------------------
        // S_WAIT_SYNC
        //-------------------------------------
        S_WAIT_SYNC: begin
//            UlEncodeContinue <= 1'b0; 

            if(inDataEn) begin
                if(inData == SYNC_BYTE) begin
                    wrUlRAMAddr_delay1   <= wrAddrReg;
                    wrAddrReg     <= wrAddrReg + 1'b1;
                    UlEncoderEn   <= 1'b1;
                    UlEncodeContinue <= 1'b1;
                    UlEncoderData <= inData;

                    // 若之前 sync47_cnt=1, 
                    // 现在又是47 => 2 => syncDetected=1
                    // => 下拍跳转到 WR_RAMx
                    if(sync47_cnt == 2'd1)
                        syncDetected <= 1'b1;

                    sync47_cnt <= sync47_cnt + 1'b1; 
                end else begin
                    // 非47 => 同步中断, 重新计数
                    sync47_cnt   <= 2'd0;
                    UlEncodeContinue <= 1'b0;
                end
            end
        end

        //-------------------------------------
        // S_WR_RAM0：写 RAM0
        //-------------------------------------
        S_WR_RAM0: begin
            UlEncodeContinue <= 1'b1;  

            if(wrAddrReg < RAM0_START)
                wrAddrReg <= RAM0_START;

            if(inDataEn) begin
                wrUlRAMAddr_delay1   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1; 
                UlEncoderData <= inData;
            end

//            if((wrAddrReg == RAM0_END-1'b1) || forceReadFlag) begin
            if(((wrAddrReg == RAM0_END) && inDataEn) || forceReadFlag) begin
                UlRAM_wr_state[0] <= 1'b1;
            end

            if(forceReadFlag)
            forceReadFlag_done <= 1'b1;
        end

        //-------------------------------------
        // S_WR_RAM1：写 RAM1
        //-------------------------------------
        S_WR_RAM1: begin
            UlEncodeContinue <= 1'b1; 
            if(wrAddrReg < RAM1_START)
                wrAddrReg <= RAM1_START;

            if(inDataEn) begin
                wrUlRAMAddr_delay1   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;
                UlEncoderData <= inData;
            end
//            if((wrAddrReg == RAM1_END-1'b1) || forceReadFlag) begin
            if(((wrAddrReg == RAM1_END) && inDataEn) || forceReadFlag) begin
                UlRAM_wr_state[1]  <= 1'b1;
     //           forceReadFlag_done <= 1'b1;
                // wrAFrameDataOkFlag <= 1'b1;
            end

            if(forceReadFlag)
            forceReadFlag_done <= 1'b1;
        end

        //-------------------------------------
        // S_DONE：写满收尾
        //-------------------------------------
        S_DONE: begin
//            UlEncodeContinue <= 1'b0;
            wrAFrameDataOkFlag <= 1'b1;
            forceReadFlag_done <= 1'b0;
        end

        endcase
    end
end

endmodule

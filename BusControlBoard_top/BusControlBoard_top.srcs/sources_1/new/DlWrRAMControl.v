/*��ģ�����ڿ��ƽ����½⴮�������10Bit����д��RAM*/
/*Ŀǰͨ��parameter TIMEOUT_MAX���������Ƴ�ʱ���ͻ���*/
/*�����д���ת̬��β5�����ڣ���������ʾ��������ƺ�Ҳ����������β֡*/

module DlRAMWrControl #(
    parameter TIMEOUT_MAX = 32'd100_000 // ��ʱ��ֵ������Ҫ���޸ģ�
)

(   
//    input DlDataRevEnable,
    input  wire         clk,
    input  wire         nRst,

    // ���� ���½⴮�� �� 10 λ���ݺ�ʹ��
    input  wire [9:0]   inData,
    input  wire         inDataEn,   // 10λ�����Чʱ����

    // ���Զ����������������д״̬�������Ŀ� RAM�������Ŀ��д����־��
    input  wire [1:0]   DlRAM_rd_state,

    // �����д RAM ��ַ
    output reg  [6:0]   wrDlRAMAddr,
    // �������ǰ���� RAM ��д״̬ (0=δд����1=д��)
    output reg  [1:0]   DlRAM_wr_state,  // ��д���Ƶ������ź�


//    output reg          UlEncoderEn,       // ���������ġ����ֽ�ʹ�ܡ�
    output reg          DlDecodeContinue,  // ��ǰ�Ƿ���д����

    // дһ֡������ɱ�־��д��ʱ����һ���ڣ�
    output reg          wrAFrameDataOkFlag,

    // �͸� 8b/10b ������������
    output reg  [9:0]   DlDecoderData

    // ������д���������ֳ�ʱ�������ݵ��ź�

);

//--------------------------------------
// 1) ����/�Ĵ�������
//--------------------------------------
localparam SYNC_BYTE  = 10'h287;  
localparam RAM0_START = 7'd0;
localparam RAM0_END   = 7'd37;
localparam RAM1_START = 7'd64;
localparam RAM1_END   = 7'd101;

localparam S_IDLE       = 3'd0,
           S_WAIT_SYNC  = 3'd1,
           S_WR_RAM0    = 3'd2,
           S_WR_RAM1    = 3'd3,
           S_DONE       = 3'd4;

reg [2:0] cstate, nstate;
reg [6:0] wrAddrReg;

// ��⵽��0x287����
reg [1:0] sync287_cnt;  
reg       syncDetected;

// ��ʱ������
reg [31:0] timeOutCnt;
//reg forceReadFlag_done;

reg [2:0] delayCounter;  // �ӳټ�����
reg s4_hold;
reg forceReadFlag_done;
reg          forceReadFlag;

//wire conditional_reset = ~DlDataRevEnable | ~nRst;

// д��״̬�ӳ�β��5�����ڣ�
always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        delayCounter <= 3'd0;
        s4_hold <= 0;
    end else if (cstate == S_DONE) begin
        // ��д�����ݺ��ӳ�5�����������״̬
        if (delayCounter < 3'd5) begin
            delayCounter <= delayCounter + 1'b1;
        end else begin
            s4_hold <= 1;   // ���ߺ���ܻص�����̬
            delayCounter <= 3'd0; // ���ü�����
            end 
        
        end else begin
            s4_hold <= 0;
            delayCounter <= 3'd0; // ���ü�����
    end
end


//--------------------------------------
// 2) ��״̬������̬/��̬
//--------------------------------------
    // ״̬���߼�
/*always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else
        cstate <= nstate;
end */


always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else 
        cstate <= nstate;
//    else 
//        cstate <= S_IDLE;
end

    // ״̬ת���߼�
always @(*) begin
//    nstate = cstate;
    case(cstate)
    //-------------------------------------
    // S_IDLE������
    //-------------------------------------
    S_IDLE: begin
        // ����ڱ��ļ�⵽ 0x287�����������ּ��+д������Ȼ����һ������ʽת�� S_WAIT_SYNC
        // ���򣬼���ά�ֿ���״̬

        if(inDataEn && (inData == SYNC_BYTE || inData ==10'h2b8)) begin
            // ����Ƿ�287���ǵĻ�ת��S_WAIT_SYNC, 
            // ͬʱ��inData=287д��RAM
            nstate = S_WAIT_SYNC;
        end
        else 
        nstate = S_IDLE;
    end

    //-------------------------------------
    // S_WAIT_SYNC���ȴ��ڶ��� 0x287
    //-------------------------------------

    S_WAIT_SYNC: begin
        if(inData == SYNC_BYTE || inData ==10'h2b8) begin
            // ��������287�Ѽ�⵽
            if(!DlRAM_wr_state[0]) 
                nstate = S_WR_RAM0;
            else if(!DlRAM_wr_state[1])
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
// 3) ������ڲ��Ĵ�������
//--------------------------------------
always @(posedge clk or negedge nRst) begin
    if(!nRst) begin
        DlRAM_wr_state     <= 2'b00;
//        UlEncoderEn        <= 1'b0; 
        DlDecodeContinue   <= 1'b0; 
        wrAFrameDataOkFlag <= 1'b0;
        DlDecoderData      <= 10'd0;
        wrDlRAMAddr        <= 7'd0;
        wrAddrReg          <= 7'd0;
        sync287_cnt         <= 2'd0;
        syncDetected       <= 1'b0;
        timeOutCnt         <= 32'd0;
        forceReadFlag      <= 1'b0;
//        s4_hold <= 0;
        forceReadFlag_done <= 1'b0;
//        forceReadFlag_done <= 1'b0;
    end
    else begin
        // Ĭ��
//        UlEncoderEn        <= 1'b0; 
        wrAFrameDataOkFlag <= 1'b0;

        // ��ʱ�����߼�
        if(inDataEn)
            timeOutCnt <= 32'd0;
        else if(timeOutCnt < TIMEOUT_MAX)
            timeOutCnt <= timeOutCnt + 1'b1;

        if(timeOutCnt >= TIMEOUT_MAX) begin
            forceReadFlag <= 1'b1;
        end
        else begin
            // forceReadFlag <= 1'b0; // ������
        end

        // ������������ => ��д��
        if(DlRAM_rd_state[0])
            DlRAM_wr_state[0] <= 1'b0;
        if(DlRAM_rd_state[1])
            DlRAM_wr_state[1] <= 1'b0;

        case(cstate)
        //-------------------------------------
        // S_IDLE
        //-------------------------------------
        S_IDLE: begin
            if (DlRAM_wr_state[0])
            wrAddrReg        <= RAM1_START;
            else if (DlRAM_wr_state[1])
            wrAddrReg        <= RAM0_START;
            else 
            wrAddrReg <= 10'd0;

            wrDlRAMAddr      <= 7'd0;
            sync287_cnt       <= 2'd0;
            syncDetected     <= 1'b0;
            wrAFrameDataOkFlag <= 1'b0;
//            s4_hold <= 0;

            // �� S_IDLE ʱ��������inDataEn=1 && inData=0x47
            // ������д���һ��47
            if(inDataEn && (inData == SYNC_BYTE || inData == 10'h2b8)) begin
                DlDecodeContinue <= 1'b1; 
                wrDlRAMAddr   <= wrAddrReg;  
                wrAddrReg     <= wrAddrReg + 1'b1;
//                UlEncoderEn   <= 1'b1;
                DlDecoderData <= inData;

                // ��һ��47
                sync287_cnt <= 2'd1;
            end
            else begin
                sync287_cnt <= 2'd0;
                DlDecodeContinue <= 1'b0;
            end
        end

        //-------------------------------------
        // S_WAIT_SYNC
        //-------------------------------------
        S_WAIT_SYNC: begin
//            DlDecodeContinue <= 1'b0; 

            if(inDataEn) begin
                if(inData == SYNC_BYTE || inData == 10'h2b8) begin
                    DlDecodeContinue <= 1'b1;
                    wrDlRAMAddr   <= wrAddrReg;
                    wrAddrReg     <= wrAddrReg + 1'b1;
//                    UlEncoderEn   <= 1'b1;
                    DlDecoderData <= inData;

                    // ��֮ǰ sync47_cnt=1, 
                    // ��������47 => 2 => syncDetected=1
                    // => ������ת�� WR_RAMx
                    if(sync287_cnt == 2'd1)
                        syncDetected <= 1'b1;

                    sync287_cnt <= sync287_cnt + 1'b1; 
                end
                else begin
                    // ��47 => ͬ���ж�, ���¼���
                    sync287_cnt   <= 2'd0;
                    DlDecodeContinue <= 1'b0;
                end
            end
        end

        //-------------------------------------
        // S_WR_RAM0��д RAM0
        //-------------------------------------
        S_WR_RAM0: begin
            DlDecodeContinue <= 1'b1;  

            if(wrAddrReg < RAM0_START)
                wrAddrReg <= RAM0_START;

            if(inDataEn) begin
                wrDlRAMAddr   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
//                UlEncoderEn   <= 1'b1; 
                DlDecoderData <= inData;
            end

            if((wrAddrReg == RAM0_END) && inDataEn) begin
                DlRAM_wr_state[0]  <= 1'b1;
            end

            if(forceReadFlag)
            forceReadFlag_done <= 1'b1;
        end

        //-------------------------------------
        // S_WR_RAM1��д RAM1
        //-------------------------------------
        S_WR_RAM1: begin
            DlDecodeContinue <= 1'b1; 
            if(wrAddrReg < RAM1_START)
                wrAddrReg <= RAM1_START;

            if(inDataEn) begin
                wrDlRAMAddr   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
//                UlEncoderEn   <= 1'b1;
                DlDecoderData <= inData;
            end

            if(((wrAddrReg == RAM1_END) && inDataEn) || forceReadFlag) begin
                DlRAM_wr_state[1]  <= 1'b1;
     //           forceReadFlag_done <= 1'b1;
                // wrAFrameDataOkFlag <= 1'b1;
            end

            if(forceReadFlag)
            forceReadFlag_done <= 1'b1;
        end

        //-------------------------------------
        // S_DONE��д����β
        //-------------------------------------
        S_DONE: begin
            DlDecodeContinue <= 1'b0;
            wrAFrameDataOkFlag <= 1'b1;
            forceReadFlag_done <= 1'b0;
        end

        endcase
    end
end

endmodule

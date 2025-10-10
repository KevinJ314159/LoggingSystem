/*��ģ�����ڿ��ƽ�����8b/10b���������д��RAM*/
/*Ŀǰͨ��parameter TIMEOUT_MAX���������Ƴ�ʱ���ͻ���*/
/*�����д���ת̬��β5�����ڣ���������ʾ��������ƺ�Ҳ����������β֡*/

module UlRAMWrControl #(
    parameter TIMEOUT_MAX = 32'd100_000 // ��ʱ��ֵ������Ҫ���޸ģ�
)

(
    input  wire         clk,
    input  wire         nRst,

    // ���� McBSPDriver_16bTo8b �� 8 λ���ݺ�ʹ��
    input  wire [7:0]   inData,
    input  wire         inDataEn,

    // ���Զ����������������д״̬�������Ŀ� RAM�������Ŀ��д����־��
    input  wire [1:0]   UlRAM_rd_state,

    // �����д RAM ��ַ
    output reg  [9:0]   wrUlRAMAddr,
    // �������ǰ���� RAM ��д״̬ (0=δд����1=д��)
    output reg  [1:0]   UlRAM_wr_state,

    // 8b/10b������ʹ��(���ֽ�) �Լ�д����״ָ̬ʾ��д���̳��ߣ�

    output reg          UlEncoderEn,       // ���������ġ����ֽ�ʹ�ܡ�
    output reg          UlEncodeContinue,  // ��ǰ�Ƿ���д����

    // дһ֡������ɱ�־��д��ʱ����һ���ڣ�
    output reg          wrAFrameDataOkFlag,

    // �͸� 8b/10b ������������
    output reg  [7:0]   UlEncoderData

    // ������д���������ֳ�ʱ�������ݵ��ź�

);



//--------------------------------------
// 1) ����/�Ĵ�������
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

// ��⵽��0x47����
reg [1:0] sync47_cnt;  
reg       syncDetected;

// ��ʱ������
reg [31:0] timeOutCnt;
//reg forceReadFlag_done;

reg [2:0] delayCounter;  // �ӳټ�����
reg s4_hold;
reg forceReadFlag_done;
reg          forceReadFlag;

reg [9:0] wrUlRAMAddr_delay1 , wrUlRAMAddr_delay2;

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
always @(posedge clk or negedge nRst) begin
    if(!nRst)
        cstate <= S_IDLE;
    else
        cstate <= nstate;
end

    // ״̬ת���߼�
always @(*) begin
    nstate = cstate;      // ��ʱɾ��
    case(cstate)
    //-------------------------------------
    // S_IDLE������
    //-------------------------------------
    /*S_IDLE: begin               // (���ڰ汾�����ƻ���ͬ��ͷǰ����������ʱ����)
        // ����ڱ��ļ�⵽ 0x47�����������ּ��+д������Ȼ����һ������ʽת�� S_WAIT_SYNC
        // ���򣬼���ά�ֿ���״̬

        if(inDataEn) begin
            // �����Ƿ�47��������ת��S_WAIT_SYNC, 
            // ��д��д��Ҫ��inData�Ƿ�=47
            nstate = S_WAIT_SYNC;
        end
    end*/

        S_IDLE: begin
        // ����ڱ��ļ�⵽ 0x287�����������ּ��+д������Ȼ����һ������ʽת�� S_WAIT_SYNC
        // ���򣬼���ά�ֿ���״̬

        if(inDataEn && inData == SYNC_BYTE) begin
            // ����Ƿ�287���ǵĻ�ת��S_WAIT_SYNC, 
            // ͬʱ��inData=287д��RAM
            nstate = S_WAIT_SYNC;
        end
        else 
        nstate = S_IDLE;
    end

    //-------------------------------------
    // S_WAIT_SYNC���ȴ��ڶ��� 0x47
    //-------------------------------------

/*    S_WAIT_SYNC: begin              (���ڰ汾�����ƻ���ͬ��ͷǰ����������ʱ����)
        if(syncDetected) begin
            // ��������47�Ѽ�⵽
            if(!UlRAM_wr_state[0]) 
                nstate = S_WR_RAM0;
            else if(!UlRAM_wr_state[1])
                nstate = S_WR_RAM1;
            else
                nstate = S_IDLE;
        end
    end     */


        S_WAIT_SYNC: begin            // (ͬ�������ݰ汾)
        if(inData == SYNC_BYTE) begin
            // ��������287�Ѽ�⵽
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
// 3) ������ڲ��Ĵ�������
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
        // Ĭ��

        wrUlRAMAddr_delay2 <= wrUlRAMAddr_delay1;       // ���ڽ������RAM�ĵ�ַ���ӳ����ģ�����Ԥ��RAM�ӳ�
        wrUlRAMAddr <= wrUlRAMAddr_delay2;

        UlEncoderEn        <= 1'b0; 
        wrAFrameDataOkFlag <= 1'b0;

        // ��ʱ�����߼�
        if(inDataEn)
            timeOutCnt <= 32'd0;
        else if(timeOutCnt < TIMEOUT_MAX)
            timeOutCnt <= timeOutCnt + 1'b1;

        if(timeOutCnt >= TIMEOUT_MAX) begin
            forceReadFlag <= 1'b1;
        end
//        else begin
            // forceReadFlag <= 1'b0; // ������
//        end

        // ������������ => ��д��
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

            // �� S_IDLE ʱ��������inDataEn=1 && inData=0x47
            // ������д���һ��47
            if(inDataEn && inData == SYNC_BYTE) begin
                wrUlRAMAddr_delay1   <= wrAddrReg;  
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;
                UlEncodeContinue <= 1'b1;
                UlEncoderData <= inData;

                // ��һ��47
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

                    // ��֮ǰ sync47_cnt=1, 
                    // ��������47 => 2 => syncDetected=1
                    // => ������ת�� WR_RAMx
                    if(sync47_cnt == 2'd1)
                        syncDetected <= 1'b1;

                    sync47_cnt <= sync47_cnt + 1'b1; 
                end else begin
                    // ��47 => ͬ���ж�, ���¼���
                    sync47_cnt   <= 2'd0;
                    UlEncodeContinue <= 1'b0;
                end
            end
        end

        //-------------------------------------
        // S_WR_RAM0��д RAM0
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
        // S_WR_RAM1��д RAM1
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
        // S_DONE��д����β
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

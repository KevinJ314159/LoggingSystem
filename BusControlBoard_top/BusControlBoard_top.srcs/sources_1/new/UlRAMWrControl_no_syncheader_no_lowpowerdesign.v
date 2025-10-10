module UlRAMWrControl(
    input  wire         clk,
    input  wire         nRst,

    // ���� McBSPDriver_16bTo8b �� 8 λ���ݺ�ʹ��
    input  wire [7:0]   inData,
    input  wire         inDataEn,

    // ���Զ����������������д״̬�������Ŀ� RAM�������Ŀ��д����־��
    input  wire [1:0]   UlRAM_rd_state,

    // �����д RAM ��ַ
    output reg  [9:0]   wrUlRAMAddr,
    // �������ǰ���� RAM ��д״̬ (0 = δд����1 = ��д��)
    output reg  [1:0]   UlRAM_wr_state,

    // ��ԭ���� UlEncodeContinue���� ����Ϊ UlEncoderEn
    // ���� 8b/10b ������ʹ�� 
    output reg          UlEncoderEn,

    // ��ԭ���� UlEncoderEn���� ����Ϊ UlEncodeContinue
    // ��ʾ�������Ƿ�������С���д״̬�С� 
    output reg          UlEncodeContinue,

    // �����дһ֡������ɱ�־��д��ʱ����һ�£�
    output reg          wrAFrameDataOkFlag,

    // �͸� 8b/10b ������������
    output reg  [7:0]   UlEncoderData
);

//--------------------------------------
// 1) ����/�Ĵ�������
//--------------------------------------

// ͬ��ͷ���������ֽ� 0x47
localparam SYNC_BYTE = 8'h47;  

// RAM0����ַ 0 ~ 261
localparam RAM0_START = 10'd0;
localparam RAM0_END   = 10'd261;

// RAM1����ַ 512 ~ 773
localparam RAM1_START = 10'd512;
localparam RAM1_END   = 10'd773;

// ״̬��
localparam  S_IDLE      = 3'd0,
            S_WAIT_SYNC = 3'd1,
            S_WR_RAM0   = 3'd2,
            S_WR_RAM1   = 3'd3,
            S_DONE      = 3'd4;

reg [2:0] cstate, nstate;
reg [9:0] wrAddrReg;

// ����������� 2 �� 0x47
reg [1:0] sync47_cnt;
reg       syncDetected;  

//--------------------------------------
// 2) ��״̬������̬/��̬
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
    // S_IDLE������
    //-------------------------------------
    S_IDLE: begin
        if(inDataEn)
            nstate = S_WAIT_SYNC;
    end

    //-------------------------------------
    // S_WAIT_SYNC������������� 0x47
    //-------------------------------------
    S_WAIT_SYNC: begin
        if(syncDetected) begin
            // ��� RAM0 δд�� => д RAM0
            if(!UlRAM_wr_state[0])
                nstate = S_WR_RAM0;
            // ����д RAM1
            else if(!UlRAM_wr_state[1])
                nstate = S_WR_RAM1;
            else
                nstate = S_IDLE; // ��д���ͻؿ���
        end
    end

    //-------------------------------------
    // S_WR_RAM0��д RAM0
    //-------------------------------------
    S_WR_RAM0: begin
        if((wrAddrReg == RAM0_END) && inDataEn)
            nstate = S_DONE;
    end

    //-------------------------------------
    // S_WR_RAM1��д RAM1
    //-------------------------------------
    S_WR_RAM1: begin
        if((wrAddrReg == RAM1_END) && inDataEn)
            nstate = S_DONE;
    end

    //-------------------------------------
    // S_DONE��д����β
    //-------------------------------------
    S_DONE: begin
        nstate = S_IDLE;
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
        UlEncoderEn        <= 1'b0;  // ��ԭUlEncodeContinue��
        UlEncodeContinue   <= 1'b0;  // ��ԭUlEncoderEn��
        wrAFrameDataOkFlag <= 1'b0;
        UlEncoderData      <= 8'd0;
        wrUlRAMAddr        <= 10'd0;
        wrAddrReg          <= 10'd0;
        sync47_cnt         <= 2'd0;
        syncDetected       <= 1'b0;
    end
    else begin
        // Ĭ��
        UlEncoderEn        <= 1'b0; // ԭ��UlEncodeContinue
        wrAFrameDataOkFlag <= 1'b0;

        // ���������������ĳ�� RAM�������Ӧ��д����־
        if(UlRAM_rd_state[0])
            UlRAM_wr_state[0] <= 1'b0;
        if(UlRAM_rd_state[1])
            UlRAM_wr_state[1] <= 1'b0;

        case(cstate)
        //-------------------------------------
        // S_IDLE
        //-------------------------------------
        S_IDLE: begin
            UlEncodeContinue <= 1'b0; // ��ԭUlEncoderEn��
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
        // S_WR_RAM0��д RAM0
        //-------------------------------------
        S_WR_RAM0: begin
            UlEncodeContinue <= 1'b1;  // ��ԭUlEncoderEn��
            if(wrAddrReg < RAM0_START)
                wrAddrReg <= RAM0_START;

            if(inDataEn) begin
                wrUlRAMAddr   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;   // ��ԭUlEncodeContinue��
                UlEncoderData <= inData;
            end

            if((wrAddrReg == RAM0_END) && inDataEn) begin
                UlRAM_wr_state[0]  <= 1'b1;
                wrAFrameDataOkFlag <= 1'b1;
            end
        end

        //-------------------------------------
        // S_WR_RAM1��д RAM1
        //-------------------------------------
        S_WR_RAM1: begin
            UlEncodeContinue <= 1'b1;  // ��ԭUlEncoderEn��
            if(wrAddrReg < RAM1_START)
                wrAddrReg <= RAM1_START;

            if(inDataEn) begin
                wrUlRAMAddr   <= wrAddrReg;
                wrAddrReg     <= wrAddrReg + 1'b1;
                UlEncoderEn   <= 1'b1;  // ��ԭUlEncodeContinue��
                UlEncoderData <= inData;
            end

            if((wrAddrReg == RAM1_END) && inDataEn) begin
                UlRAM_wr_state[1]  <= 1'b1;
                wrAFrameDataOkFlag <= 1'b1;
            end
        end

        //-------------------------------------
        // S_DONE��д����β
        //-------------------------------------
        S_DONE: begin
            UlEncodeContinue <= 1'b0;
        end

        endcase
    end
end

endmodule

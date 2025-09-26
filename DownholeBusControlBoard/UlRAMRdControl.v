module UlRAMRdControl(
    input  wire        clk,
    input  wire        nRst,

    // ����д���������Ŀ� RAM ��д��
    input  wire [1:0]  UlRAM_wr_state,

    // ���͸�д���������Ŀ� RAM �Ѷ���
    output reg  [1:0]  UlRAM_rd_state,

    //--------------------------------------------
    // ���ڶ� RAM �Ľӿ�
    // ͨ����Ҫ���������ַ(rdAddr)����ʹ��(rdEn) ��
    // �����ⲿ���� RAM ����
    // ����ʾ���У��ѡ����������ݡ�Ҳ��Ϊ��ģ�����
    //--------------------------------------------
    output reg         rdRAMEn,       // ��ʹ��
    output reg  [9:0]  rdRAMAddr,     // ����ַ
//    input  wire [9:0]  ramDataIn,     // ���� RAM �Ķ�����

    // ��������������ϲ������
//    output reg  [9:0]  rdDataOut,
    output reg         rdDataOutEn    // �����Ч�ź�(�����̱��ָ�)
);

//////////////////////////////////////////////////////
// 1) ��������
//////////////////////////////////////////////////////
localparam RAM0_START = 10'd0;
localparam RAM0_END   = 10'd261;

localparam RAM1_START = 10'd512;
localparam RAM1_END   = 10'd773;

localparam S_IDLE     = 3'd0,
           S_READ0    = 3'd1,
           S_READ1    = 3'd2,
           S_DONE_0   = 3'd3,
           S_DONE_1   = 3'd4;

reg [2:0]counter;       // ά��Rd_state״̬������
reg [2:0] cstate, nstate;
reg [9:0] rdAddrReg;


// �ڶ�����ģ���S_DONE״̬֮���һ������������ʱ�������־
reg [2:0] delayCounter;  // �ӳټ�����
reg s3_hold;

//////////////////////////////////////////////////////
// 2) ��״̬������̬/��̬
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
    // S_IDLE�����У��ȴ�д��������д���ź�
    //------------------------------------------------
    S_IDLE: begin
        // ��� RAM0 д�� => �� RAM0
        if(UlRAM_wr_state[0])
            nstate = S_READ0;
        // ������� RAM1 д�� => �� RAM1
        else if(UlRAM_wr_state[1])
            nstate = S_READ1;
        else
            nstate = S_IDLE;
    end

    //------------------------------------------------
    // S_READ0����ȡ RAM0 ��ַ(0~261)
    //------------------------------------------------
    S_READ0: begin
        // ����������ַ => תȥ S_DONE_0
        if(rdAddrReg == RAM0_END)
            nstate = S_DONE_0;
        else
            nstate = S_READ0;
    end

    //------------------------------------------------
    // S_READ1����ȡ RAM1 ��ַ(512~773)
    //------------------------------------------------
    S_READ1: begin
        if(rdAddrReg == RAM1_END)
            nstate = S_DONE_1;
        else
            nstate = S_READ1;
    end

    //------------------------------------------------
    // S_DONE_0������ RAM0���� rd_state[0] = 1
    //------------------------------------------------
    S_DONE_0: begin
        // ���Ļص�����
        if ( s3_hold )
        nstate = S_IDLE;
        else 
        nstate = S_DONE_0;
            

    end

    //------------------------------------------------
    // S_DONE_1������ RAM1���� rd_state[1] = 1
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




always @(posedge clk or negedge nRst) begin
    if (!nRst) begin
        delayCounter <= 3'd0;
        s3_hold <= 0;
    end else if (cstate == S_DONE_0 || cstate == S_DONE_1) begin
        // �ڶ������ݺ��ӳ�5�����������״̬
        if (delayCounter < 3'd5) begin
            delayCounter <= delayCounter + 1'b1;
        end else begin
            s3_hold <= 1;
            delayCounter <= 3'd0; // ���ü�����
        end
    end else begin
            s3_hold <= 0;
            delayCounter <= 3'd0; // ���ü�����
    end
end


//////////////////////////////////////////////////////
// 3) �����Ĵ�������
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
//        s3_hold <= 0;
    end else begin
        // Ĭ��
        rdRAMEn     <= 1'b0;
        rdDataOutEn <= 1'b0;

        // ʹUlRAM_rd_state�������������Ա�д�����ܶ���


        case(cstate)
        //------------------------------------------------
        // S_IDLE
        //------------------------------------------------
        S_IDLE: begin
            // �����ַ & rd_state
            UlRAM_rd_state  <= 2'b00;

        if(UlRAM_wr_state[0])
            rdAddrReg <= RAM0_START;
        // ������� RAM1 д�� => �� RAM1
        else if(UlRAM_wr_state[1])
            rdAddrReg <= RAM1_START;
        else
            rdAddrReg       <= 10'd0;

            rdRAMAddr       <= 10'd0;
//            UlRAM_rd_state  <= 2'b00;
//            s3_hold <= 0;
//            rdDataOut       <= 10'd0;
        end

        //------------------------------------------------
        // S_READ0��������ȡ RAM0
        //------------------------------------------------
        S_READ0: begin
            // �򿪶�ʹ��
            rdRAMEn   <= 1'b1;
            rdDataOutEn <= 1'b1; // ��������ά�ָ�

            // �����ַ
            rdRAMAddr <= rdAddrReg;
            // ���������������
//            rdDataOut <= ramDataIn;

            // ��ַ�ۼ�
            if(rdAddrReg < RAM0_END)
                rdAddrReg <= rdAddrReg + 1'b1;
        end

        //------------------------------------------------
        // S_READ1��������ȡ RAM1
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
        // S_DONE_0������ RAM0��һ�ĺ�ص�����
        //------------------------------------------------
        S_DONE_0: begin
            UlRAM_rd_state[0] <= 1'b1; // ��֪д����������RAM0 ���ꡱ
        end

        //------------------------------------------------
        // S_DONE_1������ RAM1
        //------------------------------------------------
        S_DONE_1: begin
            UlRAM_rd_state[1] <= 1'b1;
        end

        endcase
    end
end

endmodule

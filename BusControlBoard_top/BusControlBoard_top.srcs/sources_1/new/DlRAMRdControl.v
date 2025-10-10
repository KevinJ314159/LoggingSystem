module DlRAMRdControl(
    input  wire        clk,
    input  wire        nRst,
    input  wire        bus_state,
//    input  wire        DlDataRevEnable,     // ���Ծ��´������Ƶĳɹ�ͬ���źţ�������浽����ͨ·����
    input  wire        ABitSendOk,          // ����RS232��һ�ֽڷ�����ɱ�־
    input  wire [7:0]      decodedData_8bit,  // �������������������
    input  wire send_data,   // ���Խ������������Ч�źţ���������RAM����ʱת����RS2323����

    // ����д���������Ŀ� RAM ��д��
    input  wire [1:0]  DlRAM_wr_state,

    // ���͸�д���������Ŀ� RAM �Ѷ���
    output reg  [1:0]  DlRAM_rd_state,

    //--------------------------------------------
    // ���ڶ� RAM �Ľӿ�
    // ͨ����Ҫ���������ַ(rdAddr)����ʹ��(rdEn) ��
    // �����ⲿ���� RAM ����
    // ����ʾ���У��ѡ����������ݡ�Ҳ��Ϊ��ģ�����
    //--------------------------------------------
    output reg         rdRAMEn,       // ��ʹ��
    output reg  [6:0]  rdRAMAddr,     // ����ַ
//    input  wire [9:0]  ramDataIn,     // ���� RAM �Ķ�����

    // ��������������ϲ������
    output reg  [7:0]  rdDataOut,     // ��Rs232��8Bit����
    output reg         rdDataOutEn,    // ����������������Ч�ź�(��rdRAMEn�Ӻ�һ����)
    output reg         decode_continue,     // �������������һ֡��Ч�ź�
    output reg         send_req     // �ṩ��Rs232�ķ���������Ack_send״̬�������������ߣ���������ȡRAM����ʱת�����Խ������������Ч�źż���

);

//////////////////////////////////////////////////////
// 1) ��������
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


reg [2:0]counter;       // ά��Rd_state״̬������
reg [2:0] cstate, nstate;
reg [6:0] rdAddrReg;
//reg AckInsertFlag;      // ��Ҫ����Ack���ݱ�־�����뷢��Ack״̬������
reg Ack_sendedFlag;
reg read_enable_flag;
reg [6:0] Ack_sendCount;
reg decode_continue_d1;     // �ӳ�һ������
reg s3_hold;
/*always @(posedge DlDataRevEnable or negedge nRst) begin
    if(!nRst)
        AckInsertFlag <= 1'b0;
    else
        AckInsertFlag <= 1'b1;
end*/

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
        // ÿ��
        if (!Ack_sendedFlag)
            nstate = S_SEND_ACK;
        // ��� RAM0 д�� => �� RAM0
        else if(DlRAM_wr_state[0] && !bus_state)
            begin
            nstate = S_READ0;
//            decode_continue <= 1'b0;
            end
        // ������� RAM1 д�� => �� RAM1
        else if(DlRAM_wr_state[1] && !bus_state)
            begin
            nstate = S_READ1;
//            decode_continue <= 1'b0;
            end
        else
            nstate = S_IDLE;
    end

    //------------------------------------------------
    // S_READ0����ȡ RAM0 ��ַ(0~261)
    //------------------------------------------------
    S_READ0: begin
        // ����������ַ => תȥ S_DONE_0
        if(rdAddrReg == RAM0_END && ABitSendOk)
            nstate = S_DONE_0;
        else
            nstate = S_READ0;
    end

    //------------------------------------------------
    // S_READ1����ȡ RAM1 ��ַ(512~773)
    //------------------------------------------------
    S_READ1: begin
        if(rdAddrReg == RAM1_END && ABitSendOk)
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

    S_SEND_ACK: begin
        if ( Ack_sendedFlag )
        nstate = S_IDLE;
        else
        nstate = S_SEND_ACK;
    end


    default: nstate = S_IDLE;

    endcase
end




// �ڶ�����ģ���S_DONE״̬֮���һ������������ʱ�������־
reg [2:0] delayCounter;  // �ӳټ�����
//
reg send_reqAck,send_reqAck1,send_reqAck2,send_reqAck3,send_reqAck4,send_reqAck5;

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
        // Ĭ��
        rdRAMEn     <= 1'b0;
        rdDataOutEn <= rdRAMEn;
        decode_continue <= decode_continue_d1;



        // ʹDlRAM_rd_state�������������Ա�д�����ܶ���


        case(cstate)
        //------------------------------------------------
        // S_IDLE
        //------------------------------------------------
        S_IDLE: begin
            // �����ַ & rd_state

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
        // ������� RAM1 д�� => �� RAM1
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
        // S_READ0��������ȡ RAM0
        //------------------------------------------------
        S_READ0: begin
            // �򿪶�ʹ��
            if(!read_enable_flag) begin
            rdRAMEn   <= 1'b1;
//            rdDataOutEn <= 1'b1; // ��������ά�ָ�
            read_enable_flag <= 1'b1;
            end
            // ����������ʹ�ܺ͸�RAM�Ķ���ַ
            rdDataOutEn <= rdRAMEn;
            rdRAMAddr <= rdAddrReg;

            // ��RS232�����
            send_req <= send_data;
            rdDataOut <= decodedData_8bit;

            decode_continue_d1 <= 1'b1;
//            decode_continue <= decode_continue_d1;
            // ���������������
//            rdDataOut <= ramDataIn;

            if (ABitSendOk && (rdAddrReg < RAM0_END)) begin
                rdAddrReg <= rdAddrReg + 1'b1;
                read_enable_flag <= 1'b0;
                end
        end

        //------------------------------------------------
        // S_READ1��������ȡ RAM1
        //------------------------------------------------
        S_READ1: begin
            // �򿪶�ʹ��
            if(!read_enable_flag) begin
            rdRAMEn   <= 1'b1;
//            rdDataOutEn <= 1'b1; // ��������ά�ָ�
            read_enable_flag <= 1'b1;
            end
            // �����ַ

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
        // S_DONE_0������ RAM0��һ�ĺ�ص�����
        //------------------------------------------------
        S_DONE_0: begin
            DlRAM_rd_state[0] <= 1'b1; // ��֪д����������RAM0 ���ꡱ
            decode_continue_d1 <= 1'b0;
        end

        //------------------------------------------------
        // S_DONE_1������ RAM1
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

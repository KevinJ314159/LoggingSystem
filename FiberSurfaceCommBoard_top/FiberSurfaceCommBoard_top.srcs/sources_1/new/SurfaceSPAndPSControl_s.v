
/*��Ҫ֪��input RX_Los,             // �����źŶ�ʧָʾ ����Ч��ƽĿǰ����ߵ�ƽ��ʧ*/
/*��Ҫ֪��output reg Tx_Disable        // ���ͽ����źŵ� ��Ч��ƽĿǰ����ߵ�ƽ����*/
/*��Ҫ֪��output reg UlDataOutEn,      // �������������Ч�ź�
����̫���������ʲô�ù��ܺ�DoHole_sync_success����ͬ���ɹ�ָʾ�ź��غϣ�������Ч��ƽ��Ŀǰ����ߵ�ƽʹ����Ч*/
/*������ѡͨѡ���½���ѡͨ/�½��ط��ͣ���ΪDataIn�������ؽ���*/
/*DataInEnĿǰ����ߵ�ƽ��Ч*/

module SurfaceSPAndPSControl_s (
    // ����˿�
    input CLK_100MHZ,         // 100/40 MHz ʱ���ź�
    input CLK_10MHZ,          // 10 MHz ʱ���ź�
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    input DataInEn,           //���Ե�������RAM��ģ��� ��������ʹ���ź�
    input [9:0] DataIn,       //���Ե�������RAM��ģ��� 10 λ��������
    input UpSig_RClk ,       // ���Դ���ת�����Ļָ�ʱ��
    input UpSig_nLock,      // �����źţ��͵�ƽ��ʾ��������
    input [9:0] UpSig_ROut, // ���е�����ת����10λ�������
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)

    // ����˿�
    output wire UpSig_RefClk,   // ���е�����ת���Ĳο�ʱ���ź�
    output reg UpSig_RClk_RnF, // ���е�����ת���Ľ���ʱ�ӷ�ת�ź�
    output reg UpSig_nPWRDN,   // ����ת���ĵ����ź�
    output reg UpSig_REn,      // ����ת��������ʹ���ź�
    output reg UlDataOutEn,      /* �������������Ч�źţ���̫���������ʲô�ù��ܺ�DoHole_sync_success����ͬ���ɹ�ָʾ�ź��غϣ���
                                     Ŀǰ���յ�����ͬ���뼰β֡�������ߣ�����Ϊ����������Ч��*/
    output wire [9:0] UlDataOut,  // ����10λ�������
    output wire DownSig_TClk,       // ���е�����ת���Ĵ���ʱ���ź�
    output reg DownSig_TClk_RnF,   // ����ת���Ĵ���ʱ�ӷ�ת�ź�
    output reg [9:0] DownSig_Din,  // �ṩ������ת������10λ����
    output reg DownSig_DEn,        // �����������е�����ת��������ʹ���ź�
    output reg DownSig_nPWRDN,     // ����ת�����ĵ����ź� �ź�Ϊ0ʱ������ת���������DownSig_ROut�������״̬��
    output wire DownSig_Sync1,      // ����ת������ͬ���ź�1
    output wire DownSig_Sync2,      // ����ת������ͬ���ź�2
    output reg shakehand_success // ����ͬ���ɹ�ָʾ�ź�(Ŀǰ�ھ��·���ͬ��β֡�����빤��״̬�����Ϊ���ͬ��)
//    output reg Tx_Disable        // ���ͽ����ź�
//    output reg DownSig_TDIS        // ��Ҫȷ�ϴ˽ӿ���;

);
    wire sync_success;      // ��StoPControl_instanceģ���������Ϊ�����PtoSControlģ���ͬ���ɹ��ź�
    wire SEND_LAST_FRAME_En;    // ��PtoSControl_instanceģ���������Ϊ�����DownholeSPAndPSControlģ���β֡�����ź�
    //reg [9:0] DataIn_to_send;    // ������Ҫ���������͵�����
    reg send_last_frame;    // β֡����ֱ�Ӵ�����
    reg last_frame_sended;  // β֡�ѷ��ͱ�־
    // reg last_frame_sended_one_cycle_dly;  // β֡�ѷ��ͱ�־һ���ӳ�
    // reg tem_delay;
    reg [5:0] hold_counter;  // ���ڼ��� 38 ������
    reg [1:0] detect_counter; // ���ڼ���������� 10'h287
    reg detect_flag;         // ��־λ����ʾ�Ƿ��⵽�������� 10'h287

    //���Ʒ���β֡��ֱ��������ת�����ݵ�ת̬����
    parameter SEND_FRAME_TAIL = 2'b00;        // �ȴ�ͬ���ɹ���־WAIT_SYNC_Success
    parameter WAIT_SYNC_Success = 2'b01;         // ����֡βSEND_FRAME_TAI
    parameter NORMAl = 2'b10;                  // ��������״̬
    parameter NULL = 2'b11;            // ����������״̬

    // ��ǰ״̬����һ��״̬
    reg [1:0] state, next_state;

//������ֱ��ת�����źţ�
    assign UpSig_RefClk = CLK_10MHZ;  // ֱ������ CLK_10MHZ
    assign DownSig_TClk = CLK_10MHZ;      // ֱ������ CLK_10MHZ
    assign UlDataOut = UpSig_ROut;    // ��ֱ�ӽ��⴮�����������ͬ���룩�������һ�����Ƿ���Ҫ��״̬���з�����ʵ�ֺ�UlDataOutEn�źŵ��ϸ�ͬ����

StoPControl_s StoPControl_instance(
//    .RX_Los(RX_Los),
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)
    .CLK_100MHZ(CLK_100MHZ),           // 100MHzʱ������
    .CLK_10MHZ(CLK_10MHZ),            // 10MHzʱ������
    .nRst(nRst),                 // �͵�ƽ��Ч��λ�ź�
    .UpSig_RClk (UpSig_RClk ),         // ���Դ���ת�����Ļָ�ʱ��
    .UpSig_nLock(UpSig_nLock),        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    .UpSig_ROut(UpSig_ROut),   // ����ת��������� 10 λ����
    .sync_success(sync_success)         // ͬ���ɹ���־
        );


PtoSControl_s PtoSControl_instance(
//    .RX_Los(RX_Los),
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)
    .CLK_100MHZ(CLK_100MHZ),       // 100 MHz ʱ��
    .CLK_10MHZ(CLK_10MHZ),          // 10 MHz ʱ���ź�
    .sync_success(sync_success),       // ���� StoPControl ��ͬ���ɹ���־
    .nRst(nRst),               // ��λ�źţ��͵�ƽ��Ч
    .DownSig_Sync1(DownSig_Sync1),   // ͬ���뷢��ʹ��1
    .DownSig_Sync2(DownSig_Sync2),   // ͬ���뷢��ʹ��2
    .SEND_LAST_FRAME_En(SEND_LAST_FRAME_En) // 1026��ͬ�����ѷ��ͣ�β֡����ʹ��)
        );


        //β֡����ֱ�Ӵ������߼�
    always @(posedge SEND_LAST_FRAME_En or negedge nRst) begin
        if (~nRst)
            send_last_frame <= 0;
        else if(state == SEND_FRAME_TAIL)
            send_last_frame <= 1;
    end

        /*//β֡�ѷ��ͱ�־�߼�
    always @(negedge SEND_LAST_FRAME_En or negedge nRst) begin
        if (~nRst)
            last_frame_sended <= 0;
        else
            last_frame_sended <= 1;
    end

        //β֡�ѷ��ͱ�־һ���ӳ��߼�
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)begin
            last_frame_sended_one_cycle_dly <= 0;
            tem_delay <= 0;
        end else begin
            tem_delay <= last_frame_sended;
            last_frame_sended_one_cycle_dly <= tem_delay;
            end
    end*/

    // ״̬���߼�
    always @(posedge CLK_10MHZ or negedge nRst) begin  // ����10Mhzʱ��ת��״̬
        if (~nRst)
            state <= SEND_FRAME_TAIL;
        else
            state <= next_state;
    end

    // ״̬ת���߼�
    always @(*) begin
        case (state)

            SEND_FRAME_TAIL: begin
                if (last_frame_sended)      // ����ѷ���β֡��������������״̬
                    next_state = WAIT_SYNC_Success;
                else
                    next_state = SEND_FRAME_TAIL;
            end

            WAIT_SYNC_Success: begin
                if (sync_success)
                    next_state = NORMAl;
                else
                    next_state = WAIT_SYNC_Success;
            end

            NORMAl: begin
//                if (RX_Los)                // ����յ������źŶ�ʧ��ʾ��ص��ȴ�ͬ��״̬
                if (~nRst)                // ����յ������źŶ�ʧ��ʾ��ص��ȴ�ͬ��״̬
                    next_state = SEND_FRAME_TAIL;
                else
                    next_state = NORMAl;
            end
            default: next_state = SEND_FRAME_TAIL;
        endcase
    end


    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            UpSig_RClk_RnF <= 0;  // �ڽ⴮���ָ�ʱ���½��ض�����
            DownSig_TClk_RnF <= 0;  // ���������½��ط�����
            DownSig_nPWRDN <= 1;    // ����λʱ��������������
            UpSig_REn <= 1;    //.����λʱ�Ϳ�ʼ���ս⴮�������
            UpSig_nPWRDN <= 1;    // ����λʱ�������⴮����
            DownSig_DEn <= 1;     // ����λʱ�Ϳ�ʼʹ�����������Ч��
            DownSig_Din <= 10'b00000_00000;   // ������������
            UlDataOutEn <= 0;       // �⴮�����������Ч��ʹ�ܵ�
            hold_counter <= 0;      // ��λ������
            detect_counter <= 0;    // ��λ��������
            detect_flag <= 0;       // ��λ��־λ
            last_frame_sended <= 0; 
            shakehand_success <= 0;   // ͬ������δ���
//            Tx_Disable <= 1;    // ���շ�ģ���ȹرշ��͹���
        end else begin
        case (state)

                SEND_FRAME_TAIL: begin
//                    Tx_Disable <= 0;    // ���շ�ģ�鿪�����͹���
                    DownSig_DEn <= 1;     // ������������������Ч���������Է���ͬ����
                    DownSig_nPWRDN <= 1;    // ���������빤��ת̬
                    UpSig_REn <= 1;    //.���ս⴮�������ͬ����
                    UpSig_nPWRDN <= 1;    // �⴮�����빤��״̬
                    UlDataOutEn <= 0;   // �·������Ѿ���Ч��
                    shakehand_success <= 0;
                    if(send_last_frame) begin
                    DownSig_Din <= 10'b10011_11100;
                    last_frame_sended <= 1;
                    end
                end

                WAIT_SYNC_Success: begin
//                    Tx_Disable <= 1;    // ���շ�ģ���ȹرշ��͹���
                    DownSig_DEn <= 1;     // ������������������Ч����
                    DownSig_nPWRDN <= 1;    // ���������ֹ���ת̬
                    UpSig_REn <= 1;    //.��ʼ���ս⴮�������ͬ����
                    UpSig_nPWRDN <= 1;    // �⴮�����빤��״̬
                    UlDataOutEn <= 0;       // �⴮�����������Ч��ʹ�ܵ�
                    last_frame_sended <= 0; // β֡�ѷ��ͱ�־��0
                    shakehand_success <= 0;   // ͬ������δ���
                end

                NORMAl: begin

                    DownSig_nPWRDN <= 1;    // ���������빤��ת̬
                    UpSig_REn <= 1;    //.���ս⴮�����������
                    UpSig_nPWRDN <= 1;    // �⴮�����빤��״̬
                    send_last_frame <= 0;   // β֡����ֱ�Ӵ�������0
                    last_frame_sended <= 0;    // β֡�ѷ��ͱ�־��0
                    shakehand_success <= 1;   // ͬ�����������

                    if (DataInEn) begin       // ������������״̬��DataInEn�ӹܶԴ��������ʹ�ܵĿ���
                        DownSig_DEn <= 1;
                        DownSig_Din <= DataIn;    // ֱ��ת���������ݸ�������
                        end else begin
                        DownSig_DEn <= 0;       // ȷ�������Ƿ���Ҫ�ر����д�����ʹ�ܣ�
                        DownSig_Din <= 10'b00000_00000;
                        end

                    if (UpSig_ROut == 10'h287) begin
//                        UlDataOutEn <= 1;   // �·�������Ч
                        if (detect_counter < 2)
                        detect_counter <= detect_counter + 1;  // ����������⵽�Ĵ���
                            end else begin 
                                detect_counter <= 0;  // ������� 10'h287�����ü�����
//                        UlDataOutEn <= 0;   // �·�������Ч
                     end

                     if (detect_counter == 2) begin
                        detect_flag <= 1;  // ���ñ�־λ
                        detect_counter <= 0;  // ���ü�������
                    end

                    

                    if (detect_flag) begin
//                        UlDataOutEn <= 1;   // �·�������Ч
                            if (hold_counter < 35)
                            hold_counter <= hold_counter + 1;  // ���� 38 ������
                                else begin
                                hold_counter <= 0;  // ������ɺ�����
                                detect_flag <= 0;   // �����־λ
                                UlDataOutEn <= 0;   // ���� UlDataOutEn
                                end
//                    end else begin
//                    UlDataOutEn <= 0;  // ��������±��ֵ͵�ƽ
                end

                if ((detect_flag || UpSig_ROut == 10'h287) && hold_counter < 35) begin
                    UlDataOutEn <= 1;
//                end else begin
//                    UlDataOutEn <= 0;
                end
                    //DataIn_to_send <= DataIn;
                    //DownSig_Din <= DataIn_to_send;
//                    DownSig_Din <= DataIn;    // ֱ��ת���������ݸ�������

                    //last_frame_sended_one_cycle_dly <= 0;
                    //tem_delay <= 0;
//                    UlDataOutEn <= 1;   // �·������Ѿ���Ч

                end

            endcase
    end
end

endmodule
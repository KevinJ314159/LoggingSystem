
/*��Ҫ֪��input RX_Los,             // �����źŶ�ʧָʾ ����Ч��ƽĿǰ����ߵ�ƽ��ʧ*/
/*��Ҫ֪��output reg Tx_Disable        // ���ͽ����źŵ� ��Ч��ƽĿǰ����ߵ�ƽ����*/
/*��Ҫ֪��output reg DLDataOutEn,      // �������������Ч�ź�
����̫���������ʲô�ù��ܺ�DoHole_sync_success����ͬ���ɹ�ָʾ�ź��غϣ�������Ч��ƽ��Ŀǰ����ߵ�ƽʹ����Ч*/
/*������ѡͨѡ���½���ѡͨ/�½��ط��ͣ���ΪDataIn�������ؽ���*/
/*DataInEnĿǰ����ߵ�ƽ��Ч*/

module DownholeSPAndPSControl (
    // ����˿�
//    input CLK_100MHZ,         // 40 MHz ʱ���ź�
    input CLK_10MHZ,          // 10 MHz ʱ���ź�
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    input DataInEn,           // ��������ʹ���ź�
    input [9:0] DataIn,       // 10 λ��������
    input DownSig_RClk,       // ���Դ���ת�����Ļָ�ʱ��  ֱ���ô�ʱ�������⴮���������ģ��
    input DownSig_nLock,      // �����źţ��͵�ƽ��ʾ��������
    input [9:0] DownSig_ROut, // ���е�����ת����10λ�������
//    input RX_Los,             // �����źŶ�ʧָʾ

    // ����˿�
    output wire DownSig_RefClk,   // ���е�����ת���Ĳο�ʱ���ź�
    output reg DownSig_RClk_RnF, // ���е�����ת���Ľ���ʱ�ӷ�ת�ź�
    output reg DownSig_nPWRDN,   // ����ת���ĵ����ź�
    output reg DownSig_REn,      // ����ת��������ʹ���ź�
    output wire DLDataOutEn,      /* �������������Ч�źţ���̫���������ʲô�ù��ܺ�DoHole_sync_success����ͬ���ɹ�ָʾ�ź��غϣ���
                                     Ŀǰ���յ�����ͬ���뼰β֡�������ߣ�����Ϊ����������Ч��*/
    output wire [9:0] DLDataOut,  // ����10λ�������
    output wire UpSig_TClk,       // ���е�����ת���Ĵ���ʱ���ź�
    output reg UpSig_TClk_RnF,   // ����ת���Ĵ���ʱ�ӷ�ת�ź�
    output wire [9:0] UpSig_Din,  // �ṩ������ת������10λ����
    output reg UpSig_DEn,        // �����������е�����ת��������ʹ���ź�
    output reg UpSig_nPWRDN,     // ����ת�����ĵ����ź�
    output wire UpSig_Sync1,      // ����ת������ͬ���ź�1
    output wire UpSig_Sync2,      // ����ת������ͬ���ź�2
    output wire DoHole_sync_success // ����ͬ���ɹ�ָʾ�ź�(Ŀǰ�ھ��·���ͬ��β֡�����빤��״̬�����Ϊ���ͬ��)
//    output reg Tx_Disable        // ���ͽ����ź�
);
//    wire sync_success;      // ��StoPControl_instanceģ���������Ϊ�����PtoSControlģ���ͬ���ɹ��ź�
//    wire SEND_LAST_FRAME_En;    // ��PtoSControl_instanceģ���������Ϊ�����DownholeSPAndPSControlģ���β֡�����ź�
    //reg [9:0] DataIn_to_send;    // ������Ҫ���������͵�����
//    reg send_last_frame;    // β֡����ֱ�Ӵ�����
//    reg last_frame_sended;  // β֡�ѷ��ͱ�־
    // reg last_frame_sended_one_cycle_dly;  // β֡�ѷ��ͱ�־һ���ӳ�
    // reg tem_delay;
//    reg [5:0] hold_counter;  // ���ڼ��� 38 ������
//    reg [1:0] detect_counter; // ���ڼ���������� 10'h287
//    reg detect_flag;         // ��־λ����ʾ�Ƿ��⵽�������� 10'h287

    //���Ʒ���β֡��ֱ��������ת�����ݵ�ת̬����
//    parameter WAIT_SYNC_Success = 2'b00;        // �ȴ�ͬ���ɹ���־
//    parameter SEND_FRAME_TAIL = 2'b01;         // ����֡β
//    parameter NORMAl = 2'b10;                  // ��������״̬
//    parameter NULL = 2'b11;            // ����������״̬

    // ��ǰ״̬����һ��״̬
//   reg [1:0] state, next_state;

//������ֱ��ת�����źţ�
    assign DownSig_RefClk = CLK_10MHZ;  // ֱ������ CLK_10MHZ
    assign UpSig_TClk = CLK_10MHZ;      // ֱ������ CLK_10MHZ
//    assign DLDataOut = DownSig_ROut;    // ��ֱ�ӽ��⴮�����������ͬ���룩�������һ�����Ƿ���Ҫ��״̬���з�����ʵ�ֺ�DLDataOutEn�źŵ��ϸ�ͬ����

StoPControl StoPControl_instance(
//    .RX_Los(RX_Los),
//    .CLK_100MHZ(CLK_100MHZ),           // 100MHzʱ������
//    .CLK_10MHZ(CLK_10MHZ),            // 10MHzʱ������
    .nRst(nRst),                 // �͵�ƽ��Ч��λ�ź�
    .DownSig_RClk(DownSig_RClk),         // ���Դ���ת�����Ļָ�ʱ��
    .DownSig_nLock(DownSig_nLock),        // ���Դ���ת�����������źţ���������ʱΪ�͵�ƽ
    .DownSig_Rout(DownSig_ROut),   // ����ת��������� 10 λ����
    .sync_success(DoHole_sync_success),         // ͬ���ɹ���־
    .DlDataOut(DLDataOut),
    .DlDataOutEn(DLDataOutEn)
        );

PtoSControl PtoSControl_instance(
//    .RX_Los(RX_Los),
//    .CLK_100MHZ(CLK_100MHZ),       // 100 MHz ʱ��
    .DataIn(DataIn),
    .DataInEn(DataInEn),
    .CLK_10MHZ(CLK_10MHZ),          // 10 MHz ʱ���ź�
    .sync_success(DoHole_sync_success),       // ���� StoPControl ��ͬ���ɹ���־
    .nRst(nRst),               // ��λ�źţ��͵�ƽ��Ч
    .UpSig_Sync1(UpSig_Sync1),   // ͬ���뷢��ʹ��1
    .UpSig_Sync2(UpSig_Sync2),   // ͬ���뷢��ʹ��2
//    .SEND_LAST_FRAME_En(SEND_LAST_FRAME_En), // 1026��ͬ�����ѷ��ͣ�β֡����ʹ��)
    .UpSig_Din(UpSig_Din)
        );



    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            DownSig_RClk_RnF <= 1;  //  �ߵ�ƽ�趨�⴮���ڽ⴮���ָ�ʱ���½��ط������ݣ�������RCLK�������ز������ݲ�ת��
            UpSig_TClk_RnF <= 0;  // ����������������������������
            UpSig_nPWRDN <= 1;    // ����λʱ��������������
            DownSig_REn <= 1;    //.����λʱ�Ϳ�ʼ���ս⴮�������
            DownSig_nPWRDN <= 1;    // ����λʱ�������⴮����
            UpSig_DEn <= 1;     // ����λʱ�Ϳ�ʼʹ�����������Ч��
//            UpSig_Din <= 10'b00000_00000;   // ������������
//            DLDataOutEn <= 0;       // �⴮�����������Ч��ʹ�ܵ�
//            hold_counter <= 0;      // ��λ������
//            detect_counter <= 0;    // ��λ��������
//            detect_flag <= 0;       // ��λ��־λ
//            last_frame_sended <= 0; 
//            DoHole_sync_success <= 0;   // ͬ������δ���
//            Tx_Disable <= 1;    // ���շ�ģ���ȹرշ��͹���
        end else begin
            DownSig_RClk_RnF <= 1;  //  �ߵ�ƽ�趨�⴮���ڽ⴮���ָ�ʱ���½��ط������ݣ�������RCLK�������ز������ݲ�ת��
            UpSig_TClk_RnF <= 0;  // ����������������������������
            UpSig_nPWRDN <= 1;    // ����λʱ��������������
            DownSig_REn <= 1;    //.����λʱ�Ϳ�ʼ���ս⴮�������
            DownSig_nPWRDN <= 1;    // ����λʱ�������⴮����
            UpSig_DEn <= 1;     // ����λʱ�Ϳ�ʼʹ�����������Ч��

            end 
        end
/*        //β֡����ֱ�Ӵ������߼�
    always @(posedge SEND_LAST_FRAME_En or negedge nRst) begin
        if (~nRst)
            send_last_frame <= 0;
        else if(state == SEND_FRAME_TAIL)
            send_last_frame <= 1;
    end

        //β֡�ѷ��ͱ�־�߼�
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
/*
    // ״̬���߼�
    always @(posedge CLK_10MHZ or negedge nRst) begin  // ����10Mhzʱ��ת��״̬
        if (~nRst)
            state <= WAIT_SYNC_Success;
        else
            state <= next_state;
    end

    // ״̬ת���߼�
    always @(*) begin
        case (state)
            WAIT_SYNC_Success: begin
                if (sync_success)
                    next_state = SEND_FRAME_TAIL;
                else
                    next_state = WAIT_SYNC_Success;
            end

            SEND_FRAME_TAIL: begin
                if (last_frame_sended)      // ����ѷ���β֡��������������״̬
                    next_state = NORMAl;
                else
                    next_state = SEND_FRAME_TAIL;
            end

            NORMAl: begin
                if (~nRst)                // ����յ������źŶ�ʧ��ʾ��ص��ȴ�ͬ��״̬
                    next_state = WAIT_SYNC_Success;
                else
                    next_state = NORMAl;
            end
            default: next_state = WAIT_SYNC_Success;
        endcase
    end
*/


/*        case (state)
                WAIT_SYNC_Success: begin
                    Tx_Disable <= 1;    // ���շ�ģ���ȹرշ��͹���
                    UpSig_DEn <= 1;     // ������������������Ч����
                    UpSig_nPWRDN <= 1;    // ���������빤��ת̬
                    DownSig_REn <= 1;    //.��ʼ���ս⴮�������ͬ����
                    DownSig_nPWRDN <= 1;    // �⴮�����빤��״̬
                    DLDataOutEn <= 0;       // �⴮�����������Ч��ʹ�ܵ�
                    last_frame_sended <= 0; // β֡�ѷ��ͱ�־��0
                    DoHole_sync_success <= 0;   // ͬ������δ���
                end

                SEND_FRAME_TAIL: begin
                    Tx_Disable <= 0;    // ���շ�ģ�鿪�����͹���
                    UpSig_DEn <= 1;     // ������������������Ч���������Է���ͬ����
                    UpSig_nPWRDN <= 1;    // ���������빤��ת̬
                    DownSig_REn <= 1;    //.���ս⴮�������ͬ����
                    DownSig_nPWRDN <= 1;    // �⴮�����빤��״̬
                    DLDataOutEn <= 0;   // �·������Ѿ���Ч��
                    DoHole_sync_success <= 0;
                    if(send_last_frame) begin
                    UpSig_Din <= 10'b01111_11110;
                    last_frame_sended <= 1;
                    end
                end

                NORMAl: begin
                    Tx_Disable <= 0;    // ���շ�ģ�鿪�����͹���
                    UpSig_nPWRDN <= 1;    // ���������빤��ת̬
                    DownSig_REn <= 1;    //.���ս⴮�����������
                    DownSig_nPWRDN <= 1;    // �⴮�����빤��״̬
                    send_last_frame <= 0;   // β֡����ֱ�Ӵ�������0
                    last_frame_sended <= 0;    // β֡�ѷ��ͱ�־��0
                    DoHole_sync_success <= 1;   // ͬ�����������

                    if (DataInEn) begin       // ������������״̬��DataInEn�ӹܶԴ��������ʹ�ܵĿ���
                        UpSig_DEn <= 1;
                        UpSig_Din <= DataIn;    // ֱ��ת���������ݸ�������
                        end else begin
                        UpSig_DEn <= 0;
                        UpSig_Din <= 10'b00000_00000;
                        end

                    if (DownSig_ROut == 10'h287) begin
//                        DLDataOutEn <= 1;   // �·�������Ч
                        if (detect_counter < 2)
                        detect_counter <= detect_counter + 1;  // ����������⵽�Ĵ���
                            end else begin 
                                detect_counter <= 0;  // ������� 10'h287�����ü�����
//                        DLDataOutEn <= 0;   // �·�������Ч
                     end

                     if (detect_counter == 2) begin
                        detect_flag <= 1;  // ���ñ�־λ
                        detect_counter <= 0;  // ���ü�������
                    end

                    

                    if (detect_flag) begin
//                        DLDataOutEn <= 1;   // �·�������Ч
                            if (hold_counter < 35)
                            hold_counter <= hold_counter + 1;  // ���� 38 ������
                                else begin
                                hold_counter <= 0;  // ������ɺ�����
                                detect_flag <= 0;   // �����־λ
                                DLDataOutEn <= 0;   // ���� DLDataOutEn
                                end
//                    end else begin
//                    DLDataOutEn <= 0;  // ��������±��ֵ͵�ƽ
                end

                if ((detect_flag || DownSig_ROut == 10'h287) && hold_counter < 35) begin
                    DLDataOutEn <= 1;
//                end else begin
//                    DLDataOutEn <= 0;
                end
                    //DataIn_to_send <= DataIn;
                    //UpSig_Din <= DataIn_to_send;
//                    UpSig_Din <= DataIn;    // ֱ��ת���������ݸ�������

                    //last_frame_sended_one_cycle_dly <= 0;
                    //tem_delay <= 0;
//                    DLDataOutEn <= 1;   // �·������Ѿ���Ч

                end

            endcase
    end
end*/

endmodule
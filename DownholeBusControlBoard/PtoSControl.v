/*1.��ģ�鸺�����StoPControlģ�鷢�͵�ͬ���ɹ��źţ�
�����ƾ��´���������淢��ͬ���룬���򶥲�ģ�鷢�����β֡�ź�*/
/*2.ʹ��״̬��ʵ�֣����β֡�źŽ���������100Mhzʱ�����ڣ�֮������*/
/*3.ĿǰΪ���Է��㣬���ӳ�10��ʱ�����ھͷ���β֡*/

module PtoSControl(
//    input RX_Los,
//    input CLK_100MHZ,       // 100 MHz ʱ��
    input CLK_10MHZ,          // 10 MHz ʱ���ź�
    input sync_success,       // ���� StoPControl ��ͬ���ɹ���־
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    input DataInEn,
    input [9:0] DataIn,       //���Ե�������RAM��ģ��� 10 λ��������

    output reg UpSig_Sync1,   // ͬ���뷢��ʹ��1
    output reg UpSig_Sync2,   // ͬ���뷢��ʹ��2


    output reg [9:0] UpSig_Din  // �ṩ������ת������10λ����
);

    // ״̬����
    parameter WAIT_SYNC_SUCCESS = 2'b00;  // �ȴ� sync_success �ź�
    parameter SEND_SYNC = 2'b01;          // ����ͬ���ź�
    parameter SEND_LAST_FRAME = 2'b10;     // �ȴ�85��ʱ������
    parameter NORMAL = 2'b11;    // ����β֡

    // ��ǰ״̬����һ��״̬
    reg [1:0] state, next_state;

    // ������
    reg [10:0] counter;  // ���ڼ���85��ʱ�����ڣ����127��
    reg [3:0] sync_timer; // ����ͬ���ź�ά�ֵĶ�ʱ�������15��ʱ�����ڣ�
    reg SEND_LAST_FRAME_En; // 1026��ͬ�����ѷ��ͣ�β֡����ʹ��
    reg last_frame_sended;
//    reg [1:0] counter_delay;    // ���ڿ���SEND_LAST_FRAME_En�����ӳ��ļ�ʱ��

    //����10MHZ���ṩ���⴮/�������ο�ʱ�ӣ����ۼƼ�����
        always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            sync_timer <= 0;
        else if (state == SEND_SYNC)
            sync_timer <= sync_timer + 1; // ͬ���źż�ʱ
        else if (state != SEND_SYNC)
            sync_timer <= 0; // �˳�ͬ���źŷ���ʱ����
    end
    
    //����10MHZ���ṩ���⴮/�������ο�ʱ�ӣ����ۼƼ�����
        always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            counter <= 0;
        else if (state == SEND_LAST_FRAME)
            counter <= counter + 1; // 85ʱ�����ڼ�ʱ
        else if (state != SEND_LAST_FRAME)
            counter <= 0; // �˳�β֡����ʱ����
    end

/*    //����10MHZ���ṩ���⴮/�������ο�ʱ�ӣ����ۼƼ�����
        always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            counter_delay <= 0;
        else if (SEND_LAST_FRAME_En == 1)
            counter_delay <= counter_delay + 1; // ͬ���źż�ʱ
//        else if (state != SEND_SYNC)
//            sync_timer <= 0; // �˳�ͬ���źŷ���ʱ����
    end*/

    // ״̬���߼�
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst)
            state <= WAIT_SYNC_SUCCESS;
        else
            state <= next_state;
    end

    // ״̬ת���߼�
    always @(*) begin
        case (state)
            WAIT_SYNC_SUCCESS: begin
                if (sync_success)
                    next_state = SEND_SYNC;
                else
                    next_state = WAIT_SYNC_SUCCESS;
            end

            SEND_SYNC: begin
                if (sync_timer == 10)  // ά��ͬ���ź�10��ʱ�����ں�
                    next_state = SEND_LAST_FRAME;
                else
                    next_state = SEND_SYNC;
            end

            SEND_LAST_FRAME: begin
                if (last_frame_sended) // ����β֡ʹ�����ߺ������������ת̬
                    next_state = NORMAL;
                else
                    next_state = SEND_LAST_FRAME;
            end

            NORMAL: begin                               // ����������˳�״̬����
                if (~nRst)
                    next_state = WAIT_SYNC_SUCCESS;     // �ص��ȴ�ͬ��״̬
                else
                    next_state = NORMAL;
            end
            default: next_state = WAIT_SYNC_SUCCESS;
        endcase
    end

    // �������
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            UpSig_Sync1 <= 0;
            UpSig_Sync2 <= 0;
            SEND_LAST_FRAME_En <= 0;
//            counter <= 0;
//            sync_timer <= 0;
            last_frame_sended <= 0;
//            counter_delay <= 2'd0;

        end else begin
            case (state)
                WAIT_SYNC_SUCCESS: begin
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
                    UpSig_Din <= 10'b00000_00000;
                    SEND_LAST_FRAME_En <= 0;
//                    counter <= 0;
//                    sync_timer <= 0;
                end

                SEND_SYNC: begin
                    UpSig_Sync1 <= 1;
                    UpSig_Sync2 <= 1;
//                    UpSig_Din <= 10'b00000_00000;
//                    counter <= 0;
                    SEND_LAST_FRAME_En <= 0;
                end

                SEND_LAST_FRAME: begin
                if (counter >= 1027)begin    //Ϊ���Է��㣬Ŀǰ���ӳ�10�����ڷ���β֡
                    SEND_LAST_FRAME_En <= 1;

                    if (SEND_LAST_FRAME_En) begin
                        UpSig_Din <= 10'b10011_11100;
                        last_frame_sended <= 1;
//                        counter_delay <= 2'd0;
                    end
                end
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
//                    sync_timer <= 0;
                    
                end

                NORMAL: begin
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
//                    UpSig_Din <= DataIn;
//                    counter <= 0;
//                    sync_timer <= 0;
                    last_frame_sended <= 0;

                    if (DataInEn) begin       // ������������״̬��DataInEn�ӹܶԴ��������ʹ�ܵĿ���
                        UpSig_Din <= DataIn;    // ֱ��ת���������ݸ�������

                        end else begin
//                        DownSig_DEn <= 0;       // ȷ�������Ƿ���Ҫ�ر����д�����ʹ�ܣ�
                        UpSig_Din <= 10'b00000_11111;     // ���Ϳ���ֱ̬�ӷ�ͬ���룿
                        end
                end

                default: begin
                    UpSig_Sync1 <= 0;
                    UpSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
                    last_frame_sended <= 0;
                    UpSig_Din <= 10'b00000_00000;
                end
            endcase
        end
    end
endmodule

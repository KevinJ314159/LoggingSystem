/*1.��ģ�鸺���ڸ�λ�󼴷��ʹ���/�⴮��ͬ���룬��StoPControl_s���յ����´�����ͬ���źź�β֡��,�����ģ�鷢��
sync_success�źţ���ΪPtoSControl_sģ�����ִ�У��������ط�1026��ͬ�����������*/
/*2.ʹ��״̬��ʵ�֣����β֡�źŽ���������100Mhzʱ�����ڣ�֮������*/
/*3.ĿǰΪ���Է��㣬���ӳ�10��ʱ�����ھͷ���β֡ʵ�ʲ�����Ҫ����*/

module PtoSControl_s(
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)
//    input CLK_100MHZ,       // 100 MHz ʱ��
    input CLK_10MHZ,          // 10 MHz ʱ���ź�
    input sync_success,       // ���� StoPControl ��ͬ���ɹ���־
    input nRst,               // ��λ�źţ��͵�ƽ��Ч
    input DataInEn,          
    input [9:0] DataIn,       //���Ե�������RAM��ģ��� 10 λ��������

    output reg DownSig_Sync1,   // ͬ���뷢��ʹ��1
    output reg DownSig_Sync2,   // ͬ���뷢��ʹ��2

//    output reg shakehand_success,   // �յ�����StoPControl_sģ���sync_success�źź󣬱�ʾ���浽����ͨ��Ҳ�����
    output reg [9:0] DownSig_Din  // �ṩ������ת������10λ����
);

    // ״̬����
    parameter SEND_SYNC = 2'd0;         // ����ͬ���ź�
    parameter SEND_LAST_FRAME = 2'd1;          // ����ͬ���ź�     // �ȴ�85��ʱ�����ڷ���β֡
    parameter WAIT_SYNC_SUCCESS = 2'd2;         // �ȴ� sync_success �ź� 
    parameter NORMAL = 2'd3;    // ��������״̬ 

    // ��ǰ״̬����һ��״̬
    reg [1:0] state, next_state;

    // ������
    reg [10:0] counter;  // ���ڼ���85��ʱ�����ڣ����2048��
    reg [3:0] sync_timer; // ����ͬ���ź�ά�ֵĶ�ʱ�������15��ʱ�����ڣ�
    reg SEND_LAST_FRAME_En;
     reg last_frame_sended; // 1026��ͬ�����ѷ��ͣ�β֡����ʹ��
    reg [1:0] counter_delay;    // ���ڿ���SEND_LAST_FRAME_En�����ӳ��ļ�ʱ��

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

/*        //����SEND_LAST_FRAME_En�����ӳ����ۼƼ�����
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
            state <= SEND_SYNC;
        else
            state <= next_state;
    end

    // ״̬ת���߼�
    always @(*) begin
        case (state)
            SEND_SYNC: begin
                if (sync_timer == 10)  // ά��ͬ���ź�10��ʱ�����ں�
                    next_state = SEND_LAST_FRAME;
                else
                    next_state = SEND_SYNC;
            end

            SEND_LAST_FRAME: begin
                if (last_frame_sended) // ����β֡ʹ�����ߺ������������ת̬
                    next_state = WAIT_SYNC_SUCCESS;
                else
                    next_state = SEND_LAST_FRAME;
            end

            WAIT_SYNC_SUCCESS: begin
                if (sync_success)
                    next_state = NORMAL;
                else
                    next_state = WAIT_SYNC_SUCCESS;
            end

            NORMAL: begin                               // ����������˳�״̬����
                if (~nRst)
                    next_state = SEND_SYNC;     // �ص��ȴ�ͬ��״̬
                else
                    next_state = NORMAL;
            end
            default: next_state = SEND_SYNC;
        endcase
    end

    // �������
    always @(posedge CLK_10MHZ or negedge nRst) begin
        if (~nRst) begin
            DownSig_Sync1 <= 0;
            DownSig_Sync2 <= 0;
            SEND_LAST_FRAME_En <= 0;
//            counter <= 0;
//            sync_timer <= 0;
            DownSig_Din <= 10'b00000_00000;
            last_frame_sended <= 0;
//            shakehand_success <= 0;
        end else begin
            case (state)

                SEND_SYNC: begin
                    DownSig_Sync1 <= 1;
                    DownSig_Sync2 <= 1;
//                    DownSig_Din <= 10'b00000_00000; // ��ʱ�⴮������Sync�������·���ͬ���루�����������ݿ���������
//                    counter <= 0;
                    SEND_LAST_FRAME_En <= 0;
//                    shakehand_success <= 0;
                end

                SEND_LAST_FRAME: begin
                if (counter >= 1027)begin    //Ϊ���Է��㣬Ŀǰ���ӳ�10�����ڷ���β֡
                    SEND_LAST_FRAME_En <= 1;

                if(SEND_LAST_FRAME_En) begin
                    DownSig_Din <= 10'b10011_11100;
                    last_frame_sended <= 1;
                    end
//                    if (counter_delay == 2'd1) begin
//                        last_frame_sended <= 1;
//                        counter_delay <= 2'd0;
//                    end
                end
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
//                    sync_timer <= 0;
//                    shakehand_success <= 0;
                    
                end

                WAIT_SYNC_SUCCESS: begin
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
                    DownSig_Din <= 10'b00000_00000;
                    SEND_LAST_FRAME_En <= 0;
//                    counter <= 0;
//                    sync_timer <= 0;
//                    shakehand_success <= 0;
                end

                NORMAL: begin
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
//                    counter <= 0;
//                    sync_timer <= 0;
                    last_frame_sended <= 0;
//                    shakehand_success <= 1;

                    if (DataInEn) begin       // ������������״̬��DataInEn�ӹܶԴ��������ʹ�ܵĿ���
                        DownSig_Din <= DataIn;    // ֱ��ת���������ݸ�������

                        end else begin
//                        DownSig_DEn <= 0;       // ȷ�������Ƿ���Ҫ�ر����д�����ʹ�ܣ�
                        DownSig_Din <= 10'b00000_11111;     // ���Ϳ���ֱ̬�ӷ�ͬ���룿
                        end

                    end


                default: begin
                    DownSig_Sync1 <= 0;
                    DownSig_Sync2 <= 0;
                    SEND_LAST_FRAME_En <= 0;
                    last_frame_sended <= 0;
//                    shakehand_success <= 0;
                    DownSig_Din <= 10'b00000_00000;
                end
            endcase
        end
    end
endmodule

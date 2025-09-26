/*1.��ģ�����ڼ�⾮�½⴮���Ƿ�����洮�������ͬ��*/
/*2.Ŀǰʹ��4״̬״̬��ʵ�֣�����30��������ͬ���룬ʶ��ͬ����β֡���⴮�����LOCK�źż���Ϊ���ͬ��*/
/*3.��Ҫȷ��ͬ����β֡��ȷ�Ͻ⴮�������ź�LOCK���͵�ʱ����������Ӱ�죩*/
module sync_detect_s (
//    input UpSig_SD,     // ���Թ��ת��ģ��(��;��Ҫȷ��)
//    input CLK_100MHZ,           // ��40MHz�� ʱ������
    input UpSig_RClk,
    input nRst,                 // ��λ�źţ��͵�ƽ��Ч
//    input detected_negedge,         // ����ת�����Ļָ�ʱ�ӵ��½���
    input [9:0] UpSig_ROut,   // ����ת��������� 10 λ����
    input UpSig_nLock,        // ����ת�����������ź�
    output reg sync_success          // ͬ���ɹ���־
);

    // ״̬����
    parameter WAIT_SYNC = 2'b00;        // �ȴ�ͬ����
    parameter WAIT_FRAME_TAIL = 2'b01;  // �ȴ�֡β
    parameter WAIT_UpSig_nLock = 2'b10;     // �ȴ������ź�����
    parameter SYNC_SUCCESS = 2'b11;            // �ɹ�

    // ��ǰ״̬����һ��״̬
    reg [1:0] state,next_state;

    // ͬ������
    reg [4:0] sync_code_count; // ���ڼ�����⵽��ͬ��������

    // ״̬���߼�
    always @(posedge UpSig_RClk or negedge nRst) begin
        if (~nRst)
            state <= WAIT_SYNC; // ��λʱ��״̬���ص��ȴ�ͬ��״̬
        else
            state <= next_state; // ���µ�ǰ״̬
    end

/*    // ����ͬ���������
    always @(posedge detected_negedge or negedge nRst) begin
        if (~nRst)
            sync_code_count <= 5'b0;
        else if (state == WAIT_SYNC && UpSig_ROut == 10'b00000_11111)
            sync_code_count <= sync_code_count + 1;
        else if (state != WAIT_SYNC)
            sync_code_count <= 5'b0; // ״̬�����ڵȴ�ͬ��ʱ���������
    end
*/

        // ����ͬ���������
    always @(posedge UpSig_RClk or negedge nRst) begin
        if (~nRst)
            sync_code_count <= 5'b0;
//        else if(detected_negedge) begin
            else if (state == WAIT_SYNC && UpSig_ROut == 10'b00000_11111)
                sync_code_count <= sync_code_count + 1;
            else if (state != WAIT_SYNC)
            sync_code_count <= 5'b0; // ״̬�����ڵȴ�ͬ��ʱ���������
//            end
    end

    // ״̬��ת���߼�
    always @(*) begin
        case (state)
            WAIT_SYNC: begin
                // �ȴ�ͬ����
                if (sync_code_count == 30)  // ����Ѿ���⵽30��ͬ����
                    next_state = WAIT_FRAME_TAIL; // ת���ȴ�֡β״̬
//                else if (RX_Los)
//                    next_state = WAIT_SYNC; // �����ȴ�ͬ����
                else 
                    next_state = WAIT_SYNC; // �����ȴ�ͬ����
            end
            WAIT_FRAME_TAIL: begin
                // �ȴ�֡β10'b10011_11100 �� UpSig_nLock Ϊ�͵�ƽ
                if (UpSig_ROut == 10'b10011_11100)
                    next_state = WAIT_UpSig_nLock; // ���֡β�������㣬ת���ȴ���������
                else
                    next_state = WAIT_FRAME_TAIL; // �����ȴ�֡β
            end
            WAIT_UpSig_nLock: begin
                if (!UpSig_nLock)
                next_state = SYNC_SUCCESS; // ����ͬ���ɹ�״̬
                else
                    next_state = WAIT_UpSig_nLock;
            end
            SYNC_SUCCESS: begin
//                if (RX_Los)
                if (~nRst)
                next_state = WAIT_SYNC; // �ص��ȴ�ͬ����״̬
                else
                next_state = SYNC_SUCCESS; // ����ͬ���ɹ�״̬
            end
            default: next_state = WAIT_SYNC; // Ĭ�ϵȴ�ͬ����״̬
        endcase
    end

    // �������
    always @(posedge UpSig_RClk or negedge nRst) begin
        if (~nRst)
            sync_success <= 0;
        else if (state == SYNC_SUCCESS )
            sync_success <= 1; // ��ͬ���ɹ�ʱ������ sync_success �ź�
        else
            sync_success <= 0; // ���򱣳�Ϊ�͵�ƽ
    end

endmodule

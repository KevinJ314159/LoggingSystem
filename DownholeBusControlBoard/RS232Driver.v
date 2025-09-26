/*��Ҫȷ��Rs232_clk�Ƿ���ǲ�����ʱ��*/

module RS232Driver (
    input  wire        clk,            // 10MHzʱ��
    input  wire        Rs232_clk,       // ������ʱ�ӣ�ÿ�������ط���һ�� bit
    input  wire        rst_n,          // �첽��λ������Ч
    input  wire        send_req,       // ���������ź�
    input  wire [7:0]  data_in,        // �����͵� 8 λ����
    
    output reg         tx_out,         // ���з��������ߣ�����ʱΪ�ߵ�ƽ��
    output reg         bus_state,      // ����״̬��1 ��ʾæµ��0 ��ʾ����
    output reg         send_done       // ��������ź�
);

    // ���ڴ洢 1 ��ʼλ + 8 ����λ + 2 ֹͣλ = 11 λ
    reg [9:0] shift_reg;
    reg [3:0] bit_cnt;  // ������Χ 0~9 ����
    reg send_req_flag;
//    reg Abit_sendOk;

    wire baud_clk;

    Rs232clk_edge_detecter Rs232clk_edge_detecter_instance(
    .Rs232Clk(Rs232_clk),       // ���Խ⴮���Ļָ�ʱ��
    .CLK_10MHZ(clk),         // 10MHz ʱ��
    .nRst(rst_n),               // ��λ�źţ��͵�ƽ��Ч
    .Rs232ClkPosedge_detected(baud_clk)  // 232������ʱ�������ؼ���־);
    );


    // ����״̬�ı���
    localparam IDLE = 2'd0,        // �ȴ���������
               SENDING = 2'd1,     // ����״̬
               SEND_COMPLETE = 2'd2; // �������״̬

    reg [1:0] state, next_state;  // ��ǰ״̬����һ��״̬


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            send_req_flag <= 1'b0;
        end else begin
            send_req_flag <= send_req;
        end
    end

    // ״̬����״̬ת���߼�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;  // ��λʱ״̬���������״̬
        end else begin
            state <= next_state;  // ������һ��״̬
        end
    end


    // ������һ��״̬
    always @(*) begin
        case(state)
            IDLE: begin
                if (send_req_flag) begin
                    next_state = SENDING;  // �յ��������󣬽��뷢��״̬
                end else begin
                    next_state = IDLE;  // �����ڿ���״̬
                end
            end
            SENDING: begin
                if (bit_cnt == 4'd10) begin
                    next_state = SEND_COMPLETE;  // ������ɣ��������״̬
                end else begin
                    next_state = SENDING;  // �����ڷ���״̬
                end
            end
            SEND_COMPLETE: begin
                next_state = IDLE;  // ������ɺ󷵻ص�����״̬
            end
            default: next_state = IDLE;  // Ĭ�ϻص�����״̬
        endcase
    end

    // ���������߼�
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_out    <= 1'b1;        // ����ʱ������Ϊ�ߵ�ƽ
            shift_reg <= 11'b11111_111111;
            bit_cnt   <= 4'd0;
//            send_req_flag <= 1'b0;
//            Abit_sendOk <= 1'b0;
            send_done <= 1'b0;
            bus_state <= 1'b0;
        end else begin
            case(state)
                IDLE: begin
                    send_done <= 1'b0;  // ��������ź�����
                    bus_state <= 1'b0;   // ���߿���
                    if (send_req_flag) begin
                        shift_reg <= {1'b1, data_in, 1'b0};  // ���������־
                    end
                end

                 SENDING: begin
                    // �ڷ���״̬���� bus_state = 1
                    bus_state <= 1'b1;

                    // ֻ�м�⵽ baud_clk_rise ʱ���Ž��з��Ͷ�����bit_cnt++ 
                    if (baud_clk) begin
                        // �� case(bit_cnt) ��λ���� shift_reg[bit_cnt]
                        case(bit_cnt)
                            4'd0: tx_out <= shift_reg[0];  // ��ʼλ
                            4'd1: tx_out <= shift_reg[1];
                            4'd2: tx_out <= shift_reg[2];
                            4'd3: tx_out <= shift_reg[3];
                            4'd4: tx_out <= shift_reg[4];
                            4'd5: tx_out <= shift_reg[5];
                            4'd6: tx_out <= shift_reg[6];
                            4'd7: tx_out <= shift_reg[7];
                            4'd8: tx_out <= shift_reg[8];
                            4'd9: tx_out <= shift_reg[9];  // ֹͣλ
//                            4'd10: tx_out <= shift_reg[10];  // ֹͣλ
                            default: tx_out <= 1'b1;        // ���ౣ��
                        endcase

                        // ������һλ�� bit_cnt +1
                        if (bit_cnt <= 4'd9)
                            bit_cnt <= bit_cnt + 1'b1;
                        else if (bit_cnt == 4'd10) begin
//                        bus_state <= 1'b0;
//                        Abit_sendOk <= 1'b1;
                    end
                end
                end

                SEND_COMPLETE: begin
                    send_done <= 1'b1;  // ������ɣ���������ź�Ϊ1
                    bus_state <= 1'b0;  // ���߿���
                    bit_cnt <= 4'd0;
//                    Abit_sendOk <= 1'b0;
//                    if (Abit_sendOk) begin
//                        state <= IDLE;  // ������ɺ󣬷��ؿ���״̬
//                    end
                end

                default: begin
                    tx_out    <= 1'b1;  // �����߸ߵ�ƽ
                    send_done <= 1'b0;
                    bus_state <= 1'b0;
                end
            endcase
        end
    end

endmodule

`timescale 1ns/1ns
module RS232Driver_tb;

    // Testbench signals
    reg clk;
    reg baud_clk;         // ������ʱ��
    reg rst_n;            // �첽��λ
    reg send_req;         // ��������
    reg [7:0] data_in;    // �����͵� 8 λ����
    wire tx_out;          // ���з���������
    wire bus_state;       // ����״̬

    // ʵ���� RS232Driver
    RS232Driver uut (
        .clk(clk),
        .Rs232_clk(baud_clk),
        .rst_n(rst_n),
        .send_req(send_req),
        .data_in(data_in),
        .tx_out(tx_out),
        .bus_state(bus_state),
        .send_done(send_done)
    );

    // ������ʱ����������115200�����ʣ�����Ϊ 8680 ����
    initial begin
        baud_clk = 0;
        forever #4340 baud_clk = ~baud_clk;  // 115200������ʱ������ 8680���룬���ڵ�һ����4340����
    end

        initial begin
        clk = 0;
        forever #50 clk = ~clk;  // 115200������ʱ������ 8680���룬���ڵ�һ����4340����
    end
    // Test procedure
    initial begin
        // ��ʼ��
        rst_n = 0;
        send_req = 0;
        data_in = 8'b10101010;  // ��һ������ 0xAA
        #100;
        
        // ��λ���
        rst_n = 1;
        
        // ����5�����ݣ�ȷ��ÿ�����ݵķ������㹻��ʱ��
        send_data(8'b10101010);  // 0xAA
        send_data(8'b11001100);  // 0xCC
        send_data(8'b11110000);  // 0xF0
        send_data(8'b00001111);  // 0x0F
        send_data(8'b11111111);  // 0xFF

        // ��������
        #1000;
        $finish;
    end

    // �������ݵĹ���
    task send_data(input [7:0] data);
        begin
            data_in = data;       // ��������
            send_req = 1;         // ���� send_req
            #100;                 // ���� send_req ���� 100����
            send_req = 0;         // ���� send_req
            #100000;              // �ȴ����� 100 ΢�루ȷ��������ȫ���䣩�ٷ�����һ������
        end
    endtask


endmodule

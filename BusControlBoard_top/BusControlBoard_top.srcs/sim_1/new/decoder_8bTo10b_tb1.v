module decoder_10bto8b_tb;

    // �����ź�
    reg clk;                // ʱ���ź�
    reg rst_n;              // ��λ�ź�
    reg valid_in;           // ������Ч�ź�
    reg [9:0] din_10b;      // 10λ��������
    wire [7:0] dout_8b;     // 8λ�������
    wire valid_out;         // �����Ч�ź�

    // ���ӽ���ģ��
    decoder_10bto8b uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .din_10b(din_10b),
        .dout_8b(dout_8b),
        .valid_out(valid_out)
    );

    // ʱ�����ɣ�10 MHz ʱ�ӣ�����Ϊ 100ns
    always begin
        #50 clk = ~clk;  // ÿ 50ns ��תʱ�ӣ��൱�� 10MHz ʱ��Ƶ��
    end

    // ��λ����
    initial begin
        rst_n = 0;
        #200 rst_n = 1;  // ��λ 15ns ����
    end

    // �����������ɺ� valid_in �źſ���
    initial begin
        // ��ʼ��
        clk = 0;
        valid_in = 0;
        din_10b = 10'd0;

        // �ȴ���λ���
        #200;

        // ���͵�һ������������
        din_10b = 10'h287;  // һ��ʾ�� 10 λ����
        valid_in = 1;              // ���� valid_in
        #100 valid_in = 0;          // ���� valid_in

        // �ȴ� 89200ns
        #89200;

        // ���͵ڶ�������������
        din_10b = 10'h0c5;  // ��һ��ʾ�� 10 λ����
        valid_in = 1;              // ���� valid_in
        #100 valid_in = 0;          // ���� valid_in

        // �ȴ� 89200ns
        #89200;

        // ���͵���������������
        din_10b = 10'b1111010100;  // ��һ��ʾ�� 10 λ����
        valid_in = 1;              // ���� valid_in
        #100 valid_in = 0;          // ���� valid_in

        // �ȴ� 89200ns
        #89200;

        // ����ģ��
        #300;
        $finish;
    end


endmodule
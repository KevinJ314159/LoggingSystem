module DualPortRAM(
    input         clk_in,
    input         clk_out,
    // д�˿�
    input  [9:0]  waddr,
    input  [9:0]  wdata,
    input         wen,
    // ���˿�
    input  [9:0]  raddr,
    input         rden,
    output reg [9:0] rdata
);
    // ��ģ�ͣ�λ��10 �洢�����Ϊ1024
    reg [9:0] mem [0:1023];

    // д������ͬ��д��
    always @(posedge clk_in) begin
        if (wen)
            mem[waddr] <= wdata;
    end

    // ��������ͬ������
    always @(posedge clk_out) begin
        if (rden)
            rdata <= mem[raddr];
        else
            rdata <= 10'd0;
    end
endmodule

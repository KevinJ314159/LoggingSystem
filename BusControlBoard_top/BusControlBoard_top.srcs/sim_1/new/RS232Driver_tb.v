`timescale 1ns/1ns
module RS232Driver_tb;

    // Testbench signals
    reg clk;
    reg baud_clk;         // 波特率时钟
    reg rst_n;            // 异步复位
    reg send_req;         // 发送请求
    reg [7:0] data_in;    // 待发送的 8 位数据
    wire tx_out;          // 串行发送数据线
    wire bus_state;       // 总线状态

    // 实例化 RS232Driver
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

    // 波特率时钟生成器，115200波特率，周期为 8680 纳秒
    initial begin
        baud_clk = 0;
        forever #4340 baud_clk = ~baud_clk;  // 115200波特率时钟周期 8680纳秒，周期的一半是4340纳秒
    end

        initial begin
        clk = 0;
        forever #50 clk = ~clk;  // 115200波特率时钟周期 8680纳秒，周期的一半是4340纳秒
    end
    // Test procedure
    initial begin
        // 初始化
        rst_n = 0;
        send_req = 0;
        data_in = 8'b10101010;  // 第一组数据 0xAA
        #100;
        
        // 复位解除
        rst_n = 1;
        
        // 发送5组数据，确保每组数据的发送有足够的时间
        send_data(8'b10101010);  // 0xAA
        send_data(8'b11001100);  // 0xCC
        send_data(8'b11110000);  // 0xF0
        send_data(8'b00001111);  // 0x0F
        send_data(8'b11111111);  // 0xFF

        // 结束仿真
        #1000;
        $finish;
    end

    // 发送数据的过程
    task send_data(input [7:0] data);
        begin
            data_in = data;       // 设置数据
            send_req = 1;         // 拉高 send_req
            #100;                 // 保持 send_req 拉高 100纳秒
            send_req = 0;         // 拉低 send_req
            #100000;              // 等待至少 100 微秒（确保数据完全传输）再发送下一组数据
        end
    endtask


endmodule

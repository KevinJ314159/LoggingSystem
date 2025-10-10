
`timescale 1ns/1ps
module McBSPDriver_16Bit_s_tb;

    // Testbench signals
    reg clk;
    reg McBSPClk;         // 波特率时钟
    reg nRst;            // 异步复位
    reg tRequest;         // 发送请求
    reg [15:0] data_in;    // 待发送的 8 位数据
    wire tx_out;          // 串行发送数据线
    wire bus_state;       // 总线状态
    wire FSX;

    // 实例化 RS232Driver
    McBSPDriver_16Bit_s uut (
//        .clk(clk),
        .McBSPClk(McBSPClk),
        .nRst(nRst),
        .tRequest(tRequest),
        .tData(data_in),
        .DX(tx_out),
        .busIdle(bus_state),
        .FSX(FSX)
//        .send_done(send_done)
    );

    // 波特率时钟生成器，115200波特率，周期为 8680 纳秒
    initial begin
        McBSPClk = 1;
        forever #50 McBSPClk = ~McBSPClk;  // 115200波特率时钟周期 8680纳秒，周期的一半是4340纳秒
    end

        initial begin
        clk = 1;
        forever #50 clk = ~clk;  // 115200波特率时钟周期 8680纳秒，周期的一半是4340纳秒
    end
    // Test procedure
    initial begin
        // 初始化
        nRst = 0;
        tRequest = 0;
        data_in = 8'b10101010;  // 第一组数据 0xAA
        #100;
        
        // 复位解除
        nRst = 1;
        
        // 发送5组数据，确保每组数据的发送有足够的时间
        send_data(16'h4747);  // 0xAA
        send_data(16'h1314);  // 0xCC
        send_data(16'h4747);  // 0xF0
        send_data(16'h1a1b);  // 0x0F
        send_data(16'h4747);  // 0xFF

        // 结束仿真
        #1000;
        $finish;
    end

    // 发送数据的过程
    task send_data(input [15:0] data);
        begin
            data_in = data;       // 设置数据
            tRequest = 1;         // 拉高 tRequest
            #100;                 // 保持 tRequest 拉高 100纳秒
            tRequest = 0;         // 拉低 tRequest
            #100000;              // 等待至少 100 微秒（确保数据完全传输）再发送下一组数据
        end
    endtask


endmodule

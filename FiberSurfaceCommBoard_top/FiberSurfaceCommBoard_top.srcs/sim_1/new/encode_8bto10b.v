module encode_8bto10b(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        din_en,     // 输入使能，高电平表示本拍需进行 8b->10b 编码
    input  wire        is_k,       // 是否为 K 码
    input  wire [7:0]  din_8b,     // 8 位输入数据

    // 10 位输出数据，以及本拍是否有效的使能信号
    output reg  [9:0]  dout_10b,
    output reg         dout_en
);

//////////////////////////////////////////////////////////
// 1) 运行奇偶(Running Disparity)管理寄存器
//////////////////////////////////////////////////////////
reg RD_pre, RD_next;

//////////////////////////////////////////////////////////
// 2) 主时序逻辑
//    在检测到 din_en=1 时，对数据进行编码并更新 RD
//////////////////////////////////////////////////////////
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        {RD_next, dout_10b} <= 11'd0;
        RD_pre    <= 1'b0;    // 也可改为1, 具体看您需要从正RD还是负RD开始
        dout_en   <= 1'b0;
    end
    else begin
        // 缺省输出无效
        dout_en <= 1'b0;

        if(din_en) begin
            // 调用 8b->10b 编码函数
            {RD_next, dout_10b} <= code_10b(is_k, RD_pre, din_8b);
            // 标记本拍输出有效
            dout_en <= 1'b1;
        end
        else begin
            // 保持不变
            {RD_next, dout_10b} <= {RD_next, dout_10b};
        end

        // 运行奇偶在本拍结束后更新
        RD_pre <= RD_next;
    end
end

//////////////////////////////////////////////////////////
// 3) 功能函数：code_10b
//    输入：is_k, RD_pre, din_8b
//    输出：{RD_next, dout_10b} (共11bit)
//    修改点：在生成10位编码后，对其各个位进行反转
//////////////////////////////////////////////////////////
function [10:0] code_10b;
    input        is_k;      // 是否K码
    input        RD_pre;    // 上一拍RD
    input [7:0]  din_8b;    // 当前待编码8位

    // 中间寄存器
    reg          RD_mid;    // 6b编码后更新的RD
    reg          is_k28;    // 是否 k28.x
    reg  [5:0]   b6;        // 5b->6b阶段输出
    reg  [3:0]   b4;        // 3b->4b阶段输出
    reg          is_P7;     
    reg          A7_cnd1, A7_cnd2;

    // 用于位反转的寄存器
    reg [9:0]    code_temp; // 原始10位编码： {b6, b4}
    reg [9:0]    reversed;  // 反转后的10位编码
    integer      i;         // 循环变量

    // 最终输出
    reg  [9:0]   dout_10b;
    reg          RD_next;   // 4b编码后更新的RD

    begin
        /////////////////////////////////////////
        // 3.1 判定是否K28
        /////////////////////////////////////////
        is_k28 = is_k && (din_8b[4:0] == 5'd28);

        /////////////////////////////////////////
        // 3.2 A7/P7条件判断
        //     如果出现连续5个 0 或 1，需用A7编码修正
        /////////////////////////////////////////
        A7_cnd1 = (!RD_pre) 
                  && (din_8b[7:3] == 5'b11110) 
                  && ((din_8b[2:0] == 3'b001)
                   || (din_8b[2:0] == 3'b010)
                   || (din_8b[2:0] == 3'b100));

        A7_cnd2 = ( RD_pre)
                  && (din_8b[7:3] == 5'b11101)
                  && ((din_8b[2:0] == 3'b011)
                   || (din_8b[2:0] == 3'b101)
                   || (din_8b[2:0] == 3'b110));

        // is_P7 表示当前使用P7编码，而非A7或K
        is_P7 = !(is_k | A7_cnd1 | A7_cnd2);

        /////////////////////////////////////////
        // 3.3 5b->6b编码 (abcdei)
        /////////////////////////////////////////
        if(is_k28) begin
            b6     = (RD_pre)? 6'b110000 : 6'b001111; 
            RD_mid = ~RD_pre;
        end
        else begin
            case(din_8b[4:0])  // EDCBA -> abcdei
                5'd0 :  begin b6 = (RD_pre)?6'b011000:6'b100111; RD_mid=~RD_pre; end
                5'd1 :  begin b6 = (RD_pre)?6'b100010:6'b011101; RD_mid=~RD_pre; end
                5'd2 :  begin b6 = (RD_pre)?6'b010010:6'b101101; RD_mid=~RD_pre; end
                5'd3 :  begin b6 = 6'b110001; RD_mid= RD_pre;   end
                5'd4 :  begin b6 = (RD_pre)?6'b001010:6'b110101; RD_mid=~RD_pre; end
                5'd5 :  begin b6 = 6'b101001; RD_mid= RD_pre;   end
                5'd6 :  begin b6 = 6'b011001; RD_mid= RD_pre;   end
                5'd7 :  begin b6 = (RD_pre)?6'b000111:6'b111000; RD_mid= RD_pre;   end
                5'd8 :  begin b6 = (RD_pre)?6'b000110:6'b111001; RD_mid=~RD_pre; end
                5'd9 :  begin b6 = 6'b100101; RD_mid= RD_pre;   end
                5'd10:  begin b6 = 6'b010101; RD_mid= RD_pre;   end
                5'd11:  begin b6 = 6'b110100; RD_mid= RD_pre;   end
                5'd12:  begin b6 = 6'b001101; RD_mid= RD_pre;   end
                5'd13:  begin b6 = 6'b101100; RD_mid= RD_pre;   end
                5'd14:  begin b6 = 6'b011100; RD_mid= RD_pre;   end
                5'd15:  begin b6 = (RD_pre)?6'b101000:6'b010111; RD_mid=~RD_pre; end
                5'd16:  begin b6 = (RD_pre)?6'b100100:6'b011011; RD_mid=~RD_pre; end
                5'd17:  begin b6 = 6'b100011; RD_mid= RD_pre;   end
                5'd18:  begin b6 = 6'b010011; RD_mid= RD_pre;   end
                5'd19:  begin b6 = 6'b110010; RD_mid= RD_pre;   end
                5'd20:  begin b6 = 6'b001011; RD_mid= RD_pre;   end
                5'd21:  begin b6 = 6'b101010; RD_mid= RD_pre;   end
                5'd22:  begin b6 = 6'b011010; RD_mid= RD_pre;   end
                5'd23:  begin b6 = (RD_pre)?6'b000101:6'b111010; RD_mid=~RD_pre; end
                5'd24:  begin b6 = (RD_pre)?6'b001100:6'b110011; RD_mid=~RD_pre; end
                5'd25:  begin b6 = 6'b100110; RD_mid= RD_pre;   end
                5'd26:  begin b6 = 6'b010110; RD_mid= RD_pre;   end
                5'd27:  begin b6 = (RD_pre)?6'b001001:6'b110110; RD_mid=~RD_pre; end
                5'd28:  begin b6 = 6'b001110; RD_mid= RD_pre;   end
                5'd29:  begin b6 = (RD_pre)?6'b010001:6'b101110; RD_mid=~RD_pre; end
                5'd30:  begin b6 = (RD_pre)?6'b100001:6'b011110; RD_mid=~RD_pre; end
                5'd31:  begin b6 = (RD_pre)?6'b010100:6'b101011; RD_mid=~RD_pre; end
                default:begin b6 = 6'bxxxxxx; RD_mid= RD_pre;   end
            endcase
        end

        /////////////////////////////////////////
        // 3.4 3b->4b编码 (fghj)
        /////////////////////////////////////////
        case(din_8b[7:5])  // HGF -> fghj
            3'd0: begin 
                b4     = (RD_mid)? 4'b0100 : 4'b1011; 
                RD_next= ~RD_mid; 
            end
            3'd1: begin 
                b4     = (!RD_mid && is_k28)? 4'b0110 : 4'b1001;
                RD_next= RD_mid; 
            end
            3'd2: begin 
                b4     = (!RD_mid && is_k28)? 4'b1010 : 4'b0101; 
                RD_next= RD_mid; 
            end
            3'd3: begin 
                b4     = (RD_mid)? 4'b0011 : 4'b1100;
                RD_next= RD_mid; 
            end
            3'd4: begin
                b4     = (RD_mid)? 4'b0010 : 4'b1101;
                RD_next= ~RD_mid;
            end
            3'd5: begin
                b4     = (!RD_mid && is_k28)? 4'b0101 : 4'b1010;
                RD_next= RD_mid;
            end
            3'd6: begin
                b4     = (!RD_mid && is_k28)? 4'b1001 : 4'b0110;
                RD_next= RD_mid;
            end
            3'd7: begin
                RD_next= ~RD_mid;
                if(is_P7) 
                    b4 = (RD_mid)? 4'b0001 : 4'b1110;
                else
                    b4 = (RD_mid)? 4'b0111 : 4'b1000;
            end
            default: begin
                b4     = 4'bxxxx;
                RD_next= RD_mid;
            end
        endcase

        // 组合出原始10位编码（未反转）： {b6, b4}
        code_temp = {b6, b4};

        // 对 code_temp 进行逐位反转：
        for (i = 0; i < 10; i = i + 1) begin
            reversed[i] = code_temp[9 - i];
        end

        // 最终输出 (11bit: 下一个 RD + 反转后的 10bit编码)
        code_10b = {RD_next, reversed};
    end
endfunction

endmodule

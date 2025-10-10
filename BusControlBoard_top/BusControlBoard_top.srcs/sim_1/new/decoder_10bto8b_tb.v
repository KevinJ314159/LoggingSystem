module decoder_10bto8b_tb(
    input clk,              // 时钟信号
    input rst_n,            // 复位信号
    input valid_in,         // 输入有效信号
    input [9:0] din_10b,    // 10位输入数据
    output reg [7:0] dout_8b,  // 8位输出解码数据
    output reg valid_out    // 解码结果有效信号
    );

    reg [2:0] dout_3b_r;
    reg [4:0] dout_5b_r;
    reg is_k28;
    reg [3:0] din_4b;
    reg [5:0] din_6b;
//    reg [9:0] din_10b_reversed;  // 反转后的 10 位输入数据
    reg valid_in_d;

/*    // 高低位反转（字节顺序反转）
    assign din_10b_reversed = {din_10b[0], din_10b[1], din_10b[2], din_10b[3], 
                               din_10b[4], din_10b[5], din_10b[6], din_10b[7], 
                               din_10b[8], din_10b[9]};*/

always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
//            din_10b_reversed <= 10'd0;
            din_4b <= 4'd0;
            din_6b <= 6'd0;
            valid_in_d <= 1'b0;
            end
        else if (valid_in) begin
//            din_10b_reversed <= {din_10b[0], din_10b[1], din_10b[2], din_10b[3], din_10b[4], din_10b[5], din_10b[6], din_10b[7], din_10b[8], din_10b[9]};
            din_4b = {din_10b[6], din_10b[7], din_10b[8], din_10b[9]};  // 反转后的低4位
            din_6b = {din_10b[0], din_10b[1], din_10b[2], din_10b[3], din_10b[4], din_10b[5]};  // 反转后的高6位
            valid_in_d <= valid_in;
        end
            else 
                valid_in_d <= 1'b0;
    end

//    assign din_4b = din_10b_reversed[3:0];  // 反转后的低4位
//    assign din_6b = din_10b_reversed[9:4];  // 反转后的高6位

    initial begin
        is_k28 = 0;
        valid_out = 0;
        dout_3b_r = 0;
        dout_5b_r = 0;
    end

    // 4b to 3b 解码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout_3b_r <= 3'd0;
        else if (valid_in_d) begin
            case(din_4b)
            4'b1011:dout_3b_r =  3'd0;
            4'b0100:dout_3b_r =  3'd0;
            4'b1001:dout_3b_r = (is_k28)? 3'd6: 3'd1;       //(D28)？
            4'b0110:dout_3b_r = (is_k28)? 3'd1: 3'd6;      //K码的编码,RD=-1
//            4'b0110:dout_3b_r =  3'd6;
//            4'b1001:dout_3b_r =  3'd6;      //K码的编码，RD=-1
            
            4'b0101:dout_3b_r = (is_k28)? 3'd5: 3'd2;      //(D28)？
            4'b1010:dout_3b_r = (is_k28)? 3'd2: 3'd5;      //K码的编码,RD=-1
//            4'b1010:dout_3b_r =  3'd5;
//            4'b0101:dout_3b_r =  3'd5;      //K码的编码，RD=-1
            4'b1100:dout_3b_r =  3'd3;
            4'b0011:dout_3b_r =  3'd3;
            4'b1101:dout_3b_r =  3'd4;
            4'b0010:dout_3b_r =  3'd4;


            4'b1110:dout_3b_r =  3'd7;//P7
            4'b0001:dout_3b_r =  3'd7;//P7
            4'b0111:dout_3b_r =  3'd7;//A7,K
            4'b1000:dout_3b_r =  3'd7;//A7,K
            default: dout_3b_r = 3'bXXX; 
            endcase
        end
    end

     // 6b to 5b 解码
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            dout_5b_r <= 5'd0;
        else if (valid_in_d) begin
 case(din_6b)
               6'b100111 : dout_5b_r = 5'd0 ;
               6'b011101 : dout_5b_r = 5'd1 ;
               6'b101101 : dout_5b_r = 5'd2 ;
               6'b110001 : dout_5b_r = 5'd3 ;
               6'b110101 : dout_5b_r = 5'd4 ;
               6'b101001 : dout_5b_r = 5'd5 ;
               6'b011001 : dout_5b_r = 5'd6 ;
               6'b111000 : dout_5b_r = 5'd7 ;
               6'b111001 : dout_5b_r = 5'd8 ;
               6'b100101 : dout_5b_r = 5'd9 ;
               6'b010101 : dout_5b_r = 5'd10;
               6'b110100 : dout_5b_r = 5'd11;
               6'b001101 : dout_5b_r = 5'd12;
               6'b101100 : dout_5b_r = 5'd13;
               6'b011100 : dout_5b_r = 5'd14;
               6'b010111 : dout_5b_r = 5'd15;
               6'b011011 : dout_5b_r = 5'd16;
               6'b100011 : dout_5b_r = 5'd17;
               6'b010011 : dout_5b_r = 5'd18;
               6'b110010 : dout_5b_r = 5'd19;
               6'b001011 : dout_5b_r = 5'd20;
               6'b101010 : dout_5b_r = 5'd21;
               6'b011010 : dout_5b_r = 5'd22;
               6'b111010 : dout_5b_r = 5'd23;
               6'b110011 : dout_5b_r = 5'd24;
               6'b100110 : dout_5b_r = 5'd25;
               6'b010110 : dout_5b_r = 5'd26;
               6'b110110 : dout_5b_r = 5'd27;
               6'b001110 : dout_5b_r = 5'd28;
               6'b101110 : dout_5b_r = 5'd29;
               6'b011110 : dout_5b_r = 5'd30;
               6'b101011 : dout_5b_r = 5'd31;
               6'b011000 : dout_5b_r = 5'd0 ;
               6'b100010 : dout_5b_r = 5'd1 ;
               6'b010010 : dout_5b_r = 5'd2 ; 
               6'b001010 : dout_5b_r = 5'd4 ;
               6'b000111 : dout_5b_r = 5'd7 ; 
               6'b000110 : dout_5b_r = 5'd8 ; 
               6'b101000 : dout_5b_r = 5'd15;
               6'b100100 : dout_5b_r = 5'd16;
               6'b000101 : dout_5b_r = 5'd23;
               6'b001100 : dout_5b_r = 5'd24;
               6'b001001 : dout_5b_r = 5'd27;
               6'b010001 : dout_5b_r = 5'd29;
               6'b100001 : dout_5b_r = 5'd30;
               6'b010100 : dout_5b_r = 5'd31;
               6'b001111 : begin dout_5b_r = 5'd28; is_k28 = 1;end
               6'b110000 : begin dout_5b_r = 5'd28; is_k28 = 1;end
               default : begin dout_5b_r = 5'bXXXXX; is_k28 = 0;end
            endcase
        end
    end

    // 输出解码结果并生成有效信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_8b <= 8'd0;
            valid_out <= 0;
        end else if (valid_in_d) begin
            dout_8b <= {dout_3b_r, dout_5b_r};  // 合并3b和5b为8b输出
            valid_out <= 1;  // 在解码后拉高有效信号
        end else begin
            valid_out <= 0;  // 拉低有效信号
        end
    end

endmodule
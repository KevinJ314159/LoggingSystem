// Module: encode
// Time:
// Auther:
//
// Description: 
//     8b/10b encoding of one frame.
//     Encode_en signal will keep high for one frame.When it detects encode_en high,it will do first 8b/10b encoding,
// then do next 8b/10b encoding whenever it detects once encode_continue signal until one frame is encoded completely.
//		
// Modification:  
//     2014.6.9
//         Add one state(delay) in order to delay state(load_data) one period.

module encode_8bTo10b_new (
	input clk,
	input rst_n,
	input encode_en,
	input encode_continue,
	input [7:0] data_8b,
	
	output reg [9:0] data_10b,
	output reg data_10b_en,
	output reg encode_load_data_flag
);
	//input clk;
	//input rst_n;
	//input encode_en;	// enable signal of one frame encoding,keep high for one frame when encoding
	//input encode_continue;	// when the encoded 10bits data loaded by next module,next module will output encode_continue signal to make it continue next data's encoding
	//input [7:0]data_8b;	// unencoded data
	//output reg [9:0]data_10b;	// encoded data
	//output reg data_10b_en;	// synchronized signal of one encoded data
	//output reg encode_load_data_flag;	// this signal show that the data previous module produced has been used,the previous module can generate next data..
//	output reg [7:0]data_8b_crc;
	
	                
	parameter idle = 3'd0;
	parameter delay = 3'd1;
	parameter load_data = 3'd2;
	parameter encode_5b_6b = 3'd3;
	parameter encode_3b_4b = 3'd4;
	parameter data_10b_out = 3'd5;
	parameter waiting = 3'd6;
	reg [2:0]state,n_state;
	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			state <= idle;
		end
		else if (encode_en) begin	// encode only at high level 
			state <= n_state;
		end
		else begin
			state <= idle;
		end
	end
	
	always @ ( * ) begin
		case (state)
			idle: begin 
				if (encode_en) begin
					n_state = delay;
				end
				else begin
					n_state = idle;
				end
			end
			delay: begin
				n_state = load_data;
			end
			load_data: begin
				n_state = encode_5b_6b;
			end
			encode_5b_6b: begin
					n_state = encode_3b_4b;
			end
			encode_3b_4b: begin
					n_state = data_10b_out;
			end
			data_10b_out: begin
				n_state = waiting;
			end
			waiting: begin
				if (encode_continue) begin	// wait encode_continue signal,go on next encoding
					n_state = load_data;
				end
				else begin
					n_state = waiting;
				end
			end
			default: n_state = idle;
		endcase
	end
	
	reg [4:0]data_5b;
	reg [2:0]data_3b;
	reg [5:0]data_6b;
	reg [3:0]data_4b;
//	reg [8:0]count;
	reg rd;
	always @ (posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			data_10b <= 10'd0;
			data_10b_en <= 1'b0;
	      data_5b <= 5'd0;
			data_3b <= 3'd0;
			data_6b <= 6'd0;
			data_4b <= 4'd0;
			rd <= 1'b0;
			encode_load_data_flag <= 1'b0;
//			data_8b_crc <= 8'd0;
//			count <= 8'd0;
		end
		else begin
			case (state)
				idle: begin
					data_10b <= 10'd0;
					data_10b_en <= 1'b0;
					data_5b <= 5'd0;
					data_3b <= 3'd0;
					data_6b <= 6'd0;
					data_4b <= 4'd0;
					rd <= 1'b0;
					encode_load_data_flag <= 1'b0;
//					data_8b_crc <= 8'd0;
//					count <= 8'd0;
				end
				delay: begin	// delay 1T
					data_10b <= 10'd0;
					data_10b_en <= 1'b0;
					data_5b <= 5'd0;
					data_3b <= 3'd0;
					data_6b <= 6'd0;
					data_4b <= 4'd0;
					rd <= 1'b0;
					encode_load_data_flag <= 1'b0;
				end
				load_data: begin
					encode_load_data_flag <= 1'b1;
					data_5b <= data_8b[4:0];
					data_3b <= data_8b[7:5];
				end
				encode_5b_6b: begin
					encode_load_data_flag <= 1'b0;
					case (data_5b)
						5'd0: begin
							data_6b <= rd ? 6'b000110 : 6'b111001;
							rd <= ~rd;
						end
						5'd1: begin
							data_6b <= rd ? 6'b010001 : 6'b101110;
							rd <= ~rd;
						end
						5'd2: begin
							data_6b <= rd ? 6'b010010 : 6'b101101;
							rd <= ~rd;
						end
						5'd3: begin
							data_6b <= 6'b100011;
							rd <= rd;
						end
						5'd4: begin
							data_6b <= rd ? 6'b010100 : 6'b101011;
							rd <= ~rd;
						end
						5'd5: begin
							data_6b <= 6'b100101;
							rd <= rd;
						end
						5'd6: begin
							data_6b <= 6'b100110;
							rd <= rd;
						end
						5'd7: begin
							data_6b <= rd ? 6'b111000 : 6'b000111;
							rd <= rd;
						end
						5'd8: begin
							data_6b <= rd ? 6'b011000 : 6'b100111;
							rd <= ~rd;
						end
						5'd9: begin
							data_6b <= 6'b101001;
							rd <= rd;
						end
						5'd10: begin
							data_6b <= 6'b101010;
							rd <= rd;
						end
						5'd11: begin
							data_6b <= 6'b001011;
							rd <= rd;
						end
						5'd12: begin
							data_6b <= 6'b101100;
							rd <= rd;
						end
						5'd13: begin
							data_6b <= 6'b001101;
							rd <= rd;
						end
						5'd14: begin
							data_6b <= 6'b001110;
							rd <= rd;
						end
						5'd15: begin
							data_6b <= rd ? 6'b000101 : 6'b111010;
							rd <= ~rd;
						end
						5'd16: begin
							data_6b <= rd ? 6'b001001 : 6'b110110;
							rd <= ~rd;
						end
						5'd17: begin
							data_6b <= 6'b110001;
							rd <= rd;
						end
						5'd18: begin
							data_6b <= 6'b110010;
							rd <= rd;
						end
						5'd19: begin
							data_6b <= 6'b010011;
							rd <= rd;
						end
						5'd20: begin
							data_6b <= 6'b110100;
							rd <= rd;
						end
						5'd21: begin
							data_6b <= 6'b010101;
							rd <= rd;
						end
						5'd22: begin
							data_6b <= 6'b010110;
							rd <= rd;
						end
						5'd23: begin
							data_6b <= rd ? 6'b101000 : 6'b010111;
							rd <= ~rd;
						end
						5'd24: begin
							data_6b <= rd ? 6'b001100 : 6'b110011;
							rd <= ~rd;
						end
						5'd25: begin
							data_6b <= 6'b011001;
							rd <= rd;
						end
						5'd26: begin
							data_6b <= 6'b011010;
							rd <= rd;
						end
						5'd27: begin
							data_6b <= rd ? 6'b100100 : 6'b011011;
							rd <= ~rd;
						end
						5'd28: begin
							data_6b <= 6'b011100;
							rd <= rd;
						end
						5'd29: begin
							data_6b <= rd ? 6'b100010 : 6'b011101;
							rd <= ~rd;
						end
						5'd30: begin
							data_6b <= rd ? 6'b100001 : 6'b011110;
							rd <= ~rd;
						end
						5'd31: begin
							data_6b <= rd ? 6'b001010 : 6'b110101;
							rd <= ~rd;
						end
						default: ;
					endcase
				end
				encode_3b_4b: begin
					case (data_3b)
						3'd0: begin
							data_4b <= rd ? 4'b0010 : 4'b1101;
							rd <= ~rd;
						end
						3'd1: begin
							data_4b <= 4'b1001;
							rd <= rd;
						end
						3'd2: begin
							data_4b <= 4'b1010;
							rd <= rd;
						end
						3'd3: begin
							data_4b <= rd ? 4'b1100 : 4'b0011;
							rd <= rd;
						end
						3'd4: begin
							data_4b <= rd ? 4'b0100 : 4'b1011;
							rd <= ~rd;
						end
						3'd5: begin
							data_4b <= 4'b0101;
							rd <= rd;
						end
						3'd6: begin
							data_4b <= 4'b0110;
							rd <= rd;
						end
						3'd7: begin
							if (((rd > 1'b0) && ~data_6b[5] && ~data_6b[4]) || ((rd == 1'b0) && data_6b[5] && data_6b[4])) begin
								data_4b <= rd ? 4'b0001 : 4'b1110;  // D.x.A7
							end
							else begin
								data_4b <= rd ? 4'b1000 : 4'b0111;  // D.x.P7
							end
							rd <= ~rd;
						end
						default: ;
					endcase
				end
				data_10b_out: begin	// out one encoded data 
					data_10b <= {data_4b,data_6b};
					data_10b_en <= 1'b1;
				end
				waiting: begin
					data_10b_en <= 1'b0;
				end
				default: ;
			endcase
		end
	end

endmodule

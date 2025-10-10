/*此模块用于将McBSP接口收到的16bit串行数据转变为8bit并行数据。*/

module McBSPDriver_16bTo8b (
    input interfaceClk,    // McBSP接口10Mhz时钟（来自DSP的串行时钟）
    input nRst,            // 低有效复位（异步复位）
    input McBSPFSR,        // McBSP帧同步信号（指示帧开始）
    input McBSPDR,         // McBSP串行数据输入（1-bit）
    output reg McBSPDataEn,// 并行数据有效标志（高电平有效）
    output reg [7:0] McBSPData // 输出的8位并行数据
);

//-------------------------
// 内部寄存器定义
//-------------------------
reg [3:0] bit_cnt;     // 4-bit位计数器（0-15计数）
reg [15:0] shift_reg;  // 16位移位寄存器（存储接收的串行数据）
reg frame_synced;      // 帧同步标志（1=正在接收数据帧）

//-------------------------
// 主逻辑流程
//-------------------------
always @(negedge interfaceClk or negedge nRst) begin
    // 复位初始化
    if (!nRst) begin
        bit_cnt <= 4'd0;          
        shift_reg <= 16'h0;       
        McBSPDataEn <= 1'b0;      
        frame_synced <= 1'b0;     
        McBSPData <= 8'b0;
    end 
    // 正常工作模式
    else begin
        McBSPDataEn <= 1'b0;  // 默认数据无效
        
        // 帧同步检测（下降沿触发）
        if (McBSPFSR && !frame_synced) begin
            frame_synced <= 1'b1; 
            bit_cnt <= 4'd0;      
        end
        
        // 数据接收阶段
        if (frame_synced) begin
            // 串行数据移位（MSB first）
            shift_reg <= {shift_reg[14:0], McBSPDR};  
            
            // 位计数器递增
            bit_cnt <= bit_cnt + 1;  

            // 每接收8位输出一次
            if (bit_cnt == 4'd7) begin       // 接收前8位
                McBSPData <= {shift_reg[6:0],McBSPDR}; // 取低8位（先接收的8位）
                McBSPDataEn <= 1'b1;
            end
            else if (bit_cnt == 4'd15) begin // 接收后8位
                McBSPData <= {shift_reg[6:0],McBSPDR};  // 取低8位（后接收的8位）
                McBSPDataEn <= 1'b1;
                frame_synced <= 1'b0;         // 结束帧接收
            end
        end
    end
end

endmodule
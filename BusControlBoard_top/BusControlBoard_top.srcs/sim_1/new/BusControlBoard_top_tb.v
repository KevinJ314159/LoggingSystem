`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/04/03 10:36:23
// Design Name: 
// Module Name: BusControlBoard_top_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BusControlBoard_top_tb;
//    reg CLK_10MHZ_t_1;
    reg ClkIn_t;
    reg nRst_t;

    reg DownSig_RClk_t;
    reg DownSig_nLock_t;
    reg [9:0] DownSig_ROut_t;

    wire DownSig_RClk_RnF_t;
    wire DownSig_nPWRDN_t;
    wire DownSig_REn_t;
    wire DownSig_RefClk;

    wire UpSig_TClk_RnF_t;
    wire [9:0] UpSig_Din_t;
    wire UpSig_DEn_t;
    wire UpSig_nPWRDN_t;
    wire UpSig_Sync1_t;
    wire UpSig_Sync2_t;
    wire UpSig_TClk;

    reg McBSPFSR_t;
    reg McBSPDR_t;

    wire outDataToDsp_t;
    wire DspUlClk_t;


BusControlBoard_top BusControlBoard_top_tb1(
    .ClkIn(ClkIn_t),        // 40Mhz鏃堕挓杈撳叆
    .nRst(nRst_t),         // 寮傛澶嶄綅淇″彿锛堜綆鐢靛钩鏈夋晥锛?

    .DownSig_RClk(DownSig_RClk_t),     // 鏉ヨ嚜瑙ｄ覆鍣ㄧ殑鎭㈠鏃堕挓
    .DownSig_nLock(DownSig_nLock_t),    // 鏉ヨ嚜瑙ｄ覆鍣ㄧ殑PLL閿佸畾淇″彿
    .DownSig_ROut(DownSig_ROut_t),     // 鏉ヨ嚜涓茶鍒板苟琛岃浆鎹紙瑙ｄ覆鍣級鐨?10浣嶆暟鎹緭鍑?

    .DownSig_RefClk(DownSig_RefClk),      // 鎻愪緵缁? 涓茶鍒板苟琛岃浆鎹紙瑙ｄ覆鍣級鐨勫弬鑰冩椂閽熶俊鍙?
    .DownSig_RClk_RnF(DownSig_RClk_RnF_t),   // 鎻愪緵缁? 涓茶鍒板苟琛岃浆鎹紙瑙ｄ覆鍣級鐨勬帴鏀舵椂閽熷弽杞俊鍙?
    .DownSig_nPWRDN(DownSig_nPWRDN_t),    // 鎻愪緵缁? 涓插苟杞崲锛堣В涓插櫒锛夌殑鎺夌數淇″彿
    .DownSig_REn(DownSig_REn_t),       //. 鎻愪緵缁? 涓插苟杞崲锛堣В涓插櫒锛夌殑鏁版嵁浣胯兘淇″彿

    .UpSig_TClk_RnF(UpSig_TClk_RnF_t),     // 鎻愪緵缁? 骞朵覆杞崲锛堜覆琛屽櫒锛夌殑浼犺緭鏃堕挓鍙嶈浆淇″彿
    .UpSig_Din(UpSig_Din_t),          // 鎻愪緵缁? 骞朵覆杞崲鍣紙涓茶鍣級鐨?10浣嶆暟鎹?
    .UpSig_DEn(UpSig_DEn_t),          // 鎻愪緵缁? 骞惰鍒颁覆琛岃浆鎹紙涓茶鍣級鐨勬暟鎹娇鑳戒俊鍙?
    .UpSig_nPWRDN(UpSig_nPWRDN_t),       //  鎻愪緵缁? 骞朵覆杞崲鍣紙涓茶鍣級鐨勬帀鐢典俊鍙?
    .UpSig_Sync1(UpSig_Sync1_t),
    .UpSig_Sync2(UpSig_Sync2_t),
    .UpSig_TClk(UpSig_TClk),



    .McBSPFSR(McBSPFSR_t),        // McBSP甯у悓姝ヤ俊鍙凤紙鎸囩ず甯у紑濮嬶級
    .McBSPDR(McBSPDR_t),         // McBSP涓茶鏁版嵁杈撳叆锛?1-bit锛?


    .outDataToDsp(outDataToDsp_t),

    .DspUlClk(DspUlClk_t)        // 涓婅FIFO鎻愪緵缁欎簳涓婦SP鐨勫彂閫佸弬鑰冩椂閽?





    );

    reg  [7:0]  validData;
    reg  validDataEn;
    wire [9:0]outData;      // 10Bb缂栫爜鍚庣殑鏁版嵁
    reg Sync_CodeDown;

    reg [10:0] count; // 鍙戦?佹鏁拌鏁板櫒

encode_8bto10b_sim encode_8bto10b_sim_instance(
    .clk(DownSig_RClk_t),
    .rst_n(nRst_t),
//    .encode_en()
    .din_en(validDataEn),
    .is_k(1'b1),
    .din_8b(validData),
    .dout_10b(outData),
    .dout_en(outDataen)
    );


always begin
        #12 ClkIn_t = ~ClkIn_t; // 姣?12ns缈昏浆涓?娆℃椂閽?40Mhz
//        #48 DownSig_RClk_t = ~DownSig_RClk_t;
    end

always begin
//        #12 ClkIn_t = ~ClkIn_t; // 姣?12ns缈昏浆涓?娆℃椂閽?40Mhz
        #48 DownSig_RClk_t = ~DownSig_RClk_t;
    end

    // DownSig_Rout_t鍙戦?佹暟鎹?昏緫锛氬湪鏃堕挓涓嬮檷娌垮彂閫佹暟鎹?
    always @(negedge DownSig_RClk_t or negedge nRst_t) begin
        if (!nRst_t) begin
            Sync_CodeDown <= 1;
            count <= 0;
            DownSig_ROut_t <= 10'd0;
        end else begin
            if (count < 10 && Sync_CodeDown) begin
                // 鍓?10娆″彂閫?10'b10010_00101
                DownSig_ROut_t <= 10'b10010_00101;
            end else if (count < 20 && Sync_CodeDown) begin
                // 鎺ヤ笅鏉ョ殑10娆″彂閫?10'b00000_11111
                DownSig_ROut_t <= 10'b00000_11111;
            end else if (count < 30 && Sync_CodeDown) begin
                // 鎺ヤ笅鏉ョ殑10娆″彂閫?10'b10010_00101
                DownSig_ROut_t <= 10'b10010_00101;
            end else if (count < 1026 && Sync_CodeDown) begin
                // 鎺ヤ笅鏉ョ殑40娆″彂閫?10'b00000_11111
                DownSig_ROut_t <= 10'b00000_11111;
            end else if (count == 1026 && Sync_CodeDown) begin
                // 鏈?鍚庝竴娆″彂閫?10'b01111_11110
                DownSig_ROut_t <= 10'b01111_11110;

            end else if (count == 1080 && Sync_CodeDown) begin
                DownSig_ROut_t <= 10'b10100_00111;
                // 鍙戦??10'h287
            end else if (count == 1090 && Sync_CodeDown) begin
                DownSig_ROut_t <= 10'b10100_00111;
                // 鍙戦??10'h287
            end else if (count < 1100 && Sync_CodeDown) begin
                DownSig_ROut_t <= 110'b11111_00111;

            end else if (count < 1200 && Sync_CodeDown) begin
                DownSig_ROut_t <= 10'b11111_01111;

            end else if (count < 1500 && Sync_CodeDown) begin
                DownSig_ROut_t <= 10'b11111_11111;
            end else begin
                DownSig_ROut_t <= outData;
                Sync_CodeDown <= 0;
                end 

            count <= count + 1; // 璁℃暟鍣ㄩ?掑
        end
    end



    // 鍒濆鍧?
    initial begin
        ClkIn_t = 1;
        DownSig_RClk_t = 1;
        nRst_t = 0;
        DownSig_nLock_t = 0;
        Sync_CodeDown <= 1'b1;
        validData <= 8'd0;
        validDataEn <= 1'b0;
        McBSPFSR_t <= 0; 
        McBSPDR_t <= 0;


//        DataIn_t_send_flag = 0;
        #201 nRst_t = 1; // 閲婃斁澶嶄綅淇″彿
//        #15000 DataIn_t_send_flag = 1;
    #1000000;
    begin

    // 2) 杩炲彂涓や釜 0x47 (濡傛灉鍐欐帶闇?瑕佷袱杩炲瓧鑺? 0x47 鎵嶈Е鍙?)
//    sendByte_8cycles_1pulse(8'h47);
//    sendByte_8cycles_1pulse(8'h47);

    // 3) 缁х画鍙戦?? 8 涓瓧鑺?
//    repeat(8) sendByte_8cycles_1pulse($random);

    // 4) 妯℃嫙璇绘帶鍒跺櫒璇诲畬 RAM0
//    #1000;
//    UlRAM_rd_state = 2'b01;
//    #200;
//    UlRAM_rd_state = 2'b00;

    // 5) 鍐嶅彂涓や釜 0x47 => 鍐欎笅涓?甯?
    validDataEn <= 1'b1;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);
    repeat(36) sendByte_8cycles_1pulse($random);
    #100
    validDataEn <= 1'b0;
    end

    #300000;
    begin
    validDataEn <= 1'b1;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);
    repeat(36) sendByte_8cycles_1pulse($random);
    #100
    validDataEn <= 1'b0;
    end

     #300000;
     begin
     validDataEn <= 1'b1;
    sendByte_8cycles_1pulse(8'h47);
    sendByte_8cycles_1pulse(8'h47);
    repeat(36) sendByte_8cycles_1pulse($random);
    #100
    validDataEn <= 1'b0;
    end

    send_4_frames();

    #4000000;
//        #25000 RX_Los_t = 1;
        #400;
        nRst_t = 0;
        #400
        $stop;
    end




  task sendByte_8cycles_1pulse(input [7:0] dataInTask);
    integer i;
    begin
      // 绗竴涓笅闄嶆部锛氳 inDataEn=1, 骞跺啓鍏? inData
      @(negedge DownSig_RClk_t);
      validData   <= dataInTask;
//      inDataEn <= 1'b1;

      // 绗簩涓笅闄嶆部锛氱珛鍗虫媺浣? inDataEn (鍙淮鎸?1涓懆鏈?)
//      @(negedge clk);
//      inDataEn <= 1'b0;
      // 鍚屾椂 inData 淇濇寔涓嶅彉

      // 鍐嶄繚鎸佸墿浣?6涓笅闄嶆部(璁? inData 鎸佺画鎬诲叡8涓懆鏈?)
//      for(i=0; i<6; i=i+1) begin
//        @(negedge clk);
//      end

      // 瀹屾垚 8 涓笅闄嶆部鍚庯紝鎵嶅彂閫佷笅涓?涓瓧鑺?
      // (褰撳墠鏃跺埢 inDataEn=0, inData 渚濇棫淇濇寔, 鐩村埌姝ゆ椂鍒囨崲)
    end
  endtask



  task send_4_frames;
    integer i, j;
    reg [15:0] data;
begin
    for (i = 0; i < 4; i = i + 1) begin
        // 鍙戦?佺涓?鏁版嵁锛屽浐瀹氫负 16'h4747
        send_16bit_data(16'h4747);
        
        // 鍙戦?佸墿涓嬬殑130涓殢鏈烘暟鎹?
        for (j = 0; j < 130; j = j + 1) begin
            data = $random;  // 鐢熸垚闅忔満16浣嶆暟鎹?
            send_16bit_data(data);
        end
        
        // 姣忓彂閫佸畬涓?缁勫抚鍚庯紝绛夊緟2000ns (200涓椂閽熷懆鏈?)
        #2000;
    end
end
endtask

//-------------------------------------------------
// 鍙戦??16浣嶆暟鎹换鍔? (FSR 鎷夐珮涓?涓懆鏈?)
//-------------------------------------------------
task send_16bit_data;
    input [15:0] data;
    integer i;
begin
    // Step 1: 鍏堟媺楂? FSR 淇″彿 1 涓懆鏈?
    @(posedge DspUlClk_t);
    McBSPFSR_t <= 1;
    @(posedge DspUlClk_t);
    McBSPFSR_t <= 0;  // 浠呬繚鎸? 1 涓懆鏈?
    
    // Step 2: 渚濇鍙戦?? 16 浣嶆暟鎹?
    for (i = 15; i >= 0; i = i - 1) begin
        McBSPDR_t <= data[i];
        @(posedge DspUlClk_t);
    end
end
endtask


endmodule

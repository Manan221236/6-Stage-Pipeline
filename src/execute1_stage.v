module execute1_stage (
    input  wire        clk, rst,
    
    // From Decode
    input  wire [31:0] RD1_D, RD2_D, Imm_Ext_D,
    input  wire [4:0]  ALUControlD, RD_D,
    input  wire        RegWriteD, ALUSrcD, MemWriteD,
    input  wire [1:0]  ResultSrcD,
    input  wire        BranchD, JumpD,
    input  wire [31:0] PCD, PCPlus4D,
    input  wire [2:0]  LoadTypeD, StoreTypeD, funct3_D,
    input  wire [4:0]  RS1_D, RS2_D,
    
    // Forwarding inputs
    input  wire [1:0]  ForwardA_E1, ForwardB_E1,
    input  wire [31:0] ALU_ResultE2, ALU_ResultM, ResultW,
    
    // To Execute2
    output reg [31:0]  Src_A_E1, Src_B_E1, Imm_Ext_E1,
    output reg [4:0]   ALUControlE1, RD_E1,
    output reg         RegWriteE1, MemWriteE1,
    output reg [1:0]   ResultSrcE1,
    output reg         BranchE1, JumpE1,
    output reg [31:0]  PCE1, PCPlus4E1,
    output reg [2:0]   LoadTypeE1, StoreTypeE1, funct3_E1
);

    //----------------------------------------------------------------
    // ENHANCED Forwarding Logic (Combinational)
    //----------------------------------------------------------------
    wire [31:0] Src_A_pre, Src_B_pre;
    
    // Enhanced 4:1 forwarding muxes with proper priority
    assign Src_A_pre = (ForwardA_E1 == 2'b00) ? RD1_D :           // No forwarding
                       (ForwardA_E1 == 2'b01) ? ResultW :         // From WB stage
                       (ForwardA_E1 == 2'b10) ? ALU_ResultM :     // From MEM stage
                       (ForwardA_E1 == 2'b11) ? ALU_ResultE2 :    // From E2 stage
                       RD1_D;                                      // Default fallback
    
    assign Src_B_pre = (ForwardB_E1 == 2'b00) ? RD2_D :           // No forwarding
                       (ForwardB_E1 == 2'b01) ? ResultW :         // From WB stage
                       (ForwardB_E1 == 2'b10) ? ALU_ResultM :     // From MEM stage
                       (ForwardB_E1 == 2'b11) ? ALU_ResultE2 :    // From E2 stage
                       RD2_D;                                      // Default fallback
    
    // ALU source selection (ALUSrcD determines immediate vs register)
    wire [31:0] Src_B_final = ALUSrcD ? Imm_Ext_D : Src_B_pre;
    
    //----------------------------------------------------------------
    // Pipeline Register E1/E2
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            Src_A_E1 <= 32'h0;
            Src_B_E1 <= 32'h0;
            Imm_Ext_E1 <= 32'h0;
            ALUControlE1 <= 5'h0;
            RD_E1 <= 5'h0;
            RegWriteE1 <= 1'b0;
            MemWriteE1 <= 1'b0;
            ResultSrcE1 <= 2'b00;
            BranchE1 <= 1'b0;
            JumpE1 <= 1'b0;
            PCE1 <= 32'h0;
            PCPlus4E1 <= 32'h0;
            LoadTypeE1 <= 3'b000;
            StoreTypeE1 <= 3'b000;
            funct3_E1 <= 3'b000;
        end else begin
            // Register forwarded operands
            Src_A_E1 <= Src_A_pre;
            Src_B_E1 <= Src_B_final;
            Imm_Ext_E1 <= Imm_Ext_D;
            
            // Pass through control signals
            ALUControlE1 <= ALUControlD;
            RD_E1 <= RD_D;
            RegWriteE1 <= RegWriteD;
            MemWriteE1 <= MemWriteD;
            ResultSrcE1 <= ResultSrcD;
            BranchE1 <= BranchD;
            JumpE1 <= JumpD;
            PCE1 <= PCD;
            PCPlus4E1 <= PCPlus4D;
            LoadTypeE1 <= LoadTypeD;
            StoreTypeE1 <= StoreTypeD;
            funct3_E1 <= funct3_D;
        end
    end
    
    //----------------------------------------------------------------
    // ENHANCED DEBUG OUTPUT
    //----------------------------------------------------------------
    
    // Debug forwarding decisions for important registers
    always @(*) begin
        if (!rst && (ForwardA_E1 != 2'b00 || ForwardB_E1 != 2'b00)) begin
            $display("EXECUTE1_FORWARD: RS1_D=x%0d, RS2_D=x%0d", RS1_D, RS2_D);
            $display("EXECUTE1_FORWARD: ForwardA=%b->0x%08h, ForwardB=%b->0x%08h", 
                     ForwardA_E1, Src_A_pre, ForwardB_E1, Src_B_pre);
            if (ForwardA_E1 == 2'b11) 
                $display("EXECUTE1_FORWARD: A from E2=0x%08h", ALU_ResultE2);
            if (ForwardA_E1 == 2'b10) 
                $display("EXECUTE1_FORWARD: A from MEM=0x%08h", ALU_ResultM);
            if (ForwardA_E1 == 2'b01) 
                $display("EXECUTE1_FORWARD: A from WB=0x%08h", ResultW);
        end
    end
    
    // Debug specific registers (A=x14, B=x15 inputs)
    always @(posedge clk) begin
        if (!rst && RegWriteD && (RD_D == 5'd14 || RD_D == 5'd15)) begin
            $display("EXECUTE1_INPUT: RD=x%0d, Src_A_pre=0x%08h(%0d), Src_B_final=0x%08h(%0d)", 
                     RD_D, Src_A_pre, $signed(Src_A_pre), Src_B_final, $signed(Src_B_final));
            $display("EXECUTE1_INPUT: ALUSrcD=%b (0=reg, 1=imm), Imm_Ext_D=0x%08h", 
                     ALUSrcD, Imm_Ext_D);
        end
    end
    
    // Debug multiplication setup
    always @(posedge clk) begin
        if (!rst && (ALUControlD >= 5'b01010) && (ALUControlD <= 5'b01101)) begin
            $display("EXECUTE1_MULT_SETUP: ALUControl=%b, A=0x%08h(%0d), B=0x%08h(%0d)", 
                     ALUControlD, Src_A_pre, $signed(Src_A_pre), Src_B_final, $signed(Src_B_final));
            if (Src_A_pre == 32'd12345 && Src_B_final == 32'd6789) begin
                $display("EXECUTE1_MULT_SETUP: ✅ CORRECT A=12345, B=6789 detected!");
            end else if (Src_A_pre == 32'd0 || Src_B_final == 32'd0) begin
                $display("EXECUTE1_MULT_SETUP: ❌ Zero input detected - check forwarding");
            end
        end
    end
    
    // Debug pipeline register updates
    always @(posedge clk) begin
        if (!rst && RegWriteD) begin
            $display("EXECUTE1_PIPELINE: Storing RD=x%0d, Src_A=0x%08h, Src_B=0x%08h", 
                     RD_D, Src_A_pre, Src_B_final);
        end
    end
    
endmodule
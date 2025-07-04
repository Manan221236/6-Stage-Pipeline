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
    // Stage 1: Forwarding Logic (Combinational)
    //----------------------------------------------------------------
    wire [31:0] Src_A_pre, Src_B_pre;
    
    // 3:1 forwarding muxes (optimized for single stage)
    assign Src_A_pre = (ForwardA_E1 == 2'b00) ? RD1_D :
                       (ForwardA_E1 == 2'b01) ? ResultW :
                       (ForwardA_E1 == 2'b10) ? ALU_ResultM :
                       ALU_ResultE2;
    
    assign Src_B_pre = (ForwardB_E1 == 2'b00) ? RD2_D :
                       (ForwardB_E1 == 2'b01) ? ResultW :
                       (ForwardB_E1 == 2'b10) ? ALU_ResultM :
                       ALU_ResultE2;
    
    // ALU source selection
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
    
endmodule
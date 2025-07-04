module execute2_stage (
    input  wire        clk, rst,
    
    // From Execute1
    input  wire [31:0] Src_A_E1, Src_B_E1, Imm_Ext_E1,
    input  wire [4:0]  ALUControlE1, RD_E1,
    input  wire        RegWriteE1, MemWriteE1,
    input  wire [1:0]  ResultSrcE1,
    input  wire        BranchE1, JumpE1,
    input  wire [31:0] PCE1, PCPlus4E1,
    input  wire [2:0]  LoadTypeE1, StoreTypeE1, funct3_E1,
    
    // To Memory
    output reg         RegWriteE2, MemWriteE2,
    output reg [1:0]   ResultSrcE2,
    output reg [4:0]   RD_E2,
    output reg [31:0]  PCPlus4E2, WriteDataE2, ALU_ResultE2,
    output reg [2:0]   LoadTypeE2, StoreTypeE2,
    
    // Branch/Jump outputs
    output wire        PCSrcE2,
    output wire [31:0] PCTargetE2, JALR_TargetE2,
    output wire        is_jalr_E2
);

    //----------------------------------------------------------------
    // ALU Operation (Combinational in this stage)
    //----------------------------------------------------------------
    wire [31:0] ALU_out;
    ALU alu_u (
        .clk(clk), .rst(rst),
        .A(Src_A_E1), .B(Src_B_E1),
        .Result(ALU_out),
        .ALUControl(ALUControlE1),
        .OverFlow(), .Carry(), .Zero(), .Negative()
    );

    //----------------------------------------------------------------
    // Branch Resolution (Combinational)
    //----------------------------------------------------------------
    wire BranchTakenE2;
    Branch_Comparator cmp_u (
        .A(Src_A_E1), .B(Src_B_E1),
        .funct3(funct3_E1),
        .BranchTaken(BranchTakenE2)
    );

    // Branch/jump targets
    PC_Adder add_branch (.a(PCE1), .b(Imm_Ext_E1), .c(PCTargetE2));
    JALR_Target_Calculator jalr_u (
        .Src_A(Src_A_E1), .Imm_Ext(Imm_Ext_E1), .JALR_Target(JALR_TargetE2)
    );

    assign is_jalr_E2 = JumpE1 & (funct3_E1 == 3'b000);
    assign PCSrcE2 = (BranchTakenE2 & BranchE1) | JumpE1;

    //----------------------------------------------------------------
    // Pipeline Register E2/M
    //----------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            RegWriteE2 <= 1'b0;
            MemWriteE2 <= 1'b0;
            ResultSrcE2 <= 2'b00;
            RD_E2 <= 5'h0;
            PCPlus4E2 <= 32'h0;
            WriteDataE2 <= 32'h0;
            ALU_ResultE2 <= 32'h0;
            LoadTypeE2 <= 3'b000;
            StoreTypeE2 <= 3'b000;
        end else begin
            RegWriteE2 <= RegWriteE1;
            MemWriteE2 <= MemWriteE1;
            ResultSrcE2 <= ResultSrcE1;
            RD_E2 <= RD_E1;
            PCPlus4E2 <= PCPlus4E1;
            WriteDataE2 <= Src_B_E1;  // For store operations
            ALU_ResultE2 <= ALU_out;
            LoadTypeE2 <= LoadTypeE1;
            StoreTypeE2 <= StoreTypeE1;
        end
    end
    
endmodule
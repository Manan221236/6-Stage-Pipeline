module Pipeline_top (input  wire clk,
                     input  wire rst,
                     // Debug outputs to prevent optimization
                     output wire [31:0] debug_alu_result,  // 32 pins
                     output wire [4:0]  debug_reg_addr,    // 5 pins  
                     output wire        debug_reg_write,   // 1 pin
                     output wire        debug_mem_write);  

    // -----------------------------------------------------------------
    //  6-STAGE PIPELINE INTER-STAGE WIRES
    // -----------------------------------------------------------------
    
    /* Fetch → Decode */
    wire [31:0] InstrD, PCD, PCPlus4D;

    /* Decode → Execute1 */
    wire        RegWriteD, ALUSrcD, MemWriteD, BranchD, JumpD;
    wire [1:0]  ResultSrcD;
    wire [4:0]  ALUControlD, RD_D, RS1_D, RS2_D;
    wire [31:0] RD1_D, RD2_D, Imm_Ext_D, PCD_to_E1, PCPlus4D_to_E1;
    wire [2:0]  LoadTypeD, StoreTypeD, funct3_D;

    /* Execute1 → Execute2 */
    wire [31:0] Src_A_E1, Src_B_E1, Imm_Ext_E1;
    wire [4:0]  ALUControlE1, RD_E1;
    wire        RegWriteE1, MemWriteE1;
    wire [1:0]  ResultSrcE1;
    wire        BranchE1, JumpE1;
    wire [31:0] PCE1, PCPlus4E1;
    wire [2:0]  LoadTypeE1, StoreTypeE1, funct3_E1;

    /* Execute2 → Memory */
    wire        PCSrcE2;
    wire [31:0] PCTargetE2, JALR_TargetE2;
    wire        RegWriteE2, MemWriteE2;
    wire [1:0]  ResultSrcE2;
    wire [31:0] PCPlus4E2, WriteDataE2, ALU_ResultE2;
    wire [4:0]  RD_E2;
    wire [2:0]  LoadTypeE2, StoreTypeE2;
    wire        is_jalr_E2;

    /* Memory → Write-back */
    wire        RegWriteM, MemWriteM;
    wire [1:0]  ResultSrcM;
    wire [31:0] PCPlus4M, WriteDataM, ALU_ResultM;
    wire [4:0]  RD_M;
    wire [2:0]  LoadTypeM, StoreTypeM;

    /* Write-back stage */
    wire        RegWriteW;
    wire [1:0]  ResultSrcW;
    wire [31:0] PCPlus4W, ALU_ResultW, ReadDataW;
    wire [4:0]  RDW;
    wire [2:0]  LoadTypeW, StoreTypeW;

    /* Final WB data (goes back to Decode & Execute1) */
    wire [31:0] ResultW;

    /* Forwarding selections for 6-stage pipeline */
    wire [1:0]  ForwardAE1, ForwardBE1;

    // ================================================================
    //  6-STAGE PIPELINE MODULE INSTANTIATION
    // ================================================================

    // ================================================================
    //  Stage 0 - FETCH
    // ================================================================
    fetch_cycle Fetch (
        .clk          (clk),
        .rst          (rst),
        .PCSrcE       (PCSrcE2),        // From Execute2 now
        .PCTargetE    (PCTargetE2),     // From Execute2
        .JALR_TargetE (JALR_TargetE2),  // From Execute2
        .JumpE        (JumpE1),         // From Execute1 (early detection)
        .is_jalr_E    (is_jalr_E2),     // From Execute2
        .InstrD       (InstrD),
        .PCD          (PCD),
        .PCPlus4D     (PCPlus4D)
    );

    // ================================================================
    //  Stage 5 - WRITE-BACK (instantiated early for ResultW)
    // ================================================================
    writeback_cycle WriteBack (
        .clk         (clk),
        .rst         (rst),
        .ResultSrcW  (ResultSrcW),
        .PCPlus4W    (PCPlus4W),
        .ALU_ResultW (ALU_ResultW),
        .ReadDataW   (ReadDataW),
        .ResultW     (ResultW)
    );

    // ================================================================
    //  6-Stage Hazard / Forwarding Unit
    // ================================================================
    hazard_unit_6stage Forwarding_block (
        .rst          (rst),
        .RegWriteE1   (RegWriteE1),     // From Execute1
        .RegWriteE2   (RegWriteE2),     // From Execute2
        .RegWriteM    (RegWriteM),      // From Memory
        .RegWriteW    (RegWriteW),      // From Write-back
        .RD_E1        (RD_E1),          // From Execute1
        .RD_E2        (RD_E2),          // From Execute2
        .RD_M         (RD_M),           // From Memory
        .RD_W         (RDW),            // From Write-back
        .Rs1_D        (RS1_D),          // From Decode
        .Rs2_D        (RS2_D),          // From Decode
        .ForwardA_E1  (ForwardAE1),     // To Execute1
        .ForwardB_E1  (ForwardBE1)      // To Execute1
    );

    // ================================================================
    //  Stage 1 - DECODE
    // ================================================================
    decode_cycle Decode (
        .clk          (clk),
        .rst          (rst),
        .InstrD       (InstrD),
        .PCD          (PCD),
        .PCPlus4D     (PCPlus4D),
        .RegWriteW    (RegWriteW),
        .RDW          (RDW),
        .ResultW      (ResultW),
        
        // Outputs to Execute1 (renamed for clarity)
        .RegWriteE    (RegWriteD),
        .ALUSrcE      (ALUSrcD),
        .MemWriteE    (MemWriteD),
        .ResultSrcE   (ResultSrcD),
        .BranchE      (BranchD),
        .ALUControlE  (ALUControlD),
        .RD1_E        (RD1_D),
        .RD2_E        (RD2_D),
        .Imm_Ext_E    (Imm_Ext_D),
        .RD_E         (RD_D),
        .PCE          (PCD_to_E1),
        .PCPlus4E     (PCPlus4D_to_E1),
        .RS1_E        (RS1_D),
        .RS2_E        (RS2_D),
        .JumpE        (JumpD),
        .LoadTypeE    (LoadTypeD),
        .StoreTypeE   (StoreTypeD),
        .funct3_E     (funct3_D)
    );

    // ================================================================
    //  Stage 2 - EXECUTE1 (Forwarding and Operand Preparation)
    // ================================================================
    execute1_stage Execute1 (
        .clk          (clk),
        .rst          (rst),
        
        // From Decode
        .RD1_D        (RD1_D),
        .RD2_D        (RD2_D),
        .Imm_Ext_D    (Imm_Ext_D),
        .ALUControlD  (ALUControlD),
        .RD_D         (RD_D),
        .RegWriteD    (RegWriteD),
        .ALUSrcD      (ALUSrcD),
        .MemWriteD    (MemWriteD),
        .ResultSrcD   (ResultSrcD),
        .BranchD      (BranchD),
        .JumpD        (JumpD),
        .PCD          (PCD_to_E1),
        .PCPlus4D     (PCPlus4D_to_E1),
        .LoadTypeD    (LoadTypeD),
        .StoreTypeD   (StoreTypeD),
        .funct3_D     (funct3_D),
        .RS1_D        (RS1_D),
        .RS2_D        (RS2_D),
        
        // Forwarding inputs
        .ForwardA_E1  (ForwardAE1),
        .ForwardB_E1  (ForwardBE1),
        .ALU_ResultE2 (ALU_ResultE2),   // From Execute2
        .ALU_ResultM  (ALU_ResultM),    // From Memory
        .ResultW      (ResultW),        // From Write-back
        
        // To Execute2
        .Src_A_E1     (Src_A_E1),
        .Src_B_E1     (Src_B_E1),
        .Imm_Ext_E1   (Imm_Ext_E1),
        .ALUControlE1 (ALUControlE1),
        .RD_E1        (RD_E1),
        .RegWriteE1   (RegWriteE1),
        .MemWriteE1   (MemWriteE1),
        .ResultSrcE1  (ResultSrcE1),
        .BranchE1     (BranchE1),
        .JumpE1       (JumpE1),
        .PCE1         (PCE1),
        .PCPlus4E1    (PCPlus4E1),
        .LoadTypeE1   (LoadTypeE1),
        .StoreTypeE1  (StoreTypeE1),
        .funct3_E1    (funct3_E1)
    );

    // ================================================================
    //  Stage 3 - EXECUTE2 (ALU Operation and Branch Resolution)
    // ================================================================
    execute2_stage Execute2 (
        .clk             (clk),
        .rst             (rst),
        
        // From Execute1
        .Src_A_E1        (Src_A_E1),
        .Src_B_E1        (Src_B_E1),
        .Imm_Ext_E1      (Imm_Ext_E1),
        .ALUControlE1    (ALUControlE1),
        .RD_E1           (RD_E1),
        .RegWriteE1      (RegWriteE1),
        .MemWriteE1      (MemWriteE1),
        .ResultSrcE1     (ResultSrcE1),
        .BranchE1        (BranchE1),
        .JumpE1          (JumpE1),
        .PCE1            (PCE1),
        .PCPlus4E1       (PCPlus4E1),
        .LoadTypeE1      (LoadTypeE1),
        .StoreTypeE1     (StoreTypeE1),
        .funct3_E1       (funct3_E1),
        
        // To Memory
        .RegWriteE2      (RegWriteE2),
        .MemWriteE2      (MemWriteE2),
        .ResultSrcE2     (ResultSrcE2),
        .RD_E2           (RD_E2),
        .PCPlus4E2       (PCPlus4E2),
        .WriteDataE2     (WriteDataE2),
        .ALU_ResultE2    (ALU_ResultE2),
        .LoadTypeE2      (LoadTypeE2),
        .StoreTypeE2     (StoreTypeE2),
        
        // Branch/Jump outputs
        .PCSrcE2         (PCSrcE2),
        .PCTargetE2      (PCTargetE2),
        .JALR_TargetE2   (JALR_TargetE2),
        .is_jalr_E2      (is_jalr_E2)
    );

    // ================================================================
    //  Stage 4 - MEMORY
    // ================================================================
    memory_cycle Memory (
        .clk           (clk),
        .rst           (rst),
        .RegWriteM     (RegWriteE2),     // From Execute2
        .MemWriteM     (MemWriteE2),     // From Execute2
        .ResultSrcM    (ResultSrcE2),    // From Execute2
        .RD_M          (RD_E2),          // From Execute2
        .PCPlus4M      (PCPlus4E2),      // From Execute2
        .WriteDataM    (WriteDataE2),    // From Execute2
        .ALU_ResultM   (ALU_ResultE2),   // From Execute2
        .LoadTypeM     (LoadTypeE2),     // From Execute2
        .StoreTypeM    (StoreTypeE2),    // From Execute2
        
        // To Write-back
        .RegWriteW     (RegWriteW),
        .ResultSrcW    (ResultSrcW),
        .RD_W          (RDW),
        .PCPlus4W      (PCPlus4W),
        .ALU_ResultW   (ALU_ResultW),
        .ReadDataW     (ReadDataW),
        .LoadTypeW     (LoadTypeW),
        .StoreTypeW    (StoreTypeW)
    );
    
    // Store outputs for hazard unit
    assign RegWriteM = RegWriteE2;
    assign ALU_ResultM = ALU_ResultE2;
    assign RD_M = RD_E2;

    // ================================================================
    //  DEBUG OUTPUT ASSIGNMENTS
    // ================================================================
    assign debug_alu_result = ALU_ResultW;      
    assign debug_reg_addr   = RDW;              
    assign debug_reg_write  = RegWriteW;        
    assign debug_mem_write  = MemWriteE2;       // From Execute2 now

endmodule
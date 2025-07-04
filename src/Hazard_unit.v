// ================================================================
//  hazard_unit.v   -   2-source forwarding (EX/MEM & MEM/WB)
//  FIXED: Active-HIGH reset logic
// ================================================================
module hazard_unit_6stage (
    input        rst,
    // Pipeline stages
    input        RegWriteE1, RegWriteE2, RegWriteM, RegWriteW,
    input  [4:0] RD_E1, RD_E2, RD_M, RD_W,
    input  [4:0] Rs1_D, Rs2_D,
    
    // Forwarding outputs
    output [1:0] ForwardA_E1, ForwardB_E1
);
    
    // Enhanced forwarding with more sources
    assign ForwardA_E1 = 
        (rst) ? 2'b00 :
        (RegWriteW && RD_W != 0 && RD_W == Rs1_D) ? 2'b01 :    // From WB
        (RegWriteM && RD_M != 0 && RD_M == Rs1_D) ? 2'b10 :    // From MEM
        (RegWriteE2 && RD_E2 != 0 && RD_E2 == Rs1_D) ? 2'b11 : // From E2
        2'b00;
    
    assign ForwardB_E1 = 
        (rst) ? 2'b00 :
        (RegWriteW && RD_W != 0 && RD_W == Rs2_D) ? 2'b01 :
        (RegWriteM && RD_M != 0 && RD_M == Rs2_D) ? 2'b10 :
        (RegWriteE2 && RD_E2 != 0 && RD_E2 == Rs2_D) ? 2'b11 :
        2'b00;
        
endmodule
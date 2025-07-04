module ALU_Decoder
#(
    parameter ADD  = 5'b00000,
    parameter SUB  = 5'b00001,
    parameter AND_ = 5'b00010,
    parameter OR_  = 5'b00011,
    parameter XOR_ = 5'b00100,
    parameter SLT  = 5'b00101,
    parameter SLTU = 5'b00110,
    parameter SLL  = 5'b00111,
    parameter SRL  = 5'b01000,
    parameter SRA  = 5'b01001,
    parameter MUL  = 5'b01010,
    parameter MULH = 5'b01011,
    parameter MULHSU = 5'b01100,
    parameter MULHU  = 5'b01101,
    parameter LUI  = 5'b01110,
    parameter AUIPC= 5'b01111
)
(
    input  [2:0] ALUOp,
    input  [2:0] funct3,
    input  [6:0] funct7,
    input  [6:0] op,
    output reg [4:0] ALUControl
);
    always @(*) begin
        case (ALUOp)
        //----------------------------------------------------------
        // 000 : address-calc / JALR  (always ADD)
        //----------------------------------------------------------
        3'b000 : ALUControl = ADD;
        //----------------------------------------------------------
        // 001 : branch compares
        //----------------------------------------------------------
        3'b001 : begin
            case (funct3)
                3'b000, 3'b001: ALUControl = SUB;   // BEQ, BNE
                3'b100, 3'b101: ALUControl = SLT;   // BLT, BGE
                3'b110, 3'b111: ALUControl = SLTU;  // BLTU, BGEU
                default        : ALUControl = SUB;
            endcase
        end
        //----------------------------------------------------------
        // 010 : R-type  & I-type  ALU
        //----------------------------------------------------------
        3'b010 : begin
            // CRITICAL FIX: Only check M-extension for R-type instructions (op=0x33)
            if (funct7 == 7'b0000001 && op == 7'b0110011) begin
                // M-extension multiplication (only for R-type)
                case (funct3)
                    3'b000: ALUControl = MUL;
                    3'b001: ALUControl = MULH;
                    3'b010: ALUControl = MULHSU;
                    3'b011: ALUControl = MULHU;
                    default: ALUControl = ADD;
                endcase
                // DEBUG: Show M-extension detection for R-type only
                $display("ALU_DECODER DEBUG: M-extension R-type detected!");
                $display("  ALUOp=%b, op=%b, funct7=%b, funct3=%b", ALUOp, op, funct7, funct3);
                $display("  Generated ALUControl=%b (%s)", ALUControl, 
                         (ALUControl == MUL) ? "MUL" :
                         (ALUControl == MULH) ? "MULH" :
                         (ALUControl == MULHSU) ? "MULHSU" :
                         (ALUControl == MULHU) ? "MULHU" : "UNKNOWN");
            end
            else begin
                // Standard R-type and I-type operations
                case (funct3)
                    3'b000: ALUControl =
                             (funct7[5] & op[5]) ? SUB : ADD;  // ADD / SUB (R-type only)
                    3'b001: ALUControl = SLL;
                    3'b010: ALUControl = SLT;
                    3'b011: ALUControl = SLTU;
                    3'b100: ALUControl = XOR_;
                    3'b101: ALUControl = (funct7[5] & op[5]) ? SRA : SRL;  // SRA/SRL (R-type check)
                    3'b110: ALUControl = OR_;
                    3'b111: ALUControl = AND_;
                    default: ALUControl = ADD;
                endcase
                
                // DEBUG: Show normal I-type/R-type processing
                if (op == 7'b0010011) begin  // I-type
                    $display("ALU_DECODER DEBUG: I-type instruction processed correctly");
                    $display("  ALUOp=%b, op=%b (I-type), funct3=%b", ALUOp, op, funct3);
                    $display("  Generated ALUControl=%b (ignored funct7 for I-type)", ALUControl);
                end
            end
        end
        //----------------------------------------------------------
        // 011 : M-extension (DEDICATED ALUOp for multiplication)
        //----------------------------------------------------------
        3'b011 : begin
            case (funct3)
                3'b000: ALUControl = MUL;
                3'b001: ALUControl = MULH;
                3'b010: ALUControl = MULHSU;
                3'b011: ALUControl = MULHU;
                default: ALUControl = ADD;
            endcase
            // DEBUG: Show dedicated M-extension path
            $display("ALU_DECODER DEBUG: Dedicated M-extension ALUOp=011!");
            $display("  funct3=%b, Generated ALUControl=%b", funct3, ALUControl);
        end
        //----------------------------------------------------------
        // 100 : LUI (places upper imm into dest)
        //----------------------------------------------------------
        3'b100 : ALUControl = LUI;
        //----------------------------------------------------------
        // 101 : AUIPC  (ADD PC + imm)
        //----------------------------------------------------------
        3'b101 : ALUControl = AUIPC;
        //----------------------------------------------------------
        // 110 : JAL / JALR use ADD to compute PC+4 for link reg
        //----------------------------------------------------------
        3'b110 : ALUControl = ADD;
        //----------------------------------------------------------
        // default
        //----------------------------------------------------------
        default: ALUControl = ADD;
        endcase
        
        // ENHANCED DEBUG: Show all ALU control decisions
        if (ALUOp == 3'b010) begin
            $display("ALU_DECODER: ALUOp=%b, op=%b, funct7=%b, funct3=%b -> ALUControl=%b", 
                     ALUOp, op, funct7, funct3, ALUControl);
            
            // CRITICAL: Warn if funct7=0x1 on I-type (this was the bug!)
            if (op == 7'b0010011 && funct7 == 7'b0000001) begin
                $display("ALU_DECODER WARNING: I-type instruction with funct7=0x1 detected");
                $display("  This is caused by immediate value 0x039 (57), not M-extension!");
                $display("  Correctly ignoring funct7 for I-type instruction");
            end
        end
    end
endmodule
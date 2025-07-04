module ALU(clk, rst, A, B, Result, ALUControl, OverFlow, Carry, Zero, Negative);
    input clk, rst;
    input [31:0] A, B;
    input [4:0] ALUControl;
    output Carry, OverFlow, Zero, Negative;
    output [31:0] Result;
    
    //================================================================
    // COMBINATIONAL ARITHMETIC OPERATIONS
    //================================================================
    
    wire [31:0] Sum;
    wire Cout;
    wire [4:0] shamt;
    
    assign shamt = B[4:0];
    
    // Addition/Subtraction with carry
    assign {Cout, Sum} = (ALUControl[0] == 1'b0) ? {1'b0, A} + {1'b0, B} : 
                                                   {1'b0, A} + {1'b0, (~B + 1)};
    
    //================================================================
    // COMBINATIONAL MULTIPLICATION (6-Stage Compatible)
    //================================================================
    
    // Type casting for signed/unsigned operations
    wire signed [31:0] A_signed = $signed(A);
    wire signed [31:0] B_signed = $signed(B);
    wire [31:0] A_unsigned = A;
    wire [31:0] B_unsigned = B;
    
    // Combinational 64-bit multiplication results
    wire [63:0] mult_result_signed   = A_signed * B_signed;                           // MUL, MULH
    wire [63:0] mult_result_su       = A_signed * $signed({1'b0, B_unsigned});       // MULHSU
    wire [63:0] mult_result_unsigned = A_unsigned * B_unsigned;                      // MULHU
    
    // Multiplication result selection (combinational)
    wire [63:0] mult_result_selected = 
        (ALUControl == 5'b01010) ? mult_result_signed :     // MUL
        (ALUControl == 5'b01011) ? mult_result_signed :     // MULH
        (ALUControl == 5'b01100) ? mult_result_su :         // MULHSU
        (ALUControl == 5'b01101) ? mult_result_unsigned :   // MULHU
        64'h0;
    
    // Extract appropriate 32-bit result from 64-bit multiplication
    wire [31:0] mult_final = 
        (ALUControl == 5'b01010) ? mult_result_selected[31:0] :      // MUL - lower 32 bits
        (ALUControl == 5'b01011) ? mult_result_selected[63:32] :     // MULH - upper 32 bits
        (ALUControl == 5'b01100) ? mult_result_selected[63:32] :     // MULHSU - upper 32 bits
        (ALUControl == 5'b01101) ? mult_result_selected[63:32] :     // MULHU - upper 32 bits
        32'h0;
    
    //================================================================
    // OTHER COMBINATIONAL OPERATIONS
    //================================================================
    
    wire [31:0] immediate_result = 
        (ALUControl == 5'b00000) ? Sum :                                    // ADD
        (ALUControl == 5'b00001) ? Sum :                                    // SUB
        (ALUControl == 5'b00010) ? A & B :                                  // AND
        (ALUControl == 5'b00011) ? A | B :                                  // OR
        (ALUControl == 5'b00100) ? A ^ B :                                  // XOR
        (ALUControl == 5'b00101) ? {{31{1'b0}}, ($signed(A) < $signed(B))} : // SLT
        (ALUControl == 5'b00110) ? {{31{1'b0}}, (A < B)} :                  // SLTU
        (ALUControl == 5'b00111) ? A << shamt :                             // SLL
        (ALUControl == 5'b01000) ? A >> shamt :                             // SRL
        (ALUControl == 5'b01001) ? $signed(A) >>> shamt :                   // SRA
        (ALUControl == 5'b01110) ? B :                                      // LUI
        (ALUControl == 5'b01111) ? Sum :                                    // AUIPC
        32'h00000000;
    
    //================================================================
    // FINAL RESULT SELECTION
    //================================================================
    
    wire is_multiplication = (ALUControl >= 5'b01010) && (ALUControl <= 5'b01101);
    assign Result = is_multiplication ? mult_final : immediate_result;
    
    //================================================================
    // FLAGS COMPUTATION
    //================================================================
    
    assign OverFlow = ((Sum[31] ^ A[31]) & 
                      (~(ALUControl[0] ^ B[31] ^ A[31])) &
                      (~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]));
    assign Carry = ((~ALUControl[1]) & (~ALUControl[2]) & (~ALUControl[3]) & (~ALUControl[4]) & Cout);
    assign Zero = &(~Result);
    assign Negative = Result[31];
    
    //================================================================
    // ENHANCED DEBUG OUTPUT
    //================================================================
    
    // Debug multiplication operations
    always @(*) begin
        if (!rst && is_multiplication && (A != 0 || B != 0)) begin
            case (ALUControl)
                5'b01010: $display("ALU_MUL: %0d * %0d = %0d (lower 32 bits)", 
                                  $signed(A), $signed(B), $signed(Result));
                5'b01011: $display("ALU_MULH: %0d * %0d = %0d (upper 32 bits, signed)", 
                                  $signed(A), $signed(B), $signed(Result));
                5'b01100: $display("ALU_MULHSU: %0d * %0u = %0d (upper 32 bits, mixed)", 
                                  $signed(A), B, $signed(Result));
                5'b01101: $display("ALU_MULHU: %0u * %0u = %0u (upper 32 bits, unsigned)", 
                                  A, B, Result);
            endcase
            
            // Special case for K²RED test values
            if (A == 32'd12345 && B == 32'd6789) begin
                $display("ALU_K2RED_TEST: ✅ 12345 * 6789 = %0d (Expected: 83810205 for MUL)", 
                         $signed(Result));
                if (ALUControl == 5'b01010 && Result == 32'd83810205) begin
                    $display("ALU_K2RED_TEST: ✅ PERFECT MATCH!");
                end
            end
        end
    end
    
    // Debug addition/subtraction operations
    always @(*) begin
        if (!rst && (ALUControl == 5'b00000 || ALUControl == 5'b00001) && (A != 0 || B != 0)) begin
            if (ALUControl == 5'b00000) begin
                $display("ALU_ADD: %0d + %0d = %0d", $signed(A), $signed(B), $signed(Result));
            end else begin
                $display("ALU_SUB: %0d - %0d = %0d", $signed(A), $signed(B), $signed(Result));
            end
        end
    end
    
    // Debug logical operations for mask generation
    always @(*) begin
        if (!rst && (ALUControl == 5'b00010) && (A != 0 && B != 0)) begin
            $display("ALU_AND: 0x%08h & 0x%08h = 0x%08h (mask operation)", A, B, Result);
            if (B == 32'h00001FFF) begin
                $display("ALU_AND: ✅ 13-bit mask (0x1FFF) detected");
            end
        end
    end
    
    // Debug shift operations
    always @(*) begin
        if (!rst && (ALUControl >= 5'b00111) && (ALUControl <= 5'b01001) && (A != 0)) begin
            case (ALUControl)
                5'b00111: $display("ALU_SLL: 0x%08h << %0d = 0x%08h", A, shamt, Result);
                5'b01000: $display("ALU_SRL: 0x%08h >> %0d = 0x%08h", A, shamt, Result);
                5'b01001: $display("ALU_SRA: 0x%08h >>> %0d = 0x%08h", A, shamt, Result);
            endcase
        end
    end
    
    // Error detection
    always @(*) begin
        if (!rst && is_multiplication && (A == 0 && B == 0)) begin
            $display("ALU_WARNING: Multiplication with both inputs zero - check forwarding");
        end
    end
    
    //================================================================
    // PERFORMANCE MONITORING
    //================================================================
    
    // Count multiplication operations
    integer mult_count = 0;
    always @(posedge clk) begin
        if (!rst && is_multiplication) begin
            mult_count = mult_count + 1;
            $display("ALU_PERF: Multiplication #%0d completed", mult_count);
        end
    end
    
endmodule
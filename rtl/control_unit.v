module control_unit ( 
    input  wire [6:0] opcode, 
    input  wire [2:0] funct3, 
    input  wire [6:0] funct7, 
    output reg  [3:0] alu_op, 
    output reg        alu_src,      // 0: rs2, 1: immediate 
    output reg        mem_read, 
    output reg        mem_write, 
    output reg        reg_write, 
    output reg  [1:0] wb_sel,       // 00: ALU, 01: MEM, 10: PC+4 
    output reg        branch, 
    output reg        jal, 
    output reg        jalr, 
    output reg        lui, 
    output reg        auipc 
); 
 
    // ALU operation encoding 
    localparam ALU_ADD  = 4'd0; 
    localparam ALU_SUB  = 4'd1; 
    localparam ALU_SLL  = 4'd2; 
    localparam ALU_SLT  = 4'd3; 
    localparam ALU_SLTU = 4'd4; 
    localparam ALU_XOR  = 4'd5; 
    localparam ALU_SRL  = 4'd6; 
    localparam ALU_SRA  = 4'd7; 
    localparam ALU_OR   = 4'd8; 
    localparam ALU_AND  = 4'd9; 
    localparam ALU_PASS_B = 4'd10;  // Pass operand B (for LUI) 
 
    always @(*) begin 
        // Default values (NOP-safe) 
        alu_op    = ALU_ADD; 
        alu_src   = 1'b0; 
        mem_read  = 1'b0; 
        mem_write = 1'b0; 
        reg_write = 1'b0; 
        wb_sel    = 2'b00; 
        branch    = 1'b0; 
        jal       = 1'b0; 
        jalr      = 1'b0; 
        lui       = 1'b0; 
        auipc     = 1'b0; 
 
        case (opcode) 
            // ----- R-type: register-register ALU ----- 
            7'b0110011: begin 
                reg_write = 1'b1; 
                alu_src   = 1'b0; 
                wb_sel    = 2'b00; 
                case (funct3) 
                    3'b000: alu_op = (funct7[5]) ? ALU_SUB : ALU_ADD;  // ADD/SUB 
                    3'b001: alu_op = ALU_SLL;   // SLL 
                    3'b010: alu_op = ALU_SLT;   // SLT 
                    3'b011: alu_op = ALU_SLTU;  // SLTU 
                    3'b100: alu_op = ALU_XOR;   // XOR 
                    3'b101: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;  // SRL/SRA 
                    3'b110: alu_op = ALU_OR;    // OR 
                    3'b111: alu_op = ALU_AND;   // AND 
                endcase 
            end 
 
            // ----- I-type: ALU with immediate ----- 
            7'b0010011: begin 
                reg_write = 1'b1; 
                alu_src   = 1'b1; 
                wb_sel    = 2'b00; 
                case (funct3) 
                    3'b000: alu_op = ALU_ADD;   // ADDI 
                    3'b001: alu_op = ALU_SLL;   // SLLI 
                    3'b010: alu_op = ALU_SLT;   // SLTI 
                    3'b011: alu_op = ALU_SLTU;  // SLTIU 
                    3'b100: alu_op = ALU_XOR;   // XORI 
                    3'b101: alu_op = (funct7[5]) ? ALU_SRA : ALU_SRL;  // SRLI/SRAI 
                    3'b110: alu_op = ALU_OR;    // ORI 
                    3'b111: alu_op = ALU_AND;   // ANDI 
                endcase 
            end 
 
            // ----- LOAD ----- 
            7'b0000011: begin 
                reg_write = 1'b1; 
                alu_src   = 1'b1; 
                alu_op    = ALU_ADD; 
                mem_read  = 1'b1; 
                wb_sel    = 2'b01;  // From memory 
            end 
 
            // ----- STORE ----- 
            7'b0100011: begin 
                alu_src   = 1'b1; 
                alu_op    = ALU_ADD; 
                mem_write = 1'b1; 
            end 
 
            // ----- BRANCH ----- 
            7'b1100011: begin 
                branch    = 1'b1; 
                alu_src   = 1'b0; 
                alu_op    = ALU_SUB;  // For comparison 
            end 
 
            // ----- LUI ----- 
            7'b0110111: begin 
                reg_write = 1'b1; 
                lui       = 1'b1; 
                alu_src   = 1'b1; 
                alu_op    = ALU_PASS_B; 
                wb_sel    = 2'b00; 
            end 
 
            // ----- AUIPC ----- 
            7'b0010111: begin 
                reg_write = 1'b1; 
                auipc     = 1'b1; 
                alu_src   = 1'b1; 
                alu_op    = ALU_ADD; 
                wb_sel    = 2'b00; 
            end 
 
            // ----- JAL ----- 
            7'b1101111: begin 
                reg_write = 1'b1; 
                jal       = 1'b1; 
                wb_sel    = 2'b10;  // PC+4 
            end 
 
            // ----- JALR ----- 
            7'b1100111: begin 
                reg_write = 1'b1; 
                jalr      = 1'b1; 
                alu_src   = 1'b1; 
                alu_op    = ALU_ADD; 
                wb_sel    = 2'b10;  // PC+4 
            end 
 
            // ----- FENCE (treated as NOP in simple implementation) ----- 
            7'b0001111: begin 
                // NOP 
            end 
 
            // ----- ECALL / EBREAK (minimal support) ----- 
            7'b1110011: begin 
                // NOP for now; can be expanded for OS support 
            end 
 
            default: begin 
                // NOP 
            end 
        endcase 
    end 
 
endmodule 

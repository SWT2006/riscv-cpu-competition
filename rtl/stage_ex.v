module stage_ex ( 
    input  wire [31:0] idex_pc, 
    input  wire [31:0] idex_pc_plus4, 
    input  wire [31:0] idex_rs1_data, 
    input  wire [31:0] idex_rs2_data, 
    input  wire [31:0] idex_imm, 
    input  wire [ 4:0] idex_rs1_addr, 
    input  wire [ 4:0] idex_rs2_addr, 
    input  wire [ 4:0] idex_rd_addr, 
    input  wire [ 3:0] idex_alu_op, 
    input  wire        idex_alu_src, 
    input  wire        idex_branch, 
    input  wire        idex_jal, 
    input  wire        idex_jalr, 
    input  wire        idex_lui, 
    input  wire        idex_auipc, 
    input  wire [ 2:0] idex_funct3, 
    // Forwarding inputs 
    input  wire [ 1:0] forward_a, 
    input  wire [ 1:0] forward_b, 
    input  wire [31:0] exmem_alu_result, 
    input  wire [31:0] wb_write_data, 
    input  wire [31:0] exmem_pc_plus4, 
    input  wire [ 1:0] exmem_wb_sel, 
    input  wire [ 1:0] memwb_wb_sel, 
    input  wire [31:0] memwb_pc_plus4, 
    // Outputs 
    output wire [31:0] alu_result, 
    output wire [31:0] rs2_data_fwd, 
    output wire        branch_taken, 
    output wire [31:0] branch_target 
); 
 
    // ALU operation encoding (must match control_unit) 
    localparam ALU_ADD    = 4'd0; 
    localparam ALU_SUB    = 4'd1; 
    localparam ALU_SLL    = 4'd2; 
    localparam ALU_SLT    = 4'd3; 
    localparam ALU_SLTU   = 4'd4; 
    localparam ALU_XOR    = 4'd5; 
    localparam ALU_SRL    = 4'd6; 
    localparam ALU_SRA    = 4'd7; 
    localparam ALU_OR     = 4'd8; 
    localparam ALU_AND    = 4'd9; 
    localparam ALU_PASS_B = 4'd10; 
 
    // --------------------------------------------------------------- 
    // Forwarding Muxes 
    // --------------------------------------------------------------- 
    reg [31:0] fwd_a_data;  // Forwarded rs1 
    reg [31:0] fwd_b_data;  // Forwarded rs2 
 
    // For EX/MEM forwarding, when the previous instruction is JAL/JALR 
    // (wb_sel == 2'b10), we need to forward pc_plus4 instead of alu_result 
    wire [31:0] exmem_fwd_data = (exmem_wb_sel == 2'b10) ? exmem_pc_plus4 : exmem_alu_result; 
    wire [31:0] memwb_fwd_data = wb_write_data;  // WB stage already muxes correctly 
 
    always @(*) begin 
        case (forward_a) 
            2'b00:   fwd_a_data = idex_rs1_data;       // No forwarding 
            2'b10:   fwd_a_data = exmem_fwd_data;      // Forward from EX/MEM 
            2'b01:   fwd_a_data = memwb_fwd_data;      // Forward from MEM/WB 
            default: fwd_a_data = idex_rs1_data; 
        endcase 
    end 
 
    always @(*) begin 
        case (forward_b) 
            2'b00:   fwd_b_data = idex_rs2_data; 
            2'b10:   fwd_b_data = exmem_fwd_data; 
            2'b01:   fwd_b_data = memwb_fwd_data; 
            default: fwd_b_data = idex_rs2_data; 
        endcase 
    end 
 
    // rs2 data for store instructions (after forwarding) 
    assign rs2_data_fwd = fwd_b_data; 
 
    // --------------------------------------------------------------- 
    // ALU Input Selection 
    // --------------------------------------------------------------- 
    wire [31:0] alu_operand_a; 
    wire [31:0] alu_operand_b; 
 
    // For AUIPC: operand A = PC; for LUI: operand A doesn't matter (PASS_B) 
    assign alu_operand_a = idex_auipc ? idex_pc : fwd_a_data; 
    // For I-type/Load/Store/AUIPC/LUI: operand B = immediate 
    assign alu_operand_b = idex_alu_src ? idex_imm : fwd_b_data; 
 
    // --------------------------------------------------------------- 
    // ALU 
    // --------------------------------------------------------------- 
    reg [31:0] alu_out; 
 
    always @(*) begin 
        case (idex_alu_op) 
            ALU_ADD:    alu_out = alu_operand_a + alu_operand_b; 
            ALU_SUB:    alu_out = alu_operand_a - alu_operand_b; 
            ALU_SLL:    alu_out = alu_operand_a << alu_operand_b[4:0]; 
            ALU_SLT:    alu_out = ($signed(alu_operand_a) < $signed(alu_operand_b)) ? 32'd1 : 32'd0; 
            ALU_SLTU:   alu_out = (alu_operand_a < alu_operand_b) ? 32'd1 : 32'd0; 
            ALU_XOR:    alu_out = alu_operand_a ^ alu_operand_b; 
            ALU_SRL:    alu_out = alu_operand_a >> alu_operand_b[4:0]; 
            ALU_SRA:    alu_out = $signed(alu_operand_a) >>> alu_operand_b[4:0]; 
            ALU_OR:     alu_out = alu_operand_a | alu_operand_b; 
            ALU_AND:    alu_out = alu_operand_a & alu_operand_b; 
            ALU_PASS_B: alu_out = alu_operand_b;  // LUI 
            default:    alu_out = 32'b0; 
        endcase 
    end 
 
    assign alu_result = alu_out; 
 
    // --------------------------------------------------------------- 
    // Branch Comparison Unit 
    // --------------------------------------------------------------- 
    reg  branch_cond; 
 
    always @(*) begin 
        case (idex_funct3) 
            3'b000:  branch_cond = (fwd_a_data == fwd_b_data);                          // BEQ 
            3'b001:  branch_cond = (fwd_a_data != fwd_b_data);                          // BNE 
            3'b100:  branch_cond = ($signed(fwd_a_data) < $signed(fwd_b_data));          // BLT 
            3'b101:  branch_cond = ($signed(fwd_a_data) >= $signed(fwd_b_data));         // BGE 
            3'b110:  branch_cond = (fwd_a_data < fwd_b_data);                           // BLTU 
            3'b111:  branch_cond = (fwd_a_data >= fwd_b_data);                          // BGEU 
            default: branch_cond = 1'b0; 
        endcase 
    end 
 
    // --------------------------------------------------------------- 
    // Branch / Jump Target Calculation 
    // --------------------------------------------------------------- 
    wire [31:0] pc_branch_target = idex_pc + idex_imm;                   // B-type, JAL 
    wire [31:0] jalr_target      = (fwd_a_data + idex_imm) & 32'hFFFFFFFE;  // JALR 
 
    assign branch_taken  = idex_jal | idex_jalr | (idex_branch & branch_cond); 
    assign branch_target = idex_jalr ? jalr_target : pc_branch_target; 
 
endmodule 

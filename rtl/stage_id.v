module stage_id ( 
    input  wire        clk, 
    input  wire        rst_n, 
    input  wire [31:0] instruction, 
    input  wire [31:0] pc, 
    // Write-back port 
    input  wire        wb_reg_write, 
    input  wire [ 4:0] wb_rd_addr, 
    input  wire [31:0] wb_write_data, 
    // Outputs 
    output wire [31:0] rs1_data, 
    output wire [31:0] rs2_data, 
    output wire [31:0] imm, 
    output wire [ 4:0] rs1_addr, 
    output wire [ 4:0] rs2_addr, 
    output wire [ 4:0] rd_addr, 
    output wire [ 3:0] alu_op, 
    output wire        alu_src, 
    output wire        mem_read, 
    output wire        mem_write, 
    output wire [ 2:0] mem_funct3, 
    output wire        reg_write, 
    output wire [ 1:0] wb_sel, 
    output wire        branch, 
    output wire        jal, 
    output wire        jalr, 
    output wire        lui, 
    output wire        auipc, 
    output wire [ 2:0] funct3 
); 
 
    // Instruction fields 
    wire [6:0] opcode = instruction[6:0]; 
    wire [4:0] rd     = instruction[11:7]; 
    wire [2:0] f3     = instruction[14:12]; 
    wire [4:0] rs1    = instruction[19:15]; 
    wire [4:0] rs2    = instruction[24:20]; 
    wire [6:0] funct7 = instruction[31:25]; 
 
    assign rs1_addr   = rs1; 
    assign rs2_addr   = rs2; 
    assign rd_addr    = rd; 
    assign funct3     = f3; 
    assign mem_funct3 = f3; 
 
    // --------------------------------------------------------------- 
    // Register File 
    // --------------------------------------------------------------- 
    reg [31:0] regfile [0:31]; 
    integer i; 
 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            for (i = 0; i < 32; i = i + 1) 
                regfile[i] <= 32'b0; 
        end else if (wb_reg_write && wb_rd_addr != 5'b0) begin 
            regfile[wb_rd_addr] <= wb_write_data; 
        end 
    end 
 
    // Read ports (x0 is hardwired to 0) 
    assign rs1_data = (rs1 == 5'b0) ? 32'b0 : 
                      (wb_reg_write && wb_rd_addr == rs1) ? wb_write_data :  // WB-to-ID forwarding 
                      regfile[rs1]; 
    assign rs2_data = (rs2 == 5'b0) ? 32'b0 : 
                      (wb_reg_write && wb_rd_addr == rs2) ? wb_write_data : 
                      regfile[rs2]; 
 
    // --------------------------------------------------------------- 
    // Immediate Generator 
    // --------------------------------------------------------------- 
    imm_gen u_imm_gen ( 
        .instruction (instruction), 
        .imm         (imm) 
    ); 
 
    // --------------------------------------------------------------- 
    // Control Unit 
    // --------------------------------------------------------------- 
    control_unit u_control ( 
        .opcode   (opcode), 
        .funct3   (f3), 
        .funct7   (funct7), 
        .alu_op   (alu_op), 
        .alu_src  (alu_src), 
        .mem_read (mem_read), 
        .mem_write(mem_write), 
        .reg_write(reg_write), 
        .wb_sel   (wb_sel), 
        .branch   (branch), 
        .jal      (jal), 
        .jalr     (jalr), 
        .lui      (lui), 
        .auipc    (auipc) 
    ); 
 
endmodule 

module riscv_cpu_top ( 
    input  wire        clk, 
    input  wire        rst_n,          // Active-low reset 
    // Instruction Memory Interface 
    output wire [31:0] imem_addr, 
    input  wire [31:0] imem_rdata, 
    // Data Memory Interface 
    output wire [31:0] dmem_addr, 
    output wire [31:0] dmem_wdata, 
    input  wire [31:0] dmem_rdata, 
    output wire [ 3:0] dmem_wmask,     // Byte write enable 
    output wire        dmem_wen,       // Write enable 
    output wire        dmem_ren        // Read enable 
); 
 
    // --------------------------------------------------------------- 
    // Internal wires between pipeline stages 
    // --------------------------------------------------------------- 
 
    // IF stage outputs 
    wire [31:0] if_pc; 
    wire [31:0] if_pc_plus4; 
    wire [31:0] if_instruction; 
 
    // IF/ID pipeline register outputs 
    wire [31:0] ifid_pc; 
    wire [31:0] ifid_pc_plus4; 
    wire [31:0] ifid_instruction; 
 
    // ID stage outputs 
    wire [31:0] id_rs1_data; 
    wire [31:0] id_rs2_data; 
    wire [31:0] id_imm; 
    wire [ 4:0] id_rs1_addr; 
    wire [ 4:0] id_rs2_addr; 
    wire [ 4:0] id_rd_addr; 
    wire [ 3:0] id_alu_op; 
    wire        id_alu_src;         // 0=rs2, 1=imm 
    wire        id_mem_read; 
    wire        id_mem_write; 
    wire [2:0]  id_mem_funct3; 
    wire        id_reg_write; 
    wire [1:0]  id_wb_sel;          // 00=ALU, 01=MEM, 10=PC+4 
    wire        id_branch; 
    wire        id_jal; 
    wire        id_jalr; 
    wire        id_lui; 
    wire        id_auipc; 
 
    // ID/EX pipeline register outputs 
    wire [31:0] idex_pc; 
    wire [31:0] idex_pc_plus4; 
    wire [31:0] idex_rs1_data; 
    wire [31:0] idex_rs2_data; 
    wire [31:0] idex_imm; 
    wire [ 4:0] idex_rs1_addr; 
    wire [ 4:0] idex_rs2_addr; 
    wire [ 4:0] idex_rd_addr; 
    wire [ 3:0] idex_alu_op; 
    wire        idex_alu_src; 
    wire        idex_mem_read; 
    wire        idex_mem_write; 
    wire [2:0]  idex_mem_funct3; 
    wire        idex_reg_write; 
    wire [1:0]  idex_wb_sel; 
    wire        idex_branch; 
    wire        idex_jal; 
    wire        idex_jalr; 
    wire        idex_lui; 
    wire        idex_auipc; 
    wire [2:0]  idex_funct3; 
 
    // EX stage outputs 
    wire [31:0] ex_alu_result; 
    wire [31:0] ex_rs2_data_fwd;    // Forwarded rs2 data for store 
    wire        ex_branch_taken; 
    wire [31:0] ex_branch_target; 
 
    // EX/MEM pipeline register outputs 
    wire [31:0] exmem_pc_plus4; 
    wire [31:0] exmem_alu_result; 
    wire [31:0] exmem_rs2_data; 
    wire [ 4:0] exmem_rd_addr; 
    wire        exmem_mem_read; 
    wire        exmem_mem_write; 
    wire [2:0]  exmem_mem_funct3; 
    wire        exmem_reg_write; 
    wire [1:0]  exmem_wb_sel; 
 
    // MEM stage outputs 
    wire [31:0] mem_read_data; 
 
    // MEM/WB pipeline register outputs 
    wire [31:0] memwb_pc_plus4; 
    wire [31:0] memwb_alu_result; 
    wire [31:0] memwb_mem_data; 
    wire [ 4:0] memwb_rd_addr; 
    wire        memwb_reg_write; 
    wire [1:0]  memwb_wb_sel; 
 
    // WB stage output 
    wire [31:0] wb_write_data; 
 
    // Hazard / Control signals 
    wire        stall;              // Pipeline stall (load-use hazard) 
    wire        flush;              // Pipeline flush (branch/jump taken) 
    wire [1:0]  forward_a;         // Forwarding mux select for rs1 
    wire [1:0]  forward_b;         // Forwarding mux select for rs2 
 
    // --------------------------------------------------------------- 
    // Stage 1: Instruction Fetch (IF) 
    // --------------------------------------------------------------- 
    stage_if u_stage_if ( 
        .clk            (clk), 
        .rst_n          (rst_n), 
        .stall          (stall), 
        .branch_taken   (ex_branch_taken), 
        .branch_target  (ex_branch_target), 
        .pc_out         (if_pc), 
        .pc_plus4       (if_pc_plus4), 
        .imem_addr      (imem_addr), 
        .imem_rdata     (imem_rdata), 
        .instruction    (if_instruction) 
    ); 
 
    // --------------------------------------------------------------- 
    // IF/ID Pipeline Register 
    // --------------------------------------------------------------- 
    pipe_ifid u_pipe_ifid ( 
        .clk            (clk), 
        .rst_n          (rst_n), 
        .stall          (stall), 
        .flush          (flush), 
        .if_pc          (if_pc), 
        .if_pc_plus4    (if_pc_plus4), 
        .if_instruction (if_instruction), 
        .ifid_pc        (ifid_pc), 
        .ifid_pc_plus4  (ifid_pc_plus4), 
        .ifid_instruction(ifid_instruction) 
    ); 
 
    // --------------------------------------------------------------- 
    // Stage 2: Instruction Decode (ID) 
    // --------------------------------------------------------------- 
    stage_id u_stage_id ( 
        .clk            (clk), 
        .rst_n          (rst_n), 
        .instruction    (ifid_instruction), 
        .pc             (ifid_pc), 
        // Write-back port 
        .wb_reg_write   (memwb_reg_write), 
        .wb_rd_addr     (memwb_rd_addr), 
        .wb_write_data  (wb_write_data), 
        // Outputs 
        .rs1_data       (id_rs1_data), 
        .rs2_data       (id_rs2_data), 
        .imm            (id_imm), 
        .rs1_addr       (id_rs1_addr), 
        .rs2_addr       (id_rs2_addr), 
        .rd_addr        (id_rd_addr), 
        .alu_op         (id_alu_op), 
        .alu_src        (id_alu_src), 
        .mem_read       (id_mem_read), 
        .mem_write      (id_mem_write), 
        .mem_funct3     (id_mem_funct3), 
        .reg_write      (id_reg_write), 
        .wb_sel         (id_wb_sel), 
        .branch         (id_branch), 
        .jal            (id_jal), 
        .jalr           (id_jalr), 
        .lui            (id_lui), 
        .auipc          (id_auipc), 
        .funct3         () 
    ); 
 
    // --------------------------------------------------------------- 
    // ID/EX Pipeline Register 
    // --------------------------------------------------------------- 
    pipe_idex u_pipe_idex ( 
        .clk            (clk), 
        .rst_n          (rst_n), 
        .stall          (1'b0), 
        .flush          (stall | flush),  // Flush on load-use stall or branch 
        // Inputs from ID 
        .id_pc          (ifid_pc), 
        .id_pc_plus4    (ifid_pc_plus4), 
        .id_rs1_data    (id_rs1_data), 
        .id_rs2_data    (id_rs2_data), 
        .id_imm         (id_imm), 
        .id_rs1_addr    (id_rs1_addr), 
        .id_rs2_addr    (id_rs2_addr), 
        .id_rd_addr     (id_rd_addr), 
        .id_alu_op      (id_alu_op), 
        .id_alu_src     (id_alu_src), 
        .id_mem_read    (id_mem_read), 
        .id_mem_write   (id_mem_write), 
        .id_mem_funct3  (id_mem_funct3), 
        .id_reg_write   (id_reg_write), 
        .id_wb_sel      (id_wb_sel), 
        .id_branch      (id_branch), 
        .id_jal         (id_jal), 
        .id_jalr        (id_jalr), 
        .id_lui         (id_lui), 
        .id_auipc       (id_auipc), 
        .id_funct3      (ifid_instruction[14:12]), 
        // Outputs 
        .idex_pc        (idex_pc), 
        .idex_pc_plus4  (idex_pc_plus4), 
        .idex_rs1_data  (idex_rs1_data), 
        .idex_rs2_data  (idex_rs2_data), 
        .idex_imm       (idex_imm), 
        .idex_rs1_addr  (idex_rs1_addr), 
        .idex_rs2_addr  (idex_rs2_addr), 
        .idex_rd_addr   (idex_rd_addr), 
        .idex_alu_op    (idex_alu_op), 
        .idex_alu_src   (idex_alu_src), 
        .idex_mem_read  (idex_mem_read), 
        .idex_mem_write (idex_mem_write), 
        .idex_mem_funct3(idex_mem_funct3), 
        .idex_reg_write (idex_reg_write), 
        .idex_wb_sel    (idex_wb_sel), 
        .idex_branch    (idex_branch), 
        .idex_jal       (idex_jal), 
        .idex_jalr      (idex_jalr), 
        .idex_lui       (idex_lui), 
        .idex_auipc     (idex_auipc), 
        .idex_funct3    (idex_funct3) 
    ); 
 
    // --------------------------------------------------------------- 
    // Stage 3: Execute (EX) 
    // --------------------------------------------------------------- 
    stage_ex u_stage_ex ( 
        .idex_pc        (idex_pc), 
        .idex_pc_plus4  (idex_pc_plus4), 
        .idex_rs1_data  (idex_rs1_data), 
        .idex_rs2_data  (idex_rs2_data), 
        .idex_imm       (idex_imm), 
        .idex_rs1_addr  (idex_rs1_addr), 
        .idex_rs2_addr  (idex_rs2_addr), 
        .idex_rd_addr   (idex_rd_addr), 
        .idex_alu_op    (idex_alu_op), 
        .idex_alu_src   (idex_alu_src), 
        .idex_branch    (idex_branch), 
        .idex_jal       (idex_jal), 
        .idex_jalr      (idex_jalr), 
        .idex_lui       (idex_lui), 
        .idex_auipc     (idex_auipc), 
        .idex_funct3    (idex_funct3), 
        // Forwarding inputs 
        .forward_a      (forward_a), 
        .forward_b      (forward_b), 
        .exmem_alu_result(exmem_alu_result), 
        .wb_write_data  (wb_write_data), 
        .exmem_pc_plus4 (exmem_pc_plus4), 
        .exmem_wb_sel   (exmem_wb_sel), 
        .memwb_wb_sel   (memwb_wb_sel), 
        .memwb_pc_plus4 (memwb_pc_plus4), 
        // Outputs 
        .alu_result     (ex_alu_result), 
        .rs2_data_fwd   (ex_rs2_data_fwd), 
        .branch_taken   (ex_branch_taken), 
        .branch_target  (ex_branch_target) 
    ); 
 
    assign flush = ex_branch_taken; 
 
    // --------------------------------------------------------------- 
    // EX/MEM Pipeline Register 
    // --------------------------------------------------------------- 
    pipe_exmem u_pipe_exmem ( 
        .clk            (clk), 
        .rst_n          (rst_n), 
        // Inputs 
        .ex_pc_plus4    (idex_pc_plus4), 
        .ex_alu_result  (ex_alu_result), 
        .ex_rs2_data    (ex_rs2_data_fwd), 
        .ex_rd_addr     (idex_rd_addr), 
        .ex_mem_read    (idex_mem_read), 
        .ex_mem_write   (idex_mem_write), 
        .ex_mem_funct3  (idex_mem_funct3), 
        .ex_reg_write   (idex_reg_write), 
        .ex_wb_sel      (idex_wb_sel), 
        // Outputs 
        .exmem_pc_plus4 (exmem_pc_plus4), 
        .exmem_alu_result(exmem_alu_result), 
        .exmem_rs2_data (exmem_rs2_data), 
        .exmem_rd_addr  (exmem_rd_addr), 
        .exmem_mem_read (exmem_mem_read), 
        .exmem_mem_write(exmem_mem_write), 
        .exmem_mem_funct3(exmem_mem_funct3), 
        .exmem_reg_write(exmem_reg_write), 
        .exmem_wb_sel   (exmem_wb_sel) 
    ); 
 
    // --------------------------------------------------------------- 
    // Stage 4: Memory Access (MEM) 
    // --------------------------------------------------------------- 
    stage_mem u_stage_mem ( 
        .exmem_alu_result(exmem_alu_result), 
        .exmem_rs2_data (exmem_rs2_data), 
        .exmem_mem_read (exmem_mem_read), 
        .exmem_mem_write(exmem_mem_write), 
        .exmem_mem_funct3(exmem_mem_funct3), 
        // Data memory interface 
        .dmem_addr      (dmem_addr), 
        .dmem_wdata     (dmem_wdata), 
        .dmem_rdata     (dmem_rdata), 
        .dmem_wmask     (dmem_wmask), 
        .dmem_wen       (dmem_wen), 
        .dmem_ren       (dmem_ren), 
        // Output 
        .mem_read_data  (mem_read_data) 
    ); 
 
    // --------------------------------------------------------------- 
    // MEM/WB Pipeline Register 
    // --------------------------------------------------------------- 
    pipe_memwb u_pipe_memwb ( 
        .clk            (clk), 
        .rst_n          (rst_n), 
        // Inputs 
        .mem_pc_plus4   (exmem_pc_plus4), 
        .mem_alu_result (exmem_alu_result), 
        .mem_read_data  (mem_read_data), 
        .mem_rd_addr    (exmem_rd_addr), 
        .mem_reg_write  (exmem_reg_write), 
        .mem_wb_sel     (exmem_wb_sel), 
        // Outputs 
        .memwb_pc_plus4 (memwb_pc_plus4), 
        .memwb_alu_result(memwb_alu_result), 
        .memwb_mem_data (memwb_mem_data), 
        .memwb_rd_addr  (memwb_rd_addr), 
        .memwb_reg_write(memwb_reg_write), 
        .memwb_wb_sel   (memwb_wb_sel) 
    ); 
 
    // --------------------------------------------------------------- 
    // Stage 5: Write Back (WB) 
    // --------------------------------------------------------------- 
    stage_wb u_stage_wb ( 
        .memwb_alu_result(memwb_alu_result), 
        .memwb_mem_data (memwb_mem_data), 
        .memwb_pc_plus4 (memwb_pc_plus4), 
        .memwb_wb_sel   (memwb_wb_sel), 
        .wb_write_data  (wb_write_data) 
    ); 
 
    // --------------------------------------------------------------- 
    // Hazard Detection Unit 
    // --------------------------------------------------------------- 
    hazard_unit u_hazard_unit ( 
        .idex_mem_read  (idex_mem_read), 
        .idex_rd_addr   (idex_rd_addr), 
        .ifid_rs1_addr  (ifid_instruction[19:15]), 
        .ifid_rs2_addr  (ifid_instruction[24:20]), 
        .stall          (stall) 
    ); 
 
    // --------------------------------------------------------------- 
    // Forwarding Unit 
    // --------------------------------------------------------------- 
    forwarding_unit u_forwarding_unit ( 
        .idex_rs1_addr  (idex_rs1_addr), 
        .idex_rs2_addr  (idex_rs2_addr), 
        .exmem_rd_addr  (exmem_rd_addr), 
        .exmem_reg_write(exmem_reg_write), 
        .memwb_rd_addr  (memwb_rd_addr), 
        .memwb_reg_write(memwb_reg_write), 
        .forward_a      (forward_a), 
        .forward_b      (forward_b) 
    ); 
 
endmodule 

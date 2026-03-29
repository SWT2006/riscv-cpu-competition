module pipe_exmem ( 
    input  wire        clk, 
    input  wire        rst_n, 
    // Inputs 
    input  wire [31:0] ex_pc_plus4, 
    input  wire [31:0] ex_alu_result, 
    input  wire [31:0] ex_rs2_data, 
    input  wire [ 4:0] ex_rd_addr, 
    input  wire        ex_mem_read, 
    input  wire        ex_mem_write, 
    input  wire [ 2:0] ex_mem_funct3, 
    input  wire        ex_reg_write, 
    input  wire [ 1:0] ex_wb_sel, 
    // Outputs 
    output reg  [31:0] exmem_pc_plus4, 
    output reg  [31:0] exmem_alu_result, 
    output reg  [31:0] exmem_rs2_data, 
    output reg  [ 4:0] exmem_rd_addr, 
    output reg         exmem_mem_read, 
    output reg         exmem_mem_write, 
    output reg  [ 2:0] exmem_mem_funct3, 
    output reg         exmem_reg_write, 
    output reg  [ 1:0] exmem_wb_sel 
); 
 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            exmem_pc_plus4   <= 32'b0; 
            exmem_alu_result <= 32'b0; 
            exmem_rs2_data   <= 32'b0; 
            exmem_rd_addr    <= 5'b0; 
            exmem_mem_read   <= 1'b0; 
            exmem_mem_write  <= 1'b0; 
            exmem_mem_funct3 <= 3'b0; 
            exmem_reg_write  <= 1'b0; 
            exmem_wb_sel     <= 2'b0; 
        end else begin 
            exmem_pc_plus4   <= ex_pc_plus4; 
            exmem_alu_result <= ex_alu_result; 
            exmem_rs2_data   <= ex_rs2_data; 
            exmem_rd_addr    <= ex_rd_addr; 
            exmem_mem_read   <= ex_mem_read; 
            exmem_mem_write  <= ex_mem_write; 
            exmem_mem_funct3 <= ex_mem_funct3; 
            exmem_reg_write  <= ex_reg_write; 
            exmem_wb_sel     <= ex_wb_sel; 
        end 
    end 
 
endmodule 

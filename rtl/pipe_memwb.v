module pipe_memwb ( 
    input  wire        clk, 
    input  wire        rst_n, 
    // Inputs 
    input  wire [31:0] mem_pc_plus4, 
    input  wire [31:0] mem_alu_result, 
    input  wire [31:0] mem_read_data, 
    input  wire [ 4:0] mem_rd_addr, 
    input  wire        mem_reg_write, 
    input  wire [ 1:0] mem_wb_sel, 
    // Outputs 
    output reg  [31:0] memwb_pc_plus4, 
    output reg  [31:0] memwb_alu_result, 
    output reg  [31:0] memwb_mem_data, 
    output reg  [ 4:0] memwb_rd_addr, 
    output reg         memwb_reg_write, 
    output reg  [ 1:0] memwb_wb_sel 
); 
 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            memwb_pc_plus4   <= 32'b0; 
            memwb_alu_result <= 32'b0; 
            memwb_mem_data   <= 32'b0; 
            memwb_rd_addr    <= 5'b0; 
            memwb_reg_write  <= 1'b0; 
            memwb_wb_sel     <= 2'b0; 
        end else begin 
            memwb_pc_plus4   <= mem_pc_plus4; 
            memwb_alu_result <= mem_alu_result; 
            memwb_mem_data   <= mem_read_data; 
            memwb_rd_addr    <= mem_rd_addr; 
            memwb_reg_write  <= mem_reg_write; 
            memwb_wb_sel     <= mem_wb_sel; 
        end 
    end 
 
endmodule 

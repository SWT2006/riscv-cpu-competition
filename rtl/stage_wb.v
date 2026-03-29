module stage_wb ( 
    input  wire [31:0] memwb_alu_result, 
    input  wire [31:0] memwb_mem_data, 
    input  wire [31:0] memwb_pc_plus4, 
    input  wire [ 1:0] memwb_wb_sel, 
    output reg  [31:0] wb_write_data 
); 
 
    always @(*) begin 
        case (memwb_wb_sel) 
            2'b00:   wb_write_data = memwb_alu_result;  // ALU result 
            2'b01:   wb_write_data = memwb_mem_data;    // Memory load data 
            2'b10:   wb_write_data = memwb_pc_plus4;    // PC+4 (JAL/JALR) 
            default: wb_write_data = memwb_alu_result; 
        endcase 
    end 
 
endmodule 

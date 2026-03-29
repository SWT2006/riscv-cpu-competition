module forwarding_unit ( 
    input  wire [ 4:0] idex_rs1_addr, 
    input  wire [ 4:0] idex_rs2_addr, 
    input  wire [ 4:0] exmem_rd_addr, 
    input  wire        exmem_reg_write, 
    input  wire [ 4:0] memwb_rd_addr, 
    input  wire        memwb_reg_write, 
    output reg  [ 1:0] forward_a,      // 00: no fwd, 10: EX/MEM, 01: MEM/WB 
    output reg  [ 1:0] forward_b 
); 
 
    // Forwarding for operand A (rs1) 
    always @(*) begin 
        if (exmem_reg_write && (exmem_rd_addr != 5'b0) && (exmem_rd_addr == idex_rs1_addr)) 
            forward_a = 2'b10;  // Forward from EX/MEM 
        else if (memwb_reg_write && (memwb_rd_addr != 5'b0) && (memwb_rd_addr == idex_rs1_addr)) 
            forward_a = 2'b01;  // Forward from MEM/WB 
        else 
            forward_a = 2'b00;  // No forwarding 
    end 
 
    // Forwarding for operand B (rs2) 
    always @(*) begin 
        if (exmem_reg_write && (exmem_rd_addr != 5'b0) && (exmem_rd_addr == idex_rs2_addr)) 
            forward_b = 2'b10; 
        else if (memwb_reg_write && (memwb_rd_addr != 5'b0) && (memwb_rd_addr == idex_rs2_addr)) 
            forward_b = 2'b01; 
        else 
            forward_b = 2'b00; 
    end 
 
endmodule 

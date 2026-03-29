module hazard_unit ( 
    input  wire        idex_mem_read,   // Load instruction in EX stage 
    input  wire [ 4:0] idex_rd_addr,    // Destination register of load 
    input  wire [ 4:0] ifid_rs1_addr,   // Source register 1 in ID stage 
    input  wire [ 4:0] ifid_rs2_addr,   // Source register 2 in ID stage 
    output wire        stall            // Stall signal 
); 
 
    // Load-use hazard: stall for one cycle when a load in EX is 
    // followed immediately by an instruction that reads the loaded register 
    assign stall = idex_mem_read && 
                   (idex_rd_addr != 5'b0) && 
                   ((idex_rd_addr == ifid_rs1_addr) || (idex_rd_addr == ifid_rs2_addr)); 
 
endmodule 
 

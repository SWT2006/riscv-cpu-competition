module stage_mem ( 
    input  wire [31:0] exmem_alu_result, 
    input  wire [31:0] exmem_rs2_data, 
    input  wire        exmem_mem_read, 
    input  wire        exmem_mem_write, 
    input  wire [ 2:0] exmem_mem_funct3, 
    // Data memory interface 
    output wire [31:0] dmem_addr, 
    output wire [31:0] dmem_wdata, 
    input  wire [31:0] dmem_rdata, 
    output reg  [ 3:0] dmem_wmask, 
    output wire        dmem_wen, 
    output wire        dmem_ren, 
    // Output 
    output reg  [31:0] mem_read_data 
); 
 
    wire [1:0] byte_offset = exmem_alu_result[1:0]; 
 
    assign dmem_addr = {exmem_alu_result[31:2], 2'b00};  // Word-aligned address 
    assign dmem_wen  = exmem_mem_write; 
    assign dmem_ren  = exmem_mem_read; 
 
    // --------------------------------------------------------------- 
    // Store Data Alignment and Write Mask 
    // --------------------------------------------------------------- 
    reg [31:0] store_data; 
 
    always @(*) begin 
        dmem_wmask = 4'b0000; 
        store_data = 32'b0; 
        if (exmem_mem_write) begin 
            case (exmem_mem_funct3) 
                3'b000: begin  // SB 
                    case (byte_offset) 
                        2'b00: begin dmem_wmask = 4'b0001; store_data = {24'b0, exmem_rs2_data[7:0]};       end 
                        2'b01: begin dmem_wmask = 4'b0010; store_data = {16'b0, exmem_rs2_data[7:0], 8'b0}; end 
                        2'b10: begin dmem_wmask = 4'b0100; store_data = {8'b0, exmem_rs2_data[7:0], 16'b0}; end 
                        2'b11: begin dmem_wmask = 4'b1000; store_data = {exmem_rs2_data[7:0], 24'b0};       end 
                    endcase 
                end 
                3'b001: begin  // SH 
                    case (byte_offset[1]) 
                        1'b0: begin dmem_wmask = 4'b0011; store_data = {16'b0, exmem_rs2_data[15:0]};       end 
                        1'b1: begin dmem_wmask = 4'b1100; store_data = {exmem_rs2_data[15:0], 16'b0};       end 
                    endcase 
                end 
                3'b010: begin  // SW 
                    dmem_wmask = 4'b1111; 
                    store_data = exmem_rs2_data; 
                end 
                default: begin 
                    dmem_wmask = 4'b0000; 
                    store_data = 32'b0; 
                end 
            endcase 
        end 
    end 
 
    assign dmem_wdata = store_data; 
 
    // --------------------------------------------------------------- 
    // Load Data Alignment and Sign/Zero Extension 
    // --------------------------------------------------------------- 
    always @(*) begin 
        mem_read_data = 32'b0; 
        if (exmem_mem_read) begin 
            case (exmem_mem_funct3) 
                3'b000: begin  // LB (sign-extended) 
                    case (byte_offset) 
                        2'b00: mem_read_data = {{24{dmem_rdata[ 7]}}, dmem_rdata[ 7: 0]}; 
                        2'b01: mem_read_data = {{24{dmem_rdata[15]}}, dmem_rdata[15: 8]}; 
                        2'b10: mem_read_data = {{24{dmem_rdata[23]}}, dmem_rdata[23:16]}; 
                        2'b11: mem_read_data = {{24{dmem_rdata[31]}}, dmem_rdata[31:24]}; 
                    endcase 
                end 
                3'b001: begin  // LH (sign-extended) 
                    case (byte_offset[1]) 
                        1'b0: mem_read_data = {{16{dmem_rdata[15]}}, dmem_rdata[15: 0]}; 
                        1'b1: mem_read_data = {{16{dmem_rdata[31]}}, dmem_rdata[31:16]}; 
                    endcase 
                end 
                3'b010: begin  // LW 
                    mem_read_data = dmem_rdata; 
                end 
                3'b100: begin  // LBU (zero-extended) 
                    case (byte_offset) 
                        2'b00: mem_read_data = {24'b0, dmem_rdata[ 7: 0]}; 
                        2'b01: mem_read_data = {24'b0, dmem_rdata[15: 8]}; 
                        2'b10: mem_read_data = {24'b0, dmem_rdata[23:16]}; 
                        2'b11: mem_read_data = {24'b0, dmem_rdata[31:24]}; 
                    endcase 
                end 
                3'b101: begin  // LHU (zero-extended) 
                    case (byte_offset[1]) 
                        1'b0: mem_read_data = {16'b0, dmem_rdata[15: 0]}; 
                        1'b1: mem_read_data = {16'b0, dmem_rdata[31:16]}; 
                    endcase 
                end 
                default: mem_read_data = 32'b0; 
            endcase 
        end 
    end 
 
endmodule 

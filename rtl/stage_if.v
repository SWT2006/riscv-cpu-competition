module stage_if ( 
    input  wire        clk, 
    input  wire        rst_n, 
    input  wire        stall, 
    input  wire        branch_taken, 
    input  wire [31:0] branch_target, 
    output reg  [31:0] pc_out, 
    output wire [31:0] pc_plus4, 
    output wire [31:0] imem_addr, 
    input  wire [31:0] imem_rdata, 
    output wire [31:0] instruction 
); 
 
    wire [31:0] next_pc; 
 
    assign pc_plus4 = pc_out + 32'd4; 
 
    // Next PC selection: branch target or sequential 
    assign next_pc = branch_taken ? branch_target : pc_plus4; 
 
    // PC register 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            pc_out <= 32'h0000_0000;  // Reset vector 
        end else if (!stall) begin 
            pc_out <= next_pc; 
        end 
        // If stall, hold current PC 
    end 
 
    // Instruction memory interface 
    assign imem_addr   = pc_out; 
    assign instruction = imem_rdata; 
 
endmodule 

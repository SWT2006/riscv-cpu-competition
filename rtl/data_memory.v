module data_memory #( 
    parameter MEM_SIZE = 4096  // Number of 32-bit words 
)( 
    input  wire        clk, 
    input  wire [31:0] addr, 
    input  wire [31:0] wdata, 
    output wire [31:0] rdata, 
    input  wire [ 3:0] wmask, 
    input  wire        wen, 
    input  wire        ren 
); 
 
    reg [31:0] mem [0:MEM_SIZE-1]; 
 
    wire [31:0] word_addr = {2'b0, addr[31:2]}; 
 
    // Read (combinational for single-cycle read) 
    assign rdata = ren ? mem[word_addr] : 32'b0; 
 
    // Write (byte-level granularity) 
    always @(posedge clk) begin 
        if (wen) begin 
            if (wmask[0]) mem[word_addr][ 7: 0] <= wdata[ 7: 0]; 
            if (wmask[1]) mem[word_addr][15: 8] <= wdata[15: 8]; 
            if (wmask[2]) mem[word_addr][23:16] <= wdata[23:16]; 
            if (wmask[3]) mem[word_addr][31:24] <= wdata[31:24]; 
        end 
    end 
 
    // Initialize to zero (optional, for simulation) 
    integer i; 
    initial begin 
        for (i = 0; i < MEM_SIZE; i = i + 1) 
            mem[i] = 32'b0; 
    end 
 
endmodule 
 

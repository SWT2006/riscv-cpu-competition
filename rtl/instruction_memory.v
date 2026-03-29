module instruction_memory #( 
    parameter MEM_SIZE  = 4096,    // Number of 32-bit words 
    parameter INIT_FILE = "program.hex" 
)( 
    input  wire [31:0] addr, 
    output wire [31:0] rdata 
); 
 
    reg [31:0] mem [0:MEM_SIZE-1]; 
 
    initial begin 
        $readmemh(INIT_FILE, mem); 
    end 
 
    assign rdata = mem[addr[31:2]];  // Word-addressed 
 
endmodule 

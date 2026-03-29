
//============================================================================ 
// File: riscv_soc.v 
// Description: SoC wrapper - integrates CPU, memories, and basic peripherals 
//              (UART, GPIO/LED, seven-segment display) 
//============================================================================ 
module riscv_soc ( 
    input  wire        clk, 
    input  wire        rst_n, 
    // GPIO 
    output reg  [31:0] gpio_out, 
    input  wire [31:0] gpio_in, 
    // Seven-segment display 
    output reg  [31:0] seg_display, 
    // UART (optional) 
    output wire        uart_tx, 
    input  wire        uart_rx, 
    // LEDs 
    output reg  [ 7:0] leds 
); 
 
    // CPU signals 
    wire [31:0] imem_addr; 
    wire [31:0] imem_rdata; 
    wire [31:0] dmem_addr; 
    wire [31:0] dmem_wdata; 
    wire [31:0] dmem_rdata; 
    wire [ 3:0] dmem_wmask; 
    wire        dmem_wen; 
    wire        dmem_ren; 
 
    // --------------------------------------------------------------- 
    // CPU Core 
    // --------------------------------------------------------------- 
    riscv_cpu_top u_cpu ( 
        .clk        (clk), 
        .rst_n      (rst_n), 
        .imem_addr  (imem_addr), 
        .imem_rdata (imem_rdata), 
        .dmem_addr  (dmem_addr), 
        .dmem_wdata (dmem_wdata), 
        .dmem_rdata (dmem_rdata), 
        .dmem_wmask (dmem_wmask), 
        .dmem_wen   (dmem_wen), 
        .dmem_ren   (dmem_ren) 
    ); 
 
    // --------------------------------------------------------------- 
    // Instruction Memory 
    // --------------------------------------------------------------- 
    instruction_memory #( 
        .MEM_SIZE  (8192), 
        .INIT_FILE ("program.hex") 
    ) u_imem ( 
        .addr  (imem_addr), 
        .rdata (imem_rdata) 
    ); 
 
    // --------------------------------------------------------------- 
    // Memory Map: 
    //   0x0000_0000 - 0x0000_FFFF : Data RAM (64KB) 
    //   0x1000_0000 : GPIO output 
    //   0x1000_0004 : GPIO input (read-only) 
    //   0x1000_0008 : Seven-segment display 
    //   0x1000_000C : LEDs 
    //   0x2000_0000 : UART TX data 
    //   0x2000_0004 : UART status 
    // --------------------------------------------------------------- 
 
    wire is_ram    = (dmem_addr[31:16] == 16'h0000); 
    wire is_gpio   = (dmem_addr == 32'h1000_0000) || (dmem_addr == 32'h1000_0004); 
    wire is_seg    = (dmem_addr == 32'h1000_0008); 
    wire is_led    = (dmem_addr == 32'h1000_000C); 
    wire is_uart   = (dmem_addr[31:4] == 28'h2000_000); 
 
    // Data RAM 
    wire [31:0] ram_rdata; 
    wire        ram_wen = dmem_wen & is_ram; 
    wire        ram_ren = dmem_ren & is_ram; 
 
    data_memory #( 
        .MEM_SIZE (16384)  // 64KB = 16K words 
    ) u_dmem ( 
        .clk   (clk), 
        .addr  (dmem_addr), 
        .wdata (dmem_wdata), 
        .rdata (ram_rdata), 
        .wmask (dmem_wmask), 
        .wen   (ram_wen), 
        .ren   (ram_ren) 
    ); 
 
    // Read data mux 
    reg [31:0] periph_rdata; 
 
    always @(*) begin 
        if (is_ram) 
            periph_rdata = ram_rdata; 
        else if (dmem_addr == 32'h1000_0000) 
            periph_rdata = gpio_out; 
        else if (dmem_addr == 32'h1000_0004) 
            periph_rdata = gpio_in; 
        else if (is_seg) 
            periph_rdata = seg_display; 
        else if (is_led) 
            periph_rdata = {24'b0, leds}; 
        else 
            periph_rdata = 32'b0; 
    end 
 
    assign dmem_rdata = periph_rdata; 
 
    // Peripheral writes 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            gpio_out    <= 32'b0; 
            seg_display <= 32'b0; 
            leds        <= 8'b0; 
        end else if (dmem_wen) begin 
            if (dmem_addr == 32'h1000_0000) 
                gpio_out <= dmem_wdata; 
            if (is_seg) 
                seg_display <= dmem_wdata; 
            if (is_led) 
                leds <= dmem_wdata[7:0]; 
        end 
    end 
 
    // UART (stub - can be replaced with actual UART module) 
    assign uart_tx = 1'b1;  // Idle 
 
endmodule 

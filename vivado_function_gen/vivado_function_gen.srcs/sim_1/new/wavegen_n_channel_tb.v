`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2023 20:28:22
// Design Name: 
// Module Name: cordic_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module wavegen_n_channel_tb;
    localparam CH = 4;
    localparam PW = 16;
    localparam VW = 16;
    localparam OW = 12;
    localparam ITER = 10;

    reg             clk             = 0;
    reg             rst             = 1;
    reg[PW-1:0]     step_sz[CH-1:0] = '{5000, 1000, 200, 500};
    reg[VW-1:0]     x_init[CH-1:0];
    reg[CH-1:0]     ch_en           = 0;
    
    integer i;
    initial begin
        for(i = 0; i < CH; i++)
            x_init[i]   <= dut.cordic_module.x_init_default;
    end

    wire[OW-1:0]    out[CH-1:0];

    wavegen_n_channel #(
        .CH(CH),
        .PW(PW),
        .VW(VW),
        .OW(OW),
        .ITER(ITER)
    ) dut (
        .clk(clk),
        .rst(rst),
        .step_size(step_sz),
        .channel_en(ch_en),
        .x_init(x_init),
        
        .out(out)
    );
    
    always #5 clk = ~clk;
    
    localparam NUM_CYCLES  = 150;

    initial begin
        // FPGA reset cooldown
        rst = 1;
        repeat(10) @(posedge clk);
        
        // CORDIC register flush
        rst = 0;
        repeat(20) @(posedge clk);
        ch_en[0] = 1;
        
        repeat(NUM_CYCLES) @(posedge clk);
        ch_en[1] = 1;
        
        repeat(NUM_CYCLES) @(posedge clk);
        ch_en[2] = 1;

        repeat(NUM_CYCLES) @(posedge clk);
        ch_en[3] = 1;

        repeat(NUM_CYCLES) @(posedge clk);
        ch_en = 4'b1000;
        
        repeat(2*NUM_CYCLES) @(posedge clk);
        
        $finish;
    end
endmodule

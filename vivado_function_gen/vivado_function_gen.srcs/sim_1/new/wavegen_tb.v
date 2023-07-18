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


module wavegen_tb;

    localparam PW = 16;
    localparam VW = 16;
    localparam OW = 12;
    localparam ITER = 10;
    localparam DW = 8;

    reg             clk         = 0;
    reg             rst         = 1;
    reg[PW-1:0]     step_ch1    = 10;
    reg[PW-1:0]     step_ch2    = 20;
    reg[VW-1:0]     init_ch1    = dut.cordic_module.x_init_default;
    reg[VW-1:0]     init_ch2    = dut.cordic_module.x_init_default;
    reg[OW-1:0]     offset_ch1  = (1 << (OW - 1));
    reg[OW-1:0]     offset_ch2  = (1 << (OW - 1));
    reg[DW-1:0]     prescaler_ch1 = 25;
    reg[DW-1:0]     prescaler_ch2 = 25;
    reg             ch2_en      = 0;

    wire[OW-1:0]    out_ch1;
    wire[OW-1:0]    out_ch2;

    wavegen #(
        .PW(PW),
        .VW(VW),
        .OW(OW),
        .ITER(ITER)
    ) dut (
        .clk(clk),
        .rst(rst),
        .step_ch1(step_ch1),
        .step_ch2(step_ch2),
        .ch2_en(ch2_en),
        .init_ch1(init_ch1),
        .init_ch2(init_ch2),
        .offset_ch1(offset_ch1),
        .offset_ch2(offset_ch2),
        .prescaler_ch1(prescaler_ch1),
        .prescaler_ch2(prescaler_ch2),
            
        .out_ch1(out_ch1),
        .out_ch2(out_ch2)
    );
    
    always #5 clk = ~clk;

    initial begin
        // FPGA reset cooldown
        rst = 1;
        repeat(10) @(posedge clk);
        
        // CORDIC register flush
        rst = 0;
        repeat(20) @(posedge clk);
        
        repeat(100000) @(posedge clk);
        ch2_en = 1;
        
        repeat(100000) @(posedge clk);
        step_ch2    = 50;
        init_ch2    = 1 << 14;
        
        repeat(100000) @(posedge clk);
        offset_ch2  = 1024;
        prescaler_ch1 = 5;
        
        repeat(100000) @(posedge clk);
        
        $finish;
    end
endmodule

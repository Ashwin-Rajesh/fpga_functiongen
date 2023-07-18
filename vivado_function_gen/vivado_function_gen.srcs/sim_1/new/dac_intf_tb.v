`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2023 16:26:23
// Design Name: 
// Module Name: dac_intf_tb
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


module dac_intf_tb;

    reg rst = 0, clk = 0, start = 0;
    
    reg[15:0] ina = 0, inb = 0;
    
    wire sync, dina, dinb, sclk;
    
    dac_intf dut (
        // Internal interface
        .ina(ina),
        .inb(inb),
        .start(start),
        .clk(clk),
        .rst(rst),
        
        // PMOD DA2 interface
        .sync(sync),
        .dina(dina),
        .dinb(dinb),
        .sclk(sclk)
    );  
    
    always #5 clk = ~clk;
    
    initial begin
        rst = 1;
        repeat(10) @(negedge clk);

        rst = 0;        
        ina = 16'haaaa;
        inb = 16'h5555;
        start = 1;
        
        repeat(10) @(negedge clk);
        ina = $random;
        inb = $random;
        
        repeat(30) @(negedge clk);
                
        $finish;
    end    

endmodule

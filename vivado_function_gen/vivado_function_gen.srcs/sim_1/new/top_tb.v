`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.04.2023 17:13:43
// Design Name: 
// Module Name: top_tb
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


module top_tb;
    reg         clk = 0;
    reg[15:0]   sw  = 0;
    reg         btn1 = 0, btn2 = 0, btn3 = 0, btn4 = 0, btn5 = 0;
    
    wire[15:0]   led;
    wire[3:0]    ja;
    wire[6:0]    seg;
    wire         dp;
    wire[3:0]    an;

    toplevel top(
        // Clock pin
        .clk_inp(clk),
        
        // Slide switches
        .sw(sw),
        // Buttons
        .btnC(btn1), .btnU(btn2), .btnL(btn3), .btnR(btn4), .btnD(btn5),
        
        // LED output
        .led(led),
        // PMOD connector    
        .ja(ja),
        // Seven segment display output
        .seg(seg),
        .dp(dp),
        .an(an)
    );
    
    always #5 clk = ~clk;
    
    initial begin
        repeat(20) @(posedge clk);
        
        repeat(100000) @(posedge clk);
        $finish;
    end
    
endmodule

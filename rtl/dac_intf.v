`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2023 16:05:15
// Design Name: 
// Module Name: dac_intf
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

module dac_intf (
    input[15:0] ina,
    input[15:0] inb,
    input start,
    input clk,
    input rst,
    
    // DAC2 signals
    output sync,
    output dina,
    output dinb,
    output sclk
);
    reg[3:0]    bit_count  = 15;
    reg         state      = 0;   
    
    reg[15:0]   a_data;
    reg[15:0]   b_data; 
    
    localparam state_idle = 0;
    localparam state_active = 1;
    
    assign sync = (state == state_idle);
    assign sclk = clk;
    assign dina = a_data[bit_count];
    assign dinb = b_data[bit_count];
    
    always @(posedge clk) begin
        if(rst) begin
            bit_count   <= 15;
            state       <= 0;
            
            a_data      <= 0;
            b_data      <= 0;
        end else begin
            case(state)
                state_idle: 
                    if(start) begin
                        state       <= state_active;
                        bit_count   <= 15;
                        
                        a_data      <= ina;
                        b_data      <= inb;
                    end else begin
                    end
                state_active:
                    begin
                        state       <= bit_count == 0 ? state_idle : state_active;                        
                        bit_count   <= bit_count - 1;
                    end
            endcase
        end
    end
endmodule

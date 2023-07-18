`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2023 23:35:49
// Design Name: 
// Module Name: wavegen
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

module wavegen_n_channel #(
    parameter CH    = 4,        // Number of channels
    parameter PW    = 16,       // Width of phase registers
    parameter VW    = 16,       // Width of value registers in cordic
    parameter OW    = 12,       // Width of output
    parameter ITER  = 10        // Number of CORDIC iterations (excluding pre-rotation)
) (
    input               clk,
    input               rst,
    input[PW-1:0]       step_size[CH-1:0],
    input[VW-1:0]       x_init[CH-1:0],
    input[CH-1:0]       channel_en,
        
    output reg[OW-1:0]  out[CH-1:0]
);
    localparam LOG_CH = $clog2(CH);

    // Channel select registers (for maintaining which channel is being computed in CORDIC)
    reg[LOG_CH-1:0] inp_channel_sel;
    reg[LOG_CH-1:0] channel_sel[ITER:0];
    reg[LOG_CH-1:0] out_channel_sel;
    
    // Channel phases and output registers
    reg[PW-1:0]     phase[CH-1:0];
    reg[OW-1:0]     outputs[CH-1:0];

    // CORDIC input and outputs
    wire[PW-1:0]    cordic_inp  = phase[inp_channel_sel];   
    wire[VW-1:0]    x_inp       = x_init[inp_channel_sel];     
    wire signed[VW:0] cordic_out; 
    reg[OW-1:0]     act_out;
    
    always @* begin
        if(~cordic_out[VW]) begin    // Positive input
            if(cordic_out[VW-1])
                act_out = {OW{1'b1}};                                                   // Output has saturated to high
            else                
                act_out = {1'b1, cordic_out[VW-2:VW-OW]};                               // Add 0.5 to the x output
        end else begin
            if(~cordic_out[VW-1])
                act_out = 0;                                                            // Output has saturated to low
            else
                act_out = ({1'b1, {(VW-1){1'b0}}} + cordic_out[VW-1:0]) >> (VW - OW);   // Take negative
        end
    end

    cordic #(
        .PW(PW),            // Width of phase registers
        .VW(VW),            // Width of value registers
        .ITER(ITER)         // Number of CORDIC iterations (excluding pre-rotation)
    ) cordic_module (
        .clk(clk),          // Clock signal
        .rst(rst),          // Reset signal
        .phase(cordic_inp), // Phase input (time multiplexer)
        .x_inp(x_inp),      // X input
    
        .y_out(cordic_out)  // Output sine wave
    );
    
    integer i;
    
    genvar j;

    reg[LOG_CH-1:0] next_channel;
    always @(*) begin
        next_channel = inp_channel_sel;
        
        for(i = 1; i < CH; i = i + 1)
            if(channel_en[get_nth_channel(inp_channel_sel, i)]) begin
                next_channel = get_nth_channel(inp_channel_sel, i);
                break;
            end                
    end    

    always @(posedge clk) begin
        if(rst) begin
            inp_channel_sel     <= 0;
            out_channel_sel     <= 0;

            for(i = 0; i <= ITER; i = i + 1)
                channel_sel[i]  <= 0;

            for(i = 0; i < CH; i = i + 1) begin
                out[i]          <= 0;
                phase[i]        <= 0;
            end
        end else begin
            // channel_sel is a shift register
            for(i = ITER; i > 0; i = i - 1)
                channel_sel[i]  <= channel_sel[i-1];
            channel_sel[0]      <= inp_channel_sel;
            out_channel_sel     <= channel_sel[ITER];
            
            for(i = 0; i < CH; i = i + 1)
                if(channel_en[i])
                    phase[i]    <= phase[i] + step_size[i];
            
            inp_channel_sel     <= next_channel;
            
            out[out_channel_sel] <= act_out;
        end
    end    
    
    function integer get_nth_channel(input integer curr_channel, input integer n);
        integer add_result = curr_channel + n;
        begin
            get_nth_channel = add_result >= CH ? add_result - CH : add_result;
        end
    endfunction
endmodule

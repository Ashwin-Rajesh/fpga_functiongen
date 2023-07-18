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

module wavegen #(
    parameter PW    = 16,       // Width of phase registers
    parameter VW    = 16,       // Width of value registers in cordic
    parameter DW    = 5,        // Prescaler width
    parameter OW    = 12,       // Width of output
    parameter ITER  = 10        // Number of CORDIC iterations (excluding pre-rotation)
) (
    input               clk,
    input               rst,
    input[PW-1:0]       step_ch1,
    input[PW-1:0]       step_ch2,
    input               ch1_en,
    input               ch2_en,
    input[VW-1:0]       init_ch1,
    input[VW-1:0]       init_ch2,
    input[OW-1:0]       offset_ch1,
    input[OW-1:0]       offset_ch2,
    input[DW-1:0]       prescaler_ch1,
    input[DW-1:0]       prescaler_ch2,
    input[1:0]          wavesel_ch1,
    input[1:0]          wavesel_ch2,        // 0 : Idle, 1 : Sinusoid, 2 : Sawtooth, 3 : Square
    
    output reg[OW-1:0]  out_ch1 = 0,
    output reg[OW-1:0]  out_ch2 = 0
);

    // Control pipeline
    reg inp_channel_sel             = 0;
    reg[ITER:0] channel_sel_pipe    = 0;
    reg out_channel_sel             = 0;

    // Datapath variables    
    wire signed[VW:0] cordic_out; 
    reg[OW-1:0]     act_out;    
    reg[PW-1:0]     ch1_phase       = 0;
    reg[PW-1:0]     ch2_phase       = 0;
    reg[DW-1:0]     ch1_pre_count   = 0;
    reg[DW-1:0]     ch2_pre_count   = 0;
    wire[PW-1:0]    cordic_inp      = inp_channel_sel ? ch2_phase : ch1_phase;
    wire[VW-1:0]    x_inp           = inp_channel_sel ? init_ch2 : init_ch1;
    wire            ch1_match       = (ch1_pre_count >= prescaler_ch1);
    wire            ch2_match       = (ch2_pre_count >= prescaler_ch2);
    
//    always @* begin
//        if(~cordic_out[VW]) begin    // Positive input
//            if(cordic_out[VW-1])
//                act_out = {OW{1'b1}};                                                   // Output has saturated to high
//            else                
//                act_out = {1'b1, cordic_out[VW-2:VW-OW]};                               // Add 0.5 to the x output
//        end else begin
//            if(~cordic_out[VW-1])
//                act_out = 0;                                                            // Output has saturated to low
//            else
//                act_out = ({1'b1, {(VW-1){1'b0}}} + cordic_out[VW-1:0]) >> (VW - OW);   // Take negative
//        end
//    end
    
    reg signed[OW+1:0] temp_out;
    wire[OW-1:0] offset = out_channel_sel ? offset_ch2 : offset_ch1;
    always @* begin
        temp_out = {cordic_out[VW], cordic_out[VW:VW-OW]} + {2'b0, offset};
        if(temp_out < 0)
            act_out = 0;
        else if(temp_out > {2'b0, {OW{1'b1}}})
            act_out = {2'b0, {OW{1'b1}}};
        else
            act_out = temp_out[OW-1:0];
    end
    
    cordic #(
        .PW(PW),            // Width of phase registers
        .VW(VW),            // Width of value registers
        .ITER(ITER)         // Number of CORDIC iterations (excluding pre-rotation)
    ) cordic_module (
        .clk(clk),          // Clock signal
        .rst(rst),          // Reset signal
        .phase(cordic_inp), // Phase input (time multiplexer)
        .x_inp(x_inp),      // Initial x value
    
        .y_out(cordic_out)  // Output sine wave
    );
    
    always @(posedge clk) begin
        if(rst) begin
            // Datapath
            ch1_phase           <= 0;
            ch2_phase           <= 0;
            out_ch1             <= 0;
            out_ch2             <= 0;
            ch1_pre_count       <= 0;
            ch2_pre_count       <= 0;
            
            // Control pipeline initialization
            inp_channel_sel     <= 0;
            out_channel_sel     <= 0;
            channel_sel_pipe    <= 0;
        end else begin
            // Datapath
            ch1_phase           <= ch1_match ? ch1_phase + step_ch1 : ch1_phase;
            ch2_phase           <= ch2_match ? ch2_phase + step_ch2 : ch2_phase;
            out_ch1             <= out_channel_sel ? out_ch1 : act_out;
            out_ch2             <= out_channel_sel ? act_out : out_ch2;
            ch1_pre_count       <= ch1_match ? 0 : ch1_pre_count + 1;
            ch2_pre_count       <= ch2_match ? 0 : ch2_pre_count + 1;
            
            // Control pipeline update
            inp_channel_sel     <= ch2_en && ch1_en ? ~inp_channel_sel : ch2_en;
            channel_sel_pipe    <= {channel_sel_pipe[ITER-1:0], inp_channel_sel};
            out_channel_sel     <= channel_sel_pipe[ITER];
        end
    end    
endmodule

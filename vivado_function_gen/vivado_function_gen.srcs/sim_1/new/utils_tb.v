`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2023 18:41:00
// Design Name: 
// Module Name: utils_tb
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

module utils_tb;

    real    float_inp;
    integer fixed_out;
    real    float_out;
    
    integer frac_width = 32;
    
    initial begin
        float_inp = 0;
        fixed_out = real_to_q(float_inp, frac_width);
        float_out = q_to_real(fixed_out, frac_width);
        #10;
        
        float_inp = 0.5;
        fixed_out = real_to_q(float_inp, frac_width);
        float_out = q_to_real(fixed_out, frac_width);
        #10;
        
        float_inp = 0.25;
        fixed_out = real_to_q(float_inp, frac_width);
        float_out = q_to_real(fixed_out, frac_width);
        #10;

        float_inp = 0.75;
        fixed_out = real_to_q(float_inp, frac_width);
        float_out = q_to_real(fixed_out, frac_width);
        #10;

        $finish;
    end
    
    function automatic integer real_to_q(
        input real      inp,
        input integer   frac_width
    );
    real frac_width_float;
        begin
            frac_width_float = frac_width;
            real_to_q = inp * (2 ** frac_width_float);
        end
    endfunction
    
    function automatic real q_to_real(
        input integer   inp,
        input integer   frac_width
    );
        real inp_float;
        real frac_width_float;
        begin
            inp_float = inp;
            frac_width_float = frac_width;
            q_to_real = inp_float / (2 ** frac_width_float); 
        end
    endfunction
endmodule

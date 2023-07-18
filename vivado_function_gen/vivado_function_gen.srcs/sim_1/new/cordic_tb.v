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


module cordic_tb;

    parameter PW = 16;
    parameter VW = 16;
    parameter ITER = 10;
    parameter OW = 12;

    reg         clk     = 0;
    reg         rst     = 1;
    reg[PW-1:0] phase   = 0;

    wire[VW:0] x_out;
    wire[VW:0] y_out;
    
    reg unsigned[OW-1:0] dac_out = 0;
    reg unsigned[OW-1:0] ref_out = 0;
    reg [VW-1:0]         x_inp = dut.x_init_default;

    cordic #(
        .PW(PW),
        .VW(VW),
        .ITER(ITER)
    ) dut(
        .clk(clk),
        .rst(rst),
        .phase(phase),
        .x_inp(x_inp),

        .x_out(x_out),
        .y_out(y_out)
    );
    
    real    x_val[ITER-1:0];
    real    y_val[ITER-1:0];
    real    phase_val[ITER-1:0];
    real    out_val[ITER+1:0];
    reg[OW:0] error = 0;
    reg[OW:0] max_error = 0;
    
    always @* dac_out = out_convert(x_out);    
    always @(rst, out_val[ITER+1]) ref_out = out_convert(dut.val_to_q(out_val[ITER+1]));
    
    always #5 clk = ~clk;

    integer i;
    always @* begin
        for(i = 0; i < ITER; i = i + 1) begin
            x_val[i]        <= dut.q_to_val(dut.x_reg[i]);
            y_val[i]        <= dut.q_to_val(dut.y_reg[i]);
            phase_val[i]    <= dut.q_to_phase(dut.ang_reg[i]);
        end
    end
    
    real    x_out_val;
    real    y_out_val;
    real    phase_in_val;
    
    always @* begin
        x_out_val = dut.q_to_val(x_out);
        y_out_val = dut.q_to_val(y_out);
        phase     = dut.phase_to_q(phase_in_val);
    end
    
    always @(posedge clk) begin
        if(~rst) begin
            for(i = ITER + 1; i > 0; i = i -1) begin
                out_val[i]      = out_val[i-1];
            end
            out_val[0]  = $cos(phase_in_val * dut.pi / 180);
        end
    end
    
    reg error_check = 0;
    always @* begin
        error = error_check ? abs_int(ref_out - dac_out) : 0;
    end
    always @(negedge clk) begin
        if(error_check) begin
            $display("%d", error);
            max_error   <= max_abs_int(max_error, error);
        end
    end

    initial begin
        // FPGA reset cooldown
        rst = 1;
        repeat(10) @(negedge clk);
        
        // CORDIC register flush
        rst = 0;
        repeat(20) @(negedge clk);
        error_check = 1;        
        phase_in_val = 0;
        
        repeat(10000) @(negedge clk) 
            //phase_in_val = $random;
            phase_in_val = phase_in_val + 1;
        
        $display();
        $finish;
    end

    function real max(
        input real inp1,
        input real inp2
    );
        max = inp1 > inp2 ? inp1 : inp2;
    endfunction

    function integer max_abs_int(
        input integer inp1,
        input integer inp2
    );
        max_abs_int = abs_int(inp1) > abs_int(inp2) ? inp1 : inp2;
    endfunction
    
    function integer abs_int(
        input integer inp
    );
        abs_int = inp > 0 ? inp : -inp;    
    endfunction
    
    function [OW-1:0] out_convert(
        input reg[VW:0] inp
    );
        begin
            if(~inp[VW]) begin      // Positive input
                if(inp[VW-1])
                    out_convert = {OW{1'b1}};                                               // Output has saturated to high
                else                
                    out_convert = {1'b1, inp[VW-2:VW-OW]};                                  // Add 0.5 to the x output
            end else begin
                if(~inp[VW-1])      // Negative input
                    out_convert = 0;                                                        // Output has saturated to low
                else
                    out_convert = ({1'b1, {(VW-1){1'b0}}} + inp[VW-1:0]) >> (VW - OW);      // Take negative
            end
        end
    endfunction
endmodule

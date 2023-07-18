`timescale 1ns / 1ps

module cordic #(
    parameter PW    = 16,       // Width of phase registers
    parameter VW    = 16,       // Width of value registers
    parameter ITER  = 10        // Number of CORDIC iterations (excluding pre-rotation)
) (
    input           clk,
    input           rst,
    input[PW-1:0]   phase,
    input[VW-1:0]   x_inp,

    output[VW:0]    x_out,
    output[VW:0]    y_out
);

    reg[PW-1:0]     angle_lut[ITER-1:0];

    reg signed [VW:0]       x_reg[ITER:0];
    reg signed [VW:0]       y_reg[ITER:0];
    reg[PW-1:0]             ang_reg[ITER:0];

    integer i;

    localparam real pi = 3.14159265358979323846;    
    localparam real scaling_factor = 1.1644353455052086;
    localparam reg[VW-1:0] x_init_default = val_to_q(1/scaling_factor);
            
    //wire[VW-1:0]    x_init = val_to_q(1/scaling_factor);
    reg[VW-1:0]     x_init  = 0;
    wire[VW-1:0]    y_init  = 0;
    reg[PW-1:0]     ang_init = 0;
    
    assign x_out = x_reg[ITER];
    assign y_out = y_reg[ITER];
    
    initial begin
        for(i = 0; i < ITER; i = i + 1) begin
            angle_lut[i]    = phase_to_q($atan(1.0 / (2.0 ** (i + 1))) * 180.0 / pi);
            //scaling_factor  = scaling_factor * $sqrt(1.0 + (2.0 ** (-2 * (i + 1))));
        end
    end

    initial begin        
        for(i = 0; i <= ITER; i = i + 1) begin
            x_reg[i]       <= 0;
            y_reg[i]       <= 0;
            ang_reg[i]     <= 0;
        end
        ang_init    <= 0;
    end

    always @(posedge clk) begin
        if(rst) begin
            for(i = 0; i <= ITER; i = i + 1) begin
                x_reg[i]       <= 0;
                y_reg[i]       <= 0;
                ang_reg[i]     <= 0;
            end
            ang_init    <= 0;
            x_init      <= val_to_q(1/scaling_factor);
        end else begin
            // Load initial angle
            ang_init    <= phase;
            x_init      <= x_inp;

            // Stage I : Pre-rotation
            case(ang_init[(PW-1):(PW-3)])
                3'b000: begin	// 0 .. 45, No change
                    x_reg[0]    <= x_init;
                    y_reg[0]    <= y_init;
                    ang_reg[0]  <= ang_init;
                    end
                3'b001: begin	// 45 .. 90 : -90 degree rotation
                    x_reg[0]    <= -y_init;
                    y_reg[0]    <= x_init;
                    ang_reg[0]  <= ang_init - {2'b01,{VW-2{1'b0}}};
                    //ang_reg[0]  <= ang_init - phase_to_q(90);
                    end
                3'b010: begin	// 90 .. 135 : -90 degree rotation
                    x_reg[0]    <= -y_init;
                    y_reg[0]    <= x_init;
                    ang_reg[0]  <= ang_init - {2'b01,{VW-2{1'b0}}};
                    //ang_reg[0]  <= ang_init - phase_to_q(90);
                    end
                3'b011: begin	// 135 .. 180 : -180 degree rotation
                    x_reg[0]    <= -x_init;
                    y_reg[0]    <= -y_init;
                    ang_reg[0]  <= ang_init - {2'b10,{VW-2{1'b0}}};
                    //ang_reg[0]  <= ang_init - phase_to_q(180);
                    end
                3'b100: begin	// 180 .. 225 : -180 degree rotation
                    x_reg[0]    <= -x_init;
                    y_reg[0]    <= -y_init;
                    ang_reg[0]  <= ang_init - {2'b10,{VW-2{1'b0}}};
                    //ang_reg[0]  <= ang_init + phase_to_q(180);
                    end
                3'b101: begin	// 225 .. 270 : 90 degree rotation
                    x_reg[0]    <= y_init;
                    y_reg[0]    <= -x_init;
                    ang_reg[0]  <= ang_init + {2'b01,{VW-2{1'b0}}};
                    //ang_reg[0]  <= ang_init + phase_to_q(90);
                    end
                3'b110: begin	// 270 .. 315 : 90 degree rotation
                    x_reg[0]    <= y_init;
                    y_reg[0]    <= -x_init;
                    ang_reg[0]  <= ang_init + {2'b01,{VW-2{1'b0}}};
                    //ang_reg[0]  <= ang_init + phase_to_q(90);
                    end
                3'b111: begin	// 315 .. 360, No change
                    x_reg[0]    <= x_init;
                    y_reg[0]    <= y_init;
                    ang_reg[0]  <= ang_init;
                    end
            endcase

            for(i = 0; i < ITER; i = i + 1) begin
                if(ang_reg[i][PW-1]) begin    // Rotate clockwise
                    x_reg[i+1]    <= x_reg[i]   + (y_reg[i] >>> (i + 1));
                    y_reg[i+1]    <= y_reg[i]   - (x_reg[i] >>> (i + 1));
                    ang_reg[i+1]  <= ang_reg[i] + angle_lut[i];
                end else begin                // Rotate counter-clockwise
                    x_reg[i+1]    <= x_reg[i]   - (y_reg[i] >>> (i + 1));
                    y_reg[i+1]    <= y_reg[i]   + (x_reg[i] >>> (i + 1));
                    ang_reg[i+1]  <= ang_reg[i] - angle_lut[i];
                end
            end
        end
    end

    // Floating to/from fixed point
    function automatic integer real_to_q(
        input real      inp,
        input integer   frac_width
    );
        real_to_q = inp * (2 ** frac_width);
    endfunction        
    function automatic real q_to_real(
        input integer   inp,
        input integer   frac_width
    );
        real inp_float;
        begin
            inp_float = inp;
            q_to_real = inp_float / (2 ** frac_width); 
        end
    endfunction
    
    // Angle (0 to 360) to/from fixed point
    function automatic [PW-1:0] phase_to_q(
        input real      inp
    );
        phase_to_q = real_to_q(inp / 360, PW);
    endfunction    
    function automatic real q_to_phase(
        input reg unsigned[PW-1:0] inp
    );
        real temp_phase;
        begin
            temp_phase = 360 * q_to_real(inp, PW);
            q_to_phase = temp_phase > 180 ? (temp_phase - 360) : temp_phase;
        end
    endfunction
    
    // X/Y value to/from fixed point
    function automatic [VW:0] val_to_q(
        input real      inp
    );
        val_to_q = real_to_q(inp, VW-1);
    endfunction    
    function automatic real q_to_val(
        input reg signed[VW:0] inp
    );
        integer temp;
        begin
            temp = inp;
            q_to_val = q_to_real(temp, VW-1);
        end
    endfunction
endmodule

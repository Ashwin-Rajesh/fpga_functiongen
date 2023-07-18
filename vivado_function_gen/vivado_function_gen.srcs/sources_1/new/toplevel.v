`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 27.04.2023 23:42:10
// Design Name: 
// Module Name: toplevel
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


module toplevel(
    // Clock pin
    input           clk_inp,
    
    // Slide switches
    input[15:0]     sw,
    // Buttons
    input           btnC, btnU, btnL, btnR, btnD,
    
    // LED output
    output[15:0]    led,
    // PMOD connector    
    output[3:0]     ja,
    // Seven segment display output
    output[6:0]     seg,
    output          dp,
    output[3:0]     an
    );
    
    wire clk;
    
    clk_wiz_0 clk_wizard
    (
        // Clock out ports
        .clk_out1(clk),
        // Clock in ports
        .clk_in1(clk_inp)
    );
    
    wire reset;
    wire left;
    wire right;
    wire select;
    
    localparam debounce_cycles = 100000;
    
    debouncer #(
       .debounce_cycles(debounce_cycles)
    ) debouncer_reset (
        .inp(btnU),
        .clk(clk),
        .rst(1'b0),
        .out(reset)
    );
    debouncer #(
       .debounce_cycles(debounce_cycles)
    ) debouncer_left (
        .inp(btnC),
        .clk(clk),
        .rst(1'b0),
        .out(select)
    );
    debouncer #(
       .debounce_cycles(debounce_cycles)
    ) debouncer_right (
        .inp(btnL),
        .clk(clk),
        .rst(1'b0),
        .out(left)
    );
    debouncer #(
       .debounce_cycles(debounce_cycles)
    ) debouncer_select (
        .inp(btnR),
        .clk(clk),
        .rst(1'b0),
        .out(right)
    );
    
    // Single-cycles pulses when button is pressed
    reg left_edge   = 0;
    reg right_edge  = 0;
    reg select_edge = 0;
    
    reg left_prev   = 0;
    reg right_prev  = 0;
    reg select_prev = 0;
    
    always @(posedge clk) begin
        left_prev   <= left;
        right_prev  <= right;
        select_prev <= select;
        
        left_edge   <= left     & ~left_prev;
        right_edge  <= right    & ~right_prev;
        select_edge <= select   & ~select_prev;
    end

   // Which mode is the input in?
    reg[3:0] inp_mode_sel = 0;
    always @(posedge clk) begin
        if(reset) begin
            inp_mode_sel    <= 0;
        end else begin
            if(left_edge)
                inp_mode_sel = inp_mode_sel + 1;
            else if(right_edge)
                inp_mode_sel = inp_mode_sel - 1;
            else
                inp_mode_sel = inp_mode_sel;
        end
    end
    
    // LEDs indicate the mode
    reg[15:0] led;
    always @* begin
        led = 0;
        led[inp_mode_sel] = 1'b1;
    end
    
    reg[15:0] seven_seg_inp;    
    seven_segment_intf #(.clkdiv_ratio(50000)) seven_seg_intf_inst (
        .clk(clk),
        .rst(rst),
        .inp(seven_seg_inp),
        .sel(an),
        .data({dp, seg})
    );
    
    reg[15:0] step_sz_1     = 38;
    reg[15:0] step_sz_2     = 76;
    reg[15:0] init_1        = wavegen_inst.cordic_module.x_init_default;
    reg[15:0] init_2        = wavegen_inst.cordic_module.x_init_default;
    reg[15:0] offset_1      = (1 << 11);
    reg[15:0] offset_2      = (1 << 11);
    reg[7:0]  prescaler_1   = 16;
    reg[7:0]  prescaler_2   = 16;
    reg[1:0]  wavesel_1     = 1;
    reg[1:0]  wavesel_2     = 1;
    
    always @* begin
        case(inp_mode_sel)
            0: seven_seg_inp    <= step_sz_1;
            1: seven_seg_inp    <= init_1;
            2: seven_seg_inp    <= offset_1;
            3: seven_seg_inp    <= prescaler_1;
            4: seven_seg_inp    <= wavesel_1;
            8: seven_seg_inp    <= step_sz_2;
            9: seven_seg_inp    <= init_2;
            10: seven_seg_inp   <= offset_2;   
            11: seven_seg_inp   <= prescaler_2;         
            12: seven_seg_inp   <= wavesel_2;
            default:
                seven_seg_inp   <= 0;
        endcase
    end
    
    always @(posedge clk) begin
        if(reset) begin
            step_sz_1     <= 38;
            step_sz_2     <= 76;
            init_1        <= wavegen_inst.cordic_module.x_init_default;
            init_2        <= wavegen_inst.cordic_module.x_init_default;
            offset_1      <= (1 << 11);
            offset_2      <= (1 << 11);
            prescaler_1   <= 16;
            prescaler_2   <= 16;
            wavesel_1     <= 1;
            wavesel_2     <= 1;
        end else if(select) begin
            case(inp_mode_sel)
                0: step_sz_1    <= sw;
                1: init_1       <= sw;
                2: offset_1     <= sw;
                3: prescaler_1  <= sw;
                4: wavesel_1    <= sw;
                8: step_sz_2    <= sw;
                9: init_2       <= sw;
                10: offset_2    <= sw;
                11: prescaler_2 <= sw;
                12: wavesel_2   <= sw;
            endcase
        end
    end
    
    wire[11:0] ch1_out;
    wire[11:0] ch2_out;
    
    wavegen #(
        .PW(16),        // Width of phase registers
        .VW(16),        // Width of value registers in cordic
        .OW(12),        // Width of output
        .DW(8),         // Width of prescaler
        .ITER(10)       // Number of CORDIC iterations (excluding pre-rotation)
    ) wavegen_inst (
        .clk(clk),
        .rst(reset),
        .step_ch1(step_sz_1),
        .step_ch2(step_sz_2),
        .ch1_en(wavesel_1 == 2'b1),
        .ch2_en(wavesel_2 == 2'b1),
        .init_ch1({1'b0, init_1}),
        .init_ch2({1'b0, init_2}),
        .offset_ch1(offset_1),
        .offset_ch2(offset_2),
        .prescaler_ch1(prescaler_1),
        .prescaler_ch2(prescaler_2),
            
        .out_ch1(ch1_out),
        .out_ch2(ch2_out)
    );
    
    reg clk_dac = 0;
    reg[1:0] clk_div = 0;
    
    always @(posedge clk) begin
        clk_div         <= clk_div + 1;
        clk_dac         <= (clk_div == 0) ? ~ clk_dac : clk_dac;
    end
    
    reg[20:0] count;
    always @(posedge clk) begin
        count <= reset ? 0 : count + 1;
    end
    
    reg[7:0]    ch1_pre_count   = 0;
    reg[7:0]    ch2_pre_count   = 0;

    reg unsigned[11:0]   ch1_count       = 0;
    reg unsigned[11:0]   ch2_count       = 0;
    
    wire        ch1_match       = (ch1_pre_count >= prescaler_1);
    wire        ch2_match       = (ch2_pre_count >= prescaler_2);
    
    always @(posedge clk) begin
        if(rst) begin
            ch1_pre_count   <= 0;
            ch2_pre_count   <= 0;
            
            ch1_count   <= 0;
            ch2_count   <= 0;
        end else begin
            ch1_pre_count   <= ch1_match ? 0 : ch1_pre_count + 1;
            ch2_pre_count   <= ch2_match ? 0 : ch2_pre_count + 1;
            
            if(ch1_match) begin
                if(wavesel_1 == 2'h3)
                    ch1_count   <= ch1_count + step_sz_1;
                else
                    ch1_count   <= (ch1_count >= offset_1[11:0]) ? init_1 : ch1_count + step_sz_1;
            end else
                ch1_count   <= ch1_count;
            
            if(ch2_match) begin
                if(wavesel_2 == 2'h3)
                    ch2_count   <= ch2_count + step_sz_2;
                else
                    ch2_count   <= (ch2_count >= offset_2[11:0]) ? init_2 : ch2_count + step_sz_2;
            end else
                ch2_count   <= ch2_count;
                
        end
    end
    
    reg[11:0] ch1_act_out   = 0;
    reg[11:0] ch2_act_out   = 0;
    
    always @(posedge clk) begin
        if(rst) begin
            ch1_act_out     <= 0;
            ch2_act_out     <= 0;
        end else begin
            case(wavesel_1)
                0:  ch1_act_out <= offset_1;
                1:  ch1_act_out <= ch1_out;
                2:  ch1_act_out <= ch1_count;
                3:  ch1_act_out <= (ch1_count > 12'h7FF) ? offset_1 : init_1;
                default:
                    ch1_act_out <= 0;
            endcase
            
            case(wavesel_2)
                0:  ch2_act_out <= offset_2;
                1:  ch2_act_out <= ch2_out;
                2:  ch2_act_out <= ch2_count;
                3:  ch2_act_out <= (ch2_count > 12'h7FF) ? offset_1 : init_1;
                default:
                    ch2_act_out <= 0;
            endcase
        end
    end
    
    dac_intf dac_intf_inst (
        .ina({4'b0, ch1_act_out}),
        .inb({4'b0, ch2_act_out}),
        .start(1'b1),
        .clk(clk),
        .rst(reset),
        
        // DAC2 signals
        .sync(ja[0]),
        .dina(ja[1]),
        .dinb(ja[2]),
        .sclk(ja[3])
    );
endmodule

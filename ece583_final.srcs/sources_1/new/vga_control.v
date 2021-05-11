`timescale 1ns / 1ps
module vga_control
	(
		input wire clk,
		input wire [11:0] sw,
		output wire hsync, vsync,
		output wire [11:0] rgb
	);
	
	wire reset;
	// register for Basys 2 8-bit RGB DAC 
	reg [11:0] rgb_reg;
	
	// video status output from vga_sync to tell when to route out rgb signal to DAC
	wire video_on;
	
	// get the current x/y of vga_sync
    wire [9:0] x, y;

    // instantiate vga_sync
    vga_sync vga_sync_unit (.clk(clk), .reset(reset), .hsync(hsync), .vsync(vsync),
                            .video_on(video_on), .p_tick(), .x(x), .y(y));

    // rgb buffer
    always @(posedge clk, posedge reset) begin
        if (reset)
            rgb_reg <= 0;
        else if (x == 50 || y == 320)
            rgb_reg <= 12'hFFF;
        else
            rgb_reg <= sw;
    end
    
    // output
    assign rgb = (video_on) ? rgb_reg : 12'b0;
endmodule

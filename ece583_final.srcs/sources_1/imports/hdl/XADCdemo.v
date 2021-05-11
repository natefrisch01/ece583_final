`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/12/2015 03:26:51 PM
// Design Name: 
// Module Name: // Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - Fixed timing slack (ArtVVB 06/01/17)
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
 

module XADCdemo(
    input CLK100MHZ,
    input vauxp6,
    input vauxn6,
    input vauxp7,
    input vauxn7,
    input vauxp15,
    input vauxn15,
    input vauxp14,
    input vauxn14,
    input vp_in,
    input vn_in,
    input wire [15:0] sw,
    output wire hsync, vsync,
    output wire [11:0] rgb,
    output reg [15:0] led,
    output [3:0] an,
    output dp,
    output [6:0] seg
);
    reg [19:0] refresh_counter;
    reg [1:0] refresh_sel;
    reg refresh_bit;
    wire refresh_wire;
    reg reset;
    wire [15:0] data; 
    reg [15:0] temp; 
    parameter storage_size = 640;
    parameter actual_buffer_size = 40;
    reg [5:0] buffer_size;
    reg [1:0] buffer_sel;
    reg filter_sel;
    reg [7:0] data_storage [(storage_size - 1):0];
    reg [9:0] i;
    reg [7:0] buffer [(actual_buffer_size - 1):0];
    integer sum;
    assign refresh_wire = refresh_bit;
    always @(*) begin
        refresh_sel = sw[15:14];
        buffer_sel = sw[13:12];
        filter_sel = sw[11];
        case(refresh_sel)
            0: refresh_bit = refresh_counter[16];
            1: refresh_bit = refresh_counter[17];
            2: refresh_bit = refresh_counter[18];
            3: refresh_bit = refresh_counter[19];
        endcase
        case(buffer_sel)
            0: buffer_size = 5;
            1: buffer_size = 10;
            2: buffer_size = 20;
            3: buffer_size = 40;
        endcase
    end

    always @(posedge CLK100MHZ, posedge reset) begin
        if (reset) refresh_counter <= 0;
        else refresh_counter <= refresh_counter + 1;
    end
    
    always @(posedge refresh_bit) begin
        for (i = actual_buffer_size; i > 0; i = i - 1) begin
            buffer[i] <= buffer[i-1];
        end
        buffer[0] <= data[15:8]; 
        for (i = storage_size; i > 0; i = i - 1) begin
            data_storage[i] <= data_storage[i-1];
        end
        if (!filter_sel)
            data_storage[0] <= data[15:8];
        else begin
            sum = 0;
            for (i = 0; i < buffer_size; i = i + 1) begin
                sum = sum + buffer[i];
            end
            sum = sum / buffer_size;
            data_storage[0] = sum;
        end
    end 
	// register for Basys 2 8-bit RGB DAC 
	reg [11:0] rgb_reg;
  
	
	// video status output from vga_sync to tell when to route out rgb signal to DAC
	wire video_on;
	
	// get the current x/y of vga_sync
    wire [9:0] x, y;

    // instantiate vga_sync
    vga_sync vga_sync_unit (.clk(CLK100MHZ), .reset(), .hsync(hsync), .vsync(vsync),
                            .video_on(video_on), .p_tick(), .x(x), .y(y));

    // rgb buffer
    always @(posedge CLK100MHZ) begin
        if (reset)
            rgb_reg <= 0;
        else if (x >= 50) begin
            if (y == (data_storage[x - 50] + 50))
                rgb_reg <= 12'hFFF;
            else   
                rgb_reg <= 12'b0; 
        end
        else
            rgb_reg <= 12'b0;
    end
    
    // output
    assign rgb = (video_on) ? rgb_reg : 12'b0;
    
    
    wire enable;  
    wire ready; 
    reg [6:0] Address_in;
	
	//secen segment controller signals
    reg [32:0] count;
    localparam S_IDLE = 0;
    localparam S_FRAME_WAIT = 1;
    localparam S_CONVERSION = 2;
    reg [1:0] state = S_IDLE;
    reg [15:0] sseg_data;
	
	//binary to decimal converter signals
    reg b2d_start;
    reg [15:0] b2d_din;
    wire [15:0] b2d_dout;
    wire b2d_done;
    //xadc instantiation connect the eoc_out .den_in to get continuous conversion
    xadc_wiz_0  XLXI_7 (
        .daddr_in(Address_in), //addresses can be found in the artix 7 XADC user guide DRP register space
        .dclk_in(CLK100MHZ), 
        .den_in(enable), 
        .di_in(0), 
        .dwe_in(0), 
        .busy_out(),                    
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .vauxp7(vauxp7),
        .vauxn7(vauxn7),
        .vauxp14(vauxp14),
        .vauxn14(vauxn14),
        .vauxp15(vauxp15),
        .vauxn15(vauxn15),
        .vn_in(vn_in), 
        .vp_in(vp_in), 
        .alarm_out(), 
        .do_out(data), 
        //.reset_in(),
        .eoc_out(enable),
        .channel_out(),
        .drdy_out(ready)
    );
    
    //led visual dmm              
    always @(posedge(CLK100MHZ)) begin            
        if(ready == 1'b1) begin
            case (data[15:12])
            1:  led <= 16'b11;
            2:  led <= 16'b111;
            3:  led <= 16'b1111;
            4:  led <= 16'b11111;
            5:  led <= 16'b111111;
            6:  led <= 16'b1111111; 
            7:  led <= 16'b11111111;
            8:  led <= 16'b111111111;
            9:  led <= 16'b1111111111;
            10: led <= 16'b11111111111;
            11: led <= 16'b111111111111;
            12: led <= 16'b1111111111111;
            13: led <= 16'b11111111111111;
            14: led <= 16'b111111111111111;
            15: led <= 16'b1111111111111111;                        
            default: led <= 16'b1; 
            endcase
        end
    end
    
    //binary to decimal conversion
    always @ (posedge(CLK100MHZ)) begin
        case (state)
        S_IDLE: begin
            state <= S_FRAME_WAIT;
            count <= 'b0;
        end
        S_FRAME_WAIT: begin
            if (count >= 10000000) begin
                if (data > 16'hFFD0) begin
                    sseg_data <= 16'h1000;
                    state <= S_IDLE;
                end else begin
                    b2d_start <= 1'b1;
                    b2d_din <= data;
                    state <= S_CONVERSION;
                end
            end else
                count <= count + 1'b1;
        end
        S_CONVERSION: begin
            b2d_start <= 1'b0;
            if (b2d_done == 1'b1) begin
                sseg_data <= b2d_dout;
                state <= S_IDLE;
            end
        end
        endcase
    end
    
    bin2dec m_b2d (
        .clk(CLK100MHZ),
        .start(b2d_start),
        .din(b2d_din),
        .done(b2d_done),
        .dout(b2d_dout)
    );
      
    always @(posedge(CLK100MHZ)) begin
        Address_in <= 8'h16;
    end
    
    DigitToSeg segment1(
        .in1(sseg_data[3:0]),
        .in2(sseg_data[7:4]),
        .in3(sseg_data[11:8]),
        .in4(sseg_data[15:12]),
        .in5(),
        .in6(),
        .in7(),
        .in8(),
        .mclk(CLK100MHZ),
        .an(an),
        .dp(dp),
        .seg(seg)
    );
endmodule

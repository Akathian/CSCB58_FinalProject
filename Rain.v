`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module vgatest
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(1'b1),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

   reg [5:0] current_state;
	reg player_init;
	reg [7:0] x, y;
	reg [7:0] p_x, p_y;
	reg [2:0] colour;
   reg [17:0] draw_counter;	
	wire frame;
	
   localparam  S_RESET       		= 6'd0, // 00000 in binary
               S_PLAYER_INIT   	= 6'd1, // 00001 in binary
               S_PLAYER_ERASE 	= 6'd2,
					S_IDLE 				= 6'd3,
					S_PLAYER_UPDATE 	= 6'd4,
					S_PLAYER_DRAW 		= 6'd5;
		
   clock(.clock(CLOCK_50), .clk(frame));
   // Next state logic aka our state table
   always@(posedge CLOCK_50)
		begin
			player_init = 1'b0;
			colour = 3'b000;
			x = 8'b00000000;
			y = 8'b00000000;
			if (~KEY[0]) current_state = S_RESET;
			case(current_state)
				S_RESET: begin
					if (draw_counter < 17'b10000000000000000) begin
						x = draw_counter[7:0];
						y = draw_counter[16:8];
						draw_counter = draw_counter + 1'b1;
					end
					else begin
						draw_counter= 8'b00000000;
						current_state = S_PLAYER_INIT;
					end
				end
				S_PLAYER_INIT: begin
					if (draw_counter < 6'b10000) begin
						p_x = 8'd76;
						p_y = 8'd110;
						x = p_x + draw_counter[3:0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b111;
					end
					else begin
						draw_counter= 8'b00000000;
						current_state = S_IDLE;
					end
				end
				S_IDLE: begin
					if (frame)
						current_state = S_PLAYER_ERASE;
					end
				S_PLAYER_ERASE: begin
					if (draw_counter < 6'b100000) begin
						x = p_x + draw_counter[3:0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
					end
					else begin
						draw_counter= 8'b00000000;
						current_state = S_PLAYER_UPDATE;
					end
				end
				S_PLAYER_UPDATE: begin
					if (~KEY[1] && p_x < 8'd144) p_x = p_x + 1'b1;
					if (~KEY[2] && p_x > 8'd0) p_x = p_x - 1'b1;
					current_state = S_PLAYER_DRAW;
				end
				S_PLAYER_DRAW: begin
					if (draw_counter < 6'b100000) begin
						x = p_x + draw_counter[3:0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
						colour = 3'b111;
					end
					else begin
						draw_counter= 8'b00000000;
						current_state = S_IDLE;
					end
				end
			endcase // state_table 
		end
endmodule

module clock(input clock, output clk);
reg [19:0] frame_counter;
reg frame;
	always@(posedge clock)
    begin
        if (frame_counter == 20'b00000000000000000000) begin
		  frame_counter = 20'b11001011011100110100;
		  frame = 1'b1;
		  end
        else begin
			frame_counter = frame_counter - 1'b1;
			frame = 1'b0;
		  end
    end
	 assign clk = frame;
endmodule

`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module Rain
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		  HEX0,
		  HEX1,
		  HEX2,
		  HEX3,
		  HEX4,
		  HEX5,
		  HEX6,
		  HEX7,
		  LEDR[17:0],
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

	wire [7:0] x, y;
	wire [2:0] colour;
	wire [31:0] score;
	output [17:0] LEDR;
	assign LEDR[17:0] = score[17:0];
	control c0(.clk(CLOCK_50),
					.restart(KEY[0]),
					.move_left(KEY[2]),
					.move_right(KEY[1]),
					.x(x),
					.y(y),
					.colour(colour),
					.score(score));
	output [3:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7; 
	hex_display h0(score[3:0], HEX0);
	hex_display h1(score[7:4], HEX1);
	hex_display h2(score[11:8], HEX2);
	hex_display h3(score[15:12], HEX3);
	hex_display h4(score[19:16], HEX4);
	hex_display h5(score[23:20], HEX5);
	hex_display h6(score[27:24], HEX6);
	hex_display h7(score[31:28], HEX7);
endmodule

module control(
	input clk,
	input restart,
	input move_left,
	input move_right,
	output reg [7:0] x,
	output reg [7:0] y,
	output reg [2:0] colour,
	output reg [31:0] score
	);
   reg [5:0] current_state;
	reg player_init;
	reg [7:0] p_x, p_y;
   reg [17:0] draw_counter;
	reg [31:0] score_counter;
	wire frame;
	
   localparam  S_RESET       		= 6'd0, // 00000 in binary
               S_PLAYER_INIT   	= 6'd1, // 00001 in binary
               S_PLAYER_ERASE 	= 6'd2,
					S_IDLE 				= 6'd3,
					S_PLAYER_UPDATE 	= 6'd4,
					S_PLAYER_DRAW 		= 6'd5;
		
   clock(.clock(clk), .clk(frame));
			
   // Next state logic aka our state table
   always@(posedge clk)
		begin
			player_init = 1'b0;
			colour = 3'b000;
			x = 8'b00000000;
			y = 8'b00000000;
			if (~restart) current_state = S_RESET;
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
						x = p_x + draw_counter[0];
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
						x = p_x + draw_counter[0];
						y = p_y + draw_counter[4];
						draw_counter = draw_counter + 1'b1;
					end
					else begin
						draw_counter= 8'b00000000;
						current_state = S_PLAYER_UPDATE;
					end
				end
				S_PLAYER_UPDATE: begin
					if (move_right && move_left && p_x < 8'd158) begin
						p_x = p_x + 1'b1;
						score_counter = score_counter + 1'b1;
						if score_counter[5] == 1'b1 begin
							score = score + 1'b1;
						end
					end
					if (~move_left && p_x > 8'd0) begin
						p_x = p_x - 1'b1;
						score_counter = score_counter + 1'b1;
						if (score_counter[5] == 1'b1); begin
							score = score + 1'b1;
						end
					end
					current_state = S_PLAYER_DRAW;
				end
				S_PLAYER_DRAW: begin
					if (draw_counter < 6'b100000) begin
						x = p_x + draw_counter[0];
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

module hex_display(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule
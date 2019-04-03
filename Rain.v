`include "vga_adapter/vga_adapter.v"
`include "vga_adapter/vga_address_translator.v"
`include "vga_adapter/vga_controller.v"
`include "vga_adapter/vga_pll.v"

module Rain
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
		  SW,
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
	wire [9:0] p1_score, p2_score;
	input [17:0] SW;
	output [17:0] LEDR;
	wire [7:0] random;

	control c0(.clk(CLOCK_50),
					.restart(KEY[0]),
					.move_p1(SW[0]),
					.move_p2(SW[17]),
					.random(random),
					.x(x),
					.y(y),
					.colour(colour),
					.p1_score(p1_score),
					.p2_score(p2_score)
					);
	random_num rand_gen(.clk(CLOCK_50), .data_out(random));				
	
	
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
	wire [3:0] p1_thousands, p1_hundreds, p1_tens, p1_ones;
	wire [3:0] p2_thousands, p2_hundreds, p2_tens, p2_ones;

	assign LEDR[7:0] = random;
	
	BCD p1_bcd(
				  .binary(p1_score[9:0]),
				  .Thousands(p1_thousands),
				  .Hundreds(p1_hundreds),
				  .Tens(p1_tens),
				  .Ones(p1_ones)
					);
		BCD p2_bcd(
				  .binary(p2_score[9:0]),
				  .Thousands(p2_thousands),
				  .Hundreds(p2_hundreds),
				  .Tens(p2_tens),
				  .Ones(p2_ones)
					);
	
	hex_display p1_hex_ones(p1_ones, HEX0);
	hex_display p1_hex_tens(p1_tens, HEX1);
	hex_display p1_hex_hundreds(p1_hundreds, HEX2);
	hex_display p1_hex_thousands(p1_thousands, HEX3);
	
	hex_display p2_hex_ones(p2_ones, HEX4);
	hex_display p2_hex_tens(p2_tens, HEX5);
	hex_display p2_hex_hundreds(p2_hundreds, HEX6);
	hex_display p2_hex_thousands(p2_thousands, HEX7);
endmodule

// moveable character sourced from
// https://github.com/julesyan/CSCB58-Final-Project
// We changed the size ofthe player and the way you can move the player. Only stops moving when at ends of the
// screen, otherwise it is constantly moving
// We added a scoring system and a second player
module control(
	input clk,
	input restart,
	input move_p1,
	input move_p2,
	input [7:0] random,
	output reg [7:0] x,
	output reg [7:0] y,
	output reg [2:0] colour,
	output reg [9:0] p1_score,
	output reg [9:0] p2_score
	);
   reg [5:0] current_state;
	reg p1_init, p2_init;
	reg r1_init;
	reg [7:0] pos_x_p1, pos_y_p1;
	reg [7:0] pos_x_p2, pos_y_p2;
	reg [7:0] pos_x_r1, pos_y_r1;
	reg [7:0] pos_x_r2, pos_y_r2;
	reg [7:0] pos_x_r3, pos_y_r3;
	reg [7:0] pos_x_r4, pos_y_r4;
	reg [7:0] pos_x_r5, pos_y_r5;
   reg [17:0] draw_counter_p1, draw_counter_p2;
	reg [17:0] draw_counter_r1, 
				  draw_counter_r2,
				  draw_counter_r3,
				  draw_counter_r4,
				  draw_counter_r5;
	reg [17:0] draw_counter_dead;

	
	wire frame;
	
   localparam  S_RESET_P1       		= 6'd0,
					S_RESET_P2				= 6'd1,
					
               S_PLAYER1_INIT   		= 6'd2,
               S_PLAYER1_ERASE 		= 6'd3,
					S_IDLE					= 6'd4,
					S_PLAYER1_UPDATE 		= 6'd5,
					S_PLAYER1_DRAW 		= 6'd6,
					
					S_PLAYER2_INIT			= 6'd7,
					S_PLAYER2_ERASE		= 6'd8,
					S_PLAYER2_UPDATE 		= 6'd9,
					S_PLAYER2_DRAW			= 6'd10,
					
					S_RAIN_1_INIT			= 6'd12,
					S_RAIN_1_ERASE			= 6'd13,
					S_RAIN_1_UPDATE		= 6'd14,
					S_RAIN_1_DRAW			= 6'd15,
					
					S_RAIN_2_INIT			= 6'd16,
					S_RAIN_2_ERASE			= 6'd17,
					S_RAIN_2_UPDATE		= 6'd18,
					S_RAIN_2_DRAW			= 6'd19,
					
					S_RAIN_3_INIT			= 6'd20,
					S_RAIN_3_ERASE			= 6'd21,
					S_RAIN_3_UPDATE		= 6'd22,
					S_RAIN_3_DRAW			= 6'd23,
					
					S_RAIN_4_INIT			= 6'd24,
					S_RAIN_4_ERASE			= 6'd25,
					S_RAIN_4_UPDATE		= 6'd26,
					S_RAIN_4_DRAW			= 6'd27,
					
					S_RAIN_5_INIT			= 6'd28,
					S_RAIN_5_ERASE			= 6'd29,
					S_RAIN_5_UPDATE		= 6'd30,
					S_RAIN_5_DRAW			= 6'd31,
					
					S_PLAYER1_WIN			= 6'd32,
					S_PLAYER2_WIN			= 6'd33;
		
   clock(.clock(clk), .clk(frame));

   // Next state logic aka our state table
   always@(posedge clk)
		begin
			p1_init = 1'b0;
			p2_init = 1'b0;
			r1_init = 1'b0;
			colour = 3'b000;
			x = 8'b00000000;
			y = 8'b00000000;
			if (~restart) current_state = S_RESET_P1;
			case(current_state)
				// if reset button is pressed
				S_RESET_P1: begin
					if (draw_counter_p1 < 17'b10000000000000000) begin
						draw_counter_dead = 17'd0;
						x = draw_counter_p1[7:0];
						y = draw_counter_p1[16:8];
						p1_score = 10'b0;
						draw_counter_p1 = draw_counter_p1 + 1'b1;
					end
					else begin
						draw_counter_p1= 8'b00000000;
						current_state = S_RESET_P2;
					end
				end
				
				S_RESET_P2: begin
					if (draw_counter_p2 < 17'b10000000000000000) begin
						x = draw_counter_p2[7:0];
						y = draw_counter_p2[16:8];
						p2_score = 10'b0;
						draw_counter_p2 = draw_counter_p2 + 1'b1;
					end
					else begin
						draw_counter_p2= 8'b00000000;
						current_state = S_PLAYER1_INIT;
					end
				end
				
				//init player 1
				S_PLAYER1_INIT: begin
					if (draw_counter_p1 < 6'b10000) begin
						pos_x_p1 = 8'd157;
						pos_y_p1 = 8'd110;
						x = pos_x_p1 + draw_counter_p1[0];
						y = pos_y_p1 + draw_counter_p1[4];
						draw_counter_p1 = draw_counter_p1 + 1'b1;
						colour = 3'b010;
					end
					else begin
						draw_counter_p1= 8'b00000000;
						current_state = S_PLAYER2_INIT;
					end
				end
				
				
				//init player 2
				S_PLAYER2_INIT: begin
					if (draw_counter_p2 < 6'b10000) begin
						pos_x_p2 = 8'd1;
						pos_y_p2 = 8'd110;
						x = pos_x_p2 + draw_counter_p2[0];
						y = pos_y_p2 + draw_counter_p2 [4];
						draw_counter_p2 = draw_counter_p2 + 1'b1;
						colour = 3'b100;
					end
					else begin
						draw_counter_p2= 8'b00000000;
						current_state = S_RAIN_1_INIT;
					end
				end
				
				S_RAIN_1_INIT: begin
					if (draw_counter_r1 < 6'b10000) begin
							pos_x_r1 <= random;
							pos_y_r1 = 8'd0;
							x = pos_x_r1 + draw_counter_r1[0];
							y = pos_y_r1 + draw_counter_r1 [4];
							draw_counter_r1 = draw_counter_r1 + 1'b1;
							colour = 3'b001;
						end
						else begin
							draw_counter_r1= 8'b00000000;
							current_state = S_RAIN_2_INIT;
						end
					end
					
				S_RAIN_2_INIT: begin
					if (draw_counter_r2 < 6'b10000) begin
							pos_x_r2 <= random;
							pos_y_r2 = 8'd0;
							x = pos_x_r2 + draw_counter_r2[0];
							y = pos_y_r2 + draw_counter_r2 [4];
							draw_counter_r2 = draw_counter_r2 + 1'b1;
							colour = 3'b001;
						end
						else begin
							draw_counter_r2= 8'b00000000;
							current_state = S_IDLE;
						end
					end
				
				S_RAIN_3_INIT: begin
					if (draw_counter_r3 < 6'b10000) begin
							pos_x_r3 <= random;
							pos_y_r3 = 8'd0;
							x = pos_x_r3 + draw_counter_r3[0];
							y = pos_y_r3 + draw_counter_r3 [4];
							draw_counter_r3 = draw_counter_r3 + 1'b1;
							colour = 3'b001;
						end
						else begin
							draw_counter_r3= 8'b00000000;
							current_state = S_IDLE;
						end
					end
				
				S_RAIN_4_INIT: begin
					if (draw_counter_r4 < 6'b10000) begin
							pos_x_r4 <= random;
							pos_y_r4 = 8'd0;
							x = pos_x_r4 + draw_counter_r4[0];
							y = pos_y_r4 + draw_counter_r4 [4];
							draw_counter_r4 = draw_counter_r4 + 1'b1;
							colour = 3'b001;
						end
						else begin
							draw_counter_r4= 8'b00000000;
							current_state = S_RAIN_5_INIT;
						end
					end
					
				S_RAIN_5_INIT: begin
					if (draw_counter_r5 < 6'b10000) begin
							pos_x_r5 <= random;
							pos_y_r5 = 8'd0;
							x = pos_x_r5 + draw_counter_r5[0];
							y = pos_y_r5 + draw_counter_r5 [4];
							draw_counter_r5 = draw_counter_r5 + 1'b1;
							colour = 3'b001;
						end
						else begin
							draw_counter_r5= 8'b00000000;
							current_state = S_IDLE;
						end
					end
					
				//idle state
				S_IDLE: begin
					if (frame)
						current_state = S_PLAYER1_ERASE;
					end
				
				//erase player 1
				S_PLAYER1_ERASE: begin
					if (draw_counter_p1 < 6'b100000) begin
						x = pos_x_p1 + draw_counter_p1[0];
						y = pos_y_p1 + draw_counter_p1[4];
						draw_counter_p1 = draw_counter_p1 + 1'b1;
					end
					else begin
						draw_counter_p1= 8'b00000000;
						current_state = S_PLAYER1_UPDATE;
					end
				end
				
				//update player 1
				S_PLAYER1_UPDATE: begin
					if (move_p1 && pos_x_p1 < 8'd158) begin
						pos_x_p1 = pos_x_p1 + 1'b1;
						p1_score = p1_score + 1'b1;
						if (p1_score >= 10'b1111111111) begin
							current_state = S_PLAYER1_WIN;
						end
						else begin
							current_state = S_PLAYER1_DRAW;
						end
					end
					if (~move_p1 && pos_x_p1 > 8'd0) begin
						pos_x_p1 = pos_x_p1 - 1'b1;
						p1_score = p1_score + 1'b1;
						if (p1_score >= 10'b1111111111) begin
							current_state = S_PLAYER1_WIN;
						end
						else begin
							current_state = S_PLAYER1_DRAW;
						end
					end
					if (pos_x_p1 <= 8'd0 | pos_x_p1 >= 8'd158) begin
						current_state = S_PLAYER1_DRAW;
					end
				end
				
				//draw player 1
				S_PLAYER1_DRAW: begin
					if (draw_counter_p1 < 6'b100000) begin
						x = pos_x_p1 + draw_counter_p1[0];
						y = pos_y_p1 + draw_counter_p1[4];
						draw_counter_p1 = draw_counter_p1 + 1'b1;
						colour = 3'b010;
					end
					else begin
						draw_counter_p1= 8'b00000000;
						current_state = S_PLAYER2_ERASE;
					end
				end
				
				//erase player 2
				S_PLAYER2_ERASE: begin
					if (draw_counter_p2 < 6'b100000) begin
						x = pos_x_p2 + draw_counter_p2[0];
						y = pos_y_p2 + draw_counter_p2[4];
						draw_counter_p2 = draw_counter_p2 + 1'b1;
					end
					else begin
						draw_counter_p2= 8'b00000000;
						current_state = S_PLAYER2_UPDATE;
					end
				end

				//update player 2
				S_PLAYER2_UPDATE: begin
					if (move_p2 && pos_x_p2 < 8'd158) begin
						pos_x_p2 = pos_x_p2 + 1'b1;
						p2_score = p2_score + 1'b1;
						if (p2_score >= 10'b1111111111) begin
							current_state = S_PLAYER2_WIN;
						end
						else begin
							current_state = S_PLAYER2_DRAW;
						end
					end
					if (~move_p2 && pos_x_p2 > 8'd0) begin
						pos_x_p2 = pos_x_p2 - 1'b1;
						p2_score = p2_score + 1'b1;
						if (p2_score >= 10'b1111111111) begin
							current_state = S_PLAYER2_WIN;
						end
						else begin
							current_state = S_PLAYER2_DRAW;
						end
					end
					if (pos_x_p2 <= 8'd0 | pos_x_p2 >= 8'd158) begin
						current_state = S_PLAYER2_DRAW;
					end
				end
				
				//draw player 2
				S_PLAYER2_DRAW: begin
					if (draw_counter_p2 < 6'b100000) begin
						x = pos_x_p2 + draw_counter_p2[0];
						y = pos_y_p2 + draw_counter_p2[4];
						draw_counter_p2 = draw_counter_p2 + 1'b1;
						colour = 3'b100;
					end
					else begin
						draw_counter_p2= 8'b00000000;
						current_state = S_RAIN_1_ERASE;
					end
				end
				
				S_RAIN_1_ERASE: begin
					if (draw_counter_r1 < 6'b100000) begin
						x = pos_x_r1 + draw_counter_r1[0];
						y = pos_y_r1 + draw_counter_r1[6:4];
						draw_counter_r1 = draw_counter_r1 + 1'b1;
					end
					else begin
						draw_counter_r1= 8'b00000000;
						current_state = S_RAIN_1_UPDATE;
					end
				end

				//update player 2
				S_RAIN_1_UPDATE: begin
					if (pos_y_r1 >= 8'd119) begin
						if (draw_counter_r1 < 17'b10000000000000000) begin
							x = draw_counter_r1[7:0];
							y = draw_counter_r1[16:8];
							draw_counter_r1 = draw_counter_r1 + 1'b1;
						end
						else begin
							draw_counter_r1= 8'b00000000;
							current_state = S_RAIN_1_INIT;
						end
					end
					else begin
						pos_y_r1 = pos_y_r1 + 1'b1;
						current_state = S_RAIN_1_DRAW;
					end
				end
								
				//draw player 2
				S_RAIN_1_DRAW: begin
					if (draw_counter_r1 < 6'b100000) begin
						x = pos_x_r1 + draw_counter_r1[0];
						y = pos_y_r1 + draw_counter_r1[6:4];
						draw_counter_r1 = draw_counter_r1 + 1'b1;
						colour = 3'b001;
					end
					else begin
						draw_counter_r1= 8'b00000000;
						current_state = S_RAIN_2_ERASE;
					end
				end
				
				S_RAIN_2_ERASE: begin
					if (draw_counter_r2 < 6'b100000) begin
						x = pos_x_r2 + draw_counter_r2[0];
						y = pos_y_r2 + draw_counter_r2[6:4];
						draw_counter_r2 = draw_counter_r2 + 1'b1;
					end
					else begin
						draw_counter_r2= 8'b00000000;
						current_state = S_RAIN_2_UPDATE;
					end
				end

				//update player 2
				S_RAIN_2_UPDATE: begin
					if (pos_y_r2 >= 8'd119) begin
						if (draw_counter_r2 < 17'b10000000000000000) begin
							x = draw_counter_r2[7:0];
							y = draw_counter_r2[16:8];
							draw_counter_r2 = draw_counter_r2 + 1'b1;
						end
						else begin
							draw_counter_r2= 8'b00000000;
							current_state = S_RAIN_2_INIT;
						end
					end
					else begin
						pos_y_r2 = pos_y_r2 + 1'b1;
						current_state = S_RAIN_2_DRAW;
					end
				end
								
				//draw player 2
				S_RAIN_2_DRAW: begin
					if (draw_counter_r2 < 6'b100000) begin
						x = pos_x_r2 + draw_counter_r2[0];
						y = pos_y_r2 + draw_counter_r2[6:4];
						draw_counter_r2 = draw_counter_r2 + 2'b1;
						colour = 3'b001;
					end
					else begin
						draw_counter_r2= 8'b00000000;
						current_state = S_RAIN_3_ERASE;
					end
				end
				
				S_RAIN_3_ERASE: begin
					if (draw_counter_r3 < 6'b100000) begin
						x = pos_x_r3 + draw_counter_r3[0];
						y = pos_y_r3 + draw_counter_r3[6:4];
						draw_counter_r3 = draw_counter_r3 + 1'b1;
					end
					else begin
						draw_counter_r3= 8'b00000000;
						current_state = S_RAIN_3_UPDATE;
					end
				end

				//update player 2
				S_RAIN_3_UPDATE: begin
					if (pos_y_r3 >= 8'd119) begin
						if (draw_counter_r3 < 17'b10000000000000000) begin
							x = draw_counter_r3[7:0];
							y = draw_counter_r3[16:8];
							draw_counter_r3 = draw_counter_r3 + 1'b1;
						end
						else begin
							draw_counter_r3= 8'b00000000;
							current_state = S_RAIN_3_INIT;
						end
					end
					else begin
						pos_y_r3 = pos_y_r3 + 1'b1;
						current_state = S_RAIN_3_DRAW;
					end
				end
								
				//draw player 2
				S_RAIN_3_DRAW: begin
					if (draw_counter_r3 < 6'b100000) begin
						x = pos_x_r3 + draw_counter_r3[0];
						y = pos_y_r3 + draw_counter_r3[6:4];
						draw_counter_r3 = draw_counter_r3 + 1'b1;
						colour = 3'b001;
					end
					else begin
						draw_counter_r3 = 8'b00000000;
						current_state = S_RAIN_4_ERASE;
					end
				end
				
				S_RAIN_4_ERASE: begin
					if (draw_counter_r4 < 6'b100000) begin
						x = pos_x_r4 + draw_counter_r4[0];
						y = pos_y_r4 + draw_counter_r4[6:4];
						draw_counter_r4 = draw_counter_r4 + 1'b1;
					end
					else begin
						draw_counter_r4= 8'b00000000;
						current_state = S_RAIN_4_UPDATE;
					end
				end

				S_RAIN_4_UPDATE: begin
					if (pos_y_r4 >= 8'd119) begin
						if (draw_counter_r4 < 17'b10000000000000000) begin
							x = draw_counter_r4[7:0];
							y = draw_counter_r4[16:8];
							draw_counter_r4 = draw_counter_r4 + 1'b1;
						end
						else begin
							draw_counter_r4= 8'b00000000;
							current_state = S_RAIN_4_INIT;
						end
					end
					else begin
						pos_y_r4 = pos_y_r4 + 1'b1;
						current_state = S_RAIN_4_DRAW;
					end
				end
								
				S_RAIN_4_DRAW: begin
					if (draw_counter_r4 < 6'b100000) begin
						x = pos_x_r4 + draw_counter_r4[0];
						y = pos_y_r4 + draw_counter_r4[6:4];
						draw_counter_r4 = draw_counter_r4 + 1'b1;
						colour = 3'b001;
					end
					else begin
						draw_counter_r4 = 8'b00000000;
						current_state = S_RAIN_5_ERASE;
					end
				end
				
				S_RAIN_5_ERASE: begin
					if (draw_counter_r5 < 6'b100000) begin
						x = pos_x_r5 + draw_counter_r5[0];
						y = pos_y_r5 + draw_counter_r5[6:4];
						draw_counter_r5 = draw_counter_r5 + 1'b1;
					end
					else begin
						draw_counter_r5= 8'b00000000;
						current_state = S_RAIN_5_UPDATE;
					end
				end

				S_RAIN_5_UPDATE: begin
					if (pos_y_r5 >= 8'd119) begin
						if (draw_counter_r5 < 17'b10000000000000000) begin
							x = draw_counter_r5[7:0];
							y = draw_counter_r5[16:8];
							draw_counter_r5 = draw_counter_r5 + 1'b1;
						end
						else begin
							draw_counter_r5= 8'b00000000;
							current_state = S_RAIN_5_INIT;
						end
					end
					else begin
						pos_y_r5 = pos_y_r5 + 1'b1;
						current_state = S_RAIN_5_DRAW;
					end
				end
								
				S_RAIN_5_DRAW: begin
					if (draw_counter_r5 < 6'b100000) begin
						x = pos_x_r5 + draw_counter_r5[0];
						y = pos_y_r5 + draw_counter_r5[6:4];
						draw_counter_r5 = draw_counter_r5 + 1'b1;
						colour = 3'b001;
					end
					else begin
						draw_counter_r5 = 8'b00000000;
						current_state = S_IDLE;
					end
				end
				
				
				S_PLAYER1_WIN: begin
					p2_score = 8'd69;
					if (draw_counter_dead < 17'b10000000000000000) begin
							
							x = draw_counter_dead[7:0];
							y = draw_counter_dead[16:8];
							draw_counter_dead = draw_counter_dead + 1'b1;
							colour = 3'b010;
					end
				end
				
				S_PLAYER2_WIN: begin
					if (draw_counter_dead < 17'b10000000000000000) begin
							x = draw_counter_dead[7:0];
							y = draw_counter_dead[16:8];
							draw_counter_dead = draw_counter_dead + 1'b1;
							colour = 3'b100;
					end
				end
			endcase	
		end
endmodule

// code copied from
// https://github.com/julesyan/CSCB58-Final-Project
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
			4'b0000: OUT = 7'b1000000; // 0
			4'b0001: OUT = 7'b1111001; // 1
			4'b0010: OUT = 7'b0100100; // 2
			4'b0011: OUT = 7'b0110000; // 3
			4'b0100: OUT = 7'b0011001; // 4
			4'b0101: OUT = 7'b0010010; // 5
			4'b0110: OUT = 7'b0000010; // 6
			4'b0111: OUT = 7'b1111000; // 7
			4'b1000: OUT = 7'b0000000; // 8
			4'b1001: OUT = 7'b0011000; // 9
			4'b1010: OUT = 7'b0001000; // A
			4'b1011: OUT = 7'b0000011; // b
			4'b1100: OUT = 7'b1000110; // C
			4'b1101: OUT = 7'b0100001; // d
			4'b1110: OUT = 7'b0000110; // E
			4'b1111: OUT = 7'b0001110; // F
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule

// code obtained from
// https://pubweb.eng.utah.edu/~nmcdonal/Tutorials/BCDTutorial/BCDConversion.html
// added a thousands column (our own code)
module BCD (
  input [9:0] binary,
  output reg [3:0] Thousands,
  output reg [3:0] Hundreds,
  output reg [3:0] Tens,
  output reg [3:0] Ones
  );

  integer i;
  always @(binary)
  begin
    //set 100's, 10's, and 1's to 0
	 Thousands = 4'd0;
    Hundreds = 4'd0;
    Tens = 4'd0;
    Ones = 4'd0;

    for (i = 9; i >=0; i = i-1)
    begin
      //add 3 to columns >= 5
		if (Thousands >= 5)
			Thousands = Thousands + 3;

      if (Hundreds >= 5)
        Hundreds = Hundreds + 3;
      if (Tens >= 5)
        Tens = Tens + 3;
      if (Ones >= 5)
        Ones = Ones + 3;

      //shift left one
		Thousands = Thousands << 1;
		Thousands[0] = Hundreds[3];
      Hundreds = Hundreds << 1;
      Hundreds[0] = Tens[3];
      Tens = Tens << 1;
      Tens[0] = Ones[3];
      Ones = Ones << 1;
      Ones[0] = binary[i];
    end
  end
endmodule


module random_num(
	input  clk,
   output [8:0] data_out);
	reg [8:0] data = 8'd1;
	reg [32:0] counter;
	reg state;
	reg newbit;
	
	always @(posedge clk)
		begin
			counter <= counter + 1;
			state <= counter[0];
			if (!state)
				data <= data;
			else if(data == 8'b11111111 | data == 8'b00000000)
				data <= 8'd1;
			else
				data <= {data[7:0], data[6] ^ data[5]};
			end
		assign data_out = data;
endmodule

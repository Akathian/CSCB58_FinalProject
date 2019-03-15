module Rain
		(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		KEY,
		SW,
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
	input   [9:0]   SW;
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

	wire resetn, go, load, ld_y, ld_x, ld_c;
	assign resetn = KEY[0];
	assign load = KEY[3];
	assign go = KEY[1];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [7:0] x; // start at d80 b1010000
	wire [6:0] y; // start at d100 b1100100
	wire [1:0] pos_add_y, pos_add_x;
	wire writeEn;
	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(3'b100), // color red
			.x(x),
			.y(y),
			.plot(writeEn),
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

	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	// Instansiate datapath
	// datapath d0(...);
	datapath d0(
			.clk(CLOCK_50),
			.resetn(resetn),
			.data_in(SW[9:0]),
			.pos_add_y(pos_add_y),
			.pos_add_x(pos_add_x),
			.ld_y(ld_y),
			.ld_x(ld_x),
			.ld_c(ld_c),
			.y(y),
			.x(x),
			.c(colour)
		);

	control c0(
			.clk(CLOCK_50),
			.resetn(resetn),
			.go(go),
			.ld_y(ld_y),
			.ld_x(ld_x),
			.ld_c(ld_c),
			.en_plot(writeEn),
			.pos_add_y(pos_add_y),
			.pos_add_x(pos_add_x)
		);

endmodule

module control(
		input clk,
		input resetn,
		input go,
		output reg  ld_y, ld_x, ld_c,
		output reg  en_plot,
		output reg  [1:0]  pos_add_y, pos_add_x
		);
	reg [5:0] current_state, next_state;

	localparam S_LOAD_Y       = 5'd0, // 00000 in binary
		S_LOAD_Y_WAIT  = 5'd1, // 00001 in binary
		S_LOAD_X       = 5'd2, // 00010 in binary
		S_LOAD_X_WAIT  = 5'd3, // 00011 in binary
		S_DRAW_0       = 5'd4, //  00111 in binary
		S_DRAW_1       = 5'd5, //  01111 in binary
		S_DRAW_2       = 5'd6, //  11111 in binary
		S_DRAW_3			= 5'd7, // 01011 in binary
		S_DRAW_4			= 5'd8, // 01100 in binary
		S_DRAW_5       = 5'd9, //  01000 in binary
		S_DRAW_6       = 5'd10, // 01000 in binary
		S_DRAW_7       = 5'd11, // 01000 in binary
		S_DRAW_8       = 5'd12, // 01000 in binary
		S_DRAW_9       = 5'd13, // 01000 in binary
		S_DRAW_10      = 5'd14, // 01000 in binary
		S_DRAW_11      = 5'd15, // 01000 in binary
		S_DRAW_12      = 5'd16, // 01000 in binary
		S_DRAW_13      = 5'd17, // 01000 in binary
		S_DRAW_14      = 5'd18, // 01000 in binary
		S_DRAW_15      = 5'd19; // 01000 in binary


	// Next state logic aka our state table
	always@(*)
	begin: state_table
		case (current_state)
			//								go = 1 : go = 0
			// One line if format = COND. ? if true: if false
			S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
			S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_X; // Loop in current state until go signal goes low
			S_LOAD_X: next_state = go ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
			S_LOAD_X_WAIT: next_state = go ? S_LOAD_X_WAIT : S_DRAW_0; // Loop in current state until go signal goes low
			S_DRAW_0: next_state = S_DRAW_1;
			S_DRAW_1: next_state = S_DRAW_2;
			S_DRAW_2: next_state = S_DRAW_3;
			S_DRAW_3: next_state = S_DRAW_4;
			S_DRAW_4: next_state = S_DRAW_5;
			S_DRAW_5: next_state = S_DRAW_6;
			S_DRAW_6: next_state = S_DRAW_7;
			S_DRAW_7: next_state = S_DRAW_8;
			S_DRAW_8: next_state = S_DRAW_9;
			S_DRAW_9: next_state = S_DRAW_10;
			S_DRAW_10: next_state = S_DRAW_11;
			S_DRAW_11: next_state = S_DRAW_12;
			S_DRAW_12: next_state = S_DRAW_13;
			S_DRAW_13: next_state = S_DRAW_14;
			S_DRAW_14: next_state = S_DRAW_15;
			S_DRAW_15: next_state = S_LOAD_Y;// we will be done our operations, start over after
			default:     next_state = S_LOAD_Y;
		endcase
	end // state_table


	// Output logic aka all of our datapath control signals
	always @(*)
	begin: enable_signals
		// By default make all our signals 0
		ld_y = 1'b0;
		ld_x = 1'b0;
		ld_c = 1'b0;
		pos_add_y = 2'b00;
		pos_add_x = 2'b00;
		en_plot = 1'b0;

		case (current_state)
			S_LOAD_Y: begin
				ld_y = 1'b1;
			end
			S_LOAD_X: begin
				ld_x = 1'b1;
			end
			S_DRAW_0: begin
				en_plot = 1'b1;
			end
			S_DRAW_1: begin
				pos_add_y = 2'b01;
				pos_add_x = 2'b00;
				en_plot = 1'b1;
			end
			S_DRAW_2: begin
				pos_add_y = 2'b10;
				pos_add_x = 2'b00;
				en_plot = 1'b1;
			end
			S_DRAW_3: begin
				pos_add_y = 2'b11;
				pos_add_x = 2'b00;
				en_plot = 1'b1;
			end
			S_DRAW_4: begin
				pos_add_y = 2'b00;
				pos_add_x = 2'b01;
				en_plot = 1'b1;
			end
			S_DRAW_5: begin
				pos_add_y = 2'b01;
				pos_add_x = 2'b01;
				en_plot = 1'b1;
			end
			S_DRAW_6: begin
				pos_add_y = 2'b10;
				pos_add_x = 2'b01;
				en_plot = 1'b1;
			end
			S_DRAW_7: begin
				pos_add_y = 2'b11;
				pos_add_x = 2'b01;
				en_plot = 1'b1;
			end
			S_DRAW_8: begin
				pos_add_y = 2'b00;
				pos_add_x = 2'b10;
				en_plot = 1'b1;
			end
			S_DRAW_9: begin
				pos_add_y = 2'b01;
				pos_add_x = 2'b10;
				en_plot = 1'b1;
			end
			S_DRAW_10: begin
				pos_add_y = 2'b10;
				pos_add_x = 2'b10;
				en_plot = 1'b1;
			end
			S_DRAW_11: begin
				pos_add_y = 2'b11;
				pos_add_x = 2'b10;
				en_plot = 1'b1;
			end
			S_DRAW_12: begin
				en_plot = 1'b1;
				pos_add_y = 2'b00;
				pos_add_x = 2'b11;
			end
			S_DRAW_13: begin
				en_plot = 1'b1;
				pos_add_y = 2'b01;
				pos_add_x = 2'b11;
			end
			S_DRAW_14: begin
				en_plot = 1'b1;
				pos_add_y = 2'b10;
				pos_add_x = 2'b11;
			end
			S_DRAW_15: begin
				en_plot = 1'b1;
				pos_add_y = 2'b11;
				pos_add_x = 2'b11;
			end
			// default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
		endcase
	end // enable_signals

	// current_state registers
	always@(posedge clk)
	begin: state_FFs
		if(!resetn)
			current_state <= S_LOAD_Y;
		else
			current_state <= next_state;
	end // state_FFS
endmodule

module datapath(
		input clk,
		input resetn,
		input [9:0] data_in,
		input [1:0] pos_add_y, pos_add_x,
		input ld_y,
		input ld_x,
		input ld_c,
		output reg [6:0] y,
		output reg [7:0] x,
		output reg [2:0] c
		);
	reg [6:0]yi = 7'b0;
	reg [7:0]xi = 8'b0;
	reg [2:0]ci = 3'b0;
	// Registers a, b, c, x with respective input logic
	// if reset then reset everything
	always@(posedge clk) begin
		if(!resetn) begin
			yi <= 7'b0;
			xi <= 8'b0;
			ci <= 3'b0;
		end
		else begin
			// if we are loading y then take in data from switches
			if(ld_y)
				yi <= data_in[6:0];
			// if we are loading x then take in data from switches and prepend a 0
			if(ld_x)
				xi <= {1'b0 , data_in[7:0]};
			// if we are loading color then take data from switches
			if(ld_c)
				ci <= data_in[9:7];
		end
	end
	always @(*)
	begin : XY_ADD
		case (pos_add_y)
			2'b01: begin
				y <= yi + 2'b01;
			end
			2'b10: begin
				y <= yi + 2'b10;
			end
			2'b11: begin
				y <= yi + 2'b11;
			end
			default: y <= yi;
		endcase
		case (pos_add_x)
			2'b01: begin
				x <= xi + 2'b01;
			end
			2'b10: begin
				x <= xi + 2'b10;
			end
			2'b11: begin
				x <= xi + 2'b11;
			end
			default: x <= xi;
		endcase
		c <= ci;
	end
endmodule

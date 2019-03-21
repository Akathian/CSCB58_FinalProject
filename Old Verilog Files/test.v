module control(
		input clk,
		input resetn,
		input go,
		output reg  ld_y, ld_x, ld_c,
		output reg  en_plot,
		output reg  [1:0]  pos_add_y, pos_add_x
		);
	reg [5:0] current_state, next_state;

	localparam S_MENU 	= 5'd0,
		S_MENU_WAIT 	= 5'd1,
		S_DRAW_0     	= 5'd4, //  00111 in binary
		S_DRAW_1		= 5'd5, //  01111 in binary
		S_DRAW_2		= 5'd6, //  11111 in binary
		S_DRAW_3		= 5'd7, // 01011 in binary
		S_DRAW_4		= 5'd8, // 01100 in binary
		S_DRAW_5 		= 5'd9, //  01000 in binary
		S_DRAW_6 		= 5'd10, // 01000 in binary
		S_DRAW_7		= 5'd11, // 01000 in binary
		S_DRAW_8       	= 5'd12, // 01000 in binary
		S_DRAW_9       	= 5'd13, // 01000 in binary
		S_DRAW_10      	= 5'd14, // 01000 in binary
		S_DRAW_11     	= 5'd15, // 01000 in binary
		S_DRAW_12     	= 5'd16, // 01000 in binary
		S_DRAW_13      	= 5'd17, // 01000 in binary
		S_DRAW_14      	= 5'd18, // 01000 in binary
		S_DRAW_15      	= 5'd19, // 01000 in binary
		S_DRAW_WAIT		= 5'd20,
		S_ERASE_OLD		= 4'd21
		S_LEFT			= 5'd22,
		S_RIGHT 		= 5'd23;

	// Next state logic aka our state table
	always@(*)
	begin: state_table
		case (current_state)
			//								go = 1 : go = 0
			// One line if format = COND. ? if true: if false
			S_MENU: next_state = go ? S_MENU_WAIT : S_MENU;
			S_MENU_WAIT: next_state = go ? S_MENU_WAIT: S_DRAW_0;
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
			S_DRAW_15: next_state = S_DRAW_WAIT;
			S_DRAW_WAIT: next_state = (mv_left | mv_right) ? S_ERASE_OLD: S_DRAW_WAIT; // if mv left is high then go to mv left state
			S_ERASE_OLD: next_state = mv_left ? S_LEFT: S_ERASE_OLD;
			S_ERASE_OLD: next_state = mv_right ? S_RIGHT: S_ERASE_OLD;
			S_LEFT: next_state = S_DRAW_0;
			S_RIGHT: next_state = S_DRAW_0;
			default:     next_state = S_MENU;
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
		output reg [7:0] x
		);
	reg [6:0]yi = 7'b0;
	reg [7:0]xi = 8'b0;


	always@(posedge clk) begin
		if(!resetn) begin
			yi <= 7'b0;
			xi <= 8'b0;
		end
		else begin
			// if we are loading y then take in data from switches
			if(ld_y)
				yi <= 7'b1100100; //
			// if we are loading x then take in data from switches and prepend a 0
			if(ld_x)
				xi <= {1'b0 , 7'b1010000};
			// if we are loading color then take data from switches
			if(ld_c)
				ci <= 3'b100; // color red
		end
	end
endmodule

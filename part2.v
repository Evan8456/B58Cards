// Part 2 skeleton

module part2
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
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire ld_x;
	wire ld_y;
	wire x_offset;
	wire y_offest;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
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
	datapath d0(
			.clock(CLOCK_50),
			.resetn(resetn),
			.colour_in(SW[9:7]),
			.pos_in(SW[6:0]),
			.ld_x(ld_x),
			.ld_y(ld_y),
			.x_offest(x_offest),
			.y_offest(y_offest),
			.colour_out(colour),
			.x_out(x),
			.y_out(y));

    // Instansiate FSM control
    control c0(
			.clock(CLOCK_50),
			.resetn(resetn),
			.go(KEY[3]),
			.plot(writeEn),
			.ld_x(ld_x),
			.ld_y(ld_y),
			.x_offest(x_offest),
			.y_offest(y_offest));
endmodule

module datapath(
	input clock,
	input resetn,
	input [2:0] colour_in,
	input [6:0] pos_in,
	input ld_x,
	input ld_y,
	input [1:0] x_offset,
	input [1:0] y_offset,
	
	output reg colour_out,
	output reg x_out,
	output reg y_out
	);
	
	always @(posedge clock) begin
		if(!resetn) begin
			colour_out <= 3'b0;
			x_out <= 7'b0;
			y_out <= 7'b0;
		end
		else begin
			colour_out <= colour_in;
			if(ld_x)
				x_out <= (pos_in + x_offest);
			if(ld_y)
				y_out <= (pos_in + y_offset);
		end
	end
endmodule

module control(
	input clock,
	input resetn,
	input go,
	
	output reg plot,
	output reg ld_x,
	output reg ld_y,
	output reg [1:0] x_offest,
	output reg [1:0] y_offest
	);

    reg [4:0] current_state, next_state; 
    
	localparam  LOAD_X			= 5'd0,
                LOAD_X_WAIT		= 5'd1,
				LOAD_Y			= 5'd2,
                LOAD_Y_WAIT		= 5'd3,
                PLOT_00			= 5'd4,
                PLOT_01			= 5'd5,
                PLOT_02			= 5'd6,
                PLOT_03			= 5'd7,
                PLOT_10			= 5'd8,
                PLOT_11			= 5'd9,
                PLOT_12			= 5'd10,
                PLOT_13			= 5'd11,
                PLOT_20			= 5'd12,
                PLOT_21			= 5'd13,
                PLOT_22			= 5'd14,
                PLOT_23			= 5'd15,
                PLOT_30			= 5'd16,
                PLOT_31			= 5'd17,
                PLOT_32			= 5'd18,
                PLOT_33			= 5'd19;
	
	// Next state logic
	always @(posedge clock) begin
		case(current_state)
                LOAD_X: next_state = go ? LOAD_X_WAIT : LOAD_X; // Loop in current state until value is input
                LOAD_X_WAIT: next_state = go ? LOAD_X_WAIT : LOAD_Y; // Loop in current state until go signal goes low
                LOAD_Y: next_state = go ? LOAD_Y_WAIT : LOAD_Y; // Loop in current state until value is input
                LOAD_Y_WAIT: next_state = go ? LOAD_Y_WAIT : PLOT_00; // Loop in current state until go signal goes low
				PLOT_00: next_state = PLOT_01;
				PLOT_01: next_state = PLOT_02;
				PLOT_02: next_state = PLOT_03;
				PLOT_03: next_state = PLOT_10;
				PLOT_10: next_state = PLOT_11;
				PLOT_11: next_state = PLOT_12;
				PLOT_12: next_state = PLOT_13;
				PLOT_13: next_state = PLOT_20;
				PLOT_20: next_state = PLOT_21;
				PLOT_21: next_state = PLOT_22;
				PLOT_22: next_state = PLOT_23;
				PLOT_23: next_state = PLOT_30;
				PLOT_30: next_state = PLOT_31;
				PLOT_31: next_state = PLOT_32;
				PLOT_32: next_state = PLOT_33;
				PLOT_33: next_state = LOAD_X; // loop back to the begining
            default:	next_state = LOAD_X;
		endcase
	end
	
	// Output Logic
	always @(*) begin
		// make all signals default to zero
		plot = 1'b0;
		ld_x = 1'b0;
		ld_y = 1'b0;
		x_offest = 2'd0;
		y_offest = 2'd0;
		
		case(current_state)
			LOAD_X: begin
				ld_x = 1'b1;
			end
			LOAD_Y: begin
				ld_y = 1'b1;
			end
			PLOT_00: begin
				plot = 1'b1;
			end
			PLOT_01: begin
				plot = 1'b1;
				y_offest = 2'd1;
			end
			PLOT_02: begin
				plot = 1'b1;
				y_offest = 2'd2;
			end
			PLOT_03: begin
				plot = 1'b1;
				y_offest = 2'd3;
			end
			PLOT_10: begin
				plot = 1'b1;
				x_offest = 2'd1;
			end
			PLOT_11: begin
				plot = 1'b1;
				x_offest = 2'd1;
				y_offest = 2'd1;
			end
			PLOT_12: begin
				plot = 1'b1;
				x_offest = 2'd1;
				y_offest = 2'd2;
			end
			PLOT_13: begin
				plot = 1'b1;
				x_offest = 2'd1;
				y_offest = 2'd3;
			end
			PLOT_20: begin
				plot = 1'b1;
				x_offest = 2'd2;
			end
			PLOT_21: begin
				plot = 1'b1;
				x_offest = 2'd2;
				y_offest = 2'd1;
			end
			PLOT_22: begin
				plot = 1'b1;
				x_offest = 2'd2;
				y_offest = 2'd2;
			end
			PLOT_23: begin
				plot = 1'b1;
				x_offest = 2'd2;
				y_offest = 2'd3;
			end
			PLOT_30: begin
				plot = 1'b1;
				x_offest = 2'd3;
			end
			PLOT_31: begin
				plot = 1'b1;
				x_offest = 2'd3;
				y_offest = 2'd1;
			end
			PLOT_32: begin
				plot = 1'b1;
				x_offest = 2'd3;
				y_offest = 2'd2;
			end
			PLOT_33: begin
				plot = 1'b1;
				x_offest = 2'd3;
				y_offest = 2'd3;
			end
		endcase
	end
	
	// update current_state
	always@(posedge clock) begin
        if(!resetn)
            current_state <= LOAD_X;
        else
            current_state <= next_state;
	end
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule

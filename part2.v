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
//[16:0] ? or [4:0]
    reg [16:0] current_state, next_state; 
    
    
	localparam
	LOAD_X  = 5'd0
	LOAD_X_WAIT  = 5'd1,
	LOAD_Y  = 5'd2,
	LOAD_Y_WAIT  = 5'd3,
	PLOT_0_0= 5'd4,
	PLOT_0_1= 5'd5,
	PLOT_0_2= 5'd6,
	PLOT_0_3= 5'd7,
	PLOT_0_4= 5'd8,
	PLOT_0_5= 5'd9,
	PLOT_0_6= 5'd10,
	PLOT_0_7= 5'd11,
	PLOT_0_8= 5'd12,
	PLOT_0_9= 5'd13,
	PLOT_0_10= 5'd14,
	PLOT_0_11= 5'd15,
	PLOT_0_12= 5'd16,
	PLOT_0_13= 5'd17,
	PLOT_0_14= 5'd18,
	PLOT_0_15= 5'd19,
	PLOT_1_0= 5'd20,
	PLOT_1_1= 5'd21,
	PLOT_1_2= 5'd22,
	PLOT_1_3= 5'd23,
	PLOT_1_4= 5'd24,
	PLOT_1_5= 5'd25,
	PLOT_1_6= 5'd26,
	PLOT_1_7= 5'd27,
	PLOT_1_8= 5'd28,
	PLOT_1_9= 5'd29,
	PLOT_1_10= 5'd30,
	PLOT_1_11= 5'd31,
	PLOT_1_12= 5'd32,
	PLOT_1_13= 5'd33,
	PLOT_1_14= 5'd34,
	PLOT_1_15= 5'd35,
	PLOT_2_0= 5'd36,
	PLOT_2_1= 5'd37,
	PLOT_2_2= 5'd38,
	PLOT_2_3= 5'd39,
	PLOT_2_4= 5'd40,
	PLOT_2_5= 5'd41,
	PLOT_2_6= 5'd42,
	PLOT_2_7= 5'd43,
	PLOT_2_8= 5'd44,
	PLOT_2_9= 5'd45,
	PLOT_2_10= 5'd46,
	PLOT_2_11= 5'd47,
	PLOT_2_12= 5'd48,
	PLOT_2_13= 5'd49,
	PLOT_2_14= 5'd50,
	PLOT_2_15= 5'd51,
	PLOT_3_0= 5'd52,
	PLOT_3_1= 5'd53,
	PLOT_3_2= 5'd54,
	PLOT_3_3= 5'd55,
	PLOT_3_4= 5'd56,
	PLOT_3_5= 5'd57,
	PLOT_3_6= 5'd58,
	PLOT_3_7= 5'd59,
	PLOT_3_8= 5'd60,
	PLOT_3_9= 5'd61,
	PLOT_3_10= 5'd62,
	PLOT_3_11= 5'd63,
	PLOT_3_12= 5'd64,
	PLOT_3_13= 5'd65,
	PLOT_3_14= 5'd66,
	PLOT_3_15= 5'd67,
	PLOT_4_0= 5'd68,
	PLOT_4_1= 5'd69,
	PLOT_4_2= 5'd70,
	PLOT_4_3= 5'd71,
	PLOT_4_4= 5'd72,
	PLOT_4_5= 5'd73,
	PLOT_4_6= 5'd74,
	PLOT_4_7= 5'd75,
	PLOT_4_8= 5'd76,
	PLOT_4_9= 5'd77,
	PLOT_4_10= 5'd78,
	PLOT_4_11= 5'd79,
	PLOT_4_12= 5'd80,
	PLOT_4_13= 5'd81,
	PLOT_4_14= 5'd82,
	PLOT_4_15= 5'd83,
	PLOT_5_0= 5'd84,
	PLOT_5_1= 5'd85,
	PLOT_5_2= 5'd86,
	PLOT_5_3= 5'd87,
	PLOT_5_4= 5'd88,
	PLOT_5_5= 5'd89,
	PLOT_5_6= 5'd90,
	PLOT_5_7= 5'd91,
	PLOT_5_8= 5'd92,
	PLOT_5_9= 5'd93,
	PLOT_5_10= 5'd94,
	PLOT_5_11= 5'd95,
	PLOT_5_12= 5'd96,
	PLOT_5_13= 5'd97,
	PLOT_5_14= 5'd98,
	PLOT_5_15= 5'd99,
	PLOT_6_0= 5'd100,
	PLOT_6_1= 5'd101,
	PLOT_6_2= 5'd102,
	PLOT_6_3= 5'd103,
	PLOT_6_4= 5'd104,
	PLOT_6_5= 5'd105,
	PLOT_6_6= 5'd106,
	PLOT_6_7= 5'd107,
	PLOT_6_8= 5'd108,
	PLOT_6_9= 5'd109,
	PLOT_6_10= 5'd110,
	PLOT_6_11= 5'd111,
	PLOT_6_12= 5'd112,
	PLOT_6_13= 5'd113,
	PLOT_6_14= 5'd114,
	PLOT_6_15= 5'd115,
	PLOT_7_0= 5'd116,
	PLOT_7_1= 5'd117,
	PLOT_7_2= 5'd118,
	PLOT_7_3= 5'd119,
	PLOT_7_4= 5'd120,
	PLOT_7_5= 5'd121,
	PLOT_7_6= 5'd122,
	PLOT_7_7= 5'd123,
	PLOT_7_8= 5'd124,
	PLOT_7_9= 5'd125,
	PLOT_7_10= 5'd126,
	PLOT_7_11= 5'd127,
	PLOT_7_12= 5'd128,
	PLOT_7_13= 5'd129,
	PLOT_7_14= 5'd130,
	PLOT_7_15= 5'd131,
	PLOT_8_0= 5'd132,
	PLOT_8_1= 5'd133,
	PLOT_8_2= 5'd134,
	PLOT_8_3= 5'd135,
	PLOT_8_4= 5'd136,
	PLOT_8_5= 5'd137,
	PLOT_8_6= 5'd138,
	PLOT_8_7= 5'd139,
	PLOT_8_8= 5'd140,
	PLOT_8_9= 5'd141,
	PLOT_8_10= 5'd142,
	PLOT_8_11= 5'd143,
	PLOT_8_12= 5'd144,
	PLOT_8_13= 5'd145,
	PLOT_8_14= 5'd146,
	PLOT_8_15= 5'd147,
	PLOT_9_0= 5'd148,
	PLOT_9_1= 5'd149,
	PLOT_9_2= 5'd150,
	PLOT_9_3= 5'd151,
	PLOT_9_4= 5'd152,
	PLOT_9_5= 5'd153,
	PLOT_9_6= 5'd154,
	PLOT_9_7= 5'd155,
	PLOT_9_8= 5'd156,
	PLOT_9_9= 5'd157,
	PLOT_9_10= 5'd158,
	PLOT_9_11= 5'd159,
	PLOT_9_12= 5'd160,
	PLOT_9_13= 5'd161,
	PLOT_9_14= 5'd162,
	PLOT_9_15= 5'd163,
	PLOT_10_0= 5'd164,
	PLOT_10_1= 5'd165,
	PLOT_10_2= 5'd166,
	PLOT_10_3= 5'd167,
	PLOT_10_4= 5'd168,
	PLOT_10_5= 5'd169,
	PLOT_10_6= 5'd170,
	PLOT_10_7= 5'd171,
	PLOT_10_8= 5'd172,
	PLOT_10_9= 5'd173,
	PLOT_10_10= 5'd174,
	PLOT_10_11= 5'd175,
	PLOT_10_12= 5'd176,
	PLOT_10_13= 5'd177,
	PLOT_10_14= 5'd178,
	PLOT_10_15= 5'd179,
	PLOT_11_0= 5'd180,
	PLOT_11_1= 5'd181,
	PLOT_11_2= 5'd182,
	PLOT_11_3= 5'd183,
	PLOT_11_4= 5'd184,
	PLOT_11_5= 5'd185,
	PLOT_11_6= 5'd186,
	PLOT_11_7= 5'd187,
	PLOT_11_8= 5'd188,
	PLOT_11_9= 5'd189,
	PLOT_11_10= 5'd190,
	PLOT_11_11= 5'd191,
	PLOT_11_12= 5'd192,
	PLOT_11_13= 5'd193,
	PLOT_11_14= 5'd194,
	PLOT_11_15= 5'd195,
	PLOT_12_0= 5'd196,
	PLOT_12_1= 5'd197,
	PLOT_12_2= 5'd198,
	PLOT_12_3= 5'd199,
	PLOT_12_4= 5'd200,
	PLOT_12_5= 5'd201,
	PLOT_12_6= 5'd202,
	PLOT_12_7= 5'd203,
	PLOT_12_8= 5'd204,
	PLOT_12_9= 5'd205,
	PLOT_12_10= 5'd206,
	PLOT_12_11= 5'd207,
	PLOT_12_12= 5'd208,
	PLOT_12_13= 5'd209,
	PLOT_12_14= 5'd210,
	PLOT_12_15= 5'd211,
	PLOT_13_0= 5'd212,
	PLOT_13_1= 5'd213,
	PLOT_13_2= 5'd214,
	PLOT_13_3= 5'd215,
	PLOT_13_4= 5'd216,
	PLOT_13_5= 5'd217,
	PLOT_13_6= 5'd218,
	PLOT_13_7= 5'd219,
	PLOT_13_8= 5'd220,
	PLOT_13_9= 5'd221,
	PLOT_13_10= 5'd222,
	PLOT_13_11= 5'd223,
	PLOT_13_12= 5'd224,
	PLOT_13_13= 5'd225,
	PLOT_13_14= 5'd226,
	PLOT_13_15= 5'd227,
	PLOT_14_0= 5'd228,
	PLOT_14_1= 5'd229,
	PLOT_14_2= 5'd230,
	PLOT_14_3= 5'd231,
	PLOT_14_4= 5'd232,
	PLOT_14_5= 5'd233,
	PLOT_14_6= 5'd234,
	PLOT_14_7= 5'd235,
	PLOT_14_8= 5'd236,
	PLOT_14_9= 5'd237,
	PLOT_14_10= 5'd238,
	PLOT_14_11= 5'd239,
	PLOT_14_12= 5'd240,
	PLOT_14_13= 5'd241,
	PLOT_14_14= 5'd242,
	PLOT_14_15= 5'd243,
	PLOT_15_0= 5'd244,
	PLOT_15_1= 5'd245,
	PLOT_15_2= 5'd246,
	PLOT_15_3= 5'd247,
	PLOT_15_4= 5'd248,
	PLOT_15_5= 5'd249,
	PLOT_15_6= 5'd250,
	PLOT_15_7= 5'd251,
	PLOT_15_8= 5'd252,
	PLOT_15_9= 5'd253,
	PLOT_15_10= 5'd254,
	PLOT_15_11= 5'd255,
	PLOT_15_12= 5'd256,
	PLOT_15_13= 5'd257,
	PLOT_15_14= 5'd258,
	PLOT_15_15= 5'd259;

always @(posedge clock) begin
    case(current_state)
	LOAD_X: next_state = go ? LOAD_X_WAIT : LOAD_X;
	LOAD_X_WAIT: next_state = go ? LOAD_X_WAIT : LOAD_Y;
 	LOAD_Y: next_state = go ? LOAD_Y_WAIT : LOAD_Y;
	LOAD_Y_WAIT: next_state = go ? LOAD_Y_WAIT : PLOT_00;
	PLOT_0_0:  next_state=  PLOT_0_1; 
	PLOT_0_1:  next_state=  PLOT_0_2; 
	PLOT_0_2:  next_state=  PLOT_0_3; 
	PLOT_0_3:  next_state=  PLOT_0_4; 
	PLOT_0_4:  next_state=  PLOT_0_5; 
	PLOT_0_5:  next_state=  PLOT_0_6; 
	PLOT_0_6:  next_state=  PLOT_0_7; 
	PLOT_0_7:  next_state=  PLOT_0_8; 
	PLOT_0_8:  next_state=  PLOT_0_9; 
	PLOT_0_9:  next_state=  PLOT_0_10; 
	PLOT_0_10:  next_state=  PLOT_0_11; 
	PLOT_0_11:  next_state=  PLOT_0_12; 
	PLOT_0_12:  next_state=  PLOT_0_13; 
	PLOT_0_13:  next_state=  PLOT_0_14; 
	PLOT_0_14:  next_state=  PLOT_0_15; 
	PLOT_0_15:  next_state=  PLOT_10; 
	PLOT_1_0:  next_state=  PLOT_1_1; 
	PLOT_1_1:  next_state=  PLOT_1_2; 
	PLOT_1_2:  next_state=  PLOT_1_3; 
	PLOT_1_3:  next_state=  PLOT_1_4; 
	PLOT_1_4:  next_state=  PLOT_1_5; 
	PLOT_1_5:  next_state=  PLOT_1_6; 
	PLOT_1_6:  next_state=  PLOT_1_7; 
	PLOT_1_7:  next_state=  PLOT_1_8; 
	PLOT_1_8:  next_state=  PLOT_1_9; 
	PLOT_1_9:  next_state=  PLOT_1_10; 
	PLOT_1_10:  next_state=  PLOT_1_11; 
	PLOT_1_11:  next_state=  PLOT_1_12; 
	PLOT_1_12:  next_state=  PLOT_1_13; 
	PLOT_1_13:  next_state=  PLOT_1_14; 
	PLOT_1_14:  next_state=  PLOT_1_15; 
	PLOT_1_15:  next_state=  PLOT_20; 
	PLOT_2_0:  next_state=  PLOT_2_1; 
	PLOT_2_1:  next_state=  PLOT_2_2; 
	PLOT_2_2:  next_state=  PLOT_2_3; 
	PLOT_2_3:  next_state=  PLOT_2_4; 
	PLOT_2_4:  next_state=  PLOT_2_5; 
	PLOT_2_5:  next_state=  PLOT_2_6; 
	PLOT_2_6:  next_state=  PLOT_2_7; 
	PLOT_2_7:  next_state=  PLOT_2_8; 
	PLOT_2_8:  next_state=  PLOT_2_9; 
	PLOT_2_9:  next_state=  PLOT_2_10; 
	PLOT_2_10:  next_state=  PLOT_2_11; 
	PLOT_2_11:  next_state=  PLOT_2_12; 
	PLOT_2_12:  next_state=  PLOT_2_13; 
	PLOT_2_13:  next_state=  PLOT_2_14; 
	PLOT_2_14:  next_state=  PLOT_2_15; 
	PLOT_2_15:  next_state=  PLOT_30; 
	PLOT_3_0:  next_state=  PLOT_3_1; 
	PLOT_3_1:  next_state=  PLOT_3_2; 
	PLOT_3_2:  next_state=  PLOT_3_3; 
	PLOT_3_3:  next_state=  PLOT_3_4; 
	PLOT_3_4:  next_state=  PLOT_3_5; 
	PLOT_3_5:  next_state=  PLOT_3_6; 
	PLOT_3_6:  next_state=  PLOT_3_7; 
	PLOT_3_7:  next_state=  PLOT_3_8; 
	PLOT_3_8:  next_state=  PLOT_3_9; 
	PLOT_3_9:  next_state=  PLOT_3_10; 
	PLOT_3_10:  next_state=  PLOT_3_11; 
	PLOT_3_11:  next_state=  PLOT_3_12; 
	PLOT_3_12:  next_state=  PLOT_3_13; 
	PLOT_3_13:  next_state=  PLOT_3_14; 
	PLOT_3_14:  next_state=  PLOT_3_15; 
	PLOT_3_15:  next_state=  PLOT_40; 
	PLOT_4_0:  next_state=  PLOT_4_1; 
	PLOT_4_1:  next_state=  PLOT_4_2; 
	PLOT_4_2:  next_state=  PLOT_4_3; 
	PLOT_4_3:  next_state=  PLOT_4_4; 
	PLOT_4_4:  next_state=  PLOT_4_5; 
	PLOT_4_5:  next_state=  PLOT_4_6; 
	PLOT_4_6:  next_state=  PLOT_4_7; 
	PLOT_4_7:  next_state=  PLOT_4_8; 
	PLOT_4_8:  next_state=  PLOT_4_9; 
	PLOT_4_9:  next_state=  PLOT_4_10; 
	PLOT_4_10:  next_state=  PLOT_4_11; 
	PLOT_4_11:  next_state=  PLOT_4_12; 
	PLOT_4_12:  next_state=  PLOT_4_13; 
	PLOT_4_13:  next_state=  PLOT_4_14; 
	PLOT_4_14:  next_state=  PLOT_4_15; 
	PLOT_4_15:  next_state=  PLOT_50; 
	PLOT_5_0:  next_state=  PLOT_5_1; 
	PLOT_5_1:  next_state=  PLOT_5_2; 
	PLOT_5_2:  next_state=  PLOT_5_3; 
	PLOT_5_3:  next_state=  PLOT_5_4; 
	PLOT_5_4:  next_state=  PLOT_5_5; 
	PLOT_5_5:  next_state=  PLOT_5_6; 
	PLOT_5_6:  next_state=  PLOT_5_7; 
	PLOT_5_7:  next_state=  PLOT_5_8; 
	PLOT_5_8:  next_state=  PLOT_5_9; 
	PLOT_5_9:  next_state=  PLOT_5_10; 
	PLOT_5_10:  next_state=  PLOT_5_11; 
	PLOT_5_11:  next_state=  PLOT_5_12; 
	PLOT_5_12:  next_state=  PLOT_5_13; 
	PLOT_5_13:  next_state=  PLOT_5_14; 
	PLOT_5_14:  next_state=  PLOT_5_15; 
	PLOT_5_15:  next_state=  PLOT_60; 
	PLOT_6_0:  next_state=  PLOT_6_1; 
	PLOT_6_1:  next_state=  PLOT_6_2; 
	PLOT_6_2:  next_state=  PLOT_6_3; 
	PLOT_6_3:  next_state=  PLOT_6_4; 
	PLOT_6_4:  next_state=  PLOT_6_5; 
	PLOT_6_5:  next_state=  PLOT_6_6; 
	PLOT_6_6:  next_state=  PLOT_6_7; 
	PLOT_6_7:  next_state=  PLOT_6_8; 
	PLOT_6_8:  next_state=  PLOT_6_9; 
	PLOT_6_9:  next_state=  PLOT_6_10; 
	PLOT_6_10:  next_state=  PLOT_6_11; 
	PLOT_6_11:  next_state=  PLOT_6_12; 
	PLOT_6_12:  next_state=  PLOT_6_13; 
	PLOT_6_13:  next_state=  PLOT_6_14; 
	PLOT_6_14:  next_state=  PLOT_6_15; 
	PLOT_6_15:  next_state=  PLOT_70; 
	PLOT_7_0:  next_state=  PLOT_7_1; 
	PLOT_7_1:  next_state=  PLOT_7_2; 
	PLOT_7_2:  next_state=  PLOT_7_3; 
	PLOT_7_3:  next_state=  PLOT_7_4; 
	PLOT_7_4:  next_state=  PLOT_7_5; 
	PLOT_7_5:  next_state=  PLOT_7_6; 
	PLOT_7_6:  next_state=  PLOT_7_7; 
	PLOT_7_7:  next_state=  PLOT_7_8; 
	PLOT_7_8:  next_state=  PLOT_7_9; 
	PLOT_7_9:  next_state=  PLOT_7_10; 
	PLOT_7_10:  next_state=  PLOT_7_11; 
	PLOT_7_11:  next_state=  PLOT_7_12; 
	PLOT_7_12:  next_state=  PLOT_7_13; 
	PLOT_7_13:  next_state=  PLOT_7_14; 
	PLOT_7_14:  next_state=  PLOT_7_15; 
	PLOT_7_15:  next_state=  PLOT_80; 
	PLOT_8_0:  next_state=  PLOT_8_1; 
	PLOT_8_1:  next_state=  PLOT_8_2; 
	PLOT_8_2:  next_state=  PLOT_8_3; 
	PLOT_8_3:  next_state=  PLOT_8_4; 
	PLOT_8_4:  next_state=  PLOT_8_5; 
	PLOT_8_5:  next_state=  PLOT_8_6; 
	PLOT_8_6:  next_state=  PLOT_8_7; 
	PLOT_8_7:  next_state=  PLOT_8_8; 
	PLOT_8_8:  next_state=  PLOT_8_9; 
	PLOT_8_9:  next_state=  PLOT_8_10; 
	PLOT_8_10:  next_state=  PLOT_8_11; 
	PLOT_8_11:  next_state=  PLOT_8_12; 
	PLOT_8_12:  next_state=  PLOT_8_13; 
	PLOT_8_13:  next_state=  PLOT_8_14; 
	PLOT_8_14:  next_state=  PLOT_8_15; 
	PLOT_8_15:  next_state=  PLOT_90; 
	PLOT_9_0:  next_state=  PLOT_9_1; 
	PLOT_9_1:  next_state=  PLOT_9_2; 
	PLOT_9_2:  next_state=  PLOT_9_3; 
	PLOT_9_3:  next_state=  PLOT_9_4; 
	PLOT_9_4:  next_state=  PLOT_9_5; 
	PLOT_9_5:  next_state=  PLOT_9_6; 
	PLOT_9_6:  next_state=  PLOT_9_7; 
	PLOT_9_7:  next_state=  PLOT_9_8; 
	PLOT_9_8:  next_state=  PLOT_9_9; 
	PLOT_9_9:  next_state=  PLOT_9_10; 
	PLOT_9_10:  next_state=  PLOT_9_11; 
	PLOT_9_11:  next_state=  PLOT_9_12; 
	PLOT_9_12:  next_state=  PLOT_9_13; 
	PLOT_9_13:  next_state=  PLOT_9_14; 
	PLOT_9_14:  next_state=  PLOT_9_15; 
	PLOT_9_15:  next_state=  PLOT_100; 
	PLOT_10_0:  next_state=  PLOT_10_1; 
	PLOT_10_1:  next_state=  PLOT_10_2; 
	PLOT_10_2:  next_state=  PLOT_10_3; 
	PLOT_10_3:  next_state=  PLOT_10_4; 
	PLOT_10_4:  next_state=  PLOT_10_5; 
	PLOT_10_5:  next_state=  PLOT_10_6; 
	PLOT_10_6:  next_state=  PLOT_10_7; 
	PLOT_10_7:  next_state=  PLOT_10_8; 
	PLOT_10_8:  next_state=  PLOT_10_9; 
	PLOT_10_9:  next_state=  PLOT_10_10; 
	PLOT_10_10:  next_state=  PLOT_10_11; 
	PLOT_10_11:  next_state=  PLOT_10_12; 
	PLOT_10_12:  next_state=  PLOT_10_13; 
	PLOT_10_13:  next_state=  PLOT_10_14; 
	PLOT_10_14:  next_state=  PLOT_10_15; 
	PLOT_10_15:  next_state=  PLOT_110; 
	PLOT_11_0:  next_state=  PLOT_11_1; 
	PLOT_11_1:  next_state=  PLOT_11_2; 
	PLOT_11_2:  next_state=  PLOT_11_3; 
	PLOT_11_3:  next_state=  PLOT_11_4; 
	PLOT_11_4:  next_state=  PLOT_11_5; 
	PLOT_11_5:  next_state=  PLOT_11_6; 
	PLOT_11_6:  next_state=  PLOT_11_7; 
	PLOT_11_7:  next_state=  PLOT_11_8; 
	PLOT_11_8:  next_state=  PLOT_11_9; 
	PLOT_11_9:  next_state=  PLOT_11_10; 
	PLOT_11_10:  next_state=  PLOT_11_11; 
	PLOT_11_11:  next_state=  PLOT_11_12; 
	PLOT_11_12:  next_state=  PLOT_11_13; 
	PLOT_11_13:  next_state=  PLOT_11_14; 
	PLOT_11_14:  next_state=  PLOT_11_15; 
	PLOT_11_15:  next_state=  PLOT_120; 
	PLOT_12_0:  next_state=  PLOT_12_1; 
	PLOT_12_1:  next_state=  PLOT_12_2; 
	PLOT_12_2:  next_state=  PLOT_12_3; 
	PLOT_12_3:  next_state=  PLOT_12_4; 
	PLOT_12_4:  next_state=  PLOT_12_5; 
	PLOT_12_5:  next_state=  PLOT_12_6; 
	PLOT_12_6:  next_state=  PLOT_12_7; 
	PLOT_12_7:  next_state=  PLOT_12_8; 
	PLOT_12_8:  next_state=  PLOT_12_9; 
	PLOT_12_9:  next_state=  PLOT_12_10; 
	PLOT_12_10:  next_state=  PLOT_12_11; 
	PLOT_12_11:  next_state=  PLOT_12_12; 
	PLOT_12_12:  next_state=  PLOT_12_13; 
	PLOT_12_13:  next_state=  PLOT_12_14; 
	PLOT_12_14:  next_state=  PLOT_12_15; 
	PLOT_12_15:  next_state=  PLOT_130; 
	PLOT_13_0:  next_state=  PLOT_13_1; 
	PLOT_13_1:  next_state=  PLOT_13_2; 
	PLOT_13_2:  next_state=  PLOT_13_3; 
	PLOT_13_3:  next_state=  PLOT_13_4; 
	PLOT_13_4:  next_state=  PLOT_13_5; 
	PLOT_13_5:  next_state=  PLOT_13_6; 
	PLOT_13_6:  next_state=  PLOT_13_7; 
	PLOT_13_7:  next_state=  PLOT_13_8; 
	PLOT_13_8:  next_state=  PLOT_13_9; 
	PLOT_13_9:  next_state=  PLOT_13_10; 
	PLOT_13_10:  next_state=  PLOT_13_11; 
	PLOT_13_11:  next_state=  PLOT_13_12; 
	PLOT_13_12:  next_state=  PLOT_13_13; 
	PLOT_13_13:  next_state=  PLOT_13_14; 
	PLOT_13_14:  next_state=  PLOT_13_15; 
	PLOT_13_15:  next_state=  PLOT_140; 
	PLOT_14_0:  next_state=  PLOT_14_1; 
	PLOT_14_1:  next_state=  PLOT_14_2; 
	PLOT_14_2:  next_state=  PLOT_14_3; 
	PLOT_14_3:  next_state=  PLOT_14_4; 
	PLOT_14_4:  next_state=  PLOT_14_5; 
	PLOT_14_5:  next_state=  PLOT_14_6; 
	PLOT_14_6:  next_state=  PLOT_14_7; 
	PLOT_14_7:  next_state=  PLOT_14_8; 
	PLOT_14_8:  next_state=  PLOT_14_9; 
	PLOT_14_9:  next_state=  PLOT_14_10; 
	PLOT_14_10:  next_state=  PLOT_14_11; 
	PLOT_14_11:  next_state=  PLOT_14_12; 
	PLOT_14_12:  next_state=  PLOT_14_13; 
	PLOT_14_13:  next_state=  PLOT_14_14; 
	PLOT_14_14:  next_state=  PLOT_14_15; 
	PLOT_14_15:  next_state=  PLOT_150; 
	PLOT_15_0:  next_state=  PLOT_15_1; 
	PLOT_15_1:  next_state=  PLOT_15_2; 
	PLOT_15_2:  next_state=  PLOT_15_3; 
	PLOT_15_3:  next_state=  PLOT_15_4; 
	PLOT_15_4:  next_state=  PLOT_15_5; 
	PLOT_15_5:  next_state=  PLOT_15_6; 
	PLOT_15_6:  next_state=  PLOT_15_7; 
	PLOT_15_7:  next_state=  PLOT_15_8; 
	PLOT_15_8:  next_state=  PLOT_15_9; 
	PLOT_15_9:  next_state=  PLOT_15_10; 
	PLOT_15_10:  next_state=  PLOT_15_11; 
	PLOT_15_11:  next_state=  PLOT_15_12; 
	PLOT_15_12:  next_state=  PLOT_15_13; 
	PLOT_15_13:  next_state=  PLOT_15_14; 
	PLOT_15_14:  next_state=  PLOT_15_15; 
	PLOT_15_15:  next_state=  LOAD_X; 
        default:	next_state = LOAD_X; 
   endcase
end

always @(*) begin
   plot = 1'b0
   id_x = 1'b0
   id_y = 1'b0
   x_offset = 2'b0
   y_offset = 2'b0
case(current_state)
    LOAD_X: begin
    	id_x = 1'b1;
 end
    LOAD_X: begin
    	id_y = 1'b1;
 end
     PLOT_0_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd0;
     PLOT_0_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd1;
     PLOT_0_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd2;
     PLOT_0_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd3;
     PLOT_0_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd4;
     PLOT_0_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd5;
     PLOT_0_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd6;
     PLOT_0_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd7;
     PLOT_0_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd8;
     PLOT_0_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd9;
     PLOT_0_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd10;
     PLOT_0_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd11;
     PLOT_0_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd12;
     PLOT_0_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd13;
     PLOT_0_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd14;
     PLOT_0_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd0;
	y_offset = 2'd15;
     PLOT_1_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd0;
     PLOT_1_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd1;
     PLOT_1_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd2;
     PLOT_1_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd3;
     PLOT_1_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd4;
     PLOT_1_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd5;
     PLOT_1_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd6;
     PLOT_1_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd7;
     PLOT_1_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd8;
     PLOT_1_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd9;
     PLOT_1_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd10;
     PLOT_1_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd11;
     PLOT_1_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd12;
     PLOT_1_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd13;
     PLOT_1_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd14;
     PLOT_1_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd1;
	y_offset = 2'd15;
     PLOT_2_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd0;
     PLOT_2_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd1;
     PLOT_2_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd2;
     PLOT_2_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd3;
     PLOT_2_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd4;
     PLOT_2_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd5;
     PLOT_2_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd6;
     PLOT_2_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd7;
     PLOT_2_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd8;
     PLOT_2_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd9;
     PLOT_2_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd10;
     PLOT_2_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd11;
     PLOT_2_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd12;
     PLOT_2_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd13;
     PLOT_2_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd14;
     PLOT_2_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd2;
	y_offset = 2'd15;
     PLOT_3_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd0;
     PLOT_3_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd1;
     PLOT_3_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd2;
     PLOT_3_3: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd3;
     PLOT_3_4: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd4;
     PLOT_3_5: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd5;
     PLOT_3_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd6;
     PLOT_3_7: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd7;
     PLOT_3_8: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd8;
     PLOT_3_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd9;
     PLOT_3_10: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd10;
     PLOT_3_11: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd11;
     PLOT_3_12: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd12;
     PLOT_3_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd13;
     PLOT_3_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd14;
     PLOT_3_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd3;
	y_offset = 2'd15;
     PLOT_4_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd0;
     PLOT_4_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd1;
     PLOT_4_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd2;
     PLOT_4_3: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd3;
     PLOT_4_4: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd4;
     PLOT_4_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd5;
     PLOT_4_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd6;
     PLOT_4_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd7;
     PLOT_4_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd8;
     PLOT_4_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd9;
     PLOT_4_10: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd10;
     PLOT_4_11: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd11;
     PLOT_4_12: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd12;
     PLOT_4_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd13;
     PLOT_4_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd14;
     PLOT_4_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd4;
	y_offset = 2'd15;
     PLOT_5_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd0;
     PLOT_5_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd1;
     PLOT_5_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd2;
     PLOT_5_3: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd3;
     PLOT_5_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd4;
     PLOT_5_5: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd5;
     PLOT_5_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd6;
     PLOT_5_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd7;
     PLOT_5_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd8;
     PLOT_5_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd9;
     PLOT_5_10: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd10;
     PLOT_5_11: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd11;
     PLOT_5_12: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd12;
     PLOT_5_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd13;
     PLOT_5_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd14;
     PLOT_5_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd5;
	y_offset = 2'd15;
     PLOT_6_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd0;
     PLOT_6_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd1;
     PLOT_6_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd2;
     PLOT_6_3: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd3;
     PLOT_6_4: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd4;
     PLOT_6_5: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd5;
     PLOT_6_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd6;
     PLOT_6_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd7;
     PLOT_6_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd8;
     PLOT_6_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd9;
     PLOT_6_10: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd10;
     PLOT_6_11: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd11;
     PLOT_6_12: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd12;
     PLOT_6_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd13;
     PLOT_6_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd14;
     PLOT_6_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd6;
	y_offset = 2'd15;
     PLOT_7_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd0;
     PLOT_7_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd1;
     PLOT_7_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd2;
     PLOT_7_3: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd3;
     PLOT_7_4: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd4;
     PLOT_7_5: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd5;
     PLOT_7_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd6;
     PLOT_7_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd7;
     PLOT_7_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd8;
     PLOT_7_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd9;
     PLOT_7_10: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd10;
     PLOT_7_11: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd11;
     PLOT_7_12: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd12;
     PLOT_7_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd13;
     PLOT_7_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd14;
     PLOT_7_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd7;
	y_offset = 2'd15;
     PLOT_8_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd0;
     PLOT_8_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd1;
     PLOT_8_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd2;
     PLOT_8_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd3;
     PLOT_8_4: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd4;
     PLOT_8_5: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd5;
     PLOT_8_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd6;
     PLOT_8_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd7;
     PLOT_8_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd8;
     PLOT_8_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd9;
     PLOT_8_10: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd10;
     PLOT_8_11: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd11;
     PLOT_8_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd12;
     PLOT_8_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd13;
     PLOT_8_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd14;
     PLOT_8_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd8;
	y_offset = 2'd15;
     PLOT_9_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd0;
     PLOT_9_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd1;
     PLOT_9_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd2;
     PLOT_9_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd3;
     PLOT_9_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd4;
     PLOT_9_5: begin
	 colour = 3'b101;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd5;
     PLOT_9_6: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd6;
     PLOT_9_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd7;
     PLOT_9_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd8;
     PLOT_9_9: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd9;
     PLOT_9_10: begin
	 colour = 3'b101;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd10;
     PLOT_9_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd11;
     PLOT_9_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd12;
     PLOT_9_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd13;
     PLOT_9_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd14;
     PLOT_9_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd9;
	y_offset = 2'd15;
     PLOT_10_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd0;
     PLOT_10_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd1;
     PLOT_10_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd2;
     PLOT_10_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd3;
     PLOT_10_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd4;
     PLOT_10_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd5;
     PLOT_10_6: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd6;
     PLOT_10_7: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd7;
     PLOT_10_8: begin
	 colour = 3'b100;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd8;
     PLOT_10_9: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd9;
     PLOT_10_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd10;
     PLOT_10_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd11;
     PLOT_10_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd12;
     PLOT_10_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd13;
     PLOT_10_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd14;
     PLOT_10_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd10;
	y_offset = 2'd15;
     PLOT_11_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd0;
     PLOT_11_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd1;
     PLOT_11_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd2;
     PLOT_11_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd3;
     PLOT_11_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd4;
     PLOT_11_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd5;
     PLOT_11_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd6;
     PLOT_11_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd7;
     PLOT_11_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd8;
     PLOT_11_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd9;
     PLOT_11_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd10;
     PLOT_11_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd11;
     PLOT_11_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd12;
     PLOT_11_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd13;
     PLOT_11_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd14;
     PLOT_11_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd11;
	y_offset = 2'd15;
     PLOT_12_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd0;
     PLOT_12_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd1;
     PLOT_12_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd2;
     PLOT_12_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd3;
     PLOT_12_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd4;
     PLOT_12_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd5;
     PLOT_12_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd6;
     PLOT_12_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd7;
     PLOT_12_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd8;
     PLOT_12_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd9;
     PLOT_12_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd10;
     PLOT_12_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd11;
     PLOT_12_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd12;
     PLOT_12_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd13;
     PLOT_12_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd14;
     PLOT_12_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd12;
	y_offset = 2'd15;
     PLOT_13_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd0;
     PLOT_13_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd1;
     PLOT_13_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd2;
     PLOT_13_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd3;
     PLOT_13_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd4;
     PLOT_13_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd5;
     PLOT_13_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd6;
     PLOT_13_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd7;
     PLOT_13_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd8;
     PLOT_13_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd9;
     PLOT_13_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd10;
     PLOT_13_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd11;
     PLOT_13_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd12;
     PLOT_13_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd13;
     PLOT_13_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd14;
     PLOT_13_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd13;
	y_offset = 2'd15;
     PLOT_14_0: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd0;
     PLOT_14_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd1;
     PLOT_14_2: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd2;
     PLOT_14_3: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd3;
     PLOT_14_4: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd4;
     PLOT_14_5: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd5;
     PLOT_14_6: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd6;
     PLOT_14_7: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd7;
     PLOT_14_8: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd8;
     PLOT_14_9: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd9;
     PLOT_14_10: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd10;
     PLOT_14_11: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd11;
     PLOT_14_12: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd12;
     PLOT_14_13: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd13;
     PLOT_14_14: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd14;
     PLOT_14_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd14;
	y_offset = 2'd15;
     PLOT_15_0: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd0;
     PLOT_15_1: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd1;
     PLOT_15_2: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd2;
     PLOT_15_3: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd3;
     PLOT_15_4: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd4;
     PLOT_15_5: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd5;
     PLOT_15_6: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd6;
     PLOT_15_7: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd7;
     PLOT_15_8: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd8;
     PLOT_15_9: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd9;
     PLOT_15_10: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd10;
     PLOT_15_11: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd11;
     PLOT_15_12: begin
	 colour = 3'b001;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd12;
     PLOT_15_13: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd13;
     PLOT_15_14: begin
	 colour = 3'b000;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd14;
     PLOT_15_15: begin
	 colour = 3'b111;
 	 plot = 1'b1;
	x_offset = 2'd15;
	y_offset = 2'd15;
   endcase
end
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
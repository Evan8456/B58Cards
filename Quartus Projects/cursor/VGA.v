// Part 2 skeleton

module vga(
    CLOCK_50,				//	On Board 50 MHz
    // Your inputs and outputs here
    KEY,
    SW,
    // The ports below are for the VGA output.  Do not change.
    VGA_CLK,   				//	VGA Clock
    VGA_HS,					//	VGA H_SYNC
    VGA_VS,					//	VGA V_SYNC
    VGA_BLANK_N,			//	VGA BLANK
    VGA_SYNC_N,				//	VGA SYNC
    VGA_R,   				//	VGA Red[9:0]
    VGA_G,	 				//	VGA Green[9:0]
    VGA_B,   				//	VGA Blue[9:0]
    HEX7,
    HEX6,
    HEX5,
    HEX4,
    HEX3,
    LEDR
	);

	input	CLOCK_50;		//	50 MHz
	input   [11:0]   SW;
	input   [3:0]   KEY;
	output  [17:0] LEDR;

	wire resetn, load_x, go;
	wire [9:0] data_in;
	/**assign resetn = SW[10];
	assign load_x = ~KEY[3];
	assign go = ~KEY[2];
	assign data_in = SW[9:0];*/
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output	VGA_CLK;   				//	VGA Clock
	output	VGA_HS;					//	VGA H_SYNC
	output	VGA_VS;					//	VGA V_SYNC
	output	VGA_BLANK_N;				//	VGA BLANK
	output	VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   			//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 			//	VGA Green[9:0]
	output	[9:0]	VGA_B;  			//	VGA Blue[9:0]
	
	output [6:0] HEX7;
	output [6:0] HEX6;
	output [6:0] HEX5;
	output [6:0] HEX4;
	output [6:0] HEX3;
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour[2:0]),
			.x(x[7:0]),
			.y(y[6:0]),
			.plot(plot),
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
	
	
	wire LdX, LdY, LdC, plot;
	wire CtrEN, CtrReset;
	wire [3:0] CtrOut;

    // Instansiate datapath
	datapath d0(.data_in(SW[9:0]),
        .LdX(LdX),
        .LdY(LdY),
        .LdC(LdC),

        .plot(plot),

        .Ctr(CtrOut[3:0]),

        .resetN(resetn),
        .clock(CLOCK_50),

        .X_out(x[7:0]),
        .Y_out(y[6:0]),
        .C_out(colour[2:0])
	);

    // Instansiate FSM control
	control c0(.go(go),
        .resetN(resetn),
        .LoadX(load_x),
        .clock(CLOCK_50),
        .Ctr(CtrOut[3:0]),
					
        .CtrEN(CtrEN),
        .CtrReset(CtrReset),
					
        .LdX(LdX),
        .LdY(LdY),
        .LdC(LdC),

        .plot(plot),

        .current_state(LEDR[7:4]),
        .next_state(LEDR[3:0])
   );

	Counter ctr(.enable(CtrEN),
					.clock(CLOCK_50),
					.clear_b(CtrReset),
					.Q(CtrOut[3:0])
	);

	HexDecoder hexX1(.IN(x[7:4]),
					.OUT(HEX7[6:0])
	);
	 
	HexDecoder hexX2(.IN(x[3:0]),
					.OUT(HEX6[6:0])
	);
	 
	HexDecoder hexY1(.IN(y[6:4]),
					.OUT(HEX5[6:0])
	);
	 
	HexDecoder hexY2(.IN(y[3:0]),
					.OUT(HEX4[6:0])
	);
	 
	HexDecoder hexColour(.IN(colour[2:0]),
					.OUT(HEX3[6:0])
	);
endmodule

module datapath(data_in, LdX, LdY, LdC, plot, Ctr, resetN, clock, X_out, Y_out, C_out);

	input [9:0] data_in;
	input LdX, LdY, LdC; // Signal to load X, Y, C, into RegX, RegY, RegC
	input plot;		// Signal to output to X_out, Y_out, C_out from RegX, RegY, RegC

	input [3:0] Ctr;

	input resetN;
	input clock;

	output reg [7:0] X_out;
	output reg [6:0] Y_out;
	output reg [2:0] C_out;

	reg [6:0] RegX, RegY;
	reg [2:0] RegC;
	
	always @ (posedge clock) begin
		if (!resetN) begin
			RegX <= 8'b0;
			RegY <= 8'b0;
			RegC <= 8'b0;
		end else begin
			if (LdX == 1'b1)
				RegX <= data_in[6:0];
			if (LdY == 1'b1)
				RegY <= data_in[6:0];
			if (LdC == 1'b1)
				RegC <= data_in[9:7];
		end
	end
	
	// Output to out register
   always@(posedge clock) begin
		if(!resetN) begin
			X_out <= 8'b0;
			Y_out <= 7'b0;
			C_out <= 3'b0;
		end else if(plot) begin
			X_out <= RegX + Ctr[1:0];
			Y_out <= RegY + Ctr[3:2];
			C_out <= RegC;
		end
	end
endmodule

module control(go, resetN, LoadX, clock, Ctr, CtrEN, CtrReset, LdX, LdY, LdC, LdR, plot, current_state, next_state);
    input go;
    input resetN;
    input LoadX;
    input clock;
    input [3:0] Ctr;

    output reg CtrEN, CtrReset;
    output reg LdX, LdY, LdC;
    output reg plot;
	 
	 
	 output reg [4:0] current_state, next_state;

    localparam
        NO_DRAW      = 4'd0,
        LOAD_X       = 4'd1,
        LOAD_X_WAIT  = 4'd2,
        LOAD_Y       = 4'd3,
        LOAD_Y_WAIT  = 4'd4,
        LOAD_C       = 4'd5,
        LOAD_C_WAIT	 = 4'd6,
        DRAW         = 4'd7,
        CTREN        = 4'd8,
        CTRRESET     = 4'd9;

    always @(*)
    begin
        case (current_state)
            NO_DRAW: begin
                if (go == 1'b1)			// Load Y then C, then draw
                    next_state = LOAD_Y;
                else if (LoadX == 1'b1) // Load X then back to no draw
                    next_state = LOAD_X;
                else
                    next_state = NO_DRAW;// Stay in no draw
            end
            LOAD_X:			next_state = LoadX ? LOAD_X_WAIT : LOAD_X;
            LOAD_X_WAIT:	next_state = LoadX ? LOAD_X_WAIT : NO_DRAW;

            LOAD_Y:			next_state = go ? LOAD_Y_WAIT : LOAD_Y;
            LOAD_Y_WAIT:	next_state = go ? LOAD_C : LOAD_Y_WAIT;

            LOAD_C:			next_state = go ? LOAD_C_WAIT : LOAD_C;
            LOAD_C_WAIT:	next_state = go ? LOAD_C_WAIT : DRAW;
				
            DRAW:	begin
                if (Ctr[3:0] == 4'b1111)
                    next_state = CTRRESET;
                else
                    next_state = CTREN;
            end
            CTREN: 			next_state = DRAW;
            CTRRESET:		next_state = NO_DRAW;
            default:        next_state = NO_DRAW;
       endcase
    end

    always @(*)
    begin
        CtrEN = 1'b0;
        CtrReset = 1'b1;
        LdX = 1'b0;
        LdY = 1'b0;
        LdC = 1'b0;
        plot = 1'b0;

        case (current_state)
            LOAD_X: LdX = 1'b1;
            LOAD_Y:	LdY = 1'b1;
            LOAD_C: LdC = 1'b1;
            DRAW: begin
                plot = 1'b1;
            end
            CTREN: 	 CtrEN = 1'b1;
            CTRRESET: begin
                plot = 1'b1;
                CtrReset = 1'b0;
            end
        endcase
    end

    // current_state registers
    always @(posedge clock) begin
		if(!resetN)
			current_state <= NO_DRAW;
		else
			current_state <= next_state;
		end
endmodule : control

module Counter(enable, clock, clear_b, Q);
	input enable;
	input clock;
	input clear_b;
	output [3:0] Q;

	TFlipFlop FF0(
		.t(enable),
		.q(Q[0]),
		.clock(clock),
		.resetN(clear_b)
	);

	TFlipFlop FF1(
		.t(Q[0] & enable),
		.q(Q[1]),
		.clock(clock),
		.resetN(clear_b)
	);
	
	TFlipFlop FF2(
		.t(Q[1] & Q[0] & enable),
		.q(Q[2]),
		.clock(clock),
		.resetN(clear_b)
	);
	
	TFlipFlop FF3(
		.t(Q[2] & Q[1] & Q[0] & enable),
		.q(Q[3]),
		.clock(clock),
		.resetN(clear_b)
	);
endmodule

module TFlipFlop(t, q, clock, resetN);
	input t;
	input clock;
	input resetN;
	output reg q;
	always @ (posedge clock, negedge resetN)
	begin
		if (resetN == 1'b0)
			q <= 0;
		else if (t == 1'b1)
			q <= 1'b1 - q;
	end
endmodule

module HexDecoder(IN, OUT);
    input [3:0] IN;
    output reg [6:0] OUT;

    always @(*)
        case (IN)
            4'h0: OUT = 7'b100_0000;
            4'h1: OUT = 7'b111_1001;
            4'h2: OUT = 7'b010_0100;
            4'h3: OUT = 7'b011_0000;
            4'h4: OUT = 7'b001_1001;
            4'h5: OUT = 7'b001_0010;
            4'h6: OUT = 7'b000_0010;
            4'h7: OUT = 7'b111_1000;
            4'h8: OUT = 7'b000_0000;
            4'h9: OUT = 7'b001_1000;
            4'hA: OUT = 7'b000_1000;
            4'hB: OUT = 7'b000_0011;
            4'hC: OUT = 7'b100_0110;
            4'hD: OUT = 7'b010_0001;
            4'hE: OUT = 7'b000_0110;
            4'hF: OUT = 7'b000_1110;
            default: OUT = 7'h7f;
        endcase
endmodule

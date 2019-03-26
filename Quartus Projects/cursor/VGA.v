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

	/**assign resetn = SW[10];
	assign load_x = ~KEY[3];
	assign go = ~KEY[2];
	assign data_in = SW[9:0];*/
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output	VGA_CLK;   				    //	VGA Clock
	output	VGA_HS;					    //	VGA H_SYNC
	output	VGA_VS;					    //	VGA V_SYNC
	output	VGA_BLANK_N;				//	VGA BLANK
	output	VGA_SYNC_N;				    //	VGA SYNC
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
			.resetn(resetN),
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

    wire [7:0] xIn;
    wire [6:0] yIn;
    wire [2:0] cIn;
    wire resetN, go;
	wire ldP, plot;

    // Instansiate datapath
	datapath d0(
        .resetN(resetN),
        .clock(CLOCK_50),

        .xIn(xIn),              // 8 bit x location data
        .yIn(yIn),              // 7 bit y location data
        .cIn(cIn),              // 3 bit colour data

        .ldP(ldP),              // FSM Signal to load in the pixel data
        .plot(plot),		    // FSM Signal to output to X_out, Y_out, C_out from RegX, RegY, RegC

        .xOut(x[7:0]),          // x output to VGA
        .yOut(y[6:0]),          // y output to VGA
        .cOut(colour[2:0])      // colour output to VGA
        );

    // Instansiate FSM control
	control c0(
        .resetN(resetN),        // Resets the states
        .clock(CLOCK_50),       // FSM clock
        .go(go),                // Begins FSM cycle

        .ldP(ldP),              // Signal to load in pixel data
        .plot(plot)             // Signal to output the current pixel and draw on the VGA monitor
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

module datapath(
    input resetN,
    input clock,

    input [7:0] xIn,                // 8 bit x location input
    input [6:0] yIn,                // 7 bit y location input
	input [2:0] cIn,                // 3 bit colour input
	input ldP,                      // Signal to load in data input from xIn, yIn, cIn
	input plot,		                // Signal to output from RegX, RegY, RegC

	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut
    );

    reg [6:0] RegX, RegY;           // Stores the location of the top left pixel of the image
    reg [2:0] RegC;                 // Stores the curent color of the pixel

	always @ (posedge clock) begin
		if (!resetN) begin
			RegX <= 8'b0;
			RegY <= 8'b0;
			RegC <= 8'b0;
		end else begin
			if (ldP == 1'b1)        // Load in the current pixel data
				RegX <= xIn[7:0];
				RegY <= yIn[6:0];
				RegC <= cIn[2:0];
		end
	end
	
	// Output to out register
   always@(posedge clock) begin
		if(!resetN) begin
			xOut <= 8'b0;
			yOut <= 7'b0;
			cOut <= 3'b0;
		end else if(plot) begin     // Output the pixel data to VGA
			xOut <= RegX;
			yOut <= RegY;
			cOut <= RegC;
		end
	end
endmodule

module control(
    input resetN,               // Resets the states
    input clock,                // FSM clock
    input go,                   // Begins FSM cycle

    output reg ldP,             // Signal to load pixel data into registers
    output reg plot             // Signal to output the current pixel and draw on the VGA monitor
    );

    reg [4:0] current_state, next_state;

    localparam
        NO_DRAW     = 4'd0,
        LOAD_PIXEL  = 4'd1,
        DRAW        = 4'd2;

    always @(*)
    begin
        case (current_state)
            NO_DRAW: begin      // Loop in NO_DRAW until signal to start
                if (go == 1'b1)
                    LOAD_PIXEL;
                else
                    next_state = NO_DRAW;
                end
            LOAD_PIXEL: next_state = DRAW;
            DRAW: next_state = NO_DRAW;
            default: next_state = NO_DRAW;
       endcase
    end

    always @(*)
    begin
        ldP = 1'b0;
        plot = 1'b0;

        case (current_state)
            LOAD_PIXEL: ldP = 1'b1;
            DRAW: plot = 1'b1;
        endcase
    end

    // current_state registers
    always @(posedge clock) begin
		if(!resetN)
			current_state <= NO_DRAW;
		else
			current_state <= next_state;
		end
endmodule

module Counter(
    input enable,
    input clock,
    input resetN,
    input [7:0] max,
    output reg [7:0] Q
    );

    always @(posedge clock) begin
        if (!resetN)
            Q <= 8'b0;
        else if (counter < max)
            Q <= enable ? counter + 1 : counter;
        else
            Q <= 8'b0;
    end
endmodule

module TFlipFlop(t, q, clock, resetN);
	input t;
	input clock;
	input resetN;
	output reg q;
	always @ (posedge clock, negedge resetN) begin
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
endmodule : HexDecoder

module drawCard(
    input [7:0]x,
    input [6:0]y,
    input clock,
    input resetN
    );

    parameter XSize = 1;
    parameter YSize = 1;

    wire xCtr, yCtr;

    Counter xCtr(
        .enable(),
        .clock(clock),
        .resetN(resetN),
        .max(XSize),
        .Q(xCtr)
    );

    Counter yCtr(
        .enable(),
        .clock(clock),
        .resetN(resetN),
        .max(YSize),
        .Q(yCtr)
    );
endmodule

module drawSuit();

endmodule

module drawNumber();

endmodule
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
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour[2:0]),
			.x(x[7:0]),
			.y(y[6:0]),
			.plot(Plot),
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
	
	
	wire LdX, LdY, LdImg, ReadC, Plot;
	wire CtrEN, CtrRE, CtrMAX, CtrOF;
	wire [7:0] CtrOut;

    // Instansiate datapath
	datapath d0(
        .resetN(resetn),
        .clock(CLOCK_50),

        .dataIn(SW[9:0]),       // Data reg that stores 3 colors bits [9:7] and 7 location bits [6:0]
        .imageIn(),             // Load in image by rows
        .ctr(CtrOut[7:0]),      // 8 bit counter
        .ldX(LdX),
        .ldY(LdY),
        .ldImg(LdImg),          // Signal to load X, Y into RegX, RegY
        .readC(ReadC),          // Read color from the current pixel of the image into RegC
        .plot(Plot),		    // Signal to output to X_out, Y_out, C_out from RegX, RegY, RegC
        .xToVGA(x[7:0]),
        .yToVGA(y[6:0]),
        .cToVGA(c[2:0]),
        );

    // Instansiate FSM control
	control c0(

        .resetN(resetn),        // Resets the states
        .clock(CLOCK_50),       // FSM clock
        .ctrOF(CtrOF),          // Signal that the counter has overflowed
        .go(go),                // Begins FSM cycle

        .ldX(LdX),
        .ldY(LdY),              // Signal to load x and y into registers
        .ldImg(LdImg),          // Signal to load the current image into the register
        .readC(ReadC),          // Signal to read the color from the image for the current image
        .ctrEN(CtrEN),
        .ctrRE(CtrRE),          // Signal to increment the counter and reset
        .ctrMAX(CtrMAX),        // Signal for ctr to load in a max value
        .plot(Plot)             // Signal to output the current pixel and draw on the VGA monitor
   );

	Counter ctr(
        .enable(CtrEN),
        .clock(CLOCK_50),
        .resetN(CtrRE),
        .inputMax(),
        .ctrMAX(CtrMAX),
        .Q(CtrOut[7:0]),
        .ctrOF(CtrOF)
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

	input [9:0] dataIn,            // Data reg that stores 3 colors bits [9:7] and 7 location bits [6:0]
    input [159:0] imageIn[2:0],   // Load in image by rows
    input [7:0] rowSize,            // Size of the row
    input [7:0] ctr,                // 8 bit counter
	input ldX, ldY, ldImg,          // Signal to load X, Y into RegX, RegY
    input readC,                    // Read color from the current pixel of the image into RegC
	input plot,		                // Signal to output to X_out, Y_out, C_out from RegX, RegY, RegC

	output reg [7:0] xToVGA,
	output reg [6:0] yToVGA,
	output reg [2:0] cToVGA
    );

    reg [6:0] RegX, RegY;           // Stores the location of the top left pixel of the image
    reg [2:0] RegC;                 // Stores the curent color of the pixel
    reg [7:0] RegImg [2:0];         // Stores the current image (may be a row of the image or full image)
    reg [7:0] RegSize;


	always @ (posedge clock) begin
		if (!resetN) begin
			RegX <= 8'b0;
			RegY <= 8'b0;
			RegC <= 8'b0;
            RegImg <= 8'b0;
		end else begin
			if (ldX == 1'b1)        // Load in the x location of the top left pixel
				RegX <= dataIn[6:0];
			if (ldY == 1'b1)        // Load in the y location of the top left pixel
				RegY <= dataIn[6:0];
			if (LdC == 1'b1)        // Load in the current color to draw
				RegC <= RegImg[ctr][2:0];
            if (ldImg == 1'b1)      // Load in the image row
                RegImg <= imageIn;
                RegSize <= rowSize[7:0];
		end
	end
	
	// Output to out register
   always@(posedge clock) begin
		if(!resetN) begin
			xToVGA <= 8'b0;
			yToVGA <= 7'b0;
			cToVGA <= 3'b0;
		end else if(plot) begin
			xToVGA <= RegX + ctr[7:0];
			yToVGA <= RegY;
			cToVGA <= RegC;
		end
	end
endmodule

module control(
    input resetN,               // Resets the states
    input clock,                // FSM clock
    input ctrOF,                // Signal that the counter has overflowed
    input go,                   // Begins FSM cycle

    output reg ldX, ldY,        // Signal to load x and y into registers
    output reg ldImg,           // Signal to load the current image into the register
    output reg readC,           // Signal to read the color from the image for the current image
    output reg ctrEN, ctrRE,    // Signal to increment the counter and reset
    output reg ctrMAX,          // Signal for ctr to load in a max value
    output reg plot             // Signal to output the current pixel and draw on the VGA monitor
    );

    reg [4:0] current_state, next_state;

    localparam
        NO_DRAW     = 4'd0,
        LOAD_X      = 4'd1,
        LOAD_Y      = 4'd2,
        LOAD_IMG    = 4'd3,
        READ_C      = 4'd4,
        DRAW        = 4'd5,
        CTREN       = 4'd6,
        CTRRESET    = 4'd7;

    always @(*)
    begin
        case (current_state)
            NO_DRAW: begin  // Loop in NO_DRAW until signal to start
                if (go == 1'b1)
                    next_state = LOAD_X;
                else
                    next_state = NO_DRAW;
                end
            LOAD_X: next_state = LOAD_Y;                    // Load in the left x coordinate of the image
            LOAD_Y: next_state = LOAD_IMG;                  // Load in the top y coordinate of the image
            LOAD_IMG: next_state = READ_C;                  // Load in the image row into registers
            READ_C: next_state = DRAW;                      // Read the color for the current pixel
            DRAW: next_state = CTREN;                       // Draw the pixel on the VGA
            CTREN: next_state = ctrOF ? CTRRESET : READ_C;  // Increment the counter
            CTRRESET: next_state = NO_DRAW;                 // Reset the counter and finish drawing
            default: next_state = NO_DRAW;
       endcase
    end

    always @(*)
    begin
        ldX = 1'b0;
        ldY = 1'b0;
        ldImg = 1'b0;
        readC = 1'b0;
        ctrEN = 1'b0;
        ctrRE = 1'b1;
        ctrMAX = 1'b0;
        plot = 1'b0;

        case (current_state)
            LOAD_X:     ldX = 1'b1;
            LOAD_Y: 	ldY = 1'b1;
            LOAD_IMG: begin
                LdIMG = 1'b1;
                ctrMAX = 1'b1;
            end
            READ_C:     readC = 1'b1;
            DRAW:       plot = 1'b1;
            CTREN: 	    ctrEN = 1'b1;
            CTRRESET: begin
                ctrRE = 1'b0;
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
endmodule

module Counter(
    input enable,
    input clock,
    input resetN,
    input [7:0] inputMax,
    input ctrMAX,
    output reg [7:0] Q,
    output ctrOF
    );

    reg [7:0] max, ctr;

    always@(*) begin
        if (ctrMAX) begin
            ctr <= 8'b0;
            max <= inputMax[7:0];
        end
        if (ctr < max)
            ctr <= enable ? ctr + 1 : ctr;
        else begin
            ctr <= 8'b0;
            ctrOF <= 1'b0;
        end
    end

    always @(posedge clock) begin
        overflow <= 1'b0;
        if (!resetN)
            counter <= 8'b0;
        else
            counter <= enable ? counter + 1 : counter;
    end

    always @(posedge clock) begin
        if (!resetN)
            Q <= 8'b0;
        else
            Q <= counter;

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
endmodule

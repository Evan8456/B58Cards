// Part 2 skeleton

module cursor(
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
	input   [17:0]   SW;
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
	wire plot;
   wire resetN;
	assign resetN = SW[16];

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
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	
	
	wire loadNumSuit, drawBlank, drawNum, drawSuit;
	wire blankDone, numDone, suitDone;
	
	drawCard DC(
		.resetN(resetN),
		.clock(CLOCK_50),

		.xIn(8'd30),                // 8 bit x location input
		.yIn(7'd10),                // 7 bit y location input
	
		.loadNumSuit(loadNumSuit),
		.drawBlank(drawBlank),
		.drawNum(drawNum),
		.drawSuit(drawSuit),
	
		.cardNum(4'd2),
		.cardSuit(2'd4),

		.xOut(x[7:0]),
		.yOut(y[6:0]),
		.cOut(colour[2:0]),
	
		.blankDone(blankDone),
		.numDone(numDone),
		.suitDone(suitDone)
	);
		
	
	control FSM(
		.resetN(resetN),               // Resets the states
		.clock(CLOCK_50),                // FSM clock
		.go(SW[17]),                   // Begins FSM cycle
	 
		.blankDone(blankDone),
		.numDone(numDone),
		.suitDone(suitDone),

		.loadNumSuit(loadNumSuit),
		.drawBlank(drawBlank),
		.drawNum(drawNum),
		.drawSuit(drawSuit),
		.plot(plot)
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

module drawCard(
   input resetN,
   input clock,

   input [7:0] xIn,                // 8 bit x location input
   input [6:0] yIn,                // 7 bit y location input
	
	input loadNumSuit,
	input drawBlank,
	input drawNum,
	input drawSuit,
	
	input [3:0] cardNum,
	input [1:0] cardSuit,

	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut,
	
	output blankDone,
	output numDone,
	output suitDone
	);
	 
	wire [767:0] ace;
	wire [767:0] two;
	wire [767:0] three;
	wire [767:0] four;
	wire [767:0] five;
	wire [767:0] six;
	wire [767:0] seven;
	wire [767:0] eight;
	wire [767:0] nine;
	wire [767:0] ten;
	wire [767:0] jack;
	wire [767:0] queen;
	wire [767:0] king;
	
	wire [767:0] spade;
	wire [767:0] diamond;
	wire [767:0] club;
	wire [767:0] heart;
	assign two = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0FFFFFFFFFE071FFFFFFFFE3F1FFFFFFFFFF8FFFFFFFFFE00FFFFFFFFFE3FFFFFFFFFFE001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	assign heart = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF03003FFFFFF8000007FFFFF8000007FFFFF8000007FFFFF8000007FFFFFF00003FFFFFFFE001FFFFFFFFFC7FFFFFFFFFFFBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	
	reg [767:0] numDataReg, suitDataReg;
	reg [3:0] numReg;
	reg [1:0] suitReg;
	reg [7:0] xReg;
	reg [6:0] yReg;
	
	always@(posedge clock) begin
		if (!resetN) begin
			numReg <= 4'b0;
			suitReg <= 2'b0;
		end if(loadNumSuit) begin
			numReg <= cardNum;
			suitReg <= cardSuit;
		end
	end
	
	always@(posedge clock) begin
		case (numReg) 
			4'd1: numDataReg <= ace;
			4'd2: numDataReg <= two;
			4'd3: numDataReg <= three;
			4'd4: numDataReg <= four;
			4'd5: numDataReg <= five;
			4'd6: numDataReg <= six;
			4'd7: numDataReg <= seven;
			4'd8: numDataReg <= eight;
			4'd9: numDataReg <= nine;
			4'd10: numDataReg <= ten;
			4'd11: numDataReg <= jack;
			4'd12: numDataReg <= queen;
			4'd13: numDataReg <= king;
			default: numDataReg <= ace;
		endcase
		
		case (suitReg)
			2'd0: suitDataReg <= spade;
			2'd1: suitDataReg <= diamond;
			2'd2: suitDataReg <= club;
			2'd3: suitDataReg <= heart;
			default: suitDataReg <= spade;
		endcase
	end
	
	wire [7:0] blankOutX, numOutX, suitOutX;
	wire [6:0] blankOutY, numOutY, suitOutY;
	wire [2:0] blankOutC, numOutC, suitOutC;

	drawBlankCard blank(
		.resetN(resetN),
		.clock(clock),
		.x(xIn),
		.y(yIn),
		.xOut(blankOutX),
		.yOut(blankOutY),
		.cOut(blankOutC),
		.done(blankDone)
	
	);
	
	drawNum num(
		.resetN(resetN),
		.clock(clock),
		.x(xIn),
		.y(yIn),
		.in_data(numReg),
		.xOut(numOutX),
		.yOut(numOutY),
		.cOut(numOutC),
		.done(numDone)
	);
	
	
	drawNum suit(
		.resetN(resetN),
		.clock(clock),
		.x(xIn),
		.y(yIn+5'd16),
		.in_data(suitReg),
		.xOut(suitOutX),
		.yOut(suitOutY),
		.cOut(suitOutC),
		.done(suitDone)
	);
	
	// Output to out register
   always@(posedge clock) begin
		if(!resetN) begin
			xOut <= 8'b0;
			yOut <= 7'b0;
			cOut <= 3'b0;
		end else if(drawBlank) begin
			xOut <= blankOutX;
			yOut <= blankOutY;
			cOut <= blankOutC;
		end else if(drawNum) begin
			xOut <= numOutX;
			yOut <= numOutY;
			cOut <= numOutC;
		end else if(drawSuit) begin
			xOut <= suitOutX;
			yOut <= suitOutY;
			cOut <= suitOutC;
		end
	end
endmodule

module control(
    input resetN,               // Resets the states
    input clock,                // FSM clock
    input go,                   // Begins FSM cycle
	 
	 input blankDone,
	 input numDone,
	 input suitDone,

	 output reg drawBlank,
	 output reg drawNum,
	 output reg drawSuit,
	 output reg loadNumSuit,
    output reg plot            // Signal to output the current pixel and draw on the VGA monitor
    );

    reg [4:0] current_state, next_state;

    localparam
        NO_DRAW      = 4'd0,
		  LOAD_NUM_SUIT= 4'd1,
        DRAW_BLANK  	= 4'd2,
		  WAIT_BLANK  	= 4'd3,
		  DRAW_NUM	  	= 4'd4,
		  WAIT_NUM	  	= 4'd5,
		  DRAW_SUIT   	= 4'd6,
		  WAIT_SUIT	  	= 4'd7;
		  
    always @(*)
    begin
        case (current_state)
            NO_DRAW: begin      // Loop in NO_DRAW until signal to start
                if (go == 1'b1)
                    next_state = DRAW_BLANK;
                else
                    next_state = LOAD_NUM_SUIT;
                end
				LOAD_NUM_SUIT : next_state = DRAW_BLANK;
            DRAW_BLANK : next_state = WAIT_BLANK;
				WAIT_BLANK : next_state = blankDone ? DRAW_NUM : WAIT_BLANK;
				DRAW_NUM : next_state = WAIT_NUM;
				WAIT_NUM : next_state = numDone ? DRAW_SUIT : WAIT_NUM;
				DRAW_SUIT : next_state = WAIT_SUIT;
				WAIT_SUIT : next_state = suitDone ? NO_DRAW : WAIT_SUIT;
            default: next_state = NO_DRAW;
       endcase
    end

    always @(*)
    begin
		  loadNumSuit = 1'b0;
		  drawBlank = 1'b0;
		  drawNum = 1'b0;
		  drawSuit = 1'b0;
        plot = 1'b0;

        case (current_state)
				LOAD_NUM_SUIT: loadNumSuit = 1'b1;
            DRAW_BLANK: begin
					drawBlank = 1'b1;
					plot = 1'b1;
				end
				WAIT_BLANK: begin
					drawBlank = 1'b1;
					plot = 1'b1;
				end
				DRAW_NUM: begin
					drawNum = 1'b1;
					plot = 1'b1;
				end
				WAIT_NUM: begin
					drawNum = 1'b1;
					plot = 1'b1;
				end
				DRAW_SUIT: begin
					drawSuit = 1'b1;
					plot = 1'b1;
				end
				WAIT_SUIT: begin
					drawSuit = 1'b1;
					plot = 1'b1;
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
    input [7:0] max,
    output reg [7:0] Q
    );

    always @(posedge clock) begin
        if (!resetN)
            Q <= 8'b0;
        else if (Q < max)
            Q <= enable ? Q + 1 : Q;
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
endmodule

module drawBlankCard(
	input resetN,
	input clock,
	input [7:0] x,
	input [6:0] y,
	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut,
	output reg done
	);
	reg [7:0] xOffset;
	reg [6:0] yOffset;
	
	always@(posedge clock) begin
		if (!resetN) begin
			xOffset <= 8'b0;
			yOffset <= 7'b0;
			xOut <= 8'b0;
			yOut <= 7'b0;
			cOut <= 3'b0;
			done <= 1'b0;
		end else if (xOffset < 8'd23)
			xOffset <= xOffset + 1'b1;
		else if (yOffset < 8'd39) begin
			yOffset <= yOffset + 1'b1;
			xOffset <= 8'b0;
		end else
			done <= 1'b1;
		
		xOut <= x + xOffset;
		yOut <= y + yOffset;
		cOut <= 3'b111;
	end
endmodule

module drawNum(
	input resetN,
	input clock,
	input [7:0] x,
	input [6:0] y,
	input [767:0] in_data,
	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut,
	output reg done,
	output reg [767:0] data
	);
	reg [7:0] xOffset;
	reg [6:0] yOffset;
	
	always@(posedge clock) begin
		if (!resetN) begin
			xOffset <= 8'b0;
			yOffset <= 7'b0;
			xOut <= 8'b0;
			yOut <= 7'b0;
			data <= in_data;
			done <= 1'b0;
		end else if (xOffset < 8'd15) begin
			xOffset <= xOffset + 1'b1;
			data <= data << 3;
		end else if (yOffset < 8'd15) begin
			yOffset <= yOffset + 1'b1;
			xOffset <= 8'b0;
			data <= data << 3;
		end else
			done <= 1'b1;
		
		xOut <= x + xOffset;
		yOut <= y + yOffset;
		cOut <= data[767:765];
	end
endmodule

/**module drawCard2(
	input resetN,
	input clock,
	input [7:0] x,
	input [6:0] y,
	input [3:0] cardNum,
	input [1:0] cardSuit,
	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut,
	output done
	);	
	wire [767:0] ace;
	wire [767:0] two;
	assign two = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC0FFFFFFFFFE071FFFFFFFFE3F1FFFFFFFFFF8FFFFFFFFFE00FFFFFFFFFE3FFFFFFFFFFE001FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
	wire [767:0] three;
	wire [767:0] four;
	wire [767:0] five;
	wire [767:0] six;
	wire [767:0] seven;
	wire [767:0] eight;
	wire [767:0] nine;
	wire [767:0] ten;
	wire [767:0] jack;
	wire [767:0] queen;
	wire [767:0] king;
	
	wire [767:0] spade;
	wire [767:0] diamond;
	wire [767:0] club;
	wire [767:0] heart;
	assign heart = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF03003FFFFFF8000007FFFFF8000007FFFFF8000007FFFFF8000007FFFFFF00003FFFFFFFE001FFFFFFFFFC7FFFFFFFFFFFBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

	reg [767:0] num;
	reg [767:0] suit;
	reg [767:0] in_data;
	
	reg [7:0] x_loc;
	reg [6:0] y_loc;
	reg resetBG_n;
	reg resetNum_n;
	reg [1:0] current_state;
	
	wire mini_done;
	
	always@(posedge clock) begin
		case (cardNum)
			4'd1: num <= ace;
			4'd2: num <= two;
			4'd3: num <= three;
			4'd4: num <= four;
			4'd5: num <= five;
			4'd6: num <= six;
			4'd7: num <= seven;
			4'd8: num <= eight;
			4'd9: num <= nine;
			4'd10: num <= ten;
			4'd11: num <= jack;
			4'd12: num <= queen;
			4'd13: num <= king;
			default: num <= ace;
		endcase
		
		case (cardSuit)
			2'd0: suit <= spade;
			2'd1: suit <= diamond;
			2'd2: suit <= club;
			2'd3: suit <= heart;
			default: suit <= spade;
		endcase
		
		if(!resetN) begin
			resetBG_n <= 1;
			resetNum_n <= 1;
			current_state <= 0;
		end
	end
	
	drawNum dc(
		.resetN(resetNum_n),
		.clock(clock),
		.x(x),
		.y(7'd10),
		.in_data(in_data),
		.xOut(x[7:0]),
		.yOut(y[6:0]),
		.cOut(colour[2:0]),
		.done(mini_done),
		.data(data)
	);
		
	drawBlankCard bc(
		.resetN(resetBG_n),
		.clock(clock),
		.x(x),
		.y(y),
		.xOut(x[7:0]),
		.yOut(y[6:0]),
		.cOut(colour[2:0]),
		.done(mini_done),
		.data(data)
	);
endmodule**/

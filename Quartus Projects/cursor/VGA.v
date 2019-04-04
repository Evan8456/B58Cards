/*		 _______   _    _   _   _____        _   _____        _        _       __        _____     _
		|__   __| | |  | | | | |  ___|      | | |  ___|      | |      | |     /  \      |  _  \   | |
		   | |    | |__| | | | | |___       | | | |___       | |  __  | |    / /\ \     | |_|_/   | |
			| |	 |  __  | | | |____ |      | | |____ |      | | /  \ | |   / ____ \    |  _ \    |_|
			| |	 | |  | | | |  ___| |      | |  ___| |      | |/ /\ \| |  / /    \ \   | | \ \    _
			|_|    |_|  |_| |_| |_____|      |_| |_____|      |___/  \___| /_/      \_\  |_|  \_\  |_|
			
			                                      KAW!       ____
			      ____      /\                         \  __/ o  \
	  			  /    \     ||                _ _ _      /__     |        _ _ _
			  ___|    |___  ||                \\\\\\       |     |       //////
			  \__________/  ||                 \\\\\\     /       \     //////
				 | o  o |    ||                  \\\\\\   |\/ \/ \/ |   //////
				 |   -  |   / /                   \\\\\\  |  \/ \/  |  //////
				  \_  _/   / /                     \\\\\\ | \/ \/ \/| //////
				    ||____/ /                       \\\\\\|\/ \/ \/ |//////
					/  _____/                         ---------------------
				  //||                         
				  
*/
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
    HEX6,/*
    HEX5,
	 HEX4,
    HEX3,
    HEX2,
    HEX1,
    HEX0,*/
    	LEDR
	);

	input	CLOCK_50;		//	50 MHz
	input   [17:0]   SW;
	input   [3:0]   KEY;
	output  [17:0] LEDR;
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output	VGA_CLK;   		//	VGA Clock
	output	VGA_HS;			//	VGA H_SYNC
	output	VGA_VS;			//	VGA V_SYNC
	output	VGA_BLANK_N;	//	VGA BLANK
	output	VGA_SYNC_N;		//	VGA SYNC
	output	[9:0] VGA_R;  //	VGA Red[9:0]
	output	[9:0] VGA_G;	//	VGA Green[9:0]
	output	[9:0] VGA_B;  //	VGA Blue[9:0]
	
	output [6:0] HEX7;
	output [6:0] HEX6;/*
	output [6:0] HEX5;
	output [6:0] HEX4;
	output [6:0] HEX3;
	output [6:0] HEX2;
	output [6:0] HEX1;
	output [6:0] HEX0;*/
	
	wire [7:0] player_x_loc; // x location for drawing player card
	wire [7:0] player_y_loc; // y location for drawing player card
	wire [7:0] com_x_loc; // x location for drawing com card
	wire [7:0] com_y_loc; // y location for drawing com card
	assign player_x_loc = 8'd30;
	assign player_y_loc = 8'd70;
	assign com_x_loc = 8'd200;
	assign com_y_loc = 8'd70;
	
	reg [7:0] x_loc;
	reg [7:0] y_loc;
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire plot;
   wire resetN;
	wire vga_resetN;
	assign resetN = SW[0];
	assign vga_resetN = SW[16];
	wire go;
	assign go = SW[9];
	reg vga_go;

	reg [1:0] winner; // 0-no winner, 1-p1 wins, 2-p2 wins, 3-draw
	wire vga_done;
	
	reg [5:0] p1_card;
	reg [5:0] p2_card;
	
	reg [4:0] current_state, next_state;
	
	localparam
					GENERATE_SEED			= 5'd0,
					NEXT_INT_1				= 5'd1,
					DRAW_P1					= 5'd2,
					DRAW_P1_WAIT			= 5'd3,
					WAIT_USER				= 5'd4,
					WAIT_USER_2				= 5'd5,
					NEXT_INT_2				= 5'd6,
					DRAW_P2					= 5'd7,
					DRAW_P2_WAIT			= 5'd8,
					CALCULATE				= 5'd9,
					DRAW						= 5'd10;
	
	always @(posedge CLOCK_50) begin
		case(current_state)
			GENERATE_SEED: 		next_state = go ? NEXT_INT_1 : GENERATE_SEED;
			NEXT_INT_1: 			next_state = ~go ? DRAW_P1 : NEXT_INT_1;
			DRAW_P1: 				next_state = DRAW_P1_WAIT;
			DRAW_P1_WAIT:			next_state = vga_done ? WAIT_USER : DRAW_P1_WAIT;
			WAIT_USER:				next_state = go ? WAIT_USER_2 : WAIT_USER;
			WAIT_USER_2:			next_state = ~go ? NEXT_INT_2 : WAIT_USER_2;
			NEXT_INT_2: 			next_state = DRAW_P2;
			DRAW_P2: 				next_state = DRAW_P2_WAIT;
			DRAW_P2_WAIT:			next_state = vga_done ? CALCULATE : DRAW_P2_WAIT;
			CALCULATE:				begin
											if(winner == 2'd0)
												next_state = CALCULATE;
											else
												next_state = DRAW;
										end
			DRAW:						next_state = go ? NEXT_INT_1 : DRAW;
			default: next_state = GENERATE_SEED;
		endcase
	end
	
	always @(posedge CLOCK_50) begin
		//rng_counter <= 1'b0;
		next_int <= 1'b0;
		vga_go <= 1'b0;
		case(current_state)
			GENERATE_SEED: begin
				rng_counter <= 1'b1;
				winner <= 1'b0;
			end
			NEXT_INT_1: begin
				rng_counter <= 1'b0;
				next_int <= 1'b1;
			end
			DRAW_P1: begin
				vga_go <= 1'b1;
				x_loc <= player_x_loc;
				y_loc <= player_y_loc;
			end
			DRAW_P1_WAIT: begin
				p1_card <= {suit, number};
			end
			NEXT_INT_2: next_int <= 1'b1;
			DRAW_P2: begin
				vga_go <= 1'b1;
				x_loc <= com_x_loc;
				y_loc <= com_y_loc;
			end
			DRAW_P2_WAIT: begin
				p2_card <= {suit, number};
			end
			CALCULATE: begin
				// check winner
				if(p1_card[3:0] < p2_card[3:0])
					winner <= 2'd2;
				else if(p1_card[3:0] > p2_card[3:0])
					winner <= 2'd1;
				else
					winner <= 2'd3;
			end
			default: begin end
		endcase
	end

    // current_state registers
    always @(posedge CLOCK_50) begin
		if(!resetN)
			current_state <= GENERATE_SEED;
		else
			current_state <= next_state;
	end
			

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(vga_resetN),
			.clock(CLOCK_50),
			.colour(colour[2:0]),
			.x(x[7:0]),
			.y(y[6:0]),
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
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	
	
	wire loadNumSuit, drawBlank, drawNum, drawSuit;
	wire blankDone, numDone, suitDone;
	
	assign vga_done = temp_vga_done || SW[3];
	
	wire temp_vga_done;
	drawCard DC(
		.resetN(resetN),
		.clock(CLOCK_50),

		.xIn(x_loc),                // 8 bit x location input
		.yIn(y_loc),                // 7 bit y location input

		.loadNumSuit(loadNumSuit),	 // FSM signals
		.drawBlank(drawBlank),
		.drawNum(drawNum),
		.drawSuit(drawSuit),

		.cardNum(number),
		.cardSuit(suit),

		.xOut(x[7:0]),
		.yOut(y[6:0]),
		.cOut(colour[2:0]),
	
		.blankDone(blankDone),
		.numDone(numDone),
		.suitDone(temp_vga_done)
	);
		
	
	control FSM(
		.resetN(resetN),            // Resets the states
		.clock(CLOCK_50),           // FSM clock
		.go(vga_go),                    // Begins FSM cycle
	 
		.blankDone(blankDone),
		.numDone(numDone),
		.suitDone(vga_done),

		.loadNumSuit(loadNumSuit),
		.drawBlank(drawBlank),
		.drawNum(drawNum),
		.drawSuit(drawSuit),
		.plot(plot),
		
		.current_state(),
		.next_state()
	);
	/*
	HexDecoder hexX1(.IN(p1_card[3:0]),
					.OUT(HEX7[6:0])
	);
	 
	HexDecoder hexX2(.IN(p2_card[3:0]),
					.OUT(HEX6[6:0])
	);
	 
	HexDecoder hexY1(.IN(y[6:4]),
					.OUT(HEX5[6:0])
	);
	 
	HexDecoder hexY2(.IN(y[3:0]),
					.OUT(HEX4[6:0])
	);
	*/
	HexDecoder hex3(
		.IN(winner),
		.OUT(HEX6[6:0])
	);
	assign HEX7[6:0] = 7'b0001100;
	/*
	HexDecoder hex2(
		.IN(current_state),
		.OUT(HEX2[6:0])
	);
	HexDecoder hex1(
		.IN(next_state),
		.OUT(HEX1[6:0])
	);
	HexDecoder hex0(
		.IN(rand_int[3:0]),
		.OUT(HEX0[6:0])
	);
	*/
	wire [3:0] number = rand_int[5:2];
	wire [1:0] suit = rand_int[1:0];
	// rng and RAM wires
	wire [15:0] generatorSeed;
	wire [15:0] currentSeed;
	assign LEDR[15:0] = SW[12] ? currentSeed : generatorSeed; // 0 is generatorSeed, 1 is currentSeed
	wire [15:0] rand_int;
	reg rng_counter;
	reg next_int;

	randomSeedGenerator generator(
		.clock(CLOCK_50),
		.enable_count(rng_counter),
		.seed(generatorSeed)
	);
	// Decrease max with deck size
	RNG RNGmod(
		.clock(CLOCK_50),
		.LoadSeed(generatorSeed),
		.Load_n(1'b1),//load_seed
		.min_n(16'd4),
		.max_n(16'd56),
		.next_int(next_int),
		.rand_int(rand_int),
		.seed(currentSeed)
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
	
	reg [3:0] numReg;
	reg [1:0] suitReg;
	reg [7:0] xReg;
	reg [6:0] yReg;
	
	reg [767:0] numDataReg, suitDataReg;
	
	
	localparam
		ACE = 768'hFFFFFFFFFFFFFFFE00000FFFFFF03FFF81FFFF81FFFFF03FFF8FFFFFFE3FFF8FFFFFFE3FFF8FFFFFFE3FFF800000003FFF8FFFFFFE3FFF8FFFFFFE3FFF8FFFFFFE3FFF8FFFFFFE3FFF8FFFFFFE3FFF8FFFFFFE3FFF8FFFFFFE3FFFFFFFFFFFFF,
		TWO = 768'hFFFE0003FFFFFFF000007FFFFF803FE00FFFFF81FFFC0FFFFFFFFFFC0FFFFFFFFFFC0FFFFFFFFFE00FFFFFFFFF007FFFFFFFF803FFFFFFFFC01FFFFFFFFE00FFFFFFFFF007FFFFFFFF803FFFFFFFFF800000003FFF800000003FFFFFFFFFFFFF,
		THREE = 768'hFFFE00007FFFFFF000000FFFFF803FFC01FFFF81FFFF81FFFFFFFFFF81FFFFFFFFFC01FFFFFFFFE00FFFFFFFFF007FFFFFFFFFE00FFFFFFFFFFC01FFFFFFFFFF81FFFF81FFFF81FFFF803FFC01FFFFF000000FFFFFFE00007FFFFFFFFFFFFFFF,
		FOUR = 768'hFFFFFFE00FFFFFFFFF000FFFFFFFF8000FFFFFFFC01C0FFFFFFE00FC0FFFFFF007FC0FFFFF803FFC0FFFFC01FFFC0FFFE00FFFFC0FFFE0000000003FE0000000003FFFFFFFFC0FFFFFFFFFFC0FFFFFFFFFFC0FFFFFFFFFFC0FFFFFFFFFFC0FFF,
		FIVE = 768'hFC000000003FFC000000003FFC0FFFFFFFFFFC0FFFFFFFFFFC0FFFFFFFFFFC0E00007FFFFC0000000FFFFC01FFFC01FFFFFFFFFF803FFFFFFFFFF03FFC0FFFFFF03FFC01FFFFF03FFF803FFF803FFFF0000001FFFFFE00000FFFFFFFFFFFFFFF,
		SIX = 768'hFFFFFFFFFFFFFFFFF8007FFFFFFFC7FF8FFFFFFE3FFFF1FFFFFE3FFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF000007FFFFFF03FFF8FFFFFF1FFFFF1FFFFF1FFFFF1FFFFF1FFFFF1FFFFF1FFFFF1FFFFF1FFFFF1FFFFFE3FFF8FFFFFFFC0007FFF,
		SEVEN = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000FFFFFFFFFFF8FFFFFFFFFFF8FFFFFFFFFFC7FFFFFFFFFE3FFFFFFFFFF03FFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFFFFFFFF,
		EIGHT = 768'hFFFE00007FFFFFF000000FFFFF803FFC01FFFF81FFFF81FFFF81FFFF81FFFF803FFC01FFFFF007E00FFFFFFE00007FFFFFF007E00FFFFF803FFC01FFFF81FFFF81FFFF81FFFF81FFFF803FFC01FFFFF000000FFFFFFE00007FFFFFFFFFFFFFFF,
		NINE = 768'hFFFE0003FFFFFFF1FFFC7FFFFF8FFFFF8FFFFF8FFFFF8FFFFF8FFFFF8FFFFF8FFFFF8FFFFF8FFFFF8FFFFFF1FFFC0FFFFFFE00000FFFFFFFFFFF8FFFFFFFFFFF8FFFFFFFFFFC7FFFFF8FFFFC7FFFFFF1FFE3FFFFFFFE001FFFFFFFFFFFFFFFFF,
		TEN = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFC7FC0000FFFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7E3FFFF1FFFC7FC0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
		JACK = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFF0000001FFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFFFFFF1FFFFFFF8FFF1FFFFFFF81F81FFFFFFFF000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
		QUEEN = 768'hFFFE0003FFFFFF81FFFC0FFFFC7FFFFFF1FFE3FFFFFFFE3FE3FFFFFFFE3F1FFFFFFFFFC71FFFFFFFFFC71FFFFFFFFFC71FFFFFFFFFC71FFFFFFFFFC7E3FFFFFC7E3FE3FFFFFF8E3FFC7FFFFFF1FFFF81FFFC0E3FFFFE0003FFC7FFFFFFFFFFF8,
		KING = 768'hFF81FFFFFE07FF81FFFFF03FFF81FFFF81FFFF81FFFC0FFFFF81FFE07FFFFF81FF03FFFFFF81F81FFFFFFF8000FFFFFFFF81F81FFFFFFF81FF03FFFFFF81FFE07FFFFF81FFFC0FFFFF81FFFF81FFFF81FFFFF03FFF81FFFFFE07FF81FFFFFFC0,
		SPADE = 768'hFFFFF81FFFFFFFFFC003FFFFFFFE00007FFFFFF000000FFFFFF000000FFFFF80000001FFFF80000001FFFC000000003FFC000000003FE00000000007E00000000007E001F81F8007FC0FF81FF03FFFFFF81FFFFFFFFE00007FFFFFFFFFFFFFFF,
		DIAMOND = 768'hFFFFFCFFFFFFFFFFE49FFFFFFFFF2493FFFFFFF924927FFFFFF924927FFFFFC924924FFFFE49249249FFF2492492493FF2492492493FFE49249249FFFFC924924FFFFFF924927FFFFFF924927FFFFFFF2493FFFFFFFFE49FFFFFFFFFFCFFFFFF,
		CLUB = 768'hFFFFC01FFFFFFFFE0003FFFFFFF000007FFFFFF000007FFFFFFE0003FFFFFC0FC01F81FFE001C01C003F000000000007000000000007000000000007E001F8FC003FFC0FF8FF81FFFFFFF8FFFFFFFFFFC01FFFFFFFFE0003FFFFFFFFFFFFFFFF,
		HEART = 768'hFFFFFFFFFFFFFFFFFFFFFFFFFFC93FFE49FFFE4927F2493FF24924924927F24924924927F24924924927F24924924927FE492492493FFE492492493FFFC9249249FFFFF924924FFFFFFF24927FFFFFFFE493FFFFFFFFFC9FFFFFFFFFFFFFFFFF;

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
			4'd1: numDataReg <= ACE;
			4'd2: numDataReg <= TWO;
			4'd3: numDataReg <= THREE;
			4'd4: numDataReg <= FOUR;
			4'd5: numDataReg <= FIVE;
			4'd6: numDataReg <= SIX;
			4'd7: numDataReg <= SEVEN;
			4'd8: numDataReg <= EIGHT;
			4'd9: numDataReg <= NINE;
			4'd10: numDataReg <= TEN;
			4'd11: numDataReg <= JACK;
			4'd12: numDataReg <= QUEEN;
			4'd13: numDataReg <= KING;
			default: numDataReg <= 768'b0;
		endcase
		
		case (suitReg)
			2'd0: suitDataReg <= SPADE;
			2'd1: suitDataReg <= DIAMOND;
			2'd2: suitDataReg <= CLUB;
			2'd3: suitDataReg <= HEART;
			default: suitDataReg <= 768'b0;
		endcase
	end
	
	wire [7:0] blankOutX, numOutX, suitOutX;
	wire [6:0] blankOutY, numOutY, suitOutY;
	wire [2:0] blankOutC, numOutC, suitOutC;

	drawBlankCard blank(
		.resetN(resetN),
		.clock(clock),
		.start(drawBlank),
		.x(xIn),
		.y(yIn),
		.xOut(blankOutX),
		.yOut(blankOutY),
		.cOut(blankOutC),
		.done(blankDone)
	
	);
	
	drawNumSuit num(
		.resetN(resetN),
		.clock(clock),
		.start(drawNum),
		.x(xIn + 3'd4),
		.y(yIn + 2'd2),
		.data(numDataReg),
		.xOut(numOutX),
		.yOut(numOutY),
		.cOut(numOutC),
		.done(numDone)
	);
	
	drawNumSuit suit(
		.resetN(resetN),
		.clock(clock),
		.start(drawSuit),
		.x(xIn + 3'd4),
		.y(yIn + 5'd23),
		.data(suitDataReg),
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
   output reg plot,            	// Signal to output the current pixel and draw on the VGA monitor
	output reg [4:0] current_state, next_state
    );

    //reg [4:0] current_state, next_state;

    localparam
			NO_DRAW      	= 4'd0,
			NO_DRAW_TO_LOAD = 4'd8,
			LOAD_NUM_SUIT	= 4'd1,
			DRAW_BLANK  	= 4'd2,
			WAIT_BLANK  	= 4'd3,
			DRAW_NUM			= 4'd4,
			WAIT_NUM			= 4'd5,
			DRAW_SUIT		= 4'd6,
			WAIT_SUIT 		= 4'd7;

    always @(*)
    begin
        case (current_state)
            NO_DRAW 			: next_state = go ? NO_DRAW_TO_LOAD : NO_DRAW;
				NO_DRAW_TO_LOAD: next_state = ~go ? LOAD_NUM_SUIT : NO_DRAW_TO_LOAD;
				LOAD_NUM_SUIT 	: next_state = DRAW_BLANK;
            DRAW_BLANK 		: next_state = WAIT_BLANK;
				WAIT_BLANK		: next_state = blankDone ? DRAW_NUM : WAIT_BLANK;
				DRAW_NUM 		: next_state = WAIT_NUM;
				WAIT_NUM			: next_state = numDone ? DRAW_SUIT : WAIT_NUM;
				DRAW_SUIT 		: next_state = WAIT_SUIT;
				WAIT_SUIT		: next_state = suitDone ? NO_DRAW : WAIT_SUIT;
            default: next_state = NO_DRAW;
       endcase
    end

    always @(posedge clock)
    begin
		loadNumSuit = 1'b0;
		drawBlank = 1'b0;
		drawNum = 1'b0;
		drawSuit = 1'b0;
      plot = 1'b0;

      case (current_state)
			LOAD_NUM_SUIT: loadNumSuit = 1'b1;
         DRAW_BLANK, WAIT_BLANK: begin
				drawBlank <= 1'b1;
				plot <= 1'b1;
			end
			DRAW_NUM, WAIT_NUM: begin
				drawNum <= 1'b1;
				plot <= 1'b1;
			end
			DRAW_SUIT, WAIT_SUIT: begin
				drawSuit <= 1'b1;
				plot <= 1'b1;
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

module drawBlankCard(
	input resetN,
	input clock,

	input start,

	input [7:0] x,
	input [6:0] y,
	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut,

	output reg done
	);
	reg [7:0] xReg, xOffset;
	reg [6:0] yReg, yOffset;

	reg [1:0] current_state, next_state;

	localparam
		NO_DRAW 	= 2'd0,
		DRAW		= 2'd1,
		DONE		= 2'd2;

	always@(*) begin
		case (current_state)
			NO_DRAW 		: next_state = start ? DRAW : NO_DRAW;
			DRAW			: next_state = done ? DONE : DRAW;
			DONE			: next_state = NO_DRAW;
		endcase
	end

	always@(posedge clock) begin
		if (start) begin
			xReg <= x;
			yReg <= y;
		end
		
		case (current_state)
			NO_DRAW	: begin
				xOffset <= 8'b0;
				yOffset <= 7'b0;
				xReg <= 8'b0;
				yReg <= 7'b0;
				xOut <= 8'b0;
				yOut <= 7'b0;
				cOut <= 3'b0;
				done <= 1'b0;
			end
			DRAW: begin
				if (xOffset < 8'd23)
					xOffset <= xOffset + 1'b1;
				else if (yOffset < 8'd39) begin
					yOffset <= yOffset + 1'b1;
					xOffset <= 8'b0;
				end else
					done <= 1'b1;

				xOut <= xReg + xOffset;
				yOut <= yReg + yOffset;
				cOut <= 3'b111;
			end
			DONE:	begin
				done <= 1'b1;
			end
		endcase
	end

	always@(posedge clock) begin
		if (!resetN)
			current_state <= NO_DRAW;
		else
			current_state <= next_state;
	end
endmodule

module drawNumSuit(
	input resetN,
	input clock,
	
	input start,

	input [7:0] x,
	input [6:0] y,
	
	input [767:0] data,

	output reg [7:0] xOut,
	output reg [6:0] yOut,
	output reg [2:0] cOut,
	output reg done
	);

	reg [7:0] xReg, xOffset;
	reg [6:0] yReg, yOffset;
	reg [767:0] dataReg;

	reg [2:0] current_state, next_state;
	
	localparam
		NO_DRAW 		= 3'd0,
		LOAD			= 3'd1,
		DRAW			= 3'd2;

	always@(*) begin
		case (current_state)
			NO_DRAW 			: next_state = start ? LOAD : NO_DRAW;
			LOAD				: next_state = DRAW;
			DRAW				: next_state = done ? NO_DRAW : DRAW;
			default			: next_state = NO_DRAW;
		endcase
	end
	
	always@(posedge clock) begin
		done <= 1'b0;
		case (current_state)
			NO_DRAW: begin
				dataReg <= 768'b0;
				xReg <= 8'b0;
				yReg <= 7'b0;
				xOut <= 8'b0;
				yOut <= 7'b0;
				cOut <= 2'b0;
				xOffset <= 8'b0;
				yOffset <= 7'b0;
			end

			LOAD:	begin
						dataReg <= data;
						xReg <= x;
						yReg <= y;
					end
			DRAW: begin
				if (xOffset < 8'd15) begin
					xOffset <= xOffset + 1'b1;
					dataReg <= dataReg << 3;
				end else if (yOffset < 8'd15) begin
					yOffset <= yOffset + 1'b1;
					xOffset <= 8'b0;
					dataReg <= dataReg << 3;
				end else begin
					done <= 1'b1;
				end
				
				xOut <= xReg + xOffset;
				yOut <= yReg + yOffset;
				cOut <= dataReg [767:765];
			end
		endcase
	end

	always@(posedge clock) begin
		if (!resetN)
			current_state <= NO_DRAW;
		else
			current_state <= next_state;
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

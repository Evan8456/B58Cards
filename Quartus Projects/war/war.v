// 
module wasr(CLOCK_50,				//	On Board 50 MHz
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
		HEX2,
		HEX1,
		HEX0,
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
	output [6:0] HEX6;
	output [6:0] HEX5;
	output [6:0] HEX4;
	output [6:0] HEX3;
	output [6:0] HEX2, HEX1;
	output [6:0] HEX0;

	wire clock;
	wire resetn;
	wire go; // HIGH indicates that a process has finished (player choosing a card, a card drawing, etc)

	assign clock = CLOCK_50;
	assign resetn = SW[17];
	assign go = SW[0];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire plot;
	reg vga_go;

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
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.

	
	
	wire loadNumSuit, drawBlank, drawNum, drawSuit;
	wire blankDone, numDone, suitDone;

	reg [3:0] num_to_draw;
	reg [1:0] suit_to_draw;

	drawCard DC(
		.resetN(resetn),
		.clock(CLOCK_50),

		.xIn(x_loc),                // 8 bit x location input
		.yIn(y_loc),                // 7 bit y location input

		.loadNumSuit(loadNumSuit),	 // FSM signals
		.drawBlank(drawBlank),
		.drawNum(drawNum),
		.drawSuit(drawSuit),

		.cardNum(num_to_draw), // num_to_draw
		.cardSuit(suit_to_draw), // suit_to_draw

		.xOut(x[7:0]),
		.yOut(y[6:0]),
		.cOut(colour[2:0]),
	
		.blankDone(blankDone),
		.numDone(numDone),
		.suitDone(suitDone)
	);
		
	
	control FSM(
		.resetN(resetn),            // Resets the states
		.clock(CLOCK_50),           // FSM clock
		.go(vga_go),                    // Begins FSM cycle
	 
		.blankDone(blankDone),
		.numDone(numDone),
		.suitDone(suitDone),

		.loadNumSuit(loadNumSuit),
		.drawBlank(drawBlank),
		.drawNum(drawNum),
		.drawSuit(drawSuit),
		.plot(plot),
		
		.current_state(),
		.next_state()
	);
	
	HexDecoder hexX1(.IN(player_card[3:0]),
					.OUT(HEX7[6:0])
	);
	 
	HexDecoder hexX2(.IN(player_card[5:4]),
					.OUT(HEX6[6:0])
	);
	 
	HexDecoder hexY1(.IN(com_card[3:0]),
					.OUT(HEX5[6:0])
	);
	 
	HexDecoder hexY2(.IN(com_card[5:4]),
					.OUT(HEX4[6:0])
	);
	 
	HexDecoder hexColour1(.IN(colour[2:0]),
					.OUT(HEX3[6:0])
	);
	 
	HexDecoder hexColour2(.IN({2'b0, winner}),
					.OUT(HEX1[6:0])
	);

	reg [9:0] player_head; // head of the player's deck - starts empty
	reg [9:0] com_head; // head of the com's deck - starts empty
	reg [9:0] deck_head; // head of original deck - starts with 52 cards

   reg [4:0] current_state, next_state;
	assign LEDR[17:13] = current_state;
	assign LEDR[12:8] = next_state;
	
	wire [7:0] player_x_loc; // x location for drawing player card
	wire [7:0] player_y_loc; // y location for drawing player card
	wire [7:0] com_x_loc; // x location for drawing com card
	wire [7:0] com_y_loc; // y location for drawing com card
	assign player_x_loc = 8'd30;
	assign player_y_loc = 8'd70;
	assign com_x_loc = 8'd200;
	assign com_y_loc = 8'd70;
	
	reg [1:0] winner; // 0-no winner yet, 1-player wins, 2-com wins
	
	reg [1:0] op; // ram operation
	
	reg [5:0] player_count; // the number of cards in the player's deck
	reg [5:0] com_count; // the number of cards in the com's deck
	reg [5:0] curr_deck_count;
	
	reg [5:0] drawn_card;
	reg [5:0] player_card;
	reg [5:0] com_card;
	wire [5:0] card_out;
	reg [7:0] x_loc; // x position to draw next card
	reg [7:0] y_loc; // y position to draw next card
	
	reg ram_enable;
	wire temp_ram_done;
	wire ram_done;
	assign ram_done = temp_ram_done;
	assign LEDR[0] = ram_done;
	wire vga_done;
	assign vga_done = SW[7];
	assign LEDR[1] = vga_done;
	reg [9:0] ram_arg1;
	reg [9:0] ram_arg2;
	
	reg [3:0] curr_num;
	reg [1:0] curr_suit;
	
	reg load_seed; // on loads seed to rng
	reg next_int; // on triggers next int
	reg rng_counter; // while on, counts to generate random value
    
	localparam  
				ALLOC_PLAYER			= 5'd31, // Allocate memory for the head of the player's deck
				ALLOC_COM				= 5'd1, // Allocate memory for the head of the computer's deck
				ALLOC_DECK				= 5'd2, // Allocate memory for the head of the deck
				BUILD_DECK				= 5'd3, // add a card to the deck
				WAIT_FOR_IT				= 5'd4, // it waits
				GENERATE_SEED			= 5'd5, // generate a random seed
				WAIT_GO_DISABLE		= 5'd6, // Wait until go is down to get the cards
				SEED_GOT					= 5'd7, // the seed has been generated
				DRAW_FROM_DECK			= 5'd8, // draw a card from the deck
				NEXT_INT_1				= 5'd9, // calculate next int
				TO_HAND					= 5'd10, // place it in the player's or the com's hand
				CARD_DEALT				= 5'd11, // a card has been dealt to a player
				PLAYER_WAIT				= 5'd12, // wait for user input "go"
				DRAW_FROM_PLAYER		= 5'd13, // draw a card from the user's hand
				WAIT_DRAW_PLAYER		= 5'd14, // Wait until the player's card is done drawing
				NEXT_INT_2				= 5'd15, // calculate next int
				DRAW_FROM_COM			= 5'd16, // draw a card from the com's hand
				WAIT_DRAW_COM			= 5'd17, // Wait until the computer card is done drawing
				NEXT_INT_3				= 5'd18, // calculate next int
				CALCULATE				= 5'd19, // calculate who wins
				PC_TO_PLAYER			= 5'd20, // move the player's drawn card to the player's hand
				CC_TO_PLAYER			= 5'd21, // move the com's drawn card to the player's hand
				PC_TO_COM				= 5'd22, // move the player's drawn card to the com's hand
				CC_TO_COM				= 5'd23, // move the com's drawn card to the com's hand
				STOP_ENABLE 			= 5'd24; // Wait until go is low to play the next two cards

	// Next state logic
	always @(posedge clock) begin
		case(current_state)
				ALLOC_PLAYER:				next_state = ram_done ? ALLOC_COM : ALLOC_PLAYER;
				ALLOC_COM:					next_state = ram_done ? ALLOC_DECK : ALLOC_COM;
				ALLOC_DECK:					next_state = ram_done ? BUILD_DECK : ALLOC_DECK;
				BUILD_DECK:					next_state = (curr_num==4'd13 && curr_suit==2'd3) ? GENERATE_SEED : WAIT_FOR_IT;
				WAIT_FOR_IT:				next_state = ram_done ? BUILD_DECK : WAIT_FOR_IT;
				GENERATE_SEED:				next_state = go ? WAIT_GO_DISABLE : GENERATE_SEED;
				WAIT_GO_DISABLE:			next_state = ~go ? SEED_GOT : WAIT_GO_DISABLE;
				SEED_GOT:					next_state = DRAW_FROM_DECK;
				DRAW_FROM_DECK:			next_state = ram_done ? NEXT_INT_1 : DRAW_FROM_DECK;
				NEXT_INT_1:					next_state = TO_HAND;
				TO_HAND:						next_state = ram_done ? CARD_DEALT : TO_HAND;
				CARD_DEALT:					next_state = com_count==6'd26 ? PLAYER_WAIT : DRAW_FROM_DECK;
				PLAYER_WAIT:				next_state = go ? DRAW_FROM_PLAYER : PLAYER_WAIT;
				DRAW_FROM_PLAYER:			next_state = ram_done ? WAIT_DRAW_PLAYER : DRAW_FROM_PLAYER;
				WAIT_DRAW_PLAYER:			next_state = vga_done ? NEXT_INT_2 : WAIT_DRAW_PLAYER;
				NEXT_INT_2: 				next_state = DRAW_FROM_COM;
				DRAW_FROM_COM:				next_state = ram_done ? WAIT_DRAW_COM : DRAW_FROM_COM;
				WAIT_DRAW_COM:				next_state = vga_done ? NEXT_INT_3 : WAIT_DRAW_COM;
				NEXT_INT_3:					next_state = CALCULATE;
				CALCULATE: begin
					if(winner == 0)			next_state = CALCULATE;
					else if(winner == 1)	next_state = PC_TO_PLAYER;
					else					next_state = PC_TO_COM;
				end
				PC_TO_PLAYER:				next_state = ram_done ? CC_TO_PLAYER : PC_TO_PLAYER;
				PC_TO_COM:					next_state = ram_done ? CC_TO_COM : PC_TO_COM;
				CC_TO_PLAYER:				next_state = ram_done ? STOP_ENABLE : CC_TO_PLAYER;
				CC_TO_COM:					next_state = ram_done ? STOP_ENABLE : CC_TO_COM;
				STOP_ENABLE:				next_state = ~go ? PLAYER_WAIT : STOP_ENABLE;
            default: next_state = ALLOC_PLAYER;
		endcase
	end
	
	// Output Logic
	always @(posedge clock) begin
		next_int <= 0;
		load_seed <= 0;
		ram_enable <= 0;
		vga_go <= 0;
		num_to_draw <= 0;
		suit_to_draw <= 0;

		case(current_state)
			NEXT_INT_1: next_int <= 1;
			NEXT_INT_2: next_int <= 1;
			NEXT_INT_3: next_int <= 1;
			ALLOC_PLAYER: begin
				winner <= 0;
				player_count <= 0;
				com_count <= 0;
				ram_enable <= 1;
				op <= 2'd3;
				ram_arg1 <= player_head;
			end
			ALLOC_COM: begin
				ram_enable <= 1;
				op <= 2'd3;
				ram_arg1 <= com_head;
			end
			ALLOC_DECK: begin
				ram_enable <= 1;
				op <= 2'd3;
				ram_arg1 <= deck_head;
			end
			BUILD_DECK: begin
				ram_enable <= 1;
				op <= 2'd0;
				ram_arg1 <= deck_head;
				ram_arg2 <= {curr_suit,curr_num};
				if(curr_suit == 2'd3) begin
					curr_suit <= 0;
					curr_num <= curr_num+4'd1;
				end
				else
					curr_suit = curr_suit+2'd1;
			end
			GENERATE_SEED: begin
				rng_counter <= 1; // start counting
			end
			SEED_GOT: begin
				load_seed <= 1; // load the seed
				rng_counter <= 0; // stop counter
			end
			DRAW_FROM_DECK: begin
				ram_enable <= 1;
				op <= 1;
				drawn_card <= card_out;
				curr_deck_count <= 6'd52 - player_count - com_count;
				ram_arg1 <= deck_head;
				ram_arg2 <= rand_int[9:0];
			end
			TO_HAND: begin
				ram_enable <= 1;
				op <= 0;
				if(player_count < 6'd26)
					ram_arg1 <= player_head;
					// increment count?
					if(ram_done == 1)
						player_count <= player_count+6'd1;
				else
					ram_arg1 <= com_head;
					// increment count?
					if(ram_done == 1)
						com_count <= com_count+6'd1;
				ram_arg2 <= drawn_card[5:0];
			end
			DRAW_FROM_PLAYER: begin
				ram_enable <= 1;
				op <= 1;
				player_card <= card_out;
				curr_deck_count <= player_count;
				ram_arg1 <= player_head;
				ram_arg2 <= rand_int[9:0];
				x_loc <= player_x_loc;
				y_loc <= player_y_loc;
				{suit_to_draw, num_to_draw} <= card_out;
			end
			WAIT_DRAW_PLAYER: begin
				vga_go <= 1;
			end
			DRAW_FROM_COM: begin
				ram_enable <= 1;
				op <= 1;
				com_card <= card_out;
				curr_deck_count <= com_count;
				ram_arg1 <= com_head;
				ram_arg2 <= rand_int[9:0];
				x_loc <= com_x_loc;
				y_loc <= com_y_loc;
				{suit_to_draw, num_to_draw} <= card_out;
			end
			WAIT_DRAW_COM: begin
				vga_go <= 1;
			end
			CALCULATE: begin
				// check winner
				if(player_card[3:0] < com_card[3:0])
					winner <= 2'd2;
				else
					winner <= 2'd1;
			end
			PC_TO_PLAYER: begin
				ram_enable <= 1;
				op <= 0;
				ram_arg1 <= player_head;
				ram_arg2 <= player_card[5:0];
			end
			CC_TO_PLAYER: begin
				ram_enable <= 1;
				op <= 0;
				player_count <= player_count+5'd1;
				com_count <= com_count-5'd1;
				ram_arg1 <= player_head;
				ram_arg2 <= com_card[5:0];
			end
			PC_TO_COM: begin
				ram_enable <= 1;
				op <= 0;
				player_count <= player_count-6'd1;
				com_count <= com_count+6'd1;
				ram_arg1 <= com_head;
				ram_arg2 <= player_card[5:0];
			end
			CC_TO_COM: begin
				ram_enable <= 1;
				op <= 0;
				ram_arg1 <= com_head;
				ram_arg2 <= com_card[5:0];
			end
			default: begin end
		endcase
	end
	
	// update current_state
	always@(posedge clock) begin
        if(!resetn) begin
			player_head <= 10'd32;
			com_head <= 10'd64;
			deck_head <= 10'd96;
            current_state <= ALLOC_PLAYER;
        end
        else
            current_state <= next_state;
	end
	
	ram_controller rc(.HEX0(HEX2),
		.enable(ram_enable),
		.clock(clock),						
		.select_op(op),						
		.arg1(ram_arg1),
		.arg2(ram_arg2),
		.finished_op(temp_ram_done),
		.out1(card_out),
		.states(LEDR[7:3])
	);
	
	// rng and RAM wires
	wire [15:0] generatorSeed;
	wire [15:0] currentSeed;
	wire [15:0] rand_int;
	
	randomSeedGenerator generator(
		.clock(clock),
		.enable_count(rng_counter),
		.seed(generatorSeed)
	);
	// Decrease max with deck size
	RNG RNGmod(
		.clock(clock),
		.LoadSeed(generatorSeed),
		.Load_n(load_seed),
		.min_n(16'd1),
		.max_n(curr_deck_count),
		.next_int(next_int),
		.rand_int(rand_int),
		.seed(currentSeed)
	);
endmodule

module warControl(
	input clock,
	input resetn,
	input go, // HIGH indicates that a process has finished (player choosing a card, a card drawing, etc)
	
	input [9:0] player_head, // head of the player's deck - starts empty
	input [9:0] com_head, // head of the com's deck - starts empty
	
	input [9:0] deck_head // head of original deck - starts with 52 cards
	);

    reg [4:0] current_state, next_state;
	
	wire [7:0] player_x_loc; // x location for drawing player card
	wire [7:0] player_y_loc; // y location for drawing player card
	wire [7:0] com_x_loc; // x location for drawing com card
	wire [7:0] com_y_loc; // y location for drawing com card
	assign player_x_loc = 8'd50;
	assign player_y_loc = 8'd50;
	assign com_x_loc = 8'd50;
	assign com_y_loc = 8'd200;
	
	reg [1:0] winner; // 0-no winner yet, 1-player wins, 2-com wins
	
	reg [1:0] op; // ram operation
	
	reg [4:0] player_count; // the number of cards in the player's deck
	reg [4:0] com_count; // the number of cards in the com's deck
	
	reg [15:0] drawn_card;
	reg [15:0] player_card;
	reg [15:0] com_card;
	reg [15:0] card_out;
	reg [7:0] x_loc; // x position to draw next card
	reg [7:0] y_loc; // y position to draw next card
	
	reg ram_enable;
	reg ram_done;
	reg [9:0] ram_arg1;
	reg [9:0] ram_arg2;
	
	reg load_seed; // on loads seed to rng
	reg next_int; // on triggers next int
	reg rng_counter; // while on, counts to generate random value
	
	reg plot; // toggles plotting graphics
    
	localparam  
				GENERATE_SEED			= 4'd0, // generate a random seed
				SEED_GOT				= 4'd1, // the seed has been generated
				DRAW_FROM_DECK			= 4'd2, // draw a card from the deck
				NEXT_INT_1				= 4'd3, // calculate next int
				TO_HAND					= 4'd4, // place it in the player's or the com's hand
				CARD_DEALT				= 4'd5, // a card has been dealt to a player
				PLAYER_WAIT				= 4'd6, // wait for user input "go"
				DRAW_FROM_PLAYER		= 4'd7, // draw a card from the user's hand
				NEXT_INT_2				= 4'd8, // calculate next int
				DRAW_FROM_COM			= 4'd9, // draw a card from the com's hand
				NEXT_INT_3				= 4'd10, // calculate next int
				CALCULATE				= 4'd11, // calculate who wins
				PC_TO_PLAYER			= 4'd12, // move the player's drawn card to the player's hand
				CC_TO_PLAYER			= 4'd13, // move the com's drawn card to the player's hand
				PC_TO_COM				= 4'd14, // move the player's drawn card to the com's hand
				CC_TO_COM				= 4'd15; // move the com's drawn card to the com's hand
	
	// Next state logic
	always @(posedge clock) begin
		case(current_state)
				GENERATE_SEED:				next_state = go ? SEED_GOT : GENERATE_SEED;
				SEED_GOT:					next_state = DRAW_FROM_DECK;
				DRAW_FROM_DECK:				next_state = ram_done ? TO_HAND : DRAW_FROM_DECK;
				TO_HAND:					next_state = ram_done ? CARD_DEALT : TO_HAND;
				CARD_DEALT:					next_state = com_count==26 ? PLAYER_WAIT : REMOVE_FROM_DECK;
				PLAYER_WAIT:				next_state = go ? DRAW_FROM_PLAYER : PLAYER_WAIT;
				DRAW_FROM_PLAYER:			next_state = ram_done ? DRAW_FROM_COM : DRAW_FROM_PLAYER;
				DRAW_FROM_COM:				next_state = ram_done ? CALCULATE : DRAW_FROM_COM;
				CALCULATE: begin
					if(winner == 0)			next_state = CALCULATE;
					else if(winner == 1)	next_state = PC_TO_PLAYER;
					else					next_state = PC_TO_COM;
				end
				PC_TO_PLAYER:				next_state = ram_done ? CC_TO_PLAYER : PC_TO_PLAYER;
				PC_TO_COM:					next_state = ram_done ? CC_TO_COM : PC_TO_COM;
				CC_TO_PLAYER:				next_state = ram_done ? PLAYER_WAIT : CC_TO_PLAYER;
				CC_TO_COM:					next_state = ram_done ? PLAYER_WAIT : CC_TO_COM;
            default: next_state = PLAYER_WAIT;
		endcase
	end
	
	// Output Logic
	always @(*) begin
		next_int <= 0;
		load_seed <= 0;
		ram_enable <= 0;
		plot <= 0;
		case(current_state)
			NEXT_INT_1: next_int <= 1;
			NEXT_INT_2: next_int <= 1;
			NEXT_INT_3: next_int <= 1;
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
				arg1 <= deck_head;
				arg2 <= rand_int;
			end
			TO_HAND: begin
				ram_enable <= 1;
				op <= 0;
				if(player_count < 26)
					arg1 <= player_head;
					// increment count?
					if(ram_done == 1)
						player_count <= player_count+1;
				else
					arg1 = com_head;
					// increment count?
					if(ram_done == 1)
						com_count <= com_count+1;
				arg2 <= drawn_card[5:0];
			end
			DRAW_FROM_PLAYER: begin
				ram_enable <= 1;
				op <= 1;
				player_card <= card_out;
				arg1 <= player_head;
				arg2 <= rand_int;
				x_loc <= player_x_loc;
				y_loc <= player_y_loc;
				plot <= 1;
			end
			DRAW_FROM_COM: begin
				ram_enable <= 1;
				op <= 1;
				com_card <= card_out;
				arg1 <= com_head;
				arg2 <= rand_int;
				x_loc <= com_x_loc;
				y_loc <= com_y_loc;
				plot <= 1;
			end
			CALCULATE: begin
				// check winner
				if(player_card[3:0] < com_card[3:0])
					winner <= 2;
				else
					winner <= 1;
			end
			PC_TO_PLAYER: begin
				ram_enable <= 1;
				op <= 0;
				arg1 <= player_head;
				arg2 <= player_card[5:0];
			end
			CC_TO_PLAYER: begin
				ram_enable <= 1;
				op <= 0;
				player_count <= player_count+1;
				com_count <= com_count-1;
				arg1 <= player_head;
				arg2 <= com_card[5:0];
			end
			PC_TO_COM: begin
				ram_enable <= 1;
				op <= 0;
				player_count <= player_count-1;
				com_count <= com_count+1;
				arg1 <= com_head;
				arg2 <= player_card[5:0];
			end
			CC_TO_PLAYER: begin
				ram_enable <= 1;
				op <= 0;
				arg1 <= com_head;
				arg2 <= com_card[5:0];
			end
		endcase
	end
	
	// update current_state
	always@(posedge clock) begin
        if(!resetn) begin
			player_count <= 0;
			com_count <= 0;
            current_state <= DRAW_FROM_DECK;
        end
        else
            current_state <= next_state;
	end
	
	ram_controller rc(
		.enable(ram_enable),			
		.clock(clock),						
		.select_op(op),						
		.arg1(ram_arg1),
		.arg2(ram_arg2),
		.finished_op(ram_done),		
		.out1(card_out)
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
	
	RNG RNGmod(
		.clock(clock),
		.LoadSeed(generatorSeed),
		.Load_n(load_seed),
		.min_n(16'd1),
		.max_n(16'd53),
		.next_int(next_int),
		.rand_int(rand_int),
		.seed(currentSeed)
	);
endmodule

//----------------------------------------------------RNG Modules------------------------------------
// when enable_count is high, count the number of clock cycles before enable_count is low again
module randomSeedGenerator(clock, enable_count, seed);
	input clock;
	input enable_count;
	output [15:0] seed;
	
	reg start_cycle; // 1 on posedge of enable_count
	//reg end_cycle; // 1 on negedge of enable_count
	reg last_cycle; // equal to the value of enable_count in the last clock cycle
	
	counter16Bit timer(
		.enable(enable_count), // counts while enable_count is high
		.clock(clock),
		.clear_b(start_cycle), // clear the count when the counting starts
		.q(seed)
	);
	
	always@(clock) begin
		// default values
		start_cycle <= 0;
		//end_cycle <= 0;
		// check if this is a start or end cycle
		if(enable_count==1 && last_cycle==0)
			start_cycle <= 1;
		//else if(enable_count==0 && last_cycle==1)
		//	end_cycle <= 1;
		last_cycle <= enable_count;
	end
endmodule

// stores 16 bits. Increases value by one each clock cycle that enable is high
module counter16Bit(enable, clock, clear_b, q);
	input enable;
	input clock;
	input clear_b;
	output reg [15:0] q;
	
	always @ (posedge clock)
	begin
		if (clear_b == 1)
			q <= 0;
		else if (enable == 1)
			q <= q + 1;
	end
endmodule

/* Random Number Generator - generates seed from random occurances
the seed updates by the xorshift algorithm on the positive edge of next_int
rand_int will be a random value between min_n (inclusive) and max_n (exclusive)
if min_n>=max_n, rand_int will be min_n
min_n, max_n, and the seed are all 16 bit
*/
module RNG(clock, LoadSeed, Load_n, min_n, max_n, next_int, rand_int, seed);
	input clock;
	input [15:0] LoadSeed; // parallel load seed input
	input Load_n; // parallel load seed? active low
	input [15:0] min_n; // minimum possible int (inclusive)
	input [15:0] max_n; // maximum possible int (exclusive)
	input next_int; // on posedge, generates next seed
	
	output reg [15:0] rand_int; // random int in [min_n, max_n)
	reg last_cycle; // the value of rand_int on the last clock cycle
	output reg [15:0] seed; // the current random seed
	
	reg [15:0] range; // max_n-min_n, the number of possible outcomes
	wire [15:0] next_seed; // (the seed) XOR (the seed shifted right by one)
	
	xorShift seed_updater(
		.LoadVal(seed),
		.Q(next_seed)
	);
	
	always@(posedge clock) begin
		// parallel load?
		if(!Load_n)
			seed = LoadSeed;
		// if posedge of next_int
		if(next_int==1 && last_cycle==0)
			seed = next_seed;
			
		// calculate rand_int
		if(min_n>=max_n)
			rand_int = min_n;
		else begin
			range = max_n-min_n;
			rand_int = (seed % range) + min_n;
		end
		last_cycle = next_int;
	end
	
	// update seed
	//always@(posedge next_int)
	//	seed = next_seed;
endmodule

// Q is (LoadVal) XOR (LoadVal circularly shifted right by one bit). Stores 16 bits
// Eg, 1001 would become 1001^0011=1010
module xorShift(LoadVal, Q);
	input [15:0] LoadVal;
	output [15:0] Q;
	
	assign Q[15] = LoadVal[15]^LoadVal[14];
	assign Q[14] = LoadVal[14]^LoadVal[13];
	assign Q[13] = LoadVal[13]^LoadVal[12];
	assign Q[12] = LoadVal[12]^LoadVal[11];
	assign Q[11] = LoadVal[11]^LoadVal[10];
	assign Q[10] = LoadVal[10]^LoadVal[9];
	assign Q[9] = LoadVal[9]^LoadVal[8];
	assign Q[8] = LoadVal[8]^LoadVal[7];
	assign Q[7] = LoadVal[7]^LoadVal[6];
	assign Q[6] = LoadVal[6]^LoadVal[5];
	assign Q[5] = LoadVal[5]^LoadVal[4];
	assign Q[4] = LoadVal[4]^LoadVal[3];
	assign Q[3] = LoadVal[3]^LoadVal[2];
	assign Q[2] = LoadVal[2]^LoadVal[1];
	assign Q[1] = LoadVal[1]^LoadVal[0];
	assign Q[0] = LoadVal[0]^LoadVal[15];
endmodule




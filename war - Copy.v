module warControl(
	input clock,
	input resetn,
	input go, // HIGH indicates that a process has finished (player choosing a card, a card drawing, etc)
	
	input [9:0] player_head, // head of the player's deck - starts empty
	input [9:0] com_head, // head of the com's deck - starts empty
	
	input [9:0] deck_head, // head of original deck - starts with 52 cards
	
	input rng_counter, // while on, counts to create random seed
	
	output reg plot
	);

    reg [4:0] current_state, next_state;
	
	wire [7:0] player_x_loc; // x location for drawing player card
	wire [7:0] player_y_loc; // y location for drawing player card
	wire [7:0] com_x_loc; // x location for drawing com card
	wire [7:0] com_y_loc; // y location for drawing com card
	assign player_x_loc = 8'd200;
	assign player_y_loc = 8'd500;
	assign com_x_loc = 8'200;
	assign com_y_loc = 8'd100;
	
	//reg dealEn;
	//reg drawEn;
	//reg storeEn;
	reg [1:0] winner; // 0-no winner yet, 1-player wins, 2-com wins
	
	reg [1:0] op; // ram operation
	
	reg [4:0] player_count; // the number of cards in the player's deck
	reg [4:0] com_count; // the number of cards in the com's deck
	
	reg [15:0] player_card;
	reg [15:0] com_card;
	reg [15:0] card_out;
	reg [7:0] x_loc; // x position to draw next card
	reg [7:0] y_loc; // y position to draw next card
	
	reg ram_enable;
	reg ram_done;
	reg [9:0] ram_arg1;
	reg [9:0] ram_arg2;
    
	localparam  
				DEAL_TO_PLAYER			= 4'd0,
				DEAL_TO_COM				= 4'd1,
				PLAYER_WAIT				= 4'd2,
				PLAYER_PLAY				= 4'd3,
				PLAYER_DRAW				= 4'd4,
				COM_PLAY				= 4'd5,
				COM_DRAW				= 4'd6,
				CALCULATE				= 4'd7, // calculate who wins
				PLAYER_CARD_TO_PLAYER	= 4'd8,
				COM_CARD_TO_PLAYER		= 4'd9,
				PLAYER_CARD_TO_COM		= 4'd10,
				COM_CARD_TO_COM			= 4'd11;
	
	// Next state logic
	always @(posedge clock) begin
		case(current_state)
				DEAL_TO_PLAYER: begin
					if(player_count == 4'd26)
						next_state = DEAL_TO_COM;
					else
						next_state = DEAL_TO_PLAYER;
				end
				DEAL_TO_COM: begin
					if(com_count == 4'd26)
						next_state = PLAYER_WAIT;
					else
						next_state = DEAL_TO_COM;
				end
				PLAYER_WAIT: 				next_state = go ? PLAYER_PLAY : PLAYER_WAIT;
				PLAYER_PLAY: 				next_state = PLAYER_DRAW;
				PLAYER_DRAW:				next_state = go ? COM_PLAY : PLAYER_DRAW;
				COM_PLAY: 					next_state = COM_DRAW;
				COM_DRAW:					next_state = go ? CALCULATE : COM_DRAW;
				CALCULATE: begin
					if(winner == 0):
						next_state = CALCULATE;
					else if(winner == 1):
						next_state = PLAYER_CARD_TO_PLAYER;
					else
						next_state = PLAYER_CARD_TO_COM;
				end
				PLAYER_CARD_TO_PLAYER:		next_state = 
				PLAYER_WINS:		next_state = go ? DEAL : PLAYER_WINS;
				COM_WINS:		next_state = go ? DEAL : COM_WINS;
            default: next_state = DEAL;
		endcase
	end
	
	// Output Logic
	always @(*) begin
		ramEn = 0;
		winner = 0;
		case(current_state)
			DEAL_TO_PLAYER: begin
				if(ram_done == 1) begin
					player_count <= player_count+1;
					// move card from deck to player
					card_head <= deck_head;
					store_to_head <= player_head;
					ramEn <= 1;
				end
			end
			DEAL_TO_COM: begin
				dealEn <= 1;
				com_count <= com_count+1
				// move card from deck to com
				card_head <= deck_head;
				store_to_head <= com_head;
				storeEn <= 1;
			end
			PLAYER_PLAY: begin
				card_head <= player_head;
				x_loc <= player_x_loc;
				y_loc <= player_y_loc;
				drawEn <= 1;
				player_card <= card_out[15:0];
			end
			COM_PLAY: begin
				card_head <= com_head;
				x_loc <= com_x_loc;
				y_loc <= com_y_loc;
				drawEn <= 1;
				com_card <= card_out[15:0];
			end
			CALCULATE: begin
				// check winner
				if(player_card[3:0] < com_card[3:0])
					winner <= 2;
				else
					winner <= 1;
			end
			PLAYER_WINS: begin
				storeEn <= 1;
				store_to_head <= player_head;
				///////////////////////////////////////////////////// Store player and com cards to player
			end
			COM_WINS: begin
				storeEn <= 1;
				store_to_head <= com_head;
				///////////////////////////////////////////////////// Store player and com cards to com
			end
		endcase
	end
	
	// update current_state
	always@(posedge clock) begin
        if(!resetn)
			player_count <= 0;
			com_count <= 0;
            current_state <= DEAL_TO_PLAYER;
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
		.Load_n(SW[14]),
		.min_n(16'd1),
		.max_n(16'd53),
		.next_int(SW[13]),
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




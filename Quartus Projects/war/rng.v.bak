/*
SW[17] enable_count
SW[14] load RNG seed
SW[13] next_int
SW[12] seed display - 0 is generatorSeed, 1 is currentSeed
LEDR[15:0] current seed
HEX3, HEX2, HEX1, HEX0 rand_int
*/
module project(SW, CLOCK_50, LEDR, HEX0, HEX1, HEX2, HEX3);
	input [17:0] SW;
	input CLOCK_50;
	output [17:0] LEDR;
	
	output [6:0] HEX0;
	output [6:0] HEX1;
	output [6:0] HEX2;
	output [6:0] HEX3;
	
	wire [15:0] generatorSeed;
	wire [15:0] currentSeed;
	wire [15:0] rand_int;
	
	assign LEDR[15:0] = SW[12] ? currentSeed : generatorSeed; // 0 is generatorSeed, 1 is currentSeed
	
	randomSeedGenerator generator(
		.clock(CLOCK_50),
		.enable_count(SW[17]),
		.seed(generatorSeed)
	);
	
	RNG RNGmod(
		.clock(CLOCK_50),
		.LoadSeed(generatorSeed),
		.Load_n(SW[14]),
		.min_n(16'd1),
		.max_n(16'd53),
		.next_int(SW[13]),
		.rand_int(rand_int),
		.seed(currentSeed)
	);
	
	HexDecoder hex3(
		.IN(rand_int[15:12]),
		.OUT(HEX3[6:0])
	);
	HexDecoder hex2(
		.IN(rand_int[11:8]),
		.OUT(HEX2[6:0])
	);
	HexDecoder hex1(
		.IN(rand_int[7:4]),
		.OUT(HEX1[6:0])
	);
	HexDecoder hex0(
		.IN(rand_int[3:0]),
		.OUT(HEX0[6:0])
	);
	
endmodule
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

module HexDecoder(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b1000000;
			4'b0001: OUT = 7'b1111001;
			4'b0010: OUT = 7'b0100100;
			4'b0011: OUT = 7'b0110000;
			4'b0100: OUT = 7'b0011001;
			4'b0101: OUT = 7'b0010010;
			4'b0110: OUT = 7'b0000010;
			4'b0111: OUT = 7'b1111000;
			4'b1000: OUT = 7'b0000000;
			4'b1001: OUT = 7'b0011000;
			4'b1010: OUT = 7'b0001000;
			4'b1011: OUT = 7'b0000011;
			4'b1100: OUT = 7'b1000110;
			4'b1101: OUT = 7'b0100001;
			4'b1110: OUT = 7'b0000110;
			4'b1111: OUT = 7'b0001110;
			
			default: OUT = 7'b0111111;
		endcase

	end
endmodule




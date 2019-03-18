module cards(SW, LEDR, KEY, CLOCK_50, HEX0, HEX2, HEX3);
	input [17:0] SW;
	output [6:0] HEX0, HEX2, HEX3;
	input [3:0] KEY;
	input CLOCK_50;
	output [17:0] LEDR;

	wire [9:0] address;
	assign address = {7'd0, SW[2:0]};

	reg [3:0] value = 4'd1;

	wire [1:0] suit;
	assign suit = SW[5:4];

	wire clock = SW[17] ;
	wire enable = SW[12];
	wire load_val = SW[13];
	wire [7:0] card;

	assign LEDR[7:0] = card;

	wire [16:0] sc_out;
	assign card = sc_out[16:8];

	store_card sc(address, value, suit, clock, enable, load_val, sc_out);

	HexDecoder hd(
		.IN(address[3:0]),
		.OUT(HEX0)
	);

	HexDecoder hd2(
		.IN(card[3:0]),
		.OUT(HEX2)
	);

	HexDecoder hd3(
		.IN(card[7:4]),
		.OUT(HEX3)
	);
endmodule

module store_card(
	input [9:0] address, // The address to store the card at
	input [3:0] value, // The card value
	input [1:0] suit, // The card suit
	input clock, // Stores to memory on this clock tick
	input enable, // If the module should store in memory
	input load_val, // If the module should load the value and suit, loads address if 0
	output [16:0] card // The card at the current address of the module
	);

	reg [3:0] current_value; // The current value of the module
	reg [1:0] current_suit; // The current suit of the module
	reg [9:0] current_addr; // The current address of the module

	always @(posedge clock) begin
		if(enable == 0) begin
			if(load_val) begin
				current_value <= value;
				current_suit <= suit;
			end
			else
				current_addr <= address;
		end
	end

	ram1024x32 ram(
		.address(address),
		.clock(clock),
		.data({2'd0, suit, value, 8'd0}),
		.wren(enable),
		.q(card)
	);
endmodule


module remove_card(
	input [9:0] card, // The address of the card to remove
	input load_cards, // If the new address should be loaded
	input clock, // The clocked of the circuit
	input [9:0] last_card // The address of the last card's next
	);

	reg [9:0] current_card;

	always @(posedge clock)begin
		if(load_cards)
			current_card <= card;
		else
			last_card <= current_card + 8; // The value and suit of a card take 8 bits, 8 bits ahead is the value of the address of the next card
	end
	
	ram1024x32 ram(
		.address(current_card[9:0]),
		.clock(clock),
		.data(0),
		.wren(load_cards),
		.q(next_card)
	);
endmodule

// removes and outputs the nth card in a linked list of cards
module nth_card(
	input [9:0] card, // The address of the head of the linked list
	input load_cards, //If the next card should be removed
	input [5:0] n, // The nth card is outputted
	input clock,
	output reg[5:0] out_card //data for the chosen cards
	);
	
	reg [15:0] current_card;
	reg [15:0] next_card;
	reg remove_card;
	reg [5:0] count;
	
	always@(posedge clock)begin
		if(load_cards)begin
			current_card[9:0] <= card;
			remove_card <= 0;
			count <= 0;
		end
		else if(count == n) begin
			out_card <= current_card[15:10];
			remove_card <= 1;
		end
		else if(next_card != 16'b0) begin
			current_card <= next_card;
			count <= count+1;
		end
		else
			out_card <= 0;
	end
	
	remove_card remover(
		.card(current_card[9:0]),
		.load_cards(remove_card),
		.clock(clock),
		.last_card(0) // Change this
	);
	
	ram1024x32 ram(
		.address(current_card[9:0]),
		.clock(clock),
		.data(0),
		.wren(0),
		.q(next_card)
	);
endmodule

module HexDecoder(IN, OUT);
    input [3:0] IN;
	 output reg [6:0] OUT;
	 
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

**/




module store_card(
	input [9:0] address, // The address to store the card at
	input [3:0] value, // The card value
	input [1:0] suit, // The card suit
	input [9:0] next_card, // The memory address of the next card
	input clock, // Stores to memory on this clock tick
	input enable, // If the module should store,
	input load_val, // If the module should load the value and suit (takes priority over storing)
	input load_addr, // If the module should load the memory address of the last and next card
	output reg [9:0] last_card, // The memory address of the last card's next
	output [7:0] card // The card at the current address of the module
	);

	reg [3:0] current_value; // The current value of the module
	reg [1:0] current_suit; // The current suit of the module
	reg [9:0] current_next; // The next card

	always @(posedge clock) begin
		if(load_val) begin
			current_value <= value;
			current_suit <= suit;
		end
		else if(load_addr) begin
			current_next <= next_card;
		end
		else if(enable) begin
			last_card <= address;
		end
	end

	ram1024x32 ram(
		.address(address),
		.clock(clock),
		.data({suit, value}),
		.wren(enable),
		.q(card)
	);
endmodule

module remove_card(
	input [9:0] card, // The address of the card to remove
	input load_cards, // If the new address should be loaded
	input clock, // The clocked of the circuit
	output reg [9:0] last_card // The address of the last card
	);

	reg [9:0] current_card;

	always @(posedge clock)begin
		if(load_cards)
			current_card <= card;
		else
			last_card <= current_card + 8; // The value and suit of a card take 8 bits, 8 bits ahead is the value of the address of the next card
	end
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
	
	always@(posedge clock)begin
		if(load_cards)
			current_card[9:0] <= card;
			remove_card <= 0;
		else if(next_card != 16'b0)
			current_card <= next_card;
		else
			out_card <= current_card[15:10];
			remove_card <= 1;
	end
	
	remove_card remover(
		.card(current_card[9:0]),
		.load_cards(remove_card),
		.clock(clock),
		.last_card()
	);
	
	ram1024x32 ram(
		.address(current_card),
		.clock(clock),
		.data({suit, value}),
		.wren(load_cards),
		.q(next_card)
	);
endmodule






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

	always @(posedge clock):
		if(load_cards)
			current_card <= card;
		else:
			last_card <= current_card + 8; // The value and suit of a card take 8 bits, 8 bits ahead is the value of the address of the next card
	end
endmodule

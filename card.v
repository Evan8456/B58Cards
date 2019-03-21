module store_card(
	input [9:0] address, // The address to store the card at
	input [3:0] value, // The card value
	input [1:0] suit, // The card suit
	input [9:0] next_card, // The memory address of the next card
	input clock, // Stores to memory on this clock tick
	input enable, // If the module should store
	input load, // If the module should load the address, value and suit
	output [31:0] card_data, // The data at the current address of the module
	);

	reg [3:0] current_value; // The current value of the module
	reg [1:0] current_suit; // The current suit of the module
	reg [9:0] current_addr; // The current address of the module
	reg wren; // If the ram module should write

	wire next_addr_found; // If memory for the next card has been allocated
	wire [9:0] next_card_addr; // Allocates memory for a new card
	wire [31:0] card_info; // The information to be written to ram

	assign card_info = {1, 9'b0, suit, value, 6'b0, next_card_addr}; // Fill the remaining positions with 0's

	always @(posedge next_addr_found) begin
		wren <= 1;
	end

	always @(posedge enable) begin
		wren <= 0;
	end

	always @(posedge load) begin
		if(load_val && enable == 0) begin
			current_value <= value;
			current_suit <= suit;
			current_addr <= address;
			wren <= 0;
		end
	end

	allocate_memory alloc(
		.clock(clock),
		.enable(alloc_enable),
		.adr_found(next_addr_found),
		.address(next_card_addr)
	);

	ram1024x32 ram(
		.address(address),
		.clock(clock),
		.data(card_info),
		.wren(wren),
		.q(card_data)
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


module B58Cards();
	reg a;
endmodule

module card(
	input [3:0] value,
	input [1:0] suit
	);
endmodule

module ace();
	reg value;
	wire a[2:0][3:0];
endmodule

module store_card(
	input [31:0] address, // The address to store the card at
	input [3:0] value, // The card value
	input [1:0] suit, // The card suit
	input clock, // Stores to memory on this clock tick
	input enable, // If the module should store,
	input load, // If the module should load the value and suit (takes priority over storing)
	output [7:0] card // The card at the current address of the module
	);

	reg [3:0] current_value; // The current value of the module
	reg [1:0] current_suit; // The current suit of the module

	
	always @(posedge clock) begin
		if(load) begin
			current_value <= value;
			current_suit <= suit;

	ram32x4 ram(
				.address(address),
				.clock(clock),
				.data({value, suit}),
				.wren(enable),
				.q(card)
	);
endmodule
module player(clock, hand, first_card)
	input clock;
	output reg [9:0] hand; // The memory address of the hand
	output [31:0] first_card;

	reg alloc_enable; // Allocate some memory for the player's hand
	wire addr_found; // Make sure to stop when the address is found

	always @(addr_found) begin
		alloc_enable = addr_found ? 0 : 1;
	end

	allocate_memory alloc(
		.clock(clock),
		.enable(alloc_enable),
		.adr_found(addr_found),
		.address(hand)
	);
endmodule
